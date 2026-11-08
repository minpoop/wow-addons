local F = ForeverXP
local A = F:Register("ForeverAdapter", { pending = false, turnedIn = {}, baseline = {}, enabled = false,
    source = "Questie/Questie@97d7518d5402d185e47b39522a6ea09b8316f0ef" })
local V, C, E = F.modules.Validation, F.modules.Compatibility, F.modules.Events
local function call(namespace, name, ...)
    local owner = namespace and _G[namespace] or _G
    if type(owner) ~= "table" or type(owner[name]) ~= "function" then return nil end
    return owner[name](...)
end
local function fn(namespace, name)
    local owner = namespace and _G[namespace] or _G
    return type(owner) == "table" and type(owner[name]) == "function"
end
function A:Matches()
    return C:Build().interface == 16001
end
function A:SignalQuest(id)
    if V.Integer(id,1) then
        self.signalQuestId=id
        self.signalRevision=(self.signalRevision or 0)+1
    end
end
function A:Collect()
    if not self.enabled or not self:Matches() or self.loading then return nil end
    if not fn("C_QuestLog","GetNumQuestLogEntries") or not fn("C_QuestLog","GetInfo") then
        self.error = "C_QuestLog enumeration unavailable"; return nil
    end
    local count = call("C_QuestLog","GetNumQuestLogEntries")
    if not V.Integer(count) or count > 512 then self.error = "Quest log is not ready"; return nil end
    local snapshot = { quests = {}, items = {}, professions = {}, active = {}, character = C:Character(),
        provenance = "source-inspected", source = self.source }
    local level = call(nil,"UnitLevel","player")
    if V.Integer(level,1) then snapshot.level = level end
    for index=1,count do
        local info = call("C_QuestLog","GetInfo",index)
        if type(info) ~= "table" then self.error = "Incomplete quest log; waiting for update"; return nil end
        if info.isHeader ~= true then
            if not V.Integer(info.questID,1) or not V.String(info.title) then self.error = "Quest entry is not ready"; return nil end
            local id = info.questID
            if self.baseline[id] == nil then
                local previous=call("C_QuestLog","IsQuestFlaggedCompleted",id)
                local size=0; for _ in pairs(self.baseline) do size=size+1 end
                if size<1024 then
                    if type(previous)=="boolean" then self.baseline[id]=previous else self.baseline[id]="unknown" end
                else self.historyFull=true end
            end
            local quest = { accepted = true, title = info.title }
            local readable,observedLevel=pcall(function() if V.Integer(info.level,1) then return info.level end end)
            if readable then quest.level=observedLevel end
            -- Optional tag failures must not discard otherwise readable quests.
            pcall(function()
                local tag=call("C_QuestLog","GetQuestTagInfo",id)
                if type(tag)=="table" then
                    if V.Integer(tag.tagID) then quest.tagId=tag.tagID end
                    if type(tag.isElite)=="boolean" then quest.isElite=tag.isElite end
                end
            end)
            if fn("C_QuestLog","IsComplete") then
                local complete = call("C_QuestLog","IsComplete",id)
                if type(complete) == "boolean" then quest.complete = complete end
            end
            if fn("C_QuestLog","IsFailed") and call("C_QuestLog","IsFailed",id) == true then
                quest.failed,quest.complete = true,false
            end
            if fn("C_QuestLog","GetQuestObjectives") then
                local objectives = call("C_QuestLog","GetQuestObjectives",id)
                if V.Array(objectives) then
                    quest.objectives = {}
                    for i,row in ipairs(objectives) do
                        if type(row) ~= "table" or not V.String(row.text) or not V.String(row.type)
                           or not V.Integer(row.numFulfilled) or not V.Integer(row.numRequired) or type(row.finished) ~= "boolean" then
                            quest.objectives = nil; break
                        end
                        quest.objectives[i] = { text=row.text, type=row.type, count=row.numFulfilled, required=row.numRequired, finished=row.finished }
                    end
                end
            end
            snapshot.quests[id] = quest
            snapshot.active[#snapshot.active+1] = id
        end
    end
    -- Optional native focus must not make the whole snapshot fail if a getter
    -- is unavailable, restricted or temporarily returns an unreadable value.
    local function focus(namespace,name)
        local ok,id=pcall(function()
            local value=call(namespace,name)
            if V.Integer(value,1) and snapshot.quests[value] and snapshot.quests[value].accepted==true then return value end
        end)
        if ok then return id end
    end
    snapshot.trackedQuestId=focus("C_SuperTrack","GetSuperTrackedQuestID")
    snapshot.selectedQuestId=focus("C_QuestLog","GetSelectedQuest")
    if self.signalQuestId and snapshot.quests[self.signalQuestId] then
        snapshot.signalQuestId,snapshot.signalRevision=self.signalQuestId,self.signalRevision
    end
    -- Query only referenced inventory IDs and completed history, never every bag slot.
    local quests, items = {}, {}
    for id in pairs(self.turnedIn) do quests[id] = true end
    if F.character and type(F.character.liveJournal) == "table" and type(F.character.liveJournal.order) == "table" then
        for _,id in ipairs(F.character.liveJournal.order) do if V.Integer(id,1) then quests[id] = true end end
    end
    local guide = F.modules.GuideEngine.guide
    if guide then
        for _,step in ipairs(guide.steps) do
            if step.questId then quests[step.questId] = true end
            for _,id in ipairs(step.prerequisiteQuestsAny or {}) do quests[id]=true end
            for _,id in ipairs(step.prerequisiteQuestsAll or {}) do quests[id]=true end
            for _,id in ipairs(step.exclusiveQuests or {}) do quests[id]=true end
            if step.itemId then items[step.itemId] = true end
        end
    end
    for id in pairs(quests) do
        -- Historical flags can remain true on reaccepted repeatables. An active
        -- quest is never declared turned in based on its old completion history.
        if not snapshot.quests[id] then
            local completed = self.turnedIn[id] == true
            if not completed and not self.historyFull and self.baseline[id] ~= true and self.baseline[id] ~= "unknown"
               and fn("C_QuestLog","IsQuestFlaggedCompleted") then completed = call("C_QuestLog","IsQuestFlaggedCompleted",id) == true end
            if completed then snapshot.quests[id] = { turnedIn = true } end
        end
    end
    for id in pairs(items) do
        local amount
        if fn("C_Item","GetItemCount") then amount = call("C_Item","GetItemCount",id,false,false,false)
        elseif fn(nil,"GetItemCount") then amount = call(nil,"GetItemCount",id,false,false,false) end
        if V.Integer(amount) then snapshot.items[id] = amount end
    end
    self.error, self.last = nil, snapshot
    return snapshot
end
function A:Schedule()
    if not self.enabled or self.loading or self.pending then return end
    self.pending = true
    local function refresh()
        self.pending = false
        if self.enabled and not self.loading then E:Emit("FXP_STATE_CHANGED") end
    end
    if fn("C_Timer","After") then
        local ok = pcall(C_Timer.After,0.2,refresh)
        if not ok then self.pending=false; self.error="Refresh timer unavailable" end
    else refresh() end
end
function A:Start()
    if self.enabled then return true end
    if not self:Matches() then self.error = "Tracking requires observed interface 16001"; return nil,self.error end
    self.enabled = true
    C:RegisterInspectedProvider("snapshot",function() return self:Collect() end,self.source)
    for _,event in ipairs({"QUEST_LOG_UPDATE","BAG_UPDATE_DELAYED","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA","SUPER_TRACKING_CHANGED"}) do
        E:On(event,"forever-tracking",function() self:Schedule() end)
    end
    E:On("QUEST_WATCH_UPDATE","forever-tracking",function(id) self:SignalQuest(id); self:Schedule() end)
    E:On("QUEST_ACCEPTED","forever-tracking",function(id)
        -- Forever's first and only argument is the quest ID, not a log index.
        if V.Integer(id,1) then self.turnedIn[id],self.baseline[id]=nil,nil end
        self:SignalQuest(id)
        self:Schedule()
    end)
    E:On("QUEST_TURNED_IN","forever-tracking",function(id)
        if V.Integer(id,1) then
            local size=0; for _ in pairs(self.turnedIn) do size=size+1 end
            if size<2048 or self.turnedIn[id] then self.turnedIn[id]=true end
        end
        self:Schedule()
    end)
    E:On("QUEST_REMOVED","forever-tracking",function() self:Schedule() end)
    E:On("PLAYER_LEAVING_WORLD","forever-tracking",function() self.loading=true end)
    E:On("PLAYER_ENTERING_WORLD","forever-tracking",function() self.loading=false; self:Schedule() end)
    self:Schedule()
    return true
end
