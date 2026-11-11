# Map: XS function injector

**Label:** wayfinder:map

## Destination

A handoff-ready spec for a generic XS function injector: an includable XS module that reads function calls (integer function id + arguments) from an `.xsdat` request file during a live match, runs them, and writes typed results where an agent can read them with the driver (aoe2kit for raw inspection). Covers the XS module, the request/response wire format, the aoe2kit changes, and the agent docs. No implementation in this map.

## Notes

- Domain: AoE2:DE XS scripting + `.xsdat` file I/O + aoe2kit (`chrae/aoe2kit`, Go, LGPL-3.0; cloned at `GitHub/aoe2kit`, built to `bin/kit.exe`).
- Skills every session should consult: `aoe2-modding` (XS signatures come from `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json`, never memory); `ageipelago` when a ticket touches the AP host.
- The module is generic (any scenario or RMS can include it). Ageipelago is the first and hardest host: `AP.xs` calls `xsCreateFile(false)` every tick, overwriting `<scenario>.xsdat`, the only file XS can write.
- Real XS names: `xsReadInt` / `xsReadFloat` / `xsReadString` / `xsReadVector`; there is no bool reader. `xsCloseFile` closes "the currently opened or created file".
- AoE2:DE runs on this desktop. Profile `.xsdat` folder: `C:\Users\dmwev\Games\Age of Empires 2 DE\76561199655318799\profile`. Live verification is still HITL: the maintainer runs the match.
- Never commit. Grill one question at a time.
- Repo: `aoe2-xs-injector` (its own repo, moved out of AoE2_AI_Modder 2026-11-10). The AoE2_AI_Modder KB stays the reference source; paths into it are prefixed `AoE2_AI_Modder/`.
- Tracker: local markdown, see `docs/agents/issue-tracker.md`.
- Handoff prerequisites: level `AoE2_AI_Modder/docs/agent_database/xs_functions_catalog.json` with ugc.aoe2.rocks (its 15 Network functions) before the dispatch is generated; then fix-and-relaunch the generated dispatch until it compiles in the engine, correcting the KB catalog ([Engine-true signatures](issues/09-engine-true-signatures.md)).

## Decisions so far

<!-- one line per resolved ticket: [title](issues/NN-slug.md): gist -->

- [aoe2kit xsdat decoding](issues/02-aoe2kit-xsdat-decoding.md): caller-supplied `--types` decode, no encoder, `raw:N` skips a prefix; Ageipelago's uncounted location list blocks any append until its packet changes; upstream takes small general features
- [XS file I/O semantics](issues/01-xs-file-io-semantics.md): fresh opens see external writes; one file at a time implied; profile folder both ways; past-EOF, nesting, append ordering and share mode unverified, so a live spike graduated
- [Game machine access](issues/07-game-machine-access.md): this desktop is the game machine; Claude Code, the profile folder, Go 1.27 and a built aoe2kit are all local
- [Value store and references](issues/05-value-store-and-references.md): call-indexed typed result slots, no registers; tagged literal/reference arguments; store lives one request; response has every call in order; bool is int on the wire
- [Function catalog](issues/06-function-catalog.md): dispatch generated from the KB catalog (levelled with UGC) covering every function; pinned id table; argument count on the wire; hand-written core includes the generated dispatch
- [Live file I/O spike](issues/08-live-file-io-spike.md): own file flushes at every close and is readable live; outside writes fail while XS holds a file; past-EOF reads return -1/""; one file at a time; append and raw-byte strings work; no read ceiling; editor test-play is `default1`; a 289-case switch compiles; catalog signatures are wrong in places
- [Request format](issues/03-request-format.md): `xsinject.xsdat`, driver-written by atomic replace; id + call count + tagged calls; runs when the id changes (startup id adopted unrun, failed parses marked seen); whole request staged before any call runs; zero calls is a ping
- [Response coexistence](issues/04-response-coexistence.md): trailer section at EOF found from the end; host opt-in plus a write hook before its close, standalone otherwise; entries are status [+ value]; Ageipelago gains a live `LocationCount` and ships the injector wiring commented out; the driver decodes
- [Engine-true signatures](issues/09-engine-true-signatures.md): fix-and-relaunch on the generated dispatch (probe only message-less errors); corrections go into the KB catalog and upstream, no override table; a clean engine compile is the bar and gates handoff; every function emitted
- [Error reporting](issues/10-error-reporting.md): ten request status codes plus failed call/argument ints; no return value is a failure and every call runs; a Running marker exposes a killed rule; over the write limit is TooLarge with no entries; liveness is a driver timeout from the request, no heartbeat
- [Wire-format versioning](issues/11-wire-format-versioning.md): no versioning on the wire, no fingerprint, no new status code; driver/module mismatch is handled by process (re-include the core after any regeneration), documented in the agent docs
- [Driver](issues/12-driver.md): stdlib Python module + CLI (`run`/`ping`/`fetch`/`encode`) sharing a generated `signatures.json`; JSON calls by name, encoded and decoded by the driver; next id from the request file; response found by magic + mtime + echoed id; 1 s rule, 0.25 s poll, 10 s timeout; driver statuses Timeout/FileHeld/Invalid
- [Agent docs](issues/13-agent-docs.md): `docs/agent/` in this repo (driving, hosting, troubleshooting, maintaining) plus a thin user-global `xs-injector` skill routing into it; troubleshooting is one table keyed by driver output; re-include rule stated once, pointed to twice; human checklist bounds what agents ask for; no function list

Handed off 2026-11-11: [Spec: XS function injector](../xs-injector-build/issues/01-xs-function-injector-spec.md) (`ready-for-agent`).

## Not yet specified

<!-- Driver, Agent docs and Wire-format versioning graduated into tickets 2026-11-10 -->

## Out of scope

- Reading game memory or attaching to the process. Only `.xsdat` file I/O.
- Multiplayer. Reads must match in every player's game or the game desyncs; this is a single-player tool.
