local _, addon = ...
local SetGradient = addon.TransitionAPI.SetGradient;

local FadeFrame = NarciFadeUI.Fade;
local After = C_Timer.After;
local pi = math.pi;
local sqrt = math.sqrt;
local GetCursorPosition = GetCursorPosition;
local IsMouseButtonDown = IsMouseButtonDown;
local NarciAPI = NarciAPI;

local function EmptyFunc()
end

--TEMPS prefix: Deleted Later
local TEMPS = {};


local controllers = {};

local function AddControllerToWidget(widget)
    if not widget.controller then
        local controller = CreateFrame("Frame", nil, widget);
        controller:Hide();
        controller.t = 0;
        controller:SetScript("OnHide", function(self)
            self.t = 0;
            --print("Hide Controller");
        end);
        widget.controller = controller;
        tinsert(controllers, controller);
    end
    return widget.controller
end

--------------------------------------------------------------------------------------------------
--Name: Shimmer Button
--Type: Button
--Description: Shimmers slowly. Maintains highlight when moused-over
--Notes: starting Alpha is always "0"

TEMPS.totalDuration = 0;
local shimmerStyle = {
    {toAlpha = 0.5, duration = 0.4},    --#1
    {toAlpha = 0.5, duration = 0.25},   --#2
    {toAlpha = 0, duration = 1.5},      --#3
    {toAlpha = 0, duration = 0.35},     --#4
};

--time accumulation
local timeAlpha = {
    --{totalDuration, toAlpha};
};
local TIER_SHIMMER = #shimmerStyle;

for i = 1, #shimmerStyle do
    local cuurentT = TEMPS.totalDuration;
    local duration = shimmerStyle[i].duration;
    local nextT = cuurentT + duration;
    TEMPS.totalDuration = nextT;
    local fromAlpha;
    if i > 1 then
        fromAlpha = shimmerStyle[i - 1].toAlpha;
        if fromAlpha < 0 then
            fromAlpha = 0;
        end
    else
        fromAlpha = 0;
    end
    local toAlpha = shimmerStyle[i].toAlpha;
    if toAlpha < 0 then
        toAlpha = 0;
    end
    local deltaAlpha = (toAlpha - fromAlpha)/duration
    timeAlpha[i] = {cuurentT, nextT, fromAlpha, deltaAlpha};
end
shimmerStyle = nil;

local function UpdateObjectAlphaByTime(object, t)
    local data;
    local tR, fromAlpha, deltaAlpha;
    for i = 1, TIER_SHIMMER do
        data = timeAlpha[i];
        if t >= data[1] and t <= data[2] then
            fromAlpha, deltaAlpha = data[3], data[4];
            tR = t - data[1];
            break;
        end
    end

    if tR then
        object:SetAlpha(fromAlpha + deltaAlpha*tR);
        return true
    else
        object:SetAlpha(0);
        return false
    end
end

NarciUIShimmerButtonMixin = {};

function NarciUIShimmerButtonMixin:Preload()
    local controller = AddControllerToWidget(self);
    controller:SetScript("OnUpdate", function(controller, elapsed)
        if controller.isHolding then
            local toAlpha = controller.toAlpha or 0;
            local alpha;
            if toAlpha == 0 then
                alpha = self.Shimmer:GetAlpha() - 1 * elapsed;
            else
                alpha = self.Shimmer:GetAlpha() + 5 * elapsed;
            end
            if alpha >= 0.8 then
                self.Shimmer:SetAlpha(0.8);
                controller:Hide();
            elseif alpha <= 0 then
                self.Shimmer:SetAlpha(0);
                if controller.pendingReset then
                    controller.pendingReset = nil;
                    controller.isHolding = nil;
                end
            else
                self.Shimmer:SetAlpha(alpha);
            end
        else
            local t = controller.t + elapsed;
            if not UpdateObjectAlphaByTime(self.Shimmer, t) then
                t = 0;
            end
            controller.t = t;
        end
    end);
    self.Shimmer:SetAlpha(0);
    self.Shimmer:Hide();
    self.Preload = nil;
end

function NarciUIShimmerButtonMixin:PlayShimmer()
    self.Shimmer:Show();
    if self.controller.isHolding then
        self.controller.toAlpha = 0;
        self.controller.pendingReset = true;
    end
    self.controller:Show();
end

function NarciUIShimmerButtonMixin:StopShimmer()
    self.Shimmer:Hide();
    self.controller:Hide();
    self.controller.toAlpha = 0;
    self.controller.isHolding = true;
end

function NarciUIShimmerButtonMixin:HoldShimmer()
    self.controller.toAlpha = 0.8;
    self.controller.isHolding = true;
    self.Shimmer:Show();
    self.controller:Show();
end


--------------------------------------------------------------------------------------------------
--Type: Color Picker (HSV)
local ColorPicker;
local RGBRatio2HSV = NarciAPI.RGBRatio2HSV;
local HSV2RGB = NarciAPI.HSV2RGB;


NarciColorPickerSliderMixin = {};

function NarciColorPickerSliderMixin:SetBorderOffset(x)
    self.Left:SetPoint("LEFT", self, "LEFT", x, 0);
    self.Right:SetPoint("RIGHT", self, "RIGHT", -x, 0);
end

function NarciColorPickerSliderMixin:SetButtonSize(w, h)
    self.Left:SetSize(h, h);
    self.Right:SetSize(h, h);
    self.Center:SetHeight(h);
    self:SetSize(w, h);
end

function NarciColorPickerSliderMixin:SetHighlight(state)
    local v;
    if state then
        v = 1;
    else
        v = 0.66;
    end
    for i = 1, #self.borderTextures do
        self.borderTextures[i]:SetVertexColor(v, v, v);
    end
end

function NarciColorPickerSliderMixin:OnEnter()
    if not IsMouseButtonDown() then
        self:SetHighlight(true);
    end
end

function NarciColorPickerSliderMixin:OnLeave()
    if not IsMouseButtonDown() then
        self:SetHighlight(false);
    end
end

function NarciColorPickerSliderMixin:OnMouseUp()
    if not self:IsMouseOver() then
        self:SetHighlight(false);
    end
end

function NarciColorPickerSliderMixin:OnLoad()
    local tex = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\ColorPicker\\UI.tga";
    self.borderTextures = {
        self.Left, self.Center, self.Right, self.ThumbTexture
    };

    for i = 1, #self.borderTextures do
        self.borderTextures[i]:SetTexture(tex);
    end
    self.Marker:SetTexture(tex);
    self.Left:SetTexCoord(0, 0.125, 0, 0.125);
    self.Center:SetTexCoord(0.125, 0.875, 0, 0.125);
    self.Right:SetTexCoord(0.875, 1, 0, 0.125);
    self.ThumbTexture:SetTexCoord(0, 0.0625, 0.875, 1);
    self.Marker:SetTexCoord(0.125, 0.140625, 0.875, 1);
    self:SetHighlight(false);
    self:SetBorderOffset(2);
    self.Marker:SetVertexColor(0.5, 0.5, 0.5);
end


function NarciColorPickerSliderMixin:OnValueChanged(value, isUserInput)
    if value == self.value then
        return
    end
    self.ThumbTexture:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0);
    --self.Marker:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0);

    self.value = value;

    ColorPicker:Update();
end


--Confirm/Cancel New Color

NarciColorPickerActionButtonMixin = {};

function NarciColorPickerActionButtonMixin:OnLoad()
    local tex = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\ColorPicker\\UI.tga";
    self.borderTextures = {
        self.LeftEnd, self.Left, self.Center, self.Right, self.RightEnd
    }
    for i = 1, #self.borderTextures do
        self.borderTextures[i]:SetTexture(tex);
    end
    self.LeftEnd:SetTexCoord(0, 0.125, 0.3750, 0.6250);
    self.Left:SetTexCoord(0.125, 0.25, 0.3750, 0.6250);
    if self.action == "Confirm" then
        self.Center:SetTexCoord(0.505, 0.75, 0.3750, 0.6250);
    else
        self.Center:SetTexCoord(0.75, 1, 0.3750, 0.6250);
    end
    self.Right:SetTexCoord(0.125, 0.25, 0.3750, 0.6250);
    self.RightEnd:SetTexCoord(0.375, 0.5, 0.3750, 0.6250);

    self:SetHighlight(false);
end

function NarciColorPickerActionButtonMixin:SetButtonHeight(height)
    self:SetHeight(height);
    self.Reference:SetHeight(height - 3);
end

function NarciColorPickerActionButtonMixin:SetButtonWidth(width)
    self:SetWidth(width);
    self.Reference:SetWidth(width - 1);
end

function NarciColorPickerActionButtonMixin:SetButtonSize(w, h)
    self.LeftEnd:SetSize(h, 2*h);
    self.RightEnd:SetSize(h, 2*h);
    self.Center:SetSize(2*h, 2*h);
    self.Left:SetHeight(2*h);
    self.Right:SetHeight(2*h);
    self:SetButtonWidth(w);
    self:SetButtonHeight(h);
end

function NarciColorPickerActionButtonMixin:SetHighlight(state)
    local v;
    if state then
        v = 1;
    else
        v = 0.66;
    end
    for i = 1, #self.borderTextures do
        self.borderTextures[i]:SetVertexColor(v, v, v);
    end
end

function NarciColorPickerActionButtonMixin:OnEnter()
    self:SetHighlight(true);
end

function NarciColorPickerActionButtonMixin:OnLeave()
    self:SetHighlight(false);
end

function NarciColorPickerActionButtonMixin:OnMouseUp()
    self.Reference:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciColorPickerActionButtonMixin:OnMouseDown()
    self.Reference:SetPoint("CENTER", self, "CENTER", 0, -1);
end

function NarciColorPickerActionButtonMixin:OnClick()
    ColorPicker[self.action](ColorPicker);
end

function NarciColorPickerActionButtonMixin:SetColor(r, g, b)
    self.Reference:SetColorTexture(r, g, b);
    self.color = {r, g, b};
end

function NarciColorPickerActionButtonMixin:GetColor()
    if self.color then
        return unpack(self.color)
    else
        return 0, 0, 0
    end
end

NarciUIColorPickerMixin = {};

function NarciUIColorPickerMixin:Preload()
    ColorPicker = self;
    self:RegisterForDrag("LeftButton");

    local sliderHeight = 12;
    local sliderWidth = 160;
    local thumbWidth = 6;

    local HueSlider = self.HueSlider;
    local colors = {
        {1, 0, 0},      --Red
        {1, 1, 0},      --Yellow
        {0, 1, 0},      --Green
        {0, 1, 1},      --Cyan
        {0, 0, 1},      --Blue
        {1, 0, 1},      --Pink
        {1, 0, 0},      --Red
    }
    local gt;
    local gradients = {};
    local numBlocks = #colors - 1;
    local blockWidth = (sliderWidth - thumbWidth) / numBlocks;
    for i = 1, numBlocks do
        gt = HueSlider:CreateTexture(nil, "ARTWORK");
        gradients[i] = gt;
        gt:SetSize(blockWidth, sliderHeight);
        if i == 1 then
            gt:SetPoint("LEFT", HueSlider, "LEFT", thumbWidth/2 + blockWidth * (i - 1), 0);
        else
            gt:SetPoint("LEFT", gradients[i - 1], "RIGHT", 0, 0);
        end
        gt:SetColorTexture(1, 1, 1, 1);
        SetGradient(gt, "HORIZONTAL", colors[i][1], colors[i][2], colors[i][3],  colors[i+1][1], colors[i+1][2], colors[i+1][3]);
    end
    HueSlider:SetMinMaxValues(0, 360);
    HueSlider:SetValueStep(1);
    HueSlider:SetWidth(sliderWidth);
    HueSlider:SetValue(0);
    HueSlider.value = 0;

    local SatSlider = self.SaturationSlider;
    local gt2 = SatSlider:CreateTexture(nil, "ARTWORK");
    SatSlider.Gradient = gt2;
    gt2:SetSize(sliderWidth - thumbWidth, sliderHeight);
    gt2:SetPoint("LEFT", SatSlider, "LEFT", thumbWidth/2, 0);
    gt2:SetColorTexture(1, 1, 1, 1);
    SetGradient(gt2, "HORIZONTAL", 1, 1, 1, 1, 0, 0);
    SatSlider:SetMinMaxValues(0, 100);
    SatSlider:SetValueStep(1);
    SatSlider:SetWidth(sliderWidth);
    SatSlider:SetValue(100);
    SatSlider.value = 100;
    
    local BriSlider = self.BrightnessSlider;
    local gt3 = SatSlider:CreateTexture(nil, "ARTWORK");
    BriSlider.Gradient = gt3;
    gt3:SetSize(sliderWidth - thumbWidth, sliderHeight);
    gt3:SetPoint("LEFT", BriSlider, "LEFT", thumbWidth/2, 0);
    gt3:SetColorTexture(1, 1, 1, 1);
    SetGradient(gt3, "HORIZONTAL", 0, 0, 0, 1, 0, 0);
    BriSlider:SetMinMaxValues(0, 100);
    BriSlider:SetValueStep(1);
    BriSlider:SetWidth(sliderWidth);
    BriSlider:SetValue(100);

    local ConfirmButton = self.ConfirmButton;
    local CancelButton = self.CancelButton;
    
    local padding = 4;
    local sliders = {HueSlider, SatSlider, BriSlider};
    for i = 1, #sliders do
        sliders[i]:SetButtonSize(sliderWidth, sliderHeight);
        sliders[i]:SetParent(self.FrameContainer);
    end

    HueSlider:SetPoint("TOP", self, "TOP", 0, -padding);
    SatSlider:SetPoint("TOP", self, "TOP", 0, -2*padding - sliderHeight);
    BriSlider:SetPoint("TOP", self, "TOP", 0, -3*padding - 2*sliderHeight);
    ConfirmButton:SetPoint("TOPRIGHT", self, "TOP", -padding, -5*padding - 3*sliderHeight);
    CancelButton:SetPoint("TOPLEFT", self, "TOP", padding, -5*padding - 3*sliderHeight);
    ConfirmButton:SetButtonSize(sliderWidth/2 - padding - thumbWidth/4, sliderHeight);
    CancelButton:SetButtonSize(sliderWidth/2 - padding - thumbWidth/4, sliderHeight);
    CancelButton:SetColor(0, 0, 0);

    self:SetSize(sliderWidth + 2*padding - 4, 4*sliderHeight + 6*padding + 1);
    self.Preload = nil;

    self:SetRGB(0, 0, 0);
    self:Update();
end

function NarciUIColorPickerMixin:OnLoad()
    self:Preload();
    self:Hide();
end

function NarciUIColorPickerMixin:Update()
    if self.Preload then return end;

    local h, s, v = self:GetHSV();
    local r, g, b = HSV2RGB(h, 1, v);
    SetGradient(self.SaturationSlider.Gradient, "HORIZONTAL", v, v, v, r, g, b);
    r, g, b = HSV2RGB(h, s, 1);
    SetGradient(self.BrightnessSlider.Gradient, "HORIZONTAL", 0, 0, 0, r, g, b);
    r, g, b = self:GetRGB();
    self.ConfirmButton:SetColor(r, g, b);

    if self.objects then
        for i = 1, #self.objects do
            self.objects[i]:SetVertexColor(r, g, b);
        end
    end
end

function NarciUIColorPickerMixin:SetRGB(r, g, b)
    local h, s, v = RGBRatio2HSV(r, g, b);
    self.HueSlider:SetValue(h);
    self.SaturationSlider:SetValue(100*s);
    self.BrightnessSlider:SetValue(100*v);
    self.ConfirmButton:SetColor(r, g, b);
end

function NarciUIColorPickerMixin:GetHSV()
    return self.HueSlider.value or 0, (self.SaturationSlider.value or 100)/100, (self.BrightnessSlider.value or 100)/100;
end

function NarciUIColorPickerMixin:GetRGB()
    return HSV2RGB(self:GetHSV());
end

function NarciUIColorPickerMixin:OnDragStart()
    self:StartMoving();
end

function NarciUIColorPickerMixin:OnDragStop()
    self:StopMovingOrSizing();
end

function NarciUIColorPickerMixin:FadeButton(buttonIndex)
    self.ConfirmButton:Disable();
    self.CancelButton:Disable();
    FadeFrame(self.FrameContainer, 0.2, 0);
    if buttonIndex == 1 then
        FadeFrame(self.CancelButton, 0.2, 0);
    else
        FadeFrame(self.ConfirmButton, 0.2, 0);
    end
    After(0.5, function()
        FadeFrame(self, 0.25, 0);
    end);

    --After(3, function()
    --    self:ShowPanel();
    --end)
end

function NarciUIColorPickerMixin:Confirm()
    self:FadeButton(1);
    self:Update();
end

function NarciUIColorPickerMixin:Cancel()
    self:FadeButton(2);

    local r, g, b = self.CancelButton:GetColor();
    ColorPicker:SetRGB(r, g, b);
end

function NarciUIColorPickerMixin:ShowPanel()
    self.FrameContainer:Show();
    self.FrameContainer:SetAlpha(1);
    self.ConfirmButton:Show();
    self.ConfirmButton:SetAlpha(1);
    self.CancelButton:Show();
    self.CancelButton:SetAlpha(1);
    self.ConfirmButton:Enable();
    self.CancelButton:Enable();
    self:Show();
    self:SetAlpha(1);
end

function NarciUIColorPickerMixin:SetObject(switch)
    self.objects = switch.objects;
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", switch, "TOPRIGHT", 8, 0);

    if self.objects and self.objects[1] then
        --self:SetRGB(self.objects[1]:GetVertexColor());
        self.CancelButton:SetColor(self.objects[1]:GetVertexColor());
    end

    self:ShowPanel();
end

--------------------------------------------------------------------------------------------------
--Name: Skewed Rectangular Button
--Notes: Clockwise 10 Degree

local MARGIN_X = 5;
NarciShewedRectButtonMixin = {};

function NarciShewedRectButtonMixin:SetButtonSize(width, height)
    self:SetSize(width, height);
    self.MaskLeft:SetSize(MARGIN_X, height);
    self.MaskRight:SetSize(MARGIN_X, height);

    local texOffset = 0.05;
    local dy = (1 - 2*texOffset)*height/width/2;
    self.Icon:SetTexCoord(texOffset, 1 - texOffset, 0.5 - dy, 0.5 + dy);
    self.Icon:SetSize(width, height);
end

function NarciShewedRectButtonMixin:SetIcon(iconFile)
    self.Icon:SetTexture(iconFile);
end

function NarciShewedRectButtonMixin:SetColorTexture(r, g, b)
    self.Icon:SetColorTexture(r, g, b);
end

function NarciShewedRectButtonMixin:ShowAlert()
    self:SetIcon("Interface\\AddOns\\Narcissus\\Art\\NavBar\\AlertMark");
    self.Icon:Show();
end

function NarciShewedRectButtonMixin:SetHighlight(state)
    if state then
        self.Icon:SetDesaturation(0);
        self.Icon:SetVertexColor(1, 1, 1);
    else
        self.Icon:SetDesaturation(0.2);
        self.Icon:SetVertexColor(0.80, 0.80, 0.80);
    end
end

function NarciShewedRectButtonMixin:UseFullMask(state, side)
    local mode = "CLAMPTOWHITE";    --CLAMPTOBLACKADDITIVE

    if state and (not side or side == 1) then
        self.MaskLeft:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full", mode, mode);
    else
        self.MaskLeft:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SkewdRect\\ReversedMask-Left", mode, mode);
    end

    if state and (not side or side == 2) then
        self.MaskRight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full", mode, mode);
    else
        self.MaskRight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SkewdRect\\ReversedMask-Right", mode, mode);
    end
end


--------------------------------------------------------------------------------------------------
--Name: Progress Timer
--Notes: Timer & Progress Bar
NarciProgressTimerMixin = {};

function NarciProgressTimerMixin:SetOnFinishedFunc(func1, func2)
    self.Fluid.animFill.onFinishedFunc = func1;
    self.Fluid.animFade.onFinishedFunc = func2;
end

function NarciProgressTimerMixin:SetTimer(duration, loopTimer)
    self:StopAnimating();
    local animFill = self.Fluid.animFill;
    animFill.s1:SetDuration(duration);
    if loopTimer then
        self.isLoop = true;
    else
        self.isLoop = false;
    end
    animFill:Play();
end

function NarciProgressTimerMixin:Start()
    self.Fluid.animFill:Play();
    self:Show();
end

function NarciProgressTimerMixin:Stop()
    self:StopAnimating();
    self:Hide();
end

function NarciProgressTimerMixin:Pause()
    if not self.isPaused then
        self.isPaused = true;
        self.Fluid.animFill:Pause();
    end
end

function NarciProgressTimerMixin:Play()
    if self.isPaused then
        self.isPaused = nil;
        if not self.Fluid.animFade:IsPlaying() then
            self.Fluid.animFill:Play();
        end
    end
end

function NarciProgressTimerMixin:Resume()
    if self:IsShown() then
        self:Play();
    end
end

function NarciProgressTimerMixin:SetAlign(widget, offsetY)
    self:ClearAllPoints();
    offsetY = offsetY or 0;
    self:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT", 1, offsetY);
    self:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -1, offsetY);
end

function NarciProgressTimerMixin:SetColor(r, g, b)
    self.Fluid:SetColorTexture(r, g, b);
end


--------------------------------------------------------------------------------------------------
--Name: Custom Slider
--Notes:
--1. A frame with all slider's methods;
--2. Take into account the MouseDown Position
local offsetUpdater = CreateFrame("Frame");
offsetUpdater.t = 0;
offsetUpdater:Hide();

offsetUpdater:SetScript("OnUpdate", function(self)
    self.x, self.y = GetCursorPosition();
    self.ratio = (self.yTop - self.y + self.yOffset)/self.pixelRange;
    self.scrollBar:SetValueByRatio(self.ratio);
end)

function offsetUpdater:Start(scrollBar)
    local uiScale = scrollBar:GetEffectiveScale();
    self.scrollBar = scrollBar;
    self.yTop = scrollBar:GetTop() * uiScale;
    self.pixelRange = scrollBar.thumbRange * uiScale;
    local yoffset;
    if scrollBar.ThumbTexture:IsMouseOver(0, 0, -2, 0) then
        local _, thumbY, mouseY;
        _, mouseY = GetCursorPosition();
        thumbY = scrollBar.ThumbTexture:GetTop() * uiScale;
        self.yOffset = -thumbY + mouseY;
    else
        self.yOffset = -0.5 * scrollBar.ThumbTexture:GetHeight() * uiScale;
    end
    self:Show();
end

function offsetUpdater:Stop()
    self:Hide();
end

NarciCustomScrollBarMixin = {};

function NarciCustomScrollBarMixin:OnLoad()
    self.thumbRange = 0;
    self.value = 0;

    self:SetMinMaxValues(0, 0);
    self:SetThumbAlpha(0.25);

    local parentScrollFrame = self:GetParent();
    self.onValueChangedFunc = function(value)
        parentScrollFrame:SetVerticalScroll(value);
    end
end

function NarciCustomScrollBarMixin:SetMinMaxValues(minValue, maxValue)
    if minValue > maxValue then
        minValue = 0;
        maxValue = 0;
    end

    self.minValue = minValue;
    self.maxValue = maxValue;

    self:SetShown(maxValue ~= 0)
end

function NarciCustomScrollBarMixin:SetValue(value)
    if value < self.minValue then
        value = self.minValue;
    elseif value > self.maxValue then
        value = self.maxValue;
    end
    self.value = value;

    if self.maxValue ~= 0 then
        self.ThumbTexture:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -value / self.maxValue * self.thumbRange);
    end

    self.onValueChangedFunc(value);
end

function NarciCustomScrollBarMixin:SetValueByRatio(ratio)
    if ratio < 0 then
        ratio = 0;
    elseif ratio > 1 then
        ratio = 1;
    end
    self:SetValue( ratio * (self.maxValue - self.minValue) )
end

function NarciCustomScrollBarMixin:GetValue()
    return self.value or 0;
end

function NarciCustomScrollBarMixin:OnEnter()
    if IsMouseButtonDown() then
        return
    end
    if self.ThumbTexture:IsMouseOver() then
        self:SetThumbAlpha(1);
    else
        self:SetThumbAlpha(0.66);
    end
end

function NarciCustomScrollBarMixin:OnLeave()
    if not self.isDragging then
        self:SetThumbAlpha();
    end
end

function NarciCustomScrollBarMixin:OnMouseDown()
    self.isDragging = true;
    offsetUpdater:Start(self);
    self:SetThumbAlpha(1);
    if self.onMouseDownFunc then
        self.onMouseDownFunc();
    end
end

function NarciCustomScrollBarMixin:OnMouseUp()
    self.isDragging = nil;
    offsetUpdater:Stop();
    if self:IsMouseOver() then
        self:SetThumbAlpha(0.66);
    else
        self:SetThumbAlpha();
    end
end

function NarciCustomScrollBarMixin:OnHide()
    self:SetThumbAlpha();
end

function NarciCustomScrollBarMixin:SetThumbAlpha(alpha)
    alpha = alpha or 0.4;
    self.ThumbTexture:SetAlpha(alpha);
end

function NarciCustomScrollBarMixin:SetRange(fullRange, changeThumbHeight)
    local ScrollFrame = self:GetParent();
    local thumbHeight = 16;
    local barHeight = self:GetHeight() or 0;

    if not fullRange or fullRange <= 0.5 then
        fullRange = 0;
        self:Hide();
    else
        self:SetMinMaxValues(0, fullRange);
        if changeThumbHeight then
            thumbHeight = math.floor(barHeight^2 / fullRange);
            if thumbHeight > barHeight - 24 then
                thumbHeight = barHeight - 24;
            end
            if thumbHeight < 16 then
                thumbHeight = 16;
            end
        end
        self.ThumbTexture:SetHeight(thumbHeight);
    end

    self.thumbRange = barHeight - thumbHeight;
    ScrollFrame.range = fullRange;
end

function NarciCustomScrollBarMixin:OnMinMaxChanged(min, max)

end


--------------------------------------------------------------------------------------------------
NarciInteractableModelMixin = {};

local function UpdateCameraPosition(model)
    model:SetCameraPosition(model.cameraDistance * math.sin(model.cameraPitch), 0, model.cameraDistance * math.cos(model.cameraPitch) + 0.8);
end

local function UpdateCameraPitch(model, pitch)
	model.cameraPitch = pitch;
	UpdateCameraPosition(model);
end

function NarciInteractableModelMixin:OnLoad()
	self.rotation = 0.61;
	self:SetFacing(self.rotation);
    self:MakeCurrentCameraCustom();
    self:SetCameraTarget(0, 0, 0);
    self.cameraPitch = self:GetPitch();
    self.cameraDistance = self:GetCameraDistance()
end

function NarciInteractableModelMixin:StartPanning()
	self.isAltDown = IsAltKeyDown();
	self.panning = true;
	local posX, posY, posZ = self:GetPosition();
	self.posX = posX;
	self.posY = posY;
	self.posZ = posZ;
	local cursorX, cursorY = GetCursorPosition();
	self.cursorX = cursorX;
	self.cursorY = cursorY;
	self.zoomCursorStartX, self.zoomCursorStartY = cursorX, cursorY;
end

function NarciInteractableModelMixin:OnMouseWheel(delta)
	if not self:HasCustomCamera() then return; end
    self.cameraDistance = self.cameraDistance - delta * 0.25
	UpdateCameraPosition(self);
end

function NarciInteractableModelMixin:OnMouseUp(button)
	if ( button == "RightButton" and self.panning ) then
		self.panning = false;
	elseif ( self.mouseDown ) then
		if ( not button or button == "LeftButton" ) then
			self.mouseDown = false;
		end
	end
end

function NarciInteractableModelMixin:OnMouseDown(button)
	if ( button == "RightButton" and not self.mouseDown ) then
		self:StartPanning();
	else
		if ( not button or button == "LeftButton" ) then
			self.mouseDown = true;
			self.rotationCursorStart, self.cameraPitchCursorStart = GetCursorPosition();
		end
	end
end

function NarciInteractableModelMixin:OnModelLoaded()
    self:MakeCurrentCameraCustom();
    self:SetCameraTarget(0, 0, 0);
    self.cameraDistance = self:GetCameraDistance();
end

function NarciInteractableModelMixin:OnHide()
	if ( self.panning ) then
		self.panning = false;
	end
	self.mouseDown = false;
end

function NarciInteractableModelMixin:OnUpdate()
	-- Mouse drag rotation
	if (self.mouseDown) then
		if ( self.rotationCursorStart ) then
			local x, y = GetCursorPosition();
			local diffX = (x - self.rotationCursorStart) * 0.01;	--MODELFRAME_DRAG_ROTATION_CONSTANT
			local diffY = (y - self.cameraPitchCursorStart) * 0.02;
			self.rotationCursorStart, self.cameraPitchCursorStart = GetCursorPosition();

			if not IsAltKeyDown() then
				--Rotate Character
				self.rotation = self.rotation + diffX;
				if ( self.rotation < 0 ) then
					self.rotation = self.rotation + (2 * pi);
				end
				if ( self.rotation > (2 * pi) ) then
					self.rotation = self.rotation - (2 * pi);
				end
				self:SetFacing(self.rotation, false);
			else
				--Rotate Camera (pitch)
				self.cameraPitch = self.cameraPitch + diffY;
				if ( self.cameraPitch <= (0 + 0.01)) then
					self.cameraPitch = 0.01;
				end
				if ( self.cameraPitch >= ( pi - 0.01)) then
					self.cameraPitch = pi - 0.01;
				end
				UpdateCameraPitch(self, self.cameraPitch);
			end
		end
	elseif ( self.panning ) then
		local isAltDown = IsAltKeyDown();
		if isAltDown ~= self.isAltDown then
			--Reset cursor positions
			self:StartPanning();
		end
		local modelScale = self:GetModelScale();
		local cursorX, cursorY = GetCursorPosition();
		local scale = UIParent:GetEffectiveScale();
		local diff = (cursorX - self.zoomCursorStartX) + (cursorY - self.zoomCursorStartY);
		self.zoomCursorStartX, self.zoomCursorStartY = GetCursorPosition();
		if not isAltDown then
			local zoom = sqrt(sqrt(self.cameraDistance));
			local transformationRatio = 0.00002* 40 * 2 ^ (zoom * 2) * scale / modelScale;
			local dx = (cursorX - self.cursorX) * transformationRatio;
			local dy = (cursorY - self.cursorY) * transformationRatio;
			local posY = self.posY + dx;
			local posZ = self.posZ + dy;
			self:SetPosition(self.posX, posY, posZ);
			--print("Y: "..posY.." Z: "..posZ.." Dis: "..self.cameraDistance)
		else
			self.cameraDistance = self.cameraDistance - diff * 0.01;
			UpdateCameraPosition(self);
		end
	end
end

--------------------------------------------------------------------------------------------------
--Name: Search Box
local function OnDeletePressed(widget, key)
    if key == "DELETE" then
        widget:ClearText(true);
        return true
    end
end

NarciSearchBoxSharedMixin = {};

function NarciSearchBoxSharedMixin:OnLoad()
    local delayedSearch = NarciAPI_CreateAnimationFrame(0.5);
    self.delayedSearch = delayedSearch;
    delayedSearch:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            if self.onSearchFunc then
                self.onSearchFunc( self:GetText() );
            end
        end
    end)
    self:OnLeave();
    self.onDeletePressedFunc = OnDeletePressed;
    self.onKeyDownFunc = OnDeletePressed;
end

function NarciSearchBoxSharedMixin:OnShow()
    if self.noAutoFocus then return end;
    self:SetFocus();
end

function NarciSearchBoxSharedMixin:OnHide()
    self.delayedSearch:Hide();
end

function NarciSearchBoxSharedMixin:OnTextChanged(isUserInput)
    local str = self:GetText();
    if str and str ~= "" then
        self.DefaultText:Hide();
        self.EraseButton:Show();
    else
        self.DefaultText:Show();
        self.EraseButton:Hide();
    end

    if isUserInput then
        self:Search(true);
    end
    self.NoMatchText:Hide();
end

function NarciSearchBoxSharedMixin:QuitEdit()
    self:ClearFocus();
end

function NarciSearchBoxSharedMixin:OnTabPressed()
    self:HighlightText();
end

function NarciSearchBoxSharedMixin:OnEditFocusGained()
    self:HighlightText();
    self:SetScript("OnKeyDown", self.onKeyDownFunc);
end

function NarciSearchBoxSharedMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    self:OnLeave();
    self:SetScript("OnKeyDown", nil);

    if self:IsMouseOver() and IsMouseButtonDown("LeftButton") then
        self.EraseButton.isEditing = true;
    else
        self.EraseButton.isEditing = false;
    end
end

function NarciSearchBoxSharedMixin:Search(on)
    self.delayedSearch:Hide();
    if on then
        self.delayedSearch:Show();
    end
end

function NarciSearchBoxSharedMixin:ClearText(reset)
    self:SetText("");
    self.DefaultText:Show();
    self.EraseButton:Hide();
end

function NarciSearchBoxSharedMixin:OnEnter()
    self.DefaultText:SetTextColor(0.52, 0.52, 0.52);
end

function NarciSearchBoxSharedMixin:OnLeave()
    if not self:IsMouseOver() then
        self.DefaultText:SetTextColor(0.42, 0.42, 0.42);
    end
end

function NarciSearchBoxSharedMixin:GetValidText()
    local str = strtrim(self:GetText());
    if str ~= "" then
        return str
    end
end


--------------------------------------------------------------------------------------------------
--Show a L/R mark next to the item border

NarciTransmogSlotDirectionMarkMixin = {};

function NarciTransmogSlotDirectionMarkMixin:SetDirection(direction)
    if direction == 1 then
        self.tooltip = LEFTSHOULDERSLOT or "Left Shoulder";
        self.Letter:SetTexCoord(0, 0.5, 0, 0.5);
        self.Triangle:SetTexCoord(0, 0.5, 0.5, 1);
    else
        self.tooltip = RIGHTSHOULDERSLOT or "Right Shoulder";
        self.Letter:SetTexCoord(0.5, 1, 0, 0.5);
        self.Triangle:SetTexCoord(0.5, 1, 0.5, 1);
    end
end

function NarciTransmogSlotDirectionMarkMixin:SetColor(r, g, b)
    self.Letter:SetVertexColor(r, g, b);
end

function NarciTransmogSlotDirectionMarkMixin:SetQualityColor(itemQuality)
    self:SetColor(NarciAPI.GetItemQualityColor(itemQuality));
end

function NarciTransmogSlotDirectionMarkMixin:OnEnter()

end

function NarciTransmogSlotDirectionMarkMixin:OnLeave()

end

function NarciTransmogSlotDirectionMarkMixin:OnHide()

end


--------------------------------------------------------------------------------------------------
local CreateKeyChordStringUsingMetaKeyState = CreateKeyChordStringUsingMetaKeyState;
--Name: Clipboard
--Notes: Highlight the border when gaining focus. Show visual feedback (glow) after pressing Ctrl+C

local HotkeyListener = CreateFrame("Frame");
HotkeyListener:SetFrameStrata("TOOLTIP");
HotkeyListener:Hide();
HotkeyListener:SetPropagateKeyboardInput(true);
HotkeyListener:SetScript("OnKeyDown", function(self, key)
    local keys = CreateKeyChordStringUsingMetaKeyState(key);
    if keys == "CTRL-C" or key == "COMMAND-C" then
        if self.parentEditBox then
            self:Hide();
            After(0, function()
                --Texts won't be copied if the editbox hides immediately
                self.parentEditBox:OnSuccess();
            end);
        end
    end
end);

function HotkeyListener:SetParentObject(editbox)
    self.parentEditBox = editbox;
    self:Show();
end

function HotkeyListener:Stop(editbox)
    if self.parentEditBox == editbox then
        self:Hide();
    end
end

NarciResponsiveEditBoxSharedMixin = {};

function NarciResponsiveEditBoxSharedMixin:OnEditFocusGained()
    self:HighlightText();
    if self.LockHighlight then
        self:LockHighlight(true);
    else
        self:GetParent():GetParent():LockHighlight(true);
    end

    HotkeyListener:SetParentObject(self);
end

function NarciResponsiveEditBoxSharedMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    if self.LockHighlight then
        self:LockHighlight(false);
    else
        self:GetParent():GetParent():LockHighlight(false);
    end
    HotkeyListener:Stop(self);
end

function NarciResponsiveEditBoxSharedMixin:OnSuccess()
    if self.Glow then
        self:Glow(false);
    else
        self:GetParent():GetParent():Glow();
    end
    self:QuitEdit();
    if self.onCopiedCallback then
        self.onCopiedCallback(self);
    end
end

function NarciResponsiveEditBoxSharedMixin:QuitEdit()
    self:ClearFocus();
end

function NarciResponsiveEditBoxSharedMixin:OnHide()
    self:QuitEdit();
    self.numInput = nil;
    self:StopAnimating();
end

function NarciResponsiveEditBoxSharedMixin:OnTextChanged(userInput)

end

function NarciResponsiveEditBoxSharedMixin:SetDefaultCursorPosition(offset)
    self:SetCursorPosition(offset);
    self.defaultCursorPosition = offset;
end

--Subtype: The editbox itself has a border
NarciResponsiveClipboardMixin = CreateFromMixins(NarciFrameBorderMixin, NarciResponsiveEditBoxSharedMixin);

function NarciResponsiveClipboardMixin:OnTextChanged(userInput)
    if userInput then
        self:SetText(self.copiedText);
        if self.defaultCursorPosition then
            self:SetCursorPosition(self.defaultCursorPosition);
        end
        if not self.numInput then
            self.numInput = 0;
        end
        self.numInput = self.numInput + 1;
        if self.numInput > 3 then
            self.numInput = nil;
            self:QuitEdit();
        end
    else
        self.copiedText = self:GetText();
    end
end

function NarciResponsiveEditBoxSharedMixin:OnHide()
    self:QuitEdit();
    self.copiedText = nil;
end

--Subtype: Frame-ScrollFrame-EditBox
NarciScrollEditBoxMixin = CreateFromMixins(NarciFrameBorderMixin);

function NarciScrollEditBoxMixin:SetText(str)
    self.ScrollFrame.EditBox:SetText(str);
    After(0, function()
        self:UpdateScrollRange(true);
    end);
end

function NarciScrollEditBoxMixin:SetFocus()
    self.ScrollFrame.EditBox:SetFocus();
end

function NarciScrollEditBoxMixin:ClearFocus()
    self.ScrollFrame.EditBox:ClearFocus();
end

function NarciScrollEditBoxMixin:UpdateScrollRange(resetOffset)
    if resetOffset then
        self.ScrollFrame.scrollBar:SetValue(0);
    end

    local editBoxHeight = self.ScrollFrame.EditBox:GetHeight();
    local scrollFrameHeight = self.ScrollFrame:GetHeight();
    local range = math.floor(editBoxHeight - scrollFrameHeight + 0.5);
    self.ScrollFrame.scrollBar:SetRange(range, true);
end

function NarciScrollEditBoxMixin:OnMouseDown()
    self.ScrollFrame.EditBox:SetFocus();
end

function NarciScrollEditBoxMixin:PostLoad()
    self:OnLoad();
    self.ScrollFrame.scrollBar:OnLoad();

    self.ScrollFrame.buttonHeight = 14;
    self.ScrollFrame.scrollBar:SetRange(0, true);
    NarciAPI_SmoothScroll_Initialization(self.ScrollFrame, nil, nil, 2, 0.14);
end

function NarciScrollEditBoxMixin:SetFontObject(fontObject)
    self.ScrollFrame.EditBox:SetFontObject(fontObject);
end

function NarciScrollEditBoxMixin:SetFontColor(r, g, b)
    self.ScrollFrame.EditBox:SetTextColor(r, g, b);
end

--------------------------------------------------------------------------------------------------
--Notes: Hide the frame if user clicks anywhere other than the frame itself or the switch used to open that frame.

NarciAutoCloseFrameMixin = {};

function NarciAutoCloseFrameMixin:OnShow()
    if not self.setParentObjectManually then
        self.parentObject = self:GetParent();
    end
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");

    if self.autoClose then
        self.AutoCloseTimer:Play();
    end
end

function NarciAutoCloseFrameMixin:OnHide()
    self.parentObject = nil;
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self.AutoCloseTimer:Stop();
    self:Hide();
end

function NarciAutoCloseFrameMixin:OnEvent(event)
    if self:IsMouseOver() then
        self:RestartTimer();
    else
        if (not self.parentObject) or (self.parentObject and not self.parentObject:IsMouseOver()) then
            self:Hide();
        else
            self:RestartTimer();
        end
    end
end

function NarciAutoCloseFrameMixin:RestartTimer()
    self.AutoCloseTimer:Stop();
    if self.autoClose then
        self.AutoCloseTimer:Play();
    end
end

function NarciAutoCloseFrameMixin:OnTimerFinished()
    self:OnEvent("GLOBAL_MOUSE_DOWN");
end

function NarciAutoCloseFrameMixin:Toggle()
    self:SetShown(not self:IsShown());
end


--------------------------------------------------------------------------------------------------
--Simple Line Slider

NarciVerticalLineSliderMixin = {};

function NarciVerticalLineSliderMixin:OnLoad()
    self.Thumb:SetVertexColor(0.5, 0.5, 0.5);
    self.Background:SetVertexColor(0.25, 0.25, 0.25);
    self.Background:SetAlpha(0.4);
end

function NarciVerticalLineSliderMixin:OnEnter()
    self:FadeIn();
    self:RegisterEvent("GLOBAL_MOUSE_UP");
end

function NarciVerticalLineSliderMixin:OnLeave()
    if not self:IsDraggingThumb() then
        self:FadeOut();
        self:UnregisterEvent("GLOBAL_MOUSE_UP");
    end
end

function NarciVerticalLineSliderMixin:FadeIn()
    FadeFrame(self.Background, 0.25, 1);
    self.Thumb:SetVertexColor(0.8, 0.8, 0.8);
end

function NarciVerticalLineSliderMixin:FadeOut()
    FadeFrame(self.Background, 0.25, 0.4);
    self.Thumb:SetVertexColor(0.5, 0.5, 0.5);
end

function NarciVerticalLineSliderMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_UP");
end

function NarciVerticalLineSliderMixin:OnEvent()
    if (not self:IsMouseMotionFocus()) then
        self:OnLeave();
    end
end


--------------------------------------------------------------------------------------------------
local _, screenHeight = GetPhysicalScreenSize();
local PIXEL = (768/screenHeight);
screenHeight = nil;

NarciLineBorderMixin = {};

function NarciLineBorderMixin:SetWeight(weight)
    self.weight = weight;
end

function NarciLineBorderMixin:SetColor(r, g, b)
    self.Stroke:SetColorTexture(r, g, b);   --default color is 0.25
end

function NarciLineBorderMixin:OnLoad()
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    self:SetWeight(2);
    self:UpdateStroke();
end

function NarciLineBorderMixin:OnShow()
    self:UpdateStroke();
end

function NarciLineBorderMixin:UpdateStroke()
    local scale = self:GetEffectiveScale();
    if scale ~= self.scale then
        self.scale = scale;
    else
        return
    end
    local a = (self.weight or 1) * PIXEL / scale;
    self.Exclusion:ClearAllPoints();
    self.Exclusion:SetPoint("TOPLEFT", self, "TOPLEFT", a, -a);
    self.Exclusion:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -a, a);
end



--------------------------------------------------------------------------------------------------
NarciChainAnimationMixin = {};

function NarciChainAnimationMixin:Initialize(size, isLinked)
    local offset = 4;
    local unchainedOffset = 8;
    local side = 24;
    local tex = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\Chain";

    self:SetScale(size / side);
    self.isLinked = isLinked;

    self.chains = {
        self.UpTop, self.DownTop, self.UpBottom, self.DownBottom,
    };
    self.unchains = {
        self.ChainShardUp, self.ChainShardDown, self.UpBroken, self.DownBroken
    };

    for i = 1, #self.chains do
        self.chains[i]:SetTexture(tex, nil, nil, "TRILINEAR");
        self.chains[i]:SetSize(side, side);
        if i % 2 == 1 then
            self.chains[i]:SetPoint("CENTER", self, "CENTER", offset, offset);
        else
            self.chains[i]:SetPoint("CENTER", self, "CENTER", -offset, -offset);
        end
    end

    self.UpBroken:SetSize(side, side);
    self.UpBroken:SetTexture(tex, nil, nil, "TRILINEAR");
    self.UpBroken:SetPoint("CENTER", self, "CENTER", unchainedOffset, unchainedOffset);
    self.DownBroken:SetSize(side, side);
    self.DownBroken:SetTexture(tex, nil, nil, "TRILINEAR");
    self.DownBroken:SetPoint("CENTER", self, "CENTER", -unchainedOffset, -unchainedOffset);

    local tex2 = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\ChainShard";
    self.ChainShardUp:SetSize(side/2, side/2);
    self.ChainShardUp:SetTexture(tex2, nil, nil, "TRILINEAR");
    self.ChainShardDown:SetSize(side/2, side/2);
    self.ChainShardDown:SetTexture(tex2, nil, nil, "TRILINEAR");

    local tex3 = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\ChainWave";
    self.WaveExpand:SetSize(side/2, side/2);
    self.WaveExpand:SetTexture(tex3, nil, nil, "TRILINEAR");

    for i = 1, #self.chains do
        self.chains[i]:SetShown(isLinked);
    end
    for i = 1, #self.unchains do
        self.unchains[i]:SetShown(not isLinked);
    end
end

function NarciChainAnimationMixin:Switch()
    self:StopAnimating();
    local isLinked = not self.isLinked;
    self.isLinked = isLinked;
    if isLinked then
        for i = 1, #self.unchains do
            self.unchains[i]:Hide();
        end
        for i = 1, #self.chains do
            self.chains[i]:Show();
            self.chains[i].Link:Play();
        end
    else
        for i = 1, #self.unchains do
            self.unchains[i]:Show();
            self.unchains[i].Unlink:Play();
        end
        for i = 1, #self.chains do
            self.chains[i]:Hide();
        end
        self.WaveExpand.Unlink:Play();
    end
    --[[
    if not self.isPlayingSound then
        self.isPlayingSound = true;
        After(0.5, function() self.isPlayingSound = nil end);
        if isLinked then
            PlaySound(1188, "SFX", false);
        else
            PlaySound(112052, "SFX", false);
        end
    end
    --]]
end


---------------------------------------------------------------------
--Create a rectangle with stroke to indicate the area is interactable
NarciInteractableAreaIndicatorMixin = {};

function NarciInteractableAreaIndicatorMixin:OnLoad()
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    self:UpdateStroke();
end

function NarciInteractableAreaIndicatorMixin:SetStrokeSize(pixel)
    self.pixel = pixel;
    self:UpdateStroke();
end

function NarciInteractableAreaIndicatorMixin:SetStrokeColor(r, g, b)
    self.Stroke:SetColorTexture(r, g, b);
end

function NarciInteractableAreaIndicatorMixin:OnShow()
    local scale = self:GetEffectiveScale();
    if scale ~= self.scale then
        self:UpdateStroke();
    end
end

function NarciInteractableAreaIndicatorMixin:UpdateStroke()
    local pixelSize = NarciAPI.GetPixelForWidget(self, self.pixel or 2);
    self.Exclusion:SetPoint("TOPLEFT", self, "TOPLEFT", pixelSize, -pixelSize);
    self.Exclusion:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -pixelSize, pixelSize);
end

function NarciInteractableAreaIndicatorMixin:OnEnter()
    self.Stroke:Show();
end

function NarciInteractableAreaIndicatorMixin:OnLeave()
    self.Stroke:Hide();
end



---------------------------------------------------------------------
--Keybinding
--internalAction: hotkeys used within Narcissus
--externalAction: hotkeys used to open Narcissus panels
local KeyBindingButtonOverlay;

local function ReleaseOverlay()
    if KeyBindingButtonOverlay then
        KeyBindingButtonOverlay:Hide();
        KeyBindingButtonOverlay:StopAnimating();
    end
end

local function AnchorOverlayToBindingButton(button, colorType, descriptionText)
    --colorType 1 red   2 yellow    3 green
    local f = KeyBindingButtonOverlay;
    if not f then
        KeyBindingButtonOverlay = CreateFrame("Frame", "Test", button, "NarciLineBorderTemplate");
        f = KeyBindingButtonOverlay;
        f.Description = f:CreateFontString(nil, "OVERLAY", "NarciNonInteractiveFont");
        f.Description:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -6);
        f:SetScript("OnHide", ReleaseOverlay);

        f.ConfirmButton = CreateFrame("Button", nil, f, "NarciConfirmButtonTemplate");
        f.ConfirmButton:SetPoint("LEFT", f, "RIGHT", 6, 0);

        local ag = f:CreateAnimationGroup();
        f.FadeOut = ag;
        ag:SetScript("OnFinished", function()
            f:Hide();
        end);
        local a1 = ag:CreateAnimation("Alpha");
        a1:SetDuration(0.5);
        a1:SetFromAlpha(1);
        a1:SetToAlpha(0);
        a1:SetOrder(1);
        a1:SetStartDelay(1.5);
    end

    f:Hide();
    f:ClearAllPoints();
    f:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
    f:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
    f:SetParent(button);
    f.ConfirmButton.parentObject = button;

    f.Description:SetText(descriptionText);
    if descriptionText then
        f.Description:Show();
    else
        f.Description:Hide();
    end
    if colorType == 1 then
        f:SetColor(0.9333, 0.1961, 0.1412);
        f.Description:SetTextColor(0.9333, 0.1961, 0.1412);
        f.FadeOut:Play();
        f.ConfirmButton:Hide();
    elseif colorType == 2 then
        f:SetColor(0.9882, 0.9294, 0);
        f.Description:SetTextColor(0.9882, 0.9294, 0);
        f.ConfirmButton:Show();
    elseif colorType == 3 then
        f:SetColor(0.4862, 0.7725, 0.4627)
        f.Description:SetTextColor(0.4862, 0.7725, 0.4627);
        f.FadeOut:Play();
        f.ConfirmButton:Hide();
    end

    f:SetAlpha(1);
    f:Show();
end

local function GetInternalBindingKey(self)
    if self.actionName then
        return NarcissusDB[self.actionName] or NOT_BOUND
    else
        return "No Action"
    end
end

local function GetExternalBindingKey(self)
    if self.actionName then
        return GetBindingKey(self.actionName) or NOT_BOUND
    else
        return "No Action"
    end
end

local function ClearBindingKey(actionName)
    local key1, key2 = GetBindingKey(actionName);
    if key1 then
        SetBinding(key1, nil, 1);
    end
    if key2 then
        SetBinding(key2, nil, 1);
    end
    SaveBindings(1);
end


NarciGenericKeyBindingButtonMixin = {};

local function IsExitKey(key)
    return key == "ESCAPE" or key == "SPACE" or key == "ENTER" or key == "BACKSPACE"
end

local function InternalAction_OnKeydown(self, key)
    if IsExitKey(key) then
        self:ExitKeyBinding();
        return
    end

    if self.actionName then
        self:ExitKeyBinding(true);
        NarcissusDB[self.actionName] = key;
    end
end

local function ExternalAction_OnKeydown(self, key)
    if IsExitKey(key) then
        self:ExitKeyBinding();
        return
    end

    local KeyText = CreateKeyChordStringUsingMetaKeyState(key);

    self.ButtonText:SetText(KeyText);
    self.key = KeyText;
    if not IsKeyPressIgnoredForBinding(key) then
        self:VerifyKey();
    end
end

local function ExternalAction_OnKeyUp(self, key)
    self:VerifyKey();
end

local function KeyBingdingButton_OnEvent(self, event)
    if not (self:IsMouseOver() or ( KeyBindingButtonOverlay and KeyBindingButtonOverlay.ConfirmButton:IsMouseOver() )) then
        self:ExitKeyBinding();
    end
end


function NarciGenericKeyBindingButtonMixin:OnEnter()
    self.Border:SetColor(0.8, 0.8, 0.8);
end

function NarciGenericKeyBindingButtonMixin:OnLeave()
    if not self.isOn then
        self.Border:SetColor(0.25, 0.25, 0.25);
    end
end

function NarciGenericKeyBindingButtonMixin:OnLoad()
    if self.internalActionName then
        self:SetBindingActionInternal(self.internalActionName);
        self.internalActionName = nil;
    elseif self.externalActionName then
        self:SetBindingActionExternal(self.externalActionName);
        self.externalActionName = nil;
    end
end

function NarciGenericKeyBindingButtonMixin:SetBindingActionInternal(actionName)
    self.actionName = actionName;
    self.onKeyDownFunc = InternalAction_OnKeydown;
    self.onKeyUpFunc = EmptyFunc;
    self.getBindingFunc = GetInternalBindingKey;
end

function NarciGenericKeyBindingButtonMixin:SetBindingActionExternal(actionName)
    self.actionName = actionName;
    self.onKeyDownFunc = ExternalAction_OnKeydown;
    self.onKeyUpFunc = ExternalAction_OnKeyUp;
    self.getBindingFunc = GetExternalBindingKey;
end

function NarciGenericKeyBindingButtonMixin:ResetVisualAndScript()
    self.isOn = nil;
    if not self:IsVisible() or not self:IsMouseOver() then
        self.Border:SetColor(0.25, 0.25, 0.25);
    end
    self.ButtonText:SetTextColor(1, 1, 1);
    self.ButtonText:SetShadowColor(0, 0, 0);
    self.ButtonText:SetShadowOffset(0.6, -0.6);
    self.Background:SetColorTexture(0, 0, 0);
    self:SetPropagateKeyboardInput(true)
    self:SetScript("OnKeyDown", nil);
    self:SetScript("OnUpdate", nil);
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciGenericKeyBindingButtonMixin:ExitKeyBinding(success)
    self.key = nil;
    After(0, function()
        self:ResetVisualAndScript();
        self:GetBindingKey();
    end)
    if success then
        AnchorOverlayToBindingButton(self, 3, KEY_BOUND);
    else
        ReleaseOverlay();
    end
end

function NarciGenericKeyBindingButtonMixin:VerifyKey(override)
    local key = self.key;
    if not key then
        return;
    end
    if key == "SHIFT" or key=="ALT" or key=="CTRL" then
        self.key = nil;
        self:ExitKeyBinding();
        AnchorOverlayToBindingButton(self, 1, NARCI_INVALID_KEY);
        return false
    else
        local action = GetBindingAction(key);
        if (action and action ~= "" and action ~= self.actionName) and not override then
            AnchorOverlayToBindingButton(self, 2, Narci.L["Override"].." "..GetBindingName(action).." ?");
            return true
        else
            ClearBindingKey(self.actionName);
            if SetBinding(key, self.actionName, 1) then
                SaveBindings(1);    --account wide
                self:ExitKeyBinding(true);
            else
                self:ExitKeyBinding();
                AnchorOverlayToBindingButton(self, 1, ERROR_CAPS);
            end
            return false;
        end
    end
end

function NarciGenericKeyBindingButtonMixin:GetBindingKey()
    self.ButtonText:SetText( self.getBindingFunc(self) );
end

function NarciGenericKeyBindingButtonMixin:UnbindKey()
    self:ResetVisualAndScript();
    if self.defaultKey then
        self.ButtonText:SetText(self.defaultKey or NOT_BOUND);
        NarcissusDB[self.actionName] = self.defaultKey;
    elseif self.actionName then
        ClearBindingKey(self.actionName);

    end
end

function NarciGenericKeyBindingButtonMixin:OnClick(button)
    ReleaseOverlay();
    self.isOn = not self.isOn;

    if button == "LeftButton" then
        if self.isOn then
            self.ButtonText:SetTextColor(0, 0, 0);
            self.ButtonText:SetShadowColor(1, 1, 1);
            self.ButtonText:SetShadowOffset(0.6, -0.6);
            self.Background:SetColorTexture(0.8, 0.8, 0.8);
            self:SetScript("OnKeyDown", self.onKeyDownFunc);
            self:SetScript("OnKeyUp", self.onKeyUpFunc);
            self:SetScript("OnEvent", KeyBingdingButton_OnEvent);
            self:RegisterEvent("GLOBAL_MOUSE_DOWN");
            self:SetPropagateKeyboardInput(false);
        else
            self:ExitKeyBinding();
        end
    else
        self:UnbindKey();
        self:ExitKeyBinding();
    end
end

function NarciGenericKeyBindingButtonMixin:OnHide()
    if self.isOn then
        self:ResetVisualAndScript();
    end
end

function NarciGenericKeyBindingButtonMixin:OnShow()
    self:GetBindingKey();
end


NarciQuickFavoriteButtonMixin = {};

function NarciQuickFavoriteButtonMixin:SetIconSize(size)
    self.iconSize = size;
    self.Icon:SetSize(size, size);
    self.Bling:SetSize(size, size);
    self.Icon:SetTexCoord(0.5, 0.75, 0.25, 0.5);
    self.favTooltip = Narci.L["Favorites Add"];
    self.unfavTooltip = Narci.L["Favorites Remove"];
    self.isFav = false;
end

function NarciQuickFavoriteButtonMixin:SetFavorite(isFavorite)
    if isFavorite then
        self.isFav = true;
        self.Icon:SetTexCoord(0.75, 1, 0.25, 0.5);
        self.Icon:SetAlpha(1);
    else
        self.isFav = false;
        self.Icon:SetTexCoord(0.5, 0.75, 0.25, 0.5);
        self.Icon:SetAlpha(0.4);
    end
end

function NarciQuickFavoriteButtonMixin:PlayVisual()
    self:StopAnimating();
    if self.isFav then
        self.Icon:SetTexCoord(0.75, 1, 0.25, 0.5);
        self.parent.Star:Show();
        self.Bling.animIn:Play();
    else
        self.Icon:SetTexCoord(0.5, 0.75, 0.25, 0.5);
        self.parent.Star:Hide();
    end
end

function NarciQuickFavoriteButtonMixin:OnEnter()
    self.Icon:SetAlpha(1);
    if self.isFav then
        NarciTooltip:NewText(self, self.unfavTooltip, nil, nil, 1);
    else
        NarciTooltip:NewText(self, self.favTooltip, nil, nil, 1);
    end
end

function NarciQuickFavoriteButtonMixin:OnLeave()
    NarciTooltip:HideTooltip();
    if not self.isFav then
        self.Icon:SetAlpha(0.6);
    end
end

function NarciQuickFavoriteButtonMixin:OnHide()
    self:StopAnimating();
end

function NarciQuickFavoriteButtonMixin:OnMouseDown()
    self.Icon:SetSize(self.iconSize - 2, self.iconSize - 2);
    NarciTooltip:HideTooltip();
end

function NarciQuickFavoriteButtonMixin:OnMouseUp()
    self.Icon:SetSize(self.iconSize, self.iconSize);
end

function NarciQuickFavoriteButtonMixin:OnDoubleClick()

end


NarciGenericInfoButtonMixin = {};   --Question Mark Button that displays extra info when moused-over

function NarciGenericInfoButtonMixin:OnEnter()
    local c = self.HighlightColor;
    if c then
        self.Icon:SetVertexColor(c[1], c[2], c[3]);
    else
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    end

    SetCursor("Interface/CURSOR/"..(self.cursorFile or "UnableQuestTurnIn.blp"));

    local tooltip = self:GetTooltip();
    if self.usePrivateTooltip then
        tooltip:ShowButtonTooltip(self);
    else
        if tooltip and self.tooltipText then
            if tooltip.SetOwner then
                tooltip:SetOwner(self, "ANCHOR_NONE");
            end
            tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", self.tooltipOffsetX or 4, 0);
            if tooltip.SetPadding then
                tooltip:SetPadding(5, 5, 5, 5);
            end
            if tooltip.AddLine then
                tooltip:AddLine(self.tooltipText, 1, 1, 1, 1, true);
            elseif tooltip.SetTooltipText then
                tooltip:SetTooltipText(self.tooltipText, 1, 1, 1);
            end
            tooltip:Show();
            --tooltip.TextLeft1:SetSpacing(2);
            --tooltip:SetMinimumWidth(300);
        end
    end
end

function NarciGenericInfoButtonMixin:OnLeave()
    local c = self.NormalColor;
    if c then
        self.Icon:SetVertexColor(c[1], c[2], c[3]);
    else
        self.Icon:SetVertexColor(0.4, 0.4, 0.4);
    end

    ResetCursor();

    local tooltip = self:GetTooltip();
    if tooltip then
        tooltip:Hide();
    end
end

function NarciGenericInfoButtonMixin:GetTooltip()
    if self.usePrivateTooltip then
        return _G["NarciTooltip"];
    elseif self.tooltipName then
        return _G[self.tooltipName]
    else
        return self.tooltip
    end
end

function NarciGenericInfoButtonMixin:SetNormalColor(r, g, b)
    self.NormalColor = {r, g, b};
    self.Icon:SetVertexColor(r, g, b);
end

function NarciGenericInfoButtonMixin:SetHighlightColor(r, g, b)
    self.HighlightColor = {r, g, b};
end

function NarciGenericInfoButtonMixin:SetVisualType(visualType)
    --type: 1 (no shadow)   2 (shadow)
    if visualType == 2 then
        self.Icon:SetTexCoord(0.5, 1, 0, 1);
    else
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
    end
end

function NarciGenericInfoButtonMixin:SetCursorColor(colorType)
    if colorType == 2 then
        self.cursorFile = "questrepeatable.blp";
    else
        self.cursorFile = nil;
    end
end

function NarciGenericInfoButtonMixin:SetUsePrivateTooltip(state, tooltipText)
    self.usePrivateTooltip = state;
    if tooltipText then
        if state then
            self.tooltipDescription = tooltipText;
        else
            self:SetTooltipText(tooltipText);
        end
    end
end

function NarciGenericInfoButtonMixin:SetTooltipText(tooltipText)
    self.tooltipText = tooltipText;
end

TEMPS = nil;