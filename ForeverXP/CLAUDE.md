# ForeverXP: project notes for Claude Code

A free RestedXP-style leveling guide addon for **WoW Forever** (Blizzard's Classic+, launched Nov 4 2026, interface 16001).
Alliance only. Current version **2.10.0** (see `ForeverXP.toc` and the changelog in `README.md`).
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
    `fp`/`bind` are hard goals; `fly`/`hearth` only finish a step that has nothing else to check (no other
    goal and no coords). `SamePlace` matches names ignoring case and the ", Zone" suffix.
  - `Options.lua`: the options panel (two columns: left automation/display/guides, right targeting/travel),
    guide picker and theme picker.
  - `DungeonUI.lua`: the dungeon quest window (`/fxp dungeons`).
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
python3 Tools/dev/audit_parse.py && python3 Tools/dev/audit_check.py   # quest flow: loose quests, chain links, coords
python3 Tools/dev/audit_questlog.py | grep PEAK  # quest-log peak across the main route, must stay <= 20 (now 16)
python3 Tools/import_textures.py <png_dir> [name ...]  # convert generated images into Media/Themes TGAs
python3 Tools/make_textures.py                   # procedural-only textures (block_stone); --all would overwrite the generated art
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
- Roadmap agreed with the owner: phase 1 quest helpers (done), phase 2 travel (done), phase 3 map pins, phase 4 route quality from in-game reports, phase 5 talents /
  upgrades / group sync / hardcore mode, phase 6 Horde 1-60.
- There's no Horde route.
