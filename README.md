# ForeverXP

A leveling and profession guide for WoW Forever, with a resizable field journal,
level-aware Alliance and Horde 1–60 reference guides, and 12 profession guides
from 1–300 with skill, recipe and carried-material tracking.

[Download ForeverXP 0.8.0-dev](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)
· [Interface previews](Documentation/Previews/README.md)

Replace the old `ForeverXP` folder in `Interface/AddOns` with the ZIP's folder,
restart the client and run **`/fxp leveling`**. It chooses your observed faction.
Your existing quest and profession progress is retained. This development build
targets **interface 16001**, from the supplied working Questie manifest; the user
reports client version **1.60.70790**.

## Window and right-click menu

**Right-click anywhere in the window to open the dropdown.** Controls are tucked
into this menu so the main window stays focused on your current task.

- **Route plan & run report:** focused 1–20 batches, free-pool mode and opt-in local playtest reports.
- **Leveling actions:** faction guide, live journal, earlier reference guides,
  other suitable quest, defer, automatic plan and printed quest/chapter lists.
- **Choose profession / Profession actions:** all 12 guides, target skill, recipe,
  batch size, Farm/Buy/Hybrid planning and material lists.
- **Appearance:** Silent Hill, Warcraft, Warhammer 40K and High contrast.
- **Quest tips & warnings:** independent toggles for practical tips and difficulty alerts.
- **Navigation:** arrow, coordinates, show target map and clear target.
- **Window & text:** lock, compact spacing, font size, window presets and opacity.
- **Hide window:** reopen with `/fxp`. Escape also hides the window.

Drag the header to move it. **Drag the lower-right corner to resize** between
380×260 and 980×820 UI units. Long instructions scroll inside the objective card.
Position and size are saved per character; theme/text/display preferences are
shared account settings. Views and compact mode preserve the chosen dimensions.
Slash fallbacks: `/fxp menu`, `/fxp size 620 420`, `/fxp settings`.

The refreshed themes use an objective card, clearer type hierarchy, a progress
line and a separate navigation strip. Silent Hill remains the default; Warcraft
uses parchment and brass, and Warhammer uses gunmetal, crimson and bone.
James Sunderland remains in original companion text. The portrait is removed.
No extracted franchise art, copied dialogue or music is bundled.

## Leveling 1–60

`/fxp leveling` or `/fxp 1-60` chooses the observed faction; `/fxp horde` explicitly
selects Horde. Choosing a known opposite-faction campaign is rejected.

| Guide | Reference quests | Steps | Chapters |
| --- | ---: | ---: | ---: |
| Alliance 1–60 | 556 | 1,670 | 12 |
| Horde 1–60 | 821 | 2,465 | 12 |

The pools overlap in 218 neutral quests: **1,159 distinct quests** overall.
These are class-independent Classic reference pools. The Horde guide supports
Orc/Troll starts in Durotar, Tauren in Mulgore and Undead in Tirisfal, with
race-restricted introductions checked against the observed race. Custom Forever
races and class-specific tasks remain outside the validated reference scope.

Recommendations follow your actual level and observed quest state, generally
between three quest levels below and two above you. Local suitable quests receive
a preference; completing an entire region is never a gate. Older prerequisites
can appear as labeled bridges. ALL/ANY prerequisites and observed exclusive
choices are distinct. Optional encounters are excluded from automatic goals.

Accepted work, live objectives, positive turn-ins and history determine the phase.
A disappearing quest never proves completion. Outleveled quests stay unfinished
and saved. Other suitable quest, Defer and Resume automatic plan affect selection;
they do not mark quests complete or abandon them. The bar measures actual level
against 60. At level 60 the goal ends while unfinished records remain reviewable.
An exhausted pool below 60 waits visibly.

- `/fxp leveling chapters` prints chapter summaries.
- `/fxp leveling quests PAGE` lists unfinished quests, 20 per page.
- `/fxp leveling keep QUEST_ID` keeps/restores an older or deferred quest.
- `/fxp leveling auto` releases an explicit choice.
- `/fxp 1-20` opens the earlier Alliance test; `/fxp elwynn` opens the original
  34-quest shared Elwynn route. Expanded Alliance selection imports matching
  older progress/preferences once, retaining the older saves.

See [Alliance evidence](Documentation/Reference/Alliance1_60.md),
[Horde evidence](Documentation/Reference/Horde1_60.md) and
[content coverage](Documentation/CONTENT_COVERAGE.md). Quest locations are marked
reference. These pools have no measured XP budget or completed Forever 1–60
playthrough, so their content counts do not guarantee enough XP at every level.

## Focused 1–20 route batches

Version **0.8.0-dev** adds an original **Elwynn → Westfall → Redridge** plan:
**53 shared quests, 159 phases and 98 pickup/work/turn-in batches**. For example,
it collects Fargodeep, candles and gold dust before the kobold outing, then groups
the returns. The card names the batch and related ready quests.

Automatic mode applies in those regions below 20. `/fxp route elwynn` explicitly
selects it with the existing Alliance 1–60 campaign; `/fxp route off` restores free
quest-pool selection and `/fxp route auto` restores regional planning. At level 20
the full campaign continues normally. Manual keep still wins, and old unknown
steps remain unfinished when the plan catches up to observed work.

Selected early pickups require actual spare log space and valid minimum levels/
prerequisites. They never relax the automatic combat-level window. Optional group
encounters remain optional; missing regional work causes an honest wait rather
than invented XP or a silent cross-continent detour.

A synthetic three-quest benchmark reduces three hub outings to one while using
the real planner. This is an offline algorithm result, not a measured Forever
speed gain. Full route XP/travel validation remains pending. See
[route design and evidence](Documentation/ROUTE_PLANNING.md).

For a real test, run **`/fxp run start`**, play normally and use **`/fxp run report`**
at a confusing recommendation or gap. **`/fxp run stop`** retains the report. It
records measured XP changes, unique turn-ins, observed zone/task changes and waits
locally, without uploading anything. Unknown XP intervals remain unknown. See
[run report instructions](Documentation/RUN_REPORTS.md).

## Quest tips and difficulty warnings

Version **0.7.1-dev** adds a persistent warning caption to the task card, with
reasons and practical tips below the current instruction. It flags quests 2–3
levels above you, with stronger warnings at 4+, plus known elite targets/loot
leads, escorts, scripted events and close quarters. Available live quest tags can
also warn about elite/group, dungeon, raid and PvP work outside the reference pool.
Live quest levels take precedence; reference hazards are labeled as reference.

Right-click → **Quest tips & warnings** to switch either feature independently.
Combat warnings disappear when objectives are complete or you are turning in.
Advice never completes, skips or defers a quest. Unknown information stays unknown;
these are practical cautions rather than a prediction of solo success.

The reference metadata covers 1,159 distinct quests, with generic guidance for
known objective types and 17 individually authored quest notes. See
[advice coverage and evidence](Documentation/QUEST_ADVICE.md) and
[warning previews](Documentation/Previews/README.md#quest-tips-and-warnings).

## Navigation

The navigation strip shows a rotating direction arrow and **straight-line yards**
when the client supplies map identity, position, facing and world geometry. It
uses optional HereBeDragons-2.0 if installed, otherwise guarded `C_Map` reads.
No external navigation addon is required. Unsupported or ambiguous maps retain
zone/coordinate guidance; unavailable facing retains cardinal guidance when
possible. No guessed zone dimensions or travel-time estimates are used.

Right-click → Navigation → Show target on world map (or `/fxp map`) opens the
matched map outside combat and draws an addon pin when its canvas is supported.
It never moves your character. Source-inspected API contracts and fallback limits
are in [navigation notes](Documentation/NAVIGATION.md); live verification is pending.

## Profession guides 1–300

Right-click → Choose profession, or `/fxp professions`. The first readable learned
profession is selected when available. Direct selection:

`/fxp profession alchemy` · `blacksmithing` · `enchanting` · `engineering` ·
`leatherworking` · `tailoring` · `cooking` · `first-aid` · `herbalism` · `mining` ·
`skinning` · `fishing`.

The 12 reference guides contain **132 selected crafting recipes and 146 stages**.
They follow observed skill, show rank-training reminders and separately check
recipe knowledge. Learning notes include selected sellers/quest givers and
secondary-profession book/quest gates. Crafting shows a next batch, carried stock,
missing named reagents, known intermediate processing and included missing tools.
Gathering shows resources and broad reference areas; buying stock never implies
a skill increase. Outages preserve the previous plan with a stale label.

Use the menu or `/fxp target 300`, `/fxp batch 5` (1–20), `/fxp recipe next`,
`/fxp mode Farm` (Buy/Hybrid), `/fxp recipes` and `/fxp materials`. Targets,
preferences and last observed skill are kept per character/profession.

Batch counts describe crafts and reference inputs, not guaranteed skill points
or a full 1–300 shopping total. Check recipe color/availability in your client.
No crafting, purchasing, movement, quest interaction or item use is automated.
See [profession evidence](Documentation/Reference/Professions1_300.md).

## Live quest journal and recovery

`/fxp tracking` reports character/log context. `/fxp journal` builds a checklist
from your actual quest log, grouping objectives before turn-ins. Use Other suitable
quest in the menu or `/fxp quests` and `/fxp focus QUEST_ID`. It is a checklist,
with no invented locations or optimized travel claim. It stores up to 100 distinct
quests per character; repeatable cycles are not an indefinitely growing journal.

Elwynn catches up automatically from observed active/completed quests without
marking unknown earlier steps done. `/fxp resume` resynchronizes, and
`/fxp resume undo` restores the previous cursor in review mode. Back pauses
relocation; recovery respects auto-advance and disabled settings. A quest outside
Elwynn cannot be matched to that route; use the journal or faction campaign.

The user has reported successful loading, journal advancement, Elwynn catch-up and
that the 1–20 level-aware change appeared to work. No full playthrough, profession
trace or navigation validation was recorded. The global live-verified profile
remains false. New UI, Horde content and navigation require the
[live test checklist](Documentation/LIVE_TEST_CHECKLIST.md).

## Development

```sh
python3 -m venv /workspace/.foreverxp-tools
/workspace/.foreverxp-tools/bin/pip install -r requirements-dev.txt
/workspace/.foreverxp-tools/bin/python tools/test.py
python3 tools/build_leveling.py --check
python3 tools/build_leveling.py --faction Horde --check
python3 tools/build_professions.py --check
python3 tools/build_quest_advice.py --check
python3 tools/build_route_plan.py --check
/workspace/.foreverxp-tools/bin/python tools/route_benchmark.py --check Documentation/Reference/RouteBatchBenchmark.json
python3 tools/package.py --output downloads/ForeverXP-dev.zip
```

Pinned `lupa` runs actual Lua 5.1 with mocked gameplay APIs; it is not shipped.
No development service or game client is required for offline tests. Packaging
uses the observed manifest interface; it does not certify live compatibility.

`/fxp diagnostics`, `debug`, `auto`, `compact`, `theme`, `scale N`, `opacity N`,
`next`, `back`, `skip` and `select ID` remain available. `/fxp reset` then
`/fxp reset confirm` resets only this character's progression and keeps one backup.
Unknown future save schemas are preserved. Existing route draft/explicit detour
commands remain available; no verified gathering loops are bundled.

See [architecture](ARCHITECTURE.md), [guide format](GUIDE_FORMAT.md),
[profession format](PROFESSION_FORMAT.md), [testing](TESTING.md),
[compatibility](Documentation/COMPATIBILITY.md) and [roadmap](ROADMAP.md).
