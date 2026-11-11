# 05: Run one int call

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent runs a JSON request (`{"fn": <name>, "args": [...]}`) naming an int-returning function with int literals, and gets back an OK entry with the returned value. This connects the driver, the call layout, the parser, the generated dispatch and response entries end to end.

**Blocked by:** 02: Ping end to end, standalone; 04: Engine-true catalog: level with UGC, clean compile

**Status:** ready-for-agent

- [ ] The core module includes the generated dispatch
- [ ] Module parses each call (function id, argument count, then per argument a tag, 0 = literal, and an int literal); the whole request is staged and the file closed before any call runs
- [ ] Module runs each call through the dispatch and writes one entry per call in call order: status OK followed by the value
- [ ] A return of -1 or false is a value, not a failure; every call in a request runs
- [ ] Driver reads `signatures.json`, rejects an unknown name or an out-of-range argument count with `Invalid` before sending anything, and encodes the binary request
- [ ] Driver decodes entries by the return types of the request it sent and renders `message`; the result shape is `{request_id, status, failed_call, failed_argument, message, entries: [{call, fn, status, value}]}`
- [ ] `run` accepts a file or stdin
- [ ] Driver-seam tests cover the `Invalid` cases, encoding, and decoding fixture responses with int entries
- [ ] Live: a multi-call request of int functions returns the expected values, including one whose legitimate answer is -1
