# 04: Engine-true catalog: level with UGC, clean compile

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** The KB function catalog is brought level with ugc.aoe2.rocks and corrected until the whole generated dispatch compiles in the engine. This is the handoff gate the spec names: no live call can run until the dispatch the core includes compiles. HITL: the maintainer runs the launches.

**Blocked by:** 03: Generator: pinned ids, signatures.json, dispatch

**Status:** ready-for-agent

- [ ] The KB catalog gains UGC's 15 Network-section functions (289 in total); this fix lands in the KB repo
- [ ] Fix-and-relaunch: the maintainer test-plays a scenario including the generated dispatch; the line the engine names is corrected in the KB catalog and the dispatch regenerated, repeated until a clean compile
- [ ] A separate probe is written only for an error the engine reports without a message (as `xsBuildUnit(int, int, vector)` did), trying each variant
- [ ] Known corrections land: `xsIsRuleGroupEnabled` is void; `xsFlashUnit`'s `soundName` is string; `xsBuildUnit` per its probe
- [ ] Each corrected catalog entry is marked with its source; corrections are reported to UGC and xs-check
- [ ] No override table in this repo; the regenerated `signatures.json`, pinned table and dispatch are checked in
- [ ] Evidence of the clean compile is recorded on this ticket
