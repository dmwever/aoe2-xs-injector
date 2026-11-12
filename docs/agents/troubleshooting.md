# Troubleshooting the XS function injector

Find the row for what the driver printed: `status`, plus `diagnosis` for a `Timeout`. Then work
through its causes from the top. Several rows can share a key, one per cause. Every fix is yours to
apply, except the human checklist in [driving](driving.md#ask-the-human-for-these-three-things-and-nothing-else).

Before resending after an `older-id` or `stuck-running` `Timeout`, try `python -m xsinject fetch`.
It recovers a response that arrived late without running the calls again. After `no-section` with
no match running, skip it: a request sent before the match started is never run, so `ping` and
resend once the match is up.

**First checks for `no-section`**, in order:

1. **You passed `--map`:** check that `<stem>.xsdat` exists in the profile folder and is being
   updated. If it isn't, the stem is wrong (editor test-play is `default1`), so drop `--map` or fix it.
   With `--map`, the message's "no .xsdat ... carries a response section" means only that file.
2. **Find the file the game writes.** It's the `.xsdat` whose modified time keeps moving while the
   match runs. Old files, such as earlier scenarios or `*.prev*` copies, don't count. If none is
   moving, nothing in the game is writing, so start with the first row.
3. If that file is being updated but carries no section, look at the host rows.

| Driver result | Likely cause | Fix |
|---|---|---|
| `Timeout/no-section` | No match is running, or the game is still loading. | Ask the human to start the match or editor test-play, then `ping`. |
| `Timeout/no-section` | The scenario doesn't include the injector, or the copied core failed to compile (the human saw an XS error). | Follow [hosting](hosting.md#standalone): copy both `xs/xsinject.xs` and `xs/xsinject_dispatch.xs`, include the core, and restart the match. |
| `Timeout/no-section` | A host writes the game's `.xsdat` without opting in, so each of its writes wipes the section. | Ask the human to confirm the host opt-in is uncommented. Check that `xsInjectUseHostWriter()` runs from `main()` and that `xsInjectWriteSection()` comes just before the host's `xsCloseFile()`. See [hosting](hosting.md#host-mode). |
| `Timeout/no-section` | The host writes something after the hook, so the trailer isn't at the end of the file. | Move `xsInjectWriteSection()` to be the last write before `xsCloseFile()`. |
| `Timeout/no-section` | The host isn't writing at all. In Ageipelago, the slot is unconfigured (`AP_SLOT_ID == -1`), so `AP_Write` writes nothing. | Install a seed with `/install` and restart the scenario. See [hosting](hosting.md#ageipelago). |
| `Timeout/no-section` | Wrong profile folder, or `--map` names a file the game doesn't write. | Check `--profile` / `XSINJECT_PROFILE`. Look in the profile folder for the `.xsdat` the game is updating, and pass its stem to `--map` (editor test-play is `default1`). |
| `Timeout/older-id` | **The game is paused** or sitting in a menu. The module only runs while game time moves, so the last section on disk still answers an earlier request. | Ask the human to unpause, then `fetch`. |
| `Timeout/older-id` | The game is running slowly, or a big request took longer than `--timeout`. | `fetch`. Next time, raise `--timeout`. |
| `Timeout/older-id` | A host stopped writing while an older file is still on disk. For example, an Ageipelago slot became unconfigured after a configured run, so the stale file's section answers the old request. | Treat it like the host-not-writing `no-section` row: get the host writing again (in Ageipelago, `/install` a seed and restart the scenario). |
| `Timeout/older-id` | The match was restarted or ended, and no module is running now. A request sent before the match started is never run: at startup the module adopts the id in the file without running it. | Ask the human to start the match, then `ping`, then resend. |
| `Timeout/older-id` | An earlier request called `xsDisableSelf()`, so the request rule is off. | Ask the human to restart the match. See [hosting](hosting.md#foot-guns). |
| `Timeout/older-id` | Another `.xsdat` carries an older section, and the one that answers isn't the one being read. | Pass `--map` with the right file's stem. |
| `Timeout/stuck-running` | A call stopped the rule mid-request (a runtime XS error, or `xsDisableSelf()`), so the `Running` marker before call #0 is all that was stored. | Find the call: resend the calls one at a time or in smaller groups, after restarting the match if later pings time out. Check the argument values against `xsinject/signatures.json` and `catalog/functions.json`. |
| `Timeout/stuck-running` | The request is still running when the timeout hits. This is rare, because a host carries `Running` only if a call stops the rule. | `fetch` with a longer `--timeout`. |
| `FileHeld` | The game had `xsinject.xsdat` open for the whole `--lock-timeout` (or another program held `xsinject.last.json`). Nothing was sent. | Resend. If it keeps happening, raise `--lock-timeout`. If it never clears, a call to `xsOpenFile` may have left a file open, so ask the human to restart the match. |
| `Invalid` | The request has an unknown function name, a wrong argument count, a literal of the wrong type, or a bad reference (forward, self, out of range, void, or wrong type). Nothing was sent. | Read `message`, `failed_call` and `failed_argument`, check `xsinject/signatures.json`, fix the request and resend. |
| `Invalid` | No profile folder was found, several were, or the `--profile` / `XSINJECT_PROFILE` folder doesn't exist. | Pass `--profile` or set `XSINJECT_PROFILE`. |
| `Invalid` | `fetch` has no readable `xsinject.last.json`. | Nothing was sent from this profile folder. Use `run`. |
| `Ambiguous` | Several `.xsdat` files carry a fresh response to this request. | Pass `--map` with the stem of the scenario's file. |
| `Undecodable` | The response's entries don't fit the calls sent, so the core in the host is stale. | Apply [the re-include rule](maintaining.md#the-re-include-rule), restart the match, and resend. |
| `Truncated` (2) | The request file ended before the call count was met. This happens when the module reads a literal as a longer type than the one the driver sent, which means a stale core. | Apply the re-include rule. If the request was crafted by hand, fix its counts. |
| `UnknownFunction` (3) | The host's dispatch is older than `signatures.json`, so it has no function with that id. | Apply the re-include rule. |
| `BadArgCount` (4) | The host's dispatch disagrees with `signatures.json` about argument counts. | Apply the re-include rule. |
| `BadTag` (5) | A misread earlier literal misaligned the read, which means a stale core. | Apply the re-include rule. If the bytes were crafted, use tag 0 (literal) or 1 (reference). |
| `BadReference` (6) | A reference doesn't point to an earlier call. The driver blocks this, so the bytes were crafted or the core is stale. | Fix the reference, or apply the re-include rule. |
| `ReferenceTypeMismatch` (7) | The host's dispatch has another return or parameter type than `signatures.json`. | Apply the re-include rule. |
| `TooLarge` (8) | The calls **ran**, but the response would push the `.xsdat` past 1,048,575 bytes (a host's own packet counts). | Split the reads into smaller requests, or read big strings in pieces. Don't blindly resend setters, because they already ran. |
| `TrailingBytes` (9) | Bytes were left after the last call. This happens when the module reads a literal as a shorter type than the one sent, which means a stale core. | Apply the re-include rule. If the bytes were crafted, fix the counts. |

**When a value looks wrong but the status is OK**, suspect a stale core too. A literal whose
parameter type was corrected (for example int to float) has the same size either way, so a stale
core reads it as the wrong type with no error. Apply the re-include rule first, and see
[maintaining](maintaining.md#the-re-include-rule). If it persists with a fresh core, the catalog
signature may be wrong, so see [maintaining](maintaining.md#correcting-a-signature).

For raw inspection, the response section is the trailer of the game's `.xsdat`:
`[body][body byte length][magic 0x1A4E5358]`. The body opens with the magic, then the request id,
status, failed call, failed argument and entry count.
