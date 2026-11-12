# Driving the XS function injector

Call any XS function by name during a live AoE2:DE match and get its result back as JSON. The
driver writes a request to `xsinject.xsdat` in the profile folder. Once a game-second, the module
in the match runs it and writes a response section at the end of the game's own `.xsdat`. The
driver then reads that section and prints one JSON result.

Single player only. Every call runs in the real match, so a setter changes the game.

## Ask the human for these three things, and nothing else

1. **Start the match**, or editor test-play, of a scenario that includes the injector. For a quick
   check, use the test scenario in [hosting](hosting.md#standalone).
2. **Keep it unpaused.** The module only runs while game time moves. A paused game, or one sitting
   in a menu, answers nothing.
3. **Confirm the host opt-in is uncommented**, if the scenario has a host such as Ageipelago. See
   [hosting](hosting.md#ageipelago).

Everything else is yours to do: send the requests, read the results, and work through
[troubleshooting](troubleshooting.md). The game has no copy/paste, so never ask the human to read
chat or copy anything out of the game.

## Running the driver

Run it from this repo's root with Python 3.10+.
It uses only the standard library, so there is nothing to install.

```
python -m xsinject ping
python -m xsinject run request.json
python -m xsinject run -                  # the request JSON on stdin
python -m xsinject fetch
python -m xsinject encode request.json    # raw request bytes to stdout; sends nothing
```

| Command | What it does |
|---|---|
| `xsinject ping` | Sends a zero-call request. OK means the module is live and answering. Start every session with it. |
| `xsinject run <file\|->` | Validates the request, sends it, waits, and prints the result. |
| `xsinject fetch` | Sends nothing. Waits for and decodes the response to the last request sent from this profile folder (`xsinject.last.json`). Use it after a `Timeout` when you think the answer came late. |
| `xsinject encode <file\|->` | Validates the request and writes the bytes `run` would send to stdout. Use it to inspect or debug the wire format. On a mistake it prints the `Invalid` result instead. |

Options for `ping`, `run` and `fetch`:

| Option | Default | Use |
|---|---|---|
| `--profile <dir>` | `$XSINJECT_PROFILE`, then the single `~/Games/Age of Empires 2 DE/<steamid>/profile` | Pick the profile folder |
| `--map <stem>` | every `*.xsdat` except `xsinject.xsdat` | Read the response only from `<stem>.xsdat`. Editor test-play is `default1`. Under Ageipelago it is the scenario's file, e.g. `"AP Attila the Hun_<player>_<tag>"` |
| `--timeout <s>` | `10` | How long to wait for a response. Raise it for slow game speeds |
| `--poll <s>` | `0.25` | How often to check for the response |
| `--lock-timeout <s>` | `5` | `ping`/`run` only: how long to retry while the game holds the request file |

`ping`, `run` and `fetch` exit 0 only when `status` is `OK`. `encode` exits 0 when it wrote the bytes.

**Leave `--map` off by default.** The driver then checks every game `.xsdat` for the section it
needs. Pass `--map` only to settle `Ambiguous`, or under a host such as Ageipelago (see
[hosting](hosting.md#ageipelago)). It names the file the game writes, not the scenario: editor
test-play writes `default1` whatever the scenario is called. A wrong stem gives `Timeout`/`no-section`.

The same operations are a Python API that returns the same dict the CLI prints:
`xsinject.driver.run(calls, profile=..., map=..., timeout=..., poll=..., lock_timeout=...)`,
`ping(**options)` and `fetch(...)`. `encode(calls, profile=...)` returns bytes, or raises
`InvalidRequest`, whose `.result` is the `Invalid` dict.

The driver picks the request id itself: the id in `xsinject.xsdat` plus 1, or 1 when there is
none.

## The request

A request is a JSON array of calls. Each call is `{"fn": <name>, "args": [...]}`. You can leave
`args` out when there are none. Calls are numbered from 0 in the order you write them.

```json
[
  {"fn": "xsGetMapWidth"},
  {"fn": "strSubstring", "args": ["abcdef", 1, 4]},
  {"fn": "strLen", "args": [{"ref": 1}]}
]
```

An argument is a **literal** or a **reference**:

| XS parameter type | Literal |
|---|---|
| int | a JSON integer that fits in 32 bits |
| float | a JSON number |
| bool | `true` or `false` |
| string | a JSON string |
| vector | `[x, y, z]` |

Instead of a literal, any argument can be a **reference**, `{"ref": N}`: the result of the earlier
call #N in this request. Call #N's return type must be exactly this parameter's type.

- **Optional parameters** can be left off the end. XS then applies its own defaults, as it would in
  hand-written code.
- **References** only reach back within one request. Results don't survive to the next one, so put
  a whole chain in one request.
- **Every call runs**, in order, even when an earlier one returned something surprising.
- **-1 and false are values, not failures.** The module never judges a return value.

Signatures (names, parameter types, optional counts and return types) are in
`xsinject/signatures.json`: `min_args`/`max_args` give the allowed argument counts. What a function
does is described in `catalog/functions.json`. This doc lists no functions on purpose.
`signatures.json` is `{"functions": [{"name", "id", "params": [{"name", "type"}], "min_args",
"max_args", "returns"}]}`. For example, to list the functions that take an int as their first parameter:

```
python -c "import json;[print(s['name'],[p['type'] for p in s['params']],'->',s['returns']) for s in json.load(open('xsinject/signatures.json'))['functions'] if s['params'] and s['params'][0]['type']=='int']"
```

When you only want to look, prefer pure functions (`bit*`, `str*`) and plain getters such as
`xsGetMapWidth`. Anything that sets, creates, removes or spawns changes the running match, and
`xsGetRandomNumber*` is neither repeatable nor clearly free of side effects.

**`Invalid` catches name, count and type mistakes before anything is sent.** Before sending, the
driver checks every call against `signatures.json`: an unknown function name, the wrong argument
count, a literal of the wrong type, and a forward, self, out-of-range, void or wrong-type
reference. A mistake comes back as `Invalid` with `failed_call`, `failed_argument` and a message,
and nothing reaches the game, so fixing it costs no round trip.

## The result

```json
{
  "request_id": 61,
  "status": "OK",
  "failed_call": null,
  "failed_argument": null,
  "message": "OK",
  "entries": [
    {"call": 0, "fn": "xsGetMapWidth", "status": "OK", "value": 144},
    {"call": 1, "fn": "strSubstring", "status": "OK", "value": "bcd"},
    {"call": 2, "fn": "strLen", "status": "OK", "value": 3}
  ]
}
```

- One entry per call, in call order, so `call` lines up with your request.
- `value` is decoded by the function's return type: a vector as `[x, y, z]`, a bool as
  `true`/`false`. A void call still gets an entry, with `value` `null`.
- On any status other than OK, `entries` is empty. `failed_call` and `failed_argument` say where
  it failed (`null` when that doesn't apply). For `Invalid` and request-status failures, `message`
  names the call, the function, the parameter and the value you sent.
- `Timeout` results add a `diagnosis` key.

## Statuses

**Request statuses** come from the module, over the wire:

| Code | Status | Meaning |
|---|---|---|
| 0 | `OK` | Every call ran. The entries hold the results. |
| 1 | `Running` | Stored before call #0. You never see it as a final status: a response stuck here ends as `Timeout`/`stuck-running`. |
| 2 | `Truncated` | The request file ended before everything it promised was read. |
| 3 | `UnknownFunction` | The module has no function with that id. |
| 4 | `BadArgCount` | The module doesn't accept that many arguments for that function. |
| 5 | `BadTag` | An argument was neither literal nor reference. |
| 6 | `BadReference` | A reference didn't point to an earlier call. |
| 7 | `ReferenceTypeMismatch` | The referenced call's return type isn't the parameter's type. |
| 8 | `TooLarge` | The calls ran, but the response would push the `.xsdat` past the game's 1,048,575-byte write limit. Split the reads. |
| 9 | `TrailingBytes` | Bytes were left in the request file after the last call. |

Validation blocks 3-7 and 9 before sending. If the module reports one anyway, its core is stale:
see [troubleshooting](troubleshooting.md). In a parse failure no call runs.

**Driver statuses** never cross the wire. The driver reports them on its own:

| Status | Meaning |
|---|---|
| `Invalid` | The request was rejected before sending (or `fetch` has no readable `xsinject.last.json`, or no profile folder was found). Nothing was sent. |
| `Timeout` | No answer within `--timeout`. `diagnosis` says why: `no-section` (no `.xsdat` carries a response section), `older-id` (the newest section answers another request), or `stuck-running` (this request is still Running, so a call likely stopped the rule). |
| `FileHeld` | The game held the request file for `--lock-timeout` seconds. Nothing was sent. |
| `Ambiguous` | Several `.xsdat` files answered this request. Pass `--map`. |
| `Undecodable` | The response doesn't fit the calls sent. The core is stale. |

For every non-OK status, look up the fix in [troubleshooting](troubleshooting.md).

## Habits

- Start with `ping`. When it's OK, send the real work.
- Put a whole multi-step query in one request, chained with references.
- Keep each response under about 1 MB. Big strings are the usual cause of
  `TooLarge`.
- After a `Timeout`, try `fetch` before resending. Resending runs the calls again.
- Check the danger list in [hosting](hosting.md#foot-guns) before calling `xsDisableSelf` or any
  File IO function.
