std = "lua51"
max_line_length = false
exclude_files = { "src/Libs/", ".lua/", ".release/" }

-- Globals the addon defines. These should move into the addon's private
-- namespace (`local _, ns = ...`) so they can't clash with other addons.
globals = { "ADDON_NAME", "MAX_MACROS", "Str", "Array", "Dict" }

-- Ace methods often ignore self
self = false

-- WoW APIs the addon reads. Compat.lua probes for the ones that only some
-- clients have, so list every variant here.
read_globals = {
    "LibStub",
    "ClearCursor", "GetActionInfo", "GetActionText", "GetCursorInfo", "GetMacroInfo", "InCombatLockdown",
    "PickupAction", "PickupItem", "PickupMacro", "PickupSpell", "PlaceAction",
    "GetSpellInfo",
    "C_EquipmentSet", "C_Item", "C_Spell",
    string = { fields = { "split" } },
}

files["spec/"] = { std = "+busted" }
