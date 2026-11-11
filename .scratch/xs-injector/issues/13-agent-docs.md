# Agent docs

**Type:** grilling
**Status:** resolved
**Blocked by:** 12-driver.md

## Question

Where do the injector's agent docs live and what shape do they take for agentic use?

- Location and form: a `docs/agent/` guide, a recipe, a skill, or a mix.
- Must hold the Ageipelago enabling recipe (the commented-out `#include`, `xsInjectUseHostWriter()` call and hook call, verbatim) as the source of truth ([Response coexistence](04-response-coexistence.md)).
- Must map each liveness case to its fix: no section, an older id, stuck Running, and a paused game ([Error reporting](10-error-reporting.md)).
- Must document the driver CLI (`run`/`ping`/`fetch`/`encode`), the JSON request and result shapes, the driver statuses, and the fix for each `Timeout` diagnosis ([Driver](12-driver.md)).
- Must state the re-include rule: after regenerating the dispatch or changing the wire layout, re-include the core in every host, because nothing on the wire detects a mismatch and a stale core can misread a literal silently ([Wire-format versioning](11-wire-format-versioning.md)).

## Rulings

- 2026-11-10: The content lives in this repo under `docs/agent/`, next to the generator and driver it describes. A thin user-global skill `~/.claude/skills/xs-injector/SKILL.md` triggers on injector words (`xsinject`, injector, driver, `run`/`ping`/`fetch`, response section, calling an XS function live) and routes into those docs, the way `aoe2-modding` routes into the KB.
- 2026-11-10: Four files split by task: `driving.md` (CLI `run`/`ping`/`fetch`/`encode`, JSON request and result shapes, wire and driver statuses), `hosting.md` (standalone include, host opt-in, the Ageipelago recipe verbatim as its source of truth), `troubleshooting.md`, `maintaining.md` (regenerate `signatures.json` and the dispatch, fix-and-relaunch, catalog corrections to the KB and upstream, then re-include).
- 2026-11-10: `troubleshooting.md` is one table keyed by what the driver prints (`status`, plus `diagnosis` for `Timeout`) -> likely cause -> fix. Rows: `Timeout/no-section`, `Timeout/older-id` (with the paused game as its own line), `Timeout/stuck-running`, `FileHeld`, `Invalid`, wire codes 2-9 and TooLarge.
- 2026-11-10: The re-include rule (after regenerating the dispatch or changing the wire layout, re-include the core in every host; a stale core can misread a literal silently) is stated in full in `maintaining.md`, linked from `hosting.md`, and repeated as one hard rule in the skill.
- 2026-11-10: The `ageipelago` skill and `aoe2-modding` (beside its no-copy/paste rule) each get a one-line pointer to the xs-injector skill / `hosting.md`. No recipe text is duplicated.
- 2026-11-10: `driving.md` opens with the human's checklist: start the match or editor test-play, keep it unpaused, confirm the host opt-in is uncommented. The skill tells agents to ask for exactly those items and nothing else.
- 2026-11-10: The docs list no functions. Signature lookup stays in `signatures.json` and the KB catalog, and the docs say the driver's `Invalid` catches name, count and type mistakes before anything is sent.

## Answer

Grilled 2026-11-10. The decisions are the Rulings above. In short: the docs live in the repo under `docs/agent/` as four task files (driving, hosting, troubleshooting, maintaining), and a thin user-global `xs-injector` skill routes into them. Troubleshooting is one table keyed by driver output. The re-include rule appears in full once and is pointed to twice. The existing AoE2 skills get one-line pointers. A human checklist bounds what agents may ask for, and the docs carry no function reference. No new glossary terms.
