local ADDON, ns = ...
local S = ns.S

------------------------------------------------------------------------
-- What a stranger is called
------------------------------------------------------------------------
local function Mask(unit)
  if ns.db.settings.style == "stranger" then return "|cffbdb3a2Stranger|r" end
  local okR, race = pcall(UnitRace, unit)
  race = okR and S(race)
  local okS, sex = pcall(UnitSex, unit)
  sex = okS and S(sex)
  if type(race) ~= "string" then return "|cffbdb3a2Stranger|r" end
  local who = sex == 3 and "woman" or (sex == 2 and "man" or nil)
  return "|cffbdb3a2" .. race .. (who and (" " .. who) or "") .. "|r"
end
ns.Mask = Mask

------------------------------------------------------------------------
-- Nameplates
-- Works with Blizzard's plates and EllesmereUI's: we find the font string
-- showing the player's name and, while they're a stranger, write the mask
-- over it whenever the nameplate addon writes the name. The mask goes in
-- with SetFormattedText so nameplate addons that re-apply their own text on
-- SetText (EllesmereUI does) don't fight it.
------------------------------------------------------------------------
-- where `word` appears in `text` as a whole word (so "Bella" doesn't
-- match inside "Bellathene")
local function WordByte(b) return b and (b >= 128 or (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122)) end
local function FindWord(text, word)
  if type(word) ~= "string" or word == "" then return nil end
  local i, j = text:find(word, 1, true)
  while i do
    if not WordByte(text:byte(i - 1)) and not WordByte(text:byte(j + 1)) then return i, j end
    i, j = text:find(word, i + 1, true)
  end
  return nil
end

local hooked = {}   -- fontstring -> true
local byUnit = {}   -- unit token -> { fontstrings }

-- fromWrite: the nameplate/unit-frame addon just wrote fresh text itself
local function Apply(fs, fromWrite)
  local unit = fs.__wmUnit
  if not unit or fs.__wmBusy then return end
  local okE, exists = pcall(UnitExists, unit)
  if not (okE and S(exists)) then return end
  local enabled = (unit == "target") and ns.db.settings.targetFrame or ns.db.settings.plates
  local hide = enabled and not ns.IsKnownUnit(unit)
  local T = fs.__wmTrace and ns.Print
  if T then
    local okT, t = pcall(fs.GetText, fs)
    T(("  apply %s: enabled=%s hide=%s masked=%s shown=%s text=%s"):format(unit, tostring(enabled), tostring(hide),
      tostring(fs.__wmMasked), tostring(fs.__wmShown):gsub("|", "||"), (okT and S(t)) and tostring(t):gsub("|", "||") or "<secret>"))
  end
  if hide then
    local mask = Mask(unit)
    local okT, cur = pcall(fs.GetText, fs)
    cur = okT and S(cur)
    if cur == mask or (cur and fs.__wmShown == cur) then return end
    if cur then
      fs.__wmOrig = cur
      fs.__wmOrigWho = ns.UnitFull(unit)
    end
    -- swap just the name, so "13 | Joey Candleflame" becomes "13 | Gnome man"
    local out = mask
    if cur then
      local full, first = ns.UnitNames(unit)
      for _, n in ipairs({ full, first }) do
        local i, j
        if n then i, j = FindWord(cur, n) end
        if i and j then out = cur:sub(1, i - 1) .. mask .. cur:sub(j + 1) break end
      end
    end
    fs.__wmShown = out
    -- Total RP 3 nameplates put the RP name back over ours: make the mask
    -- its replacement text as well
    if fs.TRP3_overrideText ~= nil then fs.TRP3_overrideText = out end
    fs.__wmBusy = true
    local okW, errW = pcall(fs.SetFormattedText, fs, "%s", out)
    fs.__wmBusy = false
    fs.__wmMasked = true
    if T then
      local okT, t = pcall(fs.GetText, fs)
      T(("  wrote %s (%s), now %s"):format(out:gsub("|", "||"), okW and "ok" or tostring(errW),
        (okT and S(t)) and tostring(t):gsub("|", "||") or "<secret>"))
    end
  elseif fs.__wmMasked then
    fs.__wmMasked = false
    fs.__wmShown = nil
    if fromWrite then return end -- the addon already wrote the right name
    local who = ns.UnitFull(unit)
    local text = (fs.__wmOrigWho == who) and fs.__wmOrig or nil
    if not text then
      text = ns.UnitNames(unit) or ""
    end
    fs.__wmBusy = true
    -- SetText on purpose: lets a nameplate addon re-compose its own name text
    pcall(fs.SetText, fs, text)
    fs.__wmBusy = false
  end
end

-- never let an error stop the hiding silently: report the first one
local told = false
local RawApply = Apply
Apply = function(fs, fromWrite)
  local ok, err = pcall(RawApply, fs, fromWrite)
  if not ok then
    fs.__wmBusy = false
    if not told then told = true ns.Print("|cffff6060error while hiding a name:|r " .. tostring(err)) end
  end
end

local function OnWrite(self)
  if self.__wmBusy or not self.__wmUnit then return end
  Apply(self, true)
end

local function Guard(fs)
  if hooked[fs] then return end
  hooked[fs] = true
  hooksecurefunc(fs, "SetText", OnWrite)
  if fs.SetFormattedText then hooksecurefunc(fs, "SetFormattedText", OnWrite) end
end

-- font strings anywhere under `frame` whose text contains `name`
local function Collect(frame, name, out, depth)
  if not frame or depth > 6 then return end
  local okF, forbidden = pcall(function() return frame.IsForbidden and frame:IsForbidden() end)
  if okF and forbidden then return end
  local regions = { frame:GetRegions() }
  for _, r in ipairs(regions) do
    if r.GetObjectType and r:GetObjectType() == "FontString" then
      local okT, t = pcall(r.GetText, r)
      t = okT and S(t)
      if (type(t) == "string" and t:find(name, 1, true)) or r.__wmUnit then
        out[#out + 1] = r
      end
    end
  end
  for _, c in ipairs({ frame:GetChildren() }) do Collect(c, name, out, depth + 1) end
end

-- watch the name text of a unit shown in `frame` (a nameplate or the target frame)
local function AttachFrame(frame, unit)
  local okP, isPlayer = pcall(UnitIsPlayer, unit)
  if not (okP and S(isPlayer)) then return end
  local okM, me = pcall(UnitIsUnit, unit, "player")
  if okM and S(me) then return end
  local okN, name = pcall(UnitName, unit)
  name = okN and S(name)
  if type(name) ~= "string" or name == "" then return end
  local list = {}
  Collect(frame, name, list, 0)
  byUnit[unit] = list
  for _, fs in ipairs(list) do
    Guard(fs)
    fs.__wmUnit = unit
    Apply(fs)
  end
end

local function Attach(unit)
  if not ns.db or not ns.db.settings.plates then return end
  local okG, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
  if not okG or not plate then return end
  AttachFrame(plate, unit)
  -- the plate's own name text: found by where it is, not what it says, since
  -- the game hides the text from addons once a guild line is added to it
  local uf = plate.UnitFrame
  local fs = uf and uf.name
  if fs and fs.GetObjectType and fs:GetObjectType() == "FontString" then
    local okP, isPlayer = pcall(UnitIsPlayer, unit)
    local okM, me = pcall(UnitIsUnit, unit, "player")
    if okP and S(isPlayer) and not (okM and S(me)) then
      byUnit[unit] = byUnit[unit] or {}
      local seen = false
      for _, x in ipairs(byUnit[unit]) do if x == fs then seen = true end end
      if not seen then table.insert(byUnit[unit], fs) end
      Guard(fs)
      fs.__wmUnit = unit
      Apply(fs)
    end
  end
end

-- your target frame: EllesmereUI's, or Blizzard's
local function TargetFrameObj()
  return _G.EllesmereUIUnitFrames_Target or _G.TargetFrame
end
ns.TargetFrameObj = TargetFrameObj

-- EllesmereUI unit frames draw text as zones: a format ("%s | %s") and
-- pieces (level, name...). Some pieces can't be read, so we redraw the
-- zone ourselves with the name piece swapped for the mask.
local zoneBusy = false
local function ZoneApply(z)
  local unit = "target"
  local okE, exists = pcall(UnitExists, unit)
  if not (okE and S(exists)) or not z.pieces or not z.fs then return end
  local full, first = ns.UnitNames(unit)
  local okP, isPlayer = pcall(UnitIsPlayer, unit)
  local okM, me = pcall(UnitIsUnit, unit, "player")
  local player = okP and S(isPlayer) and not (okM and S(me))
  local hide = player and first and ns.db.settings.targetFrame and not ns.IsKnownUnit(unit)
  if not hide and not z.fs.__wmMasked then return end
  local vals, n, nameAt = {}, #z.pieces, nil
  for k = 1, n do
    local ok, v = pcall(z.pieces[k], unit)
    vals[k] = ok and v or ""
    local sv = ok and S(v)
    if hide and not nameAt and type(sv) == "string" and sv ~= "" and first and
      (sv == full or sv:find(first, 1, true)) then
      nameAt = k
    end
  end
  if hide and not nameAt then return end
  if hide then vals[nameAt] = Mask(unit) end
  zoneBusy = true
  pcall(z.fs.SetFormattedText, z.fs, z.fmt, unpack(vals, 1, n))
  zoneBusy = false
  z.fs.__wmMasked = hide and true or nil
end

local function AttachZones(frame)
  local zones = frame and frame._euiTextZones
  if type(zones) ~= "table" then return false end
  for _, z in ipairs(zones) do
    if type(z) == "table" and z.fs and z.fmt and z.pieces then
      if not z.fs.__wmZoneHooked then
        z.fs.__wmZoneHooked = true
        z.fs.__wmZone = z
        hooksecurefunc(z.fs, "SetFormattedText", function(self)
          if zoneBusy then return end
          pcall(ZoneApply, self.__wmZone)
        end)
      end
      z.fs.__wmZone = z
      local ok, err = pcall(ZoneApply, z)
      if not ok and ns.debugOn then ns.Print("zone: " .. tostring(err)) end
    end
  end
  return true
end

local function AttachTarget()
  if not ns.db then return end
  local tf = TargetFrameObj()
  if not tf then return end
  if AttachZones(tf) then return end -- EllesmereUI
  if ns.db.settings.targetFrame then AttachFrame(tf, "target") end
end

local function Detach(unit)
  for _, fs in ipairs(byUnit[unit] or {}) do
    if fs.__wmUnit == unit then fs.__wmUnit = nil end
  end
  byUnit[unit] = nil
end

-- /wellmet debug: what Well Met sees for your target
-- /wellmet names: the game's floating-name settings, no target needed
function ns.NameCVars()
  local list = { "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName", "UnitNameOwn", "UnitNamePlayerGuild",
    "UnitNamePlayerPVPTitle", "UnitNameFriendlyPetName", "UnitNameFriendlyGuardianName", "UnitNameFriendlyMinionName",
    "UnitNameFriendlyTotemName", "UnitNameNPC", "UnitNameForceHideMinus", "nameplateShowFriends", "nameplateShowOnlyNames",
    "nameplateShowFriendlyNPCs", "nameplateShowAll" }
  local get = (C_CVar and C_CVar.GetCVar) or GetCVar
  local out = {}
  for _, cv in ipairs(list) do
    local ok, v = pcall(get, cv)
    out[#out + 1] = cv:gsub("^UnitName", "UN:"):gsub("^nameplate", "NP:") .. "=" .. ((ok and v ~= nil) and tostring(v) or "-")
  end
  ns.Print("floating names (Well Met wants UN:FriendlyPlayerName=0): " .. table.concat(out, "  "))
end

function ns.Debug()
  local P = ns.Print
  local okE, exists = pcall(UnitExists, "target")
  if not (okE and S(exists)) then P("target a player first.") return end
  local full = ns.UnitFull("target")
  local nm, first, sur = ns.UnitNames("target")
  P(("target: full=%s  names=%s / %s / %s"):format(tostring(full), tostring(nm), tostring(first), tostring(sur)))
  P(("floating names: friendly=%s enemy=%s (Well Met wants %s)"):format(tostring(GetCVar("UnitNameFriendlyPlayerName")),
    tostring(GetCVar("UnitNameEnemyPlayerName")), ns.db.settings.overhead and "0" or "your choice"))
  P(("known=%s  plates=%s  targetFrame=%s"):format(tostring(ns.IsKnownUnit("target")),
    tostring(ns.db.settings.plates), tostring(ns.db.settings.targetFrame)))
  local function Scan(label, frame)
    if not frame then P(label .. ": not found") return end
    local n = 0
    local function walk(f, d)
      if d > 6 then return end
      for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" then
          local okT, t = pcall(r.GetText, r)
          local secret = okT and issecretvalue and issecretvalue(t)
          if secret or (okT and type(t) == "string" and t ~= "") then
            n = n + 1
            if n <= 8 then
              P(("  %s %s%s"):format(label, secret and "<secret text>" or ("\"" .. t:gsub("|", "||") .. "\""),
                r.__wmUnit and (" [watched " .. r.__wmUnit .. "]") or ""))
            end
          end
        end
      end
      for _, c in ipairs({ f:GetChildren() }) do walk(c, d + 1) end
    end
    walk(frame, 0)
    if n == 0 then P(label .. ": no text found") end
  end
  Scan("frame", TargetFrameObj())
  local zones = TargetFrameObj() and TargetFrameObj()._euiTextZones
  P("ellesmere zones: " .. (type(zones) == "table" and #zones or "none"))
  local okG, plate = pcall(C_NamePlate.GetNamePlateForUnit, "target")
  Scan("plate", okG and plate or nil)
  -- which nameplate unit is the target, and what Well Met decides for it
  for i = 1, 40 do
    local u = "nameplate" .. i
    local okU, same = pcall(UnitIsUnit, u, "target")
    if okU and S(same) then
      local okP, isP = pcall(UnitIsPlayer, u)
      P(("%s: player=%s full=%s known=%s"):format(u, tostring(okP and S(isP)), tostring(ns.UnitFull(u)), tostring(ns.IsKnownUnit(u))))
      for _, fs in ipairs(byUnit[u] or {}) do
        fs.__wmTrace = true
        Apply(fs)
        fs.__wmTrace = nil
      end
    end
  end
end

-- Total RP 3's nameplate module: after it picks a name for a plate, swap
-- in the mask for strangers (keeping its in-character / OOC marker)
local function HookTRP3Plates()
  local m = _G.TRP3_BlizzardNamePlates
  if not m or m.__wmHooked or type(m.UpdateNamePlateName) ~= "function" then return end
  m.__wmHooked = true
  hooksecurefunc(m, "UpdateNamePlateName", function(self, nameplate)
    pcall(function()
      if not ns.db.settings.plates then return end
      local uf = self:GetNamePlateUnitFrame(nameplate)
      local fs = uf and uf.name
      if not fs then return end
      local unit = S(self:GetUnitFrameUnit(uf))
      if not unit or ns.IsKnownUnit(unit) then return end
      if fs.TRP3_overrideText == nil then return end -- TRP3 isn't renaming this one
      local mask = Mask(unit)
      local info = self:GetUnitDisplayInfo(unit)
      local util = _G.TRP3_NamePlatesUtil
      if info and info.roleplayStatus and util and util.PrependRoleplayStatusToText then
        local ok, t = pcall(util.PrependRoleplayStatusToText, mask, info.roleplayStatus)
        if ok and t then mask = t end
      end
      fs.TRP3_overrideText = mask
      fs.__wmShown, fs.__wmMasked, fs.__wmUnit = mask, true, unit
      fs.__wmBusy = true
      getmetatable(fs).__index.SetText(fs, mask)
      fs.__wmBusy = false
    end)
  end)
end
ns.HookTRP3Plates = HookTRP3Plates

function ns.RefreshPlates()
  -- let Total RP 3 re-pick names (someone just became known, or a setting changed)
  local m = _G.TRP3_BlizzardNamePlates
  if m and m.__wmHooked and m.UpdateAllNamePlates then pcall(m.UpdateAllNamePlates, m) end
  for unit, list in pairs(byUnit) do
    for _, fs in ipairs(list) do
      if fs.__wmUnit == unit then Apply(fs) end
    end
  end
  AttachTarget()
  for i = 1, 40 do
    local unit = "nameplate" .. i
    if not byUnit[unit] then
      local okE, exists = pcall(UnitExists, unit)
      if okE and S(exists) then Attach(unit) end
    end
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ev:RegisterEvent("UNIT_NAME_UPDATE")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("CVAR_UPDATE")
ev:SetScript("OnEvent", function(_, event, unit)
  if not ns.db then return end
  if event == "NAME_PLATE_UNIT_ADDED" then
    -- after the nameplate addon has written the name
    C_Timer.After(0, function() Attach(unit) end)
    C_Timer.After(0.3, function() Attach(unit) end)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    Detach(unit)
  elseif event == "UNIT_NAME_UPDATE" then
    if type(unit) == "string" and unit:find("^nameplate") then C_Timer.After(0, function() Attach(unit) end) end
  elseif event == "PLAYER_TARGET_CHANGED" then
    -- the frame's addon writes the new name first, then we look
    C_Timer.After(0, AttachTarget)
    C_Timer.After(0.2, AttachTarget)
    if ns.OnTarget then ns.OnTarget() end
  elseif event == "GROUP_ROSTER_UPDATE" then
    ns.RefreshPlates()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED" then
    -- the game loads your saved settings after us; switch the names off again
    C_Timer.After(1, ns.ApplyOverhead)
    C_Timer.After(5, ns.ApplyOverhead)
  elseif event == "CVAR_UPDATE" then
    -- something turned the floating names back on
    if ns.db.settings.overhead and (unit == "UnitNameFriendlyPlayerName" or unit == "UnitNameEnemyPlayerName"
      or unit == "unitNameFriendlyPlayerName" or unit == "unitNameEnemyPlayerName") then
      C_Timer.After(0, ns.ApplyOverhead)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if ns.pendingCVars then ns.ApplyOverhead() end
  end
end)

------------------------------------------------------------------------
-- Floating names above characters can only be switched off for everyone,
-- so while that option is on we turn them off and let nameplates do it.
------------------------------------------------------------------------
local OVERHEAD = { "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName" }
function ns.ApplyOverhead()
  if InCombatLockdown and InCombatLockdown() then ns.pendingCVars = true return end
  ns.pendingCVars = nil
  local st = ns.db.settings
  st.savedCVars = st.savedCVars or {}
  for _, cv in ipairs(OVERHEAD) do
    if st.overhead then
      local now = GetCVar(cv)
      if st.savedCVars[cv] == nil then st.savedCVars[cv] = (now == "0") and "1" or now end
      if now ~= "0" then pcall(SetCVar, cv, "0") end
    elseif st.savedCVars[cv] ~= nil then
      pcall(SetCVar, cv, st.savedCVars[cv])
      st.savedCVars[cv] = nil
    end
  end
end

------------------------------------------------------------------------
-- Tooltips: the game's own and Total RP 3's character tooltip
------------------------------------------------------------------------
-- Total RP 3 status of a player, using TRP3's own lookups
local function RPStatus(unit)
  local reg = TRP3_API and TRP3_API.register
  if not reg then return nil end
  local id
  if reg.getUnitID then
    local ok, v = pcall(reg.getUnitID, unit)
    id = ok and S(v) or nil
  end
  id = id or ns.UnitFull(unit)
  if not id then return nil end
  local okK, known = pcall(reg.isUnitIDKnown, id)
  if not (okK and known) then return "none" end
  if reg.getUnitIDCharacter then
    local okC, char = pcall(reg.getUnitIDCharacter, id)
    if okC and type(char) == "table" and char.RP then
      return char.RP == 1 and "ic" or "ooc"
    end
  end
  return "known"
end
ns.RPStatus = RPStatus

local RP_TEXT = {
  ic = { "Total RP 3: in character", 0.45, 0.85, 0.45 },
  ooc = { "Total RP 3: out of character", 0.9, 0.45, 0.4 },
  known = { "Total RP 3 profile", 0.75, 0.7, 0.6 },
  none = { "No Total RP 3 profile", 0.55, 0.55, 0.55 },
}

local function AddRPLine(tt, unit)
  if not ns.db.settings.rpLine or not unit then return end
  local okP, isPlayer = pcall(UnitIsPlayer, unit)
  if not (okP and S(isPlayer)) then return end
  local okM, me = pcall(UnitIsUnit, unit, "player")
  if okM and S(me) then return end
  local st = RPStatus(unit)
  local t = st and RP_TEXT[st]
  if not t then return end
  tt:AddLine(t[1], t[2], t[3], t[4])
  tt:Show()
end

local function MaskTooltip(tt, unit)
  if not ns.db.settings.tooltips or not unit or ns.IsKnownUnit(unit) then return end
  local name = tt:GetName()
  if not name then return end
  -- swap just the name, so icons and Total RP 3's in-character / OOC
  -- markers on the same line stay
  local line1 = _G[name .. "TextLeft1"]
  if line1 then
    local okT, t = pcall(line1.GetText, line1)
    t = okT and S(t)
    local out
    if type(t) == "string" then
      local cands = {}
      local full, first = ns.UnitNames(unit)
      local ch = ns.TRP3Profile(ns.UnitFull(unit) or "")
      if ch and type(ch.FN) == "string" and ch.FN ~= "" then
        if type(ch.LN) == "string" and ch.LN ~= "" then cands[#cands + 1] = ch.FN .. " " .. ch.LN end
        cands[#cands + 1] = ch.FN
      end
      cands[#cands + 1] = full
      cands[#cands + 1] = first
      table.sort(cands, function(x, y) return #x > #y end)
      for _, n in ipairs(cands) do
        local i, j = FindWord(t, n)
        if i and j then out = t:sub(1, i - 1) .. Mask(unit) .. t:sub(j + 1) break end
      end
    end
    pcall(line1.SetText, line1, out or Mask(unit))
  end
  -- guild line would give them away too
  local okG, guild = pcall(GetGuildInfo, unit)
  guild = okG and S(guild)
  if guild then
    for i = 2, tt:NumLines() do
      local l = _G[name .. "TextLeft" .. i]
      local okT, t = pcall(l.GetText, l)
      t = okT and S(t)
      if t and t:find(guild, 1, true) then pcall(l.SetText, l, " ") end
    end
  end
  tt:Show()
end

function ns.SetupTooltips()
  HookTRP3Plates()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
      if tt ~= GameTooltip then return end
      local ok, _, unit = pcall(tt.GetUnit, tt)
      unit = ok and S(unit)
      if unit then
        pcall(MaskTooltip, tt, unit)
        pcall(AddRPLine, tt, unit)
      end
    end)
  end
  -- Total RP 3 draws its own character tooltip for the unit under the mouse
  local trp = _G.TRP3_CharacterTooltip
  if trp and trp.HookScript then
    trp:HookScript("OnShow", function(self)
      local okE, exists = pcall(UnitExists, "mouseover")
      if okE and S(exists) then
        pcall(MaskTooltip, self, "mouseover")
        pcall(AddRPLine, self, "mouseover")
      end
    end)
  end
end
