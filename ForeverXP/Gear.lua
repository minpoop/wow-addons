-- Gear.lua: Phase 5 upgrade hints. Scores items with simple leveling stat weights for your class (and spec,
-- read from where your talent points are) and compares them with what you're wearing in that slot. Shows the
-- result on item tooltips and names the best quest reward choice. It never picks rewards for you.
local ADDON, ns = ...
local FXP = ns.FXP

-- Leveling weights per class: primary stats, plus weapon DPS for melee/hunters. Rough on purpose - enough to
-- tell an upgrade from a sidegrade while leveling.
local W = {
  WARRIOR = { STR = 1.0, AGI = 0.6, STA = 0.5, AP = 0.45, DPS = 3.0, ARMOR = 0.01 },
  PALADIN = { STR = 1.0, AGI = 0.4, STA = 0.5, INT = 0.35, SPI = 0.1, AP = 0.45, DPS = 3.0, ARMOR = 0.01 },
  ROGUE   = { AGI = 1.0, STR = 0.5, STA = 0.4, AP = 0.45, DPS = 3.0, ARMOR = 0.005 },
  HUNTER  = { AGI = 1.0, STA = 0.4, INT = 0.25, AP = 0.4, RAP = 0.45, DPS = 2.5, ARMOR = 0.005 },
  SHAMAN  = { STR = 0.8, AGI = 0.6, INT = 0.5, STA = 0.4, SPI = 0.1, AP = 0.4, DPS = 2.5, ARMOR = 0.005 },
  DRUID   = { STR = 0.9, AGI = 0.9, STA = 0.5, INT = 0.35, SPI = 0.1, AP = 0.4, ARMOR = 0.01 },
  MAGE    = { INT = 1.0, SPI = 0.6, STA = 0.5, SP = 0.9 },
  PRIEST  = { INT = 0.8, SPI = 1.0, STA = 0.5, SP = 0.9 },
  WARLOCK = { INT = 0.6, SPI = 0.4, STA = 1.0, SP = 0.9 },
}
FXP.GearWeights = W

local STAT = {
  ITEM_MOD_STRENGTH_SHORT = "STR", ITEM_MOD_AGILITY_SHORT = "AGI", ITEM_MOD_STAMINA_SHORT = "STA",
  ITEM_MOD_INTELLECT_SHORT = "INT", ITEM_MOD_SPIRIT_SHORT = "SPI", ITEM_MOD_ATTACK_POWER_SHORT = "AP",
  ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "RAP", ITEM_MOD_SPELL_POWER_SHORT = "SP", ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SP",
  ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS", RESISTANCE0_NAME = "ARMOR",
}

-- Equip location -> inventory slot(s) it competes with.
local SLOTS = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
  INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}

-- Armor each class should wear while leveling (they can wear lighter, but it's never the upgrade).
-- Item class 4 is armor; its subclasses 1-4 are cloth, leather, mail and plate (language-independent IDs).
local ARMOR_CLASS = 4
local function BestArmor(class, level)
  if class == "WARRIOR" or class == "PALADIN" then return level >= 40 and 4 or 3 end
  if class == "HUNTER" or class == "SHAMAN" then return level >= 40 and 3 or 2 end
  if class == "ROGUE" or class == "DRUID" then return 2 end
  return 1
end

local function Class() local _, c = UnitClass("player"); return c end

local function Weights()
  local w = W[Class() or ""] or W.WARRIOR
  -- caster-specced hybrids care about Intellect/Spirit, not Strength
  local c = Class()
  if (c == "SHAMAN" or c == "DRUID" or c == "PALADIN") and FXP.TalentTree then
    local _, spent = FXP:TalentTree()
    local caster = (c == "SHAMAN" and ((spent[1] or 0) + (spent[3] or 0) > (spent[2] or 0)))
      or (c == "DRUID" and ((spent[1] or 0) + (spent[3] or 0) > (spent[2] or 0)))
      or (c == "PALADIN" and (spent[1] or 0) > (spent[3] or 0))
    if caster then return { INT = 1.0, SPI = 0.6, STA = 0.5, SP = 0.9, ARMOR = 0.005 } end
  end
  return w
end

local function ItemInfo(link)
  local name, _, _, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = GetItemInfo(link)
  return name, reqLevel, classID, subclassID, equipLoc
end

function FXP:ItemScore(link)
  if not link then return nil end
  local f = (C_Item and C_Item.GetItemStats) or GetItemStats
  local stats = f and f(link)
  if type(stats) ~= "table" then return nil end
  local w, score = Weights(), 0
  for k, v in pairs(stats) do
    local s = STAT[k]
    if s and w[s] then score = score + w[s] * v end
  end
  return score
end

-- Is the item an upgrade over what you wear in its slot? Returns delta (score difference, nil if not
-- comparable), the item's score and the slot it would replace.
function FXP:UpgradeFor(link)
  local _, reqLevel, classID, subclassID, equipLoc = ItemInfo(link)
  local slots = equipLoc and SLOTS[equipLoc]
  if not slots then return nil end
  if (reqLevel or 0) > UnitLevel("player") + 5 then return nil end
  if classID == ARMOR_CLASS and subclassID and subclassID >= 1 and subclassID <= 4 and equipLoc ~= "INVTYPE_CLOAK" then
    if subclassID ~= BestArmor(Class(), UnitLevel("player")) then return nil end
  end
  local score = self:ItemScore(link)
  if not score then return nil end
  local worst, worstSlot = nil, slots[1]
  for _, slot in ipairs(slots) do
    local cur = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    local cs = cur and self:ItemScore(cur) or 0
    if not worst or cs < worst then worst, worstSlot = cs, slot end
  end
  return score - worst, score, worstSlot
end

-- Tooltip line
local function AddLine(tt)
  if not (FXP.db and FXP.db.gearHints) then return end
  local _, link = tt:GetItem()
  if not link then return end
  local d, score = FXP:UpgradeFor(link)
  if not d then return end
  if d > 0.5 then
    tt:AddLine(string.format("|cff33ff33ForeverXP: upgrade (+%d)|r", math.floor(d + 0.5)))
  elseif d < -0.5 then
    tt:AddLine(string.format("|cff9a9a9aForeverXP: not an upgrade (%d)|r", math.floor(d - 0.5)))
  end
  tt:Show()
end
if GameTooltip and GameTooltip.HookScript then
  pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", AddLine)
end

-- Quest rewards: name the best choice (by upgrade, else by vendor price).
function FXP:BestReward()
  local n = GetNumQuestChoices and GetNumQuestChoices() or 0
  if n < 2 then return nil end
  local best, bestScore, bestName
  for i = 1, n do
    local link = GetQuestItemLink and GetQuestItemLink("choice", i)
    local name = GetQuestItemInfo and GetQuestItemInfo("choice", i)
    local d = link and self:UpgradeFor(link)
    local score
    if d and d > 0.5 then
      score = 1e6 + d -- an upgrade always beats vendor value
    else
      local price = link and select(11, GetItemInfo(link))
      score = price or 0 -- otherwise the one that sells for most
    end
    if not bestScore or score > bestScore then best, bestScore, bestName = i, score, name or link end
  end
  return best, bestName, bestScore and bestScore >= 1e6
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "QUEST_COMPLETE")
ev:SetScript("OnEvent", function()
  if not (FXP.db and FXP.db.gearHints) then return end
  local i, name, isUpgrade = FXP:BestReward()
  if i and FXP.Print then
    FXP.Print("Best reward for you: |cffffd100%s|r%s.", name or ("choice " .. i), isUpgrade and " (an upgrade)" or " (sells for the most)")
  end
end)
