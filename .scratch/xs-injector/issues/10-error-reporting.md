# Error reporting

**Type:** grilling
**Status:** resolved
**Blocked by:** 03-request-format.md, 04-response-coexistence.md

## Question

The response carries a request status and a status on every entry ([Response coexistence](04-response-coexistence.md)). What are the codes, and what does each failure produce?

- Request-level failures, which stop anything from running ([Request format](03-request-format.md)): a truncated request, an unknown function id, an argument count outside the function's range, a bad tag, a literal of the wrong type, a reference whose type does not match the parameter, a forward or self reference. Does the response say which call and which argument failed, and how (extra ints after the status, or a string)?
- Entry-level failures while running: what counts as a failed call when XS has no exceptions (a function that returns -1 or false is not an error), and whether one failed call stops the rest of the request.
- A response too large for the 1,048,575-byte file write limit, which the host's own bytes also count against: truncate the entries, or send an error status and no entries.
- How the agent tells "no response yet" apart from "the module isn't running", including Ageipelago writing nothing while `AP_SLOT_ID == -1`.

## Rulings

- 2026-11-10: Request status codes: `0` OK, `1` Running, `2` Truncated (file ends before the call count is met, or a string length runs past EOF), `3` UnknownFunction, `4` BadArgCount, `5` BadTag, `6` BadReference (forward, self or out of range), `7` ReferenceTypeMismatch, `8` TooLarge, `9` TrailingBytes (bytes left after the last call). A wrong-typed literal is not detectable: literals are read as the parameter's declared type, so it surfaces only as Truncated or TrailingBytes, if at all.
- 2026-11-10: The response header always carries `failed call #` and `failed argument #` after the request status, `-1` when not applicable. No message string; the driver renders the message from the request it sent.
- 2026-11-10: The module never judges a call's return value: -1 or false is a value, not a failure. Every call in a request runs; one call's result never stops the rest.
- 2026-11-10: Before running call #0 the module stores the response as status Running with 0 entries (standalone writes it; a host carries it on its next write). If an XS runtime error stops the rule mid-request, the response stays Running on that request id, and the driver reports that a call killed the rule.
- 2026-11-10: Entry status is `0` OK or `1` NotRun. No current path produces NotRun; it is reserved.
- 2026-11-10: A response that would push the file past the 1,048,575-byte write limit (host bytes included, measured from `xsGetFilePosition()` at hook time) is sent as status TooLarge with 0 entries. The calls have already run; the agent splits the request and re-sends the reads.
- 2026-11-10: Liveness is the driver's job, by a timeout counted from sending a request, never by a heartbeat, so the game may run or sit paused indefinitely between requests. No section in the file means the module is not writing (wiring commented out, an unconfigured Ageipelago with `AP_SLOT_ID == -1`, no match). A section echoing an older id means not caught up yet. Stuck at Running means a call killed the rule. The agent docs map each case to its fix.

## Answer

Grilled 2026-11-10. The decisions are the Rulings above. In short:

- **Request status**: ten codes, 0 = OK, 1 = Running, 2-9 parse failures plus TooLarge. Wrong-typed literals are undetectable by design.
- **Location**: a fixed header of request status, failed call #, and failed argument # (`-1` when n/a). The driver writes the message.
- **Running calls**: no return value is a failure; every call runs. A Running marker stored before call #0 exposes a rule killed mid-request.
- **Entries**: status OK or NotRun (reserved).
- **Write limit**: TooLarge and no entries. Side effects have already happened.
- **Liveness**: a driver timeout from the request, no heartbeat. No section, an older id, and stuck Running each map to a documented fix. A game paused with a request pending looks like a timeout; the docs say so.

Handed on: timeout values and the poll loop ([Driver](12-driver.md)); the per-case fixes in the agent docs ([Agent docs](13-agent-docs.md)).

