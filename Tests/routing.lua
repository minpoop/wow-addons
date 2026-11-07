local F,test,eq=...
local G,J,V=F.modules.GuideEngine,F.modules.LiveJournal,F.modules.StepValidator
local originalCharacter=F.character
local originalAuto=F.settings.autoAdvance
local function snapshot(a,b)
    return {active={770001,770002},quests={
        [770001]={title="First fixture quest",accepted=true,complete=a==true},
        [770002]={title="Second fixture quest",accepted=true,complete=b==true}},source="Synthetic tests"}
end
local function begin(s)
    F.character={guides={},professions={},windows={}}
    assert(J:Sync(s)); assert(G:Select(J.id,F.character)); G:Update(s)
end
test("journal batches objectives before turn-ins without completing uncertain quests",function()
    local s=snapshot(false,false); begin(s)
    s.quests[770001].complete=true; G:Update(s)
    eq(G:Current().id,"quest-770002-complete")
    eq(G.state.completed["quest-770001-turn-in"],nil)
    s.quests[770002].complete=true; G:Update(s)
    eq(G:Current().id,"quest-770001-turn-in"); eq(J:Progress(),2)
    eq(J:NextStep().id,"quest-770002-turn-in")
end)
test("out-of-order turn-ins retain the unfinished earlier quest",function()
    local s=snapshot(false,false); begin(s)
    s.quests[770002]={title="Second fixture quest",turnedIn=true}; G:Update(s)
    eq(G:Current().id,"quest-770001-complete"); eq(J:Progress(),2)
    eq(G.state.completed["quest-770001-complete"],nil)
    eq(G.state.completed["quest-770002-turn-in"],true)
end)
test("explicit quest focus persists until that task completes and then resumes the queue",function()
    local s=snapshot(false,false); begin(s)
    assert(J:Focus(770002)); G:Update(s); eq(G:Current().questId,770002)
    eq(G.state.completed["quest-770001-complete"],nil)
    s.quests[770002].complete=true; G:Update(s)
    eq(G:Current().questId,770001); eq(G.state.focusStep,nil)
    assert(J:Focus(770002)); eq(G:Current().type,"TURN_IN_QUEST")
    G:Update(s); eq(G:Current().questId,770002)
    s.quests[770002].turnedIn=true; G:Update(s); eq(G:Current().questId,770001)
    eq(J:Focus(770002),nil)
end)
test("journal preserves old interleaved cursor IDs, overrides and review mode",function()
    local s=snapshot(false,false); begin(s)
    F.character.guides[J.id]={current="quest-770001-turn-in",completed={["quest-770001-complete"]=true},overrides={["quest-770001-complete"]="confirmed"}}
    assert(J:Sync(s)); G:Update(s)
    eq(G:Current().id,"quest-770002-complete")
    eq(G.state.overrides["quest-770001-complete"],"confirmed")
    G:Back(); local current=G:Current().id
    s.quests[770002].complete=true; G:Update(s); eq(G:Current().id,current)
    G.state.review=nil; F.settings.autoAdvance=false; G:Update(s)
    eq(G.state.completed["quest-770002-complete"],nil)
    F.settings.autoAdvance=true
end)
test("manually confirming a focused task resumes unfinished work immediately",function()
    local s=snapshot(false,false); begin(s)
    assert(J:Focus(770002)); G:Advance(true)
    eq(G:Current().id,"quest-770001-complete")
    eq(G.state.overrides["quest-770002-complete"],"confirmed")
    eq(G.state.finished,false)
end)
test("Elwynn is registered as reference content and contains no class restrictions",function()
    local guide=G.guides["elwynn-forest-shared"]
    assert(guide); eq(guide.verification,"reference-reviewed"); eq(guide.class,nil)
    eq(guide.faction,"Alliance"); eq(#guide.steps,113); eq(V:Guide(guide,false),true)
    eq(V:Guide(guide,true),false)
    eq(G:Recommend({faction="Alliance",race="Human",class="Mage",zone="Elwynn Forest",level=1})==guide,false)
    local ids={}; for _,step in ipairs(guide.steps) do if step.questId then ids[step.questId]=true end end
    local count=0; for _ in pairs(ids) do count=count+1 end; eq(count,34)
end)
test("missing character APIs do not turn error messages into faction tokens",function()
    local faction,race,class=UnitFactionGroup,UnitRace,UnitClass
    UnitFactionGroup,UnitRace,UnitClass=nil,nil,nil
    local character=F.modules.Compatibility:Character()
    eq(character.faction,nil); eq(character.race,nil); eq(character.class,nil)
    F.character={guides={},professions={},windows={}}
    F:Command("elwynn"); eq(G.guide.id,"elwynn-forest-shared")
    UnitFactionGroup,UnitRace,UnitClass=faction,race,class
end)
test("Elwynn guide progresses through all steps using positive synthetic observations",function()
    F.character={guides={},professions={},windows={}}
    assert(G:Select("elwynn-forest-shared",F.character))
    local state={quests={},level=10}
    local safety=0
    while G:Current() do
        safety=safety+1; assert(safety<=113,"route stuck")
        local step=G:Current()
        if step.type=="MANUAL_INSTRUCTION" then G:Advance(true)
        elseif step.type=="REACH_LEVEL" then G:Update(state)
        else
            local q=state.quests[step.questId] or {}; state.quests[step.questId]=q
            if step.type=="ACCEPT_QUEST" then q.accepted=true
            elseif step.type=="COMPLETE_QUEST" then q.complete=true
            elseif step.type=="TURN_IN_QUEST" then q.turnedIn=true end
            G:Update(state)
        end
    end
    eq(G.state.finished,true)
    eq(G.state.completed["quest-11-turn-in"],true)
    eq(G.state.completed["elwynn-end"],true)
end)
test("optional Elwynn encounters can be skipped without removing shared progression",function()
    F.character={guides={},professions={},windows={}}
    assert(G:Select("elwynn-forest-shared",F.character))
    for index,step in ipairs(G.guide.steps) do
        if step.questId==176 then
            eq(step.optional,true); G.index=index; G.state.current=step.id
            assert(G:Skip()); eq(G.state.overrides[step.id],"skipped")
        end
    end
    eq(G:Current().id,"elwynn-end")
end)
F.settings.autoAdvance=originalAuto; F.character=originalCharacter
if originalCharacter.selectedGuide then G:Select(originalCharacter.selectedGuide,originalCharacter) end
