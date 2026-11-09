-- Compat.lua: hides API differences between Retail and the Classic clients.
local ADDON, ns = ...
local C = {}
ns.Compat = C
ns.turnedIn = {} -- quests turned in this session (faster than waiting on the server flag)

local CQL = C_QuestLog

local function LogIndex(id)
  if CQL and CQL.GetLogIndexForQuestID then
    local i = CQL.GetLogIndexForQuestID(id)
    if i and i > 0 then return i end
  end
  if GetQuestLogIndexByID then
    local i = GetQuestLogIndexByID(id)
    if i and i > 0 then return i end
  end
end

function C.IsTurnedIn(id)
  if ns.turnedIn[id] then return true end
  if CQL and CQL.IsQuestFlaggedCompleted then return CQL.IsQuestFlaggedCompleted(id) and true or false end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(id) and true or false end
  return false
end

function C.IsOnQuest(id)
  if CQL and CQL.IsOnQuest then return CQL.IsOnQuest(id) and true or false end
  return LogIndex(id) ~= nil
end

function C.IsComplete(id)
  if CQL and CQL.IsComplete then return CQL.IsComplete(id) and true or false end
  local i = LogIndex(id)
  if i and GetQuestLogTitle then
    local _, _, _, _, _, isComplete = GetQuestLogTitle(i)
    return isComplete == 1 or isComplete == true
  end
  return false
end

function C.Objectives(id)
  local out = {}
  if CQL and CQL.GetQuestObjectives then
    local ok, objs = pcall(CQL.GetQuestObjectives, id)
    if ok and type(objs) == "table" and #objs > 0 then
      for _, o in ipairs(objs) do out[#out + 1] = { text = o.text, done = o.finished } end
      return out
    end
  end
  local i = LogIndex(id)
  if i and GetNumQuestLeaderBoards then
    for j = 1, GetNumQuestLeaderBoards(i) do
      local text, _, done = GetQuestLogLeaderBoard(j, i)
      out[#out + 1] = { text = text, done = done }
    end
  end
  return out
end

function C.LogQuestIDs()
  local out = {}
  if CQL and CQL.GetNumQuestLogEntries and CQL.GetInfo then
    for i = 1, CQL.GetNumQuestLogEntries() do
      local info = CQL.GetInfo(i)
      if info and not info.isHeader and info.questID and info.questID > 0 then out[#out + 1] = info.questID end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for i = 1, GetNumQuestLogEntries() do
      local _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(i)
      if not isHeader and id and id > 0 then out[#out + 1] = id end
    end
  end
  return out
end

function C.LogFindTitle(title)
  if CQL and CQL.GetNumQuestLogEntries and CQL.GetInfo then
    for i = 1, CQL.GetNumQuestLogEntries() do
      local info = CQL.GetInfo(i)
      if info and not info.isHeader and info.title == title then return info.questID end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for i = 1, GetNumQuestLogEntries() do
      local t, _, _, isHeader, _, _, _, id = GetQuestLogTitle(i)
      if not isHeader and t == title then return id end
    end
  end
end

function C.Title(id)
  if not id then return end
  if CQL and CQL.GetTitleForQuestID then
    local t = CQL.GetTitleForQuestID(id)
    if t and t ~= "" then return t end
  end
  if CQL and CQL.GetQuestInfo then
    local t = CQL.GetQuestInfo(id)
    if t and t ~= "" then return t end
  end
end

-- World positions: vector.x = north/south axis, vector.y = east/west axis (west is positive).
function C.PlayerWorldPos()
  if not (C_Map and C_Map.GetBestMapForUnit) then return end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return end
  local pos = C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local cont, world = C_Map.GetWorldPosFromMapPos(map, pos)
  if not world then return end
  return cont, world.x, world.y
end

function C.MapToWorld(map, x, y)
  if not (map and C_Map and C_Map.GetWorldPosFromMapPos) then return end
  local cont, world = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(x / 100, y / 100))
  if world then return cont, world.x, world.y end
end

-- Gossip helpers (C_GossipInfo exists on Retail and current Classic clients)
function C.GossipActive()
  if C_GossipInfo and C_GossipInfo.GetActiveQuests then return C_GossipInfo.GetActiveQuests() or {} end
  return {}
end

function C.GossipAvailable()
  if C_GossipInfo and C_GossipInfo.GetAvailableQuests then return C_GossipInfo.GetAvailableQuests() or {} end
  return {}
end

function C.SelectGossipActive(q)
  if C_GossipInfo and C_GossipInfo.SelectActiveQuest then C_GossipInfo.SelectActiveQuest(q.questID) end
end

function C.SelectGossipAvailable(q)
  if C_GossipInfo and C_GossipInfo.SelectAvailableQuest then C_GossipInfo.SelectAvailableQuest(q.questID) end
end
