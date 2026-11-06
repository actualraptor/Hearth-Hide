local ADDON, ns = ...

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
-- Forever runs the modern client, where some values are "secret" (opaque)
-- in combat or in instances. S() turns those into nil so we never error.
-- UI files register their build functions here; they run once saved
-- settings are loaded, so the chosen theme is known while building.
ns.deferred = {}
function ns.Defer(fn) table.insert(ns.deferred, fn) end

local function S(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end
ns.S = S

local function Print(msg)
  print("|cffd1b27aHunter's Journal|r: " .. msg)
end
ns.Print = Print

------------------------------------------------------------------------
-- Research levels
------------------------------------------------------------------------
-- Level 1 = sighted. Kills needed for levels 2..5, by how tough the creature is.
ns.THRESHOLDS = {
  normal = { 1, 5, 10, 20 },
  elite  = { 1, 2, 4, 6 },
  rare   = { 1, 2, 3, 5 },
  boss   = { 1, 1, 2, 3 },
}
ns.MAX_LEVEL = 5
ns.LEVEL_NAMES = { "Sighted", "Slain", "Studied", "Catalogued", "Mastered" }
ns.UNLOCKS = {
  [2] = "Physiology and Taming",
  [3] = "Weaknesses and Abilities",
  [4] = "Materials",
  [5] = "Field Notes",
}

function ns.Tier(e)
  local c = e.class
  if c == "worldboss" then return "boss" end
  if c == "rare" or c == "rareelite" then return "rare" end
  if c == "elite" then return "elite" end
  return "normal"
end

function ns.Level(e)
  local t = ns.THRESHOLDS[ns.Tier(e)]
  local lvl = 1
  for i, need in ipairs(t) do
    if (e.kills or 0) >= need then lvl = i + 1 end
  end
  return lvl
end

-- kills still needed for the next level, or nil when mastered
function ns.KillsToNext(e)
  local lvl = ns.Level(e)
  if lvl >= ns.MAX_LEVEL then return nil end
  return ns.THRESHOLDS[ns.Tier(e)][lvl] - (e.kills or 0)
end

------------------------------------------------------------------------
-- Weakness analysis
------------------------------------------------------------------------
local function HasWord(name, word)
  return name:find("%f[%a]" .. word .. "%f[%A]") ~= nil
end

function ns.ElementHint(e)
  if not e.name then return nil end
  for _, hint in ipairs(ns.ELEMENT_HINTS) do
    for _, w in ipairs(hint.words) do
      if HasWord(e.name, w) then return hint end
    end
  end
  return nil
end

-- Returns { [schoolKey] = { stars = 0..3, observed = n } }
function ns.Weakness(e)
  local out = {}
  local t = ns.TYPES[e.type or ""] or {}
  local hint = ns.ElementHint(e)
  for _, sc in ipairs(ns.SCHOOLS) do
    local stars = 2
    if t.schools and t.schools[sc.key] then stars = t.schools[sc.key] end
    if hint and hint.schools[sc.key] then
      local v = hint.schools[sc.key]
      if e.type == "Elemental" then
        stars = v
      elseif v < 2 then
        stars = 1 -- a "fire" humanoid resists fire but isn't immune
      end
    end
    -- what you've actually seen in the field wins
    local d = e.dmg and e.dmg[sc.key]
    local observed = 0
    if d then
      observed = (d.h or 0) + (d.r or 0) + (d.i or 0)
      if (d.i or 0) >= 2 and (d.h or 0) == 0 then
        stars = 0
      elseif observed >= 6 then
        local resistRate = (d.r or 0) / observed
        if resistRate >= 0.35 then
          stars = math.min(stars, 1)
        elseif stars < 2 and (d.i or 0) == 0 and resistRate < 0.1 then
          stars = 2
        end
      end
    end
    out[sc.key] = { stars = stars, observed = observed }
  end
  return out, hint
end

function ns.Exploits(e)
  local t = ns.TYPES[e.type or ""]
  local list = {}
  if t then
    for _, x in ipairs(t.exploits) do list[#list + 1] = x end
  end
  if e.type == "Beast" and ns.GetFamily(e.family) then
    table.insert(list, 1, "Tame Beast")
  end
  if e.class == "worldboss" or e.class == "elite" or e.class == "rareelite" then
    list[#list + 1] = "(elites may resist crowd control)"
  end
  return list
end

------------------------------------------------------------------------
-- Database
------------------------------------------------------------------------
local db
ns.db = nil

local function InitDB()
  HuntersJournalDB = HuntersJournalDB or {}
  db = HuntersJournalDB
  db.entries = db.entries or {}
  db.names = db.names or {}
  db.settings = db.settings or {}
  if db.settings.toasts == nil then db.settings.toasts = true end
  if db.settings.minimap == nil then db.settings.minimap = 200 end
  if db.settings.plates == nil then db.settings.plates = true end
  if db.settings.tooltip == nil then db.settings.tooltip = true end
  if db.settings.rpAuto == nil then db.settings.rpAuto = false end
  local d = { plateAnchor = "TOP", plateX = 0, plateY = 0, plateScale = 1, toastSound = true,
              portraits = "model", mapPins = true, mapMinKills = 5, mapMaxPins = 20, mapPinSize = 22, mapBtnX = 0, mapBtnY = 0, followTarget = true, autoObs = true, paperTone = 0.65 }
  for k, v in pairs(d) do
    if db.settings[k] == nil then db.settings[k] = v end
  end
  -- 1.5: smaller map portraits by default, leather notebook look
  if not db.settings.v15 then
    db.settings.v15 = true
    if db.settings.mapPinSize == 28 then db.settings.mapPinSize = 22 end
  end
  if db.settings.theme == nil then db.settings.theme = "leather" end
  ns.db = db
end

local function NpcIdFromGUID(guid)
  guid = S(guid)
  if type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
  return nil
end
ns.NpcIdFromGUID = NpcIdFromGUID

local function ZoneName()
  local z = GetRealZoneText and GetRealZoneText() or GetZoneText()
  return S(z)
end

-- Read everything we can about a unit. nil if it isn't a creature we track.
local function ReadUnit(unit)
  local ok, info = pcall(function()
    if not UnitExists(unit) or UnitIsPlayer(unit) or UnitPlayerControlled(unit) then return nil end
    if not UnitCanAttack("player", unit) then return nil end
    local name = S(UnitName(unit))
    if type(name) ~= "string" or name == "" then return nil end
    local guid = S(UnitGUID(unit))
    return {
      guid = guid,
      id = NpcIdFromGUID(guid),
      name = name,
      level = S(UnitLevel(unit)),
      type = S(UnitCreatureType(unit)),
      family = S(UnitCreatureFamily(unit)),
      class = S(UnitClassification(unit)),
      boss = UnitIsBossMob and S(UnitIsBossMob(unit)) or nil,
      hp = S(UnitHealthMax(unit)),
    }
  end)
  if ok then return info end
  return nil
end
ns.ReadUnit = ReadUnit

local function KeyFor(info)
  if info.id then return tostring(info.id) end
  return db.names[info.name] or ("n:" .. info.name)
end

local function GetEntry(info, create)
  local key = KeyFor(info)
  local e = db.entries[key]
  -- a name-only entry learned its npc id: move it over
  if not e and info.id then
    local oldKey = db.names[info.name]
    if oldKey and oldKey:sub(1, 2) == "n:" and db.entries[oldKey] then
      e = db.entries[oldKey]
      db.entries[oldKey] = nil
      db.entries[key] = e
      e.id = info.id
    end
  end
  if not e and create then
    e = { name = info.name, id = info.id, kills = 0, seen = time(), zones = {},
          loot = {}, gather = {}, looted = 0, gathered = 0, dmg = {}, spells = {} }
    db.entries[key] = e
  end
  if e then
    e.key = key
    db.names[info.name] = key
  end
  return e
end
ns.GetEntry = GetEntry

local CLASS_RANK = { trivial = 0, minus = 0, normal = 1, elite = 2, rare = 3, rareelite = 4, worldboss = 5 }

local function UpdateEntry(e, info)
  e.name = info.name
  e.id = e.id or info.id
  e.type = info.type or e.type
  e.family = info.family or e.family
  if info.boss then e.boss = true end
  if info.class and (CLASS_RANK[info.class] or 0) >= (CLASS_RANK[e.class or ""] or -1) then
    e.class = info.class
  end
  local lvl = info.level
  if lvl and lvl > 0 then
    if not e.minLvl or lvl < e.minLvl then e.minLvl = lvl end
    if not e.maxLvl or lvl > e.maxLvl then e.maxLvl = lvl end
  elseif lvl == -1 then
    e.skull = true
  end
  if info.hp and info.hp > 0 and (not e.hp or info.hp > e.hp) then
    e.hp = info.hp
    e.hpLvl = lvl
  end
  local zone = ZoneName()
  if zone and zone ~= "" then e.zones[zone] = true end
end

------------------------------------------------------------------------
-- Observation
------------------------------------------------------------------------
local function Observe(unit)
  local info = ReadUnit(unit)
  if not info then return nil end
  local isNew = not db.entries[KeyFor(info)]
  local e = GetEntry(info, true)
  UpdateEntry(e, info)
  if isNew and ns.OnNewEntry then ns.OnNewEntry(e) end
  if ns.Refresh then ns.Refresh() end
  return e, info
end

local function IsTracked(unit)
  return unit == "target" or unit == "focus" or unit == "mouseover"
      or (type(unit) == "string" and unit:find("^nameplate%d+$") ~= nil)
end

------------------------------------------------------------------------
-- Kills
------------------------------------------------------------------------
local counted = {}   -- guid -> true (this session)
local engaged = {}   -- guid -> true when we fought it
local recent = {}    -- name -> list of { t = time, guid = guid|nil }
local live = {}      -- guid -> entry, creatures currently fighting you
local lastCast = {}  -- guid -> { name, t }
local lootQueue = {} -- recent kills waiting to be looted
local DEBUG = false

local function Debug(...)
  if DEBUG then print("|cffd1b27aHJ debug|r", ...) end
end

-- Field observations ("Cast Fireball at me. It burned hot.")
local function Obs(e, id)
  e.obs = e.obs or {}
  if e.obs[id] then return end
  e.obs[id] = time()
  Debug("observation", e.name, id)
  if ns.OnObservation then pcall(ns.OnObservation, e, id) end
end
ns.Obs = Obs

local function MatchRecent(name, guid)
  local list = recent[name]
  if not list then return false end
  local now = GetTime()
  for i = #list, 1, -1 do
    local r = list[i]
    if now - r.t > 4 then
      table.remove(list, i)
    elseif (guid == nil) ~= (r.guid == nil) then
      -- one source had a GUID, the other didn't: same kill reported twice
      table.remove(list, i)
      return true
    end
  end
  return false
end

local function RegisterKill(e, guid)
  if guid then
    if counted[guid] then return end
    counted[guid] = true
  end
  if MatchRecent(e.name, guid) then return end
  recent[e.name] = recent[e.name] or {}
  table.insert(recent[e.name], { t = GetTime(), guid = guid })

  if guid then live[guid] = nil end
  table.insert(lootQueue, { e = e, guid = guid, t = GetTime() })
  if #lootQueue > 10 then table.remove(lootQueue, 1) end
  Debug("kill", e.name, guid or "no guid")

  local before = ns.Level(e)
  e.kills = (e.kills or 0) + 1
  e.lastKill = time()
  if e.kills == 1 then
    e.firstKill = time()
    e.firstZone = ZoneName()
  end
  if ns.RecordSpot then pcall(ns.RecordSpot, e) end
  local after = ns.Level(e)
  if after > before and ns.OnLevelUp then ns.OnLevelUp(e, after) end
  if ns.Refresh then ns.Refresh() end
end

local function MarkEngaged(unit, guid)
  if not guid or engaged[guid] then return end
  local ok, yes = pcall(function()
    if not UnitAffectingCombat("player") and not UnitAffectingCombat("pet") then return false end
    if UnitIsUnit(unit, "target") or UnitIsUnit(unit, "pettarget") then return true end
    local t1 = S(UnitThreatSituation("player", unit))
    local t2 = UnitExists("pet") and S(UnitThreatSituation("pet", unit))
    return t1 ~= nil or (t2 ~= nil and t2 ~= false)
  end)
  if ok and yes then
    engaged[guid] = true
    local info = ReadUnit(unit)
    if info then live[guid] = GetEntry(info, true) end
  end
end

local function CheckUnit(unit)
  if not IsTracked(unit) then return end
  local ok, dead = pcall(UnitIsDead, unit)
  dead = ok and S(dead)
  local guid = S(UnitGUID(unit))
  if not dead then
    MarkEngaged(unit, guid)
    return
  end
  if not guid or counted[guid] or not engaged[guid] then return end
  local tapOk, denied = pcall(UnitIsTapDenied, unit)
  if tapOk and S(denied) then return end
  local info = ReadUnit(unit)
  if not info then
    -- dead units can fail UnitCanAttack; read the basics directly
    local name = S(UnitName(unit))
    if type(name) ~= "string" then return end
    info = { guid = guid, id = NpcIdFromGUID(guid), name = name }
  end
  local e = GetEntry(info, true)
  UpdateEntry(e, info)
  RegisterKill(e, guid)
end

-- "X dies, you gain N experience." as a fallback when no unit was visible
local XP_PATTERN
local function BuildXPPattern()
  local fmt = COMBATLOG_XPGAIN_FIRSTPERSON or "%s dies, you gain %d experience."
  fmt = fmt:gsub("([%(%)%.%[%]%+%-%*%?%^%$])", "%%%1")
  fmt = fmt:gsub("%%s", "(.+)"):gsub("%%d", "%%d+")
  XP_PATTERN = "^" .. fmt
end

local function OnXPMessage(msg)
  msg = S(msg)
  if type(msg) ~= "string" then return end
  if not XP_PATTERN then BuildXPPattern() end
  local name = msg:match(XP_PATTERN)
  if not name then return end
  local key = db.names[name]
  local e = key and db.entries[key]
  if not e then
    e = GetEntry({ name = name }, true)
    local zone = ZoneName()
    if zone then e.zones[zone] = true end
  end
  RegisterKill(e, nil)
end

------------------------------------------------------------------------
-- Combat observations: damage schools and abilities
------------------------------------------------------------------------
local SCHOOL_BY_MASK = {}
for _, sc in ipairs(ns.SCHOOLS) do SCHOOL_BY_MASK[sc.mask] = sc.key end

local function OnUnitCombat(unit, action, flag, amount, school)
  if not IsTracked(unit) or unit == "mouseover" then return end
  action, flag, school = S(action), S(flag), S(school)
  if not action or not school then return end
  local key = SCHOOL_BY_MASK[school]
  if not key then return end
  local guid = S(UnitGUID(unit))
  if not guid or not engaged[guid] then return end
  local info = ReadUnit(unit)
  if not info then return end
  local e = GetEntry(info, true)
  local d = e.dmg[key] or {}
  e.dmg[key] = d
  if action == "DODGE" or action == "PARRY" or action == "BLOCK" or action == "WOUND" and key == "physical" then
    e.swings = (e.swings or 0) + 1
    if action ~= "WOUND" then
      local k = action:lower()
      e.avoid = e.avoid or {}
      e.avoid[k] = (e.avoid[k] or 0) + 1
      if e.swings >= 15 and e.avoid[k] / e.swings >= 0.1 then Obs(e, k) end
    end
  end
  if action == "IMMUNE" then
    d.i = (d.i or 0) + 1
  elseif action == "RESIST" or flag == "RESIST" then
    d.r = (d.r or 0) + 1
  elseif action == "WOUND" then
    d.h = (d.h or 0) + 1
  end
end

local function OnSpellcast(unit, spellID)
  if not IsTracked(unit) or unit == "mouseover" then return end
  spellID = S(spellID)
  if not spellID then return end
  local info = ReadUnit(unit)
  if not info then return end
  local name
  if C_Spell and C_Spell.GetSpellName then
    name = S(C_Spell.GetSpellName(spellID))
  elseif GetSpellInfo then
    name = S(GetSpellInfo(spellID))
  end
  if type(name) ~= "string" or name == "" then return end
  local e = GetEntry(info, true)
  e.spells[name] = (e.spells[name] or 0) + 1
  local guid = info.guid
  if guid then lastCast[guid] = { name = name, t = GetTime() } end
  local okT, atMe = pcall(UnitIsUnit, unit .. "target", "player")
  if okT and S(atMe) then
    e.spellsAtMe = e.spellsAtMe or {}
    e.spellsAtMe[name] = true
  end
  -- give damage a moment to land so we can tell how it felt
  C_Timer.After(2, function() Obs(e, "spell:" .. name) end)
end

-- Damage you take. The game doesn't say who hit you, so we only record it
-- while exactly one creature is fighting you.
local function OnPlayerHit(action, flag, school)
  action, flag, school = S(action), S(flag), S(school)
  if action ~= "WOUND" or not school then return end
  local guid, e, count = nil, nil, 0
  for g, entry in pairs(live) do
    count = count + 1
    guid, e = g, entry
  end
  if count ~= 1 then return end
  local key = SCHOOL_BY_MASK[school]
  local now = GetTime()
  local c = lastCast[guid]
  if c and now - c.t < 1.6 and key and key ~= "physical" then
    e.spellSchool = e.spellSchool or {}
    e.spellSchool[c.name] = key
    Obs(e, "spell:" .. c.name)
  elseif key == "physical" and not (c and now - c.t < 0.6) then
    e.meleeHits = (e.meleeHits or 0) + 1
    if e.meleeHits >= 2 then Obs(e, "melee") end
    if flag == "CRITICAL" or flag == "CRUSHING" then Obs(e, "crit") end
  elseif key and key ~= "physical" then
    e.hurtBy = e.hurtBy or {}
    e.hurtBy[key] = (e.hurtBy[key] or 0) + 1
    if e.hurtBy[key] >= 2 then Obs(e, "school:" .. key) end
  end
end

------------------------------------------------------------------------
-- Loot ("drops" on first loot, "gathered" for skinning/mining afterwards)
------------------------------------------------------------------------
local corpseItems = {} -- guid (or queue item) -> { itemID = true } from the first loot
local lootDone = false

local function RecordItems(e, corpseKey, items)
  local first = corpseItems[corpseKey] == nil
  local seenItems = corpseItems[corpseKey] or {}
  corpseItems[corpseKey] = seenItems
  if first then e.looted = (e.looted or 0) + 1 end
  local gatheredNow = false
  for _, it in ipairs(items) do
    if first then
      seenItems[it.id] = true
      local l = e.loot[it.id] or { n = 0, q = 0 }
      l.n, l.q = l.n + 1, l.q + it.q
      e.loot[it.id] = l
    elseif not seenItems[it.id] then
      seenItems[it.id] = true
      gatheredNow = true
      local g = e.gather[it.id] or { n = 0, q = 0 }
      g.n, g.q = g.n + 1, g.q + it.q
      e.gather[it.id] = g
    end
  end
  if gatheredNow then e.gathered = (e.gathered or 0) + 1 end
  Debug("loot recorded", e.name, #items, first and "drop" or "re-open")
end

local function EntryForGuid(guid)
  local id = NpcIdFromGUID(guid)
  local e = id and db.entries[tostring(id)]
  if e then return e end
  for _, q in ipairs(lootQueue) do
    if q.guid == guid then return q.e end
  end
  return nil
end

local function OnLoot()
  if lootDone then return end
  local n = GetNumLootItems and GetNumLootItems() or 0
  if n == 0 then return end
  lootDone = true
  local perGuid, loose = {}, {}
  for slot = 1, n do
    local link = S(GetLootSlotLink(slot))
    local itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if itemID then
      local _, _, qty = GetLootSlotInfo(slot)
      qty = S(qty) or 1
      local src = { GetLootSourceInfo(slot) }
      local placed = false
      for i = 1, #src, 2 do
        local guid, q = S(src[i]), S(src[i + 1])
        Debug("slot", slot, itemID, "source", tostring(guid))
        if type(guid) == "string" and EntryForGuid(guid) then
          perGuid[guid] = perGuid[guid] or {}
          table.insert(perGuid[guid], { id = itemID, q = q or qty })
          placed = true
        end
      end
      if not placed then table.insert(loose, { id = itemID, q = qty }) end
    end
  end

  for guid, items in pairs(perGuid) do
    RecordItems(EntryForGuid(guid), guid, items)
    for _, q in ipairs(lootQueue) do
      if q.guid == guid then q.looted = true end
    end
  end

  -- couldn't tell which corpse: give it to your latest kill
  if #loose > 0 then
    local now = GetTime()
    for i = #lootQueue, 1, -1 do
      local q = lootQueue[i]
      if now - q.t < 180 then
        RecordItems(q.e, q.guid or q, loose)
        q.looted = true
        break
      end
    end
  end
  if ns.Refresh then ns.Refresh() end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("UNIT_HEALTH")
ev:RegisterEvent("UNIT_FLAGS")
ev:RegisterEvent("UNIT_COMBAT")
ev:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
ev:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
ev:RegisterEvent("LOOT_OPENED")
ev:RegisterEvent("LOOT_READY")
ev:RegisterEvent("LOOT_CLOSED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")

ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
  if event == "ADDON_LOADED" then
    if a1 == ADDON then
      InitDB()
      for _, fn in ipairs(ns.deferred) do
        local ok, err = pcall(fn)
        if not ok then
          ns.Print("error while building the window: " .. tostring(err))
          if geterrorhandler then geterrorhandler()(err) end
        end
      end
      if ns.OnLoad then ns.OnLoad() end
    end
    return
  end
  if not db then return end

  if event == "PLAYER_TARGET_CHANGED" then
    Observe("target")
    CheckUnit("target")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    Observe("mouseover")
  elseif event == "NAME_PLATE_UNIT_ADDED" then
    Observe(a1)
  elseif event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
    CheckUnit(a1)
  elseif event == "UNIT_COMBAT" then
    if a1 == "player" then
      OnPlayerHit(a2, a3, a5)
    else
      if IsTracked(a1) then MarkEngaged(a1, S(UnitGUID(a1))) end
      OnUnitCombat(a1, a2, a3, a4, a5)
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    OnSpellcast(a1, a3)
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
    OnXPMessage(a1)
  elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
    OnLoot()
  elseif event == "LOOT_CLOSED" then
    lootDone = false
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- forget fights that ended without a kill (after death events settle)
    C_Timer.After(3, function()
      if UnitAffectingCombat("player") then return end
      wipe(live)
      wipe(lastCast)
      for guid in pairs(engaged) do
        if not counted[guid] then engaged[guid] = nil end
      end
    end)
  end
end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
-- keybindings (Options > Keybindings > AddOns > Hunter's Journal)
BINDING_HEADER_HUNTERSJOURNAL = "Hunter's Journal"
BINDING_NAME_HUNTERSJOURNAL_TOGGLE = "Open / close the journal"
BINDING_NAME_HUNTERSJOURNAL_EMOTE = "Send the research emote"
function HuntersJournal_Toggle() if ns.Toggle then ns.Toggle() end end
function HuntersJournal_SendEmote()
  if not (ns.SendPendingEmote and ns.SendPendingEmote()) then Print("no emote waiting.") end
end

SLASH_HUNTERSJOURNAL1 = "/hj"
SLASH_HUNTERSJOURNAL2 = "/hunterjournal"
SlashCmdList.HUNTERSJOURNAL = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
  if cmd == "" then
    if ns.Toggle then ns.Toggle() end
  elseif cmd == "settings" or cmd == "config" or cmd == "options" then
    if ns.ToggleSettings then ns.ToggleSettings() end
  elseif cmd == "emote" then
    if not (ns.SendPendingEmote and ns.SendPendingEmote()) then Print("no emote waiting.") end
  elseif cmd == "debug" then
    DEBUG = not DEBUG
    Print("debug messages " .. (DEBUG and "on - kills, loot and observations print to chat" or "off"))
  elseif cmd == "map" then
    if ns.ToggleMapPins then ns.ToggleMapPins() end
  elseif cmd == "toasts" then
    db.settings.toasts = not db.settings.toasts
    Print("research pop-ups " .. (db.settings.toasts and "on" or "off"))
  elseif cmd == "plates" then
    db.settings.plates = not db.settings.plates
    Print("nameplate pips " .. (db.settings.plates and "on" or "off"))
    if ns.RefreshPlates then ns.RefreshPlates() end
  elseif cmd:match("^plates %-?%d+$") then
    db.settings.plateY = tonumber(cmd:match("(%-?%d+)$"))
    Print("nameplate pips moved to offset " .. db.settings.plateY)
    if ns.RefreshPlates then ns.RefreshPlates() end
  elseif cmd == "tooltip" then
    db.settings.tooltip = not db.settings.tooltip
    Print("tooltip line " .. (db.settings.tooltip and "on" or "off"))
  elseif cmd == "minimap" then
    db.settings.hideMinimap = not db.settings.hideMinimap
    if ns.UpdateMinimap then ns.UpdateMinimap() end
  elseif cmd == "reset confirm" then
    wipe(db.entries)
    wipe(db.names)
    Print("journal wiped.")
    if ns.Refresh then ns.Refresh() end
  elseif cmd == "reset" then
    Print("this deletes every entry. Type |cffffffff/hj reset confirm|r to do it.")
  else
    Print("commands:")
    print("  /hj - open the journal")
    print("  /hj settings - open the settings window")
    print("  /hj map - hunting grounds on the world map on/off")
    print("  /hj plates - research pips on nameplates on/off")
    print("  /hj plates 10 - move the pips up (or -10 down)")
    print("  /hj tooltip - journal line in tooltips on/off")
    print("  /hj toasts - research pop-ups on/off")
    print("  /hj minimap - minimap button on/off")
    print("  /hj reset - wipe the journal")
  end
end
