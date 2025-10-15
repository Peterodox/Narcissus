-- Use this black screen to dim other UI elements


local _, addon = ...
local outSine = addon.EasingFunctions.outSine;


local SharedBlackScreen = CreateFrame("Frame", "NarciSharedBlackScreen");
addon.SharedBlackScreen = SharedBlackScreen;

SharedBlackScreen:Hide();
SharedBlackScreen:SetAlpha(0);
SharedBlackScreen.alpha = 0;
SharedBlackScreen.baseFrameLevel = 5;
SharedBlackScreen:SetFrameStrata("MEDIUM");
SharedBlackScreen:SetFixedFrameStrata(true);
SharedBlackScreen:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -1, 1);
SharedBlackScreen:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 1, -1);

SharedBlackScreen.Texture = SharedBlackScreen:CreateTexture(nil, "BACKGROUND");
SharedBlackScreen.Texture:SetAllPoints(true);
SharedBlackScreen.Texture:SetColorTexture(0, 0, 0, 0.5);


SharedBlackScreen.owners = {};

function SharedBlackScreen:AddOwner(owner)
    self.owners[owner] = true;
end

function SharedBlackScreen:RemoveOwner(owner)
    if self.owners[owner] then
        self.owners[owner] = nil;
    end
end

function SharedBlackScreen:IsInUse()
    for owner in pairs(self.owners) do
        if owner:IsVisible() then
            return true
        end
    end
    return false
end

--[[
function SharedBlackScreen:OnUpdate_FadeIn(elapsed)
    self.alpha = self.alpha + 4 * elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha);
end
--]]

function SharedBlackScreen:OnUpdate_FadeIn(elapsed)
    self.t = self.t + elapsed;
    self.alpha = outSine(self.t, self.fromAlpha, 1, 0.25);
    if self.t >= 0.25 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha);
end

function SharedBlackScreen:OnUpdate_FadeOut(elapsed)
    self.t = self.t + elapsed;
    self.alpha = self.alpha - 5 * elapsed;
    if self.alpha <= 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
        self:Hide();
    end
    self:SetAlpha(self.alpha);
end

function SharedBlackScreen:TryShow()
    self:Show();
    self.alpha = self:GetAlpha();
    if self.alpha < 1 then
        self.fromAlpha = self.alpha;
        self.t = self.t or 0;
        self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
    else
        self:SetScript("OnUpdate", nil);
    end
end

function SharedBlackScreen:TryHide()
    if self:IsVisible() and not self:IsInUse() then
        self.alpha = self:GetAlpha();
        if self.alpha > 0 then
            self.t = 0;
            self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
        else
            self:SetScript("OnUpdate", nil);
        end
    end
end

function SharedBlackScreen:OnHide()
    self:SetScript("OnUpdate", nil);
    self:Hide();
    self.t = 0;
    self.alpha = 0;
    self:SetAlpha(0);
    self:RestoreLastWidgetLevel();
end
SharedBlackScreen:SetScript("OnHide", SharedBlackScreen.OnHide);

function SharedBlackScreen:RestoreLastWidgetLevel()
    if self.lastWidgetInfo then
        self.lastWidgetInfo.widget:SetFrameLevel(self.lastWidgetInfo.frameLevel);
        self.lastWidgetInfo = nil;
    end
end

function SharedBlackScreen:RaiseFrameLevel(widget)
    self:RestoreLastWidgetLevel();
    local selfLevel = self:GetFrameLevel();
    local widgetLevel = widget:GetFrameLevel();
    if widgetLevel <= selfLevel then
        self.lastWidgetInfo = {
            widget = widget,
            frameLevel = widgetLevel,
        }
        widget:SetFrameLevel(selfLevel + 1);
    end
end

function SharedBlackScreen:GetBaseFrameLevel()
    return self.baseFrameLevel
end

function SharedBlackScreen:SetBaseFrameLevel(baseFrameLevel)
    self.baseFrameLevel = baseFrameLevel;
    self:SetFrameLevel(baseFrameLevel);
    self:SetFixedFrameLevel(true);
end
SharedBlackScreen:SetBaseFrameLevel(5);