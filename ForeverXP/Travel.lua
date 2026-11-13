-- Travel.lua: Phase 2 travel helpers.
--   * Flight master automation: on a `fly` step, the flight master's map picks the guide's destination.
--   * Flight timer: a bar with time left (learned per route, account-wide) while you're on a flight.
--   * Hearthstone: `bind` steps set your hearthstone at the innkeeper; `hearth` steps offer the Hearthstone
--     as a quest item button and finish when you arrive.
--   * Flight paths: `fp` steps finish once you know the flight path; entering a zone with a flight path you
--     haven't got prints a reminder.
-- Shift held at an NPC skips all of it, like the other automation.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local HEARTHSTONE = 6948
local TAXI_ICON, BINDER_ICON = 132057, 132052 -- gossip option icons (flight master / innkeeper "make this inn your home")

local function Lower(s) return type(s) == "string" and s:lower() or "" end
-- "Sentinel Hill, Westfall" vs "sentinel hill": either one inside the other, ignoring case and the ", Zone" part.
local function Same(a, b)
  a = (Lower(a):gsub(",.*$", ""))
  b = (Lower(b):gsub(",.*$", ""))
  if a == "" or b == "" then return false end
  return a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
end
FXP.SamePlace = Same

local function Here()
  return (GetSubZoneText and GetSubZoneText()) or "", (GetZoneText and GetZoneText()) or "",
    (GetMinimapZoneText and GetMinimapZoneText()) or ""
end

local function IsHere(place)
  if not place then return false end
  local sub, zone, mini = Here()
  return Same(sub, place) or Same(zone, place) or Same(mini, place)
end

local function Shifted() return IsShiftKeyDown and IsShiftKeyDown() end

---------------------------------------------------------------------------
-- Known flight paths (per character)
---------------------------------------------------------------------------
function FXP:KnowsFlight(name)
  for known in pairs(self.db.knownFlights or {}) do
    if Same(known, name) then return true end
  end
  return false
end

local function LearnFlight(name)
  if not name or name == "" then return end
  FXP.db.knownFlights = FXP.db.knownFlights or {}
  FXP.db.knownFlights[(name:gsub(",.*$", ""))] = true
end

---------------------------------------------------------------------------
-- Step completion for travel fields (called from IsStepDone)
---------------------------------------------------------------------------
-- `fp` and `bind` are real goals: the step waits for them. `fly` and `hearth` are how you get somewhere, so
-- they only finish a step on their own when it has nothing else to check.
-- Getting a flight path or setting the Hearthstone is advice, not a wall: once you've been at the step's spot
-- and then leave the area, the step counts as done (you either have it already or chose not to).
function FXP:MovedOn(s)
  if not (s.coords and self.DistanceTo) then return false end
  local d = self:DistanceTo(s)
  if not d then return false end
  local r = s.radius or 12
  self.db.arrived = self.db.arrived or {}
  if d <= r then self.db.arrived[s.key] = true; return false end
  if self.db.arrived[s.key] and d > math.max(r * 3, 60) then
    if not (self.movedOnSaid and self.movedOnSaid[s.key]) then
      self.movedOnSaid = self.movedOnSaid or {}
      self.movedOnSaid[s.key] = true
      if self.Print then self.Print("Moved on from %s - skipping its flight path / Hearthstone step.", s.fp or s.bind or "here") end
    end
    return true
  end
  return false
end

-- You've already done the step after this one (e.g. took the next quest in the same town): this one is moot.
function FXP:NextStepDone(s)
  if self.inNextCheck or not (self.guide and s.key) then return false end
  local i = tonumber(s.key:match(":(%d+)$"))
  local nxt = i and self.guide.steps[i + 1]
  if not (nxt and (nxt.accept or nxt.turnin or nxt.complete)) then return false end
  self.inNextCheck = true
  local ok, done = pcall(self.IsStepDone, self, nxt)
  self.inNextCheck = false
  return ok and done or false
end

function FXP:TravelDone(s, hasOther)
  local missing = false
  if s.fp and not self:KnowsFlight(s.fp) then missing = true end
  if s.bind then
    local home = GetBindLocation and GetBindLocation()
    if not Same(home, s.bind) then missing = true end
  end
  if missing then return self:MovedOn(s) or self:NextStepDone(s) end
  if not hasOther then
    if s.fly and not (IsHere(s.fly) or (self.db.flown and self.db.flown[s.key])) then return false end
    if s.hearth and not (IsHere(s.hearth) or (self.db.hearthed and self.db.hearthed[s.key])) then return false end
  end
  return true
end

-- Hearthstone button on `hearth` steps (shown by the quest item bar from Helpers.lua).
function FXP:TravelItems(s)
  if s and s.hearth and not IsHere(s.hearth) then return { HEARTHSTONE } end
  return {}
end

-- Extra lines for the guide window.
function FXP:TravelText(s)
  local out = {}
  local W, Y, G, GR = "|cffffffff", "|cffffff00", "|cff33ff33", "|cff9a9a9a"
  local function line(icon, done, text) out[#out + 1] = icon .. (done and G or W) .. text .. "|r" end
  local FLY = "|TInterface\\GossipFrame\\TaxiGossipIcon:14:14|t "
  local INN = "|TInterface\\GossipFrame\\BinderGossipIcon:14:14|t "
  if s.fp then
    local known = self:KnowsFlight(s.fp)
    line(FLY, known, "Get the " .. Y .. s.fp .. "|r" .. W .. " flight path" ..
      (known and "" or (GR .. " (already have it? just talk to the flight master)")))
  end
  if s.bind then
    local home = GetBindLocation and GetBindLocation()
    line(INN, Same(home, s.bind), "Set your Hearthstone in " .. Y .. s.bind .. "|r" ..
      ((home and home ~= "" and not Same(home, s.bind)) and (GR .. " (now " .. home .. ")") or ""))
  end
  if s.fly then line(FLY, IsHere(s.fly), "Fly to " .. Y .. s.fly .. "|r" .. GR .. " (picked for you at the flight master)") end
  if s.hearth then
    local start, dur = 0, 0
    local cd = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if cd then start, dur = cd(HEARTHSTONE) end
    local left = (dur and dur > 1.5) and math.max(0, start + dur - GetTime()) or 0
    line(INN, IsHere(s.hearth), "Hearth to " .. Y .. s.hearth .. "|r" ..
      (left > 0 and (GR .. string.format(" (Hearthstone ready in %d min)", math.ceil(left / 60))) or ""))
  end
  return out
end

---------------------------------------------------------------------------
-- Flight master
---------------------------------------------------------------------------
-- Finds the taxi node for a destination; returns index, full name, reachable.
function FXP:FindTaxiNode(dest)
  if not (NumTaxiNodes and TaxiNodeName) then return end
  for i = 1, NumTaxiNodes() do
    local name = TaxiNodeName(i)
    if Same(name, dest) then
      local kind = TaxiNodeGetType and TaxiNodeGetType(i)
      return i, name, kind == "REACHABLE", kind
    end
  end
end

function FXP:OnTaxiMap()
  -- every node on the map is a flight path this character knows
  local origin
  for i = 1, (NumTaxiNodes and NumTaxiNodes() or 0) do
    local name, kind = TaxiNodeName(i), TaxiNodeGetType and TaxiNodeGetType(i)
    if kind ~= "NONE" and kind ~= "DISTANT" then LearnFlight(name) end
    if kind == "CURRENT" then origin = name end
  end
  self.taxiOrigin = origin
  self:QueueUpdate()
  local s = self:CurrentStep()
  if not (s and s.fly and self.db.autoFly) or Shifted() then return end
  local i, name, reachable, kind = self:FindTaxiNode(s.fly)
  if not i then
    self.Print("No flight path to |cffffff00%s|r here yet - check the map.", s.fly)
  elseif kind == "CURRENT" then
    self.Print("You're already at %s.", name)
  elseif reachable then
    self.Print("Flying to |cffffff00%s|r. Hold Shift at the flight master to choose yourself.", name)
    self.db.flown = self.db.flown or {}
    self.db.flown[s.key] = true
    self.pendingFlight = { from = origin, to = name }
    TakeTaxiNode(i)
  end
end

-- Remember the route even when the player clicks the map themselves.
if hooksecurefunc and TakeTaxiNode then
  hooksecurefunc("TakeTaxiNode", function(i)
    if not FXP.pendingFlight or FXP.pendingFlight.to ~= TaxiNodeName(i) then
      FXP.pendingFlight = { from = FXP.taxiOrigin, to = TaxiNodeName(i) }
    end
  end)
end

-- Gossip: open the flight map on `fly` steps, pick "make this inn your home" on `bind` steps.
local function GossipOptions()
  if C_GossipInfo and C_GossipInfo.GetOptions then return C_GossipInfo.GetOptions() or {} end
  local out = {}
  if GetGossipOptions then
    local t = { GetGossipOptions() }
    for i = 1, #t, 2 do out[#out + 1] = { name = t[i], type = t[i + 1], index = (i + 1) / 2 } end
  end
  return out
end

local function Pick(opt)
  if C_GossipInfo and C_GossipInfo.SelectOption and opt.gossipOptionID then C_GossipInfo.SelectOption(opt.gossipOptionID)
  elseif SelectGossipOption and opt.index then SelectGossipOption(opt.index) end
end

function FXP:TravelGossip()
  local s = self:CurrentStep()
  if not s or Shifted() then return false end
  for _, opt in ipairs(GossipOptions()) do
    local icon, kind, text = opt.icon, opt.type, Lower(opt.name)
    if s.fly and self.db.autoFly and (icon == TAXI_ICON or kind == "taxi" or text:find("fly", 1, true)) then
      Pick(opt); return true
    end
    if s.bind and self.db.autoBind and (icon == BINDER_ICON or kind == "binder" or text:find("home", 1, true)) then
      local home = GetBindLocation and GetBindLocation()
      if not Same(home, s.bind) then Pick(opt); return true end
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Flight timer
---------------------------------------------------------------------------
local timer
local function BuildTimer()
  timer = CreateFrame("StatusBar", "ForeverXPFlightTimer", UIParent)
  timer:SetSize(220, 14)
  timer:SetPoint("TOP", UIParent, "TOP", 0, -110)
  timer:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  timer:SetStatusBarColor(0.3, 0.75, 1)
  timer.bg = timer:CreateTexture(nil, "BACKGROUND")
  timer.bg:SetAllPoints()
  timer.bg:SetColorTexture(0, 0, 0, 0.6)
  timer.text = timer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  timer.text:SetPoint("CENTER")
  timer:Hide()
end

local function Clock(sec)
  sec = math.max(0, math.floor(sec + 0.5))
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function RouteKey(f) return (f.from or "?") .. " > " .. (f.to or "?") end

function FXP:FlightTimes()
  ForeverXPDB = ForeverXPDB or {}
  ForeverXPDB.flightTimes = ForeverXPDB.flightTimes or {}
  return ForeverXPDB.flightTimes
end

function FXP:StartFlight()
  if not self.db.flightTimer then return end
  local f = self.pendingFlight or {}
  self.flight = { from = f.from, to = f.to, start = GetTime() }
  self.flight.known = f.from and f.to and self:FlightTimes()[RouteKey(f)]
  if not timer then BuildTimer() end
  timer:Show()
end

function FXP:EndFlight()
  local f = self.flight
  self.flight, self.pendingFlight = nil, nil
  if timer then timer:Hide() end
  if not (f and f.from and f.to) then return end
  local took = GetTime() - f.start
  if took > 5 then self:FlightTimes()[RouteKey(f)] = math.floor(took + 0.5) end
end

function FXP:FlightTick()
  local f = self.flight
  if not (f and timer and timer:IsShown()) then return end
  local gone = GetTime() - f.start
  local dest = f.to and (f.to:gsub(",.*$", "")) or "your destination"
  if f.known then
    timer:SetMinMaxValues(0, f.known); timer:SetValue(math.min(gone, f.known))
    timer.text:SetText(string.format("%s - %s left", dest, Clock(f.known - gone)))
  else
    timer:SetMinMaxValues(0, 1); timer:SetValue(1)
    timer.text:SetText(string.format("%s - %s (first time on this route)", dest, Clock(gone)))
  end
end

---------------------------------------------------------------------------
-- Flight path reminders
---------------------------------------------------------------------------
local reminded = {}
function FXP:FlightReminder()
  if not (self.db.fpReminders and self.db.knownFlights and next(self.db.knownFlights)) then return end
  local zone = GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText())
  local list = (UnitFactionGroup and UnitFactionGroup("player") == "Horde") and ns.FlightPointsHorde or ns.FlightPoints
  for _, fp in ipairs((list or {})[zone or ""] or {}) do
    if not self:KnowsFlight(fp) and not reminded[fp] then
      reminded[fp] = true
      self.Print("You don't have the |cffffff00%s|r flight path yet - grab it while you're here.", fp)
    end
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "TAXIMAP_OPENED", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "CONFIRM_BINDER",
  "UI_INFO_MESSAGE", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "HEARTHSTONE_BOUND", "PLAYER_ENTERING_WORLD" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2)
  if not FXP.db then return end
  if event == "TAXIMAP_OPENED" then
    FXP:OnTaxiMap()
  elseif event == "PLAYER_CONTROL_LOST" then
    -- the taxi flag can lag the control loss by a moment
    local function check() if UnitOnTaxi and UnitOnTaxi("player") and not FXP.flight then FXP:StartFlight() end end
    check()
    if C_Timer and C_Timer.After then C_Timer.After(0.5, check) end
  elseif event == "PLAYER_CONTROL_GAINED" then
    if FXP.flight then FXP:EndFlight(); FXP:QueueUpdate() end
  elseif event == "CONFIRM_BINDER" then
    local s = FXP:CurrentStep()
    if s and s.bind and FXP.db.autoBind and not Shifted() then
      if ConfirmBinder then ConfirmBinder()
      elseif C_PlayerInteractionManager and C_PlayerInteractionManager.ConfirmationInteraction and Enum and Enum.PlayerInteractionType then
        C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.Binder)
      end
      if StaticPopup_Hide then StaticPopup_Hide("CONFIRM_BINDER") end
    end
  elseif event == "UI_INFO_MESSAGE" then
    local msg = a2 or a1
    if ERR_NEWTAXIPATH and msg == ERR_NEWTAXIPATH then
      -- name the new flight path after where you're standing; the next flight map fixes the exact name
      local sub, zone = Here()
      local named
      local fps = (UnitFactionGroup and UnitFactionGroup("player") == "Horde") and ns.FlightPointsHorde or ns.FlightPoints
      for _, fp in ipairs((fps or {})[zone] or {}) do if Same(sub, fp) then named = fp end end
      local s = FXP:CurrentStep()
      LearnFlight(named or (s and s.fp) or sub)
      FXP:QueueUpdate()
    end
  elseif event == "HEARTHSTONE_BOUND" then
    FXP:QueueUpdate()
  else -- zone changes: hearth/fly arrivals and flight path reminders
    local s = FXP:CurrentStep()
    if s and s.hearth and IsHere(s.hearth) then
      FXP.db.hearthed = FXP.db.hearthed or {}
      FXP.db.hearthed[s.key] = true
    end
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then FXP:FlightReminder() end
    FXP:QueueUpdate()
  end
end)
ev:SetScript("OnUpdate", function(self, dt)
  self.acc = (self.acc or 0) + dt
  if self.acc > 0.2 then self.acc = 0; FXP:FlightTick() end
end)
