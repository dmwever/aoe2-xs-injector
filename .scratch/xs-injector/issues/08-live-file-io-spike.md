# Live file I/O spike

**Type:** task (HITL)
**Status:** open
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
