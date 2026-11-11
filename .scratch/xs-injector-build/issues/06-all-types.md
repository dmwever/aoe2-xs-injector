# 06: All literal and return types

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent can pass and receive every XS value type: int, float, string, vector and bool. Void calls appear as entries with no value, so call numbers stay aligned. The agent can inspect the exact request bytes with `encode`.

**Blocked by:** 05: Run one int call

**Status:** ready-for-agent

- [ ] Literals are plain JSON (float, string, `true`/`false` sent as int, vector `[x, y, z]`), encoded as the parameter's declared XS type (strings as uint32 length + raw bytes)
- [ ] Driver rejects a literal whose JSON type does not fit the parameter with `Invalid`
- [ ] Module parses each literal type, checking every string length against the remaining file size before reading it
- [ ] Results are stored in the five typed arrays (bool native internally) and written by return type; bool crosses the wire as int
- [ ] A void OK entry is the status int alone
- [ ] Driver decodes vectors as `[x, y, z]` and bools as `true`/`false`
- [ ] `encode <file|->` prints the request bytes to stdout without sending
- [ ] Driver-seam tests cover each literal type's validation and encoding, each return type's decoding, void entries, and `encode`
- [ ] Live: one call per return type and one void call return the expected entries; a UTF-8 string round-trips byte-exact
