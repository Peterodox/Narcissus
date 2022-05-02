local abs = math.abs;
local max = math.max;
local min = math.min;
local floor = math.floor;

local IsShiftKeyDown = IsShiftKeyDown;      --For acceleration

local _, SCREEN_HEIGHT = GetPhysicalScreenSize();
local PIXEL_RATIO = 768 / SCREEN_HEIGHT;

local function Driver_OnHide(self)
    self.isScrolling = nil;
end

local function Driver_OnUpdate(self, elapsed)
    local value = self.bar:GetValue();
    local step = max(abs(value - self.toValue)*(self.speed)*(elapsed*60), self.minOffset);
    local remainedStep;
    if ( self.delta == 1 ) then
        --Up
        remainedStep = min(self.toValue - value, 0);
        if - remainedStep <= (self.minOffset) then
            self.isScrolling = nil;
            self:Hide();
            self.bar:SetValue(self.toValue);
            if self.onScrollFinishedFunc then
                self.onScrollFinishedFunc();
            end
            self.toValue = nil;
        else
            self.bar:SetValue(max(0, value - step));
        end
	else
        remainedStep = max(self.toValue - value, 0);
        if remainedStep <= (self.minOffset) then
            self.isScrolling = nil;
            self:Hide();
            self.bar:SetValue(self.toValue);
            if self.onScrollFinishedFunc then
                self.onScrollFinishedFunc();
            end
            self.toValue = nil;
        else
            self.bar:SetValue(min(self.range, value + step));
        end
    end
end

local function ScrollFrame_OnShow(self)
    local uiScale = self:GetEffectiveScale();
    if not uiScale or uiScale == 0 then
        uiScale = 0.6667;
    end
    self.Driver.minOffset = PIXEL_RATIO / uiScale;
end

local function ScrollFrame_OnMouseWheel(self, delta)
    if ( not self.ScrollBar:IsVisible() ) then
        if self.parentScrollFunc then
            self.parentScrollFunc(delta);
        else
            return;
        end
    end
    
    local d = self.Driver;
	d.delta = delta;

	local current = self.ScrollBar:GetValue();
    if not((current <= 0.1 and delta > 0) or (current >= d.range - 0.1 and delta < 0 )) then
        d.isScrolling = true;
        if d.onScrollStartedFunc then
            d.onScrollStartedFunc();
        end
        d:Show();
    else
        return;
	end
	
    local deltaMultiplier = d.deltaMultiplier or 1;
    if IsShiftKeyDown() then
        deltaMultiplier = 2 * deltaMultiplier;
    end

    if not d.toValue then
        d.toValue = current;
    end
    local toValue = floor( (100 * min(max(0, d.toValue - delta * deltaMultiplier * d.buttonHeight), d.range) + 0.5)/100 );
    d.toValue = toValue;

    if d.positionFunc then
        local isTop = toValue <= 0.1;
        local isBottom = toValue >= d.range - 1;
        d.positionFunc(toValue, isTop, isBottom);
    end
end


local ScrollFrameMixin = {};

function ScrollFrameMixin:SetScrollRange(range)
    self.Driver.range = range;
    self.ScrollBar:SetMinMaxValues(0, range);
    self.ScrollBar:SetShown(range > 0.5);
end

function ScrollFrameMixin:SetDeltaMultiplier(multiplier)
    --Travel distance per scroll
    self.Driver.deltaMultiplier = multiplier;
end

function ScrollFrameMixin:SetStepSize(buttonHeight)
    --Travel distance per scroll
    self.Driver.buttonHeight = buttonHeight;
end

function ScrollFrameMixin:SetSpeedMultiplier(multiplier)
    --How fast it scrolls
    self.Driver.speed = multiplier;
end

function ScrollFrameMixin:SetOnValueChangedFunc(onValueChangedFunc)
    self.ScrollBar.onValueChangedFunc = onValueChangedFunc;
end

function ScrollFrameMixin:SetOnScrollStartedFunc(onScrollStartedFunc)
    self.Driver.onScrollStartedFunc = onScrollStartedFunc;
end

function ScrollFrameMixin:SetOnScrollFinishedFunc(onScrollFinishedFunc)
    self.Driver.onScrollFinishedFunc = onScrollFinishedFunc;
end

function ScrollFrameMixin:SetOnResetFunc(onResetFunc)
    self.Driver.onResetFunc = onResetFunc;
end

function ScrollFrameMixin:Reset()
    self.Driver:Hide();
    if self.Driver.onResetFunc then
        self.Driver.onResetFunc();
    else
        if self.ScrollBar:GetValue() == 0 then
            if self.ScrollBar.onValueChangedFunc then
                self.ScrollBar.onValueChangedFunc(0);
            end
        else
            self.ScrollBar:SetValue(0);
        end
    end
end

function ScrollFrameMixin:SetOffset(value)
    self.Driver:Hide();
    self.Driver.toValue = value;
    self.ScrollBar:SetValue(value);
end

function ScrollFrameMixin:ScrollToOffset(offset)
    --Note: Might cause performance issue if Δoffset is too large since button data update more frequently

    local d = self.Driver;
    local current = self.ScrollBar:GetValue();
    local delta;
    if offset > current then
        delta = -1;
    elseif offset < current then
        delta = 1;
    else
        return
    end
	d.delta = delta;

    local toValue = floor( (100 * min(max(0, offset), d.range) + 0.5)/100 );
    d.toValue = toValue;

    if d.positionFunc then
        local isTop = toValue <= 0.1;
        local isBottom = toValue >= d.range - 1;
        d.positionFunc(toValue, isTop, isBottom);
    end
    if d.onScrollStartedFunc then
        d.onScrollStartedFunc();
    end

    d.isScrolling = true;
    d:Show();
end

function ScrollFrameMixin:ScrollByValue(value)
    local current = self.ScrollBar:GetValue();
    local offset = current + value;
    if offset ~= current then
        self:ScrollToOffset(offset);
    end
end

function ScrollFrameMixin:ScrollToWidget(widget, scrollToInvisible)
    local top = self:GetTop();
    local bottom = self:GetBottom();
    local wTop = widget:GetTop();
    local wBottom = widget:GetBottom();
    if scrollToInvisible or ( (wTop > top) and (wBottom < top - 4) ) then
        self:ScrollByValue(top - wTop);
        return true
    else
        if scrollToInvisible or ( (wBottom < bottom) and (wTop > bottom + 4) ) then
            self:ScrollByValue(bottom - wBottom);
            return true
        end
    end
end

function ScrollFrameMixin:ScrollToTop()
    self:ScrollToOffset(0);
end

function ScrollFrameMixin:IsScrolling()
    return self.Driver.isScrolling;
end
---------------------------------------------------------------------
local function ApplySmoothScrollToScrollFrame(scrollFrame)
    if not scrollFrame.Driver then
        for k, v in pairs(ScrollFrameMixin) do
            scrollFrame[k] = v;
        end

        local d = CreateFrame("Frame", nil, scrollFrame);
        scrollFrame.Driver = d;

        local bar = scrollFrame.ScrollBar;
        if not bar then
            bar = CreateFrame("Slider", nil, scrollFrame);
            bar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, 0);
            bar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 1, 0);
            bar:SetMinMaxValues(0, 0);
            scrollFrame.ScrollBar = bar;
        end
        bar:SetValue(0);
        bar:SetValueStep(0.001);
        bar:SetScript("OnValueChanged", function(self, value, userInput)
            scrollFrame:SetVerticalScroll(value);
            if userInput then
                d.toValue = value;
            end
            if self.onValueChangedFunc then
                self.onValueChangedFunc(value);
            end
        end)

        d.toValue = 0;
        d:Hide();
        d:SetScript("OnUpdate", Driver_OnUpdate);
        d:SetScript("OnHide", Driver_OnHide);

        d.minOffset = PIXEL_RATIO / 0.6667;
        d.bar = bar;

        scrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
        scrollFrame:SetScript("OnShow", ScrollFrame_OnShow);
        scrollFrame:SetScrollRange(0);
        scrollFrame:SetSpeedMultiplier(0.14);
        scrollFrame:SetDeltaMultiplier(1);
        local height = scrollFrame:GetHeight();
        local step;
        if height then
            step = height * 0.5;
        else
            step = 64;
        end
        scrollFrame:SetStepSize(step);
    end
end


NarciAPI.CreateSmoothScroll = ApplySmoothScrollToScrollFrame;