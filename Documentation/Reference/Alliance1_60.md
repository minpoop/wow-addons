# Alliance 1–60 reference guide

Version 0.5.0-dev expands the successful 1–20 test framework to a level-60 goal:
**556 distinct quests, 1,668 quest phases, one waiting introduction and one
level-60 goal (1,670 steps)**. The same 97 initial quest IDs remain; 459 are added.
All selected records have no requiredClasses mask and allow common Alliance or
neutral reference eligibility. There are 83 explicitly optional quests; optional
encounters, escorts, item starters and selected special chains are excluded from
automatic goals. They can be kept explicitly. This is a shared leveling guide,
without class-specific training, dungeon/raid progression or Horde coverage.

The user said the 0.4 level-aware test appears to work in their client. This is
limited user-reported evidence for the framework, not a completed playthrough of
the expanded content. Status remains **reference-reviewed**, not live-verified.
No measured XP budget, optimal route, travel-time guarantee or guaranteed solo
completion is claimed. The actual Forever level cap and custom quest changes
still require observation.

## Chapters and selection

`/fxp leveling` or `/fxp 1-60` selects the expanded guide. Chapter summaries are
available through `/fxp leveling chapters`. Regions are alternatives that provide
suitable quests, not completion gates:

| Levels | Shared quest regions |
| --- | --- |
| 1–4 | Northshire |
| 5–9 | Elwynn |
| 10–14 | Westfall / Loch Modan |
| 15–19 | Westfall / Loch Modan / Redridge |
| 20–24 | Duskwood / Wetlands / Redridge |
| 25–29 | Duskwood / Wetlands / Hillsbrad |
| 30–34 | Stranglethorn / Hillsbrad / Arathi / Desolace / Shimmering Flats |
| 35–39 | Stranglethorn / Badlands / Dustwallow / Swamp of Sorrows |
| 40–44 | Tanaris / Feralas / Hinterlands |
| 45–49 | Tanaris / Feralas / Searing Gorge / Azshara / Blasted Lands |
| 50–54 | Un'Goro / Felwood / Burning Steppes / Western Plaguelands |
| 55–59 | Winterspring / Eastern Plaguelands / Silithus |

The actual player level determines a goal window [-3, +2], subject to minimum
levels and prerequisites. Observed native quest levels override reference levels.
Candidate score is 100 minus 10 per level of difference, plus 25 for a matching
current zone and 15 for observed active work. Current eligible active work and
eligible native focus take precedence over the score; explicit keep overrides
the level window. The old 1–20 test retains its smaller zone preference of 5.
No distances, traversability or travel times are inferred.

ALL prerequisites must each be turned in. ANY prerequisites need one positively
observed alternative, including history for alternatives outside the selected
pool. Only selected supported alternatives can be offered as work. Conflicting
exclusive introductions are blocked by positive active/completed observations.
Missing history stays unknown; needed old prerequisites may be offered as labeled
bridges. An accepted quest is positive evidence it was eligible, without marking
its unobserved prerequisites complete. Optional ancestors block automatic chains
until positively completed or explicitly kept.

Objective instructions are newly generated from selected factual entity/item
names. Where available, one spawn/object/exploration point provides a labeled
reference lead. It is not a sole drop source or a travel route. Required totals and
special actions come from the live quest log; reference objectives do not assert
live completion. Giver/recipient locations are provided independently for each
phase; unknown locations remain absent.

At observed level 60 the goal ends. An exhausted suitable pool below 60 displays
waiting rather than inventing completion or sending the player through every old
quest. Outleveled quests remain unfinished. Defer changes a planner preference,
not world state. Keep pins a quest until positive turn-in; Auto plan releases it.
Quest lists are paginated at 20 rows. There are no automatic quest interactions,
movement, purchases or abandonment.

The expanded pool also marks source-identified elite-only item drops and a
dungeon-related branch optional; this tightens one initial quest flag (ID 278)
without changing the retained 1–20 test. These authored exclusions are recorded
in optionalReason where newly added.

## Upgrade and persistence

Selecting the new guide imports matching 1–20 completed IDs, explicit overrides,
user deferrals and a retained quest pin once. It does not copy the old finished
flag or level-20 goal. If there is no 1–20 save, matching Elwynn completion can be
imported. The original saves remain separate, and selecting an already-existing
1–60 save never reimports over newer progress. `/fxp 1-20` opens the old test.
An existing old selection remains selected on login until `/fxp leveling` is used.
Campaign state stays version 1; bounded deferrals now allow 2,048 IDs, enough for
the entire pool. Unknown future state versions are retained and rejected safely.

## Source evidence

[Alliance1_60Facts.json](Alliance1_60Facts.json) contains curated facts from pinned
published Questie v10.10.3 commit
[`13a0430455d068e5889949a505bb02e0b92bf5fc`](https://github.com/Questie/Questie/tree/13a0430455d068e5889949a505bb02e0b92bf5fc).
Only selected quest facts, actor names and single reference points are included;
no third-party implementation, complete database, quest descriptions or guide
instructions are imported. Selection, chapter writing, instructions and planner
are original. Source database hashes:

| Reference file under Database/Classic | SHA-256 |
| --- | --- |
| classicQuestDB.lua | `a822801c772a8e11d3c6bb194960bd0fea86529ed9f63eb0d4e637fe54c9bf22` |
| classicNpcDB.lua | `e45ae223597c5c38d629617a50efca81e46a7c8d3588b33f6875f3d3fec1c4ed` |
| classicObjectDB.lua | `d08fbd8216757918330d9ff02bfc1b13f837f198e0aa62aa76260bb1bd9cd042` |
| classicItemDB.lua | `987d037b6df94d5b0b1dc326a1670581e3abb952736a4ae055fd9f161328b71c` |

The authoring-time parser read literal data only; downloaded Lua was not executed.
The repository retains selected facts and an offline deterministic generator:

```sh
python3 tools/build_leveling.py
python3 tools/build_leveling.py --check
```

## Validation and live follow-up

Offline checks load the complete TOC in Lua 5.1; validate all phases, references,
chapter coverage and save import; check eligible goals at each level 1–59; and
simulate acceptance, objectives, turn-in and accelerated levels through 60. Factual
checks cover every quest, class/race/minimum level, ALL/ANY/exclusive relationship,
giver/recipient point and reproducible generated content. Each later five-level
band contains at least 20 non-optional reference quests. Counts establish content
breadth, not XP sufficiency. Additional tests exercise external alternative history
through the native adapter, without completing unknown quests.

Next live check: install and run `/fxp leveling` on the existing character. Verify
progress imports, the new /60 goal, correct observed level, and available quests.
Complete a chain with multiple prerequisites, change levels and zones, defer/keep
work and relog. Test through each later chapter, recording missing quests, incorrect
reference leads, travel interruptions and XP gaps. Use Options to test each theme
at normal and compact size. No new API/content verification flag is enabled by
offline checks.
