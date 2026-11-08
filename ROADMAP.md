# Development status — 0.7.1

| Area | Implemented | Remaining validation/work |
| --- | --- | --- |
| Foundation | Interface-16001 manifest, guarded adapters, safe per-character progression and recovery | User reports loading works; full runtime/event/save matrix pending |
| Quest planning | Journal, automatic catch-up, level-aware faction campaigns, defer/keep, prerequisite bridges | User reports journal/catch-up and 1–20 improvement; complete live quest traces pending |
| Content | Alliance 556 quests, Horde 821, 12 chapters each through 60; retained Elwynn/1–20 | Full live 1–60 playthroughs, XP gaps, custom server/race facts, class and dungeon guides |
| Navigation | Optional HBD/C_Map geometry, rotating arrow, straight-line yards, safe target-map action and canvas pin, coordinate fallback | Actual facing/axes/map canvas, combat/taint, localization and performance checks |
| Professions | 12 guides 1–300; skill/rank/recipe/carried-stock tracking; 132 recipes/146 stages | Complete live profession tests, verified resource loops, server-specific differences |
| Quest advice | Level/tag cautions, reference elite/escort/event/cave notes and practical tips, independent menu preferences | Native tag behavior and actual server hazards need live checks |
| Window | Resizable scrolling objective card, right-click dropdown, themes, text controls, per-character dimensions | Native font/layout/resize/menu and relog checks in game |
| Integration | Explicit detours and route drafts, Farm/Buy/Hybrid planning | Surveyed routes, verified position recording and measured travel costs |
| Release | Lua/Python regression suite, source-rendered previews, ZIP/checksum | Live checklist, long-session profiling and production release gate |

New code and source-inspected APIs do not certify compatibility. No authored
content is live-verified end to end. Follow Documentation/LIVE_TEST_CHECKLIST.md
and record actual outcomes before promoting labels or claiming complete XP supply.
