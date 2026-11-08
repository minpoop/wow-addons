local F,test,eq=...
local A,U,G,S,M=F.modules.QuestAdvice,F.modules.MainWindow,F.modules.GuideEngine,F.modules.Settings,F.modules.ContextMenu
local old={snapshot=F.snapshot,loading=F.modules.ForeverAdapter.loading,tips=F.settings.questTips,warnings=F.settings.questWarnings,
    guide=G.guide,index=G.index,state=G.state,character=F.character,tab=U.tab,width=U.width,height=U.height,theme=F.settings.theme}
F.modules.ForeverAdapter.loading=false;F.settings.questTips=true;F.settings.questWarnings=true
local function step(id,phase,level) return {questId=id,type=phase or "COMPLETE_QUEST",questLevel=level} end
local function warning(advice,code)
    for _,row in ipairs(advice.warnings) do if row.code==code then return row end end
end
test("reference advice covers both faction pools and preserves distinct hazard facts",function()
    local count=0;for _ in pairs(A.records) do count=count+1 end;eq(count,1159)
    eq(A.records[176].eliteSource,"Hogger");eq(A.records[87].eliteSource,nil)
    eq(A.records[435].escort,true);eq(A.records[4966].event,true)
    eq(A.records[62].event,nil);eq(A.records[62].cave,true)
end)
test("invalid advice is rejected without replacing the installed reference catalog",function()
    local records=A.records
    eq(A:RegisterReference({[990001]={title="Synthetic",questLevel=1,kind="kill",tips={function() end}}}),nil)
    eq(A:RegisterReference({[990001]={title="Synthetic",questLevel=1,kind="kill",cave="yes"}}),nil)
    eq(A:RegisterReference({[990001]={title="Synthetic",questLevel=1,kind="kill",tips={[2]="Sparse"}}}),nil)
    eq(A.records,records)
end)
test("difficulty thresholds use observed quest levels before authored reference levels",function()
    local s=step(990001,nil,30)
    local snapshot={level=10,quests={[990001]={level=11}}}
    eq(#A:For(s,snapshot).warnings,0)
    snapshot.quests[990001].level=12
    local advice=A:For(s,snapshot);eq(advice.severity,"caution");assert(warning(advice,"level").text:find("Live quest level 12",1,true))
    snapshot.quests[990001].level=14
    advice=A:For(s,snapshot);eq(advice.severity,"danger");eq(advice.badge,"QUEST +4 LEVELS")
    snapshot.quests[990001].level=nil
    assert(warning(A:For(s,snapshot),"level").text:find("Reference quest level 30",1,true))
end)
test("missing levels and unknown quests never produce a guessed safety rating",function()
    eq(#A:For(step(990001),{}).warnings,0);eq(#A:For(step(990001),{}).tips,0)
    eq(#A:For(nil,{}).warnings,0)
    eq(warning(A:For(step(87),{level=0/0}),"level"),nil)
    F.modules.ForeverAdapter.loading=true
    eq(warning(A:For(step(87),{level=1}),"level"),nil)
    F.modules.ForeverAdapter.loading=false
end)
test("elite loot leads warn without claiming every source or optional quest is elite",function()
    local advice=A:For(step(176),{level=11})
    assert(warning(advice,"elite-source").text:find("possible alternative sources",1,true))
    eq(advice.badge,"ELITE LOOT SOURCE")
    eq(warning(A:For(step(87),{level=8}),"elite-source"),nil)
    local optional=step(990001);optional.optional=true
    advice=A:For(optional,{});eq(advice.badge,"OPTIONAL QUEST");eq(warning(advice,"elite"),nil)
end)
test("live elite dungeon raid and PvP tags work outside the reference pool",function()
    for id,code in pairs({[1]="group",[81]="dungeon",[62]="raid",[41]="pvp"}) do
        local advice=A:For(step(990001),{quests={[990001]={tagId=id}}});assert(warning(advice,code))
    end
    assert(warning(A:For(step(990001),{quests={[990001]={isElite=true}}}),"group"))
    eq(#A:For(step(990001),{quests={[990001]={tagId=99999}}}).warnings,0)
end)
test("escort scripted-event and cave guidance are separate warnings",function()
    local escort=A:For(step(435),{});assert(warning(escort,"escort"));eq(warning(escort,"event"),nil)
    local event=A:For(step(4966),{});assert(warning(event,"event"));eq(warning(event,"escort"),nil)
    local mine=A:For(step(62),{});assert(warning(mine,"cave"));eq(warning(mine,"event"),nil)
end)
test("completed objectives and turn-ins suppress combat warnings while failed quests stay visible",function()
    local done=A:For(step(176),{level=1,quests={[176]={complete=true}}});eq(#done.warnings,0);eq(#done.tips,1)
    eq(#A:For(step(176,"TURN_IN_QUEST"),{level=1}).warnings,0)
    eq(#A:For(step(176),{quests={[176]={turnedIn=true}}}).tips,0)
    local failed=A:For(step(176),{quests={[176]={failed=true,complete=true}}})
    eq(failed.badge,"QUEST FAILED");eq(failed.severity,"danger");eq(#failed.warnings,1)
end)
test("tips prefer original quest notes and otherwise use known objective types",function()
    local hogger=A:For(step(176),{})
    assert(hogger.tips[1]:find("Hogger",1,true));assert(hogger.tips[1]:find("Reference tip:",1,true))
    assert(A:For(step(185),{}).tips[1]:find("named targets",1,true))
    local live=A:For(step(990001),{quests={[990001]={objectives={{type="item"}}}}})
    assert(live.tips[1]:find("item names",1,true))
end)
test("optional tag reads cannot interrupt quest tracking on missing malformed or throwing APIs",function()
    local adapter=F.modules.ForeverAdapter
    local build,log,level=GetBuildInfo,C_QuestLog,UnitLevel
    local enabled,loading,baseline=adapter.enabled,adapter.loading,adapter.baseline
    GetBuildInfo=function() return "fixture","fixture","fixture",16001 end
    UnitLevel=function() return 12 end
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,GetInfo=function() return {questID=990001,title="Synthetic quest"} end,
        GetQuestTagInfo=function() return {tagID=81,isElite=true} end}
    adapter.enabled=true;adapter.loading=false;adapter.baseline={}
    local snapshot=assert(adapter:Collect());eq(snapshot.quests[990001].tagId,81);eq(snapshot.quests[990001].isElite,true)
    C_QuestLog.GetQuestTagInfo=function() error("Optional API unavailable") end
    snapshot=assert(adapter:Collect());eq(snapshot.quests[990001].accepted,true);eq(snapshot.quests[990001].tagId,nil)
    C_QuestLog.GetQuestTagInfo=function() return {tagID="localized",isElite="yes"} end
    snapshot=assert(adapter:Collect());eq(snapshot.quests[990001].tagId,nil);eq(snapshot.quests[990001].isElite,nil)
    C_QuestLog.GetQuestTagInfo=nil;assert(adapter:Collect())
    GetBuildInfo,C_QuestLog,UnitLevel=build,log,level
    adapter.enabled,adapter.loading,adapter.baseline=enabled,loading,baseline
end)
test("warning captions stay outside the scroll area and remain legible in every theme",function()
    F.character={guides={},professions={},windows={}}
    local fixture={id="advice-ui-fixture",title="Synthetic advice view",verification="live-verified",source="Offline fixture only",steps={
        {id="task",type="COMPLETE_QUEST",questId=176,text="Synthetic current task."}}}
    assert(G:RegisterGuide(fixture));assert(G:Select(fixture.id,F.character))
    F.snapshot={level=7,quests={[176]={accepted=true}}}
    U:Show("guide");U:ResizeTo(400,300,false)
    local state=G.state;assert(U.eyebrow.text:find("WARNING:",1,true));eq(U.adviceSeverity,"danger")
    assert(U.body.text:find("TIP (REFERENCE):",1,true));assert(U.scrollRange>0)
    eq(U.heading.text,A.records[176].title)
    local function luminance(color)
        local function linear(x) return x<=.04045 and x/12.92 or ((x+.055)/1.055)^2.4 end
        return .2126*linear(color[1])+.7152*linear(color[2])+.0722*linear(color[3])
    end
    for _,choice in ipairs(F.modules.Themes.options) do
        S:Set("theme",choice.id)
        local theme=F.modules.Themes:Get()
        for _,color in ipairs({theme.warning,theme.danger}) do
            local a,b=luminance(color),luminance(theme.card)
            assert((math.max(a,b)+.05)/(math.min(a,b)+.05)>=4.5)
        end
        eq(U.eyebrow.SetTextColorArgs[1],theme.danger[1])
    end
    U:Scroll(-100);assert(U.eyebrow.text:find("WARNING:",1,true))
    eq(G.state,state);eq(state.completed.task,nil);eq(state.current,"task")
end)
test("right-click toggles independently persist tips and warnings without changing progress",function()
    local state=G.state
    M:Open("advice");assert(M:Invoke("quest-tips"));eq(F.settings.questTips,false);eq(F.settings.questWarnings,true)
    eq(#A:For(step(176),{}).tips,0);assert(A:For(step(176),{}).badge)
    M:Open("advice");assert(M:Invoke("quest-warnings"));eq(F.settings.questWarnings,false)
    eq(A:For(step(176),{}).badge,nil);eq(U.adviceSeverity,nil)
    eq(S:Load(F.db.settings).questWarnings,false);eq(S:Load({}).questTips,true)
    eq(G.state,state);eq(state.completed.task,nil)
end)
M:Close()
F.character,F.snapshot=old.character,old.snapshot
G.guide,G.index,G.state=old.guide,old.index,old.state
F.modules.ForeverAdapter.loading=old.loading
S:Set("questTips",old.tips);S:Set("questWarnings",old.warnings);S:Set("theme",old.theme)
U:ResizeTo(old.width,old.height,false);U:Show(old.tab)
