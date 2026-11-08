# Validation

```sh
/workspace/.foreverxp-tools/bin/python tools/test.py
```

Install pinned `requirements-dev.txt` into that isolated virtual environment first
(see README). Current suite: **135 Lua checks + 14 Python tests**. Lua tests run
actual Lua 5.1 through lupa, loading every TOC module in order. Gameplay and frame
APIs are mocks. No game client/account is used and no live compatibility claim is
implied. The development package targets the observed manifest interface 16001.

## Coverage

| Test group | Checks |
| --- | --- |
| Foundation / planning | Initialization, events, missing APIs, settings, saves, corruption/future schemas, character isolation, reset backup, data-only validation |
| Quest tracking / routing | Single-ID acceptance, coalesced events, objectives, explicit/history turn-ins, repeatables, abandonment, outages/loading, journal batching/focus |
| Recovery | Mid-route installation, native focus, fresh activity, unknown prior work, review/undo, preserved overrides, relog and disabled settings |
| Alliance campaigns | Level-aware choices at all levels 1–59, accelerated levels, observed quest levels, prerequisite bridges, optional content, defer/keep, positive phases, real target 60 and one-time old-save import |
| Horde campaign | 821-quest registration, all four race starts, choices at each level 1–59, race/faction guards, automatic faction choice and synthetic positive progression |
| Professions | 12 guides/132 recipes/146 stages; all skill points 1–299; modern/legacy skill IDs, recipe/rank knowledge, training gates, processing/tools/stock, batch choices, gathering, unlearning, outages, persistence and coalescing |
| Navigation | Nine scenarios for vectors/facing, reported map dimensions, world axes/shared instances, unknown data, ambiguous names, safe map opening/pin/combat, optional HBD, timers, loading and interface guards |
| Interface | Six scenarios for native resize callbacks, limits/reflow, per-character dimensions, hidden controls/dropdown, outside/hide dismissal, lock, scrolling, typography/profession actions without quest mutation |
| Themes | Immediate/persisted changes, all views, native-font calls, portrait absence, companion text, valid defaults and normal-text contrast |
| Materials / integration | Shared inventory/surplus, recursive dependencies/cycles, known-recipe alternatives, price uncertainty, Farm/Buy/Hybrid, skill estimates, route drafts, explicit detour pause/restoration |

Python checks validate content CLI safety, packaging, all selected quest facts and
phase locations, class/race masks, source prerequisites, representative profession
reagents/outputs, level-band breadth and deterministic regeneration. Horde checks
explicitly distinguish Undead bit16 from Troll bit128. Package checks require the
new modules and original 64×64 uncompressed arrow, excluding portrait art and
synthetic fixture modules. Packaging test overrides use temporary copies only.

Run the deterministic checks independently with:

```sh
python3 tools/build_leveling.py --check
python3 tools/build_leveling.py --faction Horde --check
python3 tools/build_professions.py --check
```

## Visual review

`tools/preview.py` runs the actual Lua UI with mocked frames and outputs HTML to
`dist/previews`. Chromium captures are copied to Documentation/Previews. They show
all requested themes, dropdown, small window, Horde, navigation and profession
views. Arrow preview direction/distance and character state are synthetic.
Screenshots check source layout only; native font metrics and rendering may differ.
No screenshot was captured from the live WoW client.

## Live evidence and remaining checks

The user reports the initial addon loads, the journal progresses, Elwynn catches
up and the level-aware 1–20 change appears to work. No quest/action trace, full
playthrough or profession/navigation test accompanied those reports.

The new window/Horde/navigation and full profession validation remain pending.
Follow [the live test checklist](Documentation/LIVE_TEST_CHECKLIST.md) for native
resize/menu/theme/save behavior, four Horde starts, all chapters, prerequisite
availability, XP gaps, actual arrow/yard/map behavior, combat/taint and profession
skill/recipe/inventory outcomes. Long-session CPU/memory profiling also needs the
client. No offline result promotes a guide or provider to live-verified.
