-- Alt+Z Forever: minimap button, opens the settings window

local _, ns = ...

local ICON = "Interface\\AddOns\\alt-z-forever\\icon.tga"

local button

local function Place()
    local angle = math.rad(ns.DB()["minimapButtonAngle"] or ns.DEFAULTS.minimapButtonAngle)
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    ns.DB()["minimapButtonAngle"] = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
    Place()
end

-- child of Minimap, so it fades with the minimap
local function Create()
    button = CreateFrame("Button", "AltZForeverMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    -- the ring sits in the top left of its texture, 50 wide centres it on the button
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function()
        if ns.ToggleSettings then ns.ToggleSettings() end
    end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Alt+Z Forever")
        GameTooltip:AddLine("Select to open the settings.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move the button.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.UpdateMinimapButton()
    local db = ns.DB()
    if not db or not Minimap then return end
    if not db["minimapButton"] then
        if button then button:Hide() end
        return
    end
    if not button then Create() end
    Place()
    button:Show()
end
