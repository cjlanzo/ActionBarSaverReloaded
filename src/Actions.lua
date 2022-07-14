local Actions = _G.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME):NewModule("Actions")

local pickupActionButton = {
    item = PickupItem,
    spell = PickupSpell,
    macro = PickupMacro
}

local function RestoreActionButton(index, actionButton)
    -- Clear the slot
    if GetActionInfo(index) then
        PickupAction(index)
        ClearCursor()
    end

    if not actionButton then return true end

    pickupActionButton[actionButton.type](actionButton.id)

    if GetCursorInfo() ~= actionButton.type then
        ClearCursor()
        return false
    end

    PlaceAction(index)

    return true
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
    Dict.iteri(warnings, function(warning) self:Print(warning) end)
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
    local errors = {}
    local warnings = {}

    -- Start with an empty cursor
    ClearCursor()

    for i = 1, MAX_ACTION_BUTTONS do
        local actionButton = set[i]

        if IsMacro(actionButton) and duplicates[actionButton.id] then AddWarning(warnings, actionButton.id, duplicates[actionButton.id]) end
        if not RestoreActionButton(i, actionButton) then
            table.insert(errors, string.format("Error: Unable to restore %s with id %s to slot %d", set[i].type, set[i].id, i))
        end
    end

    self:Print(string.format("Restored set '%s'", setName))
    Dict.iteri(warnings, function(warning) self:Print(warning) end)
    Dict.iteri(errors, function(error) self:Print(error) end)
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

function Actions:PrintUsage()
    self:Print("ABS Slash commands")
    self:Print("/abs save <set> - Saves your current action bar setup under the given set.")
    self:Print("/abs restore <set> - Restores the saved set.")
    self:Print("/abs delete <set> - Deletes the saved set.")
    self:Print("/abs list - Lists all saved sets.")
end