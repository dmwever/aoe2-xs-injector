# 02: Ping end to end, standalone

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent runs `ping` from the driver CLI against a live match whose test scenario includes the core module (no dispatch yet), and gets back an OK response echoing its request id. This is the tracer bullet: the request file, the module's request rule, the standalone response section, and the driver's send/find/decode loop all exist and work together.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] Driver resolves the profile folder from `--profile`, then `XSINJECT_PROFILE`, then auto-detecting the single `<steamid>/profile` folder
- [x] Driver picks the next request id from `xsinject.xsdat` (+1, or 1 when missing), saves the request as `xsinject.last.json`, and writes `xsinject.xsdat` by temp file + replace, retrying while the game holds it and giving up with `FileHeld` after 5 s
- [x] Module request rule runs every game-second; a missing or empty request file means idle; the id found at startup is adopted without being run; a changed (not necessarily greater) id is marked seen before it is parsed
- [x] A zero-call request produces a response section written standalone (`xsCreateFile(false)`, section only): trailer framing `[body][body byte length][magic]`, the body opening with the magic, then request id, request status, failed call # (-1), failed argument # (-1), entry count 0
- [x] Every module read is bounded by the file size, never by a -1 return
- [x] Driver finds the response by scanning `*.xsdat` (skipping the request file) for the trailing magic, modified after the send and echoing the request id; more than one match is an error; `--map` pins one file
- [x] Driver polls every 0.25 s with a 10 s default timeout (both configurable) and reports `Timeout` with `diagnosis` `no-section` or `older-id`
- [x] CLI prints the standard result shape and exits 0 only on OK
- [x] Driver-seam tests (temp profile folder, fixture response sections) cover profile resolution, next id, `FileHeld`, response finding including multiple matches and `--map`, header decode, and both timeout diagnoses
- [x] Live: the maintainer starts editor test-play of the test scenario; `ping` returns OK with the echoed id; a second `ping` gets the next id

## Comments

- 2026-11-11: Driver (`xsinject/`), core module (`xs/xsinject.xs`) and test scenario script (`xs/XsInjectTest.xs`) implemented; 29 driver-seam tests pass; XS lints clean with xs-check v0.2.30 (copy into `tools/`, gitignored). Live check pending. Judgement calls to confirm: magic is `441340760` (`0x1A4E5358`; XS int literals max 9 digits); multiple matching files return a new driver status `Ambiguous`; a missing or ambiguous profile folder returns `Invalid`; `failed_call`/`failed_argument` print `null` when n/a; a request with calls answers `UnknownFunction` at call #0 until slice 2's dispatch exists; a negative call count answers `Truncated`. "Modified after the send" is checked against each file's mtime snapshot taken just before the send.
- 2026-11-11: Live check passed. XsTesting editor test-play with Ageipelago `Test.xs` including `xsinject.xs`: the engine compiled the module, and pings 1, 2 and 3 returned OK (32-byte section in `default1.xsdat`). The live run found a `0\profile` folder (non-Steam) beside the real one, so auto-detect now ignores `0` when a Steam id folder exists. Not exercised live: adopting the id already in the file at startup (it needs a relaunch with a request file present).
