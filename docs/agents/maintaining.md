# Maintaining the XS function injector

How to keep the generated dispatch true to the engine, and how to keep every host in step with it.
This repo needs nothing outside itself.

## What is generated from what

| File | Role | Edited by |
|---|---|---|
| `catalog/functions.json` | The function catalog: every XS function's name, parameters, optional count and return type. This is the source of truth, and this repo owns it. | Hand |
| `catalog/renames.json` | Old name → new name, so a renamed function keeps its id. | Hand |
| `xsinject/function_ids.json` | The pinned name → id table. New functions take the next free id. Ids are never reused, renames keep their id, and retired ids record why. | Generator (checked in) |
| `xsinject/signatures.json` | name → id, parameter types, `min_args`..`max_args`, return type. The driver validates and decodes from it. | Generator (checked in) |
| `xs/xsinject_dispatch.xs` | One `switch` case per function, with one call site per allowed argument count, plus the parameter-type table the module's parser uses. | Generator (checked in) |
| `xs/xsinject.xs` | The core module: request rule, parser, result store, response writer, host hook. Its byte layouts mirror `xsinject/wire.py`. | Hand, together with `wire.py` |

`signatures.json` and the dispatch come out of the same run. That is the only thing that keeps the
driver's validation and the module's dispatch in agreement.

## Regenerating

From the repo root:

```
python -m xsinject.generate
```

It reads `catalog/` and the pinned table, and rewrites `signatures.json`, `function_ids.json` and
`xs/xsinject_dispatch.xs`. It prints the counts. It fails (exit 1, nothing written) when:

- a pinned function has left the catalog with no rename entry. Add the rename to
  `catalog/renames.json`, or retire the function on purpose:
  `python -m xsinject.generate --retire <name> "<why>"`. Retiring keeps its id out of use forever
  and drops it from the dispatch, even when the catalog still lists it (as the AI-script-only
  `xsGetGoal` family is). `--retire` can be repeated, and the reason can't be empty.
- a catalog entry has a type that isn't int, float, bool, string, vector or void, or inconsistent
  counts.

Then:

1. `python -m pytest`. `tests/test_checked_in_outputs.py` fails until the checked-in outputs match a
   fresh regeneration.
2. **Compile gate.** Every catalog change has to pass a clean engine compile before it ships.
   Copy `xs/XsInjectDispatchCheck.xs` and `xs/xsinject_dispatch.xs` into
   `<profile>/resources/_common/xs/`, make the check file a scenario's script, and have the human
   start editor test-play. A clean compile means no XS error dialog, and chat shows
   `xsinject dispatch compiled`. On an error, see fix-and-relaunch below.
3. Apply [the re-include rule](#the-re-include-rule) to every host.

## Fix-and-relaunch

The catalog is engine-true only when the whole dispatch compiles. The engine stops at the first bad
call site and names the line, so each wrong signature costs one launch.

1. Have the human launch the compile gate above.
2. Find the named line in `xs/xsinject_dispatch.xs` and the function it calls. Read the error:
   - `void syscall/function cannot be called here`: the function is void, but the catalog gives it a
     return type.
   - `expression type does not match expected type`: the stored return type is wrong. **This
     doesn't rule out void** (`xsTaskUnits` gave it while catalogued as bool and turned out void).
   - `X is not a valid operator`: the function doesn't exist in scenario XS. Retire it with a
     reason.
   - No message: write a small probe that tries each variant (bare statement,
     `int r = ...`, `bool b = ...`, each argument count), as `.scratch/xs-injector-build/probes/xsBuildUnit.xs`
     did.
3. Correct the entry in `catalog/functions.json` (see below), regenerate, and relaunch.
4. Repeat until it compiles clean. Record the evidence (launch count, corrections) on the ticket
   that made the change.

## Correcting a signature

- Make the fix in `catalog/functions.json`, and only there. There is no override table.
- Mark the corrected entry with a `source` field saying how it was established: the engine compile
  or probe, the date, and the error text. For example:
  `"source": "engine compile, ... 2026-11-10: return type corrected bool -> void (\"void syscall/function cannot be called here\")"`.
- Fix the entry's `desc` and `prototype` if they now contradict the type.
- If `tests/test_checked_in_outputs.py` pins known corrections, add the new one there.
- **Reporting upstream is optional courtesy**: ugc.aoe2.rocks for the docs, and xs-check for the
  linter. Nothing here depends on them. Note on the ticket whether you reported it.
- A new game update can add or rename functions. Add them to the catalog (with renames in
  `catalog/renames.json`), regenerate, and pass the compile gate again.

## The re-include rule

**After any regeneration, or any change to `xs/xsinject.xs` or `xsinject/wire.py`, copy both
`xs/xsinject.xs` and `xs/xsinject_dispatch.xs` into every host's XS folder again, and restart the
match there.** XS compiles a scenario's script when the match starts, so a running match keeps the
old core until it restarts.

Hosts include the core by copying it. The known copies are:

- the scenario you drive, in `<profile>/resources/_common/xs/`
- Ageipelago: `Ageipelago/age 2 files/resources/_common/xs/` (see [hosting](hosting.md#ageipelago))
- any other scenario or mod that has included it

**Why this rule exists: the silent-misread risk.** The wire has no version, no fingerprint and no
mismatch status, by design: the driver and the core ship together from this repo. The driver
encodes every literal by the parameter types in the current `signatures.json`. A host's copy of the
dispatch parses it by the types it was generated with. When those disagree:

- A same-size type change (int ↔ float, int ↔ bool) is read **with no error**. The bytes of `1.5`
  read as an int give a huge integer, and the call runs with it. The result is `OK` and looks
  plausible. **Nothing detects this.**
- A size-changing type (string ↔ anything) misaligns the rest of the read and usually surfaces as
  `Truncated`, `BadTag` or `TrailingBytes`.
- A new function id gives `UnknownFunction`. A changed count range gives `BadArgCount`. A changed
  return type can give `ReferenceTypeMismatch`, `Undecodable` or a misread value.

Every one of those codes, other than a same-size misread, sends you back to this rule from
[troubleshooting](troubleshooting.md). The same-size misread sends you nowhere, so the only defence
is to follow the rule every time.

A related risk is accepted, not prevented: if the catalog itself is wrong about a same-size type,
XS converts silently, and a value can come back with the wrong type. The compile gate doesn't catch
it. Only a wrong-looking value does.

## Changing the wire layout

The layouts live in `xs/xsinject.xs` (module) and `xsinject/wire.py` (driver). Change both together.
`tests/test_xs_contract.py` pins the constants they share (magic, TooLarge code, write limit), so
extend it when you add one. A layout change is never versioned on the wire: the re-include rule is
the whole compatibility story.

## Docs and skill

These four docs live in `docs/agents/`. `tests/test_agent_docs.py` checks that the troubleshooting
table has a row for every status the driver can print, and that `driving.md` covers every CLI
command. Add a row and a mention when you add a status or a command.

The user-global `xs-injector` skill is kept in `docs/agents/skill/SKILL.md`. After changing it,
copy it to `~/.claude/skills/xs-injector/SKILL.md`.
