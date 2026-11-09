-- Themes.lua: visual themes for the guide window.
-- Fan-made homages built only from WoW's own fonts and textures - no game logos or assets.
--   Classic         the original ForeverXP look
--   Fog Town        survival-horror fog: rust, drifting fog, radio static near danger
--   Spartan HUD     sci-fi shooter HUD: cyan visor lines, corner brackets, shield-recharge bar
--   Ashen Bonfire   dark-fantasy soulslike: ember-lit stone, serif text, big death / level-up banners
--   Imperial Gothic grimdark sci-fi: crimson and gold, skulls, litanies and thoughts for the day
local ADDON, ns = ...
local FXP = ns.FXP

local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Themes\\"
local F_FRIZ, F_ARIAL, F_MORPH = "Fonts\\FRIZQT__.TTF", "Fonts\\ARIALN.TTF", "Fonts\\MORPHEUS.TTF"

local THEMES = {
  {
    key = "classic", label = "Classic",
    bg = { 0.04, 0.05, 0.07, 0.88 }, border = { 0.2, 0.9, 0.55, 0.9 },
    edge = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, inset = 3,
    header = { 0.2, 0.9, 0.55, 0.12 }, bar = { 0.2, 0.9, 0.55 }, barHeight = 3,
    flash = { 0.2, 1, 0.5 }, icon = "Interface\\Icons\\INV_Misc_Book_09",
  },
  {
    key = "fog", label = "Fog Town",
    bg = { 0.10, 0.10, 0.10, 0.90 }, border = { 0.45, 0.16, 0.10, 0.95 },
    edge = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, inset = 3,
    header = { 0.35, 0.08, 0.05, 0.35 }, bar = { 0.55, 0.12, 0.08 }, barHeight = 3,
    flash = { 0.6, 0.6, 0.6 }, icon = "Interface\\Icons\\INV_Misc_Book_09", iconDesat = true,
    tex = "fog_world", texAlt = "fog_rust", overlay = "fog_grate", shade = 1.0,
    titleFont = { F_ARIAL, 13, "" }, bodyFont = { F_ARIAL, 13, "" },
    title = function(name, i, n) return string.format("|cffb8b0a8%s|r  |cff6e6a66%d/%d|r", name:lower(), i, n) end,
    warnPrefix = "|cffb03a2e... |r", warnColor = "|cffc0503c",
    tipColor = "|cffa8a8a8",
    effect = "fog",
  },
  {
    key = "spartan", label = "Spartan HUD",
    bg = { 0.01, 0.06, 0.09, 0.82 }, border = { 0.25, 0.85, 1.0, 0.85 },
    edge = WHITE8, edgeSize = 1, inset = 1,
    header = { 0.25, 0.85, 1.0, 0.10 }, bar = { 0.30, 0.90, 1.0 }, barHeight = 5,
    flash = { 0.3, 0.9, 1.0 }, icon = false, tex = "hud_hex", shade = 1.0,
    titleFont = { F_ARIAL, 13, "OUTLINE" }, bodyFont = { F_ARIAL, 13, "" },
    title = function(name, i, n) return string.format("|cff7fe7ff%s|r  |cff3fa7c7[%02d/%02d]|r", name:upper(), i, n) end,
    warnPrefix = "|cffff5050WARNING: |r", warnColor = "|cffffb0a0",
    tipPrefix = "|cff7fe7ffINTEL: |r", tipColor = "|cffbfefff",
    completeText = "|cff7fe7ffCHECKPOINT|r",
    effect = "spartan",
  },
  {
    key = "ashen", label = "Ashen Bonfire",
    bg = { 0.03, 0.025, 0.02, 0.93 }, border = { 1.0, 0.5, 0.15, 0.8 },
    edge = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16, inset = 4,
    header = { 0.9, 0.4, 0.1, 0.08 }, bar = { 0.85, 0.45, 0.12 }, barHeight = 3,
    flash = { 1.0, 0.55, 0.15 }, icon = false, tex = "ashen_stone", shade = 0.9,
    titleFont = { F_MORPH, 15, "" }, bodyFont = { F_FRIZ, 12, "" },
    title = function(name, i, n) return string.format("|cffe8d5b0%s|r  |cff8a7a62%d/%d|r", name, i, n) end,
    warnPrefix = "|cffd04020Beware: |r", warnColor = "|cffe0a080",
    tipPrefix = "|cffc9a35aTry |r", tipColor = "|cffd8c8a8",
    completeText = "|cffe8c070Objective attained|r",
    banners = { level = { "LEVEL ASCENDED", 0.95, 0.80, 0.40 }, death = { "THOU HAST FALLEN", 0.75, 0.08, 0.06 } },
    effect = "ashen",
  },
  {
    key = "imperial", label = "Imperial Gothic",
    bg = { 0.14, 0.02, 0.02, 0.92 }, border = { 1.0, 0.82, 0.35, 1.0 },
    edge = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 16, inset = 4,
    header = { 0.6, 0.05, 0.05, 0.45 }, bar = { 0.85, 0.68, 0.22 }, barHeight = 3,
    flash = { 1.0, 0.8, 0.3 }, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    tex = "imperial_plate", shade = 0.85, seal = "imperial_seal",
    titleFont = { F_MORPH, 14, "" }, bodyFont = { F_FRIZ, 12, "" },
    title = function(name, i, n) return string.format("|cffd4af37+++|r |cffefe2c0%s|r |cffd4af37+++|r |cff9a7d4a%d/%d|r", name, i, n) end,
    warnPrefix = "|cffd02020HERETIC THREAT: |r", warnColor = "|cffe8a090",
    tipPrefix = "|cffd4af37Thought for the day: |r", tipColor = "|cffefe2c0",
    completeText = "|cffd4af37+++ OBJECTIVE PURGED +++|r",
    aphorisms = {
      "A quest abandoned is a quest betrayed.",
      "Experience is earned in blood and turned in at the nearest outpost.",
      "Rest is for the rested-XP bar.",
      "Blessed is the mind too busy questing to doubt.",
      "Grind without complaint. Level without pause.",
      "Even the humblest boar serves the great tally.",
      "Hope is the first step on the road to a wipe.",
      "Only the vigilant read the step text twice.",
    },
    effect = "imperial",
  },
}
ns.Themes = THEMES

local function Theme(key)
  for _, t in ipairs(THEMES) do if t.key == key then return t end end
  return THEMES[1]
end

function FXP:ThemeIndex()
  for i, t in ipairs(THEMES) do if t.key == (self.db and self.db.theme) then return i end end
  return 1
end

function FXP:CycleTheme(d)
  local i = (self:ThemeIndex() - 1 + d) % #THEMES + 1
  self.db.theme = THEMES[i].key
  self:ApplyTheme()
  return THEMES[i].label
end

---------------------------------------------------------------------------
-- Effect layers (built once, shown only for the theme that uses them)
---------------------------------------------------------------------------
local function Tex(parent, layer, sub, r, g, b, a)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetColorTexture(r, g, b, a or 1)
  return t
end

local function BuildFx(f)
  if f.fx then return f.fx end
  local fx = CreateFrame("Frame", nil, f)
  fx:SetAllPoints()
  fx:SetFrameLevel(f:GetFrameLevel())
  f.fx = fx

  -- Tiled background textures (Media/Themes/*.tga): base, alternate (cross-fades in), see-through overlay
  local function Layer(sub)
    local t = f:CreateTexture(nil, "BACKGROUND", nil, sub)
    t:Hide()
    return t
  end
  fx.base, fx.alt, fx.over = Layer(-3), Layer(-2), Layer(-1)
  fx.seal = f:CreateTexture(nil, "OVERLAY", nil, 6)
  fx.seal:SetSize(32, 64)
  fx.seal:SetPoint("TOP", f, "BOTTOMLEFT", 34, 10)
  fx.seal:Hide()
  f:HookScript("OnSizeChanged", function() FXP:TileThemeTextures() end)

  -- Fog Town: two drifting fog sheets + static
  fx.fog1 = Tex(f, "BORDER", 1, 0.75, 0.75, 0.73, 0.08)
  fx.fog1:SetPoint("TOPLEFT", 4, -30); fx.fog1:SetPoint("BOTTOMRIGHT", -4, 4)
  fx.fog2 = Tex(f, "BORDER", 2, 0.85, 0.85, 0.82, 0.06)
  fx.fog2:SetPoint("TOPLEFT", 40, -50); fx.fog2:SetPoint("BOTTOMRIGHT", -60, 20)
  fx.static = {}
  for i = 1, 14 do
    local s = Tex(f, "BORDER", 3, 1, 1, 1, 0)
    s:SetHeight(1)
    fx.static[i] = s
  end

  -- Spartan HUD: corner brackets + scan line + shield sweep
  fx.brackets = {}
  local corners = { { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 }, { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 } }
  for _, c in ipairs(corners) do
    local hz = Tex(f, "OVERLAY", 7, 0.5, 0.95, 1, 0.95); hz:SetSize(14, 2); hz:SetPoint(c[1], c[2], c[3])
    local vt = Tex(f, "OVERLAY", 7, 0.5, 0.95, 1, 0.95); vt:SetSize(2, 14); vt:SetPoint(c[1], c[2], c[3])
    fx.brackets[#fx.brackets + 1] = hz; fx.brackets[#fx.brackets + 1] = vt
  end
  fx.scan = Tex(f, "BORDER", 4, 0.4, 0.9, 1, 0.12)
  fx.scan:SetHeight(1)
  fx.sweep = Tex(f.bar, "OVERLAY", 7, 0.85, 1, 1, 0)
  fx.sweep:SetSize(40, 7)

  -- Ashen Bonfire: rising embers
  fx.embers = {}
  for i = 1, 6 do
    local e = Tex(f, "BORDER", 5, 1, 0.55, 0.15, 0)
    e:SetSize(2, 2)
    fx.embers[i] = { tex = e, x = math.random(10, 280), y = math.random(0, 60), speed = 8 + math.random() * 10 }
  end

  -- Imperial Gothic: candle-glow pulse behind the header
  fx.glow = Tex(f.header, "BACKGROUND", 1, 0.9, 0.3, 0.1, 0)
  fx.glow:SetAllPoints()

  -- Completion caption (Spartan / Ashen / Imperial)
  fx.caption = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fx.caption:SetPoint("BOTTOM", f.header, "BOTTOM", 0, -16)
  fx.caption:SetAlpha(0)
  return fx
end

local function HideAllFx(fx)
  fx.base:Hide(); fx.alt:Hide(); fx.over:Hide(); fx.seal:Hide()
  fx.fog1:Hide(); fx.fog2:Hide()
  for _, s in ipairs(fx.static) do s:Hide() end
  for _, b in ipairs(fx.brackets) do b:Hide() end
  fx.scan:Hide(); fx.sweep:Hide(); fx.glow:Hide()
  for _, e in ipairs(fx.embers) do e.tex:Hide() end
end

local function StepHasWarning()
  local s = FXP.guide and FXP.guide.steps[FXP.db.step]
  return s and s.warn
end

local EFFECTS = {}

function EFFECTS.fog(f, fx, t, dt)
  -- the "shift": danger steps slowly peel the plaster away into rusted metal behind a grate
  local target = StepHasWarning() and 1 or 0
  fx.shift = fx.shift or 0
  if fx.shift < target then fx.shift = math.min(target, fx.shift + dt * 0.35)
  elseif fx.shift > target then fx.shift = math.max(target, fx.shift - dt * 0.25) end
  local sh = fx.shift
  fx.base:SetAlpha(1 - sh * (0.85 + 0.15 * math.random()))
  fx.alt:SetAlpha(sh)
  fx.over:SetAlpha(sh * 0.85)
  local fogK = 1 - sh * 0.6
  fx.fog1:SetAlpha((0.07 + 0.05 * math.sin(t * 0.35)) * fogK)
  fx.fog2:ClearAllPoints()
  local drift = 30 * math.sin(t * 0.12)
  fx.fog2:SetPoint("TOPLEFT", 40 + drift, -50); fx.fog2:SetPoint("BOTTOMRIGHT", -60 + drift, 20)
  fx.fog2:SetAlpha((0.05 + 0.04 * math.sin(t * 0.5 + 1)) * fogK)
  -- radio static: constant crackle on dangerous steps, random bursts otherwise
  fx.nextBurst = fx.nextBurst or (t + 4)
  if t > fx.nextBurst then fx.burstUntil = t + 0.25 + math.random() * 0.3; fx.nextBurst = t + 4 + math.random() * 6 end
  local crackle = StepHasWarning() or (fx.burstUntil and t < fx.burstUntil)
  local h = f:GetHeight()
  for _, s in ipairs(fx.static) do
    if crackle and math.random() < 0.5 then
      s:ClearAllPoints()
      s:SetPoint("TOPLEFT", f, "TOPLEFT", 4 + math.random(0, 60), -math.random(4, math.max(5, math.floor(h) - 4)))
      s:SetWidth(math.random(40, 220))
      s:SetAlpha(0.05 + math.random() * 0.12)
      s:Show()
    else
      s:Hide()
    end
  end
  -- the border occasionally bleeds red
  if crackle and math.random() < 0.08 then f:SetBackdropBorderColor(0.7, 0.05, 0.03, 1)
  elseif math.random() < 0.2 then f:SetBackdropBorderColor(0.45, 0.16, 0.10, 0.95) end
end

function EFFECTS.spartan(f, fx, t, dt)
  local h = f:GetHeight()
  local y = (t * 40) % math.max(1, h)
  fx.scan:ClearAllPoints()
  fx.scan:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -y)
  fx.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -y)
  local pulse = 0.75 + 0.2 * math.sin(t * 2)
  for _, b in ipairs(fx.brackets) do b:SetAlpha(pulse) end
  if fx.sweepT then
    fx.sweepT = fx.sweepT + dt
    local w = f.bar:GetWidth()
    local x = (fx.sweepT / 0.6) * (w + 40) - 40
    fx.sweep:ClearAllPoints()
    fx.sweep:SetPoint("LEFT", f.bar, "LEFT", x, 0)
    fx.sweep:SetAlpha(0.8 * (1 - fx.sweepT / 0.6))
    if fx.sweepT >= 0.6 then fx.sweepT = nil; fx.sweep:SetAlpha(0) end
  end
end

function EFFECTS.ashen(f, fx, t, dt)
  fx.heat = math.max(0.35, math.min(1, (fx.heat or 0.7) + (math.random() - 0.5) * 0.25))
  f:SetBackdropBorderColor(1.0, 0.35 + 0.25 * fx.heat, 0.1, 0.55 + 0.35 * fx.heat)
  local w = f:GetWidth()
  for _, e in ipairs(fx.embers) do
    e.y = e.y + e.speed * dt
    if e.y > 70 then e.y = 0; e.x = math.random(10, math.max(11, math.floor(w) - 10)); e.speed = 8 + math.random() * 10 end
    e.tex:ClearAllPoints()
    e.tex:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", e.x + 3 * math.sin(t * 2 + e.speed), 4 + e.y)
    e.tex:SetAlpha(0.9 * (1 - e.y / 70))
  end
end

function EFFECTS.imperial(f, fx, t, dt)
  fx.glow:SetAlpha(0.06 + 0.05 * math.sin(t * 1.3) + 0.02 * math.random())
  if fx.seal.SetRotation then fx.seal:SetRotation(0.06 * math.sin(t * 0.9)) end -- the seal sways
end

local function RunCaption(fx, t, dt)
  if not fx.capT then return end
  fx.capT = fx.capT + dt
  local a = fx.capT < 0.2 and fx.capT / 0.2 or math.max(0, 1 - (fx.capT - 1.2) / 0.6)
  fx.caption:SetAlpha(a)
  if fx.capT > 1.8 then fx.capT = nil; fx.caption:SetAlpha(0) end
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------
local function SetFont(fs, spec, fallbackObject)
  if spec then fs:SetFont(spec[1], spec[2], spec[3] or "") else fs:SetFontObject(fallbackObject) end
end

function FXP:ApplyTheme()
  local f = self.frame
  if not f then return end
  local th = Theme(self.db.theme)
  self.theme = th

  f:SetBackdrop({ bgFile = WHITE8, edgeFile = th.edge, edgeSize = th.edgeSize,
    insets = { left = th.inset, right = th.inset, top = th.inset, bottom = th.inset } })
  f:SetBackdropColor(unpack(th.bg))
  f:SetBackdropBorderColor(unpack(th.border))
  f.header.bg:SetColorTexture(unpack(th.header))
  f.bar:SetStatusBarColor(unpack(th.bar))
  f.bar:SetHeight(th.barHeight or 3)

  if f.icon then
    if th.icon then
      f.icon:SetTexture(th.icon); f.icon:Show()
      f.icon:SetTexCoord(th.icon:find("RaidTargeting") and 0 or 0.08, th.icon:find("RaidTargeting") and 1 or 0.92,
        th.icon:find("RaidTargeting") and 0 or 0.08, th.icon:find("RaidTargeting") and 1 or 0.92)
      if f.icon.SetDesaturated then f.icon:SetDesaturated(th.iconDesat and true or false) end
    else
      f.icon:Hide()
    end
  end

  SetFont(f.title, th.titleFont, "GameFontNormal")
  SetFont(f.current, th.bodyFont, "GameFontHighlight")

  local fx = BuildFx(f)
  HideAllFx(fx)
  fx.caption:SetFont(th.titleFont and th.titleFont[1] or F_FRIZ, 14, "OUTLINE")
  local function Use(layer, name, alpha)
    if not name then return end
    layer:SetTexture(TEX .. name, "REPEAT", "REPEAT")
    layer:ClearAllPoints()
    layer:SetPoint("TOPLEFT", th.inset, -th.inset)
    layer:SetPoint("BOTTOMRIGHT", -th.inset, th.inset)
    local k = th.shade or 1
    layer:SetVertexColor(k, k, k)
    layer:SetAlpha(alpha)
    layer:Show()
  end
  Use(fx.base, th.tex, 1)
  Use(fx.alt, th.texAlt, 0)
  Use(fx.over, th.overlay, 0)
  fx.shift = 0
  if th.seal then fx.seal:SetTexture(TEX .. th.seal); fx.seal:Show() end
  self:TileThemeTextures()

  local e = th.effect
  if e == "fog" then fx.fog1:Show(); fx.fog2:Show() end
  if e == "spartan" then
    for _, b in ipairs(fx.brackets) do b:Show() end
    fx.scan:Show(); fx.sweep:Show(); fx.sweep:SetAlpha(0)
  end
  if e == "ashen" then for _, em in ipairs(fx.embers) do em.tex:Show() end end
  if e == "imperial" then fx.glow:Show() end

  local t = 0
  fx:SetScript("OnUpdate", function(_, dt)
    t = t + dt
    if EFFECTS[e] and f:IsShown() then EFFECTS[e](f, fx, t, dt) end
    RunCaption(fx, t, dt)
  end)

  if self.RefreshUI then self:RefreshUI() end
end

-- Keep textures at native pixel scale (tiled, not stretched) whatever the window size.
function FXP:TileThemeTextures()
  local f = self.frame
  if not (f and f.fx) then return end
  local w, h = f:GetWidth() or 300, f:GetHeight() or 150
  for _, layer in ipairs({ f.fx.base, f.fx.alt, f.fx.over }) do
    layer:SetTexCoord(0, w / 256, 0, h / 256)
  end
end

-- Called when a step completes (from FlashUI).
function FXP:ThemeOnComplete()
  local f, th = self.frame, self.theme
  if not (f and f.fx and th) then return end
  if th.effect == "spartan" then f.fx.sweepT = 0 end
  if th.effect == "fog" then f.fx.nextBurst = 0 end -- a burst of static on every completed step
  if th.completeText then
    f.fx.caption:SetText(th.completeText)
    f.fx.capT = 0
  end
end

-- Thought-for-the-day lines when a step has no tip of its own (Imperial Gothic).
function FXP:ThemeAphorism(stepIndex)
  local th = self.theme
  if not (th and th.aphorisms) then return nil end
  return th.aphorisms[(stepIndex % #th.aphorisms) + 1]
end

---------------------------------------------------------------------------
-- Full-screen banners (Ashen Bonfire): death and level-up
---------------------------------------------------------------------------
local banner
local function ShowBanner(text, r, g, b)
  if not banner then
    banner = CreateFrame("Frame", nil, UIParent)
    banner:SetFrameStrata("FULLSCREEN_DIALOG")
    banner:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    banner:SetSize(4000, 110)
    banner.band = banner:CreateTexture(nil, "BACKGROUND")
    banner.band:SetAllPoints()
    banner.band:SetColorTexture(0, 0, 0, 0.75)
    banner.text = banner:CreateFontString(nil, "OVERLAY")
    banner.text:SetFont(F_MORPH, 56, "")
    banner.text:SetPoint("CENTER")
    banner:Hide()
  end
  banner.text:SetText(text)
  banner.text:SetTextColor(r, g, b)
  local t = 0
  banner:SetAlpha(0); banner:Show()
  banner:SetScript("OnUpdate", function(self, dt)
    t = t + dt
    local a = t < 1 and t or (t < 3.5 and 1 or math.max(0, 1 - (t - 3.5)))
    self:SetAlpha(a)
    banner.text:SetScale(1 + t * 0.015)
    if t > 4.5 then self:Hide(); self:SetScript("OnUpdate", nil) end
  end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_DEAD")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function(_, event)
  local th = FXP.theme
  if not (th and th.banners) then return end
  local b = (event == "PLAYER_DEAD") and th.banners.death or th.banners.level
  if b then ShowBanner(b[1], b[2], b[3], b[4]) end
end)
