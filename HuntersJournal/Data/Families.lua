local _, ns = ...

-- Hunter pet families as they work in WoW: Forever.
-- role, special ability, other abilities, diet, and a short field note.
ns.FAMILIES = {
  ["Bat"] = { role = "Offensive", special = "Sonic Blast", desc = "Damages and slows the target's spellcasting.",
    abilities = { "Bite", "Dive", "Cower" }, diet = { "Fruit", "Fungus" }, icon = "Ability_Hunter_Pet_Bat",
    note = "Bats roost in caves and ruins and hunt by echo. Their screech can rattle a caster mid-spell." },
  ["Bear"] = { role = "Defensive", special = "Swipe", desc = "Strikes up to three nearby enemies.",
    abilities = { "Bite", "Claw", "Dash", "Cower" }, diet = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" }, icon = "Ability_Hunter_Pet_Bear",
    note = "Bears will eat nearly anything and shrug off punishment that would fell lesser beasts." },
  ["Bird of Prey"] = { role = "Offensive", special = "Mine!", desc = "Damages and disarms the target.",
    abilities = { "Claw", "Dive", "Cower" }, diet = { "Fish", "Meat" }, icon = "Ability_Hunter_Pet_Owl",
    note = "Owls and hawks strike from above and have been known to snatch weapons right out of a fighter's hands." },
  ["Boar"] = { role = "Defensive", special = "Charge", desc = "Rushes and immobilizes the target, empowering the next attack.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" }, icon = "Ability_Hunter_Pet_Boar",
    note = "Stubborn and tough, boars charge first and think later. The quilboar of Kalimdor revere them." },
  ["Carrion Bird"] = { role = "Balanced", special = "Demoralizing Screech", desc = "Damages nearby enemies and lowers their attack power.",
    abilities = { "Bite", "Claw", "Dive", "Cower" }, diet = { "Fish", "Meat" }, icon = "Ability_Hunter_Pet_Vulture",
    note = "Vultures and condors circle wherever there is death, and arrive long before anyone else." },
  ["Cat"] = { role = "Offensive", special = "Prowl", desc = "Stealths; the first strike from Prowl deals bonus damage.",
    abilities = { "Bite", "Claw", "Dash", "Cower" }, diet = { "Fish", "Meat" }, icon = "Ability_Hunter_Pet_Cat",
    note = "Lions, tigers and panthers are patient ambush hunters, favored by hunters who like to strike first." },
  ["Core Hound"] = { role = "Offensive", special = "Lava Breath", desc = "Breathes molten fire at the target.",
    abilities = { "Bite", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_CoreHound",
    note = "Two-headed hounds of the Firelord's domain. Only the most skilled beast masters can bond with one." },
  ["Crab"] = { role = "Defensive", special = "Pinch", desc = "Damages and slows the target.",
    abilities = { "Claw", "Dash", "Cower" }, diet = { "Bread", "Fish", "Fruit", "Fungus" }, icon = "Ability_Hunter_Pet_Crab",
    note = "Armored scavengers of every coastline. Slow to anger, slower to let go." },
  ["Crocolisk"] = { role = "Defensive", special = "Dismember", desc = "Damages the target and halves healing it receives.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Fish", "Meat" }, icon = "Ability_Hunter_Pet_Crocolisk",
    note = "Ancient river predators that lurk in the shallows of the Wetlands and Dustwallow Marsh." },
  ["Fox"] = { role = "Offensive", special = "Trickster's Dance", desc = "Raises dodge chance and attack speed for 12 sec.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Fruit", "Meat" }, icon = "Ability_Hunter_Pet_Fox",
    note = "Quick and clever. New to the beast master's bond in Forever." },
  ["Gorilla"] = { role = "Defensive", special = "Thunderstomp", desc = "Shakes the ground, damaging nearby enemies.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Bread", "Fruit", "Fungus" }, icon = "Ability_Hunter_Pet_Gorilla",
    note = "Great apes of the Stranglethorn and Un'Goro jungles, fiercely territorial and immensely strong." },
  ["Hyena"] = { role = "Balanced", special = "Tendon Rip", desc = "Slows the target and makes it bleed.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_Hyena",
    note = "Pack scavengers of the Barrens and Badlands. Never alone for long." },
  ["Raptor"] = { role = "Offensive", special = "Savage Rend", desc = "Tears the target, causing a bleed.",
    abilities = { "Bite", "Claw", "Dash", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_Raptor",
    note = "Swift, vicious pack hunters. The trolls of Zul'Gurub and the Barrens' Raptor Grounds breed them for war." },
  ["Scorpid"] = { role = "Defensive", special = "Scorpid Poison", desc = "Stacking poison damage over time.",
    abilities = { "Claw", "Dash", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_Scorpid",
    note = "Desert scorpions grown to monstrous size. Their venom is prized by alchemists and rogues alike." },
  ["Spider"] = { role = "Offensive", special = "Web", desc = "Immobilizes the target and damages it over time.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_Spider",
    note = "From Duskwood's giant webs to the depths of mines, spiders pin their prey and wait." },
  ["Tallstrider"] = { role = "Defensive", special = "Dust Cloud", desc = "Kicks up dust that lowers the target's armor.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Bread", "Cheese", "Fruit", "Fungus" }, icon = "Ability_Hunter_Pet_TallStrider",
    note = "Long-legged flightless birds of Mulgore and the Barrens. Faster than they look." },
  ["Turtle"] = { role = "Defensive", special = "Shell Shield", desc = "Reduces damage taken and attack speed for 12 sec.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Bread", "Fish", "Fruit", "Fungus" }, icon = "Ability_Hunter_Pet_Turtle",
    note = "Patient and nearly unbreakable. A favorite of hunters who want their pet to hold the line." },
  ["Wind Serpent"] = { role = "Offensive", special = "Lightning Breath", desc = "A 20-yard bolt of lightning.",
    abilities = { "Bite", "Dive", "Cower" }, diet = { "Bread", "Cheese", "Fish" }, icon = "Ability_Hunter_Pet_WindSerpent",
    note = "Feathered serpents of the Stonetalon peaks and Thousand Needles that crackle with storm energy." },
  ["Wolf"] = { role = "Balanced", special = "Furious Howl", desc = "Raises nearby allies' melee attack power.",
    abilities = { "Bite", "Dash", "Cower" }, diet = { "Meat" }, icon = "Ability_Hunter_Pet_Wolf",
    note = "Pack animals through and through. Orcs have ridden and hunted beside wolves since their days on Draenor." },
}

ns.FAMILY_ALIASES = {
  ["Owl"] = "Bird of Prey",
  ["Windserpent"] = "Wind Serpent",
  ["Crocilisk"] = "Crocolisk",
  ["Coyote"] = "Wolf",
}

function ns.GetFamily(name)
  if not name then return nil end
  name = ns.FAMILY_ALIASES[name] or name
  return ns.FAMILIES[name], name
end
