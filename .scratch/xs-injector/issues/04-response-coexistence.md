# Response coexistence

**Type:** grilling
**Status:** open
**Blocked by:** 01-xs-file-io-semantics.md, 08-live-file-io-spike.md, 02-aoe2kit-xsdat-decoding.md

## Question

How do injector results share `<scenario>.xsdat` with a host that rewrites it every tick (Ageipelago's `AP_Write` uses `xsCreateFile(false)`)?

- Ordering: injector appends after the host's write each tick, the host calls the injector, or another arrangement.
- Framing so a reader finds the injector section: magic, length, request id, sequence.
- How a generic module learns it has a host writer, and the case with no host at all.
- What changes aoe2kit needs to read only the injector section.
- Ageipelago's packet ends in a location list that runs to EOF with no count (see aoe2kit xsdat decoding). Which Ageipelago change makes room: a location count from the reserved block, an end marker, or the injector section placed before the list? That is a cross-repo packet change under the ageipelago skill's hard rules (reserved block, version bump, client `skip_int`).
