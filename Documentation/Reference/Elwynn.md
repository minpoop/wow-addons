# Elwynn Forest — shared reference route

Version 0.3 adds **34 distinct quests and 113 guide steps**, with an original
ordering and newly written instructions. Start with `/fxp elwynn`. This is an
Alliance common route intended for roughly levels 1–10, with no class filter.
Class-specific letters, training quests and ability recommendations are excluded;
trainer visits are optional manual reminders. No fixed XP yield is assumed.

**Status: reference-reviewed, not live-verified on Forever.** The user confirmed
that the earlier live journal progresses in game; this does not validate this
new route. Server quest availability, chains, coordinates and difficulty remain
to be checked. The route has no automatic travel or automatic quest interaction.
It is not automatically recommended as a verified guide.

## Sources

Curated facts came from the published Questie v10.10.3 reference commit
[`13a0430455d068e5889949a505bb02e0b92bf5fc`](https://github.com/Questie/Questie/tree/13a0430455d068e5889949a505bb02e0b92bf5fc).
Only quest titles/IDs, eligibility/prerequisites, giver identities and selected
giver/object coordinates are recorded in ElwynnFacts.json. No guide ordering,
instruction text, implementation code, quest descriptions or wholesale database
was imported. The route's ordering and instructions are original.

| Reference file | SHA-256 |
| --- | --- |
| Database/Classic/classicQuestDB.lua | `a822801c772a8e11d3c6bb194960bd0fea86529ed9f63eb0d4e637fe54c9bf22` |
| Database/Classic/classicNpcDB.lua | `e45ae223597c5c38d629617a50efca81e46a7c8d3588b33f6875f3d3fec1c4ed` |
| Database/Classic/classicObjectDB.lua | `d08fbd8216757918330d9ff02bfc1b13f837f198e0aa62aa76260bb1bd9cd042` |

All 34 selected quest records have no requiredClasses mask. Their Classic race
mask is Alliance (77); this does not establish availability for every custom
Forever race. Coordinates are points in Classic Elwynn area 12, divided by 100
for the normalized format. They are labeled reference coordinates, without
claiming that Forever's map IDs or terrain match.

## Route sections

| Section | Included work |
| --- | --- |
| Northshire | A Threat Within, Eagan/wolf and kobold chains, Brotherhood of Thieves, Milly/Grape Manifest, Garrick, Report to Goldshire |
| Goldshire / farms | Fargodeep, Kobold Candles, Gold Dust Exchange, Lost Necklace → Pie for Billy → Back to Billy → Goldtooth |
| Optional farm encounter | Princess Must Die! — three optional quest steps |
| Jasperlode / eastern forest | Jasperlode, Fishy Peril → Further Concerns, frontier and murlocs, missing guards/Rolf, Red Linen Goods, return report |
| Optional Eastvale delivery | Cloth and Leather Armor — three optional quest steps |
| Westbrook | Garrison introduction and Riverpaw Gnoll Bounty |
| Optional bounty | Wanted: "Hogger" — three optional steps, no solo safety claim |

Finish current objectives before returning when the route batches them. Delivery
quests may require talking to the named recipient before the completion API
updates. Use Next to explicitly confirm an instruction only when appropriate.
Optional encounters can be skipped one step at a time with `/fxp skip`.

## Validation and next live checks

Offline tests verify schema, all backward prerequisite references, progression
through every step, optional skips, and matching curated facts for every quest,
minimum level and giver coordinate. These tests do not establish server validity.

On Forever, begin in Northshire with A Threat Within. Verify the accept and
turn-in names/locations, then Kobold Camp Cleanup and the wolf quest branch. If a
step differs, report its step number, quest name, and what the client offers.
Next validate each section in order before upgrading any verification label.
Level 10 completion, XP rates, optimal travel times and full 1–60 coverage are
not claimed. Missing end-to-end evidence keeps the route reference-reviewed.
