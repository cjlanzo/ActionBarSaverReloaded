# ActionBarSaver:Reloaded

## Overview

ActionBarSaver:Reloaded is an addon for saving and restoring action bar profiles. It is based on the original ActionBarSaver addon but is a full re-write.

All sets are saved by class rather than by character. Additionally, when you list profiles, you will only see profiles that pertain to your class.

Features such as rename have been deleted for simplicity. To perform a rename, simply save the set with a new name and delete the old set. Additionally, restoring a set will no longer try to re-create macros that do not exist. It will simply notify you of the missing macro and restore nothing for that slot. ABS:R will not work properly if you have multiple macros with the same name, and will warn you of potential issues if you restore a set that has a macro with a shared name.

A new feature has been added for setting up aliases for spells. A common use case for this would be restoring a single set for two characters that share a class but have a different race. For example, you could create a set on a troll shaman that contains `Berserking` and then add an alias for `War Stomp` using `/abs alias 20554 20549`. If you do this, when you restore a set it will first try to restore the proper spell but will also try each alias that you set up. A spell can have as many aliases as you want.

## Usage

`/abs save <set>` - Saves your current action bar setup under the given <set>\
`/abs restore <set>` - Restores the saved <set>\
`/abs delete <set>` - Deletes the saved <set>\
`/abs list` - Lists all saved sets\
`/abs alias <spellID> <aliasID>` - Adds an alias with <aliasID> to <spellID>\
`/abs unalias <spellID>` - Removes all aliases associated with <spellID>\
`/abs aliases` - List all spell aliases

## Known Issues

* Aliases should do not work both ways. If you alias `Berserking` as `War Stomp` and then save a set that contains `Berserking`, it will work properly if you restore that set on a tauren. However, if you save a set that contains `War Stomp` and try to restore it on a troll, it will fail. This will be addressed in a future version.