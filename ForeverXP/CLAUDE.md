# ForeverXP: project notes for Claude Code

A free RestedXP-style leveling guide addon for **WoW Forever** (Blizzard's Classic+, launched Nov 4 2026, interface 16001).
Alliance and Horde. Current version **2.15.1** (see `ForeverXP.toc` and the changelog in `README.md`).
Moved here from a claude.ai chat on 2026-11-09. This file is the handoff.

## Ground rules from the owner
- The owner (the user) decides on direction, and Claude does the research and writing itself. Don't ask for guidance on routine guide content.
- Write original routes from public quest data. **Don't copy RestedXP's paid guide content.**
- Players **will have Questie installed**, so the addon reads quest data from Questie.
- Themes are fan homages. **Don't use game logos, character art, game assets or game names in-game.**
  They use WoW's own fonts and textures, plus original textures in `Media/Themes`.

## Layout (load order is set in ForeverXP.toc)
- `Compat.lua`: wraps API differences (C_QuestLog vs the old API, gossip, map and world positions).
- `Data/QuestDB.lua`: a small static quest database, used as a fallback when Questie isn't available.
- `Data/ClassQuests.lua`: class quest blocks. These are injected into every guide whose level range covers them, right after that guide's first `train` step.
- `Data/Dungeons.lua`: data for the dungeon quest window.
- `Core.lua`: the engine.
  - Guide registry: `RegisterGuide` and `InjectClassSteps`.
  - Quest resolution: `Resolve`. A `"Name#k"` string means the k-th quest in a chain that shares one name.
  - Step logic: `IsStepDone`, `Unavailable` and `PickGuide`. Side guides are never picked automatically.
  - Catch-up XP debt, automation and the slash commands.
- `Questie.lua`: Questie bridge. Handles QuestieDB/ZoneDB/QuestXP queries, the name index, spawn positions and prerequisite and faction checks.
- Window and display files:
  - `UI.lua`: the guide window.
  - `Themes.lua`: the ten themes, their effects, tiled textures and banners.
    - Classic, Default UI (the game's own dialog textures), Fog Town, Spartan HUD, Ashen Bonfire, Imperial Gothic,
      Blocky, Abyssal Dragon, Frostbound and Ascension.
    - Ascension has `tiers` (one per 5 levels, `floor(level / 5) + 1`, 13 in all). `Resolve` layers the current
      tier over the base theme; a level-up into a new tier re-skins the window and shows an ASCENDED banner.
      `/fxp tier <level>` previews any level, `/fxp tier` goes back to live.
    - Effect layers are made with `Tex`, which keeps the colour opaque and animates the region alpha
      (a colour alpha of 0 multiplied with `SetAlpha` would never show).
  - `Arrow.lua`: the waypoint arrow, with TomTom support.
  - `Targeting.lua`: up to three secure "Target <name>" macro buttons under the guide window for the step's
    NPCs/mobs (`StepTargets`: authored `target`, turn-in NPC, quest giver, then Questie objective mobs via
    `Questie:ObjectiveNames`), a nameplate/mouseover "nearby" glow and chat ping, and the "FXP Target"
    character macro (max 255 chars). Secure frames: attributes, position and visibility only change out of
    combat (`targetsDirty` is replayed on PLAYER_REGEN_ENABLED); they're placed by absolute coordinates, never
    anchored to the guide window, so the guide window never becomes protected. `Bindings.xml` binds button 1.
    The on-screen pop-up (`ForeverXPTargetPop`, `RefreshTargetPop`) shows while a target is nearby (or always,
    `targetPopAlways`); its macro lists nearby names last so `/targetexact` lands on one in sight. It can only
    appear or change out of combat.
  - `Helpers.lua`: phase 1 quest helpers. Quest item buttons (`StepItems`: authored `useItem`, then
    `Questie:QuestItems` for the step's quests, kept only if carried and usable; secure `type=item` buttons,
    out-of-combat changes only), auto-train on `train` steps (`AutoTrain`, bottom-up, gold reserve, Shift
    skips, not at profession trainers) and quest cleanup (`OrphanQuests` / `/fxp cleanup`, confirm popup,
    finished quests kept).
  - `Travel.lua`: phase 2 travel. `fly` (auto-pick at the flight master via TAXIMAP_OPENED; gossip opens the
    map), `bind` (innkeeper gossip + CONFIRM_BINDER), `hearth` (Hearthstone 6948 via the item bar), `fp`
    (known flights learned from every flight map and ERR_NEWTAXIPATH), the flight timer (route times in the
    account-wide `ForeverXPDB.flightTimes`) and zone reminders from `Data/FlightPoints.lua`. In `IsStepDone`,
    `fp`/`bind` are goals but never walls: an unmet one still finishes the step once you've arrived and then
    left the area (`MovedOn`: 3x radius, min 60 yd) or done the next step (`NextStepDone`); `fly`/`hearth` only
    finish a step that has nothing else to check (no other goal and no coords). `SamePlace` matches names ignoring case and the ", Zone" suffix.
  - `Pins.lua`: phase 3 map pins. `PinSteps` (current + `mapPinsAhead` unfinished steps with `StepCoords`,
    cached 0.5 s, cleared by `Update`), world-map pins on `WorldMapFrame:GetCanvas()` (scale 1/canvas zoom,
    offsets divided by that scale; other maps via `C_Map.GetMapPosFromWorldPos`), minimap pins via
    `MinimapOffset` (yards per zoom, indoor table, rotate CVar, current step clamps to the rim). Pin art is
    `Media/Pin.tga` from `make_textures.py map_pin`, tinted per pin.
  - `Feedback.lua`: phase 4 route feedback, all in account-wide `ForeverXPDB`: `reports` (`/fxp report`, note
    icon on the header), `runLog` (per-step seconds, deaths, how it ended; capped at 3000; `LogStepChange` from
    `Update`, `manualStep` set by `SetStep`), `routeCheck` (`/fxp check`: `CheckGuide` per guide against
    Questie, 3 guides per tick) and `/fxp export`. Steps carry `src` = position in the guide file (class
    quest steps are injected at runtime and have none), so reports map back to file lines.
  - Phase 5 (`Talents.lua`, `Gear.lua`, `Party.lua`, `Hardcore.lua`, `Data/Talents.lua`):
    - Talents: one 51-point leveling build per class in `Data/Talents.lua` (original, Classic talent names).
      `NextTalent` matches names against the live tree (`GetTalentInfo`), respects tiers (5 points each) and
      `GetTalentPrereqs`, skips what's missing and reports it (`/fxp talents`, also run by `/fxp check`, saved
      as `ForeverXPDB.talentIssues`). Auto-learn takes one point per CHARACTER_POINTS_CHANGED.
    - Gear: per-class stat weights (hybrids switch to caster weights by talent spend), `UpgradeFor(link)` vs the
      worst equipped item in the slot(s), armor class gate by item class/subclass IDs; tooltip line via
      OnTooltipSetItem; `BestReward` names the best quest choice (never auto-picks).
    - Party: addon prefix `FXPSYNC`, "S/J\tguide\tstep" messages, `PartyLine` in the window, follow-leader and
      `/fxp sync`. Parse with a pattern, not `strsplit and strsplit(...)` (and-expressions keep one value).
    - Hardcore: `Questie:ObjectiveMobs` levels/rank -> `DangerLine` (3+ levels, or 2+ in hardcore; elites =
      rank 1-3), `SetHardcore` forces skipGroup and restores it, once-per-fight low-health raid warning.
    - The guide window shows talent/danger/party lines above the step, plus the Learn button.
  - `Options.lua`: the options panel (two columns: left automation/display/guides, right targeting/travel),
    guide picker and theme picker.
  - `DungeonUI.lua`: the dungeon quest window (`/fxp dungeons`).
- Horde guides (`Guides/Horde_Starts.lua`, `Horde_10-30.lua`, `Horde_30-60.lua`) are GENERATED by
  `Tools/dev/route_gen.lua` from `Tools/dev/horde_plan.lua` (zone plan: area, quest-zone `qareas`, level window,
  hub fp/bind, extra areas) and WoW Forever's QuestieDB data: faction/race filter, friendly giver and turn-in in
  the zone or a city, no elites/dungeons/class/profession/repeatable quests, item-started quests when the item
  drops in the zone, prerequisite-ordered rounds (accept by giver, objectives nearest-first, hand-ins by NPC),
  log cap 15, expected-level gating with "grind to N" steps. It prints quest-XP coverage per zone. Change the
  plan or generator and regenerate rather than hand-editing the output.
- Guide files:
  - `Guides/Human_Northshire.lua` and `Guides/Elwynn_6-10.lua`: the Human start.
  - `Guides/Alliance_Starts.lua`: Dwarf/Gnome (Coldridge, Dun Morogh), Night Elf (Shadowglen, Teldrassil, Darkshore) and Skyborne (Zephras Isle, a placeholder).
  - `Guides/Alliance_10-30.lua`, `Guides/Alliance_30-60.lua`: the main route.
  - `Guides/Alliance_Extra.lua`:
    - Main-route zones: Badlands (with the level 40 mount stop), Swamp of Sorrows, The Riverglades (a Forever zone, hub-based), Searing Gorge, Blasted Lands and Burning Steppes.
    - Side guides: Thousand Needles, Desolace, Shen'dralas, Azshara and Silithus.
- `Media/Arrow.tga` and `Media/Themes/*.tga`: 32-bit power-of-two TGAs.
  - Most theme textures are generated art: prompts in `Tools/texture_prompts.txt`, made with gpt-image-bridge
    (Codex CLI logged in with the owner's ChatGPT account, no API key), converted by `Tools/import_textures.py`
    (tiling, 256x256, brightness and contrast tuned for readable text, white to alpha for the grate and seal).
  - `block_stone` (Blocky) is pixel art from `Tools/make_textures.py`; generated images blur pixel art.
- `Tools/fxp_wowhead.py`: a personal-use Wowhead scraper that writes `Data/QuestDB.lua`.

## Step format (guide files)
```lua
{ accept = "Quest Name" | { ... } | 1234, complete = ..., turnin = ...,
  optional = true,        -- only tracked if the player has the quest; otherwise skipped, no XP debt
  level = 40, train = "Ironforge", mount = true, anyQuest = { ... },  -- other step kinds
  class = { "HUNTER" }, races = { "Dwarf" }, ifLevel = 10,            -- filters (skipped = no XP debt)
  elite = true, group = 3, coords = { x, y }, zone = "Tanaris", radius = 20, npc = "...",
  target = "Mob Name" | { ... },  -- extra names for the target buttons (rare spawns, named mobs Questie lacks)
  useItem = 1234 | { ... },       -- quest items to offer as buttons (when Questie doesn't link them)
  fly = "Stormwind", fp = "Sentinel Hill", bind = "Lakeshire", hearth = "Theramore",  -- travel (Travel.lua)
  text = "...", warn = "...", tip = "..." }
```
- A step with only text and no coords waits for a manual Next.
- Quests that Questie doesn't know, or whose prerequisite isn't met, are skipped automatically, so uncertain quests should be marked `optional = true`.

## Checks to run after any change
Run these from the addon folder.
```bash
luac -p $(find . -name '*.lua')                 # syntax (or: python3 Tools/dev/lua_run.py check $(find . -name '*.lua'), Linux liblua5.4 only)
lua -e "arg_root='.'" Tools/dev/harness.lua      # runs the whole addon against stubbed WoW API, expect "0 failures"
lua -e "arg_root='.'" Tools/dev/smoke.lua        # every command/theme/step/event/handler for both factions; expect 8 stub-artifact errors
python3 Tools/dev/audit_parse.py && python3 Tools/dev/audit_check.py   # quest flow: loose quests, chain links, coords
python3 Tools/dev/audit_questlog.py | grep PEAK  # quest-log peak across the main route, must stay <= 20 (now 11)
python3 Tools/import_textures.py <png_dir> [name ...]  # convert generated images into Media/Themes TGAs
python3 Tools/read_reports.py <ForeverXP.lua> [out.md]  # owner's saved variables -> fix list with guide file:line
# offline /fxp check against WoW Forever's real data (git clone https://github.com/Questie/QuestieDB somewhere first):
lua -e "arg_root='.'; qdb_root='/path/to/QuestieDB'" Tools/dev/forever_check.lua   # both factions; expect "0 findings"
lua -e "arg_root='.'; qdb_root='/path/to/QuestieDB'; plan_file='Tools/dev/horde_plan.lua'" Tools/dev/route_gen.lua  # regenerate Horde guides
python3 Tools/dev/audit_questlog.py "Valley of Trials 1-6" | grep PEAK   # Horde quest-log peak (15)
python3 Tools/make_textures.py                   # procedural-only textures (block_stone, map pin); --all would overwrite the generated art
```

## Known limits and open work
- Nothing has been tested in the live game yet. The first priority is the owner's in-game feedback.
- **WoW Forever's new zones** have no published quest names yet.
  - The Riverglades and Shen'dralas guides only pace levels and travel, and Questie tracks the quests.
  - Zephras Isle (the Skyborne start) is levels and trainer stops only.
  - The race token for Skyborne is a guess: `Skyborne` / `ShenDorei` / `Shendorei`.
  - Once quest data appears (Wowhead, Questie updates), rewrite these as named step-by-step guides.
- Only four of Forever's nine new dungeons are listed: Excavation Site, City of Dalaran, Drowned City and Krol'dok. Their quests are unknown.
- Some class quest names are uncertain (Dwarf Shaman totems are new in Forever, plus the rogue and warlock 30 chains). If a name is wrong, the step skips itself.
- The 42-60 quest names and coordinates come from Classic data and haven't been checked against Forever. That's why most steps there are optional.
- Themes haven't been seen in the live game yet: check the new textures, the effects (embers, glow, static and fog
  were invisible before the `Tex` fix in 2.7), the MONOCHROME fonts on Blocky and the Ascension tier-up banner.
- Targeting buttons are untested in the live game: check click-to-target, the key binding, the skull
  (solo only), the FXP Target macro creation, and that nothing errors when the step changes in combat.
- Phase 1 helpers are untested in the live game: item buttons (use, cooldown, count, key binding), auto-train
  at a real class trainer (filter, purchase order, reserve) and the cleanup popup's abandon.
- Phase 2 travel is untested in the live game: gossip option icons (taxi 132057, binder 132052), auto-flying,
  CONFIRM_BINDER confirm, the flight timer start (PLAYER_CONTROL_LOST + UnitOnTaxi) and the reminders.
  `fp` steps only learn a flight path you already had once you open a flight map there.
- Phase 3 pins are untested in the live game: world map canvas scaling, the continent-map conversion, the
  minimap yard table (indoors especially) and the rotating minimap.
- Phase 4 is the feedback loop: ask the owner for their `WTF/Account/<account>/SavedVariables/ForeverXP.lua`
  after a play session, run `Tools/read_reports.py` on it and fix the route from that. Settled in 2.13.1 with the
  Forever data: Seeking Wisdom handed in at Bishop Farthing (Stormwind, end of Duskwood 27-30); Legend of Stalvan
  #2, The Missing Diplomat (starts with Thomas in Stormwind), Green Hills of Stranglethorn and Mor'Ladim removed;
  Un'Goro relabelled 53-54 (its quests are 51-55), Felwood 54-55, Winterspring 55-56. Audit: no quest accepted
  and never turned in; quest-log peak 11.
- First owner route check (v2.12.0) ran before Questie's name index finished, so ~700 "Questie doesn't know"
  findings were false; numeric-ID quests were checked properly. Fixed: CheckRoute waits for `indexDone`
  (or `indexFailed`, then skips text-named quests), and the result records `nameIndex`. Real findings fixed in
  Westfall (stew delivery 36 before 38; Defias Brotherhood 65 needs 14). Ask the owner to rerun `/fxp check`.
- Second owner file (2.12.x): still the old 2.12.0 check (not rerun); run log showed ~5 min stuck on Wetlands
  step 1 (fp + bind Menethil) then manual skipping. Fixed in 2.12.2 with MovedOn/NextStepDone.
  `ForeverXPDB.lastVersion` now records the installed build at login.
- Third owner file (2.12.2 check): `nameIndex = unavailable`. Cause: current Questie (checked against
  github.com/Questie/Questie, Nov 2026) sets `QuestieDB.QuestPointers` only in `QuestieDB.Initialize`, late in
  its startup, from the global `LibQuestieDB.Quest.GetAllIds(true)`; we gave up at once. `Questie:AllQuestIds`
  now falls back to LibQuestieDB and `BuildNameIndex` retries (2 s x 90). Prerequisite check now means
  handed in (pre1 = preQuestSingle) and matches by name. Real finding fixed: Wetlands Fire Taboo needs
  Tramping Paws handed in first (route reordered).
- Fourth owner file (2.12.3, name index complete): 38 real findings. Built `Tools/dev/forever_check.lua`, which
  runs the addon's own CheckRoute offline against QuestieDB's `data/Forever/*` (matches the in-game run except
  live-only Questie corrections, e.g. Report to Captain Stoutfist needing The Algaz Gauntlet). Fixed every
  finding in 2.13.0 (Horde quests removed from Arathi/Feralas/Hinterlands, Dustwallow rebuilt from real quests,
  prerequisite orders in Coldridge/Wetlands/Arathi, misspellings). Offline check: 0 findings. When a guide
  references a quest, look it up in the Forever data first (name, races, pre1, start/finish NPC and spawns).
- Phase 5 is untested in the live game: talent names in WoW Forever (watch `/fxp talents`), LearnTalent from
  an addon, GetItemStats keys and the tooltip hook, addon messages in a real party, UNIT_HEALTH alerts.
- Roadmap agreed with the owner: phase 1 quest helpers (done), phase 2 travel (done), phase 3 map pins (done),
  phase 5 talents / upgrades / group sync / hardcore (done in 2.14.0),
  phase 4 route feedback tools (done; fixes ongoing from reports), phase 6 Horde 1-60 (done in 2.15.0).
- Horde route (2.15.0) is generated and data-checked but unplayed: quest-XP coverage is ~30-75% below 30 and
  ~15-40% above (Horde 40s are quest-light), so grind steps carry the rest. Hand-tuning ideas: second visits
  (Tanaris/Feralas/Ashenvale), dungeon quests, warnings/tips text. Horde has no class quest blocks yet
  (Data/ClassQuests.lua is Alliance; blocks can carry `faction = "Horde"`).
