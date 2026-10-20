local _, addon = ...
local PrivateAPI = addon.PrivateAPI; ---@type NarcissusPrivateAPI
local StatSheetController = addon.StatSheetController; ---@type StatSheetController
local StatSheetLayout = addon.StatSheetLayout; ---@type StatSheetLayout


--- [event] = true  -- Full Update
--- [event] = token -- Update specific stat
local DynamicEvents = {
    COMBAT_RATING_UPDATE = true,
    PLAYER_EQUIPMENT_CHANGED = true,
};

--- These events update specific stats
local DynamicUnitEvents = {
    UNIT_AURA = true,
    UNIT_STATS = true,

    UNIT_ATTACK_SPEED = "AttackSpeed",
    UNIT_DAMAGE = "Damage",
    UNIT_MAXHEALTH = "Health",
    UNIT_MAXPOWER = "Power",
};


---@class StatSheetFrame
local StatFrameMixin = {};
addon.StatFrameMixin = StatFrameMixin;

function StatFrameMixin:OnLoad()
    self.entries = {};  -- List of StatButton. Most stat buttons won't get released after being created
    self.statXEntry = {};     -- statToken to StatButton

    StatSheetController:AddStatFrame(self);
    StatSheetController:MakeFrameFadable(self);
end

function StatFrameMixin:Init()
    self.Init = nil;
    local layoutType = self.isDetailed and "Detailed" or "Concise";
    local layout = StatSheetLayout[layoutType];
    self:SetLayout(layout);
end

function StatFrameMixin:SetLayout(layout)
    local spacerHeight = 26; -- buttonHeight 24 + 2
    local n = 0;
    local row = 1;

    local function AddChild(statButton)
        if statButton.token and not self.statXEntry[statButton.token] then
            self.statXEntry[statButton.token] = statButton;
        end
    end

    if self.isDetailed then
        local addSpacer = false;
        local isLeftCol = true;
        local chartFrame, lastFrameIsChart;

        for i, token in ipairs(layout) do
            if token == "Chart" and not chartFrame then
                -- There is only one RadarChartFrame
                -- Chart's parent is not the StatFrame, since we show chart for Equipment Set Manager while hiding other stats
                local frame = CreateFrame("Frame", "Narci_RadarChartFrame", self:GetParent(), "Narci_StatsChartTemplate");
                chartFrame = frame;
                chartFrame:SetRow(row);
                StatSheetController:AssignRadarChart(frame);

                if i == 1 then -- We'll never reach here since chart will never be the first widget
                    frame:SetPoint("TOP", self, "TOP", 0, 0);
                else
                    frame:SetPoint("TOP", self.entries[n - 1], "BOTTOMRIGHT", 0, -spacerHeight);
                end

                n = n + 1;
                self.entries[n] = frame;

                isLeftCol = true;
                addSpacer = true;
                lastFrameIsChart = true;

                for _, button in ipairs(frame:GetStatButtons()) do
                    AddChild(button);
                end
            else
                local button = CreateFrame("Button", nil, self, "Narci_DetailedAttributeTemplate");
                button:SetToken(token);
                button:SetLeftColumn(isLeftCol);
                button:SetRow(row);
                AddChild(button);

                n = n + 1;
                self.entries[n] = button;

                local offsetY;
                if addSpacer then
                    offsetY = -spacerHeight;
                    addSpacer = false;
                else
                    offsetY = 0;
                end

                if i == 1 then
                    button:SetPoint("TOPRIGHT", self, "TOP", 0, 0);
                elseif lastFrameIsChart then
                    lastFrameIsChart = nil;
                    button:SetPoint("TOPRIGHT", chartFrame, "BOTTOM", 0, -spacerHeight);
                elseif isLeftCol then
                    button:SetPoint("TOPRIGHT", self.entries[n - 2], "BOTTOMRIGHT", 0, offsetY);
                else
                    button:SetPoint("TOPLEFT", self.entries[n - 1], "TOPRIGHT", 0, 0);
                    row = row + 1;
                end

                isLeftCol = not isLeftCol;
            end
        end
    else
        local addSpacer = false;

        for i, token in ipairs(layout) do
            if token == "Spacer" then
                addSpacer = true;
            elseif token == "StatTab" then
                local frame = addon.StatSheetAPI.CreateStatTab(self);
                n = n + 1;
                row = row + 1;
                self.entries[n] = frame;

                frame:SetPoint("TOP", self.entries[n - 1], "BOTTOM", 0, -spacerHeight);
                frame:SetRow(row);
                frame:Init();

            else
                local button = CreateFrame("Button", nil, self, "Narci_AttributeTemplate");
                button:SetToken(token);
                button:SetRow(row);
                row = row + 1;
                AddChild(button);

                n = n + 1;
                self.entries[n] = button;

                local offsetY;
                if addSpacer then
                    offsetY = -spacerHeight;
                    addSpacer = false;
                else
                    offsetY = 0;
                end

                if i == 1 then
                    button:SetPoint("TOP", self, "TOP", 0, 0);
                else
                    button:SetPoint("TOP", self.entries[n - 1], "BOTTOM", 0, offsetY);
                end
            end
        end
    end

    if self.animationDelay then
        self:SetIntroAnimationDelay(self.animationDelay);
    end
end

function StatFrameMixin:OnShow()
    if self.Init then
        self:Init();
    end
    PrivateAPI.RegisterFrameForEvents(self, DynamicEvents);
    PrivateAPI.RegisterFrameForUnitEvents(self, DynamicUnitEvents);
end

function StatFrameMixin:OnHide()
    PrivateAPI.UnregisterFrameForEvents(self, DynamicEvents, DynamicUnitEvents);
    self:StopAnimating();
    self:SnapToFadeResult();
end

function StatFrameMixin:OnEvent(event, ...)
    local token = DynamicEvents[event] or DynamicUnitEvents[event];
    if token then
        if token == true then
            self:RequestFullUpdate();
        else
            if not self.isStatDirty then -- not when a full update is already queued
                self:UpdateStatByToken(token);
            end
        end
    end
end

function StatFrameMixin:UpdateStatByToken(token)
    if self.statXEntry[token] then
        self.statXEntry[token]:Update();
    end
end

function StatFrameMixin:FullUpdate()
    self.isStatDirty = nil;
    for _, button in ipairs(self.entries) do
        button:Update();
    end
end

function StatFrameMixin:RequestFullUpdate()
    if self.t and not self.isLazyRefresh then
        if not self.isStatDirty then
            self.statChangedAfterUpdate = true;
        end
        self.t = 0;
    else
        self.isStatDirty = true;
        self.isLazyRefresh = nil;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_FullUpdate);
    end
end

function StatFrameMixin:OnUpdate_FullUpdate(elapsed)
    -- Update next frame and pause for 0.2 s
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

function StatFrameMixin:LazyRefresh()
    self.totalEntries = #self.entries;
    if self.totalEntries == 0 then
        self.totalEntries = nil;
    end
    self.t = 0;
    self.entryIndex = 0;
    self.isLazyRefresh = true;
    self:SetScript("OnUpdate", self.OnUpdate_LazyRefresh);
end

function StatFrameMixin:OnUpdate_LazyRefresh(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.05 then -- lazy refresh interval: 0.05 s
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self.isLazyRefresh = nil;
        self.continueUpdating = nil;
        self.entryIndex = self.entryIndex + 1;

        if self.totalEntries and self.entryIndex <= self.totalEntries then
            self.entries[self.entryIndex]:Update();
            self.continueUpdating = true;
        end

        if self.totalEntries and self.entryIndex > self.totalEntries then
            self.totalEntries = nil;
        end

        if self.continueUpdating then
            self.t = 0;
            self:SetScript("OnUpdate", self.OnUpdate_LazyRefresh);
        end
    end
end

--- StatButton fade in by row from top to bottom
function StatFrameMixin:SetIntroAnimationDelay(secondsPerRow)
    self.animationDelay = secondsPerRow;
    local delay;
    local isAfterRadarChart;
    for _, button in ipairs(self.entries) do
        delay = secondsPerRow * (button:GetRow() + (isAfterRadarChart and 1 or 0));
        if button.isRadarChart then
            isAfterRadarChart = true;
        end
        if button.animIn then
            button.animIn.A2:SetStartDelay(delay);
        elseif button.SetIntroAnimationDelay then
            button:SetIntroAnimationDelay(delay, secondsPerRow);
        end
    end
end

function StatFrameMixin:PlayIntroAnimation()
    for _, button in ipairs(self.entries) do
        if button.animIn then
            button.animIn:Play();
        elseif button.PlayIntroAnimation then
            button:PlayIntroAnimation();
        end
    end
end

function StatFrameMixin:SnapToFadeResult()
    -- Override
end
