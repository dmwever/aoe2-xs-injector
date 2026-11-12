# Hosting the XS function injector

How to put the injector into a scenario or mod so an agent can [drive](driving.md) it. There are
two modes:

- **Standalone**: the scenario doesn't write the game's own `.xsdat` itself. Include the core and
  you're done. The module writes the response section into that file.
- **Host**: the scenario or mod already rewrites the game's own `.xsdat`, for example every tick.
  It opts in, and it carries the response section at the end of each of its own writes.

Either way, the injector is two files that sit side by side in the scenario's XS folder:

| File | What it is |
|---|---|
| `xs/xsinject.xs` | The core module. Include only this one. |
| `xs/xsinject_dispatch.xs` | The generated dispatch. The core includes it. |

The XS folder is `<profile>/resources/_common/xs/`. **Copy both files every time either one
changes** (see [the re-include rule](maintaining.md#the-re-include-rule)). A host running an old
core can misread arguments without any error.

## Standalone

1. Copy `xs/xsinject.xs` and `xs/xsinject_dispatch.xs` into the XS folder.
2. Add to the scenario's script:

   ```c
   include "./xsinject.xs";
   ```

3. Start the match. The module's rule runs on its own once a game-second. There's no call to make
   from `main()`.

The response lands in `<xsGetMapName(false)>.xsdat` in the profile folder. Editor test-play uses
`default1.xsdat`.

**Test scenario:** `xs/XsInjectTest.xs` is exactly this: the include and an empty `main()`. To use
it, copy it together with both core files into the XS folder, set it as a scenario's script, and
start editor test-play. `xs/XsInjectHostTest.xs` is the same thing as a minimal host (see below).

A standalone scenario must not write the game's `.xsdat` itself. If it does, the two writers wipe
each other's output. Use host mode instead.

## Host mode

A host is a scenario or mod that writes the game's own `.xsdat` (`xsCreateFile(false)`) itself. It
needs three lines:

```c
include "./xsinject.xs";

void main() {
    xsInjectUseHostWriter();      // 1. opt in, once, from main() or something main() calls
    ...
}

void MyWrite() {
    if (xsCreateFile(false) == false) {
        return;
    }
    // ... the host's own packet ...
    xsInjectWriteSection();       // 2. just before the host's own close
    xsCloseFile();
}
```

- `xsInjectUseHostWriter()` switches the module out of standalone mode. After that, the module
  stores each response and never writes the file itself. A repeat call is harmless.
- `xsInjectWriteSection()` appends the last stored response at the file's current position, so it
  must be the last write before `xsCloseFile()`. The module keeps that response and rewrites it on
  every host write, so a host that truncates the file every tick never loses it. Before the first
  response it writes nothing, and with no file open it does nothing.
- The section is a trailer: `[body][body byte length][magic]`, which a reader finds from the end of
  the file. The host's packet layout doesn't change, but **the host's own reader must ignore bytes
  after its packet**. For example, write an explicit count and read exactly that many.
- **Responses only arrive on host writes.** If the host stops writing (for example, when it is
  unconfigured or between phases), the driver times out.
- **TooLarge counts the host's bytes.** If the host's packet plus the section would pass
  1,048,575 bytes, the response goes out as `TooLarge` with no entries. The calls still ran.

> **Warning: a host that writes the file without opting in wipes every response.** Without
> `xsInjectUseHostWriter()`, the module writes the section standalone. The host's next
> `xsCreateFile(false)` truncates it, and the driver reports `Timeout`/`no-section`. Opt in and
> call the hook, or don't write the file.

`xs/XsInjectHostTest.xs` is a minimal working host. It writes `[tick][string][tick * 2]` every
game-second and then calls the hook.

## Ageipelago

This recipe is the source of truth for enabling the injector in Ageipelago. Ageipelago's `AP.xs`
carries the three lines commented out, each under a one-line pointer to this section:

```c
// XS function injector (off by default): recipe in aoe2-xs-injector/docs/agents/hosting.md
```

Ageipelago's repo folder `age 2 files/` is the live game folder, so files placed there are what the
game loads. The XS folder is `Ageipelago/age 2 files/resources/_common/xs/`.

To enable it:

1. Copy `xs/xsinject.xs` and `xs/xsinject_dispatch.xs` from this repo into Ageipelago's XS
   folder, next to `AP.xs`. They stay untracked there: don't commit them to Ageipelago.
2. In `AP.xs`, uncomment these three lines:
   - after the other includes at the top:

     ```c
     include "./xsinject.xs";
     ```

   - as the first statement of `InitAP()`, which every scenario's `main()` calls:

     ```c
     xsInjectUseHostWriter();
     ```

   - in `AP_Write`, just before its `xsCloseFile()`:

     ```c
     xsInjectWriteSection();
     ```

3. Install a seed with the client's `/install`. While `AP_SLOT_ID == -1` (the stub `SlotData.xs`),
   `AP_Write` writes nothing, so no response can arrive.
4. Start a scenario. Drive with `--map` set to the scenario's own `.xsdat` stem, which is
   `AP <scenario name>_<player>_<tag>`, e.g.:

   ```
   python -m xsinject ping --map "AP Attila the Hun_<player>_<tag>"
   ```

   Look for the matching `.xsdat` in the profile folder to get the exact stem. Without `--map`, a
   stale section in another file (such as an old `default1.xsdat`) can confuse a `Timeout`
   diagnosis.
5. When you're done, comment the three lines out again. Ageipelago ships with them commented out.

This works because Ageipelago's packet carries `CurrentPacketLocationCount` (field 25), and its
client reads exactly that many location ids. The section after them is never read as locations.

## Foot-guns

The dispatch covers every function in the catalog, including these. They are documented risks, not
blocked:

- **`xsDisableSelf()`** disables the injector's own request rule. After that, the module never
  reads another request, and every later request times out (`older-id`). If the call also cuts the
  current run short, that request stays `Running` (`stuck-running`). Restart the match to recover.
- **File IO calls** (`xsCreateFile`, `xsOpenFile`, `xsWrite*`, `xsCloseFile`, and so on). XS
  has one open file at a time, and opening or creating a file silently replaces the current one.
  The module reads the whole request and closes it before running any call, so a request can't cut
  its own read short. But a call to `xsCreateFile(false)` truncates the game's `.xsdat`, including
  a host's packet until its next write. A call that writes can also corrupt a response being built.
  Call these only when File IO is what you're testing, and expect to need a fresh response
  afterwards.
- **A host must call the hook last.** Anything it writes after `xsInjectWriteSection()` hides the
  trailer, and the driver sees `no-section`.
