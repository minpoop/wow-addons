-- Targeting.lua: "Target <name>" buttons that pop up under the guide window for the NPCs and mobs the
-- current step needs, glow when that unit is nearby, and an "FXP Target" macro for the action bar.
--
-- Targeting is a protected action, so the buttons are secure macro buttons. Their attributes, position and
-- visibility can only change out of combat; changes made in combat are queued until combat ends.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end end
local MAX_BUTTONS = 3
local MACRO_NAME = "FXP Target"
local SKULL = 8

BINDING_HEADER_FOREVERXP = "ForeverXP"
_G["BINDING_NAME_CLICK ForeverXPTarget1:LeftButton"] = "Target the step's NPC / mob"
_G["BINDING_NAME_CLICK ForeverXPTargetPop:LeftButton"] = "Target what's nearby (on-screen button)"

local function AsList(v)
  if v == nil then return {} end
  return type(v) == "table" and v or { v }
end

---------------------------------------------------------------------------
-- What to target
---------------------------------------------------------------------------
-- Targets for a step, most useful first: authored `target` names, the turn-in NPC, the quest giver,
-- then the mobs for unfinished objectives. Each entry is { name = "...", kind = "npc" | "mob" }.
function FXP:StepTargets(s)
  local out, seen = {}, {}
  local function add(name, kind)
    if type(name) == "string" and name ~= "" and not seen[name] then
      seen[name] = true
      out[#out + 1] = { name = name, kind = kind }
    end
  end
  if not s then return out end
  for _, n in ipairs(AsList(s.target)) do add(n, "mob") end
  for _, q in ipairs(s.turnin or {}) do
    local id = self:Resolve(q)
    if not (id and C.IsTurnedIn(id)) then
      local d = not s.npc and self:QuestData(q)
      add(s.npc or (d and d.finish and d.finish.name), "npc")
    end
  end
  for _, q in ipairs(s.accept or {}) do
    local id = self:Resolve(q)
    if not (id and (C.IsOnQuest(id) or C.IsTurnedIn(id))) then
      local d = not s.npc and self:QuestData(q)
      add(s.npc or (d and d.start and d.start.name), "npc")
    end
  end
  local QZ = ns.Questie
  if s.complete and QZ and QZ.ready then
    for _, q in ipairs(s.complete) do
      local id = self:Resolve(q)
      if id and C.IsOnQuest(id) and not C.IsComplete(id) then
        for _, n in ipairs(QZ:ObjectiveNames(id)) do add(n, "mob") end
      end
    end
  end
  return out
end

-- Macro text for one target. Mobs get a skull when you're solo (marking in a group would annoy others).
-- The mark only goes on if it isn't there yet, so a button that fires on both key down and up is harmless.
local MARK = "/run if UnitExists('target') and not UnitIsDead('target') and UnitCanAttack('player','target')" ..
  " and not IsInGroup() and GetRaidTargetIndex('target')~=" .. SKULL .. " then SetRaidTarget('target'," .. SKULL .. ") end"

function FXP:TargetMacroText(t)
  local text = "/cleartarget\n/targetexact " .. t.name
  if t.kind == "mob" and self.db.targetMark ~= false then text = text .. "\n" .. MARK end
  return text
end

-- Body for the action-bar macro: every target in one click (WoW keeps the last one it finds). Macros hold
-- at most 255 characters, so names that don't fit are left out and the skull line goes first.
function FXP:TargetMacroBody(targets)
  if #targets == 0 then return "/run print('|cff33ff99ForeverXP|r: nothing to target on this step.')" end
  local body = "/cleartarget"
  for _, t in ipairs(targets) do
    local line = "\n/targetexact " .. t.name
    if #body + #line > 255 then break end
    body = body .. line
  end
  local markable = false
  for _, t in ipairs(targets) do if t.kind == "mob" then markable = true end end
  if markable and self.db.targetMark ~= false and #body + 1 + #MARK <= 255 then body = body .. "\n" .. MARK end
  return body
end

---------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------
local holder, buttons, pop
local nearby, announced = {}, {}

local function Build()
  holder = CreateFrame("Frame", "ForeverXPTargets", UIParent)
  holder:SetSize(220, MAX_BUTTONS * 22)
  holder:SetFrameStrata("MEDIUM")
  holder:Hide()
  buttons = {}
  for i = 1, MAX_BUTTONS do
    local b = CreateFrame("Button", "ForeverXPTarget" .. i, holder, "SecureActionButtonTemplate")
    b:SetSize(220, 20)
    b:RegisterForClicks("AnyUp", "AnyDown") -- works with either setting of "cast on key down"
    b:SetAttribute("type", "macro")
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(0.04, 0.05, 0.07, 1)
    b.bg:SetAlpha(0.85)
    b.edge = b:CreateTexture(nil, "BORDER")
    b.edge:SetPoint("TOPLEFT", -1, 1); b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
    b.edge:SetColorTexture(1, 0.82, 0, 1)
    b.edge:SetAlpha(0.35)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16)
    b.icon:SetPoint("LEFT", 3, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 5, 0)
    b.text:SetPoint("RIGHT", -4, 0)
    b.text:SetJustifyH("LEFT")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnEnter", function(self)
      if not self.target then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Target " .. self.target.name, 1, 0.82, 0)
      GameTooltip:AddLine(self.target.kind == "npc" and "The NPC for this step." or "A mob this step needs.", 1, 1, 1)
      if i == 1 then GameTooltip:AddLine("Key binding: Key Bindings > AddOns > ForeverXP", 0.6, 0.6, 0.6) end
      GameTooltip:AddLine("Drag the 'FXP Target' macro onto a bar to target from there.", 0.6, 0.6, 0.6)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons[i] = b
  end
end

-- Puts the buttons just under the guide window, or just above it when it sits at the bottom of the screen.
-- Absolute coordinates on purpose: anchoring secure buttons to the (insecure) guide window would make the
-- guide window protected too, and then it couldn't fade or hide in combat.
local function Place(n)
  local f = FXP.frame
  holder:ClearAllPoints()
  holder:SetScale(f:GetScale())
  local left, bottom, top = f:GetLeft(), f:GetBottom(), f:GetTop()
  if not (left and bottom and top) then holder:SetPoint("TOP", UIParent, "CENTER", 0, -120); return end
  local below = bottom > n * 22 + 6
  if below then holder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom - 3)
  else holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, top + 3) end
  for i, b in ipairs(buttons) do
    b:ClearAllPoints()
    if below then b:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(i - 1) * 22)
    else b:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, (i - 1) * 22) end
  end
  holder.placed = { left, bottom, top, f:GetScale(), n }
end

local function Moved(n)
  local f, p = FXP.frame, holder.placed
  return not p or p[1] ~= f:GetLeft() or p[2] ~= f:GetBottom() or p[3] ~= f:GetTop() or p[4] ~= f:GetScale() or p[5] ~= n
end

-- Keeps the "FXP Target" macro in sync (out of combat, only when it changes).
function FXP:UpdateTargetMacro(targets)
  if not self.db.targetMacro or not (GetMacroIndexByName and CreateMacro and EditMacro) then return end
  local body = self:TargetMacroBody(targets)
  if body == self.lastMacroBody then return end
  local ok = pcall(function()
    local idx = GetMacroIndexByName(MACRO_NAME)
    if not idx or idx == 0 then
      local _, perChar = GetNumMacros()
      if (perChar or 0) >= (MAX_CHARACTER_MACROS or 18) then return end -- no free slot: leave the macros alone
      CreateMacro(MACRO_NAME, "INV_Misc_QuestionMark", body, true)
    else
      EditMacro(idx, MACRO_NAME, nil, body)
    end
  end)
  if ok then self.lastMacroBody = body end
end

---------------------------------------------------------------------------
-- The on-screen button: pops up when something the step needs is nearby
---------------------------------------------------------------------------
local function BuildPop()
  pop = CreateFrame("Button", "ForeverXPTargetPop", UIParent, "SecureActionButtonTemplate")
  pop:SetSize(44, 44)
  pop:SetFrameStrata("MEDIUM")
  pop:RegisterForClicks("AnyUp", "AnyDown")
  pop:SetAttribute("type", "macro")
  pop:SetMovable(true)
  pop:SetClampedToScreen(true)
  pop:RegisterForDrag("LeftButton")
  pop:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end
  end)
  pop:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    FXP.db.targetPopPos = { point, rel, x, y }
  end)
  local p = FXP.db.targetPopPos
  if p then pop:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else pop:SetPoint("CENTER", UIParent, "CENTER", 0, -160) end

  pop.glow = pop:CreateTexture(nil, "BACKGROUND")
  pop.glow:SetPoint("CENTER")
  pop.glow:SetSize(76, 76)
  pop.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  pop.glow:SetBlendMode("ADD")
  pop.icon = pop:CreateTexture(nil, "ARTWORK")
  pop.icon:SetAllPoints()
  pop.frame = pop:CreateTexture(nil, "OVERLAY")
  pop.frame:SetPoint("CENTER")
  pop.frame:SetSize(78, 78)
  pop.frame:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  pop.label = pop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  pop.label:SetPoint("TOP", pop, "BOTTOM", 0, -4)
  pop.hint = pop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  pop.hint:SetPoint("TOP", pop.label, "BOTTOM", 0, -1)
  pop:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  pop:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("ForeverXP: target what's nearby", 1, 0.82, 0)
    for _, t in ipairs(self.targets or {}) do
      GameTooltip:AddLine((nearby[t.name] and "|cff40ff40nearby|r  " or "") .. t.name, 1, 1, 1)
    end
    GameTooltip:AddLine("Shift-drag to move. Key binding: Key Bindings > AddOns > ForeverXP.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  pop:SetScript("OnLeave", function() GameTooltip:Hide() end)
  pop:Hide()
  FXP.targetPopButton = pop
end

-- Targets ordered so the nearby ones come last: /targetexact keeps the last unit it finds, so a click
-- lands on something that's actually here rather than a name from across the zone.
local function NearbyLast(targets)
  local far, near = {}, {}
  for _, t in ipairs(targets) do
    if nearby[t.name] then near[#near + 1] = t else far[#far + 1] = t end
  end
  for _, t in ipairs(near) do far[#far + 1] = t end
  return far, near
end

-- Out of combat only: show the button while a target is nearby (or always, if the player chose that).
function FXP:RefreshTargetPop()
  if not pop or (InCombatLockdown and InCombatLockdown()) then return end
  local targets = self.targets or {}
  local ordered, near = NearbyLast(targets)
  local want = self.db.targetPop and #targets > 0 and (#near > 0 or self.db.targetPopAlways)
  if not want then
    if pop:IsShown() then pop:Hide() end
    pop.key = nil
    return
  end
  local key = table.concat((function() local n = {} for i, t in ipairs(ordered) do n[i] = t.name end return n end)(), "|")
  if key ~= pop.key then
    pop.key = key
    pop.targets = targets
    pop:SetAttribute("macrotext", self:TargetMacroBody(ordered))
    local lead = near[#near] or targets[1]
    pop.lead = lead
    pop.icon:SetTexture(lead.kind == "npc" and "Interface\\Icons\\INV_Misc_Note_01" or "Interface\\Icons\\Ability_Hunter_SniperShot")
    pop.label:SetText((lead.kind == "npc" and "|cffffd100" or "|cffff6060") .. lead.name .. "|r")
    local extra = #near > 1 and ("+" .. (#near - 1) .. " more nearby") or (#near == 0 and "not in sight yet" or "click to target")
    pop.hint:SetText(extra)
  end
  if not pop:IsShown() then pop:Show(); pop.popT = 0 end
end

function FXP:RefreshTargets()
  if not (self.db and self.frame) then return end
  if not holder then Build(); BuildPop() end
  if InCombatLockdown and InCombatLockdown() then self.targetsDirty = true; return end
  self.targetsDirty = false

  local step = self.guide and self:CurrentStep()
  local targets = (step and not self:InCatchUp()) and self:StepTargets(step) or {}
  self.targets = targets
  if (step and step.key) ~= self.targetStepKey then self.targetStepKey = step and step.key; wipe(announced) end
  self:UpdateTargetMacro(targets)
  self:RefreshTargetPop()

  local n = math.min(#targets, MAX_BUTTONS)
  if not self.db.targetButtons or n == 0 or not self.frame:IsShown() then holder:Hide(); return end
  for i, b in ipairs(buttons) do
    local t = targets[i]
    b.target = t
    if t then
      b:SetAttribute("macrotext", self:TargetMacroText(t))
      b.icon:SetTexture(t.kind == "npc" and "Interface\\GossipFrame\\AvailableQuestIcon"
        or "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
      b.text:SetText((t.kind == "npc" and "|cffffd100Talk to|r " or "|cffff6060Target|r ") .. t.name)
      b:Show()
    else
      b:SetAttribute("macrotext", nil)
      b:Hide()
    end
  end
  Place(n)
  holder:Show()
end

---------------------------------------------------------------------------
-- "It's nearby": glow when a target's nameplate (or your mouseover) shows up
---------------------------------------------------------------------------
local function ScanNearby()
  wipe(nearby)
  if C_NamePlate and C_NamePlate.GetNamePlates then
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
      local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
      local name = unit and UnitName(unit)
      if name then nearby[name] = true end
    end
  end
  local mo = UnitExists and UnitExists("mouseover") and UnitName("mouseover")
  if mo then nearby[mo] = true end
end

local function Ping()
  if not (FXP.targets and FXP.db and FXP.db.targetButtons) then return end
  for _, t in ipairs(FXP.targets) do
    if nearby[t.name] and not announced[t.name] then
      announced[t.name] = true
      if FXP.Print then FXP.Print("|cffffd100%s|r is nearby - click its button to target it.", t.name) end
      if FXP.db.sound and SOUNDKIT and SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING then pcall(PlaySound, SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING) end
    end
  end
end

---------------------------------------------------------------------------
-- Driver: queued refreshes after combat, following the guide window, glow animation
---------------------------------------------------------------------------
local driver = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_REGEN_ENABLED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_TARGET_CHANGED" }) do
  pcall(driver.RegisterEvent, driver, e)
end
driver:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_ENABLED" then
    if FXP.targetsDirty then FXP:RefreshTargets() end
  else
    ScanNearby()
    Ping()
    FXP:RefreshTargetPop()
  end
end)

local acc, scan, t = 0, 0, 0
driver:SetScript("OnUpdate", function(_, dt)
  t = t + dt
  acc = acc + dt
  scan = scan + dt
  if scan > 1 then -- mouseover and nameplates can go away without an event we listen to
    scan = 0
    ScanNearby()
    FXP:RefreshTargetPop()
  end
  if acc > 0.25 then
    acc = 0
    if holder and FXP.frame and not (InCombatLockdown and InCombatLockdown()) then
      local shouldShow = FXP.db.targetButtons and FXP.targets and #FXP.targets > 0 and FXP.frame:IsShown()
      if shouldShow ~= holder:IsShown() then FXP:RefreshTargets()
      elseif holder:IsShown() and Moved(math.min(#FXP.targets, MAX_BUTTONS)) then Place(math.min(#FXP.targets, MAX_BUTTONS)) end
    end
  end
  if pop and pop:IsShown() then
    -- pop in (the glow swells then settles) and keep breathing; dim when the target has gone out of sight
    local any = false
    for _, tg in ipairs(pop.targets or {}) do if nearby[tg.name] then any = true end end
    pop.popT = (pop.popT or 1) + dt
    local swell = pop.popT < 0.35 and (1 + 0.6 * (1 - pop.popT / 0.35)) or 1
    pop.glow:SetSize(76 * swell, 76 * swell)
    pop.glow:SetVertexColor(any and 0.3 or 1, 1, any and 0.3 or 0.6)
    pop.glow:SetAlpha(any and (0.6 + 0.4 * math.sin(t * 6)) or 0.25)
    pop.icon:SetAlpha(any and 1 or 0.55)
  end
  if holder and holder:IsShown() then
    local pulse = 0.55 + 0.45 * math.sin(t * 5)
    for _, b in ipairs(buttons) do
      if b.target and nearby[b.target.name] then
        b.edge:SetColorTexture(0.3, 1, 0.3, 1); b.edge:SetAlpha(pulse)
      else
        b.edge:SetColorTexture(1, 0.82, 0, 1); b.edge:SetAlpha(0.35)
      end
    end
  end
end)
