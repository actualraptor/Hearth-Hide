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

------------------------------------------------------------------------
-- The name in front of /say, /yell and /emote lines. The game builds it
-- through "sender name filters" (Total RP 3 uses one for RP names). Every
-- filter gets wrapped: for a stranger in a local channel the mask is
-- shown, anything else goes through untouched. The clickable link behind
-- the name still points at the real character.
------------------------------------------------------------------------
local LOCAL = { CHAT_MSG_SAY = true, CHAT_MSG_YELL = true, CHAT_MSG_EMOTE = true }

local function UnitByGUID(guid)
  local list = { "target", "mouseover", "focus" }
  for i = 1, 40 do list[#list + 1] = "nameplate" .. i end
  for _, u in ipairs(list) do
    local okG, g = pcall(UnitGUID, u)
    g = okG and S(g)
    if g and g == guid then return u end
  end
  return nil
end

-- the mask for a sender, or nil to leave the name alone
local function SenderMask(event, ...)
  if not (ns.db and ns.db.settings.chatNames and LOCAL[event]) then return nil end
  local args = { ... }
  local sender, guid = S(args[3]), S(args[13])
  if type(sender) ~= "string" or sender == "" then return nil end
  if type(guid) ~= "string" or not guid:find("^Player%-") then return nil end
  local okMe, myGuid = pcall(UnitGUID, "player")
  if okMe and S(myGuid) == guid then return nil end
  local short = sender:gsub("%-.*$", "")
  if short == UnitName("player") then return nil end
  local unit = type(guid) == "string" and UnitByGUID(guid) or UnitByName(short)
  if unit then
    local okP, isPlayer = pcall(UnitIsPlayer, unit)
    if not (okP and S(isPlayer)) or ns.IsKnownUnit(unit) then return nil end
    return ns.Mask(unit)
  end
  if not IsStrangerName(sender) then return nil end
  return "|cffbdb3a2Stranger|r"
end
ns.SenderMask = SenderMask

local CFU = _G.ChatFrameUtil
local mine = {}  -- our wrappers and our own filter

local function Wrap(orig)
  local w = function(event, ...)
    local ok, mask = pcall(SenderMask, event, ...)
    if ok and mask then return mask end
    return orig(event, ...)
  end
  mine[w] = true
  return w
end

local function WrapAll()
  if not (CFU and CFU.GetSenderNameFilters and CFU.RemoveSenderNameFilter and CFU.AddSenderNameFilter) then return end
  local ok, list = pcall(CFU.GetSenderNameFilters)
  if not ok or type(list) ~= "table" then return end
  local todo = {}
  for _, f in pairs(list) do
    if type(f) == "function" and not mine[f] then todo[#todo + 1] = f end
  end
  for _, f in ipairs(todo) do
    CFU.RemoveSenderNameFilter(f)
    CFU.AddSenderNameFilter(Wrap(f))
  end
end

local function Own(event, ...)
  if ns.chatDebug and LOCAL[event] then
    ns.chatDebug = ns.chatDebug - 1
    if ns.chatDebug <= 0 then ns.chatDebug = nil end
    local parts = { tostring(event) }
    for i = 1, math.min(select("#", ...), 14) do
      local v = select(i, ...)
      parts[#parts + 1] = i .. "=" .. ((issecretvalue and issecretvalue(v)) and "<secret>" or tostring(v))
    end
    ns.Print("chat hook: " .. table.concat(parts, "  "):gsub("|", "||"))
  end
  local ok, mask = pcall(SenderMask, event, ...)
  if ok and mask then return mask end
  return nil
end
mine[Own] = true

function ns.SetupChatNames()
  -- only hook chat at all when the (experimental) setting is on
  if not (ns.db and ns.db.settings.chatNames) then return end
  if not (CFU and CFU.AddSenderNameFilter) or ns.chatNamesReady then return end
  ns.chatNamesReady = true
  -- only our own filter; other addons' filters (Total RP 3's) are left alone
  CFU.AddSenderNameFilter(Own)
end
