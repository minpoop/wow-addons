local passed, failed = 0, 0
local function eq(a,b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
-- Generic candidate UI mock: stateful enough to detect missing text and controls.
local frames, messages = {}, {}
local methods = {}
for _, name in ipairs({"SetWidth","SetHeight","SetPoint","SetFont","SetFontObject","SetJustifyH","SetTextColor","SetFrameStrata","SetMovable","EnableMouse","SetClampedToScreen","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAllPoints","SetColorTexture","SetTexture","ClearAllPoints","SetScale","SetAlpha","SetFrameLevel","SetResizable","SetResizeBounds","SetMinResize","SetMaxResize","StartSizing","EnableMouseWheel","SetScrollChild","SetVerticalScroll","SetRotation","SetVertexColor"}) do
    local key = name
    methods[key] = function(self, ...) self[key .. "Args"] = {...} end
end
function methods:GetStringHeight() return math.max(14, math.ceil(#(self.text or "")/70)*14) end
function methods:GetEffectiveScale() return 1 end
function methods:GetWidth() return self.SetWidthArgs and self.SetWidthArgs[1] or 0 end
function methods:GetHeight() return self.SetHeightArgs and self.SetHeightArgs[1] or 0 end
function methods:SetText(value) self.text = value end
function methods:GetPoint() return "CENTER",UIParent,"CENTER",12,34 end
function methods:Show() self.shown = true end
function methods:Hide()
    local shown=self.shown; self.shown=false
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterEvent(name) self.events[name] = nil end
local function object()
    return setmetatable({scripts={},events={},shown=true}, {__index=methods})
end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function CreateFrame(kind, name, parent)
    local frame = object(); frames[#frames+1] = frame; return frame
end
UIParent, SlashCmdList = object(), {}
DEFAULT_CHAT_FRAME = { AddMessage=function(_,message) messages[#messages+1] = message end }
function UnitGUID() return "fixture-character" end
function GetBuildInfo() return "fixture-version", "fixture-build", "fixture-date", 999999 end
local function loadAddon()
    local file = assert(io.open("ForeverXP/ForeverXP.toc"))
    for line in file:lines() do
        if line:match("%.lua$") then assert(loadfile("ForeverXP/" .. line))() end
    end
    file:close()
end
loadAddon()
local F = ForeverXP
local E, C, D, G, V, M, P, U = F.modules.Events,F.modules.Compatibility,F.modules.SavedVariables,F.modules.GuideEngine,F.modules.StepValidator,F.modules.MaterialCalculator,F.modules.ProfessionPlanner,F.modules.MainWindow
test("unverified client blocks providers, missing and throwing API calls are safe",function()
    eq(C:Read("snapshot"),nil)
    eq(pcall(function() C:RegisterProvider("snapshot",function() return {} end) end),false)
    eq(C:Call("NotAGameAPI"),nil)
    _G.BrokenCandidate = function() error("API failure") end
    eq(C:Call("BrokenCandidate"),nil)
    eq(C:Build().interface,999999); eq(C:Build().verified,false)
end)
test("event bridge loads only matching addon, initializes UI and saves",function()
    E.frame.scripts.OnEvent(E.frame,"ADDON_LOADED","AnotherAddon"); eq(F.initialized,nil)
    E.frame.scripts.OnEvent(E.frame,"ADDON_LOADED","ForeverXP")
    eq(F.initialized,true); eq(F.persistent,true); eq(ForeverXPDB.schema,1)
    eq(U.heading.text,"Your next chapter"); assert(U.frame:IsShown())
    local count = #frames; F:Initialize(); E:Start(); eq(#frames,count)
end)
test("event subscriptions deduplicate, isolate failures and unregister",function()
    local calls = 0
    E:On("TEST","one",function() calls=calls+1 end)
    E:On("TEST","one",function() calls=calls+2 end)
    E:On("TEST","bad",function() error("expected fixture error") end)
    E:Emit("TEST"); eq(calls,2)
    E:Off("TEST","one"); E:Off("TEST","bad"); eq(E.frame.events.TEST,nil)
end)
test("unknown schema and corruption preserve original with session isolation",function()
    local original = {schema=99,characters={secretProgress=42}}
    local db = D:Open(original); eq(D.readOnly,true); eq(original.characters.secretProgress,42)
    db.characters.fixture = {}; eq(original.characters.fixture,nil)
    D:Open("bad"); eq(D.readOnly,true)
    D:Open({schema=1,settings={},characters="bad"}); eq(D.readOnly,true)
    D:Open(nil)
end)
test("legacy migration retains backup and character separation",function()
    local old = {schema=0,settings={},characters={}}
    local db = D:Open(old); eq(db.schema,1); eq(db.migrationBackup.schema,0); eq(old.schema,0)
    local a = D:Character(db,"A"); local b = D:Character(db,"B")
    a.guides.x=1; eq(b.guides.x,nil)
    local session,persistent = D:Character(db,nil); eq(persistent,false); eq(next(session.guides),nil)
    db.characters.bad = "original"; local _, safe = D:Character(db,"bad"); eq(safe,false); eq(db.characters.bad,"original")
end)
test("settings validate finite values, clamp ranges and persist",function()
    local s = F.modules.Settings:Load({scale=math.huge,opacity=-1,integration="invalid"})
    eq(s.scale,1); eq(s.opacity,0.25); eq(s.integration,"disabled")
    F:Command("scale 12"); eq(F.settings.scale,1.8)
    F:Command("opacity 0.8"); eq(F.db.settings.opacity,0.8)
    F:Command("scale 1"); F:Command("settings"); assert(U.body.text:find("Preferences") == nil)
    U:SavePosition(); eq(F.character.windows.main.x,12)
    F:Command("compact"); eq(U.frame.SetHeightArgs[1],U.height); F:Command("compact")
end)
-- All identifiers below are synthetic fixtures, never shipped as playable guides.
local function guide()
    return {id="fixture",title="Synthetic test",steps={
        {id="accept",type="ACCEPT_QUEST",questId=990001,text="Fixture accept"},
        {id="complete",type="COMPLETE_QUEST",questId=990001,text="Fixture complete",prerequisites={"accept"}},
        {id="turnin",type="TURN_IN_QUEST",questId=990001,text="Fixture turn-in"},
        {id="manual",type="MANUAL_INSTRUCTION",text="Fixture manual",optional=true}}}
end
test("guide schema rejects executable data, duplicates and forward prerequisites",function()
    local g=guide(); eq(V:Guide(g,false),true); eq(V:Guide(g,true),false)
    g.steps[2].id="accept"; eq(V:Guide(g,false),false)
    g=guide(); g.steps[1].prerequisites={"complete"}; eq(V:Guide(g,false),false)
    g=guide(); g.code=function() end; eq(V:Guide(g,false),nil)
    g=guide(); g.loop=g; eq(V:Guide(g,false),nil)
    g=guide(); g.steps[1].waypoint={zone="fixture-zone",x=2,y=0}; eq(V:Guide(g,false),false)
    for kind in pairs(V.types) do assert(type(kind)=="string") end
end)
local function registerFixture()
    local g=guide(); g.verification="live-verified"; g.source="mock test only; NOT live evidence"
    -- Only tests make this assertion to exercise the registry. No addon content does.
    assert(G:RegisterGuide(g)); return g
end
test("guide events track acceptance, completion and positive turn-in evidence",function()
    registerFixture(); assert(G:Select("fixture",F.character))
    G:Update({quests={}}); eq(G:Current().id,"accept")
    G:Update({quests={[990001]={accepted=true}}}); eq(G:Current().id,"complete")
    G:Update({quests={[990001]={complete=true}}}); eq(G:Current().id,"turnin")
    G:Update({quests={}}); eq(G:Current().id,"turnin") -- disappearance is NOT turn-in
    G:Update({quests={[990001]={turnedIn=true}}}); eq(G:Current().id,"manual")
    eq(G:Complete(G:Current(),{}),nil)
end)
test("manual review, optional skip, reload and guide completion persist",function()
    G:Back(); eq(G:Current().id,"turnin"); eq(G.state.review,true)
    G:Update({quests={[990001]={turnedIn=true}}}); eq(G:Current().id,"turnin")
    G:Advance(true); eq(G.state.overrides.turnin,"confirmed")
    assert(G:Skip()); eq(G.state.finished,true); eq(G.state.overrides.manual,"skipped")
    local db=D:Open(ForeverXPDB); local character=D:Character(db,"fixture-character")
    assert(G:Select("fixture",character)); eq(G:Current(),nil); eq(G.state.finished,true)
end)
test("recovery recommends evidence only, never mutates or skips unknown",function()
    local character={guides={},professions={},windows={}}
    assert(G:Select("fixture",character))
    local suggestions=G:Recovery({quests={[990001]={complete=true}}})
    eq(#suggestions,2); eq(G:Current().id,"accept"); eq(next(G.state.completed),nil)
    eq(G:Skip(),nil)
    character.guides.fixture.current="removed-step"; eq(G:Select("fixture",character),nil)
end)
test("character-aware recommendations use authored content and deterministic ties",function()
    G.guides.fixture.faction="Alliance"; G.guides.fixture.minLevel=10
    eq(G:Recommend({faction="Horde",level=20}),nil)
    eq(G:Recommend({faction="Alliance",level=1}),nil)
    eq(G:Recommend({faction="Alliance",level=10}).id,"fixture")
end)
test("collect, level and profession evidence distinguish unknown from false",function()
    eq(G:Complete({type="COLLECT_ITEMS",itemId=1,count=3},{items={[1]=2}}),false)
    eq(G:Complete({type="COLLECT_ITEMS",itemId=1,count=3},{items={[1]=3}}),true)
    eq(G:Complete({type="REACH_LEVEL",level=3},{level=4}),true)
    eq(G:Complete({type="REACH_PROFESSION_SKILL",profession="fixture",skill=3},{professions={fixture=3}}),true)
    eq(G:Complete({type="TRAVEL_TO",id="travel"},{observed={travel=true}}),true)
end)
local recipes={bar={output="bar",outputCount=2,inputs={ore=3},station="fixture-station"},
    tool={output="tool",outputCount=1,inputs={bar=3,flux=1},vendor={flux=true}},
    ring={output="ring",outputCount=1,inputs={bar=1}}}
test("material dependencies share inventory and intermediate surplus",function()
    local result=assert(M:Calculate({tool=1,ring=1},recipes,{bar=1,ore=1},{bar="bar"}))
    eq(result.missing.ore,5); eq(result.missing.flux,1); eq(result.crafts.bar,2)
    eq(result.used.bar,1); eq(result.used.ore,1); eq(result.vendor.flux,true)
    eq(result.stations["fixture-station"],true)
end)
test("crafted intermediate leftovers are reused across recipes",function()
    local r={bar={output="bar",outputCount=3,inputs={ore=2}},
        a={output="a",outputCount=1,inputs={bar=2}},b={output="b",outputCount=1,inputs={bar=1}}}
    local result=assert(M:Calculate({a=1,b=1},r,{}, {bar="bar"}))
    eq(result.crafts.bar,1); eq(result.missing.ore,2); eq(result.used.bar,0)
end)
test("material calculator detects cycles, bad quantities and producer mismatch",function()
    local cycle={a={output="a",outputCount=1,inputs={b=1}},b={output="b",outputCount=1,inputs={a=1}}}
    local result,err=M:Calculate({a=1},cycle,{}, {a="a",b="b"}); eq(result,nil); assert(err:find("cycle"))
    eq(M:Calculate({a=1},cycle,{b=99}, {a="a",b="b"}),nil)
    eq(M:Calculate({tool=-1},recipes,{},{}),nil)
    eq(M:Calculate({tool=1},recipes,{ore=-1},{}),nil)
    eq(M:Calculate({ring=1},recipes,{}, {bar="tool"}),nil)
end)
test("profession modes share state and split verified hybrid opportunities",function()
    local character={professions={}}; local state=P:State(character,"fixture"); state.target=100
    local materials={missing={ore=5,flux=1}}
    assert(P:SetMode(state,"Farm")); eq(P:Distribute(materials,state).farm.ore,5)
    assert(P:SetMode(state,"Buy")); local buy=P:Distribute(materials,state,nil,{ore=2})
    eq(buy.buy.ore,5); eq(buy.cost,10); eq(buy.costComplete,false)
    assert(P:SetMode(state,"Hybrid"))
    local hybrid=P:Distribute(materials,state,{ore={verified=true,route="fixture-route"}}, {flux=3})
    eq(hybrid.farm.ore,5); eq(hybrid.buy.flux,1); eq(hybrid.cost,3); eq(state.target,100)
    eq(P:SetMode(state,"invalid"),nil)
    local estimate=P:Estimate(5,0.5,0.2); eq(estimate.guaranteed,nil); eq(estimate.expected,10); eq(estimate.conservative,12)
    eq(P:Estimate(5,1,0).guaranteed,5); eq(P:Estimate(5,0,0),nil)
end)
test("waypoints degrade to coordinates, reject invalid numbers and clear",function()
    local w=F.modules.Waypoints
    eq(w:Set({zone="fixture",x=0.25,y=0.75}),true); assert(w:Text():find("25.0"))
    eq(w:Set({zone="fixture",x=0/0,y=0.5}),nil)
    eq(w:Set(nil),true); eq(w:Text(),"No waypoint")
end)
assert(loadfile("Tests/planning.lua"))(F,test,eq)
assert(loadfile("Tests/tracking.lua"))(F,test,eq)
assert(loadfile("Tests/routing.lua"))(F,test,eq)
assert(loadfile("Tests/recovery.lua"))(F,test,eq)
assert(loadfile("Tests/campaign.lua"))(F,test,eq)
assert(loadfile("Tests/campaign_full.lua"))(F,test,eq)
assert(loadfile("Tests/themes.lua"))(F,test,eq)
assert(loadfile("Tests/profession_guides.lua"))(F,test,eq)
assert(loadfile("Tests/interface.lua"))(F,test,eq)
assert(loadfile("Tests/navigation.lua"))(F,test,eq)
assert(loadfile("Tests/horde.lua"))(F,test,eq)
assert(loadfile("Tests/advice.lua"))(F,test,eq)
assert(loadfile("Tests/route_plan.lua"))(F,test,eq)
assert(loadfile("Tests/run_tracker.lua"))(F,test,eq)
test("reset requires two commands and keeps a backup without deleting other characters",function()
    F.character.guides.saved="keep"; F.db.characters.other={guides={x=1},professions={},windows={}}
    F:Command("reset confirm"); eq(F.character.guides.saved,"keep")
    F:Command("reset confirm"); eq(F.character.guides.saved,nil)
    eq(F.character.resetBackup.guides.saved,"keep"); eq(F.db.characters.other.guides.x,1)
end)
test("missing UI and identity remain safe; future schema stays untouched on initialization",function()
    local create, guid, raw = CreateFrame, UnitGUID, {schema=99,characters={important=true}}
    CreateFrame,UnitGUID,ForeverXPDB=nil,nil,raw
    loadAddon(); ForeverXP:Initialize()
    eq(ForeverXPDB,raw); eq(ForeverXP.persistent,false)
    eq(ForeverXP.modules.MainWindow.frame,nil)
    CreateFrame,UnitGUID=create,guid
end)
print(string.format("%d passed; %d failed (mocked Lua 5.1; no live-client validation)",passed,failed))
assert(failed == 0, "test suite failed")
