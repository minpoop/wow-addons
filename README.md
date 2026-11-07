# ForeverXP

Original, modular leveling and profession guide addon under development for the
WoW Forever server. This repository contains a tested offline foundation, **not
a production release or a verified leveling guide**.

[Download the development addon ZIP](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)
· [Preview images](Documentation/Previews/README.md)

Extract the ZIP's `ForeverXP` folder into `Interface/AddOns`. This package contains
the themed framework and James portrait; it does not include full leveling routes
or verified live quest tracking.

The user reports client version **1.60.70790**. The supplied working
`Questie_Forever.toc` declares **interface 16001** and `LoadSavedVariablesFirst: 1`;
ForeverXP now targets those manifest settings. No live client or verified server
content is available here. [Reference evidence](Documentation/REFERENCE_EVIDENCE.md)
records exactly what was inspected; the gameplay API profile remains unverified.

Implemented: guarded capability probes and provider boundary, event dispatch,
versioned and character-separated saves, conservative recovery from corrupt
saves, slash commands, a movable window with guide/profession/settings views,
guide validation and evidence-based progression, coordinate guidance, authored
profession skill bands and recipe alternatives, recursive material calculation,
Farm/Buy/Hybrid planning, route draft import/recording and consent-based detours. No protected
gameplay actions, purchasing or automatic movement are implemented.

Live quest/inventory/profession tracking, arrows, map pins and verified content
remain pending. The profession view has selection, target and mode controls;
they populate only from registered verified catalogs and normalized providers.

## Field-journal theme

The Silent Hill 2–inspired interface uses original procedural fog bands, muted
gray-green panels, oxidized borders, faded paper text and subtle progress marks.
James Sunderland appears in a persistent portrait panel with his name and short
original field notes kept separate from quest instructions. The bundled portrait
is newly generated fan art; no extracted game art, copied dialogue or music
is bundled. `/fxp theme fog` selects the default; `/fxp theme contrast` increases
contrast. The preference persists between sessions. Live visual testing is pending.

## Development

Use the existing checkout; no additional worktree is needed.

```sh
python3 -m venv /workspace/.foreverxp-tools
/workspace/.foreverxp-tools/bin/pip install -r requirements-dev.txt
/workspace/.foreverxp-tools/bin/python tools/test.py
```

The only development dependency is pinned `lupa`, which runs real Lua 5.1. It is
not shipped with the addon. There are no development services to start.

## Development installation

1. Review [the investigation checklist](Documentation/COMPATIBILITY.md) and the
   remaining API limitations before testing on the reported Forever client.
2. Run `python3 tools/package.py`. This writes `dist/ForeverXP-dev.zip` using
   interface 16001 from the source manifest. An explicit `--interface` override is
   supported for another observed target. Packaging does **not** certify compatibility.
3. Extract the `ForeverXP` folder into the client's `Interface/AddOns` directory.
   Enable only for controlled development testing, then relog or reload UI using
   the target client's supported procedure. Back up existing saved variables first.
4. Verify loading, event signatures, UI calls and persistence in game. Implement
   and verify a client profile before enabling gameplay providers.

The manifest interface comes from the user's working addon, not a version-number
guess. The ZIP is a development build for live loading/visual checks, not a
production guide release. Gameplay providers remain disabled pending evidence.

## Commands (candidate slash API)

`/fxp` or `/foreverxp` toggles the window. Use `/fxp guide`, `professions`,
`settings`, `diagnostics`, `debug`, `auto`, `compact`, `scale 1.1`, or `opacity 0.9`.
Drag the window to move it. Position, scale, opacity and settings are retained.
The Route / Supplies / Options tabs share the field-journal theme.
`/fxp select ID` selects registered verified content, `next` explicitly confirms
a step, `back` reviews a step and pauses auto advancement, and `skip` skips an
optional step. There are currently no shipped guides to select.

Profession commands: `/fxp profession CATALOG`, `/fxp target N`, `/fxp mode Farm`
(or Buy/Hybrid), `/fxp estimate expected` (or conservative/guaranteed),
`/fxp price ITEM N`, and `/fxp materials`. Manual prices use consistent user-chosen
currency units. A failed provider retains the last plan and marks it stale.

`/fxp integration minimal`, `balanced`, or `focused` enables suggestions (at most
1, 3, or all matching routes); `disabled` is the default. These are suggestion
counts, not claims about measured travel time. `/fxp detour start ROUTE confirm`
explicitly starts an installed verified route. `detour next` advances its points;
`detour cancel` restores the main objective. Auto advancement pauses during a
detour. `/fxp record DRAFT` records an observed coordinate through a verified
position provider; drafts are never automatically certified or published.

`/fxp reset` requests a second `/fxp reset confirm` command. Only the current
character's guide/profession progression is reset, retaining one backup. Settings
and other characters are retained. Unknown save schemas are never overwritten.

See [architecture](ARCHITECTURE.md), [guide format](GUIDE_FORMAT.md),
[profession format](PROFESSION_FORMAT.md), [testing](TESTING.md), and
[roadmap](ROADMAP.md) for contracts and remaining work.
