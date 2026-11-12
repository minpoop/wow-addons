-- Questie.lua: reads quest data from Questie (and its WoW Forever QuestieDB) at runtime.
-- Questie is treated as the primary data source; Data/QuestDB.lua is the fallback.
-- Every call into Questie is wrapped in pcall so a Questie update can never break ForeverXP.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local Q = { ready = false, cache = {}, posCache = {}, byName = {}, byNameList = {}, indexDone = false }
ns.Questie = Q

local ALLIANCE_RACES = 77 -- Questie race mask: Human 1 + Dwarf 4 + Night Elf 8 + Gnome 64
local HORDE_RACES = 178   -- Orc 2 + Undead 16 + Tauren 32 + Troll 128

---------------------------------------------------------------------------
-- Connecting
---------------------------------------------------------------------------
local function Import(name)
  if not (QuestieLoader and QuestieLoader.ImportModule) then return end
  local ok, mod = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
  if ok and type(mod) == "table" then return mod end
end

function Q:Init()
  self.DB = Import("QuestieDB")
  self.ZoneDB = Import("ZoneDB")
  self.QuestXP = Import("QuestXP")
  -- QueryQuestSingle only exists once Questie has compiled its database after login
  if not (self.DB and type(self.DB.QueryQuestSingle) == "function") then return false end
  local ok, name = pcall(self.DB.QueryQuestSingle, 783, "name")
  if not (ok and name) then return false end
  self.ready = true
  return true
end

local function QQ(id, key)
  local ok, v = pcall(Q.DB.QueryQuestSingle, id, key)
  if ok then return v end
end
local function QN(id, key)
  if not Q.DB.QueryNPCSingle then return end
  local ok, v = pcall(Q.DB.QueryNPCSingle, id, key)
  if ok then return v end
end
local function QO(id, key)
  if not Q.DB.QueryObjectSingle then return end
  local ok, v = pcall(Q.DB.QueryObjectSingle, id, key)
  if ok then return v end
end
local function QI(id, key)
  if not Q.DB.QueryItemSingle then return end
  local ok, v = pcall(Q.DB.QueryItemSingle, id, key)
  if ok then return v end
end

local function UiMapForArea(areaId)
  local z = Q.ZoneDB
  if z and z.GetUiMapIdByAreaId then
    local ok, m = pcall(z.GetUiMapIdByAreaId, z, areaId)
    if ok and type(m) == "number" then return m end
  end
end

---------------------------------------------------------------------------
-- Quest rows
---------------------------------------------------------------------------
function Q:Row(id)
  if not (self.ready and type(id) == "number") then return end
  local c = self.cache[id]
  if c ~= nil then return c or nil end
  local name = QQ(id, "name")
  if not name then self.cache[id] = false return end
  local row = { id = id, name = name, level = QQ(id, "questLevel"), req = QQ(id, "requiredLevel"),
                races = QQ(id, "requiredRaces"), pre1 = QQ(id, "preQuestSingle"), preAll = QQ(id, "preQuestGroup") }
  local sb, fb = QQ(id, "startedBy"), QQ(id, "finishedBy")
  row.startNpc = sb and sb[1] and sb[1][1]
  row.startObj = sb and sb[2] and sb[2][1]
  row.finishNpc = fb and fb[1] and fb[1][1]
  row.finishObj = fb and fb[2] and fb[2][1]
  if self.QuestXP and self.QuestXP.GetQuestLogRewardXP then
    local ok, xp = pcall(self.QuestXP.GetQuestLogRewardXP, self.QuestXP, id, true)
    if ok and type(xp) == "number" and xp > 0 then row.xp = xp end
  end
  self.cache[id] = row
  return row
end

function Q:FitsFaction(row)
  local r = row and row.races
  if not r or r == 0 or not bit then return true end
  local horde = UnitFactionGroup("player") == "Horde"
  local mine, other = horde and HORDE_RACES or ALLIANCE_RACES, horde and ALLIANCE_RACES or HORDE_RACES
  -- only rule a quest out when it's clearly for the other faction (unknown race bits are allowed)
  return not (bit.band(r, mine) == 0 and bit.band(r, other) ~= 0)
end

-- Are the quest's prerequisites done? Returns ok, missingQuestID
function Q:PrereqsMet(row)
  if not row then return true end
  if type(row.preAll) == "table" then
    for _, p in ipairs(row.preAll) do
      if not C.IsTurnedIn(p) then return false, p end
    end
  end
  if type(row.pre1) == "table" and #row.pre1 > 0 then
    for _, p in ipairs(row.pre1) do
      if C.IsTurnedIn(p) then return true end
    end
    return false, row.pre1[1]
  end
  return true
end

---------------------------------------------------------------------------
-- Positions (nearest spawn to the player, cached for a few seconds)
---------------------------------------------------------------------------
function Q:NearestSpawn(spawns)
  if type(spawns) ~= "table" then return end
  local pc, px, py = C.PlayerWorldPos()
  local best, bestD
  for areaId, list in pairs(spawns) do
    local uiMap = UiMapForArea(areaId)
    if uiMap and type(list) == "table" then
      for _, c in ipairs(list) do
        local x, y = c[1], c[2]
        if x and y and x > 0 and y > 0 then
          local d = 1e12
          if pc then
            local tc, tx, ty = C.MapToWorld(uiMap, x, y)
            if tc and tc == pc then d = (tx - px) ^ 2 + (ty - py) ^ 2 end
          end
          if not bestD or d < bestD then best, bestD = { x = x, y = y, map = uiMap }, d end
        end
      end
    end
  end
  return best
end

local function Cached(key, fn)
  local e = Q.posCache[key]
  local now = GetTime()
  if e and now - e.t < 5 then return e.v end
  local v = fn()
  Q.posCache[key] = { t = now, v = v }
  return v
end

-- Quest giver ("start") or turn-in ("finish") as { name, x, y, map }
function Q:Endpoint(row, key)
  if not row then return end
  return Cached(row.id .. key, function()
    local npc = key == "start" and row.startNpc or row.finishNpc
    if npc then
      local p = self:NearestSpawn(QN(npc, "spawns")) or {}
      p.name = QN(npc, "name")
      return p
    end
    local obj = key == "start" and row.startObj or row.finishObj
    if obj then
      local p = self:NearestSpawn(QO(obj, "spawns")) or {}
      p.name = QO(obj, "name")
      return p
    end
  end)
end

-- Nearest place to work on a quest's objectives: mobs to kill, objects to use, or mobs that drop the item
function Q:ObjectivePos(id)
  if not self.ready then return end
  return Cached(id .. "obj", function()
    local objs = QQ(id, "objectives")
    if type(objs) ~= "table" then return end
    for _, o in ipairs(objs[1] or {}) do -- creatures
      local p = self:NearestSpawn(QN(o[1], "spawns"))
      if p then return p end
    end
    for _, o in ipairs(objs[2] or {}) do -- objects
      local p = self:NearestSpawn(QO(o[1], "spawns"))
      if p then return p end
    end
    for _, o in ipairs(objs[3] or {}) do -- items: look at who drops them
      for _, n in ipairs(QI(o[1], "npcDrops") or {}) do
        local p = self:NearestSpawn(QN(n, "spawns"))
        if p then return p end
      end
      for _, ob in ipairs(QI(o[1], "objectDrops") or {}) do
        local p = self:NearestSpawn(QO(ob, "spawns"))
        if p then return p end
      end
    end
  end)
end

-- Names of the creatures a quest's objectives need: mobs to kill, then the mobs that drop the quest items
-- (a few per item; objects can't be targeted). Used by the targeting buttons.
function Q:ObjectiveNames(id)
  if not self.ready then return {} end
  return Cached(id .. "names", function()
    local out, seen = {}, {}
    local function add(npcId)
      local name = npcId and QN(npcId, "name")
      if type(name) == "string" and not seen[name] then seen[name] = true; out[#out + 1] = name end
    end
    local objs = QQ(id, "objectives")
    if type(objs) ~= "table" then return out end
    for _, o in ipairs(objs[1] or {}) do add(o[1]) end -- creatures
    for _, o in ipairs(objs[3] or {}) do              -- items: who drops them
      local drops = QI(o[1], "npcDrops") or {}
      for i = 1, math.min(3, #drops) do add(drops[i]) end
    end
    return out
  end) or {}
end

-- Item IDs tied to a quest: the item that starts it / is handed to you, items it needs you to carry, and
-- items its objectives ask for. Used by the quest item buttons (which only show the usable ones you carry).
function Q:QuestItems(id)
  if not self.ready then return {} end
  return Cached(id .. "items", function()
    local out, seen = {}, {}
    local function add(item) if type(item) == "number" and not seen[item] then seen[item] = true; out[#out + 1] = item end end
    add(QQ(id, "sourceItemId"))
    for _, item in ipairs(QQ(id, "requiredSourceItems") or {}) do add(item) end
    local objs = QQ(id, "objectives")
    if type(objs) == "table" then for _, o in ipairs(objs[3] or {}) do add(o[1]) end end
    return out
  end) or {}
end

---------------------------------------------------------------------------
-- Quest names used by the guides -> Questie IDs (built in the background)
---------------------------------------------------------------------------
function Q:BuildNameIndex()
  local pointers = self.DB.QuestPointers or self.DB.questPointers
  if type(pointers) ~= "table" then return end
  local wanted = {}
  for _, g in pairs(FXP.guides) do
    for _, n in pairs(g.quests or {}) do wanted[n] = true end
    for _, s in ipairs(g.steps) do
      for _, list in ipairs({ s.accept or {}, s.complete or {}, s.turnin or {} }) do
        for _, q in ipairs(list) do
          if type(q) == "string" then wanted[(FXP.SplitName(q))] = true end
        end
      end
    end
  end
  local ids = {}
  for id in pairs(pointers) do ids[#ids + 1] = id end
  local i = 0
  local ticker
  ticker = C_Timer.NewTicker(0.05, function()
    for _ = 1, 400 do
      i = i + 1
      local id = ids[i]
      if not id then
        ticker:Cancel()
        -- order each name's quests the way a chain is played: by quest level, then ID
        for _, list in pairs(self.byNameList) do
          table.sort(list, function(a, b)
            local ra, rb = self:Row(a), self:Row(b)
            local la, lb = ra and ra.level or 0, rb and rb.level or 0
            if la ~= lb then return la < lb end
            return a < b
          end)
        end
        for name, list in pairs(self.byNameList) do self.byName[name] = list[1] end
        self.indexDone = true
        FXP:QueueUpdate()
        return
      end
      local name = QQ(id, "name")
      if name and wanted[name] then
        local row = self:Row(id)
        if self:FitsFaction(row) then
          self.byNameList[name] = self.byNameList[name] or {}
          table.insert(self.byNameList[name], id)
        end
      end
    end
  end)
end

---------------------------------------------------------------------------
-- Status report (/fxp questie)
---------------------------------------------------------------------------
function Q:Report()
  local P = FXP.Print
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local ver = getMeta and getMeta("Questie", "Version")
  P("Questie: %s%s", QuestieLoader and "installed" or "|cffff4040not found|r", ver and (" (v" .. ver .. ")") or "")
  P("Questie database: %s", self.ready and "|cff55ff55connected|r" or "|cffff4040not ready|r (it loads a few seconds after login)")
  if not self.ready then return end
  local n = 0
  for _ in pairs(self.byName) do n = n + 1 end
  P("Zone lookups: %s, XP data: %s, quest names matched: %d",
    self.ZoneDB and "yes" or "no", self.QuestXP and "yes" or "no", n)
  local s = FXP:CurrentStep()
  local q = s and ((s.turnin or s.accept or s.complete or {})[1])
  if q then
    local id = FXP:Resolve(q)
    local row = self:Row(id)
    if row then
      local e = self:Endpoint(row, s.turnin and "finish" or "start") or {}
      P("Current step: %s (%d) lvl %s req %s xp %s, NPC %s at %s",
        row.name, id, tostring(row.level), tostring(row.req), tostring(row.xp), tostring(e.name),
        e.x and string.format("%.1f, %.1f (map %s)", e.x, e.y, tostring(e.map)) or "?")
      local ok, missing = self:PrereqsMet(row)
      if not ok then P("Prerequisite missing: quest %s", tostring(missing)) end
    else
      P("Current step quest %s isn't in Questie's database.", tostring(q))
    end
  end
end

---------------------------------------------------------------------------
-- Wait for Questie after login
---------------------------------------------------------------------------
local waiter = CreateFrame("Frame")
waiter:RegisterEvent("PLAYER_LOGIN")
waiter:SetScript("OnEvent", function()
  local tries = 0
  local t
  t = C_Timer.NewTicker(2, function()
    tries = tries + 1
    if Q:Init() then
      t:Cancel()
      FXP.Print("Using Questie's quest database.")
      Q:BuildNameIndex()
      FXP:QueueUpdate()
    elseif tries >= 60 then
      t:Cancel()
      if not QuestieLoader then
        FXP.Print("Questie isn't installed. ForeverXP works best with Questie; using built-in data.")
      else
        FXP.Print("Couldn't read Questie's database; using built-in data. Type /fxp questie for details.")
      end
    end
  end)
end)
