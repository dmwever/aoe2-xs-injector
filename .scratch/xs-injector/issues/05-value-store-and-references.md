# Value store and references

**Type:** grilling
**Status:** resolved
**Blocked by:** none

## Question

How are results stored and fed back into later calls?

- Per-type arrays (`injectionIntArray`, `injectionStringArray`, float, vector, bool-as-int) and the `currentInjected*` registers: which are kept, and what "reset the others to default" means.
- How an argument says "literal value" versus "result #n of type T" versus "current register".
- Store lifetime: per request, per match, or an explicit clear call.
- Which results go into the response: every call, or only marked ones.

## Answer

Grilled 2026-11-10. Terms in `GLOSSARY.md` (Call, Result slot, Literal argument, Reference argument).

- **Store**: five typed arrays (int, float, bool, string, vector) sharing one index. Call #n's result goes in the array of its return type at index n. No `currentInjected*` registers, so "reset the others to default" is moot.
- **Arguments**: an int tag precedes each argument. `0` = literal, value follows encoded as the parameter's declared type. `1` = reference, an int call number follows. The referenced call's return type must match the parameter, else error.
- **Lifetime**: per request. Call numbers restart at 0 and slots are cleared before each request. A reference may only point at an earlier call in the same request; forward and self references are errors. A value needed by a later request comes back in the response and is re-sent as a literal.
- **Response**: one entry per call, in call order. Non-void calls carry their value; void calls carry an empty entry.
- **Bool**: the store uses a native bool array (`xsArrayCreateBool`), but the catalog has no `xsWriteBool` / `xsReadBool`, so bool crosses the wire as int in both directions.

Handed on, not decided here: the bytes of an empty entry ([Response coexistence](04-response-coexistence.md)); the store's size cap ([Live file I/O spike](08-live-file-io-spike.md), item 9); how type mismatches and bad references are reported (map fog, Error reporting).
