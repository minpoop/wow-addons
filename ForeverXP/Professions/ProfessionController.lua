local F = ForeverXP
local C = F:Register("ProfessionController", {})
function C:Select(id)
    local catalog = F.modules.RecipeDatabase.catalogs[id]
    if not catalog then return nil, "unknown profession catalog" end
    local state, err = F.modules.ProfessionPlanner:State(F.character, catalog.profession)
    if not state then return nil, err end
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
        local plan, err = F.modules.ProfessionPlanner:Plan(self.catalog, self.state, snapshot.skill,
            snapshot.inventory, snapshot.knownRecipes, self.state.prices, snapshot.opportunities)
        if plan then self.plan, self.error, self.stale = plan, nil, false
        else self.error, self.stale = err, true end
    end
    F.modules.Events:Emit("FXP_CHANGED")
end
function C:Change(key, value)
    if not self.state then return nil, "select a profession catalog first" end
    local V = F.modules.Validation
    if key == "mode" then
        local ok, err = F.modules.ProfessionPlanner:SetMode(self.state,value)
        if not ok then return nil, err end
    elseif key == "target" then
        if not V.Integer(value) or value < self.catalog.minSkill or value > self.catalog.maxSkill then return nil, "target outside verified catalog range" end
        self.state.target = value
    elseif key == "estimate" then
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
