-- Options.lua: options window, guide picker, minimap button.
local ADDON, ns = ...
local FXP = ns.FXP

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

---------------------------------------------------------------------------
-- Options window
---------------------------------------------------------------------------
local function Checkbox(parent, label, key, x, y, onChange)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", x, y)
  local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  fs:SetText(label)
  cb:SetScript("OnShow", function(self) self:SetChecked(FXP.db[key]) end)
  cb:SetScript("OnClick", function(self)
    FXP.db[key] = self:GetChecked() and true or false
    if onChange then onChange() end
  end)
  return cb
end

local function Stepper(parent, label, x, y, get, set)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("TOPLEFT", x, y)
  local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  minus:SetSize(22, 20); minus:SetText("-")
  minus:SetPoint("LEFT", fs, "RIGHT", 8, 0)
  local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  plus:SetSize(22, 20); plus:SetText("+")
  plus:SetPoint("LEFT", minus, "RIGHT", 2, 0)
  local function Draw() fs:SetText(label .. ": |cffffffff" .. get() .. "|r") end
  minus:SetScript("OnClick", function() set(-1); Draw() end)
  plus:SetScript("OnClick", function() set(1); Draw() end)
  parent:HookScript("OnShow", Draw)
  Draw()
end

local function ApplyScale()
  local s = FXP.db.scale
  if FXP.frame then FXP.frame:SetScale(s) end
  if FXP.arrow then FXP.arrow:SetScale(s) end
end

function FXP:BuildOptions()
  local f = CreateFrame("Frame", "ForeverXPOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(340, 876)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.04, 0.05, 0.07, 0.96)
  f:SetBackdropBorderColor(0.2, 0.9, 0.55, 0.9)
  self:MakeMovable(f, "optionsPos")
  table.insert(UISpecialFrames, "ForeverXPOptions") -- Escape closes it
  f:Hide()

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetText("ForeverXP")
  local ver = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ver:SetPoint("LEFT", title, "RIGHT", 8, -1)
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  ver:SetText("v" .. ((getMeta and getMeta(ADDON, "Version")) or "?"))

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 0, 0)

  local function Header(text, y)
    local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 14, y)
    h:SetText(text)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", h, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", f, "RIGHT", -14, 0)
    line:SetColorTexture(1, 1, 1, 0.12)
  end

  Header("Automation", -44)
  Checkbox(f, "Auto accept guide quests", "autoAccept", 12, -62)
  Checkbox(f, "Auto turn in guide quests", "autoTurnin", 12, -86)
  Checkbox(f, "Skip elite / group steps (solo leveling)", "skipGroup", 12, -110, function() FXP:Update() end)
  Checkbox(f, "Catch-up grinding after skipped steps", "catchUp", 12, -134, function() FXP:Update() end)
  Checkbox(f, "Pop up buttons for quest items to use", "questItems", 12, -158, function() FXP:RefreshItems() end)
  Checkbox(f, "Auto-train skills on guide trainer steps", "autoTrain", 12, -182)
  Stepper(f, "Keep at least (gold) when training", 16, -212,
    function() return FXP.db.trainReserve or 0 end,
    function(d) FXP.db.trainReserve = math.max(0, math.min(500, (FXP.db.trainReserve or 0) + d * 5)) end)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 40, -236)
  hint:SetText("Hold Shift when talking to an NPC to skip automation.")

  Header("Display", -258)
  Checkbox(f, "Show waypoint arrow", "arrow", 12, -276, function() FXP:RefreshArrow() end)
  Checkbox(f, "Play a sound when a step completes", "sound", 12, -300)
  Checkbox(f, "Fade the guide in combat", "combatFade", 12, -324)
  Checkbox(f, "Lock window and arrow position", "locked", 12, -348)
  Checkbox(f, "Hide minimap button", "minimapHide", 12, -372, function() FXP:RefreshMinimapButton() end)
  Checkbox(f, "Show hard-step warnings on screen", "announceWarnings", 12, -396)

  Header("Targeting", -426)
  Checkbox(f, "Pop up target buttons for the step's NPCs and mobs", "targetButtons", 12, -444, function() FXP:RefreshTargets() end)
  Checkbox(f, "Put a skull on targeted mobs when solo", "targetMark", 12, -468, function() FXP.lastMacroBody = nil; FXP:RefreshTargets() end)
  Checkbox(f, "Keep an 'FXP Target' macro for your action bar", "targetMacro", 12, -492, function() FXP.lastMacroBody = nil; FXP:RefreshTargets() end)
  Checkbox(f, "Pop up an on-screen target button when one is nearby", "targetPop", 12, -516, function() FXP:RefreshTargets() end)
  Checkbox(f, "...keep it on screen whenever the step has targets", "targetPopAlways", 12, -540, function() FXP:RefreshTargets() end)

  Stepper(f, "Scale", 16, -574,
    function() return string.format("%d%%", math.floor(FXP.db.scale * 100 + 0.5)) end,
    function(d) FXP.db.scale = math.max(0.6, math.min(1.6, FXP.db.scale + d * 0.1)); ApplyScale() end)
  Stepper(f, "Upcoming steps", 170, -574,
    function() return FXP.db.upcoming end,
    function(d) FXP.db.upcoming = math.max(0, math.min(5, FXP.db.upcoming + d)); FXP:RefreshUI() end)

  local themeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  themeLabel:SetPoint("TOPLEFT", 16, -604)
  local function DrawTheme()
    local t = ns.Themes and ns.Themes[FXP:ThemeIndex()]
    themeLabel:SetText("Theme: |cffffffff" .. (t and t.label or "Classic") .. "|r")
  end
  local tPrev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  tPrev:SetSize(22, 20); tPrev:SetPoint("TOPRIGHT", -42, -600); tPrev:SetText("<")
  tPrev:SetScript("OnClick", function() FXP:CycleTheme(-1); DrawTheme() end)
  local tNext = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  tNext:SetSize(22, 20); tNext:SetPoint("TOPRIGHT", -16, -600); tNext:SetText(">")
  tNext:SetScript("OnClick", function() FXP:CycleTheme(1); DrawTheme() end)
  f:HookScript("OnShow", DrawTheme)

  Header("Guides", -630)
  f.guideButtons = {}
  for i = 1, 6 do
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(312, 20)
    b:SetPoint("TOPLEFT", 14, -650 - (i - 1) * 22)
    b:SetScript("OnClick", function(self)
      if self.guideName then FXP:LoadGuide(self.guideName); FXP:RefreshOptions() end
    end)
    f.guideButtons[i] = b
  end

  local resetPos = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  resetPos:SetSize(120, 20)
  resetPos:SetPoint("BOTTOMRIGHT", -14, 12)
  resetPos:SetText("Reset positions")
  resetPos:SetScript("OnClick", function()
    FXP.db.framePos, FXP.db.arrowPos = nil, nil
    FXP:RestorePos(FXP.frame, "framePos", { "RIGHT", UIParent, "RIGHT", -60, 120 })
    FXP:RestorePos(FXP.arrow, "arrowPos", { "TOP", UIParent, "TOP", 0, -140 })
  end)

  local restart = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  restart:SetSize(120, 20)
  restart:SetPoint("RIGHT", resetPos, "LEFT", -6, 0)
  restart:SetText("Restart guide")
  restart:SetScript("OnClick", function() SlashCmdList.FOREVERXP("reset") end)

  local dungeons = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  dungeons:SetSize(312, 20)
  dungeons:SetPoint("BOTTOMLEFT", 14, 60)
  dungeons:SetText("Dungeon quests  (/fxp dungeons)")
  dungeons:SetScript("OnClick", function() FXP:ToggleDungeons() end)

  local cleanup = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  cleanup:SetSize(312, 20)
  cleanup:SetPoint("BOTTOMLEFT", 14, 36)
  cleanup:SetText("Clean up quests no guide uses  (/fxp cleanup)")
  cleanup:SetScript("OnClick", function() FXP:CleanupQuests() end)

  f:HookScript("OnShow", function() FXP:RefreshOptions() end)
  self.options = f
end

function FXP:RefreshOptions()
  local f = self.options
  if not f then return end
  -- fitting guides first, then the rest
  local list = {}
  for _, n in ipairs(self.guideOrder) do if self:GuideFits(self.guides[n]) then list[#list + 1] = n end end
  for _, n in ipairs(self.guideOrder) do if not self:GuideFits(self.guides[n]) then list[#list + 1] = n end end
  -- with many guides, show the ones closest to your level first
  local level = UnitLevel("player")
  local function dist(n)
    local g = self.guides[n]
    local d = 0
    if level < (g.minLevel or 1) then d = (g.minLevel or 1) - level
    elseif level > (g.maxLevel or 60) then d = level - (g.maxLevel or 60) end
    return (self:GuideFits(g) and 0 or 1000) + d
  end
  local order = {}
  for i, n in ipairs(list) do order[n] = i end
  table.sort(list, function(a, b)
    local da, db = dist(a), dist(b)
    if da ~= db then return da < db end
    return order[a] < order[b]
  end)
  for i, b in ipairs(f.guideButtons) do
    local name = list[i]
    if name then
      local g = self.guides[name]
      local active = self.guide and self.guide.name == name
      local fits = self:GuideFits(g)
      b.guideName = name
      b:SetText(string.format("%s%s  (%d-%d)%s", active and "|cff55ff55> " or (fits and "" or "|cff9a9a9a"),
        name, g.minLevel or 1, g.maxLevel or 0, (active or not fits) and "|r" or ""))
      b:Show()
    else
      b.guideName = nil
      b:Hide()
    end
  end
end

function FXP:ToggleOptions()
  if not self.options then self:BuildOptions() end
  self.options:SetShown(not self.options:IsShown())
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
local function PlaceMinimapButton(b)
  local a = math.rad(FXP.db.minimapAngle or 215)
  local r = (Minimap:GetWidth() / 2) + 8
  b:ClearAllPoints()
  b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

function FXP:BuildMinimapButton()
  local b = CreateFrame("Button", "ForeverXPMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then FXP:ToggleOptions() else FXP:ToggleUI() end
  end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      FXP.db.minimapAngle = math.deg(atan2(py / scale - my, px / scale - mx))
      PlaceMinimapButton(self)
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("ForeverXP", 0.2, 1, 0.6)
    if FXP.guide then GameTooltip:AddLine(FXP.guide.name .. "  (" .. FXP.db.step .. "/" .. #FXP.guide.steps .. ")", 1, 1, 1) end
    GameTooltip:AddLine("Left-click: show/hide guide", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click: options", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  self.minimapButton = b
  self:RefreshMinimapButton()
end

function FXP:RefreshMinimapButton()
  local b = self.minimapButton
  if not b then return end
  PlaceMinimapButton(b)
  b:SetShown(not self.db.minimapHide)
end
