# aoe2kit xsdat decoding

**Type:** research
**Status:** resolved
**Blocked by:** none

## Question

How does `chrae/aoe2kit` handle `.xsdat`, and what would it take to read an injector response out of a file another writer also uses?

- How `kit xsdat decode` knows the layout of an untagged binary file: a schema argument, heuristics, a sidecar manifest?
- Does it have an encoder (`kit xsdat encode` or a scenario recipe) the agent could use to write request files?
- Can it decode from an offset, or skip a known prefix (Ageipelago's packet), today?
- How it locates the profile `.xsdat` folder, and whether it watches or polls.
- Contribution route: does the repo take PRs, what is its test and CI setup, and is a fork or an upstream PR the realistic way to add append/section support?

Source: the GitHub repo itself (README, `cmd/kit`, the xsdat package, docs, issues).

## Answer

Full findings: [research/aoe2kit-xsdat-decoding.md](../research/aoe2kit-xsdat-decoding.md) (aoe2kit at `caa953b`).

- Layout comes from the caller: `--schema NAME` (15 Go decoders, aoe2kit-specific), a `.types` sidecar naming one of them, or `--types` as a comma list (`string,int,uint,float,vector,raw,raw:N`). Otherwise it guesses and labels every value as a guess. A decode is OK only if every byte is consumed.
- No encoder. `decode` is the only `xsdat` subcommand.
- No `--offset`, but `raw:N` skips a prefix of known length.
- Blocker found: Ageipelago's packet is 196 fixed bytes plus a location list that runs to EOF with no count (`Ageipelago/docs/communication_protocol.md:131`, `AP.xs:77-82`). Nothing appended after it can be found by aoe2kit, and Ageipelago's own client would read appended ints as location ids. Coexistence needs an Ageipelago packet change.
- aoe2kit never finds the profile folder (explicit paths only) and never watches `.xsdat`. `pkg/scenario/watch.go` (once-a-second file-change check) is a model for a poller.
- Contradiction to check live: aoe2kit docs say the sidecar appears only at scenario end and is locked during play (`docs/SIDECAR.md:67-70`), while Ageipelago's client reads its file live every second. Likely open-for-whole-game versus create/close per tick.
- Upstream: LGPL-3.0, one CI job (`go test`). Outside PRs get closed and re-landed by the maintainer in the next release with credit. Small general features (`--offset`, framed-section decode, `kit xsdat encode`) are realistic upstream asks; anything Ageipelago-specific belongs in a wrapper.

## Comments

- Research findings: [research/aoe2kit-xsdat-decoding.md](../research/aoe2kit-xsdat-decoding.md) (aoe2kit at `caa953b`).
