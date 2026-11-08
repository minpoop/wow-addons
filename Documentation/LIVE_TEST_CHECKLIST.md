# Live test checklist — 0.7

All new scenarios below are pending. No WoW client is available in this workspace.
Record version/build/interface, date, scenario, expected/actual result and any
error/quest/recipe IDs. Earlier user reports establish loading, journal progression,
Elwynn catch-up and a working-looking 1–20 test, not full content verification.

1. Install the new folder and restart. Check errors and `/fxp diagnostics` against
   the actual interface. Verify existing quest/profession state survives.
2. Right-click the header, instruction body, navigation strip and grip. Exercise
   all dropdown pages; close by action, outside click and Escape. Hide/reopen with
   `/fxp`; no invisible overlay should block the game. Try `/fxp menu` as fallback.
3. Resize from the lower-right corner at small/large UI scales. Check text reflow,
   wheel scrolling, progress/navigation separation, lock, presets and shared font
   preferences. Switch all themes and views. Relog and check size/position per
   character. The portrait should remain absent.
4. On each Horde race at level 1, `/fxp leveling` should choose Horde and offer a
   suitable home-zone introduction. Confirm race-restricted quests are available.
   Check Alliance selection on an Alliance character and opposite-faction guards.
5. At multiple mid-levels, verify the observed level, active objective or turn-in,
   minimum-level/prerequisite availability, defer/other/auto behavior and relog
   state. Unknown older work must remain unfinished. Check all later chapters for
   XP gaps, missing quests, changed locations and travel issues; record them.
6. Accept, progress, complete and turn in quests normally. Check explicit/history
   evidence, repeatables and abandonment. Disappearance must never prove turn-in.
   Check Elwynn resume/undo and journal focus without losing existing progress.
7. On an open, known map, compare the arrow to an actual target north/east/south/
   west while rotating the character. Compare reported yards with independently
   known geometry. Check zone transitions, transports, loading, unavailable facing,
   map APIs and optional HBD absent/present. Missing data must keep coordinates.
8. Outside combat, show target map and inspect the pin while zooming and changing
   maps. In combat the command must refuse safe opening without taint/protected
   errors. Unsupported canvas/map identity must fall back clearly. Check localized
   zone names; unknown names must never select a guessed map.
9. For learned crafting professions, compare observed skill/cap/known recipes and
   bag stock with the client. Craft, change inventory, train ranks and relog.
   Verify genuine skill-ups move stages; items alone do not. Check intermediate
   stock/tools, batch/target/recipe choices and a secondary book/quest rank gate.
10. Gather with each gathering profession. Check skill/stage and carried resources,
    unlearning, temporary data outages and character isolation. Confirm unchanged
    targets across Farm/Buy/Hybrid modes. Survey actual routes before verifying any.
11. Profile gameplay with window shown/hidden, map open/closed and frequent events.
    The navigation timer should stop when unused and should not trigger full quest
    or skill scans. Record CPU/memory behavior; no live profiling has run here.

Source reference content and client API verification remain separate. Record
measured outcomes before changing any verification label.


## Quest advice (0.7.1, pending)

Compare level warnings at +2 and +4 with the quest log, then test an elite/group
quest and an ordinary quest. Confirm live quest levels override references and
unknown API data never claims a safe encounter. Check escort/event/cave notes
against the actual quest; a needs-event flag alone must not imply an escort.
Complete objectives and enter turn-in: combat warnings should disappear. Verify
a failed quest stays visibly failed. Toggle tips and warnings separately from the
right-click menu, relog, resize and scroll; the warning caption must stay visible
and progress/selection must remain unchanged. Record any custom server differences.


## Focused route and run reports (0.8, pending)

Start with `/fxp route elwynn`, then `/fxp run start`. In Goldshire verify pickups
for mine, candles and gold dust appear before field work; finish overlapping
objectives and inspect the combined return. Install mid-route and confirm earlier
unknown introductions are bypassed without false completion. Test manual keep,
auto/off selection, deferrals and different actual quest levels.

Check capacity against your real quest log. Early pickups must require actual
spare slots, respect minimums/prerequisites and leave three slots reserved; field
work must still meet the ordinary difficulty window. Test a full log and an
unavailable capacity getter. A local shortage must wait or offer a labeled
regional alternative, without fabricated XP or automatic abandonment.

Use `/fxp run report` at each level, apparent XP gap, failed pickup or long detour.
Compare XP changes and unique turn-ins to actual gameplay; record deaths/travel
separately. Relog/load/change characters and verify no offline/other-character XP
or time is added. Stop/restart recording and check one previous report and normal
quest/profession progress. XP events must not cause extra quest scans. Check CPU/
memory in a longer run. At level 20 the full campaign should resume ordinary pool
selection; the retained 1–20 test should finish only at actual level 20.
