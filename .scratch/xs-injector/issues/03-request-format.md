# Request format

**Type:** grilling
**Status:** open
**Blocked by:** 01-xs-file-io-semantics.md, 08-live-file-io-spike.md

## Question

What does the request file the agent writes look like, and how does the `readFunction` rule consume it?

- File name and who creates it.
- One call per file, or a sequence of calls read until EOF.
- How a re-read of an unchanged file avoids re-running the same calls: a request id the module remembers, the agent truncating the file, or something else.
- Argument encoding per type, with bool carried as int. Already decided in [Value store and references](05-value-store-and-references.md): an int tag before each argument (`0` literal, `1` reference + call number), call numbers restart at 0 per request.
- An injected `xsOpenFile` / `xsCloseFile` / `xsCreateFile` or `xsDisableSelf` can close the request or stop the rule mid-request; every catalog function is dispatchable ([Function catalog](06-function-catalog.md)). Whether the module reads the whole request before running the first call, or guards these another way.
- Each call carries an int argument count after its function id ([Function catalog](06-function-catalog.md)).
