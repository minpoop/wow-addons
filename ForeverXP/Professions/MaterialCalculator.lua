local F = ForeverXP
local M = F:Register("MaterialCalculator", {})
local V = F.modules.Validation
local function number(n) return type(n) == "number" and n >= 0 and n < math.huge end
-- Recipe catalog is supplied by verified content, never populated with guessed IDs.
-- crafts are explicit counts, not assumed skill points. Inventory is shared across
-- the entire dependency expansion so shared ingredients cannot be subtracted twice.
function M:Calculate(crafts, recipes, inventory, producers)
    if type(crafts) ~= "table" or type(recipes) ~= "table" or (inventory ~= nil and type(inventory) ~= "table")
       or (producers ~= nil and type(producers) ~= "table") then return nil, "material inputs must be tables" end
    if not F.modules.StepValidator.DataOnly({crafts, recipes, inventory or {}, producers or {}}) then return nil, "invalid data" end
    inventory, producers = inventory or {}, producers or {}
    local owned, original, result, active = {}, {}, { raw = {}, missing = {}, used = {}, crafts = {}, stations = {}, vendor = {} }, {}
    for id, count in pairs(inventory) do
        if not V.Key(id) or not V.Integer(count) then return nil, "invalid inventory count" end
        owned[id] = count
        original[id] = count
    end
    local function recipe(id)
        local r = recipes[id]
        if type(r) ~= "table" or not number(r.outputCount) or r.outputCount < 1 or r.outputCount % 1 ~= 0
           or not V.Key(r.output) or type(r.inputs) ~= "table" then error("invalid recipe: " .. tostring(id)) end
        for item, count in pairs(r.inputs) do if not V.Key(item) or not V.Integer(count, 1) then error("invalid reagent") end end
        if r.vendor ~= nil and type(r.vendor) ~= "table" then error("invalid vendor metadata") end
        if r.station ~= nil and not V.String(r.station) then error("invalid station") end
        return r
    end
    local make, need
    need = function(item, count)
        local used = math.min(owned[item] or 0, count)
        owned[item] = (owned[item] or 0) - used
        local fromInventory = math.min(original[item] or 0, used)
        original[item] = (original[item] or 0) - fromInventory
        result.used[item] = (result.used[item] or 0) + fromInventory
        count = count - used
        if count <= 0 then return end
        local producer = producers[item]
        if producer then
            local r = recipe(producer)
            if r.output ~= item then error("producer output mismatch") end
            local n = math.ceil(count / r.outputCount)
            make(producer, n)
            owned[item] = (owned[item] or 0) + n * r.outputCount - count
        else
            result.missing[item] = (result.missing[item] or 0) + count
        end
    end
    make = function(id, count)
        if active[id] then error("recipe dependency cycle: " .. tostring(id)) end
        active[id] = true
        local r = recipe(id)
        result.crafts[id] = (result.crafts[id] or 0) + count
        if r.station then result.stations[r.station] = true end
        for item, each in pairs(r.inputs) do
            if r.vendor and r.vendor[item] then result.vendor[item] = true end
            need(item, count * each)
        end
        active[id] = nil
    end
    -- Sort to make allocation reproducible when recipes share crafted inputs.
    local ids = {}; for id in pairs(crafts) do ids[#ids+1] = id end
    table.sort(ids, function(a,b) return tostring(a) < tostring(b) end)
    local ok, err = pcall(function()
        -- Validate reachable recipe graphs even when inventory would hide a cycle.
        local visiting, visited = {}, {}
        local function visit(id)
            if visiting[id] then error("recipe dependency cycle: " .. tostring(id)) end
            if visited[id] then return end
            visiting[id] = true
            local r = recipe(id)
            for item in pairs(r.inputs) do
                local producer = producers[item]
                if producer then
                    if recipe(producer).output ~= item then error("producer output mismatch") end
                    visit(producer)
                end
            end
            visiting[id], visited[id] = nil, true
        end
        for _, id in ipairs(ids) do
            local count = crafts[id]
            if not V.Key(id) or not V.Integer(count) then error("invalid craft count") end
            if count > 0 then visit(id); make(id, count) end
        end
    end)
    if not ok then return nil, tostring(err) end
    for item, missing in pairs(result.missing) do result.raw[item] = missing + (result.used[item] or 0) end
    for item, used in pairs(result.used) do if not producers[item] then result.raw[item] = result.raw[item] or used end end
    return result
end
