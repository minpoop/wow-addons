# Development status

## Concrete plan and phase gates

1. Inspect local client evidence; record facts and unresolved contracts.
2. Build isolated compatibility, lifecycle, safe saves, slash controls and UI.
3. Validate offline foundation; gate live loading on a real interface/profile.
4. Develop independent guide and profession algorithms with synthetic fixtures.
5. After obtaining live evidence, implement exact gameplay adapters and validate
   one real guide and profession before expanding content or navigation.
6. Verify the implemented consent-based detours and field-journal UI in game;
   add measured navigation, original verified content and release validation.

## Phase report

| Phase | Implemented files/features | Validation | Remaining gate / next step |
| --- | --- | --- | --- |
| 1 Foundation | Core/, UI/MainWindow.lua, interface-16001 TOC | Offline tests; user confirms 0.1 build loads in live client | Detailed UI/persistence gameplay checks pending |
| 2 Quest engine | StepValidator, GuideEngine, LiveJournal, ForeverAdapter, RecoveryEngine | User reports 0.2 journal progresses; 0.3 route loads but did not catch up; offline regression tests | 0.3.1 adds automatic quest matching and reversible cursor recovery; live fix confirmation pending |
| 3 Navigation | Waypoints.lua, GatheringRoutes.lua | Coordinate fallback, draft validation, verified-provider recording | Facing/map/scale APIs, arrow and map pins pending |
| 4 Professions | MaterialCalculator.lua, RecipeDatabase.lua, ProfessionPlanner.lua, ProfessionController.lua | Authored target skill bands, known-recipe alternatives, estimates, UI and stale-data handling | Live skill/recipe tracker and verified catalogs pending |
| 5 Modes | Pure Farm/Buy/Hybrid split and manual prices | Shared targets, inventory subtraction and shopping quantities | Verified farming routes and live inventory integration pending |
| 6 Integrated routing | Navigation/Detours.lua, explicit slash consent, suggestion limits | Pause/resume, cancellation, main objective restoration | Verified routes and live-client integration pending |
| 7 Content | Original Elwynn common route: 34 quests / 113 steps; curated pinned facts | Schema, dependency, eligibility and factual coordinate checks; synthetic full progression | Forever validation pending; other faction regions and professions missing |
| 8 Release | Documentation, data validator, ZIP packager, original SH2-inspired theme with James Sunderland notes | Offline suite, packaging and content CLI tests | Development ZIP built; live visual review, performance profiling and production release pending |

This is an incremental implementation, not the completed production addon from
the master brief. Advancing the independent algorithms does not bypass the Phase 1
live-compatibility requirements. User-reported startup is recorded separately from
gameplay validation. No verified sample leveling route is claimed.

Current external blockers: live API/event evidence and original verified server
content. The reported version is `1.60.70790`; the supplied working reference
manifest resolves the interface to `16001`. The upstream quest compatibility and
event/cache source at that exact commit has been inspected. The next live check
is `/fxp elwynn`: validate Northshire accept/turn-in steps and report mismatches.
No named quest, event trace or full route completion accompanied the reported
journal advancement; keep that limited result separate from content verification.
