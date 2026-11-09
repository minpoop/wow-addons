-- Arrow.lua: waypoint arrow that points to the current step's coordinates.
local ADDON, ns = ...
local FXP = ns.FXP

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local TWO_PI = 2 * math.pi

function FXP:BuildArrow()
  local a = CreateFrame("Button", "ForeverXPArrow", UIParent)
  a:SetSize(52, 52)
  a:SetScale(self.db.scale or 1)
  a:RegisterForClicks("RightButtonUp")
  self:MakeMovable(a, "arrowPos")
  self:RestorePos(a, "arrowPos", { "TOP", UIParent, "TOP", 0, -140 })

  a.tex = a:CreateTexture(nil, "OVERLAY")
  a.tex:SetAllPoints()
  a.tex:SetTexture(self.MEDIA .. "Arrow")

  a.check = a:CreateTexture(nil, "OVERLAY")
  a.check:SetSize(34, 34)
  a.check:SetPoint("CENTER")
  a.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  a.check:Hide()

  a.dist = a:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  a.dist:SetPoint("TOP", a, "BOTTOM", 0, -1)

  a.label = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  a.label:SetPoint("TOP", a.dist, "BOTTOM", 0, -1)
  a.label:SetWidth(200)
  a.label:SetWordWrap(false)

  a:SetScript("OnClick", function()
    FXP.db.arrow = false
    FXP:RefreshArrow()
    FXP.Print("Arrow hidden. Turn it back on with /fxp arrow")
  end)
  a:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("ForeverXP arrow", 1, 1, 1)
    GameTooltip:AddLine("Drag to move, right-click to hide", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  a:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local elapsed, shownAngle = 0, nil
  a:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.03 then return end
    local step = elapsed
    elapsed = 0
    local s = FXP:CurrentStep()
    local dist, dNorth, dWest = FXP:DistanceTo(s)
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not (dist and facing) then
      self.tex:Show(); self.check:Hide()
      self.tex:SetVertexColor(0.6, 0.6, 0.6, 0.4)
      self.dist:SetText("|cff9a9a9aNo direction here|r")
      return
    end

    if dist <= ((s and s.radius) or 12) then
      self.tex:Hide(); self.check:Show()
      self.dist:SetText("|cff55ff55Arrived|r")
      return
    end
    self.tex:Show(); self.check:Hide()

    -- angle from north, counter-clockwise (same convention as GetPlayerFacing)
    local target = (atan2(dWest, dNorth) - facing) % TWO_PI
    -- ease toward the target angle so the arrow glides instead of snapping
    if not shownAngle then shownAngle = target end
    local diff = ((target - shownAngle + math.pi) % TWO_PI) - math.pi
    shownAngle = (shownAngle + diff * math.min(1, step * 12)) % TWO_PI
    self.tex:SetRotation(shownAngle)

    -- green when facing it, through yellow, to red when facing away
    local off = math.abs(((shownAngle + math.pi) % TWO_PI) - math.pi) / math.pi
    local r, g = math.min(1, off * 2), math.min(1, 2 - off * 2)
    self.tex:SetVertexColor(r, g, 0.15, 1)

    local yards = math.floor(dist + 0.5)
    self.dist:SetText(yards >= 1000 and string.format("%.1fk yd", yards / 1000) or (yards .. " yd"))
  end)
  self.arrow = a
end

function FXP:RefreshArrow()
  if not self.arrow then return end
  local s = self:CurrentStep()
  local show = self.db.arrow and s and self:StepCoords(s) and not s.noArrow
  self.arrow:SetShown(show and true or false)
  if s then
    self.arrow.label:SetText(s.npc or (s.zone) or "")
  end

  -- Optional TomTom support (adds a world-map waypoint too)
  if TomTom and TomTom.AddWaypoint then
    local key = show and (self.guide.name .. ":" .. self.db.step) or nil
    if key == self.tomtomKey then return end
    self.tomtomKey = key
    if self.tomtomUID and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, self.tomtomUID) end
    self.tomtomUID = nil
    if show then
      local x, y, map = self:StepCoords(s)
      self.tomtomUID = TomTom:AddWaypoint(map, x / 100, y / 100,
        { title = "ForeverXP: " .. (s.npc or ("step " .. self.db.step)), persistent = false, crazy = false })
    end
  end
end
