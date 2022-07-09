local ABS = _G.LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

function ABS:OnInitialize()
    self.db = _G.LibStub("AceDB-3.0"):New(ADDON_NAME, {})
    self.actions = ABS:GetModule("Actions")
    self.commands = {
        save    = self.actions.SaveProfile,
        restore = self.actions.RestoreProfile,
        delete  = self.actions.DeleteProfile,
        rename  = self.actions.RenameProfile,
        list    = self.actions.ListProfiles,
    }

    self:RegisterChatCommand("absn", "HandleCommands")
end

-- function printUsage()
--     print("ABS Slash commands")
--     print("/abs save <profile> - Saves your current action bar setup under the given profile.")
--     print("/abs restore <profile> - Changes your action bars to the passed profile.")
--     print("/abs delete <profile> - Deletes the saved profile.")
--     print("/abs rename <oldProfile> <newProfile> - Renames a saved profile from oldProfile to newProfile.")
--     print("/abs list - Lists all saved profiles.")
--     -- print("/abs count - Toggles checking if you have the item in your inventory before restoring it, use if you have disconnect issues when restoring.")
--     -- print("/abs macro - Attempts to restore macros that have been deleted for a profile.")
--     -- print("/abs rank - Toggles if ABS should restore the highest rank of the spell, or the one saved originally.")
-- end

-- local commands = {
--     save = self.actions.SaveProfile,
--     restore = self.actions.RestoreProfile,
--     delete = self.actions.DeleteProfile,
--     rename = self.actions.RenameProfile,
--     list = self.actions.ListProfiles,
-- }



function ABS:HandleCommands(input)
    local cmd, args = Str.split(input, " ", 2)

    local fn = self.commands[Str.toLower(cmd)]

    if fn then fn(args) else self.actions:PrintUsage() end

    -- print(#info)
    -- print("HI")
    -- print(input)
    -- local cmd = self:GetArgs(input, 1)
    -- self.commands[cmd]
    -- -- local cmd, args = self:GetArgs(input, 2)
    -- print(cmd)
    -- print(args)
end