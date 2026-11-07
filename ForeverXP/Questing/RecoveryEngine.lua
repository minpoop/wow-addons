local F = ForeverXP
local R = F:Register("RecoveryEngine", {})
local V = F.modules.Validation
local function pending(state,step) return state.completed[step.id]~=true end
local function ready(state,step,snapshot)
    for _,id in ipairs(step.prerequisites or {}) do if state.completed[id]~=true then return false end end
    return not step.minLevel or (V.Integer(snapshot.level,1) and snapshot.level>=step.minLevel)
end
function R:Apply(engine,snapshot,force)
    local guide,state=engine.guide,engine.state
    if not guide or not guide.autoResume or not state or type(snapshot)~="table" or type(snapshot.quests)~="table" then return false end
    if snapshot.active~=nil and not V.Array(snapshot.active) then return false end
    if state.finished and not force then return false end
    if not force and F.settings.recovery=="disabled" then return false end
    local changed=false
    local byQuest,byStep={},{}
    local lastTurnIn
    for index,step in ipairs(guide.steps) do
        byStep[step.id]=index
        if step.questId then
            byQuest[step.questId]=byQuest[step.questId] or {}
            byQuest[step.questId][step.type]=index
        end
        if pending(state,step) and engine:Complete(step,snapshot)==true then
            state.completed[step.id]=true; changed=true
        end
        if step.type=="TURN_IN_QUEST" and engine:Complete(step,snapshot)==true then lastTurnIn=index end
    end
    local function forQuest(id)
        if not V.Integer(id,1) or not byQuest[id] then return end
        local q=snapshot.quests[id]
        if type(q)~="table" or q.turnedIn==true or (q.accepted~=true and q.complete~=true) then return end
        local phase=q.complete==true and "TURN_IN_QUEST" or "COMPLETE_QUEST"
        local index=byQuest[id][phase]
        if index and pending(state,guide.steps[index]) then return index end
    end
    local initial=engine.resumePending==true or not state.resumeStart
    local signalChanged=snapshot.signalRevision~=nil and snapshot.signalRevision~=engine.lastResumeSignal
    local native=snapshot.trackedQuestId or snapshot.selectedQuestId
    local nativeChanged=native~=nil and native~=engine.lastResumeNative
    local target,reason
    if signalChanged then
        target=forQuest(snapshot.signalQuestId)
        if target then reason="quest acceptance or objective update" end
    end
    if not target and (initial or nativeChanged or force) then
        target=forQuest(snapshot.trackedQuestId) or forQuest(snapshot.selectedQuestId)
        if target then reason="your tracked or selected quest" end
    end
    if not target then
        local current=engine:Current()
        target=current and forQuest(current.questId)
        if target then reason="your current accepted quest" end
    end
    if not target then
        for _,id in ipairs(snapshot.active or {}) do
            target=forQuest(id)
            if target then reason="a quest already in your log"; break end
        end
    end
    -- Test/provider snapshots can omit the active array; only explicit positive
    -- quest records are candidates, never absence or inferred prerequisites.
    if not target then
        for _,step in ipairs(guide.steps) do
            if step.questId then
                target=forQuest(step.questId)
                if target then reason="a quest already in your log"; break end
            end
        end
    end
    local floor=state.resumeStart and byStep[state.resumeStart] or 1
    if initial then
        if target then
            local quest=guide.steps[target].questId
            floor=byQuest[quest].ACCEPT_QUEST or target
        elseif lastTurnIn then floor=lastTurnIn+1 end
    end
    if not target and (state.resumeStart or lastTurnIn) then
        for index=floor,#guide.steps do
            local step=guide.steps[index]
            if pending(state,step) and ready(state,step,snapshot)
               and (step.type=="ACCEPT_QUEST" or step.type=="REACH_LEVEL") then
                target=index; reason="completed quest history and remaining route prerequisites"; break
            end
        end
    end
    engine.lastResumeSignal,engine.lastResumeNative=snapshot.signalRevision,native
    if target then
        if initial or not state.resumeStart then state.resumeStart=guide.steps[math.min(floor,#guide.steps)].id end
        engine.resumePending=false
        if engine.index~=target then
            local from=state.current
            local deferred=0
            for index=1,target-1 do if pending(state,guide.steps[index]) then deferred=deferred+1 end end
            state.resume={from=from,target=guide.steps[target].id,reason=reason,deferred=deferred}
            state.current,state.finished=guide.steps[target].id,false
            engine.index=target
            changed=true
            if deferred>0 then F:Print("Matched your quest to step "..target..". "..deferred.." earlier steps remain unconfirmed; /fxp resume undo returns to the previous step.") end
        end
    end
    if changed then engine:Changed() end
    return target~=nil
end
function R:Undo(engine)
    local state=engine.state
    local from=state and type(state.resume)=="table" and state.resume.from
    if not from then return nil,"No automatic catch-up to undo." end
    for index,step in ipairs(engine.guide.steps) do
        if step.id==from then
            state.current,state.finished,state.review=from,false,true
            engine.index=index; engine:Changed()
            return true
        end
    end
    return nil,"Previous step is no longer in this guide; progress retained."
end
