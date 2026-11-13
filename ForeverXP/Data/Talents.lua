-- Leveling talent builds, one per class: 51 points from level 10 to 60, in the order to take them.
-- Each entry is { "Talent Name", ranks } and means "add this many ranks next". Names are the Classic talent
-- names; Talents.lua looks them up in the live talent tree by name, so a talent WoW Forever renamed or moved is
-- skipped (and listed by /fxp talents) instead of breaking the guide. Tiers unlock every 5 points in a tree;
-- the running totals in the comments are points in that tree after the entry.
-- Original builds written for ForeverXP (common leveling choices: damage and mana efficiency first).
local ADDON, ns = ...

ns.TalentBuilds = {
  WARRIOR = { name = "Arms (two-handed) into Fury", trees = { "Arms", "Fury" }, build = {
    { "Improved Heroic Strike", 3 },        -- Arms 3
    { "Improved Rend", 2 },                 -- 5
    { "Tactical Mastery", 3 },              -- 8
    { "Improved Charge", 2 },               -- 10
    { "Anger Management", 1 },              -- 11
    { "Deep Wounds", 3 },                   -- 14
    { "Improved Overpower", 1 },            -- 15
    { "Two-Handed Weapon Specialization", 5 }, -- 20
    { "Sweeping Strikes", 1 },              -- 21
    { "Sword Specialization", 5 },          -- 26
    { "Impale", 2 },                        -- 28
    { "Improved Hamstring", 2 },            -- 30
    { "Mortal Strike", 1 },                 -- 31
    { "Cruelty", 5 },                       -- Fury 5
    { "Unbridled Wrath", 5 },               -- 10
    { "Improved Battle Shout", 5 },         -- 15
    { "Enrage", 5 },                        -- 20
  } },
  PALADIN = { name = "Retribution, then Holy", trees = { "Retribution", "Holy" }, build = {
    { "Benediction", 5 },                   -- Ret 5
    { "Improved Judgement", 2 },            -- 7
    { "Deflection", 3 },                    -- 10
    { "Seal of Command", 1 },               -- 11
    { "Conviction", 5 },                    -- 16
    { "Vindication", 3 },                   -- 19
    { "Eye for an Eye", 2 },                -- 21
    { "Two-Handed Weapon Specialization", 3 }, -- 24
    { "Sanctity Aura", 1 },                 -- 25
    { "Vengeance", 5 },                     -- 30
    { "Repentance", 1 },                    -- 31
    { "Divine Strength", 5 },               -- Holy 5
    { "Improved Seal of Righteousness", 5 }, -- 10
    { "Consecration", 1 },                  -- 11
    { "Healing Light", 3 },                 -- 14
    { "Divine Intellect", 5 },              -- 19
    { "Unyielding Faith", 1 },              -- 20
  } },
  HUNTER = { name = "Beast Mastery, then Marksmanship", trees = { "Beast Mastery", "Marksmanship" }, build = {
    { "Improved Aspect of the Hawk", 5 },   -- BM 5
    { "Thick Hide", 3 },                    -- 8
    { "Endurance Training", 2 },            -- 10
    { "Unleashed Fury", 5 },                -- 15
    { "Ferocity", 5 },                      -- 20
    { "Bestial Discipline", 2 },            -- 22
    { "Spirit Bond", 2 },                   -- 24
    { "Intimidation", 1 },                  -- 25
    { "Frenzy", 5 },                        -- 30
    { "Bestial Wrath", 1 },                 -- 31
    { "Efficiency", 5 },                    -- MM 5
    { "Lethal Shots", 5 },                  -- 10
    { "Aimed Shot", 1 },                    -- 11
    { "Hawk Eye", 3 },                      -- 14
    { "Improved Arcane Shot", 1 },          -- 15
    { "Mortal Shots", 5 },                  -- 20
  } },
  ROGUE = { name = "Combat (swords), then Assassination", trees = { "Combat", "Assassination" }, build = {
    { "Improved Sinister Strike", 2 },      -- Combat 2
    { "Lightning Reflexes", 3 },            -- 5
    { "Precision", 5 },                     -- 10
    { "Endurance", 2 },                     -- 12
    { "Deflection", 3 },                    -- 15
    { "Dual Wield Specialization", 5 },     -- 20
    { "Blade Flurry", 1 },                  -- 21
    { "Sword Specialization", 5 },          -- 26
    { "Weapon Expertise", 2 },              -- 28
    { "Aggression", 2 },                    -- 30
    { "Adrenaline Rush", 1 },               -- 31
    { "Malice", 5 },                        -- Assassination 5
    { "Murder", 2 },                        -- 7
    { "Ruthlessness", 3 },                  -- 10
    { "Relentless Strikes", 1 },            -- 11
    { "Lethality", 5 },                     -- 16
    { "Improved Eviscerate", 3 },           -- 19
    { "Remorseless Attacks", 1 },           -- 20
  } },
  PRIEST = { name = "Shadow (wand and Spirit Tap first), then Discipline", trees = { "Discipline", "Shadow" }, build = {
    { "Wand Specialization", 5 },           -- Disc 5
    { "Spirit Tap", 5 },                    -- Shadow 5
    { "Improved Shadow Word: Pain", 2 },    -- 7
    { "Shadow Focus", 3 },                  -- 10
    { "Mind Flay", 1 },                     -- 11
    { "Improved Mind Blast", 4 },           -- 15
    { "Shadow Reach", 3 },                  -- 18
    { "Shadow Weaving", 5 },                -- 23
    { "Vampiric Embrace", 1 },              -- 24
    { "Blackout", 1 },                      -- 25
    { "Darkness", 5 },                      -- 30
    { "Shadowform", 1 },                    -- 31
    { "Improved Power Word: Shield", 3 },   -- Disc 8
    { "Improved Power Word: Fortitude", 2 }, -- 10
    { "Meditation", 3 },                    -- 13
    { "Inner Focus", 1 },                   -- 14
    { "Martyrdom", 1 },                     -- 15
    { "Mental Agility", 5 },                -- 20
  } },
  SHAMAN = { name = "Enhancement, then Restoration", trees = { "Enhancement", "Restoration" }, build = {
    { "Ancestral Knowledge", 5 },           -- Enh 5
    { "Thundering Strikes", 5 },            -- 10
    { "Two-Handed Axes and Maces", 1 },     -- 11
    { "Improved Ghost Wolf", 2 },           -- 13
    { "Enhancing Totems", 2 },              -- 15
    { "Flurry", 5 },                        -- 20
    { "Elemental Weapons", 3 },             -- 23
    { "Parry", 1 },                         -- 24
    { "Improved Weapon Totems", 1 },        -- 25
    { "Weapon Mastery", 5 },                -- 30
    { "Stormstrike", 1 },                   -- 31
    { "Tidal Focus", 5 },                   -- Resto 5
    { "Totemic Focus", 5 },                 -- 10
    { "Nature's Guidance", 3 },             -- 13
    { "Ancestral Healing", 2 },             -- 15
    { "Totemic Mastery", 1 },               -- 16
    { "Improved Healing Wave", 4 },         -- 20
  } },
  MAGE = { name = "Frost (AoE-friendly), then Arcane", trees = { "Frost", "Arcane" }, build = {
    { "Improved Frostbolt", 5 },            -- Frost 5
    { "Ice Shards", 5 },                    -- 10
    { "Improved Blizzard", 3 },             -- 13
    { "Piercing Ice", 3 },                  -- 16
    { "Frost Channeling", 3 },              -- 19
    { "Permafrost", 1 },                    -- 20
    { "Ice Block", 1 },                     -- 21
    { "Improved Cone of Cold", 3 },         -- 24
    { "Arctic Reach", 2 },                  -- 26
    { "Shatter", 4 },                       -- 30
    { "Ice Barrier", 1 },                   -- 31
    { "Arcane Subtlety", 2 },               -- Arcane 2
    { "Arcane Focus", 3 },                  -- 5
    { "Arcane Concentration", 5 },          -- 10
    { "Wand Specialization", 2 },           -- 12
    { "Improved Arcane Explosion", 3 },     -- 15
    { "Arcane Meditation", 3 },             -- 18
    { "Improved Mana Shield", 2 },          -- 20
  } },
  WARLOCK = { name = "Affliction, then Demonology", trees = { "Affliction", "Demonology" }, build = {
    { "Improved Corruption", 5 },           -- Aff 5
    { "Improved Life Tap", 2 },             -- 7
    { "Suppression", 3 },                   -- 10
    { "Improved Curse of Agony", 3 },       -- 13
    { "Amplify Curse", 1 },                 -- 14
    { "Fel Concentration", 1 },             -- 15
    { "Nightfall", 2 },                     -- 17
    { "Grim Reach", 2 },                    -- 19
    { "Improved Drain Soul", 1 },           -- 20
    { "Siphon Life", 1 },                   -- 21
    { "Shadow Mastery", 5 },                -- 26
    { "Suppression", 2 },                   -- 28
    { "Improved Drain Life", 2 },           -- 30
    { "Dark Pact", 1 },                     -- 31
    { "Demonic Embrace", 5 },               -- Demo 5
    { "Improved Voidwalker", 3 },           -- 8
    { "Improved Health Funnel", 2 },        -- 10
    { "Fel Domination", 1 },                -- 11
    { "Fel Stamina", 4 },                   -- 15
    { "Unholy Power", 5 },                  -- 20
  } },
  DRUID = { name = "Feral (cat), then Restoration", trees = { "Feral Combat", "Restoration" }, build = {
    { "Ferocity", 5 },                      -- Feral 5
    { "Feral Instinct", 3 },                -- 8
    { "Thick Hide", 2 },                    -- 10
    { "Sharpened Claws", 3 },               -- 13
    { "Feline Swiftness", 2 },              -- 15
    { "Predatory Strikes", 3 },             -- 18
    { "Blood Frenzy", 2 },                  -- 20
    { "Savage Fury", 2 },                   -- 22
    { "Faerie Fire (Feral)", 1 },           -- 23
    { "Improved Shred", 2 },                -- 25
    { "Heart of the Wild", 5 },             -- 30
    { "Leader of the Pack", 1 },            -- 31
    { "Furor", 5 },                         -- Resto 5
    { "Improved Enrage", 2 },               -- 7
    { "Nature's Focus", 3 },                -- 10
    { "Reflection", 3 },                    -- 13
    { "Insect Swarm", 1 },                  -- 14
    { "Improved Mark of the Wild", 5 },     -- 19
    { "Improved Healing Touch", 1 },        -- 20
  } },
}
