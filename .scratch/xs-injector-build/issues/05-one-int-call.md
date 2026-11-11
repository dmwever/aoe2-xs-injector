# 05: Run one int call

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent runs a JSON request (`{"fn": <name>, "args": [...]}`) naming an int-returning function with int literals, and gets back an OK entry with the returned value. This connects the driver, the call layout, the parser, the generated dispatch and response entries end to end.

**Blocked by:** 02: Ping end to end, standalone; 04: Engine-true catalog: level with UGC, clean compile

**Status:** resolved

- [x] The core module includes the generated dispatch
- [x] Module parses each call (function id, argument count, then per argument a tag, 0 = literal, and an int literal); the whole request is staged and the file closed before any call runs
- [x] Module runs each call through the dispatch and writes one entry per call in call order: status OK followed by the value
- [x] A return of -1 or false is a value, not a failure; every call in a request runs
- [x] Driver reads `signatures.json`, rejects an unknown name or an out-of-range argument count with `Invalid` before sending anything, and encodes the binary request
- [x] Driver decodes entries by the return types of the request it sent and renders `message`; the result shape is `{request_id, status, failed_call, failed_argument, message, entries: [{call, fn, status, value}]}`
- [x] `run` accepts a file or stdin
- [x] Driver-seam tests cover the `Invalid` cases, encoding, and decoding fixture responses with int entries
- [x] Live: a multi-call request of int functions returns the expected values, including one whose legitimate answer is -1

## Comments

- 2026-11-11: Implemented. Driver: `run(calls)` API (was `send`) and `run <file|->` CLI; validation against `signatures.json` gives `Invalid` with `failed_call`/`failed_argument` before anything is written; int literals encoded as tag 0; entries decoded by the sent return types; failure `message` names the function at the failed call. Module: the core includes the dispatch, stages the whole request (staging sized by file size, every read bounded), closes the file, then dispatches each call and writes OK entries with int values. 79 tests pass.
- 2026-11-11: Interim limits until 06: the driver accepts only int parameters and int returns (`Invalid` otherwise); the module answers `BadTag` for a non-int parameter and `UnknownFunction` for a return type other than int or void (refused at parse time, so it never runs). Judgement call: new driver status `Undecodable` when an OK response doesn't fit the calls sent (likely a stale core).
- 2026-11-11: First launch failed: "cXsInjectTypeInt is not a valid operator" at xsinject.xs line 158. XS consts and globals are private to their file unless `extern`; the generator now declares every top-level const and global in the dispatch `extern` (generator test enforces it). xs-check does not catch this.
- 2026-11-11: Live check passed (XsTesting editor test-play, standalone). Request 4: `bitAnd(12,10)`=8, `xsGetUnitOwner(999999)`=-1, `bitOr(-8,3)`=-5, `xsGetMapWidth()`=120. Ping (5) OK; stdin run (6) `bitXor(5,3)`=6, `xsGetMapHeight()`=120; a wrong argument count returned `Invalid` without sending.
- 2026-11-11: Review fixes: the module refuses non-int, non-void returns at parse time (was: ran them and wrote a malformed entry); the CLI closes the request file and builds `Invalid` through `driver.invalid`. Deferred to 07: clearing result slots before each request.
- 2026-11-11: Live check of the return-type guard passed (crafted bytes, which the driver would refuse): request 10 `xsArrayGetFloat(0,0)` → `UnknownFunction` at call #0, 0 entries; request 11 `bitAnd` then `xsArrayGetFloat` → `UnknownFunction` at call #1, 0 entries; control request 12 `bitAnd(12,10)` → OK, 8.
