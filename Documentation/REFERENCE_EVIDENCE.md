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
No Questie artwork, implementation, libraries, complete databases or guide prose is bundled. Later reference guides use selected factual records with separate provenance below.
No inference to a Retail, Classic, WotLK or other client API family was made.

## Subsequent upstream source inspection

The user later confirmed the development addon loads in the live client. This
is a startup report only; gameplay support remains unverified by live tests.

The reference's build commit was resolvable in the upstream
[Questie repository](https://github.com/Questie/Questie/tree/97d7518d5402d185e47b39522a6ea09b8316f0ef).
The following files were read, not executed or bundled:

| File | SHA-256 |
| --- | --- |
| Modules/QuestieCompat.lua | `de79383e1f3e7dc717fd4eb6ca8429adf11a24c02ee94566479934c65bd3a4d8` |
| Modules/EventHandler/EventHandler.lua | `32f6042835abfa04b880a0f8c73dac97501e53b9aaf959c781c03b594bf33e60` |
| Modules/Quest/QuestLogCache.lua | `dcc37c7b8f38a4e02c3955ad9601c49a8b4755c2eaaf712313d0ede76d66d284` |

Also inspected QuestEventHandler.lua, QuestieProfessions.lua and the upstream
FOREVER_WORK_LEFT_TO_DO.md for contract caveats. These references describe
source-inspected builds, not proof of validation on the user's current build.

Findings used in the original ForeverXP adapter:

* QuestieCompat lines 448–497: C_QuestLog.GetNumQuestLogEntries/GetInfo enumerate
  records containing questID, title and isHeader; IsComplete/IsFailed are queried
  with a quest ID.
* Lines 606–608: IsQuestFlaggedCompleted is a history flag, separate from current
  objective completion. Existing repeatable history cannot prove a new turn-in.
* Lines 712–724: C_Item.GetItemCount (legacy global fallback) accepts item ID and
  bank/charge/reagent-bank flags.
* EventHandler lines 161–168: Forever QUEST_ACCEPTED supplies only the quest ID.
  Lines 197–200 register removal, turn-in (quest ID first), and log updates.
* QuestLogCache lines 103–139 use C_QuestLog.GetQuestObjectives with text, type,
  numFulfilled, numRequired and finished fields; empty/unloaded rows are unsafe
  completion evidence. ForeverXP displays validated rows and relies on the
  explicit completion API, never all-empty/all-finished inference.
* QuestEventHandler lines 453–461 document late/missing turn-in events. ForeverXP
  accepts explicit events or a newly positive history flag, preserving uncertainty
  when a repeatable's previous flag was already positive or unreadable.
* QuestieCompat lines 860–873 read C_SuperTrack.GetSuperTrackedQuestID; lines
  520–524 read C_QuestLog.GetSelectedQuest. EventHandler lines 205–206 register
  SUPER_TRACKING_CHANGED. Version 0.3.1 reads these optional getters without
  calling their setters, validates IDs against the actual active log, and isolates
  getter errors so optional focus cannot invalidate the entire quest snapshot.

No reference instructions, source implementation or assets were incorporated.
Version 0.2 added an independent read-only adapter and observed quest checklist.
Version 0.3 adds an original Elwynn route using curated factual quest records from
a separately pinned Classic source; see Reference/Elwynn.md. No wholesale
database or guide text is bundled. No protected quest interaction is performed.

## Profession guide implementation (0.6)

The previously pinned working Questie source supplies skill-line fields
name/isHeader/rank/skillID, skill/header enumeration/expansion, C_SpellBook knowledge
and IsPlayerSpell fallback, profession/rank spell IDs and skill/recipe event names.
Selected recipe facts additionally use pinned cmangos/classic-db revision
c33f90b8eeb3f8bacb53d5cbfee45075c80b416c. Its SQL literals were parsed as data;
no downloaded implementation was executed or copied. Exact archive/item/NPC hashes,
selected facts and remaining live-validation work are recorded in
Reference/Professions1_300.md. These references do not certify Forever behavior.


## Navigation and Horde expansion (0.7)

Read, without executing or bundling, the working reference commit's
[Libs/HereBeDragons/HereBeDragons-2.0.lua](https://github.com/Questie/Questie/blob/97d7518d5402d185e47b39522a6ea09b8316f0ef/Libs/HereBeDragons/HereBeDragons-2.0.lua).
This supplies contracts for optional library map IDs/names/player position and
world conversion, native world coordinate axes, reported map dimensions and
facing. QuestieCompat lines 301–318 specify safe C_Map.OpenWorldMap use and warn
about SetMapID taint. ForeverXP uses its own implementation and guarded runtime
capabilities, with no copied library or native-map mutation. Additional optional
C_Map map discovery/canvas behavior is runtime-checked and still needs live tests.
See NAVIGATION.md for limits and axis conversions.

Horde facts use the same pinned Classic database revision and four hashes as
Alliance1_60.md. Source literal records were parsed as data; selection, prose,
chapters and planner remain original. Horde1_60.md records race masks, counts,
optional exclusions and unverified server scope. Offline checks do not assert
live API or quest availability.


## Quest tips and warnings (0.7.1)

The same working QuestieCompat source at commit 97d7518d5402d185e47b39522a6ea09b8316f0ef
reads C_QuestLog.GetQuestTagInfo (lines 473–476 and 991–997), including tagID and
optional isElite. ForeverXP reads these in an isolated optional pcall; this does
not assert runtime availability. QuestAdviceFacts.json uses the existing pinned
Classic quest/NPC hashes for selected target ranks and explicit escort/event facts.
Original cave notes/tips and all remaining limitations are in QUEST_ADVICE.md.
No downloaded Lua is executed and no reference implementation is bundled.


## Regional itinerary and playtest counters (0.8)

The itinerary is original authoring over the existing pinned Alliance facts; it
contains no third-party guide text. Optional C_QuestLog.GetMaxNumQuestsCanAccept
is used only if present and returning a valid bounded integer; no capacity is
assumed and no live support is claimed. Optional UnitXP/UnitXPMax/UnitLevel/GetTime
reads and the XP event are guarded runtime probes on the target interface, not
new live-verified contracts. Existing positive quest events/history underpin
turn-in counts. Missing/ambiguous samples remain uncertain. ROUTE_PLANNING.md,
RUN_REPORTS.md and the checked synthetic benchmark distinguish implementation
proof from live travel/XP evidence; no measured Forever speedup is asserted.
