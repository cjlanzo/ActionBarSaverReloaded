---
name: changelog
description: Write the player-facing changelog for ActionBarSaver Reloaded. Use when a change affects players, when writing a PR, or when preparing a release tag.
---

# Player-friendly changelog

`CHANGELOG.md` is what players read. The packager uploads the whole file as the changelog for each release, on CurseForge and GitHub Releases (`manual-changelog` in `.pkgmeta`). Commit messages don't appear anywhere players see.

## Update it in the PR

A PR that changes something players notice adds lines to `CHANGELOG.md` in the same PR:

- New entries go under an `## Unreleased` heading at the top. Create the heading if it isn't there.
- One short bullet per change. Dev-only changes (tests, CI, build, docs) don't go in.

## Write for a player

- Describe what changed in the game, not in the code.
  - Good: `Macros that show a spell or an item now restore on Forever.`
  - Bad: `Use GetActionText for macro IDs.`
- Say which client is affected when only some are.
- If a fix leaves bad data in existing saved sets, put what the player must do first, such as re-saving the set with `/abs save`. Don't add code to repair or work around old saved data.

## Before tagging

1. Rename `## Unreleased` to the version you're about to tag, such as `## 2.1.0`.
2. Commit that to `main`, then tag the commit. The tag must include the renamed heading, because the packager reads the file at the tagged commit.
