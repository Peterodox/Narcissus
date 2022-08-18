local _, addon = ...

local THUMB_SIZE = 20;

local MainFrame;
local ANY_DRAGGING = false;

local GetCursorPosition = GetCursorPosition;


local function EmptyFunc(self, value, userInput)
end


local SliderUpdateFrame = CreateFrame("Frame");
SliderUpdateFrame:Hide();

local function SliderUpdateFrame_Lock(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.locked = nil;
        self:SetScript("OnUpdate", nil);
    end
end

local function SliderUpdateFrame_Drag(self, elapsed)
    self.x, self.y = GetCursorPosition();
    self.ratio = (self.x - self.cursorOffset - self.left)/self.pixelRange;
    self.slider:SetValueByRatio(self.ratio, true);
end

function SliderUpdateFrame:Start(slider)
    if self.locked then
        return
    end

    if slider.obeyStepOnDrag then
        self:Stop();
        return
    end

    self.slider = slider;
    local uiScale = slider:GetEffectiveScale();

    self.left = slider.RailCenter:GetLeft() * uiScale;
    self.right = slider.RailCenter:GetRight() * uiScale;
    self.pixelRange = self.right - self.left;

    if slider.Thumb:IsMouseOver() then
        local cursorX, cursorY = GetCursorPosition();
        local thumbX, thumbY = slider.Thumb:GetCenter();
        thumbX, thumbY = thumbX * uiScale, thumbY * uiScale;
        self.cursorOffset = cursorX - thumbX;
    else
        self.cursorOffset = 0;
    end

    SliderUpdateFrame:SetScript("OnUpdate", SliderUpdateFrame_Drag);
    self:Show();
end

function SliderUpdateFrame:Stop()
    if not self.locked then
        self:Hide();
    end
end

function SliderUpdateFrame:Lock()
    self.t = -0.25;
    self.locked = true;
    self:SetScript("OnUpdate", SliderUpdateFrame_Lock);
    self:Show();
end


local function Thumb_OnEnter(self)
    self.Icon:SetDesaturation(0);
    self.Icon:SetVertexColor(1, 1, 1);
end

local function Thumb_OnLeave(self)
    if not (self:GetParent().obeyStepOnDrag or self:GetParent().isDragging) then
        self.Icon:SetDesaturation(1);
        self.Icon:SetVertexColor(0.67, 0.67, 0.67);
    end
end

local function Thumb_OnMouseDown(self)
    self:GetParent().isDragging = true;
    ANY_DRAGGING = true;

    SliderUpdateFrame:Start(self:GetParent());
end

local function Thumb_OnMouseUp(self)
    self:GetParent().isDragging = nil;
    ANY_DRAGGING = false;

    if not self:IsMouseOver() then
        Thumb_OnLeave(self);
    end

    SliderUpdateFrame:Stop();

    if MainFrame then
        MainFrame:OnLeave();
    end
end

local function Thumb_OnDoubleClick(self)
    self:GetParent():ResetToDefaultValue();
    SliderUpdateFrame:Lock();
end


local function Node_OnEnter(self)

end

local function Node_OnLeave(self)

end

local function Node_OnMouseDown(self)
    self:GetParent():SetValueByStep(self.index, true);
end



NarciScreenshotToolbarSliderMixin = {};

function NarciScreenshotToolbarSliderMixin:OnLoad()
    self:SetMinMaxValues(self.minValue, self.maxValue);
    self.railSize = self.RailCenter:GetWidth();

    if self.labelText then
        self:SetLabel(self.labelText);
        self.labelText = nil;
    elseif self.labelTextKey then
        self:SetLabel(Narci.L[self.labelText] or "Not Set");
        self.labelTextKey= nil;
    end

    self.onValueChangedFunc = EmptyFunc;

    self.Thumb:SetScript("OnEnter", Thumb_OnEnter);
    self.Thumb:SetScript("OnLeave", Thumb_OnLeave);
    self.Thumb:SetScript("OnMouseDown", Thumb_OnMouseDown);
    self.Thumb:SetScript("OnMouseUp", Thumb_OnMouseUp);
    self.Thumb:SetScript("OnDoubleClick", Thumb_OnDoubleClick);

    Thumb_OnLeave(self.Thumb);

    if self.iconIndex then
        self.Icon:SetTexCoord(self.iconIndex * 0.125, (self.iconIndex + 1) * 0.125, 0.875, 1);
        self.iconIndex = nil;
    end
end

function NarciScreenshotToolbarSliderMixin:OnEnter()
    if MainFrame then
        MainFrame:OnEnter();
    end
end

function NarciScreenshotToolbarSliderMixin:OnLeave()
    if MainFrame then
        MainFrame:OnLeave();
    end
end

function NarciScreenshotToolbarSliderMixin:OnMouseDown()
    SliderUpdateFrame:Start(self);
    self.isDragging = true;
end

function NarciScreenshotToolbarSliderMixin:OnMouseUp()
    if not self:IsMouseOver() then
        self:OnLeave();
    end
    SliderUpdateFrame:Stop();
    self.isDragging = nil;
    Thumb_OnMouseUp(self.Thumb);
end

function NarciScreenshotToolbarSliderMixin:SetValue(value, userInput)
    if self.maxValue and value > self.maxValue then
        value = self.maxValue;
    elseif self.minValue and value < self.minValue then
        value = self.minValue;
    end

    if value ~= self.value or self.alwaysUpdate then
        self.onValueChangedFunc(self, value, userInput);
    end

    self.value = value;

    if self.obeyStepOnDrag then
        local index = (value - self.minValue) / self.valueStep;
        self.Thumb:SetPoint("CENTER", self.RailCenter, "LEFT", index * self.nodeOffset, 0);
    else
        local ratio;
        if self.range == 0 then
            ratio = 0;
        else
            ratio = (value - self.minValue) / self.range;
        end

        self.Thumb:SetPoint("CENTER", self.RailCenter, "LEFT", ratio * self.railSize, 0);
    end
end

function NarciScreenshotToolbarSliderMixin:GetValue()
    return self.value;
end

function NarciScreenshotToolbarSliderMixin:SetValueByStep(index, userInput)
    if index >= 0 and self.valueStep and self.minValue then
        local value = self.minValue + index * self.valueStep;
        self:SetValue(value, userInput);
    end
end

function NarciScreenshotToolbarSliderMixin:SetValueByRatio(ratio, userInput)
    if ratio > 1 then
        ratio = 1;
    elseif ratio < 0 then
        ratio = 0;
    end
    self:SetValue( (1 - ratio) * self.minValue + ratio * self.maxValue, userInput);
end

function NarciScreenshotToolbarSliderMixin:OnShow()
    if not self.ready then
        self:Init();
        self.ready = true;
    end
    if self.onShowCallback then
        self.onShowCallback(self);
    end
end

function NarciScreenshotToolbarSliderMixin:Init()
    if self.obeyStepOnDrag then
        if not self.nodes then
            self.nodes = {};
        end

        self.valueStep = (self.maxValue - self.minValue)/(self.numSteps - 1);

        local SIDE_OFFSET = THUMB_SIZE * 0.5;       --Conpensated for thumb size (20)
        local width = math.floor(self:GetWidth() + 0.5 - THUMB_SIZE);
        local offsetX = width / (self.numSteps - 1);
        self.nodeOffset = offsetX;

        local node;

        for i = 1, self.numSteps do
            node = self.nodes[i];
            if not node then
                self.nodes[i] = CreateFrame("Button", nil, self);
                node = self.nodes[i];
                node.index = i - 1;
                node:SetSize(24, 24);
                node:SetScript("OnEnter", Node_OnEnter);
                node:SetScript("OnLeave", Node_OnLeave);
                node:SetScript("OnMouseDown", Node_OnMouseDown);

                node.Texture = node:CreateTexture(nil, "BORDER");
                node.Texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\ScreenshotTool\\Slider");
                node.Texture:SetSize(20, 20);
                node.Texture:SetPoint("CENTER", node, "CENTER", 0, 0);

                node.Highlight = node:CreateTexture(nil, "HIGHLIGHT");
                node.Highlight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\ScreenshotTool\\Slider");
                node.Highlight:SetSize(20, 20);
                node.Highlight:SetPoint("CENTER", node, "CENTER", 0, 0);
                node.Highlight:SetTexCoord(0.25, 0.375, 0.125, 0.25);
                node.Highlight:SetBlendMode("ADD");
            end

            if i == 1 then
                node.Texture:SetTexCoord(0, 0.125, 0, 0.125);
            elseif i == self.numSteps then
                node.Texture:SetTexCoord(0.25, 0.375, 0, 0.125);
            else
                node.Texture:SetTexCoord(0.125, 0.25, 0, 0.125);
            end
            node:SetPoint("CENTER", self, "LEFT", offsetX * (i - 1) + SIDE_OFFSET, 0);
        end

        for i = self.numSteps + 1, #self.nodes do
            node:Hide();
        end

        self.Thumb.Icon:SetTexCoord(0, 0.125, 0.125, 0.25);
        Thumb_OnEnter(self.Thumb);
        self.RailLeft:Hide();
        self.RailRight:Hide();
        self.RailCenter:SetTexCoord(0.5, 0.75, 0, 0.125);

        local labelOffset = 4;
        self.Label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0 + labelOffset, -3);
        self.ValueText:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0 - labelOffset, -3);
        self.IconBackground:SetPoint("RIGHT", self, "LEFT", -6 + labelOffset, 6);
    else
        if self.nodes then
            for i = 1, #self.nodes do
                self.nodes[i]:Hide();
            end
        end

        self.Thumb.Icon:SetTexCoord(0.125, 0.25, 0.125, 0.25);
        Thumb_OnLeave(self.Thumb);
        self.RailLeft:Show();
        self.RailRight:Show();
        self.RailCenter:SetTexCoord(0.5, 0.75, 0.125, 0.25);
    end
end

function NarciScreenshotToolbarSliderMixin:SetMinMaxValues(minValue, maxValue)
    self.minValue = minValue;
    self.maxValue = maxValue;
    self.range = maxValue - minValue;
end

function NarciScreenshotToolbarSliderMixin:SetLabel(text)
    self.Label:SetText(text);
end

function NarciScreenshotToolbarSliderMixin:SetValueText(text)
    self.ValueText:SetText(text);
end

function NarciScreenshotToolbarSliderMixin:ResetToDefaultValue()
    if self.defaultValue then
        self:SetValue(self.defaultValue, true);
    end
end


NarciCameraSettingFrameMixin = {};

function NarciCameraSettingFrameMixin:OnLoad()
    MainFrame = self:GetParent();
end

function NarciCameraSettingFrameMixin:IsFocused()
    return self:IsShown() and (self:IsMouseOver() or ANY_DRAGGING)
end