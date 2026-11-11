# 03: Generator: pinned ids, signatures.json, dispatch

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** The maintainer runs the generator over the KB function catalog, the KB renames file and the pinned name-to-id table, and gets a checked-in `signatures.json`, an updated pinned table, and a generated XS dispatch (with its per-function parameter-type table) that the core module will include. Id stability is enforced at generation time.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] `signatures.json` holds, per function: name, function id, parameter types, argument-count range (`min_param_count..param_count`), return type
- [x] Every catalog function gets an id, File IO, `xsUnsync*` and side-effecting functions included
- [x] New functions take the next free id; ids are never reused; a rename listed in the renames file keeps its id; a removed function's id is retired
- [x] The generator fails, naming the function, when a pinned function leaves the catalog without a rename entry
- [x] The dispatch has one case per function id and one XS call site per allowed argument count, so XS applies its own defaults; arguments come from the staged typed values; non-void results go to the result slot of the function's return type at the call's index
- [x] The generator emits the parameter-type table the module's parser uses
- [x] Generator-seam tests on small fixture catalogs cover each id rule, the failure on an unexplained removal, and call sites per argument count

## Rulings

- 2026-11-11: The toolkit is standalone: nothing outside this repo is required. The KB catalog and renames file were copied once into `catalog/functions.json` and `catalog/renames.json`, which this repo now owns; the generator reads only those. Signature corrections and the UGC levelling land in `catalog/functions.json`, not in AoE2_AI_Modder (reporting them upstream is optional courtesy). xs-check stays an optional dev aid; nothing requires it.
- 2026-11-11: Deprecated functions are retired, not dispatched. `xsTask` (id 114) and `xsRemoveTask` (id 115) are marked "Deprecated. Use xsModifyObjectTasks instead." on ugc.aoe2.rocks (the only two it marks) and are retired with `--retire`, though the KB catalog still lists them. This narrows the spec's "every catalog function gets an id": `retired` in `function_ids.json` is a lasting exclusion list, and a retired name gets no id even while the catalog lists it. Ids are still never reused.

## Comments

- 2026-11-11: Implemented. `python -m xsinject.generate` (inputs: `catalog/functions.json`, `catalog/renames.json`) writes `xsinject/signatures.json`, `xsinject/function_ids.json` and `xs/xsinject_dispatch.xs`; 274 catalog functions, 2 retired, 272 dispatched, 366 call sites, xs-check lint clean with no warnings. A removal is acknowledged with `--retire NAME`; without it the generator fails naming the function. A retired name stays excluded even while the catalog lists it (see Rulings). The dispatch declares the ten `extern` argument/result array handles (XS globals are file-private) and exposes `xsInjectSignaturesInit`, `xsInjectKnownFunction`, `xsInjectMinArgs`/`MaxArgs`/`ReturnType`/`ParamType` and `xsInjectDispatch(fid, argc, argBase, slot)` for the core (ticket 05). Note: the dispatch still carries the uncorrected `xsIsRuleGroupEnabled` and `xsFlashUnit` signatures, so the core can't include it until ticket 04 lands those fixes in `catalog/functions.json`.
