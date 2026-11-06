local ADDON, ns = ...
local S = ns.S

------------------------------------------------------------------------
-- Who you are: read from your Total RP 3 profile when it's there,
-- otherwise from your character.
------------------------------------------------------------------------
local PRONOUNS = {
  he = { he = "he", him = "him", his = "his", himself = "himself" },
  she = { he = "she", him = "her", his = "her", himself = "herself" },
  they = { he = "they", him = "them", his = "their", himself = "themselves" },
}

function ns.Me()
  local me = {}
  local okN, name, surname = pcall(UnitName, "player")
  me.first = okN and S(name) or "Someone"
  surname = okN and S(surname)
  if type(surname) == "string" and surname ~= "" then me.last = surname end
  local okR, race = pcall(UnitRace, "player")
  me.race = okR and S(race) or nil
  local okC, class = pcall(UnitClass, "player")
  me.class = okC and S(class) or nil
  local okX, sex = pcall(UnitSex, "player")
  local pro = (okX and S(sex) == 3) and "she" or "he"

  if TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
    local ok, prof = pcall(TRP3_API.profile.getPlayerCurrentProfile)
    local ch = ok and type(prof) == "table" and prof.player and prof.player.characteristics
    if type(ch) == "table" then
      local function str(v) return (type(v) == "string" and v ~= "") and v or nil end
      me.first = str(ch.FN) or me.first
      me.last = str(ch.LN) or me.last
      me.title = str(ch.TI)
      me.race = str(ch.RA) or me.race
      me.class = str(ch.CL) or me.class
      for _, mi in ipairs(type(ch.MI) == "table" and ch.MI or {}) do
        local label = type(mi.NA) == "string" and mi.NA:lower() or ""
        local value = str(mi.VA)
        if value then
          value = value:gsub("^%s+", ""):gsub("%s+$", "")
          if label:find("pronoun") then
            local p = value:lower():match("^(%a+)")
            if PRONOUNS[p] then pro = p elseif p == "her" then pro = "she" elseif p == "them" then pro = "they" end
          elseif label:find("profession") or label:find("occupation") then
            me.profession = value
          elseif label:find("motto") then
            me.motto = value
          end
        end
      end
    end
  end
  me.full = me.first .. (me.last and (" " .. me.last) or "")
  for k, v in pairs(PRONOUNS[pro]) do me[k] = v end
  me.himself = PRONOUNS[pro].himself
  return me
end

------------------------------------------------------------------------
-- Introduction lines. These are emotes: your name is put in front.
-- {first} {last} {full} {title} {profession} {motto} {race} {class}
-- {he} {him} {his} {himself}. A line that uses a word your profile
-- doesn't have is skipped. Every line must say {first} so other players
-- running Well Met learn your name from it.
------------------------------------------------------------------------
ns.DEFAULT_LINES = {
  'offers a broad, easy grin and a nod. "{full}. Well met."',
  'wipes a hand on {his} trousers and holds it out. "{first}. {full}."',
  'touches two fingers to {his} brow. "{full}, {title}. Pleasure."',
  'offers a calloused hand. "Name\'s {first}. {profession}, if you\'ve ever need of one."',
  'gives a friendly nod. "{full}. {motto}"',
  'introduces {himself} with a warm smile. "I\'m {first}. Good to meet you."',
}

-- your own edited lines, else a line pack for this character, else defaults
local function BaseLines()
  return ns.PackLines() or ns.DEFAULT_LINES
end
ns.BaseLines = BaseLines

local function Lines()
  local custom = ns.cdb and ns.cdb.lines
  if type(custom) == "table" and #custom > 0 then return custom end
  return BaseLines()
end
ns.Lines = Lines

local function Fill(line, me)
  local missing = false
  local text = line:gsub("{(%a+)}", function(key)
    local v = me[key]
    if not v then missing = true return "" end
    return v
  end)
  if missing then return nil end
  return text
end

local last
local pending -- line shown in the tooltip, sent on the next click

local function Pick()
  local me = ns.Me()
  local usable = {}
  for i, line in ipairs(Lines()) do
    local text = Fill(line, me)
    if text and text ~= "" then usable[#usable + 1] = { i = i, text = text } end
  end
  if #usable == 0 then return nil end
  local choice
  repeat choice = usable[math.random(#usable)] until #usable < 2 or choice.i ~= last
  last = choice.i
  return choice.text
end
ns.PickLine = Pick

function ns.Introduce()
  local line = pending or Pick()
  pending = nil
  if not line then ns.Print("no introduction lines fit your profile. Add some in /wellmet settings.") return end
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  local ok, err = pcall(send, line, "EMOTE")
  if not ok then ns.Print("couldn't send the introduction: " .. tostring(err)) end
end

------------------------------------------------------------------------
-- The button
------------------------------------------------------------------------
local btn = CreateFrame("Button", "WellMetButton", UIParent)
btn:SetSize(38, 38)
btn:SetFrameStrata("HIGH")
btn:SetPoint("CENTER", 0, -220)
btn:SetMovable(true)
btn:SetClampedToScreen(true)
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:RegisterForDrag("LeftButton")
btn:Hide()

local bg = btn:CreateTexture(nil, "BACKGROUND")
bg:SetPoint("TOPLEFT", -3, 3)
bg:SetPoint("BOTTOMRIGHT", 3, -3)
bg:SetColorTexture(0.85, 0.66, 0.36, 1)
local inner = btn:CreateTexture(nil, "BORDER")
inner:SetPoint("TOPLEFT", -1, 1)
inner:SetPoint("BOTTOMRIGHT", 1, -1)
inner:SetColorTexture(0.12, 0.07, 0.03, 1)
local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
for _, path in ipairs({ "Interface\\Icons\\Achievement_Reputation_01", "Interface\\Icons\\INV_Misc_Note_01", "Interface\\Icons\\INV_Misc_QuestionMark" }) do
  if icon:SetTexture(path) ~= false then break end
end
btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- soft glow while your target is a stranger
local glow = btn:CreateTexture(nil, "OVERLAY")
glow:SetPoint("TOPLEFT", -8, 8)
glow:SetPoint("BOTTOMRIGHT", 8, -8)
glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
glow:SetBlendMode("ADD")
glow:SetVertexColor(1, 0.8, 0.4)
glow:Hide()
local glowT = 0
btn:SetScript("OnUpdate", function(_, elapsed)
  if not glow:IsShown() then return end
  glowT = glowT + elapsed
  glow:SetAlpha(0.35 + 0.35 * math.sin(glowT * 3))
end)

local function Attached()
  return ns.db.settings.btnAttach
end

local function TargetIsPlayer()
  local okE, exists = pcall(UnitExists, "target")
  if not (okE and S(exists)) then return false end
  local okP, isPlayer = pcall(UnitIsPlayer, "target")
  local okM, me = pcall(UnitIsUnit, "target", "player")
  return okP and S(isPlayer) and not (okM and S(me))
end

local function Place()
  local st = ns.db.settings
  btn:ClearAllPoints()
  if Attached() then
    local tf = ns.TargetFrameObj and ns.TargetFrameObj()
    local off = st.btnOffset or { x = 26, y = -6 }
    if tf then
      btn:SetPoint("CENTER", tf, "TOPRIGHT", off.x, off.y)
    else
      btn:SetPoint("CENTER", 0, -220)
    end
  elseif st.btnPos then
    btn:SetPoint("CENTER", UIParent, "BOTTOMLEFT", st.btnPos.x, st.btnPos.y)
  else
    btn:SetPoint("CENTER", 0, -220)
  end
end

btn:SetScript("OnDragStart", function(self)
  if IsShiftKeyDown() then self:StartMoving() end
end)
btn:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local x, y = self:GetCenter()
  local tf = ns.TargetFrameObj and ns.TargetFrameObj()
  if Attached() and tf and tf:GetRight() then
    -- remember the spot relative to the target frame
    local s = self:GetEffectiveScale() / tf:GetEffectiveScale()
    ns.db.settings.btnOffset = { x = x * s - tf:GetRight(), y = y * s - tf:GetTop() }
  else
    ns.db.settings.btnPos = { x = x, y = y }
  end
  Place()
end)
btn:SetScript("OnClick", function(_, button)
  if button == "RightButton" then
    ns.ToggleTarget()
  else
    ns.Introduce()
  end
  GameTooltip:Hide()
end)
btn:SetScript("OnEnter", function(self)
  pending = Pick()
  local me = UnitName("player") or ""
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  if TargetIsPlayer() then
    if ns.IsKnownUnit("target") then
      GameTooltip:AddLine("You know " .. ns.DisplayName(ns.UnitFull("target") or "them"), 0.6, 0.85, 0.5)
    else
      GameTooltip:AddLine("Introduce yourself to this " .. (ns.Mask("target"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()), 0.85, 0.69, 0.40)
    end
  else
    GameTooltip:AddLine("Introduce yourself", 0.85, 0.69, 0.40)
  end
  if pending then GameTooltip:AddLine(me .. " " .. pending, 1, 0.5, 0.25, true) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Left-click: introduce yourself", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Right-click: mark your target as known / a stranger", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Shift-drag: move", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

function ns.UpdateButton()
  local st = ns.db.settings
  Place()
  local show = st.button and (not Attached() or TargetIsPlayer())
  btn:SetShown(show and true or false)
  glow:SetShown(show and Attached() and TargetIsPlayer() and not ns.IsKnownUnit("target") or false)
end

-- target changed, or someone became known
function ns.OnTarget() ns.UpdateButton() end

function ns.OnLoad()
  ns.UpdateButton()
  ns.ApplyOverhead()
  -- TRP3 builds its tooltip at login, so hook it a moment later
  C_Timer.After(2, ns.SetupTooltips)
end
