local _, ns = ...
local Compat = ns.Compat
local Actions = _G.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME):NewModule("Actions")

local pickupActionButton = {
    item = Compat.PickupItem,
    spell = Compat.PickupSpell,
    macro = Compat.PickupMacro,
    companion = Compat.PickupSpell,
    equipmentset = Compat.PickupEquipmentSet,
    summonmount = Compat.PickupMount,
    outfit = Compat.PickupOutfit,
}

-- Action types whose cursor type differs from what the action bar reports
local cursorType = {
    summonmount = "mount",
}

-- Alias groups are kept per action type. Players name the type, and mounts
-- show on the action bar as "summonmount".
local aliasTypes = {
    spell = "spell",
    item = "item",
    mount = "summonmount",
}
local aliasTypeNames = { spell = "spell", item = "item", summonmount = "mount" }

local function FindAliasGroup(self, actionType, id)
    for label, ids in pairs(self.db.global.aliasGroups[actionType] or {}) do
        if Array.contains(ids, id) then return label, ids end
    end
end

local function RestoreActionButton(self, index, actionButton)
    -- Clear the slot
    if GetActionInfo(index) then
        PickupAction(index)
        ClearCursor()
    end

    if not actionButton then return true, nil end

    -- e.g. flyouts, or equipment sets on a client without them
    local pickup = pickupActionButton[actionButton.type]
    if not pickup then return false end

    local ids = { actionButton.id }
    local label, group = FindAliasGroup(self, actionButton.type, actionButton.id)
    for _, id in ipairs(group or {}) do
        if id ~= actionButton.id then table.insert(ids, id) end
    end

    for _, id in ipairs(ids) do
        pickup(id)

        if GetCursorInfo() == (cursorType[actionButton.type] or actionButton.type) then
            PlaceAction(index)
            return true, id
        end

        ClearCursor()
    end

    -- The group's label, so the error can say the group was tried too
    return false, nil, label
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

    for i = 1, Compat.MaxActionSlots do
        local type, id = GetActionInfo(i)

        if type == "macro" then
            -- Use the macro name as the ID. Mainline clients report the spell or
            -- item a macro shows in place of its index, so ask the slot instead
            id = GetActionText(i)
            if duplicates[id] then AddWarning(warnings, id, duplicates[id]) end
        end

        if type and id then
            set[i] = {
                type = type,
                id = id
            }
        end
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

    for i = 1, Compat.MaxActionSlots do
        local actionButton = set[i]

        if IsMacro(actionButton) and duplicates[actionButton.id] then AddWarning(messages, actionButton.id, duplicates[actionButton.id]) end

        local succeeded, restoredID, groupLabel = RestoreActionButton(self, i, actionButton)
        if not succeeded and groupLabel then
            table.insert(messages, string.format("Error: Unable to restore %s %d or anything in its group '%s' to slot %d",
                aliasTypeNames[actionButton.type], actionButton.id, groupLabel, i))
        elseif not succeeded then
            table.insert(messages, string.format("Error: Unable to restore %s with id [%s] to slot %d", set[i].type, set[i].id or "?", i))
        elseif actionButton and restoredID ~= actionButton.id then
            local typeName = aliasTypeNames[actionButton.type]
            local name = actionButton.type == "spell" and string.format(" (%s)", Compat.GetSpellName(restoredID)) or ""
            table.insert(messages, string.format("Info: Restored %s %d%s in place of %s %d", typeName, restoredID, name, typeName, actionButton.id))
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

local ALIAS_USAGE = "/abs alias <spell|item|mount> <group> <id> [id...] - e.g. /abs alias spell racials 20554 20549"
local UNALIAS_USAGE = "/abs unalias <spell|item|mount> <group> [id...] - e.g. /abs unalias spell racials 20549"

-- Splits "<type> <group> [id...]". Returns nothing after printing usage if the args don't fit.
local function ParseAliasArgs(self, args, usage, idsRequired)
    local words = {}
    for word in string.gmatch(args or "", "%S+") do table.insert(words, word) end

    local typeName = Str.toLower(words[1])
    local actionType = aliasTypes[typeName]
    if not actionType then
        self:Print(Str.nullOrEmpty(words[1]) and "Must provide a type: spell, item or mount"
            or string.format("Unknown type '%s'. Must be spell, item or mount", words[1]))
        self:Print(usage)
        return
    end

    local label = Str.toLower(words[2])
    if Str.nullOrEmpty(label) then
        self:Print("Must provide a group name")
        self:Print(usage)
        return
    end

    local ids = {}
    for i = 3, #words do
        local id = tonumber(words[i])
        if not id then
            self:Print(string.format("'%s' is not an ID. IDs must be numbers", words[i]))
            self:Print(usage)
            return
        end
        table.insert(ids, id)
    end

    if idsRequired and #ids == 0 then
        self:Print("Must provide at least one ID")
        self:Print(usage)
        return
    end

    return actionType, typeName, label, ids
end

function Actions:Alias(args)
    local actionType, typeName, label, ids = ParseAliasArgs(self, args, ALIAS_USAGE, true)
    if not actionType then return end

    local groups = self.db.global.aliasGroups
    groups[actionType] = groups[actionType] or {}
    local group = groups[actionType][label] or {}

    for _, id in ipairs(ids) do
        local otherLabel = FindAliasGroup(self, actionType, id)

        if otherLabel == label or Array.contains(group, id) then
            self:Print(string.format("'%s' already has %s %d", label, typeName, id))
        elseif otherLabel then
            self:Print(string.format("Can't add %s %d to '%s': it's already in '%s'", typeName, id, label, otherLabel))
        else
            table.insert(group, id)
            self:Print(string.format("Added %s %d to '%s'", typeName, id, label))
        end
    end

    if #group > 0 then groups[actionType][label] = group end
end

function Actions:Unalias(args)
    local actionType, typeName, label, ids = ParseAliasArgs(self, args, UNALIAS_USAGE, false)
    if not actionType then return end

    local groups = self.db.global.aliasGroups[actionType] or {}
    local group = groups[label]

    if not group then
        self:Print(string.format("No %s group named '%s'", typeName, label))
        return
    end

    if #ids == 0 then
        groups[label] = nil
        self:Print(string.format("Deleted %s group '%s'", typeName, label))
        return
    end

    for _, id in ipairs(ids) do
        local found = false
        for i, v in ipairs(group) do
            if v == id then
                table.remove(group, i)
                found = true
                break
            end
        end

        if found then
            self:Print(string.format("Removed %s %d from '%s'", typeName, id, label))
        else
            self:Print(string.format("'%s' doesn't have %s %d", label, typeName, id))
        end
    end

    if #group == 0 then
        groups[label] = nil
        self:Print(string.format("Group '%s' is now empty and was deleted", label))
    end
end

function Actions:ListAliases()
    local found = false

    for _, typeName in ipairs({ "spell", "item", "mount" }) do
        local groups = self.db.global.aliasGroups[aliasTypes[typeName]] or {}
        local labels = Dict.keysAsArray(groups)
        table.sort(labels)

        for _, label in ipairs(labels) do
            local entries = Array.map(groups[label], function(id)
                local name = typeName == "spell" and Compat.GetSpellName(id)
                return name and string.format("%d (%s)", id, name) or tostring(id)
            end)
            self:Print(string.format("%s '%s': %s", typeName, label, table.concat(entries, ", ")))
            found = true
        end
    end

    if not found then self:Print("No alias groups found") end
end

function Actions:PrintUsage()
    self:Print("ABS Slash commands")
    self:Print("/abs save <set> - Saves your current action bar setup under the given <set>")
    self:Print("/abs restore <set> - Restores the saved <set>")
    self:Print("/abs delete <set> - Deletes the saved <set>")
    self:Print("/abs list - Lists all saved sets")
    self:Print("/abs alias <spell|item|mount> <group> <id> [id...] - Adds IDs to an alias group")
    self:Print("/abs unalias <spell|item|mount> <group> [id...] - Removes IDs from a group, or the whole group")
    self:Print("/abs aliases - Lists all alias groups")
end