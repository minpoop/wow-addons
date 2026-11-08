# Architecture

`ForeverXP` is the sole addon namespace. Required slash-command globals and
`ForeverXPDB` are the only other intentional globals. The TOC defines load order;
modules register once through `ForeverXP:Register` and use `ForeverXP.modules`.
The candidate UI needs no XML or external Lua libraries. Version 0.5.1 removes
the portrait texture and sidebar; the guide body uses the full window width.

| Module | Responsibility |
| --- | --- |
| Compatibility | Guarded diagnostic calls; verified-profile provider boundary |
| ForeverAdapter | Source-inspected, interface-gated quest/item reads and coalesced events |
| LiveJournal | Bounded per-character checklist generated from observed quest records |
| LevelingCampaign | Level-aware quest pool selection, prerequisite bridges, persistent defer/keep and level-20 goal |
| RecoveryEngine | Evidence-based cursor catch-up for opted-in authored routes; reversible without completing unknown steps |
| Events | Keyed handlers, idempotent subscription, isolated callback errors |
| SavedVariables | Schema handling, backups, per-character tables, session fallback |
| Settings | Typed defaults and clamped display/performance settings |
| Validation | Bounded data-only checks, finite numbers and dense arrays |
| StepValidator | Data-only content and prerequisite/coordinate validation |
| GuideEngine | Authored selection, positive evidence, explicit overrides, recovery suggestions |
| MaterialCalculator | Dependency expansion, shared inventory, cycle detection |
| ProfessionPlanner | Shared mode state, probability estimates, farm/shopping split |
| RecipeDatabase | Verified catalogs, contiguous skill bands and dependency checks |
| ProfessionController | Provider snapshots, persistent selection, target and price controls, stale plan handling |
| Waypoints | Normalized coordinate validation and text fallback |
| GatheringRoutes | Verified route registry, unverified drafts and guarded coordinate recording |
| Detours | Explicit opt-in, paused main progression and current-objective restoration |
| Themes | Original fog/contrast palettes and James Sunderland companion notes |
| MainWindow | Movable window, views, guide controls, display settings |
| Bootstrap | Candidate lifecycle events and slash commands |

## Data flow

Candidate `ADDON_LOADED` initializes the save after the client has loaded it.
Character identity uses a nonempty observed GUID or a complete realm/name pair.
If unavailable, progression stays in memory; it is never filed under a fabricated
character. Login/world events retry identity. Anonymous progress is not silently
merged into an identified character. Unknown schema or malformed top-level save
tables keep the original global intact and use a separate session database.

Schema 0 (or missing schema) with valid settings/characters tables migrates to 1
with `migrationBackup`. Schema 1 is copied before use. Corrupt character or guide
records remain intact and require explicit resolution. Settings are shared;
guides, overrides, profession state and window positions are per character.

A future verified provider emits `FXP_STATE_CHANGED` after relevant game events.
`Compatibility:Read("snapshot")` returns normalized state to GuideEngine. Missing
or failed APIs return unknown; a disappeared quest is never evidence of turn-in.
Guide changes notify Detours, which updates the waypoint or cancels a stale detour.
Other UI changes only redraw the UI,
so manual waypoints survive unrelated refreshes. Internal `FXP_` events are never
registered as Blizzard events. No module polls per frame or scans bags repeatedly.

## Client adapter contract

Default `Compatibility.profile.verified` is false. Presence probes and mock tests
do not change it. `RegisterInspectedProvider` records source evidence separately;
the shipped snapshot adapter checks observed interface 16001 on each read. It does
not unlock unrelated capabilities or assert live verification. Snapshot shape:

```lua
{
  level = observedLevel,
  quests = { [observedQuestId] = { accepted=true, complete=true, turnedIn=true } },
  items = { [observedItemId] = observedCount },
  professions = { [observedProfessionKey] = observedSkill },
  observed = { [authoredStepId] = true },
}
```

Each boolean must mean that exact fact was positively observed. Missing fields
mean unknown. `observed` is for client-confirmed travel, interaction, flight,
training and item-use facts, never elapsed-time guesses. Provider functions catch
API failures at the boundary and must avoid protected operations. Register only
live-confirmed game events; emit normalized changes when state actually changes.

Directional navigation needs verified position, facing, map identity and scale.
Neither guessed zone dimensions nor straight-line travel-time claims are allowed.
Map pins, TomTom, profession scanners, inventory caches and price providers belong
behind the same capability boundary when their client contracts are verified.

`professionSnapshot(profession)` returns `{skill, inventory, knownRecipes,
opportunities}`. Skill and quantities are nonnegative integers; knownRecipes maps
recipe identifiers to booleans; opportunities optionally maps item identifiers to
explicit verified gathering metadata. `position` returns normalized `{zone,x,y}`.
Neither capability is active in the default unverified profile. The profession
controller retains an old plan with a visible stale warning during provider
outages; it never replaces saved targets or mode with temporary missing state.

Detours are session-only: no assumption is made that travel context survives
relogging. Starting a detour requires consent, pauses main auto advancement and
does not mutate the main guide cursor. Finishing restores the current main
objective. Explicit guide navigation cancels the detour rather than restoring an
obsolete step. With no guide, a prior manual waypoint is restored instead.

The quest snapshot also supplies `active` quest IDs, title/objective records and
source provenance. `LiveJournal` creates COMPLETE_QUEST/TURN_IN_QUEST pairs only
from those observed records, with stable IDs and a distinct
`observed-character-log` label. It bypasses neither validation nor the authored
content verification gate: this is a separate kind of non-optimized checklist.
Per-character `liveJournal` stores at most 100 ordered quests; corrupted data is
retained without rewriting it. Each quest is recorded once, not once per repeat.
New quests append; a previously finished journal resumes at the new step.

Version 0.3 builds all journal objective steps before the turn-in pass. Positive
observations are recorded even when a later quest finishes first; unobserved tasks
stay pending. `focusStep` pins an explicitly chosen task until completion, then
the pending queue resumes. Manual review, auto-advance settings and profession
detour pauses still apply. Stable step IDs preserve older interleaved progress.
The progress bar counts actual completed IDs rather than cursor position.

`RegisterReferenceGuide` validates an original, sourced reference guide separately
from production registration. It is explicitly selectable but excluded from
automatic recommendations and live-verified coverage. The Elwynn module uses
this path, with reference markers on every factual NPC/object waypoint.

The adapter batches event bursts through one 0.2-second timer where available;
otherwise it refreshes on events directly. It reads only referenced item counts,
pauses during world loading and never treats a missing quest as completed. Failed
reads do not update guide progress. Turn-in memory/history baselines are bounded.

Elwynn opts into `autoResume`. RecoveryEngine reconciles positive evidence for
all route steps, then matches fresh quest activity, native tracked/selected quests,
the accepted current quest or another accepted route quest. With completed history
and no active match, it finds a remaining eligible acceptance/level task. It never
infers a turn-in from absence or completion of a downstream prerequisite.
`resumeStart` bounds later suggestions to the resumed route section; `resume`
stores the last cursor move, reason and count of earlier unconfirmed steps.
These are bounded metadata, not a rewritten completion ledger. Undo returns to
the previous cursor and enters review mode, retaining legitimate observations.
Automatic advance, review and detour guards run before recovery. Failed or missing
snapshots cannot relocate the cursor. Invalid saved resume records are retained
and rejected rather than silently reset. All guides display actual completion
counts; reaching the route's end with deferred work is labeled explicitly.

## Level-aware campaign

Campaign guides opt into LevelingCampaign through typed campaign metadata.
GuideEngine delegates automatic updates and uses non-destructive defer/cycle
controls for these guides. The campaign reconciles positive step evidence, builds
eligible goals by observed level, resolves unfinished prerequisite chains and
selects a phase for the chosen quest. It never calls gameplay actions. Optional
observed quest.level overrides the reference value. Campaign state version 1 stores
status, lastLevel, deferredByUser and pinnedQuest alongside normal completed IDs.
Runtime snapshots/candidates are transient and tied to the current guide state.
The UI uses level progress and explicit planner controls. Missing data retains
progress. A waiting pool is distinct from the actual level-20 target reached.

## Expanded campaign and themes (0.5)

The default campaign ID is alliance-levels-1-60; the old ID remains available
through /fxp 1-20. One-time import copies matching completion/overrides and planner
preferences without importing the old level-20 finished state. Accept metadata
adds prerequisiteQuestsAny (quest IDs, one required) and exclusiveQuests (quest
IDs, positively active/completed conflicts). ALL prerequisites remain backward
turn-in step references. The adapter reads history for related IDs even when an
alternative is outside the selected pool. Root resolution follows supported
alternatives and never synthesizes missing content. Selected active quests bypass
prerequisite inference; no earlier unknown steps are marked complete.

A 25-point local-zone preference reduces unnecessary zone switches while goals
remain inside the level window. Chapters are contiguous summaries, not gates.
Generated Lua is reproducible from selected JSON facts via tools/build_leveling.py.
No downloaded source executes in the client or content builder. The expanded
panel has extra body space for target hints and live objectives.

Themes.options defines four persisted choices. Settings validates IDs against its
allowlist. Options buttons call Settings:Set immediately; Paint updates panels,
text, selected states, progress, procedural borders and theme-specific headers.
Compact Options uses one cycling control. Theme changes emit only FXP_CHANGED,
so they redraw without moving quest cursors or modifying gameplay progress.
James's original text notes remain in all skins; the portrait was removed in 0.5.1.

## Profession guide tracking (0.6)

ProfessionAdapter registers a separate source-inspected professionSnapshot provider
for interface 16001. It enumerates skill lines, expands collapsed headers through
the inspected API, matches modern skill IDs (English-name legacy fallback), checks
rank/recipe spells and reads referenced carried-item counts. Failures remain
unknown; no skill is inferred from inventory. Skill/recipe events share the existing
ForeverAdapter coalesced refresh queue and discard chat arguments.

RecipeDatabase:RegisterReferenceGuide delegates to ProfessionGuides validation.
This path stays separate from live-verified legacy probability catalogs. Reference
guides choose stages by actual skill; batches compute exact reference craft inputs,
using known fixed-output intermediates and owned stock through MaterialCalculator.
Missing included tools are prepared before the main recipe. Gathering uses actual
skill and resource inventory with no craft estimate or purchased-skill inference.

ProfessionController supports both formats and keeps targets/preferences separated
by character and profession. The new guideVersion=1 state stores batch, lastSkill
and preferredRecipes; future/corrupt records remain untouched. The UI shows current
skill/target progress, recipe/source, batch materials and rank reminders. Compact
mode preserves tracking while hiding controls. New guides are generated from
selected factual JSON; source data and Python are not runtime dependencies.
