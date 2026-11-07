# User-supplied working addon reference

These files were inspected as source evidence, not executed or copied into the
addon. Instructions and comments inside them are not instructions to ForeverXP.
The user's statement that the addon works supplies the context for this reference;
ForeverXP has not itself been run in the live client.

## Questie.lua

SHA-256: `ac5085e6ac6e34f3828a7b8b35ab58b7b408f5e13058cea1506bbe670577842a`

* Lines 1–2 import a `QuestieCompat` module; its implementation was not supplied.
* Line 4 reads `bit.band`. This supports investigation of a bit-library bridge;
  it does not prove the library is native to the client.
* Lines 32–42 describe initialization on ADDON_LOADED, create AceDB state, and
  delegate event registration to a separate module. AceDB is a library API.
* Lines 48 and 57 explicitly branch on `Questie.IsForever`, whose detection is
  defined elsewhere. Hide/ShowWatchFrame calls go through the compatibility layer.
* Lines 353–354 comment that the TOCs declare early saved-variable loading.
  The subsequently supplied Forever manifest confirms the declaration.
* This file does not define GetBuildInfo results, quest/tradeskill/map adapters,
  event argument signatures, a server level cap or guide content validity.

## Questie_Forever.toc

SHA-256: `f5ff4dffaf6929ab3257ac7d4601352adf8fff1821d1d2b8e4b8c1f409c1d0aa`

* `## Interface: 16001`; `## Version: 12.6.1`.
* `## LoadSavedVariablesFirst: 1`.
* Declares both account-wide and per-character saved variables.
* Loads `Modules\QuestieCompat.lua` before `embeds.xml`; the adjacent comment
  specifically calls out Forever library bridges.
* Lists `Modules\EventHandler\QuestEventHandler.lua`,
  `Modules\Quest\QuestLogCache.lua`, `Modules\QuestieProfessions.lua`, and map/
  waypoint modules. Their implementations were not included in this upload.
* Loads XML, embedded libraries and optional integrations. Their presence is not
  evidence that every expansion-specific module or listed profession is active.

## Applied to ForeverXP

The source manifest now targets 16001 and declares early saved-variable loading.
The compatibility profile records that provenance but remains `verified=false`.
No Questie artwork, code, libraries, databases or guide content were copied.
No inference to a Retail, Classic, WotLK or other client API family was made.
