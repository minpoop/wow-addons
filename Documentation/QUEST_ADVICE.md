# Quest tips and difficulty warnings — 0.7.1

The task card shows a worded warning beside the quest phase and colors the left
edge for caution or stronger danger. The caption stays outside the instruction
scroll area. Reasons and practical tips follow the current task inside the card.
Right-click → Quest tips & warnings switches tips and warnings independently;
both default on and persist with account settings. Changing them never changes
quest selection, completion, deferrals, overrides or character progress.

## Difficulty signals

- A quest two or three levels above the observed player level shows caution.
  Four or more levels above shows a stronger warning. The live quest level takes
  precedence; otherwise the step/catalog reference level is explicitly labeled.
  Without an observed player level there is no guessed level warning.
- Optional live C_QuestLog.GetQuestTagInfo identifies elite/group, dungeon, raid
  and PvP tags even for quests outside the installed reference pools. Numeric tag
  IDs avoid matching localized names. Missing, malformed or throwing tag APIs do
  not interrupt quest tracking. isElite is used only when actually supplied.
- Selected reference NPC ranks identify elite targets and elite loot leads. A
  loot-source warning explicitly allows alternative sources; it does not claim
  every possible source is elite or guarantee that a group is required.
- Explicit reference escort objectives, needs-event flags and authored cave notes
  get separate messages. The needs-event flag alone never implies an escort,
  ambush or group requirement. Exploration flags alone do not create event warnings.
- An optional quest without a more specific warning gets a neutral reminder to
  check its requirements. Optional does not mean elite.

Failed quests retain a clear live failure warning. Completed objectives and
turn-in phases suppress combat/terrain warnings and show a recipient/item reminder.
A positively turned-in quest needs no new combat advice. Unknown quests without
usable observations have no invented safety rating. Gear, class, party strength,
current enemies and custom server changes are not measured by these heuristics.

## Tips and source coverage

The advice catalog covers metadata for the **1,159 distinct quests** in the
Alliance/Horde 1–60 pools. It also serves matching quests in Elwynn, the older
1–20 test and live journals. Known collect, kill, explore and delivery objectives
receive general practical guidance. Unknown kinds can remain without a tip.
**17 quests have individually authored notes**, including Hogger, Goldtooth,
Fargodeep/Jasperlode, Burning Blade Medallion, Skull Rock, selected escorts and
Counterattack. There are 61 records with selected elite targets/loot leads,
12 explicit escorts, 34 other event records and five authored cave notes.
These counts overlap and do not mean every quest has a bespoke walkthrough.

QuestAdviceFacts.json in Reference/ records the same pinned Questie Classic source
and four SHA-256 hashes as Alliance1_60Facts.json. Selected objective actors retain
NPC ID/name/rank evidence; ranks 1, 2 and 3 are elite/rare-elite/boss classifications.
The source specialFlags bit 2 means needs-event. Explicit escort objective facts
are recorded separately. Original cave notes and practical tips are authored
reference advice, not observations from Forever. No quest descriptions, wholesale
databases or third-party implementation are bundled.

Live tag contracts were inspected in the working Questie commit
97d7518d5402d185e47b39522a6ea09b8316f0ef: QuestieCompat.lua lines 473–476 and
991–997 return tagID/tagName/isElite from C_QuestLog.GetQuestTagInfo. Numeric tag
semantics are also used in the pinned QuestieDB tag helpers. These are source
contracts; this addition has not run in the live Forever client.

```sh
python3 tools/build_quest_advice.py --check
```

The generator deterministically creates Data/QuestAdvice/Classic.lua from selected
JSON facts. Runtime validation rejects executable, cyclic, invalid or sparse data
without replacing the installed catalog. Advice is a pure view calculation, with
no polling, new gameplay actions or save-schema change.

## Validation

Twelve mocked Lua checks cover catalog validation, level precedence/thresholds,
unknown/loading data, elite source distinctions, live tags, event types, completed
and failed quests, tips, optional API failures, theme contrast, scrolling and
independent settings without progression changes. Three Python tests check pool
coverage, phase-independent reference facts, selected actor evidence, generated
runtime records and deterministic regeneration. Source-rendered previews show
Hogger at two levels and an escort; their character observations are synthetic.

Live follow-up: compare warnings with an actual ordinary quest, an elite/group
quest, an escort and a quest above your level. Complete the objectives, switch to
turn-in, toggle both preferences, relog and compare custom server differences.
Reference classifications remain reference-reviewed until checked in game.
