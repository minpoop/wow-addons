-- Pins.lua: Phase 3 map pins. The current step (gold) and the next few (faded) are marked on the world map
-- and the minimap. The current step's minimap pin sticks to the rim when it's out of range.
-- Plain frames on the map canvas / minimap, no libraries: positions are recomputed while the map is open.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local PIN = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Pin"
local MAX_PINS = 4
local CURRENT = { 1.0, 0.82, 0.1 }
local AHEAD = { 0.55, 0.85, 1.0 }

-- Minimap diameter in yards per zoom level (0 = most zoomed out).
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }
local INDOOR = { [0] = 300, 240, 180, 120, 80, 50 }

local function Plain(text) -- first line of step text without colour codes / icons, for tooltips
  text = (text or ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  return (text:match("^[^\n]*") or ""):gsub("^%s+", "")
end

---------------------------------------------------------------------------
-- Which steps get pins
---------------------------------------------------------------------------
-- Current step plus the next `mapPinsAhead` steps that aren't done and have a place on the map.
function FXP:PinSteps()
  local c = self.pinCache
  if c and c.guide == self.guide and c.step == self.db.step and GetTime() - c.t < 0.5 then return c.list end
  local out = self:BuildPinSteps()
  self.pinCache = { guide = self.guide, step = self.db.step, t = GetTime(), list = out }
  return out
end

function FXP:BuildPinSteps()
  local out = {}
  if not (self.guide and (self.db.mapPins or self.db.minimapPins)) then return out end
  local steps, i = self.guide.steps, self.db.step
  local ahead = self.db.mapPinsAhead or 2
  while i <= #steps and #out < 1 + ahead and #out < MAX_PINS do
    local s = steps[i]
    if i == self.db.step or not self:IsStepDone(s) then
      local x, y, map = self:StepCoords(s)
      if x and map then
        out[#out + 1] = { step = s, index = i, n = #out + 1, x = x, y = y, map = map, current = (#out == 0 and i == self.db.step) }
      end
    end
    i = i + 1
  end
  return out
end

-- Pin position on a given map (0-1), converting through world coordinates when it's another map
-- (so the current zone's pins also show on the continent map).
function FXP:PinOnMap(p, mapID)
  if p.map == mapID then return p.x / 100, p.y / 100 end
  if not (C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return end
  local cont, wx, wy = C.MapToWorld(p.map, p.x, p.y)
  if not cont then return end
  local _, pos = C_Map.GetMapPosFromWorldPos(cont, CreateVector2D(wx, wy), mapID)
  if not pos then return end
  local x, y = pos.x, pos.y
  if pos.GetXY then x, y = pos:GetXY() end
  if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then return x, y end
end

-- Minimap offset in pixels from the centre for a target dNorth/dWest yards away.
-- Returns x, y, onEdge. `rotate` follows the "rotate minimap" setting (player facing is up).
function FXP:MinimapOffset(dNorth, dWest, facing, rotate, zoom, indoors, size)
  local yards = (indoors and INDOOR or OUTDOOR)[zoom or 0] or OUTDOOR[0]
  local scale = (size / 2) / (yards / 2)
  local x, y = -dWest, dNorth
  if rotate and facing then
    local c, s = math.cos(-facing), math.sin(-facing)
    x, y = x * c - y * s, x * s + y * c
  end
  x, y = x * scale, y * scale
  local r = math.sqrt(x * x + y * y)
  local edge = size / 2 - 6
  if r > edge then return x / r * edge, y / r * edge, true end
  return x, y, false
end

---------------------------------------------------------------------------
-- Pin frames
---------------------------------------------------------------------------
local function MakePin(parent, size)
  local p = CreateFrame("Frame", nil, parent)
  p:SetSize(size, size)
  p.tex = p:CreateTexture(nil, "OVERLAY")
  p.tex:SetAllPoints()
  p.tex:SetTexture(PIN)
  p.num = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p.num:SetPoint("CENTER", 0, 0)
  p.num:SetTextColor(0, 0, 0)
  p:EnableMouse(true)
  p:SetScript("OnEnter", function(self)
    if not self.info then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine((self.info.current and "Current step" or ("Step " .. self.info.index)) .. " - ForeverXP", 1, 0.82, 0)
    GameTooltip:AddLine(Plain(FXP:StepText(self.info.step, false)), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  p:SetScript("OnLeave", function() GameTooltip:Hide() end)
  p:Hide()
  return p
end

local function Paint(pin, info)
  pin.info = info
  local c = info.current and CURRENT or AHEAD
  pin.tex:SetVertexColor(c[1], c[2], c[3])
  pin:SetAlpha(info.current and 1 or 0.7)
  pin.num:SetText(info.n)
end

---------------------------------------------------------------------------
-- World map
---------------------------------------------------------------------------
local worldPins, worldDriver
local function WorldMapReady() return WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame.GetMapID end

function FXP:RefreshWorldPins()
  if not WorldMapReady() then return end
  local canvas = WorldMapFrame:GetCanvas()
  if not worldPins then
    worldPins = {}
    for i = 1, MAX_PINS do worldPins[i] = MakePin(canvas, 22) end
  end
  local mapID = WorldMapFrame:GetMapID()
  local list = (self.db.mapPins and WorldMapFrame:IsShown() and mapID) and self:PinSteps() or {}
  local zoom = (WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.GetCanvasScale
    and WorldMapFrame.ScrollContainer:GetCanvasScale()) or 1
  local w, h = canvas:GetWidth(), canvas:GetHeight()
  for i, pin in ipairs(worldPins) do
    local info = list[i]
    local x, y
    if info then x, y = self:PinOnMap(info, mapID) end
    if x then
      Paint(pin, info)
      -- keep pins the same size on screen however far the map is zoomed: shrink the pin by the canvas zoom
      -- and scale its offset back up, because offsets are in the pin's own (scaled) units
      local s = (info.current and 1 or 0.8) / zoom
      pin:SetScale(s)
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", canvas, "TOPLEFT", x * w / s, -y * h / s)
      pin:SetFrameLevel(canvas:GetFrameLevel() + 2000 + (info.current and 10 or 0))
      pin:Show()
    else
      pin:Hide()
    end
  end
end

local function HookWorldMap()
  if worldDriver or not WorldMapReady() then return end
  worldDriver = CreateFrame("Frame", nil, WorldMapFrame)
  local acc = 0
  worldDriver:SetScript("OnUpdate", function(_, dt) -- only runs while the map is open
    acc = acc + dt
    if acc > 0.1 then acc = 0; FXP:RefreshWorldPins() end
  end)
  worldDriver:SetScript("OnHide", function() if worldPins then for _, p in ipairs(worldPins) do p:Hide() end end end)
end

---------------------------------------------------------------------------
-- Minimap
---------------------------------------------------------------------------
local miniPins
function FXP:RefreshMinimapPins()
  if not Minimap then return end
  if not miniPins then
    miniPins = {}
    for i = 1, MAX_PINS do miniPins[i] = MakePin(Minimap, 14) end
  end
  local list = self.db.minimapPins and self:PinSteps() or {}
  local pc, px, py = C.PlayerWorldPos()
  local facing = GetPlayerFacing and GetPlayerFacing()
  local rotate = GetCVar and GetCVar("rotateMinimap") == "1"
  local zoom = Minimap.GetZoom and Minimap:GetZoom() or 0
  local indoors = IsIndoors and IsIndoors()
  local size = Minimap:GetWidth() or 140
  for i, pin in ipairs(miniPins) do
    local info = list[i]
    local shown = false
    if info and pc then
      local tc, tx, ty = C.MapToWorld(info.map, info.x, info.y)
      if tc and tc == pc then
        local x, y, edge = self:MinimapOffset(tx - px, ty - py, facing, rotate, zoom, indoors, size)
        if not edge or info.current then -- only the current step clings to the rim
          Paint(pin, info)
          if edge then pin:SetAlpha(0.6) end
          pin:ClearAllPoints()
          pin:SetPoint("CENTER", Minimap, "CENTER", x, y)
          pin:Show()
          shown = true
        end
      end
    end
    if not shown then pin:Hide() end
  end
end

---------------------------------------------------------------------------
-- Driver
---------------------------------------------------------------------------
local driver = CreateFrame("Frame")
pcall(driver.RegisterEvent, driver, "PLAYER_LOGIN")
pcall(driver.RegisterEvent, driver, "ADDON_LOADED")
driver:SetScript("OnEvent", function() HookWorldMap() end)
local acc = 0
driver:SetScript("OnUpdate", function(_, dt)
  acc = acc + dt
  if acc < 0.1 or not FXP.db then return end
  acc = 0
  HookWorldMap()
  FXP:RefreshMinimapPins()
end)
