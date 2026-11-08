local F = ForeverXP
local G = F:Register("ProfessionGuides", {})
local V = F.modules.Validation
function G:Validate(guide)
    if type(guide)~="table" or not V.DataOnly(guide) or guide.guide~=true
       or guide.verification~="reference-reviewed" or not V.String(guide.source)
       or not V.String(guide.id) or not V.String(guide.profession) or not V.String(guide.title) or not V.String(guide.name)
       or not V.Integer(guide.skillId,1) or guide.minSkill~=1 or guide.maxSkill~=300
       or not ({craft=true,gather=true})[guide.kind] or not V.Array(guide.stages,true)
       or type(guide.itemNames)~="table" or type(guide.recipes)~="table" or type(guide.toolRecipes)~="table" or type(guide.producers)~="table"
       or not V.Array(guide.rankSpells,true) or #guide.rankSpells~=4 or type(guide.rankNotes)~="table" then return nil,"invalid reference profession guide" end
    for _,id in ipairs(guide.rankSpells) do if not V.Integer(id,1) then return nil,"invalid rank spell" end end
    for id,name in pairs(guide.itemNames) do if not V.Integer(id,1) or not V.String(name) then return nil,"invalid item name" end end
    for id,r in pairs(guide.recipes) do
        if not V.Integer(id,1) or type(r)~="table" or not V.String(r.name) or not V.String(r.acquisition) or not V.Integer(r.minimum,1)
           or not V.Key(r.output) or not V.Integer(r.outputCount,1) or type(r.inputs)~="table" or not next(r.inputs)
           or not V.Array(r.tools) then return nil,"invalid reference recipe" end
        for item,count in pairs(r.inputs) do if not V.Integer(item,1) or not V.Integer(count,1) or not guide.itemNames[item] then return nil,"invalid reference reagent" end end
        for _,item in ipairs(r.tools) do if not V.Integer(item,1) or not guide.itemNames[item] then return nil,"invalid recipe tool" end end
        for _,field in ipairs({"sellers","questSources"}) do
          if r[field]~=nil then
            if not V.Array(r[field]) then return nil,"invalid recipe sources" end
            for _,seller in ipairs(r[field]) do
                if type(seller)~="table" or not V.Integer(seller.id,1) or not V.String(seller.name) or not V.String(seller.faction)
                   or (seller.zone~=nil and not V.String(seller.zone)) then return nil,"invalid recipe seller" end
            end
          end
        end
    end
    for item,id in pairs(guide.toolRecipes) do if not guide.recipes[id] or guide.recipes[id].output~=item then return nil,"invalid tool recipe" end end
    for item,id in pairs(guide.producers) do if not guide.recipes[id] or guide.recipes[id].output~=item or not guide.recipes[id].fixedOutput then return nil,"invalid processing recipe" end end
    local craftAll={}; for id in pairs(guide.recipes) do craftAll[id]=1 end
    if next(craftAll) then
        local producers={}; for item,id in pairs(guide.toolRecipes) do producers[item]=id end; for item,id in pairs(guide.producers) do producers[item]=id end
        local ok,err=F.modules.MaterialCalculator:Calculate(craftAll,guide.recipes,{},producers)
        if not ok then return nil,err end
    end
    local edge,seen=1,{}
    for _,stage in ipairs(guide.stages) do
        if type(stage)~="table" or not V.String(stage.id) or seen[stage.id] or stage.from~=edge
           or not V.Integer(stage.to,2) or stage.to<=edge or stage.to>300 or not V.String(stage.text) then return nil,"invalid profession stage coverage" end
        seen[stage.id],edge=true,stage.to
        if guide.kind=="craft" then
            if not V.Array(stage.choices,true) then return nil,"recipe choices required" end
            for _,id in ipairs(stage.choices) do if not guide.recipes[id] or guide.recipes[id].minimum>stage.from then return nil,"recipe unavailable at stage start" end end
        elseif not V.Array(stage.resources,true) then return nil,"gathering resources required"
        else for _,id in ipairs(stage.resources) do if not V.Integer(id,1) or not guide.itemNames[id] then return nil,"invalid gathering resource" end end end
    end
    if edge~=300 then return nil,"profession coverage must reach 300" end
    return true
end
function G:Seller(recipe)
    local faction=F.modules.Compatibility:Character().faction
    for _,seller in ipairs(recipe.sellers or {}) do
        local key=faction=="Alliance" and "A" or (faction=="Horde" and "H" or nil)
        if not key or seller.faction:find(key,1,true) then
            return "Reference seller: "..seller.name..(seller.zone and (" · "..seller.zone) or "")
        end
    end
    for _,source in ipairs(recipe.questSources or {}) do
        local key=faction=="Alliance" and "A" or (faction=="Horde" and "H" or nil)
        if not key or source.faction:find(key,1,true) then return "Reference quest: "..source.name..(source.zone and (" · "..source.zone) or "") end
    end
end
function G:State(state)
    if not V.Integer(state.target,1) or state.target>300 or (state.guideVersion~=nil and state.guideVersion~=1)
       or (state.batch~=nil and (not V.Integer(state.batch,1) or state.batch>20))
       or (state.lastSkill~=nil and not V.Integer(state.lastSkill))
       or (state.preferredRecipes~=nil and type(state.preferredRecipes)~="table") then return nil,"Unknown or invalid profession guide state retained." end
    for key,id in pairs(state.preferredRecipes or {}) do
        if not V.String(key) or not V.Integer(id,1) then return nil,"Invalid recipe preferences retained." end
    end
    return true
end
function G:Name(guide,id) return guide.itemNames[id] or tostring(id) end
function G:Stage(guide,skill)
    for _,stage in ipairs(guide.stages) do if skill>=stage.from and skill<stage.to then return stage end end
end
function G:Plan(guide,state,snapshot)
    if type(snapshot)~="table" or snapshot.skillsReady~=true then return nil,"Skill lines unreadable; open your Skills window and expand professions." end
    if (snapshot.cap~=nil and not V.Integer(snapshot.cap,1)) or type(snapshot.knownRecipes)~="table" then return nil,"Unreadable profession knowledge; previous observation retained." end
    local valid,err=self:State(state); if not valid then return nil,err end
    local plan={target=state.target,kind=guide.kind,inventoryReady=type(snapshot.inventory)=="table",cap=snapshot.cap,knownRecipes=snapshot.knownRecipes or {}}
    if snapshot.skill==nil then plan.status="not-found"; return plan end
    if not V.Integer(snapshot.skill) then return nil,"Unreadable profession skill; previous progress retained." end
    plan.current=snapshot.skill
    if plan.current>=state.target then plan.status="target-reached"; return plan end
    local stage=self:Stage(guide,plan.current)
    if not stage then return nil,"Waiting for a readable skill within this 1–300 guide." end
    plan.stage,plan.stop=stage,math.min(stage.to,state.target)
    plan.status="active"
    if V.Integer(plan.cap,1) and plan.current>=plan.cap and state.target>plan.cap then plan.status="train-rank" end
    if guide.kind=="gather" then
        plan.inventory=snapshot.inventory
        return plan
    end
    local selected=state.preferredRecipes and state.preferredRecipes[stage.id]
    local id
    for _,choice in ipairs(stage.choices) do
        if (not selected or selected==choice) and plan.knownRecipes[choice]==true then id=choice; break end
    end
    if not id then
        if selected then
            for _,choice in ipairs(stage.choices) do if selected==choice then id=choice end end
        end
        id=id or stage.choices[1]
    end
    if plan.inventoryReady then
        local visiting={}
        local function toolRecipe(recipe)
            if visiting[recipe] then return recipe end
            visiting[recipe]=true
            local r=guide.recipes[recipe]
            for _,tool in ipairs(r.tools) do
                if snapshot.inventory[tool]==0 and guide.toolRecipes[tool] then
                    local maker=guide.toolRecipes[tool]
                    if guide.recipes[maker].minimum<=plan.current then return toolRecipe(maker) end
                end
            end
            for tool in pairs(r.inputs) do
                if snapshot.inventory[tool]==0 and guide.toolRecipes[tool] and recipe~=guide.toolRecipes[tool] then
                    local maker=guide.toolRecipes[tool]
                    if guide.recipes[maker].minimum<=plan.current then return toolRecipe(maker) end
                end
            end
            return recipe
        end
        local tool=toolRecipe(id)
        if tool~=id then plan.tool=true; id=tool end
    end
    plan.recipeId,plan.recipe=id,guide.recipes[id]
    plan.knowledge=plan.knownRecipes[id]
    plan.batch=plan.tool and 1 or math.min(state.batch or 5,plan.stop-plan.current)
    if plan.inventoryReady then
        local producers={}
        for item,maker in pairs(guide.producers) do if plan.knownRecipes[maker]==true and guide.recipes[maker].minimum<=plan.current then producers[item]=maker end end
        local materials,problem=F.modules.MaterialCalculator:Calculate({[id]=plan.batch},guide.recipes,snapshot.inventory,producers)
        if not materials then return nil,problem end
        plan.materials=materials
        plan.distribution=F.modules.ProfessionPlanner:Distribute(materials,state,nil,state.prices)
    end
    return plan
end
function G:Text(controller)
    local guide,state,plan=controller.catalog,controller.state,controller.plan
    local lines={}
    if not plan then
        if V.Integer(state.lastSkill) then lines[#lines+1]="Last observed skill: "..state.lastSkill.." · waiting for live data" end
        lines[#lines+1]=controller.error or "Waiting for live profession data."
        return table.concat(lines,"\n\n")
    end
    if controller.stale then lines[#lines+1]="Previous observation · live tracking unavailable" end
    if plan.status=="not-found" then return "Profession not found in readable skill lines.\n\nLearn "..guide.name.." or expand professions in your Skills window.\nYour saved target and preferences remain available." end
    lines[#lines+1]="Skill "..plan.current.." / "..state.target..(plan.cap and (" · rank cap "..plan.cap) or "")..(guide.kind=="craft" and (" · "..state.mode) or "")
    if plan.status=="target-reached" then lines[#lines+1]="Target skill reached."; return table.concat(lines,"\n\n") end
    if plan.status=="train-rank" then lines[#lines+1]="Train the next profession rank before gaining more skill." end
    lines[#lines+1]=plan.stage.from.."–"..plan.stop.." · "..plan.stage.text
    if guide.kind=="gather" then
        for i=1,math.min(3,#plan.stage.resources) do
            local id=plan.stage.resources[i]
            lines[#lines+1]=self:Name(guide,id)..": carried "..(plan.inventory and tostring(plan.inventory[id]) or "unknown")
        end
        lines[#lines+1]="Progress follows observed skill, not items collected or attempts."
    else
        local action=plan.knowledge==true and (plan.tool and "Craft tool first: " or "Craft: ") or (plan.knowledge==false and "Learn recipe: " or "Check recipe knowledge: ")
        lines[#lines+1]=action..plan.recipe.name
        if plan.knowledge~=true then lines[#lines+1]="Recipe source: "..plan.recipe.acquisition end
        if plan.knowledge~=true then local seller=self:Seller(plan.recipe); if seller then lines[#lines+1]=seller end end
        lines[#lines+1]="Next batch: "..plan.batch.." craft(s). Skill-ups vary; check recipe color."
        if plan.materials then
            local ids={}; for item in pairs(plan.materials.raw) do ids[#ids+1]=item end; table.sort(ids)
            for recipe,count in pairs(plan.materials.crafts) do
                if recipe~=plan.recipeId then lines[#lines+1]="Prepare first: "..guide.recipes[recipe].name.." × "..count; break end
            end
            for i=1,math.min(3,#ids) do
                local item=ids[i]
                lines[#lines+1]=self:Name(guide,item)..": need "..plan.materials.raw[item]..", missing "..(plan.materials.missing[item] or 0)
            end
            if #ids>3 then lines[#lines+1]="More reagents: /fxp materials" end
        else lines[#lines+1]="Inventory unreadable; carried and missing materials are unknown." end
        for _,item in ipairs(plan.recipe.tools) do
            if plan.inventoryReady and (controller.snapshot.inventory[item] or 0)==0 then lines[#lines+1]="Required tool: "..self:Name(guide,item); break end
        end
    end
    if plan.cap and state.target>plan.cap and guide.rankNotes[plan.cap] then lines[#lines+1]=guide.rankNotes[plan.cap] end
    return table.concat(lines,"\n")
end
function G:Cycle(controller)
    local plan=controller.plan
    if not plan or not plan.stage or controller.catalog.kind~="craft" then return nil,"No crafting stage is currently available." end
    local choices=plan.stage.choices
    local position=1
    for i,id in ipairs(choices) do if id==plan.recipeId then position=i % #choices+1 end end
    controller.state.preferredRecipes=controller.state.preferredRecipes or {}
    controller.state.preferredRecipes[plan.stage.id]=choices[position]
    controller:Refresh(); return true
end
function G:Materials(controller)
    local plan,guide=controller.plan,controller.catalog
    if not plan or not plan.recipe then return nil,"Select a crafting guide with a readable current skill first." end
    F:Print("Next batch: "..plan.batch.." × "..plan.recipe.name..(controller.stale and " · stale observation" or ""))
    local amounts=plan.materials and plan.materials.raw or {}
    if not plan.materials then for id,count in pairs(plan.recipe.inputs) do amounts[id]=count*plan.batch end end
    local ids={}; for id in pairs(amounts) do ids[#ids+1]=id end; table.sort(ids)
    for _,id in ipairs(ids) do
        local message=self:Name(guide,id)..": need "..amounts[id]
        message=message..(plan.materials and (", owned used "..(plan.materials.used[id] or 0)..", missing "..(plan.materials.missing[id] or 0)) or ", inventory unknown")
        F:Print(message)
    end
    if plan.materials then
        for recipe,count in pairs(plan.materials.crafts) do
            if recipe~=plan.recipeId then F:Print("Prepare "..guide.recipes[recipe].name.." × "..count.." craft(s) for this batch.") end
        end
    end
    return true
end
