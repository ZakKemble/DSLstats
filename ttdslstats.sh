#!/bin/bash

# Licence:
# Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
# http://creativecommons.org/licenses/by-nc-sa/4.0/

USERNAME="admin"
PASSWORD="admin"
ADDRESS="192.168.1.1"

DEBUG=0

SESSIONCOOKIE="SessionID_R3"
LOGINPATH="/api/system/user_login"
DSLPATH="/api/ntwk/dslinfo"
TIMEOUT=2

# Cookie timeout is around 15 - 20 seconds

exitError()
{
	if [ $? -ne 0 ]; then
		echo "${1}" 1>&2
		exit 1
	fi
}

debugPrint()
{
	if [ ${DEBUG} -eq 1 ]; then
		echo "${1}"
	fi
}

# Make sure wget is installed
hash wget 2>/dev/null
exitError "wget not found. Aborting."

# Get the HTML login page and headers as we need the CSRF tokens (stored in meta tags in the HTML) and session cookie
LOGIN_PAGE=$(wget -T ${TIMEOUT} -t 1 -q -S -O - http://${ADDRESS} 2>&1)
exitError "Failed to get login page"

# Parse out cookie value and CSRF stuff
COOKIE=$(echo -n "${LOGIN_PAGE}" | grep ${SESSIONCOOKIE} | sed -e 's/.*'${SESSIONCOOKIE}'=\([^;]*\).*/\1/')
CSRF_PARAM_TOKEN=$(echo -n "${LOGIN_PAGE}" | grep csrf_ | sed -e 's/.*content="\(.*\)".*/\1/')

# Split the CSRF stuff
CSRF_DATA=(${CSRF_PARAM_TOKEN})
CSRF_PARAM=${CSRF_DATA[0]}
CSRF_TOKEN=${CSRF_DATA[1]}

# Check to see if this router is a HG633, as a few extra things are needed when processing the password
IS_HG633=0
TMP=$(echo -n "${LOGIN_PAGE}" | grep HG633)
if [ $? -eq 0 ]; then
	IS_HG633=1
fi

# Hash the password
# 1> Hash the password using SHA256
# 2> Base64 encode the hash
# 3> Concatenate the username + base64 encoded password hash + CSRF parameter + CSRF token (HG633 only)
# 4> Hash the concatenated string using SHA256 (HG633 only)
# 5> Profit?
PASSWORD_HASH=$(echo -n $(echo -n ${PASSWORD} | sha256sum | cut -c -64) | base64 -w 0)
if [ ${IS_HG633} -eq 1 ]; then
	DATA_TO_HASH=${USERNAME}${PASSWORD_HASH}${CSRF_PARAM}${CSRF_TOKEN}
	FINAL_HASH=$(echo -n ${DATA_TO_HASH} | sha256sum | cut -c -64)
else
	FINAL_HASH=${PASSWORD_HASH}
fi

debugPrint "*ISHG633: ${IS_HG633}"
debugPrint "*COOKIE: ${COOKIE}"
debugPrint "*PARAM_TOKEN: ${CSRF_PARAM_TOKEN}"
debugPrint "*PARAM: ${CSRF_PARAM}"
debugPrint "*TOKEN: ${CSRF_TOKEN}"
debugPrint "*PASSHASH: ${PASSWORD_HASH}"
debugPrint "*DATATOHASH: ${DATA_TO_HASH}"
debugPrint "*FINALHASH: ${FINAL_HASH}"

# Create JSON string containing the CSRF parameter, CSRF token, username and hashed password
POST_DATA="{\"csrf\":{\"csrf_param\":\"${CSRF_PARAM}\",\"csrf_token\":\"${CSRF_TOKEN}\"},\"data\":{\"UserName\":\"${USERNAME}\",\"Password\":\"${FINAL_HASH}\"}}"
debugPrint "*POSTDATA: ${POST_DATA}"

# Do the login
# POST the JSON string and also send the session cookie from the login page
LOGIN_RESPONSE=$(wget -T ${TIMEOUT} -t 1 -q -S -O - --no-cookies --header "Cookie: ${SESSIONCOOKIE}=${COOKIE}" --post-data=${POST_DATA} http://${ADDRESS}${LOGINPATH} 2>&1)
debugPrint "*LOGINRES:"
debugPrint "${LOGIN_RESPONSE}"
exitError "Failed to get login response"

# Check login was successful
# If grep doesn't find a match it exits with status 1
TMP=$(echo -n "${LOGIN_RESPONSE}" | grep "\"errorCategory\":\"ok\"")
exitError "Incorrect username or password (possibly locked out or something)"

# If something fails then we want the pipe to stop
set -o pipefail

# Get new cookie value
# Normally sed will exit with status 0, even if a match it not found. We want it to exit with status 1 which is what the extra q1 stuff does
# http://stackoverflow.com/questions/1665549/have-sed-ignore-non-matching-lines
# Modified to do the quit command instead of delete
COOKIE=$(echo -n "${LOGIN_RESPONSE}" | grep ${SESSIONCOOKIE} | sed -e 's/.*'${SESSIONCOOKIE}'=\([^;]\+\).*/\1/' -e 'tx' -e 'q1' -e ':x')
debugPrint "*COOKIE: ${COOKIE}"
exitError "Invalid cookie"

# Get the DSL stats
DSLSTATS=$(wget -T ${TIMEOUT} -t 1 -q -O - --no-cookies --header "Cookie: ${SESSIONCOOKIE}=${COOKIE}" http://${ADDRESS}${DSLPATH} | cut -d '*' -f 2)
debugPrint "***"
debugPrint "${DSLSTATS}"
debugPrint "***"
exitError "Failed to get DSL stats"

# Print out the stats
echo "${DSLSTATS}"

exit 0
