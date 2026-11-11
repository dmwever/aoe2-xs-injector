# Response coexistence

**Type:** grilling
**Status:** resolved
**Blocked by:** 01-xs-file-io-semantics.md, 08-live-file-io-spike.md, 02-aoe2kit-xsdat-decoding.md

## Question

How do injector results share `<scenario>.xsdat` with a host that rewrites it every tick (Ageipelago's `AP_Write` uses `xsCreateFile(false)`)?

- Ordering: injector appends after the host's write each tick, the host calls the injector, or another arrangement.
- Framing so a reader finds the injector section: magic, length, request id, sequence.
- How a generic module learns it has a host writer, and the case with no host at all.
- What changes aoe2kit needs to read only the injector section.
- Ageipelago's packet ends in a location list that runs to EOF with no count (see aoe2kit xsdat decoding). Which Ageipelago change makes room: a location count from the reserved block, an end marker, or the injector section placed before the list? That is a cross-repo packet change under the ageipelago skill's hard rules (reserved block, version bump, client `skip_int`).
- The response must echo the request id it answers, including for a zero-call ping and a request that failed parsing ([Request format](03-request-format.md)).

## Rulings

- 2026-11-10: With a host, the host calls one injector function (working name `xsInjectWriteSection()`) just before its own `xsCloseFile()`, and the section is written into the host's open file. The module keeps the last response in its store so it can rewrite it on every host write.
- 2026-11-10: The section is a trailer at EOF: `[section body][section byte length][magic]`, and the body also opens with the magic. A reader finds it from EOF without knowing the host's layout.
- 2026-11-10: The host opts in by calling `xsInjectUseHostWriter()` from `main()`. Without that call the module is standalone: it writes the file itself with `xsCreateFile(false)` (section only), once per response. A host that writes the file without opting in wipes responses (documented). Accepted: Ageipelago's `AP_Write` writes nothing while `AP_SLOT_ID == -1`, so an unconfigured install shows no response.
- 2026-11-10: Section body: magic, request id, request status, entry count, then one entry per call in call order. An entry is a status int, followed by the value only when the status is OK and the function is non-void; a void OK entry is the status int alone. Values carry no type tag (the driver knows return types by function id). A ping or a failed parse has entry count 0, and the request status tells them apart. Codes are left to Error reporting.
- 2026-11-10: Ageipelago gets a `LocationCount` field from reserved field 24 (byte offset 92; reserved block 26 -> 25). `AP_Write` counts the non-`-1` ids in a first pass and writes exactly those; `Age2Packet` reads exactly that many and ignores trailing bytes. Minor `world_version` bump, `communication_protocol.md` table, and a layout test modelled on `test_mercenary_packet.py`. It ships live in Ageipelago as a cross-repo precondition of the spec, and is not built in this map.
- 2026-11-10: Ageipelago ships the injector wiring commented out: the `#include`, the `xsInjectUseHostWriter()` call in `main()`, and the hook call just before `AP_Write`'s `xsCloseFile()`. A developer uncomments them to enable the injector. No mutable stub.
- 2026-11-10: The injector's agent docs hold the enabling recipe (those lines, verbatim) as the source of truth. Ageipelago's commented block carries a single-line comment pointing at the recipe.
- 2026-11-10: The driver finds and decodes the response section itself, using the catalog's return types. aoe2kit is unchanged for the response path (a static `--types` list cannot follow status-dependent entries) and stays the tool for raw inspection. A general `--from-end`/trailer feature is an optional upstream ask, not required.

## Answer

Grilled 2026-11-10. Terms in `GLOSSARY.md` (Response, Entry, Response section, Host, Standalone). The decisions are the Rulings above. In short:

- **Hook**: a host calls the injector's write function just before its own `xsCloseFile()`, and the module rewrites its last response on every host write.
- **Trailer**: `[body][byte length][magic]` at EOF, with the body also opening with the magic, so a reader needs no host layout.
- **Opt-in**: `xsInjectUseHostWriter()` from `main()`. Otherwise the module is standalone and writes the file itself once per response.
- **Body**: magic, request id, request status, entry count, then entries of status [+ value]. A ping or a failed parse has zero entries.
- **Ageipelago**: `LocationCount` from reserved field 24, written live with a minor bump (cross-repo precondition). The injector wiring ships commented out under a one-line pointer to the recipe in the injector docs.
- **Decoding**: the driver decodes the section, and aoe2kit stays unchanged for raw inspection.

Handed on: status codes, the 1,048,575-byte write limit shared with the host, and the unconfigured-install case (map fog, Error reporting); which `.xsdat` holds the response (map fog, Driver); a version in the magic (map fog, Wire-format versioning).

