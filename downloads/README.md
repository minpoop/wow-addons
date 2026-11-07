# Downloadable development build

[Download ForeverXP-dev.zip](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)

If GitHub shows a file page, choose **Download raw file**. For a private repository,
sign in with an account that has access. Extract the `ForeverXP` folder from the
ZIP into your WoW client's `Interface/AddOns` directory.

This is a development framework targeting Forever interface 16001. It includes
the James portrait, field-journal theme and a source-inspected live quest journal
(`/fxp journal`), plus a shared Elwynn reference route (`/fxp elwynn`). The user
reports journal advancement works. Elwynn's 34 quests still need live route
validation, and full 1–60 coverage is not included. See the root README.

`SHA256SUMS` records the archive's checksum. To rebuild the tracked download:

```sh
python3 tools/package.py --output downloads/ForeverXP-dev.zip
cd downloads
sha256sum ForeverXP-dev.zip > SHA256SUMS
```
