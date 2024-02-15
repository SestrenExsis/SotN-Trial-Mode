
local P = {}
Math = P

P.band = function(__a, __b)
    local result = __a & __b
    return result
end

P.lshift = function(__a, __b)
    local result = (__a << __b)
    return result
end