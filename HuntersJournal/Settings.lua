local ADDON, ns = ...
ns.Defer(function()

-- Settings window (/hj settings, the Settings button in the journal, or
-- Options > AddOns > Hunter's Journal)

local UI = ns.UI
local C, Text, Fill, Border = UI.C, UI.Text, UI.Fill, UI.Border
local COL_W = 280
local controls = {}

local function S() return ns.db.settings end

local win = CreateFrame("Frame", "HuntersJournalSettings", UIParent)
win:SetSize(COL_W * 2 + 72, 760)
win:SetPoint("CENTER", 0, 20)
win:SetFrameStrata("DIALOG")
win:SetToplevel(true)
win:EnableMouse(true)
win:SetMovable(true)
win:SetClampedToScreen(true)
win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving)
win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:Hide()
tinsert(UISpecialFrames, "HuntersJournalSettings")
if UI.LEATHER then
  UI.Book(win, 8)
else
  Fill(win, "BACKGROUND", C.bg, 0.98):SetAllPoints()
  Border(win, C.tan, 0.9)
end

local title = Text(win, 16, C.tan, nil, nil, UI.TITLE_FONT)
title:SetPoint("TOPLEFT", 18, -14)
title:SetText("HUNTER'S JOURNAL  SETTINGS")
local sub = Text(win, 10, C.muted)
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
sub:SetText("Changes apply immediately.")

local close = CreateFrame("Button", nil, win)
close:SetSize(24, 24)
close:SetPoint("TOPRIGHT", -8, -8)
local closeTxt = Text(close, 15, C.tan, "CENTER")
closeTxt:SetPoint("CENTER")
closeTxt:SetText("X")
close:SetScript("OnClick", function() win:Hide() end)

------------------------------------------------------------------------
-- Controls
------------------------------------------------------------------------
local cols = {}
for i = 1, 2 do
  local c = CreateFrame("Frame", nil, win)
  c:SetSize(COL_W, 400)
  c:SetPoint("TOPLEFT", 24 + (i - 1) * (COL_W + 24), -56)
  c.y = 0
  cols[i] = c
end

local function Place(col, frame, h)
  frame:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -col.y)
  col.y = col.y + h
end

local function Header(col, label)
  col.y = col.y + (col.y > 0 and 10 or 0)
  local h = UI.SectionHeader(col, label)
  h:SetWidth(COL_W)
  Place(col, h, 28)
end

local function Check(col, label, key, onChange, invert)
  local b = CreateFrame("Button", nil, col)
  b:SetSize(COL_W, 20)
  local box = CreateFrame("Frame", nil, b)
  box:SetSize(14, 14)
  box:SetPoint("LEFT", 0, 0)
  Fill(box, "BACKGROUND", C.inset, 1):SetAllPoints()
  Border(box, C.tanDim, 1)
  local mark = Fill(box, "ARTWORK", C.tan, 1)
  mark:SetPoint("TOPLEFT", 3, -3)
  mark:SetPoint("BOTTOMRIGHT", -3, 3)
  local t = Text(b, 11, C.text)
  t:SetPoint("LEFT", box, "RIGHT", 8, 0)
  t:SetJustifyV("MIDDLE")
  t:SetText(label)
  local function value()
    local v = S()[key] and true or false
    if invert then v = not v end
    return v
  end
  b.Refresh = function() mark:SetShown(value()) end
  b:SetScript("OnClick", function()
    local v = not value()
    if invert then S()[key] = not v else S()[key] = v end
    b.Refresh()
    if onChange then onChange() end
  end)
  Place(col, b, 24)
  controls[#controls + 1] = b
end

local function Choice(col, label, key, options, onChange)
  local fr = CreateFrame("Frame", nil, col)
  fr:SetSize(COL_W, 42)
  local t = Text(fr, 11, C.text)
  t:SetPoint("TOPLEFT")
  t:SetText(label)
  local btns = {}
  local bw = (COL_W - (#options - 1) * 3) / #options
  for i, opt in ipairs(options) do
    local b = CreateFrame("Button", nil, fr)
    b:SetSize(bw, 20)
    b:SetPoint("TOPLEFT", (i - 1) * (bw + 3), -17)
    b.bg = Fill(b, "BACKGROUND", C.panel2, 1)
    b.bg:SetAllPoints()
    b.text = Text(b, 10, C.muted, "CENTER")
    b.text:SetPoint("CENTER")
    b.text:SetText(opt[2])
    b:SetScript("OnClick", function()
      S()[key] = opt[1]
      fr.Refresh()
      if onChange then onChange() end
    end)
    btns[i] = b
  end
  fr.Refresh = function()
    for i, opt in ipairs(options) do
      local on = S()[key] == opt[1]
      local b = btns[i]
      if on then
        b.bg:SetColorTexture(C.tan[1], C.tan[2], C.tan[3], 1)
        if UI.LEATHER then b.text:SetTextColor(0.97, 0.90, 0.78) else b.text:SetTextColor(0.1, 0.09, 0.07) end
      else
        b.bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
        b.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
      end
    end
  end
  Place(col, fr, 44)
  controls[#controls + 1] = fr
end

local function Slider(col, label, key, min, max, step, fmt, onChange)
  local fr = CreateFrame("Frame", nil, col)
  fr:SetSize(COL_W, 38)
  local t = Text(fr, 11, C.text)
  t:SetPoint("TOPLEFT")
  t:SetText(label)
  local v = Text(fr, 11, C.tan, "RIGHT")
  v:SetPoint("TOPRIGHT")
  local s = CreateFrame("Slider", nil, fr)
  s:SetOrientation("HORIZONTAL")
  s:SetSize(COL_W, 14)
  s:SetPoint("TOPLEFT", 0, -18)
  local track = Fill(s, "BACKGROUND", C.panel2, 1)
  track:SetPoint("LEFT")
  track:SetPoint("RIGHT")
  track:SetHeight(4)
  local thumb = s:CreateTexture(nil, "OVERLAY")
  thumb:SetSize(10, 14)
  thumb:SetColorTexture(C.tan[1], C.tan[2], C.tan[3], 1)
  s:SetThumbTexture(thumb)
  s:SetMinMaxValues(min, max)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:EnableMouseWheel(true)
  s:SetScript("OnMouseWheel", function(self, d)
    self:SetValue(math.max(min, math.min(max, self:GetValue() + d * step)))
  end)
  local busy = false
  s:SetScript("OnValueChanged", function(_, val)
    val = math.floor(val / step + 0.5) * step
    v:SetText(fmt(val))
    if busy then return end
    S()[key] = val
    if onChange then onChange() end
  end)
  fr.Refresh = function()
    busy = true
    s:SetValue(S()[key] or min)
    v:SetText(fmt(S()[key] or min))
    busy = false
  end
  Place(col, fr, 42)
  controls[#controls + 1] = fr
end

local function Btn(col, label, onClick)
  local b = CreateFrame("Button", nil, col)
  b:SetSize(COL_W, 24)
  local bg = Fill(b, "BACKGROUND", C.panel2, 1)
  bg:SetAllPoints()
  Border(b, C.tanDim, 0.9)
  b.text = Text(b, 11, C.tan, "CENTER")
  b.text:SetPoint("CENTER")
  b.text:SetText(label)
  b:SetScript("OnClick", onClick)
  Place(col, b, 30)
  return b
end

local function plates() if ns.RefreshPlates then ns.RefreshPlates() end end
local function journal() if ns.ForceRefresh then ns.ForceRefresh() end end
local function map() if ns.RefreshMapPins then ns.RefreshMapPins() end end
local px = function(v) return (v > 0 and "+" or "") .. v end

-- left column
local L, R = cols[1], cols[2]
Header(L, "NAMEPLATES")
Check(L, "Show research pips on nameplates", "plates", plates)
Choice(L, "Position", "plateAnchor",
  { { "TOP", "Above" }, { "BOTTOM", "Below" }, { "LEFT", "Left" }, { "RIGHT", "Right" } }, plates)
Slider(L, "Move sideways", "plateX", -80, 80, 1, px, plates)
Slider(L, "Move up / down", "plateY", -40, 40, 1, px, plates)
Slider(L, "Size", "plateScale", 0.5, 2, 0.05, function(v) return string.format("%d%%", v * 100 + 0.5) end, plates)
Header(L, "JOURNAL")
Choice(L, "Look (needs a UI reload)", "theme", { { "leather", "Leather notebook" }, { "classic", "Classic" } }, function()
  if ns.ShowReload then ns.ShowReload() end
end)
if UI.LEATHER then
  Slider(L, "Paper brightness", "paperTone", 0.55, 1, 0.05, function(v) return string.format("%d%%", v * 100 + 0.5) end, function()
    if ns.SetPaperTone then ns.SetPaperTone(S().paperTone) end
    if ns.ShowReload then ns.ShowReload() end
  end)
end
Choice(L, "Pictures in the list", "portraits", { { "model", "Creature portraits" }, { "icon", "Type icons" } }, journal)
Check(L, "Jump to your target while the journal is open", "followTarget")
Check(L, "Journal line in creature tooltips", "tooltip")
Check(L, "Minimap button", "hideMinimap", function() ns.UpdateMinimap() end, true)

-- right column
Header(R, "WORLD MAP")
Check(R, "Show hunting grounds on the world map", "mapPins", map)
Slider(R, "Kills in an area before it shows", "mapMinKills", 1, 25, 1, tostring, map)
Slider(R, "Most creatures shown per map", "mapMaxPins", 5, 50, 1, tostring, map)
Slider(R, "Portrait size", "mapPinSize", 16, 48, 2, tostring, map)
local function mapBtn() if ns.PlaceMapButton then ns.PlaceMapButton() end end
Slider(R, "Map button: move sideways", "mapBtnX", -600, 0, 2, px, mapBtn)
Slider(R, "Map button: move up / down", "mapBtnY", -400, 0, 2, px, mapBtn)
Header(R, "POP-UPS AND ROLEPLAY")
Check(R, "Research level-up pop-ups", "toasts")
Check(R, "Pop-up sound", "toastSound")
Btn(R, "Show a test pop-up (shift-drag to move it)", function() if ns.TestToast then ns.TestToast() end end)
Btn(R, "Reset pop-up position", function()
  S().toastPos = nil
  if ns.PlaceToast then ns.PlaceToast() end
  ns.Print("research pop-up back in its usual spot.")
end)
Check(R, "Offer an RP emote on research level-up", "rpAuto")
Check(R, "Write field observations into my notes", "autoObs")
Header(R, "DATA")
Choice(R, "Journal kept", "scope", { { "account", "Shared by all characters" }, { "character", "One per character" } }, function()
  if ns.SetScope then ns.SetScope(S().scope) end
  ns.Print(S().scope == "character" and "this character now keeps its own journal (it started with a copy of the shared one)."
    or "all characters now share one journal.")
end)
local wipeBtn
wipeBtn = Btn(R, "Wipe the journal...", function()
  if wipeBtn.armed then
    wipe(ns.db.entries)
    wipe(ns.db.names)
    wipeBtn.armed = false
    wipeBtn.text:SetText("Journal wiped")
    ns.Print("journal wiped.")
    journal(); plates(); map()
  else
    wipeBtn.armed = true
    wipeBtn.text:SetText("Click again to delete every entry")
    C_Timer.After(4, function()
      wipeBtn.armed = false
      wipeBtn.text:SetText("Wipe the journal...")
    end)
  end
end)

-- reload prompt for the look setting
local reload = CreateFrame("Button", nil, win)
reload:SetSize(170, 24)
reload:SetPoint("BOTTOMLEFT", 24, 18)
Fill(reload, "BACKGROUND", C.tan, 1):SetAllPoints()
local reloadTxt = Text(reload, 11, UI.LEATHER and { 0.97, 0.90, 0.78 } or { 0.1, 0.09, 0.07 }, "CENTER")
reloadTxt:SetPoint("CENTER")
reloadTxt:SetText("Reload UI to apply the look")
reload:SetScript("OnClick", function() ReloadUI() end)
reload:Hide()
function ns.ShowReload() reload:Show() end

win:SetScript("OnShow", function()
  for _, c in ipairs(controls) do c.Refresh() end
end)

function ns.ToggleSettings()
  if win:IsShown() then win:Hide() else win:Show() end
end

------------------------------------------------------------------------
-- Entry in the game's Options > AddOns list
------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
  local panel = CreateFrame("Frame")
  local t = Text(panel, 16, C.tan)
  t:SetPoint("TOPLEFT", 16, -16)
  t:SetText("Hunter's Journal")
  local d = Text(panel, 12, C.text)
  d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
  d:SetText("All settings live in the journal's own settings window.")
  local b = CreateFrame("Button", nil, panel)
  b:SetSize(200, 26)
  b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -14)
  Fill(b, "BACKGROUND", C.panel2, 1):SetAllPoints()
  Border(b, C.tan, 0.9)
  local bt = Text(b, 12, C.tan, "CENTER")
  bt:SetPoint("CENTER")
  bt:SetText("Open settings")
  b:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
    win:Show()
  end)
  pcall(function()
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "Hunter's Journal")
    Settings.RegisterAddOnCategory(cat)
  end)
end)
end)
