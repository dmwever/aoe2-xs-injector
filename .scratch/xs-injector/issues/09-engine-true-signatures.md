# Engine-true signatures

**Type:** grilling
**Status:** resolved
**Blocked by:** none

## Question

The dispatch is generated from the KB catalog ([Function catalog](06-function-catalog.md)), but the catalog's signatures do not match the engine. The [Live file I/O spike](08-live-file-io-spike.md) hit three mismatches in the first 171 functions: `xsIsRuleGroupEnabled` is void, `xsFlashUnit`'s `soundName` is not int, and `xsBuildUnit`'s three-argument form fails for an unstated reason. xs-check shares the catalog's errors, and the engine reports only the first compile error per launch, sometimes with no message.

Where do engine-true return and parameter types come from, and where do the corrections live?

- How the remaining unverified functions (catalog ids 170-273, plus UGC's 15 Network functions once levelled) get checked against the engine: one launch per error, a sweep harness that bisects, a probe per function, or another source of signatures.
- Where a correction lives: fixed upstream in `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json` (and reported to UGC/xs-check), or an override table in this repo that the generator applies.
- What the generator does with a function it cannot verify: emit it, or leave it out until verified.

## Rulings

- 2026-11-10: Signatures are checked against the engine by fix-and-relaunch on the generated dispatch itself: the maintainer test-plays it, the line the engine names is corrected, the dispatch is regenerated, repeat until it compiles. A separate probe file is written only for an error the engine reports without a message (as `xsBuildUnit` did), trying each variant in turn.
- 2026-11-10: Corrections are made in `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json` itself, each corrected entry marked with its source, and reported to UGC and xs-check. No override table in this repo.
- 2026-11-10: A clean engine compile of the whole dispatch is the bar for "verified". No runtime type probe.
- 2026-11-10: The generator emits every catalog function; no per-function verified flag. A clean engine compile of the generated dispatch is a handoff gate, repeated whenever a catalog update adds or changes functions.

## Answer

Grilled 2026-11-10. The Rulings above are the decisions; in short:

- **How**: fix-and-relaunch on the real dispatch. The engine reports the first error with its line, so the cost is one launch per wrong signature, not per function. Probe files only for message-less errors.
- **Where**: fixed in the KB catalog (one source of truth), marked, and reported upstream. The known three (`xsIsRuleGroupEnabled` void, `xsFlashUnit` `soundName` string, `xsBuildUnit` pending its probe) land there too.
- **Bar**: a clean compile. Accepted risk: a type XS converts silently (e.g. int↔float on assignment) can still be catalogued wrong and carry the wrong type tag in the response.
- **Unverified**: never ships. Everything is emitted; the clean compile gates handoff.

Handed on: the checking run itself is execution, a handoff prerequisite alongside levelling the catalog (map Notes).
