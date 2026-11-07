# Downloadable development build

[Download ForeverXP-dev.zip](https://github.com/minpoop/wow-addons/blob/main/downloads/ForeverXP-dev.zip?raw=true)

If GitHub shows a file page, choose **Download raw file**. For a private repository,
sign in with an account that has access. Extract the `ForeverXP` folder from the
ZIP into your WoW client's `Interface/AddOns` directory.

This is a development framework targeting Forever interface 16001. It includes
the James portrait and field-journal theme, but no complete leveling guides or
verified live gameplay adapters. See the root README and compatibility checklist.

`SHA256SUMS` records the archive's checksum. To rebuild the tracked download:

```sh
python3 tools/package.py --output downloads/ForeverXP-dev.zip
cd downloads
sha256sum ForeverXP-dev.zip > SHA256SUMS
```
