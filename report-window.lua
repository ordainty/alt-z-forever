-- Alt+Z Forever: bug report window, copy the issue link and report text

local _, ns = ...

local ISSUE_URL = "https://github.com/ordainty/alt-z-forever/issues/new?template=bug.yml"
local WIDTH, HEIGHT = 580, 460

local win, link, box, scroll
local reportText = ""

-- read-only, typing puts the text back
local function ReadOnly(edit, getText)
    edit:SetAutoFocus(false)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(getText())
            self:HighlightText()
        end
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
end

local function SelectAll(edit)
    edit:SetFocus()
    edit:HighlightText()
end

local function Text(anchor, text, y)
    local t = win:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    t:SetPoint("TOPLEFT", anchor, anchor == win and "TOPLEFT" or "BOTTOMLEFT", anchor == win and 16 or 0, y)
    t:SetWidth(WIDTH - 32)
    t:SetJustifyH("LEFT")
    t:SetText(text)
    return t
end

local function Button(text, width, onClick)
    local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Create()
    win = CreateFrame("Frame", "AltZForeverReport", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(WIDTH, HEIGHT)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "AltZForeverReport")
    local titleText = win.TitleText
    if not titleText then
        titleText = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleText:SetPoint("TOP", win, "TOP", 0, -5)
    end
    titleText:SetText("Alt+Z Forever: report a bug")

    local step1 = Text(win, "1. Copy this link into your browser. Filing an issue needs a free GitHub account.", -34)

    link = CreateFrame("EditBox", nil, win, "InputBoxTemplate")
    link:SetSize(WIDTH - 150, 20)
    link:SetPoint("TOPLEFT", step1, "BOTTOMLEFT", 6, -6)
    link:SetText(ISSUE_URL)
    link:SetCursorPosition(0)
    ReadOnly(link, function() return ISSUE_URL end)
    local copyLink = Button("Select link", 100, function() SelectAll(link) end)
    copyLink:SetPoint("LEFT", link, "RIGHT", 8, 0)

    local step2 = Text(step1, "2. Say what happened, then paste this report into the Report box. "
        .. "It has your settings and addon list, no account or character names.", -38)
    local step3 = Text(step2, "If a frame fades when it shouldn't (or the other way round), point at it, "
        .. "type /azf under, then click Refresh.", -6)
    step3:SetTextColor(0.8, 0.8, 0.8)

    scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", step3, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -34, 42)
    local bg = win:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetColorTexture(0, 0, 0, 0.5)
    bg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -4, 4)
    bg:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, -4)

    box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetFontObject(ChatFontNormal)
    box:SetWidth(WIDTH - 60)
    box:SetHeight(200)
    ReadOnly(box, function() return reportText end)
    scroll:SetScrollChild(box)
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function() SelectAll(box) end)

    local selectReport = Button("Select report", 120, function() SelectAll(box) end)
    selectReport:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    local refresh = Button("Refresh", 90, function() ns.ShowReport() end)
    refresh:SetPoint("LEFT", selectReport, "RIGHT", 8, 0)
    local hint = win:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
    hint:SetText("Then Ctrl+C to copy.")
    local close = Button(CLOSE or "Close", 90, function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)
end

function ns.ShowReport()
    if not win then Create() end
    local ok, text = pcall(ns.BuildReport)
    reportText = ok and text or ("The report failed to build: " .. tostring(text))
    box:SetText(reportText)
    box:SetCursorPosition(0)
    box:ClearFocus()
    win:Show()
    scroll:SetVerticalScroll(0)
end
