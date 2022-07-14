Dict = {}

function Dict.iteri(arr, fn)
   for _,v in ipairs(arr) do
        fn(v)
   end
end

function Dict.mapi(arr, fn)
    local t = {}

    for _,v in ipairs(arr) do
        table.insert(t, fn(v))
    end

    return t
end

function Dict.iter(t, fn)
    for k,v in pairs(t) do
        fn(k,v)
    end
end

function Dict.map(t, fn)
    local nt = {}

    for k,v in pairs(t) do
        nt[k] = fn(k,v)
    end

    return nt
end

function Dict.mapRange(start, stop, fn)
    local arr = {}

    for i = start, stop do
        arr[i] = fn(i)
    end

    return arr
end

function Dict.iterRange(start, stop, fn)
    for i = start, stop do
        fn(i)
    end
end

function Dict.keysAsArray(t)
    local nt = {}

    for k,_ in pairs(t) do
        table.insert(nt, k)
    end

    return nt
end