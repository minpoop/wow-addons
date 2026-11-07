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

## Manual live-client scenarios (all unrun)

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
