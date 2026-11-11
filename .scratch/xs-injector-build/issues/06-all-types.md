# 06: All literal and return types

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent can pass and receive every XS value type: int, float, string, vector and bool. Void calls appear as entries with no value, so call numbers stay aligned. The agent can inspect the exact request bytes with `encode`.

**Blocked by:** 05: Run one int call

**Status:** resolved

- [x] Literals are plain JSON (float, string, `true`/`false` sent as int, vector `[x, y, z]`), encoded as the parameter's declared XS type (strings as uint32 length + raw bytes)
- [x] Driver rejects a literal whose JSON type does not fit the parameter with `Invalid`
- [x] Module parses each literal type, checking every string length against the remaining file size before reading it
- [x] Results are stored in the five typed arrays (bool native internally) and written by return type; bool crosses the wire as int
- [x] A void OK entry is the status int alone
- [x] Driver decodes vectors as `[x, y, z]` and bools as `true`/`false`
- [x] `encode <file|->` prints the request bytes to stdout without sending
- [x] Driver-seam tests cover each literal type's validation and encoding, each return type's decoding, void entries, and `encode`
- [x] Live: one call per return type and one void call return the expected entries; a UTF-8 string round-trips byte-exact

## Comments

- 2026-11-11: Implemented. Driver: literals validated per declared parameter type (int: 32-bit int; float: any finite JSON number that fits a 32-bit float; bool: only `true`/`false`; string: any JSON string, sent as uint32 byte length + UTF-8; vector: exactly three finite numbers), `Invalid` naming call and argument otherwise. Entries decode by return type: floats to their shortest float32 spelling (0.1, not 0.100000001), vectors `[x, y, z]`, bools `true`/`false`, strings UTF-8 (invalid bytes replaced, so the result stays printable). `encode <file|->` writes raw request bytes to stdout using the next id from the profile's request file (1 when no profile resolves); API `encode(calls, profile=None)` picks the id the same way and raises `InvalidRequest` (its `.result` is the Invalid result). Module: parses every literal type, peeking each string length and checking it against the remaining size before `xsReadString`; the int-only return guard is gone; results are written by return type, bool as int. 121 tests pass.
- 2026-11-11: Engine fact found live: `xsArrayResizeVector` returns false and leaves the array unchanged in this build (float, string and bool resizes work). Vector staging and result arrays only had index 0, so vectors worked only as the first vector argument and on call #0. The core now grows vector arrays by replacing them with a bigger one (at least doubling). Worth reporting to UGC.
- 2026-11-11: The response body length is now measured with `xsGetFilePosition()` around the body write (a string's byte length isn't knowable in XS). Verified live in standalone mode; host mode (08) should measure the same way.
- 2026-11-11: Live check passed (XsTesting editor test-play, standalone). Request 21: `bitAnd(12,10)`=8, `xsVectorGetX([1.5,2,3])`=1.5, `xsVectorLength([3,4,0])`=5.0, `xsVectorSet(1,2.5,-3)`=[1.0,2.5,-3.0], `xsIsRuleEnabled("xsInjectRequestRule")`=true, `xsGetMapName(false)`="default1", `strTrim("  Ça ✓ 日本  ")`="Ça ✓ 日本" (bytes `c3 87 61 20 e2 9c 93 20 e6 97 a5 e6 9c ac` in the section), `xsChatData(...)` void entry with no value, `xsGetMapWidth()`=120. Request 20: 12 `xsVectorSet` + 12 `xsVectorGetZ` calls (vector arrays grown several times) all correct; `fstr("ünï ✓ 日本 €")` round-tripped exactly. Request 22 (crafted bytes): a string length of 1,000,000 with 3 bytes left gave `Truncated` at call #0, argument #0, 0 entries, and the module kept answering.
- 2026-11-11: Review fixes: a JSON int too big for a double (e.g. `10**400`) on a float or vector parameter crashed validation with `OverflowError`; it is now `Invalid` (the float32 fit check moved into `wire`). `driver.encode` takes `profile=` like the CLI, so the API and CLI match. Stale `wire.py` docstring fixed. Judgement calls kept: non-UTF-8 string bytes decode with replacement characters so the result JSON stays printable (strings are raw bytes on the wire, but JSON output needs text); floats print as their shortest float32 spelling; replaced vector arrays are abandoned, not freed (XS can't free arrays). Deferred: one per-type table for the driver's check/encode/decode cascades.
