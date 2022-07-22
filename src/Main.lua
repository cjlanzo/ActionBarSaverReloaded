local ABS = _G.LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

function ABS:OnInitialize()
    self.db = _G.LibStub("AceDB-3.0"):New(ADDON_NAME, {
        class = {
            spellAliases = {},
            sets = {},
        },
        profile = {
            autoRestoreOnRespec = false
        }
    })
    self.actions = ABS:GetModule("Actions")
    self.commands = {
        save        = self.actions.SaveSet,
        restore     = self.actions.RestoreSet,
        delete      = self.actions.DeleteSet,
        list        = self.actions.ListSets,
        alias       = self.actions.AliasSpell,
        unalias     = self.actions.DeleteSpellAliases,
        aliases     = self.actions.ListAliases,
        autorestore = self.actions.ToggleAutoRestoreOnRespec
    }

    self:RegisterChatCommand("abs", "HandleCommands")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- clean this up (naming of command??)
-- make it so you don't have to reload after toggling
-- ^^ -> make it doesn't start restoring multiple times if you spam toggle it (essentially does rehooking it keep making it do it more and more times?)
-- ^^ -> could make a self.hooked = true for when this gets set to true and not do it again if so?
function ABS:PLAYER_ENTERING_WORLD()
    if not self.db.profile.autoRestoreOnRespec then return end
    if not Talented then
        self:Print("Must have Talented addon installed to use autoRestoreOnRespec")
        return
    end

    hooksecurefunc(Talented, "ApplyCurrentTemplate", function(talented, ...)
        self.actions.RestoreSet(self, talented.db.profile.last_template)
    end)

end

function ABS:HandleCommands(input)
    local cmd, args = Str.split(input, " ", 2)
    local fn = self.commands[Str.toLower(cmd)]

    if fn then fn(self, args) else self.actions.PrintUsage(self) end
end

function ABS:Print(msg)
    print("|cff33ff99ABS|r: " .. msg)
end