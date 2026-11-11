# 04: Engine-true catalog: level with UGC, clean compile

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** The repo's function catalog (`catalog/functions.json`) is brought level with ugc.aoe2.rocks and corrected until the whole generated dispatch compiles in the engine. This is the handoff gate the spec names: no live call can run until the dispatch the core includes compiles. HITL: the maintainer runs the launches.

**Blocked by:** 03: Generator: pinned ids, signatures.json, dispatch

**Status:** resolved

- [x] `catalog/functions.json` gains UGC's 15 Network-section functions (289 in total, less the retired `xsTask`/`xsRemoveTask`)
- [x] Fix-and-relaunch: the maintainer test-plays a scenario including the generated dispatch; the line the engine names is corrected in `catalog/functions.json` and the dispatch regenerated, repeated until a clean compile
- [x] A separate probe is written only for an error the engine reports without a message (as `xsBuildUnit(int, int, vector)` did), trying each variant
- [x] Known corrections land: `xsIsRuleGroupEnabled` is void; `xsFlashUnit`'s `soundName` is string; `xsBuildUnit` per its probe
- [x] Each corrected catalog entry is marked with its source
- [x] No override table in this repo; the regenerated `signatures.json`, pinned table and dispatch are checked in
- [x] Evidence of the clean compile is recorded on this ticket

## Rulings

- 2026-11-11: The toolkit is standalone: nothing outside this repo is required. The KB catalog and renames file were copied once into `catalog/functions.json` and `catalog/renames.json`, which this repo now owns; the generator reads only those. Signature corrections and the UGC levelling land in `catalog/functions.json`, not in AoE2_AI_Modder (reporting them upstream is optional courtesy). xs-check stays an optional dev aid; nothing requires it.
- 2026-11-11: AI-script-only functions are retired, not dispatched. `xsGetGoal` (232), `xsSetGoal` (234), `xsGetStrategicNumber` (233) and `xsSetStrategicNumber` (235) don't exist in scenario XS ("xsGetGoal is not a valid operator"). They are retired with `--retire` like `xsTask`/`xsRemoveTask` and stay in `catalog/functions.json`, which remains level with UGC. The game exe lists exactly these four in their own syscall block, apart from the scenario syscalls. The other AI-category functions (`xsGetAiSignal`, `xsSetAiSignal`, `xsGetAiScriptGoal`, `xsSetAiScriptGoal`) are listed with the scenario syscalls and stay dispatched.

## Comments

- 2026-11-11: Catalog levelled and the known corrections applied; the engine launch is still to do.
  - The 15 UGC Network-section functions (`xsResetNetData` .. `xsUnsyncIsSandboxMode`, category `network`) were appended to `catalog/functions.json` from ugc.aoe2.rocks section 17, fetched 2026-11-11. UGC lists 289 functions and the catalog now matches them name for name. Each new entry has a `source` field.
  - `xsIsRuleGroupEnabled` is now void and `xsFlashUnit`'s `soundName` is now string. Both entries have a `source` field citing spike run B.
  - `xsBuildUnit` is unchanged. A probe is only written if the engine reports it again without a message. Spike run B's line 1019 doesn't clearly map to `xsBuildUnit` in today's numbering, so the full dispatch is launched first.
  - Regenerated: 287 functions dispatched (289 less the retired `xsTask`/`xsRemoveTask`). New ids are 274..288; ids 114/115 stay retired.
  - New compile gate: `xs/XsInjectDispatchCheck.xs` includes the dispatch and calls `xsInjectSignaturesInit()`. It is deployed as `Test.xs` (XsTesting scenario) together with `xsinject_dispatch.xs`.
  - xs-check isn't a usable gate here: it doesn't know the Network functions and still has the old `xsFlashUnit` signature. The engine is the gate.
  - `tests/test_checked_in_outputs.py` guards that the checked-in outputs match a fresh regeneration and carry the corrections.
- 2026-11-11: Launch 1 of the full dispatch failed at line 1813, `xsBuildUnit(int, int, vector)` stored as bool: "expression type does not match expected type". Probe `.scratch/xs-injector-build/probes/xsBuildUnit.xs` failed at line 17. The 3-arg and 6-arg calls as bare statements compiled (so all six parameter types are right), `int r = xsBuildUnit(...)` compiled, and `bool b = xsBuildUnit(...)` failed. Corrected: `xsBuildUnit` returns int, marked with its source. Regenerated and redeployed `XsInjectDispatchCheck.xs` for launch 2.
  - Hint, not evidence: the game exe embeds a help signature for 268 of the 289 functions. It confirms `void xsIsRuleGroupEnabled` and `xsFlashUnit(int, int, string)`, but it still says `bool xsBuildUnit`, and it lists vector setters as float. So it's stale in places and only a lead. It says `xsTaskUnits` is void (the catalog says bool); that call site comes right after `xsBuildUnit`.
- 2026-11-11: Launch 2 failed at line 1827, `xsTaskUnits(int, int)` stored as bool: "expression type does not match expected type". This is the same message `xsBuildUnit` gave, not the void message, so the exe's `void` hint is wrong. Corrected to return int, marked with its source; launch 3 confirms it. If line 1827 fails again, probe it like `xsBuildUnit`.
- 2026-11-11: Launch 3 failed at line 1827 again, `xsTaskUnits` stored as int: "void syscall/function cannot be called here". Corrected to void (the exe's hint was right). Lesson: a void call stored as bool reports "expression type does not match expected type", not the void message. So that message does not rule out void; the `xsBuildUnit` probe was needed to tell int from void.
- 2026-11-11: Launch 4 got past `xsTaskUnits` (void confirmed) and failed at line 2264: "xsGetGoal is not a valid operator". The signature was fine. Per the ruling above, the four AI-script-only functions are retired. Regenerated: 283 functions dispatched, 6 retired. Redeployed for launch 5.
- 2026-11-11: **Clean compile.** Launch 5: the maintainer test-played XsTesting with `Test.xs` = `xs/XsInjectDispatchCheck.xs` and the generated `xsinject_dispatch.xs` (283 dispatched functions, 6 retired). There was no XS error and chat showed `xsinject dispatch compiled`. Five launches plus one probe in total. Engine corrections in `catalog/functions.json`, each with a `source` field: `xsIsRuleGroupEnabled` → void, `xsFlashUnit` `soundName` → string, `xsBuildUnit` → int, `xsTaskUnits` → void. Retired as AI-script-only: `xsGetGoal`, `xsSetGoal`, `xsGetStrategicNumber`, `xsSetStrategicNumber`. Re-run this gate after every catalog change.
- 2026-11-11: After review: each retired entry in `xsinject/function_ids.json` now records why, as `{"id", "reason"}`. `--retire` takes `NAME REASON` and refuses an empty reason. The six existing retirements were migrated with their reasons. `xsIsRuleGroupEnabled`'s stale "Returns true" desc was fixed. The "level with UGC" test was dropped, because nothing contacts UGC, so it only pinned a count. The regenerated dispatch is byte-identical to the launch-5 copy, so the clean compile still holds.
