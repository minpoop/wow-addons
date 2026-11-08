local F,test,eq=...
local R,G,C,A,U=F.modules.RecipeDatabase,F.modules.ProfessionGuides,F.modules.ProfessionController,F.modules.ProfessionAdapter,F.modules.MainWindow
local Compat=F.modules.Compatibility
local saved={character=F.character,compact=F.settings.compact,provider=Compat.providers.professionSnapshot,evidence=Compat.inspected.professionSnapshot,
    questProvider=Compat.providers.snapshot,questEvidence=Compat.inspected.snapshot,enabled=A.enabled,catalog=C.catalog,state=C.state,plan=C.plan,snapshot=C.snapshot}
local globals={}; local names={"GetBuildInfo","C_SkillInfo","GetNumSkillLines","GetSkillLineInfo","ExpandSkillHeader","C_SpellBook","IsPlayerSpell","C_Item","GetItemCount","C_Timer"}
for _,name in ipairs(names) do globals[name]=_G[name] end
local questAdapter=F.modules.ForeverAdapter
local oldEnabled,oldLoading,oldPending=questAdapter.enabled,questAdapter.loading,questAdapter.pending
local rows,stock,knowledge,cap,timers={},{},{},300,{}
GetBuildInfo=function() return "fixture","fixture","fixture",16001 end
C_SkillInfo={GetNumSkillLines=function() return #rows end,GetSkillLineInfo=function(i) return rows[i] end}
C_Item={GetItemCount=function(id) return stock[id] or 0 end}
C_SpellBook={IsSpellKnown=function(id)
    for _,guide in pairs(R.catalogs) do
        if guide.guide then for i,rank in ipairs(guide.rankSpells) do if rank==id then return ({75,150,225,300})[i]<=cap end end end
    end
    if knowledge[id]~=nil then return knowledge[id] end
    return true
end}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
questAdapter.enabled,questAdapter.loading,questAdapter.pending=true,false,false
A.enabled=nil; assert(A:Start())
Compat:RegisterInspectedProvider("snapshot",function() return nil end,"Profession test isolation")
local function observe(slug,skill,inventory,rank,known)
    rows={}; if skill~=nil then rows={{name=R.catalogs[slug].name,skillID=R.catalogs[slug].skillId,isHeader=false,rank=skill}} end
    stock,cap,knowledge=inventory or {},rank or 300,known or {}
end
local function begin(slug,skill,inventory,rank,known)
    F.character={guides={},professions={},windows={}}
    observe(slug,skill,inventory,rank,known)
    assert(C:Select(slug)); return C.plan
end
test("all twelve reference profession guides load with 132 recipes and 146 stages",function()
    local count,recipes,stages=0,0,0
    for _,guide in pairs(R.catalogs) do
        if guide.guide then
            count=count+1; stages=stages+#guide.stages
            for _ in pairs(guide.recipes) do recipes=recipes+1 end
            eq(G:Validate(guide),true); eq(guide.minSkill,1); eq(guide.maxSkill,300)
        end
    end
    eq(count,12); eq(recipes,132); eq(stages,146); eq(Compat.profile.verified,false)
end)
test("each profession has a valid skill-driven stage for every skill from 1 to 299",function()
    for _,guide in pairs(R.catalogs) do
        if guide.guide then
            for skill=1,299 do
                local stage=G:Stage(guide,skill); assert(stage,guide.id.." gap at "..skill)
                assert(stage.from<=skill and stage.to>skill)
            end
        end
    end
end)
test("profession adapter uses skill IDs for localized names and reads only referenced inventory",function()
    begin("alchemy",123,{[2447]=7},150)
    rows[1].name="Localized profession name"
    local snapshot=A:Read("alchemy")
    eq(snapshot.skill,123); eq(snapshot.cap,150); eq(snapshot.inventory[2447],7)
    eq(snapshot.inventory[999999],nil); eq(snapshot.knownRecipes[2330],true)
end)
test("legacy skill APIs provide a safe English-name fallback",function()
    begin("alchemy",85)
    local modern=C_SkillInfo
    C_SkillInfo=nil
    GetNumSkillLines=function() return 1 end
    GetSkillLineInfo=function() return "Alchemy",false,true,85 end
    local snapshot=A:Read("alchemy"); C_SkillInfo=modern
    eq(snapshot.skill,85)
end)
test("collapsed skill headers expand once before reading without marking absent skills complete",function()
    begin("alchemy",50)
    local skill=rows[1]; rows={{name="Professions",isHeader=true,isCollapsed=true}}
    local expanded=0
    C_SkillInfo.ExpandSkillHeader=function() expanded=expanded+1; rows[1].isCollapsed=false; rows[2]=skill end
    eq(A:Read("alchemy").skill,50); eq(A:Read("alchemy").skill,50); eq(expanded,1)
    C_SkillInfo.ExpandSkillHeader=nil
end)
test("item changes and crafting attempts do not invent profession skill gains",function()
    local plan=begin("alchemy",1,{[2447]=2,[765]=1,[3371]=5},75)
    eq(plan.current,1); eq(plan.materials.missing[2447],3); eq(plan.materials.missing[765],4)
    local stage=plan.stage.id
    stock[2447]=50; C:Refresh()
    eq(C.plan.current,1); eq(C.plan.stage.id,stage); eq(C.state.lastSkill,1)
    eq(C.plan.materials.missing[2447],nil)
end)
test("live skill jumps catch up automatically and target completion requires observed rank",function()
    begin("alchemy",47,{},300)
    rows[1].rank=160; C:Refresh()
    eq(C.plan.stage.from,155); eq(C.plan.current,160); eq(C.state.lastSkill,160)
    rows[1].rank=299; C:Refresh(); eq(C.plan.status,"active")
    rows[1].rank=300; C:Refresh(); eq(C.plan.status,"target-reached")
end)
test("recipe knowledge is observed independently of reference skill eligibility",function()
    begin("alchemy",1,{},75,{[2330]=false})
    eq(C.plan.knowledge,false); assert(G:Text(C):find("Learn recipe",1,true))
    local known=C_SpellBook; C_SpellBook=nil; IsPlayerSpell=nil; C:Refresh()
    eq(C.plan.knowledge,nil); assert(G:Text(C):find("Check recipe knowledge",1,true))
    C_SpellBook=known
end)
test("missing runed tools are prepared without falsely advancing enchanting skill",function()
    begin("enchanting",1,{},75)
    eq(C.plan.recipeId,7421); eq(C.plan.tool,true); eq(C.plan.batch,1)
    stock[6218]=1; C:Refresh()
    eq(C.plan.recipeId,7418); eq(C.plan.current,1); eq(C.state.lastSkill,1)
end)
test("known processing recipes expand a batch with shared intermediate stock exactly once",function()
    begin("tailoring",45,{[2996]=5,[2589]=100,[2320]=99})
    eq(C.plan.recipeId,3755); eq(C.plan.batch,5)
    eq(C.plan.materials.crafts[2963],10)
    eq(C.plan.materials.raw[2589],20); eq(C.plan.materials.used[2996],5)
    knowledge[2963]=false; C:Refresh()
    eq(C.plan.materials.crafts[2963],nil); eq(C.plan.materials.missing[2996],10)
end)
test("gathering tracks skill and carried resources without treating purchases as progress",function()
    for _,slug in ipairs({"herbalism","mining","skinning","fishing"}) do
        begin(slug,50)
        local stage=C.plan.stage.id; local item=C.plan.stage.resources[1]
        stock[item]=999; C:Refresh()
        eq(C.plan.current,50); eq(C.plan.stage.id,stage); eq(C.plan.inventory[item],999)
        eq(C:Change("mode","Buy"),nil)
        rows[1].rank=175; C:Refresh(); eq(C.plan.current,175); assert(C.plan.stage.id~=stage)
    end
end)
test("observed rank caps show training gates and unlock without resetting progress",function()
    begin("first-aid",150,{},150)
    eq(C.plan.status,"train-rank"); assert(G:Text(C):find("Expert First Aid",1,true))
    cap=225; C:Refresh(); eq(C.plan.status,"active"); eq(C.plan.current,150)
    rows[1].rank=225; C:Refresh(); eq(C.plan.status,"train-rank")
    assert(G:Text(C):find("Triage",1,true))
end)
test("unlearned or unavailable skill lines retain saved targets and the last positive observation",function()
    begin("alchemy",87); assert(C:Change("target",275))
    rows={}; C:Refresh(); eq(C.plan.status,"not-found"); eq(C.plan.current,nil)
    eq(C.state.lastSkill,87); eq(C.state.target,275)
end)
test("temporary skill and inventory errors stay distinct and preserve observed progress",function()
    begin("alchemy",87)
    local previous=C.plan; local getter=C_SkillInfo.GetNumSkillLines
    C_SkillInfo.GetNumSkillLines=function() error("not ready") end
    C:Refresh(); eq(C.plan,previous); eq(C.stale,true)
    C_SkillInfo.GetNumSkillLines=getter
    local item=C_Item.GetItemCount; C_Item.GetItemCount=function() error("not ready") end
    C:Refresh(); eq(C.plan.current,87); eq(C.plan.materials,nil); eq(C.stale,false)
    assert(G:Text(C):find("Inventory unreadable",1,true)); C_Item.GetItemCount=item
end)
test("profession preferences survive relog and remain separate by character and profession",function()
    begin("alchemy",87); C:Change("target",275); C:Change("batch",7)
    local first=F.modules.SavedVariables.Copy(F.character)
    F.character=first; assert(C:Select("alchemy")); eq(C.state.target,275); eq(C.state.batch,7)
    assert(C:Select("tailoring")); eq(C.state.target,300)
    F.character={guides={},professions={},windows={}}; assert(C:Select("alchemy")); eq(C.state.target,300)
    eq(first.professions.alchemy.target,275)
end)
test("corrupt and unknown future guide state is rejected without overwriting the save",function()
    begin("alchemy",87); C.state.guideVersion=99
    local state=C.state; eq(C:Select("alchemy"),nil); eq(state.guideVersion,99)
    state.guideVersion=1; state.batch=100
    eq(C:Select("alchemy"),nil); eq(state.batch,100)
end)
test("reference profession schema rejects stage gaps, unavailable recipes and preparation cycles",function()
    local copy=F.modules.SavedVariables.Copy
    local bad=copy(R.catalogs.alchemy); bad.stages[2].from=999; eq(G:Validate(bad),nil)
    bad=copy(R.catalogs.alchemy); bad.recipes[2330].minimum=5; eq(G:Validate(bad),nil)
    bad=copy(R.catalogs.alchemy); bad.recipes[2330].inputs={[118]=1}; eq(G:Validate(bad),nil)
    bad=copy(R.catalogs.alchemy); bad.rankSpells={[2]=1}; eq(G:Validate(bad),nil)
end)
test("public profession controls select aliases, change batches and preserve guide progress",function()
    begin("first-aid",42); F.settings.compact=false
    F:Command("profession FirstAid"); eq(C.catalog.id,"first-aid")
    U:Show("professions"); assert(U.body.text:find("Skill 42 / 300",1,true))
    eq(U.recipeControls,nil)
    local menu=F.modules.ContextMenu; menu:Open("batch"); assert(menu:Invoke("batch-10")); eq(C.state.batch,10)
    F:Command("batch 3"); eq(C.state.batch,3)
    F:Command("target 100"); eq(C.state.target,100)
    assert(math.abs(U.progressFill.SetWidthArgs[1]-U.contentWidth*41/99)<0.001)
    F:Command("materials"); F:Command("recipes")
    F:Command("compact"); eq(U.recipeControls,nil)
    F:Command("compact")
    observe("mining",65); assert(C:Select("mining")); U:Render()
    eq(U.recipeControls,nil)
    for _,item in ipairs(menu:Items("profession-actions")) do assert(item.id~="batch" and item.id~="modes") end
end)
test("skill and recipe event bursts use the existing coalesced refresh queue",function()
    begin("alchemy",100); timers={}; questAdapter.pending=false
    local secret=setmetatable({},{__tostring=function() error("chat arguments must not be inspected") end})
    rows[1].rank=110
    F.modules.Events:Emit("CHAT_MSG_SKILL",secret)
    F.modules.Events:Emit("SKILL_LINES_CHANGED")
    F.modules.Events:Emit("NEW_RECIPE_LEARNED",secret)
    eq(#timers,1); eq(C.plan.current,100)
    timers[1](); eq(C.plan.current,110); eq(questAdapter.pending,false)
end)
test("unsupported interfaces cannot enable profession tracking or replace current observations",function()
    begin("alchemy",87)
    local build=GetBuildInfo; GetBuildInfo=function() return "other","other","other",999999 end
    local previous=C.plan; C:Refresh(); eq(C.plan,previous); eq(C.stale,true)
    eq(A:Read("alchemy"),nil); GetBuildInfo=build
    C:Refresh(); eq(C.stale,false); eq(C.plan.current,87)
end)
for _,name in ipairs(names) do _G[name]=globals[name] end
F.character,F.settings.compact=saved.character,saved.compact
Compat.providers.professionSnapshot,Compat.inspected.professionSnapshot=saved.provider,saved.evidence
Compat.providers.snapshot,Compat.inspected.snapshot=saved.questProvider,saved.questEvidence
A.enabled=saved.enabled
questAdapter.enabled,questAdapter.loading,questAdapter.pending=oldEnabled,oldLoading,oldPending
C.catalog,C.state,C.plan,C.snapshot=saved.catalog,saved.state,saved.plan,saved.snapshot
U:Show("guide")
