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
BAGS = {}           -- itemID -> count
USABLE = {}         -- itemID -> spell name
GetItemCount = function(i) return BAGS[i] or 0 end
GetItemSpell = function(i) return USABLE[i] end
GetItemIcon = function(i) return "icon" .. tostring(i) end
GetItemInfo = function(i) return "Item " .. tostring(i) end
GetItemCooldown = function() return 0, 0 end
SHIFT = false
IsShiftKeyDown = function() return SHIFT end
TRAINER = {}        -- { name, rank, category, cost }
BOUGHT = {}
GetNumTrainerServices = function() return #TRAINER end
GetTrainerServiceInfo = function(i) local t = TRAINER[i]; return t[1], t[2], t[3] end
GetTrainerServiceCost = function(i) return TRAINER[i][4] end
BuyTrainerService = function(i) BOUGHT[#BOUGHT + 1] = TRAINER[i][1] end
IsTradeskillTrainer = function() return false end

local ns = {}
local files = { "Compat.lua", "Data/QuestDB.lua", "Data/ClassQuests.lua", "Data/Dungeons.lua", "Data/FlightPoints.lua", "Core.lua", "Questie.lua",
  "UI.lua", "Themes.lua", "Arrow.lua", "Targeting.lua", "Helpers.lua", "Travel.lua", "Pins.lua", "Feedback.lua", "Options.lua", "DungeonUI.lua", "Guides/Human_Northshire.lua", "Guides/Elwynn_6-10.lua",
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
-- 10b. the on-screen button pops up for what's nearby
FXP.db.targetMacro = true; FXP.db.targetPop = true; FXP.db.targetPopAlways = false
killStep.target = nil
local pop = FXP.targetPopButton
check(pop ~= nil, "on-screen target button exists")
local popAttr, popShown = nil, false
pop.SetAttribute = function(_, k, v) if k == "macrotext" then popAttr = v end end
pop.Show = function() popShown = true end
pop.Hide = function() popShown = false end
pop.IsShown = function() return popShown end
FXP:RefreshTargets()
check(not popShown, "no pop-up while nothing the step needs is nearby")
local plates = {}
C_NamePlate.GetNamePlates = function() return plates end
UnitName = function(u) return u == "nameplate1" and "Kobold Vermin" or nil end
plates[1] = { namePlateUnitToken = "nameplate1" }
local function fire(ev) for _, o in ipairs(ALLOBJ) do local h = o._scripts.OnEvent; if h then pcall(h, o, ev) end end end
fire("NAME_PLATE_UNIT_ADDED")
check(popShown and popAttr and popAttr:find("Kobold Vermin"), "pops up when a needed mob's nameplate appears")
local lastLine = popAttr and popAttr:gsub("\n/run.*$", ""):match("([^\n]+)$")
check(lastLine == "/targetexact Kobold Vermin", "the nearby mob is targeted last, so the click lands on it")
plates[1] = nil
fire("NAME_PLATE_UNIT_REMOVED")
check(not popShown, "hides again when it goes out of sight")
COMBAT = true; plates[1] = { namePlateUnitToken = "nameplate1" }; fire("NAME_PLATE_UNIT_ADDED")
check(not popShown, "never shows itself in combat (protected)")
COMBAT = false
FXP.db.targetPopAlways = true; plates[1] = nil; fire("NAME_PLATE_UNIT_REMOVED")
check(popShown, "'keep it on screen' shows it whenever the step has targets")
-- 11. Phase 1: quest item buttons, auto-train, quest cleanup
ns.Questie = { ready = true, ObjectiveNames = function() return {} end,
  QuestItems = function(_, id) return { 5001, 5002, 5003 } end }
local itemStep = { complete = { "Item Test Q" }, useItem = 6000, key = "it1" }
QS.on[FXP:Resolve("Item Test Q")] = true
BAGS = { [5001] = 1, [5002] = 3, [6000] = 1 }      -- 5003 not carried
USABLE = { [5001] = "Use", [6000] = "Use" }        -- 5002 carried but not usable (just a collect item)
local items = FXP:StepItems(itemStep)
check(#items == 2 and items[1] == 6000 and items[2] == 5001, "quest item buttons: authored item first, only usable items you carry")
QS.comp[FXP:Resolve("Item Test Q")] = true
check(#FXP:StepItems(itemStep) == 1, "objective items drop off once the quest is complete (authored item stays)")
QS.comp[FXP:Resolve("Item Test Q")] = nil
FXP.db.questItems = true
FXP.guide = { name = "T", steps = { itemStep } }; FXP.db.step = 1
FXP:RefreshItems()
check(FXP.stepItems and #FXP.stepItems == 2 and FXP.itemBar ~= nil, "item bar refreshes with the step's items")
COMBAT = true; BAGS[5001] = 0; FXP:RefreshItems()
check(FXP.itemsDirty and #FXP.stepItems == 2, "item buttons don't change in combat; queued")
COMBAT = false
for _, o in ipairs(ALLOBJ) do local h = o._scripts.OnEvent; if h then pcall(h, o, "PLAYER_REGEN_ENABLED") end end
check(not FXP.itemsDirty and #FXP.stepItems == 1, "queued item refresh runs after combat")

local trainStep = { train = true, key = "tr1" }
FXP.guide = { name = "T", steps = { trainStep } }; FXP.db.step = 1
FXP.db.autoTrain = true; FXP.db.trainReserve = 0
GetMoney = function() return 5000 end
TRAINER = { { "Frostbolt", "Rank 2", "available", 1000 }, { "Arcane Intellect", "Rank 1", "used", 0 },
  { "Fire Ward", "Rank 1", "available", 3000 }, { "Polymorph", "Rank 2", "unavailable", 100 } }
BOUGHT = {}
local nb = FXP:AutoTrain()
check(nb == 2 and #BOUGHT == 2, "auto-train buys every available skill it can afford")
FXP.db.trainReserve = 0.03 -- keep 3 silver = 300 copper: 5000 - 3000 - 1000 = 1000 >= 300, still both
BOUGHT = {}; FXP:AutoTrain()
check(#BOUGHT == 2, "reserve respected when there's enough")
FXP.db.trainReserve = 0.25 -- keep 2500 copper: Fire Ward (3000) would leave 2000, skipped; Frostbolt leaves 4000
BOUGHT = {}; FXP:AutoTrain()
check(#BOUGHT == 1 and BOUGHT[1] == "Frostbolt", "never spends below the gold reserve")
FXP.db.trainReserve = 0
SHIFT = true; BOUGHT = {}; FXP:AutoTrain()
check(#BOUGHT == 0, "holding Shift skips auto-train")
SHIFT = false
FXP.guide = { name = "T", steps = { { text = "not a train step", key = "x" } } }
BOUGHT = {}; FXP:AutoTrain()
check(#BOUGHT == 0, "only trains on guide trainer steps")

FXP.knownQuests = nil
LOG = { { id = FXP:Resolve("Item Test Q"), title = "Item Test Q" }, { id = 99001, title = "Some Random Quest" },
  { id = 99002, title = "Finished Random Quest" } }
C_QuestLog.GetNumQuestLogEntries = function() return #LOG end
C_QuestLog.GetInfo = function(i) return { questID = LOG[i].id, title = LOG[i].title, isHeader = false } end
C_QuestLog.GetTitleForQuestID = function(id) for _, q in ipairs(LOG) do if q.id == id then return q.title end end end
QS.comp[99002] = true
local guideQuest = next(FXP.guides["Westfall 10-14"].quests or {}) or FXP:Resolve(FXP.guides["Westfall 10-14"].steps[2].accept and FXP.guides["Westfall 10-14"].steps[2].accept[1] or "x")
FXP.guides["__phase1"] = { name = "__phase1", steps = { { accept = { "Item Test Q" }, key = "p1" } } }
FXP.knownQuests = nil
local orphans = FXP:OrphanQuests()
check(#orphans == 1 and orphans[1].id == 99001, "cleanup finds only quests no guide uses (and keeps finished ones)")
local abandoned = {}
C_QuestLog.SetSelectedQuest = function(id) abandoned[#abandoned + 1] = id end
C_QuestLog.SetAbandonQuest = function() end
C_QuestLog.AbandonQuest = function() end
check(FXP:AbandonQuests(orphans) == 1 and abandoned[1] == 99001, "abandons exactly the confirmed list")
FXP.guides["__phase1"] = nil

-- 12. Phase 2: travel
local SAME = FXP.SamePlace
check(SAME("Sentinel Hill, Westfall", "sentinel hill") and SAME("Theramore Isle", "Theramore") and not SAME("Stormwind", "Ironforge"),
  "place names match ignoring case and the ', Zone' part")
FXP.db.autoFly, FXP.db.autoBind, FXP.db.flightTimer, FXP.db.fpReminders = true, true, true, true
FXP.db.knownFlights, FXP.db.flown, FXP.db.hearthed = nil, nil, nil
ZONE, SUBZONE, HOME = "Westfall", "Sentinel Hill", "Goldshire"
GetZoneText = function() return ZONE end; GetRealZoneText = GetZoneText
GetSubZoneText = function() return SUBZONE end; GetMinimapZoneText = GetSubZoneText
GetBindLocation = function() return HOME end
TAXI = {}; TAKEN = nil
NumTaxiNodes = function() return #TAXI end
TaxiNodeName = function(i) return TAXI[i][1] end
TaxiNodeGetType = function(i) return TAXI[i][2] end
TakeTaxiNode = function(i) TAKEN = TAXI[i][1] end
local function fireT(ev, a1, a2) for _, o in ipairs(ALLOBJ) do local h = o._scripts.OnEvent; if h then pcall(h, o, ev, a1, a2) end end end

local fpStep = { fp = "Sentinel Hill", bind = "Sentinel Hill", coords = { 56.6, 52.6 }, key = "fp1" }
check(not FXP:IsStepDone(fpStep), "flight path step waits until you know the flight path")
TAXI = { { "Sentinel Hill, Westfall", "CURRENT" }, { "Stormwind, Elwynn", "REACHABLE" } }
FXP.guide = { name = "T", steps = { fpStep } }; FXP.db.step = 1
fireT("TAXIMAP_OPENED")
check(FXP:KnowsFlight("Sentinel Hill") and FXP:KnowsFlight("Stormwind"), "opening a flight map learns every flight path on it")
check(not FXP:IsStepDone(fpStep), "...but the step also waits for the Hearthstone")
local picked
C_GossipInfo = C_GossipInfo or {}
C_GossipInfo.GetOptions = function() return { { name = "Make this inn your home.", icon = 132052, gossipOptionID = 77 } } end
C_GossipInfo.SelectOption = function(id) picked = id end
C_GossipInfo.GetActiveQuests = function() return {} end
C_GossipInfo.GetAvailableQuests = function() return {} end
FXP:OnGossip()
check(picked == 77, "innkeeper: picks 'make this inn your home' on a bind step")
local confirmed = false
ConfirmBinder = function() confirmed = true; HOME = "Sentinel Hill" end
fireT("CONFIRM_BINDER")
check(confirmed and FXP:IsStepDone(fpStep), "confirms the bind, and the step completes")
HOME = "Goldshire"; picked = nil; SHIFT = true; FXP:OnGossip(); SHIFT = false
check(picked == nil, "Shift at the innkeeper skips it")

local flyStep = { fly = "Stormwind", key = "fly1" }
FXP.guide = { name = "T", steps = { flyStep } }; FXP.db.step = 1
C_GossipInfo.GetOptions = function() return { { name = "Show me where I can fly.", icon = 132057, gossipOptionID = 5 } } end
picked = nil; FXP:OnGossip()
check(picked == 5, "flight master: opens the flight map on a fly step")
TAKEN = nil; fireT("TAXIMAP_OPENED")
check(TAKEN == "Stormwind, Elwynn", "flight map: flies to the guide's destination")
check(FXP:IsStepDone(flyStep), "a pure fly step is done once you've taken the flight")
FXP.db.flown = nil; TAKEN = nil; SHIFT = true; fireT("TAXIMAP_OPENED"); SHIFT = false
check(TAKEN == nil, "Shift at the flight master lets you choose")
TAXI = { { "Sentinel Hill, Westfall", "CURRENT" } }; TAKEN = nil; fireT("TAXIMAP_OPENED")
check(TAKEN == nil, "no flight to an unknown destination")
ZONE, SUBZONE = "Stormwind City", "Trade District"
check(FXP:IsStepDone(flyStep), "...and a fly step is done anyway once you're there")
local trainFly = { train = true, fly = "Ironforge", key = "tf1" }
check(not FXP:IsStepDone(trainFly), "fly on a train step doesn't finish it - training does")

FXP.pendingFlight = { from = "Sentinel Hill, Westfall", to = "Stormwind, Elwynn" }
local clock = 100; GetTime = function() return clock end
ForeverXPDB = nil
FXP:StartFlight(); clock = 190; FXP:FlightTick(); FXP:EndFlight()
check(ForeverXPDB.flightTimes["Sentinel Hill, Westfall > Stormwind, Elwynn"] == 90, "flight timer learns how long a route takes (account-wide)")
FXP.pendingFlight = { from = "Sentinel Hill, Westfall", to = "Stormwind, Elwynn" }
FXP:StartFlight()
check(FXP.flight.known == 90, "next time on that route it counts down")
FXP:EndFlight(); GetTime = function() return 100 end

local hearthStep = { hearth = "Theramore", key = "h1" }
FXP.guide = { name = "T", steps = { hearthStep } }; FXP.db.step = 1
BAGS[6948] = 1; USABLE[6948] = "Hearthstone"
local hs = FXP:StepItems(hearthStep)
check(hs[1] == 6948, "hearth step offers the Hearthstone as a button")
check(not FXP:IsStepDone(hearthStep), "hearth step waits until you arrive")
ZONE, SUBZONE = "Dustwallow Marsh", "Theramore Isle"
fireT("ZONE_CHANGED_NEW_AREA")
check(FXP:IsStepDone(hearthStep) and #FXP:StepItems(hearthStep) == 0, "arriving finishes it and the button goes away")

local said = {}
local realPrint = FXP.Print
FXP.Print = function(fmt, ...) said[#said + 1] = string.format(fmt, ...) end
ZONE, SUBZONE = "Redridge Mountains", "Lakeshire"
fireT("ZONE_CHANGED_NEW_AREA"); fireT("ZONE_CHANGED_NEW_AREA")
local lr = 0
for _, l in ipairs(said) do if l:find("Lakeshire", 1, true) and l:find("flight path", 1, true) then lr = lr + 1 end end
check(lr == 1, "entering a zone reminds you once about a flight path you haven't got")
ERR_NEWTAXIPATH = "New flight path discovered!"
fireT("UI_INFO_MESSAGE", 0, ERR_NEWTAXIPATH)
check(FXP:KnowsFlight("Lakeshire"), "'new flight path discovered' learns it")
FXP.Print = realPrint

local nTravel, unknownFP = 0, {}
local allFP = {}
for _, list in pairs(ns.FlightPoints) do for _, n in ipairs(list) do allFP[n] = true end end
for _, g in pairs(FXP.guides) do
  for _, st in ipairs(g.steps) do
    if st.fly or st.fp or st.bind or st.hearth then nTravel = nTravel + 1 end
    if st.fp and not allFP[st.fp] and st.fp ~= "Farholde Keep" then unknownFP[#unknownFP + 1] = st.fp end
  end
end
check(nTravel >= 45, "guides use the travel fields (" .. nTravel .. " steps)")
check(#unknownFP == 0, "every guide flight path is in the flight path list" .. (#unknownFP > 0 and (": " .. table.concat(unknownFP, ", ")) or ""))
-- 13. Phase 3: map pins
FXP.db.mapPins, FXP.db.minimapPins, FXP.db.mapPinsAhead = true, true, 2
local pinGuide = { name = "PinT", steps = {
  { text = "current", coords = { 10, 20, 1436 }, key = "p1" },
  { text = "no place", key = "p2" },
  { text = "next", coords = { 30, 40, 1436 }, key = "p3" },
  { text = "after", coords = { 50, 60, 1436 }, key = "p4" },
  { text = "too far ahead", coords = { 70, 80, 1436 }, key = "p5" } } }
FXP.guide = pinGuide; FXP.db.step = 1; FXP.pinCache = nil
local pins = FXP:PinSteps()
check(#pins == 3 and pins[1].current and pins[1].x == 10 and pins[2].index == 3 and pins[3].index == 4 and not pins[2].current,
  "pins: current step + the next 2 with a place (steps without one are skipped)")
FXP.db.mapPinsAhead = 0; FXP.pinCache = nil
check(#FXP:PinSteps() == 1, "pins: 'upcoming steps to pin' = 0 shows only the current step")
FXP.db.mapPinsAhead = 2; FXP.db.mapPins, FXP.db.minimapPins = false, false; FXP.pinCache = nil
check(#FXP:PinSteps() == 0, "pins: off when both map options are off")
FXP.db.mapPins, FXP.db.minimapPins = true, true; FXP.pinCache = nil
local px, py = FXP:PinOnMap({ map = 1436, x = 25, y = 75 }, 1436)
check(px == 0.25 and py == 0.75, "pins: same-map position is the step's coords")

local function near(a, b) return math.abs(a - b) < 0.01 end
local mx, my, edge = FXP:MinimapOffset(100, 0, 0, false, 0, false, 140)
check(near(mx, 0) and near(my, 30) and not edge, "minimap: 100 yards north at full zoom-out is 30 px up")
mx, my = FXP:MinimapOffset(0, 50, 0, false, 0, false, 140)
check(near(mx, -15) and near(my, 0), "minimap: west is left")
mx, my = FXP:MinimapOffset(0, 50, math.pi / 2, true, 0, false, 140)
check(near(mx, 0) and near(my, 15), "minimap: rotating minimap facing west puts west straight up")
mx, my = FXP:MinimapOffset(30, 0, 0, false, 5, false, 140)
local mx2, my2 = FXP:MinimapOffset(30, 0, 0, false, 0, false, 140)
check(my > my2 * 3, "minimap: zooming in spreads pins out")
mx, my, edge = FXP:MinimapOffset(5000, 0, 0, false, 0, false, 140)
check(edge and near(math.sqrt(mx * mx + my * my), 64), "minimap: far targets clamp to the rim")

local canvas = Obj()
canvas.GetWidth = function() return 1000 end
canvas.GetHeight = function() return 700 end
canvas.GetFrameLevel = function() return 1 end
WorldMapFrame = { GetCanvas = function() return canvas end, GetMapID = function() return 1436 end,
  IsShown = function() return true end, ScrollContainer = { GetCanvasScale = function() return 2 end } }
FXP.guide = pinGuide; FXP.db.step = 1; FXP.pinCache = nil
FXP:RefreshWorldPins()
local placed = {}
for _, o in ipairs(ALLOBJ) do
  if o.info then
    o.SetPoint = function(self, _, _, _, x, y) placed[self.info.n] = { x = x, y = y, s = self._scale } end
    o.SetScale = function(self, s) self._scale = s end
  end
end
FXP:RefreshWorldPins()
local p1 = placed[1]
check(p1 and near(p1.s, 0.5) and near(p1.x * p1.s, 100) and near(p1.y * p1.s, -140),
  "world map: pin sits at its map spot and keeps its size when the map is zoomed")
check(placed[2] and near(placed[2].s, 0.4), "world map: upcoming pins are drawn smaller")
WorldMapFrame = nil
-- 14. Phase 4: reports, run log, route check, export
ForeverXPDB = nil
local fbGuide = FXP.guides["Westfall 10-14"]
FXP.guide = fbGuide; FXP.db.step = 3
local said4 = {}
local realPrint4 = FXP.Print
FXP.Print = function(fmt, ...) said4[#said4 + 1] = string.format(fmt, ...) end
local rep = FXP:Report("arrow points into the sea")
check(ForeverXPDB.reports[1] == rep and rep.reason == "other" and rep.note == "arrow points into the sea"
  and rep.guide == "Westfall 10-14" and rep.step == 3 and rep.src and rep.text ~= "" and type(rep.quests) == "table",
  "/fxp report <note> saves the step, file position, note and quest state")
local srcOk, nClass, shifted = true, 0, false
for i, st in ipairs(fbGuide.steps) do
  if st.classStep then nClass = nClass + 1; if st.src then srcOk = false end
  elseif st.src ~= i - nClass then srcOk = false
  elseif nClass > 0 then shifted = true end
end
check(srcOk and nClass > 0, "every file step keeps its file position; injected class quest steps have none")

local clock4 = 1000; GetTime = function() return clock4 end
FXP.db.step = 1; FXP:LogStepChange(false)
clock4 = 1300; FXP.db.step = 2; FXP:LogStepChange(false)
FXP:NoteDeath(); FXP:NoteDeath()
clock4 = 2300; FXP.db.step = 3; FXP:LogStepChange(true)
local log = ForeverXPDB.runLog
check(#log == 2 and log[1].secs == 300 and log[1].how == "done" and log[2].secs == 1000 and log[2].deaths == 2 and log[2].how == "manual",
  "run log records time per step, deaths and manual skips")
local sum = FXP:RunSummary()
check(#sum == 1 and sum[1].name == "Westfall 10-14 #2", "run summary flags only the slow/skipped/deadly step")
GetTime = function() return 100 end

local realQZ4 = ns.Questie
local rows = {
  [FXP:Resolve("CK Good")] = { id = 1, name = "CK Good", req = 10 },
  [FXP:Resolve("CK Horde")] = { id = 2, name = "CK Horde", req = 10, horde = true },
  [FXP:Resolve("CK High")] = { id = 3, name = "CK High", req = 30 },
  [FXP:Resolve("CK Pre")] = { id = 4, name = "CK Pre", req = 10, pre1 = { 424242 } },
  [FXP:Resolve("CK Far")] = { id = 5, name = "CK Far", req = 10 },
}
ns.Questie = { ready = true,
  Row = function(_, id) return rows[id] end,
  FitsFaction = function(_, row) return not row.horde end,
  Endpoint = function(_, row, key) if row.name == "CK Far" then return { name = "Farmer Far", x = 80, y = 80, map = 1436 } end end }
local ckGuide = { name = "CK", minLevel = 10, maxLevel = 12, zone = "Westfall", steps = {
  { accept = { "CK Good" }, src = 1 }, { accept = { "CK Unknown" }, src = 2 }, { accept = { "CK Horde" }, src = 3 },
  { accept = { "CK High" }, src = 4 }, { accept = { "CK Pre" }, src = 5 }, { accept = { "CK Far" }, coords = { 20, 20 }, src = 6 },
  { accept = { "CK Unknown" }, class = { "MAGE" }, src = 7 } } }
local f = FXP:CheckGuide(ckGuide, {})
local issues = {}
for _, x in ipairs(f) do issues[x.quest] = x.issue end
check(#f == 5 and issues["CK Unknown"]:find("doesn't know") and issues["CK Horde"]:find("Alliance") and issues["CK High"]:find("needs level 30")
  and issues["CK Pre"]:find("424242") and issues["CK Far"]:find("Farmer Far") and not issues["CK Good"],
  "route check flags unknown, wrong-faction, too-high, missing-prerequisite and misplaced quests (and skips class steps)")
ns.Questie = realQZ4

ForeverXPDB.routeCheck = { when = "today", version = "test", findings = f }
local txt = FXP:ExportText()
check(txt:find("== Reports (1)", 1, true) and txt:find("arrow points into the sea", 1, true) and txt:find("Westfall 10-14 #2", 1, true)
  and txt:find("CK Horde", 1, true), "/fxp export lists reports, problem steps and route check findings")
FXP.Print = realPrint4

-- write ForeverXPDB the way WoW does, for Tools/read_reports.py (end-to-end test)
if SV_OUT then
  local function ser(v, ind)
    if type(v) == "string" then return string.format("%q", v) end
    if type(v) ~= "table" then return tostring(v) end
    local out, n = { "{" }, #v
    for k, x in pairs(v) do
      if not (type(k) == "number" and k >= 1 and k <= n and k % 1 == 0) then
        out[#out + 1] = ind .. "\t[" .. (type(k) == "string" and string.format("%q", k) or tostring(k)) .. "] = " .. ser(x, ind .. "\t") .. ","
      end
    end
    for i = 1, n do out[#out + 1] = ind .. "\t" .. ser(v[i], ind .. "\t") .. ", -- [" .. i .. "]" end
    out[#out + 1] = ind .. "}"
    return table.concat(out, "\n")
  end
  local fh = io.open(SV_OUT, "w"); fh:write("\nForeverXPDB = " .. ser(ForeverXPDB, "") .. "\n"); fh:close()
end
ns.Questie = realQZ
print(("\n%d failures"):format(fails))
