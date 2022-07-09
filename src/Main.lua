local ABS = _G.LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

function ABS:OnInitialize()
    self.db = _G.LibStub("AceDB-3.0"):New(ADDON_NAME, {})
    self.actions = ABS:GetModule("Actions")

    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, {
        name = ADDON_NAME,
        type = "group",
        args = {
            save = {
                type = "execute",
                name = "/abs save <profile>",
                desc = "Saves your current action bar setup under the given profile",
                func = self.actions.SaveProfile
            },
            restore = {
                type = "execute",
                name = "/abs restore <profile>",
                desc = "Changes your action bars to the passed profile",
                func = self.actions.RestoreProfile
            },
            rename = {
                type = "execute",
                name = "/abs rename <oldProfile> <newProfile>",
                desc = "Renames a saved profile from oldProfile to newProfile",
                func = self.actions.RenameProfile
            },
            delete = {
                type = "execute",
                name = "/abs delete <profile>",
                desc = "Deletes the saved profile",
                func = self.actions.DeleteProfile
            },
            list = {
                type = "execute",
                name = "/abs list",
                desc = "Lists all saved profiles",
                func = self.actions.ListProfiles
            },
        }
    }, {
        "absn",
        "actionbarsavernew"
    })
end