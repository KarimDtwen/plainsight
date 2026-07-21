---
name: progress-log
description: Close out a work session — update progress.md in the exact handoff format and sync the Notion roadmap page. Use at end of session, after commits land, or when asked to "update progress".
---

# Progress log contract

`progress.md` is the handoff log (same format as UniMatch). A fresh session must be able to pick up cold from it.

## After each committed chunk
1. Bump `_Last updated: YYYY-MM-DD_` under the title.
2. Keep ONE dated program section per work stream: `## <emoji> <Title> (YYYY-MM-DD) — <status>` where status ∈ `in progress` / `core landed` / `done`.
3. Inside it, log work as `**Done & committed:**` bullets, each shaped exactly:
   ``**`PS-0NN`** `abc1234` — what changed``
   (backtick-wrapped item ID, short commit hash, em-dash, description.)
4. Update in place: the `## Completed milestones` table (`| M | Title | Status |`, ✅ + hash + terse note), `## Current state` (branch @ hash, tree cleanliness, test counts), `## Next steps (in order)` (numbered, ✅/⚠️/⬜ prefixes, `**Manual (…)**` for Karim-only steps).
5. Append landmines to `## Gotchas / things to know` the moment they're discovered — never delete old ones.
6. Keep `## How to run / verify` commands current (analyze/test/pytest/build lines + seeder).
7. End every session entry with the acceptance line: `flutter analyze` clean · N Flutter tests · N backend tests.

## Notion sync (every close-out)
Page: **Plainsight — Build Roadmap** (id `3a4f8878-4309-812c-a09d-e70751d94af8`; load Notion tools via ToolSearch). Update the milestone table status glyphs (⬜ → 🔄 → ✅), and append one line to `# Session log`: date — what landed, test counts. Keep it terse; progress.md holds the detail.
