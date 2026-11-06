local ADDON, ns = ...
ns.Defer(function()

-- World map overlay: a creature portrait wherever you've made enough kills.
-- Toggle with the journal button in the bottom-left corner of the world map.

local UI = ns.UI
local C = UI.C
local host, toggle, watcher
local pins = {}
local lastMap, lastScale

------------------------------------------------------------------------
-- Overlay: a plain frame on top of the map (not inside the zoomable
-- canvas). Pins on it are re-positioned every frame from map coordinates.
------------------------------------------------------------------------
local overlay
local tracked = {}

local function Project(nx, ny)
  local cv = WorldMapFrame:GetCanvas()
  local l, t = cv:GetLeft(), cv:GetTop()
  local ol, ob = overlay:GetLeft(), overlay:GetBottom()
  if not (l and t and ol and ob) then return nil end
  local k = cv:GetEffectiveScale() / overlay:GetEffectiveScale()
  local x = (l + nx * cv:GetWidth()) * k
  local y = (t - ny * cv:GetHeight()) * k
  return x - ol, y - ob
end

local function Reposition()
  for f in pairs(tracked) do
    if f:IsShown() then
      local x, y = Project(f.nx, f.ny)
      f:ClearAllPoints()
      if x then f:SetPoint("CENTER", overlay, "BOTTOMLEFT", x, y) end
    else
      tracked[f] = nil
    end
  end
end

function ns.MapOverlay()
  if overlay then return overlay end
  if not WorldMapFrame or not WorldMapFrame.GetCanvas then return nil end
  local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
  overlay = CreateFrame("Frame", nil, parent)
  overlay:SetAllPoints(parent)
  overlay:SetFrameLevel(parent:GetFrameLevel() + 1500)
  overlay:SetClipsChildren(true)
  overlay:SetScript("OnUpdate", Reposition)
  return overlay
end

function ns.MapTrack(f)
  tracked[f] = true
  local x, y = Project(f.nx, f.ny)
  f:ClearAllPoints()
  if x then f:SetPoint("CENTER", overlay, "BOTTOMLEFT", x, y) end
end

local MERGE = 0.06  -- spots closer than this (in map units) count as one area

local function Clusters(m)
  local st = ns.db.settings
  local minKills = st.mapMinKills or 5
  local out = {}
  for _, e in pairs(ns.db.entries) do
    local list = {}
    for _, s in pairs(e.spots or {}) do
      if s.m == m and s.x then
        local hit
        for _, c in ipairs(list) do
          local dx, dy = c.x - s.x, c.y - s.y
          if dx * dx + dy * dy < MERGE * MERGE then hit = c break end
        end
        if hit then
          local n = hit.n + s.n
          hit.x = (hit.x * hit.n + s.x * s.n) / n
          hit.y = (hit.y * hit.n + s.y * s.n) / n
          hit.n = n
          hit.sub = hit.sub or s.sub
        else
          list[#list + 1] = { x = s.x, y = s.y, n = s.n, sub = s.sub, e = e }
        end
      end
    end
    for _, c in ipairs(list) do
      if c.n >= minKills then out[#out + 1] = c end
    end
  end
  table.sort(out, function(a, b) return a.n > b.n end)
  for i = #out, (st.mapMaxPins or 20) + 1, -1 do out[i] = nil end
  -- nudge pins that would sit on top of each other
  for i = 2, #out do
    for j = 1, i - 1 do
      local dx, dy = out[i].x - out[j].x, out[i].y - out[j].y
      if dx * dx + dy * dy < 0.0009 then
        out[i].x = out[i].x + 0.028
      end
    end
  end
  return out
end

local function Pin(i)
  local p = pins[i]
  if p then return p end
  p = UI.Portrait(host, 28)
  p:EnableMouse(true)
  -- a visible gold frame at any zoom
  p.mapRing = p:CreateTexture(nil, "BACKGROUND", nil, -8)
  p.mapRing:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  p.count = p:CreateFontString(nil, "OVERLAY")
  p.count:SetFont(UI.FONT, 10, "OUTLINE")
  p.count:SetPoint("BOTTOMRIGHT", 3, -3)
  p.count:SetTextColor(C.star[1], C.star[2], C.star[3])
  p:SetScript("OnEnter", function(self)
    local e = self.cluster and self.cluster.e
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(e.name, C.gold[1], C.gold[2], C.gold[3])
    GameTooltip:AddLine(self.cluster.n .. " slain in this area" .. (self.cluster.sub and (" (" .. self.cluster.sub .. ")") or ""), 1, 1, 1)
    GameTooltip:AddLine("Research " .. ns.Level(e) .. "/5   Lv " .. (e.minLvl or "?") .. (e.maxLvl and e.maxLvl ~= e.minLvl and ("-" .. e.maxLvl) or ""), 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Click to open in the journal", 0.6, 0.58, 0.52)
    GameTooltip:Show()
  end)
  p:SetScript("OnLeave", function() GameTooltip:Hide() end)
  p:SetScript("OnMouseUp", function(self)
    local e = self.cluster and self.cluster.e
    if e then ns.OpenEntry(e.key, 6) end
  end)
  pins[i] = p
  return p
end

local function Draw()
  if not host then return end
  for _, p in ipairs(pins) do p:Hide() end
  local on = ns.db.settings.mapPins
  if toggle then toggle.active:SetShown(on) end
  if not on or not WorldMapFrame:IsShown() then return end
  local m = WorldMapFrame:GetMapID()
  if not m then return end
  local size = ns.db.settings.mapPinSize or 28
  local factor = 1
  for i, c in ipairs(Clusters(m)) do
    local p = Pin(i)
    p.cluster = c
    p:SetSize(size, size)
    p:SetFrameLevel(host:GetFrameLevel() + 10 + i)
    p.count:SetFont(UI.FONT, math.min(200, 11 * factor), "OUTLINE")
    p.count:ClearAllPoints()
    p.count:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 3 * factor, -3 * factor)
    p.count:SetText(c.n)
    p.mapRing:ClearAllPoints()
    p.mapRing:SetPoint("TOPLEFT", -2 * factor, 2 * factor)
    p.mapRing:SetPoint("BOTTOMRIGHT", 2 * factor, -2 * factor)
    UI.SetPortrait(p, c.e)
    -- keep the type icon underneath in case the 3D model can't draw here
    UI.SetIcon(p.icon, UI.EntryIcon(c.e))
    p.icon:SetDesaturated(false)
    p.icon:Show()
    p.nx, p.ny = c.x, c.y
    p:Show()
    ns.MapTrack(p)
  end
end
ns.RefreshMapPins = Draw

function ns.ToggleMapPins()
  ns.db.settings.mapPins = not ns.db.settings.mapPins
  ns.Print("hunting grounds on the world map " .. (ns.db.settings.mapPins and "on" or "off"))
  Draw()
end

function ns.PlaceMapButton()
  if not toggle then return end
  local parent = toggle:GetParent()
  toggle:ClearAllPoints()
  toggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12 + (ns.db.settings.mapBtnX or 0), -44 + (ns.db.settings.mapBtnY or 0))
end

local function Setup()
  if host or not WorldMapFrame or not WorldMapFrame.GetCanvas then return end
  host = ns.MapOverlay()
  if not host then return end

  -- toggle button on the map
  local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
  toggle = CreateFrame("Button", nil, parent)
  toggle:SetSize(32, 32)
  toggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12 + (ns.db.settings.mapBtnX or 0), -44 + (ns.db.settings.mapBtnY or 0))
  toggle:SetFrameLevel(parent:GetFrameLevel() + 2000)
  local bg = toggle:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
  local icon = toggle:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", 3, -3)
  icon:SetPoint("BOTTOMRIGHT", -3, 3)
  UI.SetIcon(icon, "INV_Misc_Book_09")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  UI.Border(toggle, C.gold, 0.9, "OVERLAY")
  toggle.active = toggle:CreateTexture(nil, "OVERLAY")
  toggle.active:SetPoint("TOPLEFT", -3, 3)
  toggle.active:SetPoint("BOTTOMRIGHT", 3, -3)
  toggle.active:SetColorTexture(C.star[1], C.star[2], C.star[3], 0.35)
  toggle.active:SetBlendMode("ADD")
  toggle:SetScript("OnClick", function()
    ns.db.settings.mapPins = not ns.db.settings.mapPins
    Draw()
  end)
  toggle:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Hunter's Journal", C.gold[1], C.gold[2], C.gold[3])
    GameTooltip:AddLine(ns.db.settings.mapPins and "Hide hunting grounds" or "Show hunting grounds", 1, 1, 1)
    GameTooltip:AddLine("Creatures appear where you've slain " .. (ns.db.settings.mapMinKills or 5) .. "+ of them.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
  end)
  toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

  watcher = CreateFrame("Frame", nil, WorldMapFrame)
  local acc = 0
  watcher:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.25 then return end
    acc = 0
    local m = WorldMapFrame:GetMapID()
    local s = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.GetCanvasScale
      and WorldMapFrame.ScrollContainer:GetCanvasScale()
    if m ~= lastMap or s ~= lastScale then
      lastMap, lastScale = m, s
      Draw()
    end
  end)
  WorldMapFrame:HookScript("OnShow", function() lastMap = nil end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, name)
  if event == "PLAYER_LOGIN" or name == "Blizzard_WorldMap" then
    if WorldMapFrame and not host then
      local ok, err = pcall(Setup)
      if not ok then ns.Print("couldn't add the world map button: " .. tostring(err)) end
    end
  end
end)
end)
