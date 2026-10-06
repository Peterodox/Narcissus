local _, addon = ...


local Schematics = {};

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


local StatFrameMixin = {};
addon.StatFrameMixin = StatFrameMixin;

function StatFrameMixin:OnLoad()
    self.staticEntries = {};  -- Most stat buttons won't get released after being created
    self.dynamicEntries = {}; -- For Classic: stat buttons here get released/reused after changing Melee/Ranged/Spell

    local layoutType = self.isDetailed and "Detailed" or "Concise";
    local layout = addon.IS_FOREVER and Schematics[layoutType].Forever or Schematics[layoutType].Retail;
    self:SetLayout(layout);
end

function StatFrameMixin:SetLayout(layout)
    local spacerHeight = 26; -- buttonHeight 24 + 2
    local n = 0;

    local function AddChild(statButton)
        if statButton.token and not self[statButton.token] then
            self[statButton.token] = statButton;
        end
    end

    if self.isDetailed then
        local addSpacer = false;
        local isLeftCol = true;
        local chartFrame, lastFrameIsChart;

        for i, token in ipairs(layout) do
            if token == "Chart" then
                -- Chart's parent is not the StatFrame, since we show chart for Equipment Set Manager while hiding other stats
                local frame = CreateFrame("Frame", "Narci_RadarChartFrame", self:GetParent(), "Narci_StatsChartTemplate");
                chartFrame = frame;

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
                button.token = token;
                button:SetLeftColumn(isLeftCol);
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
                button.token = token;
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
