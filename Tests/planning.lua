local F, test, eq = ...
local R, P, C = F.modules.RecipeDatabase, F.modules.ProfessionPlanner, F.modules.Compatibility
local function catalog()
    return {id="fixture-profession",profession="fixture-profession",title="Synthetic profession",minSkill=0,maxSkill=10,
        recipes={process={output="bar",outputCount=2,inputs={ore=3}},
            a={output="a",outputCount=1,inputs={bar=1,flux=1}},
            b={output="b",outputCount=1,inputs={bar=2}},alt={output="alt",outputCount=1,inputs={ore=1}}},
        producers={bar="process"},segments={
            {id="low",from=0,to=5,choices={{recipe="a",chance=1,gain=1},{recipe="alt",chance=1,gain=1}},trainer="Fixture trainer reminder"},
            {id="high",from=5,to=10,choices={{recipe="b",chance=0.5,gain=1}}}}}
end
local function observed()
    return {skill=3,inventory={bar=1,ore=2,flux=1},knownRecipes={process=true,a=true,b=true,alt=true}}
end
test("catalog validates dense skill coverage, alternatives, metadata and cycles",function()
    local c=catalog(); eq(R:Validate(c,false),true); eq(R:RegisterCatalog(c),nil)
    c.segments[2].from=6; eq(R:Validate(c,false),nil)
    c=catalog(); c.segments[2].to=9; eq(R:Validate(c,false),nil)
    c=catalog(); c.segments[1].choices[1].chance=0/0; eq(R:Validate(c,false),nil)
    c=catalog(); c.recipes.process.inputs={bar=1}; eq(R:Validate(c,false),nil)
end)
test("target planner handles partial bands, probabilities and consolidated inventory",function()
    local s=observed()
    local plan=assert(P:Plan(catalog(),{mode="Buy",target=7,safety=0.25},s.skill,s.inventory,s.knownRecipes))
    eq(#plan.rows,2); eq(plan.rows[1].from,3); eq(plan.rows[2].to,7)
    eq(plan.expected.crafts.process,5); eq(plan.conservative.crafts.process,6)
    eq(plan.expected.missing.ore,13); eq(plan.expected.missing.flux,1)
    eq(plan.guaranteed,nil); eq(plan.allGuaranteed,false)
    eq(plan.distribution.buy.ore,16); eq(plan.trainers[1],"Fixture trainer reminder")
    eq(s.inventory.ore,2)
end)
test("guaranteed mode refuses chance-based requirements and allows deterministic bands",function()
    local s=observed()
    eq(P:Plan(catalog(),{mode="Farm",target=7,estimate="guaranteed"},3,s.inventory,s.knownRecipes),nil)
    local plan=assert(P:Plan(catalog(),{mode="Farm",target=5,estimate="guaranteed"},3,s.inventory,s.knownRecipes))
    eq(plan.guaranteed.missing.ore,1); eq(plan.allGuaranteed,true)
    local done=assert(P:Plan(catalog(),{mode="Farm",target=3},3,s.inventory,s.knownRecipes))
    eq(#done.rows,0); eq(next(done.materials.missing),nil)
    eq(P:Estimate(2,0/0,0),nil); eq(P:Estimate(2,0.5,0/0),nil)
end)
test("recipe selection respects knowledge and manual overrides",function()
    local s=observed(); s.knownRecipes.a=false
    local plan=assert(P:Plan(catalog(),{mode="Buy",target=5},3,s.inventory,s.knownRecipes))
    eq(plan.rows[1].recipe,"alt")
    eq(P:Plan(catalog(),{mode="Buy",target=5,selectedRecipes={low="a"}},3,s.inventory,s.knownRecipes),nil)
    s.knownRecipes.a=true; s.knownRecipes.process=false
    eq(P:Plan(catalog(),{mode="Buy",target=5},3,s.inventory,s.knownRecipes),nil)
    s.inventory.bar=99
    assert(P:Plan(catalog(),{mode="Buy",target=5},3,s.inventory,s.knownRecipes))
end)
local snapshot=observed()
test("controller integrates providers, commands, UI and transient outages without progress loss",function()
    local c=catalog(); c.verification="live-verified"; c.source="Synthetic test assertion only"
    assert(R:RegisterCatalog(c))
    C.profile.verified=true -- Mock fixture only; no client compatibility assertion.
    C:RegisterProvider("professionSnapshot",function() return snapshot end)
    F:Command("profession fixture-profession"); F:Command("target 7")
    local controller=F.modules.ProfessionController
    assert(controller.plan); eq(controller.stale,false)
    F:Command("mode Buy"); eq(controller.state.mode,"Buy"); eq(controller.state.target,7)
    F:Command("price ore 2"); F:Command("price flux 1"); eq(controller.plan.distribution.costComplete,true)
    F.modules.MainWindow:Render(); assert(F.modules.MainWindow.body.text:find("Skill 3"))
    local old=controller.plan; snapshot=nil
    F.modules.Events:Emit("FXP_STATE_CHANGED")
    eq(controller.plan,old); eq(controller.stale,true); eq(controller.state.target,7)
    assert(F.modules.MainWindow.body.text:find("stale plan"))
    snapshot=observed(); snapshot.skill=4
    F.modules.Events:Emit("FXP_STATE_CHANGED"); eq(controller.plan.current,4); eq(controller.stale,false)
    eq(controller:Change("target",999),nil); eq(controller.state.target,7)
    C.profile.verified=false
end)
local function route()
    return {id="fixture-route",title="Synthetic route",zone="fixture-zone",resource="ore",minSkill=0,maxSkill=10,
        description="Synthetic observations only",difficulty="fixture",
        points={{zone="fixture-zone",x=0.1,y=0.2},{zone="fixture-zone",x=0.3,y=0.4}}}
end
test("route imports remain unverified and malformed coordinates cannot be registered",function()
    local routes=F.modules.GatheringRoutes
    local r=route(); eq(routes:Validate(r,false),true); eq(routes:RegisterRoute(r),nil)
    local character={}; assert(routes:ImportDraft(character,r))
    eq(character.recordedRoutes[r.id].verification,"unverified-observation")
    eq(routes:ImportDraft(character,r),nil)
    r.points[2].zone="wrong-zone"; eq(routes:Validate(r,false),nil)
    r=route(); r.points[3]={zone="fixture-zone",x=0/0,y=0}; eq(routes:Validate(r,false),nil)
end)
test("recording requires verified position capability, matching zone and unique observation",function()
    local routes=F.modules.GatheringRoutes; local character={}
    assert(routes:ImportDraft(character,route()))
    eq(routes:Record(character,"fixture-route"),nil)
    local position={zone="fixture-zone",x=0.5,y=0.6}
    C.profile.verified=true; C:RegisterProvider("position",function() return position end)
    assert(routes:Record(character,"fixture-route")); eq(#character.recordedRoutes["fixture-route"].points,3)
    eq(routes:Record(character,"fixture-route"),nil)
    position.zone="wrong-zone"; eq(routes:Record(character,"fixture-route"),nil)
    C.profile.verified=false
end)
test("detours require consent, retain main guide state, and restore the current objective",function()
    local routes,detours,engine=F.modules.GatheringRoutes,F.modules.Detours,F.modules.GuideEngine
    local r=route(); r.verification="live-verified"; r.source="Synthetic test assertion only"; assert(routes:RegisterRoute(r))
    local guide={id="detour-guide",title="Synthetic guide",verification="live-verified",source="Synthetic test only",steps={
        {id="one",type="MANUAL_INSTRUCTION",text="Fixture one",waypoint={zone="fixture-zone",x=0.8,y=0.9}},
        {id="two",type="MANUAL_INSTRUCTION",text="Fixture two",waypoint={zone="fixture-zone",x=0.7,y=0.6}}}}
    assert(engine:RegisterGuide(guide)); assert(engine:Select(guide.id,F.character))
    eq(#detours:Suggest("ore","fixture-zone",1),0)
    eq(detours:Start(r.id,true),nil)
    F:Command("integration balanced"); eq(#detours:Suggest("ore","fixture-zone",1),1)
    eq(#detours:Suggest("ore","other-zone",1),0)
    eq(detours:Start(r.id,false),nil); assert(detours:Start(r.id,true))
    eq(F.modules.Waypoints.current.x,0.1)
    engine:Update({observed={one=true}}); eq(engine:Current().id,"one")
    assert(detours:Next()); eq(F.modules.Waypoints.current.x,0.3)
    assert(detours:Next()); eq(detours.active,nil); eq(engine:Current().id,"one"); eq(F.modules.Waypoints.current.x,0.8)
    assert(detours:Start(r.id,true)); engine:Advance(true)
    eq(detours.active,nil); eq(F.modules.Waypoints.current.x,0.7)
    assert(detours:Start(r.id,true)); F:Command("integration disabled")
    eq(detours.active,nil); eq(engine:Current().id,"two")
end)
test("guide metadata rejects sparse prerequisites and wrong field types",function()
    local v=F.modules.StepValidator
    local g={id="schema",title="Fixture",steps={{id="one",type="MANUAL_INSTRUCTION",text="Fixture"}}}
    g.steps[1].prerequisites={[2]="one"}; eq(v:Guide(g,false),false)
    g.steps[1].prerequisites={}; g.minLevel="1"; eq(v:Guide(g,false),false)
    g.minLevel=nil; g.steps[1].optional="yes"; eq(v:Guide(g,false),false)
    local valid,missing=v:KnownQuests({steps={{questId=990001},{questId=990002}}},{[990001]=true})
    eq(valid,false); eq(missing[990002],true)
end)
test("fog journal includes James, readable theme switching and original companion notes",function()
    local ui,themes=F.modules.MainWindow,F.modules.Themes
    ui:Show("guide"); assert(ui.companion.text:find("James Sunderland",1,true))
    eq(F.settings.theme,"fog"); local fog=ui.background.SetColorTextureArgs[1]
    F:Command("theme contrast"); eq(F.settings.theme,"contrast")
    eq(F.db.settings.theme,"contrast"); assert(ui.background.SetColorTextureArgs[1] ~= fog)
    ui:Show("professions"); assert(ui.companion.text:find("Count your supplies",1,true))
    ui:Show("settings"); assert(ui.companion.text:find("important things",1,true))
    local menu=F.modules.ContextMenu; menu:Open("themes")
    local selected=menu.rows[2]
    selected.scripts.OnEnter(); eq(selected.background.SetColorTextureArgs[1],themes:Get().hover[1])
    selected.scripts.OnLeave(); menu:Close()
    F:Command("theme missing"); eq(F.settings.theme,"contrast")
    local fallback={SetTexture=function(self,...) self.color={...} end}
    themes:Texture(fallback,themes:Get().panel); eq(fallback.color[4],1)
    F:Command("theme fog"); ui:Show("guide")
end)
test("invalid external snapshots and materials fail without mutating progress",function()
    eq(F.modules.MaterialCalculator:Calculate(nil,{}),nil)
    eq(P:Distribute({missing={ore=1}},{mode="Hybrid"},true),nil)
    eq(P:Distribute({missing={ore=1}},{mode="Hybrid"},{ore=true}),nil)
    eq(F.modules.GuideEngine:Complete({type="REACH_LEVEL",level=3},{level=math.huge}),nil)
    local character={guides={bad={current="one",completed={one="yes"},overrides={}}}}
    F.modules.GuideEngine.guides.bad={steps={{id="one"}}}
    eq(F.modules.GuideEngine:Select("bad",character),nil)
    eq(character.guides.bad.completed.one,"yes")
    F.modules.GuideEngine.guides.bad=nil
end)
test("portrait-free layout uses the full guide width in every tab and compact mode",function()
    local ui=F.modules.MainWindow
    for _,tab in ipairs({"guide","professions","settings"}) do
        ui:Show(tab)
        eq(ui.frame.SetWidthArgs[1],ui.width)
        eq(ui.portrait,nil); eq(ui.portraitName,nil)
        eq(ui.body.SetWidthArgs[1],ui.contentWidth)
        eq(ui.scroll.SetPointArgs[4],18)
    end
    F:Command("compact"); eq(ui.frame.SetHeightArgs[1],ui.height)
    eq(ui.body.SetWidthArgs[1],ui.contentWidth)
    F:Command("compact"); ui:Show("guide")
end)
