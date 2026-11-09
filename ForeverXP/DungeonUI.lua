-- Dungeon quest window (/fxp dungeons): dungeons near your level and their quests,
-- with live status (done / on your log / not picked up).
local ADDON, ns = ...
local FXP = ns.FXP
local C = ns.Compat

local GREEN, YELLOW, WHITE, GREY = "|cff33ff66", "|cffffd200", "|cffffffff", "|cff9d9d9d"

local function QuestStatus(name)
  local id = FXP:Resolve(name)
  if id and C.IsTurnedIn(id) then return GREEN .. "[done]|r" end
  if id and C.IsOnQuest(id) then
    if C.IsComplete(id) then return GREEN .. "[ready to turn in]|r" end
    return YELLOW .. "[on your log]|r"
  end
  return GREY .. "[not picked up]|r"
end

function FXP:DungeonText(showAll)
  local level = UnitLevel("player")
  local out = {}
  local function add(t) out[#out + 1] = t end
  local shown = 0
  for _, d in ipairs(ns.Dungeons or {}) do
    if showAll or (level >= d.min - 3 and level <= d.max) then
      shown = shown + 1
      local col = (level < d.min) and "|cffff8c1a" or ((level > d.max - 3) and GREY or GREEN)
      add(col .. d.name .. "|r " .. GREY .. "(" .. d.min .. "-" .. d.max .. ")|r")
      add(GREY .. "   " .. d.where .. "|r")
      if d.forever and #d.quests == 0 then
        add("   " .. WHITE .. "New in WoW Forever - quests aren't published yet; Questie will show them.|r")
      end
      for _, q in ipairs(d.quests) do
        add("   " .. QuestStatus(q[1]) .. " " .. YELLOW .. q[1] .. "|r")
        add("      " .. GREY .. q[2] .. "|r")
      end
      add(" ")
    end
  end
  if shown == 0 then add(WHITE .. "No dungeons near your level. Tick 'Show all' to see the full list.|r") end
  return table.concat(out, "\n")
end

function FXP:BuildDungeons()
  local f = CreateFrame("Frame", "ForeverXPDungeons", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(380, 460)
  f:SetPoint("CENTER", 200, 0)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.04, 0.05, 0.07, 0.96)
  f:SetBackdropBorderColor(0.2, 0.9, 0.55, 0.9)
  self:MakeMovable(f, "dungeonPos")
  table.insert(UISpecialFrames, "ForeverXPDungeons")
  f:Hide()

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetText("Dungeon quests")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)

  local all = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  all:SetPoint("TOPLEFT", 10, -34)
  all:SetSize(22, 22)
  local allLabel = all:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  allLabel:SetPoint("LEFT", all, "RIGHT", 2, 0)
  allLabel:SetText("Show all dungeons")
  all:SetScript("OnClick", function() FXP:RefreshDungeons() end)
  f.showAll = all

  local scroll = CreateFrame("ScrollFrame", "ForeverXPDungeonsScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 14, -62)
  scroll:SetPoint("BOTTOMRIGHT", -32, 14)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(330, 10)
  scroll:SetScrollChild(child)
  local text = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT")
  text:SetWidth(330)
  text:SetJustifyH("LEFT")
  text:SetSpacing(2)
  f.child, f.text = child, text

  f:SetScript("OnShow", function() FXP:RefreshDungeons() end)
  self.dungeonFrame = f
end

function FXP:RefreshDungeons()
  local f = self.dungeonFrame
  if not (f and f:IsShown()) then return end
  f.text:SetText(self:DungeonText(f.showAll:GetChecked()))
  f.child:SetHeight(math.max(10, f.text:GetStringHeight() + 10))
end

function FXP:ToggleDungeons()
  if not self.dungeonFrame then self:BuildDungeons() end
  if self.dungeonFrame:IsShown() then self.dungeonFrame:Hide() else self.dungeonFrame:Show() end
end
