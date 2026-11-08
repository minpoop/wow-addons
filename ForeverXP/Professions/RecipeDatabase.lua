local F = ForeverXP
local R = F:Register("RecipeDatabase", { catalogs = {} })
local V = F.modules.Validation
function R:Validate(catalog, production)
    if type(catalog) ~= "table" or not V.DataOnly(catalog) then return nil, "catalog must be finite, acyclic data" end
    if not V.String(catalog.id) or not V.String(catalog.title) or not V.String(catalog.profession) then return nil, "catalog identity required" end
    if production and not V.Verified(catalog) then return nil, "live verification and source required" end
    if not V.Integer(catalog.minSkill) or not V.Integer(catalog.maxSkill, 1) or catalog.minSkill >= catalog.maxSkill then return nil, "invalid skill range" end
    if type(catalog.recipes) ~= "table" or not next(catalog.recipes) or type(catalog.producers) ~= "table" then return nil, "recipes and producers required" end
    local all = {}
    for id, recipe in pairs(catalog.recipes) do
        if not V.Key(id) or type(recipe) ~= "table" or not V.Key(recipe.output)
           or not V.Integer(recipe.outputCount, 1) or type(recipe.inputs) ~= "table" or not next(recipe.inputs) then return nil, "invalid recipe" end
        for item, count in pairs(recipe.inputs) do
            if not V.Key(item) or not V.Integer(count, 1) then return nil, "invalid reagent" end
        end
        if recipe.vendor ~= nil then
            if type(recipe.vendor) ~= "table" then return nil, "invalid vendor metadata" end
            for item, flag in pairs(recipe.vendor) do
                if not recipe.inputs[item] or type(flag) ~= "boolean" then return nil, "invalid vendor reagent" end
            end
        end
        if recipe.station ~= nil and not V.String(recipe.station) then return nil, "invalid station" end
        all[id] = 1
    end
    for item, recipe in pairs(catalog.producers) do
        if not V.Key(item) or not catalog.recipes[recipe] or catalog.recipes[recipe].output ~= item then return nil, "invalid producer mapping" end
    end
    local valid, err = F.modules.MaterialCalculator:Calculate(all, catalog.recipes, {}, catalog.producers)
    if not valid then return nil, err end
    if not V.Array(catalog.segments, true) then return nil, "dense segments required" end
    local edge, seen = catalog.minSkill, {}
    for _, segment in ipairs(catalog.segments) do
        if type(segment) ~= "table" or not V.String(segment.id) or seen[segment.id]
           or segment.from ~= edge or not V.Integer(segment.to, 1) or segment.to <= edge or segment.to > catalog.maxSkill
           or not V.Array(segment.choices, true) then return nil, "invalid, duplicate or discontinuous skill segment" end
        seen[segment.id], edge = true, segment.to
        local choices = {}
        for _, choice in ipairs(segment.choices) do
            if type(choice) ~= "table" or not catalog.recipes[choice.recipe] or choices[choice.recipe]
               or not V.Finite(choice.chance) or choice.chance <= 0 or choice.chance > 1
               or not V.Integer(choice.gain, 1) then return nil, "invalid skill-up choice" end
            choices[choice.recipe] = true
        end
        if segment.trainer ~= nil and not V.String(segment.trainer) then return nil, "trainer reminder must be text" end
    end
    if edge ~= catalog.maxSkill then return nil, "incomplete catalog coverage" end
    return true
end
function R:RegisterCatalog(catalog)
    local ok, err = self:Validate(catalog, true)
    if not ok then return nil, err end
    if self.catalogs[catalog.id] then return nil, "duplicate catalog" end
    self.catalogs[catalog.id] = F.modules.SavedVariables.Copy(catalog)
    return true
end

function R:RegisterReferenceGuide(guide)
    local ok,err=F.modules.ProfessionGuides:Validate(guide)
    if not ok then return nil,err end
    if self.catalogs[guide.id] then return nil,"duplicate profession guide" end
    self.catalogs[guide.id]=F.modules.SavedVariables.Copy(guide)
    return true
end
