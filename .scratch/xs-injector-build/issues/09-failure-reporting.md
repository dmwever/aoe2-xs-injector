# 09: Failure reporting

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** When a request is malformed, a call kills the rule, or a response arrives late, the agent learns exactly what happened from the driver: a specific status, which call and argument failed, a rendered message, and a way to recover a late response.

**Blocked by:** 07: References; 08: Optional arguments

**Status:** ready-for-agent

- [ ] Module reports the first parse failure with status 2 Truncated, 3 UnknownFunction, 4 BadArgCount, 5 BadTag, 6 BadReference, 7 ReferenceTypeMismatch or 9 TrailingBytes, plus failed call # and failed argument # (-1 when n/a), with 0 entries; nothing runs; the id stays seen
- [ ] Before call #0 the module stores a Running response with 0 entries (standalone writes it); if the rule dies mid-request the response stays Running
- [ ] Driver reports `Timeout` with `diagnosis` `stuck-running` when the response stays Running
- [ ] Entry status `1` NotRun is defined and decoded, but no path produces it
- [ ] Driver renders a message for every wire code from the request it sent
- [ ] `fetch` decodes the current response against `xsinject.last.json` without sending anything
- [ ] Driver-seam tests decode a fixture for each code and for Running, and cover `fetch`
- [ ] Live: crafted request bytes (bypassing driver validation) produce each parse-failure code; a rule-killing call gives `Timeout/stuck-running`; a deliberately short timeout followed by `fetch` recovers the response
