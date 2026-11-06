local ADDON, ns = ...
local S = ns.S

------------------------------------------------------------------------
-- The game's own emote lines name people: "You thank Ashe Kern.",
-- "Ashe Kern waves at you." While they're strangers, those names become
-- "the Human woman" / "A Human woman".
------------------------------------------------------------------------
local function Plain(mask) return (mask:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- find a unit we can see with this name (target, mouseover, nameplates...)
local function UnitByName(name)
  if type(name) ~= "string" or name == "" then return nil end
  name = name:gsub("%-.*$", "")
  local list = { "target", "mouseover", "focus", "targettarget" }
  for i = 1, 40 do list[#list + 1] = "nameplate" .. i end
  for _, u in ipairs(list) do
    local okE, exists = pcall(UnitExists, u)
    if okE and S(exists) then
      local full, first = ns.UnitNames(u)
      if name == first or name == full then return u end
    end
  end
  return nil
end

local function Article(word, capital)
  local v = word:sub(1, 1):lower():match("[aeiou]")
  if capital then return v and "An " or "A " end
  return "the "
end

-- what to call a stranger in a sentence
local function Call(unit, atStart)
  local who = unit and Plain(ns.Mask(unit)) or "Stranger"
  if who == "Stranger" then return atStart and "A stranger" or "a stranger" end
  return Article(who, atStart) .. who
end

local function IsStrangerName(name, unit)
  if unit then return not ns.IsKnownUnit(unit) end
  local full = ns.FullName(name)
  return full ~= nil and not ns.IsKnownName(full) and full ~= ns.UnitFull("player")
end

-- swap every whole-word occurrence of `name` in `msg`
-- withSurname: also take a capitalised word right after the name (Forever
-- surnames), for people we can't see and so can't look up
local function Swap(msg, name, unit, withSurname)
  local out, pos = {}, 1
  while true do
    local i, j = ns.FindWord(msg, name, pos)
    if not i then break end
    if withSurname then
      local sur = msg:sub(j + 1):match("^ %u[%a']+")
      if sur then j = j + #sur end
    end
    out[#out + 1] = msg:sub(pos, i - 1)
    out[#out + 1] = Call(unit, i == 1)
    pos = j + 1
  end
  if pos == 1 then return msg end
  out[#out + 1] = msg:sub(pos)
  return table.concat(out)
end

local function Filter(_, event, msg, author, ...)
  if not ns.db or not ns.db.settings.chatEmotes then return false end
  local okM, m = pcall(function() return S(msg) end)
  if not okM or type(m) ~= "string" then return false end
  local changed = m
  -- the person doing the emote
  local sender = S(author)
  if type(sender) == "string" and sender ~= "" then
    local short = sender:gsub("%-.*$", "")
    local unit = UnitByName(short)
    if unit and not S(UnitIsPlayer(unit)) then unit = nil end
    local me = UnitName("player")
    if short ~= me and IsStrangerName(sender, unit) then
      local full = unit and ns.UnitNames(unit)
      if full and full ~= short then changed = Swap(changed, full, unit) end
      changed = Swap(changed, short, unit, not full)
    end
  end
  -- whoever the emote is aimed at: usually your target
  local okP, isPlayer = pcall(UnitIsPlayer, "target")
  if okP and S(isPlayer) and not ns.IsKnownUnit("target") then
    local full, first = ns.UnitNames("target")
    if full then changed = Swap(changed, full, "target") end
    if first and first ~= full then changed = Swap(changed, first, "target") end
  end
  if changed ~= m then return false, changed, author, ... end
  return false
end

if ChatFrame_AddMessageEventFilter then
  ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", Filter)
end
ns.ChatFilter = Filter
