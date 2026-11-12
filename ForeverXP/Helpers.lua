-- Helpers.lua: Phase 1 quest helpers.
--   * Quest item buttons: usable quest items for the current step pop up as clickable buttons.
--   * Auto-train: on a guide "train" step, buy every skill the class trainer offers that you can afford.
--   * Quest cleanup: offer to abandon quests in your log that no guide (or dungeon list) uses.
local ADDON, ns = ...
local FXP, C = ns.FXP, ns.Compat

local MAX_ITEMS = 4
_G["BINDING_NAME_CLICK ForeverXPItem1:LeftButton"] = "Use the step's quest item"

local function AsList(v)
  if v == nil then return {} end
  return type(v) == "table" and v or { v }
end

local function ItemCount(item)
  local f = (C_Item and C_Item.GetItemCount) or GetItemCount
  return (f and f(item)) or 0
end

local function ItemSpell(item)
  local f = (C_Item and C_Item.GetItemSpell) or GetItemSpell
  return f and f(item)
end

local function ItemIcon(item)
  if C_Item and C_Item.GetItemIconByID and type(item) == "number" then return C_Item.GetItemIconByID(item) end
  if GetItemIcon then return GetItemIcon(item) end
  return select(10, GetItemInfo(item))
end

local function ItemName(item)
  local name = (C_Item and C_Item.GetItemNameByID and type(item) == "number" and C_Item.GetItemNameByID(item))
    or (GetItemInfo and GetItemInfo(item))
  return name or (type(item) == "string" and item) or ("item " .. tostring(item))
end

local function ItemCooldown(item)
  local f = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
  if not (f and type(item) == "number") then return 0, 0 end
  return f(item)
end

---------------------------------------------------------------------------
-- Quest item buttons
---------------------------------------------------------------------------
-- Usable items for a step that you're carrying: authored `useItem` first, then Questie's items for the
-- step's unfinished quests. An item counts as usable when it has a "Use:" spell.
function FXP:StepItems(s)
  local out, seen = {}, {}
  local function add(item)
    if item and not seen[item] and ItemCount(item) > 0 and ItemSpell(item) then
      seen[item] = true
      out[#out + 1] = item
    end
  end
  if not s then return out end
  for _, item in ipairs(AsList(s.useItem)) do add(item) end
  local QZ = ns.Questie
  if QZ and QZ.ready then
    for _, list in ipairs({ s.complete or {}, s.turnin or {}, s.accept or {} }) do
      for _, q in ipairs(list) do
        local id = self:Resolve(q)
        if id and C.IsOnQuest(id) and not (list == s.complete and C.IsComplete(id)) then
          for _, item in ipairs(QZ:QuestItems(id)) do add(item) end
        end
      end
    end
  end
  return out
end

local bar, slots

local function BuildBar()
  bar = CreateFrame("Frame", "ForeverXPItems", UIParent)
  bar:SetSize(MAX_ITEMS * 40, 36)
  bar:SetFrameStrata("MEDIUM")
  bar:SetMovable(true)
  bar:SetClampedToScreen(true)
  local p = FXP.db.itemBarPos
  if p then bar:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else bar:SetPoint("CENTER", UIParent, "CENTER", 0, -230) end
  bar:Hide()
  slots = {}
  for i = 1, MAX_ITEMS do
    local b = CreateFrame("Button", "ForeverXPItem" .. i, bar, "SecureActionButtonTemplate")
    b:SetSize(34, 34)
    b:SetPoint("LEFT", bar, "LEFT", (i - 1) * 40, 0)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "item")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function()
      if IsShiftKeyDown() and not InCombatLockdown() then bar:StartMoving() end
    end)
    b:SetScript("OnDragStop", function()
      bar:StopMovingOrSizing()
      local point, _, rel, x, y = bar:GetPoint()
      FXP.db.itemBarPos = { point, rel, x, y }
    end)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetPoint("CENTER")
    b.border:SetSize(60, 60)
    b.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b:SetScript("OnEnter", function(self)
      if not self.item then return end
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      if type(self.item) == "number" and GameTooltip.SetItemByID then GameTooltip:SetItemByID(self.item)
      else GameTooltip:AddLine(ItemName(self.item), 1, 1, 1) end
      GameTooltip:AddLine("ForeverXP: quest item for this step. Shift-drag to move.", 0.6, 0.6, 0.6)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    slots[i] = b
  end
  FXP.itemBar = bar
end

-- Counts and cooldowns are cosmetic, so they update any time (combat included).
local function Decorate()
  for _, b in ipairs(slots) do
    if b.item then
      local n = ItemCount(b.item)
      b.count:SetText(n > 1 and n or "")
      b.icon:SetDesaturated(n == 0)
      local start, dur = ItemCooldown(b.item)
      if b.cd.SetCooldown and start and dur and dur > 0 then b.cd:SetCooldown(start, dur) end
    end
  end
end

-- Secure part: which items the buttons use, and showing/hiding the bar. Out of combat only.
function FXP:RefreshItems()
  if not self.db then return end
  if not bar then BuildBar() end
  if InCombatLockdown and InCombatLockdown() then self.itemsDirty = true; return end
  self.itemsDirty = false
  local step = self.guide and self:CurrentStep()
  local items = (self.db.questItems and step) and self:StepItems(step) or {}
  self.stepItems = items
  for i, b in ipairs(slots) do
    local item = items[i]
    b.item = item
    if item then
      b:SetAttribute("item", type(item) == "number" and ("item:" .. item) or item)
      b.icon:SetTexture(ItemIcon(item) or "Interface\\Icons\\INV_Misc_QuestionMark")
      b:Show()
    else
      b:SetAttribute("item", nil)
      b:Hide()
    end
  end
  if #items > 0 then
    bar:SetWidth(#items * 40)
    bar:Show()
    Decorate()
  else
    bar:Hide()
  end
end

---------------------------------------------------------------------------
-- Auto-train
---------------------------------------------------------------------------
-- Only on a guide "train" step, only at class trainers, never with Shift held, and never spending below
-- the reserve the player set (so mount money is safe). Buys from the bottom of the list up, because each
-- purchase can shift the entries below it.
function FXP:AutoTrain()
  local st = self:CurrentStep()
  if not (self.db.autoTrain and st and st.train) then return 0 end
  if IsShiftKeyDown and IsShiftKeyDown() then return 0 end
  if IsTradeskillTrainer and IsTradeskillTrainer() then return 0 end
  if not (GetNumTrainerServices and GetTrainerServiceInfo and BuyTrainerService) then return 0 end
  if SetTrainerServiceTypeFilter then pcall(SetTrainerServiceTypeFilter, "available", 1) end
  local reserve = (self.db.trainReserve or 0) * 10000
  local bought, spent, names = 0, 0, {}
  for i = GetNumTrainerServices(), 1, -1 do
    local name, rank, category = GetTrainerServiceInfo(i)
    if category == "available" then
      local cost = (GetTrainerServiceCost and GetTrainerServiceCost(i)) or 0
      if (GetMoney() - spent - cost) >= reserve then
        local ok = pcall(BuyTrainerService, i)
        if ok then
          bought, spent = bought + 1, spent + cost
          names[#names + 1] = name .. ((rank and rank ~= "") and (" (" .. rank .. ")") or "")
        end
      end
    end
  end
  if bought > 0 and self.Print then
    self.Print("Trained %d skill%s for %s: %s", bought, bought == 1 and "" or "s",
      GetCoinTextureString and GetCoinTextureString(spent) or (spent .. "c"), table.concat(names, ", "))
  end
  return bought
end

---------------------------------------------------------------------------
-- Quest cleanup
---------------------------------------------------------------------------
local function BaseName(q) return (q:gsub("#%d+$", "")) end

-- Quest IDs and names any guide or the dungeon list mentions.
function FXP:KnownQuests()
  if self.knownQuests then return self.knownQuests end
  local ids, names = {}, {}
  local function note(q)
    if type(q) == "number" then ids[q] = true
    elseif type(q) == "string" then names[BaseName(q)] = true end
    local id = self:Resolve(q)
    if id then ids[id] = true end
  end
  for _, g in pairs(self.guides or {}) do
    for id, name in pairs(g.quests or {}) do ids[id] = true; names[name] = true end
    for _, s in ipairs(g.steps or {}) do
      for _, key in ipairs({ "accept", "complete", "turnin", "anyQuest" }) do
        for _, q in ipairs(AsList(s[key])) do note(q) end
      end
    end
  end
  for _, d in ipairs(ns.Dungeons or {}) do
    for _, q in ipairs(d.quests or {}) do names[q[1]] = true end
  end
  self.knownQuests = { ids = ids, names = names }
  return self.knownQuests
end

-- Quests in your log that nothing in ForeverXP uses. Finished quests are left alone (free XP to hand in).
function FXP:OrphanQuests()
  local known, out = self:KnownQuests(), {}
  for _, id in ipairs(C.LogQuestIDs()) do
    local title = C.Title(id)
    if not known.ids[id] and not (title and known.names[title]) and not C.IsComplete(id) then
      out[#out + 1] = { id = id, title = title or ("Quest " .. id) }
    end
  end
  return out
end

local function Abandon(id)
  local CQL = C_QuestLog
  if CQL and CQL.SetSelectedQuest and CQL.SetAbandonQuest and CQL.AbandonQuest then
    CQL.SetSelectedQuest(id); CQL.SetAbandonQuest(); CQL.AbandonQuest()
    return true
  end
  if GetQuestLogIndexByID and SelectQuestLogEntry and SetAbandonQuest and AbandonQuest then
    local i = GetQuestLogIndexByID(id)
    if i and i > 0 then SelectQuestLogEntry(i); SetAbandonQuest(); AbandonQuest(); return true end
  end
  return false
end

function FXP:AbandonQuests(list)
  local n = 0
  for _, q in ipairs(list) do if Abandon(q.id) then n = n + 1 end end
  return n
end

-- /fxp cleanup: list the orphans and ask before abandoning anything.
function FXP:CleanupQuests()
  local list = self:OrphanQuests()
  if #list == 0 then self.Print("Your quest log only has quests the guides use. Nothing to clean up.") return end
  local titles = {}
  for i, q in ipairs(list) do titles[i] = q.title end
  self.Print("Not used by any guide: %s", table.concat(titles, ", "))
  if not StaticPopupDialogs then return end
  local shown = {}
  for i = 1, math.min(10, #titles) do shown[i] = titles[i] end
  if #titles > 10 then shown[#shown + 1] = "...and " .. (#titles - 10) .. " more" end
  local text = string.format("Abandon %d quest%s no ForeverXP guide uses?\n\n%s", #list, #list == 1 and "" or "s",
    table.concat(shown, "\n"))
  StaticPopupDialogs.FOREVERXP_CLEANUP = {
    text = (text:gsub("%%", "%%%%")), -- the popup runs its text through string.format
    button1 = "Abandon", button2 = "Keep",
    OnAccept = function(_, data)
      local n = FXP:AbandonQuests(data)
      FXP.Print("Abandoned %d quest%s.", n, n == 1 and "" or "s")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  StaticPopup_Show("FOREVERXP_CLEANUP", nil, nil, list)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRAINER_SHOW", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "PLAYER_REGEN_ENABLED", "QUEST_LOG_UPDATE" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
  if not FXP.db then return end
  if event == "TRAINER_SHOW" then
    FXP:AutoTrain()
  elseif event == "BAG_UPDATE_COOLDOWN" then
    if bar and bar:IsShown() then Decorate() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if FXP.itemsDirty then FXP:RefreshItems() end
  else -- bags or quest log changed: the step's items may have appeared or been used up
    FXP:RefreshItems()
  end
end)
