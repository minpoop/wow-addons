local F=ForeverXP
local P=F:Register("RoutePlanner",{plans={}})
local V=F.modules.Validation
local phases={accept="ACCEPT_QUEST",work="COMPLETE_QUEST",["turn-in"]="TURN_IN_QUEST"}
local function includes(list,value)
    for _,item in ipairs(list or {}) do if item==value then return true end end
    return false
end
function P:Register(plan)
    if type(plan)~="table" or not V.DataOnly(plan) or not V.String(plan.id) or not V.String(plan.title)
       or plan.verification~="reference-planned" or not V.String(plan.source) or not V.String(plan.faction)
       or not V.Integer(plan.minLevel,1) or not V.Integer(plan.maxLevel,plan.minLevel)
       or not V.Array(plan.guides,true) or not V.Array(plan.zones,true) or not V.Array(plan.stages,true)
       or #plan.stages>512 or not V.Integer(plan.pickupLead,0) or plan.pickupLead>5
       or not V.Integer(plan.reservedSlots,1) then return nil,"Invalid route plan." end
    local seen,actions,questActions={},{},{}
    for _,zone in ipairs(plan.zones) do if not V.String(zone) then return nil,"Invalid route zone." end end
    for _,id in ipairs(plan.guides) do
        local guide=F.modules.GuideEngine.guides[id]
        if not guide or not guide.campaign or guide.faction~=plan.faction then return nil,"Route guide is unavailable." end
    end
    for position,stage in ipairs(plan.stages) do
        if type(stage)~="table" or not V.String(stage.id) or seen[stage.id] or not V.String(stage.title)
           or not phases[stage.phase] or not V.Array(stage.quests,true) or #stage.quests>12
           or not V.Integer(stage.maxLevel,plan.minLevel) or stage.maxLevel>plan.maxLevel
           or (stage.note~=nil and not V.String(stage.note))
           or (stage.pickupAhead~=nil and type(stage.pickupAhead)~="boolean")
           or (stage.pickupAhead and stage.phase~="accept") then return nil,"Invalid route batch." end
        seen[stage.id]=true
        for _,id in ipairs(stage.quests) do
            local key=tostring(id)..":"..stage.phase
            if not V.Integer(id,1) or actions[key] then return nil,"Duplicate or invalid route action." end
            actions[key]=true
            questActions[id]=questActions[id] or {};questActions[id][stage.phase]=position
            for _,guideId in ipairs(plan.guides) do
                local record=F.modules.LevelingCampaign:Index(F.modules.GuideEngine.guides[guideId]).quests[id]
                if not record or record.optional then return nil,"Route action requires a supported non-optional quest." end
            end
        end
    end
    for id,action in pairs(questActions) do
        if not action.accept or not action.work or not action["turn-in"] or action.accept>=action.work or action.work>=action["turn-in"] then return nil,"Route phases must be ordered and complete." end
    end
    for id,action in pairs(questActions) do
        for _,guideId in ipairs(plan.guides) do
            local guide=F.modules.GuideEngine.guides[guideId]
            local index=F.modules.LevelingCampaign:Index(guide)
            local record=index.quests[id]
            for _,pre in ipairs(record.requires) do
                if questActions[pre] and questActions[pre]["turn-in"]>=action.accept then return nil,"Route prerequisite must precede its pickup." end
            end
        end
    end
    if self.plans[plan.id] then return nil,"Duplicate route plan." end
    self.plans[plan.id]=F.modules.SavedVariables.Copy(plan)
    return true
end
function P:Active(engine,snapshot)
    local choice=F.settings and F.settings.routePlan or "auto"
    if choice=="off" or not engine.guide or not V.Integer(snapshot.level,1) then return end
    local player=type(snapshot.character)=="table" and snapshot.character or {}
    for _,plan in pairs(self.plans) do
        if (choice=="auto" or choice==plan.id) and includes(plan.guides,engine.guide.id)
           and (not player.faction or player.faction==plan.faction)
           and snapshot.level>=plan.minLevel and snapshot.level<=plan.maxLevel
           and (choice~="auto" or includes(plan.zones,player.zone)) then return plan end
    end
end
function P:Phase(record,snapshot)
    local q=snapshot.quests[record.id]
    if type(q)=="table" and (q.accepted==true or q.complete==true) then
        return q.complete==true and "TURN_IN_QUEST" or "COMPLETE_QUEST"
    end
    return "ACCEPT_QUEST"
end
function P:Local(plan,engine,record,snapshot)
    local phase=self:Phase(record,snapshot)
    local step=engine.guide.steps[record[phase]]
    local zone=step.waypoint and step.waypoint.zone or step.zone
    if not includes(plan.zones,zone) then return false end
    if phase=="ACCEPT_QUEST" then
        -- Avoid collecting an unplanned delivery that immediately leaves the route.
        local work=engine.guide.steps[record.COMPLETE_QUEST]
        local destination=work.waypoint and work.waypoint.zone or work.zone
        if not includes(plan.zones,destination) then return false end
        if V.Integer(snapshot.questLogCapacity,1) and V.Array(snapshot.active) and #snapshot.active>=snapshot.questLogCapacity then return false end
    end
    local q=snapshot.quests[record.id]
    return not (type(q)=="table" and q.failed==true)
end
function P:Choose(engine,snapshot,candidates,root)
    local plan=self:Active(engine,snapshot)
    if not plan then return nil,nil,false end
    local index=F.modules.LevelingCampaign:Index(engine.guide)
    local byId={};for _,candidate in ipairs(candidates) do byId[candidate.record.id]=candidate end
    -- Rejoin at observed work, without completing or revisiting unknown earlier
    -- introductions. Active eligible quests take precedence over history alone.
    local activeFloor,historyFloor
    for position,stage in ipairs(plan.stages) do
        for _,id in ipairs(stage.quests) do
            local q=snapshot.quests[id]
            if type(q)=="table" then
                if stage.phase=="accept" and byId[id] and (q.accepted==true or q.complete==true) then
                    activeFloor=math.min(activeFloor or position,position)
                end
            end
            if stage.phase=="turn-in" and F.modules.LevelingCampaign:Done(index,engine.state,snapshot,id) then
                historyFloor=math.max(historyFloor or 1,position+1)
            end
        end
    end
    local floor=activeFloor or historyFloor or 1
    local free=V.Integer(snapshot.questLogCapacity,1) and V.Array(snapshot.active) and snapshot.questLogCapacity-#snapshot.active or nil
    for position,stage in ipairs(plan.stages) do
        local available={}
        for _,id in ipairs(stage.quests) do
            local candidate=byId[id]
            if not candidate and stage.pickupAhead and free and free>plan.reservedSlots then
                local record=index.quests[id]
                local level=F.modules.LevelingCampaign:QuestLevel(record,snapshot)
                if level>=snapshot.level-engine.guide.campaign.maxQuestLag and level<=snapshot.level+plan.pickupLead
                   and self:Phase(record,snapshot)=="ACCEPT_QUEST" and root(id,false,{})==record then
                    candidate={record=record,goal=record,pickupAhead=true}
                end
            end
            if position>=floor and candidate and self:Local(plan,engine,candidate.record,snapshot) then
                local q=snapshot.quests[id]
                local native=type(q)=="table" and V.Integer(q.level,1) and q.level~=candidate.record.level
                if (snapshot.level<=stage.maxLevel or candidate.bridge or native)
                   and self:Phase(candidate.record,snapshot)==phases[stage.phase] then available[#available+1]=candidate end
            end
        end
        if #available>0 then
            local selected=available[1]
            -- Activity can choose another task within this outing, without
            -- bypassing the earlier pickup batch or dragging in a distant quest.
            if stage.phase=="work" then
                for _,candidate in ipairs(available) do
                    if candidate.record.id==snapshot.signalQuestId or candidate.record.id==snapshot.trackedQuestId
                       or candidate.record.id==snapshot.selectedQuestId then selected=candidate;break end
                end
            end
            return selected,{plan=plan,stage=stage,tasks=available,status="planned"},true
        end
    end
    -- Unplanned regional alternatives can fill a shortfall; do not silently
    -- send this focused route to Loch Modan or another distant region.
    for _,candidate in ipairs(candidates) do
        if self:Local(plan,engine,candidate.record,snapshot) then
            return candidate,{plan=plan,status="alternative",tasks={candidate}},true
        end
    end
    return nil,{plan=plan,status="waiting",tasks={},reason=free and free<=0 and "quest-log-full" or "no-eligible-task"},true
end
function P:Alternatives(engine,snapshot,candidates,selected)
    local plan=self:Active(engine,snapshot)
    if not plan then return candidates end
    local result,seen={},{}
    for _,candidate in ipairs(candidates) do
        if self:Local(plan,engine,candidate.record,snapshot) then result[#result+1]=candidate;seen[candidate.record.id]=true end
    end
    if selected and selected.pickupAhead and not seen[selected.record.id] then result[#result+1]=selected end
    return result
end
function P:Text(route,selected)
    if not route then return end
    if route.status=="waiting" then
        if route.reason=="quest-log-full" then return "Your quest log is full. Review old quests to free space, or explicitly keep an accepted quest to finish it. The guide will not abandon anything." end
        return "Route waiting: no eligible task in the planned regions. Check deferred or failed quests and other local work; this is not a measured XP guarantee."
    end
    local text=""
    if route.stage then
        local others={};for _,task in ipairs(route.tasks) do if task~=selected then others[#others+1]=task.record.title end end
        local verbs={accept="Also collect nearby: ",work="Also work on: ",["turn-in"]="Also ready to turn in: "}
        if #others>0 then text=verbs[route.stage.phase]..table.concat(others,"; ") end
        if selected and selected.pickupAhead then text=text..(text~="" and "\n" or "").."Early pickup only: save this for later; its field work must still meet your working level range." end
        if route.stage.note then text=text..(text~="" and "\n" or "")..route.stage.note end
    else text="Local alternative outside the authored batches; check its travel and requirements." end
    return text
end
