# Architecture

`ForeverXP` is the sole addon namespace. Required slash-command globals and
`ForeverXPDB` are the only other intentional globals. The TOC defines load order;
modules register once through `ForeverXP:Register` and use `ForeverXP.modules`.
The candidate UI needs no XML or external Lua libraries. It includes a bundled
James Sunderland portrait texture with its original generated source in `art/`.

| Module | Responsibility |
| --- | --- |
| Compatibility | Guarded diagnostic calls; verified-profile provider boundary |
| ForeverAdapter | Source-inspected, interface-gated quest/item reads and coalesced events |
| LiveJournal | Bounded per-character checklist generated from observed quest records |
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
