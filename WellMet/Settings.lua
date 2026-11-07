local ADDON, ns = ...

------------------------------------------------------------------------
-- Settings window (/wellmet)
------------------------------------------------------------------------
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 0.85, 0.69, 0.40 }

local win = CreateFrame("Frame", "WellMetSettings", UIParent, "BackdropTemplate")
win:SetSize(560, 754)
win:SetPoint("CENTER")
win:SetFrameStrata("DIALOG")
win:EnableMouse(true)
win:SetMovable(true)
win:SetClampedToScreen(true)
win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving)
win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
win:SetBackdropColor(0.08, 0.05, 0.03, 0.96)
win:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
win:Hide()
tinsert(UISpecialFrames, "WellMetSettings")

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

local title = Text(win, 18, GOLD)
title:SetPoint("TOPLEFT", 18, -16)
title:SetText("Well Met")
local sub = Text(win, 11, { 0.65, 0.58, 0.48 })
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
sub:SetText("Strangers stay strangers until they tell you their name.")

local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -4, -4)

local controls = {}
local y = -64
local function Check(label, key, onChange, x)
  local cb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", x or 16, y)
  local t = Text(cb, 12)
  t:SetPoint("LEFT", cb, "RIGHT", 4, 1)
  t:SetText(label)
  cb:SetScript("OnClick", function(self)
    ns.db.settings[key] = self:GetChecked() and true or false
    if onChange then onChange() end
  end)
  cb.Refresh = function() cb:SetChecked(ns.db.settings[key]) end
  controls[#controls + 1] = cb
  if not x then y = y - 26 end
  return cb
end

local function Header(label)
  y = y - 6
  local t = Text(win, 13, GOLD)
  t:SetPoint("TOPLEFT", 18, y)
  t:SetText(label)
  local line = win:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
  line:SetPoint("TOPLEFT", 18, y - 17)
  line:SetSize(524, 1)
  y = y - 26
end

local function plates() ns.RefreshPlates() end

Header("Strangers")
Check("Hide strangers' names on nameplates", "plates", plates)
Check("Hide strangers' names on your target frame", "targetFrame", plates)
Check("Hide strangers' names in tooltips (also Total RP 3's)", "tooltips")
Check("Show in tooltips whether someone uses Total RP 3, and if they're in character", "rpLine")
Check("Hide strangers' names in the game's emote lines (\"You thank the Human woman.\")", "chatEmotes")
Check("Turn off the game's floating names above characters", "overhead", function() ns.ApplyOverhead() end)
Check("Turn off pet and totem names (they show the owner's name; yours too)", "petNames", function() ns.ApplyOverhead() end)
do
  local t = Text(win, 12)
  t:SetPoint("TOPLEFT", 20, y - 4)
  t:SetText("Show strangers as:")
  local opts = { { "race", "Human woman" }, { "stranger", "Stranger" } }
  local btns = {}
  for i, o in ipairs(opts) do
    local b = CreateFrame("CheckButton", nil, win, "UIRadioButtonTemplate")
    b:SetPoint("TOPLEFT", 140 + (i - 1) * 130, y - 2)
    local bt = Text(b, 12)
    bt:SetPoint("LEFT", b, "RIGHT", 4, 1)
    bt:SetText(o[2])
    b:SetScript("OnClick", function()
      ns.db.settings.style = o[1]
      for _, x in ipairs(btns) do x:SetChecked(x == b) end
      plates()
    end)
    btns[i] = b
  end
  controls[#controls + 1] = { Refresh = function()
    for i, o in ipairs(opts) do btns[i]:SetChecked(ns.db.settings.style == o[1]) end
  end }
  y = y - 28
end

Header("Who counts as known")
Check("Guildmates", "knowGuild", plates, 16)
Check("Party and raid members", "knowGroup", plates, 200)
Check("Friends", "knowFriends", plates, 400)
y = y - 26
Check("Anyone I've set a Total RP 3 relationship with", "knowRelations", plates)
Check("Tell me in chat when I learn someone's name", "announce")

Header("Introducing yourself")
Check("Show the introduce button (shift-drag to move)", "button", function() ns.UpdateButton() end)
Check("Put it on your target frame, only when you target a player", "btnAttach", function() ns.UpdateButton() end)

local hint = Text(win, 11, { 0.65, 0.58, 0.48 })
hint:SetPoint("TOPLEFT", 20, y - 2)
hint:SetWidth(520)
hint:SetJustifyV("TOP")
hint:SetText("One emote per line, your name goes in front. Words you can use: {first} {last} {full} {title} {profession} {motto} {race} {class} {he} {him} {his} {himself}. Lines using something your profile doesn't have are skipped. Keep {first} in every line so others learn your name.")
y = y - 44

local box = CreateFrame("Frame", nil, win, "BackdropTemplate")
box:SetPoint("TOPLEFT", 18, y)
box:SetSize(524, 130)
box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
box:SetBackdropColor(0, 0, 0, 0.45)
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.35)
local scroll = CreateFrame("ScrollFrame", nil, box)
scroll:SetPoint("TOPLEFT", 6, -6)
scroll:SetPoint("BOTTOMRIGHT", -6, 6)
local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFont(FONT, 12, "")
edit:SetWidth(510)
edit:SetTextColor(0.92, 0.88, 0.80)
scroll:SetScrollChild(edit)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, d)
  local max = math.max(0, edit:GetHeight() - self:GetHeight())
  self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 20)))
end)
box:EnableMouse(true)
box:SetScript("OnMouseDown", function() edit:SetFocus() end)
edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
edit:SetScript("OnTextChanged", function(self, user)
  if not user then return end
  local lines = {}
  for l in (self:GetText() .. "\n"):gmatch("(.-)\n") do
    l = l:gsub("^%s+", ""):gsub("%s+$", "")
    if l ~= "" then lines[#lines + 1] = l end
  end
  ns.cdb.lines = lines
end)
y = y - 138

local function Button(label, x, w, onClick)
  local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  b:SetSize(w, 22)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(label)
  b:SetScript("OnClick", onClick)
  return b
end

Button("Try a line", 18, 110, function()
  local line = ns.PickLine()
  ns.Print(line and ((UnitName("player") or "") .. " " .. line) or "no line fits your profile.")
end)
Button("Reset to default lines", 134, 170, function()
  ns.cdb.lines = nil
  edit:SetText(table.concat(ns.BaseLines(), "\n"))
end)

local known = Text(win, 11, { 0.65, 0.58, 0.48 }, "RIGHT")
known:SetPoint("TOPRIGHT", -20, y - 5)

local forget
forget = Button("Forget everyone", 400, 140, function()
  if forget.armed then
    ns.ForgetAll()
    forget.armed = false
    forget:SetText("Forget everyone")
    known:SetText("You know 0 people")
  else
    forget.armed = true
    forget:SetText("Click again")
    C_Timer.After(4, function() forget.armed = false forget:SetText("Forget everyone") end)
  end
end)
forget:ClearAllPoints()
forget:SetPoint("BOTTOMRIGHT", -18, 16)
known:ClearAllPoints()
known:SetPoint("RIGHT", forget, "LEFT", -10, 0)

win:SetScript("OnShow", function()
  for _, c in ipairs(controls) do c.Refresh() end
  edit:SetText(table.concat(ns.Lines(), "\n"))
  local n = ns.KnownCount()
  known:SetText("You know " .. n .. (n == 1 and " person" or " people"))
end)

function ns.ToggleSettings()
  if win:IsShown() then win:Hide() else win:Show() end
end

------------------------------------------------------------------------
-- Also listed in the game's Options > AddOns
------------------------------------------------------------------------
if Settings and Settings.RegisterCanvasLayoutCategory then
  local panel = CreateFrame("Frame")
  local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", 16, -16)
  t:SetText("Well Met")
  local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
  d:SetText("Strangers stay strangers until they tell you their name.\nType /wellmet, or use the button below.")
  d:SetJustifyH("LEFT")
  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetSize(200, 26)
  b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -14)
  b:SetText("Open Well Met settings")
  b:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    win:Show()
  end)
  local cat = Settings.RegisterCanvasLayoutCategory(panel, "Well Met")
  Settings.RegisterAddOnCategory(cat)
end
