# Focused 1–20 route planning — 0.8

Version 0.8 adds an original Elwynn → Westfall → Redridge itinerary with **53
shared quests, 159 quest phases and 98 ordered phase batches**. It addresses a
specific weakness in the earlier planner: accepting one quest, working it and
returning before collecting other nearby tasks. The guide can now collect a
pickup batch, work its compatible field objectives and combine the return.
Goldshire's Fargodeep, candles and gold-dust quests are a concrete example.

This is a planned Classic reference segment, not a measured Forever 1–20 XP
budget or a completed speedrun. It does not reuse RestedXP routes or text. Other
starting regions, Horde and levels 20+ retain the existing level-aware pool.
The reference quest facts, hazards, source hashes and live-validation limits
remain unchanged.

## Use it

The default automatic mode applies while an Alliance campaign character below
20 is in Elwynn, Westfall or Redridge. It is class-independent common content;
this is the Human-region itinerary, not an authored start for every race.
Outside those regions or after level 19, automatic selection uses the normal
campaign pool again. Selecting the full 1–60 guide still has a level-60 goal.

Right-click → **Route plan & run report** provides the controls:

- `/fxp route elwynn` explicitly selects this plan and the existing Alliance
  1–60 campaign, preserving its progression. The plan segment covers 1–19;
  the ordinary campaign continues from level 20.
- `/fxp route auto` uses regional batches where an applicable plan exists.
- `/fxp route off` restores free quest-pool selection.
- `/fxp leveling auto` releases a manually kept quest and resumes planning.

A manually kept quest always takes precedence. A pickup batch can take priority
over the native tracked quest; within a field batch, observed activity/tracking
can choose another compatible task. The card names the batch and lists other
ready tasks. No acceptance, movement, combat, turn-in or abandonment is automated.

## Eligibility and recovery

Candidates still obey observed level, minimum level, prerequisites, race gates,
exclusive alternatives, optional exclusions and user deferrals. Field work uses
the existing [-3,+2] quest-level window. Necessary old prerequisites remain
explicit bridges. Fresh native quest levels override the reference values.

Selected preparation batches can suggest an **early pickup up to five quest
levels above you** when its minimum level/prerequisites are already satisfied.
This requires an actually readable quest-log capacity and active count, leaving
three slots reserved after pickup. Without readable capacity, early pickup is
disabled. It never raises the automatic field-work limit. A full log favors
existing work; if no eligible task remains, the card explains the log restriction.
It never drops a quest for you.

Optional `C_QuestLog.GetMaxNumQuestsCanAccept` is runtime-checked and isolated by
pcall. Its presence/valid result is required rather than assuming a capacity of
20 or 25. This optional contract still needs native-client validation.

An accepted suitable quest rejoins at its pickup/field batch. With history alone,
the route can rejoin after positively observed turn-ins, including saved completed
steps. Earlier unknown tasks remain unfinished and reviewable; the route does not
invent completion to move its cursor. Old Northshire/Goldshire batches have exit
levels, with allowances for necessary bridges and observed custom quest levels.

If authored batches have no ready tasks, supported regional alternatives can be
offered with a label. The focused plan does not silently send the player to Loch
Modan. If no eligible regional task remains, it waits below level 20 and suggests
checking restrictions/local alternatives. A wait can reflect deferrals, failure,
prerequisites or log space; it does not prove an XP shortage. Main campaign
completion still requires the actual target level.

## Offline comparison

`tools/route_benchmark.py` loads the real Lua planner against an explicitly
synthetic three-quest hub/field map. The older free-pool strategy produces three
separate outings (six hub crossings); phase batches produce one outing (two hub
crossings). Both reconcile the same nine positive quest phases. Synthetic map
units are recorded, without claiming real yards, traversability, seconds or XP.
The benchmark does not model deaths, vendors, terrain, respawns or other players.

```sh
/workspace/.foreverxp-tools/bin/python tools/route_benchmark.py --check Documentation/Reference/RouteBatchBenchmark.json
python3 tools/build_route_plan.py --check
```

The checked JSON result is an algorithm regression artifact, not an in-game
performance result. No percentage speed improvement is claimed for Forever.

## Source and validation

Reference/ElwynnWestfall1_20Plan.json is the independently authored itinerary.
The generator creates Data/RoutePlans/ElwynnWestfall1_20.lua. Every selected quest
exists in both retained Alliance campaigns, has no class restriction and is
non-optional in the selected reference. Python checks all three phases, prerequisite
ordering and giver/recipient regions. Runtime registration rejects incomplete,
duplicated or invalid phase batches and out-of-order selected ALL prerequisites.

Thirteen dedicated Lua route scenarios cover batching, safe advance pickups,
capacity, working-level limits, minimum/prerequisite/race/defer guards, explicit
pins, recovery, region/level handoff and honest waits. The existing campaign
simulations now assert positive phase ledgers rather than assuming that accepting
one quest must immediately focus its objectives; batching intentionally permits
another pickup first. Separate tests retain free-pool behavior and manual control.

Actual path efficiency, sufficient XP at each stage, turn-in timing, availability
and server-specific changes need a live playthrough. Follow the run-report guide
and record concrete failures before adding verified labels or extending this
itinerary to more starts/level ranges.
