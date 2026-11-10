# Function catalog

**Type:** grilling
**Status:** resolved
**Blocked by:** 05-value-store-and-references.md

## Question

Which XS functions get an injector id, and how is the dispatch `switch` produced?

- Generated from `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json` versus written by hand.
- Id stability across game updates and catalog rebuilds (renames such as `xsGetLocalPlayerId` -> `xsUnsyncGetLocalPlayerId`).
- Whether side-effecting functions (effects, unit changes) and `xsUnsync*` functions are allowed.
- Functions whose parameters the encoding can't express. Void functions are allowed: they get an empty response entry and can't be referenced ([Value store and references](05-value-store-and-references.md)).

## Rulings

- 2026-11-10: Dispatch is generated from `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json`, not hand-written and not scraped from ugc.aoe2.rocks. The catalog matches the UGC page on all 274 shared prototypes but lacks UGC's 15 Network-section functions; the catalog is brought level with UGC (a fix in AoE2_AI_Modder) before the dispatch is generated.
- 2026-11-10: Every catalog function gets an id. No exclusions: File IO, `xsUnsync*` and side-effecting functions are all dispatchable.
- 2026-11-10: Ids come from a pinned name-to-id table checked into this repo. New functions take the next free id; ids are never reused; a rename in `AoE2_AI_Modder/docs/agent_database/xs_renames.json` keeps its id; a removed function's id is retired. The generator fails when a pinned function leaves the catalog without a rename entry.
- 2026-11-10: Each call carries an int argument count, from `min_param_count` to `param_count`. The generated case has one XS call site per allowed count so XS applies its own defaults; the catalog records none.
- 2026-11-10: A Python generator in this repo reads the catalog, `xs_renames.json` and the pinned table, and writes the dispatch and the table. The core XS module is hand-written and includes the generated dispatch file; both are checked in, and a host includes the core alone. The driver reads the same pinned table to map names to ids.

## Answer

Grilled 2026-11-10. Terms in `GLOSSARY.md` (Function id, Driver). The Rulings above are the decisions; in short:

- **Source**: the dispatch is generated from `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json`. It matches ugc.aoe2.rocks on all 274 shared prototypes but lacks UGC's 15 Network functions; the catalog is levelled with UGC (an AoE2_AI_Modder fix) before generation, giving 289.
- **Coverage**: every catalog function gets an id, File IO, `xsUnsync*` and side-effecting ones included.
- **Ids**: a pinned name-to-id table in this repo; next free id for new functions, never reused, renames keep their id via `xs_renames.json`, removed ids retired, generator fails on an unexplained removal.
- **Optional parameters**: each call carries an int argument count in `min_param_count..param_count`; the generated case has one call site per allowed count, so XS applies its own defaults (the catalog records none).
- **Layout**: a Python generator writes the dispatch file and the table; a hand-written core includes the dispatch; both are checked in; a host includes the core alone; the driver reads the same table.
- **Inexpressible parameters**: none. Every catalog type is int, float, bool, string, vector or void.

Handed on: injected File IO calls and `xsDisableSelf` can break a request mid-read ([Request format](03-request-format.md)); whether a ~289-case switch with several call sites per case compiles ([Live file I/O spike](08-live-file-io-spike.md), item 10); an out-of-range argument count (map fog, Error reporting).
