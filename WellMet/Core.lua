local ADDON, ns = ...

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
-- Forever hides some values from addons ("secret" values). S() turns those
-- into nil so nothing ever errors on them.
local function S(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end
ns.S = S

local function Print(msg)
  print("|cffd8b066Well Met|r: " .. msg)
end
ns.Print = Print

local DEFAULTS = {
  plates = true,          -- hide strangers' names on nameplates
  tooltips = true,        -- ...and in tooltips (incl. Total RP 3)
  rpLine = true,          -- tooltip line: in character / out of character / no TRP3
  overhead = true,        -- turn off the game's floating names above heads
  petNames = true,
  chatEmotes = true,      -- "You thank the Human woman." instead of their name        -- ...and the "<Owner's Pet>" labels on pets and totems
  style = "race",         -- "race" (Human woman) or "stranger"
  knowGuild = true,       -- guildmates count as known
  knowGroup = true,       -- party / raid members count as known
  knowFriends = true,     -- friends list counts as known
  announce = true,        -- chat line when you learn someone's name
  targetFrame = true,     -- ...and on your target frame
  button = true,          -- show the introduce button
  btnAttach = true,       -- show it on your target frame when you target a player
  btnOffset = nil,
  btnPos = nil,
}

------------------------------------------------------------------------
-- Names
------------------------------------------------------------------------
local myRealm
local function Realm()
  if not myRealm or myRealm == "" then myRealm = (GetNormalizedRealmName and GetNormalizedRealmName()) or "" end
  return myRealm
end

-- "Name-Realm" for any spelling we get (chat senders, unit names)
local function FullName(name, realm)
  name = S(name)
  if type(name) ~= "string" or name == "" then return nil end
  if name:find("-", 1, true) then return name end
  realm = S(realm)
  if type(realm) ~= "string" or realm == "" then realm = Realm() end
  return name .. "-" .. realm
end
ns.FullName = FullName

-- WoW Forever: UnitName gives (first name, surname), not (name, realm),
-- so the realm comes from the GUID instead.
local function UnitFull(unit)
  local ok, name = pcall(UnitName, unit)
  if not ok then return nil end
  local realm
  local guid = S(UnitGUID(unit))
  if guid and GetPlayerInfoByGUID then
    local okI, _, _, _, _, _, gname, grealm = pcall(GetPlayerInfoByGUID, guid)
    if okI then
      grealm = S(grealm)
      if type(grealm) == "string" and grealm ~= "" then realm = grealm:gsub("%s", "") end
      gname = S(gname)
      if type(gname) == "string" and gname ~= "" and not S(name) then name = gname end
    end
  end
  return FullName(name, realm)
end
ns.UnitFull = UnitFull

-- "Joey Candleflame" (first + surname) and "Joey"
function ns.UnitNames(unit)
  local ok, first, surname = pcall(UnitName, unit)
  first, surname = ok and S(first), ok and S(surname)
  if type(first) ~= "string" or first == "" then return nil end
  if type(surname) == "string" and surname ~= "" and not surname:find("-", 1, true) then
    return first .. " " .. surname, first, surname
  end
  return first, first, nil
end

-- Total RP 3 profile of another player, if TRP3 knows them
function ns.TRP3Profile(full)
  if not (TRP3_API and TRP3_API.register and TRP3_API.register.getUnitIDCurrentProfile) then return nil end
  local ok, profile = pcall(TRP3_API.register.getUnitIDCurrentProfile, full)
  if ok and type(profile) == "table" then return profile.characteristics end
  return nil
end

------------------------------------------------------------------------
-- Who you know
------------------------------------------------------------------------
local cdb -- per character

function ns.IsKnownName(full)
  return full ~= nil and cdb ~= nil and cdb.known[full] ~= nil
end

function ns.IsKnownUnit(unit)
  if not cdb then return true end
  local okP, isPlayer = pcall(UnitIsPlayer, unit)
  if not okP or not S(isPlayer) then return true end -- only players get hidden
  local okU, me = pcall(UnitIsUnit, unit, "player")
  if okU and S(me) then return true end
  local full = UnitFull(unit)
  if not full then return true end -- can't tell (secret): never hide by mistake
  if cdb.known[full] then return true end
  local st = ns.db.settings
  if st.knowGroup then
    local okG, inGroup = pcall(function() return UnitInParty(unit) or UnitInRaid(unit) end)
    if okG and S(inGroup) then return true end
  end
  if st.knowGuild and UnitIsInMyGuild then
    local okI, inGuild = pcall(UnitIsInMyGuild, unit)
    if okI and S(inGuild) then return true end
  end
  if st.knowFriends and C_FriendList and C_FriendList.IsFriend then
    local guid = S(UnitGUID(unit))
    if guid then
      local okF, friend = pcall(C_FriendList.IsFriend, guid)
      if okF and S(friend) then return true end
    end
  end
  return false
end

local function DisplayName(full)
  local ch = ns.TRP3Profile(full)
  if ch and type(ch.FN) == "string" and ch.FN ~= "" then
    return ch.FN .. ((type(ch.LN) == "string" and ch.LN ~= "") and (" " .. ch.LN) or "")
  end
  return (full:gsub("%-.*$", ""))
end
ns.DisplayName = DisplayName

function ns.Learn(full, how)
  if not full or not cdb or cdb.known[full] then return end
  cdb.known[full] = { t = time(), how = how }
  if ns.db.settings.announce and how ~= "manual" then
    Print("you now know |cffffffff" .. DisplayName(full) .. "|r.")
  end
  if ns.RefreshPlates then ns.RefreshPlates() end
  if ns.UpdateButton then ns.UpdateButton() end
end

function ns.Forget(full)
  if not full or not cdb then return end
  cdb.known[full] = nil
  if ns.RefreshPlates then ns.RefreshPlates() end
  if ns.UpdateButton then ns.UpdateButton() end
end

function ns.KnownCount()
  local n = 0
  for _ in pairs(cdb and cdb.known or {}) do n = n + 1 end
  return n
end

function ns.ForgetAll()
  if cdb then wipe(cdb.known) end
  if ns.RefreshPlates then ns.RefreshPlates() end
  if ns.UpdateButton then ns.UpdateButton() end
end

------------------------------------------------------------------------
-- Hearing a name: someone says their own name in /say, /yell, /emote or a
-- whisper ("Name's Raptor."). Their character name and their Total RP 3
-- first or full name all count.
------------------------------------------------------------------------
local function NameByte(b)
  return b and (b >= 128 or (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122))
end

-- whole-word, case-insensitive
local function SaysWord(text, word)
  if type(word) ~= "string" or #word < 2 then return false end
  local lt, lw = text:lower(), word:lower()
  local i, j = lt:find(lw, 1, true)
  while i do
    if not NameByte(lt:byte(i - 1)) and not NameByte(lt:byte(j + 1)) then return true end
    i, j = lt:find(lw, i + 1, true)
  end
  return false
end

local function OnChat(msg, sender)
  msg, sender = S(msg), S(sender)
  if type(msg) ~= "string" or type(sender) ~= "string" then return end
  local full = FullName(sender)
  if not full or ns.IsKnownName(full) then return end
  local me = UnitFull("player")
  if full == me then return end
  local charName = full:gsub("%-.*$", "")
  local said = SaysWord(msg, charName)
  if not said then
    local ch = ns.TRP3Profile(full)
    if ch then
      said = SaysWord(msg, ch.FN) or (type(ch.FN) == "string" and type(ch.LN) == "string" and SaysWord(msg, ch.FN .. " " .. ch.LN))
    end
  end
  if said then ns.Learn(full, "said") end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
for _, e in ipairs({ "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" }) do
  ev:RegisterEvent(e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    WellMetDB = WellMetDB or {}
    WellMetDB.settings = WellMetDB.settings or {}
    for k, v in pairs(DEFAULTS) do
      if WellMetDB.settings[k] == nil then WellMetDB.settings[k] = v end
    end
    WellMetCharDB = WellMetCharDB or {}
    WellMetCharDB.known = WellMetCharDB.known or {}
    ns.db, ns.cdb, cdb = WellMetDB, WellMetCharDB, WellMetCharDB
    -- 1.0 saved surnames where the realm belongs ("Joey-Candleflame")
    if (cdb.v or 1) < 2 and Realm() ~= "" then
      local fixed = {}
      for full, info in pairs(cdb.known) do
        fixed[(full:gsub("%-.*$", "")) .. "-" .. Realm()] = info
      end
      cdb.known, cdb.v = fixed, 2
    end
    if ns.OnLoad then ns.OnLoad() end
    return
  end
  if cdb then OnChat(a1, a2) end
end)

------------------------------------------------------------------------
-- Line packs: other addons (like a personal one of your own) can add
-- introduction lines for a character without changing Well Met itself.
--   WellMet_AddLines("Raptor", { 'nods. "{first}."', ... })
-- The key is a character name, or "Name-Realm".
------------------------------------------------------------------------
ns.packs = {}
function WellMet_AddLines(who, lines)
  if type(who) ~= "string" or type(lines) ~= "table" then return end
  ns.packs[who] = ns.packs[who] or {}
  for _, l in ipairs(lines) do
    if type(l) == "string" and l ~= "" then table.insert(ns.packs[who], l) end
  end
end

function ns.PackLines()
  local full = UnitFull("player")
  local name = full and full:gsub("%-.*$", "")
  return (full and ns.packs[full]) or (name and ns.packs[name]) or nil
end

------------------------------------------------------------------------
-- Keybindings and slash commands
------------------------------------------------------------------------
BINDING_HEADER_WELLMET = "Well Met"
BINDING_NAME_WELLMET_INTRODUCE = "Introduce yourself"
BINDING_NAME_WELLMET_TOGGLE_TARGET = "Mark target as known / stranger"

local function ToggleTarget()
  local okP, isPlayer = pcall(UnitIsPlayer, "target")
  if not (okP and S(isPlayer)) then Print("target a player first.") return end
  local full = UnitFull("target")
  if not full then Print("the game won't say who that is here.") return end
  if ns.IsKnownName(full) then
    ns.Forget(full)
    Print(DisplayName(full) .. " is a stranger again.")
  else
    ns.Learn(full, "manual")
    Print("you now know |cffffffff" .. DisplayName(full) .. "|r.")
  end
end
ns.ToggleTarget = ToggleTarget

-- for other addons (Mannerisms uses these for {target})
function WellMet_IsStranger(unit)
  local st = ns.db and ns.db.settings
  if not st or not (st.plates or st.targetFrame or st.tooltips) then return false end
  return not ns.IsKnownUnit(unit)
end
function WellMet_Mask(unit) return ns.Mask and ns.Mask(unit) or "Stranger" end

function WellMet_Introduce() if ns.Introduce then ns.Introduce() end end
function WellMet_ToggleTarget() ToggleTarget() end

SLASH_WELLMET1 = "/wellmet"
SLASH_WELLMET2 = "/wmet"
SlashCmdList.WELLMET = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
  if cmd == "" or cmd == "settings" or cmd == "config" then
    if ns.ToggleSettings then ns.ToggleSettings() end
  elseif cmd == "intro" or cmd == "introduce" then
    WellMet_Introduce()
  elseif cmd == "know" or cmd == "toggle" or cmd == "forget" then
    ToggleTarget()
  elseif cmd == "names" then
    if ns.NameCVars then ns.NameCVars() end
  elseif cmd == "debug" then
    if not ns.Debug then Print("debug isn't loaded - Plates.lua failed to load?") return end
    local ok, err = pcall(ns.Debug)
    if not ok then Print("debug error: " .. tostring(err)) end
  elseif cmd == "list" then
    local names = {}
    for full in pairs(cdb.known) do names[#names + 1] = DisplayName(full) end
    table.sort(names)
    Print(#names .. " known: " .. (#names > 0 and table.concat(names, ", ") or "nobody yet"))
  elseif cmd == "forgetall confirm" then
    ns.ForgetAll()
    Print("everyone is a stranger again.")
  elseif cmd == "forgetall" then
    Print("this forgets everyone this character has met. Type |cffffffff/wellmet forgetall confirm|r.")
  else
    Print("/wellmet settings, /wellmet intro, /wellmet know (toggle your target), /wellmet list, /wellmet forgetall")
  end
end
