-- UI.lua: the guide window.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local WIDTH, PAD, HEADER = 300, 10, 24
local GREEN, GREY, YELLOW, WHITE = "|cff55ff55", "|cff9a9a9a", "|cffffd100", "|cffffffff"

local ICON = {
  accept   = "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14:0:0|t ",
  turnin   = "|TInterface\\GossipFrame\\ActiveQuestIcon:14:14:0:0|t ",
  complete = "|TInterface\\GossipFrame\\IncompleteQuestIcon:14:14:0:0|t ",
  level    = "|TInterface\\Icons\\Spell_Holy_SurgeOfLight:14:14:0:0:64:64:6:58:6:58|t ",
  text     = "|TInterface\\GossipFrame\\GossipGossipIcon:14:14:0:0|t ",
  train    = "|TInterface\\GossipFrame\\TrainerGossipIcon:14:14:0:0|t ",
  warn     = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14:14:0:0|t ",
  tip      = "|TInterface\\Common\\help-i:16:16:-1:0|t",
  done     = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:0|t ",
  todo     = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12:12:0:0|t ",
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function SavePos(frame, key)
  local point, _, rel, x, y = frame:GetPoint()
  FXP.db[key] = { point, rel, x, y }
end

function FXP:RestorePos(frame, key, default)
  frame:ClearAllPoints()
  local p = self.db[key]
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else frame:SetPoint(unpack(default)) end
end

function FXP:MakeMovable(frame, key, handle)
  handle = handle or frame
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", function() if not FXP.db.locked then frame:StartMoving() end end)
  handle:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePos(frame, key) end)
end

local function Tooltip(btn, text)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(text, 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function IconButton(parent, texture, size, tip, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  b:SetNormalTexture(texture .. "-Up")
  b:SetPushedTexture(texture .. "-Down")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  b:SetScript("OnClick", onClick)
  Tooltip(b, tip)
  return b
end

local function FormatTime(sec)
  if not sec or sec ~= sec or sec == math.huge then return "--" end
  sec = math.floor(sec)
  if sec >= 3600 then return string.format("%dh %dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
  return string.format("%dm", math.max(1, math.floor(sec / 60)))
end

local function FormatNumber(n)
  local s = tostring(math.floor(n + 0.5))
  local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (out:gsub("^,", ""))
end

---------------------------------------------------------------------------
-- Step text
---------------------------------------------------------------------------
function FXP:StepText(s, current)
  if not s then return "" end
  local lines = {}
  local function add(t) lines[#lines + 1] = t end
  local function npcFor(q, key)
    local name = s.npc
    if not name then
      local d = self:QuestData(q)
      name = d and d[key] and d[key].name
    end
    return name and (GREY .. " - " .. name .. "|r") or ""
  end
  local function reqFor(q)
    local d = self:QuestData(q)
    if d and d.req and UnitLevel("player") < d.req then return " |cffff4040(requires level " .. d.req .. ")|r" end
    return ""
  end

  if s.optional then add(GREY .. "(optional - only if offered)|r") end
  if s.elite or s.group then
    add("|cffff4040" .. (s.elite and "[Elite] " or "") ..
      (s.group and ("Group of " .. s.group .. "+ recommended") or "Group recommended") .. "|r")
  end
  if s.train then
    add(ICON.train .. WHITE .. "Visit your class trainer and buy new skills|r" ..
      (type(s.train) == "string" and (GREY .. " - " .. s.train .. "|r") or ""))
  end
  if s.classStep then add("|cffc69b6d[Class quest]|r") end
  if s.mount then
    local gold = math.floor(((GetMoney and GetMoney()) or 0) / 10000)
    add(ICON.train .. WHITE .. "Learn riding and buy your first mount|r " .. GREY .. "(you have " .. gold .. "g)|r")
  end
  if s.text then add(ICON.text .. WHITE .. s.text .. "|r") end
  if s.anyQuest then
    local names = {}
    for _, q in ipairs(s.anyQuest) do names[#names + 1] = YELLOW .. self:QuestName(q) .. "|r" end
    add(ICON.accept .. WHITE .. "Pick up|r " .. table.concat(names, GREY .. " or |r"))
  end
  if s.accept then
    for _, q in ipairs(s.accept) do
      local id = self:Resolve(q)
      local done = id and (C.IsOnQuest(id) or C.IsTurnedIn(id))
      add((done and ICON.done or ICON.accept) .. (done and GREEN or WHITE) .. "Accept|r " .. YELLOW .. self:QuestName(q) .. "|r" .. reqFor(q) .. npcFor(q, "start"))
    end
  end
  if s.complete then
    for _, q in ipairs(s.complete) do
      local id = self:Resolve(q)
      local done = id and (C.IsTurnedIn(id) or C.IsComplete(id))
      add((done and ICON.done or ICON.complete) .. (done and GREEN or WHITE) .. "Complete|r " .. YELLOW .. self:QuestName(q) .. "|r")
      if current and not done then
        for _, o in ipairs(id and C.Objectives(id) or {}) do
          add("     " .. (o.done and ICON.done or ICON.todo) .. (o.done and GREEN or GREY) .. (o.text or "") .. "|r")
        end
      end
    end
  end
  if s.turnin then
    for _, q in ipairs(s.turnin) do
      local id = self:Resolve(q)
      local done = id and C.IsTurnedIn(id)
      add((done and ICON.done or ICON.turnin) .. (done and GREEN or WHITE) .. "Turn in|r " .. YELLOW .. self:QuestName(q) .. "|r" .. npcFor(q, "finish"))
    end
  end
  if self.TravelText then for _, l in ipairs(self:TravelText(s)) do add(l) end end
  if s.level then
    add(ICON.level .. WHITE .. "Grind to level " .. s.level .. "|r " .. GREY .. "(now " .. UnitLevel("player") .. ")|r")
  end
  local th = self.theme or {}
  if s.warn then add(ICON.warn .. (th.warnPrefix or "") .. (th.warnColor or "|cffff8c1a") .. s.warn .. "|r") end
  if s.tip and current then
    add((th.tipPrefix and "" or ICON.tip) .. (th.tipPrefix or "") .. (th.tipColor or "|cff8fd3ff") .. s.tip .. "|r")
  elseif current and th.aphorisms and self.ThemeAphorism then
    add(th.tipPrefix .. GREY .. self:ThemeAphorism(self.db.step or 1) .. "|r")
  end
  local cx, cy = self:StepCoords(s)
  if cx and current then
    add(GREY .. string.format("     %.1f, %.1f%s", cx, cy, s.zone and ("  " .. s.zone) or "") .. "|r")
  end
  return table.concat(lines, "\n")
end

local function PlainStep(s)
  local txt = FXP:StepText(s)
  txt = txt:gsub("|T.-|t%s?", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  return txt
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function FXP:BuildUI()
  local f = CreateFrame("Frame", "ForeverXPFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(WIDTH, 120)
  f:SetFrameStrata("MEDIUM")
  f:SetScale(self.db.scale or 1)
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  f:SetBackdropColor(0.04, 0.05, 0.07, 0.88)
  f:SetBackdropBorderColor(0.2, 0.9, 0.55, 0.9)
  self:RestorePos(f, "framePos", { "RIGHT", UIParent, "RIGHT", -60, 120 })

  -- Header
  local h = CreateFrame("Frame", nil, f)
  h:SetPoint("TOPLEFT", 4, -4)
  h:SetPoint("TOPRIGHT", -4, -4)
  h:SetHeight(HEADER)
  h.bg = h:CreateTexture(nil, "BACKGROUND")
  h.bg:SetAllPoints()
  h.bg:SetColorTexture(0.2, 0.9, 0.55, 0.12)
  self:MakeMovable(f, "framePos", h)
  f.header = h

  local icon = h:CreateTexture(nil, "ARTWORK")
  icon:SetSize(16, 16)
  icon:SetPoint("LEFT", 6, 0)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.icon = icon

  f.title = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  f.title:SetPoint("RIGHT", h, "RIGHT", -102, 0)
  f.title:SetJustifyH("LEFT")
  f.title:SetWordWrap(false)

  local close = IconButton(h, "Interface\\Buttons\\UI-Panel-MinimizeButton", 22, "Hide (/fxp toggle)", function() FXP:ToggleUI() end)
  close:SetPoint("RIGHT", 2, 0)
  f.collapse = IconButton(h, "Interface\\Buttons\\UI-MinusButton", 14, "Collapse / expand", function()
    FXP.db.collapsed = not FXP.db.collapsed; FXP:RefreshUI()
  end)
  f.collapse:SetPoint("RIGHT", close, "LEFT", -2, 0)
  local nextB = IconButton(h, "Interface\\Buttons\\UI-SpellbookIcon-NextPage", 22, "Next step", function() SlashCmdList.FOREVERXP("next") end)
  nextB:SetPoint("RIGHT", f.collapse, "LEFT", -2, 0)
  local prevB = IconButton(h, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage", 22, "Previous step", function() SlashCmdList.FOREVERXP("prev") end)
  prevB:SetPoint("RIGHT", nextB, "LEFT", 2, 0)
  local report = IconButton(h, "Interface\\Icons\\INV_Misc_Note_01", 14, "Report a problem with this step (/fxp report)",
    function() FXP:Report() end)
  report:SetPoint("RIGHT", prevB, "LEFT", -2, 0)

  -- Guide progress bar
  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -1)
  bar:SetPoint("TOPRIGHT", h, "BOTTOMRIGHT", 0, -1)
  bar:SetHeight(3)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.2, 0.9, 0.55)
  bar.bg = bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetAllPoints()
  bar.bg:SetColorTexture(1, 1, 1, 0.08)
  f.bar = bar

  -- Body
  f.current = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.current:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", PAD - 4, -8)
  f.current:SetWidth(WIDTH - PAD * 2)
  f.current:SetJustifyH("LEFT")
  f.current:SetSpacing(3)

  -- "Learn" for the suggested talent (shown only while a talent point is waiting; Talents.lua)
  f.learn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.learn:SetSize(52, 18)
  f.learn:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", -6, -5)
  f.learn:SetText("Learn")
  if f.learn.SetNormalFontObject then f.learn:SetNormalFontObject("GameFontNormalSmall") end
  f.learn:SetScript("OnClick", function()
    local t = FXP.NextTalent and FXP:NextTalent()
    if t then FXP:LearnTalent(t) end
  end)
  f.learn:Hide()

  f.divider = f:CreateTexture(nil, "ARTWORK")
  f.divider:SetHeight(1)
  f.divider:SetPoint("TOPLEFT", f.current, "BOTTOMLEFT", 0, -8)
  f.divider:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  f.divider:SetColorTexture(1, 1, 1, 0.1)

  f.upcoming = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.upcoming:SetPoint("TOPLEFT", f.divider, "BOTTOMLEFT", 0, -6)
  f.upcoming:SetWidth(WIDTH - PAD * 2)
  f.upcoming:SetJustifyH("LEFT")
  f.upcoming:SetSpacing(2)

  f.footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.footer:SetPoint("BOTTOMLEFT", PAD, 8)
  f.footer:SetPoint("BOTTOMRIGHT", -PAD, 8)
  f.footer:SetJustifyH("LEFT")

  -- Flash on step complete
  f.flash = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  f.flash:SetPoint("TOPLEFT", 4, -4)
  f.flash:SetPoint("BOTTOMRIGHT", -4, 4)
  f.flash:SetColorTexture(0.2, 1, 0.5, 0)

  -- Right-click the window for options
  h:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then FXP:ToggleOptions() end end)
  Tooltip(h, "Drag to move\nRight-click for options")

  self.frame = f
  if self.ApplyTheme then self:ApplyTheme() end
  if self.db.hidden then f:Hide() end
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function FXP:FlashUI()
  local f = self.frame
  if not f then return end
  local t = 0
  local c = (self.theme and self.theme.flash) or { 0.2, 1, 0.5 }
  if self.ThemeOnComplete then self:ThemeOnComplete() end
  f.flash:SetAlpha(1)
  f:SetScript("OnUpdate", function(frame, dt)
    t = t + dt
    local a = math.max(0, 0.25 * (1 - t / 0.8))
    frame.flash:SetColorTexture(c[1], c[2], c[3], a)
    if t >= 0.8 then frame:SetScript("OnUpdate", nil) end
  end)
end

function FXP:RefreshFooter()
  local f = self.frame
  if not f or not f:IsShown() then return end
  if self:AtMaxLevel() then f.footer:SetText(""); return end
  local cur, max, perHour, eta = self:XPStats()
  if not cur then return end
  local pct = max > 0 and (cur / max * 100) or 0
  local rested = GetXPExhaustion and GetXPExhaustion()
  f.footer:SetText(string.format("|cffffd100Lvl %d|r  %s%.0f%%|r%s   %s%s xp/hr|r   %s%s to level|r",
    UnitLevel("player"), WHITE, pct,
    rested and (" |cff6fa8ff+" .. math.floor(rested / max * 100) .. "% rested|r") or "",
    GREY, perHour > 0 and FormatNumber(perHour) or "--",
    GREY, FormatTime(eta)))
end

function FXP:RefreshUI()
  local f = self.frame
  if not f then return end
  local collapsed = self.db.collapsed
  f.collapse:SetNormalTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
  f.collapse:SetPushedTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Down" or "Interface\\Buttons\\UI-MinusButton-Down")

  if not self.guide then
    f.title:SetText("ForeverXP")
    f.bar:SetMinMaxValues(0, 1); f.bar:SetValue(0)
    f.current:SetText(GREY .. "No guide loaded. Right-click the header or type /fxp to pick one.|r")
    f.upcoming:SetText(""); f.divider:Hide(); f.footer:SetText("")
    f:SetHeight(HEADER + f.current:GetStringHeight() + 30)
    return
  end

  local steps, i = self.guide.steps, self.db.step
  if self.theme and self.theme.title then
    f.title:SetText(self.theme.title(self.guide.name, i, #steps))
  else
    f.title:SetText(string.format("%s  |cff9a9a9a%d/%d|r", self.guide.name, i, #steps))
  end
  f.bar:SetMinMaxValues(0, #steps)
  f.bar:SetValue(i - 1)
  local body = self:StepText(steps[i], true)
  if self:InCatchUp() then
    local debt = self.db.xpDebt
    local mobs = UnitLevel("player")
    body = "|TInterface\\Icons\\Ability_DualWield:14:14:0:0:64:64:6:58:6:58|t |cffff6060Catch-up:|r " .. WHITE ..
      "grind " .. YELLOW .. FormatNumber(debt) .. " XP|r" .. WHITE .. " from mobs (level " .. (mobs - 1) .. "-" .. (mobs + 2) ..
      ") near here to make up for skipped steps.|r\n" ..
      GREY .. "Quest XP doesn't count. /fxp forgive to skip the grind.|r\n\n" ..
      GREY .. "Then:|r\n" .. body
  end
  -- lines from the phase 5 helpers, above the step: talent point, danger warning, party
  local extra, talent = {}, nil
  if self.TalentLine then talent = self:TalentLine(); if talent then extra[#extra + 1] = talent end end
  if self.DangerLine then local l = self:DangerLine(steps[i]); if l then extra[#extra + 1] = l end end
  if self.PartyLine then local l = self:PartyLine(); if l then extra[#extra + 1] = l end end
  if #extra > 0 then body = table.concat(extra, "\n") .. "\n" .. body end
  if f.learn then if talent then f.learn:Show() else f.learn:Hide() end end
  f.current:SetText(body)

  local height = HEADER + 3 + 8 + f.current:GetStringHeight() + 10
  if collapsed or (self.db.upcoming or 0) == 0 then
    f.upcoming:SetText(""); f.divider:Hide(); f.footer:Hide()
  else
    local lines = {}
    for j = i + 1, math.min(i + self.db.upcoming, #steps) do
      lines[#lines + 1] = PlainStep(steps[j])
    end
    f.upcoming:SetText(table.concat(lines, "\n"))
    f.divider:SetShown(#lines > 0)
    f.footer:Show()
    if #lines > 0 then height = height + 15 + f.upcoming:GetStringHeight() end
    self:RefreshFooter()
    if f.footer:GetText() and f.footer:GetText() ~= "" then height = height + 18 end
  end
  f:SetHeight(height)
end

function FXP:ToggleUI()
  if not self.frame then return end
  self.frame:SetShown(not self.frame:IsShown())
  self.db.hidden = not self.frame:IsShown()
  if self.frame:IsShown() then self:RefreshUI() end
end

function FXP:SetCombatFade(inCombat)
  local a = (inCombat and self.db.combatFade) and 0.35 or 1
  if self.frame then self.frame:SetAlpha(a) end
end
