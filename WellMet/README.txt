Well Met - roleplay introductions for World of Warcraft: Forever

Strangers' names stay hidden on nameplates, your target frame and tooltips until they tell
you who they are. They show as "Human woman", "Tauren man" and so on, or
just "Stranger".

LEARNING NAMES
  - Someone says their name in /say, /yell, /emote or a whisper:
    "Name's Raptor." - their character name or Total RP 3 name both count.
  - Guildmates, party/raid members and friends count as known (settings).
  - Right-click the introduce button (or /wellmet know) to mark your target as
    known or a stranger again.
  Who you know is saved per character, so each of your characters meets
  people on their own.

INTRODUCING YOURSELF
  Click the introduce button, use the keybind (Options > Keybindings >
  AddOns > Well Met) or type /wellmet intro. It posts a random emote built from
  your Total RP 3 profile (name, title, profession, motto, pronouns).
  Hover the button to see the line first. Edit the lines in /wellmet settings
  (also under Options > AddOns > Well Met).
  By default the button sits on your target frame and only shows when you
  target another player; it glows while they're a stranger. Shift-drag to
  move it, or turn that off to keep it free-floating.

YOUR OWN LINE PACK
  Another small addon can give a character its own introductions without
  touching Well Met:
    WellMet_AddLines("YourName", { 'nods. "{first}."', ... })
  Make a folder with a .toc ("## Dependencies: WellMet") and a Lua file
  with that call.

WORKS WITH
  Blizzard and EllesmereUI nameplates and target frames. Total RP 3 tooltips are
  covered too. Chat still shows names next to messages.
  Inside dungeons the game hides player names from addons, so nothing is
  hidden there.

COMMANDS
  /wellmet            settings
  /wellmet intro      introduce yourself
  /wellmet know       toggle your target between known and stranger
  /wellmet list       who this character knows
  /wellmet forgetall  forget everyone (asks to confirm)
