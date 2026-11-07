local F = ForeverXP
local V = F:Register("StepValidator", {})
local Check = F.modules.Validation
V.types = { ACCEPT_QUEST=true, COMPLETE_QUEST=true, TURN_IN_QUEST=true, KILL_MOBS=true,
    COLLECT_ITEMS=true, TRAVEL_TO=true, TALK_TO_NPC=true, TRAIN_SKILL=true,
    LEARN_FLIGHT_PATH=true, USE_ITEM=true, SET_HEARTHSTONE=true, USE_HEARTHSTONE=true,
    REACH_LEVEL=true, REACH_PROFESSION_SKILL=true, MANUAL_INSTRUCTION=true }
V.DataOnly = Check.DataOnly
local function positive(n) return Check.Integer(n, 1) end
function V:Waypoint(w)
    return type(w) == "table" and Check.Key(w.zone)
        and type(w.x) == "number" and w.x >= 0 and w.x <= 1
        and type(w.y) == "number" and w.y >= 0 and w.y <= 1
end
function V:Guide(guide, production)
    local errors, seen = {}, {}
    local function fail(message) errors[#errors+1] = message end
    if type(guide) ~= "table" or not self.DataOnly(guide) then return nil, { "guide must contain only finite, acyclic data" } end
    if not Check.String(guide.id) then fail("guide id required") end
    if not Check.String(guide.title) then fail("guide title required") end
    for _, key in ipairs({"faction", "race", "class"}) do
        if guide[key] ~= nil and not Check.String(guide[key]) then fail(key .. " must be a nonempty string") end
    end
    for _, key in ipairs({"minLevel", "maxLevel"}) do
        if guide[key] ~= nil and not positive(guide[key]) then fail(key .. " must be a positive integer") end
    end
    if positive(guide.minLevel) and positive(guide.maxLevel) and guide.minLevel > guide.maxLevel then fail("inverted level range") end
    if production and (guide.verification ~= "live-verified" or type(guide.source) ~= "string" or guide.source == "") then
        fail("live verification and source required for production guides")
    end
    if not Check.Array(guide.steps, true) then return nil, { "nonempty dense steps array required" } end
    for i, step in ipairs(guide.steps) do
        local prefix = "step " .. i .. ": "
        if type(step) ~= "table" then fail(prefix .. "must be a table")
        else
            if not Check.String(step.id) or seen[step.id] then fail(prefix .. "missing or duplicate id") end
            if not self.types[step.type] then fail(prefix .. "unknown type") end
            if not Check.String(step.text) then fail(prefix .. "instruction required") end
            if step.optional ~= nil and type(step.optional) ~= "boolean" then fail(prefix .. "optional must be boolean") end
            if step.waypoint and not self:Waypoint(step.waypoint) then fail(prefix .. "invalid normalized coordinates") end
            if step.type == "ACCEPT_QUEST" or step.type == "COMPLETE_QUEST" or step.type == "TURN_IN_QUEST" then
                if not positive(step.questId) then fail(prefix .. "questId required") end
            elseif step.type == "COLLECT_ITEMS" then
                if not positive(step.itemId) or not positive(step.count) then fail(prefix .. "itemId and count required") end
            elseif step.type == "REACH_LEVEL" then
                if not positive(step.level) then fail(prefix .. "level required") end
            elseif step.type == "REACH_PROFESSION_SKILL" then
                if not Check.String(step.profession) or not positive(step.skill) then fail(prefix .. "profession and skill required") end
            elseif step.type == "TRAVEL_TO" then
                if not self:Waypoint(step.waypoint) then fail(prefix .. "travel waypoint required") end
            elseif step.type == "TALK_TO_NPC" or step.type == "LEARN_FLIGHT_PATH" then
                if not positive(step.npcId) then fail(prefix .. "npcId required") end
            elseif step.type == "KILL_MOBS" then
                if not positive(step.npcId) or not positive(step.count) then fail(prefix .. "npcId and count required") end
            elseif step.type == "USE_ITEM" then
                if not positive(step.itemId) then fail(prefix .. "itemId required") end
            elseif step.type == "TRAIN_SKILL" then
                if not Check.String(step.profession) or not positive(step.skill) then fail(prefix .. "profession and skill required") end
            end
            if step.prerequisites ~= nil and not Check.Array(step.prerequisites) then fail(prefix .. "prerequisites must be a dense array")
            else
                local prerequisites = {}
                for _, id in ipairs(step.prerequisites or {}) do
                    if not Check.String(id) or not seen[id] then fail(prefix .. "unreachable prerequisite: " .. tostring(id)) end
                    if prerequisites[id] then fail(prefix .. "duplicate prerequisite") end
                    prerequisites[id] = true
                end
            end
            if type(step.id) == "string" then seen[step.id] = true end
        end
    end
    return #errors == 0, errors
end
function V:KnownQuests(guide, known)
    local missing = {}
    for _, step in ipairs(guide.steps) do
        if step.questId and known[step.questId] ~= true then missing[step.questId] = true end
    end
    return next(missing) == nil, missing
end
