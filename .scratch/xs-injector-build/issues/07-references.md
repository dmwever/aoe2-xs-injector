# 07: References

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent chains calls in one request by passing `{"ref": N}` as an argument, so call N's result feeds a later call without a round trip.

**Blocked by:** 06: All literal and return types

**Status:** ready-for-agent

- [ ] Driver encodes a reference as tag 1 plus the call number
- [ ] Result slots are cleared before each request; call numbers restart at 0 per request
- [ ] Driver rejects with `Invalid`: a forward, self or out-of-range reference, a reference to a void call, and a reference whose return type does not match the parameter
- [ ] Module resolves a reference from the referenced call's slot at run time, and checks it at parse time as a backstop
- [ ] Driver-seam tests cover every reference validation case and the encoding
- [ ] Live: a chained request (get a value, then pass it to a second function) returns the expected result; a value from one request is not visible to the next
