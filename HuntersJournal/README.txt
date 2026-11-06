Hunter's Journal - for World of Warcraft: Forever
=================================================

A Monster Hunter style field guide. Every creature you meet gets an entry,
and hunting it raises its RESEARCH LEVEL, unlocking more of its page.

RESEARCH LEVELS
  1  Sighted      name, level, habitat (just target it or see its nameplate)
  2  Slain        physiology (health) + taming info
  3  Studied      weaknesses, exploits (crowd control), observed abilities
  4  Catalogued   materials: drops and gathered items with drop rates
  5  Mastered     field notes (lore) + your hunter's record

  Kills needed for levels 2/3/4/5:
    normal mobs   1 / 5 / 10 / 20
    elites        1 / 2 / 4 / 6
    rares         1 / 2 / 3 / 5
    bosses        1 / 1 / 2 / 3

ROLEPLAY (the "My Notes" tab, always unlocked)
  - Write your own in-character notes on any creature (saved per character).
  - Sketch / Study / Record buttons send an emote, e.g.
    "Raptor crouches low and studies the Riverpaw Outrunner closely..."
    Hover a button to preview the exact line first.
  - Read aloud says the start of your notes in /say.
  - Field observations: while you fight a creature one-on-one, the journal
    notices how it attacks and writes it into your notes, e.g.
      - Cast Fireball at me. It burned hot.
      - Raked me with its claws.
      - Quick on its feet. It dodged a good share of my attacks.
    Turn off auto-writing with the checkbox; the "+ Add observations"
    link under the notes adds them by hand instead.
  - Optional: when a creature's research level rises, the pop-up offers a
    matching emote. WoW Forever only lets addons post emotes from a click or
    key press, so click the pop-up, type /hj emote, or bind a key under
    Options > Keybindings > AddOns > Hunter's Journal.

HUNTING GROUNDS (the "Grounds" tab, unlocks after the first kill)
  - Every kill saves where you were: the zone, which part of it, the
    sub-zone name, and the map position.
  - A map of the zone with your kill spots marked (arrows switch zones).
  - "Where to find them" in words, e.g.
    "Northeastern Elwynn Forest, near Brackwell Pumpkin Patch   9"
  - World map: opens the real world map with your kill spots pinned.
  - Tell (/say): "Looking for Prowlers? I've had the best luck in
    northeastern Elwynn Forest, near Brackwell Pumpkin Patch."
  - Point (/emote): "unfolds a hand-drawn map and taps a spot in ..."
  Kills from before this version have no location.

INSTALL
  1. Close the game.
  2. Copy the "HuntersJournal" folder into
       World of Warcraft\_forever_\Interface\AddOns\
  3. Start the game. Open with /hj or the book button on the minimap.

LOOK
  Leather notebook (default) or Classic, under Settings > Journal > Look.
  Changing it needs a UI reload (a button appears).

SORTING
  The Sort button next to the search box cycles Level / Name / Research /
  Kills / Recent (right-click goes backwards).

SETTINGS
  Open with the Settings button in the journal header, /hj settings, or
  Options > AddOns > Hunter's Journal. Everything applies instantly:
  - Nameplate pips: on/off, above/below/left/right, move, resize
  - List pictures: creature portraits or type icons
  - Tooltip line, minimap button, pop-ups and their sound
  - World map: on/off, kills needed before a creature shows, max shown,
    portrait size
  - Auto-emote for RP, and wiping the journal

WORLD MAP
  The book button in the top-right of the world map (under the map's other
  buttons; movable in settings) or /hj map toggles
  hunting grounds: a portrait of each creature wherever you've slain
  5+ of them (number shown on the portrait). Hover for details, click to
  open that creature's Grounds page.

COMMANDS
  /hj            open / close (opens on your current target)
  /hj settings   settings window
  /hj map        hunting grounds on the world map on/off
  /hj debug      print kills, loot and observations to chat (for bug reports)
  /hj plates     research pips above nameplates on/off
  /hj plates 10  move the pips up 10 (use -10 to move down)
  /hj tooltip    journal line in creature tooltips on/off
  /hj toasts     research level-up pop-ups on/off
  /hj minimap    minimap button on/off
  /hj reset      wipe the journal (asks for confirmation)

HOW THE DATA IS GATHERED
  Everything is recorded from what you actually see. Nothing is downloaded.
  - Kills: a creature you fought dying, plus the "X dies, you gain..." XP
    message as a backup.
  - Drop rates: items on corpses you loot, divided by corpses looted.
    Items from re-opening a corpse (skinning, mining) count as Gathered.
  - Weaknesses: a starting estimate from the creature type and name
    (undead and demons take extra Holy, a "Fire Elemental" is immune to
    fire...), then corrected by hits, resists and immunes you see in combat.
  - Abilities: spells you see the creature cast.
  - Taming: WoW Forever's 19 pet families with their abilities and diets.
  - Lore: hand-written notes for named creatures and factions, and family
    or type notes for everything else.

  Forever hides some combat info inside dungeons, so dungeon kills may not
  be counted. Loot still records.

  The journal is shared by all characters on your account.
