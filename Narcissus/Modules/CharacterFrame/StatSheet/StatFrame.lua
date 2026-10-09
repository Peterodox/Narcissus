local _, addon = ...
local PrivateAPI = addon.PrivateAPI; ---@type NarcissusPrivateAPI
local StatSheetController = addon.StatSheetController; ---@type StatSheetController


local Schematics = {};
do
    Schematics.Detailed = {};
    Schematics.Concise = {};

    Schematics.Detailed.Retail = {
        "Primary", "Health",
        "Stamina", "Armor",
        "Damage", "Reduction",
        "AttackSpeed", "Dodge",
        "Power", "Parry",
        "Regen", "Block",

        "Chart",

        "Leech", "Avoidance",
        "MovementSpeed", "Speed",
    };

    Schematics.Concise.Retail = {
        "Primary",
        "Stamina",
        "Health",
        "Power",
        "Regen",

        "Spacer",

        "Crit",
        "Haste",
        "Mastery",
        "Versatility",

        "Spacer",

        "Leech",
        "Avoidance",
        "Speed",
    };


    Schematics.Detailed.Forever = Schematics.Detailed.Retail; -- [TEMP]
    Schematics.Concise.Forever = Schematics.Concise.Retail;   -- [TEMP]
end


--- [event] = true  -- Full Update
--- [event] = token -- Update specific stat
local DynamicEvents = {
    COMBAT_RATING_UPDATE = true,
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
    self.staticEntries = {};  -- List of StatButton. Most stat buttons won't get released after being created
    self.dynamicEntries = {}; -- List of StatButton. For Classic: stat buttons here get released/reused after changing Melee/Ranged/Spell
    self.statXEntry = {};     -- statToken to StatButton

    local layoutType = self.isDetailed and "Detailed" or "Concise";
    local layout = addon.IS_FOREVER and Schematics[layoutType].Forever or Schematics[layoutType].Retail;
    self:SetLayout(layout);

    StatSheetController:AddStatFrame(self);
    StatSheetController:MakeFrameFadable(self);
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
                    frame:SetPoint("TOP", self.staticEntries[n - 1], "BOTTOMRIGHT", 0, -spacerHeight);
                end

                n = n + 1;
                self.staticEntries[n] = frame;

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
                self.staticEntries[n] = button;

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
                    button:SetPoint("TOPRIGHT", self.staticEntries[n - 2], "BOTTOMRIGHT", 0, offsetY);
                else
                    button:SetPoint("TOPLEFT", self.staticEntries[n - 1], "TOPRIGHT", 0, 0);
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
            else
                local button = CreateFrame("Button", nil, self, "Narci_AttributeTemplate");
                button:SetToken(token);
                button:SetRow(row);
                row = row + 1;
                AddChild(button);

                n = n + 1;
                self.staticEntries[n] = button;

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
                    button:SetPoint("TOP", self.staticEntries[n - 1], "BOTTOM", 0, offsetY);
                end
            end
        end
    end
end

function StatFrameMixin:OnShow()
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
    for _, button in ipairs(self.staticEntries) do
        button:Update();
    end
    for _, button in ipairs(self.dynamicEntries) do
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
    self.totalStatic = #self.staticEntries;
    self.totalDynamic = #self.dynamicEntries;
    if self.totalStatic == 0 then
        self.totalStatic = nil;
    end
    if self.totalDynamic == 0 then
        self.totalDynamic = nil;
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

        if self.totalStatic and self.entryIndex <= self.totalStatic then
            self.staticEntries[self.entryIndex]:Update();
            self.continueUpdating = true;
        end

        if self.totalStatic and self.entryIndex > self.totalStatic then
            self.totalStatic = nil;
            if self.totalDynamic then
                self.entryIndex = 0;
                self.continueUpdating = true;
            end
        end

        if self.totalDynamic and self.entryIndex <= self.totalDynamic then
            self.dynamicEntries[self.entryIndex]:Update();
            self.continueUpdating = true;
        end

        if self.continueUpdating then
            self.t = 0;
            self:SetScript("OnUpdate", self.OnUpdate_LazyRefresh);
        end
    end
end

--- StatButton fade in by row from top to bottom
function StatFrameMixin:SetIntroAnimationDelay(secondsPerRow)
    local delay;
    for _, entries in ipairs({self.staticEntries, self.dynamicEntries}) do
        local isAfterRadarChart;
        for _, button in ipairs(entries) do
            delay = secondsPerRow * (button:GetRow() + (isAfterRadarChart and 1 or 0));
            if button.isRadarChart then
                isAfterRadarChart = true;
            end
            if button.animIn then
                button.animIn.A2:SetStartDelay(delay);
            end
        end
    end
end

function StatFrameMixin:PlayIntroAnimation()
    for _, entries in ipairs({self.staticEntries, self.dynamicEntries}) do
        for _, button in ipairs(entries) do
            if button.animIn then
                button.animIn:Play();
            end
        end
    end
end

function StatFrameMixin:SnapToFadeResult()
    -- Override
end
