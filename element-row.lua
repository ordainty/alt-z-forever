-- Alt+Z Forever: element row, a label plus the four switches

local _, ns = ...

local COL = { 240, 315, 390, 465 } -- x of the four switch columns (horizontal layout)
local ROW_H = 26
ns.ELEMENT_ROW_COL = COL
ns.ELEMENT_ROW_H = ROW_H

local VERT_W = 246
local VERT_ROW_H = 24
local VERT_TITLE_H = 22
ns.ELEMENT_ROW_VERT_W = VERT_W

local COLUMN_TIPS = {
    { "Always shown", "Checked: this element never fades." },
    { "In combat", "Checked: shows during combat. Unchecked: stays faded in combat unless hovered." },
    { "Standing still", "Checked: shows when you stop moving (out of combat)." },
    { "Moving", "Checked: shows while you move (out of combat)." },
}
ns.ELEMENT_ROW_COLUMN_TIPS = COLUMN_TIPS

local STACKED_LABELS = { "Always shown", "Shows in combat", "Shows when standing still", "Shows while moving" }

function ns.Tip(frame, title, text, hint)
    if not text and not hint then return end
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
        if hint then GameTooltip:AddLine(hint, 0.6, 0.6, 0.6, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- unticked stores nil not false, both mean off
function ns.Differs(now, default)
    if type(now) == "number" or type(default) == "number" then return now ~= default end
    return (now and true or false) ~= (default and true or false)
end

function ns.CheckBox(parent, x, title, tip, hint)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", parent, "LEFT", x, 0)
    ns.Tip(cb, title, tip, hint)
    return cb
end

local function StackedCheckBox(parent, y, title, tip, hint)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    fs:SetText(title)
    ns.Tip(cb, title, tip, hint)
    return cb
end

-- checkboxes on this client don't get right-click at all,
-- so it goes on the row name (a plain frame)
ns.RESET_HINT_DEFAULT = "Right-click the row title to reset to default."
ns.RESET_HINT_INHERIT = "Right-click the row title to go back to following the group."

function ns.SetFades(accessor, fades)
    accessor.setFades(fades)
end

function ns.SetColumn(accessor, col, on)
    if col == 1 then
        ns.SetFades(accessor, not on)
    elseif col == 2 then
        accessor.setCombat(not on)
        if on then accessor.setFades(true) end
    elseif col == 3 then
        accessor.setIdle(on)
        if on then accessor.setFades(true) end
    else
        accessor.setMove(on)
        if on then accessor.setFades(true) end
    end
end

function ns.ColumnShown(accessor, col)
    local fades, combatFades, idleShown, moveShown = accessor.get()
    if col == 1 then return not fades end
    if not fades then return false end
    if col == 2 then return not combatFades end
    if col == 3 then return idleShown and true or false end
    return moveShown and true or false
end

function ns.KeyAccessor(db, key)
    db.idleShow = db.idleShow or {}
    db.moveShow = db.moveShow or {}
    local combatKey = key .. "ConcealDuringCombat"
    return {
        get = function()
            return db[key] and true or false, db[combatKey], db.idleShow[key], db.moveShow[key]
        end,
        setFades = function(v) db[key] = v end,
        setCombat = function(v) db[combatKey] = v end,
        setIdle = function(v) db.idleShow[key] = v or nil end,
        setMove = function(v) db.moveShow[key] = v or nil end,
        reset = function()
            local d = ns.DEFAULTS
            db[key] = d[key]
            db[combatKey] = d[combatKey]
            db.idleShow[key] = d.idleShow[key]
            db.moveShow[key] = d.moveShow[key]
        end,
        overridden = function()
            local d = ns.DEFAULTS
            return ns.Differs(db[key], d[key])
                or ns.Differs(db[combatKey], d[combatKey])
                or ns.Differs(db.idleShow[key], d.idleShow[key])
                or ns.Differs(db.moveShow[key], d.moveShow[key])
        end,
        resetHint = ns.RESET_HINT_DEFAULT,
        resetTip = { "Reset to default", "Puts this element's four switches back to the ones the addon shipped with." },
        resetNoneTip = { "Nothing to reset", "This element is already set the way the addon shipped it." },
    }
end

function ns.HasOverride(db, frameName)
    local row = db.frameOverrides and db.frameOverrides[frameName]
    return row ~= nil and (row.fades ~= nil or row.combat ~= nil or row.idle ~= nil or row.move ~= nil)
end

function ns.OverrideAccessor(db, frameName, groupKey)
    db.frameOverrides = db.frameOverrides or {}
    local groupAccessor = ns.KeyAccessor(db, groupKey)
    local function Row()
        db.frameOverrides[frameName] = db.frameOverrides[frameName] or {}
        return db.frameOverrides[frameName]
    end
    local function Overridden() return ns.HasOverride(db, frameName) end
    return {
        get = function()
            local row = db.frameOverrides[frameName]
            local gFades, gCombat, gIdle, gMove = groupAccessor.get()
            if not row then return gFades, gCombat, gIdle, gMove end
            local fades = row.fades; if fades == nil then fades = gFades end
            local combat = row.combat; if combat == nil then combat = gCombat end
            local idle = row.idle; if idle == nil then idle = gIdle end
            local move = row.move; if move == nil then move = gMove end
            return fades, combat, idle, move
        end,
        setFades = function(v) Row().fades = v end,
        setCombat = function(v) Row().combat = v end,
        -- false, not nil, or nil would mean inherit from the group
        setIdle = function(v) Row().idle = v and true or false end,
        setMove = function(v) Row().move = v and true or false end,
        overridden = Overridden,
        reset = function() db.frameOverrides[frameName] = nil end,
        resetHint = ns.RESET_HINT_INHERIT,
        resetTip = { "Reset to group default", "Clears this element's own settings; it follows its group again." },
        resetNoneTip = { "Nothing to reset", "This element has no settings of its own yet: it already follows its group." },
    }
end

function ns.ElementRow(parent, label, tip, accessor, onChange, opts)
    local vertical = opts and opts.vertical
    local f = CreateFrame("Frame", nil, parent)
    local fs = f:CreateFontString(nil, "ARTWORK", vertical and "GameFontNormal" or "GameFontHighlight")
    if vertical then
        f:SetWidth(VERT_W)
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
        fs:SetWidth(VERT_W - 16)
        fs:SetJustifyH("LEFT")
    else
        f:SetHeight(ROW_H)
        fs:SetPoint("LEFT", f, "LEFT", 28, 0)
    end
    fs:SetText(label)
    f.SetLabel = function(text) fs:SetText(text) end

    if accessor.disabled then
        fs:SetFontObject("GameFontDisable")
        local dfs = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        dfs:SetText(accessor.disabledText or "not on this client")
        if vertical then
            dfs:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -VERT_TITLE_H - 6)
            f:SetHeight(VERT_TITLE_H + 28)
        else
            dfs:SetPoint("LEFT", f, "LEFT", COL[1], 0)
        end
        f.Refresh = function() end
        return f
    end

    if not vertical then
        local hint = accessor.reset and accessor.resetHint or nil
        if tip or hint then
            f:EnableMouse(true)
            ns.Tip(f, label, tip, hint)
        end
        if accessor.reset then
            f:SetScript("OnMouseUp", function(_, button)
                if button ~= "RightButton" then return end
                if accessor.overridden and not accessor.overridden() then return end
                accessor.reset()
                if onChange then onChange() end
            end)
        end
    end

    local always, combat, idle, move
    if vertical then
        local top = -VERT_TITLE_H - 4
        always = StackedCheckBox(f, top, STACKED_LABELS[1], COLUMN_TIPS[1][2])
        combat = StackedCheckBox(f, top - VERT_ROW_H, STACKED_LABELS[2], COLUMN_TIPS[2][2])
        idle = StackedCheckBox(f, top - VERT_ROW_H * 2, STACKED_LABELS[3], COLUMN_TIPS[3][2])
        move = StackedCheckBox(f, top - VERT_ROW_H * 3, STACKED_LABELS[4], COLUMN_TIPS[4][2])
    else
        always = ns.CheckBox(f, COL[1], COLUMN_TIPS[1][1], COLUMN_TIPS[1][2])
        combat = ns.CheckBox(f, COL[2], STACKED_LABELS[2], COLUMN_TIPS[2][2])
        idle = ns.CheckBox(f, COL[3], STACKED_LABELS[3], COLUMN_TIPS[3][2])
        move = ns.CheckBox(f, COL[4], STACKED_LABELS[4], COLUMN_TIPS[4][2])
    end

    local function Fire()
        if onChange then onChange() end
    end

    local function Switch(cb, onLeft)
        cb:SetScript("OnClick", function(self)
            onLeft(self)
            Fire()
        end)
    end

    for col, cb in ipairs({ always, combat, idle, move }) do
        Switch(cb, function(self) ns.SetColumn(accessor, col, self:GetChecked() and true or false) end)
    end

    local resetBtn
    if accessor.reset and (vertical or (opts and opts.resetButton)) then
        resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetSize(vertical and 110 or 60, 20)
        if vertical then
            resetBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -VERT_TITLE_H - 8 - VERT_ROW_H * 4)
        else
            -- clear of the last switch, inside the page
            resetBtn:SetPoint("LEFT", f, "LEFT", COL[4] + 40, 0)
        end
        resetBtn:SetText("Reset")
        -- a disabled button swallows the mouse but never fires OnEnter, no tooltip
        if resetBtn.SetMotionScriptsWhileDisabled then
            resetBtn:SetMotionScriptsWhileDisabled(true)
        end
        resetBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local t = self:IsEnabled() and accessor.resetTip or accessor.resetNoneTip
            if t then
                GameTooltip:SetText(t[1])
                GameTooltip:AddLine(t[2], 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        resetBtn:SetScript("OnClick", function()
            accessor.reset()
            Fire()
        end)
    end

    if vertical then
        f:SetHeight(VERT_TITLE_H + 4 + VERT_ROW_H * 4 + (resetBtn and 30 or 0) + 8)
    end

    f.Refresh = function()
        always:SetChecked(ns.ColumnShown(accessor, 1))
        combat:SetChecked(ns.ColumnShown(accessor, 2))
        idle:SetChecked(ns.ColumnShown(accessor, 3))
        move:SetChecked(ns.ColumnShown(accessor, 4))
        if resetBtn then
            resetBtn:SetEnabled(accessor.overridden and accessor.overridden() or false)
        end
    end
    return f
end
