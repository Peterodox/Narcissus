local sqrt = math.sqrt;
local pow = math.pow;
local floor = math.floor;

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

local GetCursorPosition = GetCursorPosition;

local TEXTURE_PATH_PREFIX = "Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\ModelControl\\";
local CAP_OFFSET = 48;
local MAX_OFFSET = 12;
local curveK = MAX_OFFSET/CAP_OFFSET^2;


local ThumbResetter = CreateFrame("Frame");
ThumbResetter.t= 0;
ThumbResetter.duration = 0.5;
ThumbResetter:Hide();

ThumbResetter:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    local offsetX = outQuart(self.t, self.fromX, self.toX, self.duration);
    local alpha = outQuart(self.t, self.fromAlpha, 0, self.duration);
    if self.t >= self.duration then
        offsetX = self.toX;
        alpha = 0;
        self:Hide();
    end
    self.object:SetPoint("CENTER", self.widget, "LEFT", offsetX, 0);
    self.fluid:SetAlpha(alpha);
end);

function ThumbResetter:ResetThumb(widget)
    if self:IsShown() then
        --self.object:SetPoint("CENTER", self.widget, "LEFT", self.toX, 0);
        --self.Fluid:SetAlpha(0);
        self:Hide();
    end
    local Thumb = widget.OverlayFrame.Thumb;
    local _, _, _, fromX = Thumb:GetPoint();
    local barWidth = widget:GetWidth();
    local toX, duration;
    if fromX < 0 then
        toX = 0;
        duration = sqrt(-fromX/MAX_OFFSET)
    elseif fromX > barWidth then
        toX = barWidth;
        duration = sqrt((fromX - barWidth )/MAX_OFFSET);
    end

    if duration and duration > 0 then
        self.duration = 0.65*duration;
        self.widget = widget;
        self.object = Thumb;
        self.fluid = widget.Fluid;
        self.fromAlpha = widget.Fluid:GetAlpha();
        self.fromX = fromX;
        self.toX = toX;
        self.t = 0;
        self:Show();
    end
end

local function GetCapDiff(x)
    local r = (CAP_OFFSET - x) + CAP_OFFSET;
    local y = 0;
    local ratio = 0;
    if x >= 0 then
        if x > CAP_OFFSET then
            x = CAP_OFFSET;
        end
        y = curveK * (CAP_OFFSET^2 - (x - CAP_OFFSET)^2);
        ratio = y / MAX_OFFSET;
    elseif x < 0 then
        if x < -CAP_OFFSET then
            x = -CAP_OFFSET;
        end
        y = curveK * (-CAP_OFFSET^2 + (x + CAP_OFFSET)^2);
        ratio = -y / MAX_OFFSET;
    end
    return y, ratio
end

local function CreateMarks(widget, visualRange, maxRange, gap)
    if not widget.marks then
        widget.marks = {};
    end
    local barWidth = widget:GetWidth();
    widget.visualRange = visualRange;
    widget.maxRange = maxRange;
    widget.maxOffset = barWidth * (maxRange / visualRange - 1);
    local valuePerX = visualRange / barWidth;
    widget.valuePerX = valuePerX;
    local visualGap = gap / valuePerX;
    local mark;
    local numMark = floor(maxRange/gap);
    for i = 1, numMark do
        mark = widget.marks[i];
        if not mark then
            mark = CreateFrame("Frame", nil, widget.ClipFrame, "NarciSliderMarkerTemplate");
            tinsert(widget.marks, mark);
        end
        mark:Show();
        mark:ClearAllPoints();
        mark:SetPoint("CENTER", widget.Reference, "LEFT", i * visualGap, 0);
        if i ~= numMark then
            mark.Label:SetText(i * gap);
        end
    end

    for i = numMark + 1, #widget.marks do
        widget.marks[i]:Hide();
    end
end


NarciUncappedSliderMixin = {};

function NarciUncappedSliderMixin:OnLoad()
    if self.iconName then
        self.Icon:SetTexture(TEXTURE_PATH_PREFIX.."Icon".. self.iconName);
    end
    self.isDragging = false;
    self.barOffset = 0;
    CreateMarks(self, 2000, 10000, 1000);
    self.isInBound = false;
    self.Fluid:SetVertexColor(0.82, 0, 0);
end

function NarciUncappedSliderMixin:OnEnter()
    self.OverlayFrame.ThumbHighlight:Show();
end

function NarciUncappedSliderMixin:OnLeave()
    if not self.isDragging then
        self.OverlayFrame.ThumbHighlight:Hide();
    end
end

function NarciUncappedSliderMixin:OnMouseDown(button)
    self.isDragging = true;
    self.scale = self:GetEffectiveScale();
    self.capLeft = self:GetLeft();
    self.capRight = self:GetRight();

    self:SetScript("OnUpdate", function(self, elapsed)
        local diff = self:UpdateThumbPosition();
        self.barOffset = self.barOffset + diff * 12 * elapsed;
        if self.barOffset < 0 then
            self.barOffset = 0;
            if self.isInBound then
                self.isInBound = false;
                self.Fluid:SetVertexColor(0.82, 0, 0);
            end
        elseif self.barOffset > self.maxOffset then
            self.barOffset = self.maxOffset;
            if self.isInBound then
                self.isInBound = false;
                self.Fluid:SetVertexColor(0.82, 0, 0);
            end
        else
            if not self.isInBound then
                self.isInBound = true;
                self.Fluid:SetVertexColor(0.25, 0.78, 0.92);
            end
        end
        self:UpdateEffectiveOffset();
    end)
end

function NarciUncappedSliderMixin:OnMouseUp()
    self.isDragging = false;

    self:SetScript("OnUpdate", nil);
    if not self:IsMouseOver() then
        self:OnLeave();
    end
    ThumbResetter:ResetThumb(self);
end

function NarciUncappedSliderMixin:UpdateThumbPosition()
    local cursorX, _ = GetCursorPosition() / self.scale;
    local diff = 0;
    local fluidAlpha;
    if cursorX > self.capRight then
        diff = cursorX - self.capRight;
        cursorX = self.capRight;
    elseif cursorX < self.capLeft then
        diff = cursorX - self.capLeft;
        cursorX = self.capLeft;
    end

    --Damping
    if diff == 0 then
        self.isMovingRight = false;
        self.isMovingLeft = false;
        fluidAlpha = 0;
    else
        diff, fluidAlpha = GetCapDiff(diff);
        if diff > 0 then
            if not self.isMovingRight then
                self.isMovingRight = true;
                self.isMovingLeft = false;
                self.Fluid:ClearAllPoints();
                self.Fluid:SetPoint("RIGHT", self.OverlayFrame.Thumb, "CENTER", 0, 0);
                self.Fluid:SetTexCoord(0.25, 0, 0.5, 0.5625);
            end
        else
            if not self.isMovingLeft then
                self.isMovingLeft = true;
                self.isMovingRight = false;
                self.Fluid:ClearAllPoints();
                self.Fluid:SetPoint("LEFT", self.OverlayFrame.Thumb, "CENTER", 0, 0);
                self.Fluid:SetTexCoord(0, 0.25, 0.5, 0.5625);
            end
        end
    end
    local thumbOffset = cursorX - self.capLeft;
    self.thumbOffset = thumbOffset;
    local offset = thumbOffset + diff;
    self.OverlayFrame.Thumb:SetPoint("CENTER", self, "LEFT", offset, 0);
    self.Fluid:SetAlpha(sqrt(fluidAlpha));
    return diff
end

function NarciUncappedSliderMixin:UpdateEffectiveOffset(forcedRefresh)
    self.Reference:SetPoint("CENTER", self, "LEFT", -self.barOffset, 0);
    local alpha = (10 - self.barOffset)/10;
    if alpha < 0 then
        alpha = 0;
    end
    self.Hedge:SetAlpha(alpha);
    self.Icon:SetAlpha(alpha);
    
    local effectiveValue = floor( (self.barOffset + self.thumbOffset)* self.valuePerX + 0.5);
    if effectiveValue ~= self.effectiveValue or forcedRefresh then
        self.effectiveValue = effectiveValue;
        self.OverlayFrame.ValueText:SetText(effectiveValue);
        if self.onValueChangedFunc then
            self.onValueChangedFunc(effectiveValue);
        end
        if self.barOffset < 10 then
            local alpha = self.barOffset/10;
            self.ZeroButton:SetAlpha(alpha);
            if alpha < 0.05 then
                self.ZeroButton:Hide();
                self.showZeroButton = false;
            end
        else
            self.ZeroButton:Show();
            if not self.showZeroButton then
                self.showZeroButton = true;
                self.ZeroButton.flyIn:Play();
            end
        end
    end
end

function NarciUncappedSliderMixin:SetValue(value, forcedRefresh)
    local maxRange = self.maxRange;
    if value > maxRange then
        value = maxRange;
    elseif value < 0 then
        value = 0;
    end
    local thumbOffset;
    local visualRange = self.visualRange;
    local barWidth = self:GetWidth();
    if value > visualRange then
        if value > (maxRange - visualRange) then
            thumbOffset =  barWidth * (visualRange - maxRange + value) / visualRange;
        else
            thumbOffset = barWidth / 2;
        end
    elseif value < visualRange then
        thumbOffset = barWidth * value / visualRange;
    else
        thumbOffset =  barWidth * value / (3 * visualRange);
    end
    self.barOffset = value / self.valuePerX - thumbOffset;
    self.thumbOffset = thumbOffset;
    self:UpdateEffectiveOffset(forcedRefresh);
    self.OverlayFrame.Thumb:SetPoint("CENTER", self, "LEFT", thumbOffset, 0);
    self.Fluid:SetAlpha(0);
    --print(self.effectiveValue)
end

function NarciUncappedSliderMixin:ResetValueVisual()
    self.OverlayFrame.Thumb:SetPoint("CENTER", self, "LEFT", 0, 0);
    self.Fluid:SetAlpha(0);
    self.thumbOffset = 0;
    self.barOffset = 0;
    self.ZeroButton:Hide();
    self.showZeroButton = false;
    self.effectiveValue = 0;
    self.Hedge:SetAlpha(1);
    self.Icon:SetAlpha(1);
    self.Reference:SetPoint("CENTER", self, "LEFT", 0, 0);
end