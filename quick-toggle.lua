-- Alt+Z Forever: keybind gestures, quick toggle and the card at the cursor

local _, ns = ...

local function Announce(text)
    print("Alt+Z Forever: " .. text)
    if UIErrorsFrame then UIErrorsFrame:AddMessage(text, 1, 0.82, 0) end
end

local labels
local function LabelFor(descriptor)
    if descriptor.frameName then
        local group = labels and labels[descriptor.group] or descriptor.group
        return descriptor.frameName .. " (" .. group .. ")"
    end
    if not labels then
        labels = {}
        for _, section in ipairs(ns.SETTINGS_SECTIONS or {}) do
            for _, row in ipairs(section.rows) do
                if row.kind == nil then labels[row.key] = row.label end
            end
        end
    end
    return labels[descriptor.key] or descriptor.key
end

local function AccessorFor(descriptor)
    local db = ns.DB()
    if descriptor.frameName then
        return ns.OverrideAccessor(db, descriptor.frameName, descriptor.group)
    end
    return ns.KeyAccessor(db, descriptor.key)
end

-- parent is UIParent, a child of the alpha 0 element would be invisible too
local flash
local function Flash(frame)
    if not flash then
        flash = CreateFrame("Frame", "AltZForeverFlash", UIParent)
        flash:SetFrameStrata("TOOLTIP")
        flash:EnableMouse(false)
        if flash.SetIgnoreParentAlpha then flash:SetIgnoreParentAlpha(true) end
        local fill = flash:CreateTexture(nil, "BACKGROUND")
        fill:SetAllPoints()
        fill:SetColorTexture(1, 0.82, 0, 0.2)
        for _, edge in ipairs({
            { "TOPLEFT", "TOPRIGHT", 0, 2 },
            { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 2 },
            { "TOPLEFT", "BOTTOMLEFT", 2, 0 },
            { "TOPRIGHT", "BOTTOMRIGHT", 2, 0 },
        }) do
            local t = flash:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(1, 0.82, 0, 0.9)
            t:SetPoint(edge[1])
            t:SetPoint(edge[2])
            if edge[3] > 0 then t:SetWidth(edge[3]) else t:SetHeight(edge[4]) end
        end
        local ag = flash:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(1)
        a:SetToAlpha(0)
        a:SetDuration(0.7)
        a:SetSmoothing("OUT")
        ag:SetScript("OnFinished", function() flash:Hide() end)
        flash.ag = ag
    end

    local l, _, w, h = frame:GetRect()
    if not (l and w) or w <= 0 or h <= 0 then return end
    flash.ag:Stop()
    flash:ClearAllPoints()
    flash:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    flash:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    flash:SetAlpha(1)
    flash:Show()
    flash.ag:Play()
end

local function FadeModeOffHow()
    local keys = ns.BindingKeys and ns.BindingKeys("ALTZFOREVER_TOGGLE")
    return keys and ("Press " .. keys .. " to turn it back on.") or "Type /azf on to turn it back on."
end

function AltZForever_QuickToggle()
    local hit = ns.ElementAtCursor()
    if not hit then
        Announce("nothing with settings under the cursor.")
        return
    end
    local accessor = AccessorFor(hit)
    local fades = accessor.get()
    ns.SetFades(accessor, not fades)
    ns.ApplyChange()
    Flash(hit.frame)
    local state = fades and "always shown" or "fades"
    if ns.IsEnabled and not ns.IsEnabled() then
        state = state .. " - saved, but nothing fades while fade mode is off. " .. FadeModeOffHow()
    end
    Announce(LabelFor(hit) .. ": " .. state)
end

local PAD = 10
local TITLE_H = 20

local card, shownFor
local cardRows = {}

local function RowId(descriptor)
    return descriptor.frameName and ("frame:" .. descriptor.frameName) or ("key:" .. descriptor.key)
end

local function EnsureCard()
    if card then return card end
    card = CreateFrame("Frame", "AltZForeverCard", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    card:SetFrameStrata("DIALOG")
    card:SetToplevel(true)
    card:EnableMouse(true)
    card:SetClampedToScreen(true)
    card:Hide()
    if card.SetBackdrop then
        card:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
    end
    tinsert(UISpecialFrames, "AltZForeverCard")
    local close = CreateFrame("Button", nil, card, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", card, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() card:Hide() end)
    card:SetScript("OnHide", function() shownFor = nil end)
    local hint = card:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
    hint:SetJustifyH("LEFT")
    hint:Hide()
    card.hint = hint
    return card
end

-- frames can't be destroyed, reuse the rows
local function RowFor(descriptor)
    local id = RowId(descriptor)
    local row = cardRows[id]
    if not row then
        local accessor = AccessorFor(descriptor)
        row = ns.ElementRow(card, LabelFor(descriptor), nil, accessor, function()
            ns.ApplyChange()
            cardRows[id].Refresh()
        end, { vertical = true })
        cardRows[id] = row
    end
    return row
end

function AltZForever_QuickCard()
    local hit = ns.ElementAtCursor()
    if not hit then
        Announce("nothing with settings under the cursor.")
        return
    end
    EnsureCard()
    local id = RowId(hit)
    if card:IsShown() and shownFor == id then
        card:Hide()
        return
    end
    for rowId, row in pairs(cardRows) do
        if rowId ~= id then row:Hide() end
    end
    local row = RowFor(hit)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -TITLE_H)
    row:Show()
    local hint, hintH = card.hint, 0
    if ns.IsEnabled and not ns.IsEnabled() then
        hint:ClearAllPoints()
        hint:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 4, -2)
        hint:SetWidth(row:GetWidth() - 8)
        hint:SetText("Fade mode is off. Changes here are saved, but nothing fades yet. " .. FadeModeOffHow())
        hint:Show()
        hintH = hint:GetStringHeight() + 8
    else
        hint:Hide()
    end
    card:SetSize(row:GetWidth() + PAD * 2, row:GetHeight() + TITLE_H + PAD + hintH)
    row.Refresh()

    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale + 12, cy / scale - 12)
    shownFor = id
    card:Show()
    Flash(hit.frame)
end

-- keybinding panel truncates this at about 22 chars
BINDING_NAME_ALTZFOREVER_QUICKTOGGLE = "Toggle element fade"
BINDING_NAME_ALTZFOREVER_QUICKCARD = "Element fade settings"
