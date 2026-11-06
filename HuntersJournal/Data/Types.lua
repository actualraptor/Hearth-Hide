local _, ns = ...

-- Damage schools, in display order
ns.SCHOOLS = {
  { key = "physical", name = "Physical", mask = 1,  color = { 0.90, 0.85, 0.75 } },
  { key = "holy",     name = "Holy",     mask = 2,  color = { 1.00, 0.90, 0.50 } },
  { key = "fire",     name = "Fire",     mask = 4,  color = { 1.00, 0.45, 0.20 } },
  { key = "nature",   name = "Nature",   mask = 8,  color = { 0.45, 0.90, 0.35 } },
  { key = "frost",    name = "Frost",    mask = 16, color = { 0.45, 0.80, 1.00 } },
  { key = "shadow",   name = "Shadow",   mask = 32, color = { 0.70, 0.45, 1.00 } },
  { key = "arcane",   name = "Arcane",   mask = 64, color = { 0.95, 0.55, 1.00 } },
}

-- Per creature type: crowd control that works (exploits), school ratings
-- (0 = immune, 1 = resistant, 2 = normal, 3 = weak), a category for the
-- journal list, and a short field note.
ns.TYPES = {
  ["Beast"] = {
    icon = "Ability_Hunter_BeastTaming",
    exploits = { "Freezing Trap", "Scare Beast", "Hibernate", "Polymorph" },
    note = "Creatures of the wild. Driven by hunger and territory rather than malice.",
  },
  ["Humanoid"] = {
    icon = "Achievement_Character_Human_Male",
    exploits = { "Sap", "Polymorph", "Freezing Trap", "Fear", "Seduction" },
    note = "Thinking foes. They flee at low health and call for help, so pull with care.",
  },
  ["Undead"] = {
    icon = "Spell_Shadow_RaiseDead",
    exploits = { "Shackle Undead", "Turn Undead", "Freezing Trap" },
    schools = { holy = 3 },
    note = "Raised by the Scourge or bound by their own grief. The Light burns them.",
  },
  ["Demon"] = {
    icon = "Spell_Shadow_SummonFelHunter",
    exploits = { "Banish", "Enslave Demon", "Fear", "Freezing Trap" },
    schools = { holy = 3 },
    note = "Agents of the Burning Legion. Paladins' Exorcism and Holy Wrath strike them hard.",
  },
  ["Elemental"] = {
    icon = "Spell_Nature_EarthElemental_Totem",
    exploits = { "Banish", "Freezing Trap" },
    note = "Living fire, water, earth and air. Immune to bleeding and to their own element.",
    immuneBleed = true,
  },
  ["Dragonkin"] = {
    icon = "INV_Misc_Head_Dragon_01",
    exploits = { "Hibernate", "Freezing Trap" },
    note = "Whelps, drakes and their kin. Even the smallest carries the pride of a great flight.",
  },
  ["Giant"] = {
    icon = "Ability_Warrior_Rampage",
    exploits = { "Freezing Trap" },
    note = "Mountain-sized and slow to anger. Most crowd control simply fails on them.",
  },
  ["Mechanical"] = {
    icon = "INV_Gizmo_02",
    exploits = { "Freezing Trap" },
    note = "Gnomish and goblin contraptions. They don't bleed and they don't panic.",
    immuneBleed = true,
  },
  ["Critter"] = {
    icon = "Ability_Hunter_Pet_Rat",
    exploits = { "Polymorph" },
    note = "Harmless wildlife. Recorded for completeness.",
  },
  ["Not specified"] = {
    icon = "INV_Misc_QuestionMark",
    exploits = {},
    note = "Something that defies easy classification.",
  },
}

-- Name keywords that hint at an element. Applied to any creature type,
-- strongest for elementals. Order matters: first match wins.
ns.ELEMENT_HINTS = {
  { words = { "Fire", "Flame", "Lava", "Magma", "Blaze", "Ember", "Inferno", "Scorch", "Molten", "Cinder" },
    schools = { fire = 0, frost = 3 }, label = "Fire-aligned" },
  { words = { "Frost", "Ice", "Snow", "Glacier", "Water", "Tide", "Wave", "Sea Spray" },
    schools = { frost = 0, fire = 3 }, label = "Frost/Water-aligned" },
  { words = { "Earth", "Rock", "Stone", "Boulder", "Granite", "Obsidian" },
    schools = { nature = 0 }, label = "Earth-aligned" },
  { words = { "Air", "Wind", "Storm", "Thunder", "Lightning", "Cyclone", "Dust Devil" },
    schools = { nature = 0 }, label = "Air-aligned" },
  { words = { "Shadow", "Void", "Fel" },
    schools = { shadow = 1 }, label = "Shadow-touched" },
}
