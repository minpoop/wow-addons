local F = ForeverXP
local P = F:Register("ProfessionPlanner", {})
local V = F.modules.Validation
function P:State(character, profession)
    local state = character.professions[profession]
    if state ~= nil and (type(state) ~= "table" or not V.DataOnly(state)
       or not ({Farm=true,Buy=true,Hybrid=true})[state.mode] or not V.Integer(state.target)
       or (state.prices ~= nil and type(state.prices) ~= "table")) then
        return nil, "corrupt profession state retained"
    end
    if not state then state = { mode = "Hybrid", target = 1 }; character.professions[profession] = state end
    return state
end
function P:SetMode(state, mode)
    if not ({Farm=true,Buy=true,Hybrid=true})[mode] then return nil, "invalid mode" end
    state.mode = mode
    return true -- target and progression deliberately shared between all three modes
end
function P:Estimate(points, probability, safety)
    if not V.Integer(points) or not V.Finite(probability)
       or probability <= 0 or probability > 1 or not V.Finite(safety) or safety < 0 or safety > 2 then
        return nil, "invalid estimate parameters"
    end
    return { guaranteed = probability == 1 and points or nil, expected = points / probability,
        conservative = math.ceil(points / probability * (1 + safety)),
        note = "Estimate assumes constant independent skill-up probability; not a guarantee." }
end
-- Authored skill bands, not invented recipes or a claim of globally optimal cost.
function P:Plan(catalog, state, current, inventory, known, prices, opportunities)
    local ok, err = F.modules.RecipeDatabase:Validate(catalog, false)
    if not ok then return nil, err end
    if type(state) ~= "table" or not V.DataOnly(state) or not ({Farm=true,Buy=true,Hybrid=true})[state.mode]
       or not V.Integer(state.target) or state.target > catalog.maxSkill or state.target < catalog.minSkill
       or not V.Integer(current) or current < catalog.minSkill or current > catalog.maxSkill then return nil, "invalid current or target skill" end
    if type(inventory) ~= "table" or type(known) ~= "table" then return nil, "inventory and recipe knowledge required" end
    local safety = state.safety == nil and 0.2 or state.safety
    if not V.Finite(safety) or safety < 0 or safety > 2 then return nil, "invalid safety margin" end
    if state.selectedRecipes ~= nil and type(state.selectedRecipes) ~= "table" then return nil, "invalid recipe overrides" end
    local plan = { current = current, target = state.target, rows = {}, trainers = {}, allGuaranteed = true }
    local expected, conservative, guaranteed = {}, {}, {}
    for _, segment in ipairs(catalog.segments) do
        local first, last = math.max(current, segment.from), math.min(state.target, segment.to)
        if last > first then
            local selected = state.selectedRecipes and state.selectedRecipes[segment.id]
            local choice
            for _, option in ipairs(segment.choices) do
                if known[option.recipe] == true and (not selected or option.recipe == selected) then choice = option; break end
            end
            if not choice then return nil, "No known selected recipe for segment " .. segment.id .. "; learn a recipe or choose an alternative." end
            local points = last - first
            local average = points / (choice.chance * choice.gain)
            local count, margin = math.ceil(average), math.ceil(average * (1 + safety))
            expected[choice.recipe] = (expected[choice.recipe] or 0) + count
            conservative[choice.recipe] = (conservative[choice.recipe] or 0) + margin
            if choice.chance ~= 1 then plan.allGuaranteed = false end
            guaranteed[choice.recipe] = (guaranteed[choice.recipe] or 0) + math.ceil(points / choice.gain)
            plan.rows[#plan.rows+1] = { segment = segment.id, recipe = choice.recipe, from = first, to = last,
                expectation = average, expectedCrafts = count, conservativeCrafts = margin, chance = choice.chance }
            if segment.trainer then plan.trainers[#plan.trainers+1] = segment.trainer end
        end
    end
    local calculator = F.modules.MaterialCalculator
    plan.expected, err = calculator:Calculate(expected, catalog.recipes, inventory, catalog.producers)
    if not plan.expected then return nil, err end
    plan.conservative, err = calculator:Calculate(conservative, catalog.recipes, inventory, catalog.producers)
    if not plan.conservative then return nil, err end
    for recipe in pairs(plan.conservative.crafts) do
        if known[recipe] ~= true then return nil, "Required processing recipe is not known: " .. tostring(recipe) end
    end
    if plan.allGuaranteed then plan.guaranteed = calculator:Calculate(guaranteed, catalog.recipes, inventory, catalog.producers) end
    local estimate = state.estimate or "conservative"
    if estimate ~= "expected" and estimate ~= "conservative" and estimate ~= "guaranteed" then return nil, "invalid estimate mode" end
    if not plan[estimate] then return nil, "Guaranteed requirements are unavailable for probabilistic skill-ups." end
    plan.materials = plan[estimate]
    plan.distribution, err = self:Distribute(plan.materials, state, opportunities, prices)
    if not plan.distribution then return nil, err end
    plan.estimate = estimate
    return plan
end
function P:Distribute(materials, state, opportunities, prices)
    if type(materials) ~= "table" or type(materials.missing) ~= "table" or type(state) ~= "table"
       or not ({Farm=true,Buy=true,Hybrid=true})[state.mode] or (opportunities ~= nil and type(opportunities) ~= "table")
       or (prices ~= nil and type(prices) ~= "table") then return nil, "invalid distribution inputs" end
    local plan = { farm = {}, buy = {}, cost = 0, unknownPrices = {}, routes = {} }
    for item, count in pairs(materials.missing) do
        if not V.Key(item) or not V.Integer(count) then return nil, "invalid missing material count" end
        local opportunity = opportunities and opportunities[item]
        if opportunity ~= nil and type(opportunity) ~= "table" then return nil, "invalid gathering opportunity" end
        local farm = state.mode == "Farm" or (state.mode == "Hybrid" and opportunity and opportunity.verified == true)
        if farm then
            plan.farm[item] = count
            if opportunity and opportunity.verified then plan.routes[item] = opportunity.route end
        else
            plan.buy[item] = count
            local price = prices and prices[item]
            if type(price) == "number" and price >= 0 and price < math.huge then plan.cost = plan.cost + price * count
            else plan.unknownPrices[item] = true end
        end
    end
    plan.costComplete = next(plan.unknownPrices) == nil
    return plan
end
