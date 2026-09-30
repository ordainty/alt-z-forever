-- Alt+Z Forever
-- Based on Conceal by Keirmot (https://github.com/joaoc-pires/WoW-Conceal), GPLv3.
-- Modified by Ordainty from upstream commit dd72c9a. See README.md.

local ADDON_NAME, ns = ...
local Conceal = CreateFrame("Frame")
local settingsDB = {}
local defaults = {
    mouseover = true,
    alpha = 0,
    animationDuration = 0.25,
    fadeOutDuration = 0.25,
    fadeDelaySeconds = 0,
    buffFrame = true,
    buffFrameConcealDuringCombat = false,
    debuffFrame = true,
    debuffFrameConcealDuringCombat = false,
    actionBar1 = true,
    actionBar1ConcealDuringCombat = false,
    actionBar2 = true,
    actionBar2ConcealDuringCombat = false,
    actionBar3 = true,
    actionBar3ConcealDuringCombat = false,
    actionBar4 = true,
    actionBar4ConcealDuringCombat = false,
    actionBar5 = true,
    actionBar5ConcealDuringCombat = false,
    actionBar6 = true,
    actionBar6ConcealDuringCombat = false,
    actionBar7 = true,
    actionBar7ConcealDuringCombat = false,
    actionBar8 = true,
    actionBar8ConcealDuringCombat = false,
    petActionBar = true,
    petActionBarConcealDuringCombat = false,
    stanceBar = true,
    stanceBarConcealDuringCombat = false,
    selfFrame = true,
    selfFrameConcealDuringCombat = false,
    targetFrame = true,
    targetFrameConcealDuringCombat = false,
    microBar = true,
    microBarConcealDuringCombat = false,
    experience = true,
    experienceConcealDuringCombat = false,
    focusFrame = false,
    focusFrameConcealDuringCombat = false,
    castBar = false,
    objectiveTracker = true,
    objectiveTrackerConcealDuringCombat = true,
    buffIconCooldownViewer = false,
    buffIconCooldownViewerConcealDuringCombat = false,
    essentialCooldownViewer = false,
    essentialCooldownViewerConcealDuringCombat = false,
    utilityCooldownViewer = false,
    utilityCooldownViewerConcealDuringCombat = false,
    minimapCluster = true,
    minimapClusterConcealDuringCombat = false,
    bagsBar = true,
    bagsBarConcealDuringCombat = false,
    chat = true,
    everythingElse = true,
    party = true,
    restedXP = true,
    restedXPConcealDuringCombat = true,
    chatConcealDuringCombat = false,
    everythingElseConcealDuringCombat = false,
    partyConcealDuringCombat = false,
    idleShow = { minimapCluster = true, objectiveTracker = true, chat = true, party = true, restedXP = true },
    moveShow = {},
    -- per-frame overrides for named sweep frames: { fades, combat, idle, move }
    frameOverrides = {},
    targetLingerSeconds = 7,
    hideAllTargetLingerSeconds = 5,
    spellCastRevealSeconds = 3,
    whisperRevealSeconds = 10,
    chatInteractLingerSeconds = 3,
    unitsShowWithTarget = true,
    afkTimeoutSeconds = 30,
    afkFadeEnabled = true,
    showInDungeons = true, showInRaids = true, showInBattlegrounds = true,
    showInArenas = true, showInScenarios = true,
    barsHoverGroup = true, barsHoverLinger = 0,
    unitsHoverGroup = true, unitsHoverLinger = 0,
    partyHoverGroup = true, partyHoverLinger = 0,
    minimapHoverGroup = true, minimapHoverLinger = 3,
    minimapHoverSnapOut = true,
    otherHoverLinger = 0,
    tooltipAtCursor = true,
    newBuffReveal = true,
    alwaysShowStacked = true,
    minimapButton = true,
    minimapButtonAngle = 215,
}

-- read-only, ResetSettings copies it
ns.DEFAULTS = defaults

local isInCombat = false
local lastDesired = {}
local targetShownUntil = 0
local buffShownUntil = 0
local barsShownUntil = 0
local chatShownUntil = 0
local hideAllTargetShownUntil = 0
local tickerHandle = nil
local enabled = true
local forceHideAll = false
local afkHidden = false
local lastActivityAt = 0
local instanceType, instanceSuspended = "none", false
local INSTANCE_SETTING = {
    party = "showInDungeons", raid = "showInRaids", pvp = "showInBattlegrounds",
    arena = "showInArenas", scenario = "showInScenarios",
}

-- retail name first, classic fallback
local ActionBar1 = MainActionBar or MainMenuBar
local ActionBar2 = MultiBarBottomLeft
local ActionBar3 = MultiBarBottomRight
local ActionBar4 = MultiBarRight
local ActionBar5 = MultiBarLeft
local ActionBar6 = MultiBar5
local ActionBar7 = MultiBar6
local ActionBar8 = MultiBar7
local SocialButton = QuickJoinToastButton
local PetBar = PetActionBar or PetActionBarFrame
local ShapeshiftBar = StanceBar or StanceBarFrame
local MicroBar = MicroMenuContainer or MicroButtonAndBagsBar
local ExperienceBar = StatusTrackingBarManager or MainMenuExpBar
local QuestTracker = ObjectiveTrackerFrame or QuestWatchFrame
local CastBar = PlayerCastingBarFrame or CastingBarFrame

local trackedFrames = {
    {"Player frame", PlayerFrame}, {"Target frame", TargetFrame}, {"Focus frame", FocusFrame},
    {"Buffs", BuffFrame}, {"Debuffs", DebuffFrame},
    {"Action bar 1", ActionBar1}, {"Action bar 2", ActionBar2}, {"Action bar 3", ActionBar3},
    {"Action bar 4", ActionBar4}, {"Action bar 5", ActionBar5}, {"Action bar 6", ActionBar6},
    {"Action bar 7", ActionBar7}, {"Action bar 8", ActionBar8},
    {"Pet bar", PetBar}, {"Stance bar", ShapeshiftBar}, {"Micro menu", MicroBar},
    {"XP bar", ExperienceBar}, {"Quest tracker", QuestTracker}, {"Bags bar", BagsBar},
    {"Minimap", MinimapCluster}, {"Cast bar", CastBar},
}


function Conceal:UpdateUI()
    wipe(lastDesired)
    Conceal:ResetSweep()
    Conceal:TickUpdate()
    if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
end

function Conceal:OnInitialize()
    local savedSettingsDB = AltZForeverDB
    if not savedSettingsDB then
        settingsDB = CopyTable(defaults)
        AltZForeverDB = settingsDB
    else
        settingsDB = savedSettingsDB
        for k, v in pairs(defaults) do
            if settingsDB[k] == nil then
                settingsDB[k] = type(v) == "table" and CopyTable(v) or v
            end
        end
        settingsDB["targetLinger"] = nil
        if settingsDB["minimapHoverLingerSeconds"] then
            settingsDB["minimapHoverLinger"] = settingsDB["minimapHoverLingerSeconds"]
            settingsDB["minimapHoverLingerSeconds"] = nil
        end
        for _, k in ipairs({ "interactive", "health", "power", "actionTargetMode", "socialButton",
                "trackerHoverLingerSeconds", "minimapHoverFadeOutSeconds", "alwaysShowPlainsrunning" }) do
            settingsDB[k] = nil
        end
        if type(settingsDB["frameOverrides"]) ~= "table" then settingsDB["frameOverrides"] = {} end
    end

    isInCombat = UnitAffectingCombat("player")
    lastActivityAt = GetTime()

    if QueueStatusButton then QueueStatusButton:SetParent(UIParent) end
    tickerHandle = C_Timer.NewTicker(0.25, function()
        Conceal:TickUpdate()
    end)
    Conceal:TickUpdate()

    -- no raw input hook, so poll cursor position for the AFK timer
    local lastFocus
    local lastCursorX, lastCursorY = GetCursorPosition()
    local wasClicking = false
    C_Timer.NewTicker(0.05, function()
        if not tickerHandle then return end
        local focus
        if GetMouseFoci then focus = GetMouseFoci()[1] elseif GetMouseFocus then focus = GetMouseFocus() end
        local cx, cy = GetCursorPosition()
        if cx ~= lastCursorX or cy ~= lastCursorY then
            lastCursorX, lastCursorY = cx, cy
            Conceal:RecordActivity()
        end
        -- clicking the unit you already target fires no target event
        local clicking = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
        if clicking and not wasClicking and UnitExists("mouseover") then
            Conceal:RecordActivity()
            if forceHideAll then
                hideAllTargetShownUntil = GetTime() + (settingsDB["hideAllTargetLingerSeconds"] or 5)
                Conceal:TickUpdate()
            end
        end
        wasClicking = clicking
        if focus ~= lastFocus then
            lastFocus = focus
            Conceal:TickUpdate()
        end
    end)

    local ok, err = pcall(ns.CreateSettingsWindow, Conceal, settingsDB)
    if not ok then
        print("Alt+Z Forever: settings window failed to load: " .. tostring(err))
    end
end


-- Conditionals
function Conceal:FadeIn(frame, forced)
    if frame == nil then return end

    if forced then
        frame:SetAlpha(1)
        return
    end

    local duration = settingsDB["animationDuration"]
    if duration == 0 then duration = 0.01 end

    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    if currentAlpha == 1 then
        return
    end

    Conceal:AnimateToAlpha(frame, 1, duration)
end


function Conceal:FadeOut(frame, forced)
    if frame == nil then return end

    local frameAlpha = Conceal:GetConcealAlpha()

    if forced then
        frame:SetAlpha(frameAlpha)
        return
    end

    local duration = settingsDB["fadeOutDuration"]
    if duration == 0 then duration = 0.01 end

    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    if currentAlpha == tonumber(string.format("%.2f", frameAlpha)) then
        return
    end

    Conceal:AnimateToAlpha(frame, frameAlpha, duration)
end

function Conceal:GetConcealAlpha()
    local a = settingsDB["alpha"] or 30
    if a > 1 then a = a / 100 end
    if a == 1 then a = 0.95 end
    return a
end

function Conceal:IsContextActive()
    -- read combat live, the cached flag is stale after a mid-fight reconnect
    return InCombatLockdown() or UnitAffectingCombat("player")
end

local isMovingFlag = false

function Conceal:IsMoving()
    -- GetUnitSpeed can return a secret number, comparing it errors
    local speed = GetUnitSpeed("player")
    if issecretvalue and issecretvalue(speed) then return isMovingFlag end
    return speed > 0
end

function Conceal:SetAfkHidden(on)
    if afkHidden == on then return end
    afkHidden = on
    wipe(lastDesired)
    Conceal:ResetSweep()
    if on and GameTooltip:IsShown() then GameTooltip:Hide() end
end

function Conceal:RecordActivity()
    lastActivityAt = GetTime()
    if afkHidden then
        Conceal:SetAfkHidden(false)
        if tickerHandle then Conceal:TickUpdate() end
    end
end

function Conceal:UpdateInstanceRule()
    local inInstance, kind = IsInInstance()
    instanceType = inInstance and kind or "none"
    local setting = INSTANCE_SETTING[instanceType]
    instanceSuspended = (setting and settingsDB[setting]) and true or false
end

function Conceal:CheckAfk(inCombat, moving)
    local timeout = settingsDB["afkTimeoutSeconds"] or 0
    if not settingsDB["afkFadeEnabled"] or timeout <= 0 then
        if afkHidden then Conceal:SetAfkHidden(false) end
        return
    end
    if inCombat or moving then
        lastActivityAt = GetTime()
        if afkHidden then Conceal:SetAfkHidden(false) end
        return
    end
    if not afkHidden and GetTime() - lastActivityAt >= timeout then
        Conceal:SetAfkHidden(true)
    end
end

local function IsBarPiece(name)
    return name ~= nil and (name:match("^MainActionBar") or name:match("^MultiBar")
        or name:match("^ActionButton") or name:match("^StanceBar") or name:match("^PetActionBar")) ~= nil
end

local focusChain = {}
local function MouseFocus()
    if GetMouseFoci then return GetMouseFoci()[1] end
    return GetMouseFocus and GetMouseFocus()
end
local function RebuildFocusChain()
    wipe(focusChain)
    local f, depth = MouseFocus(), 0
    -- forbidden frames only allow IsForbidden
    while f and depth < 20 and not f:IsForbidden() do
        focusChain[f] = true
        f, depth = f:GetParent(), depth + 1
    end
end

local function IsHovered(frame, mouseOverFn, revealOnFlyout)
    if not settingsDB["mouseover"] then return false end
    if mouseOverFn then
        if mouseOverFn(frame) then return true end
    elseif frame:IsMouseOver() or focusChain[frame] then
        return true
    end
    -- flyouts can't be tied to the bar that opened them
    return (revealOnFlyout and SpellFlyout and SpellFlyout:IsShown()) and true or false
end

local heldSince = setmetatable({}, { __mode = "k" })

local SECTION_OF = {
    actionBar1 = "bars", actionBar2 = "bars", actionBar3 = "bars", actionBar4 = "bars",
    actionBar5 = "bars", actionBar6 = "bars", actionBar7 = "bars", actionBar8 = "bars",
    petActionBar = "bars", stanceBar = "bars", microBar = "bars", bagsBar = "bars", experience = "bars",
    essentialCooldownViewer = "bars", utilityCooldownViewer = "bars", buffIconCooldownViewer = "bars",
    selfFrame = "units", targetFrame = "units", focusFrame = "units",
    party = "party",
    minimapCluster = "minimap", objectiveTracker = "minimap", buffFrame = "minimap", debuffFrame = "minimap",
}
local hoverSeen = setmetatable({}, { __mode = "k" })
local lingering = setmetatable({}, { __mode = "k" })
local MainBarHovered

function Conceal:DesiredAlpha(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout, inCombat, moving, frameAlpha, section, override)
    local fades = settingsDB[key]
    if override and override.fades ~= nil then fades = override.fades end
    if not forceHideAll then
        if not fades then return 1, false end
        if not afkHidden and (not enabled or instanceSuspended) then return 1, false end
    end
    section = section or SECTION_OF[key] or "other"

    local snap = false
    if not afkHidden then
        local grouped = settingsDB[section .. "HoverGroup"]
        if mouseOverFn and grouped == false then
            mouseOverFn = (key == "actionBar1" or key == "everythingElse") and MainBarHovered or nil
        end
        local token = (mouseOverFn and grouped) and section or frame
        local wasLingering = lingering[frame]
        lingering[frame] = nil
        if IsHovered(frame, mouseOverFn, revealOnFlyout) then
            hoverSeen[token] = GetTime()
            return 1, true
        end
        local linger = settingsDB[section .. "HoverLinger"] or 0
        if linger > 0 and hoverSeen[token] and GetTime() - hoverSeen[token] < linger then
            lingering[frame] = true
            return 1, false
        end
        snap = (wasLingering and settingsDB[section .. "HoverSnapOut"]) and true or false
    end
    if (forceHideAll or afkHidden) and (key == "targetFrame" or key == "selfFrame")
            and GetTime() < hideAllTargetShownUntil and (key == "selfFrame" or UnitExists("target")) then
        return 1
    end
    local combatFades = false
    if inCombat then
        combatFades = concealDuringContextKey and settingsDB[concealDuringContextKey]
        if override and override.combat ~= nil then combatFades = override.combat end
    end
    if not forceHideAll and not combatFades then
        if key == "targetFrame" and GetTime() < targetShownUntil and UnitExists("target") then return 1 end
        if key == "selfFrame" and GetTime() < targetShownUntil then return 1 end
        if section == "bars" and GetTime() < barsShownUntil then return 1 end
    end
    if forceHideAll or afkHidden then return frameAlpha, false, snap end
    if key == "buffFrame" and GetTime() < buffShownUntil and not combatFades then return 1 end
    if inCombat then
        if combatFades then return frameAlpha, false, snap end
        heldSince[frame] = GetTime()
        return 1
    end
    if (key == "targetFrame" or key == "selfFrame") and settingsDB["unitsShowWithTarget"] and UnitExists("target") then
        heldSince[frame] = GetTime()
        return 1
    end
    local shownSet = settingsDB[moving and "moveShow" or "idleShow"]
    local shown = shownSet and shownSet[key]
    if override then
        local o = override.idle
        if moving then o = override.move end
        if o ~= nil then shown = o end
    end
    if shown then
        heldSince[frame] = GetTime()
        return 1
    end
    local delay = settingsDB["fadeDelaySeconds"] or 0
    if delay > 0 and heldSince[frame] and GetTime() - heldSince[frame] < delay then return 1 end
    return frameAlpha, false, snap
end

function Conceal:IsActionBar1MouseOver()
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn and btn:IsMouseOver() then
            return true
        end
    end
    return false
end

-- hidden bars skipped or their empty spot counts as a hover
local barsHovered, partyHovered = false, false
local hoverBars = { ActionBar2, ActionBar3, ActionBar4, ActionBar5, ActionBar6, ActionBar7, ActionBar8,
    PetBar, ShapeshiftBar, ExperienceBar, MicroBar, BagsBar }
-- looked up by name, may load late
local partyGroupNames = { PartyFrame = true, CompactPartyFrame = true,
    CompactRaidFrameManager = true, CompactRaidFrameContainer = true }

local function AnyBarHovered()
    if Conceal:IsActionBar1MouseOver() then return true end
    for f in pairs(focusChain) do
        if f == ActionBar1 or IsBarPiece(f:GetName()) then return true end
        for _, bar in ipairs(hoverBars) do
            if f == bar then return true end
        end
    end
    for _, bar in ipairs(hoverBars) do
        if bar and bar:IsVisible() and bar:IsMouseOver() then return true end
    end
    return false
end

local function BarsHovered() return barsHovered end

MainBarHovered = function()
    if Conceal:IsActionBar1MouseOver() then return true end
    for f in pairs(focusChain) do
        if f == ActionBar1 or IsBarPiece(f:GetName()) then return true end
    end
    return false
end

local unitsHovered = false
local function AnyUnitFrameHovered()
    for _, f in ipairs({ PlayerFrame, PetFrame, TargetFrame, FocusFrame }) do
        if f and f:IsVisible() and (f:IsMouseOver() or focusChain[f]) then return true end
    end
    return false
end
local function UnitsHovered() return unitsHovered end

local minimapGroupHovered, minimapGroupUp = false, false
local function UpdateMinimapGroup()
    minimapGroupHovered = enabled and ((MinimapCluster and IsHovered(MinimapCluster))
        or (BuffFrame and IsHovered(BuffFrame)) or (DebuffFrame and IsHovered(DebuffFrame))
        or (QuestTracker and IsHovered(QuestTracker))) or false
    minimapGroupUp = minimapGroupHovered
end
local function MinimapGroupUp() return minimapGroupUp end

-- aura icons inherit frame alpha and Blizzard resets each icon's alpha every frame,
-- so draw a copy on top of the faded frame
local auraCopies = {}
local auraCopyHolder
local keptNames = {}

local function IsKeptAura(button)
    local id = button.buttonInfo and button.buttonInfo.auraInstanceID
    if not id then return false end
    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", id)
    if not aura then return false end
    local stacks = aura.applications
    if settingsDB["alwaysShowStacked"] and stacks and not (issecretvalue and issecretvalue(stacks)) and stacks >= 2 then
        return true, aura.name
    end
    return false
end

local function CopyText(dst, src)
    if not src or not src:IsShown() then dst:Hide() return end
    local font, size, flags = src:GetFont()
    if not font then dst:Hide() return end
    dst:SetFont(font, size, flags)
    dst:SetTextColor(src:GetTextColor())
    dst:SetJustifyH(src:GetJustifyH())
    dst:ClearAllPoints()
    dst:SetAllPoints(src)
    dst:SetText(src:GetText())
    dst:Show()
end

local function GetAuraCopy(button)
    local copy = auraCopies[button]
    if not copy then
        auraCopyHolder = auraCopyHolder or CreateFrame("Frame", "AltZForeverAuraCopies", UIParent)
        copy = CreateFrame("Frame", nil, auraCopyHolder)
        copy:EnableMouse(false)
        copy.icon = copy:CreateTexture(nil, "ARTWORK")
        copy.count = copy:CreateFontString(nil, "OVERLAY")
        copy.duration = copy:CreateFontString(nil, "OVERLAY")
        auraCopies[button] = copy
    end
    return copy
end

local function UpdateKeptAuras(frame, key, used)
    if not frame or not frame:IsVisible() or not C_UnitAuras or not C_UnitAuras.GetAuraDataByAuraInstanceID then return end
    local faded = (lastDesired[key] and lastDesired[key] < 1) or frame:GetEffectiveAlpha() < 0.99
    if not faded then return end
    local container = frame.AuraContainer or frame
    for _, button in ipairs({ container:GetChildren() }) do
        if not button:IsForbidden() and button:IsVisible() then
            local ok, kept, name = pcall(IsKeptAura, button)
            if ok and kept then
                local copy = GetAuraCopy(button)
                copy:SetScale(button:GetEffectiveScale() / UIParent:GetEffectiveScale())
                copy:ClearAllPoints()
                copy:SetAllPoints(button)
                copy:SetFrameStrata(button:GetFrameStrata())
                copy:SetFrameLevel(button:GetFrameLevel() + 5)
                local icon = button.Icon
                copy.icon:ClearAllPoints()
                copy.icon:SetAllPoints(icon or copy)
                if icon then
                    copy.icon:SetTexture(icon:GetTexture())
                    copy.icon:SetTexCoord(icon:GetTexCoord())
                end
                CopyText(copy.count, button.Count)
                CopyText(copy.duration, button.Duration)
                copy:Show()
                used[button] = true
                table.insert(keptNames, name)
            end
        end
    end
end

local animGroups = setmetatable({}, { __mode = "k" })
local tickStats = { rescanMs = 0, sweepMs = 0, anims = 0, created = 0, slowMs = 0, slowKey = "-", minimapMs = 0, alphaMs = 0, slowAlphaMs = 0, slowAlphaName = "-" }
local worstStats = { rescanMs = 0, sweepMs = 0, anims = 0, created = 0, slowMs = 0, slowKey = "-", minimapMs = 0, alphaMs = 0, slowAlphaMs = 0, slowAlphaName = "-" }

local AnimateToAlphaInner

function Conceal:AnimateToAlpha(frame, toAlpha, duration, onFinished)
    if frame == nil then return end
    local started = debugprofilestop()
    AnimateToAlphaInner(frame, toAlpha, duration, onFinished)
    local ms = debugprofilestop() - started
    tickStats.alphaMs = tickStats.alphaMs + ms
    if ms > tickStats.slowAlphaMs then
        tickStats.slowAlphaMs = ms
        tickStats.slowAlphaName = (not frame:IsForbidden() and frame:GetName()) or "?"
    end
end

AnimateToAlphaInner = function(frame, toAlpha, duration, onFinished)
    if frame == nil then return end
    tickStats.anims = tickStats.anims + 1
    -- one group per frame, a new one per transition leaks
    local anim = animGroups[frame]
    if anim then anim:Stop() end

    if duration <= 0.01 then
        frame:SetAlpha(toAlpha)
        if onFinished then onFinished() end
        return
    end

    if not anim then
        tickStats.created = tickStats.created + 1
        anim = frame:CreateAnimationGroup()
        anim.alphaAnim = anim:CreateAnimation("Alpha")
        anim:SetToFinalAlpha(true)
        animGroups[frame] = anim
    end
    local fromAlpha = frame:GetAlpha()

    if tonumber(string.format("%.2f", fromAlpha)) == tonumber(string.format("%.2f", toAlpha)) then
        if onFinished then onFinished() end
        return
    end

    local alphaAnim = anim.alphaAnim
    alphaAnim:SetFromAlpha(fromAlpha)
    alphaAnim:SetToAlpha(toAlpha)
    alphaAnim:SetDuration(duration)
    alphaAnim:SetStartDelay(0)
    anim:SetScript("OnFinished", onFinished and function() onFinished() end or nil)
    anim:Play()
end

local function Drifted(frame, desired)
    local anim = animGroups[frame]
    if anim and anim:IsPlaying() then return false end
    return math.abs(frame:GetAlpha() - desired) > 0.01
end

local sweepExcludedNames = {
    RXPG_ARROW = true,
    TomTomCrazyArrow = true,
    AltZForeverAuraCopies = true,
    AltZForeverSettings = true,
    GameTooltip = true, ItemRefTooltip = true, ShoppingTooltip1 = true, ShoppingTooltip2 = true,
    UIErrorsFrame = true,
    ZoneTextFrame = true, SubZoneTextFrame = true,
    RaidWarningFrame = true, RaidBossEmoteFrame = true, ActionStatus = true,
    MirrorTimer1 = true, MirrorTimer2 = true, MirrorTimer3 = true, TimerTracker = true,
    LootFrame = true, GameMenuFrame = true, WorldMapFrame = true, ContainerFrameContainer = true,
    PlayerCastingBarFrame = true, CastingBarFrame = true,
}
local sweepExcludedStrata = { DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true }
-- except the beta client's unnamed submit bug button
local function IsStrataExempt(frame)
    local bug = _G.Bug
    return type(bug) == "table" and type(bug.GetParent) == "function"
        and not bug:IsForbidden() and bug:GetParent() == frame
end
local SWEEP_RESCAN_SECONDS = 2

-- nil means not ours, test for nil not == true
local managedFrames = {}
local sweepFrames = {}
local sweepLast = setmetatable({}, { __mode = "k" })
local sweepTouched = setmetatable({}, { __mode = "k" })
local sweepSeenNames = {}
local lastSweepScan = 0

-- SetAlpha alone loses to a fade-out still playing
local function RestoreSweepFrame(frame)
    local anim = animGroups[frame]
    if anim then anim:Stop() end
    if frame:GetAlpha() < 1 then frame:SetAlpha(1) end
    sweepLast[frame], sweepTouched[frame] = nil, nil
end

local function IsChatElement(name)
    return name ~= nil and (name:match("^ChatFrame") ~= nil or name == "GeneralDockManager"
        or name == "ChatAlertFrame" or name == "FriendsMicroButton" or name == "QuickJoinToastButton")
end

local function IsChatTab(name)
    return name ~= nil and name:match("^ChatFrame%d+Tab$") ~= nil
end

local function IsTyping()
    local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    return editBox ~= nil and editBox:IsShown()
end

local chatWasFocused, chatWasTyping = false, false
local function UpdateChatInteract()
    local focused = false
    for f in pairs(focusChain) do
        if IsChatElement(f:GetName()) then focused = true break end
    end
    local typing = IsTyping()
    if (chatWasFocused and not focused) or (chatWasTyping and not typing) then
        local linger = settingsDB["chatInteractLingerSeconds"] or 0
        if linger > 0 and not forceHideAll and not afkHidden then
            chatShownUntil = math.max(chatShownUntil, GetTime() + linger)
        end
    end
    chatWasFocused, chatWasTyping = focused, typing
end

local function IsSweepFrameHovered(frame)
    if focusChain[frame] then return true end
    if not frame:IsMouseOver() then return false end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return frame:GetWidth() * scale < UIParent:GetWidth() / 2
        and frame:GetHeight() * scale < UIParent:GetHeight() / 2
end

local function RescanSweepFrames()
    local windows = {}
    for _, name in ipairs(UISpecialFrames or {}) do windows[name] = true end

    local holdsNamed = {}
    for f in pairs(managedFrames) do
        local p = f:GetParent()
        while p and p ~= UIParent and not p:IsForbidden() do
            holdsNamed[p] = true
            p = p:GetParent()
        end
    end

    local current = {}
    wipe(sweepFrames)
    for _, frame in ipairs({ UIParent:GetChildren() }) do
        -- forbidden frames error on anything but IsForbidden, even GetName
        local excluded = frame:IsForbidden() or holdsNamed[frame]
        if not excluded then
            local name = frame:GetName()
            excluded = name and (sweepExcludedNames[name] or windows[name]
                or (UIPanelWindows and UIPanelWindows[name]) or name:match("^ContainerFrame"))
        end
        if not excluded then
            table.insert(sweepFrames, frame)
            current[frame] = true
            local named = frame:GetName()
            if named and not managedFrames[frame] and frame:IsVisible()
                    and not (sweepExcludedStrata[frame:GetFrameStrata()] and not IsStrataExempt(frame)) then
                sweepSeenNames[named] = true
            end
        end
    end
    for frame in pairs(sweepTouched) do
        if not current[frame] then RestoreSweepFrame(frame) end
    end
    -- container of a named frame must stay at 1 or it hides that frame (quest tracker)
    for container in pairs(holdsNamed) do
        if container:GetParent() == UIParent and container:GetAlpha() < 1 then
            RestoreSweepFrame(container)
        end
    end
    lastSweepScan = GetTime()
end

local function PartyGroupHover() return partyHovered end

-- party frames can sit outside their container's bounds
local function IsFrameOrChildHovered(f)
    if IsSweepFrameHovered(f) then return true end
    for _, child in ipairs({ f:GetChildren() }) do
        if not child:IsForbidden() and child:IsVisible() and child:IsMouseOver() then return true end
    end
    return false
end

local function SweepGroupKey(name)
    return IsChatElement(name) and "chat" or ((name and partyGroupNames[name]) and "party"
        or ((name and name:find("^RXP")) and "restedXP" or "everythingElse"))
end

local function SweepDesiredAlpha(frame, inCombat, moving, frameAlpha)
    local name = frame:GetName()
    local key = SweepGroupKey(name)
    if key == "chat" and enabled and IsTyping() then return 1, false end
    if key == "chat" and not forceHideAll and not afkHidden and GetTime() < chatShownUntil then return 1, false end
    local overrides = settingsDB["frameOverrides"]
    local hoverFn, section = IsSweepFrameHovered, nil
    if name and partyGroupNames[name] then
        hoverFn = PartyGroupHover
    elseif IsBarPiece(name) then
        hoverFn, section = BarsHovered, "bars"
    end
    local desired, hovered, snap = Conceal:DesiredAlpha(key, frame, key .. "ConcealDuringCombat", hoverFn, false, inCombat, moving, frameAlpha, section, overrides and name and overrides[name])
    return desired, hovered and true or false, snap
end

function Conceal:SweepUpdate(inCombat, moving, frameAlpha)
    local started = debugprofilestop()
    if GetTime() - lastSweepScan > SWEEP_RESCAN_SECONDS then
        RescanSweepFrames()
        tickStats.rescanMs = debugprofilestop() - started
    end
    partyHovered = false
    for name in pairs(partyGroupNames) do
        local f = _G[name]
        if f and not f:IsForbidden() and f:IsVisible() and IsFrameOrChildHovered(f) then
            partyHovered = true
            break
        end
    end
    for _, frame in ipairs(sweepFrames) do
        if managedFrames[frame] or (sweepExcludedStrata[frame:GetFrameStrata()] and not IsStrataExempt(frame)) then
            if sweepTouched[frame] then RestoreSweepFrame(frame) end
        elseif not frame:IsShown() then
            sweepLast[frame] = nil
        else
            -- pcall, other addons' frames can hand back secret values
            local ok, desired, hovered, snap = pcall(SweepDesiredAlpha, frame, inCombat, moving, frameAlpha)
            if ok and (sweepLast[frame] ~= desired
                    or (not IsChatTab(frame:GetName()) and Drifted(frame, desired))) then
                local duration = desired == 1 and settingsDB["animationDuration"] or settingsDB["fadeOutDuration"]
                if hovered or (snap and desired ~= 1) then duration = 0 end
                Conceal:AnimateToAlpha(frame, desired, duration == 0 and 0.01 or duration)
                sweepLast[frame] = desired
                sweepTouched[frame] = true
            end
        end
    end
    tickStats.sweepMs = debugprofilestop() - started - tickStats.rescanMs
end

function Conceal:ResetSweep()
    wipe(sweepLast)
end

local castBarDisabled = false
local tickMs, tickWorstMs = 0, 0
local tickTotalMs = 0

function Conceal:TickUpdate()
    tickStats.rescanMs, tickStats.sweepMs, tickStats.anims, tickStats.created = 0, 0, 0, 0
    tickStats.slowMs, tickStats.slowKey, tickStats.minimapMs = 0, "-", 0
    tickStats.alphaMs, tickStats.slowAlphaMs, tickStats.slowAlphaName = 0, 0, "-"
    local started = debugprofilestop()
    Conceal:TickUpdateInner()
    tickMs = debugprofilestop() - started
    tickTotalMs = tickTotalMs + tickMs
    if tickMs > tickWorstMs then
        tickWorstMs = tickMs
        for k, v in pairs(tickStats) do worstStats[k] = v end
    end
end

function Conceal:TickUpdateInner()
    local frameAlpha = Conceal:GetConcealAlpha()
    local contextActive = Conceal:IsContextActive()
    local moving = Conceal:IsMoving()
    Conceal:CheckAfk(contextActive, moving)
    Conceal:UpdateInstanceRule()
    RebuildFocusChain()
    UpdateChatInteract()
    barsHovered = AnyBarHovered()
    unitsHovered = AnyUnitFrameHovered()
    UpdateMinimapGroup()

    local ApplyInner
    local function Apply(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout)
        if frame == nil then return end
        local applyStarted = debugprofilestop()
        ApplyInner(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout)
        local ms = debugprofilestop() - applyStarted
        if ms > tickStats.slowMs then tickStats.slowMs, tickStats.slowKey = ms, key end
    end

    ApplyInner = function(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout)
        managedFrames[frame] = key
        -- hidden frame's alpha isn't seen and bar changes cost ~20 ms
        if not frame:IsVisible() then
            lastDesired[key] = nil
            return
        end
        local desired, hovered, snap = Conceal:DesiredAlpha(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout, contextActive, moving, frameAlpha)

        if lastDesired[key] == desired and not Drifted(frame, desired) then
            return
        end

        if desired == 1 then
            Conceal:AnimateToAlpha(frame, 1, (hovered or settingsDB["animationDuration"] == 0) and 0.01 or settingsDB["animationDuration"])
        else
            local fadeOut = (snap or settingsDB["fadeOutDuration"] == 0) and 0.01 or settingsDB["fadeOutDuration"]
            Conceal:AnimateToAlpha(frame, frameAlpha, fadeOut)
        end
        lastDesired[key] = desired
    end

    Apply("selfFrame", PlayerFrame, "selfFrameConcealDuringCombat", UnitsHovered)
    if UnitExists("pet") then
        Apply("selfFrame", PetFrame, "selfFrameConcealDuringCombat", UnitsHovered)
    end

    Apply("targetFrame", TargetFrame, "targetFrameConcealDuringCombat", UnitsHovered)
    Apply("focusFrame", FocusFrame, "focusFrameConcealDuringCombat", UnitsHovered)

    Apply("buffFrame", BuffFrame, "buffFrameConcealDuringCombat", MinimapGroupUp)
    Apply("debuffFrame", DebuffFrame, "debuffFrameConcealDuringCombat", MinimapGroupUp)

    local usedCopies = {}
    wipe(keptNames)
    UpdateKeptAuras(BuffFrame, "buffFrame", usedCopies)
    UpdateKeptAuras(DebuffFrame, "debuffFrame", usedCopies)
    for button, copy in pairs(auraCopies) do
        if not usedCopies[button] then copy:Hide() end
    end

    Apply("buffIconCooldownViewer", BuffIconCooldownViewer, "buffIconCooldownViewerConcealDuringCombat")
    Apply("essentialCooldownViewer", EssentialCooldownViewer, "essentialCooldownViewerConcealDuringCombat")
    Apply("utilityCooldownViewer", UtilityCooldownViewer, "utilityCooldownViewerConcealDuringCombat")

    Apply("actionBar1", ActionBar1, "actionBar1ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar2", ActionBar2, "actionBar2ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar3", ActionBar3, "actionBar3ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar4", ActionBar4, "actionBar4ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar5", ActionBar5, "actionBar5ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar6", ActionBar6, "actionBar6ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar7", ActionBar7, "actionBar7ConcealDuringCombat", BarsHovered, true)
    Apply("actionBar8", ActionBar8, "actionBar8ConcealDuringCombat", BarsHovered, true)

    Apply("petActionBar", PetBar, "petActionBarConcealDuringCombat", BarsHovered, true)
    Apply("stanceBar", ShapeshiftBar, "stanceBarConcealDuringCombat", BarsHovered, true)
    Apply("microBar", MicroBar, "microBarConcealDuringCombat", BarsHovered)
    Apply("experience", ExperienceBar, "experienceConcealDuringCombat", BarsHovered)
    Apply("objectiveTracker", QuestTracker, "objectiveTrackerConcealDuringCombat", MinimapGroupUp)
    if Conceal.HoldTrackerBackground then Conceal:HoldTrackerBackground() end
    Apply("chat", SocialButton, "chatConcealDuringCombat")
    Apply("bagsBar", BagsBar, "bagsBarConcealDuringCombat", BarsHovered)

    -- MinimapCluster pieces only hide via Hide(), so Show first and Hide at the end of a fade to 0
    if MinimapCluster then
        managedFrames[MinimapCluster] = "minimapCluster"
        local last = lastDesired["minimapCluster"]
        if not settingsDB["minimapCluster"] and not forceHideAll and (last == nil or last == 1) then
            if last ~= 1 then
                MinimapCluster:Show()
                MinimapCluster:SetAlpha(1)
                lastDesired["minimapCluster"] = 1
            end
        else
            local mmStarted = debugprofilestop()
            local desired, hovered, snap = Conceal:DesiredAlpha("minimapCluster", MinimapCluster, "minimapClusterConcealDuringCombat", MinimapGroupUp, false, contextActive, moving, frameAlpha)

            if lastDesired["minimapCluster"] ~= desired then
                MinimapCluster:Show()
                lastDesired["minimapCluster"] = desired

                if desired == 1 then
                    Conceal:AnimateToAlpha(MinimapCluster, 1, (hovered or settingsDB["animationDuration"] == 0) and 0.01 or settingsDB["animationDuration"])
                else
                    local fadeOut = (snap or settingsDB["fadeOutDuration"] == 0) and 0.01 or settingsDB["fadeOutDuration"]
                    if frameAlpha == 0 then
                        Conceal:AnimateToAlpha(MinimapCluster, 0, fadeOut, function()
                            -- stale fade-out can finish after a newer fade-in
                            if lastDesired["minimapCluster"] == 0 then
                                MinimapCluster:Hide()
                            end
                        end)
                    else
                        Conceal:AnimateToAlpha(MinimapCluster, frameAlpha, fadeOut)
                    end
                end
            end
            tickStats.minimapMs = debugprofilestop() - mmStarted
        end
    end

    Conceal:SweepUpdate(contextActive, moving, frameAlpha)

    -- RegisterAllEvents every tick lags the client, do it once (undo needs /reload)
    if CastBar and settingsDB["castBar"] and not castBarDisabled then
        CastBar:UnregisterAllEvents()
        castBarDisabled = true
    end
end

function Conceal:DidEnterCombat()
    isInCombat = true
    if tickerHandle then Conceal:TickUpdate() end
end

function Conceal:DidExitCombat()
    isInCombat = false
    if tickerHandle then Conceal:TickUpdate() end
end

function Conceal:PLAYER_ENTER_COMBAT(info, value)
    Conceal:DidEnterCombat()
end

function Conceal:PLAYER_REGEN_DISABLED(info, value)
    Conceal:DidEnterCombat()
end

function Conceal:PLAYER_LEAVE_COMBAT(info, value)
    Conceal:DidExitCombat()
end

function Conceal:PLAYER_REGEN_ENABLED(info, value)
    Conceal:DidExitCombat()
end

function Conceal:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    -- ADDON_LOADED fires before the combat flag is ready, resync here
    isInCombat = InCombatLockdown() or UnitAffectingCombat("player")
    Conceal:UpdateInstanceRule()
    Conceal:UpdateUI()
    if not settingsDB["welcomeSeen"] and ns.ShowWelcome then
        -- let the loading screen clear first
        C_Timer.After(2, function()
            if not settingsDB["welcomeSeen"] and not InCombatLockdown() then ns.ShowWelcome() end
        end)
    end
end

function Conceal:GetStatus(info)
    return settingsDB[info[#info]]
end

function Conceal:ResetSettings()
    local welcomeSeen = settingsDB["welcomeSeen"]
    wipe(settingsDB)
    for k, v in pairs(CopyTable(defaults)) do settingsDB[k] = v end
    settingsDB["welcomeSeen"] = welcomeSeen
    if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
    Conceal:UpdateFramesToAlpha()
    if ns.RefreshSettings then ns.RefreshSettings() end
end

function Conceal:UpdateFramesToAlpha(alpha)
    wipe(lastDesired)
    Conceal:ResetSweep()
    Conceal:TickUpdate()
end

function Conceal:SetStatus(info)
    local key = info[#info]

    if settingsDB[key] then
        settingsDB[key] = false

        if key == "selfFrame" then
            settingsDB["selfFrameConcealDuringCombat"] = false
        elseif key == "targetFrame" then
            settingsDB["targetFrameConcealDuringCombat"] = false
        elseif key == "focusFrame" then
            settingsDB["focusFrameConcealDuringCombat"] = false
        elseif key == "actionBar1" then
            settingsDB["actionBar1ConcealDuringCombat"] = false
        elseif key == "actionBar2" then
            settingsDB["actionBar2ConcealDuringCombat"] = false
        elseif key == "actionBar3" then
            settingsDB["actionBar3ConcealDuringCombat"] = false
        elseif key == "actionBar4" then
            settingsDB["actionBar4ConcealDuringCombat"] = false
        elseif key == "actionBar5" then
            settingsDB["actionBar5ConcealDuringCombat"] = false
        elseif key == "actionBar6" then
            settingsDB["actionBar6ConcealDuringCombat"] = false
        elseif key == "actionBar7" then
            settingsDB["actionBar7ConcealDuringCombat"] = false
        elseif key == "actionBar8" then
            settingsDB["actionBar8ConcealDuringCombat"] = false
        elseif key == "petActionBar" then
            settingsDB["petActionBarConcealDuringCombat"] = false
        elseif key == "stanceBar" then
            settingsDB["stanceBarConcealDuringCombat"] = false
        elseif key == "microBar" then
            settingsDB["microBarConcealDuringCombat"] = false
        elseif key == "experience" then
            settingsDB["experienceConcealDuringCombat"] = false
        elseif key == "objectiveTracker" then
            settingsDB["objectiveTracker"] = false
        elseif key == "buffIconCooldownViewer" then
            settingsDB["buffIconCooldownViewerConcealDuringCombat"] = false
        elseif key == "essentialCooldownViewer" then
            settingsDB["essentialCooldownViewerConcealDuringCombat"] = false
        elseif key == "utilityCooldownViewer" then
            settingsDB["utilityCooldownViewerConcealDuringCombat"] = false
        end
    else
        settingsDB[key] = true

        if key == "selfFrameConcealDuringCombat" then
            settingsDB["selfFrame"] = true
        elseif key == "targetFrameConcealDuringCombat" then
            settingsDB["targetFrame"] = true
        elseif key == "focusFrameConcealDuringCombat" then
            settingsDB["focusFrame"] = true
        elseif key == "actionBar1ConcealDuringCombat" then
            settingsDB["actionBar1"] = true
        elseif key == "actionBar2ConcealDuringCombat" then
            settingsDB["actionBar2"] = true
        elseif key == "actionBar3ConcealDuringCombat" then
            settingsDB["actionBar3"] = true
        elseif key == "actionBar4ConcealDuringCombat" then
            settingsDB["actionBar4"] = true
        elseif key == "actionBar5ConcealDuringCombat" then
            settingsDB["actionBar5"] = true
        elseif key == "actionBar6ConcealDuringCombat" then
            settingsDB["actionBar6"] = true
        elseif key == "actionBar7ConcealDuringCombat" then
            settingsDB["actionBar7"] = true
        elseif key == "actionBar8ConcealDuringCombat" then
            settingsDB["actionBar8"] = true
        elseif key == "petActionBarConcealDuringCombat" then
            settingsDB["petActionBar"] = true
        elseif key == "stanceBarConcealDuringCombat" then
            settingsDB["stanceBar"] = true
        elseif key == "microBarConcealDuringCombat" then
            settingsDB["microBar"] = true
        elseif key == "experienceConcealDuringCombat" then
            settingsDB["experience"] = true
        elseif key == "buffIconCooldownViewerConcealDuringCombat" then
            settingsDB["buffIconCooldownViewer"] = true
        elseif key == "essentialCooldownViewerConcealDuringCombat" then
            settingsDB["essentialCooldownViewer"] = true
        elseif key == "utilityCooldownViewerConcealDuringCombat" then
            settingsDB["utilityCooldownViewer"] = true
        end
    end
    Conceal:UpdateUI()  
end

function Conceal:GetSlider(info)
    return settingsDB[info[#info]]
end

function Conceal:SetSlider(info, value)
    settingsDB[info[#info]] = value
    if info[#info] == "alpha" then 
        local frameAlpha = value;
        if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
        Conceal:UpdateFramesToAlpha(frameAlpha)
    end
end

function Conceal:OnEvent(event, ...)
	self[event](self, event, ...)
end

function Conceal:ADDON_LOADED(event, addOnName)
	if event == "ADDON_LOADED" and (addOnName == ADDON_NAME) then
        Conceal:OnInitialize()
    end
end

function Conceal:PLAYER_LOGOUT(event, addOnName)
	if event == "PLAYER_LOGOUT" and (addOnName == ADDON_NAME) then
        AltZForeverDB = settingsDB
    end
end

Conceal:RegisterEvent("ADDON_LOADED")
Conceal:RegisterEvent("PLAYER_LOGOUT")
Conceal:RegisterEvent("PLAYER_ENTER_COMBAT")
Conceal:RegisterEvent("PLAYER_LEAVE_COMBAT")
Conceal:RegisterEvent("PLAYER_REGEN_DISABLED")
Conceal:RegisterEvent("PLAYER_REGEN_ENABLED")
Conceal:RegisterEvent("PLAYER_ENTERING_WORLD")
Conceal:RegisterEvent("PLAYER_TARGET_CHANGED")
Conceal:RegisterUnitEvent("UNIT_AURA", "player")
Conceal:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
-- a failed cast never fires UNIT_SPELLCAST_SUCCEEDED
Conceal:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
Conceal:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", "player")
Conceal:RegisterEvent("CHAT_MSG_WHISPER")
Conceal:RegisterEvent("CHAT_MSG_BN_WHISPER")

local function LogBlockedAction(event, addonName, functionName)
    if addonName ~= "alt-z-forever" or not settingsDB then return end
    local log = settingsDB["debugLog"] or {}
    settingsDB["debugLog"] = log
    table.insert(log, ("%s %s: %s (instance=%s, combat=%s)"):format(
        date("%Y-%m-%d %H:%M:%S"), event, tostring(functionName), instanceType, tostring(isInCombat)))
    while #log > 300 do table.remove(log, 1) end
end
function Conceal:ADDON_ACTION_BLOCKED(...) LogBlockedAction(...) end
function Conceal:ADDON_ACTION_FORBIDDEN(...) LogBlockedAction(...) end
Conceal:RegisterEvent("ADDON_ACTION_BLOCKED")
Conceal:RegisterEvent("ADDON_ACTION_FORBIDDEN")

-- payload is secret in combat, testing it throws
local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end

function Conceal:UNIT_AURA(event, unit, info)
    if not enabled or not settingsDB["newBuffReveal"] then return end
    if type(info) ~= "table" then return end
    local full, added = info.isFullUpdate, info.addedAuras
    if IsSecret(full) or IsSecret(added) or full or not added then return end
    local linger = settingsDB["minimapHoverLinger"] or 0
    if linger <= 0 then return end
    for _, aura in ipairs(added) do
        local ok, helpful = pcall(function() return aura.isHelpful end)
        if ok and not IsSecret(helpful) and helpful then
            buffShownUntil = GetTime() + linger
            if tickerHandle then Conceal:TickUpdate() end
            return
        end
    end
end

local function OnActionAttempted()
    Conceal:RecordActivity()
    if not enabled then return end
    local barsLinger = settingsDB["spellCastRevealSeconds"] or 0
    if barsLinger > 0 then barsShownUntil = GetTime() + barsLinger end
    local frameLinger = settingsDB["targetLingerSeconds"] or 0
    if frameLinger > 0 then targetShownUntil = GetTime() + frameLinger end
    if tickerHandle then Conceal:TickUpdate() end
end

function Conceal:UNIT_SPELLCAST_SUCCEEDED() OnActionAttempted() end
function Conceal:UNIT_SPELLCAST_FAILED() OnActionAttempted() end
Conceal.UNIT_SPELLCAST_FAILED_QUIET = Conceal.UNIT_SPELLCAST_FAILED

function Conceal:CHAT_MSG_WHISPER()
    if not enabled then return end
    local linger = settingsDB["whisperRevealSeconds"] or 0
    if linger <= 0 then return end
    chatShownUntil = GetTime() + linger
    if tickerHandle then Conceal:TickUpdate() end
end
Conceal.CHAT_MSG_BN_WHISPER = Conceal.CHAT_MSG_WHISPER

function Conceal:PLAYER_TARGET_CHANGED()
    Conceal:RecordActivity()
    if UnitExists("target") then
        targetShownUntil = GetTime() + (settingsDB["targetLingerSeconds"] or 7)
        hideAllTargetShownUntil = GetTime() + (settingsDB["hideAllTargetLingerSeconds"] or 5)
    end
    if tickerHandle then Conceal:TickUpdate() end
end

Conceal:SetScript("OnEvent", Conceal.OnEvent)

-- pcall, unknown event names error and these aren't verified on Forever
pcall(Conceal.RegisterEvent, Conceal, "PLAYER_STARTED_MOVING")
pcall(Conceal.RegisterEvent, Conceal, "PLAYER_STOPPED_MOVING")
function Conceal:PLAYER_STARTED_MOVING() isMovingFlag = true; if tickerHandle then Conceal:TickUpdate() end end
function Conceal:PLAYER_STOPPED_MOVING() isMovingFlag = false; if tickerHandle then Conceal:TickUpdate() end end

function Conceal:SetEnabled(on)
    enabled = on
    wipe(lastDesired)
    Conceal:ResetSweep()
    Conceal:TickUpdate()
    local text = "Alt+Z Forever: fade mode " .. (on and "ON" or "OFF")
    print(text)
    UIErrorsFrame:AddMessage(text, 1, 0.82, 0)
end

function AltZForever_Toggle()
    Conceal:SetEnabled(not enabled)
end
BINDING_NAME_ALTZFOREVER_TOGGLE = "Toggle fade mode"

function Conceal:SetForceHideAll(on)
    forceHideAll = on
    wipe(lastDesired)
    Conceal:ResetSweep()
    Conceal:TickUpdate()
    local text = "Alt+Z Forever: " .. (on and "UI hidden" or "UI restored")
    print(text)
    UIErrorsFrame:AddMessage(text, 1, 0.82, 0)
end

function AltZForever_HideAll()
    Conceal:SetForceHideAll(not forceHideAll)
end
BINDING_NAME_ALTZFOREVER_HIDEALL = "Hide everything / restore"

ns.BINDINGS = {
    { name = "ALTZFOREVER_TOGGLE", label = "Turn fading on and off", short = "fade mode" },
    { name = "ALTZFOREVER_QUICKTOGGLE", label = "Point at an element: toggle its fading", short = "point: toggle" },
    { name = "ALTZFOREVER_QUICKCARD", label = "Point at an element: open its settings", short = "point: card" },
    { name = "ALTZFOREVER_HIDEALL", label = "Hide everything, press again to restore", short = "hide all" },
}

-- GetBindingText prettifies BUTTON3 where it exists
function ns.BindingKeys(binding)
    local keys = { GetBindingKey(binding) }
    if #keys == 0 then return nil end
    for i, key in ipairs(keys) do
        local ok, text = pcall(GetBindingText, key)
        keys[i] = (ok and text and text ~= "") and text or key
    end
    return table.concat(keys, " or ")
end

-- which call opens the keybind panel changes between versions, try each
function ns.OpenKeyBindings()
    local function Shown()
        return (SettingsPanel and SettingsPanel:IsShown())
            or (KeyBindingFrame and KeyBindingFrame:IsShown()) or false
    end
    local attempts = {
        function() Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID) end,
        function() SettingsPanel:OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID) end,
        function() KeyBindingFrame_LoadUI() ShowUIPanel(KeyBindingFrame) end,
    }
    for _, attempt in ipairs(attempts) do
        if pcall(attempt) and Shown() then return true end
    end
    return false
end

local function OverrideWords(row)
    local parts = {}
    if row.fades ~= nil then parts[#parts + 1] = row.fades and "fades" or "always shown" end
    if row.combat ~= nil then parts[#parts + 1] = row.combat and "fades in combat" or "shows in combat" end
    if row.idle ~= nil then parts[#parts + 1] = row.idle and "shows when still" or "fades when still" end
    if row.move ~= nil then parts[#parts + 1] = row.move and "shows while moving" or "fades while moving" end
    return table.concat(parts, ", ")
end

local function StatusLines()
    local lines = {}
    local missing = {}
    for _, entry in ipairs(trackedFrames) do
        if entry[2] == nil then table.insert(missing, entry[1]) end
    end
    lines[#lines + 1] = "Alt+Z Forever: fade mode " .. (enabled and "ON" or "OFF") .. ", hide-all " .. (forceHideAll and "ON" or "OFF") .. ", alpha=" .. tostring(settingsDB["alpha"]) .. ", ticker " .. (tickerHandle and "running" or "NOT running") .. ", moving=" .. tostring(Conceal:IsMoving()) .. ", combat=" .. tostring(Conceal:IsContextActive())
    local afkTimeout = settingsDB["afkTimeoutSeconds"] or 0
    local afkState = afkHidden and "HIDDEN"
        or ((settingsDB["afkFadeEnabled"] and afkTimeout > 0) and "armed" or "off")
    lines[#lines + 1] = ("AFK fade: %s, timeout=%ds, idle for %.0fs"):format(
        afkState, afkTimeout, GetTime() - lastActivityAt)
    lines[#lines + 1] = ("Instance: type=%s, fading %s"):format(instanceType,
        instanceSuspended and "SUSPENDED (setting ticked)" or "normal")
    lines[#lines + 1] = "Not found on this client: " .. (#missing > 0 and table.concat(missing, ", ") or "none")
    local keyParts = {}
    for _, binding in ipairs(ns.BINDINGS) do
        keyParts[#keyParts + 1] = binding.short .. "=" .. (ns.BindingKeys(binding.name) or "NOT SET")
    end
    lines[#lines + 1] = "Keys: " .. table.concat(keyParts, ", ")
    lines[#lines + 1] = ("Tick: last %.2f ms, worst %.2f ms since last debug. Swept frames: %d."):format(tickMs, tickWorstMs, #sweepFrames)
    lines[#lines + 1] = ("Worst tick: rescan %.2f ms, sweep %.2f ms, rest %.2f ms, %d fades started (%d new)."):format(
        worstStats.rescanMs, worstStats.sweepMs, tickWorstMs - worstStats.rescanMs - worstStats.sweepMs,
        worstStats.anims, worstStats.created)
    lines[#lines + 1] = ("Worst tick: slowest named frame %s %.2f ms, minimap %.2f ms."):format(
        worstStats.slowKey, worstStats.slowMs, worstStats.minimapMs)
    lines[#lines + 1] = ("Worst tick: alpha changes %.2f ms total, slowest %s %.2f ms."):format(
        worstStats.alphaMs, worstStats.slowAlphaName, worstStats.slowAlphaMs)
    local isSelf = UnitIsUnit("target", "player")
    local secret = issecretvalue and issecretvalue(isSelf) or false
    lines[#lines + 1] = ("Target: exists=%s isSelf=%s secret=%s linger left %.1f s, player frame alpha %.2f"):format(
        tostring(UnitExists("target")), secret and "?" or tostring(isSelf), tostring(secret),
        math.max(0, targetShownUntil - GetTime()), PlayerFrame and PlayerFrame:GetAlpha() or -1)
    lines[#lines + 1] = ("Spell cast reveal: linger left %.1f s"):format(math.max(0, barsShownUntil - GetTime()))
    lines[#lines + 1] = ("Whisper reveal: linger left %.1f s. Hide-all target flash: linger left %.1f s"):format(
        math.max(0, chatShownUntil - GetTime()), math.max(0, hideAllTargetShownUntil - GetTime()))
    local overridden = {}
    for name, row in pairs(settingsDB["frameOverrides"] or {}) do
        if ns.HasOverride(settingsDB, name) then
            overridden[#overridden + 1] = ("%s [%s] %s"):format(name, SweepGroupKey(name), OverrideWords(row))
        end
    end
    table.sort(overridden)
    lines[#lines + 1] = "Frames with their own settings: "
        .. (#overridden > 0 and table.concat(overridden, "; ") or "none")
    lines[#lines + 1] = ("Kept auras: %s (buffs alpha %.2f, debuffs alpha %.2f)"):format(
        #keptNames > 0 and table.concat(keptNames, ", ") or "none shown",
        BuffFrame and BuffFrame:GetAlpha() or -1, DebuffFrame and DebuffFrame:GetAlpha() or -1)
    return lines
end

local function UnderLines()
    local lines = {}
    local inSweep = {}
    for _, s in ipairs(sweepFrames) do inSweep[s] = true end
    local f, depth = MouseFocus(), 0
    if not f then lines[#lines + 1] = "Alt+Z Forever: nothing under the mouse." end
    while f and depth < 20 do
        if f:IsForbidden() then lines[#lines + 1] = "  (forbidden frame)" break end
        local name = f:GetName()
        lines[#lines + 1] = ("  %s%s: alpha=%.2f named=%s swept=%s barPiece=%s strata=%s sweepLast=%s ignoresParentAlpha=%s"):format(
            string.rep(" ", depth), tostring(name or "<unnamed>"), f:GetAlpha(),
            tostring(managedFrames[f] or false), tostring(inSweep[f] == true), tostring(IsBarPiece(name)),
            f:GetFrameStrata(), tostring(sweepLast[f]),
            tostring(f.IsIgnoringParentAlpha and f:IsIgnoringParentAlpha() or false))
        f, depth = f:GetParent(), depth + 1
    end
    RebuildFocusChain()
    lines[#lines + 1] = "  bar group sees a hover: " .. tostring(AnyBarHovered())
    return lines
end

-- function, OnInitialize swaps settingsDB so a captured ref goes stale
function ns.DB()
    return settingsDB
end

function ns.IsEnabled()
    return enabled
end

function ns.ApplyChange()
    Conceal:UpdateUI()
    if ns.RefreshSettings then ns.RefreshSettings() end
end

function ns.ElementAtCursor()
    local inSweep = {}
    for _, s in ipairs(sweepFrames) do inSweep[s] = true end

    local function Describe(f, how)
        local key = managedFrames[f]
        if key then return { frame = f, key = key, how = how } end
        local name = f:GetName()
        if name and inSweep[f] then
            return { frame = f, frameName = name, group = SweepGroupKey(name), how = how }
        end
        return nil
    end

    local f, depth = MouseFocus(), 0
    while f and depth < 20 and not f:IsForbidden() do
        local found = Describe(f, "pointer")
        if found then return found end
        f, depth = f:GetParent(), depth + 1
    end

    local cx, cy = GetCursorPosition()
    local best, bestArea
    local function Consider(frame)
        if frame:IsForbidden() or not frame:IsVisible() then return end
        local l, b, w, h = frame:GetRect()
        if not (l and w) or w <= 0 or h <= 0 then return end
        local s = frame:GetEffectiveScale()
        if cx < l * s or cx > (l + w) * s or cy < b * s or cy > (b + h) * s then return end
        local area = w * h
        if bestArea == nil or area < bestArea then best, bestArea = frame, area end
    end
    for frame in pairs(managedFrames) do pcall(Consider, frame) end
    for _, frame in ipairs(sweepFrames) do
        if frame:GetName() then pcall(Consider, frame) end
    end
    return best and Describe(best, "geometry") or nil
end

-- GetSourceLocation gives Interface/AddOns/<addon>/..., the folder is the addon
local GAME_OWNER, UNLOADED_OWNER, UNKNOWN_OWNER = "Blizzard built-in", "Not loaded", "Unknown"
local OWNER_LAST = { [GAME_OWNER] = 1, [UNLOADED_OWNER] = 2, [UNKNOWN_OWNER] = 3 }

local ownerCache = {}
local function FrameOwner(name)
    local cached = ownerCache[name]
    if cached then return cached end
    local frame = _G[name]
    if not frame then return UNLOADED_OWNER end
    if not frame.GetSourceLocation then return UNKNOWN_OWNER end
    local ok, src = pcall(frame.GetSourceLocation, frame)
    if not ok or type(src) ~= "string" then return UNKNOWN_OWNER end

    local owner = GAME_OWNER
    local folder = src:match("AddOns/([^/\\]+)")
    if folder and not folder:match("^Blizzard_") then
        local AddOnMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
        local gotTitle, title = pcall(AddOnMeta, folder, "Title")
        if gotTitle and type(title) == "string" and title ~= "" then
            owner = (title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        else
            owner = folder
        end
    end
    ownerCache[name] = owner
    return owner
end

function ns.NamedSweepFrames()
    pcall(RescanSweepFrames)
    local seen, out = {}, {}
    local function Add(name, loaded)
        if seen[name] then return end
        seen[name] = true
        out[#out + 1] = { name = name, group = SweepGroupKey(name), loaded = loaded, owner = FrameOwner(name) }
    end
    for name in pairs(sweepSeenNames) do Add(name, true) end
    local overrides = settingsDB and settingsDB["frameOverrides"]
    if overrides then
        for name in pairs(overrides) do Add(name, _G[name] ~= nil) end
    end
    table.sort(out, function(a, b)
        local aLast, bLast = OWNER_LAST[a.owner] or 0, OWNER_LAST[b.owner] or 0
        if aLast ~= bLast then return aLast < bLast end
        if a.owner ~= b.owner then return a.owner < b.owner end
        return a.name < b.name
    end)
    return out
end

local function Describe(v, depth)
    if type(v) ~= "table" then return tostring(v) end
    if (depth or 0) > 2 then return "{...}" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. Describe(v[k], (depth or 0) + 1) end
    return "{" .. table.concat(parts, ", ") .. "}"
end

function ns.BuildReport()
    local lines = {}
    local AddOnMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local version, build, _, toc = GetBuildInfo()
    lines[#lines + 1] = ("Alt+Z Forever %s | client %s (%s), interface %s, %s | %s"):format(
        tostring(AddOnMeta(ADDON_NAME, "Version")), tostring(version), tostring(build), tostring(toc),
        GetLocale(), date("%Y-%m-%d %H:%M"))
    lines[#lines + 1] = ""
    for _, line in ipairs(StatusLines()) do lines[#lines + 1] = line end

    local changed = {}
    for k, v in pairs(defaults) do
        local now = settingsDB[k]
        if Describe(now) ~= Describe(v) then changed[#changed + 1] = k .. "=" .. Describe(now) end
    end
    table.sort(changed)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Changed settings (the rest are defaults): " .. (#changed > 0 and table.concat(changed, ", ") or "none")

    local NumAddOns = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
    local AddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    local AddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    local others = {}
    for i = 1, NumAddOns() do
        local name = AddOnInfo(i)
        if name and name ~= ADDON_NAME and AddOnLoaded(i) then
            local v = AddOnMeta(i, "Version")
            others[#others + 1] = v and (name .. " " .. v) or name
        end
    end
    table.sort(others)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Other addons loaded: " .. (#others > 0 and table.concat(others, ", ") or "none")

    lines[#lines + 1] = ""
    local captures = settingsDB["reportCaptures"]
    if type(captures) == "table" and #captures > 0 then
        lines[#lines + 1] = "Recent /azf under captures:"
        for _, capture in ipairs(captures) do
            for _, line in ipairs(capture) do lines[#lines + 1] = line end
        end
    else
        lines[#lines + 1] = "No /azf under captures. (Point at the problem, type /azf under, then open the report again.)"
    end

    local notes, inCommand = {}, false
    for _, entry in ipairs(type(settingsDB["debugLog"]) == "table" and settingsDB["debugLog"] or {}) do
        entry = tostring(entry)
        if entry:match("^%d%d%d%d%-%d%d%-%d%d ") then
            inCommand = entry:find(" /azf ", 1, true) ~= nil
        end
        if not inCommand then notes[#notes + 1] = entry end
    end
    if #notes > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Addon log, last 15 entries:"
        for i = math.max(1, #notes - 14), #notes do lines[#lines + 1] = notes[i] end
    end
    return table.concat(lines, "\n")
end

SLASH_ALTZFOREVER1 = "/azf"
SlashCmdList["ALTZFOREVER"] = function(msg)
    -- backticks sneak in from copied markdown
    local raw = strtrim(((msg or ""):gsub("`", "")))
    msg = strlower(raw)
    local print = print
    if msg == "debug" or msg:match("^debug ") or msg == "under" or msg == "here" or msg == "point" or msg == "bench" then
        local log = settingsDB["debugLog"] or {}
        settingsDB["debugLog"] = log
        table.insert(log, date("%Y-%m-%d %H:%M:%S") .. " /azf " .. raw)
        print = function(s)
            _G.print(s)
            table.insert(log, s)
            while #log > 300 do table.remove(log, 1) end
        end
    end
    if msg == "on" then
        Conceal:SetEnabled(true)
    elseif msg == "off" then
        Conceal:SetEnabled(false)
    elseif msg == "toggle" then
        AltZForever_Toggle()
    elseif msg == "hideall" then
        AltZForever_HideAll()
    elseif msg == "reset" then
        Conceal:ResetSettings()
        print("Alt+Z Forever: settings reset to defaults.")
    elseif msg == "debug" then
        for _, line in ipairs(StatusLines()) do print(line) end
        tickWorstMs = 0
    elseif msg:match("^debug %S") then
        -- /azf debug <FrameName>, names are case-sensitive
        local name = raw:match("^%S+%s+(%S+)")
        local f = _G[name]
        if type(f) ~= "table" or type(f.GetAlpha) ~= "function" then
            print("Alt+Z Forever: no frame named " .. name .. " (names are case-sensitive).")
        elseif f:IsForbidden() then
            print("Alt+Z Forever: " .. name .. " is forbidden; addons can't touch it.")
        else
            local inSweep, escClosable = false, false
            for _, s in ipairs(sweepFrames) do if s == f then inSweep = true break end end
            for _, n in ipairs(UISpecialFrames or {}) do if n == name then escClosable = true break end end
            local parent = f:GetParent()
            local anim = animGroups[f]
            -- party frame alpha comes from the secret range check, can be nil or secret
            local function Num(v)
                if issecretvalue and issecretvalue(v) then return "secret" end
                return type(v) == "number" and ("%.2f"):format(v) or tostring(v)
            end
            local function Call(method)
                local fn = f[method]
                if type(fn) ~= "function" then return "n/a" end
                local ok, v = pcall(fn, f)
                if not ok then return "error" end
                if issecretvalue and issecretvalue(v) then return "secret" end
                return v
            end
            print(("%s: shown=%s visible=%s alpha=%s effective=%s ignoresParentAlpha=%s parent=%s strata=%s"):format(
                name, tostring(Call("IsShown")), tostring(Call("IsVisible")), Num(Call("GetAlpha")),
                Num(Call("GetEffectiveAlpha")), tostring(Call("IsIgnoringParentAlpha")),
                tostring(parent and parent:GetName()), tostring(Call("GetFrameStrata"))))
            print(("  named=%s swept=%s sweepLast=%s escClosable=%s excluded=%s animating=%s"):format(
                tostring(managedFrames[f] or false), tostring(inSweep), tostring(sweepLast[f]),
                tostring(escClosable), tostring(sweepExcludedNames[name] == true),
                tostring(anim ~= nil and anim:IsPlaying())))
        end
    elseif msg == "under" then
        local capture = UnderLines()
        table.insert(capture, 1, date("%H:%M:%S") .. " /azf under")
        for _, line in ipairs(capture) do print(line) end
        local captures = settingsDB["reportCaptures"] or {}
        settingsDB["reportCaptures"] = captures
        table.insert(captures, capture)
        while #captures > 3 do table.remove(captures, 1) end
    elseif msg == "report" then
        if ns.ShowReport then
            ns.ShowReport()
        else
            print("Alt+Z Forever: the report window failed to load on this client.")
        end
    elseif msg == "welcome" then
        if ns.ShowWelcome then
            ns.ShowWelcome()
        else
            print("Alt+Z Forever: the welcome window failed to load on this client.")
        end
    elseif msg == "catalog" then
        local inSweep = {}
        for _, s in ipairs(sweepFrames) do inSweep[s] = true end
        local esc = {}
        for _, n in ipairs(UISpecialFrames or {}) do esc[n] = true end
        local rows = { date("%Y-%m-%d %H:%M:%S") .. " /azf catalog. Fields: name | source | strata | WxH | shown | parent | esc | named/swept/excluded" }
        local function Safe(fn, ...)
            local ok, v = pcall(fn, ...)
            return ok and tostring(v) or "?"
        end
        for i = 1, select("#", UIParent:GetChildren()) do
            local f = select(i, UIParent:GetChildren())
            if f:IsForbidden() then
                rows[#rows + 1] = ("#%d <forbidden>"):format(i)
            else
                local name = f:GetName()
                local label = name or (f.GetDebugName and Safe(f.GetDebugName, f)) or "<unnamed>"
                local src = f.GetSourceLocation and Safe(f.GetSourceLocation, f) or "n/a"
                local parent = f:GetParent()
                rows[#rows + 1] = ("%s | %s | %s | %sx%s | shown=%s | %s | esc=%s | %s/%s/%s"):format(
                    label, src, f:GetFrameStrata(), Safe(f.GetWidth, f), Safe(f.GetHeight, f),
                    tostring(f:IsShown()), tostring(parent and parent:GetName()), tostring(name ~= nil and esc[name] == true),
                    tostring(managedFrames[f] or false), tostring(inSweep[f] == true),
                    tostring(name ~= nil and sweepExcludedNames[name] == true))
            end
        end
        settingsDB["catalog"] = rows
        print(("Alt+Z Forever: catalogued %d UIParent children to SavedVariables. /reload to write the file."):format(#rows - 1))
    elseif msg == "lag" then
        local log = settingsDB["debugLog"] or {}
        settingsDB["debugLog"] = log
        local function Log(s)
            table.insert(log, s)
            while #log > 300 do table.remove(log, 1) end
        end
        Log(date("%Y-%m-%d %H:%M:%S") .. " /azf lag (20 s)")
        print("Alt+Z Forever: recording frame times for 20 s. Make the lag happen now.")
        Conceal.lagFrame = Conceal.lagFrame or CreateFrame("Frame")
        local stopAt = GetTime() + 20
        local frames, slow, worst, ourTotal = 0, 0, 0, tickTotalMs
        Conceal.lagFrame:SetScript("OnUpdate", function(self, elapsed)
            frames = frames + 1
            local ms = elapsed * 1000
            local ours = tickTotalMs - ourTotal
            ourTotal = tickTotalMs
            if ms > worst then worst = ms end
            if ms > 50 then
                slow = slow + 1
                if slow <= 40 then
                    local fading = {}
                    for fr, group in pairs(animGroups) do
                        if group:IsPlaying() then table.insert(fading, fr:GetName() or "unnamed") end
                    end
                    Log(("  %s frame %.0f ms, our tick %.1f ms, fading: %s"):format(date("%H:%M:%S"),
                        ms, ours, #fading > 0 and table.concat(fading, ",") or "-"))
                end
            end
            if GetTime() >= stopAt then
                self:SetScript("OnUpdate", nil)
                local line = ("Alt+Z Forever lag: %d frames, %d over 50 ms, worst %.0f ms."):format(frames, slow, worst)
                Log(line)
                print(line .. " /reload and tell the agent.")
            end
        end)
    elseif msg == "bench" then
        local function Time(frames)
            local saved = {}
            for i, f in ipairs(frames) do saved[i] = f:GetAlpha() end
            local started = debugprofilestop()
            for _ = 1, 3 do
                for i, f in ipairs(frames) do f:SetAlpha(saved[i] < 0.5 and 1 or 0) end
                for i, f in ipairs(frames) do f:SetAlpha(saved[i]) end
            end
            return (debugprofilestop() - started) / 6
        end
        Conceal.benchFrame = Conceal.benchFrame or CreateFrame("Frame", nil, UIParent)
        print(("Bench (ms per change): bare frame %.3f"):format(Time({ Conceal.benchFrame })))
        local bars = {
            {"bar1", ActionBar1}, {"bar2", ActionBar2}, {"bar3", ActionBar3}, {"bar4", ActionBar4},
            {"bar5", ActionBar5}, {"bar6", ActionBar6}, {"bar7", ActionBar7}, {"bar8", ActionBar8},
            {"pet", PetBar}, {"stance", ShapeshiftBar},
        }
        for _, entry in ipairs(bars) do
            local f = entry[2]
            if f then
                local buttons = f.actionButtons or f.buttons or { f:GetChildren() }
                local line = ("%s %s: shown=%s visible=%s prot=%s kids=%d, bar %.2f"):format(
                    entry[1], tostring(f:GetName()), tostring(f:IsShown()), tostring(f:IsVisible()),
                    tostring(f:IsProtected()), select("#", f:GetChildren()), Time({ f }))
                if buttons[1] then
                    line = line .. (", 1 button %.2f, all %d buttons %.2f"):format(
                        Time({ buttons[1] }), #buttons, Time(buttons))
                end
                print(line)
            end
        end
    elseif msg == "here" then
        local cx, cy = GetCursorPosition()
        local hits = {}
        local f = EnumerateFrames()
        while f do
            pcall(function()
                if f:IsForbidden() or not f:IsVisible() or f:GetEffectiveAlpha() < 0.05 then return end
                local l, b, w, h = f:GetRect()
                if not (l and w and w > 0 and h > 0) or w * h > 1200 * 700 then return end
                local s = f:GetEffectiveScale()
                if cx >= l * s and cx <= (l + w) * s and cy >= b * s and cy <= (b + h) * s then
                    table.insert(hits, { f = f, area = w * h })
                end
            end)
            f = EnumerateFrames(f)
        end
        table.sort(hits, function(a, b) return a.area < b.area end)
        print(("Alt+Z Forever: %d frames under the cursor (smallest first, max 40):"):format(#hits))
        for i = 1, math.min(#hits, 40) do
            local h = hits[i].f
            pcall(function()
                local name = (h.GetDebugName and h:GetDebugName()) or h:GetName() or tostring(h)
                local w, ht = h:GetSize()
                print(("  %s: %dx%d strata=%s level=%d alpha=%.2f effective=%.2f%s%s%s"):format(
                    name, w, ht, h:GetFrameStrata(), h:GetFrameLevel(), h:GetAlpha(), h:GetEffectiveAlpha(),
                    managedFrames[h] and " NAMED" or "", sweepTouched[h] and " SWEPT" or "",
                    h:GetParent() == UIParent and " (UIParent child)" or ""))
            end)
        end
    elseif msg == "point" then
        local hit = ns.ElementAtCursor()
        if not hit then
            print("Alt+Z Forever: nothing with settings under the cursor.")
        else
            local accessor = hit.frameName
                and ns.OverrideAccessor(settingsDB, hit.frameName, hit.group)
                or ns.KeyAccessor(settingsDB, hit.key)
            local fades, combat, idle, move = accessor.get()
            print(("Alt+Z Forever: %s, found by %s"):format(
                hit.key or (hit.frameName .. " (sweep group " .. hit.group .. ")"), hit.how))
            print(("  frame=%s alpha=%.2f visible=%s"):format(
                tostring(hit.frame:GetName() or "<unnamed>"), hit.frame:GetAlpha(),
                tostring(hit.frame:IsVisible())))
            print(("  fades=%s concealDuringCombat=%s idleShow=%s moveShow=%s"):format(
                tostring(fades), tostring(combat), tostring(idle), tostring(move)))
        end
    elseif msg == "" or msg == "menu" or msg == "settings" then
        if ns.ToggleSettings then
            ns.ToggleSettings()
        else
            print("Alt+Z Forever: the settings window failed to load on this client.")
        end
    else
        print("Alt+Z Forever commands:")
        print("  /azf toggle - fade mode on/off (also /azf on, /azf off)")
        print("  /azf hideall - hide everything now; run it again to restore your current settings")
        print("  /azf - open or close the settings window (also /azf menu)")
        print("  /azf reset - restore default settings")
        print("  /azf debug - show status and missing frames")
        print("  /azf debug <FrameName> - why one frame is or isn't fading (get names with /fstack)")
        print("  /azf under - point at a frame that fades wrongly and press Enter; the report includes it")
        print("  /azf point - what the pointing keys would act on, and how it was found")
        print("  /azf report - report a bug: a link to the issue page and a report to paste")
        print("  /azf welcome - the welcome window, with the keys and how to use them")
        print("  /azf help - this list")
        print("  More at curseforge.com/wow/addons/alt-z-forever")
        print("  Two keybinds (Esc > Key Bindings > Addons > Alt+Z Forever): hover an element, then")
        print("  press one key to toggle its fading, or the other to open its settings.")
    end
end
-- party/raid borders use ignoreParentAlpha, make them follow again
local function FollowParentAlpha(frame)
    if not frame or frame:IsForbidden() then return end
    local name = frame:GetName()
    if not (name and (name:match("^CompactParty") or name:match("^CompactRaid"))) then return end
    for _, key in ipairs({ "selectionHighlight", "aggroHighlight" }) do
        local region = frame[key]
        if region and region.SetIgnoreParentAlpha then region:SetIgnoreParentAlpha(false) end
    end
end
for _, fn in ipairs({ "CompactUnitFrame_UpdateSelectionHighlight", "CompactUnitFrame_UpdateAggroHighlight" }) do
    if type(_G[fn]) == "function" then hooksecurefunc(fn, FollowParentAlpha) end
end

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    -- nameplate aura tooltips hand us a forbidden frame, only IsForbidden is safe
    if settingsDB and settingsDB["tooltipAtCursor"] and parent and not parent:IsForbidden() then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end)

GameTooltip:HookScript("OnShow", function(tt)
    if afkHidden then tt:Hide() end
end)

-- quest tracker background drifts to 1 with no SetAlpha call, put it back each tick
-- don't hook Blizzard's setters, it errors on some loads
if ObjectiveTrackerFrame and ObjectiveTrackerFrame.NineSlice then
    local bg = ObjectiveTrackerFrame.NineSlice
    local logged = 0
    function Conceal:HoldTrackerBackground()
        local intended = ObjectiveTrackerManager and ObjectiveTrackerManager.backgroundAlpha
        if type(intended) ~= "number" then return end
        local a = bg:GetAlpha()
        if math.abs(a - intended) <= 0.01 then return end
        if logged < 5 and settingsDB then
            logged = logged + 1
            local log = settingsDB["debugLog"] or {}
            settingsDB["debugLog"] = log
            table.insert(log, date("%Y-%m-%d %H:%M:%S") .. (" tracker background %.2f -> %.2f (tracker alpha %.2f, shown %s)"):format(
                a, intended, ObjectiveTrackerFrame:GetAlpha(), tostring(bg:IsShown())))
        end
        bg:SetAlpha(intended)
    end
end
