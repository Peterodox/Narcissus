local _, addon = ...

local GetColorByKey = addon.API.GetColorByKey;

local PIXEL = 1;

do
    local _, screenHeight = GetPhysicalScreenSize();
    PIXEL = 768/screenHeight;
end



NarciBarberShopSharedTemplateMixin = {};

function NarciBarberShopSharedTemplateMixin:UpdatePixel()
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    self.Exclusion:SetPoint("TOPLEFT", self, "TOPLEFT", PIXEL, -PIXEL);
    self.Exclusion:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -PIXEL, PIXEL);

    if self.GlowExclusion then
        self.GlowExclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    end

    self:OnLeave();
end

local function SetObjectColor(object, r, g, b, a)
    if not g then
        r, g, b = GetColorByKey(r);
        a = 1;
    end

    object:SetColorTexture(r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:SetBorderColor(r, g, b, a)
    SetObjectColor(self.Border, r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:SetBackgroundColor(r, g, b, a)
    SetObjectColor(self.Background, r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:OnEnter()
    self:SetBorderColor("focused");
    if self.ButtonText then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSharedTemplateMixin:OnLeave()
    if self.IsEnabled and self:IsEnabled() then
        self:SetBorderColor("grey");
    else
        self:SetBorderColor("disabled");
    end
end

function NarciBarberShopSharedTemplateMixin:OnDisable()
    self:SetBorderColor("disabled");
    if self.ButtonText then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciBarberShopSharedTemplateMixin:OnEnable()
    self:SetBorderColor("grey");
    if self.ButtonText then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSharedTemplateMixin:OnClick()
    if self.onClickFunc then
        self.onClickFunc(self, self.arg1, self.arg2);
    end
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end