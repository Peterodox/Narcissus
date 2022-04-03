local _, addon = ...


----Show tooltip after delay----
local SharedTooltipDelay = CreateFrame("Frame");
addon.SharedTooltipDelay = SharedTooltipDelay;

local function Delay_OnUpdate(self, elapased)
    self.t = self.t + elapased;
    if self.t >= 0 then
        self:OnFinished();
    end
end

function SharedTooltipDelay:Setup(tooltipAnchor, delay, setupFunc, arg1, arg2, arg3)
    self.t = -delay;
    self.widget = tooltipAnchor;
    self.setupFunc = setupFunc;
    self.arg1, self.arg2, self.arg3 = arg1, arg2, arg3;
    self:SetScript("OnUpdate", Delay_OnUpdate);
    self.alive = true;
end

function SharedTooltipDelay:Kill()
    if self.alive then
        self:SetScript("OnUpdate", nil);
        self.widget = nil;
        self.setupFunc = nil;
        self.arg1, self.arg2, self.arg3 = nil, nil, nil;
        self.t = nil;
        self.alive = nil;
    end
end

function SharedTooltipDelay:OnFinished()
    self:SetScript("OnUpdate", nil);
    if self.widget and self.setupFunc then
        if self.widget:IsVisible() then
            self.setupFunc(self.arg1, self.arg2, self.arg3);
        end
    end
    self:Kill();
end