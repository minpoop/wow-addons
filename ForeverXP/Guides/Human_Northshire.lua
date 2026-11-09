-- Sample guide: Human start (Northshire), Classic map IDs.
-- Coordinates are approximate - fine-tune them in-game with /fxp pos (see README).
local ADDON, ns = ...

ns.FXP:RegisterGuide("Northshire 1-6", {
  faction = "Alliance", races = { "Human" },
  minLevel = 1, maxLevel = 6,
  zone = "Elwynn Forest", -- map is detected by name in-game
  map = 1429,             -- fallback: Classic Elwynn uiMapID
  next = "Elwynn Forest 6-10",
  quests = {
    [783] = "A Threat Within", [7] = "Kobold Camp Cleanup", [5261] = "Eagan Peltskinner",
    [33] = "Wolves Across the Border", [18] = "Brotherhood of Thieves",
    [15] = "Investigate Echo Ridge", [21] = "Skirmish at Echo Ridge",
    [6] = "Bounty on Garrick Padfoot", [54] = "Report to Goldshire",
  },
  steps = {
    { accept = 783, npc = "Deputy Willem", coords = { 48.2, 42.9 } },
    { turnin = 783, npc = "Marshal McBride", coords = { 48.9, 41.6 }, text = "Go inside the Abbey." },
    { accept = 7, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { accept = { 5261, 18 }, npc = "Deputy Willem", coords = { 48.2, 42.9 } },
    { turnin = 5261, npc = "Eagan Peltskinner", coords = { 48.9, 40.1 } },
    { accept = 33, npc = "Eagan Peltskinner", coords = { 48.9, 40.1 } },
    { complete = { 7, 33 }, coords = { 47.5, 35.5 }, radius = 60, noArrow = false,
      text = "Kill Kobold Vermin and Young Wolves north of the Abbey.",
      tip = "Kobold Vermin are easy; pull wolves one at a time and eat between fights." },
    { turnin = 33, npc = "Eagan Peltskinner", coords = { 48.9, 40.1 } },
    { turnin = 7, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { train = "Northshire Abbey", coords = { 49.5, 41.5 }, ifLevel = 4,
      text = "Your class trainer is inside or just outside the Abbey." },
    { accept = 15, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { complete = { 15, 18 }, coords = { 47.5, 34.0 }, radius = 70,
      text = "Kill Kobold Workers outside Echo Ridge Mine (around 46, 33), then Defias Thugs across the river east of the Abbey for bandanas.",
      warn = "Defias Thugs hit hard for level 3-4.", tip = "Fight one Thug at a time and keep your health above half before the next pull." },
    { turnin = 15, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { accept = 21, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { turnin = 18, npc = "Deputy Willem", coords = { 48.2, 42.9 } },
    { accept = 6, npc = "Deputy Willem", coords = { 48.2, 42.9 } },
    { complete = 21, coords = { 47.6, 31.8 }, text = "Enter Echo Ridge Mine and kill Kobold Laborers.",
      warn = "The mine tunnels are packed with Kobold Laborers.", tip = "Clear slowly from the entrance; never run deep in, or you'll pull several at once." },
    { complete = 6, coords = { 57.5, 48.0 }, text = "Kill Garrick Padfoot at the cabin southeast of the Abbey.",
      warn = "Garrick Padfoot (level 5) has Defias Thugs around his cabin.", tip = "Kill the Thugs outside first, then pull Garrick alone. Be level 5 if you can." },
    { turnin = 21, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { accept = 54, npc = "Marshal McBride", coords = { 48.9, 41.6 } },
    { turnin = 6, npc = "Deputy Willem", coords = { 48.2, 42.9 } },
    { text = "Follow the road south out of Northshire to Goldshire.", coords = { 42.1, 65.9 }, radius = 20 },
    { turnin = 54, npc = "Marshal Dughan", coords = { 42.1, 65.9 } },
  },
})
