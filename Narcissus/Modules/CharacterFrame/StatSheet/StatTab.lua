-- Forever: Melee / Ranged / Spell / Defense Tabs

local _, addon = ...
local StatSheetAPI = addon.StatSheetAPI; ---@class StatSheetAPI
local PrivateAPI = addon.PrivateAPI; ---@type NarcissusPrivateAPI


local StatTabMixin = {};

function StatTabMixin:Update()
    self:RequestFullUpdate();
end

function StatTabMixin:FullUpdate()
    self.isStatDirty = nil;
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

        self:FullUpdate();
    end

    local lastTabButton = self:GetLastTabButton();
    if lastTabButton then
        lastTabButton.RightDivider:Hide();
    end
end

local DynamicEvents = {
    PLAYER_EQUIPMENT_CHANGED = true,
    SKILL_LINES_CHANGED = true,
    SPELL_POWER_CHANGED = true,
};

local DynamicUnitEvents = {
    UNIT_ATTACK = true,
    UNIT_RANGED_ATTACK_POWER = true,
    UNIT_RANGEDDAMAGE = true,
    UNIT_RESISTANCES = true,
    UNIT_SPELL_HASTE = true,
    UNIT_STATS = true,
};

function StatTabMixin:RequestFullUpdate()
    if self.t then
        if not self.isStatDirty then
            self.statChangedAfterUpdate = true;
        end
        self.t = 0;
    else
        self.isStatDirty = true;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_FullUpdate);
    end
end

function StatTabMixin:OnUpdate_FullUpdate(elapsed)
    self.t = self.t + elapsed;

    if self.isStatDirty then
        self:FullUpdate();
    end

    if self.t > 0.2 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        if self.statChangedAfterUpdate then
            self.statChangedAfterUpdate = nil;
            self:FullUpdate();
        end
    end
end

function StatTabMixin:OnEvent(event, ...)
    self:RequestFullUpdate();
end

function StatTabMixin:OnShow()
    PrivateAPI.RegisterFrameForEvents(self, DynamicEvents);
    PrivateAPI.RegisterFrameForUnitEvents(self, DynamicUnitEvents);
end

function StatTabMixin:OnHide()
    PrivateAPI.UnregisterFrameForEvents(self, DynamicEvents, DynamicUnitEvents);
end


function StatSheetAPI.CreateStatTab(parent)
    local frame = CreateFrame("Frame", nil, parent);

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

    local maxRow = 1;
    local tabInfo = StatSheetAPI.StatTabInfo;

    if tabInfo then
        for _, v in ipairs(tabInfo) do
            frame:AddTab(v.key, v.name);
            frame.tabKeyXStatLayout[v.key] = v.layout;
            if #v.layout > maxRow then
                maxRow = #v.layout;
            end
        end
    end

    frame:SetSize(240, 24 * (1 + maxRow));
    frame:SetScript("OnEvent", frame.OnEvent);
    frame:SetScript("OnShow", frame.OnShow);
    frame:SetScript("OnHide", frame.OnHide);

    return frame;
end
