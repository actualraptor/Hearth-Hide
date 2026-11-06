local ADDON, ns = ...
ns.Defer(function()

-- Hunting grounds: where you killed each creature, shown on a zone map,
-- described in words, and shareable in RP.

local S = ns.S
local UI = ns.UI
local C, Text, Fill, Border, hex = UI.C, UI.Text, UI.Fill, UI.Border, UI.hex
local page, PAGE_W = UI.groundsPage, UI.PAGE_W
local MUTED, TAN = hex(C.muted), hex(C.tan)
local GRID = 40 -- positions are rounded to a 40x40 grid per zone

------------------------------------------------------------------------
-- Recording
------------------------------------------------------------------------
local function PlayerSpot()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local m = S(C_Map.GetBestMapForUnit("player"))
  if not m then return nil end
  local ok, pos = pcall(C_Map.GetPlayerMapPosition, m, "player")
  if not ok or not pos then return m end
  local x, y = pos:GetXY()
  return m, S(x), S(y)
end

local function MapName(m)
  local info = m and C_Map.GetMapInfo and C_Map.GetMapInfo(m)
  return info and info.name or nil
end

function ns.RecordSpot(e)
  local m, x, y = PlayerSpot()
  local zone = S(GetRealZoneText and GetRealZoneText() or GetZoneText())
  local sub = S(GetSubZoneText())
  if sub == "" or sub == zone then sub = nil end
  e.spots = e.spots or {}
  local key, gx, gy
  if m and x and y and (x > 0 or y > 0) then
    gx, gy = math.floor(x * GRID), math.floor(y * GRID)
    key = m .. ":" .. gx .. ":" .. gy
  else
    key = "z:" .. (zone or "?") .. ":" .. (sub or "")
  end
  local s = e.spots[key]
  if not s then
    s = { n = 0, zone = MapName(m) or zone, sub = sub }
    if gx then
      s.m = m
      s.x = (gx + 0.5) / GRID
      s.y = (gy + 0.5) / GRID
    end
    e.spots[key] = s
  end
  s.n = s.n + 1
  s.sub = s.sub or sub
end

------------------------------------------------------------------------
-- Describing places in words
------------------------------------------------------------------------
local function Direction(x, y)
  if not x then return nil end
  local ns_ = y < 0.36 and "north" or (y > 0.64 and "south" or "")
  local ew = x < 0.36 and "west" or (x > 0.64 and "east" or "")
  if ns_ == "" and ew == "" then return "central" end
  return ns_ .. ew .. "ern"
end

-- groups of spots that read the same: "northeastern Elwynn Forest, near X"
local function Grounds(e)
  local groups, order = {}, {}
  for _, s in pairs(e.spots or {}) do
    local dir = Direction(s.x, s.y)
    local key = (s.zone or "?") .. "|" .. (dir or "") .. "|" .. (s.sub or "")
    local g = groups[key]
    if not g then
      g = { zone = s.zone, dir = dir, sub = s.sub, n = 0 }
      groups[key] = g
      order[#order + 1] = g
    end
    g.n = g.n + s.n
  end
  table.sort(order, function(a, b) return a.n > b.n end)
  return order
end

local function Phrase(g)
  local where = g.zone or "parts unknown"
  if g.dir then where = g.dir .. " " .. where end
  where = "in " .. where
  if g.sub then where = where .. ", near " .. g.sub end
  return where
end

local function Plural(name)
  if name:find("[sxz]$") or name:find("[cs]h$") then return name .. "es" end
  if name:find("[^aeiou]y$") then return name:sub(1, -2) .. "ies" end
  if name:find("f$") then return name:sub(1, -2) .. "ves" end
  return name .. "s"
end

local function IsNamed(e)
  return not e.name:find(" ") or e.class == "rare" or e.class == "rareelite" or e.class == "worldboss"
end

------------------------------------------------------------------------
-- Page
------------------------------------------------------------------------
local head = UI.SectionHeader(page, "HUNTING GROUNDS")
head:SetPoint("TOPLEFT")
head:SetPoint("TOPRIGHT")

local zoneLabel = Text(page, 11, C.text, "CENTER")
zoneLabel:SetPoint("TOP", head, "BOTTOM", 0, -6)
zoneLabel:SetWidth(PAGE_W - 60)

local function Arrow(label, point, x)
  local b = CreateFrame("Button", nil, page)
  b:SetSize(22, 16)
  b:SetPoint(point, head, point == "TOPLEFT" and "BOTTOMLEFT" or "BOTTOMRIGHT", x, -4)
  local t = Text(b, 12, C.tan, "CENTER")
  t:SetPoint("CENTER")
  t:SetText(label)
  return b
end
local prevBtn = Arrow("<", "TOPLEFT", 0)
local nextBtn = Arrow(">", "TOPRIGHT", 0)

local MAP_W, MAP_H = PAGE_W, 196
local mapBox = CreateFrame("Frame", nil, page)
mapBox:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -26)
mapBox:SetSize(MAP_W, MAP_H)
Fill(mapBox, "BACKGROUND", { 0.04, 0.04, 0.04 }, 1):SetAllPoints()
Border(mapBox, C.tanDim, 0.8, "OVERLAY")

local canvas = CreateFrame("Frame", nil, mapBox)
canvas:SetClipsChildren(true)
local tiles, dots = {}, {}

local noMap = Text(mapBox, 11, C.muted, "CENTER")
noMap:SetPoint("CENTER")
noMap:SetWidth(MAP_W - 40)

local listHead = UI.SectionHeader(page, "WHERE TO FIND THEM")
listHead:SetPoint("TOPLEFT", mapBox, "BOTTOMLEFT", 0, -8)
listHead:SetWidth(PAGE_W)
local listText = Text(page, 11, C.text)
listText:SetPoint("TOPLEFT", listHead, "BOTTOMLEFT", 6, -6)
listText:SetWidth(PAGE_W - 12)
listText:SetSpacing(3)

local function Button(label, i, w)
  local b = CreateFrame("Button", nil, page)
  b:SetSize(w, 24)
  b:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", (i - 1) * (w + 4), 0)
  b.bg = Fill(b, "BACKGROUND", C.panel2, 1)
  b.bg:SetAllPoints()
  Border(b, C.tanDim, 0.8)
  local t = Text(b, 11, C.tan, "CENTER")
  t:SetPoint("CENTER")
  t:SetText(label)
  b:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
    GameTooltip:Hide()
  end)
  return b
end
local bw = math.floor((PAGE_W - 8) / 3)
local mapBtn = Button("World map", 1, bw)
local sayBtn = Button("Tell (/say)", 2, bw)
local emoteBtn = Button("Point (/emote)", 3, bw)

------------------------------------------------------------------------
-- Zone map drawing
------------------------------------------------------------------------
local current, zones, zoneIndex = nil, {}, 1

local function Dot(parent, list, i)
  local d = list[i]
  if not d then
    d = CreateFrame("Frame", nil, parent)
    d.edge = d:CreateTexture(nil, "ARTWORK")
    d.edge:SetAllPoints()
    d.edge:SetColorTexture(0, 0, 0, 1)
    pcall(d.edge.SetRotation, d.edge, math.pi / 4)
    d.fill = d:CreateTexture(nil, "OVERLAY")
    d.fill:SetPoint("TOPLEFT", 2, -2)
    d.fill:SetPoint("BOTTOMRIGHT", -2, 2)
    d.fill:SetColorTexture(C.star[1], C.star[2], C.star[3], 1)
    pcall(d.fill.SetRotation, d.fill, math.pi / 4)
    d:EnableMouse(true)
    d:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(self.title or "", C.gold[1], C.gold[2], C.gold[3])
      GameTooltip:AddLine(self.body or "", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    d:SetScript("OnLeave", function() GameTooltip:Hide() end)
    list[i] = d
  end
  return d
end

local function DrawMap(m)
  for _, t in ipairs(tiles) do t:Hide() end
  for _, d in ipairs(dots) do d:Hide() end
  canvas:Hide()
  noMap:Hide()
  if not m then
    noMap:SetText("No map positions recorded yet.\nPositions are saved on kills made from now on.")
    noMap:Show()
    return
  end
  local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(m)
  local L = layers and layers[1]
  local files = L and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(m, 1)
  if not L or not files or #files == 0 then
    noMap:SetText("This map can't be drawn here.\nUse the World map button.")
    noMap:Show()
    return
  end
  local scale = math.min(MAP_W / L.layerWidth, MAP_H / L.layerHeight)
  local w, h = L.layerWidth * scale, L.layerHeight * scale
  canvas:SetSize(w, h)
  canvas:ClearAllPoints()
  canvas:SetPoint("CENTER", mapBox, "CENTER")
  canvas:Show()
  local cols = math.ceil(L.layerWidth / L.tileWidth)
  local tw, th = L.tileWidth * scale, L.tileHeight * scale
  for i, file in ipairs(files) do
    local t = tiles[i]
    if not t then
      t = canvas:CreateTexture(nil, "BACKGROUND")
      tiles[i] = t
    end
    t:SetTexture(file)
    t:SetSize(tw, th)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", canvas, "TOPLEFT", ((i - 1) % cols) * tw, -math.floor((i - 1) / cols) * th)
    t:SetVertexColor(0.8, 0.78, 0.72)
    t:Show()
  end
  local n = 0
  for _, s in pairs(current.spots or {}) do
    if s.m == m and s.x then
      n = n + 1
      local d = Dot(canvas, dots, n)
      local size = math.min(14, 7 + s.n)
      d:SetSize(size, size)
      d:ClearAllPoints()
      d:SetPoint("CENTER", canvas, "TOPLEFT", s.x * w, -s.y * h)
      d.title = current.name
      d.body = s.n .. (s.n == 1 and " kill" or " kills") .. " here" .. (s.sub and (" (" .. s.sub .. ")") or "")
      d:SetFrameLevel(canvas:GetFrameLevel() + 5)
      d:Show()
    end
  end
end

local function ZoneList(e)
  local byMap, list = {}, {}
  for _, s in pairs(e.spots or {}) do
    if s.m then
      if not byMap[s.m] then
        byMap[s.m] = { m = s.m, name = s.zone or MapName(s.m) or "?", n = 0 }
        list[#list + 1] = byMap[s.m]
      end
      byMap[s.m].n = byMap[s.m].n + s.n
    end
  end
  table.sort(list, function(a, b) return a.n > b.n end)
  return list
end

local function ShowZone()
  local z = zones[zoneIndex]
  prevBtn:SetShown(#zones > 1)
  nextBtn:SetShown(#zones > 1)
  if z then
    zoneLabel:SetText(z.name .. MUTED .. "   " .. z.n .. (z.n == 1 and " kill" or " kills") ..
      (#zones > 1 and ("   (" .. zoneIndex .. "/" .. #zones .. ")") or "") .. "|r")
  else
    zoneLabel:SetText(MUTED .. "No mapped kills|r")
  end
  DrawMap(z and z.m)
end

prevBtn:SetScript("OnClick", function()
  zoneIndex = zoneIndex > 1 and zoneIndex - 1 or #zones
  ShowZone()
end)
nextBtn:SetScript("OnClick", function()
  zoneIndex = zoneIndex < #zones and zoneIndex + 1 or 1
  ShowZone()
end)

------------------------------------------------------------------------
-- RP lines
------------------------------------------------------------------------
local function SayLine(e)
  local g = Grounds(e)[1]
  if not g then return nil end
  local who = IsNamed(e) and e.name or Plural(e.name)
  local lines = IsNamed(e) and {
    "%s? Last I saw of that one was %s.",
    "If you're after %s, try %s. That's where I found it.",
  } or {
    "%s? You'll find plenty %s. I've taken " .. g.n .. " there myself.",
    "Looking for %s? I've had the best luck %s.",
    "%s gather %s. Go armed.",
  }
  local fmt = lines[math.random(#lines)]
  local text = fmt:format(who, Phrase(g))
  return (text:gsub("^%l", string.upper))
end

local function EmoteLine(e)
  local g = Grounds(e)[1]
  if not g then return nil end
  local what = IsNamed(e) and e.name or ("the " .. Plural(e.name))
  local lines = {
    "unfolds a hand-drawn map and taps a spot %s, where %s were last hunted.",
    "points off toward the horizon. \"%s. That's where you'll find %s.\"",
    "flips the journal open to a sketched map and marks a spot %s for %s.",
  }
  local i = math.random(#lines)
  local where = Phrase(g)
  if i == 2 then
    return lines[i]:format((where:gsub("^%l", string.upper)), what)
  elseif i == 1 and IsNamed(e) then
    return ("unfolds a hand-drawn map and taps a spot %s, where %s was last seen."):format(where, what)
  end
  return lines[i]:format(where, what)
end

local function Send(msg, channel)
  if not msg then return end
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  if send then pcall(send, msg, channel) end
end

local function Preview(btn, title, text, r, g, b)
  btn.bg:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1)
  GameTooltip:SetOwner(btn, "ANCHOR_TOP")
  GameTooltip:AddLine(title, C.gold[1], C.gold[2], C.gold[3])
  GameTooltip:AddLine(text or "No locations recorded yet.", r, g, b, true)
  GameTooltip:Show()
end

sayBtn:SetScript("OnEnter", function(self)
  if not current then return end
  self.pending = SayLine(current)
  local me = UnitName("player") or "You"
  Preview(self, "Say", self.pending and (me .. " says: " .. self.pending), 1, 1, 1)
end)
sayBtn:SetScript("OnClick", function(self)
  if current then Send(self.pending or SayLine(current), "SAY") end
  self.pending = current and SayLine(current)
end)
emoteBtn:SetScript("OnEnter", function(self)
  if not current then return end
  self.pending = EmoteLine(current)
  local me = UnitName("player") or "You"
  Preview(self, "Emote", self.pending and (me .. " " .. self.pending), 1, 0.5, 0.25)
end)
emoteBtn:SetScript("OnClick", function(self)
  if current then Send(self.pending or EmoteLine(current), "EMOTE") end
  self.pending = current and EmoteLine(current)
end)

------------------------------------------------------------------------
-- World map pins
------------------------------------------------------------------------
local pinEntry, pinHost, pins, lastMap = nil, nil, {}, nil

local function DrawPins()
  if not pinHost then return end
  for _, p in ipairs(pins) do p:Hide() end
  if not pinEntry or not WorldMapFrame:IsShown() then return end
  local m = WorldMapFrame:GetMapID()
  local n = 0
  for _, s in pairs(pinEntry.spots or {}) do
    if s.m == m and s.x then
      n = n + 1
      local d = Dot(pinHost, pins, n)
      local size = math.min(22, 12 + s.n)
      d:SetSize(size, size)
      d.nx, d.ny = s.x, s.y
      ns.MapTrack(d)
      d.title = pinEntry.name
      d.body = s.n .. (s.n == 1 and " kill" or " kills") .. " here" .. (s.sub and (" (" .. s.sub .. ")") or "")
      d:Show()
    end
  end
end

local function EnsurePinHost()
  if pinHost or not WorldMapFrame or not WorldMapFrame.GetCanvas then return pinHost end
  pinHost = ns.MapOverlay and ns.MapOverlay()
  if not pinHost then return nil end
  local watcher = CreateFrame("Frame", nil, WorldMapFrame)
  local acc = 0
  watcher:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.2 then return end
    acc = 0
    local m = WorldMapFrame:GetMapID()
    if m ~= lastMap then lastMap = m; DrawPins() end
  end)
  WorldMapFrame:HookScript("OnHide", function()
    pinEntry = nil
    DrawPins()
  end)
  if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.SetCanvasScale then
    hooksecurefunc(WorldMapFrame.ScrollContainer, "SetCanvasScale", function() DrawPins() end)
  end
  return pinHost
end

mapBtn:SetScript("OnEnter", function(self)
  self.bg:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:AddLine("Show on the world map", C.gold[1], C.gold[2], C.gold[3])
  GameTooltip:AddLine("Opens this zone with your kill spots marked. They stay until you close the map.", 1, 1, 1, true)
  GameTooltip:Show()
end)
mapBtn:SetScript("OnClick", function()
  local z = zones[zoneIndex]
  if not current or not z then return end
  if not WorldMapFrame then return end
  if not WorldMapFrame:IsShown() then
    if ToggleWorldMap then pcall(ToggleWorldMap) else pcall(ShowUIPanel, WorldMapFrame) end
  end
  if not EnsurePinHost() then return end
  pcall(WorldMapFrame.SetMapID, WorldMapFrame, z.m)
  pinEntry = current
  lastMap = nil
  C_Timer.After(0.1, DrawPins)
end)

------------------------------------------------------------------------
function ns.FillGrounds(e)
  if current ~= e then zoneIndex = 1 end
  current = e
  zones = ZoneList(e)
  if zoneIndex > #zones then zoneIndex = 1 end
  ShowZone()

  local groups = Grounds(e)
  if #groups == 0 then
    listText:SetText(MUTED .. "No kill locations yet. Every kill from now on is pinned here.|r")
  else
    local lines = {}
    for i = 1, math.min(#groups, 4) do
      local g = groups[i]
      local phrase = Phrase(g):gsub("^in ", "")
      lines[#lines + 1] = TAN .. "-|r " .. phrase:gsub("^%l", string.upper) .. MUTED .. "   " .. g.n .. "|r"
    end
    listText:SetText(table.concat(lines, "\n"))
  end
end

-- best spot in words, used by the Physiology "Habitat" line
function ns.BestGround(e)
  local g = Grounds(e)[1]
  if not g then return nil end
  return (Phrase(g):gsub("^in ", ""))
end
end)
