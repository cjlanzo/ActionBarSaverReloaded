local Actions = _G.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME):NewModule("Actions")

local function classifyAction(index)
    local actionType, id, subType, extraID = GetActionInfo(index)

    if actionType and id then

    end
end

function Actions.SaveProfile(profileName)
    if Str.nullOrEmpty(profileName) then
        print("Profile name must contain a value")
        return
    end

    -- db.Sets[playerClass][name] = db.Sets[playerClass][name] or {}

    -- local set = db.Sets[playerClass][name]
    print(string.format("called actions.saveProfile with '%s'", profileName))
end

function Actions:RestoreProfile(profileName)
    if Str.nullOrEmpty(profileName) then
        print("Profile name must contain a value")
        return
    end

    print(string.format("called actions.restoreProfile with '%s'", profileName))
end

function Actions:RenameProfile()
    print("called actions.renameProfile")
end

function Actions:DeleteProfile()
    print("called actions.deleteProfile")
end

function Actions:ListProfiles()
    print("called actions.list")
end

function Actions:PrintUsage()
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