-- Core.lua: guide registry, step logic, auto quest handling, XP tracking, slash commands.
local ADDON, ns = ...
local C = ns.Compat

local FXP = CreateFrame("Frame")
ns.FXP = FXP
_G.ForeverXP = FXP

FXP.guides, FXP.guideOrder = {}, {}
FXP.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

local PREFIX = "|cff33ff99ForeverXP|r: "
local function Print(...) print(PREFIX .. string.format(...)) end
FXP.Print = Print

local DEFAULTS = {
  autoAccept = true, autoTurnin = true, arrow = true, sound = true,
  combatFade = true, locked = false, collapsed = false, hidden = false,
  scale = 1, upcoming = 2, minimapAngle = 215, minimapHide = false,
  skipGroup = false, announceWarnings = true, theme = "classic", catchUp = true,
  targetButtons = true, targetMacro = true, targetMark = true, targetPop = true, targetPopAlways = false,
  questItems = true, autoTrain = true, trainReserve = 0,
  autoFly = true, autoBind = true, flightTimer = true, fpReminders = true,
  mapPins = true, minimapPins = true, mapPinsAhead = 2,
  talents = true, autoTalents = false, gearHints = true, partySync = true, partyFollow = false,
  hardcore = false, dangerWarnings = true, lowHealth = 0.35,
}

---------------------------------------------------------------------------
-- Guide registration
---------------------------------------------------------------------------
local function AsList(v)
  if v == nil then return nil end
  if type(v) == "table" then return v end
  return { v }
end

--[[ info = {
  faction = "Alliance"|"Horde"|nil, races = {"Human"}|nil,
  minLevel = 1, maxLevel = 6, zone = "Elwynn Forest",
  next = "Next Guide Name", quests = { [id] = "Name" }, steps = { ... } }
  Quests in steps can be IDs (numbers) or exact quest names (strings). ]]
FXP.zoneNames = {}

-- Classic uiMapIDs, used until the real map for a zone has been seen in-game.
local CLASSIC_MAPS = {
  ["Alterac Mountains"] = 1416, ["Arathi Highlands"] = 1417, ["Badlands"] = 1418,
  ["Blasted Lands"] = 1419, ["Tirisfal Glades"] = 1420, ["Silverpine Forest"] = 1421,
  ["Western Plaguelands"] = 1422, ["Eastern Plaguelands"] = 1423, ["Hillsbrad Foothills"] = 1424,
  ["The Hinterlands"] = 1425, ["Dun Morogh"] = 1426, ["Searing Gorge"] = 1427,
  ["Burning Steppes"] = 1428, ["Elwynn Forest"] = 1429, ["Deadwind Pass"] = 1430,
  ["Duskwood"] = 1431, ["Loch Modan"] = 1432, ["Redridge Mountains"] = 1433,
  ["Stranglethorn Vale"] = 1434, ["Swamp of Sorrows"] = 1435, ["Westfall"] = 1436,
  ["Wetlands"] = 1437, ["Teldrassil"] = 1438, ["Darkshore"] = 1439, ["Ashenvale"] = 1440,
  ["Thousand Needles"] = 1441, ["Stonetalon Mountains"] = 1442, ["Desolace"] = 1443,
  ["Feralas"] = 1444, ["Dustwallow Marsh"] = 1445, ["Tanaris"] = 1446, ["Azshara"] = 1447,
  ["Felwood"] = 1448, ["Un'Goro Crater"] = 1449, ["Moonglade"] = 1450, ["Silithus"] = 1451,
  ["Winterspring"] = 1452, ["Stormwind City"] = 1453, ["Ironforge"] = 1455,
  ["Darnassus"] = 1457, ["The Barrens"] = 1413, ["Mulgore"] = 1412, ["Durotar"] = 1411,
}

-- Class quest steps (Data/ClassQuests.lua) are copied into every guide whose level range
-- contains the quest's level, right after the guide's first trainer stop.
local function InjectClassSteps(info)
  local CQ = ns.ClassQuests
  if not CQ or info.noClassSteps then return end
  local lo, hi = info.minLevel or 1, info.maxLevel or 60
  local add = {}
  for _, block in ipairs(CQ) do
    if block.level >= lo and (block.level < hi or hi >= 60) then
      for _, st in ipairs(block.steps) do
        local c = {}
        for k, v in pairs(st) do c[k] = v end
        c.class = block.class
        c.ifLevel = c.ifLevel or block.level
        c.classStep = true
        add[#add + 1] = c
      end
    end
  end
  if #add == 0 then return end
  local pos
  for i, s in ipairs(info.steps) do if s.train then pos = i + 1; break end end
  pos = pos or math.max(1, #info.steps)
  for j = #add, 1, -1 do table.insert(info.steps, pos, add[j]) end
end

function FXP:RegisterGuide(name, info)
  info.name = name
  if info.zone then self.zoneNames[info.zone] = true end
  for i, s in ipairs(info.steps) do s.src = i end -- position in the guide file (class steps get injected below)
  InjectClassSteps(info)
  for i, s in ipairs(info.steps) do
    s.accept, s.complete, s.turnin = AsList(s.accept), AsList(s.complete), AsList(s.turnin)
    s.anyQuest = s.anyQuest and AsList(s.anyQuest) or nil
    s.key = name .. ":" .. i
    if s.zone then self.zoneNames[s.zone] = true end
  end
  self.guides[name] = info
  table.insert(self.guideOrder, name)
end

---------------------------------------------------------------------------
-- Quest resolution. Numeric IDs are Classic IDs; if a client (e.g. WoW Forever)
-- uses different IDs we learn the real ones by title. String entries are quest
-- names and get their ID the first time the quest is seen.
---------------------------------------------------------------------------
-- "Name#2" = the 2nd quest of that name in a chain (for chains that reuse one title).
local function SplitName(q)
  local base, n = q:match("^(.-)#(%d+)$")
  if base then return base, tonumber(n) end
  return q, nil
end
FXP.SplitName = SplitName

function FXP:Resolve(q)
  local db = self.db
  if type(q) == "string" then
    local id = db and db.nameMap and db.nameMap[q]
    if id then return id end
    local base, nth = SplitName(q)
    local QZ = ns.Questie
    -- Questie knows every quest of that name in chain order: exact answer
    if QZ and QZ.byNameList and QZ.byNameList[base] then
      id = QZ.byNameList[base][nth or 1]
      if id and nth and db then db.nameMap = db.nameMap or {}; db.nameMap[q] = id end
      if id then return id end
    end
    id = C.LogFindTitle(base)
    if id and nth and db and db.nameMap then
      -- don't hand out an ID that another part of the same chain already owns
      for k, v in pairs(db.nameMap) do
        if v == id and k ~= q and SplitName(k) == base then id = nil break end
      end
    end
    if id and db then db.nameMap = db.nameMap or {}; db.nameMap[q] = id end
    if not id and not nth and self.dbByName and self.dbByName[base] then id = self.dbByName[base].id end
    return id
  end
  return (db and db.idMap and db.idMap[q]) or q
end

function FXP:GuideName(q)
  if type(q) == "string" then return (SplitName(q)) end
  for _, g in pairs(self.guides) do
    if g.quests and g.quests[q] then return g.quests[q] end
  end
end

function FXP:LearnQuest(realID, title)
  if not (realID and realID > 0 and self.db) then return end
  title = title or C.Title(realID)
  if not title then return end
  self.db.nameMap = self.db.nameMap or {}
  self.db.nameMap[title] = realID
  self.db.idMap = self.db.idMap or {}
  -- if this exact ID is used by a guide, it's correct as-is; never remap another quest onto it
  for _, g in pairs(self.guides) do
    if g.quests and g.quests[realID] then return end
  end
  for _, g in pairs(self.guides) do
    for guideID, name in pairs(g.quests or {}) do
      if name == title and guideID ~= realID then self.db.idMap[guideID] = realID end
    end
  end
end

function FXP:LearnQuestLog()
  for _, id in ipairs(C.LogQuestIDs()) do self:LearnQuest(id) end
end

-- Remember the uiMapID of every zone a guide names, as the player walks through it.
function FXP:LearnZone()
  if not (C_Map and C_Map.GetBestMapForUnit and self.db) then return end
  local m = C_Map.GetBestMapForUnit("player")
  self.db.zoneMaps = self.db.zoneMaps or {}
  local guard = 0
  while m and m > 0 and guard < 8 do
    local info = C_Map.GetMapInfo(m)
    if not info then break end
    if self.zoneNames[info.name] then self.db.zoneMaps[info.name] = info.mapID end
    m, guard = info.parentMapID, guard + 1
  end
end

function FXP:StepMap(s)
  if s.coords and s.coords[3] then return s.coords[3] end
  local zone = s.zone or (self.guide and self.guide.zone)
  if zone then
    local learned = self.db.zoneMaps and self.db.zoneMaps[zone]
    return learned or CLASSIC_MAPS[zone]
  end
  return self.guide and self.guide.map
end

function FXP:QuestName(q)
  if type(q) == "string" then return (SplitName(q)) end
  local db = self:QuestData(q)
  return C.Title(self:Resolve(q)) or self:GuideName(q) or (db and db.name) or ("Quest #" .. q)
end

---------------------------------------------------------------------------
-- Quest database (Data/QuestDB.lua, generated by Tools/fxp_wowhead.py)
---------------------------------------------------------------------------
function FXP:BuildQuestIndex()
  self.dbByName = {}
  local faction = UnitFactionGroup("player")
  for id, q in pairs(ns.QuestDB or {}) do
    if q.name then
      local cur = self.dbByName[q.name]
      local fits = not q.side or q.side == "Both" or q.side == faction
      if not cur or (fits and not cur.fits) then self.dbByName[q.name] = { id = id, fits = fits } end
    end
  end
  -- If this game version uses different IDs than a guide, pre-learn them by name.
  if self.db then
    self.db.idMap = self.db.idMap or {}
    for _, g in pairs(self.guides) do
      for guideID, name in pairs(g.quests or {}) do
        local hit = self.dbByName[name]
        if hit and hit.id ~= guideID and not (ns.QuestDB or {})[guideID] and not self.db.idMap[guideID] then
          self.db.idMap[guideID] = hit.id
        end
      end
    end
  end
end

-- Database row for a guide quest (number or name), or nil.
-- Merged quest info: Questie's live database first, Data/QuestDB.lua as fallback.
function FXP:QuestData(q)
  local static = self:StaticQuestData(q)
  local QZ = ns.Questie
  if not (QZ and QZ.ready) then return static end
  local id = self:Resolve(q)
  local row = (id and QZ:Row(id)) or (type(q) == "number" and QZ:Row(q)) or nil
  if not row then return static end
  self.mergeCache = self.mergeCache or {}
  local hit = self.mergeCache[row.id]
  if hit and GetTime() - hit.t < 5 then return hit.v end
  local m = {}
  for k, v in pairs(static or {}) do m[k] = v end
  m.name, m.level, m.req = row.name, row.level or m.level, row.req or m.req
  m.xp = row.xp or m.xp
  for _, key in ipairs({ "start", "finish" }) do
    local e = QZ:Endpoint(row, key)
    if e then
      local old = m[key] or {}
      if e.x then
        m[key] = { name = e.name or old.name, x = e.x, y = e.y, map = e.map }
      else
        m[key] = { name = e.name or old.name, x = old.x, y = old.y, map = old.map, zone = old.zone }
      end
    end
  end
  self.mergeCache[row.id] = { t = GetTime(), v = m }
  return m
end

function FXP:StaticQuestData(q)
  local QDB = ns.QuestDB
  if not QDB then return end
  if type(q) == "string" then
    local hit = self.dbByName and self.dbByName[(SplitName(q))]
    return hit and QDB[hit.id]
  end
  local row = QDB[self:Resolve(q) or q] or QDB[q]
  if row then return row end
  local name = self:GuideName(q)
  local hit = name and self.dbByName and self.dbByName[name]
  return hit and QDB[hit.id]
end

-- Where the arrow should point: explicit step coords, else the quest giver /
-- turn-in NPC from the database. Returns x, y, uiMapID.
function FXP:StepCoords(s)
  if not s then return end
  if s.coords then return s.coords[1], s.coords[2], self:StepMap(s) end
  local list, key = s.turnin, "finish"
  if not list then list, key = s.accept, "start" end
  if list then
    local q = self:QuestData(list[1])
    local npc = q and q[key]
    if npc and npc.x then
      local map = npc.map
      if npc.zone and self.db.zoneMaps and self.db.zoneMaps[npc.zone] then map = self.db.zoneMaps[npc.zone] end
      return npc.x, npc.y, map
    end
  end
  -- objective steps: point at the nearest mobs/objects for the first unfinished quest (from Questie)
  local QZ = ns.Questie
  if s.complete and QZ and QZ.ready then
    for _, q in ipairs(s.complete) do
      local id = self:Resolve(q)
      if id and C.IsOnQuest(id) and not C.IsComplete(id) then
        local p = QZ:ObjectivePos(id)
        if p then return p.x, p.y, p.map end
      end
    end
  end
end

-- A quest you can't get right now (prerequisite not done / other faction / not in this game), per Questie.
function FXP:Unavailable(id, q)
  local QZ = ns.Questie
  if not (QZ and QZ.ready) then return false end
  if not id then
    -- a quest name Questie has never heard of: don't let a typo stall the guide
    if type(q) == "string" and QZ.indexDone then
      local base = SplitName(q)
      return not (QZ.byNameList and QZ.byNameList[base]) and not C.LogFindTitle(base)
    end
    return false
  end
  if C.IsOnQuest(id) or C.IsTurnedIn(id) then return false end
  local row = QZ:Row(id)
  if not row then return false end
  if not QZ:FitsFaction(row) then return true end
  return not QZ:PrereqsMet(row)
end

---------------------------------------------------------------------------
-- Step evaluation
---------------------------------------------------------------------------
function FXP:DistanceTo(s)
  local x, y, map = self:StepCoords(s)
  if not x then return end
  local pc, px, py = C.PlayerWorldPos()
  if not pc then return end
  local tc, tx, ty = C.MapToWorld(map, x, y)
  if not tc or tc ~= pc then return end
  local dNorth, dWest = tx - px, ty - py
  return math.sqrt(dNorth * dNorth + dWest * dWest), dNorth, dWest
end

function FXP:IsStepDone(s)
  -- steps gated behind a level are skipped if you're too low when you reach them
  -- level-gated steps you're too low for are skipped without catch-up (you couldn't take them)
  if s.ifLevel and UnitLevel("player") < s.ifLevel then return true end
  -- class- and race-specific steps are skipped (no catch-up) for everyone else
  if s.class then
    local _, cls = UnitClass("player")
    local ok = false
    for _, c in ipairs(s.class) do if c == cls then ok = true end end
    if not ok then return true end
  end
  if s.races then
    local _, race = UnitRace("player")
    local ok = false
    for _, r in ipairs(s.races) do if r == race then ok = true end end
    if not ok then return true end
  end
  -- elite/group steps are skipped when the player chose to level solo
  if (s.group or s.elite) and self.db.skipGroup then return true, true end
  -- optional quests: only tracked if you actually picked them up; otherwise skipped, no catch-up
  if s.optional then
    local have = false
    for _, list in ipairs({ s.accept or {}, s.complete or {}, s.turnin or {} }) do
      for _, q in ipairs(list) do
        local id = self:Resolve(q)
        if id and (C.IsOnQuest(id) or C.IsTurnedIn(id)) then have = true end
      end
    end
    if not have then return true end
  end
  local checked = false
  if s.train then -- done once you've closed a trainer window during this step
    checked = true
    if not (self.db.trained and self.db.trained[s.key]) then return false end
  end
  if s.accept then
    checked = true
    for _, q in ipairs(s.accept) do
      local id = self:Resolve(q)
      if not self:Unavailable(id, q) then
        if not id or not (C.IsOnQuest(id) or C.IsTurnedIn(id)) then return false end
      end
    end
  end
  if s.complete then
    checked = true
    for _, q in ipairs(s.complete) do
      local id = self:Resolve(q)
      if not self:Unavailable(id, q) then
        if not id or not (C.IsTurnedIn(id) or (C.IsOnQuest(id) and C.IsComplete(id))) then return false end
      end
    end
  end
  if s.turnin then
    checked = true
    for _, q in ipairs(s.turnin) do
      local id = self:Resolve(q)
      if not self:Unavailable(id, q) then
        if not id or not C.IsTurnedIn(id) then return false end
      end
    end
  end
  if s.anyQuest then -- done once you have (or finished) any one of these; skipped if none exist
    checked = true
    local have = false
    for _, q in ipairs(s.anyQuest) do
      local id = self:Resolve(q)
      if id and (C.IsOnQuest(id) or C.IsTurnedIn(id)) then have = true end
    end
    if not have then
      for _, q in ipairs(s.anyQuest) do
        if not self:Unavailable(self:Resolve(q), q) then return false end
      end
    end
  end
  if s.mount then
    checked = true
    if not self:HasRiding() then return false end
  end
  if s.level then
    checked = true
    if UnitLevel("player") < s.level then return false end
  end
  if s.fp or s.bind or s.fly or s.hearth then -- travel fields (Travel.lua)
    local hasOther = checked or (s.coords ~= nil)
    checked = true
    if self.TravelDone and not self:TravelDone(s, hasOther) then return false end
  end
  if not checked and s.coords then -- pure travel step
    local d = self:DistanceTo(s)
    if not d or d > (s.radius or 12) then return false end
    checked = true
  end
  return checked -- text-only steps need a manual "Next"
end

-- Riding skill (or being mounted) means the mount stop is done.
function FXP:HasRiding()
  if self.db.hasMount then return true end
  if IsMounted and IsMounted() then self.db.hasMount = true; return true end
  if GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local name = GetSkillLineInfo(i)
      if name and name:find("Riding") then self.db.hasMount = true; return true end
    end
  end
  if IsSpellKnown then -- modern clients: Apprentice Riding
    for _, id in ipairs({ 33388, 33391, 34090 }) do
      if IsSpellKnown(id) then self.db.hasMount = true; return true end
    end
  end
  return false
end

function FXP:CurrentStep()
  return self.guide and self.guide.steps[self.db.step]
end

local function PlayStepSound()
  if not FXP.db.sound or not SOUNDKIT then return end
  local id = SOUNDKIT.IG_QUEST_LIST_COMPLETE or SOUNDKIT.IG_QUEST_LIST_OPEN
  if id then pcall(PlaySound, id) end
end

function FXP:Update()
  if self.RefreshDungeons then self:RefreshDungeons() end
  if not self.guide then
    if self.RefreshUI then self:RefreshUI() end
    return
  end
  local steps = self.guide.steps
  local before = self.db.step
  self:CheckDebt()
  if not self.hold and not self:InCatchUp() then
    while self.db.step <= #steps do
      local st = steps[self.db.step]
      local done, skipped = self:IsStepDone(st)
      if not done then break end
      if skipped then self:AddDebt(st); if self.NoteSkip then self:NoteSkip() end end
      self.db.step = self.db.step + 1
    end
  end
  local advanced = self.db.step > before
  if self.db.step > #steps then
    local nextName = self.guide.next
    if nextName and self.guides[nextName] then
      Print("Guide finished! Loading |cffffff00%s|r", nextName)
      PlayStepSound()
      self:LoadGuide(nextName)
      return
    end
    self.db.step = #steps
    if not self.finishedNotice then Print("Guide complete.") end
    self.finishedNotice = true
  end
  if advanced then
    PlayStepSound()
    if self.FlashUI then self:FlashUI() end
  end
  self:AnnounceWarning()
  if self.RefreshUI then self:RefreshUI() end
  if self.RefreshArrow then self:RefreshArrow() end
  if self.RefreshTargets then self:RefreshTargets() end
  if self.RefreshItems then self:RefreshItems() end
  self.pinCache = nil -- steps changed: map pins recompute
  if self.LogStepChange then self:LogStepChange(self.manualStep) end
  if self.BroadcastStep and (self.lastSentStep ~= self.db.step or self.lastSentGuide ~= (self.guide and self.guide.name)) then
    self.lastSentStep, self.lastSentGuide = self.db.step, self.guide and self.guide.name
    self:BroadcastStep()
  end
  self.manualStep = nil
end

-- Big on-screen alert the first time a step with a warning becomes current.
function FXP:AnnounceWarning()
  local s = self:CurrentStep()
  if not (s and s.warn and self.db.announceWarnings) then return end
  if self.warnedKey == s.key then return end
  self.warnedKey = s.key
  local msg = "Careful: " .. s.warn
  if RaidNotice_AddMessage and RaidWarningFrame then
    RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 1, g = 0.55, b = 0.1 })
  end
  Print("|cffff8c1a%s|r", msg)
  if s.tip then Print("|cff8fd3ffTip:|r %s", s.tip) end
end

function FXP:QueueUpdate()
  if self.pending then return end
  self.pending = true
  C_Timer.After(0.2, function()
    self.pending = false
    self:Update()
  end)
end

function FXP:LoadGuide(name, step)
  local g = self.guides[name]
  if not g then Print("No guide named '%s'. Type /fxp list", tostring(name)) return end
  self.guide = g
  self.db.guide = name
  self.db.step = math.max(1, math.min(step or 1, #g.steps))
  self.hold = false
  self.finishedNotice = false
  self:Update()
end

function FXP:SetStep(n)
  if not self.guide then return end
  n = math.max(1, math.min(n, #self.guide.steps))
  -- moving forward past unfinished steps = skipped XP
  for i = self.db.step, n - 1 do
    local st = self.guide.steps[i]
    if not self:IsStepDone(st) then self:AddDebt(st) end
  end
  self.db.step = n
  self.hold = true -- don't auto-skip a step the player chose manually
  self.manualStep = true
  self:Update()
end

function FXP:GuideFits(g)
  local faction = UnitFactionGroup("player")
  local _, race = UnitRace("player")
  if g.faction and g.faction ~= faction then return false end
  if g.races then
    local ok = false
    for _, r in ipairs(g.races) do if r == race then ok = true end end
    if not ok then return false end
  end
  return true
end

function FXP:PickGuide()
  local level = UnitLevel("player")
  for _, name in ipairs(self.guideOrder) do
    local g = self.guides[name]
    if not g.side and self:GuideFits(g) and level >= (g.minLevel or 1) and level <= (g.maxLevel or 999) then return name end
  end
end

---------------------------------------------------------------------------
-- XP tracking (session XP/hour and time-to-level)
---------------------------------------------------------------------------
function FXP:ResetXP()
  self.xp = { start = GetTime(), gained = 0, last = UnitXP("player"), lastMax = UnitXPMax("player"), level = UnitLevel("player") }
end

function FXP:OnXP()
  local x = self.xp
  if not x then return end
  local cur, level = UnitXP("player"), UnitLevel("player")
  local gain = 0
  if level > x.level then
    gain = (x.lastMax - x.last) + cur
  elseif cur > x.last then
    gain = cur - x.last
  end
  x.gained = x.gained + gain
  x.last, x.lastMax, x.level = cur, UnitXPMax("player"), level
  if gain > 0 then self:PayDebt(gain) end
end

---------------------------------------------------------------------------
-- Catch-up grinding: skipped steps add an XP "debt" that must be ground off
-- by killing mobs (quest turn-in XP doesn't count) before the guide moves on.
---------------------------------------------------------------------------
local function QuestXPEstimate()
  -- typical quest reward as a share of the current level's XP bar
  local L = UnitLevel("player")
  local pct = math.max(0.035, math.min(0.08, 0.08 - (L - 10) * 0.0009))
  return UnitXPMax("player") * pct
end

function FXP:StepXPValue(s)
  if s.xp then return s.xp end
  local est, v = QuestXPEstimate(), 0
  local function qxp(q) local d = self:QuestData(q); return (d and d.xp) or est end
  for _, q in ipairs(s.turnin or {}) do v = v + qxp(q) end
  for _, q in ipairs(s.complete or {}) do v = v + qxp(q) * 0.4 end -- kill XP from the objectives
  if s.elite or s.group then v = math.max(v, est * 1.5) end
  return math.floor(v)
end

function FXP:AddDebt(s)
  if not (self.db.catchUp and s and s.key) then return end
  self.db.skipped = self.db.skipped or {}
  if self.db.skipped[s.key] then return end
  self.db.skipped[s.key] = true
  local v = self:StepXPValue(s)
  if v <= 0 then return end
  local cap = UnitXPMax("player")
  self.db.xpDebt = math.min((self.db.xpDebt or 0) + v, cap)
  Print("Skipped step costs about |cffffd100%d XP|r. Grind mobs to catch up (%d XP to go).", v, self.db.xpDebt)
end

function FXP:PayDebt(gain)
  if (self.db.xpDebt or 0) <= 0 then return end
  local t = GetTime()
  -- wait a moment so we can tell whether this XP came from a quest turn-in
  C_Timer.After(1.5, function()
    if math.abs((self.lastTurnIn or -99) - t) <= 2 then return end
    self.db.xpDebt = math.max(0, (self.db.xpDebt or 0) - gain)
    if self.db.xpDebt == 0 then
      Print("|cff55ff55Caught up!|r Back to the guide.")
      self.hold = false
      PlayStepSound()
    end
    self:Update()
  end)
end

function FXP:CheckDebt()
  -- no need to grind if you're already above this guide's level range
  if (self.db.xpDebt or 0) > 0 and self.guide and UnitLevel("player") > (self.guide.maxLevel or 60) then
    self.db.xpDebt = 0
  end
end

function FXP:InCatchUp()
  return self.db.catchUp and (self.db.xpDebt or 0) > 0
end

function FXP:XPStats()
  local x = self.xp
  if not x then return end
  local elapsed = GetTime() - x.start
  local perHour = elapsed > 60 and (x.gained / elapsed * 3600) or 0
  local cur, max = UnitXP("player"), UnitXPMax("player")
  local eta = perHour > 0 and ((max - cur) / perHour * 3600) or nil
  return cur, max, perHour, eta
end

function FXP:AtMaxLevel()
  local maxLevel = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or MAX_PLAYER_LEVEL or 60
  return UnitLevel("player") >= maxLevel
end

---------------------------------------------------------------------------
-- Auto accept / turn-in (only for quests in the next few guide steps)
---------------------------------------------------------------------------
function FXP:Wanted(kind, id, title)
  if not self.guide then return false end
  if id == 0 then id = nil end
  if not (id or title) then return false end
  local names = self.guide.quests or {}
  -- optional quests anywhere in the guide are always welcome
  for _, st in ipairs(self.guide.steps) do
    if st.optional and st[kind] then
      for _, q in ipairs(st[kind]) do
        local qn = type(q) == "string" and (SplitName(q)) or names[q]
        if (id and self:Resolve(q) == id) or (title and qn == title) then return true end
      end
    end
  end
  for i = self.db.step, math.min(self.db.step + 4, #self.guide.steps) do
    local list = self.guide.steps[i][kind]
    if list then
      for _, q in ipairs(list) do
        local qn = type(q) == "string" and (SplitName(q)) or names[q]
        if (id and self:Resolve(q) == id) or (title and qn == title) then
          if id and type(q) ~= "string" then self:LearnQuest(id, title) end
          return true
        end
      end
    end
  end
  return false
end

local function Allowed(key) return FXP.db and FXP.db[key] and not IsShiftKeyDown() end

function FXP:OnGossip()
  if Allowed("autoTurnin") then
    for _, q in ipairs(C.GossipActive()) do
      if q.isComplete and self:Wanted("turnin", q.questID, q.title) then C.SelectGossipActive(q) return end
    end
  end
  if Allowed("autoAccept") then
    for _, q in ipairs(C.GossipAvailable()) do
      if self:Wanted("accept", q.questID, q.title) then C.SelectGossipAvailable(q) return end
    end
  end
  -- nothing quest-related left: flight master / innkeeper automation for travel steps
  if self.TravelGossip then self:TravelGossip() end
end

function FXP:OnGreeting()
  if Allowed("autoTurnin") then
    for i = 1, (GetNumActiveQuests and GetNumActiveQuests() or 0) do
      local title, isComplete = GetActiveTitle(i)
      local id = GetActiveQuestID and GetActiveQuestID(i)
      if isComplete and self:Wanted("turnin", id, title) then SelectActiveQuest(i) return end
    end
  end
  if Allowed("autoAccept") then
    for i = 1, (GetNumAvailableQuests and GetNumAvailableQuests() or 0) do
      local id = GetAvailableQuestInfo and select(5, GetAvailableQuestInfo(i))
      local title = GetAvailableTitle and GetAvailableTitle(i)
      if self:Wanted("accept", id, title) then SelectAvailableQuest(i) return end
    end
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = {
  "PLAYER_LOGIN", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE",
  "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "ZONE_CHANGED_NEW_AREA", "QUEST_DETAIL",
  "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING",
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "TRAINER_CLOSED",
}
for _, e in ipairs(events) do pcall(FXP.RegisterEvent, FXP, e) end

FXP:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    ForeverXPCharDB = ForeverXPCharDB or {}
    self.db = ForeverXPCharDB
    if self.db.auto ~= nil then -- migrate v1.0 setting
      self.db.autoAccept, self.db.autoTurnin, self.db.auto = self.db.auto, self.db.auto, nil
    end
    for k, v in pairs(DEFAULTS) do if self.db[k] == nil then self.db[k] = v end end
    self.db.step = self.db.step or 1
    self:ResetXP()
    self:BuildQuestIndex()
    self:LearnZone()
    self:LearnQuestLog()
    if self.BuildUI then self:BuildUI() end
    if self.BuildArrow then self:BuildArrow() end
    if self.BuildMinimapButton then self:BuildMinimapButton() end
    local name = (self.db.guide and self.guides[self.db.guide]) and self.db.guide or self:PickGuide()
    if name then
      self:LoadGuide(name, (name == self.db.guide) and self.db.step or 1)
    else
      Print("No guide matches your character. Type /fxp to pick one.")
      self:Update()
    end
    -- travel steps and the XP footer need a slow poll
    C_Timer.NewTicker(1, function()
      self:LearnZone()
      local s = self:CurrentStep()
      if s and self:StepCoords(s) and not self.hold then self:Update()
      elseif self.RefreshFooter then self:RefreshFooter() end
    end)
  elseif not self.db then
    return
  elseif event == "QUEST_TURNED_IN" then
    local id = ...
    ns.turnedIn[id] = true
    self.lastTurnIn = GetTime()
    self:LearnQuest(id)
    self.hold = false
    self:QueueUpdate()
  elseif event == "QUEST_ACCEPTED" then
    local a, b = ...
    self:LearnQuest(b or a) -- Classic passes (logIndex, questID), modern passes (questID)
    self.hold = false
    self:QueueUpdate()
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    self:LearnZone()
    self:QueueUpdate()
  elseif event == "QUEST_DETAIL" then
    if Allowed("autoAccept") and self:Wanted("accept", GetQuestID(), GetTitleText()) then AcceptQuest() end
  elseif event == "QUEST_PROGRESS" then
    if Allowed("autoTurnin") and IsQuestCompletable() and self:Wanted("turnin", GetQuestID(), GetTitleText()) then CompleteQuest() end
  elseif event == "QUEST_COMPLETE" then
    if Allowed("autoTurnin") and self:Wanted("turnin", GetQuestID(), GetTitleText()) then
      if GetNumQuestChoices() <= 1 then
        GetQuestReward(GetNumQuestChoices())
      else
        Print("Pick your reward.")
      end
    end
  elseif event == "GOSSIP_SHOW" then
    self:OnGossip()
  elseif event == "QUEST_GREETING" then
    self:OnGreeting()
  elseif event == "TRAINER_CLOSED" then
    local st = self:CurrentStep()
    if st and st.train then
      self.db.trained = self.db.trained or {}
      self.db.trained[st.key] = true
      self.hold = false
      self:QueueUpdate()
    end
  elseif event == "PLAYER_XP_UPDATE" then
    self:OnXP()
    if self.RefreshFooter then self:RefreshFooter() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if self.SetCombatFade then self:SetCombatFade(true) end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if self.SetCombatFade then self:SetCombatFade(false) end
  else
    if event == "QUEST_ACCEPTED" or event == "PLAYER_LEVEL_UP" then self.hold = false end
    if event == "PLAYER_LEVEL_UP" then self:OnXP() end
    self:QueueUpdate()
  end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_FOREVERXP1, SLASH_FOREVERXP2 = "/fxp", "/foreverxp"
SlashCmdList.FOREVERXP = function(msg)
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  if not FXP.db then return end
  if cmd == "" or cmd == "options" or cmd == "config" then
    FXP:ToggleOptions()
  elseif cmd == "toggle" or cmd == "show" or cmd == "hide" then
    FXP:ToggleUI()
  elseif cmd == "next" then
    if FXP.guide then FXP:SetStep(FXP.db.step + 1) end
  elseif cmd == "prev" then
    if FXP.guide then FXP:SetStep(FXP.db.step - 1) end
  elseif cmd == "step" and tonumber(arg) then
    FXP:SetStep(tonumber(arg))
  elseif cmd == "list" then
    for _, n in ipairs(FXP.guideOrder) do
      local g = FXP.guides[n]
      Print("%s (%d-%d) %s", n, g.minLevel or 1, g.maxLevel or 0, g.faction or "")
    end
  elseif cmd == "load" then
    FXP:LoadGuide(arg)
  elseif cmd == "reset" then
    if FXP.guide then FXP:LoadGuide(FXP.guide.name, 1) end
  elseif cmd == "dungeons" or cmd == "dungeon" or cmd == "dg" then
    FXP:ToggleDungeons()
  elseif cmd == "questie" then
    if ns.Questie then ns.Questie:Report() end
  elseif cmd == "forgive" then
    FXP.db.xpDebt = 0; FXP:Update(); Print("Catch-up XP cleared.")
  elseif cmd == "xp" then
    FXP:ResetXP(); Print("XP/hour tracker reset.")
  elseif cmd == "arrow" then
    FXP.db.arrow = not FXP.db.arrow; FXP:RefreshArrow(); Print("Arrow: %s", FXP.db.arrow and "ON" or "OFF")
  elseif cmd == "lock" then
    FXP.db.locked = not FXP.db.locked; Print("Frames %s", FXP.db.locked and "locked" or "unlocked")
  elseif cmd == "talents" or cmd == "talent" then
    FXP:TalentReport()
  elseif cmd == "sync" then
    FXP:PushStep()
  elseif cmd == "hardcore" or cmd == "hc" then
    FXP:SetHardcore(not FXP.db.hardcore)
    Print("Hardcore mode %s.", FXP.db.hardcore and "|cffff4040ON|r (group/elite steps skipped, low-health alerts)" or "off")
  elseif cmd == "report" then
    FXP:Report(arg)
  elseif cmd == "check" then
    FXP:CheckRoute()
  elseif cmd == "export" then
    FXP:ShowExport()
  elseif cmd == "cleanup" then
    FXP:CleanupQuests()
  elseif cmd == "tier" then
    FXP:PreviewAscension(arg)
  elseif cmd == "pos" then
    local map = C_Map.GetBestMapForUnit("player")
    local p = map and C_Map.GetPlayerMapPosition(map, "player")
    if p then
      local x, y = p:GetXY()
      Print("map = %d, coords = { %.1f, %.1f }", map, x * 100, y * 100)
    else
      Print("Position unavailable here.")
    end
  else
    Print("/fxp — options and guide picker")
    Print("/fxp toggle | next | prev | step N | load <name> | reset | dungeons | xp | forgive | questie | arrow | lock | pos | cleanup | tier [level]")
    Print("Route feedback: /fxp report [note] | check | export")
    Print("Extras: /fxp talents | sync (push your step to the party) | hardcore")
    Print("Hold SHIFT while talking to an NPC to skip auto accept/turn-in.")
  end
end
