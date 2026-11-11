# Wire-format versioning

**Type:** grilling
**Status:** resolved
**Blocked by:** none

## Question

How do the module and the driver detect that they speak different wire formats?

- The request reserves room for a version field before its id ([Request format](03-request-format.md)). Is it an int version, and what does the module do on a mismatch: a new request status code, or reuse an existing one ([Error reporting](10-error-reporting.md))?
- Does the response section carry its version in the magic ([Response coexistence](04-response-coexistence.md)), in a separate field, or not at all?
- What bumps the version: any layout change, or also a change to the pinned function-id table ([Function catalog](06-function-catalog.md))? How the driver learns the module's id table (a table hash or catalog revision in the response, or nothing).

## Rulings

- 2026-11-10: No wire-format versioning. The request has no version field and stays `[request id][call count]...` as [Request format](03-request-format.md) ruled; its note reserving a magic/version field in front of the request id is withdrawn.
- 2026-11-10: The response section carries no version. Its fixed magic ([Response coexistence](04-response-coexistence.md)) is a finder only.
- 2026-11-10: No new request status code; codes stay 0-9 ([Error reporting](10-error-reporting.md)).
- 2026-11-10: No dispatch fingerprint or id-table hash on the wire. Driver/module mismatch, in layout or in signatures, is handled by process: driver and core ship together from this repo, and the agent docs tell developers to re-include the core in every host after any regeneration or layout change.

## Answer

Grilled 2026-11-10. Nothing on the wire detects a driver/module mismatch: no version in the request or the response, no fingerprint, no new status code. Considered and rejected: a frozen `[version][request id]` prefix with a `VersionMismatch` code, a version int after the response magic, and a generated dispatch fingerprint with a `DispatchMismatch` code. The known risk accepted: a host that vendors an older core than the driver's pinned table can misread a literal whose parameter type was corrected, silently.

Handed on: the re-include-after-regeneration rule and the silent-misread risk go in the agent docs ([Agent docs](13-agent-docs.md)).
