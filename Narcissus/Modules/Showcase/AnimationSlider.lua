local _, addon = ...

local GetCursorPosition = GetCursorPosition;

local floor = math.floor;
local function Round(n)
    if n then
        return floor(n + 0.5);
    end
end

local MAX_CAP_OFFSET = 48;

local function GetCapOffset(diff)
    if diff > 0 then
        if diff > MAX_CAP_OFFSET then
            return 12, 1
        else
            local x = diff/MAX_CAP_OFFSET;
            return 12*(1 -(x - 1)^2), x
        end
    elseif diff < 0 then
        diff = -diff;
        if diff > MAX_CAP_OFFSET then
            return -12, -1
        else
            local x = diff/MAX_CAP_OFFSET;
            return 12*((x - 1)^2 - 1), -x
        end
    else
        return 0, 0
    end
end

local function UpdateCursorNotch(self, elapased)
    local x, y = GetCursorPosition();
    local diff = 0;
    local movingRight;
    if x < self.left then
        diff = x - self.left;
        x = self.left;
        movingRight = false;
    elseif x > self.right then
        diff = x - self.right;
        x = self.right;
        movingRight = true;
    end
    self.CursorNotch:SetPoint("CENTER", self, "LEFT", x - self.left, 0);

    if self.isDragging then
        local offset, speedRatio = GetCapOffset(diff);
        self.Thumb:SetPoint("BOTTOM", self, "LEFT", x - self.left, 0);
        self.offset = self.offset + speedRatio * elapased * 200;    --4s/s
        local exceeding;
        if movingRight then
            if not self.movingRight then
                self.movingRight = true;
                self.Tail:ClearAllPoints();
                self.Tail:SetPoint("RIGHT", self, "RIGHT", 0, 0);
                self.Tail:SetTexCoord(1, 0, 0, 1);
            end
        else
            if self.movingRight then
                self.movingRight = nil;
                self.Tail:ClearAllPoints();
                self.Tail:SetPoint("LEFT", self, "LEFT", 0, 0);
                self.Tail:SetTexCoord(0, 1, 0, 1);
            end
        end
        if self.offset < 0 then
            self.offset = 0;
            exceeding = true;
        elseif self.offset > self.maxOffset then
            self.offset = self.maxOffset;
            exceeding = true;
            self.Tail:ClearAllPoints();
            self.Tail:SetPoint("RIGHT", self, "RIGHT", 0, 0);
        end
        if exceeding ~= self.exceeding then
            self.exceeding = exceeding;
            if exceeding then
                self.Tail:SetVertexColor(0.84, 0.08, 0.15);
            else
                self.Tail:SetVertexColor(0, 0.68, 0.94);
            end
        end

        local alpha;
        if speedRatio > 0 then
            alpha = 2*speedRatio;
        else
            alpha = -2*speedRatio;
        end
        if alpha > 1 then
            alpha = 1;
        end
        self.Tail:SetAlpha(alpha);

        self.RefObject:SetPoint("CENTER", self, "LEFT", -self.offset, 0);
        self.value = Round((self.offset + x - self.left)*self.valuePerX);
        self.ValueText:SetText(self.value);

        self.onValueChangedFunc(self, self.value);
    end
end

NarciShowcaseAnimationSliderMixin = {};

function NarciShowcaseAnimationSliderMixin:OnLoad()
    self.Label:SetText(Narci.L["Elapse"]);
    self.SliderCenter:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\FrameSlider", nil, nil, "TRILINEAR")
    self.CeilingNotch = self.ClipFrame.CeilingNotch;
    self.valuePerX = 10;
    self.offset = 0;
    --self.SliderLeft:SetVertexColor(0.25, 0.25, 0.25);
    self.SliderCenter:SetVertexColor(0.25, 0.25, 0.25);
    self.Tail:SetVertexColor(0, 0.68, 0.94);
    self:SetRange(15000);
    self:CreateNotch(500);
    self:UpdateLineSize();
    self:OnLeave();
end

function NarciShowcaseAnimationSliderMixin:OnShow()
    self.sliderWidth = self:GetWidth();
end

function NarciShowcaseAnimationSliderMixin:SetRange(range)
    self.range = range;
    local sliderWidth = self:GetWidth();
    self.maxOffset = range / self.valuePerX - sliderWidth;
end

function NarciShowcaseAnimationSliderMixin:CreateNotch(valueDistance)
    if not self.notches then
        self.notches = {};
        self.RefObject = self:CreateTexture();
        self.RefObject:SetSize(4, 16);
        self.RefObject:Hide();
        self.RefObject:SetPoint("CENTER", self, "LEFT", 0, 0);
    end
    if self.valuePerX then
        local widthRange = self:GetWidth() * self.valuePerX;
        local valueX = valueDistance / self.valuePerX;
        local numNotches = math.ceil(self.range / valueDistance);
        for i = 1, numNotches do
            if not self.notches[i] then
                self.notches[i] = self.ClipFrame:CreateTexture(nil, "OVERLAY");
                self.notches[i]:SetSize(2, 6);
                self.notches[i]:SetColorTexture(0.25, 0.25, 0.25);
                self.notches[i].label = self.ClipFrame:CreateFontString(nil, "OVERLAY", "NarciShowcaseSliderFontTemplate");
            end
            self.notches[i]:SetPoint("CENTER", self.RefObject, "CENTER", (i - 1)*valueX, 0);
            self.notches[i].label:SetPoint("TOP", self.RefObject, "BOTTOM", (i - 1)*valueX + 1, 2);
            self.notches[i].label:SetText( (i-1) * valueDistance);
        end
    end
end

function NarciShowcaseAnimationSliderMixin:UpdateLineSize()
    local _, screenHeight = GetPhysicalScreenSize();
    local pixel = (768/screenHeight);
    for _, notch in pairs(self.notches) do
        notch:SetSize(2*pixel, 6);
    end
    self.CursorNotch:SetSize(2*pixel, 6);
    self.CeilingNotch:SetSize(2*pixel, 6);
end

function NarciShowcaseAnimationSliderMixin:OnEnter()
    self.left = self:GetLeft();
    self.right = self:GetRight();
    self.CursorNotch:Show();
    self:SetScript("OnUpdate", UpdateCursorNotch);
    self.Thumb:SetVertexColor(1, 1, 1);
    self.CeilingNotch:SetAlpha(1);
    self.SliderCenter:SetVertexColor(0.35, 0.35, 0.35);
end

function NarciShowcaseAnimationSliderMixin:OnLeave()
    if not self.isDragging then
        self.CursorNotch:Hide();
        self:SetScript("OnUpdate", nil);
        self.Thumb:SetVertexColor(0.67, 0.67, 0.67);
        self.CeilingNotch:SetAlpha(0.5);
        self.SliderCenter:SetVertexColor(0.25, 0.25, 0.25);
    end
end

function NarciShowcaseAnimationSliderMixin:OnMouseDown(button)
    if button == "LeftButton" then
        self.isDragging = true;
    else
        self:SetValue(0, true);
    end
    if self.onMouseDownFunc then
        self.onMouseDownFunc(self);
    end
end

function NarciShowcaseAnimationSliderMixin:OnMouseUp()
    self.isDragging = nil;
    self.Tail:SetAlpha(0);
    if self:IsMouseOver() then
        self:SetScript("OnUpdate", UpdateCursorNotch);
    else
        self:OnLeave();
    end
end

function NarciShowcaseAnimationSliderMixin:OnHide()
    self:SetScript("OnUpdate", nil);
    self.isDragging = nil;
    self.CursorNotch:Hide();
end

function NarciShowcaseAnimationSliderMixin:SetValue(value, userInput)
    value = Round(value);
    if value > self.range then
        value = self.range;
    elseif value < 0 then
        value = 0;
    end
    self.offset = value/self.valuePerX - self.sliderWidth * 0.5;
    if self.offset < 0 then
        self.offset = 0;
    elseif self.offset > self.maxOffset then
        self.offset = self.maxOffset;
    end
    self.RefObject:SetPoint("CENTER", self, "LEFT", -self.offset, 0);
    local leftValue = self.offset * self.valuePerX;
    local x = (value - leftValue)/self.valuePerX;
    self.Thumb:SetPoint("BOTTOM", self, "LEFT", x, 0);
    self.value = value;
    if userInput then
        self.onValueChangedFunc(self, value);
    end
end

function NarciShowcaseAnimationSliderMixin:SetCeiling(value)
    --max seconds for a specific animation
    value = Round(value);
    if value and value > 0 then
        local offset = value/self.valuePerX;
        self.CeilingNotch:ClearAllPoints();
        self.CeilingNotch:SetPoint("CENTER", self.RefObject, "CENTER", offset, 0);
        self.CeilingNotch:Show();
    else
        self.CeilingNotch:Hide();
    end
end

function NarciShowcaseAnimationSliderMixin:Reset()
    self.sliderWidth = self:GetWidth();
    self:SetValue(0, true);
end