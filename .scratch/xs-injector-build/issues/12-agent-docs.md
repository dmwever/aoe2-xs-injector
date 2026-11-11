# 12: Agent docs and xs-injector skill

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent that knows only the user-global `xs-injector` skill can drive the injector, wire it into a host, troubleshoot from the driver's output alone, and maintain the generated dispatch.

**Blocked by:** 09: Failure reporting; 11: Ageipelago wiring

**Status:** ready-for-agent

- [ ] Four task docs in this repo's agent docs folder: `driving`, `hosting`, `troubleshooting`, `maintaining`
- [ ] `driving` opens with the human checklist (start the match or editor test-play, keep it unpaused, confirm the host opt-in is uncommented), then covers the CLI commands, the JSON request and result shapes, and the wire and driver statuses; it says `Invalid` catches name, count and type mistakes before sending, and lists no functions
- [ ] `hosting` covers the standalone include, the host opt-in, and the Ageipelago recipe verbatim as its source of truth; links to the re-include rule; warns that a host writing the file without opting in wipes responses; documents `xsDisableSelf` and injected File IO as foot-guns
- [ ] `troubleshooting` is one table keyed by driver output -> likely cause -> fix, with rows for `Timeout/no-section`, `Timeout/older-id` (paused game as its own line), `Timeout/stuck-running`, `FileHeld`, `Invalid`, wire codes 2-9 and TooLarge
- [ ] `maintaining` covers regenerating, fix-and-relaunch, KB corrections and upstream reports, and states the re-include rule and the silent-misread risk in full
- [ ] The user-global skill triggers on injector words, routes into the docs, repeats the re-include rule as one hard rule, and tells agents to ask humans only for the checklist items
- [ ] The `ageipelago` and `aoe2-modding` skills each get a one-line pointer
- [ ] Check: a fresh agent given only the skill runs a ping and a chained request, and resolves a `Timeout/no-section` from the table
