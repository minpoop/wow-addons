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
    if guide.autoResume~=nil and type(guide.autoResume)~="boolean" then fail("autoResume must be boolean") end
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
            if step.minLevel ~= nil and not positive(step.minLevel) then fail(prefix .. "invalid minimum level") end
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
    if guide.campaign~=nil then
        local plan=guide.campaign
        if type(plan)~="table" or not Check.Integer(plan.targetLevel,2)
           or not Check.Integer(plan.maxQuestLag) or plan.maxQuestLag>10
           or not Check.Integer(plan.maxQuestLead) or plan.maxQuestLead>10
           or (plan.zonePreference~=nil and (not Check.Integer(plan.zonePreference) or plan.zonePreference>100)) then
            fail("invalid campaign level policy")
        else
            local quests,goal={},0
            for _,step in ipairs(guide.steps) do
                if type(step)=="table" then
                    if step.type=="REACH_LEVEL" and step.level==plan.targetLevel then goal=goal+1 end
                    if step.questId and positive(step.questId) and ({ACCEPT_QUEST=true,COMPLETE_QUEST=true,TURN_IN_QUEST=true})[step.type] then
                        if not positive(step.questLevel) or not positive(step.minLevel) or not Check.String(step.questTitle) then fail("campaign quest metadata required") end
                        local record=quests[step.questId] or {}; quests[step.questId]=record
                        if record[step.type] then fail("duplicate campaign quest phase") end
                        record[step.type]=true
                        if record.level and (record.level~=step.questLevel or record.minimum~=step.minLevel or record.title~=step.questTitle) then fail("inconsistent campaign quest metadata") end
                        record.level,record.minimum,record.title=step.questLevel,step.minLevel,step.questTitle
                    elseif step.questId then fail("invalid campaign quest phase")
                    end
                end
            end
            if not next(quests) or goal~=1 then fail("campaign needs quests and one target level step") end
            local positions={}; for i,step in ipairs(guide.steps) do if type(step)=="table" and step.type=="ACCEPT_QUEST" and positive(step.questId) then positions[step.questId]=i end end
            for i,step in ipairs(guide.steps) do
                if type(step)=="table" then
                    for _,field in ipairs({"prerequisiteQuestsAny","exclusiveQuests"}) do
                        if step[field]~=nil then
                            if step.type~="ACCEPT_QUEST" or not Check.Array(step[field]) then fail("campaign quest relationships require dense accept-step arrays")
                            else
                                local ids={}
                                for _,id in ipairs(step[field]) do
                                    if not positive(id) or ids[id] or id==step.questId then fail("invalid campaign quest relationship") end
                                    ids[id]=true
                                    if field=="prerequisiteQuestsAny" and positions[id] and positions[id]>=i then fail("campaign alternative must precede dependent quest") end
                                end
                            end
                        end
                    end
                end
            end
            if plan.chapters~=nil then
                if not Check.Array(plan.chapters,true) then fail("campaign chapters require a dense array")
                else
                    local expected=1
                    for _,chapter in ipairs(plan.chapters) do
                        if type(chapter)~="table" or chapter.minLevel~=expected or not positive(chapter.maxLevel)
                           or chapter.maxLevel<expected or not Check.String(chapter.title) or not Check.String(chapter.text) then fail("invalid campaign chapter coverage"); break end
                        expected=chapter.maxLevel+1
                    end
                    if expected~=plan.targetLevel then fail("campaign chapters must cover every level before target") end
                end
            end
            for _,record in pairs(quests) do
                if not record.ACCEPT_QUEST or not record.COMPLETE_QUEST or not record.TURN_IN_QUEST then fail("campaign quest phases incomplete") end
            end
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
