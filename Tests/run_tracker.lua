local F,test,eq=...
local R,G,C,E=F.modules.RunTracker,F.modules.GuideEngine,F.modules.LevelingCampaign,F.modules.Events
local names={"UnitLevel","UnitXP","UnitXPMax","GetTime","GetBuildInfo","C_QuestLog"}
local globals={};for _,name in ipairs(names) do globals[name]=_G[name] end
local old={character=F.character,snapshot=F.snapshot,guide=G.guide,state=G.state,index=G.index,loading=F.modules.ForeverAdapter.loading,choice=F.settings.routePlan}
local level,xp,maximum,clock=7,20,100,1000
UnitLevel=function() return level end;UnitXP=function() return xp end;UnitXPMax=function() return maximum end;GetTime=function() return clock end
GetBuildInfo=function() return "fixture","fixture","fixture",16001 end
F.modules.ForeverAdapter.loading=false
local function snapshot(quests,zone) return {level=level,quests=quests or {},character={zone=zone or "Synthetic fields"}} end
local function begin()
    F.character={guides={},professions={},windows={}};F.snapshot=snapshot()
    R:Pause();R.owner=nil;assert(R:Start());return F.character.routeRun
end
test("local runs require explicit start and readable supported-client data",function()
    F.character={guides={},professions={},windows={}};F.snapshot=snapshot()
    R:Observe(F.snapshot);eq(F.character.routeRun,nil)
    local build=GetBuildInfo;GetBuildInfo=function() return "other","other","other",999999 end
    eq(R:Start(),nil);eq(F.character.routeRun,nil);GetBuildInfo=build
    local data=begin();eq(data.active,true);eq(data.samples,1);eq(data.xpGained,0)
end)
test("XP tracking adds observed gains and one known level rollover without quest attribution",function()
    level,xp,maximum,clock=7,20,100,1000;local data=begin()
    xp=65;clock=1030;R:Observe(snapshot());eq(data.xpGained,45);eq(data.seconds,30)
    level,xp,maximum=8,10,150;R:Observe(snapshot());eq(data.xpGained,90)
    eq(data.turnIns,0);eq(data.lastLevel,8)
    local text=table.concat(assert(R:Lines()),"\n");assert(text:find("XP includes kills and other sources",1,true))
end)
test("ambiguous resets multi-level jumps and outages cannot create phantom XP",function()
    level,xp,maximum=7,95,100;local data=begin()
    xp=0;R:Observe(snapshot());eq(data.xpGained,0);eq(data.unknownXPIntervals,1)
    level,xp,maximum=8,0,150;R:Observe(snapshot());eq(data.xpGained,0)
    level,xp=10,25;R:Observe(snapshot());eq(data.xpGained,0);eq(data.unknownXPIntervals,2)
    UnitXP=function() error("Unavailable XP") end;R:Observe(snapshot());eq(data.xpAvailable,false)
    UnitXP=function() return xp end;R:Observe(snapshot());eq(data.xpGained,0)
end)
test("loading and character changes reset baselines instead of counting offline time or XP",function()
    level,xp,maximum,clock=7,20,100,1000;local data=begin()
    clock=1010;E:Emit("PLAYER_LEAVING_WORLD");eq(data.seconds,10)
    F.modules.ForeverAdapter.loading=false;clock=10000;xp=80;R:Observe(snapshot());eq(data.seconds,10);eq(data.xpGained,0)
    local character=F.character
    F.character={guides={},professions={},windows={}};R:Observe(snapshot());eq(F.character.routeRun,nil)
    clock=20000;xp=90;F.character=character;R:Observe(snapshot());eq(data.seconds,10);eq(data.xpGained,0)
end)
test("only positive in-run turn-ins count and repeated history or disappearance cannot inflate them",function()
    level,xp,maximum=7,20,100;local data=begin()
    R:Observe(snapshot({[990901]={turnedIn=true}}));eq(data.turnIns,0)
    R:Observe(snapshot({[990902]={accepted=true}}));R:Observe(snapshot({}));eq(data.turnIns,0)
    R:Observe(snapshot({[990902]={accepted=true}}));R:Observe(snapshot({[990902]={turnedIn=true}}));eq(data.turnIns,1)
    E:Emit("QUEST_TURNED_IN",990902);eq(data.turnIns,1)
    E:Emit("QUEST_TURNED_IN",990903);eq(data.turnIns,2)
end)
test("route waits are deduplicated and never confused with stale or unreadable planner data",function()
    local data=begin();local state={};G.state=state;G.guide={id="run-gap-fixture",steps={}};G.index=1
    local s=snapshot()
    C.runtime[G.guide.id]={state=state,snapshot=s,status="waiting"}
    R:Observe(s);R:Observe(s);eq(data.routeWaits,1)
    C.runtime[G.guide.id].error="Unreadable snapshot";R:Observe(s);eq(data.routeWaits,1)
    C.runtime[G.guide.id].error=nil;R:Observe(snapshot());eq(data.routeWaits,1)
    C.runtime[G.guide.id]={state=state,snapshot=s,status="active"};R:Observe(s)
    C.runtime[G.guide.id].status="waiting";R:Observe(s);eq(data.routeWaits,2)
    local text=table.concat(assert(R:Lines()),"\n");assert(text:find("waits do not prove an XP shortage",1,true))
end)
test("report traces stay bounded and recording can stop without changing guide progression",function()
    local data=begin();local state={completed={sentinel=true},current="sentinel"};G.state=state
    for i=1,140 do R:Event(data,"fixture","Synthetic event "..i) end
    eq(#data.events,80);assert(data.events[1].text:find("61",1,true))
    assert(R:Stop());eq(data.active,false);local gained=data.xpGained
    xp=xp+10;R:Observe(snapshot());E:Emit("QUEST_TURNED_IN",990904)
    eq(data.xpGained,gained);eq(data.turnIns,0);eq(state.completed.sentinel,true);eq(state.current,"sentinel")
    assert(R:Start());eq(F.character.previousRouteRun.active,false)
end)
test("corrupt and future run records are retained without blocking quest progress",function()
    F.character={guides={},professions={},windows={},routeRun={version=99,important=true}}
    eq(R:Start(),nil);eq(F.character.routeRun.version,99);eq(F.character.routeRun.important,true)
    local data=begin();data.currentXP="invalid";eq(R:Lines(),nil);eq(data.currentXP,"invalid")
end)
test("XP events perform no quest-log scans and optional API failures remain local",function()
    level,xp,maximum=7,20,100;local data=begin();local scans=0
    C_QuestLog={GetNumQuestLogEntries=function() scans=scans+1;return 0 end}
    xp=30;E:Emit("PLAYER_XP_UPDATE","player");eq(scans,0);eq(data.xpGained,10)
    xp=40;E:Emit("PLAYER_XP_UPDATE","pet");eq(data.xpGained,10)
    UnitXPMax=nil;E:Emit("PLAYER_XP_UPDATE","player");eq(data.xpAvailable,false);eq(scans,0)
    UnitXPMax=function() return maximum end
end)
test("optional quest-log capacity errors never discard an otherwise readable snapshot",function()
    local adapter=F.modules.ForeverAdapter;local enabled,loading,baseline=adapter.enabled,adapter.loading,adapter.baseline
    adapter.enabled=true;adapter.loading=false;adapter.baseline={}
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,GetInfo=function() return {questID=990905,title="Synthetic quest"} end,
        GetMaxNumQuestsCanAccept=function() return 20 end}
    local s=assert(adapter:Collect());eq(s.questLogCapacity,20)
    C_QuestLog.GetMaxNumQuestsCanAccept=function() error("Optional API unavailable") end
    s=assert(adapter:Collect());eq(s.questLogCapacity,nil);eq(s.quests[990905].accepted,true)
    C_QuestLog.GetMaxNumQuestsCanAccept=function() return "20" end;s=assert(adapter:Collect());eq(s.questLogCapacity,nil)
    adapter.enabled,adapter.loading,adapter.baseline=enabled,loading,baseline
end)
test("public route and run menu commands preserve progression and retain a stopped report",function()
    local Compat=F.modules.Compatibility
    local provider,evidence=Compat.providers.snapshot,Compat.inspected.snapshot
    level,xp,maximum=7,20,100
    local current=snapshot();current.active={};current.character={zone="Elwynn Forest",faction="Alliance"}
    Compat:RegisterInspectedProvider("snapshot",function() return current end,"Synthetic public run controls")
    F.character={guides={},professions={},windows={}}
    F:Command("route elwynn");eq(G.guide.id,C.id);eq(F.settings.routePlan,"elwynn-westfall-1-20")
    local menu=F.modules.ContextMenu
    menu:Open("route-planning");assert(menu:Invoke("run-start"));eq(F.character.routeRun.active,true)
    local state=G.state;local id=state.current
    menu:Open("route-planning");assert(menu:Invoke("run-report"));eq(G.state,state);eq(state.current,id)
    menu:Open("route-planning");assert(menu:Invoke("run-stop"));eq(F.character.routeRun.active,false)
    menu:Open("route-planning");assert(menu:Invoke("route-off"));eq(F.settings.routePlan,"off");eq(C.runtime[C.id].route,nil)
    menu:Close();Compat.providers.snapshot,Compat.inspected.snapshot=provider,evidence
end)
for _,name in ipairs(names) do _G[name]=globals[name] end
F.character,F.snapshot=old.character,old.snapshot
G.guide,G.state,G.index=old.guide,old.state,old.index
F.modules.ForeverAdapter.loading=old.loading;R:Pause();R.owner=nil
F.settings.routePlan=old.choice;F.db.settings=F.settings
