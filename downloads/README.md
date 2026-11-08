# Downloadable development build

[Download ForeverXP 0.7.1-dev](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)

If GitHub shows a file page, choose **Download raw file**. For a private repository,
sign in with an account that has access. Replace the old `ForeverXP` folder in
`Interface/AddOns` with the ZIP's folder, then restart the client.

Run **`/fxp leveling`** for your observed faction's 1–60 reference guide. Alliance
has 556 reference quests and Horde has 821, with race-aware Horde starts. Existing
quest/profession progress is retained. Twelve profession guides cover skill 1–300
with observed skill, recipe and carried-material tracking.

**Right-click the window for its dropdown menu. Drag the lower-right corner to
resize.** Size and position persist per character. Theme, text size, lock, compact
spacing, guide selection, profession controls and navigation live in the menu.
`/fxp menu` opens it; `/fxp size 620 420` restores standard dimensions; `/fxp`
reopens a hidden window. The portrait remains removed.

Navigation shows direction and straight-line yards only when supported map data
is available, with coordinate fallback. The map command opens a matched target
map outside combat and adds a pin on supported canvases. This source-inspected
feature needs live validation, as do Horde content, professions and the full
1–60 XP path. See the root README and live test checklist.

Target interface is **16001** from the working reference manifest. This is a
development build, not a live-verified production release. `SHA256SUMS` records
the ZIP checksum. Rebuild with:

```sh
python3 tools/package.py --output downloads/ForeverXP-dev.zip
cd downloads
sha256sum ForeverXP-dev.zip > SHA256SUMS
```


Version 0.7.1 adds quest tips and difficulty warnings. Reference elite targets,
elite loot leads, escorts/events and selected cave notes are labeled clearly;
level warnings prefer actual quest levels. Live quest tags are optional. The
right-click Quest tips & warnings submenu controls each feature independently.
Warnings never mark a quest complete or change your selected work. Check reference
hazards against your actual client and target before relying on them.
