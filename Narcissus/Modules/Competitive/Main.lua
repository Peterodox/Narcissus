NarciCompetitiveDisplayMixin = {};

function NarciCompetitiveDisplayMixin:OnLoad()
    self:ClearAllPoints();
    self:SetPoint("TOP", Narci_ConciseStatFrame.Primary, "TOP", 0, 0);

    self.LoadingOverlay.LoadingIndicator:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\LoadingIndicator", nil, nil, "TRILINEAR");
end

function NarciCompetitiveDisplayMixin:ShowMythicPlus()
    self.MythicPlus:PostUpdate();
end

function NarciCompetitiveDisplayMixin:HideLoading()
    self:SetScript("OnUpdate", nil);
    if self.LoadingOverlay:IsShown() then
        self.LoadingOverlay.FadeOut:Play();
        return true
    end
end

function NarciCompetitiveDisplayMixin:ShowLoading()
    if not self.LoadingOverlay:IsShown() then
        self.LoadingOverlay.FadeIn:Play();
        self.LoadingOverlay:Show();
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end
end

function NarciCompetitiveDisplayMixin:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 2 then
        self.t = 0;
        if self:HideLoading() then
            self.MythicPlus:PostUpdate();
        end
    end
end