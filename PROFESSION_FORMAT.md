# Profession format

Version 0.6 adds 12 explicitly labeled Classic reference guides covering 1–300,
with a source-inspected runtime adapter. Reference recipes and authored stages
remain distinct from live-verified server facts. See the separate tracking-guide
contract below; the legacy catalog/planner contract remains supported.

The pure calculator accepts `crafts`, `recipes`, `inventory`, and `producers` maps.
Synthetic example (all keys are fixtures, not game IDs):

```lua
local recipes = {
  process = {output="bar-fixture", outputCount=2, inputs={["ore-fixture"]=3}},
  craft = {output="tool-fixture", outputCount=1,
           inputs={["bar-fixture"]=3,["flux-fixture"]=1},
           station="station-fixture", vendor={["flux-fixture"]=true}},
}
local result, errorMessage = ForeverXP.modules.MaterialCalculator:Calculate(
  {craft=2}, recipes, {["ore-fixture"]=1}, {["bar-fixture"]="process"})
```

Outputs: `missing` remaining leaf purchases/gathering, `used` original inventory
consumed, `raw` leaf demand after owned intermediate substitution (used + missing),
`crafts` counts including processing, `stations` reminders, `vendor` reagent flags.
Owned intermediates reduce processing; batch surplus is reused. Inventory is
allocated once across all requested crafts. Producer mappings explicitly choose
alternatives; no unsupported automatic recipe efficiency claim is made. Reachable
cycles, invalid quantities, missing recipes and producer/output mismatches fail.

Craft counts are explicit. `ProfessionPlanner:Estimate(points,probability,safety)`
returns guaranteed counts only at probability 1, an expectation at constant
independent probability, and a configurable expected-count margin. A margin is
not a statistical guarantee. Tiered/changing skill-up probabilities use contiguous
authored segments; the planner does not guess the probabilities or recipes.

`State(character,key)` stores one profession state, including `target` and mode.
`SetMode` supports Farm, Buy and Hybrid without resetting target or progression.
`Distribute` uses inventory-subtracted missing materials. Farm lists collection
requirements; Buy lists purchases; Hybrid farms only explicit verified
opportunities and buys the remainder. No gathering coordinates are invented.
Manual price maps use one consistent currency unit. Cost is partial unless
`costComplete` is true. No purchases or crafting are automated.

## Authored target catalogs

`RecipeDatabase:Validate(catalog,false)` validates authoring input;
`RegisterCatalog(catalog)` requires live verification and source declarations.
Required catalog fields: `id`, `title`, `profession`, `minSkill`, `maxSkill`,
`recipes`, `producers` and a dense `segments` array covering the skill interval.
Each segment has a unique `id`, inclusive `from`, exclusive `to`, optional text
`trainer` reminder and ordered `choices`. A choice supplies `recipe`, an observed
skill-up `chance` in (0,1], and integer skill-point `gain` per success. Authored
bands represent assumptions to verify on the server, not measured facts here.

`Plan(catalog,state,current,inventory,knownRecipes,prices,opportunities)` intersects
the requested target with each band and picks its first known authored recipe,
or the explicit `state.selectedRecipes[segment.id]`. Unavailable recipes and
unknown processing recipes produce an actionable error. Per-band expected crafts
are rounded up; conservative counts apply `state.safety` (default 0.2). Counts
are consolidated before material expansion so inventory is subtracted only once.
Expected and conservative calculations are separate scenarios, not additive.
Guaranteed material counts are available only when every selected chance is 1.
This is authored-route planning, not a globally optimal market-cost solver.

`state.estimate` selects expected, conservative (default) or guaranteed.
Character-specific targets, mode, prices and overrides are preserved. The live
controller expects a verified `professionSnapshot` provider; absent/transient data
retains the previous plan with a stale warning. Controls and slash commands can
change the selected catalog, target, mode, estimate and manual prices.

## Gathering content contract

Each future route needs ID, zone/map identity, resource identifier, minimum and
maximum skill, ordered normalized waypoints, description, difficulty, source,
client/build and verification date. `GatheringRoutes:Validate` checks required
metadata, skill ranges, dense ordered points, normalized coordinates, matching
zones and a 512-point limit. Production registration requires verification/source;
authors must independently record client/build/date evidence. `ImportDraft` always
demotes imported content to unverified observations. It preserves existing drafts
and caps saved drafts at 100. `Record` requires a verified position provider,
rejects other-zone/duplicate points, and never certifies the observation as a spawn.

Integration defaults to disabled. Minimal/balanced/focused limit suggestions to
1/3/all same-zone, skill-matching verified routes. These limits are not measured
travel-time budgets. Explicitly accepted detours share waypoints, pause main guide
auto advancement and restore the main objective afterward. Map overlays, trainer
location registries and auction providers remain pending.

## Tracking-driven reference guides (0.6)

RecipeDatabase:RegisterReferenceGuide validates the dedicated ProfessionGuides
schema; it never sets a live-verification flag. Each guide has guide=true,
kind=craft/gather, id/profession/name/title, skillId, minSkill=1, maxSkill=300,
reference-reviewed verification and a source. Four rankSpells correspond to the
reference caps 75/150/225/300. rankNotes supply training reminders. Stages are
contiguous from 1 through 300, with id/from/to/text. Craft stages have recipe-ID
choices whose minimum skill does not exceed stage.from; gathering stages have
resource item IDs. Recipe records include name, minimum, acquisition, exact
reference reagent maps, required tools, output and outputCount. Optional seller
and quest-source records are factual learning leads, not live availability claims.

Explicit fixed-output producers expand known processing recipes through the
existing MaterialCalculator. toolRecipes identify included rod/tool preparation.
Source spell effects without an item output (enchants) use a synthetic internal
output key, never an assertion that an inventory item was created. No skill-up
probability is assigned to this guide format. Batch size 1–20 controls a next-craft
scenario, bounded by the remaining stage/target points; repeated crafting never
advances a stage without a new observed skill. Unknown preparation knowledge
leaves that component as an acquisition requirement rather than inventing a recipe.

Profession state adds guideVersion=1, batch, lastSkill and preferredRecipes keyed
by stage ID. Unknown future versions and corrupt values are retained and rejected.
Default target is 300 on first selection; existing targets are preserved. Gathering
modes do not imply skill from purchases. Legacy estimate commands do not apply to
these next-batch guides.

professionSnapshot returns skillsReady, optional positively observed skill/cap,
knownRecipes boolean map and optional inventory. Missing skill means not found in
readable lines, not completed. Missing inventory means unknown stock, not zero.
Provider failures retain prior plans as stale; lastSkill persists as a labeled
historical observation. Actual skill at or above the selected target is required
for target reached. No inferred craft count or resource count completes a stage.
