-- Show current money when cursor is close to the MoneyFrame next to SaveOutfitButton
-- Show ! when the cost > 5% of player gold


local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;
local FadeFrame = NarciFadeUI.Fade;


local MoneyModule = TransmogUIManager:CreateModule("MoneyDisplay");


--VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH, VIEWED_TRANSMOG_OUTFIT_SITUATIONS_CHANGED, PLAYER_MONEY


local MoneyDisplayFrameMixin = {};
do
    function MoneyDisplayFrameMixin:OnShow()
        self:RegisterEvent("VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH");
        self:RegisterEvent("VIEWED_TRANSMOG_OUTFIT_SITUATIONS_CHANGED");
        self:RegisterEvent("PLAYER_MONEY");
        self:UpdateMoney();
        self:SetScript("OnEvent", self.OnEvent);
    end

    function MoneyDisplayFrameMixin:OnHide()
        self:UnregisterEvent("VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH");
        self:UnregisterEvent("VIEWED_TRANSMOG_OUTFIT_SITUATIONS_CHANGED");
        self:UnregisterEvent("PLAYER_MONEY");
        self.t = 0;
        self:SetScript("OnEvent", nil);
        self:SetScript("OnUpdate", nil);
    end

    function MoneyDisplayFrameMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.1 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:UpdateMoney();
        end
    end

    function MoneyDisplayFrameMixin:OnEvent(event, ...)
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function MoneyDisplayFrameMixin:UpdateMoney()
        local owned = GetMoney();
        local cost = C_TransmogOutfitInfo.GetPendingTransmogCost() or 0;
        self.AlertIcon:SetShown(cost >= 0.05 * owned);
        MoneyFrame_Update(self.Money, owned, true);
    end

    function MoneyDisplayFrameMixin:OnEnter()
        FadeFrame(self.Flyout, 0.12, 1);
    end

    function MoneyDisplayFrameMixin:OnLeave()
        FadeFrame(self.Flyout, 0.2, 0);
    end
end


function MoneyModule:OnLoad()
    local parent = TransmogFrame;
    local MoneyFrame = parent.OutfitCollection.MoneyFrame;

    local MoneyDisplayFrame = CreateFrame("Frame", nil, parent);
    MoneyDisplayFrame:Hide();

    local width, height = MoneyFrame:GetSize();
    MoneyDisplayFrame:SetSize(width, height);
    MoneyDisplayFrame:SetPoint("CENTER", MoneyFrame, "CENTER", 0, 0);
    MoneyDisplayFrame:SetHitRectInsets(0, 0, -4, -2);

    local Flyout = CreateFrame("Frame", nil, MoneyDisplayFrame);
    MoneyDisplayFrame.Flyout = Flyout;
    Flyout:Hide();
    Flyout:SetAlpha(0);
    Flyout:SetSize(width, height + 24);
    Flyout:SetPoint("BOTTOMRIGHT", MoneyDisplayFrame, "TOPRIGHT", 0, 8);

    local Title = Flyout:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    Title:SetPoint("TOP", Flyout, "TOP", 0, -8);
    Title:SetText(L["Your Money Amount"]);

    local AlertIcon = MoneyDisplayFrame:CreateTexture(nil, "OVERLAY");
    MoneyDisplayFrame.AlertIcon = AlertIcon;
    AlertIcon:SetSize(18, 18);
    AlertIcon:Hide();
    AlertIcon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/DressingRoom/YellowAlert");
    AlertIcon:SetPoint("LEFT", MoneyDisplayFrame, "LEFT", 3, 0);

    local Background = Flyout:CreateTexture(nil, "BACKGROUND");
    MoneyDisplayFrame.Background = Background;
    Background:SetAllPoints(true);
    Background:SetAtlas("common-currencybox-a");

    local Money = CreateFrame("Frame", nil, Flyout, "SmallMoneyFrameTemplate");
    MoneyDisplayFrame.Money = Money;
    width, height = MoneyFrame.Money:GetSize();
    Money:SetSize(width, height);
    Money:SetPoint("BOTTOMRIGHT", Flyout, "BOTTOMRIGHT", 9, 8); --6

    SmallMoneyFrame_OnLoad(Money);
	MoneyFrame_SetType(Money, "STATIC");

    Mixin(MoneyDisplayFrame, MoneyDisplayFrameMixin);
    MoneyDisplayFrame:SetScript("OnShow", MoneyDisplayFrame.OnShow);
    MoneyDisplayFrame:SetScript("OnHide", MoneyDisplayFrame.OnHide);
    MoneyDisplayFrame:SetScript("OnEnter", MoneyDisplayFrame.OnEnter);
    MoneyDisplayFrame:SetScript("OnLeave", MoneyDisplayFrame.OnLeave);

    MoneyDisplayFrame:SetFrameLevel(MoneyFrame:GetFrameLevel() + 128);
    MoneyDisplayFrame:Show();
end
