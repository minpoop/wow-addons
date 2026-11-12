-- Minimal WoW stub environment to execute ForeverXP and test step logic.
local ROOT = arg_root
local noop = function() end
ALLOBJ = {}
function Obj()
  local o = { _scripts = {} }
  ALLOBJ[#ALLOBJ + 1] = o
  o.SetScript = function(self, n, fn) self._scripts[n] = fn end
  o.HookScript = function(self, n, fn) self._scripts[n] = fn end
  o.GetScript = function(self, n) return self._scripts[n] end
  o.CreateTexture = function() return Obj() end
  o.CreateFontString = function() return Obj() end
  o.IsShown = function() return true end
  o.GetText = function() return "" end
  return setmetatable(o, { __index = function(t, k)
    if type(k) == "string" and k:match("^Get") then return function() return 100 end end
    if type(k) == "string" and k:match("^%u") then return function(...) return nil end end
    return nil
  end })
end
unpack = unpack or table.unpack
CreateFrame = function() return Obj() end
UIParent = Obj(); Minimap = Obj(); UISpecialFrames = {}; SlashCmdList = {}
BackdropTemplateMixin = {}
C_Timer = { After = noop, NewTicker = function() return { Cancel = noop } end }
C_Map = { GetBestMapForUnit = function() return nil end, GetMapInfo = function() return nil end,
  GetPlayerMapPosition = function() return nil end, GetWorldPosFromMapPos = function() return nil end }
GetTime = function() return 100 end
GetMoney = function() return 954321 end
print = function(...) io.write(table.concat({ ... }, " "), "\n") end
PLAYER = { level = 1, class = "HUNTER", race = "Human", faction = "Alliance" }
UnitLevel = function() return PLAYER.level end
UnitClass = function() return PLAYER.class:lower(), PLAYER.class end
UnitRace = function() return PLAYER.race, PLAYER.race end
UnitFactionGroup = function() return PLAYER.faction end
UnitXP = function() return 0 end; UnitXPMax = function() return 1000 end
GetMaxPlayerLevel = function() return 60 end
QS = { done = {}, on = {}, comp = {} }
C_QuestLog = {
  IsQuestFlaggedCompleted = function(id) return QS.done[id] end,
  IsOnQuest = function(id) return QS.on[id] end,
  IsComplete = function(id) return QS.comp[id] end,
  GetLogIndexForQuestID = function() return nil end,
  GetNumQuestLogEntries = function() return 0 end,
}
SKILLS = {}
GetNumSkillLines = function() return #SKILLS end
GetSkillLineInfo = function(i) return SKILLS[i] end
IsMounted = function() return false end
COMBAT = false
InCombatLockdown = function() return COMBAT end
MACROS = {}
GetMacroIndexByName = function(n) for i, m in ipairs(MACROS) do if m.name == n then return i end end return 0 end
GetNumMacros = function() return 0, #MACROS end
CreateMacro = function(n, icon, body) MACROS[#MACROS + 1] = { name = n, body = body }; return #MACROS end
EditMacro = function(i, n, icon, body) MACROS[i].body = body end
UnitName = function(u) return nil end
UnitExists = function(u) return false end
C_NamePlate = { GetNamePlates = function() return {} end }

local ns = {}
local files = { "Compat.lua", "Data/QuestDB.lua", "Data/ClassQuests.lua", "Data/Dungeons.lua", "Core.lua", "Questie.lua",
  "UI.lua", "Themes.lua", "Arrow.lua", "Targeting.lua", "Options.lua", "DungeonUI.lua", "Guides/Human_Northshire.lua", "Guides/Elwynn_6-10.lua",
  "Guides/Alliance_Starts.lua", "Guides/Alliance_10-30.lua", "Guides/Alliance_30-60.lua", "Guides/Alliance_Extra.lua" }
for _, f in ipairs(files) do
  local chunk, err = loadfile(ROOT .. "/" .. f)
  if not chunk then error(err) end
  local ok, e = pcall(chunk, "ForeverXP", ns)
  if not ok then error(f .. ": " .. tostring(e)) end
end
local FXP = ns.FXP
local fails = 0
local function check(cond, msg) if not cond then fails = fails + 1; print("FAIL: " .. msg) else print("ok   " .. msg) end end

-- db defaults
FXP.db = { step = 1, trained = {}, catchUp = true, skipGroup = false }

-- fake quest resolution
local ids, nextId, unavailable = {}, 1000, {}
FXP.Resolve = function(self, q)
  if type(q) == "number" then return q end
  if not ids[q] then nextId = nextId + 1; ids[q] = nextId end
  return ids[q]
end
FXP.Unavailable = function(self, id, q) return unavailable[q] or false end

print(("guides: %d"):format(#FXP.guideOrder))
-- 1. class step injection
local function countClass(g, cls)
  local n = 0
  for _, s in ipairs(FXP.guides[g].steps) do
    if s.classStep and s.class[1] == cls then n = n + 1 end
  end
  return n
end
check(countClass("Westfall 10-14", "HUNTER") == 2, "hunter L10 block injected into Westfall 10-14")
check(countClass("Elwynn Forest 6-10", "HUNTER") == 0, "no L10 block in Elwynn 6-10 (half-open range)")
check(countClass("Dun Morogh 6-11", "HUNTER") == 2, "hunter block in Dun Morogh 6-11")
check(countClass("Coldridge Valley 1-6", "SHAMAN") == 2, "shaman L4 block in Coldridge")
-- keys unique per guide
for _, n in ipairs(FXP.guideOrder) do
  local seen = {}
  for _, s in ipairs(FXP.guides[n].steps) do
    if seen[s.key] then fails = fails + 1; print("FAIL dup key " .. s.key) end
    seen[s.key] = true
  end
end

-- 2. render every step for every guide (catches runtime errors in StepText/StepCoords)
local rendered, errs = 0, 0
for _, n in ipairs(FXP.guideOrder) do
  FXP.guide = FXP.guides[n]
  for i, s in ipairs(FXP.guide.steps) do
    local ok, e = pcall(FXP.StepText, FXP, s, true)
    rendered = rendered + 1
    if not ok then errs = errs + 1; print("RENDER ERROR " .. n .. " #" .. i .. ": " .. tostring(e)) end
    local ok2, e2 = pcall(FXP.IsStepDone, FXP, s)
    if not ok2 then errs = errs + 1; print("DONE ERROR " .. n .. " #" .. i .. ": " .. tostring(e2)) end
  end
end
check(errs == 0, ("rendered + evaluated %d steps without errors"):format(rendered))

-- 3. class filter
local g = FXP.guides["Westfall 10-14"]
local hunterStep
for _, s in ipairs(g.steps) do if s.classStep and s.anyQuest then hunterStep = hunterStep or (s.class[1] == "HUNTER" and s) end end
PLAYER.level = 10; PLAYER.class = "WARRIOR"
check(FXP:IsStepDone(hunterStep) == true, "hunter step skipped for a warrior")
PLAYER.class = "HUNTER"
check(FXP:IsStepDone(hunterStep) == false, "hunter step waits for a hunter without the quest")
QS.on[FXP:Resolve("Taming the Beast#1")] = true
check(FXP:IsStepDone(hunterStep) == true, "hunter step done once Taming the Beast is on the log")
PLAYER.level = 9; QS.on = {}
check(FXP:IsStepDone(hunterStep) == true, "hunter step skipped below level 10")
-- anyQuest all unavailable -> skipped
PLAYER.level = 10; unavailable["Taming the Beast#1"] = true
check(FXP:IsStepDone(hunterStep) == true, "anyQuest step skipped when the game has none of the quests")
unavailable = {}

-- 4. chain turn-in step waits through the chain
local chainStep
for _, s in ipairs(g.steps) do if s.classStep and s.turnin and #s.turnin > 0 and s.class[1] == "HUNTER" then chainStep = s end end
QS.done[FXP:Resolve("Taming the Beast#1")] = true
check(FXP:IsStepDone(chainStep) == false, "hunter chain step not done after only part 1")
for _, q in ipairs(chainStep.turnin) do QS.done[FXP:Resolve(q)] = true end
check(FXP:IsStepDone(chainStep) == true, "hunter chain step done after the whole chain")

-- 5. mount stop by race
local bad = FXP.guides["Badlands 38-40"]
local mounts = {}
for _, s in ipairs(bad.steps) do if s.mount then mounts[#mounts + 1] = s end end
check(#mounts == 5, "five race-specific mount steps")
PLAYER.level = 40; PLAYER.race = "Dwarf"
local dwarfPending = 0
for _, s in ipairs(mounts) do if not FXP:IsStepDone(s) then dwarfPending = dwarfPending + 1 end end
check(dwarfPending == 1, "exactly one mount step shows for a Dwarf")
SKILLS = { "Riding" }
local after = 0
for _, s in ipairs(mounts) do if not FXP:IsStepDone(s) then after = after + 1 end end
check(after == 0, "mount step completes once Riding is learned")
check(FXP:StepText(mounts[1], true):find("95g") ~= nil, "mount step shows your gold (95g)")

-- 6. PickGuide by race and level
local function pick(race, lvl) PLAYER.race = race; PLAYER.level = lvl; return FXP:PickGuide() end
check(pick("Human", 1) == "Northshire 1-6", "Human 1 -> Northshire")
check(pick("Dwarf", 1) == "Coldridge Valley 1-6", "Dwarf 1 -> Coldridge")
check(pick("Gnome", 8) == "Dun Morogh 6-11", "Gnome 8 -> Dun Morogh")
check(pick("NightElf", 1) == "Shadowglen 1-6", "Night Elf 1 -> Shadowglen")
check(pick("NightElf", 13) == "Darkshore 11-16", "Night Elf 13 -> Darkshore")
check(pick("Skyborne", 1) == "Zephras Isle 1-12", "Skyborne 1 -> Zephras Isle")
local p = pick("Human", 49)
check(not FXP.guides[p].side, "side guides never auto-picked (Human 49 -> " .. tostring(p) .. ")")

-- 7. chains
for _, start in ipairs({ "Northshire 1-6", "Coldridge Valley 1-6", "Shadowglen 1-6", "Zephras Isle 1-12" }) do
  local cur, n, path = start, 0, {}
  while cur and n < 60 do
    check(FXP.guides[cur] ~= nil, "guide exists: " .. cur); n = n + 1; path[#path + 1] = cur
    cur = FXP.guides[cur].next
  end
  print("   " .. start .. ": " .. n .. " guides -> " .. path[#path])
end

-- 8. dungeon window text
local ok, txt = pcall(FXP.DungeonText, FXP, true)
check(ok and txt:find("Krol'dok") ~= nil, "dungeon text renders (all dungeons)")
PLAYER.level = 25
local ok2, txt2 = pcall(FXP.DungeonText, FXP, false)
check(ok2 and txt2:find("Stockade") and not txt2:find("Stratholme"), "dungeon list filtered by level")

-- 9. themes
FXP.db.theme = "classic"; FXP.db.scale = 1; FXP.db.upcoming = 2
FXP:BuildUI()
check(FXP.theme and FXP.theme.key == "classic", "UI builds with the Classic theme")
FXP.guide = FXP.guides["Westfall 10-14"]; FXP.db.step = 3
for _, th in ipairs(ns.Themes) do
  FXP.db.theme = th.key
  local ok, e = pcall(function()
    FXP:ApplyTheme()
    local fx = FXP.frame.fx
    local upd = fx:GetScript("OnUpdate")
    for i = 1, 200 do upd(fx, 0.05) end
    FXP:FlashUI()
    for i = 1, 60 do upd(fx, 0.05) end
    FXP:RefreshUI()
    for _, s in ipairs(FXP.guide.steps) do FXP:StepText(s, true) end
  end)
  check(ok, "theme runs: " .. th.label .. (ok and "" or (" -> " .. tostring(e))))
  check(FXP.theme.key == th.key, "theme applied: " .. th.label)
end
FXP.db.theme = "ashen"; FXP:ApplyTheme()
local fired = 0
for _, o in ipairs(ALLOBJ) do
  local h = o._scripts.OnEvent
  if h then
    local ok, e = pcall(h, o, "PLAYER_DEAD"); if not ok then print("banner err " .. tostring(e)) else fired = fired + 1 end
    pcall(h, o, "PLAYER_LEVEL_UP")
  end
end
check(fired > 0, "death / level-up banner events run")
FXP.db.theme = "imperial"; FXP:ApplyTheme()
local imp = FXP:StepText({ text = "x", key = "t" }, true)
check(imp:find("Thought for the day") ~= nil, "Imperial shows a thought for the day")
local sp = (function() FXP.db.theme = "spartan"; FXP:ApplyTheme(); return FXP:StepText({ warn = "w", tip = "t", key = "k" }, true) end)()
check(sp:find("WARNING") and sp:find("INTEL"), "Spartan relabels warnings and tips")

-- 9b. new themes: Ascension tiers, level-up re-skin, preview, Blocky burst, Abyssal danger
local function tick(n) local fx = FXP.frame.fx; local upd = fx:GetScript("OnUpdate"); for i = 1, n or 40 do upd(fx, 0.05) end end
FXP.db.theme = "ascend"; FXP.db.ascendPreview = nil; FXP.levelSeen = nil
local tiersOk = true
for _, case in ipairs({ { 1, 1, "Cave" }, { 4, 1, "Cave" }, { 5, 2, "Forest Floor" }, { 29, 6, "Mountain Foothills" },
    { 30, 7, "Mountain Lake" }, { 59, 12, "Aurora" }, { 60, 13, "Galactic Core" } }) do
  PLAYER.level = case[1]; FXP:ApplyTheme(); tick(30)
  if FXP.theme.tierIndex ~= case[2] or FXP.theme.name ~= case[3] then
    tiersOk = false; print("tier mismatch at level " .. case[1] .. ": " .. tostring(FXP.theme.name))
  end
end
check(tiersOk, "Ascension picks the right tier every 5 levels")
check(FXP.theme.key == "ascend" and FXP.theme.prismatic and FXP.theme.tex == "asc_12", "Ascension top tier is prismatic with its own texture")
PLAYER.level = 9; FXP.levelSeen = nil; FXP:ApplyTheme()
local lvlHandlers = {}
for _, o in ipairs(ALLOBJ) do if o._scripts.OnEvent then lvlHandlers[#lvlHandlers + 1] = o._scripts.OnEvent end end
for _, h in ipairs(lvlHandlers) do pcall(h, nil, "PLAYER_LEVEL_UP", 10) end
check(FXP.theme.tierIndex == 3 and FXP.theme.name == "Old Woods", "Ascension re-skins on the level-up that reaches a new tier")
FXP:PreviewAscension("47")
check(FXP.db.ascendPreview == 47 and FXP.theme.name == "Starfield", "/fxp tier previews a level")
FXP:PreviewAscension("")
check(FXP.db.ascendPreview == nil and FXP.theme.name == "Old Woods", "/fxp tier with no level goes back to live")
FXP.levelSeen = nil; PLAYER.level = 1
FXP.db.theme = "blocky"; FXP:ApplyTheme(); FXP:FlashUI(); tick(2)
local flying = 0
for _, p in ipairs(FXP.frame.fx.parts) do if p.life > 0 and not p.orb then flying = flying + 1 end end
check(flying > 10, "Blocky bursts into block fragments on completion")
FXP.db.theme = "abyss"; FXP:ApplyTheme()
local darkA = 0
FXP.frame.fx.dark.SetAlpha = function(_, a) darkA = a end
FXP.guide.steps[FXP.db.step].warn = FXP.guide.steps[FXP.db.step].warn or "test danger"
tick(5)
check(darkA > 0.2, "Abyssal darkness thickens on a danger step")
FXP.db.theme = "wow"; FXP:ApplyTheme()
check(FXP.theme.tileSize == 64, "Default UI uses the game's own 64px dialog background")

-- 10. targeting buttons and macro
FXP.db.targetButtons, FXP.db.targetMacro, FXP.db.targetMark = true, true, true
local npcStep = { accept = { "Targeting Test A" }, npc = "Marshal McBride", key = "tgt1" }
local t1 = FXP:StepTargets(npcStep)
check(#t1 == 1 and t1[1].name == "Marshal McBride" and t1[1].kind == "npc", "accept step targets the quest giver")
QS.on[FXP:Resolve("Targeting Test A")] = true
check(#FXP:StepTargets(npcStep) == 0, "no target once the quest is picked up")
local realQZ = ns.Questie
ns.Questie = { ready = true, ObjectiveNames = function() return { "Kobold Vermin", "Kobold Worker" } end }
local killStep = { complete = { "Targeting Test K" }, target = "Hogger", key = "tgt2" }
QS.on[FXP:Resolve("Targeting Test K")] = true
local t2 = FXP:StepTargets(killStep)
check(#t2 == 3 and t2[1].name == "Hogger" and t2[2].name == "Kobold Vermin" and t2[3].kind == "mob",
  "kill step targets the authored mob, then Questie's objective mobs")
local mt = FXP:TargetMacroText(t2[2])
check(mt:find("/targetexact Kobold Vermin", 1, true) and mt:find("SetRaidTarget", 1, true), "mob macro targets exactly and marks a skull")
check(not FXP:TargetMacroText(t1[1]):find("SetRaidTarget", 1, true), "NPCs are never marked")
local body = FXP:TargetMacroBody(t2)
check(#body <= 255 and body:find("Hogger") and body:find("Kobold Worker"), "action-bar macro fits 255 chars and has every target")
local many = {}
for i = 1, 20 do many[i] = { name = "A Very Long Creature Name Number " .. i, kind = "mob" } end
check(#FXP:TargetMacroBody(many) <= 255, "action-bar macro stays within 255 chars with many targets")
FXP.guide = { name = "T", steps = { killStep } }; FXP.db.step = 1; FXP.db.xpDebt = 0
MACROS = {}; FXP.lastMacroBody = nil
FXP:RefreshTargets()
check(#FXP.targets == 3 and MACROS[1] and MACROS[1].name == "FXP Target" and MACROS[1].body:find("Hogger"), "refresh creates the FXP Target macro")
COMBAT = true
killStep.target = "Defias Bandit"
FXP:RefreshTargets()
check(FXP.targetsDirty and not MACROS[1].body:find("Defias"), "in combat nothing secure changes; the refresh is queued")
COMBAT = false
for _, o in ipairs(ALLOBJ) do local h = o._scripts.OnEvent; if h then pcall(h, o, "PLAYER_REGEN_ENABLED") end end
check(not FXP.targetsDirty and MACROS[1].body:find("Defias Bandit"), "queued refresh runs when combat ends")
FXP.db.targetMacro = false; MACROS[1].body = "x"; FXP.lastMacroBody = nil; FXP:RefreshTargets()
check(MACROS[1].body == "x", "macro left alone when the option is off")
ns.Questie = realQZ
print(("\n%d failures"):format(fails))
