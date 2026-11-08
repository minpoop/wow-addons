# Downloadable development build

[Download ForeverXP-dev.zip](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)

If GitHub shows a file page, choose **Download raw file**. For a private repository,
sign in with an account that has access. Extract the `ForeverXP` folder from the
ZIP into your WoW client's `Interface/AddOns` directory.

This is version **0.6.0-dev**, targeting Forever interface 16001. It includes
the portrait-free field-journal themes and a source-inspected live quest journal
(`/fxp journal`), plus the Elwynn route and an expanded **level-aware Alliance 1–60
guide**. Replace the old folder, restart the client and run **`/fxp leveling`**.
It selects among 556 reference quests based on your level and quest state, setting
aside outleveled quests without false completion. `/fxp elwynn` remains the old
area route. The user reports journal advancement and Elwynn catch-up work.
The campaign still needs a live 1–60 playthrough and measured XP validation.
Open `/fxp settings` to pick Silent Hill, Warcraft, Warhammer 40K or High contrast.
Old 1–20 progress/preferences import when you select the expanded guide.
See the root README.

`SHA256SUMS` records the archive's checksum. To rebuild the tracked download:

```sh
python3 tools/package.py --output downloads/ForeverXP-dev.zip
cd downloads
sha256sum ForeverXP-dev.zip > SHA256SUMS
```

Version 0.6 adds 12 Classic profession guides from 1–300 with skill, recipe and
carried-material tracking. Open **Professions** or `/fxp professions`; choose a
guide or run `/fxp profession alchemy` (other profession names work too).
`/fxp target 300`, `/fxp batch 5`, `/fxp recipes` and `/fxp materials` control and
inspect the selected guide. Crafting skill-ups vary; next-batch reference inputs
are separate from a promised 1–300 material total. Live profession testing is pending.
