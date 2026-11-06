local ADDON, ns = ...

local function S(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end
ns.S = S

function ns.Print(msg) print("|cffd8b066Mannerisms|r: " .. msg) end

-- run f, and say so in chat if it breaks
function ns.Safe(f, ...)
  local ok, err = pcall(f, ...)
  if not ok then ns.Print("|cffff6060error:|r " .. tostring(err)) end
  return ok
end

local function Copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = Copy(v) end
  return c
end
ns.Copy = Copy

local SETTINGS = {
  scale = 1,           -- ring size
  preview = true,      -- show the line you're about to send in the middle
  quickTap = 0.25,     -- a tap shorter than this leaves the ring open for clicking
}

------------------------------------------------------------------------
-- Who you are (Total RP 3 profile when there is one) and who you target
------------------------------------------------------------------------
local PRONOUNS = {
  he = { he = "he", him = "him", his = "his", himself = "himself" },
  she = { he = "she", him = "her", his = "her", himself = "herself" },
  they = { he = "they", him = "them", his = "their", himself = "themselves" },
}

local function Me()
  local me = {}
  local okN, name, surname = pcall(UnitName, "player")
  me.first = okN and S(name) or "Someone"
  surname = okN and S(surname)
  if type(surname) == "string" and surname ~= "" then me.last = surname end
  local okR, race = pcall(UnitRace, "player")
  me.race = okR and S(race) or nil
  local okC, class = pcall(UnitClass, "player")
  me.class = okC and S(class) or nil
  local okX, sex = pcall(UnitSex, "player")
  local pro = (okX and S(sex) == 3) and "she" or "he"
  if TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
    local ok, prof = pcall(TRP3_API.profile.getPlayerCurrentProfile)
    local ch = ok and type(prof) == "table" and prof.player and prof.player.characteristics
    if type(ch) == "table" then
      local function str(v) return (type(v) == "string" and v ~= "") and v or nil end
      me.first = str(ch.FN) or me.first
      me.last = str(ch.LN) or me.last
      me.title = str(ch.TI)
      me.race = str(ch.RA) or me.race
      me.class = str(ch.CL) or me.class
      for _, mi in ipairs(type(ch.MI) == "table" and ch.MI or {}) do
        local label = type(mi.NA) == "string" and mi.NA:lower() or ""
        local value = str(mi.VA)
        if value and label:find("pronoun") then
          local p = value:lower():match("^%s*(%a+)")
          if PRONOUNS[p] then pro = p elseif p == "her" then pro = "she" elseif p == "them" then pro = "they" end
        end
      end
    end
  end
  me.full = me.first .. (me.last and (" " .. me.last) or "")
  for k, v in pairs(PRONOUNS[pro]) do me[k] = v end
  return me
end
ns.Me = Me

-- how to call your target: their name, or "the dwarf man" while Well Met
-- says they're a stranger
local function TargetName()
  local okE, exists = pcall(UnitExists, "target")
  if not (okE and S(exists)) then return nil end
  local okM, isMe = pcall(UnitIsUnit, "target", "player")
  if okM and S(isMe) then return nil end
  local okP, isPlayer = pcall(UnitIsPlayer, "target")
  if okP and S(isPlayer) then
    if WellMet_IsStranger and WellMet_IsStranger("target") then
      local mask = WellMet_Mask and WellMet_Mask("target") or "stranger"
      mask = mask:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
      return "the " .. mask:lower()
    end
    if TRP3_API and TRP3_API.register and TRP3_API.register.getUnitIDCurrentProfile then
      local okU, name, realm = pcall(UnitName, "target")
      name = okU and S(name)
      local guid = S(UnitGUID("target"))
      local full = name
      if guid and GetPlayerInfoByGUID then
        local okI, _, _, _, _, _, gname, grealm = pcall(GetPlayerInfoByGUID, guid)
        grealm = okI and S(grealm)
        if name and (not grealm or grealm == "") then grealm = GetNormalizedRealmName and GetNormalizedRealmName() end
        if name and grealm then full = name .. "-" .. grealm:gsub("%s", "") end
      end
      local okT, prof = pcall(TRP3_API.register.getUnitIDCurrentProfile, full)
      local ch = okT and type(prof) == "table" and prof.characteristics
      if ch and type(ch.FN) == "string" and ch.FN ~= "" then return ch.FN end
    end
  end
  local okN, name = pcall(UnitName, "target")
  name = okN and S(name)
  if type(name) == "string" and name ~= "" then return name end
  return nil
end
ns.TargetName = TargetName

------------------------------------------------------------------------
-- Lines
------------------------------------------------------------------------
local function Fill(line, me)
  local missing = false
  local text = line:gsub("{(%a+)}", function(key)
    local v = me[key]
    if not v then missing = true return "" end
    return v
  end)
  if missing then return nil end
  return text
end

local lastPick = {}
-- a ready-to-send line for this slice, or nil
function ns.Pick(slice)
  if slice.kind == "game" then return slice.emote and ("/" .. slice.emote:lower()) or nil end
  if slice.kind ~= "emote" and slice.kind ~= "say" then return nil end
  local me = Me()
  me.target = TargetName()
  local usable = {}
  for i, line in ipairs(slice.lines or {}) do
    local text = Fill(line, me)
    if text and text ~= "" then usable[#usable + 1] = { i = i, text = text } end
  end
  if #usable == 0 then return nil end
  local c
  repeat c = usable[math.random(#usable)] until #usable < 2 or c.i ~= lastPick[slice]
  lastPick[slice] = c.i
  return c.text
end

function ns.Send(slice, text)
  if slice.kind == "game" then
    if not slice.emote or slice.emote == "" then return end
    local ok, err = pcall(DoEmote, slice.emote:upper())
    if not ok then ns.Print("couldn't do that emote: " .. tostring(err)) end
    return
  end
  text = text or ns.Pick(slice)
  if not text then
    ns.Print("no line on \"" .. (slice.label or "?") .. "\" fits right now" ..
      ((slice.lines and #slice.lines > 0) and " (some need a target)." or "."))
    return
  end
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  local ok, err = pcall(send, text, slice.kind == "say" and "SAY" or "EMOTE")
  if not ok then ns.Print("couldn't send that: " .. tostring(err)) end
end

------------------------------------------------------------------------
-- Rings
------------------------------------------------------------------------
function ns.RingForKey(slot)
  for id, r in pairs(ns.db.rings) do
    if r.key == slot then return id end
  end
  return nil
end

BINDING_HEADER_MANNERISMS = "Mannerisms"
for i = 1, 6 do _G["BINDING_NAME_MANNERISMS_RING" .. i] = "Open ring " .. i .. (i == 1 and " (main)" or "") end

function Mannerisms_Key(slot, keystate)
  if not ns.db then return end
  if ns.debug then ns.Print("key " .. slot .. " " .. tostring(keystate)) end
  local id = ns.RingForKey(slot)
  if not id then
    if keystate == "down" then ns.Print("no ring uses key " .. slot .. " yet. Pick one in /mm.") end
    return
  end
  if keystate == "down" then ns.Safe(ns.KeyDown, id) else ns.Safe(ns.KeyUp, id) end
end

local function Reset()
  ns.db.rings = Copy(ns.DEFAULT_RINGS)
  ns.db.root = ns.DEFAULT_ROOT
end
ns.Reset = Reset

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  MannerismsDB = MannerismsDB or {}
  local db = MannerismsDB
  db.settings = db.settings or {}
  for k, v in pairs(SETTINGS) do if db.settings[k] == nil then db.settings[k] = v end end
  ns.db = db
  if type(db.rings) ~= "table" or not next(db.rings) then Reset() end
  if ns.OnLoad then ns.OnLoad() end
end)

SLASH_MANNERISMS1 = "/mm"
SLASH_MANNERISMS2 = "/mannerisms"
SlashCmdList.MANNERISMS = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
  if cmd == "" or cmd == "edit" or cmd == "settings" then
    if ns.ToggleEditor then ns.ToggleEditor() end
  elseif cmd == "debug" then
    ns.debug = not ns.debug
    ns.Print("debug " .. (ns.debug and "on" or "off"))
  elseif cmd == "open" then
    ns.Open(ns.db.root, true)
  elseif cmd == "reset confirm" then
    Reset()
    if ns.EditorRefresh then ns.EditorRefresh() end
    ns.Print("rings are back to the defaults.")
  elseif cmd == "reset" then
    ns.Print("this replaces all your rings with the defaults. Type |cffffffff/mm reset confirm|r.")
  else
    ns.Print("/mm (edit rings), /mm open (open the main ring), /mm reset")
  end
end
