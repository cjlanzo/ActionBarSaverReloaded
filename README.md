# ActionBarSaver:Reloaded

## Overview

ActionBarSaver:Reloaded is an addon for saving and restoring action bar profiles. It is based on the original ActionBarSaver addon but is a full re-write.

All sets are saved by class rather than by character. Additionally, when you list profiles, you will only see profiles that pertain to your class.

Features such as rename have been deleted for simplicity. To perform a rename, simply save the set with a new name and delete the old set. Additionally, restoring a set will no longer try to re-create macros that do not exist. It will simply notify you of the missing macro and restore nothing for that slot. ABS:R will not work properly if you have multiple macros with the same name, and will warn you of potential issues if you restore a set that has a macro with a shared name.

Alias groups let one set work on characters that can't have the same spells, items or mounts. For example, a troll has `Berserking` and a tauren has `War Stomp`. Put both in a group with `/abs alias spell racials 20554 20549`, and restoring a set that has either one places whichever one the character has. A group can hold as many IDs as you want, and works in both directions. Groups are kept per type (`spell`, `item` or `mount`), so you name the type in every alias command. Groups are shared by every character on your account.

To copy a set to another account, run `/abs export <set>` and copy the text it shows. On the other account, run `/abs import` and paste it. Only that set is replaced, so the other account keeps its own alias groups, and restoring the set swaps in that character's racials and mounts. `/abs export aliases` copies your alias groups the same way. Importing never overwrites a set or alias groups without asking first. A set can only be imported on a character of the same class.

## Usage

Every command also works as `/absr`. Use it on clients where `/abs` is taken, such as French, where `/abs` means `/afk`.

`/abs save <set>` - Saves your current action bar setup under the given <set>\
`/abs restore <set>` - Restores the saved <set>\
`/abs delete <set>` - Deletes the saved <set>\
`/abs list` - Lists all saved sets\
`/abs alias <spell|item|mount> <group> <id> [id...]` - Adds IDs to an alias group, creating it if needed\
`/abs unalias <spell|item|mount> <group> [id...]` - Removes IDs from a group, or the whole group if no IDs are given. A group with no IDs left is deleted\
`/abs aliases` - Lists all alias groups\
`/abs export <set>` - Shows the <set> as text to copy to another account\
`/abs export aliases` - Shows your alias groups as text to copy to another account\
`/abs import [set]` - Imports a set or alias groups. Give <set> to save the set under a different name
