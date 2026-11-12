# 12: Agent docs and xs-injector skill

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent that knows only the user-global `xs-injector` skill can drive the injector, wire it into a host, troubleshoot from the driver's output alone, and maintain the generated dispatch.

**Blocked by:** 09: Failure reporting; 11: Ageipelago wiring

**Status:** resolved

- [x] Four task docs in this repo's agent docs folder: `driving`, `hosting`, `troubleshooting`, `maintaining`
- [x] `driving` opens with the human checklist (start the match or editor test-play, keep it unpaused, confirm the host opt-in is uncommented), then covers the CLI commands, the JSON request and result shapes, and the wire and driver statuses; it says `Invalid` catches name, count and type mistakes before sending, and lists no functions
- [x] `hosting` covers the standalone include, the host opt-in, and the Ageipelago recipe verbatim as its source of truth; links to the re-include rule; warns that a host writing the file without opting in wipes responses; documents `xsDisableSelf` and injected File IO as foot-guns
- [x] `troubleshooting` is one table keyed by driver output -> likely cause -> fix, with rows for `Timeout/no-section`, `Timeout/older-id` (paused game as its own line), `Timeout/stuck-running`, `FileHeld`, `Invalid`, wire codes 2-9 and TooLarge
- [x] `maintaining` covers regenerating, fix-and-relaunch, KB corrections and upstream reports, and states the re-include rule and the silent-misread risk in full
- [x] The user-global skill triggers on injector words, routes into the docs, repeats the re-include rule as one hard rule, and tells agents to ask humans only for the checklist items
- [x] The `ageipelago` and `aoe2-modding` skills each get a one-line pointer
- [x] Check: a fresh agent given only the skill runs a ping and a chained request, and resolves a `Timeout/no-section` from the table

## Answer

2026-11-11. Docs in `docs/agents/`: `driving.md`, `hosting.md` (the Ageipelago recipe, at the path `AP.xs` points to), `troubleshooting.md` and `maintaining.md`. The skill lives in `docs/agents/skill/SKILL.md` and is installed at `~/.claude/skills/xs-injector/SKILL.md`; recopy it after any edit. Pointers: one row in Ageipelago `docs/agent/SKILL.md` "Where to look" (mirror recopied to `~/.claude/skills/ageipelago`), and one "Live calls" line in `~/.claude/skills/aoe2-modding/SKILL.md`. `tests/test_agent_docs.py` checks that the troubleshooting table has a row for every status the driver prints (wire codes from `wire.REQUEST_STATUS`), that a paused game has its own `older-id` row, that `driving.md` covers every CLI subcommand, that the recipe lines are in `hosting.md`, and that the skill routes to all four docs.

Beyond the spec, the table also has rows for the driver statuses `Ambiguous` and `Undecodable`.

**Check, simulated only:** a fresh agent given only the skill drove a fake game, a script standing in for the module that answered once `MATCH_STARTED` existed. It got `Timeout/no-section`, resolved it from the table's first row, then ran ping OK and a chained request OK. It found that the skill's quick-start example was `Invalid` (`strLen` given a reference to an int). That is fixed, along with the doc gaps it reported. **Live (2026-11-12, XsTesting editor test-play as the host, `xs/XsInjectHostTest.xs` with a current core):** a fresh agent given only the skill pinged with `--map XsTesting` (the scenario's name, a natural guess) and got `Timeout/no-section` (request 64). It resolved this from the row "`--map` names a file the game doesn't write" (editor test-play is `default1`). `ping --map default1` was then OK (65). The chained request `xsGetMapWidth` -> `bitRsh({"ref": 0}, 1)` was OK with 120 and 60 (66). Doc fixes from that run:
- `driving.md` says to leave `--map` off by default.
- The `no-section` first checks now start with a wrong `--map` and say how to tell which file is fresh.
- The pure-function hint is narrowed.

Follow-up, filed as [13](13-map-no-section-message.md): with `--map`, the `no-section` message still says "no .xsdat in the profile folder carries a response section", even when another file does. If the named file is missing, the driver could say so.

## Comments

2026-11-11, agent (from ticket 11): Ageipelago's commented-out wiring points at `aoe2-xs-injector/docs/agents/hosting.md`, so the `hosting` doc must live at that path. Ageipelago's include line is `include "./xsinject.xs";`, the opt-in is the first statement of `InitAP()`, and the hook goes just before `AP_Write`'s `xsCloseFile()`.

2026-11-11, agent (from ticket 11's live run):
- When Ageipelago is the host, the driver needs `--map "<scenario xsdat stem>"`, for example `AP Attila the Hun_<player>_<tag>`.
- If the host stops writing (for example an unconfigured slot) while an older file is still on disk, the driver reports `Timeout/older-id`, not `no-section`. Give this its own troubleshooting row.
