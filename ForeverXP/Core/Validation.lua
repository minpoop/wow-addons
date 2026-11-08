local F = ForeverXP
local V = F:Register("Validation", {})
function V.Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function V.Integer(value, minimum)
    return V.Finite(value) and value % 1 == 0 and value >= (minimum or 0)
end
function V.String(value) return type(value) == "string" and value:find("%S") ~= nil end
function V.Key(value) return V.String(value) or V.Integer(value, 1) end
function V.Array(value, nonempty)
    if type(value) ~= "table" then return false end
    local count = 0
    for key in pairs(value) do
        if not V.Integer(key, 1) then return false end
        count = count + 1
    end
    if nonempty and count == 0 then return false end
    for i = 1, count do if value[i] == nil then return false end end
    return true
end
function V.DataOnly(value, budget)
    local active, count = {}, 0
    local function visit(item, depth)
        count = count + 1
        if count > (budget or 50000) or depth > 64 then return false end
        local kind = type(item)
        if kind == "number" then return V.Finite(item) end
        if kind ~= "table" then return kind == "nil" or kind == "string" or kind == "boolean" end
        if getmetatable(item) or active[item] then return false end
        active[item] = true
        for key, child in pairs(item) do
            if (type(key) ~= "string" and not V.Finite(key)) or not visit(child, depth + 1) then return false end
        end
        active[item] = nil
        return true
    end
    return visit(value, 0)
end
function V.Verified(value)
    return value.verification == "live-verified" and V.String(value.source)
end
