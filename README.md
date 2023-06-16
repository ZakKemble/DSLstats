# TT DSL Stats

A bash script for retrieving DSL statistics from some routers supplied by UK ISP TalkTalk.

Edit `ttdslstats.sh` to setup the `USERNAME`, `PASSWORD`, `ADDRESS` and `AUTHTYPE` settings.

`AUTHTYPE` will depend on your routers firmware version. Use `0` for older versions, otherwise set it to `1`. The exact version that requires changing `AUTHTYPE` is unknown, but it's somewhere between `1.04t` and `1.11ttb`.

Make sure you've added the execute permission (`chmod +x ./ttdslstats.sh`) and your system has `wget` installed.

Run:

`./ttdslstats.sh`

JSON output data:

```
{
	"DownPower":14,
	"Modulation":"VDSL2",
	"UpCurrRate":19999,
	"ShowtimeStart":71509,
	"DownstreamMaxBitRate":98868,
	"DownAttenuation":2.6,
	"Status":"Up",
	"DataPath":"Interleaved",
	"UpstreamMaxBitRate":27052,
	"UpPower":-7,
	"ImpulsoNoiseProUs":0.01,
	"ImpulsoNoiseProDs":3,
	"InterleaveDelayDs":0,
	"UpAttenuation":3,
	"DownMargin":6.8,
	"InterleaveDelayUs":0,
	"UpMargin":15.2,
	"DownCurrRate":79998,
	"UpDepth":1,
	"DownDepth":1
}
```

## Tested Routers

| Router | Firmware | AUTHTYPE |
| --- | --- | --- |
| Huawei HG633 | 1.15t | 1 |
| Huawei HG635 | 1.04t | 0 |
| Huawei HG635 | 1.11ttb | 1 |
