# 07: References

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent chains calls in one request by passing `{"ref": N}` as an argument, so call N's result feeds a later call without a round trip.

**Blocked by:** 06: All literal and return types

**Status:** resolved

- [x] Driver encodes a reference as tag 1 plus the call number
- [x] Result slots are cleared before each request; call numbers restart at 0 per request
- [x] Driver rejects with `Invalid`: a forward, self or out-of-range reference, a reference to a void call, and a reference whose return type does not match the parameter
- [x] Module resolves a reference from the referenced call's slot at run time, and checks it at parse time as a backstop
- [x] Driver-seam tests cover every reference validation case and the encoding
- [x] Live: a chained request (get a value, then pass it to a second function) returns the expected result; a value from one request is not visible to the next

## Comments

- 2026-11-11: Implemented. Driver: an argument that is a JSON object with a `"ref"` key is a reference (any other object is still judged as a literal). It must be exactly `{"ref": <int>}`, and the int must name an earlier call: self, forward, negative and past-the-end references are `Invalid` with distinct messages, as are references to a void call and to a call whose return type is not exactly the parameter's type (no int/float/bool coercion). A valid reference is encoded as tag 1 plus the call number (`wire.Ref`). Module: tag 1 is parsed with a size check (`Truncated` when the call number is missing), checked against earlier calls only (`BadReference`) and the referenced function's return type (`ReferenceTypeMismatch`; a void target lands here too), and staged per argument in `gXsInjectArgRef`. At run time each reference copies the referenced call's result slot into the argument slot just before its call dispatches; result slots for the request's calls are cleared before call #0. The generated dispatch is unchanged. 140 tests pass.
- 2026-11-11: Live check passed (XsTesting editor test-play, standalone). Request 26 chained every type: `xsGetMapWidth()`=120 -> `bitAnd(ref0,255)`=120; `xsVectorSet(3,4,0)` -> `xsVectorLength(ref2)`=5.0, `xsVectorGetX(ref2)`=3.0; `xsGetMapName(false)`="default1" -> `strTrim(ref5)`="default1"; `xsIsRuleEnabled(...)`=true -> `xsGetMapName(ref7)`="default1.aoe2scenario" (same as the literal `true` call); a void entry; `xsVectorSet(ref3, ref4, 7.5)`=[5,3,7.5]. Crafted bytes: forward ref to call #1 right after request 26 (whose call #1 held 120) -> `BadReference` at call 0 arg 0, so nothing from the previous request is reachable; self ref -> `BadReference`; ref to a void call and int-into-vector -> `ReferenceTypeMismatch` at call 1 arg 0; ref tag with no call number -> `Truncated`. The module kept answering (ping OK after).
