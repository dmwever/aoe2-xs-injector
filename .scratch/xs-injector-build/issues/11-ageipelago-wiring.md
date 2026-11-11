# 11: Ageipelago wiring

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** Ageipelago ships the injector wiring commented out. A developer uncomments it and can drive the injector inside a real Ageipelago match, while Ageipelago's own client keeps reading its packet.

**Blocked by:** 10: Host mode and TooLarge; outside this repo: Ageipelago's `LocationCount` packet change (reserved field 24) shipped live

**Status:** ready-for-agent

- [ ] Ageipelago carries, commented out: the core `#include`, `xsInjectUseHostWriter()` in `main()`, and the hook call just before `AP_Write`'s `xsCloseFile()`
- [ ] A single-line comment above them points at the recipe in the injector's hosting doc; no recipe text is duplicated
- [ ] Work in the Ageipelago repo follows the `ageipelago` skill's rules
- [ ] Live: with the wiring uncommented and a configured slot, `ping` and a chained request succeed during an Ageipelago match, and the Ageipelago client still reads its packet correctly
- [ ] Live: an unconfigured install (`AP_SLOT_ID == -1`) gives `Timeout/no-section`
