local F,test,eq=...
local A,C,E,G,J=F.modules.ForeverAdapter,F.modules.Compatibility,F.modules.Events,F.modules.GuideEngine,F.modules.LiveJournal
local originalCharacter=F.character
F.character={guides={},professions={},windows={}}
local names={"GetBuildInfo","UnitLevel","C_QuestLog","C_Item","C_Timer","C_SuperTrack"}
local old={}; for _,name in ipairs(names) do old[name]=_G[name] end
local queue,enumerations,level,owned={},0,5,0
local entries={{isHeader=true,title="Fixture header"},{isHeader=false,title="Observed fixture quest",questID=880001}}
local complete,history={},{}
local function drain()
    local pending=queue; queue={}
    for _,fn in ipairs(pending) do fn() end
end
C_QuestLog={
    GetNumQuestLogEntries=function() enumerations=enumerations+1; return #entries end,
    GetInfo=function(index) return entries[index] end,
    IsComplete=function(id) return complete[id]==true end,
    IsFailed=function() return false end,
    IsQuestFlaggedCompleted=function(id) return history[id]==true end,
    GetQuestObjectives=function(id) return {{text="Observed fixture objective",type="monster",numFulfilled=complete[id] and 3 or 1,numRequired=3,finished=complete[id]==true}} end,
}
C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
UnitLevel=function() return level end
C_Item={GetItemCount=function(id,bank,charges,reagents)
    eq(id,990100); eq(bank,false); eq(charges,false); eq(reagents,false); return owned
end}
test("Forever adapter requires interface match and keeps live verification distinct",function()
    eq(A:Start(),nil)
    GetBuildInfo=function() return "1.60.70790","fixture-build","fixture-date",16001 end
    assert(A:Start()); eq(C.profile.verified,false); eq(#queue,1)
    drain()
    local s=assert(C:Read("snapshot")); eq(#s.active,1); eq(s.active[1],880001)
    eq(s.quests[880001].complete,false); eq(s.level,5); eq(s.provenance,"source-inspected")
end)
test("live journal creates only observed quest steps and shows real objective counts",function()
    F:Command("journal"); eq(G.guide.id,J.id); eq(G:Current().questId,880001)
    eq(G.guide.verification,"observed-character-log"); eq(#G.guide.steps,2)
    F.modules.MainWindow:Render()
    assert(F.modules.MainWindow.body.text:find("Observed fixture objective",1,true))
    assert(F.modules.MainWindow.body.text:find("1/3",1,true))
end)
test("Forever acceptance uses the single quest ID and clears stale turn-in evidence",function()
    A.turnedIn[880001]=true; A.baseline[880001]=true
    E:Emit("QUEST_ACCEPTED",880001)
    eq(A.turnedIn[880001],nil); eq(A.baseline[880001],nil)
    drain(); eq(A.baseline[880001],false)
end)
test("quest event bursts are coalesced into one scan without per-frame polling",function()
    local before=enumerations
    for _=1,50 do E:Emit("QUEST_LOG_UPDATE") end
    eq(#queue,1); drain(); eq(enumerations,before+1)
end)
test("native tracked quest and objective activity are exposed without changing the game's selection",function()
    local writes=0
    C_SuperTrack={GetSuperTrackedQuestID=function() return 880001 end,SetSuperTrackedQuestID=function() writes=writes+1 end}
    C_QuestLog.GetSelectedQuest=function() return 880001 end
    E:Emit("QUEST_WATCH_UPDATE",880001)
    local snapshot=assert(C:Read("snapshot"))
    eq(snapshot.trackedQuestId,880001); eq(snapshot.selectedQuestId,880001)
    eq(snapshot.signalQuestId,880001); assert(snapshot.signalRevision>0); eq(writes,0)
    C_SuperTrack.GetSuperTrackedQuestID=function() error("fixture restricted focus") end
    snapshot=assert(C:Read("snapshot")); eq(snapshot.trackedQuestId,nil); eq(snapshot.selectedQuestId,880001)
    C_QuestLog.GetSelectedQuest=function() return 999999 end
    snapshot=assert(C:Read("snapshot")); eq(snapshot.selectedQuestId,nil)
    C_SuperTrack=nil; C_QuestLog.GetSelectedQuest=nil; drain()
end)
test("objectives and turn-ins advance while abandonment remains uncertain",function()
    complete[880001]=true; E:Emit("QUEST_WATCH_UPDATE",880001); drain()
    eq(G:Current().type,"TURN_IN_QUEST")
    entries={{isHeader=true,title="Fixture header"}}
    E:Emit("QUEST_REMOVED",880001); drain(); eq(G:Current().type,"TURN_IN_QUEST")
    E:Emit("QUEST_TURNED_IN",880001,10,0); drain()
    eq(G.state.finished,true); eq(G:Current(),nil)
end)
test("new accepted quests append stable IDs and reopen a finished journal",function()
    entries[2]={isHeader=false,title="Second observed fixture",questID=880002}
    E:Emit("QUEST_ACCEPTED",880002); drain()
    eq(G:Current().id,"quest-880002-complete"); eq(#G.guide.steps,4)
    eq(G.state.completed["quest-880001-turn-in"],true)
end)
test("old repeatable completion flags never imply a new turn-in",function()
    history[880002]=true; E:Emit("QUEST_ACCEPTED",880002); drain(); eq(A.baseline[880002],true)
    entries[2]=nil; E:Emit("QUEST_REMOVED",880002); drain()
    eq(G:Current().id,"quest-880002-complete")
    eq(C:Read("snapshot").quests[880002],nil)
    E:Emit("QUEST_TURNED_IN",880002); drain(); eq(G.state.finished,true)
end)
test("API errors and loading screens retain progress without using stale snapshots",function()
    local state=F.modules.SavedVariables.Copy(G.state)
    local read=C_QuestLog.GetNumQuestLogEntries
    C_QuestLog.GetNumQuestLogEntries=function() error("fixture cache failure") end
    E:Emit("QUEST_LOG_UPDATE"); drain(); eq(F.snapshot,nil)
    eq(G.state.finished,state.finished); assert(C.failures.snapshot)
    C_QuestLog.GetNumQuestLogEntries=read
    E:Emit("PLAYER_LEAVING_WORLD"); eq(C:Read("snapshot"),nil)
    E:Emit("QUEST_LOG_UPDATE"); eq(#queue,0)
    E:Emit("PLAYER_ENTERING_WORLD"); drain(); assert(C:Read("snapshot"))
end)
test("a newly changed completion history flag is positive turn-in evidence",function()
    local guide={id="history-fixture",title="Fixture",verification="live-verified",source="Synthetic test only",steps={
        {id="turnin",type="TURN_IN_QUEST",questId=880003,text="Fixture turn-in"}}}
    assert(G:RegisterGuide(guide)); assert(G:Select(guide.id,F.character))
    entries[2]={isHeader=false,title="Third observed fixture",questID=880003}
    E:Emit("QUEST_ACCEPTED",880003); drain(); eq(A.baseline[880003],false)
    history[880003]=true; entries[2]=nil
    E:Emit("QUEST_REMOVED",880003); drain(); eq(G.state.finished,true)
end)
test("unloaded objective rows and failed quests never become completed by inference",function()
    entries[2]={isHeader=false,title="Unloaded fixture",questID=880004}
    local objectives,failed=C_QuestLog.GetQuestObjectives,C_QuestLog.IsFailed
    C_QuestLog.GetQuestObjectives=function() return {{text="",numFulfilled=0,numRequired=0}} end
    C_QuestLog.IsFailed=function() return true end
    complete[880004]=true
    local snapshot=assert(C:Read("snapshot"))
    eq(snapshot.quests[880004].objectives,nil); eq(snapshot.quests[880004].complete,false)
    C_QuestLog.GetQuestObjectives,C_QuestLog.IsFailed=objectives,failed
    entries[2]=nil
end)
test("inventory and level providers drive guide steps using only referenced item IDs",function()
    local guide={id="live-inventory-fixture",title="Fixture",verification="live-verified",source="Synthetic tests only",steps={
        {id="item",type="COLLECT_ITEMS",itemId=990100,count=2,text="Fixture inventory"},
        {id="level",type="REACH_LEVEL",level=6,text="Fixture level"}}}
    assert(G:RegisterGuide(guide)); assert(G:Select(guide.id,F.character))
    owned=2; E:Emit("BAG_UPDATE_DELAYED"); drain(); eq(G:Current().id,"level")
    level=6; E:Emit("PLAYER_LEVEL_UP",6); drain(); eq(G.state.finished,true)
end)
test("journal survives relog data restoration without inventing or overwriting records",function()
    local saved=F.modules.SavedVariables.Copy(F.character)
    F.character=saved; F:Command("journal"); eq(G.state.finished,true)
    local raw=F.character.liveJournal; F.character.liveJournal=42
    eq(J:Sync({active={},quests={}}),nil); eq(F.character.liveJournal,42)
    F.character.liveJournal=raw
    GetBuildInfo=function() return "other","other","other",999999 end
    eq(C:Read("snapshot"),nil); eq(G.state.finished,true)
end)
-- Restore the foundation test environment; the real client adapter never changes globals.
for _,name in ipairs(names) do _G[name]=old[name] end
A.enabled=false; A.pending=false; F.snapshot=nil; F.character=originalCharacter
if originalCharacter.selectedGuide then G:Select(originalCharacter.selectedGuide,originalCharacter) end
