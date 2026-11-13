-- Hardcore.lua: Phase 5 safety. For everyone: a warning line when the current step's mobs are well above your
-- level or elite (from Questie's creature data). In hardcore mode also: elite/group steps are skipped, the
-- warning is louder, and a big alert fires when your health drops low in combat.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

-- The scariest thing the step asks you to fight: highest level and any elites, for unfinished objectives.
function FXP:StepDanger(s)
  local QZ = ns.Questie
  if not (s and s.complete and QZ and QZ.ready and QZ.ObjectiveMobs) then return nil end
  local top, elite
  for _, q in ipairs(s.complete) do
    local id = self:Resolve(q)
    if id and not C.IsComplete(id) then
      for _, m in ipairs(QZ:ObjectiveMobs(id)) do
        if m.max and (not top or m.max > top.max) then top = m end
        local r = m.rank or 0 -- creature rank: 1 elite, 2 rare elite, 3 boss, 4 rare (not elite)
        if (r == 1 or r == 2 or r == 3) and not elite then elite = m end
      end
    end
  end
  if not (top or elite) then return nil end
  return { top = top, elite = elite, gap = top and (top.max - UnitLevel("player")) or 0 }
end

-- Guide window line (nil when nothing stands out).
function FXP:DangerLine(s)
  if self.db.dangerWarnings == false then return nil end
  local d = self:StepDanger(s)
  if not d then return nil end
  local hc = self.db.hardcore
  if d.elite then
    return string.format("|cffff3030%s %s is elite.|r", hc and "HARDCORE:" or "Careful:", d.elite.name)
  end
  local limit = hc and 2 or 3
  if d.gap >= limit then
    return string.format("|cffff6030%s mobs here go up to level %d (%d above you).|r", hc and "HARDCORE:" or "Careful:", d.top.max, d.gap)
  end
  return nil
end

-- Hardcore mode turns on solo routing (elite/group steps skipped), remembering the previous choice.
function FXP:SetHardcore(on)
  self.db.hardcore = on and true or false
  if on then
    self.db.skipGroupBeforeHC = self.db.skipGroup
    self.db.skipGroup = true
  elseif self.db.skipGroupBeforeHC ~= nil then
    self.db.skipGroup = self.db.skipGroupBeforeHC
    self.db.skipGroupBeforeHC = nil
  end
  if self.Update then self:Update() end
end

-- Low-health alert (hardcore): once per fight, when health drops under the threshold.
local alerted = false
function FXP:CheckHealth()
  if not self.db.hardcore then return end
  if not (UnitAffectingCombat and UnitAffectingCombat("player")) then alerted = false; return end
  local hp, max = UnitHealth("player"), UnitHealthMax("player")
  if not (hp and max and max > 0) then return end
  if hp / max < (self.db.lowHealth or 0.35) and not alerted then
    alerted = true
    local msg = string.format("LOW HEALTH (%d%%) - get out!", math.floor(hp / max * 100))
    if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 1, g = 0.1, b = 0.1 }) end
    if SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING) end
    if self.Print then self.Print("|cffff3030%s|r", msg) end
  end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_HEALTH", "PLAYER_REGEN_ENABLED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event, unit)
  if not FXP.db then return end
  if event == "PLAYER_REGEN_ENABLED" then alerted = false
  elseif unit == "player" then FXP:CheckHealth() end
end)
