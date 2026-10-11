-- A fake WoW client for running the addon headlessly under busted.
--
-- Each call to wow.load() builds a fresh global environment, fills it with fake
-- versions of the WoW APIs the addon uses, and loads the addon's files in .toc
-- order. Nothing leaks between tests, so each test can pick a different client.

local wow = {}

local ADDON_NAME = "ActionBarSaverReloaded"
local SRC_DIR = "src/"

-- API shapes of the clients the addon supports. These describe which APIs
-- exist, not every detail of each client.
wow.clients = {
    {
        -- Mainline-based: no global PickupSpell/PickupItem/GetSpellInfo
        name = "Forever",
        maxSlots = 180,
        namespacedApis = true,
        -- Since 10.2, GetActionInfo reports what a macro shows instead of
        -- the macro's index: a spell ID, or a meaningless number for items
        macroActionsReportContents = true,
    },
    {
        name = "TBC Anniversary",
        maxSlots = 180,
    },
    {
        name = "Wrath/Cata/Mists",
        maxSlots = 132,
    },
    {
        name = "Era",
        maxSlots = 120,
    },
}

function wow.client(name)
    for _, client in ipairs(wow.clients) do
        if client.name == name then return client end
    end

    error("unknown client " .. name)
end

-- WoW's strsplit: split on any character in `delimiters`, into at most `pieces`
local function strsplit(delimiters, s, pieces)
    local parts = {}
    local pattern = "[" .. delimiters:gsub("%p", "%%%0") .. "]"
    local start = 1

    while not pieces or #parts < pieces - 1 do
        local from, to = s:find(pattern, start)
        if not from then break end
        table.insert(parts, s:sub(start, from - 1))
        start = to + 1
    end

    table.insert(parts, s:sub(start))

    return unpack(parts)
end

local function copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end
    return c
end

-- Minimal AceAddon/AceDB/AceConsole: enough for the addon to register itself,
-- its module and its slash command
local function FakeLibStub(game)
    local addons = {}

    local AceAddon = {}

    function AceAddon.NewAddon(_, name)
        local addon = { modules = {} }

        function addon:NewModule(moduleName)
            local module = {}
            self.modules[moduleName] = module
            return module
        end

        function addon:GetModule(moduleName) return self.modules[moduleName] end

        function addon:RegisterChatCommand(command, method)
            game.slashCommands[command] = function(input) self[method](self, input) end
        end

        addons[name] = addon
        return addon
    end

    function AceAddon.GetAddon(_, name) return addons[name] end

    local AceDB = {}

    function AceDB.New(_, savedVariable, defaults)
        game.savedVariables[savedVariable] = game.savedVariables[savedVariable] or copy(defaults)
        return game.savedVariables[savedVariable]
    end

    local libs = { ["AceAddon-3.0"] = AceAddon, ["AceDB-3.0"] = AceDB }

    return setmetatable({}, {
        __call = function(_, major) return assert(libs[major], "fake LibStub has no " .. major) end,
    })
end

-- The action bar, cursor, spellbook, bags, macros and equipment sets
local function FakeGameApis(game, client)
    local api = {}

    -- Things the cursor can hold, keyed by type then ID
    game.spells = {}         -- [spellID] = name, for spells the character knows
    game.items = {}          -- [itemID] = name, for items the character has
    game.macros = {}         -- [index] = name
    game.macroContents = {}  -- [index] = { type = "spell" or "item", id = ID } for what a macro shows
    game.equipmentSets = {}  -- [setID] = name

    game.bar = {}
    game.cursor = nil
    game.inCombat = false

    local function checkSlot(slot)
        if type(slot) ~= "number" or slot < 1 or slot > client.maxSlots then
            error("Usage: invalid action slot " .. tostring(slot), 2)
        end
    end

    -- The bar and the cursor swap contents, like dragging an action in game
    function api.PickupAction(slot)
        checkSlot(slot)
        game.cursor, game.bar[slot] = game.bar[slot], game.cursor
    end

    function api.PlaceAction(slot)
        checkSlot(slot)
        game.bar[slot], game.cursor = game.cursor, game.bar[slot]
    end

    function api.GetActionInfo(slot)
        checkSlot(slot)
        local action = game.bar[slot]
        if not action then return end

        local contents = game.macroContents[action.id]
        if action.type == "macro" and contents and client.macroActionsReportContents then
            return "macro", contents.type == "spell" and contents.id or slot - 1, contents.type
        end

        return action.type, action.id
    end

    -- For a macro, its name
    function api.GetActionText(slot)
        checkSlot(slot)
        local action = game.bar[slot]
        if action and action.type == "macro" then return game.macros[action.id] end
    end

    function api.ClearCursor() game.cursor = nil end

    function api.GetCursorInfo()
        if game.cursor then return game.cursor.type, game.cursor.id end
    end

    function api.InCombatLockdown() return game.inCombat end

    local function pickupSpell(spellID)
        if game.spells[spellID] then game.cursor = { type = "spell", id = spellID } end
    end

    local function pickupItem(itemID)
        if game.items[itemID] then game.cursor = { type = "item", id = itemID } end
    end

    local function getSpellName(spellID) return game.spells[spellID] end

    local function macroIndex(nameOrIndex)
        if game.macros[nameOrIndex] then return nameOrIndex end

        for index, name in pairs(game.macros) do
            if name == nameOrIndex then return index end
        end
    end

    function api.GetMacroInfo(nameOrIndex)
        local index = macroIndex(nameOrIndex)
        if index then return game.macros[index] end
    end

    function api.PickupMacro(nameOrIndex)
        local index = macroIndex(nameOrIndex)
        if index then game.cursor = { type = "macro", id = index } end
    end

    api.C_EquipmentSet = {
        GetEquipmentSetID = function(name)
            for setID, setName in pairs(game.equipmentSets) do
                if setName == name then return setID end
            end
        end,
        PickupEquipmentSet = function(setID)
            assert(type(setID) == "number", "PickupEquipmentSet takes a set ID")
            local name = game.equipmentSets[setID]
            -- Action bars report equipment sets by name
            if name then game.cursor = { type = "equipmentset", id = name } end
        end,
    }

    if client.namespacedApis then
        api.C_Spell = { PickupSpell = pickupSpell, GetSpellName = getSpellName }
        api.C_Item = { PickupItem = pickupItem }
    else
        api.PickupSpell = pickupSpell
        api.PickupItem = pickupItem
        api.GetSpellInfo = function(spellID)
            local name = getSpellName(spellID)
            if name then return name, nil, 136243 end
        end
    end

    return api
end

local function TocFiles()
    local files = {}

    for line in io.lines(SRC_DIR .. ADDON_NAME .. ".toc") do
        line = line:gsub("%s+$", "")
        -- Libraries come from Embeds.xml; the fakes above stand in for them
        if line:match("%.lua$") and not line:match("^#") then table.insert(files, line) end
    end

    return files
end

-- Load the addon into a fresh fake client. Returns a game object for driving it:
--   game:slash("save mySet")   run /abs with the given input
--   game.bar[slot]             what's on the action bar
--   game.output                lines the addon printed, without color codes
function wow.load(client)
    if type(client) == "string" then client = wow.client(client) end

    local game = {
        client = client,
        output = {},
        slashCommands = {},
        savedVariables = {},
    }

    local env = FakeGameApis(game, client)
    env.LibStub = FakeLibStub(game)
    env.string = setmetatable({ split = strsplit }, { __index = string })
    env.print = function(...)
        local line = table.concat({ ... }, " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        table.insert(game.output, line)
    end
    env._G = env
    setmetatable(env, { __index = _G })

    game.env = env

    local ns = {}
    for _, file in ipairs(TocFiles()) do
        local chunk = assert(loadfile(SRC_DIR .. file))
        setfenv(chunk, env)
        chunk(ADDON_NAME, ns)
    end

    game.ns = ns
    game.addon = env.LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
    game.addon:OnInitialize()
    game.db = game.addon.db

    function game:slash(input)
        self.slashCommands.abs(input)
    end

    -- Printed lines, minus the "ABS: " prefix
    function game:messages()
        local messages = {}
        for _, line in ipairs(self.output) do table.insert(messages, (line:gsub("^ABS: ", ""))) end
        return messages
    end

    function game:clearOutput()
        self.output = {}
    end

    -- Wipe the bar, as if switching specs or characters before a restore
    function game:clearBar()
        for slot in pairs(self.bar) do self.bar[slot] = nil end
    end

    return game
end

return wow
