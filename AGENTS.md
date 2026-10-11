# ActionBarSaver: Reloaded

A World of Warcraft addon that saves and restores action bar layouts with `/abs`. It runs inside the WoW client on Lua 5.1, so only the Lua standard library and the WoW API are available. `README.md` describes it from a player's side.

## One codebase for every client

One branch, `main`, builds the addon for every supported game client: Era, TBC, Wrath, Cata, Mists and Forever. `src/ActionBarSaverReloaded.toc` lists their interface versions on a single `## Interface:` line. The `release/*` branches are the old one-branch-per-client setup; leave them alone unless asked.

Clients differ in which WoW APIs they have. All of those differences live in `src/Compat.lua`:

- Add new client-specific behavior to `Compat`, then call `Compat.X` from the rest of the code. Don't call a client-specific API directly from anywhere else.
- Check whether the API exists (`C_Spell and C_Spell.PickupSpell`), not which client is running. `WOW_PROJECT_ID` and the interface version can't tell clients apart: Forever reports retail's project ID, and TBC Anniversary shares an interface version with TBC but has 180 action slots instead of 120.
- Files share state through the addon's private namespace (`local _, ns = ...`). Don't add new globals. `Str`, `Array`, `Dict`, `ADDON_NAME` and `MAX_MACROS` are older globals waiting to be moved into it.

## Layout

- `src/`: the addon. Files load in the order the `.toc` lists them.
  - `Main.lua` registers the addon, its saved variables and the `/abs` command.
  - `Actions.lua` implements the commands. Commands run with `self` set to the addon, not the module.
  - Sets and aliases are saved per class in `db.class.sets` and `db.class.spellAliases`.
- `libs/ace/`: the vendored Ace3 libraries, copied into the build as `Libs/`. Don't edit them.
- `spec/`: busted tests. `spec/helpers/wow.lua` is a fake WoW client.
- `build.cmd`: Windows-only script that copies a build into a local WoW install for testing.
- `.pkgmeta` and `.github/workflows/release.yml`: release packaging (see Releases).

## Tests and lint

Run both before calling a change done. CI runs them on every push and pull request (`.github/workflows/test.yml`).

One-time setup: a local Lua 5.1 toolchain in `.lua/`, which git ignores.

```sh
pip install hererocks   # or use a virtualenv
hererocks .lua -l5.1 -rlatest --no-readline
.lua/bin/luarocks install busted
.lua/bin/luarocks install luacheck
```

Then run:

```sh
.lua/bin/luacheck src spec
.lua/bin/busted
```

How the tests work:

- `wow.load(client)` gives each test a fresh copy of the addon running against a fake client: action bar, cursor, known spells, items, macros, equipment sets and combat state.
- Tests drive the addon the way a player does, with `game:slash("save mySet")`. They then check `game.bar`, `game.db` and `game:messages()`.
- `wow.clients` lists the API shapes being tested: namespaced vs. global APIs, and 120, 132 or 180 slots. Specs loop over every shape, so one test covers every client.
- When the addon starts using a new WoW API:
  - Add a fake for it in `spec/helpers/wow.lua`, only on the clients that have it.
  - Add its name to `read_globals` in `.luacheckrc`.
- Every bug fix comes with a test that fails before the fix. A known bug that isn't fixed yet goes in as a `pending(...)` test.

The fakes only model what the addon uses. Passing tests don't prove the addon works in a real client. Changes to how actions are picked up and placed still need a check in game.

## Releases

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) when a tag is pushed. `.github/workflows/release.yml` runs it, and it uploads to CurseForge and GitHub Releases.

- `.pkgmeta` moves `src/` to the top of the zip, moves `libs/ace/` to `Libs/`, and leaves out dev-only files. Add new dev-only files to its `ignore` list.
- The tag becomes the version: `## Version: @project-version@` in the `.toc` is replaced at build time, so don't edit it by hand. Use plain tags like `1.1.0`, not `v1.1.0`, because the tag is used as-is.
- The game versions shown on CurseForge come from the `## Interface:` line.
- The CurseForge changelog is `RELEASE_NOTES.md`. Before tagging, rename its `## Unreleased` heading to the version and date.
- Uploading needs a `CF_API_TOKEN` repository secret.
- To build a zip locally without uploading, run the packager's `release.sh -d` from the repo root. The zip goes in `.release/`, which git ignores.

## Conventions

- Commit messages follow Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, …).
- Pull requests target `main`.
- Match the surrounding style: 4-space indents, PascalCase for local functions and methods, short comments only where the reason isn't obvious.
- Player-visible changes get a line in `RELEASE_NOTES.md`.
