local _, addon = ...

--Linear Scroll For Gamepad Control
local LinearScrollUpdater = CreateFrame("Frame");
addon.LinearScrollUpdater = LinearScrollUpdater;

LinearScrollUpdater:Hide();
LinearScrollUpdater.value = 0;
LinearScrollUpdater.distancePerSecond = 0;
LinearScrollUpdater.multiplier = 1;
LinearScrollUpdater:SetScript("OnUpdate", function(self, elapsed)
    local newValue = self.value + self.distancePerSecond * self.multiplier * elapsed;
    self.slider:SetValue(newValue);
    self.value = newValue;
    if newValue >= self.maxValue or newValue <= 0 then
        self:Stop();
    end
    if self.accelerate then
        self.multiplier = self.multiplier + elapsed;
        if self.multiplier > 3 then
            self.multiplier = 3;
        end
    end
end);

function LinearScrollUpdater:Start(scrollFrame, distancePerSecond, accelerate)
    self:Hide();
    local scrollBar = scrollFrame.scrollBar;
    if not scrollBar then
        return
    end
    self.slider = scrollBar;
    self.multiplier = 1;
    self.accelerate = accelerate;
    self.value = scrollBar:GetValue();
    self.distancePerSecond = distancePerSecond;
    self.minValue, self.maxValue = scrollBar:GetMinMaxValues();
    self:Show();
    self.isActive = true;
    return not(self.value == self.maxValue or self.value == self.minValue)
end

function LinearScrollUpdater:Stop()
    if self.isActive then
        self.isActive = nil;
        self:Hide();
        return true
    end
end