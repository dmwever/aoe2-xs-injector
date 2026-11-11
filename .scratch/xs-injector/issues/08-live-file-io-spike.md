# Live file I/O spike

**Type:** task (HITL)
**Status:** resolved
**Blocked by:** 07-game-machine-access.md

## Question

What does XS file I/O actually do at the ten edges research could not settle? One throwaway spike scenario on the game machine, run once, answers all of them. The list and the evidence behind each are at the end of [research/xs-file-io-semantics.md](../research/xs-file-io-semantics.md):

1. What `xsReadInt` / `xsReadFloat` / `xsReadVector` / `xsReadString` return past EOF, and whether they raise.
2. Whether `xsGetFilePosition` advances as documented, and whether `xsGetFileSize` is fixed at open or follows a growing file.
3. Engine share mode: can the agent rewrite or `os.replace` the request file while XS has it open?
4. What an open or create does while another file is still open.
5. Whether `xsOpenFile(<own output name>)` reads back what `xsCreateFile` wrote, and whether `xsGetMapName(false)` gives that name.
6. When and why a scenario writes `default1.xsdat`.
7. Whether `xsCreateFile(true)` after `xsCreateFile(false)` in the same rule keeps both payloads in order, and where append lands after an external rewrite.
8. Maximum string length; how UTF-8 and non-ASCII bytes survive a write and read.
9. Any ceiling on reads or file size within one rule execution.
10. Whether XS compiles and runs a ~289-case `switch` whose cases hold several call sites each ([Function catalog](06-function-catalog.md)).

Also settle the aoe2kit docs contradiction (sidecar "appears only at scenario end, locked during play" versus Ageipelago reading live every second); see [aoe2kit xsdat decoding](02-aoe2kit-xsdat-decoding.md).

The agent writes the spike XS and a checklist; the maintainer runs it and pastes the output. Resolved when every item has an observed answer.

## Spike

Assets live in [spike/](../spike/):

- [driver.py](../spike/driver.py) writes the `spike_*.xsdat` fixtures (`setup`), plays the outside writer during the match (`run`), and decodes the result afterwards (`final`). Fixtures are already in the profile folder.
- The live `Ageipelago/age 2 files/resources/_common/xs/Test.xs` is run A (items 1-9 and the docs contradiction). It holds no `AP.xs`. The previous `Test.xs` is saved as [Test.prev.xs](../spike/Test.prev.xs), and the old `default1.xsdat` as [default1.prev.xsdat](../spike/default1.prev.xsdat).
- Run B (item 10, the ~289-case `switch`) gets its own `Test.xs` after run A, so a compile failure there cannot cost run A's results.

XS steps through `spike_ctl.xsdat`, which the driver advances. Each step logs typed rows to the scenario's own `.xsdat` and rewrites the whole log, so the driver sees each step's result live if the file flushes on close. Steps 7-11 hold a file open for 12 game seconds while the driver reads, appends, overwrites, replaces or deletes it. Steps 13-17 are the crash risks (1 MB string, 1.6 MB read, string read past EOF, a 2 GB string length) and run last.

### Checklist, run A

1. Close the AP client, so nothing else touches the profile folder.
2. Launch `XsTesting` from **Single Player → Scenario** (not the editor). Game speed Normal; do not pause.
3. When chat shows `spike booted`, tell the agent. The agent starts `driver.py run`.
4. Leave the game alone. Chat shows `spike step N` and `spike released hold N`. The run takes about 4 minutes and ends at `spike step 99`.
5. If the game crashes or an XS error pops up, note the last `spike step N` in chat and the error text.
6. Quit to the main menu, then tell the agent.

### Checklist, run B

1. Open `XsTesting` in the **Scenario Editor** and press **Test**. Run B loads the same `Test.xs`, which the agent has regenerated.
2. If the script fails to compile, a popup shows. Note its text.
3. Chat shows `run B done: <name>` within a second or two. Quit to the menu and tell the agent.

## Answer

Observed 2026-11-10 on this desktop; run A from the Scenario menu, run B from the editor's Test button. Detail and evidence per item are in the run A comment below; files under [spike/run/](../spike/run/).

1. **Past EOF**: numeric reads return -1 / -1.0 / (-1,-1,-1), strings return ""; nothing raises, the position stays put, and a 2 GB string length does not crash. -1 is a legal value, so XS must bound every read by `xsGetFileSize()`.
2. **Position** advances exactly as documented, and set and offset work. Size is fixed at open, because outside writes are refused while the file is held.
3. **Share mode**: XS holds a real handle across rules. While it is open for reading, an outside read works, but write, append, `os.replace` and delete all fail. While it is open for creating, even an outside read fails. After `xsCloseFile`, everything works. The agent's writer needs a retry loop.
4. **One file at a time**: any `xsOpenFile` or `xsCreateFile` silently replaces the current file; nothing stacks.
5. **Own output**: `xsOpenFile(xsGetMapName(false))` reads back what `xsCreateFile` wrote. `xsGetMapName(false)` is the `.xsdat` stem.
6. **default1**: editor test-play saves the scenario as `default1.aoe2scenario` and runs it, so `xsGetMapName(false)` is `default1` and the output is `default1.xsdat`. From the Scenario menu it is `XsTesting.xsdat`.
7. **Append**: truncate then append in one rule keeps both payloads in order; after an outside rewrite, append lands at the true end.
8. **Strings** are raw bytes both ways (UTF-8 survives; `strLen` and `ord` count bytes; `chr(233)` writes the single byte e9). 1,000,000 bytes read whole. `%` only matters in chat.
9. **No read ceiling**: 400,000 ints from a 1.6 MB file in one rule.
10. **A 289-case `switch` with 373 call sites compiles and dispatches correctly** ([TestB.xs](../spike/TestB.xs), [generator](../spike/gen_run_b.py)). `round` called with one argument applies XS's own default (2 places).

**aoe2kit docs contradiction**: the game's own `.xsdat` is flushed at every `xsCloseFile` and is readable mid-match, and unload adds nothing. The "only at scenario end, locked during play" claim in aoe2kit's `SIDECAR.md` / `XS_SIDECAR_TECHNIQUE.md` is wrong for this build.

**Catalog signatures are not engine-true.** Run B first failed to compile on catalog signatures:

- `xsIsRuleGroupEnabled` is void in the engine ("void syscall/function cannot be called here"), not bool.
- `xsFlashUnit`'s third parameter `soundName` is not int ("expression does not match expression type"); `string` compiles.
- `xsBuildUnit(int, int, vector)` failed at line 1019 with no message.

Every catalog name is present in `AoE2DE_s.exe`, so these are type errors, not missing functions. Catalog ids 0-169 compile with the two overrides above; ids 170-273 are unverified. xs-check shares the catalog's errors, so only the engine can check the generated dispatch. Handed on as [Engine-true signatures](09-engine-true-signatures.md).

## Comments

### 2026-11-10, run A observed

Launched from Single Player → Scenario, Normal speed. All 18 steps and step 99 completed; no crash. Evidence: [driver log](../spike/run/driver_log.json), per-step snapshots of the game's own file under [spike/run/](../spike/run/), the XS as [TestA.xs](../spike/TestA.xs). Every row below is from `kit xsdat decode` of `run/step99/XsTesting.xsdat` (`ok=true`, 326 rows, no remaining bytes).

1. **Past EOF.** `xsReadInt` returns -1; `xsReadFloat` returns -1.0; `xsReadVector` returns (-1,-1,-1); a 2-byte tail reads as -1. Nothing raises, and the position does not move. `xsReadString` past EOF returns "" and does not move. A declared length of 0x7FFFFFF0 with 3 bytes behind it returns "" and leaves the position after the length prefix. No crash. -1 is a legal value, so EOF must be detected by size, never by the returned value. A zero-length file opens with size 0 and reads -1.
2. **Position.** It advances exactly as documented: 0, 4, 8, 15 (after "abc"), 27 (after a vector), 31. `xsSetFilePosition(4)` works; `-1` and past the end return false and leave the position alone. `xsOffsetFilePosition(cOffsetString)` skips the length prefix plus the string (+7 for "abc"), although `xsGetDataTypeSize(cOffsetString)` is 0; int 4, float 4, vector 12. Backwards works. File growth while open cannot happen: the engine refuses outside writes while it holds the file (item 3), so size is fixed at open.
3. **Share mode.** The engine holds a real OS handle across rules. While XS holds a file from `xsOpenFile`, an outside process can read it, but append, in-place overwrite, `os.replace` and delete all fail with "Permission denied", "Access is denied" or "being used by another process". While XS holds its `xsCreateFile` handle, even an outside read fails. After `xsCloseFile`, the outside rewrite succeeds (step 5). The held handle and a fresh reopen both still see the original bytes.
4. **Nesting.** No handles stack. A second `xsOpenFile` silently replaces the first (reads come from the new file at position 0; one close leaves nothing open, and a second close returns false). `xsCreateFile` while a file is open succeeds and replaces it; reads then return -1. `xsOpenFile` while a created file is open succeeds; the created file is closed with what it had (its later write returns false and never lands).
5. **Own output.** `xsGetMapName(false)` is `XsTesting` (with extension, `XsTesting.aoe2scenario`). `xsOpenFile(xsGetMapName(false))` reads back what `xsCreateFile` wrote, right after the close. `default0` is absent; `default1` opened the old Nov 8 file.
6. **default1.** Launched from the Scenario menu, the file is `XsTesting.xsdat`, not `default1`. Editor test-play is run B.
7. **Append.** `xsCreateFile(false)` → write → close → `xsCreateFile(true)` → write → close leaves both payloads in order (1,"A",2,"B"; 18 bytes). After an outside rewrite to (900,901), append lands at the true end: (900,901,3).
8. **Strings.** Bytes pass through untouched both ways. `strLen` counts bytes and `ord` returns byte values ("é" is 2, c3 a9; "日本" is 6). A lone 0xE9 byte survives. The written log holds `c3a9`, `e697a5e69cac`, `e9`, `256425732525` exactly. `chr(233)` writes the single byte e9 (not UTF-8); `chr(26085)` and `chr(0)` give "". `%` is harmless in files. A 1,000,000-byte string reads whole.
9. **Ceilings.** One rule read 400,000 ints from a 1,600,000-byte file, past the 1,048,575-byte write cap, with no limit hit; world time did not advance during the loop. No read ceiling was found.
10. Pending run B.

**aoe2kit docs contradiction.** The aoe2kit docs are wrong for this build. The game's own file is flushed at every `xsCloseFile`: the driver decoded each step's log within about 1-2 s of the step, all match long. It is locked only while an `xsCreateFile` handle is open. Ageipelago's live reading is the true picture.

With no file open, `xsCloseFile` and `xsWriteInt` return false, `xsReadInt` and `xsGetFilePosition` return -1, and `xsGetFileSize` returns 0.

### 2026-11-10, run B observed

Launched with the editor's Test button. The first three launches failed to compile on catalog signatures (line 103 `xsIsRuleGroupEnabled`, line 1009 `xsFlashUnit`, line 1019 `xsBuildUnit`). The final run filled cases 170-288 with call sites from cases 0-169, which had already compiled. It compiled and wrote [runB_default1.xsdat](../spike/run/runB_default1.xsdat) (`ok=true`): `xsGetMapName` = `default1` (`default1.aoe2scenario` with the extension), and dispatch results `strLen("abcd")` = 4, `strSubstring("abcdef",1,4)` = "bcd", `xsVectorSet(...).y` = 1.25, `round(2.567)` = `round(2.567, 2)` = 2.57.
