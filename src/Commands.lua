commands = {}

local function printUsage() -- add msg coloring?
    print("ABS Slash commands")
    print("/abs save <profile> - Saves your current action bar setup under the given profile.")
    print("/abs restore <profile> - Changes your action bars to the passed profile.")
    print("/abs delete <profile> - Deletes the saved profile.")
    print("/abs rename <oldProfile> <newProfile> - Renames a saved profile from oldProfile to newProfile.")
    -- print("/abs count - Toggles checking if you have the item in your inventory before restoring it, use if you have disconnect issues when restoring.")
    -- print("/abs macro - Attempts to restore macros that have been deleted for a profile.")
    -- print("/abs rank - Toggles if ABS should restore the highest rank of the spell, or the one saved originally.")
    print("/abs list - Lists all saved profiles.")
end

local handler = {
    save = actions.saveProfile,
    restore = actions.restoreProfile,
    rename = actions.renameProfile,
    delete = actions.deleteProfile,
    list = actions.list,
    help = printUsage
}

local function handleCmd(cmd, arg)
    local fn = handler[str.toLower(cmd)]

    if fn then fn(arg) else printUsage() end
end

function commands.handleCommands(input)
    local cmd, args = str.split(input, " ", 2)

    handleCmd(cmd, args)
end