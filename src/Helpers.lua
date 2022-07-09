str = {}

function str.toLower(str) return string.lower(str or "") end
function str.nullOrEmpty(s) return not s or s == "" end

function str.split(s, delimiter, max)
---@diagnostic disable-next-line: undefined-field
    return string.split(delimiter, s, max)
end