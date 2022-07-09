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

function ABS:HandleCommands(input)
    local cmd, args = Str.split(input, " ", 2)
    local fn = self.commands[Str.toLower(cmd)]

    if fn then fn(self, args) else self.actions.PrintUsage(self) end
end