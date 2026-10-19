-- Forever: Melee / Ranged / Spell / Defense Tabs

local _, addon = ...
local StatSheetAPI = addon.StatSheetAPI; ---@class StatSheetAPI


local StatTabMixin = {};

function StatTabMixin:Update()
    for statButton in self.statButtonPool:EnumerateActive() do
        statButton:Update();
    end
end

function StatTabMixin:SetRow(row)
    self.row = row;
end

function StatTabMixin:GetRow()
    return self.row or 1;
end

function StatTabMixin:OnTabSelected(tabKey)
    self.statButtonPool:ReleaseAll();
    local layout = self.tabKeyXStatLayout[tabKey];

    if layout then
        local buttonHeight = 24;
        local baseRow = self:GetRow();

        -- Make sure the first stat button's row is an even number
        -- so that it's background is brighter
        if baseRow % 2 == 0 then
            baseRow = baseRow + 1;
        end

        for i, token in ipairs(layout) do
            local button = self.statButtonPool:Acquire();
            button:SetPoint("TOP", self, "TOP", 0, -i * buttonHeight);
            button:SetToken(token);
            button:SetRow(baseRow + i);
            button:Show();
        end

        self:Update();
    end

    local lastTabButton = self:GetLastTabButton();
    if lastTabButton then
        lastTabButton.RightDivider:Hide();
    end
end


function StatSheetAPI.CreateStatTab(parent)
    local frame = CreateFrame("Frame", nil, parent);
    local maxRow = 7;
    frame:SetSize(240, 24 * maxRow);

    local enableBackground = false;
    local enableDivider = true;
    addon.CreateTabSystem(frame, enableBackground, enableDivider);

    frame.Background = frame:CreateTexture(nil, "BACKGROUND");
    frame.Background:SetColorTexture(0.08, 0.08, 0.08, 0.9);
    frame.Background:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    frame.Background:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -24);

    Mixin(frame, StatTabMixin);

    frame.tabKeyXStatLayout = {};
    frame.statButtonPool = CreateFramePool("Button", frame, "Narci_AttributeTemplate");
    frame.animIn = frame:CreateAnimationGroup(nil, "NarciAttributeFadeInAnimationTemplate");
    frame:EnableScrollToSwitchTab(true);

    local tabInfo = StatSheetAPI.StatTabInfo;

    if tabInfo then
        for _, v in ipairs(tabInfo) do
            frame:AddTab(v.key, v.name);
            frame.tabKeyXStatLayout[v.key] = v.layout;
        end
    end

    return frame;
end
