# ForeverXP — free leveling guide addon

## Install
1. Unzip so you have `World of Warcraft/<game folder>/Interface/AddOns/ForeverXP/ForeverXP.toc`.
   For **WoW Forever** use the Forever game folder (the one the Battle.net app opens with
   "Show in Explorer" for WoW Forever). Classic folders (`_classic_era_` etc.) also work.
2. Restart the game and enable **ForeverXP** on the AddOns screen at character select.
3. If it shows as "out of date", tick **Load out of date AddOns**, or update the
   `## Interface:` line in `ForeverXP.toc` to your client's number
   (in-game: `/dump select(4, GetBuildInfo())`).

## Using it
- **Minimap button:** left-click shows/hides the guide, right-click opens options. Drag it around the minimap.
- **Guide window:** drag the header to move it, right-click the header for options.
  `<` / `>` change step, `-` collapses to just the current step.
- **Arrow:** drag to move, right-click to hide.
- **Footer:** level progress, rested XP, XP per hour and time to level.
- Hold **Shift** when talking to an NPC to stop auto accept/turn-in for that NPC.
  Quest rewards with a choice are never auto-picked.

## Commands
| Command | What it does |
|---|---|
| `/fxp` | Options and guide picker |
| `/fxp toggle` | Show/hide the guide window |
| `/fxp next` / `/fxp prev` | Skip forward / go back a step |
| `/fxp step 12` | Jump to step 12 |
| `/fxp list` / `/fxp load <name>` | List / load guides |
| `/fxp reset` | Restart the current guide |
| `/fxp xp` | Reset the XP/hour tracker |
| `/fxp forgive` | Clear the catch-up grind |
| `/fxp dungeons` | Dungeon quest window (dungeons near your level, quest status) |
| `/fxp questie` | Show Questie connection status |
| `/fxp arrow` | Toggle the waypoint arrow |
| `/fxp lock` | Lock/unlock frame dragging |
| `/fxp pos` | Print your map ID and coords (for writing guides) |
| `/fxp tier 45` / `/fxp tier` | Preview the Ascension theme at any level / back to your real level |

## Questie
ForeverXP reads Questie's quest database (Questie for WoW Forever + its QuestieDB) while you play.
Install Questie and ForeverXP picks it up automatically a few seconds after login. It uses it for:
- exact quest IDs, levels, required levels and XP for every quest in the guides,
- arrow positions for quest givers, turn-in NPCs and objectives (nearest spawn to you),
- skipping quests whose prerequisites you haven't done (no catch-up grind for those).

Your guide steps still decide the route; Questie fills in the data. Without Questie, ForeverXP
falls back to its built-in data. `/fxp questie` shows the connection status and what Questie
reports for your current step. If you run both, turn off auto accept in one of them.

## Updating quest data from Wowhead
ForeverXP ships with an empty `Data/QuestDB.lua`. Fill it with up-to-date WoW Forever quest data:

1. Install Python 3 from python.org (tick "Add Python to PATH" on Windows).
2. Double-click **Update Quest Data.bat** in the ForeverXP folder
   (Mac/Linux: `python3 Tools/fxp_wowhead.py`).
3. `/reload` in game.

The tool reads every quest in the guides, looks it up on Wowhead, and saves each quest's real ID,
level, required level, XP reward, quest giver, turn-in NPC and their map position. The addon then:
- uses real XP for catch-up grinding,
- points the arrow at the quest giver / turn-in NPC when a step has no coordinates,
- shows the NPC name and "(requires level N)" if you're too low,
- maps Classic quest IDs to Forever's IDs by name.

Options: `--site classic` (use Wowhead Classic), `--zone 40` (list every quest in a zone by
Wowhead zone ID, useful for writing guides), `--refresh` (re-download), `--debug` (save pages it
couldn't read to `Tools/debug/`). It waits between requests and caches results, so re-runs are quick.
Please keep it to personal use; Wowhead's terms limit automated access.

## Guides included (Alliance)
Northshire 1-6 → Elwynn Forest 6-10 → Westfall 10-14 → Loch Modan 14-16 → Redridge 16-19 → Westfall 19-20 →
Duskwood 20-24 → Wetlands 24-27 → Duskwood 27-30 → Stranglethorn 30-34 → Arathi 34-36 →
Dustwallow 36-38 → Badlands 38-40 (mount stop) → Stranglethorn 38-42 → Swamp of Sorrows 41-42 →
The Riverglades 42-44 (WoW Forever) → Tanaris 42-45 → Feralas 45-47 → Hinterlands 47-49 → Searing Gorge 48-50 →
Blasted Lands 50-51 → Burning Steppes 51-53 → Un'Goro 49-52 → Felwood 52-54 → Winterspring 54-56 →
Western Plaguelands 56-58 → Eastern Plaguelands 58-60

Side guides (load from /fxp): Ashenvale 27-30, Thousand Needles 30-32, Desolace 32-35,
Shen'dralas 40-45 (WoW Forever), Azshara 48-50, Silithus 55-58.

All of levels 1-60 are step-by-step: named quests, quest givers, coordinates, hard-quest warnings,
trainer stops, and optional steps for quests WoW Forever may not offer (they skip themselves with no XP debt).

## Changes in 2.8 - targeting buttons
- When a step needs an NPC or mobs, up to three "Talk to <NPC>" / "Target <mob>" buttons pop up under the
  guide window. Click one to target it. The names come from the quest (giver, turn-in, mobs to kill and the
  mobs that drop quest items), via Questie.
- A button glows green and you get a chat line when that NPC or mob is nearby (its nameplate or your mouseover).
- Mobs get a skull marker when you target them solo.
- An "FXP Target" macro is kept up to date in your character macros: drag it to an action bar to target
  whatever the current step needs. The first button can also be bound in Key Bindings > AddOns > ForeverXP.
- WoW doesn't let addons change targeting buttons in combat, so new buttons appear as soon as combat ends.
- Options > Targeting turns the buttons, the skull and the macro on or off.
- Ascension has a new look: a climb from a muddy cave at 1 through forests, mountains and clouds to a
  galaxy at 60.

## Changes in 2.7 - new themes
Pick a theme in Options (Display > Theme). Five new ones:
- Default UI - the game's own dialog border and background with gold titles.
- Blocky (block-building sandbox homage) - pixel-art stone with ores, a green XP-orb bar, orbs drifting up,
  and the step bursts into block fragments when you complete it. "LEVEL UP!" banner.
- Abyssal Dragon (dark-fantasy dragon homage) - black-violet scales, rising violet wisps; on danger steps the
  wisps surge and the darkness closes in.
- Frostbound (undead frost-king homage) - rune-carved black ice, falling snow, an icy glow under the title,
  "Whisper of the blade" tips and cold sayings.
- Ascension - grows with you. Every 5 levels the window climbs higher, 13 looks in all: Cave, Forest Floor,
  Old Woods, Twilight Hills, Heather Highland, Mountain Foothills, Mountain Lake, Snowy Peaks, Sea of Clouds,
  Starfield, First Aurora, Aurora and, at 60, Galactic Core (prismatic border and bar). From 30 on, sparkles
  appear and multiply each tier. Reaching a new tier shows an ASCENDED banner.
  Try any tier with `/fxp tier <level>`; `/fxp tier` goes back to your real level.
Also:
- The theme textures are new generated art (Fog Town, Spartan HUD, Ashen Bonfire, Imperial Gothic).
- Fix: Ashen's embers, Imperial's glow, Fog Town's static and fog, and Spartan's shield sweep were invisible.

## Changes in 2.6 - theme textures
Original, procedurally generated textures (Media/Themes, made by Tools/make_textures.py - rerun it to tweak them):
- Fog Town: weathered plaster with ash specks. On a danger step the window slowly "shifts" - the plaster peels
  away into rusted, stained steel plating behind a corroded diamond-mesh grate, with radio static - and shifts
  back once the danger has passed.
- Spartan HUD: dark visor glass with a glowing hexagonal energy grid and scanlines.
- Ashen Bonfire: charred, cracked flagstone with embers glowing through the cracks.
- Imperial Gothic: crimson lacquered plate with gold gothic-arch tracery, plus a swaying wax seal with
  parchment strips hanging off the window.
Textures tile at native size, so they stay crisp however tall the window grows.

## Changes in 2.5 - themes
Pick a theme in Options (Display > Theme). They're fan-made homages built only from WoW's own fonts and
textures - no game logos, characters or assets.
- Classic - the original look.
- Fog Town (survival-horror homage) - rust and grey, drifting fog, radio static that crackles whenever the
  current step has a danger warning, red bleed on the border.
- Spartan HUD (sci-fi shooter homage) - cyan visor lines, corner brackets, a scan line, a shield-recharge sweep
  across the progress bar and a CHECKPOINT caption when a step completes; WARNING / INTEL labels.
- Ashen Bonfire (dark-fantasy soulslike homage) - ember-lit stone border that flickers like a fire, rising embers,
  gothic serif titles, and huge screen-wide banners when you die or level up.
- Imperial Gothic (grimdark sci-fi homage) - crimson and gold, skull icon, +++ litany titles +++,
  "Thought for the day" tips, HERETIC THREAT warnings and OBJECTIVE PURGED on completion.

## Changes in 2.4
- WoW Forever content: The Riverglades 42-44 in the main route (Farholde Keep, boat from Powderfuse Port to
  Tanaris) and a Shen'dralas side guide. Their quest names aren't published yet, so these guides pace your
  levels and travel and Questie tracks the quests. Expanded zones (Wetlands, Desolace, Azshara) get their
  new quests from Questie automatically.
- New Classic zones in the route: Badlands, Swamp of Sorrows, Searing Gorge, Blasted Lands, Burning Steppes.
  They replace most of the old "grind to X" steps in the 38-42 and 48-53 range. Side guides: Thousand
  Needles, Desolace, Azshara, Silithus.
- Level 40 mount stop: shows the riding trainer and mount vendor for your race, displays your gold, and
  completes itself once you've learned riding. Gold-saving reminder from level 36.
- Class quests: pet quests (hunter, warlock), druid forms, paladin Redemption/Verigan's, warrior stances,
  rogue chains, shaman totems. They appear only for your class, at the right level, after the trainer stop,
  and skip themselves if WoW Forever renamed them.
- Dungeon quest guide: /fxp dungeons (or the Options button) lists dungeons near your level with every quest,
  where to get it, and whether you have it, finished it, or still need it - including Forever's new
  Excavation Site, City of Dalaran, The Drowned City and Krol'dok Stronghold.

## Changes in 2.3
- Race-specific starts. The addon picks the right one automatically from your race:
  - Human: Northshire 1-6 -> Elwynn Forest 6-10 -> Westfall
  - Dwarf / Gnome: Coldridge Valley 1-6 -> Dun Morogh 6-11 -> (tram to Stormwind) Westfall
  - Night Elf: Shadowglen 1-6 -> Teldrassil 6-11 -> Darkshore 11-16 -> Redridge Mountains
  - Skyborne: Zephras Isle 1-12 (level targets only - its quest data isn't public yet; Questie tracks the quests)
    -> Westfall. If it isn't picked automatically, use /fxp load "Zephras Isle 1-12".
- Elwynn Forest 6-10 is now Human-only, so other races aren't sent there.

## Changes in 2.2.1 (full-route audit)
- Fixed: Jasperlode Mine was never handed in (Elwynn).
- Fixed: Western Plaguelands cauldrons - each Target quest is now turned in at its cauldron and the matching
  "Return to Chillwind Camp" picked up there, so the chain no longer stalls.
- Fixed: Un'Goro's Gadgetzan steps pointed the arrow at Un'Goro coordinates; they now use Tanaris.
- Fixed: "To Winterspring!" was an accept step instead of a turn-in; Little Pamela now hands in before Pamela's Doll.
- Added missing hand-ins: Ogre Thieves, Young Crocolisk Skins, Krazek's Cookery, Screecher Spirits (with a Feralas
  objective step), The Apes of Un'Goro, Crystals of Power, Wildkin of Elune, The Wildlife Suffers Too.
- Removed ~25 quests the route picked up but never finished (dungeon preludes, Booty Bay-only turn-ins,
  dead-end chains). The quest log now peaks at 18 of 20 slots on a full run.

## Changes in 2.2
- Levels 42-60 step by step: Tanaris (Gadgetzan, Wastewander, Lost Rigger Cove, Steamwheedle Port),
  Feralas (Feathermoon, giants, Gordunni, Zukk'ash), The Hinterlands (Aerie Peak, Witherbark, Jintha'Alor),
  Un'Goro (Lar'korwi, Marshal's Refuge, A-Me 01, Ringo), Felwood (Emerald Sanctuary, Jaedenar, Talonbranch),
  Winterspring (Donova Snowden, Everlook, Winterfall), Western Plaguelands (the four cauldrons, Andorhal
  watchtowers) and Eastern Plaguelands (Tirion Fordring, Light's Hope, Darrowshire).
- Trainer stops at 46, 48, 52, 56, 58 and 60.

## Changes in 2.1
- Levels 30-42 step by step: Stranglethorn (Rebel Camp, Nesingwary tiers 1-3, Booty Bay chains),
  Arathi Highlands (Refuge Pointe, Northfold Manor, Witherbark), Dustwallow Marsh (Theramore,
  Swamplight Manor / Witch Hill, Shady Rest Inn)
- Built on the original Classic quests WoW Forever keeps; quests added in later expansions are
  skipped automatically via Questie

## Changes in 2.0
- Levels 20-30 step by step: Duskwood (two visits: Raven Hill, Abercrombie, Sven and Night Watch
  chains) and Wetlands (Menethil, Bluegill marsh, Whelgar's Excavation, Rethiel, War Banners)
- Quest names can mark their place in a chain that reuses one title: "The Night Watch#2"
- Quest names Questie doesn't know are skipped instead of stalling the guide

## Changes in 1.9
- Reads Questie's database at runtime (IDs, levels, XP, NPC and objective positions, prerequisites)
- Arrow points at quest objectives on kill/collect steps when Questie is installed
- Quests you can't get yet (missing prerequisite) are skipped without catch-up
- `/fxp questie` status command

## Changes in 1.8
- Levels 1-20 finished: Elwynn now covers Eastvale, the Rolf/Thomas chain and Westbrook; Westfall adds
  The Forgotten Heirloom and Militia part 2; Loch Modan and Redridge rebuilt in full, including the
  Price of Shoes run that unlocks Verner's quests; new Westfall 19-20 visit.
- Fixed steps that would have stalled: Bounty on Murlocs, Resupplying the Excavation, A Baying of Gnolls.
- WoW Forever quests added where confirmed (Alther's Mill, A Net Disaster, A Man About a Murloc).
- New `optional = true` steps: taken if offered, skipped without catch-up if not.
- Level-gated steps no longer add catch-up XP.
- Quest data for 55 quests.

## Changes in 1.7
- Data/QuestDB.lua now ships with real data for 30 quests (levels 1-15): XP (WoW Forever values where
  available), level requirements, quest givers and turn-in NPCs.
- Fixes: Bounty on Murlocs isn't available yet at Guard Thomas (removed from that step), the two
  different "Westfall Stew" quests no longer get confused, and better coordinates for the Echo Ridge
  kobolds, Jasperlode Mine, Salma Saldean, Redridge's sunken chest and gnoll camps.

## Changes in 1.6
- Quest data tool (Tools/fxp_wowhead.py + Update Quest Data.bat) and Data/QuestDB.lua support
- Fixed warnings on two Loch Modan / Redridge steps that didn't display

## Changes in 1.5
- Catch-up grinding: skipping a step (with `>`, a level-gated step, or "skip elite/group") adds the
  quest XP you missed as a catch-up target. The guide shows a "Catch-up" grind task and pauses
  until you've earned that XP from mobs. Quest turn-in XP doesn't count toward it.
- Debt is capped at one level's worth of XP and is cleared automatically if you out-level the guide.
- `/fxp forgive` clears it; turn the feature off in options.

## Changes in 1.4
- Hard-step warnings (orange) with an on-screen alert, plus strategy tips for 35 dangerous spots from 1-60
- Elite/group steps are tagged with a suggested group size
- New option: "Skip elite / group steps" for solo leveling
- New option: turn the on-screen warning alerts off

## Changes in 1.3
- Full Alliance 1-60 route (20 guides, chained)
- Trainer stops: `train` steps tick off when you close a class trainer window
- Guides can name quests by title instead of ID (`accept = "Raptor Mastery"`)
- Built-in map IDs for every Classic zone

## Changes in 1.2
- WoW Forever support (interface 16001)
- New guide: Elwynn Forest 6-10, chained after Northshire 1-6
- Quests are also matched by name, so guides keep working if a game version uses different quest IDs
- Zone maps are detected by name, so the arrow works on Classic, Retail-based clients and Forever
- New step option `ifLevel`

## Changes in 1.1
- Redesigned window: header bar, quest icons, objective checkmarks, guide progress bar, collapse mode, step-complete flash and sound
- XP/hour, rested XP and time-to-level footer
- Options window (separate auto accept / turn-in, sound, combat fade, scale, number of upcoming steps, lock, reset positions)
- Guide picker, minimap button
- New arrow texture with smooth turning, red→green colouring and an "arrived" checkmark
- TomTom waypoint is only re-created when the step changes
- Manual step changes are no longer instantly auto-skipped

## Writing guides
Add a file under `Guides/` and list it at the bottom of `ForeverXP.toc`.

```lua
local ADDON, ns = ...
ns.FXP:RegisterGuide("Westfall 10-14", {
  faction = "Alliance",         -- or "Horde" or nil
  races = nil,                  -- e.g. { "Human", "Dwarf" } (optional)
  minLevel = 10, maxLevel = 14, -- used for auto-picking a guide on login
  map = 1436,                   -- default uiMapID for coords
  next = "Duskwood 20-24",      -- guide to load when this one ends
  quests = { [12] = "The People's Militia" }, -- fallback names
  steps = {
    { accept = 12, npc = "Gryan Stoutmantle", coords = { 56.3, 47.5 } },
    { complete = { 12, 102 }, text = "Kill Defias Trappers", coords = { 52, 30 }, radius = 80 },
    { turnin = 12, coords = { 56.3, 47.5 } },
    { level = 12, text = "Grind murlocs on the coast" },
    { text = "Fly to Stormwind", coords = { 56.6, 52.6 } },
  },
})
```

**Step completes automatically when:**
- `accept` — every listed quest is in your log (or already done)
- `complete` — every listed quest's objectives are finished
- `turnin` — every listed quest is turned in
- `level` — you reach that level
- only `coords` — you get within `radius` yards (default 12)
- only `text` — never; click `>` or type `/fxp next`

Get quest IDs from Wowhead (the number in the URL, e.g. `wowhead.com/classic/quest=783`).
Chain quests that share a title: write `"The Night Watch#2"` for the second one.
Optional per-step keys: `optional = true`, `warn = "..."`, `tip = "..."`, `elite = true`, `group = 3`, `train = "Stormwind City"` (trainer stop), `ifLevel = 8` (skip the step if you're below level 8 when you reach it), `npc`, `zone`, `radius`, `noArrow`, and a third coords value to use a different map: `coords = { 40, 60, 1437 }`.

## Credits
Quest data checked against Warcraft Wiki (CC BY-SA 4.0), wowclassicdb and classicdb.
The Redridge route follows the order of the Warcraft Wiki "Redridge Mountains questing guide".
