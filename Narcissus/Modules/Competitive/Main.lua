NarciCompetitiveDisplayMixin = {};

function NarciCompetitiveDisplayMixin:OnLoad()
    self:ClearAllPoints();
    self:SetPoint("TOP", Narci_ConciseStatFrame.Primary, "TOP", 0, 0);

    self.LoadingOverlay.LoadingIndicator:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\LoadingIndicator", nil, nil, "TRILINEAR");
end

function NarciCompetitiveDisplayMixin:ShowMythicPlus()
    self.MythicPlus:Update();
end

function NarciCompetitiveDisplayMixin:HideLoading()
    if self.LoadingOverlay:IsShown() then
        self.LoadingOverlay.FadeOut:Play();
    end
end

function NarciCompetitiveDisplayMixin:ShowLoading()
    if not self.LoadingOverlay:IsShown() then
        self.LoadingOverlay.FadeIn:Play();
        self.LoadingOverlay:Show();
    end
end