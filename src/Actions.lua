local Actions = _G.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME):NewModule("Actions")

-- actions = {}

local function classifyAction(index)
    local actionType, id, subType, extraID = GetActionInfo(index)

    if actionType and id then

    end
end

function Actions:SaveProfile()
    -- db.Sets[playerClass][name] = db.Sets[playerClass][name] or {}

    -- local set = db.Sets[playerClass][name]
    -- print(string.format("called actions.saveProfile with '%s'", name))
    print("called actions.saveProfile")
end

function Actions:RestoreProfile()
    -- print(string.format("called actions.restoreProfile with '%s'", name))
    print("called actions.restoreProfile")
end

-- function actions.restoreAction()
--     print("called actions.delete")
-- end

function Actions:RenameProfile()
    print("called actions.renameProfile")
end

function Actions:DeleteProfile()
    print("called actions.deleteProfile")
end

function Actions:ListProfiles()
    print("called actions.list")
end