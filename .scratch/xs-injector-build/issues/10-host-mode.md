# 10: Host mode and TooLarge

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** A scenario or mod that already rewrites the game's own `.xsdat` every tick can opt in and carry the response section in its own writes, so its packet and the injector coexist. A response too large for the game's write limit comes back as TooLarge.

**Blocked by:** 06: All literal and return types

**Status:** ready-for-agent

- [ ] `xsInjectUseHostWriter()` called from `main()` switches the module out of standalone mode
- [ ] The host calls the write hook just before its own `xsCloseFile()`; the hook appends the current response section into the host's open file
- [ ] The module keeps its last response and rewrites it on every host write, including the Running marker
- [ ] If the section would push the file past 1,048,575 bytes (host bytes included, measured from `xsGetFilePosition()` at hook time, or from 0 standalone), it is sent as status 8 TooLarge with 0 entries
- [ ] Driver-seam tests decode a section trailing an arbitrary host packet, and TooLarge
- [ ] Live: a minimal test host that rewrites its packet every tick carries responses intact and its own packet still decodes; a request returning very large strings comes back TooLarge
