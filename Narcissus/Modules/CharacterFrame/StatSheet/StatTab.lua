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
    StatSheetAPI.ReleaseResistanceDisplay();

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
            button.index = i;
        end

        self:FullUpdate();
        self:SaveDefaultTabKey(tabKey);
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

function StatTabMixin:SaveDefaultTabKey(tabKey)
    if NarcissusDB_PC then
        NarcissusDB_PC.StatTabDefaultTab = tabKey;
    end
end

function StatTabMixin:GetDefaultTabKey()
    local tabKey = NarcissusDB_PC and NarcissusDB_PC.StatTabDefaultTab;
    local tabInfo = StatSheetAPI.StatTabInfo;

    if tabKey and tabInfo then
        local valid = false;
        for _, v in ipairs(tabInfo) do
            if tabKey == v.key then
                valid = true;
                break;
            end
        end
        if not valid then
            tabKey = nil;
        end
    end

    if not tabKey then
        local _, class = UnitClass("player");
		if class == "MAGE" or class == "PRIEST" or class == "WARLOCK" or class == "DRUID" then
			tabKey = "Spell";
		elseif class == "HUNTER" then
			tabKey = "Ranged";
		else
			tabKey = "Melee";
		end
    end

    return tabKey;
end

function StatTabMixin:SetIntroAnimationDelay(fromDelay, secondsPerRow)
    self.HeaderFrame.animIn.A2:SetStartDelay(fromDelay);
    for statButton in self.statButtonPool:EnumerateActive() do
        statButton.animIn.A2:SetStartDelay(fromDelay + statButton.index * secondsPerRow);
    end
end

function StatTabMixin:PlayIntroAnimation()
    self.HeaderFrame.animIn:Play();
    for statButton in self.statButtonPool:EnumerateActive() do
        statButton.animIn:Play();
    end
end


function StatSheetAPI.CreateStatTab(parent)
    local frame = CreateFrame("Frame", nil, parent);

    local enableBackground = false;
    local enableDivider = false;
    addon.CreateTabSystem(frame, enableBackground, enableDivider);

    local HeaderFrame = CreateFrame("Frame", nil, frame);
    frame.HeaderFrame = HeaderFrame;
    HeaderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    HeaderFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -24);
    HeaderFrame.animIn = HeaderFrame:CreateAnimationGroup(nil, "NarciAttributeFadeInAnimationTemplate");
    frame:SetTabButtonContainer(HeaderFrame);

    local Background = HeaderFrame:CreateTexture(nil, "BACKGROUND");
    Background:SetColorTexture(0.08, 0.08, 0.08, 0.9);
    Background:SetAllPoints(HeaderFrame);

    Mixin(frame, StatTabMixin);

    frame.tabKeyXStatLayout = {};
    frame.statButtonPool = CreateFramePool("Button", frame, "Narci_AttributeTemplate");
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

    if frame:IsVisible() then
        frame:OnShow();
    end

    frame:SetDefaultTabKey(frame:GetDefaultTabKey());

    return frame;
end
