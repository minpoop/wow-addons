local F = ForeverXP
local C = F:Register("LevelingCampaign", { indexes = {}, runtime = {} })
local V = F.modules.Validation
C.id = "alliance-levels-1-20"
function C:Index(guide)
    local cached=self.indexes[guide.id]
    if cached and cached.guide==guide then return cached end
    local index={guide=guide,quests={},order={},steps={}}
    for position,step in ipairs(guide.steps) do
        index.steps[step.id]=position
        if step.questId then
            local record=index.quests[step.questId]
            if not record then
                record={id=step.questId,order=#index.order+1,requires={}}
                index.quests[step.questId]=record; index.order[#index.order+1]=record
            end
            record[step.type]=position
            if step.type=="ACCEPT_QUEST" then
                record.title,record.level,record.minimum=step.questTitle,step.questLevel,step.minLevel
                record.zone,record.optional=step.zone,step.optional==true
            end
        elseif step.type=="REACH_LEVEL" and step.level==guide.campaign.targetLevel then index.goal=position end
    end
    for _,record in ipairs(index.order) do
        for _,id in ipairs(guide.steps[record.ACCEPT_QUEST].prerequisites or {}) do
            record.requires[#record.requires+1]=guide.steps[index.steps[id]].questId
        end
    end
    self.indexes[guide.id]=index
    return index
end
function C:ValidateState(state)
    local saved=state.campaign
    if saved==nil then return true end
    if type(saved)~="table" or saved.version~=1 or type(saved.deferredByUser)~="table"
       or not ({active=true,waiting=true,["target-reached"]=true})[saved.status]
       or (saved.pinnedQuest~=nil and not V.Integer(saved.pinnedQuest,1))
       or (saved.lastLevel~=nil and not V.Integer(saved.lastLevel,1)) then return nil,"Invalid campaign state retained" end
    local count=0
    for id,value in pairs(saved.deferredByUser) do
        count=count+1
        if count>512 or not V.Integer(id,1) or type(value)~="boolean" then return nil,"Invalid campaign deferrals retained" end
    end
    return true
end
function C:Import(guide,state,character)
    local index=self:Index(guide)
    local old=character.guides["elwynn-forest-shared"]
    if type(old)~="table" or not V.DataOnly(old) or type(old.completed)~="table" or type(old.overrides)~="table" then return end
    for id in pairs(index.steps) do
        if old.completed[id]==true then state.completed[id]=true end
        if old.overrides[id]=="confirmed" or old.overrides[id]=="skipped" then state.overrides[id]=old.overrides[id] end
    end
end
local function savedState(state)
    if not state.campaign then state.campaign={version=1,status="waiting",deferredByUser={}} end
    return state.campaign
end
function C:QuestLevel(record,snapshot)
    local q=snapshot.quests[record.id]
    return type(q)=="table" and V.Integer(q.level,1) and q.level or record.level
end
function C:Done(index,state,snapshot,id)
    local record=index.quests[id]
    if not record then return false end
    local q=snapshot.quests[id]
    return (type(q)=="table" and q.turnedIn==true) or state.completed[index.guide.steps[record.TURN_IN_QUEST].id]==true
end
function C:BuildCandidates(engine,snapshot)
    local guide,state=engine.guide,engine.state
    local index=self:Index(guide)
    local saved=savedState(state)
    local level=snapshot.level
    local function root(id,allowOptional,visiting)
        local record=index.quests[id]
        if not record or self:Done(index,state,snapshot,id) or saved.deferredByUser[id] then return end
        if record.optional and not allowOptional then return end
        local q=snapshot.quests[id]
        if type(q)=="table" and (q.accepted==true or q.complete==true) then return record end
        if level<record.minimum or visiting[id] then return end
        visiting[id]=true
        for _,pre in ipairs(record.requires) do
            if not self:Done(index,state,snapshot,pre) then return root(pre,allowOptional,visiting) end
        end
        return record
    end
    local candidates,byRoot={},{}
    local deferred=0
    for _,record in ipairs(index.order) do
        local questLevel=self:QuestLevel(record,snapshot)
        if not self:Done(index,state,snapshot,record.id) then
            if questLevel<level-guide.campaign.maxQuestLag then deferred=deferred+1 end
            if not record.optional and level>=record.minimum
               and questLevel>=level-guide.campaign.maxQuestLag and questLevel<=level+guide.campaign.maxQuestLead then
                local work=root(record.id,false,{})
                if work then
                    local q=snapshot.quests[work.id]
                    local active=type(q)=="table" and (q.accepted==true or q.complete==true)
                    local zone=type(snapshot.character)=="table" and snapshot.character.zone
                    local score=100-math.abs(questLevel-level)*10+(zone and work.zone==zone and 5 or 0)+(active and 15 or 0)
                    local candidate={record=work,goal=record,score=score,bridge=work.id~=record.id}
                    if not byRoot[work.id] or score>byRoot[work.id].score then byRoot[work.id]=candidate end
                end
            end
        end
    end
    for _,candidate in pairs(byRoot) do candidates[#candidates+1]=candidate end
    table.sort(candidates,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        return a.goal.order<b.goal.order
    end)
    return candidates,deferred,root
end
function C:Update(engine,snapshot)
    local guide,state=engine.guide,engine.state
    if type(snapshot)~="table" or type(snapshot.quests)~="table" or not V.Integer(snapshot.level,1) then
        self.runtime[guide.id]={state=state,error="Waiting for readable level and quest data; previous progress retained."}
        return false
    end
    local index=self:Index(guide)
    local saved=savedState(state)
    local changed=false
    for _,step in ipairs(guide.steps) do
        if state.completed[step.id]~=true and engine:Complete(step,snapshot)==true then state.completed[step.id]=true; changed=true end
    end
    saved.lastLevel=snapshot.level
    if snapshot.level>=guide.campaign.targetLevel or state.completed[guide.steps[index.goal].id]==true then
        saved.status="target-reached"
        state.current,state.finished=nil,true; engine.index=#guide.steps+1
        self.runtime[guide.id]={state=state,snapshot=snapshot,status=saved.status}
        if changed then engine:Changed() end
        return true
    end
    local candidates,deferred,root=self:BuildCandidates(engine,snapshot)
    local selected
    if saved.pinnedQuest then
        local work=root(saved.pinnedQuest,true,{})
        if work then selected={record=work,goal=index.quests[saved.pinnedQuest],pinned=true,bridge=work.id~=saved.pinnedQuest}
        elseif self:Done(index,state,snapshot,saved.pinnedQuest) then saved.pinnedQuest=nil end
    end
    local byId={}; for _,candidate in ipairs(candidates) do byId[candidate.record.id]=candidate end
    if not selected then selected=byId[snapshot.signalQuestId] or byId[snapshot.trackedQuestId] or byId[snapshot.selectedQuestId] end
    local current=engine:Current()
    if not selected and current and current.questId then
        local q=snapshot.quests[current.questId]
        if type(q)=="table" and (q.accepted==true or q.complete==true) then selected=byId[current.questId] end
    end
    selected=selected or candidates[1]
    local position=1
    if selected then
        local record=selected.record
        local q=snapshot.quests[record.id]
        local active=type(q)=="table" and (q.accepted==true or q.complete==true)
        position=record[active and (q.complete==true and "TURN_IN_QUEST" or "COMPLETE_QUEST") or "ACCEPT_QUEST"]
        saved.status="active"
    else saved.status="waiting" end
    local id=guide.steps[position].id
    if state.current~=id or state.finished then changed=true end
    state.current,state.finished=id,false; engine.index=position
    self.runtime[guide.id]={state=state,snapshot=snapshot,status=saved.status,selected=selected,candidates=candidates,deferred=deferred}
    if changed then engine:Changed() end
    return true
end
function C:Refresh(engine)
    local snapshot=F.modules.Compatibility:Read("snapshot")
    if not snapshot then
        self.runtime[engine.guide.id]={state=engine.state,error="Live quest data unavailable; selection retained."}
        F.modules.Events:Emit("FXP_CHANGED")
        return nil,"Live quest data unavailable; selection retained."
    end
    self:Update(engine,snapshot); F.snapshot=snapshot
    F.modules.Events:Emit("FXP_CHANGED")
    return true
end
function C:Defer(engine)
    local current=engine:Current()
    if not current or not current.questId then return nil,"No active campaign quest to defer." end
    local saved=savedState(engine.state)
    saved.deferredByUser[current.questId]=true
    if saved.pinnedQuest==current.questId then saved.pinnedQuest=nil end
    return self:Refresh(engine)
end
function C:Keep(engine,id)
    if not V.Integer(id,1) or not self:Index(engine.guide).quests[id] then return nil,"Quest is not in this campaign." end
    local saved=savedState(engine.state)
    saved.pinnedQuest=id; saved.deferredByUser[id]=nil
    engine.state.review=nil
    return self:Refresh(engine)
end
function C:Auto(engine)
    savedState(engine.state).pinnedQuest=nil; engine.state.review=nil
    return self:Refresh(engine)
end
function C:Cycle(engine)
    local run=self.runtime[engine.guide.id]
    if not run or not run.candidates or #run.candidates==0 then return nil,"No alternative quest group is available at this level." end
    local current=engine:Current() and engine:Current().questId
    local nextIndex=1
    for i,candidate in ipairs(run.candidates) do if candidate.record.id==current then nextIndex=i % #run.candidates+1 end end
    return self:Keep(engine,run.candidates[nextIndex].record.id)
end
function C:Band(level)
    for _,range in ipairs({{1,4},{5,7},{8,9},{10,11},{12,14},{15,17},{18,19}}) do
        if level>=range[1] and level<=range[2] then return range[1].."–"..range[2] end
    end
    return "20"
end
function C:Text(engine)
    local guide,state=engine.guide,engine.state
    local run=self.runtime[guide.id]
    local saved=state.campaign
    if not run or run.state~=state or run.error then return (run and run.state==state and run.error) or "Waiting for live level and quest data." end
    local level=run.snapshot.level
    local lines={"Level "..level.." / "..guide.campaign.targetLevel.." · band "..self:Band(level)}
    if run.status=="target-reached" then
        lines[#lines+1]="Level 20 target reached."
        lines[#lines+1]="Unfinished quests remain saved for review."
        return table.concat(lines,"\n\n")
    end
    local chosen=run.selected
    if not chosen then
        lines[#lines+1]="No suitable unfinished quest group is available from the reference pool."
        lines[#lines+1]="Check deferred choices or finish other level-appropriate quests; the planner will re-evaluate as your state changes."
    else
        local record=chosen.record
        lines[#lines+1]="Quest level "..self:QuestLevel(record,run.snapshot).." · "..(record.zone or "location unconfirmed")
        if chosen.bridge then lines[#lines+1]="Prerequisite for "..chosen.goal.title end
        if chosen.pinned then lines[#lines+1]="Kept by you · Auto plan resumes recommendations" end
        lines[#lines+1]=engine:Current().text
        local q=run.snapshot.quests[record.id]
        if type(q)=="table" and q.objectives then
            for i=1,math.min(2,#q.objectives) do
                local row=q.objectives[i]
                lines[#lines+1]=string.format("%s (%d/%d)",row.text,row.count,row.required)
            end
        end
    end
    if (run.deferred or 0)>0 then lines[#lines+1]=run.deferred.." older quests retained for review" end
    return table.concat(lines,"\n")
end
function C:Select()
    local G=F.modules.GuideEngine
    local player=F.modules.Compatibility:Character()
    if player.faction and player.faction~="Alliance" then return nil,"This campaign is for Alliance characters." end
    local ok,err=G:Select(self.id,F.character)
    if not ok then return nil,err end
    G.state.review=nil
    self:Refresh(G)
    F.modules.MainWindow:Show("guide")
    F:Print("Alliance 1–20 reference playtest: recommendations follow your level. Older unfinished quests stay saved.")
    return true
end
function C:List(engine)
    local run=self.runtime[engine.guide.id]
    if not run or run.state~=engine.state or not run.snapshot then return nil,"Wait for readable campaign data." end
    local index=self:Index(engine.guide)
    for _,record in ipairs(index.order) do
        if not self:Done(index,engine.state,run.snapshot,record.id) then
            local level=self:QuestLevel(record,run.snapshot)
            local note=level<run.snapshot.level-engine.guide.campaign.maxQuestLag and " · older" or ""
            if record.optional then note=note.." · optional" end
            if engine.state.campaign.deferredByUser[record.id] then note=note.." · deferred by you" end
            F:Print(record.id.." · "..record.title.." · quest level "..level..note)
        end
    end
    F:Print("/fxp leveling keep QUEST_ID keeps a quest; /fxp leveling auto resumes automatic recommendations.")
    return true
end
