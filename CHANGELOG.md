# Changelog

## 2.0.0

- Re-save any set that contains macros. Sets saved with 1.0.0 on Forever or the Classic beta are missing some macro names, so those macros fail to restore with "Unable to restore macro with id [?]". Set your bars up again and run `/abs save <name>` to replace the set.
- Restoring a set that contains a flyout no longer stops with an error. The addon skips that slot, tells you which one, and restores the rest.
- One download now works on Era, TBC, Wrath, Cata, Mists and Forever.
