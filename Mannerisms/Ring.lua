local ADDON, ns = ...

------------------------------------------------------------------------
-- The ring. Hold the key: it opens around the cursor. Move toward a
-- slice and let go to use it. A quick tap leaves it open; then click a
-- slice. Right-click goes back a ring, Escape closes.
------------------------------------------------------------------------
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 0.85, 0.69, 0.40 }
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local WHITE = "Interface\\Buttons\\WHITE8x8"

local ring = CreateFrame("Frame", "MannerismsRing", UIParent)
ring:SetSize(1, 1)
ring:SetFrameStrata("FULLSCREEN_DIALOG")
ring:Hide()
tinsert(UISpecialFrames, "MannerismsRing")

-- clicks while the ring stays open
local catcher = CreateFrame("Button", nil, ring)
catcher:SetAllPoints(UIParent)
catcher:SetFrameStrata("FULLSCREEN_DIALOG")
catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
catcher:Hide()

local function Round(parent, layer, size, r, g, b, a, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetSize(size, size)
  t:SetTexture(WHITE)
  t:SetVertexColor(r, g, b, a)
  local m = parent:CreateMaskTexture()
  m:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  m:SetAllPoints(t)
  t:AddMaskTexture(m)
  return t
end

local function Text(parent, size, color, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size, flags or "")
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 1)
  local c = color or { 0.92, 0.88, 0.80 }
  fs:SetTextColor(c[1], c[2], c[3])
  return fs
end

-- centre: a dark leather disc with a gold rim
local hub = CreateFrame("Frame", nil, ring)
hub:SetSize(150, 150)
hub:SetPoint("CENTER")
local hubRim = Round(hub, "BACKGROUND", 150, GOLD[1], GOLD[2], GOLD[3], 0.85)
hubRim:SetPoint("CENTER")
local hubBg = Round(hub, "BORDER", 144, 0.09, 0.055, 0.03, 0.96)
hubBg:SetPoint("CENTER")
local pointer = hub:CreateTexture(nil, "ARTWORK")
pointer:SetSize(22, 22)
pointer:SetTexture("Interface\\Minimap\\MinimapArrow")
pointer:SetVertexColor(1, 0.85, 0.5)
pointer:Hide()

local ringName = Text(hub, 10, { 0.72, 0.62, 0.48 })
ringName:SetPoint("TOP", 0, -26)
local label = Text(hub, 15, GOLD)
label:SetPoint("TOP", ringName, "BOTTOM", 0, -6)
label:SetWidth(132)
local preview = Text(hub, 10, { 1, 0.62, 0.35 })
preview:SetPoint("TOP", label, "BOTTOM", 0, -6)
preview:SetWidth(128)
preview:SetJustifyV("TOP")
preview:SetWordWrap(true)
preview:SetMaxLines(4)
local hint = Text(hub, 9, { 0.6, 0.54, 0.45 })
hint:SetPoint("BOTTOM", 0, 20)

-- slices
local slots = {}
local function Slot(i)
  if slots[i] then return slots[i] end
  local s = CreateFrame("Frame", nil, ring)
  s:SetSize(52, 52)
  s.rim = Round(s, "BACKGROUND", 52, GOLD[1], GOLD[2], GOLD[3], 0.75)
  s.rim:SetPoint("CENTER")
  s.bg = Round(s, "BORDER", 48, 0.06, 0.035, 0.02, 1)
  s.bg:SetPoint("CENTER")
  s.icon = s:CreateTexture(nil, "ARTWORK")
  s.icon:SetSize(44, 44)
  s.icon:SetPoint("CENTER")
  local m = s:CreateMaskTexture()
  m:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  m:SetAllPoints(s.icon)
  s.icon:AddMaskTexture(m)
  s.glow = Round(s, "OVERLAY", 64, 1, 0.8, 0.4, 0.45)
  s.glow:SetPoint("CENTER")
  s.glow:SetBlendMode("ADD")
  s.glow:Hide()
  s.sub = s:CreateTexture(nil, "OVERLAY")     -- marks a slice that opens a ring
  s.sub:SetSize(14, 14)
  s.sub:SetPoint("BOTTOMRIGHT", 2, -2)
  s.sub:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
  s.name = Text(s, 11, { 0.95, 0.90, 0.80 }, "OUTLINE")
  s.name:SetPoint("TOP", s, "BOTTOM", 0, -2)
  slots[i] = s
  return s
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------
local cur          -- ring id shown
local stack = {}   -- rings we came from
local sticky = false
local opened = 0   -- GetTime() when the key went down
local hover, pending
local angles = {}
local deadzone = 34

local function Slices()
  local r = cur and ns.db.rings[cur]
  return r and r.slices or {}
end

local function Describe(sl)
  if not sl then return "" end
  if sl.kind == "ring" then
    local r = ns.db.rings[sl.ring or ""]
    return r and ("Opens " .. (r.name or "a ring")) or "(ring is missing)"
  elseif sl.kind == "game" then
    return "/" .. (sl.emote or ""):lower() .. "  (with animation)"
  end
  if not pending then return "(nothing fits; some lines need a target)" end
  if sl.kind == "say" then return "says: " .. pending end
  local me = ns.Me()
  return me.first .. " " .. pending
end

local function SetHover(i)
  if i == hover then return end
  if hover and slots[hover] then slots[hover].glow:Hide() end
  hover = i
  local sl = i and Slices()[i]
  if sl then
    slots[i].glow:Show()
    pending = ns.Pick(sl)
    label:SetText(sl.label or "")
    preview:SetText(ns.db.settings.preview and Describe(sl) or "")
    pointer:Show()
    local a = angles[i]
    pointer:ClearAllPoints()
    pointer:SetPoint("CENTER", hub, "CENTER", math.cos(a) * 62, math.sin(a) * 62)
    pointer:SetRotation(a - math.pi / 2)
  else
    pending = nil
    label:SetText("")
    preview:SetText("")
    pointer:Hide()
  end
end

local function Layout()
  local sl = Slices()
  local n = #sl
  local radius = math.max(118, 20 + n * 16)
  for i, s in ipairs(slots) do s:Hide() s.glow:Hide() end
  hover = nil
  for i = 1, n do
    local s = Slot(i)
    local a = math.pi / 2 - (i - 1) * 2 * math.pi / n
    angles[i] = a
    s:ClearAllPoints()
    s:SetPoint("CENTER", ring, "CENTER", math.cos(a) * radius, math.sin(a) * radius)
    if s.icon:SetTexture(sl[i].icon or "Interface\\Icons\\INV_Misc_QuestionMark") == false then
      s.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    s.name:SetText(sl[i].label or "")
    s.sub:SetShown(sl[i].kind == "ring")
    s:Show()
  end
  local r = ns.db.rings[cur]
  ringName:SetText((r and r.name or ""):upper())
  label:SetText(n == 0 and "Empty ring" or "")
  preview:SetText(n == 0 and "Add slices in /mm" or "")
  pointer:Hide()
  hint:SetText(sticky and (#stack > 0 and "right-click: back" or "click a slice") or "")
end

local function Close()
  ring:Hide()
end

ring:SetScript("OnHide", function()
  catcher:Hide()
  cur, sticky, hover, pending = nil, false, nil, nil
  wipe(stack)
end)

local function MakeSticky()
  sticky = true
  catcher:Show()
  hint:SetText(#stack > 0 and "right-click: back" or "click a slice")
end

local hoverSince = 0
local function Show(id, x, y)
  cur = id
  ring:SetScale(ns.db.settings.scale or 1)
  if x then
    ring:ClearAllPoints()
    local s = ring:GetEffectiveScale()
    ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
  end
  Layout()
  ring:Show()
end

local function CursorAt()
  return GetCursorPosition()
end

-- open a ring at the cursor; sticky = stay open for clicks
function ns.Open(id, stay)
  if not (id and ns.db.rings[id]) then ns.Print("that ring doesn't exist any more.") return end
  wipe(stack)
  sticky = false
  Show(id, CursorAt())
  if stay then MakeSticky() end
end

-- open a slice's ring around the cursor; keeps hold mode if we're in it
local function Enter(sl)
  if not ns.db.rings[sl.ring or ""] then ns.Print("that ring doesn't exist any more.") return end
  stack[#stack + 1] = cur
  local keep = sticky
  Show(sl.ring, GetCursorPosition())
  if keep then MakeSticky() else hint:SetText("") end
end

local function Activate(i)
  local sl = i and Slices()[i]
  if not sl then return false end
  if sl.kind == "ring" then
    local wasHold = not sticky
    Enter(sl)
    if wasHold then MakeSticky() end  -- let go on a ring: it stays open to click
    return true
  end
  local text = pending
  Close()
  ns.Send(sl, text)
  return true
end

-- pick the slice the cursor points at
ring:SetScript("OnUpdate", function(self)
  local n = #Slices()
  if n == 0 then SetHover(nil) return end
  local cx, cy = self:GetCenter()
  if not cx then return end
  local x, y = GetCursorPosition()
  local s = self:GetEffectiveScale()
  local dx, dy = x / s - cx, y / s - cy
  if dx * dx + dy * dy < deadzone * deadzone then SetHover(nil) hoverSince = GetTime() return end
  local a = math.atan2(dy, dx)
  local best, bestD
  for i = 1, n do
    local d = math.abs(((a - angles[i]) + math.pi) % (2 * math.pi) - math.pi)
    if not bestD or d < bestD then best, bestD = i, d end
  end
  if best ~= hover then hoverSince = GetTime() end
  SetHover(best)
  -- rest on a ring slice for a moment: it opens, OPie style
  local sl = Slices()[best]
  if sl and sl.kind == "ring" and GetTime() - hoverSince > 0.35 then
    hoverSince = GetTime()
    Enter(sl)
  end
end)

catcher:SetScript("OnClick", function(_, button)
  if button == "RightButton" then
    if #stack > 0 then
      local back = table.remove(stack)
      Show(back)
      MakeSticky()
    else
      Close()
    end
    return
  end
  if hover then ns.Safe(Activate, hover) else Close() end
end)

------------------------------------------------------------------------
-- Keybinding: hold, flick, release
------------------------------------------------------------------------
local skipUp = false
function ns.KeyDown(id)
  if ring:IsShown() then
    if not sticky then return end  -- the key repeating while held
    Close()          -- pressing again closes a ring left open
    skipUp = true
    return
  end
  skipUp = false
  opened = GetTime()
  ns.Open(id, false)
end

function ns.KeyUp(id)
  if skipUp then skipUp = false return end
  if not ring:IsShown() or sticky then return end
  if ns.debug then ns.Print(("key up: hover=%s sticky=%s held=%.2fs"):format(tostring(hover), tostring(sticky), GetTime() - opened)) end
  if hover then
    ns.Safe(Activate, hover)
  elseif GetTime() - opened < (ns.db.settings.quickTap or 0.25) then
    MakeSticky()     -- a tap: leave it open
  else
    Close()          -- let go in the middle: never mind
  end
end

function ns.OnLoad()
  if ns.EditorInit then ns.EditorInit() end
end
