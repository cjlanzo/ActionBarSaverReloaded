local ABS = _G.LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

function ABS:OnInitialize()
    self.db = _G.LibStub("AceDB-3.0"):New(ADDON_NAME, {
        class = {
            spellAliases = {},
            sets = {},
        }
    })
    self.actions = ABS:GetModule("Actions")
    self.commands = {
        save    = self.actions.SaveSet,
        restore = self.actions.RestoreSet,
        delete  = self.actions.DeleteSet,
        list    = self.actions.ListSets,
        alias   = self.actions.AliasSpell,
        unalias = self.actions.DeleteSpellAliases,
        aliases = self.actions.ListAliases,
    }

    self:RegisterChatCommand("abs", "HandleCommands")
end

function ABS:HandleCommands(input)
    local cmd, args = Str.split(input, " ", 2)
    local fn = self.commands[Str.toLower(cmd)]

    if fn then fn(self, args) else self.actions.PrintUsage(self) end
end

function ABS:Print(msg)
    print("|cff33ff99ABS|r: " .. msg)
end