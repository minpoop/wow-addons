# Alliance 1–20 reference playtest

Version 0.4.0-dev introduces `/fxp leveling`: 97 distinct quests, 291 quest phases,
an introductory waiting step and one level-20 goal (293 steps). This extends the
same 34 Elwynn quests with 21 Westfall, 16 Redridge and 26 Loch Modan quest records,
including associated deliveries. Overlapping Elwynn quests are not additional
unique content. No class-specific quests or training are included.

Status: **reference-reviewed; no end-to-end Forever playthrough**. User reports
confirm addon loading, journal progression and Elwynn catch-up. They also report
outleveling the old area route. Those reports motivate this planner but do not
verify the new pool, its XP yield, geography or difficulty on Forever.

## Selection policy

Your observed level drives selection from the curated pool. A goal must meet its
reference minimum level and be within [-3, +2] quest levels of you. An observed
native quest level replaces the reference value when available. Candidate ranking
favors nearby levels, then observed active work and matching zone; ties use the
authored pool order. No travel-time optimization is claimed. Eligibility is
recomputed after level and quest changes, so a tracked low-level quest cannot
hold you in an exhausted area. Necessary lower-level chain prerequisites are
allowed and labeled with the higher-level goal they unlock.

Completion uses positive quest facts only. Old, missing or deferred quests never
become automatically turned in or abandoned. The bar measures levels 1–20, not
completion of all 97 quests. The actual observed level must reach 20; an exhausted
pool at a lower level produces a waiting message. There is no verified XP budget
or promise that these quests alone cover every character's 1–20 journey.

Other quests pins a suitable alternative; Defer quest records a planner preference;
Auto plan clears a pin. `/fxp leveling quests` lists IDs and `/fxp leveling keep ID`
can keep an older or optional quest. A pin releases on positive turn-in. User
deferrals persist until explicitly restored; Auto plan does not erase them.
The initial campaign selection imports matching completed IDs and explicit
Elwynn overrides once. Original Elwynn saves remain separate. Saves are versioned
and unknown campaign records are retained rather than overwritten.

Eight reference quests are excluded from automatic selection: IDs 59, 88, 176,
104, 155, 255, 271 and 531 (selected deliveries, escort and group encounters).
They can be kept explicitly. Dungeon finales and class quests are outside scope.
The common reference pool has no requiredClasses masks. Classic race restrictions
do not establish availability for custom Forever races.

## Facts and provenance

[Alliance1_20Facts.json](Alliance1_20Facts.json) records the selected quest IDs,
titles, levels, minimum levels, prerequisite IDs, actor identities and available
reference actor coordinates. The original source minimum of zero is preserved
as referenceMinimumLevel and normalized to level 1 for operational eligibility.
Only facts were curated; guide ordering, planner and instructions are original.
Quest descriptions, third-party guide text and implementation are not bundled.

The published Questie v10.10.3 reference commit is
[`13a0430455d068e5889949a505bb02e0b92bf5fc`](https://github.com/Questie/Questie/tree/13a0430455d068e5889949a505bb02e0b92bf5fc).
The three source database files and their SHA-256 hashes are the same as documented
in [Elwynn.md](Elwynn.md#sources). Only selected facts are included in this repo.
Reference coordinates are normalized from Classic area data and labeled in the
UI. Missing actor coordinates remain absent. Map IDs, custom server differences,
travel connections and quest XP require live validation.

## Validation

Offline tests cross-check all 97 selected facts, phase metadata, prerequisites and
available actor coordinates; simulate eligible choices at levels 1–19; exercise
accelerated level jumps, observed level overrides, history, older chain bridges,
optional exclusions, defer/keep, relog preferences, old-save import and target 20.
A synthetic progression test accepts/completes/turns in quests while level changes.
It is a logic regression test, not a measured leveling run.

Live check: select `/fxp leveling` on the character that outleveled Elwynn. Confirm
the displayed character and quest levels, suitable quest availability, prerequisite
access and UI controls. Progress a quest and level up; verify a now-old target
falls away without false completion. Keep an older quest, turn it in, and verify
automatic selection resumes. Relog and check preferences. Repeat across levels
1–20 and record XP gaps and travel issues before claiming full route coverage.

## Continued in 0.5

The retained test is now selected explicitly with `/fxp 1-20`. `/fxp leveling`
selects the expanded [Alliance 1–60 guide](Alliance1_60.md) and imports matching
test progress/preferences once. The old test save and content remain available.
