# Horde 1–60 reference guide

Version 0.7 adds **821 quests, 2,463 quest phases, one introduction and one
level-60 goal: 2,465 steps across 12 chapters**. There are **138 optional quests**.
All selected records have no class requirement. This is a shared Classic Horde
reference pool, with no class-specific training, dungeon/raid route or measured
XP guarantee. Status is reference-reviewed; no Horde playthrough occurred here.

`/fxp leveling` selects the observed faction, or use `/fxp horde`. Existing
Alliance saves remain separate. Known opposite-faction selection is rejected.
Orc/Troll start in Durotar, Tauren in Mulgore and Undead in Tirisfal Glades.
Classic race-mask bits are Orc=2, Undead=16, Tauren=32, Troll=128; their union is
178. Source-restricted quests retain an `allowedRaces` accept-step gate using
client race tokens (Undead normalizes to Scourge). Unknown race cannot grant a
restricted introduction. Starting-region preference is limited to early levels;
regions are never completion gates. Custom races need actual server evidence.

| Levels | Main reference alternatives |
| --- | --- |
| 1–4 | Durotar / Mulgore / Tirisfal |
| 5–9 | Starting-region branches |
| 10–14 | Barrens / Silverpine |
| 15–19 | Barrens / Silverpine / Stonetalon / Ashenvale |
| 20–24 | Barrens / Hillsbrad / Ashenvale / Thousand Needles |
| 25–29 | Hillsbrad / Thousand Needles / Stonetalon |
| 30–34 | Arathi / Desolace / Stranglethorn / Shimmering Flats |
| 35–39 | Stranglethorn / Dustwallow / Desolace / Swamp of Sorrows |
| 40–44 | Feralas / Tanaris / Hinterlands |
| 45–49 | Tanaris / Feralas / Searing Gorge / Azshara |
| 50–54 | Un'Goro / Felwood / Burning Steppes / Western Plaguelands |
| 55–59 | Winterspring / Eastern Plaguelands / Silithus |

The existing level-aware planner preserves observed objectives, positive history,
ALL/ANY prerequisites, exclusive alternatives and manual defer/keep preferences.
Older prerequisites can bridge suitable goals without falsely completing unknown
steps. Optional encounters are never automatic goals. The level-60 goal requires
observed level 60; lack of suitable work below 60 displays waiting.

## Selection and provenance

[Horde1_60Facts.json](Horde1_60Facts.json) contains selected factual records from
Questie/Questie Classic database commit
[13a0430455d068e5889949a505bb02e0b92bf5fc](https://github.com/Questie/Questie/tree/13a0430455d068e5889949a505bb02e0b92bf5fc).
The four database SHA-256 values are identical to those recorded in
[Alliance1_60.md](Alliance1_60.md#source-evidence) and are embedded in this facts file.
Downloaded Lua literals were parsed as data, never executed. No complete database,
third-party implementation, quest descriptions or existing guide prose is bundled.
Selection, instructions, chapter text and planner are original.

The pool selects class-independent, Horde-compatible outdoor records and usable
city prerequisites, plus suitable neutral branches. Profession/reputation/spell
requirements, repeatables and raid-flagged records are excluded. Known elites,
elite-only objective/drop sources, escort/party flags, item starters and selected
special neutral chains remain optional. Source successor metadata helps suppress
superseded introductions only with positive observations. ALL and ANY relations
are preserved; unsupported external prerequisites remain history requirements
rather than invented tasks. One reference actor/object point is a lead, not a
complete spawn survey or a promise of access.

Regenerate offline:

```sh
python3 tools/build_leveling.py --faction Horde
python3 tools/build_leveling.py --faction Horde --check
```

## Validation still needed

Offline checks cover all 821 records/phases/locations, race masks, deterministic
generation, proper starters for all four races, choices at levels 1–59, faction
selection, positive phases and synthetic progression to 60. Each later level band
has at least ten non-optional reference choices. Counts do not establish XP supply.

In game, test all four starts, later prerequisites and neutral/faction eligibility,
quest/objective availability, race tokens, locations, travel and XP gaps. Preserve
observed facts when content differs; do not promote the guide on mocked results.
See [the live checklist](../LIVE_TEST_CHECKLIST.md).
