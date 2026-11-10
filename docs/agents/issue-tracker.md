# Issue tracker: Local Markdown

Issues for this repo live as markdown files in `.scratch/`.

## Conventions

- One effort per directory: `.scratch/<effort-slug>/`
- One file per ticket at `.scratch/<effort-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- A `**Status:**` line near the top records state
- Comments append under a `## Comments` heading at the bottom
- Settled decisions go in a `## Rulings` section above `## Comments`, one dated line each. Read it before asking the maintainer anything; a ruling there is closed

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (Destination / Notes / Decisions so far / Not yet specified / Out of scope).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, the question in the body. A `**Type:**` line records `research`/`prototype`/`grilling`/`task`; a `**Status:**` line records `open`/`claimed`/`resolved`/`out-of-scope`.
- **Blocking**: a `**Blocked by:**` line near the top listing ticket files. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are `open` and unblocked; lowest number wins.
- **Claim**: set `**Status:** claimed` and save before any work.
- **Resolve**: append the answer under `## Answer`, set `**Status:** resolved`, then append a gist + link to the map's Decisions so far.
- **Research assets**: findings land in `.scratch/<effort>/research/<slug>.md`, linked from the ticket. No research branches: agents never commit in this repo.
