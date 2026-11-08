local F = ForeverXP
local C = F:Register("ProfessionController", {})
function C:Select(id)
    local catalogs=F.modules.RecipeDatabase.catalogs
    local catalog = catalogs[id]
    if not catalog and type(id)=="string" then
        local key=id:lower():gsub("[%s_%-]", "")
        for candidate,value in pairs(catalogs) do if candidate:lower():gsub("[%s_%-]", "")==key then catalog=value; id=candidate; break end end
    end
    if not catalog then return nil, "unknown profession catalog" end
    local new=F.character.professions[catalog.profession]==nil
    local state, err = F.modules.ProfessionPlanner:State(F.character, catalog.profession)
    if not state then return nil, err end
    if catalog.guide then
        local valid,problem=F.modules.ProfessionGuides:State(state)
        if not valid then return nil,problem end
        if new then state.target=300; state.batch=5; state.guideVersion=1 end
    end
    if state.target < catalog.minSkill then state.target = catalog.minSkill end
    F.character.selectedProfession = id
    self.catalog, self.state, self.plan, self.error = catalog, state, nil, nil
    self:Refresh()
    return true
end
function C:Refresh(snapshot)
    if not self.catalog then return end
    if not snapshot then snapshot = F.modules.Compatibility:Read("professionSnapshot", self.catalog.profession) end
    if type(snapshot) ~= "table" then
        self.error, self.stale = "Profession data unavailable; previous plan retained.", true
    else
        local plan,err
        if self.catalog.guide then plan,err=F.modules.ProfessionGuides:Plan(self.catalog,self.state,snapshot)
        else plan,err=F.modules.ProfessionPlanner:Plan(self.catalog,self.state,snapshot.skill,
            snapshot.inventory,snapshot.knownRecipes,self.state.prices,snapshot.opportunities) end
        if plan then
            self.plan,self.error,self.stale,self.snapshot=plan,nil,false,snapshot
            if self.catalog.guide and F.modules.Validation.Integer(plan.current) then self.state.lastSkill=plan.current end
        else self.error, self.stale = err, true end
    end
    F.modules.Events:Emit("FXP_CHANGED")
end
function C:Change(key, value)
    if not self.state then return nil, "select a profession catalog first" end
    local V = F.modules.Validation
    if key == "mode" then
        if self.catalog.guide and self.catalog.kind=="gather" then return nil,"Gather resources to increase gathering skill; buying them does not advance the guide." end
        local ok, err = F.modules.ProfessionPlanner:SetMode(self.state,value)
        if not ok then return nil, err end
    elseif key == "target" then
        if not V.Integer(value) or value < self.catalog.minSkill or value > self.catalog.maxSkill then return nil, "target outside this guide's skill range" end
        self.state.target = value
    elseif key=="batch" and self.catalog.guide then
        if self.catalog.kind~="craft" then return nil,"Batch size applies to crafting guides." end
        if not V.Integer(value,1) or value>20 then return nil,"Batch must be between 1 and 20." end
        self.state.batch=value
    elseif key == "estimate" then
        if self.catalog.guide then return nil,"This guide shows exact next-batch reagents; skill-up totals vary. Use /fxp batch NUMBER." end
        if value ~= "expected" and value ~= "conservative" and value ~= "guaranteed" then return nil, "invalid estimate" end
        self.state.estimate = value
    else return nil, "unknown profession setting" end
    self:Refresh()
    return true
end
function C:Price(item, price)
    if not self.state or not F.modules.Validation.Key(item) or not F.modules.Validation.Finite(price) or price < 0 then return nil, "invalid manual price" end
    self.state.prices = self.state.prices or {}
    if type(self.state.prices) ~= "table" then return nil, "corrupt price data retained" end
    self.state.prices[item] = price
    self:Refresh()
    return true
end

function C:Default()
    if self.catalog then return true end
    local readable,skills=pcall(function() return F.modules.ProfessionAdapter:Skills() end)
    if not readable then skills=nil end
    local ids={}; for id,guide in pairs(F.modules.RecipeDatabase.catalogs) do if guide.guide then ids[#ids+1]=id end end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local guide=F.modules.RecipeDatabase.catalogs[id]
        if skills and skills[guide.skillId] then return self:Select(id) end
    end
    if ids[1] then return self:Select(ids[1]) end
end
