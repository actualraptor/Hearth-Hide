local _, ns = ...

-- Lore is unlocked at the highest research level. Written as short field
-- notes, summarised from Warcraft lore (warcraft.wiki.gg / Wowpedia).

-- Exact creature names
ns.LORE_NAMED = {
  ["Hogger"] = "The most infamous gnoll in Elwynn Forest. This hulking brute leads the Riverpaw raiders out of the western woods, and the bounty on his head has sent many a fresh recruit back to Goldshire limping.",
  ["Princess"] = "The prize sow of the Brackwell Pumpkin Patch, now fat on stolen crops and surrounded by her porcine entourage. The Stonefields would very much like her back... in a pie.",
  ["Mother Fang"] = "A monstrous spider that nests deep in Jasperlode Mine. The miners abandoned their claim rather than face her brood.",
  ["Mor'Ladim"] = "Once the knight Morgan Ladimore, who came home from war to tragedy and took his own life in grief. Now an undead revenant who stalks the woods near Raven Hill, Duskwood. Some say only his own story can lay him to rest.",
  ["Stitches"] = "An abomination stitched together in the shadows of Duskwood and sent to march on Darkshire. The Night Watch still talks about the night it came lumbering down the road.",
  ["Old Murk-Eye"] = "An ancient, half-blind murloc who prowls the Westfall coast. He has outlived more adventurers than any fishmonger cares to count.",
  ["Echeyakee"] = "A white lion of legend in the Barrens. The tauren say only those who call it with the proper horn ever see it, and fewer still walk away.",
  ["Humar the Pridelord"] = "Lord of the Barrens' lion prides. Tauren hunters test their mettle by bringing back his pelt.",
  ["Edwin VanCleef"] = "Master stonemason turned kingpin of the Defias Brotherhood. Cheated of his guild's wages after rebuilding Stormwind, he now builds a warship in the depths of the Deadmines.",
  ["Archmage Arugal"] = "The Kirin Tor mage who summoned the worgen to fight the Scourge, only to see them turn on Silverpine. Maddened, he holds court in Shadowfang Keep with his 'children'.",
  ["Mutanus the Devourer"] = "The nightmare beneath the Wailing Caverns. Naralex's dreams turned to horror, and this murloc-like abomination is their shape.",
  ["Gath'Ilzogg"] = "A Blackrock orc commander who leads raids on Redridge from Stonewatch Keep. Lakeshire has posted a bounty for his head.",
}

-- Keywords in the creature's name, checked in order (first match wins).
ns.LORE_KEYWORDS = {
  { "Defias", "The Defias Brotherhood began as stonemasons cheated out of their pay after rebuilding Stormwind. Now they are bandits, raiding Westfall and Elwynn from hidden camps and the Deadmines." },
  { "Riverpaw", "Gnolls of the Riverpaw clan, pushing into Elwynn and Westfall. Disorganised alone, dangerous in packs, and loyal to Hogger." },
  { "Redridge", "Redridge gnolls serve the Blackrock orcs as raiders and scouts, harassing Lakeshire from the hills." },
  { "Shadowhide", "Shadowhide gnolls haunt Redridge's eastern hills, said to dabble in dark magic." },
  { "Mosshide", "Mosshide gnolls roam the bogs of the Wetlands." },
  { "Rot Hide", "Gnolls who serve the Scourge in Silverpine and Tirisfal, feeding on the plague-ridden dead." },
  { "Kobold", "Candle-loving tunnelers who infest the mines of Elwynn and beyond. 'You no take candle!'" },
  { "Tunnel Rat", "Kobold diggers. If you see one, the mine is already lost." },
  { "Murloc", "Amphibious coastal tribes with a war cry no traveller forgets. They raid fishing villages and hoard shiny things." },
  { "Blackrock", "Orcs of the Blackrock clan, still loyal to the old Horde. They hold Blackrock Spire and raid Redridge and Burning Steppes." },
  { "Dark Iron", "Dark Iron dwarves, servants of Ragnaros, who rule the depths beneath Blackrock Mountain." },
  { "Syndicate", "Human thieves and fallen nobles of Alterac who prey on Hillsbrad and the Alterac foothills." },
  { "Scarlet", "Zealots of the Scarlet Crusade. They began as a crusade against the Scourge and now see plague in every stranger." },
  { "Venture Co.", "Goblin industrialists who clear-cut forests and strip mines across Kalimdor for profit, with no regard for who lived there first." },
  { "Kolkar", "Kolkar centaurs, raiders of the Barrens and Desolace. Centaurs descend from Zaetar, son of Cenarius, and the earth princess Theradras." },
  { "Galak", "Galak centaurs of Thousand Needles." },
  { "Magram", "Magram centaurs of Desolace, at war with their Gelkis cousins." },
  { "Gelkis", "Gelkis centaurs of Desolace, earth-worshippers at war with the Magram." },
  { "Razormane", "Quilboar of the Razormane tribe, spreading thorny warrens across the Barrens and Durotar." },
  { "Bristleback", "Bristleback quilboar who raid the tauren of Mulgore." },
  { "Razorfen", "Quilboar of the Razorfen. They revere the boar demigod Agamaggan, whose blood grew the giant thorns they live in." },
  { "Harpy", "Shrieking winged women who nest in the cliffs of Kalimdor and prey on caravans." },
  { "Windfury", "Windfury harpies of Mulgore and the Barrens." },
  { "Bloodfeather", "Bloodfeather harpies who roost on Teldrassil's edge." },
  { "Witchwing", "Witchwing harpies of the Barrens." },
  { "Thistlefur", "Thistlefur furbolgs of Ashenvale, driven mad by demonic corruption." },
  { "Timbermaw", "The Timbermaw, a rare uncorrupted furbolg tribe guarding the passes of Felwood." },
  { "Gnarlpine", "Gnarlpine furbolgs of Teldrassil, once peaceful and now poisoned against the night elves." },
  { "Deadwood", "Deadwood furbolgs of Felwood, twisted by demonic taint." },
  { "Burning Blade", "Orc cultists who worship the demons of the Burning Legion." },
  { "Searing Blade", "Burning Blade cultists who lurk in the Ragefire Chasm beneath Orgrimmar." },
  { "Dragonmaw", "The Dragonmaw clan, orcs who once enslaved red dragons from Grim Batol and now hold the Wetlands." },
  { "Frostmane", "Frostmane ice trolls of Dun Morogh, driven from their caves by dwarven expansion." },
  { "Rockjaw", "Rockjaw troggs who swarm Dun Morogh, unearthed from the depths of Uldaman." },
  { "Trogg", "Troggs, savage creatures unearthed from the depths of Uldaman." },
  { "Wendigo", "Yeti-like beasts of the frozen caves of Dun Morogh and Alterac." },
  { "Satyr", "Night elves corrupted by the Burning Legion, now goat-legged demons haunting Ashenvale and Felwood." },
  { "Naga", "Descendants of the Highborne who sank with the Well of Eternity, transformed into serpent-folk." },
  { "Bloodsail", "Pirates of the Bloodsail Buccaneers who rule the seas off Stranglethorn." },
  { "Southsea", "Southsea pirates operating out of the Barrens' and Tanaris' coasts." },
  { "Grimtotem", "The Grimtotem, a tauren clan who reject the Horde and covet the lands of their kin." },
  { "Mo'grosh", "Mo'grosh ogres who occupy the Loch Modan stronghold." },
  { "Boulderfist", "Boulderfist ogres, spread across Arathi and Stonetalon." },
  { "Dustbelcher", "Dustbelcher ogres of the Badlands." },
  { "Gordunni", "Gordunni ogres of Feralas." },
  { "Skeletal", "Restless bones raised by necromancers of the Scourge." },
  { "Ghoul", "Plague-fed undead, the Scourge's endless foot soldiers." },
  { "Zombie", "Plague victims who rose again, mindless and hungry." },
  { "Worgen", "Cursed wolf-men summoned by Arugal, now spread from Silverpine into Duskwood." },
  { "Nightbane", "Worgen of the Nightbane pack who stalk the woods of Duskwood." },
  { "Kodo", "Massive beasts of burden of the Barrens. Tauren honour them; the kodo graveyard of Desolace is where they go to die." },
  { "Plainstrider", "Flightless birds of Mulgore and the Barrens, hunted by young tauren as a rite of passage." },
  { "Webwood", "Spiders of Shadowthread Cave on Teldrassil, tainted by something deep below." },
  { "Mottled", "Common game of Durotar, as tough and stubborn as the orcs who hunt them." },
}

-- Generic lore by pet family / creature type for everything else
function ns.GetLore(name, ctype, family)
  if not name then return nil end
  if ns.LORE_NAMED[name] then return ns.LORE_NAMED[name] end
  for _, kw in ipairs(ns.LORE_KEYWORDS) do
    if name:find(kw[1], 1, true) then return kw[2] end
  end
  local fam = family and ns.GetFamily(family)
  if fam and fam.note then return fam.note end
  local t = ctype and ns.TYPES[ctype]
  return t and t.note or nil
end
