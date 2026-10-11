---
name: changelog
description: Write commit messages and squash-merge text for ActionBarSaver Reloaded so the CurseForge changelog reads well to players. Use when committing, writing a PR title or description, merging a PR, or preparing a release tag.
---

# Player-friendly changelog

The packager builds the CurseForge changelog from every commit message on `main` since the previous tag, full body included. No notes file exists, so whatever lands on `main` is what players read.

## Merge PRs with squash

Each PR should land as one commit. Its title and body become one changelog entry. In the squash dialog:

- **Title:** the PR title, in Conventional Commit form and written for players (see below).
- **Body:** at most a few short bullets that a player would care about. Delete the branch's commit list, `Co-Authored-By:` trailers and the "Generated with" line. All of those show up in the changelog word for word.

Commits pushed directly to `main` follow the same rules.

## Write the subject for a player

- Describe what changed in the game, not in the code.
  - Good: `fix: restore macros that show a spell or item on Forever`
  - Bad: `fix: use GetActionText for macro IDs`
- Say which client is affected when only some are.
- Keep the Conventional Commit prefix. `feat:` and `fix:` tell players what kind of change it is.
- Dev-only changes (`test:`, `ci:`, `build:`, `chore:`, `docs:`) still appear in the changelog. Keep them short. Where you can, fold them into the PR that needs them instead of landing them alone.

## Before tagging

Read what players will see:

```sh
git log "$(git describe --tags --abbrev=0)"..HEAD --format='- %B'
```

Use `git log --format='- %B'` if there are no tags yet. If an entry reads badly, the commit is already on `main`, so put the fix in the next PR. The changelog can also be edited on CurseForge after upload.
