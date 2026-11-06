local ADDON, ns = ...

------------------------------------------------------------------------
-- /mm: edit your rings. Rings on the left, the chosen ring's slices in
-- the middle, the chosen slice on the right.
------------------------------------------------------------------------
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 0.85, 0.69, 0.40 }
local DIM = { 0.65, 0.58, 0.48 }
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"

local selRing, selSlice

local win = CreateFrame("Frame", "MannerismsEditor", UIParent, "BackdropTemplate")
win:SetSize(820, 580)
win:SetPoint("CENTER")
win:SetFrameStrata("DIALOG")
win:EnableMouse(true)
win:SetMovable(true)
win:SetClampedToScreen(true)
win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving)
win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
win:SetBackdropColor(0.08, 0.05, 0.03, 0.97)
win:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
win:Hide()
tinsert(UISpecialFrames, "MannerismsEditor")

local function Text(parent, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size, "")
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 1)
  local c = color or { 0.92, 0.88, 0.80 }
  fs:SetTextColor(c[1], c[2], c[3])
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

local function Box(parent, w, h)
  local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  b:SetSize(w, h)
  b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  b:SetBackdropColor(0, 0, 0, 0.4)
  b:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.3)
  return b
end

local function Button(parent, label, w, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 22)
  b:SetText(label)
  b:SetScript("OnClick", onClick)
  return b
end

local function Edit(parent, w, onChange)
  local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  e:SetSize(w, 22)
  e:SetAutoFocus(false)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  e:SetScript("OnEnterPressed", e.ClearFocus)
  e:SetScript("OnTextChanged", function(self, user) if user and onChange then onChange(self:GetText()) end end)
  return e
end

local function IconButton(parent, size, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  b.tex = b:CreateTexture(nil, "ARTWORK")
  b.tex:SetAllPoints()
  b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetScript("OnClick", onClick)
  b.Set = function(self, path)
    if not path or self.tex:SetTexture(path) == false then self.tex:SetTexture(QMARK) end
  end
  return b
end

-- header
local title = Text(win, 18, GOLD)
title:SetPoint("TOPLEFT", 18, -14)
title:SetText("Mannerisms")
local sub = Text(win, 11, DIM)
sub:SetPoint("LEFT", title, "RIGHT", 12, -2)
sub:SetText("Hold a ring's key, move toward a slice, let go. A quick tap keeps the ring open for clicking.")
local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -4, -4)

------------------------------------------------------------------------
-- Icon picker (shared)
------------------------------------------------------------------------
local picker = CreateFrame("Frame", nil, win, "BackdropTemplate")
picker:SetSize(8 * 34 + 20, 4 * 34 + 64)
picker:SetFrameStrata("FULLSCREEN_DIALOG")
picker:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
picker:SetBackdropColor(0.06, 0.04, 0.02, 0.98)
picker:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
picker:EnableMouse(true)
picker:Hide()
local pickCb
for i, name in ipairs(ns.ICONS) do
  local b = IconButton(picker, 30, function()
    if pickCb then pickCb("Interface\\Icons\\" .. name) end
    picker:Hide()
  end)
  b:SetPoint("TOPLEFT", 10 + ((i - 1) % 8) * 34, -10 - math.floor((i - 1) / 8) * 34)
  b:Set("Interface\\Icons\\" .. name)
end
local pickLabel = Text(picker, 10, DIM)
pickLabel:SetPoint("BOTTOMLEFT", 12, 34)
pickLabel:SetText("Or any icon name (e.g. INV_Misc_Food_15):")
local pickEdit = Edit(picker, 8 * 34 - 60, nil)
pickEdit:SetPoint("BOTTOMLEFT", 16, 8)
local pickOk = Button(picker, "Use", 50, function()
  local t = pickEdit:GetText():gsub("^%s+", ""):gsub("%s+$", "")
  if t ~= "" then
    if not t:find("\\", 1, true) then t = "Interface\\Icons\\" .. t end
    if pickCb then pickCb(t) end
  end
  picker:Hide()
end)
pickOk:SetPoint("LEFT", pickEdit, "RIGHT", 6, 0)
local function PickIcon(anchor, cb)
  pickCb = cb
  pickEdit:SetText("")
  picker:ClearAllPoints()
  picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
  picker:Show()
end

------------------------------------------------------------------------
-- Lists
------------------------------------------------------------------------
local function List(parent, w, rows, onPick)
  local box = Box(parent, w, rows * 26 + 8)
  box.rows = {}
  for i = 1, rows do
    local r = CreateFrame("Button", nil, box)
    r:SetSize(w - 8, 24)
    r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 26)
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetAllPoints()
    r.sel:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.18)
    r:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    r:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.06)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.icon:SetPoint("LEFT", 2, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.text = Text(r, 12)
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", -4, 0)
    r.text:SetWordWrap(false)
    r:SetScript("OnClick", function(self) onPick(self.value) end)
    box.rows[i] = r
  end
  box.Fill = function(self, items, selected)
    for i, r in ipairs(self.rows) do
      local it = items[i]
      if it then
        r.value = it.value
        if r.icon:SetTexture(it.icon or QMARK) == false then r.icon:SetTexture(QMARK) end
        r.text:SetText(it.text)
        r.sel:SetShown(it.value == selected)
        r:Show()
      else
        r:Hide()
      end
    end
  end
  return box
end

local Refresh -- forward

local function RingIds()
  local ids = {}
  for id in pairs(ns.db.rings) do ids[#ids + 1] = id end
  table.sort(ids, function(a, b)
    if a == ns.db.root then return true elseif b == ns.db.root then return false end
    return (ns.db.rings[a].name or a):lower() < (ns.db.rings[b].name or b):lower()
  end)
  return ids
end

-- column titles
local function ColTitle(text, x)
  local t = Text(win, 13, GOLD)
  t:SetPoint("TOPLEFT", x, -48)
  t:SetText(text)
  return t
end
ColTitle("Rings", 18)
ColTitle("Slices", 210)
ColTitle("Slice", 430)

local ringList = List(win, 180, 13, function(v) selRing, selSlice = v, 1 Refresh() end)
ringList:SetPoint("TOPLEFT", 18, -68)

local newRing = Button(win, "New ring", 88, function()
  local n = 1
  while ns.db.rings["ring" .. n] do n = n + 1 end
  local id = "ring" .. n
  ns.db.rings[id] = { name = "New ring", icon = "Interface\\Icons\\INV_Misc_Book_09", slices = {} }
  selRing, selSlice = id, nil
  Refresh()
end)
newRing:SetPoint("TOPLEFT", ringList, "BOTTOMLEFT", 0, -6)
local delRing
delRing = Button(win, "Delete", 88, function()
  if not selRing then return end
  if not delRing.armed then
    delRing.armed = true
    delRing:SetText("Sure?")
    C_Timer.After(3, function() delRing.armed = false delRing:SetText("Delete") end)
    return
  end
  delRing.armed = false
  delRing:SetText("Delete")
  ns.db.rings[selRing] = nil
  if ns.db.root == selRing then ns.db.root = RingIds()[1] end
  selRing, selSlice = nil, nil
  Refresh()
end)
delRing:SetPoint("LEFT", newRing, "RIGHT", 4, 0)

local sliceList = List(win, 200, 11, function(v) selSlice = v Refresh() end)
sliceList:SetPoint("TOPLEFT", 210, -128)

local function Slices() return selRing and ns.db.rings[selRing] and ns.db.rings[selRing].slices end

local addSlice = Button(win, "Add", 48, function()
  local sl = Slices()
  if not sl then return end
  sl[#sl + 1] = { label = "New slice", icon = QMARK, kind = "emote", lines = { "nods." } }
  selSlice = #sl
  Refresh()
end)
addSlice:SetPoint("TOPLEFT", sliceList, "BOTTOMLEFT", 0, -6)
local function Move(d)
  local sl = Slices()
  if not (sl and selSlice and sl[selSlice + d]) then return end
  sl[selSlice], sl[selSlice + d] = sl[selSlice + d], sl[selSlice]
  selSlice = selSlice + d
  Refresh()
end
local up = Button(win, "Up", 44, function() Move(-1) end)
up:SetPoint("LEFT", addSlice, "RIGHT", 2, 0)
local down = Button(win, "Down", 52, function() Move(1) end)
down:SetPoint("LEFT", up, "RIGHT", 2, 0)
local delSlice = Button(win, "Delete", 52, function()
  local sl = Slices()
  if not (sl and selSlice and sl[selSlice]) then return end
  table.remove(sl, selSlice)
  selSlice = math.min(selSlice, #sl)
  if selSlice == 0 then selSlice = nil end
  Refresh()
end)
delSlice:SetPoint("LEFT", down, "RIGHT", 2, 0)

------------------------------------------------------------------------
-- The chosen ring: name, icon, key (above the slice list)
------------------------------------------------------------------------
local ringIcon = IconButton(win, 30, function(self)
  if not selRing then return end
  PickIcon(self, function(p) ns.db.rings[selRing].icon = p Refresh() end)
end)
ringIcon:SetPoint("TOPLEFT", 210, -70)
local ringNameEdit = Edit(win, 162, function(t) if selRing then ns.db.rings[selRing].name = t ringList:Fill((function()
  local items = {}
  for _, id in ipairs(RingIds()) do
    local r = ns.db.rings[id]
    items[#items + 1] = { value = id, icon = r.icon, text = (id == ns.db.root and "|cffd8b066*|r " or "") .. (r.name or id) }
  end
  return items end)(), selRing) end end)
ringNameEdit:SetPoint("LEFT", ringIcon, "RIGHT", 10, 0)

local keyBtn = Button(win, "Key: none", 120, nil)
keyBtn:SetPoint("TOPLEFT", 210, -102)
local mainCb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
mainCb:SetSize(22, 22)
mainCb:SetPoint("LEFT", keyBtn, "RIGHT", 4, 0)
local mainLbl = Text(mainCb, 11)
mainLbl:SetPoint("LEFT", mainCb, "RIGHT", 2, 1)
mainLbl:SetText("Main")
mainCb:SetScript("OnClick", function(self)
  if selRing and self:GetChecked() then ns.db.root = selRing end
  Refresh()
end)
mainCb:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:AddLine("Main ring")
  GameTooltip:AddLine("The ring /mm open shows.", 1, 1, 1, true)
  GameTooltip:Show()
end)
mainCb:SetScript("OnLeave", GameTooltip_Hide)

-- key slots 1..6 map to the keybinds in Options > Keybindings > Mannerisms
local function KeyText(slot)
  if not slot then return "Key: none" end
  local k = GetBindingKey("MANNERISMS_RING" .. slot)
  return "Key " .. slot .. ": " .. (k and GetBindingText(k) or "not set")
end

-- press-a-key capture
local capture = CreateFrame("Frame", nil, win)
capture:SetAllPoints(keyBtn)
capture:EnableKeyboard(false)
capture:Hide()
local capSlot
capture:SetScript("OnKeyDown", function(self, key)
  if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
  self:Hide()
  self:EnableKeyboard(false)
  if key == "ESCAPE" then Refresh() return end
  local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
  local action = "MANNERISMS_RING" .. capSlot
  local old = GetBindingKey(action)
  while old do SetBinding(old) old = GetBindingKey(action) end
  SetBinding(combo, action)
  SaveBindings(GetCurrentBindingSet())
  ns.Print("ring key " .. capSlot .. " is now " .. GetBindingText(combo) .. ".")
  Refresh()
end)

keyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
keyBtn:SetScript("OnClick", function(self, button)
  if not selRing then return end
  local r = ns.db.rings[selRing]
  if button == "RightButton" then
    -- cycle which key slot this ring uses
    local nxt = ((r.key or 0) % 6) + 1
    if r.key == 6 then nxt = nil end
    if nxt then
      for _, other in pairs(ns.db.rings) do if other.key == nxt then other.key = nil end end
    end
    r.key = nxt
    Refresh()
    return
  end
  if InCombatLockdown() then ns.Print("can't change keys in combat.") return end
  if not r.key then
    for s = 1, 6 do
      if not ns.RingForKey(s) then r.key = s break end
    end
    if not r.key then ns.Print("all six ring keys are in use. Right-click to pick one.") return end
  end
  capSlot = r.key
  self:SetText("Press a key...")
  capture:Show()
  capture:EnableKeyboard(true)
  if capture.SetPropagateKeyboardInput then capture:SetPropagateKeyboardInput(false) end
end)
keyBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:AddLine("Ring key")
  GameTooltip:AddLine("Left-click, then press the key (with Shift/Ctrl/Alt if you like) that opens this ring.", 1, 1, 1, true)
  GameTooltip:AddLine("Right-click to switch between key slots 1-6, or none for a ring you only reach from another ring.", 1, 1, 1, true)
  GameTooltip:Show()
end)
keyBtn:SetScript("OnLeave", GameTooltip_Hide)

------------------------------------------------------------------------
-- The chosen slice
------------------------------------------------------------------------
local X = 430
local function Cur() local sl = Slices() return sl and selSlice and sl[selSlice] end

local slIcon = IconButton(win, 36, function(self)
  local s = Cur()
  if s then PickIcon(self, function(p) s.icon = p Refresh() end) end
end)
slIcon:SetPoint("TOPLEFT", X, -70)
local slName = Edit(win, 300, function(t)
  local s = Cur()
  if s then s.label = t sliceList:Fill((function()
    local items = {}
    for i, x in ipairs(Slices()) do items[i] = { value = i, icon = x.icon, text = x.label or "?" } end
    return items end)(), selSlice) end
end)
slName:SetPoint("LEFT", slIcon, "RIGHT", 12, 0)

local KINDS = {
  { "emote", "Emote (/me)", "Your name goes in front: \"Raptor nods.\" Orange text everyone nearby sees." },
  { "say", "Say", "Spoken out loud in /say." },
  { "game", "Game emote", "One of the game's own emotes, like /wave or /bow, with its animation." },
  { "ring", "Open ring", "Opens another ring (a sub-menu)." },
}
local kindBtns = {}
for i, k in ipairs(KINDS) do
  local b = CreateFrame("CheckButton", nil, win, "UIRadioButtonTemplate")
  b:SetPoint("TOPLEFT", X + (i - 1) * 96, -114)
  local t = Text(b, 11)
  t:SetPoint("LEFT", b, "RIGHT", 3, 1)
  t:SetText(k[2])
  b:SetScript("OnClick", function()
    local s = Cur()
    if not s then return end
    s.kind = k[1]
    if (s.kind == "emote" or s.kind == "say") and not s.lines then s.lines = {} end
    Refresh()
  end)
  kindBtns[i] = b
end
local kindHelp = Text(win, 11, DIM)
kindHelp:SetPoint("TOPLEFT", X, -138)
kindHelp:SetWidth(370)

-- lines (emote / say)
local linesPanel = CreateFrame("Frame", nil, win)
linesPanel:SetPoint("TOPLEFT", X, -160)
linesPanel:SetSize(372, 300)
local lh = Text(linesPanel, 11, DIM)
lh:SetPoint("TOPLEFT")
lh:SetWidth(372)
lh:SetText("One line per row; one is picked at random. Fill-ins: {target} {first} {last} {full} {title} {race} {class} {he} {him} {his} {himself}. A line with {target} is skipped when you have no target.")
local linesBox = Box(linesPanel, 372, 200)
linesBox:SetPoint("TOPLEFT", 0, -48)
local scroll = CreateFrame("ScrollFrame", nil, linesBox)
scroll:SetPoint("TOPLEFT", 6, -6)
scroll:SetPoint("BOTTOMRIGHT", -6, 6)
local linesEdit = CreateFrame("EditBox", nil, scroll)
linesEdit:SetMultiLine(true)
linesEdit:SetAutoFocus(false)
linesEdit:SetFont(FONT, 12, "")
linesEdit:SetWidth(356)
linesEdit:SetTextColor(0.92, 0.88, 0.80)
scroll:SetScrollChild(linesEdit)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, d)
  local max = math.max(0, linesEdit:GetHeight() - self:GetHeight())
  self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 20)))
end)
linesBox:EnableMouse(true)
linesBox:SetScript("OnMouseDown", function() linesEdit:SetFocus() end)
linesEdit:SetScript("OnEscapePressed", linesEdit.ClearFocus)
linesEdit:SetScript("OnTextChanged", function(self, user)
  if not user then return end
  local s = Cur()
  if not s then return end
  local lines = {}
  for l in (self:GetText() .. "\n"):gmatch("(.-)\n") do
    l = l:gsub("^%s+", ""):gsub("%s+$", "")
    if l ~= "" then lines[#lines + 1] = l end
  end
  s.lines = lines
end)
local tryBtn = Button(linesPanel, "Try it", 80, function()
  local s = Cur()
  if not s then return end
  local line = ns.Pick(s)
  if not line then ns.Print("nothing fits right now (lines with {target} need a target).") return end
  local me = ns.Me()
  ns.Print((s.kind == "say" and (me.first .. " says: ") or (me.first .. " ")) .. line .. "  |cff808080(only you see this)|r")
end)
tryBtn:SetPoint("TOPLEFT", linesBox, "BOTTOMLEFT", 0, -6)

-- game emote
local gamePanel = CreateFrame("Frame", nil, win)
gamePanel:SetPoint("TOPLEFT", X, -160)
gamePanel:SetSize(372, 200)
local gl = Text(gamePanel, 11, DIM)
gl:SetPoint("TOPLEFT")
gl:SetText("Emote command, without the slash:")
local gameEdit = Edit(gamePanel, 140, function(t)
  local s = Cur()
  if s then s.emote = t:gsub("^/", ""):upper() end
end)
gameEdit:SetPoint("TOPLEFT", 6, -18)
local COMMON = { "WAVE", "BOW", "BYE", "CHEER", "APPLAUD", "LAUGH", "NOD", "NO", "SALUTE", "KNEEL", "SIT", "DANCE",
  "THANK", "POINT", "SHY", "CRY", "ROAR", "FLEX", "TALK", "SHRUG", "VICTORY", "WELCOME", "KISS", "SLEEP" }
for i, e in ipairs(COMMON) do
  local b = Button(gamePanel, e:lower(), 86, function()
    local s = Cur()
    if s then s.emote = e Refresh() end
  end)
  b:SetPoint("TOPLEFT", ((i - 1) % 4) * 90, -50 - math.floor((i - 1) / 4) * 24)
end

-- open ring
local ringPanel = CreateFrame("Frame", nil, win)
ringPanel:SetPoint("TOPLEFT", X, -160)
ringPanel:SetSize(372, 200)
local rl = Text(ringPanel, 11, DIM)
rl:SetPoint("TOPLEFT")
rl:SetText("Ring to open (click to switch):")
local ringPick = Button(ringPanel, "", 220, function()
  local s = Cur()
  if not s then return end
  local ids = RingIds()
  local idx = 0
  for i, id in ipairs(ids) do if id == s.ring then idx = i end end
  for _ = 1, #ids do
    idx = idx % #ids + 1
    if ids[idx] ~= selRing then break end
  end
  s.ring = ids[idx]
  local r = ns.db.rings[s.ring]
  if r and (s.label == "New slice" or not s.label or s.label == "") then s.label = r.name s.icon = r.icon end
  Refresh()
end)
ringPick:SetPoint("TOPLEFT", 0, -20)

local noSlice = Text(win, 12, DIM)
noSlice:SetPoint("TOPLEFT", X, -76)
noSlice:SetText("Pick a slice, or press Add.")

------------------------------------------------------------------------
-- Bottom: options and the /me primer
------------------------------------------------------------------------
local primer = Text(win, 11, DIM)
primer:SetPoint("BOTTOMLEFT", 18, 44)
primer:SetWidth(560)
primer:SetText("|cffd8b066/me|r (also /e) describes what your character does, in third person, with your name in front. " ..
  "Typing |cffffffff/me leans on the bar.|r shows |cffff8040Raptor leans on the bar.|r to everyone nearby. " ..
  "Roleplayers use it for actions, expressions and anything that isn't speech.")

local previewCb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
previewCb:SetSize(22, 22)
previewCb:SetPoint("BOTTOMLEFT", 16, 12)
local pt = Text(previewCb, 11)
pt:SetPoint("LEFT", previewCb, "RIGHT", 2, 1)
pt:SetText("Show the line in the middle of the ring before sending")
previewCb:SetScript("OnClick", function(self) ns.db.settings.preview = self:GetChecked() and true or false end)

local scale = CreateFrame("Slider", nil, win, "OptionsSliderTemplate")
scale:SetPoint("BOTTOMLEFT", 400, 18)
scale:SetWidth(150)
scale:SetMinMaxValues(0.6, 1.6)
scale:SetValueStep(0.05)
scale:SetObeyStepOnDrag(true)
local st = Text(scale, 11)
st:SetPoint("BOTTOM", scale, "TOP", 0, 2)
scale:SetScript("OnValueChanged", function(_, v)
  ns.db.settings.scale = v
  st:SetText(("Ring size %d%%"):format(v * 100 + 0.5))
end)
if scale.Low then scale.Low:SetText("") scale.High:SetText("") end

local openNow = Button(win, "Try the main ring", 150, function()
  win:Hide()
  ns.Open(ns.db.root, true)
end)
openNow:SetPoint("BOTTOMRIGHT", -18, 16)

local resetBtn
resetBtn = Button(win, "Reset all rings", 150, function()
  if not resetBtn.armed then
    resetBtn.armed = true
    resetBtn:SetText("Click again to reset")
    C_Timer.After(3, function() resetBtn.armed = false resetBtn:SetText("Reset all rings") end)
    return
  end
  resetBtn.armed = false
  resetBtn:SetText("Reset all rings")
  ns.Reset()
  selRing, selSlice = ns.db.root, nil
  Refresh()
end)
resetBtn:SetPoint("BOTTOMRIGHT", openNow, "TOPRIGHT", 0, 6)

------------------------------------------------------------------------
Refresh = function()
  if not win:IsShown() then return end
  picker:Hide()
  local ids = RingIds()
  if not (selRing and ns.db.rings[selRing]) then selRing = ns.db.root or ids[1] end
  local items = {}
  for _, id in ipairs(ids) do
    local r = ns.db.rings[id]
    items[#items + 1] = { value = id, icon = r.icon, text = (id == ns.db.root and "|cffd8b066*|r " or "") .. (r.name or id) }
  end
  ringList:Fill(items, selRing)

  local r = selRing and ns.db.rings[selRing]
  ringIcon:Set(r and r.icon)
  ringNameEdit:SetText(r and r.name or "")
  keyBtn:SetText(r and KeyText(r.key) or "")
  mainCb:SetChecked(r and ns.db.root == selRing)

  local sl = r and r.slices or {}
  if selSlice and not sl[selSlice] then selSlice = nil end
  local sItems = {}
  for i, x in ipairs(sl) do
    sItems[i] = { value = i, icon = x.icon, text = (x.label or "?") .. (x.kind == "ring" and "  |cff8a7a60>|r" or "") }
  end
  sliceList:Fill(sItems, selSlice)

  local s = Cur()
  local shown = s ~= nil
  for _, w in ipairs({ slIcon, slName, kindHelp }) do w:SetShown(shown) end
  for _, b in ipairs(kindBtns) do b:SetShown(shown) end
  noSlice:SetShown(not shown)
  linesPanel:SetShown(shown and (s.kind == "emote" or s.kind == "say"))
  gamePanel:SetShown(shown and s.kind == "game")
  ringPanel:SetShown(shown and s.kind == "ring")
  if not s then return end
  slIcon:Set(s.icon)
  slName:SetText(s.label or "")
  for i, k in ipairs(KINDS) do
    kindBtns[i]:SetChecked(s.kind == k[1])
    if s.kind == k[1] then kindHelp:SetText(k[3]) end
  end
  if s.kind == "emote" or s.kind == "say" then
    linesEdit:SetText(table.concat(s.lines or {}, "\n"))
    scroll:SetVerticalScroll(0)
  elseif s.kind == "game" then
    gameEdit:SetText((s.emote or ""):lower())
  elseif s.kind == "ring" then
    local tr = s.ring and ns.db.rings[s.ring]
    ringPick:SetText(tr and (tr.name or s.ring) or "(choose a ring)")
  end
end
ns.EditorRefresh = Refresh

win:SetScript("OnShow", function()
  previewCb:SetChecked(ns.db.settings.preview)
  scale:SetValue(ns.db.settings.scale or 1)
  Refresh()
end)

function ns.ToggleEditor()
  if win:IsShown() then win:Hide() else win:Show() end
end

function ns.EditorInit()
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local panel = CreateFrame("Frame")
    local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText("Mannerisms")
    local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetJustifyH("LEFT")
    d:SetText("Radial menus of roleplay emotes and lines.\nType /mm, or use the button below.")
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(200, 26)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -14)
    b:SetText("Edit rings")
    b:SetScript("OnClick", function()
      if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
      win:Show()
    end)
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "Mannerisms")
    Settings.RegisterAddOnCategory(cat)
  end
  -- first run: offer a key for the main ring
  local r = ns.db.rings[ns.db.root]
  if r and r.key and not GetBindingKey("MANNERISMS_RING" .. r.key) and not ns.db.settings.toldKey then
    ns.db.settings.toldKey = true
    C_Timer.After(4, function()
      ns.Print("set a key for your main ring in |cffffffff/mm|r (click \"Key 1\"), then hold it, flick toward a slice and let go.")
    end)
  end
end
