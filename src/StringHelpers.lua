Str = {}

function Str.toLower(s) return string.lower(s or "") end
function Str.nullOrEmpty(s) return not s or s == "" end

function Str.split(s, delimiter, max)
---@diagnostic disable-next-line: undefined-field
    return string.split(delimiter, s, max)
end