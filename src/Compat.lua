local _, ns = ...

-- One internal API over the WoW APIs that differ between game clients.
-- Probe for the API rather than checking the client version: Forever reports
-- the same WOW_PROJECT_ID as retail, and clients sharing an interface version
-- can still differ.
local Compat = {}
ns.Compat = Compat

Compat.PickupSpell = (C_Spell and C_Spell.PickupSpell) or PickupSpell
Compat.PickupItem = (C_Item and C_Item.PickupItem) or PickupItem
Compat.PickupMacro = PickupMacro

Compat.GetSpellName = (C_Spell and C_Spell.GetSpellName) or function(spellID)
    return (GetSpellInfo(spellID))
end

-- Action bars store equipment sets by name, but pickup takes the set ID
if C_EquipmentSet then
    function Compat.PickupEquipmentSet(setName)
        local setID = C_EquipmentSet.GetEquipmentSetID(setName)
        if setID then C_EquipmentSet.PickupEquipmentSet(setID) end
    end
end

-- Mounts live in the mount journal. Action bars report them by mount ID, but
-- pickup takes an index into the journal's displayed (filtered) list.
-- Index 0 is the "Summon Random Favorite Mount" button.
if C_MountJournal then
    local RANDOM_FAVORITE_MOUNT_ID = 268435455

    function Compat.PickupMount(mountID)
        if mountID == RANDOM_FAVORITE_MOUNT_ID then
            C_MountJournal.Pickup(0)
            return
        end

        for i = 1, C_MountJournal.GetNumDisplayedMounts() do
            if C_MountJournal.GetDisplayedMountID(i) == mountID then
                C_MountJournal.Pickup(i)
                return
            end
        end
    end
end

-- Clients have 120, 132 or 180 action slots, and the interface version
-- doesn't tell them apart, so use the highest slot the client accepts
local function FindMaxActionSlots()
    for _, slots in ipairs({ 180, 132 }) do
        if pcall(GetActionInfo, slots) then return slots end
    end

    return 120
end

Compat.MaxActionSlots = FindMaxActionSlots()
