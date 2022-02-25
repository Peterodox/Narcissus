local colors = {
    full = {0, 1, 0},
    red = {240/255, 0.28, 0.28},
    orange = {1, 185/255, 0.28},
    yellow = {1, 240/255, 0.28},
};

local sqrt = math.sqrt;
local max = math.max;
local pow = math.pow;

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

-------------------------------------------------
NarciAchievementStatusBarMixin = {};

function NarciAchievementStatusBarMixin:OnLoad()
    self.min, self.max, self.value = 0, 0, 0;
    local width = self.background:GetWidth();
    --print("bar width: "..width)
    --Anchors are set AFTER the frame is created.
    self.fillWidth = width;
    self.border:SetTexture("Interface\\AddOns\\Narcissus_Achievements\\Art\\Shared\\ProgressBarShortBorder", nil, nil, "LINEAR");
    
    local animFill = NarciAPI_CreateAnimationFrame(0.5);
    self.animFill = animFill;
    animFill:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local percent = outQuart(frame.total, 0, self.percent, frame.duration)
        if frame.total >= frame.duration then
            frame:Hide();
            percent = self.percent;
        end
        self.fill:SetWidth(240 * percent);
        self.fill:SetTexCoord(0, percent, 0, 1);
    end)

    function self:PlayFilling()
        animFill:Hide();
        if self.fill:IsShown() then
            animFill.duration = max(0.15, 0.65 * sqrt(self.percent) );
            animFill:Show();
        end
    end
end

function NarciAchievementStatusBarMixin:SetMinMaxValues(min, max)
    if min then
        self.min = min;
    end
    if max then
        self.max = max;
    end
    if self.min > self.max then
        self.max = self.min;
    end
    self.value = 0;
end

function NarciAchievementStatusBarMixin:SetValue(value, colorize)
    local min, max = self.min, self.max;
    
    if value < min then
        value = min;
    elseif value > max then
        value = max;
    end
    self.value = value;

    local range = max - min;
    local percent;
    if range == 0 then
        percent = 0;

    else
        percent = (value - min) / range;
    end
    self.percent = percent;

    if percent == 0 then
        self.fill:SetWidth(0.1);
        self.fill:Hide();
        self.color:Hide();
    else
        self.fill:SetWidth(240 * percent);
        self.fill:SetTexCoord(0, percent, 0, 1);
        self.fill:Show();
        self.color:Show();
    end

    if colorize then
        local r, g, b;
        if percent == 1 then
            r, g, b = unpack(colors.full);
        elseif percent <= 0.334 then
            r, g, b = unpack(colors.red);
        elseif percent <= 0.667 then
            r, g, b = unpack(colors.orange);
        else
            r, g, b = unpack(colors.yellow);
        end
        self.color:SetColorTexture(r, g, b);
    end

    self.meter:SetText(value.."/"..max);
end

function NarciAchievementStatusBarMixin:OnShow()
    self:PlayFilling();
end

function NarciAchievementStatusBarMixin:OnHide()
    --self.animFill:Hide();
    --self:Hide();
end