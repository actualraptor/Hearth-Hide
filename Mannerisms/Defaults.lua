local ADDON, ns = ...

------------------------------------------------------------------------
-- The rings Mannerisms starts with. Everything here can be changed in
-- /mm. Slice kinds:
--   emote  - a /me emote: your name goes in front ("Raptor waves.")
--   say    - spoken out loud in /say
--   game   - one of the game's own emotes, with its animation (WAVE, BOW)
--   ring   - opens another ring
-- Several lines on one slice: one is picked at random each time.
-- Words in braces are filled in for you: {target} {first} {full} {he}
-- {his} {him} {himself} ... A line that needs something you don't have
-- (like {target} with nothing targeted) is skipped.
------------------------------------------------------------------------
local I = "Interface\\Icons\\"

ns.DEFAULT_ROOT = "main"
ns.DEFAULT_RINGS = {
  main = {
    name = "Mannerisms", icon = I .. "INV_Misc_Book_09", key = 1,
    slices = {
      { label = "Greetings", icon = I .. "Spell_Holy_SealOfSalvation", kind = "ring", ring = "greet" },
      { label = "Farewells", icon = I .. "INV_Misc_Rune_01", kind = "ring", ring = "bye" },
      { label = "Reactions", icon = I .. "Spell_Shadow_Charm", kind = "ring", ring = "react" },
      { label = "Gestures", icon = I .. "Spell_Holy_MindVision", kind = "ring", ring = "gesture" },
      { label = "Tavern", icon = I .. "INV_Drink_05", kind = "ring", ring = "tavern" },
      { label = "On the road", icon = I .. "INV_Sword_04", kind = "ring", ring = "road" },
    },
  },

  greet = {
    name = "Greetings", icon = I .. "Spell_Holy_SealOfSalvation",
    slices = {
      { label = "Wave", icon = I .. "Spell_Holy_SealOfSalvation", kind = "game", emote = "WAVE" },
      { label = "Nod hello", icon = I .. "Spell_Holy_Heal", kind = "emote", lines = {
        "gives {target} a friendly nod.",
        "nods a greeting to {target}.",
        "dips {his} head politely.",
        "offers a small, easy nod of greeting.",
      } },
      { label = "Well met", icon = I .. "INV_Misc_Note_01", kind = "say", lines = {
        "Well met.",
        "Well met, friend.",
        "Light be with you.",
        "Good to see a friendly face out here.",
        "Evening. Or is it morning already?",
      } },
      { label = "Handshake", icon = I .. "INV_Gauntlets_04", kind = "emote", lines = {
        "offers {target} a hand.",
        "clasps {target}'s forearm in greeting.",
        "holds out a hand to shake.",
      } },
      { label = "Bow", icon = I .. "Spell_Holy_Excorcism", kind = "game", emote = "BOW" },
      { label = "Warm welcome", icon = I .. "Spell_Fire_Fire", kind = "emote", lines = {
        "breaks into a wide smile at the sight of {target}.",
        "waves {target} over. \"Come, sit. There's room.\"",
        "brightens and raises a hand in welcome.",
      } },
    },
  },

  bye = {
    name = "Farewells", icon = I .. "INV_Misc_Rune_01",
    slices = {
      { label = "Wave goodbye", icon = I .. "INV_Misc_Rune_01", kind = "game", emote = "BYE" },
      { label = "Safe travels", icon = I .. "INV_Misc_Note_01", kind = "say", lines = {
        "Safe travels.",
        "Watch the roads. Light keep you.",
        "Until next time.",
        "Take care of yourself out there.",
        "May your path be clear.",
      } },
      { label = "Tip of the head", icon = I .. "INV_Helmet_29", kind = "emote", lines = {
        "tips {his} head to {target} in farewell.",
        "gives a parting nod.",
        "touches two fingers to {his} brow in farewell.",
      } },
      { label = "Head off", icon = I .. "Ability_Rogue_Sprint", kind = "emote", lines = {
        "gathers {his} things and heads off down the road.",
        "shoulders {his} pack and sets off.",
        "slips away quietly.",
      } },
      { label = "Embrace", icon = I .. "Spell_Holy_Renew", kind = "emote", lines = {
        "pulls {target} into a brief, warm embrace.",
        "claps {target} on the shoulder before parting.",
      } },
    },
  },

  react = {
    name = "Reactions", icon = I .. "Spell_Shadow_Charm",
    slices = {
      { label = "Laugh", icon = I .. "Spell_Holy_Silence", kind = "emote", lines = {
        "laughs, warm and loud.",
        "chuckles under {his} breath.",
        "snorts with laughter.",
        "laughs at {target}'s joke.",
      } },
      { label = "Agree", icon = I .. "Spell_Holy_Heal", kind = "emote", lines = {
        "nods along.",
        "nods slowly in agreement.",
        "hums in agreement.",
      } },
      { label = "Disagree", icon = I .. "Spell_Shadow_SoulLeech_3", kind = "emote", lines = {
        "shakes {his} head.",
        "frowns and shakes {his} head slowly.",
        "doesn't look convinced.",
      } },
      { label = "Surprise", icon = I .. "Spell_Nature_Lightning", kind = "emote", lines = {
        "raises {his} eyebrows.",
        "blinks in surprise.",
        "lets out a low whistle.",
      } },
      { label = "Sigh", icon = I .. "Spell_Frost_WindWalkOn", kind = "emote", lines = {
        "sighs.",
        "lets out a long, tired sigh.",
        "rubs the bridge of {his} nose and sighs.",
      } },
      { label = "Think", icon = I .. "INV_Misc_Book_08", kind = "emote", lines = {
        "rubs {his} chin thoughtfully.",
        "falls quiet for a moment, thinking it over.",
        "considers {target} for a long moment.",
      } },
      { label = "Applaud", icon = I .. "Spell_Holy_PowerWordShield", kind = "game", emote = "APPLAUD" },
    },
  },

  gesture = {
    name = "Gestures", icon = I .. "Spell_Holy_MindVision",
    slices = {
      { label = "Look around", icon = I .. "Spell_Holy_MindVision", kind = "emote", lines = {
        "glances around, taking in the surroundings.",
        "scans the area with a careful eye.",
        "looks over {his} shoulder.",
      } },
      { label = "Look over", icon = I .. "INV_Misc_Spyglass_02", kind = "emote", lines = {
        "looks {target} up and down.",
        "studies {target} with open curiosity.",
        "gives {target} a long, measuring look.",
      } },
      { label = "Stretch", icon = I .. "Spell_Nature_Sleep", kind = "emote", lines = {
        "stretches until {his} back pops.",
        "rolls {his} shoulders and stretches.",
        "yawns and stretches.",
      } },
      { label = "Sit", icon = I .. "Spell_Nature_Sleep", kind = "game", emote = "SIT" },
      { label = "Check gear", icon = I .. "INV_Misc_Bag_08", kind = "emote", lines = {
        "checks over {his} gear.",
        "tightens a strap on {his} pack.",
        "rummages through {his} bag for something.",
      } },
      { label = "Kneel", icon = I .. "Spell_Holy_Excorcism", kind = "game", emote = "KNEEL" },
    },
  },

  tavern = {
    name = "Tavern", icon = I .. "INV_Drink_05",
    slices = {
      { label = "Order", icon = I .. "INV_Drink_05", kind = "say", lines = {
        "An ale, please.",
        "Something warm, if you've got it.",
        "Whatever's good tonight.",
        "Another round!",
      } },
      { label = "Toast", icon = I .. "INV_Drink_04", kind = "emote", lines = {
        "raises {his} mug to {target}.",
        "lifts {his} drink. \"To good company!\"",
        "raises a glass. \"To the road behind and the road ahead.\"",
      } },
      { label = "Drink", icon = I .. "INV_Drink_07", kind = "emote", lines = {
        "takes a long pull from {his} mug.",
        "sips {his} drink.",
        "drains the last of {his} drink and sets it down.",
      } },
      { label = "Pay", icon = I .. "INV_Misc_Coin_01", kind = "emote", lines = {
        "slides a few coins across the bar.",
        "flips a coin to the barkeep.",
        "pays for {target}'s drink as well.",
      } },
      { label = "Cheer", icon = I .. "Spell_Holy_PowerWordShield", kind = "game", emote = "CHEER" },
      { label = "Lean back", icon = I .. "Spell_Nature_Sleep", kind = "emote", lines = {
        "leans back in {his} seat, content.",
        "leans on the bar.",
        "props {his} boots up by the fire.",
      } },
    },
  },

  road = {
    name = "On the road", icon = I .. "INV_Sword_04",
    slices = {
      { label = "Ready weapon", icon = I .. "INV_Sword_04", kind = "emote", lines = {
        "rests a hand on {his} weapon.",
        "draws {his} weapon slowly.",
        "shifts into a ready stance.",
      } },
      { label = "Quiet!", icon = I .. "Ability_Stealth", kind = "emote", lines = {
        "holds up a hand for silence.",
        "raises a finger to {his} lips.",
        "signals {target} to stay low.",
      } },
      { label = "Scout ahead", icon = I .. "Ability_Hunter_EagleEye", kind = "say", lines = {
        "I'll scout ahead. Wait here.",
        "Stay close. Something's not right.",
        "Road looks clear. Let's move.",
      } },
      { label = "Catch breath", icon = I .. "Spell_Nature_Rejuvenation", kind = "emote", lines = {
        "leans on {his} knees, catching {his} breath.",
        "wipes sweat from {his} brow.",
        "takes a swig from {his} waterskin.",
      } },
      { label = "Tend wound", icon = I .. "INV_Misc_Bandage_15", kind = "emote", lines = {
        "binds a shallow cut with a strip of cloth.",
        "checks {target} over for injuries.",
        "winces and presses a hand to {his} side.",
      } },
      { label = "Victory", icon = I .. "Spell_Holy_PowerWordShield", kind = "game", emote = "VICTORY" },
    },
  },
}

-- icons offered in the editor
ns.ICONS = {
  "INV_Misc_Book_09", "Spell_Holy_SealOfSalvation", "Spell_Holy_Heal", "INV_Misc_Note_01", "INV_Misc_Rune_01",
  "Spell_Shadow_Charm", "Spell_Holy_MindVision", "INV_Drink_05", "INV_Drink_04", "INV_Sword_04",
  "Spell_Holy_Silence", "Spell_Nature_Sleep", "INV_Misc_Bag_08", "INV_Misc_Coin_01", "Ability_Stealth",
  "Ability_Hunter_EagleEye", "Spell_Nature_Rejuvenation", "INV_Misc_Bandage_15", "Spell_Fire_Fire",
  "INV_Gauntlets_04", "Spell_Holy_Renew", "Spell_Holy_PowerWordShield", "INV_Misc_Spyglass_02",
  "INV_Misc_Food_15", "INV_Misc_Flower_02", "INV_Misc_Gem_Pearl_04", "INV_Letter_15", "INV_Misc_Head_Human_01",
  "Ability_Hunter_BeastCall", "INV_Misc_Pelt_Wolf_01", "Spell_Frost_WindWalkOn", "INV_Misc_QuestionMark",
}
