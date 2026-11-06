local ADDON, ns = ...
ns.Defer(function()

-- "My Notes" tab: your own in-character notes per creature (saved per
-- character), plus roleplay emote buttons.

local UI = ns.UI
local C, Text, Fill, Border, hex = UI.C, UI.Text, UI.Fill, UI.Border, UI.hex
local page, PAGE_W, FONT = UI.page, UI.PAGE_W, UI.FONT
local MUTED, TAN = hex(C.muted), hex(C.tan)

local current -- entry being shown

local function Me()
  local n = UnitName("player")
  return type(n) == "string" and n or "Unknown"
end

local lastSent -- message we last tried to send, for blocked-action reports
local function SendChat(msg, channel)
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  if not send then return false end
  lastSent = msg
  local ok, err = pcall(send, msg, channel)
  if not ok and ns.Print then ns.Print("couldn't send that message: " .. tostring(err)) end
  return ok
end

-- "the Riverpaw Outrunner" but just "Hogger"
local function Called(e)
  local named = not e.name:find(" ") or e.class == "rare" or e.class == "rareelite" or e.class == "worldboss"
  return named and e.name or ("the " .. e.name)
end

local EMOTES = {
  Sketch = {
    "pulls a stick of charcoal from a pouch and sketches %s into a worn leather journal.",
    "pauses to draw a quick, careful sketch of %s, shading in the details.",
    "flips to a fresh page and roughs out the shape of %s with practiced strokes.",
  },
  Study = {
    "crouches low and studies %s closely, noting every scar and marking.",
    "watches %s for a long moment, eyes narrowed, committing its habits to memory.",
    "circles %s slowly, measuring it with a hunter's eye.",
  },
  Record = {
    "flips open a battered field journal and adds a few lines about %s.",
    "scribbles hurried notes about %s, tongue between teeth.",
    "tucks the journal away after recording another entry on %s.",
  },
}

local lastPick = {}
local function Pick(kind, e)
  local list = EMOTES[kind]
  local i
  repeat i = math.random(#list) until #list < 2 or i ~= lastPick[kind]
  lastPick[kind] = i
  return list[i]:format(Called(e))
end

------------------------------------------------------------------------
-- Page layout
------------------------------------------------------------------------
local head = UI.SectionHeader(page, "MY NOTES   in character")
head:SetPoint("TOPLEFT")
head:SetPoint("TOPRIGHT")

local box = CreateFrame("Frame", nil, page)
box:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -8)
box:SetSize(PAGE_W, 176)
Fill(box, "BACKGROUND", C.inset, 1):SetAllPoints()
Border(box, C.tanDim, 0.7)

local scroll = CreateFrame("ScrollFrame", nil, box)
scroll:SetPoint("TOPLEFT", 8, -8)
scroll:SetPoint("BOTTOMRIGHT", -8, 8)

local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFont(FONT, 12, "")
edit:SetTextColor(C.text[1], C.text[2], C.text[3])
edit:SetWidth(PAGE_W - 16)
edit:SetMaxLetters(2000)
scroll:SetScrollChild(edit)

local placeholder = Text(box, 12, C.muted)
placeholder:SetPoint("TOPLEFT", 9, -9)
placeholder:SetWidth(PAGE_W - 18)
placeholder:SetText("Write what your character knows or thinks about this creature...")

box:EnableMouse(true)
box:SetScript("OnMouseDown", function() edit:SetFocus() end)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
  local max = math.max(0, edit:GetHeight() - self:GetHeight())
  self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 20)))
end)
edit:SetScript("OnCursorChanged", function(_, _, y, _, h)
  local top = -y
  local view = scroll:GetHeight()
  local cur = scroll:GetVerticalScroll()
  if top < cur then scroll:SetVerticalScroll(top)
  elseif top + h > cur + view then scroll:SetVerticalScroll(top + h - view) end
end)
edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
edit:SetScript("OnTextChanged", function(self, userInput)
  placeholder:SetShown(self:GetText() == "")
  if userInput and current then
    current.notes = current.notes or {}
    local t = self:GetText()
    current.notes[Me()] = (t ~= "") and t or nil
  end
end)

local author = Text(page, 10, C.muted, "RIGHT")
author:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -6)

------------------------------------------------------------------------
-- Field observations written as in-character lines
------------------------------------------------------------------------
local FEEL = {
  fire = { "It burned hot.", "The heat of it lingered on my skin.", "Scorched me badly." },
  frost = { "The cold bit to the bone.", "Left my fingers numb.", "Bitterly cold." },
  nature = { "It stung like venom.", "Left a nasty sting behind.", "Crackled through me." },
  shadow = { "Left a sickening chill.", "Felt like something gnawing at my soul.", "Dark, cold magic." },
  arcane = { "Raw magic, crackling and bright.", "Made my head ring.", "Sparked with arcane light." },
  holy = { "A searing, holy light.", "Burned like sunlight." },
  physical = { "Hit hard.", "A heavy, bruising blow." },
}
local HURT = {
  fire = "Its attacks burn.", frost = "Its touch is freezing cold.", nature = "Its attacks carry venom or lightning.",
  shadow = "Its blows carry a dark chill.", arcane = "Arcane energy crackles in its attacks.", holy = "Holy light burns in its attacks.",
}
local MELEE_FAMILY = {
  Wolf = "Snapped at me with its jaws.", Cat = "Raked me with its claws.", Bear = "Mauled me with heavy paws.",
  Boar = "Gored me with its tusks.", Spider = "Bit at me with venomous fangs.", Raptor = "Slashed at me with its talons.",
  Scorpid = "Struck at me with pincers and stinger.", Crab = "Pinched at me with its claws.", Crocolisk = "Snapped at me with its jaws.",
  Bat = "Raked at me in a flurry of wings.", ["Bird of Prey"] = "Dove at me, talons first.", ["Carrion Bird"] = "Tore at me with beak and talons.",
  Gorilla = "Pounded me with its fists.", Hyena = "Bit at my legs.", Tallstrider = "Pecked and kicked at me.",
  Turtle = "Snapped at me with its beak.", ["Wind Serpent"] = "Bit at me from above.", Fox = "Nipped at my heels.",
  ["Core Hound"] = "Bit at me with both heads.",
}
local MELEE_TYPE = {
  Humanoid = "Came at me with a weapon.", Undead = "Clawed at me with rotting hands.", Demon = "Struck at me with fel-touched claws.",
  Elemental = "Battered me with its body.", Mechanical = "Hammered at me with metal limbs.", Giant = "Tried to crush me with its fists.",
  Dragonkin = "Raked me with its claws.", Beast = "Attacked me with tooth and claw.", Critter = "Nipped at me. Barely noticed.",
}
local AVOID = {
  dodge = "Quick on its feet. It dodged a good share of my attacks.",
  parry = "Skilled with a blade. It parried my blows often.",
  block = "Carries a shield and knows how to use it.",
}

local function pick(list, seed)
  return list[(seed % #list) + 1]
end

function ns.ObsText(e, id)
  local seed = #e.name + (e.kills or 0)
  local kind, arg = id:match("^(%a+):(.+)$")
  if kind == "spell" then
    local school = e.spellSchool and e.spellSchool[arg]
    local atMe = (e.spellsAtMe and e.spellsAtMe[arg]) or school
    local line = atMe and ("Cast " .. arg .. " at me.") or ("Uses " .. arg .. ".")
    if school and FEEL[school] then line = line .. " " .. pick(FEEL[school], seed) end
    return line
  elseif kind == "school" then
    return HURT[arg]
  elseif id == "melee" then
    return MELEE_FAMILY[e.family or ""] or MELEE_TYPE[e.type or ""] or "Attacked me in close quarters."
  elseif id == "crit" then
    return "Landed one blow hard enough to stagger me. Keep your distance."
  else
    return AVOID[id]
  end
end

-- all observations for an entry, oldest first
local function ObsLines(e)
  local list = {}
  for id, t in pairs(e.obs or {}) do
    local text = ns.ObsText(e, id)
    if text then list[#list + 1] = { t = t, text = text } end
  end
  table.sort(list, function(a, b) return a.t < b.t end)
  return list
end

-- append lines that aren't in the notes yet; returns how many were added
local function AppendObs(e)
  e.notes = e.notes or {}
  local text = e.notes[Me()] or ""
  local added = 0
  for _, o in ipairs(ObsLines(e)) do
    local line = "- " .. o.text
    if not text:find(line, 1, true) then
      text = text .. ((text ~= "" and not text:find("\n$")) and "\n" or "") .. line
      added = added + 1
    end
  end
  if added > 0 then e.notes[Me()] = text end
  return added
end

local obsBtn = CreateFrame("Button", nil, page)
obsBtn:SetSize(170, 18)
obsBtn:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -4)
local obsTxt = Text(obsBtn, 10, C.tan)
obsTxt:SetPoint("LEFT")
obsTxt:SetJustifyV("MIDDLE")
obsBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:AddLine("Field observations", C.gold[1], C.gold[2], C.gold[3])
  GameTooltip:AddLine("Things you've noticed while fighting it, like spells it cast at you and how it attacks. Click to write any missing ones into your notes.", 1, 1, 1, true)
  GameTooltip:Show()
end)
obsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- emote buttons
local rpHead = UI.SectionHeader(page, "ROLEPLAY")
rpHead:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -28)
rpHead:SetWidth(PAGE_W)

local function RPButton(label, x, y, w)
  local b = CreateFrame("Button", nil, page)
  b:SetSize(w, 24)
  b:SetPoint("TOPLEFT", rpHead, "BOTTOMLEFT", x, y)
  b.bg = Fill(b, "BACKGROUND", C.panel2, 1)
  b.bg:SetAllPoints()
  Border(b, C.tanDim, 0.8)
  b.text = Text(b, 11, C.tan, "CENTER")
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetText(label)
  b:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
    GameTooltip:Hide()
  end)
  return b
end

local bw = math.floor((PAGE_W - 12) / 4)
local buttons = {}
for i, kind in ipairs({ "Sketch", "Study", "Record" }) do
  local b = RPButton(kind, (i - 1) * (bw + 4), -8, bw)
  b:SetScript("OnEnter", function(self)
    if not current then return end
    self.bg:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1)
    self.pending = Pick(kind, current)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Emote", C.gold[1], C.gold[2], C.gold[3])
    GameTooltip:AddLine(Me() .. " " .. self.pending, 1, 0.5, 0.25, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnClick", function(self)
    if current then SendChat(self.pending or Pick(kind, current), "EMOTE") end
    self.pending = current and Pick(kind, current)
  end)
  buttons[kind] = b
end

-- Say your notes out loud (first lines, chat limit is 255 per message)
local function Chunks(text, max)
  local out = {}
  text = text:gsub("\n+", " ")
  while #text > 0 and #out < 3 do
    if #text <= max then out[#out + 1] = text break end
    local cut = text:sub(1, max):match("^.*()[%.%!%?]%s") or text:sub(1, max):match("^.*()%s") or max
    out[#out + 1] = text:sub(1, cut):gsub("%s+$", "")
    text = text:sub(cut + 1):gsub("^%s+", "")
  end
  return out
end

local readBtn = RPButton("Read aloud", 3 * (bw + 4), -8, bw)
readBtn:SetScript("OnEnter", function(self)
  self.bg:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:AddLine("Say your notes", C.gold[1], C.gold[2], C.gold[3])
  GameTooltip:AddLine("Reads the start of your notes in /say (up to 3 lines).", 1, 1, 1, true)
  GameTooltip:Show()
end)
readBtn:SetScript("OnClick", function()
  local t = edit:GetText()
  if t == "" then
    ns.Print("write some notes first.")
    return
  end
  for _, line in ipairs(Chunks(t, 250)) do SendChat(line, "SAY") end
end)

-- auto emote toggle
local auto = CreateFrame("CheckButton", nil, page)
auto:SetSize(16, 16)
auto:SetPoint("TOPLEFT", rpHead, "BOTTOMLEFT", 2, -42)
local autoBg = Fill(auto, "BACKGROUND", C.inset, 1)
autoBg:SetAllPoints()
Border(auto, C.tanDim, 0.9)
local autoMark = Fill(auto, "ARTWORK", C.tan, 1)
autoMark:SetPoint("TOPLEFT", 4, -4)
autoMark:SetPoint("BOTTOMRIGHT", -4, 4)
local autoText = Text(page, 11, C.text)
autoText:SetPoint("LEFT", auto, "RIGHT", 8, 0)
autoText:SetJustifyV("MIDDLE")
autoText:SetText("Offer an emote when research levels up (one click)")
auto:SetScript("OnClick", function()
  ns.db.settings.rpAuto = not ns.db.settings.rpAuto
  autoMark:SetShown(ns.db.settings.rpAuto)
end)

-- auto observations toggle
local auto2 = CreateFrame("CheckButton", nil, page)
auto2:SetSize(16, 16)
auto2:SetPoint("TOPLEFT", auto, "BOTTOMLEFT", 0, -8)
Fill(auto2, "BACKGROUND", C.inset, 1):SetAllPoints()
Border(auto2, C.tanDim, 0.9)
local auto2Mark = Fill(auto2, "ARTWORK", C.tan, 1)
auto2Mark:SetPoint("TOPLEFT", 4, -4)
auto2Mark:SetPoint("BOTTOMRIGHT", -4, 4)
local auto2Text = Text(page, 11, C.text)
auto2Text:SetPoint("LEFT", auto2, "RIGHT", 8, 0)
auto2Text:SetJustifyV("MIDDLE")
auto2Text:SetText("Write field observations into my notes automatically")
auto2:SetScript("OnClick", function()
  ns.db.settings.autoObs = not ns.db.settings.autoObs
  auto2Mark:SetShown(ns.db.settings.autoObs)
end)

------------------------------------------------------------------------
local function UpdateObsButton(e)
  local total, missing = 0, 0
  local text = e.notes and e.notes[Me()] or ""
  for _, o in ipairs(ObsLines(e)) do
    total = total + 1
    if not text:find("- " .. o.text, 1, true) then missing = missing + 1 end
  end
  if total == 0 then
    obsTxt:SetText(MUTED .. "No field observations yet|r")
  elseif missing > 0 then
    obsTxt:SetText("+ Add " .. missing .. " field observation" .. (missing == 1 and "" or "s"))
  else
    obsTxt:SetText(MUTED .. total .. " observation" .. (total == 1 and "" or "s") .. " in notes|r")
  end
end

obsBtn:SetScript("OnClick", function()
  if not current then return end
  if AppendObs(current) > 0 then ns.FillMyNotes(current, true) end
end)

function ns.FillMyNotes(e, force)
  local same = current == e
  current = e
  local n = e.notes and e.notes[Me()] or ""
  UpdateObsButton(e)
  auto2Mark:SetShown(ns.db.settings.autoObs ~= false)
  -- don't disturb typing unless the text changed underneath us
  if same and not force and edit:GetText() == n then
    autoMark:SetShown(ns.db.settings.rpAuto and true or false)
    return
  end
  local typing = same and edit:HasFocus()
  edit:SetText(n)
  if typing then
    edit:SetCursorPosition(#n)
  else
    edit:SetCursorPosition(0)
    scroll:SetVerticalScroll(0)
  end
  placeholder:SetShown(n == "")
  author:SetText(MUTED .. "Written by|r " .. TAN .. Me() .. "|r")
  autoMark:SetShown(ns.db.settings.rpAuto and true or false)
end

-- Called by the research level-up handler
local AUTO = {
  [2] = { -- first kill: a new entry
    "makes a note of %s in a worn field journal. A new entry.",
    "flips to a blank page and writes a fresh heading: %s.",
    "crouches over %s's remains, sketching its outline into the journal.",
    "pulls out the journal, licks a pencil, and starts a new page on %s.",
    "marks %s down in the journal with a small, satisfied tick.",
  },
  [3] = { -- how it fights
    "pauses to jot down how %s fights, underlining a few words twice.",
    "scribbles a few hurried lines about the way %s moves and strikes.",
    "notes where %s is weakest, tapping the page thoughtfully.",
    "adds a margin note on %s: what worked, and what nearly didn't.",
    "sketches a quick diagram of how %s attacks, arrows and all.",
  },
  [4] = { -- what it carries
    "adds a careful list of what %s carries to the journal.",
    "tallies up what was taken from %s, counting twice to be sure.",
    "presses a small sample from %s between the journal's pages.",
    "writes down what %s leaves behind, with a rough guess at the odds.",
  },
  [5] = { -- mastered
    "closes the journal with a satisfied nod. The entry on %s is complete.",
    "underlines the final line on %s and blows the ink dry.",
    "stamps the page on %s with a small wax seal. Research complete.",
    "leafs back through every page on %s, then snaps the journal shut, pleased.",
  },
}
local lastAuto = {}
local function PickAuto(lvl, e)
  local list = AUTO[lvl]
  local i
  repeat i = math.random(#list) until #list < 2 or i ~= lastAuto[lvl]
  lastAuto[lvl] = i
  return list[i]:format(Called(e))
end
-- Level-ups happen the moment a creature dies, usually still in combat,
-- when the game may refuse addon chat. Hold the emote until combat ends;
-- if the game still blocks it, a click (pop-up or /hj emote) sends it.
-- Forever only lets addons post emotes from a real click or key press,
-- so the emote waits for one: the research pop-up, /hj emote or a keybind.
local pendingEmote

function ns.RPLevelUp(e, lvl)
  if not ns.db.settings.rpAuto or not AUTO[lvl] then return end
  if IsInInstance and IsInInstance() then return end
  pendingEmote = PickAuto(lvl, e)
end

function ns.PendingEmote() return pendingEmote end

-- send the waiting emote from a click or slash command
function ns.SendPendingEmote()
  if pendingEmote then
    local msg = pendingEmote
    pendingEmote = nil
    SendChat(msg, "EMOTE")
    return true
  end
  return false
end

local rpEv = CreateFrame("Frame")
rpEv:RegisterEvent("PLAYER_REGEN_ENABLED")
rpEv:RegisterEvent("ADDON_ACTION_BLOCKED")
rpEv:RegisterEvent("ADDON_ACTION_FORBIDDEN")
rpEv:SetScript("OnEvent", function(_, event, addon)
  if event == "PLAYER_REGEN_ENABLED" then
    return
  elseif addon == ADDON and lastSent then
    -- the game wants a real click for this one
    pendingEmote = lastSent
    lastSent = nil
    ns.Print("the game blocked the automatic emote. Click the research pop-up or type |cffffffff/hj emote|r to send it.")
  end
end)

-- called by the journal when a new observation is made
function ns.OnObservation(e)
  if ns.db.settings.autoObs ~= false then AppendObs(e) end
  if current == e and page:IsVisible() then ns.FillMyNotes(e) end
end
end)
