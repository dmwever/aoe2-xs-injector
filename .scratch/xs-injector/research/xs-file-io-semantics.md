# Research: XS file I/O semantics

Answers ticket [01-xs-file-io-semantics](../issues/01-xs-file-io-semantics.md). Researched 2026-11-10.

## Sources and tags

Every answer carries one tag:

- **documented**: stated by the KB catalog (`KB/docs/agent_database/xs_functions_catalog.json`, mirrored from the UGC guide) or by the live UGC page.
- **KB-claimed**: stated in `KB/docs/agent/references/XS_MEASURED_BEHAVIOR.md` with a `[M]` (measured in game) or `[D]` (documented and corroborated) marker. Section 10 of that file does not name its sources, so treat these as second-hand.
- **observed-in-code**: Ageipelago's shipping XS or the Archipelago `age2de` client does it, and the live protocol only works if it behaves that way. Cited by file and line.
- **unknown-needs-live-spike**: no written or code evidence. Settle in game.

Paths used below:

- `KB` = `C:\Users\DavidWever\Documents\GitHub\AoE2_AI_Modder`
- `AGP` = `C:\Users\DavidWever\Documents\GitHub\Ageipelago`; XS lives in `AGP/age 2 files/resources/_common/xs/`
- `ARC` = `C:\Users\DavidWever\Documents\GitHub\Archipelago\worlds\age2de`

Primary references:

- UGC function reference, File I/O section 13: https://ugc.aoe2.rocks/general/xs/functions/functions/ (local snapshot `KB/XS_Training/ugc.aoe2.rocks/general/xs/functions/functions/index.md:3833-3999`, fetched 2026-09-22; the live page still lists the same 16 entries, 13.1-13.16).
- Constants `cOffsetString` / `cOffsetInteger` / `cOffsetFloat` / `cOffsetVector`: `KB/docs/agent_database/xs_constants_catalog.json`.
- Forum bug report (build 61321, 2022): https://forums.ageofempires.com/t/xsdat-file-cannot-be-stored-in-correct-file-as-expected-for-campaigns/204962

The UGC docs say nothing about EOF, locking, handle count, the folder, or string limits. Most edge cases below are therefore code evidence or open.

## The API surface (documented)

All 16 File I/O functions are in the catalog, with the exact signatures copied from it:

| Prototype | What the doc says |
|---|---|
| `bool xsCreateFile(bool append)` | `append` is optional and defaults to `true`; `false` overwrites any existing file with the same name. Creates or appends to "a `.xsdat` file with the same name as the RMS/scenario being played". |
| `bool xsOpenFile(string filename)` | Name without `.xsdat`. Opens "an existing" file read-only. Returns `true` on success. |
| `bool xsWriteInt(int data)` | Signed 32-bit. "Causes an error if a file hasn't been opened before using." |
| `bool xsWriteFloat(float data)` | 32-bit IEEE 754. Same error note. |
| `bool xsWriteVector(vector data)` | 3 consecutive floats. Same error note. |
| `bool xsWriteString(string data)` | An unsigned 32-bit length, then that many bytes. Same error note. |
| `int xsReadInt()` / `float xsReadFloat()` | Bit-casts whatever is there; advances 4 bytes. |
| `vector xsReadVector()` | Bit-casts; advances 12 bytes. |
| `string xsReadString()` | Bit-casts; advances 4 + length bytes. |
| `bool xsSetFilePosition(int byteOffset)` | 0-indexed byte the next read starts from. |
| `bool xsOffsetFilePosition(int dataType, bool forward)` | Moves by the size of a `cOffset*` type; `forward` defaults to `true`. |
| `int xsGetFilePosition()` | 0-indexed byte the next read starts from. |
| `int xsGetFileSize()` | "Size (in bytes) of the currently open file." |
| `int xsGetDataTypeSize(int type)` | Bytes used by a `cOffset*` type. |
| `bool xsCloseFile()` | "Close the currently opened or created file." |

There is no bool reader or writer. Endianness is not documented. It is little-endian in practice: `ARC/campaign/XsdatFile.py:9-37` packs `<i`, `<f`, `<fff` and the live protocol round-trips (observed-in-code).

## 1. Reading past EOF

**What the readers return past EOF: unknown-needs-live-spike.** No doc states it.

- KB-claimed `[D]`: "Reading past EOF is unguarded" (`KB/docs/agent/references/XS_MEASURED_BEHAVIOR.md:162`). That says no error is raised, but not what value comes back.
- The forum report says a failed load "always return[s] -1", but that was about a missing file, not a short one, and on build 61321.
- Ageipelago never reads past EOF on purpose. Every variable-length reader bounds its loop by `xsGetFileSize() / 4`: `AP.xs:193`, `AP.xs:328`, `AP.xs:363`, `ItemHandler.xs:92`, `:104`, `:116`. The fixed-layout readers (`AP_Read`, `AP.xs:88-177`; `ReadMercenaryQueue`, `MercenarySeats.xs:148-168`) trust the writer's layout and never check. So the code gives no evidence about the returned value (observed-in-code: avoided, not exercised).

**Strings are the dangerous case.** KB-claimed `[M]`: "Reading a malformed length-prefixed string from a file can crash the game outright. Validate the length against the remaining file size before the read." (`XS_MEASURED_BEHAVIOR.md:79-80`). Ageipelago backs this up: `ReadMessages` keeps a commented-out guard, headed "Use this for hunting down messages that crash AoE2!" (`AP.xs:403-413`). The guard peeks the length with `xsReadInt`, compares it to `xsGetFileSize() - xsGetFilePosition()`, and rewinds with `xsSetFilePosition` (observed-in-code, though the guard is commented out).

**Is `xsGetFilePosition() >= xsGetFileSize()` a reliable EOF test?**

- Documented: both are byte counts on the same 0-indexed scale ("byte the next read will start from" and "size in bytes of the open file"). So `pos >= size` means EOF, and the safe test before a read is `pos + xsGetDataTypeSize(cOffsetInteger) <= size`. For a string, peek the length first, then require `pos + 4 + len <= size`.
- Unknown-needs-live-spike: Ageipelago never calls `xsGetFilePosition` in live code (only in the commented block at `AP.xs:405`), so the documented semantics have never been checked. Two things need checking: whether position advances exactly as documented, and whether `xsGetFileSize` is fixed when the file is opened or tracks a file that grows while it is open.
- A zero-length file opens and has size 0; it does not fail to open. KB-claimed `[D]` (`XS_MEASURED_BEHAVIOR.md:166-167`). Observed-in-code: `ReadItems` guards `fileInts < 1` after a successful open (`AP.xs:328-333`).

**For the injector:** always guard with size and position. Never let a read reach EOF, and validate every string length before calling `xsReadString`.

## 2. Does `xsOpenFile` see bytes written from outside mid-match? Locking?

**A fresh open sees the external writer's latest bytes: observed-in-code.** This is the most strongly evidenced point, because Ageipelago's whole protocol depends on it:

- The client rewrites `AP.xsdat` in place with `open(..., "wb")` on every poll tick (`ARC/client/GameClient.py:399-418`; the loop sleeps 0.5 s or 2 s, `GameClient.py:420-425`).
- The game reopens it every 2-4 s in rule `ReadAP` (`AP.xs:224-243`) and reads a new `Ping` each time (`AP.xs:103-108`). If the game cached the file, the ping would never change, and "AP Client disconnected" would fire after 5 repeats (`AP.xs:231-241`).
- The same holds for `items`, `locations`, `messages` and `mercenary_queue`. The client rewrites each of them mid-match, and the game rereads them on demand (`AP.xs:318-423`, `MercenarySeats.xs:148-168`).
- The reverse direction also works. The client overwrites the game's own output file mid-session to clear the active flag (`ARC/client/handlers/CampaignHandler.py:268-275`), and it deletes the request files the game polls (`GameClient.py:344-356`). A missing file then makes `xsOpenFile` return `false`, and the readers treat that as "nothing to do" (`AP.xs:31-33`, `AP.xs:323-327`). The false return on a missing file is also KB-claimed `[D]` (`XS_MEASURED_BEHAVIOR.md:168-169`).

**No caching across opens.** Observed-in-code (see above). Whether a file stays live while one handle is open (bytes written between `xsOpenFile` and `xsCloseFile`) is unknown-needs-live-spike. It barely matters, because XS runs a whole rule body synchronously, so the window is one rule execution.

**Locking or share mode: unknown-needs-live-spike.** Nothing documents how the engine opens the file.

- No failures are on record, but that is weak evidence. Every client write swallows exceptions with `print(ex)`, which does not reach the GUI log (`AGP/docs/agent/references/protocol.md:206-207`). A sharing violation would go unnoticed.
- In practice the game holds the handle only inside one rule body, and Ageipelago keeps reads short. A collision needs the external write to land during that window.

**Torn reads are a real risk.** KB-claimed `[D]`: "Neither side writes atomically. A reader polling a file its writer rewrites every tick will see torn reads." (`XS_MEASURED_BEHAVIOR.md:164-165`; same warning in `AGP/docs/agent/references/protocol.md:195-196`). The Python client truncates and rewrites in place, so the game can open the file truncated or half-written. Ageipelago copes through idempotence instead: ping echo, cursor-addressed windows (`AP.xs:335-339`), and acks. Ageipelago also runs its writer at 1/1 instead of `highFrequency` to keep collisions rare (`AGP/docs/agent/references/xs-mod.md:372-376`; that doc calls the rule `PublishAP`, but the code has `WriteAP` at `AP.xs:216-222`).

**For the injector:**

- The request should carry its own framing: a length or count header plus a sequence id, and a trailer or checksum if a torn tail matters. XS checks the declared size against `xsGetFileSize()` and ignores the request if they disagree.
- The agent should write to a temp file and `os.replace` it into place.
- Unknown-needs-live-spike: whether `os.replace` (MoveFileEx) can fail while the engine holds the target open, which depends on whether the engine passes `FILE_SHARE_DELETE`. The writer needs a retry loop either way.

## 3. One handle or several?

**Documented (implied):** the whole API assumes one implicit current file. Writers act on "the previously created" file, readers on "the previously opened" one, and `xsCloseFile` closes "the currently opened or created file". No call takes a handle.

**Observed-in-code:** Ageipelago never nests. Every `xsOpenFile` / `xsCreateFile` is closed before the next one, on every return path:

- readers: `AP.xs:29-41`, `88-177`, `188-204`, `318-423`; `ItemHandler.xs:87-121`; `MercenarySeats.xs:148-168`
- writer: `AP.xs:50-86`

The callbacks that run while a file is open (`GiveItem`, `UnlockTech`, `SyncSeat`) do not touch files. So the code shows that serial use works, not what nesting does.

**What happens on a second open or create while a file is still open: unknown-needs-live-spike.** It might implicitly close the first file, fail, or silently retarget the readers and writers.

**For the injector:** read the whole request into XS arrays, `xsCloseFile()`, run the calls, then `xsCreateFile(...)`, write the results, and `xsCloseFile()`. Never hold the request open while writing, and never call host code that might do file I/O between an open and its close.

## 4. Where `.xsdat` files live, and can XS read its own output?

**Folder:**

- Documented (UGC function docs): nothing about the folder.
- Observed-in-code: both directions use `<user folder>/profile/`. The client composes it as `user_folder + "/profile/"` (`ARC/client/GameClient.py:37`, `:336-337`), where the user folder is `C:/Users/<USER>/Games/Age of Empires 2 DE/<steam id>/` (`ARC/client/ApClient.py:35`). The protocol doc gives `$USER\Games\Age of Empires 2 DE\$STEAM_PROFILE\profile` for both reads and writes (`AGP/docs/communication_protocol.md:90`, `:101`).
- Historical bug, do not design around it: on build 61321 (2022), a campaign mission wrote its `.xsdat` into the mod's `resources\_common\campaign` folder and reads returned -1. A moderator acknowledged it, and it was never followed up in the thread (forum link above). Ageipelago now plays campaign missions that write `<campaign>.xsdat` into `profile/` and are read there, so current builds behave as the protocol doc says (observed-in-code).

**Names:**

- `xsOpenFile(name)` reads `profile/<name>.xsdat`. Documented (the extension is dropped) plus observed-in-code (`xsOpenFile("AP")` reads `profile/AP.xsdat`, `AP.xs:90` against `GameClient.py:401`).
- `xsCreateFile` takes no name. Documented: "same name as the RMS/scenario being played". Observed refinements:
  - A mission played from a campaign writes `<campaign>.xsdat`, not `<scenario>.xsdat` (`AGP/docs/communication_protocol.md:26-38`, `:101`). The client depends on this name to find the game (`ARC/client/handlers/CampaignHandler.py:165-188`).
  - KB-claimed `[M]` and Ageipelago-measured: some test scenarios wrote `default1.xsdat` instead of their scenario name. `US_Spike.xs` did (`XS_MEASURED_BEHAVIOR.md:170-172`), and so did `XsTesting.aoe2scenario` with script `Test.xs` (`AGP/docs/agent/references/xs-mod.md:457-462`). Neither source explains why. The cause (editor test-play? an unsaved scenario?) is unknown-needs-live-spike.

**Can `xsOpenFile` read the file `xsCreateFile` wrote?**

- Ageipelago's protocol doc says so in prose ("Each scenario can also read from its own file", `AGP/docs/communication_protocol.md:113-115`). No code does it, though: Ageipelago only ever opens files the client wrote.
- The XS side would need the output stem. `string xsGetMapName(bool showFileExtension)` is in the catalog ("Returns the name of the map currently being played"). Whether it matches the `.xsdat` stem in the campaign and `default1` cases is unknown.
- **Status: unknown-needs-live-spike.** The design does not need it if requests and responses use different files: the agent writes `<request>.xsdat` with a fixed name, and XS writes to its imposed name.

## 5. `xsCreateFile(true)` append semantics

**Documented:** `append` defaults to `true` and appends to an existing file; `false` truncates.

**KB-claimed `[D]`:**

- "Data is not durable until the close, so the robust logging idiom is truncate once, then open/append/close per record" (`XS_MEASURED_BEHAVIOR.md:160-161`). That idiom assumes append-after-truncate works across separate create/close pairs.
- Ageipelago repeats the durability rule (`AGP/docs/agent/references/xs-mod.md:463-464`).

**Observed-in-code:** Ageipelago only ever passes `false` (`AP.xs:55`). `AP_Write` can run twice in one tick, from rule `WriteAP` and again from `GiveVictory` (`AP.xs:206-210`), so two truncating creates in one tick are exercised. `true` is never used.

**Unknown-needs-live-spike:**

- Whether `xsCreateFile(true)` appends at the file's true current end. This matters if an external process has rewritten or truncated the file since XS last closed it, or if another XS writer (the host's `AP_Write`) truncated it in the same tick.
- Whether `xsCreateFile(false)` → write → `xsCloseFile()` → `xsCreateFile(true)` → write → `xsCloseFile()` in one rule leaves both payloads in order. This decides ticket 04 (response coexistence with a host that truncates every tick).

## 6. Size, length and encoding limits

**Documented:**

- Strings are a uint32 length plus raw bytes, with no terminator.
- Ints are signed 32-bit and floats IEEE 754 32-bit.
- `xsGetFileSize`, `xsGetFilePosition` and `xsSetFilePosition` all use `int`, so offsets cap at 2^31-1 (follows from the signatures).
- Nothing documents a file size limit, a string length limit or a character encoding.

**Observed-in-code:**

- The client writes strings as UTF-8 bytes with a signed `<i` length (`ARC/campaign/XsdatFile.py:34-37`), and the game reads them with `xsReadString` into `xsChatData` (`AP.xs:415-419`).
- The client strips `%` (rewritten to " percent") and `è` (rewritten to "e") first (`ARC/client/handlers/MessageHandler.py:84-87`). That points to two problems. `%` is likely format-string trouble in `xsChatData`, which has a printf-style overload (`XS_MEASURED_BEHAVIOR.md:77-78`). `è` suggests multi-byte UTF-8 does not survive, in the read or in the display. Which of the two fails is unknown.
- Bools travel as 4-byte ints (`AGP/docs/communication_protocol.md:15-16`; KB-claimed `[D]` `XS_MEASURED_BEHAVIOR.md:163`).

**KB-claimed `[M]`:** chat has a practical per-line length limit (`XS_MEASURED_BEHAVIOR.md:77-78`). That is a display limit, not a string limit.

**Unknown-needs-live-spike:**

- The maximum `xsReadString` / `xsWriteString` length.
- Whether a read string round-trips non-ASCII bytes, and whether `xsWriteString` emits UTF-8 or a code page.
- Any practical file size or read-count ceiling per rule execution. No source documents one, and Ageipelago's largest files are a few hundred ints, so it says nothing about large files.

## Unknowns that need a live spike

1. The values `xsReadInt` / `xsReadFloat` / `xsReadVector` / `xsReadString` return past EOF, and whether any of them raises an XS error instead of returning silently.
2. Whether `xsGetFilePosition` advances exactly as documented. Whether `xsGetFileSize` is fixed when the file is opened or tracks a file that grows while open.
3. The engine's share mode on `xsOpenFile` / `xsCreateFile`: can the agent `os.replace` or rewrite the request file while XS holds it open, or does that raise a sharing violation?
4. Nested handles: what `xsOpenFile` or `xsCreateFile` does while another file is still open (implicit close, failure, or silent retarget).
5. Whether `xsOpenFile(<own output stem>)` reads back what `xsCreateFile` wrote, and whether `xsGetMapName(false)` gives that stem (loose scenario, campaign mission, editor test-play).
6. Why some scenarios write `default1.xsdat`, and which launch modes do it.
7. `xsCreateFile(true)` after `xsCreateFile(false)` in the same rule or tick: both payloads present and in order. Whether append goes to the true end after an external rewrite.
8. String limits: maximum length, and how non-ASCII and UTF-8 bytes round-trip through `xsReadString` / `xsWriteString`.
9. Any per-rule ceiling on the number of reads or the file size that one rule execution can handle.

## Settled enough to design on

- A fresh `xsOpenFile` each poll sees the external writer's latest bytes; nothing is cached across opens (observed-in-code).
- A missing file makes `xsOpenFile` return `false`. A zero-length file opens with size 0 (observed-in-code, KB-claimed).
- Writes are not atomic on either side, so frame requests with a size header and a sequence id, and treat a mismatch as "not ready" (KB-claimed, observed-in-code).
- Bound every read by `xsGetFileSize()`, and length-check strings before reading: a bad length can crash the game (KB-claimed `[M]`, observed-in-code).
- Use one file at a time: read the request fully, close, then create and write the response, then close (documented single current file; observed-in-code serial use).
- Requests come from `profile/<fixed-name>.xsdat`; results go to the engine-imposed `<scenario-or-campaign>.xsdat` in the same `profile/` folder (observed-in-code).
