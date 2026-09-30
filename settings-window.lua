-- Alt+Z Forever settings window

local _, ns = ...

local CURSEFORGE_URL = "https://www.curseforge.com/wow/addons/alt-z-forever"
local NAV_W = 190
local WIDTH = 570                  -- page width; fits ElementRow's Reset button
local COL = ns.ELEMENT_ROW_COL
local ROW_H = ns.ELEMENT_ROW_H

-- id: the section's settings prefix (<id>HoverGroup, <id>HoverLinger).
-- group: tooltip for "Hover one, show all"; sections without it have no switch.
-- Rows: kind nil = element row (key, key.."ConcealDuringCombat", idleShow[key], moveShow[key]),
-- "check" = one on/off setting, "slider" = one number setting.
-- frame: a global name; if it doesn't exist on this client the row says so.
local SECTIONS = {
    {
        id = "bars", title = "Action bars",
        note = "Bars 1 to 8, pet and stance bars, micro menu, bags, XP bar and cooldown viewers. Bars turned off in Edit Mode are skipped.",
        group = "Hovering any bar reveals all of them, micro menu, bags and XP bar included. Off: each bar reveals on its own.",
        rows = {
            { key = "actionBar1", label = "Action bar 1" },
            { key = "actionBar2", label = "Action bar 2" },
            { key = "actionBar3", label = "Action bar 3" },
            { key = "actionBar4", label = "Action bar 4" },
            { key = "actionBar5", label = "Action bar 5" },
            { key = "actionBar6", label = "Action bar 6" },
            { key = "actionBar7", label = "Action bar 7" },
            { key = "actionBar8", label = "Action bar 8" },
            { key = "petActionBar", label = "Pet bar" },
            { key = "stanceBar", label = "Stance bar" },
            { key = "microBar", label = "Micro menu" },
            { key = "bagsBar", label = "Bags" },
            { key = "experience", label = "XP bar" },
            { key = "essentialCooldownViewer", label = "Essential cooldowns", frame = "EssentialCooldownViewer" },
            { key = "utilityCooldownViewer", label = "Utility cooldowns", frame = "UtilityCooldownViewer" },
            { key = "buffIconCooldownViewer", label = "Buff cooldowns", frame = "BuffIconCooldownViewer" },
        },
    },
    {
        id = "units", title = "Unit frames",
        note = "With a target, the target and player frames show. Without one, picking a target still shows them for a few seconds, even while moving.",
        group = "Hovering the player, pet, target or focus frame reveals all of them.",
        rows = {
            { key = "selfFrame", label = "Player and pet" },
            { key = "targetFrame", label = "Target" },
            { key = "focusFrame", label = "Focus" },
            { kind = "check", key = "unitsShowWithTarget", label = "Show while you have a target",
              tip = "Keeps the target and player frames showing for as long as you have a target. Combat rules still apply in combat." },
            { kind = "slider", key = "targetLingerSeconds", label = "Target shows for", min = 0, max = 15, step = 1, unit = " s",
              tip = "Seconds the frames show after you pick a target. Matters when the box above is off, and for the player frame after the target is cleared." },
            { kind = "check", key = "castBar", label = "Turn off the cast bar",
              tip = "Not a fade: the player cast bar is switched off completely. Turning it back on needs a /reload." },
        },
    },
    {
        id = "party", title = "Party and raid",
        note = "Party frames and the raid panel (the pull-out tab on the left).",
        group = "Hovering the party frames or the raid panel reveals both.",
        rows = {
            { key = "party", label = "Party frames and raid panel" },
        },
    },
    {
        id = "minimap", title = "Minimap, quests and buffs",
        note = "The minimap, quest tracker, buffs and debuffs.",
        group = "Hovering the minimap, quest tracker, buffs or debuffs reveals all four.",
        rows = {
            { key = "minimapCluster", label = "Minimap" },
            { key = "objectiveTracker", label = "Quest tracker" },
            { key = "buffFrame", label = "Buffs" },
            { key = "debuffFrame", label = "Debuffs" },
            { kind = "check", key = "newBuffReveal", label = "Show buffs when a new buff arrives",
              tip = "Gaining a buff brings up the buff frame for the \"Keep showing after hover\" time." },
            { kind = "check", key = "alwaysShowStacked", label = "Always show auras at 2+ stacks",
              tip = "Any buff or debuff currently at two or more stacks stays visible." },
        },
    },
    {
        id = "other", title = "Everything else",
        note = "Frames not listed above fade by the same rules, including other addons' frames. Tooltips, popups, open windows and waypoint arrows never fade. There is no group switch here: it would reveal the whole screen on any hover.",
        rows = {
            { key = "chat", label = "Chat", tip = "Also shows while you type." },
            { key = "restedXP", label = "RestedXP Guides",
              tip = "The RestedXP guide window and its other frames. Its waypoint arrow never fades. No effect if the addon isn't installed." },
            { key = "everythingElse", label = "Other frames" },
        },
    },
    {
        title = "In instances",
        note = "Fading is turned off inside the kinds of instance ticked here: the UI shows normally. Hide-all and AFK fade still work there.",
        rows = {
            { kind = "check", key = "showInDungeons", label = "Show the UI in dungeons",
              tip = "Turns fading off inside five-player dungeons." },
            { kind = "check", key = "showInRaids", label = "Show the UI in raids",
              tip = "Turns fading off inside raids." },
            { kind = "check", key = "showInBattlegrounds", label = "Show the UI in battlegrounds",
              tip = "Turns fading off inside battlegrounds." },
            { kind = "check", key = "showInArenas", label = "Show the UI in arenas",
              tip = "Turns fading off inside arenas." },
            { kind = "check", key = "showInScenarios", label = "Show the UI in scenarios",
              tip = "Turns fading off inside scenarios." },
        },
    },
}

ns.SETTINGS_SECTIONS = SECTIONS

-- advanced list isn't in SECTIONS, its rows come from ns.NamedSweepFrames() at runtime
local ADVANCED = {
    id = "advanced", title = "Frames by addon",
    note = "Named frames with no row of their own, grouped by the addon that created them: other addons', and the game's own odds and ends. Each follows its group above until you change it here, and Reset puts it back. The list fills as frames appear on screen, so something you have not seen yet this session is not in it yet.",
}

local GROUP_LABELS = {
    chat = "Chat", party = "Party frames and raid panel",
    restedXP = "RestedXP Guides", everythingElse = "Other frames",
}

local GENERAL = {
    { kind = "slider", key = "alpha", label = "Faded opacity", min = 0, max = 100, step = 5, unit = "%",
      tip = "How visible elements are while faded. 0 hides them completely." },
    { kind = "slider", key = "fadeDelaySeconds", label = "Wait before fading", min = 0, max = 10, step = 0.5, unit = " s",
      tip = "How long elements keep showing after combat ends or you start moving." },
    { kind = "slider", key = "fadeOutDuration", label = "Fade-out time", min = 0, max = 2, step = 0.25, unit = " s",
      tip = "How long the fade itself takes." },
    { kind = "slider", key = "animationDuration", label = "Fade-in time", min = 0, max = 2, step = 0.25, unit = " s",
      tip = "How long elements take to come back. Hover reveals are always instant." },
    { kind = "check", key = "tooltipAtCursor", label = "Tooltips follow the mouse",
      tip = "Tooltips that normally sit in the bottom-right corner (units, world objects) appear at the cursor instead." },
    { kind = "check", key = "afkFadeEnabled", label = "Fade when you're away (AFK)",
      tip = "Fades the whole UI, like hide-all, after the time below with no mouse movement, target change or spell cast. Elements set to Always shown stay. Reveals on any input; never triggers in combat." },
    { kind = "slider", key = "afkTimeoutSeconds", label = "AFK fade after", min = 15, max = 300, step = 15, unit = " s",
      tip = "Seconds of no activity before AFK fade kicks in." },
    { kind = "check", key = "minimapButton", label = "Minimap button",
      tip = "Shows a button on the minimap that opens this window. Drag it to move it around the minimap. With it off, type /azf instead." },
}

local COLUMN_TIPS = ns.ELEMENT_ROW_COLUMN_TIPS

local HOVER_SUFFIXES = { "HoverGroup", "HoverLinger", "HoverSnapOut" }

local function SectionKeys(section)
    local plain, elements = {}, {}
    if section.id then
        for _, suffix in ipairs(HOVER_SUFFIXES) do plain[#plain + 1] = section.id .. suffix end
    end
    for _, def in ipairs(section.rows) do
        if def.kind then plain[#plain + 1] = def.key else elements[#elements + 1] = def.key end
    end
    return plain, elements
end

local Differs = ns.Differs

local function SectionChangedCount(db, section)
    local d = ns.DEFAULTS
    local plain, elements = SectionKeys(section)
    local n = 0
    for _, key in ipairs(plain) do
        if Differs(db[key], d[key]) then n = n + 1 end
    end
    for _, key in ipairs(elements) do
        if Differs(db[key], d[key]) then n = n + 1 end
        local combatKey = key .. "ConcealDuringCombat"
        if Differs(db[combatKey], d[combatKey]) then n = n + 1 end
        if Differs((db.idleShow or {})[key], d.idleShow[key]) then n = n + 1 end
        if Differs((db.moveShow or {})[key], d.moveShow[key]) then n = n + 1 end
    end
    return n
end

local function ResetSection(db, section)
    local d = ns.DEFAULTS
    db.idleShow = db.idleShow or {}
    db.moveShow = db.moveShow or {}
    local plain, elements = SectionKeys(section)
    for _, key in ipairs(plain) do db[key] = d[key] end
    for _, key in ipairs(elements) do
        db[key] = d[key]
        db[key .. "ConcealDuringCombat"] = d[key .. "ConcealDuringCombat"]
        db.idleShow[key] = d.idleShow[key]
        db.moveShow[key] = d.moveShow[key]
    end
end

function ns.CreateSettingsWindow(Conceal, db)
    local refreshers = {}
    local items = {}
    local refreshing = false
    local RebuildAdvanced   -- assigned below, once the layout helpers exist
    local dirty = false

    local function Refresh()
        refreshing = true
        for _, fn in ipairs(refreshers) do fn() end
        refreshing = false
    end

    local function Changed()
        dirty = true
        Conceal:UpdateUI()
        Refresh()
    end

    local Tip, CheckBox = ns.Tip, ns.CheckBox

    local win = CreateFrame("Frame", "AltZForeverSettings", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(NAV_W + WIDTH + 60, 660)
    win:SetPoint("CENTER")
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "AltZForeverSettings")
    local titleText = win.TitleText
    if not titleText then
        titleText = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleText:SetPoint("TOP", win, "TOP", 0, -5)
    end
    titleText:SetText("Alt+Z Forever")

    StaticPopupDialogs["ALTZFOREVER_RESET"] = {
        text = "Reset all Alt+Z Forever settings to their defaults?",
        button1 = YES, button2 = NO,
        OnAccept = function() Conceal:ResetSettings() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    reset:SetSize(130, 22)
    reset:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 8)
    reset:SetText("Reset to defaults")
    reset:SetScript("OnClick", function() StaticPopup_Show("ALTZFOREVER_RESET") end)
    local report = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    report:SetSize(110, 22)
    report:SetPoint("LEFT", reset, "RIGHT", 8, 0)
    report:SetText("Report a bug")
    report:SetScript("OnClick", function() if ns.ShowReport then ns.ShowReport() end end)
    Tip(report, "Report a bug", "Opens a window with a link to the addon's issue page and a report to paste into it. Same as /azf report.")

    local nav = CreateFrame("Frame", nil, win)
    nav:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -32)
    nav:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 36)
    nav:SetWidth(NAV_W)
    local navLine = nav:CreateTexture(nil, "ARTWORK")
    navLine:SetColorTexture(1, 1, 1, 0.15)
    navLine:SetWidth(1)
    navLine:SetPoint("TOPRIGHT", nav, "TOPRIGHT", 0, 0)
    navLine:SetPoint("BOTTOMRIGHT", nav, "BOTTOMRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", nav, "TOPRIGHT", 10, 0)
    scroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -34, 36)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH, 1)
    scroll:SetScrollChild(content)

    local function Relayout()
        local y = 0
        for _, item in ipairs(items) do
            item.y = y
            if item.section and not item.section.expanded then
                item.frame:Hide()
            else
                item.frame:ClearAllPoints()
                item.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
                item.frame:Show()
                y = y + item.height
            end
        end
        content:SetHeight(math.max(y, 1))
    end

    local function ScrollTo(item)
        -- scroll range lags a frame behind a new layout
        C_Timer.After(0, function()
            local target = math.min(item.y, scroll:GetVerticalScrollRange())
            if scroll.ScrollBar then scroll.ScrollBar:SetValue(target) else scroll:SetVerticalScroll(target) end
        end)
    end

    local function Add(frame, height, section)
        frame:SetSize(WIDTH, height)
        local item = { frame = frame, height = height, section = section }
        table.insert(items, item)
        return item
    end

    local function Heading(text)
        local f = CreateFrame("Frame", nil, content)
        local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
        fs:SetText(text)
        local line = f:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 0.15)
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 1)
        line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 1)
        return f, Add(f, 30), fs
    end

    local function Note(text, section)
        local f = CreateFrame("Frame", nil, content)
        local fs = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -4)
        fs:SetWidth(WIDTH - 40)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        Add(f, fs:GetStringHeight() + 10, section)
    end

    local function Label(f, text, x)
        local fs = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fs:SetPoint("LEFT", f, "LEFT", x or 28, 0)
        fs:SetText(text)
        return fs
    end

    -- right-click goes on the row, checkboxes don't get it on this client
    local function RowResets(f, key)
        f:SetScript("OnMouseUp", function(_, button)
            if button ~= "RightButton" then return end
            if not Differs(db[key], ns.DEFAULTS[key]) then return end
            db[key] = ns.DEFAULTS[key]
            Changed()
        end)
    end

    local function CheckRow(def, section)
        local f = CreateFrame("Frame", nil, content)
        Label(f, def.label, section and 28 or 6)
        f:EnableMouse(true)
        Tip(f, def.label, def.tip, ns.RESET_HINT_DEFAULT)
        RowResets(f, def.key)
        local cb = CheckBox(f, COL[1], def.label, def.tip)
        cb:SetScript("OnClick", function(self)
            db[def.key] = self:GetChecked() and true or false
            Changed()
        end)
        table.insert(refreshers, function() cb:SetChecked(db[def.key] and true or false) end)
        Add(f, ROW_H, section)
    end

    local function SliderRow(def, section)
        local f = CreateFrame("Frame", nil, content)
        Label(f, def.label, section and 28 or 6)
        f:EnableMouse(true)
        Tip(f, def.label, def.tip, ns.RESET_HINT_DEFAULT)
        RowResets(f, def.key)
        local s = CreateFrame("Slider", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
        s:SetOrientation("HORIZONTAL")
        s:SetSize(150, 17)
        s:SetPoint("LEFT", f, "LEFT", COL[1], 0)
        if s.SetBackdrop then
            s:SetBackdrop({
                bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
                edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 3, right = 3, top = 6, bottom = 6 },
            })
        end
        s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        s:SetMinMaxValues(def.min, def.max)
        s:SetValueStep(def.step)
        if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
        Tip(s, def.label, def.tip, "Right-click to reset to default.")
        -- slider does get the right click, handle it here too
        s:SetScript("OnMouseUp", function(self, button)
            if button ~= "RightButton" then return end
            self:SetValue(ns.DEFAULTS[def.key] or def.min)
        end)
        local value = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        value:SetPoint("LEFT", s, "RIGHT", 10, 0)
        local function ShowValue(v)
            local text
            if def.step < 1 then
                text = ("%.2f"):format(v):gsub("0+$", ""):gsub("%.$", "")
            else
                text = tostring(math.floor(v + 0.5))
            end
            value:SetText(text .. def.unit)
        end
        s:SetScript("OnValueChanged", function(_, v)
            v = math.floor(v / def.step + 0.5) * def.step
            ShowValue(v)
            if refreshing or db[def.key] == v then return end
            db[def.key] = v
            Changed()
        end)
        table.insert(refreshers, function()
            local v = db[def.key] or def.min
            if def.key == "alpha" and v > 0 and v < 1 then v = v * 100 end  -- old 0..1 saves
            s:SetValue(v)
            ShowValue(v)
        end)
        Add(f, 32, section)
    end

    local sectionAccessors = {}

    local function ColumnAll(section, col)
        local list = sectionAccessors[section]
        if not list or #list == 0 then return false end
        for _, accessor in ipairs(list) do
            if not ns.ColumnShown(accessor, col) then return false end
        end
        return true
    end

    local function ColumnStrip(section)
        local f = CreateFrame("Frame", nil, content)
        local selectAll = section.rows ~= nil
        for i, col in ipairs(COLUMN_TIPS) do
            local hit = CreateFrame("Frame", nil, f)
            hit:SetSize(74, 18)
            hit:SetPoint("TOPLEFT", f, "TOPLEFT", COL[i] - 25, 0)
            local fs = hit:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            fs:SetAllPoints()
            fs:SetText(col[1])
            hit:EnableMouse(true)
            Tip(hit, col[1], col[2])
            if selectAll then
                local cb = ns.CheckBox(f, COL[i], "All: " .. col[1],
                    "Checks this column for every row in the section, or clears it if they are all checked.")
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", f, "TOPLEFT", COL[i], -18)
                cb:SetScript("OnClick", function()
                    local on = not ColumnAll(section, i)
                    for _, accessor in ipairs(sectionAccessors[section] or {}) do
                        ns.SetColumn(accessor, i, on)
                    end
                    Changed()
                end)
                table.insert(refreshers, function() cb:SetChecked(ColumnAll(section, i)) end)
            end
        end
        if selectAll then
            local all = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            all:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -22)
            all:SetText("Select all")
        end
        Add(f, selectAll and 42 or 18, section)
    end

    local function ElementRow(def, section)
        local accessor = ns.KeyAccessor(db, def.key)
        if def.frame and not _G[def.frame] then
            accessor.disabled = true
        else
            sectionAccessors[section] = sectionAccessors[section] or {}
            table.insert(sectionAccessors[section], accessor)
        end
        local f = ns.ElementRow(content, def.label, def.tip, accessor, Changed)
        table.insert(refreshers, f.Refresh)
        Add(f, ROW_H, section)
    end

    local function SectionControls(parent, section, spec)
        spec = spec or {
            count = function() return SectionChangedCount(db, section) end,
            reset = function() ResetSection(db, section) end,
            tip = "Puts this section back to the defaults it shipped with. Frames listed under \"Frames by addon\" keep their own settings; reset those there.",
            noneTip = "Everything in this section is already at its default.",
        }
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(60, 20)
        btn:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
        btn:SetText("Reset")
        -- disabled button swallows the mouse but never fires OnEnter, no tooltip
        if btn.SetMotionScriptsWhileDisabled then btn:SetMotionScriptsWhileDisabled(true) end
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:IsEnabled() then
                GameTooltip:SetText("Reset " .. section.title)
                GameTooltip:AddLine(spec.tip, 1, 1, 1, true)
            else
                GameTooltip:SetText("Nothing to reset")
                GameTooltip:AddLine(spec.noneTip, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            spec.reset()
            Changed()
        end)
        table.insert(refreshers, function()
            local n = spec.count()
            section.SetTitle(n > 0 and ((" (%d changed)"):format(n)) or "")
            btn:SetEnabled(n > 0)
        end)
    end

    local function SectionHeader(section, spec)
        local b = CreateFrame("Button", nil, content)
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", b, "LEFT", 6, 0)
        local fs = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        section.SetTitle = function(suffix) fs:SetText(section.title .. (suffix or "")) end
        section.SetTitle()
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        local line = b:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 0.15)
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
        section.SetIcon = function()
            icon:SetTexture(section.expanded and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
        end
        section.SetIcon()
        b:SetScript("OnClick", function()
            section.expanded = not section.expanded
            section.SetIcon()
            if section.onExpand then section.onExpand() end
            Relayout()
        end)
        section.item = Add(b, 28)
        if section.rows or spec then SectionControls(b, section, spec) end
    end

    local _, keysItem = Heading("Keys")
    Note("Set these in Blizzard's key bindings, under AddOns > Alt+Z Forever. Nothing here changes a binding: the addon never takes a key by itself.")
    local keyValues, keyLabelW = {}, 0
    for _, binding in ipairs(ns.BINDINGS) do
        local f = CreateFrame("Frame", nil, content)
        local fs = Label(f, binding.label, 6)
        keyLabelW = math.max(keyLabelW, fs:GetStringWidth())
        f:EnableMouse(true)
        Tip(f, binding.label, "Listed in Blizzard's key bindings as \""
            .. (_G["BINDING_NAME_" .. binding.name] or binding.name) .. "\", under AddOns > Alt+Z Forever.")
        local value = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        keyValues[#keyValues + 1] = value
        table.insert(refreshers, function()
            local keys = ns.BindingKeys(binding.name)
            value:SetText(keys or "not set")
            if keys then value:SetTextColor(1, 0.82, 0) else value:SetTextColor(0.6, 0.6, 0.6) end
        end)
        Add(f, ROW_H)
    end
    local keyCol = math.max(COL[1], keyLabelW + 6 + 24)
    for _, value in ipairs(keyValues) do
        value:SetPoint("LEFT", value:GetParent(), "LEFT", keyCol, 0)
    end

    local keyButtonRow = CreateFrame("Frame", nil, content)
    local openKeys = CreateFrame("Button", nil, keyButtonRow, "UIPanelButtonTemplate")
    openKeys:SetSize(150, 22)
    openKeys:SetPoint("LEFT", keyButtonRow, "LEFT", 6, 0)
    openKeys:SetText("Open key bindings")
    openKeys:SetScript("OnClick", function()
        if ns.OpenKeyBindings() then
            win:Hide()
        else
            print("Alt+Z Forever: open key bindings yourself with Esc > Options > Key Bindings, then AddOns > Alt+Z Forever.")
        end
    end)
    Add(keyButtonRow, 36)
    Add(CreateFrame("Frame", nil, content), 10)

    local generalHeading, generalItem, generalTitle = Heading("General")
    Note("Changes apply as soon as you click. WoW writes them to disk when you /reload or log out, so a game crash loses changes made since then.")
    for _, def in ipairs(GENERAL) do
        if def.kind == "slider" then SliderRow(def) else CheckRow(def) end
    end
    local generalSection = { title = "General", rows = GENERAL }
    generalSection.SetTitle = function(suffix) generalTitle:SetText(generalSection.title .. (suffix or "")) end
    SectionControls(generalHeading, generalSection)
    Add(CreateFrame("Frame", nil, content), 10)

    local _, aboutItem = Heading("About")
    Note("Select the link, then Ctrl+C to copy it.")
    local function LinkRow(label, url)
        local f = CreateFrame("Frame", nil, content)
        Label(f, label, 6)
        local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        edit:SetSize(340, 20)
        edit:SetPoint("LEFT", f, "LEFT", 100, 0)
        edit:SetAutoFocus(false)
        edit:SetText(url)
        edit:SetCursorPosition(0)
        edit:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText(url)
                self:HighlightText()
            end
        end)
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local pick = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        pick:SetSize(70, 22)
        pick:SetPoint("LEFT", edit, "RIGHT", 8, 0)
        pick:SetText("Select")
        pick:SetScript("OnClick", function()
            edit:SetFocus()
            edit:HighlightText()
        end)
        Add(f, 28)
    end
    LinkRow("CurseForge", CURSEFORGE_URL)
    Add(CreateFrame("Frame", nil, content), 10)

    local bar, barItem = Heading("Elements")
    bar:SetHeight(40)
    barItem.height = 40
    local function SetAll(expanded)
        for _, section in ipairs(SECTIONS) do
            section.expanded = expanded
            section.SetIcon()
        end
        ADVANCED.expanded = expanded
        if ADVANCED.SetIcon then ADVANCED.SetIcon() end
        if expanded then RebuildAdvanced() end
        Relayout()
    end
    local collapse = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    collapse:SetSize(90, 20)
    collapse:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 4)
    collapse:SetText("Collapse all")
    collapse:SetScript("OnClick", function() SetAll(false) end)
    local expand = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    expand:SetSize(90, 20)
    expand:SetPoint("RIGHT", collapse, "LEFT", -6, 0)
    expand:SetText("Expand all")
    expand:SetScript("OnClick", function() SetAll(true) end)

    for _, section in ipairs(SECTIONS) do
        section.expanded = false
        SectionHeader(section)
        Note(section.note, section)
        if section.group then
            CheckRow({ key = section.id .. "HoverGroup", label = "Hover one, show all", tip = section.group }, section)
        end
        if section.id then
            SliderRow({ key = section.id .. "HoverLinger", label = "Keep showing after hover", min = 0, max = 15, step = 1, unit = " s",
                tip = "Seconds a hover reveal keeps showing after the mouse leaves. 0 fades at once." }, section)
            CheckRow({ key = section.id .. "HoverSnapOut", label = "Then hide at once",
                tip = "When the stay-up time ends, hide instantly instead of fading out." }, section)
        end
        for _, def in ipairs(section.rows) do
            if not def.kind then ColumnStrip(section) break end
        end
        for _, def in ipairs(section.rows) do
            if def.kind == "slider" then
                SliderRow(def, section)
            elseif def.kind == "check" then
                CheckRow(def, section)
            else
                ElementRow(def, section)
            end
        end
        Add(CreateFrame("Frame", nil, content), 8, section)
    end

    -- rows cached by frame name, frames can't be destroyed
    local advRows, advExtras = {}, {}

    local function AdvancedExtra(kind, height, text, heading)
        local f = advExtras[kind]
        if not f then
            f = CreateFrame("Frame", nil, content)
            if heading then
                local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                fs:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 5)
                fs:SetText(text)
                local line = f:CreateTexture(nil, "ARTWORK")
                line:SetColorTexture(1, 1, 1, 0.08)
                line:SetHeight(1)
                line:SetPoint("BOTTOMLEFT", fs, "BOTTOMRIGHT", 8, 4)
                line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 5)
            elseif text then
                local fs = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                fs:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -4)
                fs:SetWidth(WIDTH - 40)
                fs:SetJustifyH("LEFT")
                fs:SetText(text)
            end
            advExtras[kind] = f
        end
        Add(f, height, ADVANCED).dynamic = true
    end

    function RebuildAdvanced()
        for i = #items, 1, -1 do
            if items[i].dynamic then
                -- out of the layout now, hide it here
                items[i].frame:Hide()
                table.remove(items, i)
            end
        end
        local list = ns.NamedSweepFrames and ns.NamedSweepFrames() or {}
        local lastOwner
        for _, entry in ipairs(list) do
            if entry.owner ~= lastOwner then
                lastOwner = entry.owner
                AdvancedExtra("head:" .. entry.owner, 22, entry.owner, true)
            end
            local row = advRows[entry.name]
            if not row then
                local group = GROUP_LABELS[entry.group] or entry.group
                row = ns.ElementRow(content, entry.name,
                    ("Follows %s until you change it here. Reset clears these four, and it follows the group again."):format(group),
                    ns.OverrideAccessor(db, entry.name, entry.group), Changed, { resetButton = true })
                table.insert(refreshers, row.Refresh)
                advRows[entry.name] = row
            end
            row.SetLabel(entry.name .. (entry.loaded and "" or " |cff808080(not loaded)|r"))
            Add(row, ROW_H, ADVANCED).dynamic = true
        end
        if #list == 0 then
            AdvancedExtra("empty", 34, "Nothing here yet. Frames are listed once they have been on screen this session.")
        end
        AdvancedExtra("spacer", 8)
        Refresh()
        Relayout()
    end

    ADVANCED.expanded = false
    ADVANCED.onExpand = function() if ADVANCED.expanded then RebuildAdvanced() end end
    SectionHeader(ADVANCED, {
        count = function()
            local n = 0
            for name in pairs(db.frameOverrides or {}) do
                if ns.HasOverride(db, name) then n = n + 1 end
            end
            return n
        end,
        reset = function()
            db.frameOverrides = db.frameOverrides or {}
            wipe(db.frameOverrides)
            if RebuildAdvanced then RebuildAdvanced() end
        end,
        tip = "Clears the settings you have given individual frames here. Every frame goes back to following its group above. The sections' own settings are not touched.",
        noneTip = "No frame here has settings of its own: they all follow their group above.",
    })
    Note(ADVANCED.note, ADVANCED)
    ColumnStrip(ADVANCED)

    local navY = 0
    local function NavLink(text, onClick)
        local b = CreateFrame("Button", nil, nav)
        b:SetSize(NAV_W - 8, 22)
        b:SetPoint("TOPLEFT", nav, "TOPLEFT", 0, -navY)
        local fs = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fs:SetPoint("LEFT", b, "LEFT", 6, 0)
        fs:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        fs:SetText(text)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        b:SetScript("OnClick", onClick)
        navY = navY + 24
    end
    NavLink("Keys", function() ScrollTo(keysItem) end)
    NavLink("General", function() ScrollTo(generalItem) end)
    NavLink("About", function() ScrollTo(aboutItem) end)
    local function NavSection(section)
        NavLink(section.title, function()
            if not section.expanded then
                section.expanded = true
                section.SetIcon()
                if section.onExpand then section.onExpand() end
                Relayout()
            end
            ScrollTo(section.item)
        end)
    end
    for _, section in ipairs(SECTIONS) do NavSection(section) end
    NavSection(ADVANCED)

    StaticPopupDialogs["ALTZFOREVER_RELOAD"] = {
        text = "Reload now to save your Alt+Z Forever settings to disk? They are also saved when you log out.",
        button1 = RELOADUI or "Reload", button2 = LATER or "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    win:SetScript("OnShow", function()
        if ADVANCED.expanded then RebuildAdvanced() else Refresh() end
    end)
    win:SetScript("OnHide", function()
        if dirty then
            dirty = false
            StaticPopup_Show("ALTZFOREVER_RELOAD")
        end
    end)
    Relayout()

    ns.RefreshSettings = function() if win:IsShown() then Refresh() end end
    ns.ToggleSettings = function() win:SetShown(not win:IsShown()) end

    pcall(function()
        local panel = CreateFrame("Frame")
        local t = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        t:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
        t:SetText("Alt+Z Forever")
        local d = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
        d:SetText("Settings live in their own window. You can also type /azf.")
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(140, 24)
        b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
        b:SetText("Open settings")
        b:SetScript("OnClick", function()
            if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
            win:Show()
        end)
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Alt+Z Forever")
        Settings.RegisterAddOnCategory(category)
    end)
end
