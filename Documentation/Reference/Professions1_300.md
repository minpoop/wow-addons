# Profession guides 1–300

Version 0.6.0-dev adds 12 original Classic reference guides, 132 selected crafting
recipes and 146 contiguous skill stages. Crafting: Alchemy, Blacksmithing,
Enchanting, Engineering, Leatherworking, Tailoring, Cooking and First Aid.
Gathering: Herbalism, Mining, Skinning and Fishing. Custom server professions,
Jewelcrafting, Inscription, specializations, skill above 300 and dungeon farming
routes are outside this dataset. Enchanting's reference Artisan trainer access
inside Uldaman is called out; this is not a solo-access promise.

Status: **reference-reviewed; new profession tracking and guide progression have
not been validated in the live Forever client**. The user has confirmed addon
loading and leveling behavior previously; that does not certify profession API
contracts or this new content. No broad verified-profile flag is changed.

## Use and behavior

Open Professions or /fxp professions; choose a guide, or use /fxp profession NAME.
Skill, rank cap where observed, known recipe state and carried materials drive the
panel. Mid-profession characters enter the matching stage automatically. Rank
reminders include the secondary-profession books/quests and Annora in Uldaman.
Seller/quest source notes are selected factual leads; limited stock, prerequisites
and server changes still need checking.

The default target is 300, independently saved for each profession and character.
Crafting batches default to 5 and can be changed from 1–20. The current stage and
selected target bound the next batch; this does not assume that each craft grants
a point. If a craft gives no skill, the stage stays put. No consumed reagents,
crafted item count, elapsed time or purchase is used as evidence of skill gain.
When positively observed rank cap is reached, the guide requests training.

Next-batch material requirements use the selected recipe's reference quantities.
Owned intermediates are used once. Explicit known fixed-output processing recipes
can produce bolts/components; missing included tools can be prepared first. Unknown
knowledge never becomes known by inference. Unknown carried counts remain unknown.
API failures preserve the prior plan with a stale label. Reference recipes may
differ on Forever; check live reagent requirements and recipe color before crafting.
Full 1–300 quantities, exact skill-up rates, cheapest cost and guaranteed craft
counts are not claimed. Legacy probability planning remains separate.

Gathering stages give broad authored areas and resources with carried-item counts.
They provide no surveyed spawn loops, guaranteed nodes, overlays, automated travel
or measured rates. Fishing can continue in easier water and uses actual skill,
not a fixed catch total. Gathering modes cannot increase skill by buying resources.

## Client evidence

The supplied working Questie manifest pins commit
97d7518d5402d185e47b39522a6ea09b8316f0ef. Its QuestieCompat and QuestieProfessions
modules were inspected for C_SkillInfo.GetNumSkillLines/GetSkillLineInfo
(name/isHeader/rank/skillID), legacy skill-line tuples, guarded header expansion,
C_SpellBook.IsSpellKnown/IsPlayerSpell and the profession/rank spell IDs. The same
commit's event handler registers CHAT_MSG_SKILL, SKILL_LINES_CHANGED and
NEW_RECIPE_LEARNED. The adapter ignores chat contents and uses the existing
coalesced ForeverAdapter refresh queue. Existing bag/world events refresh stock.
There is no per-frame polling or craft automation.

ProfessionAdapter gates every read on interface 16001 and loaded-world state.
Modern skill IDs work independently of the localized display name; legacy fallback
matches the English profession names. Missing or unsupported APIs stay unknown.
Collapsed skill headers can be expanded through the inspected API before reading;
this is a reversible Skills-window presentation change. The adapter never spends
money, casts, accepts quests, crafts or abandons a profession. Bank inventory is
excluded. A partial/unreadable item scan leaves stock unknown while readable skill
can still update.

## Reference facts

Selected factual recipes, reagent counts, spell outputs, tool IDs and recipe-item
minimum skills came from:

- [cmangos/classic-db at c33f90b8eeb3f8bacb53d5cbfee45075c80b416c](https://github.com/cmangos/classic-db/tree/c33f90b8eeb3f8bacb53d5cbfee45075c80b416c),
  Full_DB/ClassicDB_1_12_1_z2815.sql.gz, spell_template/npc_trainer/
  npc_trainer_template/item_template records. The archive SHA-256 is
  `4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0`.
- [Questie v10.10.3 reference commit 13a0430455d068e5889949a505bb02e0b92bf5fc](https://github.com/Questie/Questie/tree/13a0430455d068e5889949a505bb02e0b92bf5fc),
  selected item names, recipe-item vendor/reward links and NPC learning-source
  identities. Item DB SHA-256: `987d037b6df94d5b0b1dc326a1670581e3abb952736a4ae055fd9f161328b71c`;
  NPC DB SHA-256: `e45ae223597c5c38d629617a50efca81e46a7c8d3588b33f6875f3d3fec1c4ed`.

Only selected facts are retained in Professions1_300Facts.json. A literal SQL/Lua
parser was used during authoring; downloaded source was not executed. No third-party
guide text, implementation or wholesale database is bundled. Stage boundaries,
resource-area suggestions and instructions are original authoring, not measured
server skill-up curves. Initial profession recipes use an authored minimum of 1;
other selected recipe minima come from trainer or learning-item records.
Recipes requiring purchased books/plans/formulas remain gated by actual knowledge.

The deterministic offline builder is tools/build_professions.py. Run it normally
to regenerate Data/ProfessionGuides/Classic.lua or with --check to verify it.
The addon ZIP includes generated guide data and its runtime, not the source SQL
archive, reference JSON or development dependencies.

## Validation and next live checks

The suite passes 115 Lua behavioral checks and 11 Python tests. Profession cases
exercise all 12 guides at every skill 1–299, source API variants, localization by
ID, collapsed headers, actual skill jumps, absence of inferred skill gains,
knowledge/cap detection, rods, intermediates, carried counts, secondary training
gates, unlearning/unknown data, outages, persistence, corrupt future saves, controls,
coalesced events and interface gating. Python checks cross-check every generated
recipe/stage against the selected facts and deterministic output; package tests
require both new modules and the guide data. These are mocks/reference checks,
not a live 1–300 playthrough.

Install and select one learned profession. Confirm displayed skill against Skills,
check recipe knowledge and rank, then craft or gather normally. Verify a failed
skill-up does not advance, an actual skill-up updates, bag counts change, caps
request training, and preferences survive relog. Repeat for a crafting, gathering
and secondary profession before testing all 1–300 stages. Report the profession,
actual skill and displayed recipe if Forever differs from the reference.
