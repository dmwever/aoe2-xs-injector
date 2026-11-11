# 10: Host mode and TooLarge

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** A scenario or mod that already rewrites the game's own `.xsdat` every tick can opt in and carry the response section in its own writes, so its packet and the injector coexist. A response too large for the game's write limit comes back as TooLarge.

**Blocked by:** 06: All literal and return types

**Status:** resolved

- [x] `xsInjectUseHostWriter()` called from `main()` switches the module out of standalone mode
- [x] The host calls the write hook just before its own `xsCloseFile()`; the hook appends the current response section into the host's open file
- [x] The module keeps its last response and rewrites it on every host write, including the Running marker
- [x] If the section would push the file past 1,048,575 bytes (host bytes included, measured from `xsGetFilePosition()` at hook time, or from 0 standalone), it is sent as status 8 TooLarge with 0 entries
- [x] Driver-seam tests decode a section trailing an arbitrary host packet, and TooLarge
- [x] Live: a minimal test host that rewrites its packet every tick carries responses intact and its own packet still decodes; a request returning very large strings comes back TooLarge

## Answer

2026-11-11.

- XS core: `xsInjectUseHostWriter()` sets host mode, and after that `xsInjectRespond` only stores the response. `xsInjectWriteSection()` appends the kept response at the file's current position. It writes nothing before the first response, or when no file is open (`xsGetFilePosition() < 0`). Standalone mode calls the same hook right after `xsCreateFile(false)`, so it measures from 0. The section's byte size is computed once, in `xsInjectStoreResponse`: 32 fixed bytes plus each entry's size, with a string taking 8 + `strLen`. When position + size passes `cXsInjectWriteLimit` (1048575), the stored response becomes TooLarge with 0 entries. It stays TooLarge, so every later host write agrees. If the host's own bytes leave no room even for that 32-byte section, it is written anyway.
- Running: Running and the final response are stored in the same rule run, so a host only carries Running if a call stops the rule.
- Python: `wire.TOO_LARGE` and `wire.WRITE_LIMIT`. `tests/test_xs_contract.py` pins both against the XS consts. `tests/test_host_mode.py` uses a fake host that rewrites its packet plus the kept section every tick. It covers: values decoded after the host packet, the host packet intact in front of the section, Running waited past, Running kept giving `stuck-running`, and TooLarge.
- Live host: `xs/XsInjectHostTest.xs` writes `[tick][string][tick*2]` every game-second, then calls the hook.
- Live (XsTesting run as the host): before the first response, `default1.xsdat` was the 30-byte host packet alone. Request 58 (`xsGetMapWidth`, `strSubstring`, `strLen` with a reference) came back OK with 120, "bcd" and 3. Ticks later the file still held the host packet (ticks 224 and 227, `tick*2` matching) followed by the same 59-byte section. Request 59 (11 x `strTrim` on 100,000-byte strings, about 1.1 MB of response) came back TooLarge with 0 entries, as a 32-byte section after the host packet.
