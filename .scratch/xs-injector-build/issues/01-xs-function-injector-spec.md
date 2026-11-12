# Spec: XS function injector

**Label:** ready-for-agent
**Status:** open
**Blocked by:** none (see Further Notes for handoff prerequisites)
**Source:** [Map: XS function injector](../../xs-injector/map.md); every decision below is detailed in that map's resolved tickets.

## Problem Statement

An agent (or a developer) working on an AoE2:DE scenario or mod has no way to ask the running game a question or poke it during a live match. To learn a unit's hit points, a player's resource count, or what an XS function actually returns in this build, someone has to write a throwaway XS rule, rebuild, relaunch the match, read chat output or a sidecar by hand, and repeat. That loop is slow, needs a human for every step, and can't be driven by an agent. XS can only talk to the outside world through `.xsdat` files in the profile folder. A host like Ageipelago already rewrites the game's own `.xsdat` every tick, so naively adding output there clobbers it or gets clobbered.

## Solution

An includable, generic XS module, the **XS function injector**, plus a **driver** on the agent's side.

- The agent describes a **request** as a JSON list of **calls**: an XS function name plus arguments. An argument is a literal, or a reference to an earlier call's result in the same request.
- The driver validates the request against the generated signatures, encodes it to a binary `xsinject.xsdat` in the profile folder, and waits.
- Once a game-second, the module notices a new request id, parses the whole request, runs every call through a generated dispatch covering every XS function in the catalog, and stores each result in a typed **result slot**.
- The module writes a **response** as a **response section**, a trailer at the end of the game's own `.xsdat`. It is written either by the module itself (**standalone**) or by a **host** that opted in and calls the module's write hook just before its own close.
- The driver finds the response section from the end of the file, decodes it with the return types it already knows, and prints one JSON result: request status, failure location, and one typed entry per call.

Any scenario or RMS can include the module. Ageipelago is the first and hardest host. Agent docs and a thin user-global skill teach agents to drive it, host it, troubleshoot it and maintain it.

## User Stories

### Driving: agent's view

1. As an agent, I want to call any XS function by name with JSON arguments during a live match, so that I can inspect or change game state without writing and reloading XS.
2. As an agent, I want to send many calls in one request, so that a multi-step query costs one round trip.
3. As an agent, I want to pass a previous call's result as an argument (`{"ref": N}`), so that I can chain calls (e.g. get a unit id, then query that unit) in one request.
4. As an agent, I want literals written as plain JSON (int, float, string, `true`/`false`, `[x, y, z]` vectors), so that I don't need to know the binary layout.
5. As an agent, I want optional parameters to be optional in my call, so that XS applies its own defaults exactly as it would in hand-written code.
6. As an agent, I want the driver to reject an unknown function name, a wrong argument count, a wrong literal type, or a bad reference before anything is sent, so that I get an immediate, precise error instead of a wasted round trip.
7. As an agent, I want one JSON result shape from both the CLI and the API (`request_id`, `status`, `failed_call`, `failed_argument`, `message`, `entries`), so that I can parse every outcome the same way.
8. As an agent, I want each entry to carry its call number, function name, status and a decoded value (vectors as `[x, y, z]`, bools as `true`/`false`), so that I can use results directly.
9. As an agent, I want void calls to appear as entries with no value, so that call numbers in the response line up with call numbers in my request.
10. As an agent, I want a return value of -1 or false treated as a value, not a failure, so that functions whose legitimate answer is -1 still work.
11. As an agent, I want every call in a request to run even if an earlier one returned something odd, so that one surprising result doesn't hide the rest.
12. As an agent, I want a `ping` command that sends a zero-call request, so that I can check the module is live before sending real work.
13. As an agent, I want a `fetch` command that decodes the current response against my last request without sending anything, so that I can recover a response that arrived after my timeout.
14. As an agent, I want an `encode` command that prints the request bytes without sending, so that I can inspect or debug the wire format.
15. As an agent, I want `run` to accept a file or stdin, so that I can pipe requests in from other tools.
16. As an agent, I want the CLI to exit 0 only on OK, so that scripts can branch on success.
17. As an agent, I want a human-readable `message` rendered from the request I sent, so that I can tell which call and argument failed without decoding codes myself.
18. As an agent, I want a `Timeout` that says why (`no-section`, `older-id`, `stuck-running`), so that I know whether the module isn't wired, isn't caught up, or was killed mid-request.
19. As an agent, I want a `FileHeld` status when the game won't release the request file, so that I can tell a lock from a dead module.
20. As an agent, I want the profile folder auto-detected (with `--profile` and `XSINJECT_PROFILE` overrides), so that I don't have to know the Steam id path.
21. As an agent, I want `--map <name>` to pin which `.xsdat` holds the response, so that I can disambiguate when more than one file carries a response section.
22. As an agent, I want the driver to choose the next request id itself, so that I never collide with an id the module has already seen.
23. As an agent, I want poll interval, timeout and lock-retry limits to be configurable, so that I can tune for slow game speeds or long requests.
24. As an agent, I want a request whose response would exceed the game's write limit to come back as `TooLarge`, so that I know the calls ran and I need to split the reads.
25. As an agent, I want a list of exactly what to ask the human for (start the match or editor test-play, keep it unpaused, confirm the host opt-in is uncommented), so that I don't pester them with anything else.

### Hosting: scenario/mod developer's view

26. As a scenario developer, I want to include one core file to get the injector, so that enabling it is a one-line change.
27. As a scenario developer with no `.xsdat` writer of my own, I want the module to write the response itself (standalone), so that I need no wiring beyond the include.
28. As a host developer whose mod already rewrites the game's `.xsdat` every tick, I want to opt in with one call from `main()` and one hook call just before my own close, so that my packet and the response coexist in the same file.
29. As a host developer, I want the response section to be a trailer found from EOF, so that my packet layout doesn't change and readers don't need to know it.
30. As a host developer, I want the module to keep its last response and rewrite it on every one of my writes, so that my per-tick truncation never loses it.
31. As a host developer, I want a documented warning that writing the file without opting in wipes responses, so that I understand why responses vanish.
32. As the Ageipelago maintainer, I want the injector wiring shipped commented out with a one-line pointer to the recipe, so that a normal install is unaffected and enabling it is uncommenting three lines.
33. As the Ageipelago maintainer, I want my packet to carry an explicit `LocationCount`, so that bytes after the location list (the response section) are ignored by my client.
34. As a host developer, I want the enabling recipe to live in one place (the injector's hosting doc), so that it never drifts between repos.

### Module behaviour: robustness

35. As a module, I want to run a request only when its id differs from the last one seen, so that re-reading an unchanged file never re-runs calls.
36. As a module, I want to adopt the id already in the file at startup without running it, so that a stale request from a previous session never fires.
37. As a module, I want an id marked seen once its parse is attempted, so that a malformed request is reported once, not retried forever.
38. As a module, I want to read and check the whole request into staging and close the file before running any call, so that an injected File IO call or `xsDisableSelf` can't cut the read short.
39. As a module, I want every read bounded by the file size, so that a truncated file is detected by size, never by a -1 that could be a real value.
40. As a module, I want to report the first parse failure with a specific status and the failing call and argument, so that the driver can render an exact message.
41. As a module, I want to store a `Running` response before call #0, so that a runtime error that kills the rule leaves a visible marker.
42. As a module, I want result slots cleared before each request, so that no value leaks between requests.
43. As a module, I want a reference to a forward, self or out-of-range call, or to a result of the wrong type, rejected at parse time, so that no call runs with a garbage argument.
44. As a module, I want a missing or empty request file to mean idle, so that a match with no driver costs nothing.

### Maintaining: injector maintainer's view

45. As the injector maintainer, I want the dispatch generated from the KB function catalog, so that every XS function is covered without hand-writing 289 cases.
46. As the injector maintainer, I want function ids pinned in a checked-in table (new ids appended, never reused, renames keep their id, removals retired), so that ids stay stable across game updates.
47. As the injector maintainer, I want the generator to fail when a pinned function leaves the catalog without a rename entry, so that ids can't silently shift.
48. As the injector maintainer, I want one generated `signatures.json` to feed both the XS generator and the driver, so that driver validation and module dispatch never disagree.
49. As the injector maintainer, I want a fix-and-relaunch loop on the real dispatch to find wrong catalog signatures, so that the cost is one launch per wrong signature, not per function.
50. As the injector maintainer, I want signature corrections made in the KB catalog (marked with their source and reported upstream), so that there is one source of truth and no override table.
51. As the injector maintainer, I want a clean engine compile of the whole dispatch to gate every handoff and every catalog update, so that no unverified signature ships.
52. As the injector maintainer, I want the re-include rule (after any regeneration or layout change, re-include the core in every host) stated in the docs, so that a stale core doesn't silently misread literals.

### Docs and discovery

53. As an agent, I want a user-global `xs-injector` skill that triggers on injector words and routes into the repo's docs, so that I find the right doc without being told.
54. As an agent, I want a troubleshooting table keyed by exactly what the driver prints, so that I go from output to fix in one lookup.
55. As an agent, I want the docs to point me to `signatures.json` and the KB catalog for signatures instead of listing functions, so that there is no third, stale copy.
56. As an agent working in Ageipelago or general AoE2 modding, I want the existing skills to point me at the injector, so that I discover it when it's relevant.

## Implementation Decisions

### Modules

- **XS core module (hand-written).** Owns the request rule, request parsing and staging, the result store, response building, standalone writing, the host opt-in and write hook. It includes the generated dispatch. Hosts include the core only.
- **Generated XS dispatch.** One `switch` on function id, one case per catalog function. Each case has one XS call site per allowed argument count (`min_param_count..param_count`), so XS applies its own defaults. Also emits the per-function parameter-type table the parser uses. Checked in.
- **Generator (Python).** Inputs: the KB function catalog, the KB renames file, the pinned name-to-id table. Outputs: `signatures.json` (name → id, parameter types, argument-count range, return type), the pinned table, the generated dispatch. Fails on a pinned function missing from the catalog without a rename.
- **Driver (Python, stdlib only) with a thin CLI.** Commands: `run <file|->`, `ping`, `fetch`, `encode <file|->`. Reads `signatures.json`. Exposes the same operations as a Python API that returns the same result shape as the CLI prints.
- **Agent docs** in this repo under an agent docs folder: four task files, `driving`, `hosting`, `troubleshooting`, `maintaining`. Plus a thin user-global `xs-injector` skill routing into them, and one-line pointers added to the `ageipelago` and `aoe2-modding` skills.
- **aoe2kit: unchanged.** It stays the raw-inspection tool. A static `--types` list can't follow status-dependent entries, so the driver decodes responses itself. A general trailer/`--from-end` decode is an optional upstream ask, not required.

### Module public interface (XS)

- `xsInjectUseHostWriter()`: called from a host's `main()` to opt in. Without it the module is standalone.
- `xsInjectWriteSection()` (working name): the host calls this just before its own `xsCloseFile()`. It writes the current response section into the host's open file.
- Standalone: the module writes the game's own `.xsdat` itself with `xsCreateFile(false)` (section only), once per response.

### Request wire format (`xsinject.xsdat`, profile folder)

- Written only by the driver, read only by the module. Missing or empty means idle.
- Layout: `request id` (int), `call count` (int), then per call `function id` (int), `argument count` (int), then per argument a `tag` (int) followed by its payload:
  - tag `0` literal: the value encoded as the parameter's declared XS type (int, float, string as uint32 length + raw bytes, vector as 3 floats). Bool is sent as int.
  - tag `1` reference: an int call number of an earlier call in the same request.
- Call numbers restart at 0 per request. No magic, no version, no byte-length field.
- The driver writes a temp file and then calls `os.replace` onto `xsinject.xsdat`, retrying while XS holds the file. It first saves the request as `xsinject.last.json` in the profile folder, also by temp file + replace.
- Next request id = the id currently in `xsinject.xsdat` + 1 (1 if missing). The echoed id only matches a response to its request.
- A zero-call request is valid (ping).

### Request lifecycle (module)

- The request rule runs at `minInterval 1` / `maxInterval 1` game-seconds.
- At startup, adopt the id in the file (if any) as seen, without running it.
- Each tick: open the request file. If it is empty, missing, or its id equals the last seen, close and stop. Otherwise mark the id seen, then parse the whole request into staging arrays, bounding every read by `xsGetFileSize()` and checking string lengths before reading them. Then close the file.
- Parse failure: respond with the failure status and 0 entries; run nothing.
- Parse success: clear result slots, store a `Running` response with 0 entries (written in standalone, carried by the host's next write), then run every call in order, storing each non-void result in its slot. Then store the final response with one entry per call.
- `xsDisableSelf` and injected File IO stay dispatchable. They are documented as foot-guns, and staging-before-run limits the damage.

### Result store

- Five typed arrays (int, float, bool, string, vector) sharing one index. Call #n's result goes at index n in the array of its return type. No registers.
- Lifetime: one request. A reference must point to an earlier call whose return type matches the parameter's declared type.
- Bool uses a native bool array internally, but crosses the wire as int both ways.

### Response section (trailer at EOF of the game's own `.xsdat`)

- Framing: `[body][body byte length][magic]`. The body also opens with the magic. A reader finds the section from EOF without knowing what precedes it.
- Body: `magic`, `request id`, `request status`, `failed call #`, `failed argument #` (`-1` when n/a), `entry count`, then entries in call order.
- Entry: a status int (`0` OK, `1` NotRun, which is reserved with no current path producing it), followed by the value only when the status is OK and the function is non-void. No type tags: the driver knows return types by function id.
- Ping and parse failures have 0 entries; the request status tells them apart.
- The magic is a fixed int chosen at implementation. It is a finder only, not a version.

### Request status codes (wire)

`0` OK · `1` Running · `2` Truncated (file ends before the call count is met, or a string length runs past EOF) · `3` UnknownFunction · `4` BadArgCount · `5` BadTag · `6` BadReference (forward, self or out of range) · `7` ReferenceTypeMismatch · `8` TooLarge · `9` TrailingBytes.

- A wrong-typed literal is undetectable by design; at most it surfaces as Truncated or TrailingBytes. The driver's pre-send validation is the real guard.
- TooLarge: if the section would push the file past 1,048,575 bytes (host bytes included, measured from `xsGetFilePosition()` at hook time), it is sent as TooLarge with 0 entries. The calls have already run.
- The module never judges a return value; -1 and false are values.

### Driver behaviour

- Profile folder: `--profile`, then `XSINJECT_PROFILE`, then auto-detect the single `.../Age of Empires 2 DE/<steamid>/profile`.
- Request input: a JSON array of `{"fn": <name>, "args": [...]}`. Literals are plain JSON; a reference is `{"ref": N}`. Before sending, the driver validates names, argument counts, literal types and references against `signatures.json`. A failure gives driver status `Invalid` and nothing is sent.
- Finding the response: scan the profile folder's `*.xsdat` (skipping `xsinject.xsdat`) for files whose last 4 bytes are the magic, modified after the send, and echoing the request id. More than one match is an error; `--map <name>` pins one file.
- Timing defaults (all configurable): poll every 0.25 s; timeout 10 s from a successful `os.replace`; the replace retry gives up after 5 s with `FileHeld`.
- Output shape (CLI and API): `{"request_id", "status", "failed_call", "failed_argument", "message", "entries": [{"call", "fn", "status", "value"}]}`. Values are decoded by the return types of the request sent (vector `[x, y, z]`, bool `true`/`false`).
- Driver statuses, never on the wire: `Timeout` with `diagnosis` `no-section` / `older-id` / `stuck-running`; `FileHeld`; `Invalid`. The CLI exits 0 only on OK.
- `fetch` decodes the current response against `xsinject.last.json` without sending.
- Liveness is by timeout only, with no heartbeat. The game may sit idle or paused indefinitely between requests.

### Function catalog and ids

- Source: the KB function catalog, levelled with ugc.aoe2.rocks (its 15 Network-section functions added) → 289 functions. Every catalog function gets an id: File IO, `xsUnsync*` and side-effecting functions included. Every catalog type is int, float, bool, string, vector or void, so all are expressible.
- Ids come from the pinned table: next free id for new functions, never reused, renames (via the KB renames file) keep their id, removals are retired.
- Signatures are made engine-true by fix-and-relaunch on the generated dispatch. Corrections go into the KB catalog, marked with their source and reported to UGC and xs-check. Known corrections: `xsIsRuleGroupEnabled` is void; `xsFlashUnit`'s `soundName` is string; `xsBuildUnit(int, int, vector)` fails with no message and needs a variant probe.

### Versioning

- None on the wire: no version field, no dispatch fingerprint, no mismatch status code. Driver and core ship together from this repo. After any regeneration or layout change, re-include the core in every host. Accepted risk: a stale core can silently misread a literal whose parameter type was corrected.

### Ageipelago (cross-repo precondition, done under the `ageipelago` skill's rules)

- `CurrentPacketLocationCount` takes reserved field 25 (byte offset 96; reserved block 25 → 24; field 24 went to `CheckedLocationsCount` first). `AP_Write` writes the filtered count and exactly those ids (`AddLocation` refuses `-1`, so no ids are skipped); the client reads exactly that many and ignores trailing bytes. No `world_version` bump while 0.3.0 is unshipped (ruling in ticket 11); protocol doc table updated, layout test modelled on the existing mercenary packet test.
- The injector wiring ships commented out: the `#include`, `xsInjectUseHostWriter()` in `main()`, and the hook call just before `AP_Write`'s `xsCloseFile()`. A one-line comment points at the recipe in the injector's hosting doc.
- Accepted: while `AP_SLOT_ID == -1`, `AP_Write` writes nothing, so an unconfigured install shows no response (`Timeout/no-section`).

### Agent docs content

- `driving`: opens with the human checklist (start the match or editor test-play, keep it unpaused, confirm the host opt-in is uncommented). Then the CLI, the JSON request and result shapes, and the wire and driver statuses. States that `Invalid` catches name, count and type mistakes before sending. Lists no functions.
- `hosting`: standalone include, host opt-in, and the Ageipelago recipe verbatim (source of truth). Links to the re-include rule.
- `troubleshooting`: one table, driver output (`status` + `diagnosis`) → likely cause → fix. Rows: `Timeout/no-section`, `Timeout/older-id` (paused game as its own line), `Timeout/stuck-running`, `FileHeld`, `Invalid`, wire codes 2–9, TooLarge.
- `maintaining`: regenerate signatures and dispatch, fix-and-relaunch, KB corrections and upstream reports, then the re-include rule in full.
- Skill: triggers on `xsinject`, injector, driver, `run`/`ping`/`fetch`, response section, calling an XS function live. Repeats the re-include rule as one hard rule, and tells agents to ask humans only for the checklist items.

### Engine facts the design relies on (observed live, 2026-11-10)

- Past-EOF reads return -1 / -1.0 / (-1,-1,-1) / "" without raising; huge string lengths don't crash. EOF must be detected by size.
- XS holds a real OS handle while a file is open. Outside writes fail while it is open for reading; even outside reads fail while it is open for creating. After close, everything works, hence the driver's retry loop.
- One file at a time: any open or create silently replaces the current file.
- The game's own `.xsdat` is flushed at every close and is readable mid-match. `xsGetMapName(false)` is its stem; editor test-play is `default1`.
- Truncate-then-append in one rule keeps both payloads in order. Strings are raw bytes both ways. There is no read ceiling (400,000 ints were read in one rule).
- A 289-case switch with 373 call sites compiles and dispatches correctly.

## Testing Decisions

- **Good tests assert external behaviour only:** the result JSON (status, failed call/argument, entry values and types), CLI exit codes, and generator outputs and failures. They never assert on staging arrays, slot layout, or internal byte offsets.
- **Three seams, highest first:**
  1. **Driver public interface** (CLI and the identical Python API), against a temp profile folder. Tests stand in for the module by writing response-section fixtures into a fake game `.xsdat`. Covered: `Invalid` for every validation rule, `encode` output, finding the response (magic, mtime, echoed id, multiple matches, `--map`), decoding every return type and entry status, `Timeout` with each `diagnosis`, `FileHeld` against a locked request file, `fetch` against `xsinject.last.json`, profile-folder resolution, exit codes. Automated and fast.
  2. **Generator**: catalog + renames + pinned table in; `signatures.json`, pinned table and dispatch out. Covered: new functions take the next free id, ids are never reused, renames keep their id, removals are retired, an unexplained removal fails, argument-count ranges give one call site per count. Automated, on small fixture catalogs.
  3. **XS module, live only.** First, a clean engine compile of the whole generated dispatch, by fix-and-relaunch, gating handoff and every catalog change. Then a scripted HITL smoke run: the maintainer starts editor test-play of a small test scenario that includes the core, and an agent drives it with the real driver and checks the JSON results. Run once standalone and once hosted under Ageipelago. Crafted request bytes reach the parse-failure codes the driver's validation would otherwise block. aoe2kit is used for raw inspection when a live check fails.
- **Each slice (below) lands with its tests at whichever of these seams it touches**, and its live check extends the smoke run.
- **Prior art:** the live file I/O spike in the map (a Python driver stepping a test scenario, `kit xsdat decode` of the game's own `.xsdat` as evidence, a generated large-switch scenario for the compile check).

## Vertical Slices

Each slice cuts end to end (generator → XS module → wire → driver → docs where relevant), is demoable through the driver, and builds on the one before.

1. **Tracer bullet: `ping`, standalone.** The core module's request rule (1 s interval, read request id, adopt the startup id unrun, run on a changed id), a zero-call parse, and a response section written standalone with the trailer framing and header (request id, status OK, failed call/argument `-1`, 0 entries). Driver: profile resolution, next-id from the request file, temp + `os.replace` with `FileHeld` retry, `xsinject.last.json`, response finding, header decode, `ping` command, `Timeout/no-section` and `older-id`. Tests: driver seam with fixtures; live ping.
2. **One real call.** Generator v1: pinned table, `signatures.json`, and a dispatch emitted for every catalog function (int literals only exercised). Module: call parsing (function id, argument count, tag 0 int), dispatch, int result slot, OK entries. Driver: JSON `{"fn","args"}` input, name/count validation (`Invalid`), int decode, `run` command, `message`. Tests: generator seam (id rules); driver seam; live `run` of an int function.
3. **All types.** Float, string, vector and bool-as-int literals and returns; void entries with no value; driver literal-type validation and full decode; `encode` command. Tests: driver seam per type; live call per type plus a void call.
4. **References.** Tag 1, the per-request typed store cleared before each request, and reference checks in both the driver and the module. Tests: driver seam (`Invalid` on forward/self/out-of-range/type-mismatch refs); live chained request.
5. **Optional arguments.** One call site per allowed count; argument count validated against the range. Tests: generator seam (call sites per count); live call relying on an XS default.
6. **Failure reporting.** Parse-failure codes 2–7 and 9 with failed call/argument, the `Running` marker before call #0, `Timeout/stuck-running`, `fetch`. Tests: driver seam decode of each code; live crafted-bytes requests and a rule-killing call.
7. **Engine-true dispatch.** The catalog is levelled with UGC (289 functions); fix-and-relaunch until the whole dispatch compiles; corrections land in the KB catalog. Tests: compile gate.
8. **Host mode.** `xsInjectUseHostWriter()`, `xsInjectWriteSection()` rewriting the last response on every host write, TooLarge measured at hook time. Tests: driver seam TooLarge decode; live hosted run with a minimal test host that rewrites every tick, plus a TooLarge request.
9. **Ageipelago wiring.** Depends on the cross-repo `LocationCount` change shipping first. The commented-out include, opt-in and hook lines, with a pointer to the recipe. Tests: live smoke run under Ageipelago with the wiring uncommented, and Ageipelago's own client still reading its packet.
10. **Agent docs and skill.** `driving`, `hosting` (verbatim recipe), `troubleshooting` (one table keyed by driver output), `maintaining` (re-include rule); the user-global `xs-injector` skill; one-line pointers in `ageipelago` and `aoe2-modding`. Check: an agent with only the skill drives a ping and a chained request, and resolves a `Timeout/no-section` from the table.

## Out of Scope

- Reading game memory or attaching to the process; only `.xsdat` file I/O.
- Multiplayer. Reads must match in every player's game or it desyncs, so this is a single-player tool.
- Any wire-format versioning, fingerprinting, or mismatch detection.
- Changes to aoe2kit (an optional upstream trailer-decode feature is not required).
- A runtime type probe for signatures; a clean compile is the bar.
- A heartbeat or liveness signal from the module.
- A function reference in the agent docs.

## Further Notes

- **Handoff prerequisites, in order:**
  1. Level the KB function catalog with ugc.aoe2.rocks (the 15 Network functions).
  2. Generate the dispatch and run fix-and-relaunch until the engine compiles it cleanly, landing corrections in the KB catalog (starting with the three known ones).
  3. The Ageipelago `LocationCount` packet change ships live before slice 9.
- Prerequisites 1–2 are slice 7; slices 1–6 can proceed on the unlevelled catalog, using functions already known to compile (catalog ids 0–169 with the two known overrides).
- Accepted risks: XS silently converting a mis-catalogued type (e.g. int↔float) can give a wrong-typed response value, and a stale vendored core can misread corrected literals silently.
- Glossary terms used here (Request, Call, Result slot, Literal/Reference argument, Driver, Function id, Response, Entry, Response section, Host, Standalone, Driver status) are defined in the repo glossary.

## Rulings

- 2026-11-11: The toolkit is standalone: nothing outside this repo is required. The KB catalog and renames file were copied once into `catalog/functions.json` and `catalog/renames.json`, which this repo now owns; the generator reads only those. Signature corrections and the UGC levelling land in `catalog/functions.json`, not in AoE2_AI_Modder (reporting them upstream is optional courtesy). xs-check stays an optional dev aid; nothing requires it.
