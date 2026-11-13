-- Party.lua: Phase 5 group sync. Party members running ForeverXP share their guide and step over a hidden
-- addon channel; the guide window shows where they are, and you can follow the party leader's step.
-- Messages: "S\tguide\tstep" (my step) and "J\tguide\tstep" (leader: everyone following, jump here).
local ADDON, ns = ...
local FXP = ns.FXP

local wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end end
local PREFIX = "FXPSYNC"
local party = {} -- sender -> { guide, step, t }
FXP.partySteps = party

local function Send(kind, guide, step)
  if not (IsInGroup and IsInGroup()) then return end
  local f = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
  if not f then return end
  pcall(f, PREFIX, table.concat({ kind, guide or "", tostring(step or 0) }, "\t"), "PARTY")
end

local function Me() return UnitName("player") end
local function Short(name) return ((name or ""):gsub("%-.*$", "")) end -- "Name-Realm" -> "Name"

function FXP:BroadcastStep()
  if not (self.db and self.db.partySync and self.guide) then return end
  Send("S", self.guide.name, self.db.step)
end

-- /fxp sync: leader pushes their step to everyone who follows the leader.
function FXP:PushStep()
  if not self.guide then return end
  Send("J", self.guide.name, self.db.step)
  if self.Print then self.Print("Sent your step (%s #%d) to the party.", self.guide.name, self.db.step) end
end

local function IsLeader(sender)
  if not UnitIsGroupLeader then return false end
  for i = 1, 4 do
    local u = "party" .. i
    if UnitExists and UnitExists(u) and Short(UnitName(u)) == Short(sender) then return UnitIsGroupLeader(u) end
  end
  return false
end

function FXP:OnPartyMessage(msg, sender)
  if not (self.db and self.db.partySync) or Short(sender) == Me() then return end
  -- (not "strsplit and strsplit(...)": an and-expression keeps only the first return value)
  local kind, guide, step = msg:match("^(%a)\t(.-)\t(%d+)$")
  step = tonumber(step)
  if not (kind and guide and step) then return end
  party[Short(sender)] = { guide = guide, step = step, t = GetTime() }
  -- follow the leader: jump to their step when they move on (same guide), or when they push it to us
  if (kind == "J" or (self.db.partyFollow and IsLeader(sender))) and self.guides[guide] then
    if not self.guide or self.guide.name ~= guide then
      self:LoadGuide(guide, step)
    elseif self.db.step ~= step then
      self:SetStep(step, true) -- no catch-up grind for steps skipped by following the party
    end
  end
  if self.RefreshUI then self:RefreshUI() end
end

-- "Party: Ann #12 (same step), Bob Duskwood 20-24 #3" for the guide window (nil when alone).
function FXP:PartyLine()
  if not (self.db and self.db.partySync and IsInGroup and IsInGroup()) then return nil end
  local parts, now = {}, GetTime()
  for name, p in pairs(party) do
    if now - p.t < 300 then
      local where
      if self.guide and p.guide == self.guide.name then
        local d = p.step - self.db.step
        where = string.format("#%d%s", p.step, d == 0 and " (same step)" or (d > 0 and string.format(" (%d ahead)", d) or string.format(" (%d behind)", -d)))
      else
        where = string.format("%s #%d", p.guide, p.step)
      end
      parts[#parts + 1] = name .. " " .. where
    end
  end
  if #parts == 0 then return nil end
  table.sort(parts)
  return "|cff88ccffParty:|r |cffd0d0d0" .. table.concat(parts, ", ") .. "|r"
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "PLAYER_LOGIN" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event, prefix, msg, _, sender)
  if event == "PLAYER_LOGIN" then
    local f = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
    if f then pcall(f, PREFIX) end
  elseif event == "CHAT_MSG_ADDON" then
    if prefix == PREFIX then FXP:OnPartyMessage(msg, sender) end
  elseif event == "GROUP_ROSTER_UPDATE" then
    if not (IsInGroup and IsInGroup()) then wipe(party) end
    FXP:BroadcastStep()
  end
end)
-- keep everyone current even when nobody changes step
ev:SetScript("OnUpdate", function(self, dt)
  self.acc = (self.acc or 0) + dt
  if self.acc > 30 then self.acc = 0; FXP:BroadcastStep() end
end)
