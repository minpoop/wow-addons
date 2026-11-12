-- Alliance-usable flight paths by zone, for "you haven't got this flight path yet" reminders.
-- Names are the part of the flight master's node name before the comma ("Sentinel Hill, Westfall").
-- WoW Forever's new zones (Farholde Keep in The Riverglades, ...) are added from guide `fp` steps instead,
-- since their flight paths aren't published yet.
local ADDON, ns = ...

ns.FlightPoints = {
  ["Elwynn Forest"] = { "Stormwind" },           -- the flight master stands in Stormwind's Trade District
  ["Stormwind City"] = { "Stormwind" },
  ["Dun Morogh"] = { "Ironforge" },
  ["Ironforge"] = { "Ironforge" },
  ["Westfall"] = { "Sentinel Hill" },
  ["Loch Modan"] = { "Thelsamar" },
  ["Redridge Mountains"] = { "Lakeshire" },
  ["Duskwood"] = { "Darkshire" },
  ["Wetlands"] = { "Menethil Harbor" },
  ["Hillsbrad Foothills"] = { "Southshore" },
  ["Arathi Highlands"] = { "Refuge Pointe" },
  ["The Hinterlands"] = { "Aerie Peak" },
  ["Stranglethorn Vale"] = { "Rebel Camp", "Booty Bay" },
  ["Searing Gorge"] = { "Thorium Point" },
  ["Burning Steppes"] = { "Morgan's Vigil" },
  ["Blasted Lands"] = { "Nethergarde Keep" },
  ["Western Plaguelands"] = { "Chillwind Camp" },
  ["Eastern Plaguelands"] = { "Light's Hope Chapel" },
  ["Teldrassil"] = { "Rut'theran Village" },
  ["Darnassus"] = { "Rut'theran Village" },
  ["Darkshore"] = { "Auberdine" },
  ["Ashenvale"] = { "Astranaar" },
  ["Stonetalon Mountains"] = { "Stonetalon Peak" },
  ["Desolace"] = { "Nijel's Point" },
  ["Dustwallow Marsh"] = { "Theramore" },
  ["The Barrens"] = { "Ratchet" },
  ["Feralas"] = { "Feathermoon", "Thalanaar" },
  ["Tanaris"] = { "Gadgetzan" },
  ["Un'Goro Crater"] = { "Marshal's Refuge" },
  ["Felwood"] = { "Emerald Sanctuary", "Talonbranch Glade" },
  ["Winterspring"] = { "Everlook" },
  ["Azshara"] = { "Talrendis Point" },
  ["Silithus"] = { "Cenarion Hold" },
  ["Moonglade"] = { "Moonglade" },
}
