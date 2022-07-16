local Actions = _G.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME):NewModule("Actions")

local pickupActionButton = {
    item = PickupItem,
    spell = PickupSpell,
    macro = PickupMacro
}

local function RestoreActionButton(self, index, actionButton)
    -- Clear the slot
    if GetActionInfo(index) then
        PickupAction(index)
        ClearCursor()
    end

    if not actionButton then return true, nil end

    local aliases = self.db.class.spellAliases[actionButton.id] or {}
    local ids = Array.insert(aliases, actionButton.id, 1)

    for _, id in ipairs(ids) do
        pickupActionButton[actionButton.type](id)

        if GetCursorInfo() == actionButton.type then
            PlaceAction(index)
            return true, id
        end

        ClearCursor()
    end

    return false
end

local function IsMacro(actionButton) return actionButton and actionButton.type == "macro" end

local function GetMacroDuplicates()
    local t = {}
    local duplicates = {}

    for i = 1, MAX_MACROS do
        local macroName = GetMacroInfo(i)

        if macroName then
            if not t[macroName] then
                t[macroName] = 1
            else
                t[macroName] = t[macroName] + 1
                duplicates[macroName] = t[macroName]
            end
        end
    end

    return duplicates
end

local function AddWarning(warnings, macroName, usages)
    table.insert(
        warnings,
        string.format(
            "Warning: Found %d macros named '%s'. Consider renaming them to avoid issues",
            usages,
            macroName))
end

function Actions:SaveSet(setName)
    if Str.nullOrEmpty(setName) then
        self:Print("Set name cannot be empty")
        return
    end

    local duplicates = GetMacroDuplicates()
    local set = {}
    local warnings = {}

    for i = 1, MAX_ACTION_BUTTONS do
        local type, id = GetActionInfo(i)

        if type == "macro" then
            -- use macro name as the ID
            id = GetMacroInfo(id)
            if duplicates[id] then AddWarning(warnings, id, duplicates[id]) end
        end

        set[i] = type and {
            type = type,
            id = id
        }
    end

    self.db.class.sets[setName] = set
    self:Print(string.format("Saved set '%s'!", setName))
    Array.iter(warnings, function(warning) self:Print(warning) end)
end

function Actions:RestoreSet(setName)
    if Str.nullOrEmpty(setName) then
        self:Print("Set name cannot be empty")
        return
    end

    local set = self.db.class.sets[setName]

    if not set then
        self:Print(string.format("No set with the name '%s' exists", setName))
        return
    end
    if InCombatLockdown() then
        self:Print("Cannot restore sets while in combat")
        return
    end

    local duplicates = GetMacroDuplicates()
    local messages = {}

    -- Start with an empty cursor
    ClearCursor()

    for i = 1, MAX_ACTION_BUTTONS do
        local actionButton = set[i]

        if IsMacro(actionButton) and duplicates[actionButton.id] then AddWarning(messages, actionButton.id, duplicates[actionButton.id]) end
        
        local succeeded, restoredID = RestoreActionButton(self, i, actionButton)
        if not succeeded then
            table.insert(messages, string.format("Error: Unable to restore %s with id [%s] to slot %d", set[i].type, set[i].id, i))
        elseif actionButton and restoredID ~= actionButton.id then
            table.insert(messages, string.format("Info: Restored spell %d (%s) in place of spell %d", restoredID, GetSpellInfo(restoredID), actionButton.id))
        end
    end

    self:Print(string.format("Restored set '%s'", setName))
    Array.iter(messages, function(warning) self:Print(warning) end)
end

function Actions:DeleteSet(setName)
    if Str.nullOrEmpty(setName) then
        self:Print("Set name cannot be empty")
        return
    end

    if not self.db.class.sets[setName] then
        self:Print(string.format("No set with the name '%s' exists", setName))
        return
    end

    self.db.class.sets[setName] = nil

    self:Print(string.format("Deleted set '%s'", setName))
end

function Actions:ListSets()
    local sets = Dict.keysAsArray(self.db.class.sets)
    table.sort(sets)
    local setsStr = table.concat(sets, ", ")

    self:Print(not Str.nullOrEmpty(setsStr) and setsStr or "No sets found")
end

function Actions:AliasSpell(args)
    if Str.nullOrEmpty(args) then
        self:Print("Must provide args in the format 'spellID aliasID'")
        return
    end
    local spellID, aliasID = string.match(args, "(%d+)%s+(%d+)")

    spellID = tonumber(spellID)
    aliasID = tonumber(aliasID)

    if not (spellID and aliasID) then
        self:Print(string.format("Could not parse spellID and aliasID from '%s'", args))
        return
    end

    local aliases = self.db.class.spellAliases[spellID] or {}
    
    if Array.contains(aliases, aliasID) then
        self:Print(string.format("Spell %d is already aliased by %d", spellID, aliasID))
        return
    end

    table.insert(aliases, aliasID)
    self.db.class.spellAliases[spellID] = aliases

    self:Print(string.format("Added %d as an alias for %d", aliasID, spellID))
end

function Actions:DeleteSpellAliases(spellID)
    if Str.nullOrEmpty(spellID) then
        self:Print("Must provide a valid spellID")
        return
    end

    spellID = tonumber(spellID)

    if not self.db.class.spellAliases[spellID] then
        self:Print(string.format("No aliases to remove for spell with ID %d", spellID))
        return
    end

    self.db.class.spellAliases[spellID] = nil

    self:Print(string.format("Removed all aliases for spell with ID %d", spellID))
end

function Actions:ListAliases()
    local aliases = self.db.class.spellAliases

    if Dict.isEmpty(aliases) then
        self:Print("No aliases found")
        return
    end

    Dict.iter(self.db.class.spellAliases, function(spellID, aliases)
        self:Print(string.format("Spell %d is aliased by: %s", spellID, table.concat(aliases, ", ")))
    end)
end

function Actions:PrintUsage()
    self:Print("ABS Slash commands")
    self:Print("/abs save <set> - Saves your current action bar setup under the given <set>")
    self:Print("/abs restore <set> - Restores the saved <set>")
    self:Print("/abs delete <set> - Deletes the saved <set>")
    self:Print("/abs list - Lists all saved sets")
    self:Print("/abs alias <spellID> <aliasID> - Adds an alias with <aliasID> to <spellID>")
    self:Print("/abs unalias <spellID> - Removes all aliases associated with <spellID>")
    self:Print("/abs aliases - List all spell aliases")
end