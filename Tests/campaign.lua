local F,test,eq=...
local G,C,Compat=F.modules.GuideEngine,F.modules.LevelingCampaign,F.modules.Compatibility
local previousCharacter,previousAuto=F.character,F.settings.autoAdvance
local previousProvider,previousEvidence,previousSnapshot=Compat.providers.snapshot,Compat.inspected.snapshot,F.snapshot
local current
Compat:RegisterInspectedProvider("snapshot",function() return current end,"Synthetic campaign test fixture")
local function snapshot(level,quests,zone)
    return {level=level,quests=quests or {},active={},character={zone=zone or "Elwynn Forest"}}
end
local function begin(level,quests,zone)
    F.character={guides={},professions={},windows={}}
    F.settings.autoAdvance=true
    current=snapshot(level,quests,zone)
    assert(G:Select(C.testId,F.character)); G:Update(current)
    return C.runtime[C.testId]
end
test("campaign supplies a class-independent reference pool and valid level policy",function()
    local guide=G.guides[C.testId]
    eq(guide.verification,"reference-reviewed"); eq(guide.class,nil); eq(guide.campaign.targetLevel,20)
    eq(#C:Index(guide).order,97); eq(#guide.steps,293)
    eq(F.modules.StepValidator:Guide(guide,false),true); eq(F.modules.StepValidator:Guide(guide,true),false)
    local bad=F.modules.SavedVariables.Copy(guide); bad.campaign.maxQuestLag=-1
    eq(F.modules.StepValidator:Guide(bad,false),false)
end)
test("each level from 1 through 19 gets an eligible goal instead of an area-completion gate",function()
    for level=1,19 do
        local run=begin(level)
        assert(run.selected,"No candidate for level "..level)
        local goal=run.selected.goal
        assert(goal.level>=level-3 and goal.level<=level+2)
        assert(goal.minimum<=level)
        eq(G.state.campaign.lastLevel,level)
    end
end)
test("a tracked low-level quest is set aside at higher level without fake turn-in or abandonment",function()
    local run=begin(14,{[7]={accepted=true,level=2}})
    current.trackedQuestId=7; current.signalQuestId=7; G:Update(current)
    run=C.runtime[C.testId]
    assert(G:Current().questId~=7); assert(run.selected.goal.level>=11)
    eq(G.state.completed["quest-7-turn-in"],nil); eq(G.state.completed["quest-7-complete"],nil)
    eq(G.state.completed["quest-7-accept"],true); assert(run.deferred>0)
end)
test("an accelerated level jump changes recommendations while preserving unfinished work",function()
    begin(2,{[7]={accepted=true,level=2}}); current.trackedQuestId=7; G:Update(current)
    eq(G:Current().questId,7)
    current.level=13; G:Update(current)
    assert(G:Current().questId~=7)
    eq(G.state.completed["quest-7-turn-in"],nil); eq(current.quests[7].accepted,true)
end)
test("observed native quest level takes precedence over an outdated reference level",function()
    begin(14,{[7]={accepted=true,level=14}}); current.trackedQuestId=7; G:Update(current)
    eq(G:Current().questId,7)
    eq(C:QuestLevel(C:Index(G.guide).quests[7],current),14)
end)
test("positive history removes completed candidates and respects earlier saved quest state",function()
    begin(14,{[151]={turnedIn=true},[7]={turnedIn=true}})
    assert(G:Current().questId~=151)
    eq(G.state.completed["quest-151-turn-in"],true); eq(G.state.completed["quest-7-turn-in"],true)
end)
local function bridgeGuide()
    local guide={id="campaign-bridge-fixture",title="Fixture",faction="Alliance",verification="reference-reviewed",source="Synthetic fixture",campaign={targetLevel=20,maxQuestLag=3,maxQuestLead=2},steps={}}
    for _,q in ipairs({{id=990201,level=5,minimum=1},{id=990202,level=15,minimum=10,pre=990201}}) do
        for _,phase in ipairs({"accept","complete","turn-in"}) do
            local kind=({accept="ACCEPT_QUEST",complete="COMPLETE_QUEST",["turn-in"]="TURN_IN_QUEST"})[phase]
            local prerequisites={}
            if phase=="accept" and q.pre then prerequisites={"quest-"..q.pre.."-turn-in"}
            elseif phase~="accept" then prerequisites={"quest-"..q.id..(phase=="complete" and "-accept" or "-complete")} end
            guide.steps[#guide.steps+1]={id="quest-"..q.id.."-"..phase,type=kind,questId=q.id,questTitle="Synthetic "..q.id,questLevel=q.level,minLevel=q.minimum,text="Synthetic",prerequisites=prerequisites}
        end
    end
    guide.steps[#guide.steps+1]={id="goal",type="REACH_LEVEL",level=20,text="Synthetic target"}
    return guide
end
test("only necessary lower-level prerequisites are recommended as explicit chain bridges",function()
    assert(G:RegisterReferenceGuide(bridgeGuide()))
    F.character={guides={},professions={},windows={}}; assert(G:Select("campaign-bridge-fixture",F.character))
    current=snapshot(14); G:Update(current)
    local run=C.runtime[G.guide.id]
    eq(run.selected.record.id,990201); eq(run.selected.goal.id,990202); eq(run.selected.bridge,true)
    assert(C:Text(G):find("Prerequisite for",1,true))
    eq(G.state.completed["quest-990201-turn-in"],nil)
    current.quests[990201]={turnedIn=true}; G:Update(current); eq(G:Current().questId,990202)
end)
test("optional encounters are excluded from automatic recommendations",function()
    local run=begin(19,{},"Loch Modan")
    for _,candidate in ipairs(run.candidates) do eq(candidate.record.optional,false); eq(candidate.goal.optional,false) end
    assert(C:Keep(G,255)); eq(G:Current().questId,255); eq(G.state.campaign.pinnedQuest,255)
end)
test("deferring changes only planner preference; explicitly keeping restores the quest",function()
    begin(14)
    local id=G:Current().questId
    eq(G.state.completed["quest-"..id.."-turn-in"],nil)
    assert(C:Defer(G)); eq(G.state.campaign.deferredByUser[id],true)
    assert(G:Current().questId~=id); eq(G.state.completed["quest-"..id.."-turn-in"],nil)
    assert(C:Keep(G,id)); eq(G:Current().questId,id); eq(G.state.campaign.deferredByUser[id],nil)
end)
test("an older active quest can be kept until turn-in, then automatic planning resumes",function()
    begin(14,{[7]={accepted=true,level=2}})
    assert(C:Keep(G,7)); eq(G:Current().questId,7)
    current.quests[7].complete=true; G:Update(current); eq(G:Current().type,"TURN_IN_QUEST")
    current.quests[7]={turnedIn=true}; G:Update(current)
    eq(G.state.campaign.pinnedQuest,nil); assert(G:Current().questId~=7)
end)
test("missing level or quest data retains the cursor and progress",function()
    begin(14); local id=G:Current().id
    G:Update({quests={}}); eq(G:Current().id,id); eq(G.state.campaign.lastLevel,14)
    assert(C:Text(G):find("Waiting",1,true))
    G:Update({level=0,quests={}}); eq(G:Current().id,id)
    G:Update({level=0/0,quests={}}); eq(G:Current().id,id)
    G:Update({level=14}); eq(G:Current().id,id)
end)
test("exhausted eligible content waits instead of forcing old quests or claiming level 20",function()
    local s=begin(19)
    for _,record in ipairs(C:Index(G.guide).order) do current.quests[record.id]={turnedIn=true} end
    G:Update(current)
    eq(G.state.campaign.status,"waiting"); eq(G.state.finished,false)
    eq(G.state.completed["campaign-target-20"],nil)
    assert(C:Text(G):find("No suitable",1,true))
end)
test("level 20 completes the level goal without marking unfinished quests complete",function()
    begin(20,{[7]={accepted=true,level=2}})
    eq(G.state.campaign.status,"target-reached"); eq(G.state.finished,true); eq(G:Current(),nil)
    eq(G.state.completed["campaign-target-20"],true); eq(G.state.completed["quest-7-turn-in"],nil)
    assert(C:Text(G):find("Unfinished quests remain",1,true))
end)
test("existing Elwynn completion and overrides import once without overwriting old progress",function()
    local old={current="quest-7-turn-in",completed={["quest-783-turn-in"]=true},overrides={["quest-7-accept"]="confirmed"}}
    F.character={guides={["elwynn-forest-shared"]=old},professions={},windows={}}
    assert(G:Select(C.testId,F.character))
    eq(G.state.completed["quest-783-turn-in"],true); eq(G.state.overrides["quest-7-accept"],"confirmed")
    eq(old.current,"quest-7-turn-in"); eq(old.completed["campaign-target-20"],nil)
    G.state.completed["quest-783-turn-in"]=false; assert(G:Select(C.testId,F.character))
    eq(G.state.completed["quest-783-turn-in"],false)
end)
test("campaign save validation preserves unknown versions and relog preferences",function()
    begin(14); local id=G:Current().questId; assert(C:Defer(G))
    local saved=F.modules.SavedVariables.Copy(F.character)
    F.character=saved; assert(G:Select(C.testId,saved)); G:Update(current)
    eq(G.state.campaign.deferredByUser[id],true); assert(G:Current().questId~=id)
    local record=saved.guides[C.testId]; record.campaign.version=99
    eq(G:Select(C.testId,saved),nil); eq(record.campaign.version,99)
end)
test("public command and UI show a level goal with non-destructive controls",function()
    current=snapshot(16,{},"Westfall")
    F.character={guides={},professions={},windows={}}
    F:Command("1-20"); eq(G.guide.id,C.testId)
    local U=F.modules.MainWindow
    assert(U.body.text:find("Level 16 / 20",1,true))
    eq(U.previous,nil); eq(U.next,nil)
    local menu=F.modules.ContextMenu; menu:Open("guides")
    assert(menu:Invoke("auto-plan"))
    F:Command("leveling defer"); F:Command("leveling auto"); eq(G.state.campaign.pinnedQuest,nil)
    F:Command("1-20"); eq(G.guide.id,C.testId)
end)
test("accelerated 1–20 simulation preserves quest evidence and terminates at the actual target",function()
    begin(1)
    for level=1,19 do
        current.level=level; G:Update(current)
        if G.state.campaign.status=="active" then
            local id=G:Current().questId
            local record=C:Index(G.guide).quests[id]
            current.quests[id]={accepted=true,level=record.level}; current.trackedQuestId=id
            G:Update(current); eq(G:Current().type,"COMPLETE_QUEST")
            current.quests[id].complete=true; G:Update(current); eq(G:Current().type,"TURN_IN_QUEST")
            current.quests[id]={turnedIn=true}; G:Update(current)
            eq(G.state.completed["quest-"..id.."-turn-in"],true)
        end
    end
    current.level=20; G:Update(current); eq(G.state.campaign.status,"target-reached")
end)
Compat.providers.snapshot,Compat.inspected.snapshot,F.snapshot=previousProvider,previousEvidence,previousSnapshot
F.character,F.settings.autoAdvance=previousCharacter,previousAuto
if previousCharacter.selectedGuide then G:Select(previousCharacter.selectedGuide,previousCharacter) end
