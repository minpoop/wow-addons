-- Elwynn Forest 6-10 (Alliance). One loop: Goldshire -> Stonefield/Maclure farms ->
-- Fargodeep Mine -> Goldshire -> Crystal Lake -> Jasperlode Mine -> Guard Thomas.
-- Quest IDs are Classic IDs; on WoW Forever the addon re-learns IDs by quest name.
-- Coordinates are Elwynn Forest map coords; check them with /fxp pos and adjust if needed.
local ADDON, ns = ...

ns.FXP:RegisterGuide("Elwynn Forest 6-10", {
  faction = "Alliance", races = { "Human" },
  minLevel = 5, maxLevel = 10,
  zone = "Elwynn Forest", -- map is detected by name in-game
  map = 1429,             -- fallback: Classic Elwynn uiMapID
  next = "Westfall 10-14",
  quests = {
    [83] = "Red Linen Goods", [5545] = "A Bundle of Trouble", [45] = "Discover Rolf's Fate",
    [71] = "Report to Thomas", [39] = "Deliver Thomas' Report", [239] = "Westbrook Garrison Needs Help!",
    [11] = "Riverpaw Gnoll Bounty",
    [62] = "The Fargodeep Mine", [47] = "Gold Dust Exchange", [60] = "Kobold Candles",
    [85] = "Lost Necklace", [86] = "Pie for Billy", [84] = "Back to Billy", [87] = "Goldtooth",
    [106] = "Young Lovers", [111] = "Speak with Gramma", [107] = "Note to William",
    [112] = "Collecting Kelp", [114] = "The Escape", [76] = "The Jasperlode Mine",
    [40] = "A Fishy Peril", [35] = "Further Concerns", [37] = "Find the Lost Guards",
    [46] = "Bounty on Murlocs",
  },
  steps = {
    -- Goldshire
    { accept = 62, npc = "Marshal Dughan", coords = { 42.1, 65.9 } },
    { accept = 47, npc = "Remy \"Two Times\"", coords = { 42.1, 67.3 } },
    { accept = 60, npc = "William Pestle", coords = { 43.3, 65.7 } },
    { bind = "Goldshire", text = "Set your Hearthstone at Innkeeper Farley.", coords = { 43.8, 65.8 }, radius = 8 },
    { train = "Goldshire", coords = { 43.0, 65.5 }, text = "Most class trainers are in and around the Lion's Pride Inn." },

    -- Farms
    { accept = 85, npc = "\"Auntie\" Bernice Stonefield", coords = { 34.5, 84.3 },
      text = "Head south-west to Stonefield Farm. Kill boars on the way, you'll need their meat soon." },
    { turnin = 85, npc = "Billy Maclure", coords = { 43.1, 85.8 } },
    { accept = 86, npc = "Billy Maclure", coords = { 43.1, 85.8 } },
    { accept = 106, npc = "Maybell Maclure", coords = { 43.2, 89.6 }, text = "Maybell is inside the house." },
    { complete = 86, coords = { 39.0, 86.0 }, radius = 80,
      text = "Kill Stonefield and young boars between the farms for 4 Chunks of Boar Meat." },
    { turnin = 106, npc = "Tommy Joe Stonefield", coords = { 29.8, 86.0 } },
    { accept = 111, npc = "Tommy Joe Stonefield", coords = { 29.8, 86.0 } },
    { turnin = 86, npc = "\"Auntie\" Bernice Stonefield", coords = { 34.5, 84.3 } },
    { accept = 84, npc = "\"Auntie\" Bernice Stonefield", coords = { 34.5, 84.3 } },
    { turnin = 111, npc = "Gramma Stonefield", coords = { 34.9, 84.2 }, text = "Gramma is inside the farmhouse." },
    { accept = 107, npc = "Gramma Stonefield", coords = { 34.9, 84.2 } },
    { turnin = 84, npc = "Billy Maclure", coords = { 43.1, 85.8 } },
    { accept = 87, npc = "Billy Maclure", coords = { 43.1, 85.8 } },

    -- Fargodeep Mine
    { complete = { 62, 47, 60 }, coords = { 40.6, 82.3 }, radius = 60,
      text = "Enter Fargodeep Mine (lower entrance). Explore it and kill kobolds for 10 Gold Dust and 8 Large Candles.",
      warn = "Kobold Geomancers cast fire spells and kobolds come in groups inside the mine.", tip = "Use the lower entrance, kill Geomancers first, and pull to corners so you only fight one or two." },
    { complete = 87, coords = { 41.7, 78.0 }, text = "Kill Goldtooth for Bernice's Necklace.",
      warn = "Goldtooth is guarded by kobolds.", tip = "Clear the kobolds around him before pulling Goldtooth himself." },
    { turnin = 87, npc = "\"Auntie\" Bernice Stonefield", coords = { 34.5, 84.3 } },

    -- Back to Goldshire
    { hearth = "Goldshire", text = "Hearth (or run) to Goldshire.", coords = { 42.5, 66.0 }, radius = 25 },
    { turnin = 62, npc = "Marshal Dughan", coords = { 42.1, 65.9 } },
    { train = "Goldshire", coords = { 43.0, 65.5 } },
    { accept = 76, npc = "Marshal Dughan", coords = { 42.1, 65.9 } },
    { turnin = 47, npc = "Remy \"Two Times\"", coords = { 42.1, 67.3 } },
    { accept = 40, npc = "Remy \"Two Times\"", coords = { 42.1, 67.3 }, ifLevel = 7 },
    { turnin = 40, npc = "Marshal Dughan", coords = { 42.1, 65.9 }, ifLevel = 7 },
    { accept = 35, npc = "Marshal Dughan", coords = { 42.1, 65.9 }, ifLevel = 7 },
    { turnin = { 60, 107 }, npc = "William Pestle", coords = { 43.3, 65.7 },
      text = "Skip \"Shipment to Stormwind\"." },
    { accept = 112, npc = "William Pestle", coords = { 43.3, 65.7 } },

    -- Crystal Lake
    { complete = 112, coords = { 51.5, 63.5 }, radius = 60,
      text = "Kill murlocs around Crystal Lake for 4 Crystal Kelp Fronds. WoW Forever: grab \"A Net Disaster\" / \"A Man About a Murloc\" here too if they're offered.",
      warn = "Murlocs run away at low health and bring friends.", tip = "Pull from the edge of the lake, finish runners fast, and stay out of the water." },
    { turnin = 112, npc = "William Pestle", coords = { 43.3, 65.7 } },
    { accept = 114, npc = "William Pestle", coords = { 43.3, 65.7 } },
    { turnin = 114, npc = "Maybell Maclure", coords = { 43.2, 89.6 } },

    -- East Elwynn
    { complete = 76, coords = { 61.6, 54.1 }, radius = 30,
      text = "Run north-east to Jasperlode Mine and explore inside. Kill any kobolds in your way.",
      warn = "Jasperlode kobolds are level 9-11.", tip = "If you are under level 9, skip the deep parts; exploring the first chamber gives credit." },
    { accept = 83, npc = "Sara Timberlain", coords = { 79.5, 68.8 }, text = "Eastvale Logging Camp." },
    { accept = 5545, npc = "Supervisor Raelen", coords = { 81.4, 66.1 } },
    { turnin = 35, npc = "Guard Thomas", coords = { 73.9, 72.2 }, ifLevel = 7,
      text = "Guard Thomas is at the bridge west of Eastvale Logging Camp." },
    { accept = 37, npc = "Guard Thomas", coords = { 73.9, 72.2 }, ifLevel = 7 },
    { turnin = 37, npc = "A half-eaten body", coords = { 73.0, 60.0 }, ifLevel = 7,
      text = "Follow the river north. The body is on the west bank where the river forks." },
    { accept = 45, npc = "A half-eaten body", coords = { 73.0, 60.0 }, ifLevel = 7 },
    { turnin = 45, npc = "Rolf's corpse", coords = { 79.8, 55.5 }, ifLevel = 7,
      text = "Rolf's corpse lies in the murloc camp north-east of the lake.",
      warn = "The murloc camp around Rolf's body is crowded and murlocs flee to bring friends.",
      tip = "Clear a path from the west edge, then click the corpse. Don't fight at the huts." },
    { accept = 71, npc = "Rolf's corpse", coords = { 79.8, 55.5 }, ifLevel = 7 },
    { complete = 5545, coords = { 82.0, 62.0 }, radius = 60,
      text = "Pick up 8 Bundles of Wood at the base of trees around Eastvale." },
    { complete = 83, coords = { 69.5, 78.0 }, radius = 50,
      text = "Kill Defias at the Brackwell Pumpkin Patch for 6 Red Linen Bandanas.",
      warn = "Princess (level 9 boar) and her guards roam the pumpkin patch.",
      tip = "Pull Defias on the edges and keep away from Princess unless you have a friend." },
    { turnin = 5545, npc = "Supervisor Raelen", coords = { 81.4, 66.1 } },
    { turnin = 83, npc = "Sara Timberlain", coords = { 79.5, 68.8 } },
    { turnin = 71, npc = "Guard Thomas", coords = { 73.9, 72.2 }, ifLevel = 7 },
    { accept = 39, npc = "Guard Thomas", coords = { 73.9, 72.2 }, ifLevel = 7 },

    -- Back west
    { turnin = 76, npc = "Marshal Dughan", coords = { 42.1, 65.9 }, text = "Back in Goldshire." },
    { turnin = 39, npc = "Marshal Dughan", coords = { 42.1, 65.9 }, ifLevel = 7,
      text = "Run west along the road to Goldshire. Skip \"Cloth and Leather Armor\"." },
    { accept = 239, npc = "Marshal Dughan", coords = { 42.1, 65.9 } },
    { train = "Goldshire", coords = { 43.0, 65.5 } },
    { turnin = 239, npc = "Deputy Rainer", coords = { 24.2, 74.5 }, text = "Westbrook Garrison, west of Goldshire." },
    { accept = 11, npc = "Deputy Rainer", coords = { 24.2, 74.5 } },
    { complete = 11, coords = { 26.0, 88.0 }, radius = 80,
      text = "Kill Riverpaw gnolls south of Westbrook for 8 Painted Gnoll Armbands.",
      warn = "Hogger (elite, level 11) patrols the gnoll camps here.",
      tip = "Watch your map for Hogger and stay away from him solo. Pull gnolls one at a time." },
    { turnin = 11, npc = "Deputy Rainer", coords = { 24.2, 74.5 } },
    { level = 10, coords = { 26.0, 88.0 }, radius = 120,
      text = "Grind gnolls to level 10 if needed, then follow the road west into Westfall." },
  },
})
