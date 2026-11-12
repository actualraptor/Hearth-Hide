local ADDON, ns = ...
ns.Defer(function()

------------------------------------------------------------------------
-- Look and feel (Monster Hunter "Hunter's Notes": dark slate, tan trim,
-- amber stars)
------------------------------------------------------------------------
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local W, H = 940, 600
local LEFT_W = 280
local ROWS = 13
local ROW_H = 34

local C = {
  bg     = { 0.065, 0.075, 0.080 },
  panel  = { 0.110, 0.120, 0.120 },
  panel2 = { 0.150, 0.155, 0.150 },
  tan    = { 0.840, 0.710, 0.470 },
  tanDim = { 0.480, 0.410, 0.300 },
  text   = { 0.930, 0.900, 0.820 },
  muted  = { 0.580, 0.560, 0.500 },
  star   = { 1.000, 0.670, 0.200 },
  red    = { 0.900, 0.320, 0.260 },
}

-- Theme: "leather" (default) or "classic"; chosen at build time
local LEATHER = ns.db.settings.theme ~= "classic"
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local TITLE_FONT = LEATHER and "Fonts\\MORPHEUS.TTF" or FONT
C.onDark = { 0.840, 0.710, 0.470 } -- text on dark backgrounds (header, tabs)
C.onDarkDim = { 0.580, 0.560, 0.500 }
C.gold = { 0.840, 0.710, 0.470 }   -- accents over the game world (tooltips, map)
C.inset = { 0.05, 0.05, 0.05 }     -- text boxes
C.hover = { 0.22, 0.20, 0.16 }
C.pipOff = { 0.3, 0.3, 0.3 }
C.starOff = "70:70:70"
if LEATHER then
  C.bg     = { 0.29, 0.18, 0.10 }
  C.panel  = { 0.91, 0.85, 0.71 }
  C.panel2 = { 0.80, 0.70, 0.52 }
  C.tan    = { 0.55, 0.18, 0.12 }
  C.tanDim = { 0.45, 0.33, 0.21 }
  C.text   = { 0.20, 0.12, 0.06 }
  C.muted  = { 0.38, 0.28, 0.18 }
  C.star   = { 0.72, 0.33, 0.10 }
  C.red    = { 0.65, 0.12, 0.08 }
  C.onDark = { 0.88, 0.76, 0.52 }
  C.onDarkDim = { 0.66, 0.55, 0.38 }
  C.inset  = { 0.95, 0.90, 0.78 }
  C.hover  = { 0.88, 0.80, 0.62 }
  C.pipOff = { 0.52, 0.42, 0.30 }
  C.starOff = "130:108:78"
end
-- paper tone: darker, aged paper by default (Settings > Paper brightness)
local TONE = ns.db.settings.paperTone or 0.65
local function Aged(c) return { c[1] * TONE, c[2] * TONE * 0.97, c[3] * TONE * 0.9 } end
if LEATHER then
  C.panel, C.panel2, C.inset, C.hover = Aged(C.panel), Aged(C.panel2), Aged(C.inset), Aged(C.hover)
  C.paperTab = Aged({ 0.93, 0.87, 0.73 })
  C.card = Aged({ 0.95, 0.90, 0.78 })
end
local paperTex = {}
-- darker ink versions of the school colours for paper
local INK = {
  physical = { 0.25, 0.16, 0.08 }, holy = { 0.58, 0.44, 0.05 }, fire = { 0.69, 0.25, 0.10 },
  nature = { 0.22, 0.45, 0.14 }, frost = { 0.14, 0.35, 0.55 }, shadow = { 0.35, 0.22, 0.54 },
  arcane = { 0.55, 0.22, 0.55 },
}

local ICON_DIR = "Interface\\Icons\\"
local QMARK = ICON_DIR .. "INV_Misc_QuestionMark"
local STAR = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"

local function hex(c)
  return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end
local TAN, MUTED, TEXT = hex(C.tan), hex(C.muted), hex(C.text)

local function Fill(parent, layer, c, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(c[1], c[2], c[3], a or 1)
  return t
end

local function Border(frame, c, a, layer)
  local function line()
    local t = frame:CreateTexture(nil, layer or "BORDER")
    t:SetColorTexture(c[1], c[2], c[3], a or 1)
    return t
  end
  local top, bottom, left, right = line(), line(), line(), line()
  top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
  bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(1)
  left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1)
  right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1)
end

local function Text(parent, size, c, justify, flags, font)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(font or FONT, size, flags or "")
  fs:SetShadowOffset(1, -1)
  -- ink on paper has no drop shadow; light text on leather does
  local dark = LEATHER and (c == C.onDark or c == C.onDarkDim)
  fs:SetShadowColor(0, 0, 0, (LEATHER and not dark) and 0 or 0.9)
  c = c or C.text
  fs:SetTextColor(c[1], c[2], c[3])
  fs:SetJustifyH(justify or "LEFT")
  fs:SetJustifyV("TOP")
  return fs
end

-- tiled texture from the addon's Media folder
local function Tex(parent, layer, file, sub)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
  t:SetTexture(MEDIA .. file, "REPEAT", "REPEAT")
  t:SetHorizTile(true)
  t:SetVertTile(true)
  if file == "parchment.tga" then
    t:SetVertexColor(TONE, TONE * 0.97, TONE * 0.9)
    paperTex[#paperTex + 1] = t
  end
  return t
end

-- live paper brightness for the parchment textures
function ns.SetPaperTone(v)
  for _, t in ipairs(paperTex) do t:SetVertexColor(v, v * 0.97, v * 0.9) end
end

-- soft shadow along one edge ("LEFT", "RIGHT", "TOP", "BOTTOM")
local function Shade(parent, edge, size, alpha, layer)
  local t = parent:CreateTexture(nil, layer or "BORDER")
  t:SetColorTexture(1, 1, 1, 1)
  local dark, clear = CreateColor(0.12, 0.06, 0.02, alpha), CreateColor(0.12, 0.06, 0.02, 0)
  if edge == "LEFT" or edge == "RIGHT" then
    t:SetPoint("TOP" .. edge); t:SetPoint("BOTTOM" .. edge); t:SetWidth(size)
    if edge == "LEFT" then pcall(t.SetGradient, t, "HORIZONTAL", dark, clear)
    else pcall(t.SetGradient, t, "HORIZONTAL", clear, dark) end
  else
    t:SetPoint(edge .. "LEFT"); t:SetPoint(edge .. "RIGHT"); t:SetHeight(size)
    if edge == "BOTTOM" then pcall(t.SetGradient, t, "VERTICAL", dark, clear)
    else pcall(t.SetGradient, t, "VERTICAL", clear, dark) end
  end
  return t
end

-- stitched seam around a frame, inset by `inset` pixels
local function Stitch(frame, inset)
  local top = Tex(frame, "BORDER", "stitch_h.tga", 2)
  top:SetPoint("TOPLEFT", inset, -inset); top:SetPoint("TOPRIGHT", -inset, -inset); top:SetHeight(4)
  local bottom = Tex(frame, "BORDER", "stitch_h.tga", 2)
  bottom:SetPoint("BOTTOMLEFT", inset, inset); bottom:SetPoint("BOTTOMRIGHT", -inset, inset); bottom:SetHeight(4)
  local l = Tex(frame, "BORDER", "stitch_v.tga", 2)
  l:SetPoint("TOPLEFT", inset, -inset); l:SetPoint("BOTTOMLEFT", inset, inset); l:SetWidth(4)
  local r = Tex(frame, "BORDER", "stitch_v.tga", 2)
  r:SetPoint("TOPRIGHT", -inset, -inset); r:SetPoint("BOTTOMRIGHT", -inset, inset); r:SetWidth(4)
end

-- a leather-bound panel with a parchment page inside (used by other windows)
local function Book(frame, pad)
  pad = pad or 10
  local leather = Tex(frame, "BACKGROUND", "leather.tga", -8)
  leather:SetAllPoints()
  Border(frame, { 0.10, 0.05, 0.02 }, 1)
  Stitch(frame, 4)
  local page = Tex(frame, "BACKGROUND", "parchment.tga", -6)
  page:SetPoint("TOPLEFT", pad, -pad)
  page:SetPoint("BOTTOMRIGHT", -pad, pad)
  return page
end

-- page background for a panel: parchment in leather, flat colour in classic
local function Paper(frame, layer)
  if LEATHER then
    local t = Tex(frame, layer or "BACKGROUND", "parchment.tga", -6)
    t:SetAllPoints()
    return t
  end
  local t = Fill(frame, layer or "BACKGROUND", C.panel, 1)
  t:SetAllPoints()
  return t
end

local function SetIcon(tex, name)
  local path = name and (name:find("\\") and name or ICON_DIR .. name) or QMARK
  local ok = tex:SetTexture(path)
  if ok == false then tex:SetTexture(QMARK) end
end

local function Diamond(parent, size)
  local t = parent:CreateTexture(nil, "OVERLAY")
  t:SetSize(size, size)
  t:SetColorTexture(1, 1, 1, 1)
  pcall(t.SetRotation, t, math.pi / 4)
  return t
end

local function Stars(n)
  local s = ""
  for i = 1, 3 do
    if i <= n then
      s = s .. "|T" .. STAR .. ":14:14|t"
    else
      s = s .. "|T" .. STAR .. ":14:14:0:0:64:64:0:64:0:64:" .. C.starOff .. "|t"
    end
  end
  return s
end

local function Num(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  return tostring(n)
end

local CLASS_LABEL = {
  elite = "Elite", rare = "Rare", rareelite = "Rare Elite", worldboss = "Boss",
  trivial = "Trivial", minus = "Minor",
}

-- How special a creature is: elites, rares and bosses get their own look
local STYLE = {
  elite     = { label = "Elite",      ink = { 0.47, 0.30, 0.03 }, light = { 1.00, 0.82, 0.30 }, ring = { 0.82, 0.62, 0.20 }, atlas = "nameplates-icon-elite-gold" },
  rareelite = { label = "Rare Elite", ink = { 0.24, 0.28, 0.39 }, light = { 0.80, 0.86, 0.96 }, ring = { 0.80, 0.70, 0.40 }, atlas = "nameplates-icon-elite-silver" },
  rare      = { label = "Rare",       ink = { 0.24, 0.28, 0.39 }, light = { 0.80, 0.86, 0.96 }, ring = { 0.74, 0.77, 0.84 }, atlas = "nameplates-icon-elite-silver" },
  boss      = { label = "Boss",       ink = { 0.58, 0.07, 0.04 }, light = { 1.00, 0.32, 0.25 }, ring = { 0.62, 0.08, 0.05 }, skull = true },
}
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local function StyleOf(e)
  if e.boss or e.skull or e.class == "worldboss" then return STYLE.boss end
  return STYLE[e.class or ""]
end
local function StyleColor(st) return LEATHER and st.ink or st.light end

-- small badge: elite dragon / skull
local function SetBadge(tex, st)
  if not st then tex:Hide() return end
  if st.skull then
    tex:SetTexture(SKULL)
    tex:SetTexCoord(0, 1, 0, 1)
  elseif not (tex.SetAtlas and pcall(tex.SetAtlas, tex, st.atlas)) then
    tex:Hide()
    return
  end
  tex:Show()
end

local function LevelText(e)
  if e.skull then return "??" end
  if not e.minLvl then return "?" end
  if e.minLvl == e.maxLvl then return tostring(e.minLvl) end
  return e.minLvl .. "-" .. e.maxLvl
end

local function FirstZone(e)
  if e.firstZone then return e.firstZone end
  for z in pairs(e.zones or {}) do return z end
  return nil
end

local function EntryIcon(e)
  local fam = ns.GetFamily(e.family)
  if fam then return fam.icon end
  local t = ns.TYPES[e.type or ""]
  return t and t.icon or nil
end

-- A small 3D head-shot of the creature (falls back to its type icon)
local function Portrait(parent, size)
  local p = CreateFrame("Frame", nil, parent)
  p:SetSize(size, size)
  local bg = p:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.03, 0.03, 0.03, 1)
  p.icon = p:CreateTexture(nil, "ARTWORK")
  p.icon:SetAllPoints()
  p.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  p.model = CreateFrame("PlayerModel", nil, p)
  p.model:SetPoint("TOPLEFT", 1, -1)
  p.model:SetPoint("BOTTOMRIGHT", -1, 1)
  -- portraits are still pictures: freeze the animation to keep them cheap
  pcall(p.model.SetScript, p.model, "OnModelLoaded", function(m)
    pcall(m.SetPortraitZoom, m, 1)
    pcall(m.FreezeAnimation, m, 0, 0, 0)
  end)
  Border(p, C.tanDim, 0.8, "OVERLAY")
  -- coloured frame for elites, rares and bosses
  p.ring = p:CreateTexture(nil, "BACKGROUND", nil, -8)
  p.ring:SetPoint("TOPLEFT", -2, 2)
  p.ring:SetPoint("BOTTOMRIGHT", 2, -2)
  p.ring:SetColorTexture(1, 1, 1, 1)
  p.ring:Hide()
  return p
end

local function SetPortrait(p, e, dim)
  local useModel = not (ns.db and ns.db.settings.portraits == "icon")
  if e.id and useModel then
    if p.curId ~= e.id then
      p.curId = e.id
      p.model:ClearModel()
      pcall(p.model.SetCreature, p.model, e.id)
      pcall(p.model.SetPortraitZoom, p.model, 1)
    end
    p.model:Show()
    p.icon:Hide()
  else
    p.curId = nil
    p.model:Hide()
    p.icon:Show()
    SetIcon(p.icon, EntryIcon(e))
    p.icon:SetDesaturated(dim and true or false)
  end
  p.model:SetAlpha(dim and 0.45 or 1)
  local st = StyleOf(e)
  if st then
    p.ring:SetColorTexture(st.ring[1], st.ring[2], st.ring[3], 1)
    p.ring:Show()
  else
    p.ring:Hide()
  end
end

------------------------------------------------------------------------
-- Main window
------------------------------------------------------------------------
local f = CreateFrame("Frame", "HuntersJournalFrame", UIParent)
f:SetSize(W, H)
f:SetPoint("CENTER")
f:SetFrameStrata("HIGH")
f:SetToplevel(true)
f:EnableMouse(true)
f:SetMovable(true)
f:SetClampedToScreen(true)
f:Hide()
tinsert(UISpecialFrames, "HuntersJournalFrame")

if LEATHER then
  local cover = Tex(f, "BACKGROUND", "leather.tga", -8)
  cover:SetAllPoints()
  Border(f, { 0.10, 0.05, 0.02 }, 1)
  Stitch(f, 6)
  -- scuffed, worn edges and a soft vignette on the cover
  local vig = f:CreateTexture(nil, "BACKGROUND", nil, -7)
  vig:SetTexture(MEDIA .. "vignette.tga")
  vig:SetAllPoints()
  local wear = f:CreateTexture(nil, "BACKGROUND", nil, -7)
  wear:SetTexture(MEDIA .. "wear.tga")
  wear:SetAllPoints()
  wear:SetAlpha(0.8)
  -- brass corner protectors (tucked under the pages)
  local CORNERS = {
    { "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 },
    { "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 },
  }
  for _, c in ipairs(CORNERS) do
    local t = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    t:SetTexture(MEDIA .. "corner.tga")
    t:SetSize(46, 46)
    t:SetPoint(c[1], c[1]:find("LEFT") and -2 or 2, c[1]:find("TOP") and 2 or -2)
    t:SetTexCoord(c[2], c[3], c[4], c[5])
  end
else
  Fill(f, "BACKGROUND", C.bg, 0.97):SetAllPoints()
  Border(f, C.tan, 0.85)
end

local header = CreateFrame("Frame", nil, f)
header:SetPoint("TOPLEFT", 1, -1)
header:SetPoint("TOPRIGHT", -1, -1)
header:SetHeight(44)
if LEATHER then
  -- stamped title strap
  -- blind-tooled double frame pressed into the cover around the title:
  -- each line is a dark groove with a faint highlight on its lower edge
  local function Groove(x1, y1, x2, y2)
    local d = Fill(header, "BORDER", { 0.07, 0.03, 0.01 }, 0.75)
    local h = Fill(header, "BORDER", { 0.70, 0.50, 0.30 }, 0.22)
    if y1 == y2 then
      d:SetPoint("TOPLEFT", header, "TOP", x1, y1); d:SetSize(x2 - x1, 1)
      h:SetPoint("TOPLEFT", header, "TOP", x1, y1 - 1); h:SetSize(x2 - x1, 1)
    else
      d:SetPoint("TOPLEFT", header, "TOP", x1, y1); d:SetSize(1, y1 - y2)
      h:SetPoint("TOPLEFT", header, "TOP", x1 + 1, y1); h:SetSize(1, y1 - y2)
    end
  end
  for _, r in ipairs({ { 170, 10, 53 }, { 165, 14, 49 } }) do
    local w, top, bottom = r[1], -r[2], -r[3]
    Groove(-w, top, w, top); Groove(-w, bottom, w, bottom)
    Groove(-w, top, -w, bottom); Groove(w, top, w, bottom)
  end
else
  Fill(header, "BACKGROUND", C.panel2, 1):SetAllPoints()
  local hLine = Fill(header, "BORDER", C.tan, 0.6)
  hLine:SetPoint("BOTTOMLEFT"); hLine:SetPoint("BOTTOMRIGHT"); hLine:SetHeight(1)
end
header:EnableMouse(true)
header:RegisterForDrag("LeftButton")
header:SetScript("OnDragStart", function() f:StartMoving() end)
header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

local hIcon = header:CreateTexture(nil, "ARTWORK")
hIcon:SetSize(28, 28)
hIcon:SetPoint("LEFT", 12, 0)
SetIcon(hIcon, "INV_Misc_Book_09")
if LEATHER then hIcon:Hide() end

local hTitle = Text(header, LEATHER and 20 or 17, C.onDark, nil, nil, TITLE_FONT)
local hSub = Text(header, 10, C.onDarkDim)
if LEATHER then
  -- gold foil pressed into the leather, centred like a book cover
  hTitle:SetTextColor(0.80, 0.63, 0.33)
  hTitle:SetShadowColor(0.05, 0.02, 0, 0.9)
  hTitle:SetShadowOffset(0, 1)          -- dark edge on top = pressed in
  hTitle:SetJustifyH("CENTER")
  hTitle:SetPoint("TOP", header, "TOP", 0, -16)
  hSub:SetTextColor(0.66, 0.52, 0.30)
  hSub:SetShadowColor(0.05, 0.02, 0, 0.9)
  hSub:SetShadowOffset(0, 1)
  hSub:SetJustifyH("CENTER")
  hSub:SetPoint("TOP", hTitle, "BOTTOM", 0, -2)
  -- faint light catch along the bottom of the letters
  local function Catch(src, size, font)
    local c = Text(header, size, { 0.85, 0.66, 0.42 }, "CENTER", nil, font)
    c:SetDrawLayer("ARTWORK")
    c:SetAlpha(0.25)
    c:SetPoint("TOP", src, "TOP", 0, -1)
    hooksecurefunc(src, "SetText", function(_, t) c:SetText(t) end)
    return c
  end
  Catch(hTitle, 20, TITLE_FONT)
  Catch(hSub, 10)
else
  hTitle:SetPoint("LEFT", hIcon, "RIGHT", 10, 7)
  hSub:SetPoint("TOPLEFT", hTitle, "BOTTOMLEFT", 0, -3)
end
hTitle:SetText(LEATHER and "Hunter's Journal" or "HUNTER'S JOURNAL")
hSub:SetText("Monster Field Guide")

local hStats = Text(header, 11, C.onDarkDim, "RIGHT")
hStats:SetPoint("RIGHT", -120, 0)

local gear = CreateFrame("Button", nil, header)
gear:SetSize(64, 22)
gear:SetPoint("RIGHT", -46, 0)
local gearBg = Fill(gear, "BACKGROUND", LEATHER and { 0.17, 0.09, 0.04 } or C.bg, LEATHER and 0.85 or 1)
gearBg:SetAllPoints()
Border(gear, LEATHER and { 0.55, 0.40, 0.24 } or C.tanDim, 0.9)
local gearTxt = Text(gear, 10, C.onDark, "CENTER")
gearTxt:SetPoint("CENTER", 0, 0)
gearTxt:SetText("Settings")
gear:SetScript("OnClick", function() if ns.ToggleSettings then ns.ToggleSettings() end end)
gear:SetScript("OnEnter", function() gearTxt:SetTextColor(1, 1, 1) end)
gear:SetScript("OnLeave", function() gearTxt:SetTextColor(C.onDark[1], C.onDark[2], C.onDark[3]) end)

local close = CreateFrame("Button", nil, header)
close:SetSize(28, 28)
close:SetPoint("RIGHT", -10, 0)
local closeTxt = Text(close, 16, C.onDark, "CENTER")
closeTxt:SetPoint("CENTER", 0, 1)
closeTxt:SetText("X")
close:SetScript("OnClick", function() f:Hide() end)
close:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 1, 1) end)
close:SetScript("OnLeave", function() closeTxt:SetTextColor(C.onDark[1], C.onDark[2], C.onDark[3]) end)

------------------------------------------------------------------------
-- Left: search, filters, list
------------------------------------------------------------------------
local left = CreateFrame("Frame", nil, f)
left:SetPoint("TOPLEFT", 12, -56)
left:SetPoint("BOTTOMLEFT", 12, 12)
left:SetWidth(LEFT_W)
if LEATHER then
  Paper(left)
  Shade(left, "RIGHT", 26, 0.45)
  Shade(left, "LEFT", 10, 0.2)
  Border(left, { 0.18, 0.10, 0.05 }, 0.8)
else
  Fill(left, "BACKGROUND", C.panel, 1):SetAllPoints()
  Border(left, C.tanDim, 0.6)
end

local search
do
  local ok, box
  if LEATHER then
    box = CreateFrame("EditBox", nil, left)
    local line = Fill(box, "BORDER", C.tanDim, 0.9)
    line:SetPoint("BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", 0, 0); line:SetHeight(1)
  else
    ok, box = pcall(CreateFrame, "EditBox", nil, left, "InputBoxTemplate")
    if not ok then box = CreateFrame("EditBox", nil, left) end
  end
  search = box
  search:SetSize(LEFT_W - 104, 22)
  search:SetPoint("TOPLEFT", 16, -8)
  search:SetAutoFocus(false)
  search:SetFont(FONT, 12, "")
  search:SetTextColor(C.text[1], C.text[2], C.text[3])
  local ph = Text(search, 12, C.muted)
  ph:SetPoint("LEFT", 2, 0)
  ph:SetText(LEATHER and "Search the journal..." or "Search...")
  search.placeholder = ph
  search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
end

local FILTERS = {
  { label = "All" },
  { label = "Beasts", types = { Beast = true } },
  { label = "People", types = { Humanoid = true } },
  { label = "Undead", types = { Undead = true } },
  { label = "Other", other = true },
}
local filterIndex = 1
local filterButtons = {}
local scroll = 0
local selectedKey
local unknownTarget -- set when you target something with no entry
local listData = {}

local UpdateList, UpdateDetail

-- sort order for the list
local SORTS = {
  { key = "level", label = "Level" },
  { key = "name", label = "Name" },
  { key = "research", label = "Research" },
  { key = "kills", label = "Kills" },
  { key = "recent", label = "Recent" },
}
local sortBtn = CreateFrame("Button", nil, left)
sortBtn:SetSize(80, 20)
sortBtn:SetPoint("TOPRIGHT", -10, -9)
local sortBg = Fill(sortBtn, "BACKGROUND", C.panel2, LEATHER and 0.6 or 1)
sortBg:SetAllPoints()
Border(sortBtn, C.tanDim, 0.7)
local sortTxt = Text(sortBtn, 10, C.text, "CENTER")
sortTxt:SetPoint("CENTER", 0, 0)
local function SortLabel()
  local k = ns.db.settings.sortBy or "level"
  for _, srt in ipairs(SORTS) do
    if srt.key == k then sortTxt:SetText("Sort: " .. srt.label) return end
  end
  sortTxt:SetText("Sort: Level")
end
sortBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
sortBtn:SetScript("OnClick", function(_, button)
  local k = ns.db.settings.sortBy or "level"
  local idx = 1
  for i, srt in ipairs(SORTS) do if srt.key == k then idx = i end end
  idx = button == "RightButton" and (idx - 2) % #SORTS + 1 or idx % #SORTS + 1
  ns.db.settings.sortBy = SORTS[idx].key
  scroll = 0
  SortLabel()
  UpdateList()
end)
sortBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:AddLine("Sort the list", C.gold[1], C.gold[2], C.gold[3])
  for _, srt in ipairs(SORTS) do
    local on = srt.key == (ns.db.settings.sortBy or "level")
    GameTooltip:AddLine((on and "> " or "   ") .. srt.label, on and 1 or 0.7, on and 1 or 0.7, on and 1 or 0.7)
  end
  GameTooltip:AddLine("Click for next, right-click for previous", 0.6, 0.58, 0.52)
  GameTooltip:Show()
end)
sortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

for i, flt in ipairs(FILTERS) do
  local b = CreateFrame("Button", nil, left)
  local bw = (LEFT_W - 16) / #FILTERS
  b:SetSize(bw - 2, 20)
  b:SetPoint("TOPLEFT", 8 + (i - 1) * bw, -38)
  b.bg = Fill(b, "BACKGROUND", C.panel2, LEATHER and 0 or 1)
  b.bg:SetAllPoints()
  b.under = Fill(b, "BORDER", C.tan, 1)
  b.under:SetPoint("BOTTOMLEFT", 8, 0); b.under:SetPoint("BOTTOMRIGHT", -8, 0); b.under:SetHeight(2)
  b.under:Hide()
  b.text = Text(b, LEATHER and 11 or 10, C.muted, "CENTER")
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetText(flt.label)
  b:SetScript("OnClick", function()
    filterIndex = i
    scroll = 0
    UpdateList()
  end)
  filterButtons[i] = b
end

local listFrame = CreateFrame("Frame", nil, left)
listFrame:SetPoint("TOPLEFT", 4, -66)
listFrame:SetPoint("BOTTOMRIGHT", -4, 4)
listFrame:EnableMouseWheel(true)

local rows = {}
for i = 1, ROWS do
  local r = CreateFrame("Button", nil, listFrame)
  r:SetSize(LEFT_W - 8, ROW_H - 2)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
  r.bg = Fill(r, "BACKGROUND", C.panel2, LEATHER and 0 or (i % 2 == 0 and 0.55 or 0.25))
  r.bg:SetAllPoints()
  if LEATHER then
    local rule = Fill(r, "BORDER", C.tanDim, 0.35)
    rule:SetPoint("BOTTOMLEFT", 6, -1); rule:SetPoint("BOTTOMRIGHT", -6, -1); rule:SetHeight(1)
  end
  r.sel = Fill(r, "BORDER", LEATHER and C.panel2 or C.tan, LEATHER and 0.45 or 0.18)
  r.sel:SetAllPoints()
  r.bar = Fill(r, "ARTWORK", C.tan, 1)
  r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(3)
  r.hl = Fill(r, "HIGHLIGHT", C.text, 0.06)
  r.hl:SetAllPoints()
  r.icon = Portrait(r, 28)
  r.icon:SetPoint("LEFT", 7, 0)
  r.name = Text(r, 12, C.text)
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
  r.name:SetWidth(150)
  r.name:SetWordWrap(false)
  r.badge = r:CreateTexture(nil, "OVERLAY")
  r.badge:SetSize(13, 13)
  r.badge:Hide()
  r.tint = r:CreateTexture(nil, "BACKGROUND", nil, 1)
  r.tint:SetAllPoints()
  r.tint:SetColorTexture(1, 1, 1, 1)
  r.tint:Hide()
  r.sub = Text(r, 10, C.muted)
  r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 1)
  r.sub:SetWidth(150)
  r.sub:SetWordWrap(false)
  r.pips = {}
  for p = 1, 5 do
    local d = Diamond(r, 6)
    d:SetPoint("RIGHT", r, "RIGHT", -8 - (5 - p) * 9, 0)
    r.pips[p] = d
  end
  r:SetScript("OnClick", function(self)
    unknownTarget = nil
    selectedKey = self.key
    UpdateList()
    UpdateDetail()
  end)
  rows[i] = r
end

local emptyText = Text(listFrame, 12, C.muted, "CENTER")
emptyText:SetPoint("TOP", 0, -40)
emptyText:SetWidth(LEFT_W - 40)
emptyText:SetText("No entries yet.\n\nTarget or fight creatures out in the world and they will appear here.")

listFrame:SetScript("OnMouseWheel", function(_, delta)
  local maxScroll = math.max(0, #listData - ROWS)
  scroll = math.max(0, math.min(maxScroll, scroll - delta * 2))
  UpdateList()
end)

local function Matches(e)
  local flt = FILTERS[filterIndex]
  if flt.types and not flt.types[e.type or ""] then return false end
  if flt.other then
    local t = e.type or ""
    if t == "Beast" or t == "Humanoid" or t == "Undead" then return false end
  end
  local q = search:GetText()
  if q and q ~= "" and not e.name:lower():find(q:lower(), 1, true) then return false end
  return true
end

local function PipColor(d, on, mastered)
  if on then
    if mastered then d:SetVertexColor(C.star[1], C.star[2], C.star[3], 1)
    else d:SetVertexColor(C.tan[1], C.tan[2], C.tan[3], 1) end
  else
    d:SetVertexColor(C.pipOff[1], C.pipOff[2], C.pipOff[3], 1)
  end
end

UpdateList = function()
  wipe(listData)
  local total, mastered = 0, 0
  for key, e in pairs(ns.db.entries) do
    e.key = key
    total = total + 1
    if ns.Level(e) >= ns.MAX_LEVEL then mastered = mastered + 1 end
    if Matches(e) then listData[#listData + 1] = e end
  end
  local sortBy = ns.db.settings.sortBy or "level"
  table.sort(listData, function(a, b)
    if sortBy == "research" then
      local la, lb = ns.Level(a), ns.Level(b)
      if la ~= lb then return la > lb end
      if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
    elseif sortBy == "kills" then
      if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
    elseif sortBy == "recent" then
      local ta, tb = a.lastKill or a.firstKill or a.seen or 0, b.lastKill or b.firstKill or b.seen or 0
      if ta ~= tb then return ta > tb end
    elseif sortBy == "level" then
      if (a.minLvl or 0) ~= (b.minLvl or 0) then return (a.minLvl or 0) < (b.minLvl or 0) end
    end
    return a.name < b.name
  end)
  SortLabel()
  local num = LEATHER and "|cfff2dca8" or TEXT
  hStats:SetText(string.format("%s%d|r entries   %s%d|r mastered", num, total, num, mastered))

  if not unknownTarget and (not selectedKey or not ns.db.entries[selectedKey]) then
    selectedKey = listData[1] and listData[1].key
  end

  for i, b in ipairs(filterButtons) do
    if LEATHER then
      b.under:SetShown(i == filterIndex)
      local c = i == filterIndex and C.text or C.muted
      b.text:SetTextColor(c[1], c[2], c[3])
    elseif i == filterIndex then
      b.bg:SetColorTexture(C.tan[1], C.tan[2], C.tan[3], 1)
      b.text:SetTextColor(0.1, 0.09, 0.07)
    else
      b.bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
      b.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end
  end

  emptyText:SetShown(#listData == 0)
  for i = 1, ROWS do
    local r = rows[i]
    local e = listData[i + scroll]
    if e then
      r.key = e.key
      local lvl = ns.Level(e)
      SetPortrait(r.icon, e, lvl < 2)
      r.name:SetText(e.name)
      local st = StyleOf(e)
      local nc = st and StyleColor(st) or (lvl < 2 and C.muted or C.text)
      r.name:SetTextColor(nc[1], nc[2], nc[3])
      SetBadge(r.badge, st)
      if st then
        r.badge:ClearAllPoints()
        r.badge:SetPoint("LEFT", r.name, "LEFT", math.min(r.name:GetStringWidth(), 140) + 4, 0)
        r.tint:SetColorTexture(st.ring[1], st.ring[2], st.ring[3], LEATHER and 0.12 or 0.10)
        r.tint:Show()
      else
        r.tint:Hide()
      end
      local z = FirstZone(e)
      r.sub:SetText("Lv " .. LevelText(e) .. (z and ("  " .. z) or ""))
      for p = 1, 5 do PipColor(r.pips[p], p <= lvl, lvl >= ns.MAX_LEVEL) end
      local isSel = e.key == selectedKey
      r.sel:SetShown(isSel)
      r.bar:SetShown(isSel)
      r:Show()
    else
      r:Hide()
    end
  end
end

search:SetScript("OnTextChanged", function(self)
  self.placeholder:SetShown(self:GetText() == "")
  scroll = 0
  if f:IsShown() then UpdateList() end
end)

------------------------------------------------------------------------
-- Right: detail page
------------------------------------------------------------------------
local right = CreateFrame("Frame", nil, f)
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
right:SetPoint("BOTTOMRIGHT", -12, 12)
if LEATHER then
  -- the right-hand page of the open book, drawn on the cover itself so the
  -- page content (in child frames) always sits on top of it
  local rp = Tex(f, "BACKGROUND", "parchment.tga", -6)
  rp:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
  rp:SetPoint("BOTTOMRIGHT", -12, 12)
  local gutter = f:CreateTexture(nil, "BACKGROUND", nil, -5)
  gutter:SetColorTexture(1, 1, 1, 1)
  gutter:SetPoint("TOPLEFT", rp, "TOPLEFT")
  gutter:SetPoint("BOTTOMLEFT", rp, "BOTTOMLEFT")
  gutter:SetWidth(34)
  pcall(gutter.SetGradient, gutter, "HORIZONTAL", CreateColor(0.12, 0.06, 0.02, 0.5), CreateColor(0.12, 0.06, 0.02, 0))
  local spine = f:CreateTexture(nil, "BACKGROUND", nil, -4)
  spine:SetColorTexture(0.20, 0.11, 0.05, 0.9)
  spine:SetPoint("TOPLEFT", rp, "TOPLEFT", -1, 0)
  spine:SetPoint("BOTTOMLEFT", rp, "BOTTOMLEFT", -1, 0)
  spine:SetWidth(2)
  -- edges of the page block on the outer sides
  local edgeR = f:CreateTexture(nil, "BACKGROUND", nil, -4)
  edgeR:SetTexture(MEDIA .. "pageedge.tga", "CLAMP", "REPEAT")
  edgeR:SetVertTile(true)
  edgeR:SetPoint("TOPRIGHT", rp, "TOPRIGHT"); edgeR:SetPoint("BOTTOMRIGHT", rp, "BOTTOMRIGHT")
  edgeR:SetWidth(6)
  edgeR:SetVertexColor(TONE + 0.1, (TONE + 0.1) * 0.97, (TONE + 0.1) * 0.9)
  local edgeL = left:CreateTexture(nil, "BORDER", nil, 1)
  edgeL:SetTexture(MEDIA .. "pageedge.tga", "CLAMP", "REPEAT")
  edgeL:SetVertTile(true)
  edgeL:SetTexCoord(1, 0, 0, 1)
  edgeL:SetPoint("TOPLEFT"); edgeL:SetPoint("BOTTOMLEFT")
  edgeL:SetWidth(6)
  edgeL:SetVertexColor(TONE + 0.1, (TONE + 0.1) * 0.97, (TONE + 0.1) * 0.9)
  -- silk bookmark ribbon hanging out of the book
  local ribbon = f:CreateTexture(nil, "OVERLAY", nil, 2)
  ribbon:SetTexture(MEDIA .. "ribbon.tga")
  ribbon:SetPoint("TOP", rp, "BOTTOM", 140, 4)
  ribbon:SetSize(16, 56)
end

-- title band
local dName = Text(right, LEATHER and 28 or 24, C.text, nil, nil, TITLE_FONT)
dName:SetPoint("TOPLEFT", 4, -4)
local dInfo = Text(right, 12, C.muted)
dInfo:SetPoint("TOPLEFT", dName, "BOTTOMLEFT", 0, -6)

-- stamped plate next to the name: ELITE / RARE / BOSS
local stamp = CreateFrame("Frame", nil, right)
stamp:SetHeight(20)
stamp.bg = stamp:CreateTexture(nil, "BACKGROUND")
stamp.bg:SetAllPoints()
stamp.edge = {}
for i = 1, 4 do stamp.edge[i] = stamp:CreateTexture(nil, "BORDER") end
stamp.edge[1]:SetPoint("TOPLEFT"); stamp.edge[1]:SetPoint("TOPRIGHT"); stamp.edge[1]:SetHeight(1)
stamp.edge[2]:SetPoint("BOTTOMLEFT"); stamp.edge[2]:SetPoint("BOTTOMRIGHT"); stamp.edge[2]:SetHeight(1)
stamp.edge[3]:SetPoint("TOPLEFT"); stamp.edge[3]:SetPoint("BOTTOMLEFT"); stamp.edge[3]:SetWidth(1)
stamp.edge[4]:SetPoint("TOPRIGHT"); stamp.edge[4]:SetPoint("BOTTOMRIGHT"); stamp.edge[4]:SetWidth(1)
stamp.icon = stamp:CreateTexture(nil, "ARTWORK")
stamp.icon:SetSize(14, 14)
stamp.icon:SetPoint("LEFT", 5, 0)
stamp.text = Text(stamp, 11, C.onDark, "LEFT", nil, TITLE_FONT)
stamp.text:SetJustifyV("MIDDLE")
stamp:Hide()

local function ShowStamp(e)
  local st = StyleOf(e)
  if not st then stamp:Hide() return end
  SetBadge(stamp.icon, st)
  local hasIcon = stamp.icon:IsShown()
  stamp.text:ClearAllPoints()
  stamp.text:SetPoint("LEFT", hasIcon and 22 or 7, 0)
  stamp.text:SetText(st.label:upper())
  local c = st.ring
  stamp.bg:SetColorTexture(c[1] * 0.35, c[2] * 0.3, c[3] * 0.3, 0.95)
  for i = 1, 4 do stamp.edge[i]:SetColorTexture(c[1], c[2], c[3], 1) end
  local tc = st.light
  stamp.text:SetTextColor(tc[1], tc[2], tc[3])
  stamp:SetWidth(stamp.text:GetStringWidth() + (hasIcon and 30 or 14))
  stamp:ClearAllPoints()
  stamp:SetPoint("LEFT", dName, "LEFT", dName:GetStringWidth() + 12, 0)
  stamp:Show()
end

local rlLabel = Text(right, 10, C.tan, "RIGHT")
rlLabel:SetPoint("TOPRIGHT", -150, -6)
rlLabel:SetText("RESEARCH LV")
local rlNum = Text(right, 30, C.tan, "RIGHT")
rlNum:SetPoint("TOPRIGHT", rlLabel, "BOTTOMRIGHT", 0, -2)
local rlName = Text(right, 12, C.text)
rlName:SetPoint("TOPLEFT", rlLabel, "TOPRIGHT", 12, 0)
local rlPips = {}
for p = 1, 5 do
  local d = Diamond(right, 11)
  d:SetPoint("TOPLEFT", rlName, "BOTTOMLEFT", 4 + (p - 1) * 20, -10)
  rlPips[p] = d
end
local rlNext = Text(right, 10, C.muted)
rlNext:SetPoint("TOPRIGHT", right, "TOPRIGHT", -4, -62)

if LEATHER then
  -- wax seal with the research level pressed into it
  local seal = CreateFrame("Frame", nil, right)
  seal:SetSize(80, 80)
  seal:SetPoint("TOPRIGHT", 4, 8)
  local wax = seal:CreateTexture(nil, "ARTWORK")
  wax:SetTexture(MEDIA .. "seal.tga")
  wax:SetAllPoints()
  rlLabel:SetParent(seal)
  rlLabel:ClearAllPoints()
  rlLabel:SetPoint("TOP", 0, -24)
  rlLabel:SetJustifyH("CENTER")
  rlLabel:SetFont(FONT, 7, "")
  rlLabel:SetTextColor(0.97, 0.85, 0.72)
  rlLabel:SetText("RESEARCH")
  rlNum:SetParent(seal)
  rlNum:ClearAllPoints()
  rlNum:SetPoint("CENTER", 0, -6)
  rlNum:SetJustifyH("CENTER")
  rlNum:SetFont(TITLE_FONT, 26, "")
  rlNum:SetTextColor(0.97, 0.85, 0.72)
  rlNum:SetShadowColor(0.2, 0.02, 0, 0.9)
  rlName:ClearAllPoints()
  rlName:SetPoint("TOPRIGHT", seal, "TOPLEFT", -12, -10)
  rlName:SetJustifyH("RIGHT")
  for p = 1, 5 do
    rlPips[p]:ClearAllPoints()
    rlPips[p]:SetPoint("TOPRIGHT", rlName, "BOTTOMRIGHT", -2 - (5 - p) * 18, -9)
  end
  rlNext:ClearAllPoints()
  rlNext:SetPoint("TOPRIGHT", seal, "TOPLEFT", -12, -50)
  ns.UI_seal = seal
end

local bandLine = Fill(right, "BORDER", LEATHER and C.tanDim or C.tan, LEATHER and 0.9 or 0.5)
bandLine:SetPoint("TOPLEFT", 0, -82)
bandLine:SetPoint("TOPRIGHT", 0, -82)
bandLine:SetHeight(1)

-- model viewer
local modelBox = CreateFrame("Frame", nil, right)
modelBox:SetPoint("TOPLEFT", 0, -94)
modelBox:SetSize(250, 240)
local modelRing = right:CreateTexture(nil, "BACKGROUND", nil, -2)
modelRing:SetPoint("TOPLEFT", modelBox, "TOPLEFT", -3, 3)
modelRing:SetPoint("BOTTOMRIGHT", modelBox, "BOTTOMRIGHT", 3, -3)
modelRing:Hide()
local mbg = modelBox:CreateTexture(nil, "BACKGROUND")
mbg:SetAllPoints()
mbg:SetColorTexture(1, 1, 1, 1)
if LEATHER then
  mbg:Hide()
  local cardPaper = Tex(modelBox, "BACKGROUND", "parchment.tga", 0)
  cardPaper:SetAllPoints()
  Shade(modelBox, "BOTTOM", 18, 0.12)
  Border(modelBox, { 0.70, 0.60, 0.44 }, 1)
  -- two strips of tape holding the card in
  for i, x in ipairs({ -8, 8 }) do
    local tape = Fill(modelBox, "OVERLAY", { 0.85, 0.79, 0.62 }, 0.75)
    tape:SetSize(54, 15)
    tape:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", x, 6)
    pcall(tape.SetRotation, tape, i == 1 and 0.5 or -0.5)
  end
else
  if not pcall(mbg.SetGradient, mbg, "VERTICAL", CreateColor(0.05, 0.05, 0.05, 1), CreateColor(0.18, 0.17, 0.14, 1)) then
    mbg:SetColorTexture(0.1, 0.1, 0.09, 1)
  end
  Border(modelBox, C.tanDim, 0.8)
end
local modelIcon = modelBox:CreateTexture(nil, "BORDER")
modelIcon:SetSize(96, 96)
modelIcon:SetPoint("CENTER")
modelIcon:SetAlpha(LEATHER and 0 or 0.18)
local model = CreateFrame("PlayerModel", nil, modelBox)
model:SetPoint("TOPLEFT", 1, -1)
model:SetPoint("BOTTOMRIGHT", -1, 1)
local facing = 0.4
local dragX
model:EnableMouse(true)
model:SetScript("OnMouseDown", function() dragX = GetCursorPosition() end)
model:SetScript("OnMouseUp", function() dragX = nil end)
model:SetScript("OnUpdate", function(self, elapsed)
  if dragX then
    local x = GetCursorPosition()
    facing = facing + (x - dragX) * 0.02
    dragX = x
  else
    facing = facing + elapsed * 0.35
  end
  self:SetFacing(facing)
end)
local modelHint = Text(modelBox, 9, C.muted, "CENTER")
modelHint:SetPoint("BOTTOM", 0, 6)
modelHint:SetText("drag to rotate")

-- physiology box
local phys = CreateFrame("Frame", nil, right)
phys:SetPoint("TOPLEFT", modelBox, "BOTTOMLEFT", 0, -10)
phys:SetPoint("BOTTOMLEFT", 0, 0)
phys:SetWidth(250)
if not LEATHER then
  Fill(phys, "BACKGROUND", C.panel, 1):SetAllPoints()
  Border(phys, C.tanDim, 0.6)
end

local function SectionHeader(parent, label)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetHeight(20)
  local bg = Fill(bar, "BACKGROUND", C.tan, LEATHER and 0 or 1)
  bg:SetAllPoints()
  local t
  if LEATHER then
    t = Text(bar, 13, C.tan, nil, nil, TITLE_FONT)
    local rule = Fill(bar, "BORDER", C.tan, 0.55)
    rule:SetPoint("BOTTOMLEFT", 0, 0); rule:SetPoint("BOTTOMRIGHT", 0, 0); rule:SetHeight(1)
    t:SetPoint("LEFT", 2, 0)
  else
    t = Text(bar, 11, { 0.10, 0.09, 0.07 })
    t:SetPoint("LEFT", 8, 0)
  end
  t:SetJustifyV("MIDDLE")
  t:SetText(label)
  bar.text = t
  return bar
end

local physHead = SectionHeader(phys, "PHYSIOLOGY")
physHead:SetPoint("TOPLEFT", 1, -1)
physHead:SetPoint("TOPRIGHT", -1, -1)

local PHYS_ROWS = { "Level", "Class", "Health", "Slain", "First slain", "Habitat" }
local physVals = {}
for i, label in ipairs(PHYS_ROWS) do
  local l = Text(phys, 11, C.muted)
  l:SetPoint("TOPLEFT", 10, -28 - (i - 1) * 21)
  l:SetText(label)
  local v = Text(phys, 11, C.text, "RIGHT")
  v:SetPoint("TOPRIGHT", -10, -28 - (i - 1) * 21)
  v:SetWidth(150)
  v:SetWordWrap(false)
  physVals[label] = v
end

-- tabs
local tabArea = CreateFrame("Frame", nil, right)
tabArea:SetPoint("TOPLEFT", modelBox, "TOPRIGHT", 12, 0)
tabArea:SetPoint("BOTTOMRIGHT", 0, 0)

local TABS = {
  { label = "Overview",    need = 3 },
  { label = "Materials",   need = 4 },
  { label = "Taming",      need = 2 },
  { label = "Lore",        need = 5 },
  { label = "My Notes",    need = 1 },
  { label = "Grounds",     need = 2 },
}
local tabIndex = 1
local tabButtons, tabPages = {}, {}

local pageArea = CreateFrame("Frame", nil, tabArea)
pageArea:SetPoint("TOPLEFT", 0, -26)
pageArea:SetPoint("BOTTOMRIGHT", 0, 0)
if LEATHER then
  Fill(pageArea, "BACKGROUND", C.inset, 0.35):SetAllPoints()
  Border(pageArea, C.tanDim, 0.45)
else
  Fill(pageArea, "BACKGROUND", C.panel, 1):SetAllPoints()
  Border(pageArea, C.tanDim, 0.6)
end

local PAGE_W = W - 12 - LEFT_W - 12 - 12 - 250 - 12 - 24

for i, tab in ipairs(TABS) do
  local b = CreateFrame("Button", nil, tabArea)
  b:SetSize(58, 24)
  b:SetPoint("BOTTOMLEFT", tabArea, "TOPLEFT", (i - 1) * 60, -26)
  b.bg = Fill(b, "BACKGROUND", C.panel2, 1)
  b.bg:SetAllPoints()
  if LEATHER then
    b.bg:Hide()
    b.leather = Tex(b, "BACKGROUND", "leather.tga", 1)
    b.leather:SetAllPoints()
    b.paper = Tex(b, "BACKGROUND", "parchment.tga", 1)
    b.paper:SetAllPoints()
    local hi = Fill(b, "BORDER", { 1, 0.85, 0.6 }, 0.25)
    hi:SetPoint("TOPLEFT"); hi:SetPoint("TOPRIGHT"); hi:SetHeight(1)
  end
  b.text = Text(b, 10, C.muted, "CENTER")
  b.text:SetPoint("CENTER", 0, 0)
  b:SetScript("OnClick", function()
    tabIndex = i
    UpdateDetail()
  end)
  tabButtons[i] = b

  local page = CreateFrame("Frame", nil, pageArea)
  page:SetPoint("TOPLEFT", 12, -12)
  page:SetPoint("BOTTOMRIGHT", -12, 12)
  page:Hide()
  tabPages[i] = page
end

-- lock overlay (MH style "???")
local lockPage = CreateFrame("Frame", nil, pageArea)
lockPage:SetAllPoints()
local lockQ = Text(lockPage, 54, C.tanDim, "CENTER")
lockQ:SetPoint("CENTER", 0, 30)
lockQ:SetText("???")
local lockMsg = Text(lockPage, 12, C.muted, "CENTER")
lockMsg:SetPoint("TOP", lockQ, "BOTTOM", 0, -10)
lockMsg:SetWidth(PAGE_W - 40)

-- Overview page --------------------------------------------------------
local ov = tabPages[1]
local ovHead = SectionHeader(ov, "WEAKNESS")
ovHead:SetPoint("TOPLEFT"); ovHead:SetPoint("TOPRIGHT")
local weakRows = {}
for i, sc in ipairs(ns.SCHOOLS) do
  local y = -26 - (i - 1) * 19
  local n = Text(ov, 12, LEATHER and INK[sc.key] or sc.color)
  n:SetPoint("TOPLEFT", 6, y)
  n:SetText(sc.name)
  local s = Text(ov, 12, C.text)
  s:SetPoint("TOPLEFT", 90, y + 1)
  local o = Text(ov, 10, C.muted, "RIGHT")
  o:SetPoint("TOPRIGHT", -6, y)
  weakRows[sc.key] = { stars = s, obs = o }
end
local ovHint = Text(ov, 10, C.muted)
ovHint:SetPoint("TOPLEFT", 6, -26 - #ns.SCHOOLS * 19 - 2)
ovHint:SetWidth(PAGE_W - 12)

local exHead = SectionHeader(ov, "EXPLOITS")
exHead:SetPoint("TOPLEFT", ovHint, "BOTTOMLEFT", -6, -8)
exHead:SetWidth(PAGE_W)
local exText = Text(ov, 11, C.text)
exText:SetPoint("TOPLEFT", exHead, "BOTTOMLEFT", 6, -6)
exText:SetWidth(PAGE_W - 12)
exText:SetSpacing(2)

local abHead = SectionHeader(ov, "OBSERVED ABILITIES")
abHead:SetPoint("TOPLEFT", exText, "BOTTOMLEFT", -6, -10)
abHead:SetWidth(PAGE_W)
local abText = Text(ov, 11, C.text)
abText:SetPoint("TOPLEFT", abHead, "BOTTOMLEFT", 6, -6)
abText:SetWidth(PAGE_W - 12)
abText:SetSpacing(2)

-- Materials page -------------------------------------------------------
local mat = tabPages[2]
local MAT_ROWS = 15
local matRows = {}
local function MatRow(i)
  local r = matRows[i]
  if r then return r end
  r = CreateFrame("Button", nil, mat)
  r:SetSize(PAGE_W, 20)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(18, 18)
  r.icon:SetPoint("LEFT", 4, 0)
  r.name = Text(r, 11, C.text)
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.name:SetJustifyV("MIDDLE")
  r.name:SetWidth(PAGE_W - 110)
  r.name:SetWordWrap(false)
  r.pct = Text(r, 11, C.star, "RIGHT")
  r.pct:SetPoint("RIGHT", -4, 0)
  r.pct:SetJustifyV("MIDDLE")
  r.head = SectionHeader(r, "")
  r.head:SetAllPoints()
  r:SetScript("OnEnter", function(self)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:Show()
    end
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  matRows[i] = r
  return r
end

-- Taming page ----------------------------------------------------------
local tm = tabPages[3]
local tmIcon = tm:CreateTexture(nil, "ARTWORK")
tmIcon:SetSize(44, 44)
tmIcon:SetPoint("TOPLEFT", 4, -4)
local tmFamily = Text(tm, 18, C.tan, nil, nil, TITLE_FONT)
tmFamily:SetPoint("TOPLEFT", tmIcon, "TOPRIGHT", 10, -2)
local tmRole = Text(tm, 11, C.muted)
tmRole:SetPoint("TOPLEFT", tmFamily, "BOTTOMLEFT", 0, -4)
local tmBody = Text(tm, 11, C.text)
tmBody:SetPoint("TOPLEFT", tmIcon, "BOTTOMLEFT", 0, -12)
tmBody:SetWidth(PAGE_W - 8)
tmBody:SetSpacing(3)

-- Field notes page -----------------------------------------------------
local fn = tabPages[4]
local fnHead = SectionHeader(fn, "FIELD NOTES")
fnHead:SetPoint("TOPLEFT"); fnHead:SetPoint("TOPRIGHT")
local fnBody = Text(fn, 12, C.text)
fnBody:SetPoint("TOPLEFT", fnHead, "BOTTOMLEFT", 6, -10)
fnBody:SetWidth(PAGE_W - 12)
fnBody:SetSpacing(3)
local recHead = SectionHeader(fn, "HUNTER'S RECORD")
recHead:SetPoint("TOPLEFT", fnBody, "BOTTOMLEFT", -6, -14)
recHead:SetWidth(PAGE_W)
local recBody = Text(fn, 11, C.text)
recBody:SetPoint("TOPLEFT", recHead, "BOTTOMLEFT", 6, -8)
recBody:SetWidth(PAGE_W - 12)
recBody:SetSpacing(3)

-- empty state for the right side
local noSel = Text(right, 14, C.muted, "CENTER")
noSel:SetPoint("CENTER")
noSel:SetText("Select a creature from the list.")

-- shown when you target something that has no entry
local unkQ = Text(right, 64, C.tanDim, "CENTER")
unkQ:SetPoint("CENTER", 0, 40)
unkQ:SetText("???")
local unkMsg = Text(right, 13, C.muted, "CENTER")
unkMsg:SetPoint("TOP", unkQ, "BOTTOM", 0, -12)
unkMsg:SetWidth(420)

------------------------------------------------------------------------
-- Fill the detail page
------------------------------------------------------------------------
local function FillOverview(e)
  local weak, hint = ns.Weakness(e)
  for _, sc in ipairs(ns.SCHOOLS) do
    local w = weak[sc.key]
    local row = weakRows[sc.key]
    if w.stars == 0 then
      row.stars:SetText(hex(C.red) .. "IMMUNE|r")
    elseif w.stars == 1 then
      row.stars:SetText(Stars(1) .. "  " .. MUTED .. "resists|r")
    else
      row.stars:SetText(Stars(w.stars))
    end
    row.obs:SetText(w.observed > 0 and (w.observed .. " hits seen") or "")
  end
  local hintText = "More stars = more effective."
  if hint then hintText = hint.label .. ". " .. hintText end
  local t = ns.TYPES[e.type or ""]
  if t and t.immuneBleed then hintText = hintText .. " Immune to bleeds." end
  ovHint:SetText(hintText)

  local ex = ns.Exploits(e)
  if #ex == 0 then
    exText:SetText(MUTED .. "None known.|r")
  else
    local parts, note = {}, nil
    for _, x in ipairs(ex) do
      if x:sub(1, 1) == "(" then note = x else parts[#parts + 1] = x end
    end
    exText:SetText(table.concat(parts, TAN .. "  /  |r") .. (note and ("\n" .. MUTED .. note .. "|r") or ""))
  end

  local spells = {}
  for name, count in pairs(e.spells or {}) do spells[#spells + 1] = { name, count } end
  table.sort(spells, function(a, b) return a[2] > b[2] end)
  if #spells == 0 then
    abText:SetText(MUTED .. "Nothing recorded yet. Abilities appear as you watch it fight.|r")
  else
    local lines = {}
    for i = 1, math.min(#spells, 5) do
      lines[#lines + 1] = TAN .. "-|r " .. spells[i][1] .. MUTED .. "  x" .. spells[i][2] .. "|r"
    end
    abText:SetText(table.concat(lines, "\n"))
  end
end

local function SortedItems(tbl)
  local list = {}
  for id, d in pairs(tbl or {}) do list[#list + 1] = { id = id, n = d.n, q = d.q } end
  table.sort(list, function(a, b) return a.n > b.n end)
  return list
end

local function FillMaterials(e)
  local i = 0
  local function head(label)
    i = i + 1
    local r = MatRow(i)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * 21)
    r.head:Show()
    r.head.text:SetText(label)
    r.icon:Hide(); r.name:SetText(""); r.pct:SetText("")
    r.itemID = nil
    r:Show()
  end
  local function item(it, total)
    if i >= MAT_ROWS then return end
    i = i + 1
    local r = MatRow(i)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * 21)
    r.head:Hide()
    r.icon:Show()
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(it.id)
    r.icon:SetTexture(icon or QMARK)
    local name, quality
    if C_Item and C_Item.GetItemInfo then
      local n, _, q = C_Item.GetItemInfo(it.id)
      name, quality = n, q
    elseif GetItemInfo then
      local n, _, q = GetItemInfo(it.id)
      name, quality = n, q
    end
    local color = TEXT
    if LEATHER then
      local PAPER_Q = { [0] = MUTED, [1] = TEXT, [2] = "|cff1d7a12", [3] = "|cff0a4f9e", [4] = "|cff6b2a9a", [5] = "|cffa85a00" }
      color = PAPER_Q[quality or 1] or TEXT
    elseif quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
      color = ITEM_QUALITY_COLORS[quality].hex or color
    end
    if not name then
      -- not in the client's cache yet: ask for it and redraw when it arrives
      if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, it.id) end
      ns.waitingItems = true
    end
    r.name:SetText(color .. (name or ("Loading item " .. it.id .. "...")) .. "|r" .. (it.q > it.n and (MUTED .. "  avg " .. string.format("%.1f", it.q / it.n) .. "|r") or ""))
    local pct = total > 0 and math.floor(it.n / total * 100 + 0.5) or 0
    r.pct:SetText(pct .. "%  " .. MUTED .. "(" .. it.n .. "/" .. total .. ")|r")
    r.itemID = it.id
    r:Show()
  end

  local drops = SortedItems(e.loot)
  head("DROPS   " .. "from " .. (e.looted or 0) .. " looted")
  if #drops == 0 then
    i = i + 1
    local r = MatRow(i)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * 21)
    r.head:Hide(); r.icon:Hide(); r.pct:SetText(""); r.itemID = nil
    r.name:SetText(MUTED .. "No drops recorded yet.|r")
    r:Show()
  end
  for _, it in ipairs(drops) do item(it, e.looted or 0) end
  local gathers = SortedItems(e.gather)
  if #gathers > 0 and i < MAT_ROWS - 1 then
    head("GATHERED   skinning, mining, herbs")
    for _, it in ipairs(gathers) do item(it, e.gathered or 0) end
  end
  for j = i + 1, #matRows do matRows[j]:Hide() end
end

local function FillTaming(e)
  local fam, famName = ns.GetFamily(e.family)
  if e.type == "Beast" and fam then
    SetIcon(tmIcon, fam.icon)
    tmIcon:Show()
    tmFamily:SetText(famName)
    tmRole:SetText(hex(C.star) .. "TAMEABLE|r   " .. fam.role .. " pet")
    local lines = {
      TAN .. "Special ability|r",
      (LEATHER and TEXT or "|cffffffff") .. fam.special .. "|r  " .. MUTED .. fam.desc .. "|r",
      " ",
      TAN .. "Also learns|r",
      table.concat(fam.abilities, ", "),
      " ",
      TAN .. "Diet|r",
      table.concat(fam.diet, ", "),
      " ",
      TAN .. "Taming level|r",
      e.maxLvl and ("Tame at your level " .. e.maxLvl .. " or higher (best specimen seen: Lv " .. e.maxLvl .. ").") or "Unknown",
      " ",
      MUTED .. fam.note .. "|r",
    }
    tmBody:SetText(table.concat(lines, "\n"))
  else
    tmIcon:Hide()
    tmFamily:SetText("Not tameable")
    tmRole:SetText("")
    local why = e.type == "Beast" and "This beast belongs to no family a hunter can bond with."
      or ("Only beasts can be tamed. This is " .. (e.type and ("a " .. e.type:lower()) or "an unknown creature") .. ".")
    tmBody:SetText(MUTED .. why .. "|r")
  end
end

local function FillNotes(e)
  local lore = ns.GetLore(e.name, e.type, e.family)
  fnBody:SetText(lore or (MUTED .. "No scholar has written about this creature. Perhaps you will be the first.|r"))
  local zones = {}
  for z in pairs(e.zones or {}) do zones[#zones + 1] = z end
  table.sort(zones)
  local lines = {
    TAN .. "Slain|r  " .. (e.kills or 0),
    TAN .. "First slain|r  " .. (e.firstKill and date("%d %b %Y", e.firstKill) or "-") .. (e.firstZone and (" in " .. e.firstZone) or ""),
    TAN .. "Largest specimen|r  " .. (e.maxLvl and ("Lv " .. e.maxLvl) or "-") .. (e.minLvl and e.minLvl ~= e.maxLvl and ("   smallest Lv " .. e.minLvl) or ""),
    TAN .. "Habitats|r  " .. (#zones > 0 and table.concat(zones, ", ") or "-"),
  }
  recBody:SetText(table.concat(lines, "\n"))
end

UpdateDetail = function()
  local e = (not unknownTarget) and selectedKey and ns.db.entries[selectedKey] or nil
  right:SetShown(true)
  unkQ:SetShown(unknownTarget ~= nil)
  unkMsg:SetShown(unknownTarget ~= nil)
  if unknownTarget then
    unkMsg:SetText(unknownTarget .. "\nThis isn't in your journal.")
  end
  noSel:SetShown(not e and not unknownTarget)
  for _, region in ipairs({ dName, dInfo, rlLabel, rlNum, rlName, rlNext, bandLine, modelBox, phys, tabArea }) do
    region:SetShown(e ~= nil)
  end
  for _, d in ipairs(rlPips) do d:SetShown(e ~= nil) end
  if not e then stamp:Hide() modelRing:Hide() return end

  local lvl = ns.Level(e)
  local mastered = lvl >= ns.MAX_LEVEL
  dName:SetText(e.name)
  local bits = { e.type or "Unknown" }
  if e.family then bits[#bits + 1] = e.family end
  if CLASS_LABEL[e.class or ""] then bits[#bits + 1] = CLASS_LABEL[e.class] end
  dInfo:SetText(table.concat(bits, "  |  "))
  ShowStamp(e)
  local st = StyleOf(e)
  if st then
    local c = StyleColor(st)
    dName:SetTextColor(c[1], c[2], c[3])
    modelRing:SetColorTexture(st.ring[1], st.ring[2], st.ring[3], 1)
    modelRing:Show()
  else
    dName:SetTextColor(C.text[1], C.text[2], C.text[3])
    modelRing:Hide()
  end

  rlNum:SetText(tostring(lvl))
  rlName:SetText(mastered and (hex(C.star) .. ns.LEVEL_NAMES[lvl] .. "|r") or ns.LEVEL_NAMES[lvl])
  for p = 1, 5 do PipColor(rlPips[p], p <= lvl, mastered) end
  local need = ns.KillsToNext(e)
  if need then
    rlNext:SetText(string.format("%d more %s to unlock %s", need, need == 1 and "kill" or "kills", ns.UNLOCKS[lvl + 1]))
  else
    rlNext:SetText(hex(C.star) .. "Research complete|r")
  end

  -- model
  SetIcon(modelIcon, EntryIcon(e))
  model:ClearModel()
  if e.id then pcall(model.SetCreature, model, e.id) end

  -- physiology
  physVals["Level"]:SetText(LevelText(e))
  do
    local st = StyleOf(e)
    local label = st and st.label or CLASS_LABEL[e.class or ""] or "Normal"
    physVals["Class"]:SetText(st and (hex(StyleColor(st)) .. label .. "|r") or label)
  end
  if lvl >= 2 then
    physVals["Health"]:SetText(e.hp and (Num(e.hp) .. (e.hpLvl and (MUTED .. "  at Lv " .. e.hpLvl .. "|r") or "")) or (MUTED .. "hidden|r"))
  else
    physVals["Health"]:SetText(MUTED .. "???|r")
  end
  physVals["Slain"]:SetText(tostring(e.kills or 0))
  physVals["First slain"]:SetText(e.firstKill and date("%d %b %Y", e.firstKill) or "-")
  physVals["Habitat"]:SetText(FirstZone(e) or "-")

  -- tabs
  for i, tab in ipairs(TABS) do
    local b = tabButtons[i]
    local locked = lvl < tab.need
    b.text:SetText(tab.label)
    if LEATHER then
      -- leather index tabs; the open one is paper and joins the page
      b.paper:SetShown(i == tabIndex)
      b.leather:SetShown(i ~= tabIndex)
      if i == tabIndex then
        b.text:SetTextColor(C.tan[1], C.tan[2], C.tan[3])
        b:SetHeight(28)
      else
        if locked then b.text:SetTextColor(0.60, 0.48, 0.34)
        else b.text:SetTextColor(0.90, 0.80, 0.58) end
        b:SetHeight(24)
      end
    elseif i == tabIndex then
      b.bg:SetColorTexture(C.tan[1], C.tan[2], C.tan[3], 1)
      b.text:SetTextColor(0.1, 0.09, 0.07)
    else
      b.bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
      if locked then b.text:SetTextColor(0.38, 0.37, 0.34)
      else b.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
    end
    tabPages[i]:Hide()
  end

  local tab = TABS[tabIndex]
  if lvl < tab.need then
    lockPage:Show()
    local need2 = ns.THRESHOLDS[ns.Tier(e)][tab.need - 1] - (e.kills or 0)
    lockMsg:SetText(string.format("Reach research level %d to unlock.\n%s%d more %s needed.|r",
      tab.need, MUTED, need2, need2 == 1 and "kill" or "kills"))
  else
    lockPage:Hide()
    tabPages[tabIndex]:Show()
    if tabIndex == 1 then FillOverview(e)
    elseif tabIndex == 2 then FillMaterials(e)
    elseif tabIndex == 3 then FillTaming(e)
    elseif tabIndex == 4 then FillNotes(e)
    elseif tabIndex == 5 then ns.FillMyNotes(e)
    else ns.FillGrounds(e) end
  end
end

------------------------------------------------------------------------
-- Public
------------------------------------------------------------------------
-- item names arrive asynchronously; refresh the page once they do
local itemWatch = CreateFrame("Frame")
itemWatch:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemWatch:SetScript("OnEvent", function()
  if ns.waitingItems and f:IsShown() then
    ns.waitingItems = false
    ns.Refresh()
  end
end)

local pending = false
function ns.Refresh()
  if not f:IsShown() or pending then return end
  pending = true
  C_Timer.After(0.25, function()
    pending = false
    if f:IsShown() then UpdateList(); UpdateDetail() end
  end)
end

function ns.Toggle()
  if f:IsShown() then f:Hide() return end
  -- open on whatever you're targeting
  unknownTarget = nil
  if UnitExists("target") then
    local info = ns.ReadUnit("target")
    local e = info and ns.GetEntry(info, false)
    if e then
      selectedKey = e.key
    else
      local name = ns.S(UnitName("target"))
      unknownTarget = type(name) == "string" and name or "Unknown"
    end
  end
  f:Show()
  UpdateList()
  if ns.ScrollToSelected then ns.ScrollToSelected() end
  UpdateDetail()
end

function ns.Select(key)
  unknownTarget = nil
  selectedKey = key
  if f:IsShown() then UpdateList(); UpdateDetail() end
end

------------------------------------------------------------------------
-- Research toast
------------------------------------------------------------------------
local toast = CreateFrame("Button", nil, UIParent)
toast:SetSize(340, 64)
toast:SetPoint("TOP", 0, -110)
toast:SetFrameStrata("HIGH")
toast:SetMovable(true)
toast:SetClampedToScreen(true)
toast:RegisterForDrag("LeftButton")
toast:Hide()

-- where the pop-up sits: its top centre, saved in the settings once moved
local function PlaceToast()
  local pos = ns.db and ns.db.settings.toastPos
  toast:ClearAllPoints()
  if pos and pos.x and pos.y then
    toast:SetPoint("TOP", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  else
    toast:SetPoint("TOP", 0, -110)
  end
end
PlaceToast()
ns.PlaceToast = PlaceToast

-- shift-drag to move it
toast:SetScript("OnDragStart", function(self)
  if not IsShiftKeyDown() then return end
  self.dragging = true
  self:StartMoving()
end)
toast:SetScript("OnDragStop", function(self)
  if not self.dragging then return end
  self:StopMovingOrSizing()
  self.dragging = false
  self.justMoved = true
  local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
  local cx = self:GetCenter()
  ns.db.settings.toastPos = { x = cx * s, y = self:GetTop() * s }
  PlaceToast()
end)
if LEATHER then
  Book(toast, 6)
else
  Fill(toast, "BACKGROUND", C.bg, 0.95):SetAllPoints()
  Border(toast, C.tan, 0.9)
end
local tIcon = Portrait(toast, 44)
tIcon:SetPoint("LEFT", 10, 0)
local tTop = Text(toast, 10, C.tan, nil, nil, LEATHER and TITLE_FONT or nil)
tTop:SetPoint("TOPLEFT", tIcon, "TOPRIGHT", 10, -2)
local tName = Text(toast, 15, C.text)
tName:SetPoint("TOPLEFT", tTop, "BOTTOMLEFT", 0, -3)
tName:SetWidth(200)
tName:SetWordWrap(false)
local tSub = Text(toast, 10, C.muted)
tSub:SetPoint("TOPLEFT", tName, "BOTTOMLEFT", 0, -3)
-- one-click RP emote offered with the pop-up
local tHint = Text(toast, 10, C.text)
tHint:SetPoint("TOPLEFT", toast, "TOPLEFT", 12, -66)
tHint:SetPoint("RIGHT", toast, "RIGHT", -12, 0)
tHint:SetWordWrap(true)
tHint:SetMaxLines(2)
tHint:Hide()
local toastHold = 4.5
local tPips = {}
for p = 1, 5 do
  local d = Diamond(toast, 8)
  d:SetPoint("TOPRIGHT", toast, "TOPRIGHT", -12 - (5 - p) * 13, -12)
  tPips[p] = d
end
toast:SetScript("OnClick", function(self)
  -- the end of a shift-drag, or a shift-click: not a click on the pop-up
  if self.justMoved or IsShiftKeyDown() then
    self.justMoved = false
    return
  end
  -- with an emote waiting, a click just sends it (no journal popping open mid-hunt)
  if ns.SendPendingEmote and ns.SendPendingEmote() then
    self:Hide()
    return
  end
  if self.key then
    if not f:IsShown() then ns.Toggle() end
    ns.Select(self.key)
  end
  self:Hide()
end)

local toastT = 0
toast:SetScript("OnUpdate", function(self, elapsed)
  toastT = toastT + elapsed
  local a
  if toastT < 0.25 then a = toastT / 0.25
  elseif toastT < toastHold or (toastHold > 5 and self:IsMouseOver()) or self.dragging
    or (IsShiftKeyDown() and self:IsMouseOver()) then
    a = 1
    if toastT >= toastHold then toastT = toastHold end -- start fading only once you let go
  else a = 1 - (toastT - toastHold) / 0.6 end
  if a <= 0 then self:Hide() return end
  self:SetAlpha(a)
end)

local function ShowToast(e, top, sub)
  local pending = ns.PendingEmote and ns.PendingEmote()
  if not ns.db.settings.toasts then
    if pending then ns.Print("research level up! Type |cffffffff/hj emote|r or use your keybind to share it.") end
    return
  end
  if pending then
    local me = UnitName("player") or ""
    tHint:SetText(hex(C.tan) .. "Click to emote:|r " .. me .. " " .. pending)
    tHint:Show()
    toast:SetHeight(96)
    toastHold = 15
  else
    tHint:Hide()
    toast:SetHeight(64)
    toastHold = 4.5
  end
  toast.key = e.key
  PlaceToast()
  SetPortrait(tIcon, e)
  tTop:SetText(top)
  tName:SetText(e.name)
  tSub:SetText(sub)
  local lvl = ns.Level(e)
  for p = 1, 5 do PipColor(tPips[p], p <= lvl, lvl >= ns.MAX_LEVEL) end
  toastT = 0
  toast:SetAlpha(0)
  toast:Show()
  if ns.db.settings.toastSound ~= false and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then pcall(PlaySound, SOUNDKIT.IG_QUEST_LOG_OPEN) end
end

-- a sample pop-up to place it (settings, /hj movetoast)
function ns.TestToast()
  local e
  for _, x in pairs(ns.db.entries) do e = x break end
  if not e then ns.Print("hunt something first, then the test pop-up has a creature to show.") return end
  ShowToast(e, "TEST POP-UP", "Shift-drag to move me")
  toastHold = 15
end

function ns.OnLevelUp(e, lvl)
  if ns.RPLevelUp then pcall(ns.RPLevelUp, e, lvl) end
  if lvl == 2 then
    ShowToast(e, "NEW MONSTER RECORDED", "Physiology and taming notes unlocked")
  else
    ShowToast(e, "RESEARCH LEVEL " .. lvl, ns.UNLOCKS[lvl] .. " unlocked")
  end
end

------------------------------------------------------------------------
-- Minimap button
------------------------------------------------------------------------
local mm = CreateFrame("Button", "HuntersJournalMinimapButton", Minimap)
mm:SetSize(31, 31)
mm:SetFrameStrata("MEDIUM")
mm:SetFrameLevel(8)
mm:RegisterForDrag("LeftButton")
local mmIcon = mm:CreateTexture(nil, "BACKGROUND")
mmIcon:SetSize(20, 20)
mmIcon:SetPoint("CENTER", 0, 0)
SetIcon(mmIcon, "INV_Misc_Book_09")
local mmBorder = mm:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(53, 53)
mmBorder:SetPoint("TOPLEFT")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local function PlaceMinimap()
  local angle = math.rad(ns.db.settings.minimap or 200)
  local r = (Minimap:GetWidth() / 2) + 5
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

mm:SetScript("OnDragStart", function(self)
  self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    ns.db.settings.minimap = math.deg(math.atan2(cy - my, cx - mx))
    PlaceMinimap()
  end)
end)
mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mm:SetScript("OnClick", function() ns.Toggle() end)
mm:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("Hunter's Journal", C.gold[1], C.gold[2], C.gold[3])
  GameTooltip:AddLine("Click to open. Drag to move.", 1, 1, 1)
  GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

function ns.ForceRefresh()
  if f:IsShown() then
    for _, r in ipairs(rows) do if r.icon then r.icon.curId = nil end end
    UpdateList(); UpdateDetail()
  end
end

-- scroll the list so the selected row is visible
local function ScrollToSelected()
  local idx
  for i, e in ipairs(listData) do
    if e.key == selectedKey then idx = i break end
  end
  if not idx and (filterIndex ~= 1 or search:GetText() ~= "") then
    filterIndex = 1
    search:SetText("")
    UpdateList()
    for i, e in ipairs(listData) do
      if e.key == selectedKey then idx = i break end
    end
  end
  if idx and (idx <= scroll or idx > scroll + ROWS) then
    scroll = math.max(0, math.min(#listData - ROWS, idx - math.floor(ROWS / 2)))
    UpdateList()
  end
end

ns.ScrollToSelected = ScrollToSelected

-- follow your target while the journal is open
local targetWatch = CreateFrame("Frame")
targetWatch:RegisterEvent("PLAYER_TARGET_CHANGED")
targetWatch:SetScript("OnEvent", function()
  if not f:IsShown() or ns.db.settings.followTarget == false then return end
  C_Timer.After(0.05, function()
    if not UnitExists("target") then return end
    local info = ns.ReadUnit("target")
    local e = info and ns.GetEntry(info, false)
    if e then
      unknownTarget = nil
      selectedKey = e.key
      UpdateList()
      ScrollToSelected()
    else
      local name = ns.S(UnitName("target"))
      unknownTarget = type(name) == "string" and name or "Unknown"
      UpdateList()
    end
    UpdateDetail()
  end)
end)

-- open the journal on a creature, optionally on a given tab (number)
function ns.OpenEntry(key, tab)
  unknownTarget = nil
  selectedKey = key
  if tab then tabIndex = tab end
  if not f:IsShown() then f:Show() end
  UpdateList()
  UpdateDetail()
end

function ns.UpdateMinimap()
  if ns.db.settings.hideMinimap then mm:Hide() else mm:Show(); PlaceMinimap() end
end

ns.UI = { C = C, Fill = Fill, Border = Border, Text = Text, SetIcon = SetIcon, hex = hex,
  LEATHER = LEATHER, Tex = Tex, Shade = Shade, Stitch = Stitch, Book = Book, Paper = Paper, TITLE_FONT = TITLE_FONT,
  SectionHeader = SectionHeader, page = tabPages[5], groundsPage = tabPages[6], PAGE_W = PAGE_W, FONT = FONT,
  Portrait = Portrait, SetPortrait = SetPortrait, EntryIcon = EntryIcon }

function ns.OnLoad()
  ns.UpdateMinimap()
  local me = UnitName("player")
  if type(me) == "string" then hSub:SetText("Field guide of " .. me) end
  if ns.OnLoadPlates then ns.OnLoadPlates() end
end
end)
