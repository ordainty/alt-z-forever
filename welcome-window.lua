-- Alt+Z Forever: welcome window, shown once on first login

local _, ns = ...

local DOCS_URL = "https://ordainty.github.io/alt-z-forever"
local WIDTH = 500
local PAD = 16
local ROW_H = 18

local win
local refreshers = {}

local function Button(text, width, onClick)
    local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Create()
    win = CreateFrame("Frame", "AltZForeverWelcome", UIParent, "BasicFrameTemplateWithInset")
    win:SetWidth(WIDTH)
    win:SetPoint("CENTER", 0, 60)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "AltZForeverWelcome")
    local titleText = win.TitleText
    if not titleText then
        titleText = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleText:SetPoint("TOP", win, "TOP", 0, -5)
    end
    titleText:SetText("Welcome to Alt+Z Forever")

    -- stacked top down, y tracks the next free line
    local y = -36
    local function Text(text, gap, font)
        local t = win:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        y = y - gap
        t:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, y)
        t:SetWidth(WIDTH - PAD * 2)
        t:SetJustifyH("LEFT")
        t:SetText(text)
        y = y - t:GetStringHeight()
        return t
    end

    Text("Fade mode is on already, so there's nothing to set up. Your UI fades out when you start moving. "
        .. "It comes back when you point at it, pick a target or enter combat.", 0)
    Text("Type |cffffd100/azf|r or select the minimap button to open the settings, where you choose what fades and when.", 10)
    Text("Type |cffffd100/azf help|r to list every command.", 6)

    Text("Keys", 16, "GameFontNormalLarge")
    Text("The addon doesn't bind any keys for you, so it can't clash with yours. "
        .. "Set the ones you want in Blizzard's key bindings, under AddOns > Alt+Z Forever.", 6)

    y = y - 8
    local labels, labelW = {}, 0
    for i, binding in ipairs(ns.BINDINGS) do
        local label = win:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 8, y)
        label:SetText(binding.label)
        labelW = math.max(labelW, label:GetStringWidth())
        labels[i] = label
        local value = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        table.insert(refreshers, function()
            local keys = ns.BindingKeys(binding.name)
            value:SetText(keys or "not set")
            if keys then value:SetTextColor(1, 0.82, 0) else value:SetTextColor(0.6, 0.6, 0.6) end
        end)
        labels[i].value = value
        y = y - ROW_H
    end
    for _, label in ipairs(labels) do
        label.value:SetPoint("LEFT", label, "LEFT", labelW + 24, 0)
    end

    Text("Change one element quickly", 12, "GameFontNormalLarge")
    Text("Point at any part of your UI, like an action bar or the minimap. "
        .. "Press the toggle key to switch it between fading and always shown. "
        .. "Press the settings key to open that element's settings at your cursor.", 6)

    Text("Full guide", 12, "GameFontNormalLarge")
    Text("The docs cover every setting, key and command. Copy this link into your browser.", 6)
    y = y - 6
    local link = CreateFrame("EditBox", nil, win, "InputBoxTemplate")
    link:SetSize(WIDTH - PAD * 2 - 116, 20)
    link:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 6, y)
    link:SetAutoFocus(false)
    link:SetText(DOCS_URL)
    link:SetCursorPosition(0)
    -- read-only, typing puts the text back
    link:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(DOCS_URL)
            self:HighlightText()
        end
    end)
    link:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    link:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local selectLink = Button("Select link", 100, function()
        link:SetFocus()
        link:HighlightText()
    end)
    selectLink:SetPoint("LEFT", link, "RIGHT", 8, 0)
    y = y - 20

    Text("Select the link, then Ctrl+C to copy. Type /azf welcome to see this again.", 8, "GameFontDisableSmall")

    local openKeys = Button("Open key bindings", 150, function()
        if ns.OpenKeyBindings() then
            win:Hide()
        else
            print("Alt+Z Forever: open key bindings yourself with Esc > Options > Key Bindings, then AddOns > Alt+Z Forever.")
        end
    end)
    openKeys:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    local openSettings = Button("Open settings", 120, function()
        win:Hide()
        if ns.ToggleSettings then ns.ToggleSettings() end
    end)
    openSettings:SetPoint("LEFT", openKeys, "RIGHT", 8, 0)
    local close = Button(CLOSE or "Close", 90, function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)

    win:SetHeight(-y + 50)
end

function ns.ShowWelcome()
    if not win then Create() end
    for _, refresh in ipairs(refreshers) do refresh() end
    ns.DB()["welcomeSeen"] = true
    win:Show()
end
