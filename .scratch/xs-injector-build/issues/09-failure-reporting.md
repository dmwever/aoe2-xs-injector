# 09: Failure reporting

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** When a request is malformed, a call kills the rule, or a response arrives late, the agent learns exactly what happened from the driver: a specific status, which call and argument failed, a rendered message, and a way to recover a late response.

**Blocked by:** 07: References; 08: Optional arguments

**Status:** resolved

- [x] Module reports the first parse failure with status 2 Truncated, 3 UnknownFunction, 4 BadArgCount, 5 BadTag, 6 BadReference, 7 ReferenceTypeMismatch or 9 TrailingBytes, plus failed call # and failed argument # (-1 when n/a), with 0 entries; nothing runs; the id stays seen
- [x] Before call #0 the module stores a Running response with 0 entries (standalone writes it); if the rule dies mid-request the response stays Running
- [x] Driver reports `Timeout` with `diagnosis` `stuck-running` when the response stays Running
- [x] Entry status `1` NotRun is defined and decoded, but no path produces it
- [x] Driver renders a message for every wire code from the request it sent
- [x] `fetch` decodes the current response against `xsinject.last.json` without sending anything
- [x] Driver-seam tests decode a fixture for each code and for Running, and cover `fetch`
- [ ] Live: crafted request bytes (bypassing driver validation) produce each parse-failure code; a rule-killing call gives `Timeout/stuck-running`; a deliberately short timeout followed by `fetch` recovers the response

## Answer

2026-11-11. The module side (parse codes with failed call/argument, id seen before parsing, Running stored before call #0) had already landed with earlier slices. This slice adds the driver side and the proof.

- Driver: `_failure_message` renders every non-OK wire code from the request sent, as `<Status> at call #N (fn), argument #K (param = value): <why>`. A reference shows as `{"ref": N}`. A location outside the request sent is still reported by number, and an unknown code comes back as `Unknown(n)`. For statuses the driver's validation blocks, the message points to a stale core (re-include). Truncated, BadTag and TrailingBytes also say that a literal the module reads as another type causes them, since a mis-typed literal can only surface that way.
- `fetch` (API `xsinject.fetch`, CLI `xsinject fetch`) re-validates `xsinject.last.json` and waits like `run`, but accepts any section echoing the last id, however old. It sends nothing. Missing or unreadable `last.json` gives `Invalid`. A section still Running gives `Timeout/stuck-running`, and a section for another id gives `older-id`.
- Driver seam: `tests/test_failure_reporting.py` covers a fixture per code 2-9, an unknown code, a NotRun entry, Running → `Timeout/stuck-running`, and `fetch` (late recovery, nothing sent, Invalid, stuck-running, older-id, rendered failure, CLI exit codes).
- Live (requests 44-55, XsTesting): crafted bytes produced Truncated, UnknownFunction, BadArgCount, BadTag, BadReference, ReferenceTypeMismatch and TrailingBytes, each with the right call/argument and 0 entries. A 0.05 s `run` timed out (`older-id`), and `fetch` then recovered its OK response.
- **Not met: a live rule-killing call.** `xsArrayGetInt(0, 1000000)` returns -1, while `xsEnableRule("xsInjectNoSuchRule")` and `xsBreakPoint()` return normally. None stops the rule, so `Timeout/stuck-running` is proven at the driver seam only. The module stayed live afterwards (ping 56 OK).
