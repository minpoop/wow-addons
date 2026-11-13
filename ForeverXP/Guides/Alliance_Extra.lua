-- Extra zones (v2.4): the Classic zones the first route skipped, plus WoW Forever's new zones.
-- Main route additions:  Badlands 38-40 (mount stop), Swamp of Sorrows 41-42, The Riverglades 42-44 (Forever),
--                        Searing Gorge 48-50, Blasted Lands 50-51, Burning Steppes 51-53.
-- Side guides (pick with /fxp load): Thousand Needles 30-32, Desolace 32-35, Shen'dralas (Forever),
--                        Azshara 48-50, Silithus 55-58.
-- Steps for quests WoW Forever may not offer are optional and skip themselves.
local ADDON, ns = ...
local FXP = ns.FXP

---------------------------------------------------------------------------
FXP:RegisterGuide("Badlands 38-40", {
  faction = "Alliance", minLevel = 38, maxLevel = 40, zone = "Badlands",
  next = "Stranglethorn Vale 38-42",
  steps = {
    { text = "Boat Theramore -> Menethil, fly to Thelsamar (Loch Modan) and ride south through the gate into the Badlands.",
      coords = { 46.0, 12.0 }, radius = 25,
      warn = "Badlands has no Alliance flight path, and Dustbelcher ogres guard the northern road.", tip = "Set your Hearthstone in Thelsamar before you leave." },
    { accept = "Find Agmond", optional = true, text = "From Prospector Ironband in Loch Modan, if you have it." },
    { accept = { "Mirages", "A Dwarf and His Tools" }, optional = true, npc = "Prospector Ryedol", coords = { 53.4, 43.4 } },
    { accept = { "Barbecued Buzzard Wings", "Power Stones" }, optional = true, npc = "Rigglefuzz", coords = { 42.4, 52.8 } },
    { accept = "Study of the Elements: Rock", optional = true, npc = "Lotwil Veriatus", coords = { 25.8, 44.4 } },
    { accept = "Solution to Doom", optional = true, npc = "Theldurin the Lost", coords = { 51.4, 76.8 } },
    { complete = "Find Agmond", optional = true, coords = { 49.0, 25.0 }, radius = 120,
      text = "Search the Stonevault troggs' area north-east for Agmond's remains." },
    { complete = { "Barbecued Buzzard Wings", "A Dwarf and His Tools" }, optional = true, coords = { 50.0, 50.0 }, radius = 300,
      text = "Buzzards everywhere for wings; Dark Iron dwarves at Angor Fortress area for Ryedol's tools." },
    { complete = "Power Stones", optional = true, coords = { 60.0, 60.0 }, radius = 200,
      text = "Dark Iron dwarves (Angor Fortress) drop Power Stones.",
      warn = "Angor Fortress dwarves are packed in groups of three.", tip = "Pull the outer dwarves; don't go inside the fortress." },
    { complete = "Study of the Elements: Rock", optional = true, coords = { 20.0, 60.0 }, radius = 200,
      text = "Lesser Rock Elementals west of Lotwil." },
    { complete = "Mirages", optional = true, coords = { 66.0, 22.0 }, radius = 60, text = "Find the mirage source east of Ryedol." },
    { turnin = { "Barbecued Buzzard Wings", "Power Stones" }, optional = true, npc = "Rigglefuzz", coords = { 42.4, 52.8 } },
    { turnin = { "Mirages", "A Dwarf and His Tools", "Find Agmond" }, optional = true, coords = { 53.4, 43.4 } },
    { turnin = "Study of the Elements: Rock", optional = true, npc = "Lotwil Veriatus", coords = { 25.8, 44.4 } },
    { complete = "Solution to Doom", optional = true, text = "Uldaman: the tablet is inside the dungeon entrance area." },
    { turnin = "Solution to Doom", optional = true, coords = { 51.4, 76.8 } },
    { level = 40, coords = { 50.0, 50.0 }, radius = 400,
      text = "Grind to 40 - buzzards, coyotes and Dustbelcher ogres." },

    -- Level 40 mount stop (one of these shows, depending on your race)
    { mount = true, races = { "Human" }, zone = "Elwynn Forest", coords = { 84.2, 65.5 },
      text = "Mount stop: Eastvale Logging Camp in Elwynn - Randal Hunter (riding) and Katie Hunter (horses). Hearth to Thelsamar, fly Ironforge -> tram -> Stormwind and ride east.",
      tip = "Classic prices were about 90-100g with reputation discounts; check the trainer for Forever's price." },
    { mount = true, races = { "Dwarf" }, zone = "Dun Morogh", coords = { 63.5, 50.6 },
      text = "Mount stop: Amberstill Ranch in Dun Morogh - Ultham Ironhorn (riding) and Veron Amberstill (rams). Fly to Ironforge and ride east.",
      tip = "Classic prices were about 90-100g with reputation discounts; check the trainer for Forever's price." },
    { mount = true, races = { "Gnome" }, zone = "Dun Morogh", coords = { 49.2, 48.0 },
      text = "Mount stop: Steelgrill's Depot in Dun Morogh - Binjy Featherwhistle (riding) and Milli Featherwhistle (mechanostriders).",
      tip = "Classic prices were about 90-100g with reputation discounts; check the trainer for Forever's price." },
    { mount = true, races = { "NightElf" }, zone = "Darnassus", coords = { 38.2, 15.2 },
      text = "Mount stop: Darnassus - Jartsam (riding) and Lelanai (frostsabers). Boat Menethil -> Auberdine -> Rut'theran.",
      tip = "Long trip: combine it with your next trainer visit, or buy a ram/horse here if your reputation allows." },
    { mount = true, races = { "Skyborne", "ShenDorei", "Shendorei" },
      text = "Mount stop: Skyborne riding trainer and mount vendor (check your capital; Forever's location is new)." },
    { text = "Mounted? Ride back toward Stormwind and fly to Booty Bay for Stranglethorn.",
      zone = "Stormwind City", coords = { 66.2, 62.2 }, radius = 15 },
  },
})

---------------------------------------------------------------------------
FXP:RegisterGuide("Swamp of Sorrows 41-42", {
  faction = "Alliance", minLevel = 41, maxLevel = 42, zone = "Swamp of Sorrows",
  next = "The Riverglades 42-44",
  steps = {
    { fly = "Darkshire", text = "Fly Booty Bay -> Darkshire, ride east through Deadwind Pass into the Swamp of Sorrows.",
      coords = { 4.0, 62.0 }, radius = 25,
      warn = "Deadwind Pass ogres and Swamp crocolisks are 40+.", tip = "Ride through the pass without stopping." },
    { accept = "Galen's Escape", optional = true, npc = "Galen Goodward", coords = { 53.2, 29.6 },
      text = "Galen is caged in the Fallow Sanctuary (north of the lake)." },
    { complete = "Galen's Escape", optional = true, coords = { 47.0, 39.0 }, radius = 100,
      text = "Escort Galen out of the Marsh; open his strongbox at the end.",
      warn = "Escort: Marsh murlocs ambush in pairs.", tip = "Stay close and kill ambushers before they reach Galen." },
    { turnin = "Galen's Escape", optional = true, coords = { 47.8, 39.6 }, text = "Galen's Strongbox." },
    { level = 42, coords = { 60.0, 40.0 }, radius = 400,
      text = "Grind Marsh murlocs / Sawtooth crocolisks to 42, then head north through Redridge Pass." },
    { text = "Leave north through Redridge Pass into the Riverglades.", coords = { 25.0, 5.0 }, radius = 30 },
  },
})

---------------------------------------------------------------------------
-- WoW Forever zone. Quest names aren't published yet, so this guide is hub-based:
-- Questie draws and tracks the quests, the guide paces your levels and travel.
FXP:RegisterGuide("The Riverglades 42-44", {
  faction = "Alliance", minLevel = 42, maxLevel = 44, zone = "Riverglades",
  next = "Tanaris 42-45",
  steps = {
    { fp = "Farholde Keep", bind = "Farholde Keep", text = "From Redridge Pass, head to Farholde Keep - the Alliance town on the island in the south-east. Take the flight path and set your Hearthstone.",
      tip = "Arriving from Lakeshire instead: go east through Redridge Pass south of the Bristle Hills." },
    { level = 43, text = "Farholde Keep hub: take every quest (Questie '!' marks) and work the southern settlements - Wheeler's Grange and Windstead.",
      warn = "Riverglades is contested: expect Horde from Rog'mar in the middle of the zone.",
      tip = "Hand in at Farholde between loops; the flight path saves the river crossings." },
    { level = 44, text = "Push north: Meadowsbrook, Elbrim's Farm and Turner's Logging Camp, then the ruins of Sunnyglade.",
      warn = "Sunnyglade and Twilight's Shroud are held by the Twilight's Hammer - caster packs and patrols.",
      tip = "Kill casters first and pull from the edges; don't fight in the middle of Sunnyglade." },
    { text = "Optional dungeon: Krol'dok Stronghold (level 40-45) - pick up its quests at Farholde Keep. See /fxp dungeons.",
      group = 5 },
    { text = "Ride to Powderfuse Port on the east coast and take the boat to Steamwheedle Port in Tanaris." },
  },
})

---------------------------------------------------------------------------
FXP:RegisterGuide("Searing Gorge 48-50", {
  faction = "Alliance", minLevel = 48, maxLevel = 50, zone = "Searing Gorge",
  next = "Blasted Lands 50-51",
  steps = {
    { fly = "Lakeshire", text = "Fly to Lakeshire (Redridge), ride north into the Burning Steppes and grab the Morgan's Vigil flight path, then ride west along the road to Blackrock Mountain and through to the Searing Gorge.",
      zone = "Burning Steppes", coords = { 84.4, 68.3 }, radius = 20,
      warn = "Burning Steppes mobs are 50-55; stay on the road at 48.", tip = "Take the Burning Steppes quests later - you'll be back at 51." },
    { text = "Thorium Point (north-west Searing Gorge): flight path.", coords = { 37.9, 30.8 }, radius = 20 },
    { accept = "JOB OPPORTUNITY: Culling the Competition", optional = true, coords = { 37.6, 26.5 },
      text = "Wanted poster at Thorium Point." },
    { accept = { "Curse These Fat Fingers", "Fiery Menace!", "Incendosaurs? Whateverosaur is More Like It" }, optional = true, coords = { 38.0, 27.0 } },
    { accept = "Divine Retribution", optional = true, npc = "Kalaran Windblade", coords = { 39.0, 38.9 } },
    { complete = { "Curse These Fat Fingers", "Fiery Menace!" }, optional = true, coords = { 30.0, 50.0 }, radius = 300,
      text = "Glassweb Spiders, Heavy War Golems and Magma Elementals around the gorge." },
    { complete = "JOB OPPORTUNITY: Culling the Competition", optional = true, coords = { 42.0, 33.0 }, radius = 80,
      text = "Dark Iron Geologists and Taskmasters at the Grimesilt Dig Site." },
    { complete = "Incendosaurs? Whateverosaur is More Like It", optional = true, coords = { 60.0, 60.0 }, radius = 80,
      text = "Incendosaurs in the Slag Pit (south-east cavern).",
      warn = "The Slag Pit is crowded and has slaves who turn hostile.", tip = "Go in slowly and pull with range." },
    { complete = "Divine Retribution", optional = true, coords = { 42.0, 55.0 }, radius = 200,
      text = "Dark Iron Taskmasters and Slavers for the Kalaran chain." },
    { turnin = { "Curse These Fat Fingers", "Fiery Menace!", "Incendosaurs? Whateverosaur is More Like It",
      "JOB OPPORTUNITY: Culling the Competition" }, optional = true, coords = { 38.0, 27.0 } },
    { turnin = "Divine Retribution", optional = true, coords = { 39.0, 38.9 } },
    { accept = "The Flawless Flame", optional = true, coords = { 39.0, 38.9 } },
    { complete = "The Flawless Flame", optional = true, coords = { 40.0, 60.0 }, radius = 300,
      text = "Heavy War Golems and Magma Elementals." },
    { turnin = "The Flawless Flame", optional = true, coords = { 39.0, 38.9 } },
    { level = 50, coords = { 40.0, 50.0 }, radius = 400, text = "Grind golems / elementals to 50." },
    { train = "Ironforge", zone = "Ironforge", text = "Fly Thorium Point -> Ironforge and train level 50 skills." },
  },
})

---------------------------------------------------------------------------
FXP:RegisterGuide("Blasted Lands 50-51", {
  faction = "Alliance", minLevel = 50, maxLevel = 51, zone = "Blasted Lands",
  next = "Burning Steppes 51-53",
  steps = {
    { text = "Fly to Lakeshire, ride south through Redridge Pass and the Swamp of Sorrows, then south into the Blasted Lands to Nethergarde Keep. Get the flight path.",
      coords = { 65.5, 24.3 }, radius = 20,
      warn = "The Dark Portal area (south) is full of 55+ demons.", tip = "Stay in the north half of the zone." },
    { accept = { "Snickerfang Jowls", "The Basilisk's Bite", "Vulture's Vigor", "The Decisive Striker", "A Boar's Vitality" },
      optional = true, coords = { 66.7, 20.0 },
      text = "Bloodmage Drazial and Bloodmage Lynnore at Nethergarde Keep - five collection quests that each give great XP." },
    { complete = { "Snickerfang Jowls", "The Basilisk's Bite", "Vulture's Vigor", "The Decisive Striker", "A Boar's Vitality" },
      optional = true, coords = { 50.0, 35.0 }, radius = 400,
      text = "Snickerfang Hyenas, Redstone Basilisks, vultures, scorpoks and Ashmane Boars across the northern Blasted Lands.",
      tip = "Kill everything you pass - the drops for all five quests overlap." },
    { turnin = { "Snickerfang Jowls", "The Basilisk's Bite", "Vulture's Vigor", "The Decisive Striker", "A Boar's Vitality" },
      optional = true, coords = { 66.7, 20.0 } },
    { level = 51, coords = { 50.0, 35.0 }, radius = 400, text = "Keep farming the northern beasts to 51 - the collection quests can be repeated for more drops." },
  },
})

---------------------------------------------------------------------------
FXP:RegisterGuide("Burning Steppes 51-53", {
  faction = "Alliance", minLevel = 51, maxLevel = 53, zone = "Burning Steppes",
  next = "Un'Goro Crater 53-54",
  steps = {
    { text = "Fly Nethergarde -> Lakeshire -> Morgan's Vigil (or ride north from Redridge).", coords = { 84.4, 68.3 }, radius = 20 },
    { accept = { "Extinguish the Firegut", "FIFTY! YEP!" }, optional = true, npc = "Oralius", coords = { 84.6, 68.6 } },
    { accept = "Dragonkin Menace", optional = true, npc = "Helendis Riverhorn", coords = { 85.8, 69.0 } },
    { accept = "Gor'tesh the Brute Lord", optional = true, npc = "Marshal Maxwell", coords = { 84.6, 68.7 } },
    { turnin = "Yuka Screwspigot", optional = true, text = "If you carried it from Tanaris - Yuka is at Flame Crest." },
    { complete = { "Extinguish the Firegut", "FIFTY! YEP!" }, optional = true, coords = { 80.0, 45.0 }, radius = 200,
      text = "Firegut ogres at Dreadmaul Rock; Blackrock orcs all over the zone for FIFTY! YEP!",
      warn = "Firegut ogre camps have casters that heal.", tip = "Interrupt or kill the Firegut Ogre Mages first." },
    { complete = "Dragonkin Menace", optional = true, coords = { 60.0, 45.0 }, radius = 300,
      text = "Black Broodlings, Black Dragonspawn and Black Wyrmkin across the middle of the zone." },
    { complete = "Gor'tesh the Brute Lord", optional = true, coords = { 37.0, 51.0 }, radius = 60,
      text = "Gor'tesh at Blackrock Stronghold (west).",
      warn = "Gor'tesh is surrounded by Blackrock orc patrols.", tip = "Clear the approach and pull him to the outer wall." },
    { turnin = { "Extinguish the Firegut", "FIFTY! YEP!", "Dragonkin Menace", "Gor'tesh the Brute Lord" }, optional = true, coords = { 84.6, 68.7 } },
    { level = 53, coords = { 60.0, 45.0 }, radius = 400, text = "Grind dragonkin / Blackrock orcs to 53." },
    { train = "Stormwind City", zone = "Stormwind City",
      text = "Fly to Stormwind, train 52 skills, then Menethil -> Theramore -> Gadgetzan for Un'Goro." },
  },
})

---------------------------------------------------------------------------
-- SIDE GUIDES (not in the default chain; load from /fxp)
---------------------------------------------------------------------------
FXP:RegisterGuide("Thousand Needles 30-32 (side)", {
  faction = "Alliance", minLevel = 30, maxLevel = 32, zone = "Thousand Needles", side = true,
  next = "Stranglethorn Vale 30-34",
  steps = {
    { text = "Mirage Raceway in the Shimmering Flats (south-east). Fly to Theramore, then ride down through Dustwallow into Thousand Needles, or swim from Tanaris.",
      coords = { 78.0, 77.0 }, radius = 30 },
    { accept = { "A Bump in the Road", "Hardened Shells", "Load Lightening", "Salt Flat Venom", "Rocket Car Parts" }, optional = true,
      coords = { 78.0, 77.0 } },
    { complete = { "A Bump in the Road", "Hardened Shells", "Load Lightening", "Salt Flat Venom", "Rocket Car Parts" }, optional = true,
      coords = { 75.0, 65.0 }, radius = 400,
      text = "Basilisks, tortoises, scorpids and rocket car parts across the Shimmering Flats." },
    { turnin = { "A Bump in the Road", "Hardened Shells", "Load Lightening", "Salt Flat Venom", "Rocket Car Parts" }, optional = true,
      coords = { 78.0, 77.0 } },
    { level = 32, coords = { 75.0, 65.0 }, radius = 400, text = "Grind the flats to 32." },
  },
})

FXP:RegisterGuide("Desolace 32-35 (side)", {
  faction = "Alliance", minLevel = 32, maxLevel = 35, zone = "Desolace", side = true,
  next = "Arathi Highlands 34-36",
  steps = {
    { text = "Nijel's Point (north): flight path and Hearthstone. Reach it on foot from Stonetalon or fly from Astranaar after one walk.",
      coords = { 64.6, 10.5 }, radius = 20 },
    { accept = { "Vahlarriel's Search#1", "Centaur Bounty", "Reagents for Reclaimers Inc.#1" }, optional = true, coords = { 66.0, 8.0 } },
    { accept = "Kodo Roundup", optional = true, text = "Smeed Scrabblescrew / Hornizz Brimbuzzle at Ethel Rethor." },
    { complete = "Centaur Bounty", optional = true, coords = { 70.0, 50.0 }, radius = 250, text = "Magram / Gelkis centaur camps." },
    { complete = "Kodo Roundup", optional = true, coords = { 50.0, 60.0 }, radius = 200,
      text = "Use the Kodo Kombobulator on Aged / Ancient / Dying Kodos in the Kodo Graveyard and lead them to Smeed." },
    { complete = "Reagents for Reclaimers Inc.#1", optional = true, coords = { 50.0, 20.0 }, radius = 300 },
    { turnin = { "Vahlarriel's Search#1", "Centaur Bounty", "Reagents for Reclaimers Inc.#1", "Kodo Roundup" }, optional = true },
    { text = "Shen'dralas (WoW Forever) lies south through the Valley of Bones - see the Shen'dralas side guide." },
    { level = 35, coords = { 60.0, 40.0 }, radius = 400, text = "Grind to 35." },
  },
})

-- WoW Forever zone: level range and Alliance hub are not published yet.
FXP:RegisterGuide("Shen'dralas 40-45 (side)", {
  faction = nil, minLevel = 40, maxLevel = 45, zone = "Shen'dralas", side = true,
  next = "Tanaris 42-45",
  steps = {
    { text = "From Desolace, go south through the Valley of Bones into Shen'dralas.",
      tip = "Level range isn't confirmed - published estimates run from 40 to 53. Leave if quests show red." },
    { level = 42, text = "Take the quests Questie shows (Evenshade Overlook, Outcast Hideaway, Magram Front).",
      warn = "Magram and Bristleback camps are packed; Shen'dralar areas may be elite.", tip = "Pull from camp edges." },
    { level = 45, text = "Finish the zone's story. Some chains continue into Maraudon and Razorfen Downs - see /fxp dungeons." },
  },
})

FXP:RegisterGuide("Azshara 48-50 (side)", {
  faction = "Alliance", minLevel = 48, maxLevel = 50, zone = "Azshara", side = true,
  next = "Un'Goro Crater 53-54",
  steps = {
    { text = "Talrendis Point (south-west Azshara): flight path. Ride east from Ashenvale's Forest Song.",
      coords = { 11.9, 77.6 }, radius = 20,
      tip = "WoW Forever expanded Azshara - Questie will show the new quests here too." },
    { accept = { "Kim'jael Indeed!" }, optional = true, npc = "Kim'jael", coords = { 53.4, 21.8 } },
    { complete = "Kim'jael Indeed!", optional = true, coords = { 56.0, 26.0 }, radius = 150,
      text = "Recover Kim'jael's equipment from the Blood Elves and Wardens at the camp nearby." },
    { turnin = "Kim'jael Indeed!", optional = true, coords = { 53.4, 21.8 } },
    { level = 50, coords = { 40.0, 50.0 }, radius = 500, text = "Quest the expanded zone with Questie and grind to 50." },
  },
})

FXP:RegisterGuide("Silithus 55-58 (side)", {
  faction = "Alliance", minLevel = 55, maxLevel = 58, zone = "Silithus", side = true,
  next = "Western Plaguelands 56-58",
  steps = {
    { text = "Fly Marshal's Refuge (Un'Goro) -> Cenarion Hold. Take the flight path and set your Hearthstone.",
      coords = { 50.6, 34.5 }, radius = 20 },
    { accept = { "Securing the Supply Lines", "Deadly Desert Venom" },
      optional = true, coords = { 50.0, 36.0 } },
    { complete = { "Securing the Supply Lines", "Deadly Desert Venom" }, optional = true, coords = { 40.0, 45.0 }, radius = 300,
      text = "Dredge Strikers / Crushers and Stonelash scorpids near Cenarion Hold.",
      warn = "Twilight's Hammer camps and Qiraji patrols are 58+.", tip = "Keep to the northern half." },
    { turnin = { "Securing the Supply Lines", "Deadly Desert Venom" }, optional = true, coords = { 50.0, 36.0 } },
    { level = 58, coords = { 45.0, 40.0 }, radius = 500, text = "Quest and grind to 58, then fly back to the Plaguelands." },
  },
})
