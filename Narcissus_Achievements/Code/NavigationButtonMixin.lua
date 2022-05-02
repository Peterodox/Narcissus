local InspectionFrame;

local function NavButton_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > self.threshold then
        self.isHolding = true;
        self.t = 0;
        self.level = self.level + 1;
        if self.level > 3 then
            self.threshold = 0.5;
        elseif self.level > 0 then
            self.threshold = 0.8;
        end
        InspectionFrame:OnMouseWheel(self.delta);
    end
end

NarciAchievementNavigationButtonMixin = {};

function NarciAchievementNavigationButtonMixin:OnLoad()
    InspectionFrame = self:GetParent();
    local p;
    if self.delta > 0 then
        --Prev/Left Up
        p = -1;
        self.Background:SetTexCoord(0.5, 0, 0, 1);
        self.Highlight:SetTexCoord(1, 0.5, 0, 1);
    else
        --Next/Right Down
        p = 1;
        self.Background:SetTexCoord(0, 0.5, 0, 1);
        self.Highlight:SetTexCoord(0.5, 1, 0, 1);
    end
    self.FlyIn.Translation1:SetOffset(6*p, 0);
    self.FlyIn.Translation2:SetOffset(2*p, 0);
    self.FlyIn.Translation3:SetOffset(-6*p, 0);
    self.FlyIn.Translation4:SetOffset(-2*p, 0);
    self.Highlight.FlyIn.Translation1:SetOffset(-24*p, 0);
    self.Highlight.FlyIn.Translation2:SetOffset(24*p, 0);
end

function NarciAchievementNavigationButtonMixin:OnEnter()
    self:StopAnimating();
    self.Highlight.FlyIn:Play();
    self.FlyIn.Hold:SetDuration(60);
end

function NarciAchievementNavigationButtonMixin:OnLeave()
    self.FlyIn.Hold:SetDuration(0);
    self.Highlight.FadeOut:Play();
end

function NarciAchievementNavigationButtonMixin:OnMouseDown()
    self.Background:SetScale(0.9);
    if self:IsEnabled() then
        self:StartOnUpdate();
    else
        self:GetParent():OnMouseDown();
    end
end

function NarciAchievementNavigationButtonMixin:OnMouseUp()
    self.Background:SetScale(1);
    self:ClearOnUpdate();
end

function NarciAchievementNavigationButtonMixin:OnClick()
    if self.isHolding then
        self.isHolding = nil;
        return
    end
    InspectionFrame:OnMouseWheel(self.delta);
end

function NarciAchievementNavigationButtonMixin:OnDisable()
    self:SetAlpha(0);
end

function NarciAchievementNavigationButtonMixin:OnEnable()
    self:SetAlpha(1);
end

function NarciAchievementNavigationButtonMixin:OnShow()
    if self:IsEnabled() then
        self:SetAlpha(1);
    else
        self:SetAlpha(0);
    end
end

function NarciAchievementNavigationButtonMixin:OnHide()
    self:ClearOnUpdate();
    self.isHolding = nil;
end

function NarciAchievementNavigationButtonMixin:StartOnUpdate()
    self.level = 0;
    self.t = 0.5;
    self.threshold = 1;
    self:SetScript("OnUpdate", NavButton_OnUpdate);
end

function NarciAchievementNavigationButtonMixin:ClearOnUpdate()
    self:SetScript("OnUpdate", nil);
end