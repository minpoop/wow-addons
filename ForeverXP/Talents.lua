-- Talents.lua: Phase 5 talent guide. Follows Data/Talents.lua for your class: when you have an unspent
-- point it shows what to take next in the guide window (with a Learn button), or learns it for you if you turn
-- that on. Talents are looked up by name in the live talent tree, so anything WoW Forever renamed or moved is
-- skipped and listed by /fxp talents instead of breaking the suggestion.
local ADDON, ns = ...
local FXP = ns.FXP

local function Class() local _, c = UnitClass("player"); return c end

function FXP:TalentBuild() return (ns.TalentBuilds or {})[Class() or ""] end

-- Every talent in the live tree: name -> { tab, index, tier, rank, max, tabName }, plus points spent per tab.
function FXP:TalentTree()
  local byName, spent, tabs = {}, {}, {}
  local nTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 0
  for tab = 1, nTabs do
    local tabName, _, pts = GetTalentTabInfo(tab)
    tabs[tab] = tabName
    local sum = 0
    for i = 1, (GetNumTalents and GetNumTalents(tab)) or 0 do
      local name, _, tier, _, rank, maxRank = GetTalentInfo(tab, i)
      if name then
        sum = sum + (rank or 0)
        if not byName[name] then
          byName[name] = { tab = tab, index = i, tier = tier or 1, rank = rank or 0, max = maxRank or 1, tabName = tabName }
        end
      end
    end
    spent[tab] = (type(pts) == "number" and pts) or sum
  end
  return byName, spent, tabs
end

local function Unspent()
  if UnitCharacterPoints then
    local p = UnitCharacterPoints("player")
    if type(p) == "number" then return p end
  end
  if GetUnspentTalentPoints then return GetUnspentTalentPoints() or 0 end
  return 0
end

-- Can this talent take one more rank right now? Returns ok, reason.
local function Learnable(t, spent)
  if t.rank >= t.max then return false, "maxed" end
  if (spent[t.tab] or 0) < (t.tier - 1) * 5 then
    return false, string.format("needs %d points in %s", (t.tier - 1) * 5, t.tabName or "its tree")
  end
  if GetTalentPrereqs then
    local preTier, preCol, ok = GetTalentPrereqs(t.tab, t.index)
    if preTier and not ok then return false, "needs the talent above it first" end
  end
  return true
end

-- The next talent to take, following the build in order. Returns suggestion (or nil), plus a list of build
-- entries that couldn't be found or taken (for /fxp talents).
function FXP:NextTalent()
  local b = self:TalentBuild()
  if not b then return nil, {} end
  local tree, spent = self:TalentTree()
  local want, problems, first = {}, {}, nil
  for _, e in ipairs(b.build) do
    local name, n = e[1], e[2]
    want[name] = (want[name] or 0) + n
    local t = tree[name]
    if not t then
      problems[#problems + 1] = { name = name, issue = "not in this game's talent trees (renamed in WoW Forever?)" }
    elseif t.rank < want[name] then
      local ok, why = Learnable(t, spent)
      if ok and not first then
        first = { name = name, tab = t.tab, index = t.index, rank = t.rank, max = t.max, tree = t.tabName, target = want[name] }
      elseif not ok and why ~= "maxed" and not first then
        problems[#problems + 1] = { name = name, issue = why }
      end
    end
  end
  return first, problems
end

function FXP:LearnTalent(s)
  if not (s and LearnTalent) or (InCombatLockdown and InCombatLockdown()) then return false end
  local ok = pcall(LearnTalent, s.tab, s.index)
  if ok and self.Print then self.Print("Learned |cffffd100%s|r (%d/%d, %s).", s.name, s.rank + 1, s.max, s.tree or "") end
  return ok
end

-- One line for the guide window when a point is waiting (nil otherwise).
function FXP:TalentLine()
  if not self.db.talents or Unspent() <= 0 then return nil end
  local s = self:NextTalent()
  if not s then return nil end
  return string.format("|TInterface\\Icons\\Ability_Marksmanship:14:14:0:0:64:64:6:58:6:58|t |cffffd100Talent point:|r |cffffffff%s|r |cff9a9a9a(%d/%d, %s)|r",
    s.name, s.rank + 1, s.max, s.tree or "")
end

-- Spend points: automatically if the player chose that, otherwise nothing (the window shows the Learn button).
function FXP:OnTalentPoints()
  if not self.db.talents then return end
  -- one point per event: learning fires CHARACTER_POINTS_CHANGED again, which takes the next one with a fresh
  -- view of the tree (looping here could read ranks the client hasn't updated yet)
  if self.db.autoTalents and Unspent() > 0 then
    local s = self:NextTalent()
    if s then self:LearnTalent(s) end
  end
  if self.RefreshUI then self:RefreshUI() end
end

-- /fxp talents: the build, where you are in it, and anything that can't be followed.
function FXP:TalentReport()
  local b = self:TalentBuild()
  if not b then self.Print("No talent build for your class yet.") return end
  local s, problems = self:NextTalent()
  self.Print("Talent build: %s.%s", b.name, s and string.format(" Next: %s (%d/%d).", s.name, s.rank + 1, s.max) or " All done.")
  for _, p in ipairs(problems) do self.Print("  |cffff8040%s|r: %s", p.name, p.issue) end
  ForeverXPDB = ForeverXPDB or {}
  ForeverXPDB.talentIssues = { class = Class(), problems = problems }
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_TALENT_UPDATE" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function()
  if FXP.db then FXP:OnTalentPoints() end
end)
