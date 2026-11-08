local F,test,eq=...
local G,C,Compat=F.modules.GuideEngine,F.modules.LevelingCampaign,F.modules.Compatibility
local saved={character=F.character,provider=Compat.providers.snapshot,evidence=Compat.inspected.snapshot,snapshot=F.snapshot,faction=UnitFactionGroup,race=UnitRace,guide=G.guide,state=G.state,index=G.index,auto=F.settings.autoAdvance}
local current
Compat:RegisterInspectedProvider("snapshot",function() return current end,"Synthetic Horde progression tests")
UnitFactionGroup=function() return "Horde","Horde" end
local function begin(level,race,zone,quests)
    F.character={guides={},professions={},windows={}};F.settings.autoAdvance=true
    UnitRace=function() return race,race end
    current={level=level,quests=quests or {},active={},character={faction="Horde",race=race,zone=zone}}
    assert(G:Select(C.hordeId,F.character));G:Update(current)
    return C.runtime[C.hordeId]
end
test("Horde reference guide supplies all-class quests, race gates and chapters through 60",function()
    local guide=G.guides[C.hordeId];assert(guide,"Horde guide was rejected")
    eq(guide.faction,"Horde");eq(guide.class,nil);eq(guide.verification,"reference-reviewed")
    eq(#C:Index(guide).order,821);eq(#guide.steps,2465)
    eq(F.modules.StepValidator:Guide(guide,false),true);eq(#guide.campaign.chapters,12)
end)
test("all four Horde races get starting work in their own region and goals at each level",function()
    for race,zone in pairs({Orc="Durotar",Troll="Durotar",Tauren="Mulgore",Scourge="Tirisfal Glades"}) do
        local run=begin(1,race,zone);assert(run.selected,race.." missing starting work");eq(run.selected.record.zone,zone)
        for level=1,59 do
            run=begin(level,race,zone)
            assert(run.selected,race.." no goal at "..level)
            assert(run.selected.goal.level>=level-3 and run.selected.goal.level<=level+2)
            eq(C:RaceEligible(run.selected.record,current),true)
        end
    end
end)
test("race-specific quests cannot be recommended or pinned for the wrong character",function()
    begin(1,"Orc","Durotar")
    local index=C:Index(G.guide);local restricted
    for _,record in ipairs(index.order) do
        if record.allowedRaces and not C:RaceEligible(record,current) then restricted=record;break end
    end
    assert(restricted);eq(C:Keep(G,restricted.id),nil)
    local candidates=C:BuildCandidates(G,current)
    for _,candidate in ipairs(candidates) do assert(candidate.record.id~=restricted.id) end
    eq(C:RaceEligible(restricted,{character={}}),false)
end)
test("recommended leveling chooses faction automatically and rejects the opposite guide",function()
    begin(22,"Tauren","The Barrens")
    F:Command("leveling");eq(G.guide.id,C.hordeId)
    F:Command("horde");eq(G.guide.id,C.hordeId)
    local id=G.state.current;eq(C:Select(C.id),nil);eq(G.state.current,id)
    UnitFactionGroup=function() return "Alliance","Alliance" end
    eq(C:Select(C.hordeId),nil)
    UnitFactionGroup=function() return "Horde","Horde" end
end)
test("Horde quests follow positive phases, outleveling and actual target 60",function()
    begin(1,"Orc","Durotar")
    for level=1,59 do
        current.level=level;G:Update(current)
        assert(G:Current() and G:Current().questId,"No Horde objective at "..level)
        local id=G:Current().questId
        current.quests[id]={accepted=true};G:Update(current);eq(G:Current().type,"COMPLETE_QUEST")
        current.quests[id].complete=true;G:Update(current);eq(G:Current().type,"TURN_IN_QUEST")
        current.quests[id]={turnedIn=true};G:Update(current)
        eq(G.state.completed["quest-"..id.."-turn-in"],true)
    end
    current.level=60;G:Update(current);eq(G.state.finished,true)
    eq(G.state.campaign.status,"target-reached")
end)
F.character,F.snapshot,F.settings.autoAdvance=saved.character,saved.snapshot,saved.auto
Compat.providers.snapshot,Compat.inspected.snapshot=saved.provider,saved.evidence
UnitFactionGroup,UnitRace=saved.faction,saved.race
G.guide,G.state,G.index=saved.guide,saved.state,saved.index
