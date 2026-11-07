local F = ForeverXP
local G = F:Register("GuideEngine", { guides = {} })
local V = F.modules.Validation
-- Normalized snapshots use positive evidence. Missing data always means unknown.
function G:Complete(step, snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local q = type(snapshot.quests) == "table" and snapshot.quests[step.questId]
    q = type(q) == "table" and q or nil
    if step.type == "ACCEPT_QUEST" then
        if q and (q.accepted == true or q.complete == true or q.turnedIn == true) then return true, "quest acceptance observed" end
    elseif step.type == "COMPLETE_QUEST" then
        if q and (q.complete == true or q.turnedIn == true) then return true, "quest completion observed" end
    elseif step.type == "TURN_IN_QUEST" then
        if q and q.turnedIn == true then return true, "quest turn-in observed" end
    elseif step.type == "COLLECT_ITEMS" then
        local count = type(snapshot.items) == "table" and snapshot.items[step.itemId]
        if V.Integer(count) then return count >= step.count, "inventory count" end
    elseif step.type == "REACH_LEVEL" then
        if V.Integer(snapshot.level, 1) then return snapshot.level >= step.level, "player level" end
    elseif step.type == "REACH_PROFESSION_SKILL" then
        local skill = type(snapshot.professions) == "table" and snapshot.professions[step.profession]
        if V.Integer(skill) then return skill >= step.skill, "profession skill" end
    else
        -- Verified adapters may supply explicit observations for non-quest steps.
        if type(snapshot.observed) == "table" and snapshot.observed[step.id] == true then return true, "explicit observation" end
    end
    return nil, "No reliable completion evidence; manual confirmation available."
end
function G:RegisterGuide(guide)
    local valid, errors = F.modules.StepValidator:Guide(guide, true)
    if not valid then return nil, table.concat(errors, "; ") end
    if self.guides[guide.id] then return nil, "duplicate guide" end
    self.guides[guide.id] = F.modules.SavedVariables.Copy(guide)
    return true
end
function G:RegisterReferenceGuide(guide)
    local valid,errors=F.modules.StepValidator:Guide(guide,false)
    if not valid then return nil,table.concat(errors,"; ") end
    if guide.verification~="reference-reviewed" or not V.String(guide.source) then return nil,"reference evidence required" end
    if self.guides[guide.id] then return nil,"duplicate guide" end
    self.guides[guide.id]=F.modules.SavedVariables.Copy(guide)
    return true
end
function G:Recommend(character)
    local best, score
    for _, guide in pairs(self.guides) do
        if guide.verification~="reference-reviewed" and (not guide.faction or guide.faction == character.faction)
           and (not guide.race or guide.race == character.race)
           and (not guide.class or guide.class == character.class)
           and (not guide.minLevel or (character.level and character.level >= guide.minLevel))
           and (not guide.maxLevel or (character.level and character.level <= guide.maxLevel)) then
            local candidate = (guide.race and 10 or 0) + (guide.class and 5 or 0) + (guide.zone == character.zone and 2 or 0)
            if not best or candidate > score or (candidate == score and guide.id < best.id) then best, score = guide, candidate end
        end
    end
    return best -- authored order retained; no invented distance or travel graph
end
function G:Select(id, character)
    local guide = self.guides[id]
    if not guide then return nil, "unknown guide" end
    local state = character.guides[id]
    if state ~= nil and (type(state) ~= "table" or type(state.overrides) ~= "table" or type(state.completed) ~= "table") then
        return nil, "corrupt guide progress retained; reset explicitly to recover"
    end
    if state then
        if not V.DataOnly(state) or (state.finished ~= nil and type(state.finished) ~= "boolean")
           or (state.review ~= nil and type(state.review) ~= "boolean") or (state.current ~= nil and not V.String(state.current))
           or (state.focusStep ~= nil and not V.String(state.focusStep))
           or (state.resumeStart~=nil and not V.String(state.resumeStart))
           or (state.finished and state.current ~= nil) then return nil, "invalid saved cursor retained" end
        if state.resume~=nil then
            local resume=state.resume
            if type(resume)~="table" or not V.String(resume.target) or not V.String(resume.reason)
               or not V.Integer(resume.deferred) or (resume.from~=nil and not V.String(resume.from)) then
                return nil,"invalid saved resume record retained"
            end
        end
        for id,value in pairs(state.completed) do
            if not V.String(id) or type(value) ~= "boolean" then return nil, "invalid saved completion retained" end
        end
        for id,value in pairs(state.overrides) do
            if not V.String(id) or (value ~= "confirmed" and value ~= "skipped") then return nil, "invalid saved override retained" end
        end
    end
    state = state or { current = guide.steps[1].id, completed = {}, overrides = {} }
    local index
    for i, step in ipairs(guide.steps) do if step.id == state.current then index = i end end
    if not index and not state.finished then return nil, "saved step missing from guide; progress retained" end
    character.guides[id], character.selectedGuide = state, id
    local changed=self.guide~=guide or self.state~=state
    self.guide, self.state, self.index = guide, state, index or #guide.steps + 1
    if changed then
        self.resumePending=guide.autoResume==true
        self.lastResumeSignal,self.lastResumeNative=nil,nil
    end
    self:Changed()
    return true
end
function G:Current() return self.guide and self.guide.steps[self.index] end
function G:Changed() F.modules.Events:Emit("FXP_GUIDE_CHANGED") end
function G:Progress()
    local count=0
    if not self.guide or not self.state then return count end
    for _,step in ipairs(self.guide.steps) do if self.state.completed[step.id]==true then count=count+1 end end
    return count
end
function G:Advance(manual)
    local step = self:Current()
    if not step then return false end
    if manual then self.state.overrides[step.id] = "confirmed" end
    self.state.completed[step.id] = true
    if self.guide.id==F.modules.LiveJournal.id then
        self.state.review=nil
        F.modules.LiveJournal:Update({})
        return true
    end
    self.index = self.index + 1
    local following = self:Current()
    self.state.current, self.state.finished = following and following.id or nil, following == nil
    self.state.review = nil
    self:Changed()
    return true
end
function G:Back()
    if not self.guide then return end
    self.index = math.max(1, self.index - 1)
    self.state.current, self.state.finished, self.state.review = self:Current().id, false, true
    self:Changed() -- review pauses automatic advancement until manual forward
end
function G:Skip()
    local step = self:Current()
    if not step or not step.optional then return nil, "Only optional steps can be skipped." end
    self.state.overrides[step.id] = "skipped"
    return self:Advance(false)
end
function G:Update(snapshot)
    if F.modules.Detours and F.modules.Detours.active then return end
    if not F.settings.autoAdvance or not self.state or self.state.review then return end
    if self.guide and self.guide.id==F.modules.LiveJournal.id then return F.modules.LiveJournal:Update(snapshot) end
    if self.guide and self.guide.autoResume then F.modules.RecoveryEngine:Apply(self,snapshot) end
    while self:Current() do
        local step, ready = self:Current(), true
        for _, id in ipairs(step.prerequisites or {}) do if not self.state.completed[id] then ready = false end end
        if not ready or self:Complete(step, snapshot) ~= true then break end
        self:Advance(false)
    end
end
function G:Recovery(snapshot)
    local suggestions = {}
    if not self.guide then return suggestions end
    local completed = F.modules.SavedVariables.Copy(self.state.completed)
    for i = self.index, #self.guide.steps do
        local step = self.guide.steps[i]
        for _, id in ipairs(step.prerequisites or {}) do
            if completed[id] ~= true then return suggestions, "Unresolved prerequisite: " .. id end
        end
        local done, reason = self:Complete(step, snapshot)
        if done then suggestions[#suggestions+1] = { id = step.id, reason = reason }; completed[step.id] = true
        else break end
    end
    return suggestions -- recommendations only; no uncertain skips or hidden writes
end
