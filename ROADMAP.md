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
| 2 Quest engine | StepValidator, GuideEngine, LiveJournal, ForeverAdapter, RecoveryEngine | User reports 0.2 journal progresses; 0.3 route loads but did not catch up; offline regression tests | User reports catch-up now works; 0.4 adds level-aware 1–20 selection after outleveling old quests |
| 3 Navigation | Waypoints.lua, GatheringRoutes.lua | Coordinate fallback, draft validation, verified-provider recording | Facing/map/scale APIs, arrow and map pins pending |
| 4 Professions | MaterialCalculator.lua, RecipeDatabase.lua, ProfessionPlanner.lua, ProfessionController.lua | Authored target skill bands, known-recipe alternatives, estimates, UI and stale-data handling | Source-inspected skill/recipe/inventory tracking and 12 reference guides added in 0.6; live profession validation pending |
| 5 Modes | Pure Farm/Buy/Hybrid split and manual prices | Shared targets, inventory subtraction and shopping quantities | Verified farming routes and live inventory integration pending |
| 6 Integrated routing | Navigation/Detours.lua, explicit slash consent, suggestion limits | Pause/resume, cancellation, main objective restoration | Verified routes and live-client integration pending |
| 7 Content | Elwynn and retained 1–20 test; Alliance 1–60 pool: 556 quests / 1,670 steps, 12 chapters; curated facts | Schema, dependency, eligibility and factual coordinate checks; synthetic full progression | Forever validation pending; Horde leveling and live profession validation pending |
| 8 Release | Documentation, data validator, ZIP packager, original SH2-inspired theme with James Sunderland notes | Offline suite, packaging and content CLI tests | Development ZIP built; live visual review, performance profiling and production release pending |

This is an expanded reference implementation, with production validation still pending. Advancing the independent algorithms does not bypass the Phase 1
live-compatibility requirements. User-reported startup is recorded separately from
gameplay validation. No verified sample leveling route is claimed.

Current external blockers: live API/event evidence and original verified server
content. The reported version is `1.60.70790`; the supplied working reference
manifest resolves the interface to `16001`. The upstream quest compatibility and
event/cache source at that exact commit has been inspected. The next live check
is `/fxp leveling`: validate level-appropriate recommendations, prerequisite
access, quest facts and XP gaps through levels 1–60. Theme settings include
Silent Hill, Warcraft, Warhammer 40K and High contrast, with source-rendered
previews and mocked interaction/persistence tests.
No named quest, event trace or full route completion accompanied the reported
journal advancement; keep that limited result separate from content verification.
