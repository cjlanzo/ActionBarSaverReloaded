actions = {}

local function classifyAction(index)
    local actionType, id, subType, extraID = GetActionInfo(index)

    if actionType and id then

    end
end

function actions.saveProfile(name)
    -- db.Sets[playerClass][name] = db.Sets[playerClass][name] or {}

    -- local set = db.Sets[playerClass][name]
    print(string.format("called actions.saveProfile with '%s'", name))
end

function actions.restoreProfile(name)
    print(string.format("called actions.restoreProfile with '%s'", name))
end

-- function actions.restoreAction()
--     print("called actions.delete")
-- end

function actions.renameProfile()
    print("called actions.renameProfile")
end

function actions.deleteProfile()
    print("called actions.deleteProfile")
end

function actions.list()
    print("called actions.list")
end