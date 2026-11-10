# XS file I/O semantics

**Type:** research
**Status:** resolved
**Blocked by:** none

## Question

What exactly does XS file I/O do at the edges the injector depends on?

- What `xsReadInt` / `xsReadString` / `xsReadFloat` / `xsReadVector` return, and whether they error, when reading past EOF. Is `xsGetFilePosition() >= xsGetFileSize()` the reliable EOF test?
- Does `xsOpenFile` see bytes written to the file from outside the game mid-match, or does it cache or lock the file? Can an external process write the file while the game has it open?
- Can a file be opened for reading while another is open or created for writing, or is there strictly one file handle?
- Where `.xsdat` files live on disk (profile folder path pattern) for both read and write, and whether `xsOpenFile` can read the name `xsCreateFile` writes.
- Does `xsCreateFile(true)` append at the true end of the file, and does it work after an `xsCreateFile(false)` in the same tick?
- Any size limits, string length limits, or encoding rules for `xsWriteString` / `xsReadString`.

Sources: the `aoe2-modding` KB catalogs first, then UGC docs (ugc.aoe2.rocks), then Ageipelago's `AP.xs` and `docs/communication_protocol.md` as evidence of observed behaviour. Mark each answer as documented, observed-in-code, or unknown (needs a live spike).

## Answer

Full findings: [research/xs-file-io-semantics.md](../research/xs-file-io-semantics.md). Docs give signatures and byte layouts only; most edge behaviour is unverified.

- Past-EOF reads: return value unknown; KB says unguarded, and a bad string length can crash the game (`Ageipelago/.../AP.xs:403-413` keeps a commented-out guard for exactly that). Design rule: check size and position before every read and every string length before reading it.
- External writes: each fresh `xsOpenFile` sees the external process's latest bytes (Ageipelago's ping depends on it). Neither side writes atomically, so requests need a size header and a sequence id. Engine share mode unknown.
- Handles: one current file implied; nested open/create unknown. Design rule: read request, close, create/write response, close.
- Location: `<user>/Games/Age of Empires 2 DE/<steamid>/profile/` both ways. `xsCreateFile` writes `<scenario>.xsdat` (campaign name for a campaign mission); some scenarios have written `default1.xsdat`, cause unknown.
- Append: `append` defaults true, false truncates. Same-rule `false` then `true` ordering is unverified, and Ageipelago only ever passes false.
- Limits: string is uint32 length + raw bytes; no documented size or encoding limits; `%` and non-ASCII are suspect (`MessageHandler.py:84-87`).
- Nine items need a live spike; they became the ticket [Live file I/O spike](08-live-file-io-spike.md).

## Comments

- Findings: [research/xs-file-io-semantics.md](../research/xs-file-io-semantics.md). Each answer is tagged documented / KB-claimed / observed-in-code / unknown-needs-live-spike; nine spike items are listed at the end.
