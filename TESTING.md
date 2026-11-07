# Validation

```sh
/workspace/.foreverxp-tools/bin/python tools/test.py
```

Install `requirements-dev.txt` into that isolated virtual environment first (see
README). Tests run actual Lua 5.1 via lupa. No game, account or credentials are
needed. All gameplay APIs are mocks, including the build/interface return values.
These tests do not certify client compatibility or gameplay correctness.

The manifest loader executes every listed Lua module in load order. Behavioral
tests cover candidate addon events and initialization, handler deduplication and
failure isolation, missing APIs, invalid saves and legacy migration, per-character
isolation, settings and position persistence, guide schema/prerequisites,
acceptance/completion/turn-in evidence, manual review and optional skip, reload
state, recovery, route recommendation, item/level/profession conditions, material
dependency expansion, shared stock and batch surplus, cycles, invalid inputs,
Farm/Buy/Hybrid modes, price uncertainty, skill-up estimates, waypoint fallback,
reset confirmation and unsupported UI behavior. Additional tests exercise authored
skill bands and known-recipe alternatives, provider outages without plan loss,
profession view integration, route draft demotion and recording, detour consent,
main-objective restoration, finite-data checks, theme persistence and James
Sunderland's original companion notes.

Python packaging tests run in temporary copies and inspect ZIP contents, manifest
replacement, fixture exclusion and placeholder rejection. Synthetic interface
values used in override tests never produce a distributable in the working tree.
The real development package defaults to interface 16001 from the working
reference manifest. CLI tests also check duplicate/executable content rejection
and missing quests against a supplied catalog.

`Tests/tracking.lua` simulates the source-inspected interface-16001 contracts:
single-argument acceptance, event coalescing, objective rows, explicit and
history-backed turn-ins, repeatable history, abandonment, failed/unloaded data,
loading screens, inventory/level changes and journal restoration. These are
contract tests, not an assertion that gameplay testing occurred in this workspace.

User-reported live evidence: the 0.1 development build loaded successfully and the
0.2 journal "does progress". Exact quest/actions were not recorded. Detailed
event/persistence checks remain useful; these reports do not validate the new
Elwynn content or every tracking edge case.

`Tests/routing.lua` covers objective-first batching, out-of-order observations,
explicit focus, immediate manual resume, old saved cursor compatibility and full
synthetic progression through the Elwynn reference guide. `Tests/test_elwynn.py`
cross-checks every route quest, giver, reference coordinate, minimum level and
prerequisite against curated source facts. Class restrictions are absent in those
reference records. None of these tests establish live Forever route validity.

Next manual content check: use `/fxp elwynn`, confirm the introduction, then test
A Threat Within and the first Northshire quest branches. Record any differing
quest names, prerequisites or giver locations before expanding the verified label.

## Manual live-client scenarios (all unrun)

`Tests/recovery.lua` covers mid-route installation with an active Goldshire quest,
completed active quests, history-only catch-up, native focus changes, fresh quest
activity, missing/invalid snapshots, preserved overrides, relog state, review,
disabled settings, undo and the Elwynn slash-command/refresh path. The adapter's
native focus getter is read-only and optional; a throwing getter does not discard
the quest snapshot. These regression cases reproduce the reported failure as
mocked scenarios. The user now reports catch-up works, but that the quests were
outleveled. No named quest trace or full-route live validation was supplied.

For the 0.3.1 live check, install while an Elwynn quest is already accepted and
select Elwynn. It should show that quest's objective, or its turn-in if complete,
without clicking through old instructions. Change the native tracked quest or
progress another route quest and check the new target. Verify unknown earlier
steps were not marked complete, Back pauses relocation, and resume undo returns
to the previous cursor. Check saved progress after relogging.

Complete the compatibility checklist before these checks:

1. Back up saves, install a manifest built from the observed interface, log in and
   inspect addon loading and errors. Confirm no taint or protected-action errors.
2. Toggle all views, drag, change scale/opacity, compact and restore. Check clipping
   and readability at common UI resolutions. Compare fog and contrast themes and
   James's header notes. Reload and verify position/settings/theme.
3. Log in as a second character and verify guide/profession separation. Reload
   during a temporary API outage; ensure original progress remains intact.
4. With a verified adapter and one **verified** small guide, accept a quest, update
   each objective, complete and turn in. Verify each event and step advancement.
   Abandon a quest: disappearance must not imply turn-in. Verify log-full behavior.
5. Backtrack, manually confirm, skip an optional step and relog. Review recovery
   suggestions for a partially leveled character; uncertain steps must remain.
6. With verified recipes, change profession skill and inventory. Switch all three
   modes, preserving the target. Verify intermediate inputs and vendor reagents.
7. Change zone/loading state with a waypoint; ensure coordinate fallback remains
   safe. Arrows/map pins are pending and must not be described as tested.
8. Verify reset asks for confirmation; cancel by not confirming. Confirm once and
   inspect backup. Verify another character's state remains intact.
9. Profile extended gameplay and busy areas. No per-frame handler is installed in
   this foundation; future navigation/scanning needs measured throttling.

Live integration, server content, XML, combat behavior, Lua runtime identity,
visual polish, navigation direction/distance and optional addons remain unrun.

## 0.4 level-aware campaign

`Tests/campaign.lua` adds 17 behavioral scenarios: valid shared reference content,
choices at every level 1–19, outleveled tracked quests, accelerated levels, native
quest-level precedence, positive history, prerequisite bridges, optional goals,
defer/keep and pin release, missing data, exhausted pools, actual target 20,
one-time Elwynn import, invalid/reloaded saves, public commands/UI and synthetic
1–20 progression. `Tests/test_campaign.py` checks every selected quest and phase
against curated facts, including prerequisites and missing/present coordinates.
The suite currently passes 79 Lua checks and 5 Python tests.

Next live test: on the outleveled character, run `/fxp leveling`, verify the level
and recommended quest difficulty, then complete a quest and gain a level. Check
that old quests remain unfinished without holding the recommendation. Exercise
Other quests, Defer quest, Auto plan and keep; relog to check preferences. Confirm
prerequisite access, quest locations and XP gaps through levels 1–20. These
campaign scenarios have not yet been run on the live client.

## 0.5 expanded campaign and theme menu

The suite passes **95 Lua checks and 8 Python tests**. Tests/campaign_full.lua
adds 12 scenarios covering all levels 1–59, actual target 60, complete 1–20 save
continuation, ALL/ANY relationships, exclusions, local-zone preference without
area gates, corrupted metadata, full-pool preferences, paginated output, positive
synthetic progression and native external-related history. Tests/themes.lua adds
four scenarios for settings buttons, immediate/persisted selection, all tabs,
James visibility, compact controls, safe legacy defaults and normal-text contrast.
Tests/test_campaign_full.py checks every expanded fact/phase, retained initial
content, later band breadth and deterministic regeneration. Package checks verify
the expanded module is included in both TOC and ZIP.

Source-rendered Chromium previews check normal campaign layouts and the theme
menu; they are not game screenshots. Live checks: select /fxp leveling to import
old test progress, then follow the 1–60 reference validation document through
later chapters. Open Options, select all three requested themes and High contrast,
change tabs, use compact mode and relog. Confirm theme switching never moves the
quest cursor. Measure XP gaps and travel issues rather than inferring them from
synthetic progression.
