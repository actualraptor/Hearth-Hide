local ADDON, ns = ...
ns.Defer(function()

-- Research pips above nameplates, and a journal line in unit tooltips.

local S = ns.S
local C = ns.UI.C
local badges, pool = {}, {}

local function NewBadge()
  local b = CreateFrame("Frame", nil, UIParent)
  b:SetSize(56, 11)
  b:SetFrameStrata("LOW")
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.55)
  b.pips = {}
  for p = 1, 5 do
    local d = b:CreateTexture(nil, "ARTWORK")
    d:SetSize(5, 5)
    d:SetColorTexture(1, 1, 1, 1)
    pcall(d.SetRotation, d, math.pi / 4)
    d:SetPoint("LEFT", 6 + (p - 1) * 10, 0)
    b.pips[p] = d
  end
  return b
end

local function Paint(b, e)
  local lvl = ns.Level(e)
  local mastered = lvl >= ns.MAX_LEVEL
  for p = 1, 5 do
    local d = b.pips[p]
    if p <= lvl then
      if mastered then d:SetVertexColor(C.star[1], C.star[2], C.star[3], 1)
      else d:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 1) end
    else
      d:SetVertexColor(0.35, 0.35, 0.35, 1)
    end
  end
end

local function Release(unit)
  local b = badges[unit]
  if not b then return end
  badges[unit] = nil
  b:Hide()
  b:ClearAllPoints()
  pool[#pool + 1] = b
end

local function Attach(unit)
  if not ns.db or ns.db.settings.plates == false then return end
  if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
  if not ok or not plate then return end
  if plate.IsForbidden and plate:IsForbidden() then return end
  local info = ns.ReadUnit(unit)
  if not info then return end
  local e = ns.GetEntry(info, false)
  if not e then return end
  local b = badges[unit] or table.remove(pool) or NewBadge()
  badges[unit] = b
  b:ClearAllPoints()
  local st = ns.db.settings
  local anchor = st.plateAnchor or "TOP"
  local OPPOSITE = { TOP = "BOTTOM", BOTTOM = "TOP", LEFT = "RIGHT", RIGHT = "LEFT" }
  b:SetScale(st.plateScale or 1)
  if not pcall(b.SetPoint, b, OPPOSITE[anchor] or "BOTTOM", plate, anchor, st.plateX or 0, st.plateY or 0) then
    Release(unit)
    return
  end
  b.key = e.key
  Paint(b, e)
  b:Show()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ev:SetScript("OnEvent", function(_, event, unit)
  if event == "NAME_PLATE_UNIT_ADDED" then
    -- let the journal record it first
    C_Timer.After(0, function() Attach(unit) end)
  else
    Release(unit)
  end
end)

-- keep pips current after kills
local t = 0
ev:SetScript("OnUpdate", function(_, elapsed)
  t = t + elapsed
  if t < 1 then return end
  t = 0
  for unit, b in pairs(badges) do
    local e = b.key and ns.db.entries[b.key]
    if e then Paint(b, e) end
  end
end)

function ns.RefreshPlates()
  for unit in pairs(badges) do Release(unit) end
  if ns.db.settings.plates == false then return end
  for i = 1, 40 do
    local unit = "nameplate" .. i
    if UnitExists(unit) then Attach(unit) end
  end
end

------------------------------------------------------------------------
-- Tooltip line
------------------------------------------------------------------------
local function AddTooltip(tt)
  if not ns.db or ns.db.settings.tooltip == false then return end
  local ok, _, unit = pcall(tt.GetUnit, tt)
  unit = ok and S(unit)
  if not unit then return end
  local info = ns.ReadUnit(unit)
  if not info then return end
  local e = ns.GetEntry(info, false)
  if not e then return end
  local lvl = ns.Level(e)
  tt:AddLine(string.format("Hunter's Journal: research %d/5, slain %d", lvl, e.kills or 0), C.gold[1], C.gold[2], C.gold[3])
  local need = ns.KillsToNext(e)
  if need then
    tt:AddLine(string.format("%d more %s to unlock %s", need, need == 1 and "kill" or "kills", ns.UNLOCKS[lvl + 1]), 0.6, 0.58, 0.52)
  end
end

function ns.OnLoadPlates()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
      if tt == GameTooltip then pcall(AddTooltip, tt) end
    end)
  elseif GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tt) pcall(AddTooltip, tt) end)
  end
end
end)
