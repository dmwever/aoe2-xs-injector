# aoe2kit `.xsdat` decoding

Research for [issue 02](../issues/02-aoe2kit-xsdat-decoding.md).

Source: `chrae/aoe2kit` cloned at `caa953b` (2026-11-04, "release: prepare v0.4.4"), plus the GitHub REST API for issues and PRs (fetched 2026-11-10). File paths below are relative to the repo root. Nothing in the clone was built or run.

## Short answers

| Question | Answer |
|---|---|
| How does `kit xsdat decode` know the layout? | You give it the layout. Precedence: `--schema NAME` (a hard-coded Go decoder), then `--types` (a comma list, or a path to a `.types` file), then a sibling `.types` file found next to the `.xsdat`, then a labelled heuristic. The heuristic never claims to know types. |
| Encoder? | None. No `kit xsdat encode`, no Go function that writes xsdat bytes. `xsdat` has only `decode`. |
| Decode from an offset / skip a prefix? | Partly. There is no `--offset` flag, but the `--types` list accepts `raw:N`, which consumes N bytes as hex. A fixed-size prefix can be skipped that way. A variable-length prefix cannot. |
| Profile folder? | Not discovered. Every xsdat command takes an explicit path. Nothing watches or polls `.xsdat` files. |
| Contribution route | External PRs are accepted in substance but always closed unmerged; the maintainer ports them into a squashed release commit and credits the author. An upstream PR is realistic for a small, generic feature. A fork is not needed unless we want it sooner than a release. |

## 1. How the layout is chosen

The command is dispatched from `cmd/kit/main.go:153` to `runXSDat` in `cmd/kit/xsdat.go:12`. `decode` is its only subcommand (`cmd/kit/xsdat.go:20-30`). The command catalogue marks it `TraitReadOnly` (`cmd/kit/commands_catalog.go:284`).

`runXSDatDecode` (`cmd/kit/xsdat.go:33-139`) picks a layout in this order:

1. **`--schema NAME`** (`xsdat.go:81-95`) calls `DecodeDataFileSchema`. The names map to one of 15 hand-written Go decoders in a `switch` (`pkg/xs/schema_decode.go:73-106`, aliases at `:128-165`). They are aoe2kit's own probe fixtures (`rtv12`..`rtv17`, `customstore`, `engine-harness`, `long-v3`, `snake-v0`, ...). An unknown name is an error (`schema_decode.go:104-105`). There is no user-defined schema language: adding a schema means adding Go code.
2. **No `--schema` and no `--types`**: it looks for a sibling `.types` file (`xsdat.go:78-80` -> `DiscoverSiblingTypesFile`, `pkg/xs/types_document.go:27-84`). `<stem>.types` wins. Otherwise, if exactly one recognised `.types` file is in the folder it is used, and if several are, it refuses to guess.
3. **`--types` value or discovered file** (`xsdat.go:96-122`). If the text contains `header =`, it is treated as a "types document". `SchemaFromTypesDocument` (`types_document.go:99-124`) does not parse the fields. It reads the first `#` comment line as an identity and maps it to one of the hard-coded schemas above. Anything else is an error. So a `.types` document is only a pointer to a built-in decoder.
4. Otherwise the value is a **comma type list** parsed by `ParseDataTypes` (`pkg/xs/xsdat.go:135-150`). Accepted tokens (`xsdat.go:152-177`): `s|str|string`, `i|int|int32`, `u|uint|uint32`, `f|float|float32`, `v|vec|vector`, `raw|bytes` (consume all remaining bytes), `raw:N` (consume exactly N bytes). The values are read in order from offset 0 (`parseTypedData`, `xsdat.go:179-195`; per-type reads in `readTypedValue`, `:276-330`).
5. **Empty type list** gives `auto_heuristic` mode (`xsdat.go:123-130`, `parseAutoData` `:197-235`). A u32 length followed by that many valid UTF-8 bytes with no control characters other than tab/CR/LF is reported as a string (`tryAutoString` `:237-258`, `saneXSString` `:260-274`). Otherwise each 4-byte word is reported as `int_or_float` with both readings and `heuristic: true`. A warning says so (`:128`).

**Strictness.** A typed decode is `OK` only if there are no errors and **no bytes are left over** (`xsdat.go:131`). Leftover bytes are reported as `remaining_offset` / `remaining_bytes` / `remaining_hex` (`:190-194`). The docs describe this on purpose as "the tail is the alarm" (`docs/SIDECAR.md:47-49`). `kit` exits 1 when `!report.OK` (`cmd/kit/xsdat.go:136-138`), but the JSON report is still printed first.

**`--ledger expected.json`** (`pkg/xs/xsdat_decode.go:50-85`) is an assertion layer. It is a JSON array (or `payload` / `writer.payload`) of `"type value"` strings or `{type, value}` objects, with `*`/`any` as a wildcard (`:87-175`, `:259-262`). When no `--types` is given, the types are taken from the ledger (`:58-60`). Values are compared by position (`:185-215`).

**Byte format** assumed (`docs/SIDECAR.md:28-38`): no tags; string = u32 LE length + bytes; int/uint/float = 4 bytes LE; vector = 12 bytes. This matches Ageipelago's `docs/communication_protocol.md` (lines 13-24). No bool type exists. Ageipelago's 4-byte bool decodes fine as `int`.

**Output.** JSON by default, `--text` for a line per value with offset, size, and value (`cmd/kit/xsdat.go:149-208`). In JSON the values are under `decode.values` (`docs/XS_SIDECAR_TECHNIQUE.md:102-106`). NaN/Inf floats become strings (`pkg/xs/xsdat.go:50-101`).

Also: `kit xs inspect <file> [--types ...]` (`cmd/kit/xs.go:26-27`, catalogue `commands_catalog.go:282`) is a thinner front end to the same `InspectDataFile`.

## 2. Encoder

There is none.

- `runXSDat` knows only `decode` (`cmd/kit/xsdat.go:20-30`).
- A search of `pkg/xs`, `pkg/ci`, `pkg/campaign`, `pkg/customstore`, and `cmd/kit` for byte writers found only decoders. `binary.LittleEndian.AppendUint32` appears only in tests (e.g. `pkg/xs/xsdat_test.go:54-70`).
- The nearby "generators" emit **XS source**, not `.xsdat` bytes: `kit xs bridge` (trigger-variable bridge module, `pkg/xs/bridge.go`), `kit xs datagen` (xsArray data modules, `pkg/xs/datagen.go`), `kit xs harness`, `kit ci init` (`a2k_debug.xs`), and `kit campaign generate` (writer/reader XS modules). See `docs/XS_SIDECAR_TECHNIQUE.md:125-134`.

So the agent would need something else to write request files: a new `kit xsdat encode`, or a Python helper. Ageipelago's client already writes `.xsdat` from Python.

## 3. Decoding from an offset or a section

- No `--offset`, `--skip`, or section flag exists (flag parsing at `cmd/kit/xsdat.go:43-73`).
- **Workaround that works today:** put `raw:N` first in the type list, e.g. `--types raw:196,int,int,string`. `raw:N` consumes exactly N bytes and reports them as hex (`pkg/xs/xsdat.go:168-174`, `:277-283`). The values after it are decoded from offset N. A trailing `raw` (no count) absorbs whatever follows (`:325-326`), which keeps `OK` true.
- **Why that is not enough for Ageipelago.** Ageipelago's game -> client packet is "49 fixed fields (196 bytes), then a variable-length location list to EOF" (`Ageipelago/docs/communication_protocol.md:132`, field 50+ at `:150`). There is no count field before the list. So:
  - `raw:196` skips only the fixed part. The location list length is unknown, so no static type list can reach bytes that come after it.
  - Ageipelago's own reader (`Age2Packet`) reads locations "to EOF". Any bytes appended after the packet would be read as location ids unless that reader changes too.
  - Appending therefore needs a change on the Ageipelago side as well: a location count, an end marker, or putting the injector section before the list. This is a design decision for the map, not something aoe2kit can solve.
- The schema decoders do not help either. Every one starts at offset 0 with its own header (e.g. `decodePhaseRows`, `pkg/xs/schema_decode.go:872-880`) and treats bytes after its footer as an error (`:946-950`).
- **Shape of a generic upstream feature**, if wanted: a framed section such as `string magic, int version, int byte_length, payload`, plus a `--find-section MAGIC` or `--offset N` flag. It would scan or seek before `parseTypedData`. The change would sit in `runXSDatDecode` and `InspectDataBytes` (`pkg/xs/xsdat.go:113-133`), with tests in the style of `pkg/xs/xsdat_test.go`. This is my inference; aoe2kit has no such feature or issue today.

## 4. Profile folder, watching, and file-lock claims

- **No discovery.** Every xsdat entry point takes an explicit file path (`kit xsdat decode <file>`, `kit replay sidecar-sync --xsdat <path>` at `cmd/kit/main.go:10320`, `kit dat semantics-readback --xsdat` at `:16366`, and `ci` contracts use a placeholder `replace-with-sidecar.xsdat` at `pkg/ci/ci.go:107`). A search for `AppData`, `Games\Age of Empires 2 DE\<id>\profile`, or `.xsdat` globbing found nothing that resolves the profile folder.
- The only path discovery is for the **game install** (`pkg/gameinstall/install.go:15-85`: `--game-dir`, then env `AOE2KIT_GAME_DIR`, then Steam library guesses) and for `mod-status.json` under `~/Games/Age of Empires 2 DE/mods` (`pkg/modpack/check.go:244-248`). Neither finds `<steam id>\profile`.
- The location is only **documented**: `<DE profile dir>\profile\<scenario>.xsdat` (`docs/XS_SIDECAR_TECHNIQUE.md:19-20`, `:75-78`). Ageipelago writes the same path as `$USER\Games\Age of Empires 2 DE\$STEAM_PROFILE\profile` (`communication_protocol.md:90`, `:101`).
- **No watch or poll for `.xsdat`.** The only watcher in the repo is `scenario.WatchLocal` (`pkg/scenario/watch.go:25-69`) for `.aoe2scenario` files: a portable stat loop (mtime + size, 1 s default interval) that snapshots and diffs. It is a usable pattern if we add one, but it does not apply to xsdat today.
- **Lock and flush claims conflict with Ageipelago.** aoe2kit's docs say xsdat rows "are buffered and flushed at scenario unload. The file does not exist mid-game, so there is no live streaming", and "DE holds an exclusive lock while the game runs" (`docs/SIDECAR.md:67-70`; `docs/XS_SIDECAR_TECHNIQUE.md:79-84`). Ageipelago's client reads the packet live every second while the scenario runs (`communication_protocol.md:101-107`). The likely reason is that `AP_Write` creates and closes the file each tick, while aoe2kit's writer pattern holds one file open for the whole run (`XS_SIDECAR_TECHNIQUE.md:30-64`). So aoe2kit's statement applies to its own "open once, close at end" pattern. It is not a general engine limit. The injector should copy Ageipelago's create-write-close-per-tick pattern, and should treat aoe2kit's "no live streaming" sentence as describing its own fixtures. (This is my inference from the two documents; the docs themselves do not reconcile it. A HITL check on the game machine would settle it.)

## 5. Contribution route

- **License:** LGPL-3.0 (`LICENSE`; repo metadata). Go 1.23 module named `aoe2kit` (`go.mod:1-3`).
- **CONTRIBUTING.md:** dev loop is `go build -o kit ./cmd/kit`, `GOMAXPROCS=2 go test -p 2 ./... -count=1`, `./kit docs lint`, `./kit portable-check . --profile public` (`CONTRIBUTING.md:10-15`). Durable tooling must be Go; a Python side tool is discouraged in favour of recording the missing Kit capability (`:3-6`). "Structural verification is not engine verification" rules (`:20-27`). GitHub Issues is the stated feedback channel; agents must ask their human before posting (`:29-36`). Command changes must regenerate `KIT_MANIFEST.json` and the API docs (`:49-58`), and credits go in `data/credits.json` / `NOTICE.md` (`:38-47`). PRs are not mentioned.
- **CI:** one workflow, `.github/workflows/test.yml`. It runs on `pull_request` and `push`, on ubuntu-latest, with `GOMAXPROCS=2 go test -p 2 ./...` (`:3-20`). The other two workflows are release-only.
- **Existing xsdat tests:** `pkg/xs/xsdat_test.go` (5 tests, built from inline byte streams), `pkg/xs/xsdat_decode_test.go` (3 ledger tests), `cmd/kit/xsdat_test.go` (1 CLI test). A new flag would fit this style easily.
- **Maintainer activity:** repo created 2026-09-06, last push 2026-11-05. 32 commits, mostly squashed "release"/"preview" commits by `chrae` (also committing as `ryan`), with releases every few days (v0.4.4 prepared 2026-11-04). 0 stars, 1 fork.
- **How PRs are handled:** all 11 external PRs (#1-#4, #8-#14, all by `SpiRaL-network`) were **closed without merging**. Each was closed within about a day (e.g. #8 opened 2026-10-17T23:54Z, closed 2026-10-18T00:47Z). Their content was ported into the maintainer's release commits and credited: `CHANGELOG.md:88-104` ("SpiRaL-network PR #8 ... #14"), `CHANGELOG.md:214-229` ("First Community Pull Requests", #1-#4), and `data/credits.json:236-250` ("PRs #2-#4 were ported as submitted; #1 was ported in part"). The issues by the same contributor (#15, #16) also got maintainer replies with engine probes within hours, and fixes in the next release.
- **Assessment:** an upstream PR or issue is realistic for a **small, generic** change. Good candidates are `--offset N` / framed-section decode, or a symmetric `kit xsdat encode --types ... --values ...`. Expect it to land as the maintainer's port in a release, not as our merge commit, and expect it to need Go tests plus regenerated manifest/API docs. Ageipelago-specific layout knowledge (a named `--schema ageipelago`) is unlikely to fit upstream: the built-in schemas are all aoe2kit's own fixtures. For that, use the `raw:N` type list, or a local fork / thin wrapper. A fork is only worth it if we cannot wait for a release cycle (days, judging by history) or need a non-generic feature.

## Implications for the injector map

1. Agent-side reads can use aoe2kit today with `--types raw:<prefix>,<result types...>,raw`. This only works if the prefix before the injector section has a length known in advance.
2. Ageipelago's location list runs to EOF with no count. Appending a section after it needs an Ageipelago change (count or marker), or a different placement.
3. aoe2kit cannot write request files. The client side needs an encoder (new upstream `kit xsdat encode`, or Python).
4. The profile path must be supplied by the agent or by our own helper. Polling would also be ours (the `WatchLocal` stat loop is a fine model).
