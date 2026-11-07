# Live-client investigation

## Evidence and limits

* User-reported version: **1.60.70790**. This has not been inspected locally.
* Initial accessible workspace/installed-tool searches found no WoW executable or
  Blizzard UI source. The user subsequently supplied a working `Questie.lua` and
  `Questie_Forever.toc`; see REFERENCE_EVIDENCE.md for exact findings and hashes.
* No web research tool or authoritative server documentation was available in
  this session. No client family has been inferred from the version string.
* The working reference manifest declares **interface 16001**,
  `LoadSavedVariablesFirst: 1`, SavedVariables and SavedVariablesPerCharacter.
  ForeverXP uses interface 16001 and the early-save flag, while still initializing
  its database on ADDON_LOADED. It does not require reading saves at file load.
* Exact build, Lua version, event signatures and gameplay API contracts remain
  unverified. Lua 5.1 is the offline language target, not a runtime identity claim.
* The reference loads XML and includes compatibility/library bridges. That
  demonstrates intended usage, not every supported XML element or native API.
* Actual ForeverXP client loading and visual behavior have not been tested here.

## Collect before live installation

1. Capture the remaining results of `GetBuildInfo()` through a supported client command,
   e.g. `/dump GetBuildInfo()` **only if `/dump` exists on that client**. Record
   version, build, date and interface separately. Interface 16001 is already
   evidenced by the working manifest; confirm the running instance agrees.
2. Identify Lua runtime and supported syntax without invoking gameplay actions.
3. Inspect Blizzard UI/frame code for `CreateFrame`, frame methods, font objects,
   texture coloring, `OnEvent` callback arguments, drag callbacks and supported
   XML templates. This addon currently uses Lua-created UI and no XML.
4. Verify addon load name and event order, slash command registration, per-account
   SavedVariables timing, GUID/name/realm identity, logout and UI-reload writes.
5. Inspect quest log API contracts: stable quest IDs, active/completed history,
   objectives and turn-in signals. Verify event ordering, limits, and whether
   server-custom quests behave differently. Quest disappearance is inconclusive.
6. Inspect professions: available professions and caps, learned/available recipes,
   output quantities, reagent IDs, trainers and changing skill-up chances. Check
   tradeskill UI loading and whether recipes can be read while that UI is closed.
7. Inspect map APIs: map/zone IDs, coordinate scale and origin, instance floors,
   player position, facing units, yard conversion, loading screens and map-frame
   hooks. Test safe fallbacks before adding direction or estimated distance.
8. Inspect bag/item APIs and inventory-change events; distinguish unloaded item
   information from absent inventory. Determine whether bank quantities are known.
9. Confirm faction/race/class tokens and level events, actual level cap and any
   server quests/items/zones/professions. Do not infer 1–60 content validity.
10. Verify every optional integration (e.g. TomTom) against its installed version.
    Record unsupported capabilities explicitly. Verify combat/taint restrictions.

## Record the verified profile

Add exact observed version/build/interface, API signatures, event arguments,
evidence source and date to a reviewed profile. Only after this investigation
should it set `Compatibility.profile.verified=true` and register providers. Never
flip the flag solely to remove a warning. Do not run protected actions to test.

Then complete the manual scenarios in TESTING.md. Save sanitized observations,
not account credentials or identifying screenshots. Server content verification
is separate from client API verification; neither implies the other.

The next useful reference is `Modules/QuestieCompat.lua`, followed by the quest
event/log, profession and map modules listed in the supplied manifest. Inspect
them as evidence; do not import Questie code, databases or assets into ForeverXP.
