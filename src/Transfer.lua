local _, ns = ...

-- Turns sets and alias groups into text players can copy between accounts,
-- and back. The format is ours, so it stays readable and needs no library:
--   ABS1;set;<name>;<CLASS>;<slot>=<type>:<id>;...
--   ABS1;aliases;<type>.<label>=<id>,<id>;...
-- Anything that could clash with the separators is %XX-escaped.
local Transfer = {}
ns.Transfer = Transfer

local PREFIX = "ABS1"

-- Action types saved by name rather than by number
local namedTypes = { macro = true, equipmentset = true }

local function Escape(value)
    return (tostring(value):gsub("[%%;=:,%.%s]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function Unescape(value)
    return (value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

local function SplitOn(s, separator)
    local parts = {}
    for part in string.gmatch(s, "[^" .. separator .. "]+") do table.insert(parts, part) end
    return parts
end

local function SortedKeys(t)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

function Transfer.EncodeSet(name, class, set)
    local parts = { PREFIX, "set", Escape(name), Escape(class) }

    for slot = 1, table.maxn(set) do
        local action = set[slot]
        if action then
            table.insert(parts, string.format("%d=%s:%s", slot, Escape(action.type), Escape(action.id)))
        end
    end

    return table.concat(parts, ";")
end

function Transfer.EncodeAliases(aliasGroups)
    local parts = { PREFIX, "aliases" }

    for _, actionType in ipairs(SortedKeys(aliasGroups)) do
        local groups = aliasGroups[actionType]
        for _, label in ipairs(SortedKeys(groups)) do
            local ids = {}
            for _, id in ipairs(groups[label]) do table.insert(ids, Escape(id)) end
            table.insert(parts, string.format("%s.%s=%s", Escape(actionType), Escape(label), table.concat(ids, ",")))
        end
    end

    return table.concat(parts, ";")
end

local function DecodeId(actionType, raw)
    local value = Unescape(raw)
    if namedTypes[actionType] then return value end
    return tonumber(value) or value
end

local function DecodeSet(fields)
    local name, class = fields[3], fields[4]
    if not (name and class) then return nil, "The set is missing its name or class" end

    local set = {}
    for i = 5, #fields do
        local slot, actionType, id = string.match(fields[i], "^(%d+)=([^:]+):(.+)$")
        slot = tonumber(slot)
        if not slot or slot < 1 then return nil, string.format("Couldn't read slot '%s'", fields[i]) end

        actionType = Unescape(actionType)
        set[slot] = { type = actionType, id = DecodeId(actionType, id) }
    end

    return { kind = "set", name = Unescape(name), class = Unescape(class), set = set }
end

local function DecodeAliases(fields)
    local aliasGroups = {}

    for i = 3, #fields do
        local actionType, label, ids = string.match(fields[i], "^([^%.]+)%.([^=]+)=(.+)$")
        if not actionType then return nil, string.format("Couldn't read alias group '%s'", fields[i]) end

        actionType = Unescape(actionType)
        label = Unescape(label)

        local group = {}
        for _, raw in ipairs(SplitOn(ids, ",")) do
            table.insert(group, DecodeId(actionType, raw))
        end

        aliasGroups[actionType] = aliasGroups[actionType] or {}
        aliasGroups[actionType][label] = group
    end

    return { kind = "aliases", aliasGroups = aliasGroups }
end

-- Returns { kind = "set", name, class, set } or { kind = "aliases", aliasGroups },
-- or nil and a reason the text can't be read
function Transfer.Decode(text)
    -- Pasting often brings stray spaces or line breaks along
    text = (text or ""):gsub("%s+", "")
    local fields = SplitOn(text, ";")

    if fields[1] ~= PREFIX then
        return nil, "This isn't an ActionBarSaver export, or it's from a newer version of the addon"
    end

    if fields[2] == "set" then return DecodeSet(fields) end
    if fields[2] == "aliases" then return DecodeAliases(fields) end

    return nil, "This isn't an ActionBarSaver export, or it's from a newer version of the addon"
end
