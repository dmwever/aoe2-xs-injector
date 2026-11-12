# 11: Ageipelago wiring

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** Ageipelago ships the injector wiring commented out. A developer uncomments it and can drive the injector inside a real Ageipelago match, while Ageipelago's own client keeps reading its packet.

**Blocked by:** 10: Host mode and TooLarge; outside this repo: Ageipelago's `CurrentPacketLocationCount` packet change (field 25), done in this ticket

**Status:** resolved

- [x] Ageipelago carries, commented out: the core `#include`, `xsInjectUseHostWriter()` in `main()`, and the hook call just before `AP_Write`'s `xsCloseFile()`
- [x] A single-line comment above them points at the recipe in the injector's hosting doc; no recipe text is duplicated
- [x] Work in the Ageipelago repo follows the `ageipelago` skill's rules
- [x] Live: with the wiring uncommented and a configured slot, `ping` and a chained request succeed during an Ageipelago match, and the Ageipelago client still reads its packet correctly
- [x] Live: an unconfigured install (`AP_SLOT_ID == -1`) gives `Timeout/no-section`

## Rulings

- 2026-11-11: Field 24 had already gone to `CheckedLocationsCount` (Ageipelago `690c1db`), so the count of ids in the packet takes field 25 (byte offset 96, reserved 25 -> 24) and is named `CurrentPacketLocationCount` (maintainer's name). Done as part of this ticket, not as a separate precondition.
- 2026-11-11: The opt-in sits at the top of Ageipelago's `InitAP()`, which every scenario's `main()` calls, rather than in 18 separate `main()`s. It is a flag set, so a repeat call is harmless.

## Comments

2026-11-11, agent:

- Ageipelago `AP.xs`: `AP_Write` writes `filteredCount` as `CurrentPacketLocationCount` (field 25) and then every filtered id, with no counting pass and no `-1` skip: `AddLocation` refuses id `-1`, so the ledger never holds one; the reserved loop is 24. `worldMinor` unchanged. Three commented-out lines: `// include "./xsinject.xs";` after the other includes, `// xsInjectUseHostWriter();` first in `InitAP()`, `// xsInjectWriteSection();` just before `AP_Write`'s `xsCloseFile()`. Each has the pointer `// XS function injector (off by default): recipe in aoe2-xs-injector/docs/agents/hosting.md` above it, so ticket 12 must create the doc at that path.
- Archipelago apworld: `Age2Packet` reads `current_packet_location_count` and then exactly that many ids (stopping early on a short file), skipping 24 reserved ints. `world_version` stays 0.3.0: 0.3.0 has not shipped, so the layout change rides in it (maintainer, 2026-11-11). `test_mercenary_packet.py` has a `TestTheCurrentPacketLocationCount` layout test, including trailing bytes that are not read as locations. The `test_identity.py` packet builder writes the count explicitly.
- Docs: Ageipelago `docs/communication_protocol.md` table (field 25, reserved 26-49), and `docs/agent` (`protocol.md` table, `SKILL.md` reserved count 24).
- Lint: `AP_Attila_1.xs` gives the same diagnostics as before with the wiring commented out. With it uncommented, the only additions are the 16 dispatch diagnostics that `XsInjectTest.xs` already shows in this repo.
- Not done: the two live checks. They need a seed installed (`/install`, so `AP_SLOT_ID != -1`), the three lines uncommented, and a human starting a scenario.

## Answer

2026-11-11. Shipped on the maintainer's 0.3.0 branches (Ageipelago `a941be7`, Archipelago `70a172493`), then brought onto `description-status`. `world_version` stays 0.3.0 because 0.3.0 has not shipped.

Live, Attila 1 (scenario 101), wiring uncommented, slot 1 installed, the driver run with `--map "AP Attila the Hun_<player>_<tag>"`, which is the scenario's own `.xsdat`:
- `ping` (request 60) came back OK.
- Request 61 (`xsGetMapWidth`, `strSubstring("abcdef",1,4)`, `strLen` taking `{"ref": 1}`, `xsGetGameTime`) came back OK with 144, "bcd", 3 and 44.
- The file was 263 bytes: the 196-byte AP packet, then a 67-byte response section. The client's `Age2Packet` decoded slot 1, scenario 101, minor 3, `CheckedLocationsCount` 8, `CurrentPacketLocationCount` 0, no location ids, and its installed version matched. Not checked live: a packet carrying a location id together with a section; the unit tests cover that case.

Unconfigured install (stub `SlotData.xs`, scenario restarted): `AP_Write` no longer writes, so the file kept its 17:07:22 timestamp.
- The first ping (62) gave `Timeout/older-id`, because the configured run's file was still on disk and its section answered request 61.
- With that stale file moved aside, ping 63 gave `Timeout/no-section`. The file was then put back.
- Ticket 12's troubleshooting table needs a row for this: a stale host file from an earlier configured run reads as `older-id`.

The wiring is commented out again and Ageipelago's working tree matches its commit.
