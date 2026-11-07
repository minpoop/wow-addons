local F,test,eq=...
local G,R=F.modules.GuideEngine,F.modules.RecoveryEngine
local originalCharacter,originalAuto,originalRecovery=F.character,F.settings.autoAdvance,F.settings.recovery
local function begin(snapshot)
    F.character={guides={},professions={},windows={}}
    F.settings.autoAdvance,F.settings.recovery=true,"suggest"
    assert(G:Select("elwynn-forest-shared",F.character))
    if snapshot then G:Update(snapshot) end
end
test("Elwynn automatically catches up to an accepted Goldshire quest without manual steps",function()
    begin({active={62},level=6,quests={[62]={accepted=true,complete=false}}})
    eq(G:Current().id,"quest-62-complete")
    eq(G.state.completed["quest-62-accept"],true)
    eq(G.state.completed["reference-intro"],nil)
    eq(G.state.completed["quest-783-turn-in"],nil)
    assert(G.state.resume.deferred>0)
    eq(G.state.resume.reason,"a quest already in your log")
end)
test("completed active quest selects its turn-in while historical flags reconcile earlier work",function()
    begin({active={87},level=7,quests={[87]={accepted=true,complete=true},[783]={turnedIn=true}}})
    eq(G:Current().id,"quest-87-turn-in")
    eq(G.state.completed["quest-87-complete"],true)
    eq(G.state.completed["quest-783-accept"],true)
    eq(G.state.completed["quest-783-turn-in"],true)
    eq(G.state.completed["quest-85-turn-in"],nil)
end)
test("tracked or selected route quest takes priority over an unrelated earlier active quest",function()
    begin({active={7,62},trackedQuestId=62,level=6,quests={[7]={accepted=true},[62]={accepted=true}}})
    eq(G:Current().id,"quest-62-complete")
    G:Update({active={7,62},trackedQuestId=7,level=6,quests={[7]={accepted=true},[62]={accepted=true}}})
    eq(G:Current().id,"quest-7-complete")
    begin({active={7,62},trackedQuestId=999999,selectedQuestId=62,level=6,quests={[7]={accepted=true},[62]={accepted=true}}})
    eq(G:Current().id,"quest-62-complete")
end)
test("fresh objective activity changes the target without repeatedly following a stale signal",function()
    local s={active={7,62},level=6,quests={[7]={accepted=true},[62]={accepted=true}}}
    begin(s); eq(G:Current().questId,7)
    s.signalRevision,s.signalQuestId=1,62; G:Update(s); eq(G:Current().questId,62)
    s.quests[62].complete=true; G:Update(s); eq(G:Current().id,"quest-62-turn-in")
    s.signalRevision,s.signalQuestId=2,7; G:Update(s); eq(G:Current().questId,7)
end)
test("history-only catch-up finds the next eligible hub without inventing older completion",function()
    begin({active={},level=6,quests={[54]={turnedIn=true}}})
    eq(G:Current().id,"quest-62-accept")
    eq(G.state.completed["quest-54-turn-in"],true)
    eq(G.state.completed["quest-7-turn-in"],nil)
    eq(G.state.completed["goldshire-training"],nil)
end)
test("empty or invalid quest data does not jump ahead based on level alone",function()
    begin(); local current=G:Current().id
    G:Update({level=10}); eq(G:Current().id,current)
    G:Update({quests={},active={},level=10}); eq(G:Current().id,current)
    G:Update({quests={[62]={accepted=true}},active=true,level=10}); eq(G:Current().id,current)
    eq(G.state.completed["quest-62-accept"],nil)
end)
test("back, disabled auto advance, disabled recovery and undo preserve player control",function()
    local s={active={62},level=6,quests={[62]={accepted=true}}}
    begin(); F.settings.autoAdvance=false; G:Update(s); eq(G:Current().id,"reference-intro")
    F.settings.autoAdvance=true; F.settings.recovery="disabled"; G:Update(s); eq(G:Current().id,"reference-intro")
    F.settings.recovery="suggest"; G:Update(s); eq(G:Current().id,"quest-62-complete")
    assert(R:Undo(G)); eq(G:Current().id,"reference-intro"); eq(G.state.review,true)
    G:Update(s); eq(G:Current().id,"reference-intro")
    eq(G.state.completed["quest-62-accept"],true)
end)
test("resume keeps explicit overrides and saved IDs through relog restoration",function()
    local s={active={62},level=6,quests={[62]={accepted=true}}}
    begin(s); G.state.overrides["reference-intro"]="confirmed"; G.state.completed["reference-intro"]=true
    local saved=F.modules.SavedVariables.Copy(F.character)
    F.character=saved; assert(G:Select("elwynn-forest-shared",saved)); G:Update(s)
    eq(G:Current().id,"quest-62-complete"); eq(G.state.overrides["reference-intro"],"confirmed")
    eq(G.state.completed["quest-7-turn-in"],nil)
    saved.guides["elwynn-forest-shared"].resume.deferred="bad"
    eq(G:Select("elwynn-forest-shared",saved),nil)
    eq(saved.guides["elwynn-forest-shared"].resume.deferred,"bad")
end)
test("Elwynn command and later refreshes automatically relocate using live-provider snapshots",function()
    local C=F.modules.Compatibility
    local provider,evidence,previous=C.providers.snapshot,C.inspected.snapshot,F.snapshot
    local s={active={62},level=6,quests={[62]={title="The Fargodeep Mine",accepted=true,complete=false}}}
    C:RegisterInspectedProvider("snapshot",function() return s end,"Synthetic integration fixture")
    begin(); F:Command("elwynn")
    eq(G:Current().id,"quest-62-complete")
    eq(G.state.completed["quest-783-turn-in"],nil)
    assert(F.modules.MainWindow.body.text:find("step "..G.index,1,true))
    s.quests[62].complete=true; F.modules.Events:Emit("FXP_STATE_CHANGED")
    eq(G:Current().id,"quest-62-turn-in")
    local current=G:Current().id
    C.providers.snapshot=function() error("fixture temporary API error") end
    F:Command("resume"); eq(G:Current().id,current)
    C.providers.snapshot,C.inspected.snapshot,F.snapshot=provider,evidence,previous
end)
F.settings.autoAdvance,F.settings.recovery=originalAuto,originalRecovery
F.character=originalCharacter
if originalCharacter.selectedGuide then G:Select(originalCharacter.selectedGuide,originalCharacter) end
