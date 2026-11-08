local F,test,eq=...
local G,C,P,Compat=F.modules.GuideEngine,F.modules.LevelingCampaign,F.modules.RoutePlanner,F.modules.Compatibility
local old={character=F.character,snapshot=F.snapshot,guide=G.guide,state=G.state,index=G.index,choice=F.settings.routePlan,
    provider=Compat.providers.snapshot,evidence=Compat.inspected.snapshot,auto=F.settings.autoAdvance}
local current
Compat:RegisterInspectedProvider("snapshot",function() return current end,"Synthetic route tests")
F.settings.autoAdvance=true
local ids={990801,990802,990803}
local guide={id="route-safety-fixture",title="Synthetic phase route",faction="Alliance",verification="reference-reviewed",source="Synthetic fixture",
    campaign={targetLevel=20,maxQuestLag=3,maxQuestLead=2},steps={}}
for n,id in ipairs(ids) do
    for _,phase in ipairs({"accept","work","turn-in"}) do
        guide.steps[#guide.steps+1]={id=id.."-"..phase,type=({accept="ACCEPT_QUEST",work="COMPLETE_QUEST",["turn-in"]="TURN_IN_QUEST"})[phase],
            questId=id,questTitle="Synthetic "..n,questLevel=n==3 and 12 or 8,minLevel=n==3 and 7 or 1,text="Synthetic instruction",zone="Synthetic fields"}
    end
end
guide.steps[#guide.steps+1]={id="goal",type="REACH_LEVEL",level=20,text="Synthetic goal"}
assert(G:RegisterReferenceGuide(guide))
local plan={id="route-safety-fixture",title="Synthetic batches",source="Synthetic fixture",verification="reference-planned",faction="Alliance",
    minLevel=1,maxLevel=19,pickupLead=5,reservedSlots=3,guides={guide.id},zones={"Synthetic fields"},stages={
        {id="a",title="Collect nearby quests",phase="accept",quests=ids,maxLevel=19,pickupAhead=true},
        {id="w",title="Complete the outing",phase="work",quests=ids,maxLevel=19},
        {id="t",title="Return together",phase="turn-in",quests=ids,maxLevel=19}}}
assert(P:Register(plan))
local function begin(level,quests,capacity)
    F.character={guides={},professions={},windows={}};F.settings.routePlan="auto"
    current={level=level or 7,quests=quests or {},active={},questLogCapacity=capacity,character={faction="Alliance",race="Human",zone="Synthetic fields"}}
    for id,q in pairs(current.quests) do if q.accepted then current.active[#current.active+1]=id end end
    assert(G:Select(guide.id,F.character));G:Update(current)
    return C.runtime[guide.id]
end
test("authored 1–20 itinerary has 53 complete non-optional quest triplets",function()
    local authored=assert(P.plans["elwynn-westfall-1-20"])
    local actions,count={},0
    for _,stage in ipairs(authored.stages) do for _,id in ipairs(stage.quests) do actions[id]=(actions[id] or 0)+1 end end
    for id,n in pairs(actions) do count=count+1;eq(n,3);eq(C:Index(G.guides[C.id]).quests[id].optional,false) end
    eq(count,53);eq(#authored.stages,98)
end)
test("route validation rejects incomplete phases duplicate actions and unsafe optional encounters",function()
    local bad=F.modules.SavedVariables.Copy(plan);bad.id="bad-route";table.remove(bad.stages,3)
    eq(P:Register(bad),nil)
    bad=F.modules.SavedVariables.Copy(plan);bad.id="bad-route";bad.stages[1].quests={ids[1],ids[1]};eq(P:Register(bad),nil)
    bad=F.modules.SavedVariables.Copy(plan);bad.id="bad-route";bad.stages[1].pickupAhead=function() end;eq(P:Register(bad),nil)
    eq(P.plans["bad-route"],nil)
end)
test("pickup batching gathers eligible quests before beginning field work",function()
    begin();eq(G:Current().questId,ids[1]);eq(G:Current().type,"ACCEPT_QUEST")
    current.quests[ids[1]]={accepted=true};current.trackedQuestId=ids[1];G:Update(current)
    eq(G:Current().questId,ids[2]);eq(G:Current().type,"ACCEPT_QUEST")
    current.quests[ids[2]]={accepted=true};G:Update(current);eq(G:Current().type,"COMPLETE_QUEST")
    eq(G.state.completed[ids[1].."-turn-in"],nil)
end)
test("field batches wait for their remaining objectives before the combined return",function()
    begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}})
    current.quests[ids[1]].complete=true;G:Update(current)
    eq(G:Current().questId,ids[2]);eq(G:Current().type,"COMPLETE_QUEST")
    current.quests[ids[2]].complete=true;G:Update(current);eq(G:Current().type,"TURN_IN_QUEST")
    current.quests[G:Current().questId]={turnedIn=true};G:Update(current);eq(G:Current().type,"TURN_IN_QUEST")
end)
test("native activity chooses work within an outing without cancelling pickup batching",function()
    begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}})
    current.signalQuestId=ids[2];G:Update(current);eq(G:Current().questId,ids[2])
    current.quests[ids[2]]=nil;G:Update(current);eq(G:Current().type,"ACCEPT_QUEST")
end)
test("early pickups require actual spare slots and never lift the combat level limit",function()
    begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}},20)
    eq(G:Current().questId,ids[3]);eq(G:Current().type,"ACCEPT_QUEST")
    eq(C.runtime[guide.id].selected.pickupAhead,true)
    current.quests[ids[3]]={accepted=true};current.active[#current.active+1]=ids[3];current.trackedQuestId=ids[3];G:Update(current)
    assert(G:Current().questId~=ids[3]);eq(G:Current().type,"COMPLETE_QUEST")
    current.level=10;G:Update(current)
    assert(C.runtime[guide.id].selected.goal.level<=current.level+2)
end)
test("unknown or reserved log capacity disables early pickup and full logs prefer existing work",function()
    for _,capacity in ipairs({4,2}) do
        begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}},capacity)
        eq(G:Current().type,"COMPLETE_QUEST");assert(G:Current().questId~=ids[3])
    end
    begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}});eq(G:Current().type,"COMPLETE_QUEST")
    begin(7,{[ids[1]]={accepted=true}},1);eq(G:Current().questId,ids[1]);eq(G:Current().type,"COMPLETE_QUEST")
end)
test("early pickups preserve minimum levels prerequisites race restrictions and deferrals",function()
    begin(6,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}},20);assert(G:Current().questId~=ids[3])
    begin(7,{[ids[1]]={accepted=true},[ids[2]]={accepted=true}},20)
    local record=C:Index(G.guide).quests[ids[3]]
    record.requires={990899};G:Update(current);assert(G:Current().questId~=ids[3])
    current.quests[990899]={turnedIn=true};G:Update(current);eq(G:Current().questId,ids[3])
    record.allowedRaces={"Orc"};G:Update(current);assert(G:Current().questId~=ids[3])
    record.allowedRaces=nil;record.requires={}
    G:Update(current);eq(G:Current().questId,ids[3])
    assert(C:Defer(G));assert(G:Current().questId~=ids[3])
end)
test("manual keep pauses batches and plan off retains the previous quest-pool behavior",function()
    begin(7,{[ids[1]]={accepted=true}})
    assert(C:Keep(G,ids[1]));eq(G:Current().questId,ids[1]);eq(C.runtime[guide.id].route,nil)
    F.settings.routePlan="off";assert(C:Auto(G));eq(G:Current().questId,ids[1]);eq(G:Current().type,"COMPLETE_QUEST")
end)
test("Goldshire batches combine mine candles and gold dust without completing unknown earlier quests",function()
    F.character={guides={},professions={},windows={}};F.settings.routePlan="auto"
    current={level=5,quests={[54]={turnedIn=true}},character={zone="Elwynn Forest",faction="Alliance"}}
    assert(G:Select(C.id,F.character));G:Update(current);eq(G:Current().questId,62)
    current.quests[62]={accepted=true};G:Update(current);eq(G:Current().questId,60);eq(G:Current().type,"ACCEPT_QUEST")
    current.quests[60]={accepted=true};G:Update(current);eq(G:Current().questId,47)
    eq(G.state.completed["quest-783-turn-in"],nil)
    assert(C.runtime[C.id].route.stage.title:find("Goldshire",1,true))
end)
test("mid-route active quests bypass unknown introductions while observed native levels remain authoritative",function()
    F.character={guides={},professions={},windows={}};F.settings.routePlan="auto"
    current={level=9,quests={[83]={accepted=true}},character={zone="Elwynn Forest",faction="Alliance"}}
    assert(G:Select(C.id,F.character));G:Update(current)
    assert(G:Current().questId==83 or G:Current().questId==52 or G:Current().questId==46)
    eq(G.state.completed["quest-783-turn-in"],nil)
    current={level=14,quests={[7]={accepted=true,level=14}},character={zone="Elwynn Forest",faction="Alliance"}}
    G:Update(current);eq(G:Current().questId,7)
end)
test("focused route waits instead of inventing XP completion or choosing a distant region",function()
    begin();local index=C:Index(G.guide)
    for _,record in ipairs(index.order) do current.quests[record.id]={turnedIn=true} end
    G:Update(current);eq(G.state.campaign.status,"waiting");eq(G.state.finished,false)
    eq(C.runtime[guide.id].route.status,"waiting");eq(G.state.completed.goal,nil)
    current.level=20;G:Update(current);eq(G.state.finished,true)
end)
test("automatic profiles stay regional and hand back to the level-aware pool after 19",function()
    begin();current.character.zone="Elsewhere";G:Update(current);eq(C.runtime[guide.id].route,nil)
    current.character.zone="Synthetic fields";current.level=20
    eq(P:Active(G,current),nil)
    current.level=7;current.character.faction="Horde";eq(P:Active(G,current),nil)
    F.character={guides={},professions={},windows={}};F.settings.routePlan="auto"
    current={level=14,quests={},character={zone="Elwynn Forest",faction="Alliance"}}
    assert(G:Select(C.id,F.character));G:Update(current)
    for _=1,3 do
        local run=C.runtime[C.id]
        for _,candidate in ipairs(run.candidates) do
            assert(P:Local(P.plans["elwynn-westfall-1-20"],G,candidate.record,current))
        end
        assert(C:Cycle(G))
    end
end)
Compat.providers.snapshot,Compat.inspected.snapshot=old.provider,old.evidence
F.character,F.snapshot,F.settings.routePlan,F.settings.autoAdvance=old.character,old.snapshot,old.choice,old.auto
G.guide,G.state,G.index=old.guide,old.state,old.index
