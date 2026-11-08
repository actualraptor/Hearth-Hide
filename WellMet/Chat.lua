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
-- The name in front of /say, /yell and /emote lines. Nothing in the
-- game's chat code is replaced: after a line has been added, if it's a
-- local line from a stranger, the chat box's own TransformMessages swaps
-- the visible name for the mask. Every chat line carries a hidden player
-- link that names its channel ("SAY", "CHANNEL", "GUILD"...), so other
-- channels are recognised and left alone straight away.
------------------------------------------------------------------------
local LOCAL = { SAY = true, YELL = true, EMOTE = true }

-- the mask for a sender, or nil to leave the name alone
local function SenderMask(sender)
  if type(sender) ~= "string" or sender == "" then return nil end
  -- chat links on Forever carry "First Surname" (maybe with "-Realm")
  local short = sender:gsub("%-.*$", "")
  local first = short:match("^(%S+)") or short
  local myFull, myFirst = ns.UnitNames("player")
  if short == myFull or short == myFirst or first == myFirst then return nil end
  local unit = UnitByName(short)
  if unit then
    local okP, isPlayer = pcall(UnitIsPlayer, unit)
    if not (okP and S(isPlayer)) then return nil end
    local okM, me = pcall(UnitIsUnit, unit, "player")
    if okM and S(me) then return nil end
    if ns.IsKnownUnit(unit) then return nil end
    return ns.Mask(unit)
  end
  -- can't see them: go by who you've met (stored as "First-Realm")
  local realm = sender:match("%-(.+)$")
  if not IsStrangerName(first .. (realm and ("-" .. realm) or "")) then return nil end
  return "|cffbdb3a2Stranger|r"
end
ns.SenderMask = SenderMask

-- "…|Hplayer:Ashe-Realm:123:SAY|h[Ashe Kern]|h says: hi" -> the masked line,
-- or nil when nothing should change
local function MaskLine(text)
  if type(text) ~= "string" then return nil end
  local a, b, sender, kind, shown = text:find("|Hplayer:([^:|]+):[^:|]*:(%u+)[^|]*|h(.-)|h")
  if not a or not LOCAL[kind] then return nil end
  local mask = SenderMask(sender)
  if not mask then return nil end
  local plain = shown:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  local label = plain:find("%[") and ("[" .. mask .. "]") or mask
  -- keep the link itself (whisper, invite, menu), change only what it shows
  local linkStart = text:find("|h", a + 1, true)
  return text:sub(1, linkStart + 1) .. label .. text:sub(b - 1)
end
ns.MaskLine = MaskLine

-- EllesmereUI's chat draws its own copy of every line on top of the game's
-- (and keeps the two lined up for link clicks), so this can't work there
function ns.OtherChatAddon()
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  return loaded and loaded("EllesmereUIChat") and "EllesmereUI chat" or nil
end

local function OnAddMessage(frame, text)
  if not (ns.db and ns.db.settings.localNames) then return end
  if ns.OtherChatAddon() then return end
  if ns.chatDebug and ns.chatDebug > 0 and not ns.inDebugPrint then
    local secret = issecretvalue and issecretvalue(text)
    local raw = (not secret and type(text) == "string") and text or nil
    if secret or (raw and (raw:find("says") or raw:find("yells") or raw:find("Hplayer"))) then
      ns.chatDebug = ns.chatDebug - 1
      ns.inDebugPrint = true
      ns.Print(("[%s] %s"):format(frame:GetName() or "?", secret and "<secret line>" or
        raw:gsub("|", "!"):sub(1, 140)))
      ns.inDebugPrint = false
    end
  end
  if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
  if not text:find("|Hplayer:", 1, true) then return end
  local okL, masked = pcall(MaskLine, text)
  if ns.chatDebug and ns.chatDebug > 0 and not ns.inDebugPrint then
    local _, _, who, kind = text:find("|Hplayer:([^:|]+):[^:|]*:(%u+)")
    ns.inDebugPrint = true
    ns.Print(("line from %s in %s: %s, transform=%s"):format(tostring(who), tostring(kind),
      (okL and masked) and "masked" or "left alone", frame.TransformMessages and "yes" or "MISSING"))
    ns.chatDebug2 = true
    ns.inDebugPrint = false
  end
  if not okL or not masked or not frame.TransformMessages then return end
  -- find the stored line by its link (name + line id are unique), since a
  -- chat addon may store a restyled copy of the text or add it a moment
  -- later; mask that copy
  local key = text:match("(|Hplayer:[^:|]+:[^:|]*:)")
  if not key then return end
  local function Try(attempt)
    local changed, seen, kinds = 0, 0, {}
    local function TransformIn(target)
    pcall(target.TransformMessages, target,
      function(entry)
        seen = seen + 1
        local msg = type(entry) == "table" and entry.message or entry
        kinds[type(entry)] = true
        return type(msg) == "string" and not (issecretvalue and issecretvalue(msg))
          and msg:find(key, 1, true) ~= nil
      end,
      function(entry, ...)
        -- this client passes the line itself and wants the new line back;
        -- older ones pass a table to edit in place
        if type(entry) == "table" then
          local m = MaskLine(entry.message)
          if m then entry.message = m changed = changed + 1 end
          return entry, ...
        end
        local m = type(entry) == "string" and MaskLine(entry)
        if m then changed = changed + 1 return m, ... end
        return entry, ...
      end)
    end
    TransformIn(frame)
    -- the line already drawn on screen: find its text and mask that too
    local shown = 0
    local function Fix(fs)
      if not (fs and fs.GetObjectType and fs:GetObjectType() == "FontString") then return end
      local okT, t = pcall(fs.GetText, fs)
      if not okT or type(t) ~= "string" or (issecretvalue and issecretvalue(t)) then return end
      if not t:find(key, 1, true) then return end
      local m = MaskLine(t)
      if m then pcall(fs.SetText, fs, m) shown = shown + 1 end
    end
    for _, fs in ipairs(frame.visibleLines or {}) do Fix(fs) end
    local holder = frame.FontStringContainer or frame
    if holder.GetRegions then for _, r in ipairs({ holder:GetRegions() }) do Fix(r) end end
    if changed > 0 or shown > 0 then
      if frame.MarkDisplayDirty then pcall(frame.MarkDisplayDirty, frame) end
      if frame.RefreshDisplay then pcall(frame.RefreshDisplay, frame) end
    end
    if ns.chatDebug2 then ns.Print(("  on screen: %d line(s) fixed"):format(shown)) end
    if ns.chatDebug2 then
      local k = {}
      for t in pairs(kinds) do k[#k + 1] = t end
      local n = frame.GetNumMessages and frame:GetNumMessages() or "?"
      ns.inDebugPrint = true
      ns.Print(("try %d: swapped %d of %d stored line(s) [%s], frame has %s"):format(attempt, changed, seen, table.concat(k, ","), tostring(n)))
      if changed == 0 and frame.GetMessageInfo and type(n) == "number" and n > 0 then
        local okI, last = pcall(frame.GetMessageInfo, frame, n)
        if okI and type(last) == "string" and not (issecretvalue and issecretvalue(last)) then
          ns.Print("  last stored: " .. last:gsub("|", "!"):sub(1, 120))
        end
      end
      ns.inDebugPrint = false
      if frame.GetNumMessages and frame.GetMessageInfo then
        for i = frame:GetNumMessages(), math.max(1, frame:GetNumMessages() - 8), -1 do
          local okI, m = pcall(frame.GetMessageInfo, frame, i)
          if okI and type(m) == "string" and not (issecretvalue and issecretvalue(m)) and m:find(key, 1, true) then
            ns.Print("  saved now: " .. m:gsub("|", "!"):sub(1, 110))
            break
          end
        end
      end
      if attempt >= 3 then ns.chatDebug2 = nil end
    end
    return changed > 0
  end
  local told = false
  local function SafeTry(n)
    local ok, err = pcall(Try, n)
    if not ok and not told then
      told = true
      ns.Print("|cffff6060error masking a chat line:|r " .. tostring(err))
    end
  end
  SafeTry(1)
  -- the chat box draws new lines a moment later: fix what's on screen then,
  -- and once more shortly after in case it redraws from its saved copy
  C_Timer.After(0, function() SafeTry(2) end)
  C_Timer.After(0.15, function() SafeTry(3) end)
end

local hookedFrames = {}
local function HookFrame(frame)
  if not frame or hookedFrames[frame] or not frame.AddMessage then return end
  hookedFrames[frame] = true
  hooksecurefunc(frame, "AddMessage", function(self, text) OnAddMessage(self, text) end)
end

function ns.SetupChatNames()
  for i = 1, (NUM_CHAT_WINDOWS or 10) do HookFrame(_G["ChatFrame" .. i]) end
end
