-- playerClass, db

SLASH_ABS1          = "/absn" -- fix these later
SLASH_ABS2          = "/actionbarsavernew"
SlashCmdList["ABS"] = commands.handleCommands

-- function Init()
--     ActionBarSaverReloadedNewDB = ActionBarSaverReloadedNewDB or {}

--     for classToken in pairs(RAID_CLASS_COLORS) do
-- 		ActionBarSaverReloadedNewDB.Sets[classToken] = ActionBarSaverReloadedNewDB.Sets[classToken] or {}
-- 	end

--     db = ActionBarSaverReloadedNewDB
--     playerClass = select(2, UnitClass("player"))
-- end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if(addon == ADDON_NAME) then -- maybe update this bit
        print("abs loaded")
        -- Init()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)