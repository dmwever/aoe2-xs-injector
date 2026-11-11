# Request format

**Type:** grilling
**Status:** resolved
**Blocked by:** 01-xs-file-io-semantics.md, 08-live-file-io-spike.md

## Question

What does the request file the agent writes look like, and how does the `readFunction` rule consume it?

- File name and who creates it.
- One call per file, or a sequence of calls read until EOF.
- How a re-read of an unchanged file avoids re-running the same calls: a request id the module remembers, the agent truncating the file, or something else.
- Argument encoding per type, with bool carried as int. Already decided in [Value store and references](05-value-store-and-references.md): an int tag before each argument (`0` literal, `1` reference + call number), call numbers restart at 0 per request.
- An injected `xsOpenFile` / `xsCloseFile` / `xsCreateFile` or `xsDisableSelf` can close the request or stop the rule mid-request; every catalog function is dispatchable ([Function catalog](06-function-catalog.md)). Whether the module reads the whole request before running the first call, or guards these another way.
- Each call carries an int argument count after its function id ([Function catalog](06-function-catalog.md)).

## Rulings

- 2026-11-10: The request file is `xsinject.xsdat` in the profile folder, a fixed name. Only the driver writes it and only the module reads it; a missing or empty file means nothing to run.
- 2026-11-10: One request holds many calls: `request id`, `call count`, then per call `function id`, `argument count`, then per argument `tag` + literal (the parameter's declared type, bool as int) or call number. Any future magic/version field goes in front of the request id. Every read is bounded by `xsGetFileSize()`.
- 2026-11-10: The module runs a request when its id differs from the last id seen (not greater). At startup it adopts the id already in the file without running it. An id counts as seen once its parse has been attempted, whether or not the parse succeeds. The driver's next id is the echoed id + 1.
- 2026-11-10: The module reads and checks the whole request into staging arrays, closes the file, then runs the calls. A request that fails parsing runs nothing. The generator also emits a per-function parameter-type table for the parser. `xsDisableSelf` stays dispatchable and is documented as a foot-gun.
- 2026-11-10: The driver writes a temp file, then calls `os.replace` onto `xsinject.xsdat`, retrying while XS holds the file. No byte-length field.
- 2026-11-10: A request with zero calls is valid (a ping). Its response echoes the id with no entries.

## Answer

Grilled 2026-11-10. Term in `GLOSSARY.md` (Request). The Rulings above are the decisions; in short:

- **File**: `xsinject.xsdat`, written only by the driver (temp file + `os.replace`, retried while XS holds the file); missing or empty means idle.
- **Layout**: request id, call count, then calls (function id, argument count, tagged arguments). Reads are bounded by file size, since -1 is a legal value.
- **Run once**: run when the id differs from the last seen; adopt the startup file's id unrun; a failed parse still marks the id seen.
- **Parse first**: the whole request is staged and the file closed before any call runs, so injected File IO cannot cut the read short. The generator emits a parameter-type table.
- **Ping**: a zero-call request is valid and echoes the id.

Handed on: the response echoes the request id ([Response coexistence](04-response-coexistence.md)); how a parse failure is reported (map fog, Error reporting); the rule interval and poll timing (map fog, Driver).

## Comments

- 2026-11-10: The reserved magic/version slot in front of the request id is withdrawn; no versioning ([Wire-format versioning](11-wire-format-versioning.md)).
- 2026-11-10: Sharpened by [Driver](12-driver.md): the driver takes its next id from `xsinject.xsdat` (+1), not from the echoed id; the echo only matches a response to its request.
