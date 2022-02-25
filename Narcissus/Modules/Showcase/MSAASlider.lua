--local supported = MultiSampleAntiAliasingSupported();

local function Node_OnClick(self)
    if self.value == 0 then
        ConsoleExec("MSAAQuality 0");
    else
        ConsoleExec("MSAAQuality "..self.value..",0");
    end
    NarciOutfitShowcase:MarkCVarChanged();
end

local function Node_OnSelected(self, state, playAnimation)
    if state then
        self.Border:SetVertexColor(0.25, 0.25, 0.25);
        if self.value == 0 then
            self.HighlightTexture:SetTexCoord(0.25, 0.5, 0, 0.25);
        else
            self.HighlightTexture:SetTexCoord(0, 0.25, 0, 0.25);
        end
        self.HighlightTexture:SetVertexColor(1, 1, 1);
        local label = self:GetParent().ValueText;
        label:ClearAllPoints();
        label:SetPoint("BOTTOM", self, "TOP", 0, 1);
        local valueText;
        if self.value == 0 then
            valueText = "OFF";
        else
            valueText = math.pow(2, self.value).."x";
        end
        label:SetText(valueText);
        label:Show();
    end
end

NarciShowcaseMSAASliderMixin = {};

function NarciShowcaseMSAASliderMixin:OnShow()
    if self.CreateNodes then
        self:CreateNodes();
    end
    
    local level = tonumber(string.sub(GetCVar("MSAAQuality") or "", 1,1)) or 0;
    for _, node in pairs(self.Nodes) do
        node:SetSelection(node.value == level);
    end
end

function NarciShowcaseMSAASliderMixin:CreateNodes()
    self.Label:SetText("MSAA");
    self.Link:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\NodeButton", nil, nil, "TRILINEAR");
    self.Link:SetVertexColor(0.25, 0.25, 0.25);
    local distance = 24;
    local button;
    for i = 1, 4 do
        button = CreateFrame("Button", nil, self, "NarciShowcaseSharedNodeTemplate");
        button.onClickFunc = Node_OnClick;
        button.onSelectedFunc = Node_OnSelected;
        button:SetPoint("LEFT", self, "LEFT", (i - 1)*distance, 0);
        if i == 1 then
            self.Link:SetPoint("LEFT", button, "CENTER", 0, 0);
        elseif i == 4 then
            self.Link:SetPoint("RIGHT", button, "CENTER", 0, 0);
        end
        button.value = i - 1;
    end
    self:SetWidth(3 * distance + 16);
    self.CreateNodes = nil;
    NarciShowcaseMSAASliderMixin.CreateNodes = nil;
end