local F = ForeverXP
local J = F:Register("LiveJournal", { id = "live-quest-journal" })
local V = F.modules.Validation
function J:Sync(snapshot)
    if type(snapshot) ~= "table" or not V.Array(snapshot.active) or type(snapshot.quests) ~= "table" then return nil end
    local data = F.character.liveJournal
    if data ~= nil then
        if type(data) ~= "table" or not V.DataOnly(data) or not V.Array(data.order) or type(data.quests) ~= "table" then self.error="Invalid journal retained; no progress overwritten"; return nil end
        local seen={}
        for _,id in ipairs(data.order) do
            local record=data.quests[id]
            if not V.Integer(id,1) or seen[id] or type(record) ~= "table" or not V.String(record.title) then self.error="Invalid journal retained"; return nil end
            seen[id]=true
        end
    else data = { order = {}, quests = {} } end
    local firstNew
    for _,id in ipairs(snapshot.active) do
        local quest = snapshot.quests[id]
        if V.Integer(id,1) and type(quest) == "table" and V.String(quest.title) and not data.quests[id] then
            if #data.order>=100 then self.error="Journal limit reached (100 quests); existing progress retained"; break end
            firstNew=firstNew or id
            data.order[#data.order+1]=id; data.quests[id]={title=quest.title}
        end
    end
    if #data.order==0 then return nil,"Accept a quest to begin the live journal." end
    F.character.liveJournal=data
    local guide = { id=self.id,title="Live quest journal",verification="observed-character-log",source=snapshot.source,steps={} }
    for _,phase in ipairs({"complete","turn-in"}) do
        for _,id in ipairs(data.order) do
            local title=data.quests[id].title
            guide.steps[#guide.steps+1]={id="quest-"..id.."-"..phase,type=phase=="complete" and "COMPLETE_QUEST" or "TURN_IN_QUEST",questId=id,text=(phase=="complete" and "Complete: " or "Turn in: ")..title}
        end
    end
    local valid,errors=F.modules.StepValidator:Guide(guide,false)
    if not valid then self.error=table.concat(errors,"; "); return nil,self.error end
    -- Observed journals are deliberately separate from authored, live-verified routes.
    local engine=F.modules.GuideEngine
    engine.guides[self.id]=guide
    local state=F.character.guides[self.id]
    if type(state)=="table" and state.finished==true and firstNew then
        local intact=state.current==nil and type(state.completed)=="table" and type(state.overrides)=="table" and V.DataOnly(state)
            and (state.focusStep==nil or V.String(state.focusStep)) and (state.review==nil or type(state.review)=="boolean")
        if intact then
            for id,value in pairs(state.completed) do if not V.String(id) or type(value)~="boolean" then intact=false end end
            for id,value in pairs(state.overrides) do if not V.String(id) or (value~="confirmed" and value~="skipped") then intact=false end end
        end
        if intact then state.current,state.finished="quest-"..firstNew.."-complete",false end
    end
    if F.character.selectedGuide==self.id then
        local ok,err=engine:Select(self.id,F.character)
        if not ok then self.error=err; return nil,err end
    end
    return true
end
function J:Update(snapshot)
    local engine=F.modules.GuideEngine
    local state,guide=engine.state,engine.guide
    local changed=false
    -- Positive observations can arrive out of order. Record them without declaring
    -- any unobserved earlier quest complete or turned in.
    for _,step in ipairs(guide.steps) do
        if state.completed[step.id]~=true and engine:Complete(step,snapshot)==true then
            state.completed[step.id]=true; changed=true
        end
    end
    local target
    for index,step in ipairs(guide.steps) do
        if state.completed[step.id]~=true then
            target=target or index
            if state.focusStep==step.id then target=index; break end
        end
    end
    if state.focusStep and state.completed[state.focusStep]==true then state.focusStep=nil end
    local current=target and guide.steps[target].id or nil
    if state.current~=current then changed=true end
    state.current,state.finished=current,target==nil
    engine.index=target or #guide.steps+1
    if changed then engine:Changed() end
end
function J:Progress()
    local engine=F.modules.GuideEngine
    local count=0
    for _,step in ipairs(engine.guide.steps) do if engine.state.completed[step.id]==true then count=count+1 end end
    return count
end
function J:NextStep()
    local engine=F.modules.GuideEngine
    for _,step in ipairs(engine.guide.steps) do
        if step.id~=engine.state.current and engine.state.completed[step.id]~=true then return step end
    end
end
function J:Focus(id)
    if not V.Integer(id,1) then return nil,"Supply a quest ID from /fxp quests." end
    local engine=F.modules.GuideEngine
    if not engine.guide or engine.guide.id~=self.id then
        local ok,err=self:Open(); if not ok then return nil,err end
    end
    for index,step in ipairs(engine.guide.steps) do
        if step.questId==id and engine.state.completed[step.id]~=true then
            engine.state.focusStep,engine.state.current=step.id,step.id
            engine.state.finished,engine.state.review=false,nil
            engine.index=index; engine:Changed(); return true
        end
    end
    return nil,"No unfinished journal step for that quest."
end
function J:CycleFocus()
    local engine=F.modules.GuideEngine
    if not engine.guide or engine.guide.id~=self.id then return nil,"Open /fxp journal first." end
    local current=engine:Current() and engine:Current().questId
    local pending,seen={},{}
    for _,step in ipairs(engine.guide.steps) do
        if engine.state.completed[step.id]~=true and not seen[step.questId] then
            pending[#pending+1]=step.questId; seen[step.questId]=true
        end
    end
    if #pending==0 then return nil,"Journal complete." end
    local index=1
    for i,id in ipairs(pending) do if id==current then index=i % #pending+1 end end
    return self:Focus(pending[index])
end
function J:Open()
    local snapshot = F.modules.Compatibility:Read("snapshot")
    local ok,err=self:Sync(snapshot)
    if not ok then return nil,err or self.error or "Live tracking unavailable; use /fxp tracking." end
    local selected,message=F.modules.GuideEngine:Select(self.id,F.character)
    if selected then F.modules.GuideEngine:Update(snapshot) end
    return selected,message
end
