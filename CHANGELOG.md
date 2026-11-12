# Changelog

## Unreleased

- Aliases are now named groups, and work in both directions: `/abs alias spell racials 20554 20549`. Groups can hold items and mounts too, and are shared by every character on your account. Your old aliases have been removed, so set them up again with the new command. Type `/abs` to see all the alias commands.

## 2.0.2

- Transmog outfits on your action bars now restore on Forever.

## 2.0.1

- Mounts now restore on Forever. Sets you already saved keep working, so you don't need to save them again.

## 2.0.0

- Re-save any set that contains macros. Sets saved with 1.0.0 on Forever or the Classic beta are missing some macro names, so those macros fail to restore with "Unable to restore macro with id [?]". Set your bars up again and run `/abs save <name>` to replace the set.
- Restoring a set that contains a flyout no longer stops with an error. The addon skips that slot, tells you which one, and restores the rest.
- One download now works on Era, TBC, Wrath, Cata, Mists and Forever.
