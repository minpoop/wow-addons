# Guide format

Guide tables are data only: no functions, userdata, metatables, nonfinite numbers,
or cyclic tables. Coordinates are normalized 0–1, always with an explicit zone.
The following is a **synthetic authoring example**, not playable server content:

```lua
local fixture = {
  id = "synthetic-example", title = "Example only",
  faction = "Alliance", minLevel = 1, maxLevel = 2,
  verification = "fixture", source = "offline synthetic example",
  steps = {
    { id = "intro", type = "MANUAL_INSTRUCTION", text = "Example instruction" },
    { id = "level", type = "REACH_LEVEL", level = 2,
      text = "Example level condition", prerequisites = {"intro"}, optional = true },
  },
}
-- StepValidator:Guide(fixture, false) validates authoring structure.
-- GuideEngine:RegisterGuide(fixture) refuses it as production content.
```

Production registration requires `verification="live-verified"`, a nonempty
`source`, unique guide and step IDs, a dense ordered `steps` array, text, valid
step types and backward-only prerequisite IDs. This declaration is a content
author's assertion, not automated proof of server validity. Attach actual source
and verification evidence. Do not label fixtures live-verified outside tests.

`RegisterReferenceGuide` is a distinct authoring path: it requires
`verification="reference-reviewed"`, a nonempty source and valid structure. Its
guides are selectable explicitly but excluded from automatic recommendations.
They do not count as live-verified coverage. Reference waypoints carry their own
verification marker and render an in-game-check reminder. The Elwynn guide uses
this path; it is not registered through a fabricated live-verification claim.

Prerequisites must themselves be a dense array, without duplicate IDs. Metadata
types, level ranges, optional flags and all coordinates are checked. Travel steps
require waypoints; interaction/flight steps require NPC IDs; kill steps require an
NPC ID and count; use-item steps require item IDs; training requires profession
and skill. Hearth instructions still require manual or explicit observed evidence.

Types: ACCEPT_QUEST, COMPLETE_QUEST, TURN_IN_QUEST, KILL_MOBS, COLLECT_ITEMS,
TRAVEL_TO, TALK_TO_NPC, TRAIN_SKILL, LEARN_FLIGHT_PATH, USE_ITEM, SET_HEARTHSTONE,
USE_HEARTHSTONE, REACH_LEVEL, REACH_PROFESSION_SKILL, MANUAL_INSTRUCTION.

Quest steps require positive integer `questId`. Collection requires `itemId` and
`count`. Level requires `level`. Profession requires `profession` and `skill`.
Optional fields include `waypoint={zone=...,x=...,y=...}`, `prerequisites`, and
`optional`. Interaction types require explicit normalized observation or manual
confirmation; their type alone does not enable unsupported automatic tracking.

The engine follows authored order. Recommendations filter faction/race/class and
level, favor matching zone and race/class specificity, and break ties by guide ID.
It does not synthesize routes from an incomplete quest database. Completion is
saved by step ID. Removed current IDs cause an error with progress preserved.
Back enters review mode; Next explicitly confirms and resumes. Recovery produces
only consecutive evidence-supported suggestions, without mutating progress.

Before release, verify quest existence, prerequisites, coordinates, objectives,
travel connections and turn-ins on the actual server. Schema checks cannot detect
a syntactically valid but nonexistent quest ID. See the coverage report.

## Data-only authoring validation

An authored guide can set `autoResume=true` (boolean) to opt into evidence-based
cursor catch-up. Elwynn uses it. Known acceptance, completion, history and level
facts reconcile their own steps; active quests determine the current objective or
turn-in. Unknown earlier steps are not marked done. Recovery retains source
verification labels and does not certify untested route content. The existing
`GuideEngine:Recovery` method still returns suggestions without applying them;
automatic cursor matching is implemented separately by RecoveryEngine.

Use JSON for external content checks; files are parsed as data and never executed:

```sh
/workspace/.foreverxp-tools/bin/python tools/validate_content.py guide guide.json
/workspace/.foreverxp-tools/bin/python tools/validate_content.py guide guide.json --production --known-quests observed-quest-ids.json
/workspace/.foreverxp-tools/bin/python tools/validate_content.py profession profession.json
/workspace/.foreverxp-tools/bin/python tools/validate_content.py route route.json
```

The known-quests file is a separately verified JSON array of positive quest IDs.
Missing IDs fail validation. This checks against the supplied catalog, not the
server remotely. Duplicate JSON keys, nulls, nonfinite numbers, executable input,
overly deep data and files over 2 MB are rejected. Schema-valid production labels
remain author assertions; the command cannot certify live observations. Validated
data must be registered explicitly through the addon modules; the client does not
read external files or execute arbitrary imported Lua.

## Level-aware campaign guides

The Alliance playtest uses `campaign={targetLevel=20,maxQuestLag=3,maxQuestLead=2}`.
These integer limits select goal quest levels relative to the observed player.
Campaigns need one matching REACH_LEVEL step and a nonempty quest pool. Each
quest has exactly one ACCEPT_QUEST, COMPLETE_QUEST and TURN_IN_QUEST, with matching
positive `questLevel`, `minLevel` and nonempty `questTitle`. Accept prerequisites
reference earlier turn-in step IDs. Each phase retains its own positive evidence;
source order is not a requirement to finish every quest. Lower-level prerequisite
bridges can be selected to unlock eligible goals. Optional quests are excluded
unless explicitly kept. This pool format has no travel-time or XP guarantee.

Campaign Next means defer, Back cycles alternatives, and Auto plan clears an
explicit pin. Deferral changes planner preference only. It never confirms a quest
phase or abandons a quest. The separate campaign guide imports matching old
Elwynn completions/overrides once and retains the old route save.

## Expanded campaign metadata (0.5)

A campaign can add `zonePreference=25` (integer 0–100) and a dense `chapters`
array of `{minLevel,maxLevel,title,text}`. Chapter ranges must cover every level
from 1 through targetLevel-1 contiguously. The target must be at least 2.
Accept steps can add dense positive-ID arrays `prerequisiteQuestsAny` (one
completed quest required) and `exclusiveQuests` (positively observed conflicts).
These use quest IDs; the existing prerequisites field still uses backward step IDs
and means ALL. Selected alternative quests must precede the dependent quest in
source order. Alternatives outside the pool can satisfy positive history, but
cannot be invented as guide work. Duplicate/self references and sparse arrays fail
validation. See the generated Levels1_60.lua and curated facts for concrete data.
