-- Class quests. Each block is injected into every guide whose level range covers it
-- (right after the guide's first trainer stop) and only shows for that class.
-- "anyQuest" = done once you have any one of the listed quests (names differ by race/start);
-- the follow-up turn-in step waits until the whole chain is handed in. Quest names the
-- game doesn't have are skipped automatically, so race variants can share one block.
local ADDON, ns = ...

ns.ClassQuests = {
  -- HUNTER --------------------------------------------------------------
  { class = { "HUNTER" }, level = 10, steps = {
    { anyQuest = { "Taming the Beast#1" },
      text = "Level 10 pet quest: talk to your hunter trainer (Kharanos / Dolanaar / your racial trainer)." },
    { turnin = { "Taming the Beast#1", "Taming the Beast#2", "Taming the Beast#3", "Training the Beast" },
      optional = true,
      text = "Use the Taming Rod on the three beasts the quests name, then finish Training the Beast in your capital.",
      tip = "Stand at max range while taming - the beast attacks you during the cast." },
  } },

  -- WARLOCK -------------------------------------------------------------
  { class = { "WARLOCK" }, level = 10, steps = {
    { anyQuest = { "Gakin's Summons", "Surena Caledon", "The Binding" },
      text = "Voidwalker: Gakin the Darkbinder, the Slaughtered Lamb in Stormwind's Mage Quarter." },
    { turnin = { "Gakin's Summons", "Surena Caledon", "The Binding" }, optional = true,
      text = "Kill the target for the item, then summon and defeat the voidwalker at the Slaughtered Lamb's summoning circle.",
      warn = "The voidwalker you summon hits hard.", tip = "Fight it at full health and mana with your imp out." },
  } },
  { class = { "WARLOCK" }, level = 20, steps = {
    { anyQuest = { "Devourer of Souls" },
      text = "Succubus: speak to Gakin in Stormwind." },
    { turnin = { "Devourer of Souls" }, optional = true, text = "Finish the succubus chain." },
  } },
  { class = { "WARLOCK" }, level = 30, steps = {
    { anyQuest = { "The Stolen Tome", "Tome of the Cabal" },
      text = "Felhunter: Gakin in Stormwind starts the level 30 felhunter chain." },
    { turnin = { "The Stolen Tome", "Tome of the Cabal" }, optional = true, text = "Finish the felhunter chain." },
  } },

  -- DRUID ---------------------------------------------------------------
  { class = { "DRUID" }, level = 10, steps = {
    { anyQuest = { "Heeding the Call" },
      text = "Bear Form: Mathrengyl Bearwalker in Darnassus (Cenarion Enclave) sends you to Moonglade." },
    { turnin = { "Heeding the Call", "Moonglade", "Great Bear Spirit", "Back to Darnassus", "Body and Heart" }, optional = true,
      text = "Talk to the Great Bear Spirit in Moonglade, then finish Body and Heart at the Cliffspring moonkin stone in Darkshore." },
  } },
  { class = { "DRUID" }, level = 16, steps = {
    { anyQuest = { "Aquatic Form", "Trial of the Sea Lion" },
      text = "Aquatic Form: Mathrengyl Bearwalker in Darnassus." },
    { turnin = { "Trial of the Sea Lion", "Aquatic Form" }, optional = true,
      text = "Collect the pendant halves (Rut'theran waters, Bay of Storms in Azshara/Darkshore coast)." },
  } },

  -- PALADIN -------------------------------------------------------------
  { class = { "PALADIN" }, level = 12, steps = {
    { anyQuest = { "The Tome of Divinity#1" },
      text = "Redemption: the Tome of Divinity from your paladin trainer (Stormwind Cathedral or Ironforge)." },
    { turnin = { "The Tome of Divinity#1", "The Tome of Divinity#2", "The Tome of Divinity#3", "The Tome of Divinity#4" }, optional = true,
      text = "Finish the Tome of Divinity chain to learn Redemption." },
  } },
  { class = { "PALADIN" }, level = 20, steps = {
    { anyQuest = { "The Tome of Valor#1" },
      text = "Verigan's Fist: The Tome of Valor from your trainer (Westfall escort, then Wetlands)." },
    { turnin = { "The Tome of Valor#1", "The Tome of Valor#2", "The Test of Righteousness", "The Hammer May Fall" }, optional = true,
      text = "Daphne Stilwell's escort in Westfall, then the Wetlands chain.",
      warn = "Daphne's escort has three waves of Defias.", tip = "Let Daphne tank the first mob of each wave and AoE heal." },
  } },

  -- WARRIOR -------------------------------------------------------------
  { class = { "WARRIOR" }, level = 10, steps = {
    { anyQuest = { "A Warrior's Training", "Bartleby the Drunk", "Elanaria", "Vorlus Vilehoof" },
      text = "Defensive Stance: talk to your warrior trainer for the level 10 quest." },
    { turnin = { "Bartleby the Drunk", "Beat Bartleby", "Bartleby's Mug", "Vorlus Vilehoof" }, optional = true,
      text = "Finish the Defensive Stance chain." },
  } },
  { class = { "WARRIOR" }, level = 30, steps = {
    { anyQuest = { "The Islander", "The Affray", "The Windwatcher" },
      text = "Berserker Stance: Klannoc Macleod on Fray Island (Barrens, near Ratchet)." },
    { turnin = { "The Affray", "The Windwatcher" }, optional = true,
      text = "Win the Affray on Fray Island, then defeat Cyclonian for the Windwatcher.",
      warn = "The Affray is a timed gauntlet of four challengers plus Big Will.", tip = "Pop every cooldown on Big Will." },
  } },

  -- ROGUE ---------------------------------------------------------------
  { class = { "ROGUE" }, level = 16, steps = {
    { anyQuest = { "Mathias and the Defias", "Klaven's Tower" },
      text = "Rogue chain from your trainer (Westfall / Stormwind)." },
    { turnin = { "Mathias and the Defias", "Klaven's Tower" }, optional = true, text = "Finish the chain in Westfall." },
  } },
  { class = { "ROGUE" }, level = 20, steps = {
    { anyQuest = { "The Touch of Zanzil" },
      text = "Poisons: speak to your rogue trainer for the level 20 poisons quest." },
    { turnin = { "The Touch of Zanzil" }, optional = true, text = "Finish the poisons quest to learn Poisons." },
  } },

  -- SHAMAN (Dwarf Shamans are new in WoW Forever - names may differ) --------
  { class = { "SHAMAN" }, level = 4, steps = {
    { anyQuest = { "Call of Earth#1" }, text = "Earth Totem: ask your shaman trainer for the totem quest." },
    { turnin = { "Call of Earth#1", "Call of Earth#2", "Call of Earth#3" }, optional = true, text = "Finish Call of Earth." },
  } },
  { class = { "SHAMAN" }, level = 10, steps = {
    { anyQuest = { "Call of Fire#1" }, text = "Fire Totem: ask your shaman trainer." },
    { turnin = { "Call of Fire#1", "Call of Fire#2", "Call of Fire#3", "Call of Fire#4" }, optional = true, text = "Finish Call of Fire." },
  } },
  { class = { "SHAMAN" }, level = 20, steps = {
    { anyQuest = { "Call of Water#1" }, text = "Water Totem: ask your shaman trainer." },
    { turnin = { "Call of Water#1", "Call of Water#2", "Call of Water#3", "Call of Water#4" }, optional = true, text = "Finish Call of Water." },
  } },
  { class = { "SHAMAN" }, level = 30, steps = {
    { anyQuest = { "Call of Air" }, text = "Air Totem: ask your shaman trainer." },
    { turnin = { "Call of Air" }, optional = true, text = "Finish Call of Air." },
  } },
}
