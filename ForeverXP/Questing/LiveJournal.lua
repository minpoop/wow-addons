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
            firstNew=firstNew or #data.order*2+1
            data.order[#data.order+1]=id; data.quests[id]={title=quest.title}
        end
    end
    if #data.order==0 then return nil,"Accept a quest to begin the live journal." end
    F.character.liveJournal=data
    local guide = { id=self.id,title="Live quest journal",verification="observed-character-log",source=snapshot.source,steps={} }
    for _,id in ipairs(data.order) do
        local title=data.quests[id].title
        guide.steps[#guide.steps+1]={id="quest-"..id.."-complete",type="COMPLETE_QUEST",questId=id,text="Complete: "..title}
        guide.steps[#guide.steps+1]={id="quest-"..id.."-turn-in",type="TURN_IN_QUEST",questId=id,text="Turn in: "..title}
    end
    local valid,errors=F.modules.StepValidator:Guide(guide,false)
    if not valid then self.error=table.concat(errors,"; "); return nil,self.error end
    -- Observed journals are deliberately separate from authored, live-verified routes.
    local engine=F.modules.GuideEngine
    engine.guides[self.id]=guide
    local state=F.character.guides[self.id]
    if type(state)=="table" and state.finished==true and firstNew then
        local intact=state.current==nil and type(state.completed)=="table" and type(state.overrides)=="table" and V.DataOnly(state)
        if intact then
            for id,value in pairs(state.completed) do if not V.String(id) or type(value)~="boolean" then intact=false end end
            for id,value in pairs(state.overrides) do if not V.String(id) or (value~="confirmed" and value~="skipped") then intact=false end end
        end
        if intact then state.current,state.finished=guide.steps[firstNew].id,false end
    end
    if F.character.selectedGuide==self.id then
        local ok,err=engine:Select(self.id,F.character)
        if not ok then self.error=err; return nil,err end
    end
    return true
end
function J:Open()
    local snapshot = F.modules.Compatibility:Read("snapshot")
    local ok,err=self:Sync(snapshot)
    if not ok then return nil,err or self.error or "Live tracking unavailable; use /fxp tracking." end
    local selected,message=F.modules.GuideEngine:Select(self.id,F.character)
    if selected then F.modules.GuideEngine:Update(snapshot) end
    return selected,message
end
