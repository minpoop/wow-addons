-- Feedback.lua: Phase 4 route-quality tools. Everything is saved account-wide in ForeverXPDB, which WoW
-- writes to WTF/Account/<account>/SavedVariables/ForeverXP.lua on /reload or logout;
-- Tools/read_reports.py turns that file into a fix list.
--   * /fxp report [note] (and the note button on the guide window): flag the current step with a reason.
--   * Run log: how long each step took, whether it was skipped, deaths. Recorded automatically.
--   * /fxp check: checks every guide quest against Questie's WoW Forever data.
--   * /fxp export: the same information as copyable text.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local MAX_LOG = 3000
local REASONS = {
  { key = "place", label = "Wrong place / arrow" },
  { key = "missing", label = "Quest missing or not offered" },
  { key = "hard", label = "Too hard / died" },
  { key = "order", label = "Wrong order / backtracking" },
  { key = "unclear", label = "Text unclear or wrong" },
  { key = "other", label = "Something else" },
}
FXP.ReportReasons = REASONS

local function DB()
  ForeverXPDB = ForeverXPDB or {}
  ForeverXPDB.reports = ForeverXPDB.reports or {}
  ForeverXPDB.runLog = ForeverXPDB.runLog or {}
  return ForeverXPDB
end

local function Plain(text)
  text = (text or ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  return (text:gsub("\n+", " / "):gsub("%s+", " "):gsub("^%s+", ""))
end

local function Version()
  local f = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return (f and f(ADDON, "Version")) or "?"
end

local function Where()
  local w = { zone = GetRealZoneText and GetRealZoneText() or "", sub = GetSubZoneText and GetSubZoneText() or "" }
  if C_Map and C_Map.GetBestMapForUnit then
    local map = C_Map.GetBestMapForUnit("player")
    local pos = map and C_Map.GetPlayerMapPosition(map, "player")
    if pos then
      local x, y = pos.x, pos.y
      if pos.GetXY then x, y = pos:GetXY() end
      w.map, w.x, w.y = map, math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
    end
  end
  return w
end

-- Quest state for every quest a step mentions, so a report says what the game thought at the time.
local function QuestStates(s)
  local out = {}
  for _, key in ipairs({ "accept", "complete", "turnin", "anyQuest" }) do
    for _, q in ipairs(s and s[key] or {}) do
      local id = FXP:Resolve(q)
      out[#out + 1] = {
        quest = tostring(q), kind = key, id = id,
        onQuest = id and C.IsOnQuest(id) or false, complete = id and C.IsComplete(id) or false,
        turnedIn = id and C.IsTurnedIn(id) or false,
        unavailable = (FXP.Unavailable and FXP:Unavailable(id, q)) or false,
      }
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Reports
---------------------------------------------------------------------------
function FXP:SaveReport(reason, note)
  local s = self:CurrentStep()
  local _, class = UnitClass("player")
  local _, race = UnitRace("player")
  local r = {
    when = date and date("%Y-%m-%d %H:%M") or "?", version = Version(),
    guide = self.guide and self.guide.name, step = self.db.step, key = s and s.key,
    src = s and s.src, classStep = s and s.classStep or nil,
    text = s and Plain(self:StepText(s, false)) or "", reason = reason or "other", note = note or "",
    level = UnitLevel("player"), class = class, race = race, where = Where(),
    quests = QuestStates(s), questie = (ns.Questie and ns.Questie.ready) and true or false,
  }
  table.insert(DB().reports, r)
  self.Print("Step reported (%s). Thanks! /fxp export shows everything you've flagged.", reason or "other")
  return r
end

local popup
local function BuildPopup()
  popup = CreateFrame("Frame", "ForeverXPReport", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  popup:SetSize(320, 260)
  popup:SetPoint("CENTER", 0, 80)
  popup:SetFrameStrata("DIALOG")
  if popup.SetBackdrop then
    popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    popup:SetBackdropColor(0.04, 0.05, 0.07, 0.97)
    popup:SetBackdropBorderColor(1, 0.82, 0, 0.9)
  end
  popup:EnableMouse(true)
  popup:SetMovable(true)
  popup:RegisterForDrag("LeftButton")
  popup:SetScript("OnDragStart", popup.StartMoving)
  popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
  table.insert(UISpecialFrames, "ForeverXPReport")
  local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -12)
  title:SetText("Report this step")
  popup.stepText = popup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  popup.stepText:SetPoint("TOPLEFT", 12, -30)
  popup.stepText:SetWidth(296)
  popup.stepText:SetJustifyH("LEFT")
  popup.stepText:SetWordWrap(true)
  popup.stepText:SetMaxLines(2)
  popup.reason = "place"
  popup.radios = {}
  for i, r in ipairs(REASONS) do
    local b = CreateFrame("CheckButton", nil, popup, "UIRadioButtonTemplate")
    b:SetPoint("TOPLEFT", 14 + ((i - 1) % 2) * 150, -58 - math.floor((i - 1) / 2) * 22)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", b, "RIGHT", 2, 0)
    fs:SetText(r.label)
    b:SetScript("OnClick", function()
      popup.reason = r.key
      for _, o in ipairs(popup.radios) do o:SetChecked(o == b) end
    end)
    b.key = r.key
    popup.radios[i] = b
  end
  local noteLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  noteLabel:SetPoint("TOPLEFT", 14, -130)
  noteLabel:SetText("What happened? (optional)")
  popup.note = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
  popup.note:SetSize(286, 20)
  popup.note:SetPoint("TOPLEFT", 20, -146)
  popup.note:SetAutoFocus(false)
  popup.note:SetMaxLetters(240)
  popup.note:SetScript("OnEnterPressed", function() popup.send:Click() end)
  popup.note:SetScript("OnEscapePressed", function() popup:Hide() end)
  local hint = popup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 14, -176)
  hint:SetWidth(292)
  hint:SetJustifyH("LEFT")
  hint:SetText("Your level, position and quest state are saved with it. Nothing leaves your computer.")
  popup.send = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
  popup.send:SetSize(120, 22)
  popup.send:SetPoint("BOTTOMRIGHT", -12, 12)
  popup.send:SetText("Save report")
  popup.send:SetScript("OnClick", function()
    FXP:SaveReport(popup.reason, popup.note:GetText())
    popup:Hide()
  end)
  local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
  cancel:SetSize(90, 22)
  cancel:SetPoint("RIGHT", popup.send, "LEFT", -6, 0)
  cancel:SetText("Cancel")
  cancel:SetScript("OnClick", function() popup:Hide() end)
  popup:Hide()
end

-- /fxp report <note> saves straight away; /fxp report (or the button) opens the form.
function FXP:Report(note)
  if note and note ~= "" then return self:SaveReport("other", note) end
  if not popup then BuildPopup() end
  local s = self:CurrentStep()
  popup.stepText:SetText(s and Plain(self:StepText(s, false)) or "No step loaded.")
  popup.note:SetText("")
  popup.reason = "place"
  for _, o in ipairs(popup.radios) do o:SetChecked(o.key == "place") end
  popup:Show()
end

---------------------------------------------------------------------------
-- Run log: one line per step left behind
---------------------------------------------------------------------------
local cur -- the step we're timing

function FXP:LogStepChange(manual)
  if not (self.guide and self.db) then return end
  local s = self:CurrentStep()
  local key = s and (self.guide.name .. "#" .. self.db.step)
  if cur and cur.id == key then return end
  local now = GetTime()
  if cur then
    local log = DB().runLog
    local entry = {
      guide = cur.guide, step = cur.step, src = cur.src, key = cur.key, secs = math.floor(now - cur.start + 0.5),
      lvlStart = cur.level, lvlEnd = UnitLevel("player"), deaths = cur.deaths,
      how = manual and "manual" or (cur.skipped and "skipped" or "done"),
    }
    log[#log + 1] = entry
    while #log > MAX_LOG do table.remove(log, 1) end
  end
  cur = s and { id = key, guide = self.guide.name, step = self.db.step, src = s.src, key = s.key, start = now, level = UnitLevel("player"), deaths = 0 } or nil
end

function FXP:NoteSkip() if cur then cur.skipped = true end end
function FXP:NoteDeath() if cur then cur.deaths = cur.deaths + 1 end end

-- Steps that were slow, skipped or deadly, worst first. Used by /fxp export and read_reports.py's twin.
function FXP:RunSummary()
  local by = {}
  for _, e in ipairs(DB().runLog) do
    local k = (e.guide or "?") .. " #" .. (e.step or 0)
    local b = by[k] or { name = k, n = 0, secs = 0, skipped = 0, deaths = 0 }
    b.n, b.secs, b.deaths = b.n + 1, b.secs + (e.secs or 0), b.deaths + (e.deaths or 0)
    if e.how ~= "done" then b.skipped = b.skipped + 1 end
    by[k] = b
  end
  local out = {}
  for _, b in pairs(by) do
    if b.secs / b.n > 600 or b.skipped > 0 or b.deaths > 0 then out[#out + 1] = b end
  end
  table.sort(out, function(a, b) return (a.deaths * 600 + a.skipped * 300 + a.secs / a.n) > (b.deaths * 600 + b.skipped * 300 + b.secs / b.n) end)
  return out
end

---------------------------------------------------------------------------
-- Route check against Questie's WoW Forever data
---------------------------------------------------------------------------
local function MapDistance(ax, ay, bx, by) return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2) end

-- Checks one guide; `done` is the set of quest IDs the route has accepted before this guide.
function FXP:CheckGuide(g, before)
  local QZ = ns.Questie
  local found = {}
  local function add(i, s, what, q) found[#found + 1] = { guide = g.name, step = i, src = s.src, quest = q and tostring(q), issue = what } end
  local n = #g.steps
  for i, s in ipairs(g.steps) do
    if not (s.class or s.races) then -- class/race blocks can't be judged from one character's point of view
      local expect = (g.minLevel or 1) + ((g.maxLevel or 60) - (g.minLevel or 1)) * (i - 1) / math.max(1, n - 1)
      expect = math.max(expect, s.ifLevel or 0) -- an ifLevel step is only shown from that level on
      for _, key in ipairs({ "accept", "complete", "turnin" }) do
        for _, q in ipairs(s[key] or {}) do
          local id = self:Resolve(q)
          local row = id and QZ:Row(id)
          if not row then
            -- without Questie's name index a quest named by text can't be looked up, so it proves nothing
            if not (QZ.indexFailed and type(q) == "string") then
              add(i, s, "Questie doesn't know this quest (renamed or not in WoW Forever?)", q)
            end
          else
            if key == "accept" then
              if QZ.FitsFaction and not QZ:FitsFaction(row) then add(i, s, "Questie says this quest isn't for the Alliance", q) end
              if row.req and row.req > expect + 1.5 then
                add(i, s, string.format("needs level %d; this step comes at about level %d", row.req, math.floor(expect)), q)
              end
              local pre = row.pre1
              if type(pre) == "table" then pre = pre[1] end
              if type(pre) == "number" and not before[pre] and not s.optional then
                add(i, s, string.format("needs quest %d first, which the route doesn't do before this", pre), q)
              end
              before[id] = true
            end
            if s.coords and (key == "accept" or key == "turnin") then
              local e = QZ:Endpoint(row, key == "accept" and "start" or "finish")
              local map = self:StepMap(s)
              if e and e.x and e.map and map and e.map == map and MapDistance(e.x, e.y, s.coords[1], s.coords[2]) > 8 then
                add(i, s, string.format("%s is at %.1f, %.1f (Questie), step coords say %.1f, %.1f",
                  e.name or "the NPC", e.x, e.y, s.coords[1], s.coords[2]), q)
              end
            end
          end
        end
      end
    end
  end
  return found
end

-- Runs over every guide a few per frame so the game doesn't hitch; saves to ForeverXPDB.routeCheck.
function FXP:CheckRoute()
  local QZ = ns.Questie
  if not (QZ and QZ.ready) then self.Print("The route check needs Questie loaded. Try again in a few seconds.") return end
  -- quests named by text are looked up through Questie's name index, built in the background after login;
  -- checking before it's done reports most of them as unknown, so wait for it
  if not QZ.indexDone and not QZ.indexFailed then
    if not self.checkWaiting then
      self.checkWaiting = true
      local waited = 0
      self.Print("Questie's quest index is still building (%d%%). The route check will run as soon as it's ready.",
        QZ.indexTotal and QZ.indexTotal > 0 and math.floor((QZ.indexPos or 0) * 100 / QZ.indexTotal) or 0)
      local function wait()
        waited = waited + 1
        if QZ.indexDone or QZ.indexFailed or waited > 180 then
          self.checkWaiting = nil
          if not QZ.indexDone then QZ.indexFailed = true end
          self:CheckRoute()
        else
          C_Timer.After(1, wait)
        end
      end
      C_Timer.After(1, wait)
    end
    return
  end
  local order, seen = {}, {}
  for _, n in ipairs(self.guideOrder or {}) do if not seen[n] then seen[n] = true; order[#order + 1] = n end end
  local before, all, i = {}, {}, 0
  self.Print("Checking %d guides against Questie...", #order)
  local function step()
    for _ = 1, 3 do
      i = i + 1
      local g = self.guides[order[i]]
      if not g then
        DB().routeCheck = { when = date and date("%Y-%m-%d %H:%M") or "?", version = Version(), findings = all,
          nameIndex = QZ.indexDone and "complete" or "unavailable" }
        if not QZ.indexDone then
          self.Print("Note: Questie's name index wasn't available, so quests the guides name by text weren't checked.")
        end
        self.Print("Route check done: %d thing%s to look at. /fxp export to see them; /reload saves them for me.",
          #all, #all == 1 and "" or "s")
        return
      end
      local ok, res = pcall(self.CheckGuide, self, g, before)
      if ok then for _, f in ipairs(res) do all[#all + 1] = f end
      else all[#all + 1] = { guide = g.name, issue = "check failed: " .. tostring(res) } end
    end
    C_Timer.After(0.05, step)
  end
  step()
end

---------------------------------------------------------------------------
-- Export: everything as copyable text
---------------------------------------------------------------------------
function FXP:ExportText()
  local db, lines = DB(), {}
  local function L(s) lines[#lines + 1] = s end
  L("ForeverXP " .. Version() .. " route feedback")
  local rc0 = db.routeCheck
  if rc0 and rc0.version ~= Version() then
    L("(The route check below is from v" .. (rc0.version or "?") .. " - type /fxp check to run it again on this version.)")
  end
  L("")
  L("== Reports (" .. #db.reports .. ")")
  for _, r in ipairs(db.reports) do
    L(string.format("- [%s] %s #%s (lvl %s %s) at %s %s %s,%s: %s%s", r.reason or "?", r.guide or "?", r.step or "?",
      r.level or "?", r.class or "", r.where and r.where.zone or "", r.where and r.where.sub or "",
      r.where and r.where.x or "?", r.where and r.where.y or "?", r.text or "", (r.note and r.note ~= "") and (" -- NOTE: " .. r.note) or ""))
  end
  L("")
  local sum = self:RunSummary()
  L("== Slow, skipped or deadly steps (" .. #sum .. ")")
  for i = 1, math.min(40, #sum) do
    local b = sum[i]
    L(string.format("- %s: %d min avg, skipped %d/%d, deaths %d", b.name, math.floor(b.secs / b.n / 60 + 0.5), b.skipped, b.n, b.deaths))
  end
  L("")
  local rc = db.routeCheck
  L("== Route check" .. (rc and (" (" .. rc.when .. ", v" .. (rc.version or "?") .. ", name index " .. (rc.nameIndex or "not recorded")
    .. ", " .. #rc.findings .. " findings)") or ": not run yet, type /fxp check"))
  for _, f in ipairs(rc and rc.findings or {}) do
    L(string.format("- %s #%s%s: %s%s", f.guide or "?", f.step or "?", f.src and (" (file step " .. f.src .. ")") or "",
      f.quest and (f.quest .. " - ") or "", f.issue or ""))
  end
  return table.concat(lines, "\n")
end

local exportFrame
function FXP:ShowExport()
  if not exportFrame then
    exportFrame = CreateFrame("Frame", "ForeverXPExport", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    exportFrame:SetSize(560, 400)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")
    if exportFrame.SetBackdrop then
      exportFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
      exportFrame:SetBackdropColor(0.04, 0.05, 0.07, 0.97)
      exportFrame:SetBackdropBorderColor(0.2, 0.9, 0.55, 0.9)
    end
    table.insert(UISpecialFrames, "ForeverXPExport")
    local t = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 12, -10)
    t:SetText("ForeverXP feedback - Ctrl+A then Ctrl+C to copy")
    local close = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    local sf = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -32)
    sf:SetPoint("BOTTOMRIGHT", -32, 12)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    eb:SetWidth(500)
    eb:SetAutoFocus(true)
    eb:SetScript("OnEscapePressed", function() exportFrame:Hide() end)
    sf:SetScrollChild(eb)
    exportFrame.edit = eb
  end
  exportFrame.edit:SetText(self:ExportText())
  exportFrame.edit:HighlightText()
  exportFrame:Show()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_DEAD")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGOUT")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then DB().lastVersion = Version(); return end -- so a shared file says which build it came from
  if not FXP.db then return end
  if event == "PLAYER_DEAD" then FXP:NoteDeath()
  elseif event == "PLAYER_LOGOUT" then cur = nil end -- don't count time logged out
end)
