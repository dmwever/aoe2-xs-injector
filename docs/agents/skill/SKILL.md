---
name: xs-injector
description: >
  The XS function injector for AoE2:DE: call any XS function by name during a live match and get
  the result back as JSON, through the xsinject driver and a module included in the scenario.
  Use whenever the task mentions xsinject, xsinject.xsdat, the XS function injector, the injector
  driver, `xsinject run` / `ping` / `fetch` / `encode`, a response section, xsInjectUseHostWriter,
  xsInjectWriteSection, xsinject_dispatch.xs, signatures.json, or wanting to call an XS function
  live, read game state from a running match, or check what an XS function really returns.
---

# XS function injector

```
REPO = C:\Users\dmwev\Documents\GitHub\aoe2-xs-injector
```

An agent calls XS functions in a running single-player match. The driver
(`python -m xsinject`, run from `REPO`) writes a request. The module in the scenario runs it once
per game-second and writes a response section. The driver prints one JSON result. The repo's docs
are the source of truth: open the one for your task before acting.

| You want to | Open |
|---|---|
| send calls, read results, learn the CLI, request/result JSON and statuses | `REPO/docs/agents/driving.md` |
| put the injector into a scenario or mod, or enable it in Ageipelago | `REPO/docs/agents/hosting.md` |
| act on a non-OK result (`Timeout`, `FileHeld`, `Invalid`, wire codes, `TooLarge`) | `REPO/docs/agents/troubleshooting.md` |
| regenerate the dispatch, fix a catalog signature, change the wire layout | `REPO/docs/agents/maintaining.md` |

Function signatures are in `REPO/xsinject/signatures.json`, and descriptions in
`REPO/catalog/functions.json`. No doc lists functions.

## Quick start

```
cd C:\Users\dmwev\Documents\GitHub\aoe2-xs-injector
python -m xsinject ping
python -m xsinject run request.json      # [{"fn": "strSubstring", "args": ["abcdef", 1, 4]}, {"fn": "strLen", "args": [{"ref": 0}]}]
```

Exit 0 means `OK`. For anything else, find the `status` (plus `diagnosis`) row in
`troubleshooting.md`.

## Ask the human only for these

1. Start the match or editor test-play of a scenario that includes the injector.
2. Keep it unpaused.
3. Confirm the host opt-in is uncommented, when there is a host such as Ageipelago.

Do everything else yourself. The game has no copy/paste, so never ask the human to read or copy
chat.

## Hard rule

**After any regeneration, or any change to `xs/xsinject.xs` or `xsinject/wire.py`, copy both
`xs/xsinject.xs` and `xs/xsinject_dispatch.xs` into every host again and restart its match.** A
stale core can misread a literal silently and still return `OK`. See `maintaining.md` → *The
re-include rule*.
