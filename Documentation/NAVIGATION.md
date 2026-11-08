# Navigation — 0.7 development implementation

Navigation.lua reads map geometry independently from quest/profession scans. It
checks runtime interface 16001, loading state and each optional API. A coalesced
0.2-second timer (configurable/clamped 0.1–2 seconds) updates only while a guide is
visible or an explicitly requested pin's world map is visible. There is no
per-frame handler. Hidden/loading views stop scheduling navigation work.

## Evidence and optional integrations

The working Questie manifest's commit is
[97d7518d5402d185e47b39522a6ea09b8316f0ef](https://github.com/Questie/Questie/tree/97d7518d5402d185e47b39522a6ea09b8316f0ef).
Its `Libs/HereBeDragons/HereBeDragons-2.0.lua` was read as source evidence for
player map position, map dimensions, world coordinate axes, facing and optional
library methods. Its `Modules/QuestieCompat.lua` lines 301–318 document
`C_Map.OpenWorldMap`, combat guarding and the taint risk of directly calling
`WorldMapFrame:SetMapID`. No downloaded implementation or library is bundled.
This inspection does not prove the user's runtime exposes every API.

The implementation tries optional HereBeDragons-2.0 via LibStub when available;
otherwise it uses guarded `C_Map.GetBestMapForUnit`, `GetPlayerMapPosition`,
`GetWorldPosFromMapPos`/`CreateVector2D` or `GetMapWorldSize`. `GetMapInfo`, optional
`GetMapChildrenInfo`, ancestors and optional library map names resolve authored
zone names to actual map IDs. It never hardcodes zone IDs. Ambiguous/unmatched
names, including localization mismatches, keep coordinates without inventing a
map identity.

## Geometry and fallbacks

Player and target must share a known world instance for cross-map vectors.
Native C_Map world axes are converted to east/north; HBD's west/north axes are
handled separately. Same-map normalized coordinates are scaled only by dimensions
reported in yards. `GetPlayerFacing` is counterclockwise from north; the up-facing
arrow rotates relative to that heading. Tests cover all cardinal vectors and
representative rotations. No guessed map sizes are used.

- Known geometry and facing: rotating arrow and **straight-line** yard distance.
- Known geometry without facing/rotation support: cardinal direction and distance.
- Unknown position/scale/map or API error: zone and target coordinates.
- Loading or unsupported interface: clear previous direction and keep coordinates.

A straight-line vector is not a traversable path. Terrain, doors, floors,
transport and intercontinental travel are not solved, and there is no ETA.
Reference coordinates retain their source label; navigation does not certify them.

## World-map target

Right-click → Navigation → Show target on world map, or `/fxp map`, explicitly
requests safe map opening. It requires known map identity, a readable false
`InCombatLockdown()` and `C_Map.OpenWorldMap`; unsupported cases return a useful
fallback message. It never calls SetMapID, hooks protected map functions, or moves
the character. A private addon frame marks the target only on the matched
`WorldMapFrame.ScrollContainer.Child` canvas. Other maps hide it. Zoom changes use
the canvas's actual dimensions. Canvas absence suppresses the pin.

## Validation

Nine mocked Lua scenarios cover vectors, real reported dimensions, cross-map
instances, missing/throwing APIs, name ambiguity, combat-safe opening/pins,
optional HBD, timer coalescing and loading/interface gating. Source-rendered
arrow previews use synthetic vectors. No navigation, map canvas, combat/taint,
rotation or distance test has run inside the live client. Follow
[LIVE_TEST_CHECKLIST.md](LIVE_TEST_CHECKLIST.md) before promoting verification.
