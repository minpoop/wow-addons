# Downloadable development build

[Download ForeverXP-dev.zip](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)

If GitHub shows a file page, choose **Download raw file**. For a private repository,
sign in with an account that has access. Extract the `ForeverXP` folder from the
ZIP into your WoW client's `Interface/AddOns` directory.

This is version **0.4.0-dev**, targeting Forever interface 16001. It includes
the James portrait, field-journal theme and a source-inspected live quest journal
(`/fxp journal`), plus the Elwynn route and a new **level-aware Alliance 1–20
playtest**. Replace the old folder, restart the client and run **`/fxp leveling`**.
It selects among 97 reference quests based on your level and quest state, setting
aside outleveled quests without false completion. `/fxp elwynn` remains the old
area route. The user reports journal advancement and Elwynn catch-up work.
The new campaign needs a live 1–20 playthrough; no measured XP guarantee or full
1–60 coverage is included. See the root README.

`SHA256SUMS` records the archive's checksum. To rebuild the tracked download:

```sh
python3 tools/package.py --output downloads/ForeverXP-dev.zip
cd downloads
sha256sum ForeverXP-dev.zip > SHA256SUMS
```
