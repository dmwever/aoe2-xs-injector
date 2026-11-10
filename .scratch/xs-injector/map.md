# Map: XS function injector

**Label:** wayfinder:map

## Destination

A handoff-ready spec for a generic XS function injector: an includable XS module that reads function calls (integer function id + arguments) from an `.xsdat` request file during a live match, runs them, and writes typed results where an agent can read them with aoe2kit. Covers the XS module, the request/response wire format, the aoe2kit changes, and the agent docs. No implementation in this map.

## Notes

- Domain: AoE2:DE XS scripting + `.xsdat` file I/O + aoe2kit (`chrae/aoe2kit`, Go, LGPL-3.0; not cloned on this machine).
- Skills every session should consult: `aoe2-modding` (XS signatures come from `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json`, never memory); `ageipelago` when a ticket touches the AP host.
- The module is generic (any scenario or RMS can include it). Ageipelago is the first and hardest host: `AP.xs` calls `xsCreateFile(false)` every tick, overwriting `<scenario>.xsdat`, the only file XS can write.
- Real XS names: `xsReadInt` / `xsReadFloat` / `xsReadString` / `xsReadVector`; there is no bool reader. `xsCloseFile` closes "the currently opened or created file".
- No AoE2 on this desktop. Any live verification is a HITL task on the game machine.
- Never commit. Grill one question at a time.
- Repo: `aoe2-xs-injector` (its own repo, moved out of AoE2_AI_Modder 2026-11-10). The AoE2_AI_Modder KB stays the reference source; paths into it are prefixed `AoE2_AI_Modder/`.
- Tracker: local markdown, see `docs/agents/issue-tracker.md`.
- Handoff prerequisite: level `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json` with ugc.aoe2.rocks (its 15 Network functions) before the dispatch is generated.

## Decisions so far

<!-- one line per resolved ticket: [title](issues/NN-slug.md): gist -->

- [aoe2kit xsdat decoding](issues/02-aoe2kit-xsdat-decoding.md): caller-supplied `--types` decode, no encoder, `raw:N` skips a prefix; Ageipelago's uncounted location list blocks any append until its packet changes; upstream takes small general features
- [XS file I/O semantics](issues/01-xs-file-io-semantics.md): fresh opens see external writes; one file at a time implied; profile folder both ways; past-EOF, nesting, append ordering and share mode unverified, so a live spike graduated
- [Value store and references](issues/05-value-store-and-references.md): call-indexed typed result slots, no registers; tagged literal/reference arguments; store lives one request; response has every call in order; bool is int on the wire
- [Function catalog](issues/06-function-catalog.md): dispatch generated from the KB catalog (levelled with UGC) covering every function; pinned id table; argument count on the wire; hand-written core includes the generated dispatch

## Not yet specified

- **Error reporting**: what the response says for an unknown function id, wrong argument types, a reference whose type mismatches the parameter, an argument count outside the function's range, a forward or self reference, a failed call, or a truncated request.
- **Driver**: what writes requests and reads responses for the agent. Could be a new aoe2kit subcommand (encode/decode), a Python helper in this repo, or both. Also the poll loop and timing (rule interval, how the agent knows a response is fresh).
- **Agent docs**: where they live (`docs/agent/` guide, a recipe, a skill) and what shape they take for agentic use.
- **Wire-format versioning**: how the module and the client detect a mismatch.

## Out of scope

- Reading game memory or attaching to the process. Only `.xsdat` file I/O.
- Multiplayer. Reads must match in every player's game or the game desyncs; this is a single-player tool.
