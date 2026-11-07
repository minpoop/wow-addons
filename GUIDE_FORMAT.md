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
