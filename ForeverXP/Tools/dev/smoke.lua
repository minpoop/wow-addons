-- Smoke test: loads the addon in the harness stubs, then for an Alliance and a Horde character runs every slash
-- command, every theme, every step of every guide through the per-step helpers, every event and every script
-- handler on every frame, and reports anything that throws.
--   lua -e "arg_root='.'" Tools/dev/smoke.lua
-- Expected: 8 errors, all stub artifacts (QUEST_ACCEPTED gets a string id; GetQuestID / IsQuestCompletable are
-- not stubbed). Anything else is a bug.
assert(arg_root, 'set arg_root')
local h = io.open(arg_root .. '/Tools/dev/harness.lua'):read('a')
local cut = h:find("\nlocal fails = 0", 1, true)
local ns = assert(load(h:sub(1, cut) .. "\nreturn ns\n", "@harness-prefix"))()
local FXP = ns.FXP
-- stubs the prefix doesn't have
GameTooltip = Obj(); GameTooltip.GetItem = function() return "Item", "item:1" end
StaticPopupDialogs = {}; StaticPopup_Show = function() return Obj() end; StaticPopup_Hide = function() end
SOUNDKIT = { IG_QUEST_LIST_COMPLETE = 1, RAID_WARNING = 2, UI_RAID_BOSS_WHISPER_WARNING = 3 }; PlaySound = function() end
RaidWarningFrame = Obj(); RaidNotice_AddMessage = function() end
GetZoneText = function() return "Westfall" end; GetRealZoneText = GetZoneText; GetSubZoneText = function() return "Sentinel Hill" end
GetMinimapZoneText = GetSubZoneText; GetBindLocation = function() return "Goldshire" end
date = function() return "2026-11-13 12:00" end; IsShiftKeyDown = function() return false end
InCombatLockdown = function() return false end; IsInGroup = function() return false end
GetPlayerFacing = function() return 0 end; GetCVar = function() return "0" end; IsIndoors = function() return false end
UnitName = function() return "Me" end; UnitExists = function() return false end
UnitHealth = function() return 100 end; UnitHealthMax = function() return 100 end; UnitAffectingCombat = function() return false end
UnitOnTaxi = function() return true end; hooksecurefunc = function() end
NumTaxiNodes = function() return 0 end; GetTime = function() return 100 end
CreateVector2D = function(x, y) return { x = x, y = y } end
local errors, n = {}, 0
local function try(what, fn, ...) n = n + 1; local ok, e = pcall(fn, ...); if not ok then errors[#errors + 1] = what .. " -> " .. tostring(e) end end
for _, race in ipairs({ { "Human", "Alliance" }, { "Orc", "Horde" } }) do
  PLAYER.race, PLAYER.faction, PLAYER.level = race[1], race[2], 12
  -- login
  for _, o in ipairs(ALLOBJ) do local f = o._scripts.OnEvent; if f then try("PLAYER_LOGIN", f, o, "PLAYER_LOGIN") end end
  try("BuildUI", function() if not FXP.frame then FXP:BuildUI() end end)
  try("PickGuide+Load", function() FXP:LoadGuide(FXP:PickGuide()) end)
  -- every theme
  for _, th in ipairs(ns.Themes) do FXP.db.theme = th.key; try("theme " .. th.key, FXP.ApplyTheme, FXP) end
  -- every slash command
  for _, c in ipairs({ "", "toggle", "toggle", "next", "prev", "step 5", "list", "reset", "dungeons", "questie", "forgive", "xp", "arrow", "arrow",
      "lock", "lock", "pos", "tier 45", "tier", "cleanup", "report", "report something is off", "check", "export", "talents", "sync",
      "hardcore", "hardcore", "help", "load Nope" }) do
    try("/fxp " .. c, SlashCmdList.FOREVERXP, c)
  end
  -- walk every guide of this faction, rendering each step with all per-step helpers
  for _, name in ipairs(FXP.guideOrder) do
    local g = FXP.guides[name]
    if not g.faction or g.faction == race[2] then
      FXP.guide = g
      for i, s in ipairs(g.steps) do
        FXP.db.step = i
        try(name .. " #" .. i .. " text", FXP.StepText, FXP, s, true)
        try(name .. " #" .. i .. " done", FXP.IsStepDone, FXP, s)
        try(name .. " #" .. i .. " targets", FXP.StepTargets, FXP, s)
        try(name .. " #" .. i .. " items", FXP.StepItems, FXP, s)
        try(name .. " #" .. i .. " coords", FXP.StepCoords, FXP, s)
        try(name .. " #" .. i .. " danger", FXP.DangerLine, FXP, s)
      end
      FXP.db.step = 1
      try(name .. " update", FXP.Update, FXP)
      try(name .. " pins", FXP.RefreshMinimapPins, FXP)
    end
  end
  -- events with plausible arguments
  local events = { "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "TRAINER_SHOW", "TRAINER_CLOSED", "TAXIMAP_OPENED", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "CONFIRM_BINDER", "UI_INFO_MESSAGE",
    "HEARTHSTONE_BOUND", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "NAME_PLATE_UNIT_ADDED", "UPDATE_MOUSEOVER_UNIT",
    "PLAYER_TARGET_CHANGED", "PLAYER_DEAD", "PLAYER_LOGOUT", "CHARACTER_POINTS_CHANGED", "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "UNIT_HEALTH" }
  for _, ev in ipairs(events) do
    for _, o in ipairs(ALLOBJ) do
      local f = o._scripts.OnEvent
      if f then try("event " .. ev, f, o, ev, ev == "PLAYER_LEVEL_UP" and 13 or (ev == "UNIT_HEALTH" and "player" or (ev == "CHAT_MSG_ADDON" and "FXPSYNC" or 5)), "S\tWestfall 10-14\t3", "PARTY", "Other") end
    end
  end
  -- every other script handler on every frame the addon created
  for _, o in ipairs(ALLOBJ) do
    for name, f in pairs(o._scripts) do
      if name ~= "OnEvent" then
        for _ = 1, (name == "OnUpdate" and 30 or 1) do try("script " .. name, f, o, name == "OnUpdate" and 0.3 or "LeftButton") end
      end
    end
  end
end
io.write(string.format("\n%d calls, %d errors\n", n, #errors))
local seen = {}
for _, e in ipairs(errors) do local k = e:gsub("#%d+", "#N"):gsub("^[^>]*%-> ", ""); if not seen[k] then seen[k] = true; io.write("  ", e, "\n") end end
