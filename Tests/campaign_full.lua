local F,test,eq=...
local G,C,Compat,U=F.modules.GuideEngine,F.modules.LevelingCampaign,F.modules.Compatibility,F.modules.MainWindow
local previousCharacter,previousAuto=F.character,F.settings.autoAdvance
local provider,evidence,previousSnapshot=Compat.providers.snapshot,Compat.inspected.snapshot,F.snapshot
local current
Compat:RegisterInspectedProvider("snapshot",function() return current end,"Synthetic expanded campaign test")
local function begin(level,zone,quests)
    F.character={guides={},professions={},windows={}}
    F.settings.autoAdvance=true
    current={level=level,quests=quests or {},active={},character={zone=zone or "Elwynn Forest"}}
    assert(G:Select(C.id,F.character)); G:Update(current)
    return C.runtime[C.id]
end
test("expanded guide supplies 556 shared quests, all chapters and a real level-60 goal",function()
    local guide=G.guides[C.id]
    assert(guide); eq(guide.class,nil); eq(guide.faction,"Alliance")
    eq(guide.campaign.targetLevel,60); eq(#guide.steps,1670); eq(#C:Index(guide).order,556)
    eq(#guide.campaign.chapters,12); eq(F.modules.StepValidator:Guide(guide,false),true)
    eq(F.modules.StepValidator:Guide(guide,true),false)
end)
test("expanded pool has level-appropriate candidates at every level 1 through 59",function()
    for level=1,59 do
        local run=begin(level)
        assert(run.selected,"Missing content at level "..level)
        assert(run.selected.goal.level>=level-3 and run.selected.goal.level<=level+2)
        assert(run.selected.goal.minimum<=level)
        eq(run.selected.record.optional,false)
    end
end)
test("completed 1–20 saves continue to 60 while preserving completions and preferences",function()
    begin(24)
    local old={finished=true,completed={["quest-7-turn-in"]=true,["campaign-target-20"]=true},overrides={["quest-33-accept"]="confirmed"},campaign={version=1,status="target-reached",lastLevel=20,deferredByUser={[62]=true},pinnedQuest=47}}
    F.character.guides[C.testId]=old; F.character.guides[C.id]=nil
    F:Command("leveling")
    eq(G.guide.id,C.id); eq(G.state.finished,false)
    eq(G.state.completed["quest-7-turn-in"],true); eq(G.state.completed["campaign-target-60"],nil)
    eq(G.state.completed["campaign-target-20"],nil); eq(G.state.overrides["quest-33-accept"],"confirmed")
    eq(G.state.campaign.deferredByUser[62],true); eq(G.state.campaign.pinnedQuest,47)
    eq(old.finished,true); eq(old.campaign.status,"target-reached")
    G.state.completed["quest-7-turn-in"]=false
    assert(G:Select(C.id,F.character)); eq(G.state.completed["quest-7-turn-in"],false)
end)
test("the 20 target no longer ends the expanded guide and only actual 60 finishes it",function()
    begin(20); eq(G.state.finished,false); eq(G.state.campaign.status,"active")
    current.level=59; G:Update(current); eq(G.state.finished,false)
    current.level=60; G:Update(current); eq(G.state.finished,true)
    eq(G.state.completed["campaign-target-60"],true); eq(G.state.completed["quest-7-turn-in"],nil)
    assert(C:Text(G):find("Level 60 target reached",1,true))
    eq(C:Band(54,60),"50–54"); eq(C:Band(59,60),"55–59"); eq(C:Band(60,60),"60")
end)
test("later chains require every ALL prerequisite while ANY accepts either observed branch",function()
    begin(38,"Stranglethorn Vale",{[203]={turnedIn=true}})
    local _,_,root=C:BuildCandidates(G,current)
    eq(root(207,false,{}).id,204)
    current.quests[204]={turnedIn=true}; G:Update(current)
    _,_,root=C:BuildCandidates(G,current); eq(root(207,false,{}).id,207)
    begin(54,"Eastern Plaguelands",{[5601]={turnedIn=true}})
    _,_,root=C:BuildCandidates(G,current); eq(root(5149,false,{}).id,5149)
    begin(52,"Western Plaguelands",{[5066]={turnedIn=true}})
    _,_,root=C:BuildCandidates(G,current); eq(root(5092,false,{}).id,5092)
    current.quests={}; _,_,root=C:BuildCandidates(G,current); eq(root(5092,false,{}).id,5090)
end)
test("mutually exclusive introductions cannot both be recommended",function()
    begin(54,"Eastern Plaguelands",{[5601]={accepted=true}})
    local _,_,root=C:BuildCandidates(G,current)
    eq(root(5142,false,{}),nil); eq(root(5601,false,{}).id,5601)
    current.quests[5601]={turnedIn=true}; G:Update(current)
    _,_,root=C:BuildCandidates(G,current); eq(root(5142,false,{}),nil)
end)
test("expanded planner favors suitable local quests and leaves an outleveled zone",function()
    local run=begin(34,"Desolace"); eq(run.selected.record.zone,"Desolace")
    run=begin(54,"Elwynn Forest",{[7]={accepted=true,level=2}})
    current.trackedQuestId=7; G:Update(current)
    assert(G:Current().questId~=7); assert(C.runtime[C.id].selected.goal.level>=51)
    eq(G.state.completed["quest-7-turn-in"],nil)
end)
test("full campaign relationships and chapter coverage reject malformed data",function()
    local copy=F.modules.SavedVariables.Copy
    local bad=copy(G.guides[C.id]); bad.campaign.chapters[2].minLevel=6
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.steps[2].prerequisiteQuestsAny={bad.steps[2].questId}
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.steps[2].exclusiveQuests={[2]=123}
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.campaign.targetLevel=1
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.steps[2].questId=nil
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.steps[2].type=nil
    eq(F.modules.StepValidator:Guide(bad,false),false)
    bad=copy(G.guides[C.id]); bad.steps[1].questId=991999
    eq(F.modules.StepValidator:Guide(bad,false),false)
end)
test("all quest preferences fit the campaign save limit and list output is paginated",function()
    begin(54)
    for _,record in ipairs(C:Index(G.guide).order) do G.state.campaign.deferredByUser[record.id]=true end
    eq(C:ValidateState(G.state),true)
    G:Update(current); eq(G.state.campaign.status,"waiting"); eq(G.state.finished,false)
    local print=F.Print; local rows={}; F.Print=function(_,text) rows[#rows+1]=text end
    local ok,err=C:List(G,2); F.Print=print
    assert(ok,err); eq(#rows,22)
    eq(C:List(G,999),nil)
    F:Command("leveling chapters")
end)
test("expanded campaign simulates acceptance, objectives and turn-in through level 60",function()
    begin(1)
    for level=1,59 do
        current.level=level; G:Update(current)
        assert(G.state.campaign.status=="active","No work at level "..level)
        local id=G:Current().questId
        local record=C:Index(G.guide).quests[id]
        current.quests[id]={accepted=true,level=record.level}; current.trackedQuestId=id
        G:Update(current); eq(G:Current().type,"COMPLETE_QUEST")
        current.quests[id].complete=true; G:Update(current); eq(G:Current().type,"TURN_IN_QUEST")
        current.quests[id]={turnedIn=true}; G:Update(current)
        eq(G.state.completed["quest-"..id.."-turn-in"],true)
    end
    current.level=60; G:Update(current); eq(G.state.campaign.status,"target-reached")
end)
test("native adapter reads external prerequisite and exclusive history without inventing completion",function()
    begin(54)
    local A=F.modules.ForeverAdapter
    local log,enabled,loading,baseline,turnedIn,full=C_QuestLog,A.enabled,A.loading,A.baseline,A.turnedIn,A.historyFull
    local queried={}
    local build=GetBuildInfo
    GetBuildInfo=function() return "fixture-version","fixture-build","fixture-date",16001 end
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() return {} end,
        IsQuestFlaggedCompleted=function(id) queried[id]=true; return id==5066 or id==5405 end}
    A.enabled,A.loading,A.baseline,A.turnedIn,A.historyFull=true,false,{},{},false
    local ok,result=pcall(function() return A:Collect() end)
    C_QuestLog,A.enabled,A.loading,A.baseline,A.turnedIn,A.historyFull=log,enabled,loading,baseline,turnedIn,full
    GetBuildInfo=build
    assert(ok,result); assert(result)
    eq(queried[5066],true); eq(queried[5091],true); eq(queried[5405],true)
    eq(result.quests[5066].turnedIn,true); eq(result.quests[5405].turnedIn,true)
    eq(result.quests[5091],nil)
end)
test("public full campaign command, chapter overview and UI show the continued goal",function()
    begin(45,"Tanaris"); F:Command("1-60")
    eq(G.guide.id,C.id); assert(U.body.text:find("Level 45 / 60",1,true))
    F:Command("leveling"); eq(G.guide.id,C.id)
    F:Command("1-20"); eq(G.guide.id,C.testId)
end)
Compat.providers.snapshot,Compat.inspected.snapshot,F.snapshot=provider,evidence,previousSnapshot
F.character,F.settings.autoAdvance=previousCharacter,previousAuto
if previousCharacter.selectedGuide then G:Select(previousCharacter.selectedGuide,previousCharacter) end
