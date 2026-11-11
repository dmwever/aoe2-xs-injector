# Driver

**Type:** grilling
**Status:** resolved
**Blocked by:** 11-wire-format-versioning.md

## Question

What is the driver, and how does it run a request end to end?

- Form: a Python helper in this repo, a new aoe2kit subcommand, or both. The request side is settled ([Request format](03-request-format.md)): `xsinject.xsdat` via temp + `os.replace` with retry, next id = echoed id + 1, zero-call ping. The driver decodes the response section itself ([Response coexistence](04-response-coexistence.md)).
- Which `.xsdat` holds the response: `<campaign>` from a bundle, `default1` from editor test-play, the trailer magic as a filter, or a name the agent passes.
- The module's rule interval, the driver's poll interval, and the default timeout counted from sending a request ([Error reporting](10-error-reporting.md)).
- The agent-facing interface: how calls are named (function name vs id), how references are written, and what a decoded response looks like, including how each request status is rendered.

## Rulings

- 2026-11-10: The driver is a stdlib-only Python module with a thin CLI, in this repo next to the generator. aoe2kit is unchanged and stays the raw-inspection tool.
- 2026-11-10: Next request id = the id already in `xsinject.xsdat` + 1 (1 when the file is missing). The echoed id is used only to match a response to its request.
- 2026-11-10: The response file is found by scanning the profile folder's `*.xsdat` (skipping `xsinject.xsdat`) for files whose last 4 bytes are the trailer magic, modified after the send, and echoing the request id. More than one match is an error. `--map <name>` (and an API argument) pins one file.
- 2026-11-10: The module's request rule runs at `minInterval 1` / `maxInterval 1` (game seconds). Worst-case round trip is about 2 game-seconds hosted, about 1 standalone.
- 2026-11-10: The driver polls every 0.25 s; the default timeout is 10 s from a successful `os.replace`; the replace retry loop gives up after 5 s with `FileHeld`. All configurable.
- 2026-11-10: Calls are written as a JSON array of `{"fn": <name>, "args": [...]}`. Literals are plain JSON (int, float, string, `true`/`false` sent as int, vector `[x, y, z]`); a reference is `{"ref": N}`. The driver checks names, argument counts, literal types and references against the signatures before sending, then encodes the binary request layout of [Request format](03-request-format.md). The module never sees JSON; its parse-failure codes are a backstop.
- 2026-11-10: The CLI prints, and the API returns, one shape: `{"request_id", "status", "failed_call", "failed_argument", "message", "entries": [{"call", "fn", "status", "value"}]}`. The driver decodes values by the return types of the request it sent (vector `[x, y, z]`, bool `true`/`false`) and renders `message`. Driver statuses sit outside the wire codes 0-9: `Timeout` with `diagnosis` `no-section` / `older-id` / `stuck-running`, `FileHeld`, and `Invalid` (failed pre-send validation). The CLI exits 0 only on OK.
- 2026-11-10: Before writing the request, the driver saves it as `xsinject.last.json` in the profile folder (temp file + replace). `fetch` decodes the current response against it without sending anything.
- 2026-11-10: CLI commands: `run <file|->`, `ping`, `fetch`, `encode <file|->` (request bytes to stdout, unsent). Signature lookup stays in the generated data and the KB; no `functions` command.
- 2026-11-10: One generated `signatures.json` (name -> id, parameter types, argument-count range, return type) feeds both the XS generator and the driver. The profile folder comes from `--profile`, then `XSINJECT_PROFILE`, then auto-detecting the single `.../Age of Empires 2 DE/<steamid>/profile`.

## Answer

Grilled 2026-11-10. The decisions are the Rulings above. In short:

- **Form**: a stdlib Python module and CLI in this repo that shares one generated `signatures.json` with the XS generator. aoe2kit is unchanged.
- **Round trip**: the next id is read from the request file; the response is found by magic, modification time and echoed id, with `--map` to pin it. The rule runs every game-second, the driver polls every 0.25 s, and the timeout is 10 s.
- **Interface**: JSON in (function names, plain literals, `{"ref": N}`), validated and binary-encoded by the driver. JSON out, decoded by the driver, with its own `Timeout`/`FileHeld`/`Invalid` statuses next to the wire codes.
- **Late responses**: the last request is saved as `xsinject.last.json`, and `fetch` decodes against it.
- **CLI**: `run`, `ping`, `fetch`, `encode`.

Term in `GLOSSARY.md` (Driver status). Handed on: documenting the CLI, the JSON shapes, and which fix goes with each `Timeout` diagnosis ([Agent docs](13-agent-docs.md)).
