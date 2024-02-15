
local P = {}
Math = P

P.band = function(__a, __b)
    local result = bit.band(__a, __b)
    return result
end

P.lshift = function(__a, __b)
    local result = bit.lshift(__a, __b)
    return result
end