local _, addon = ...

local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local function IsSlotUsable(slotID)
    local _, _, enable = GetInventoryItemCooldown("player", slotID);
    return enable and enable == 1
end


local LAST_BUTTON;

local function OnScaleUpFinished(self)
    self:GetParent():SetScale(1.150);
end

local function CreateScaleUpAnimationOnWidget(widget)
    local ag = widget:CreateAnimationGroup();
    ag:SetScript("OnFinished", OnScaleUpFinished);

    local anim = ag:CreateAnimation("Scale");
    anim:SetScale(1.150, 1.150);
    anim:SetDuration(0.12);
    anim:SetSmoothing("OUT");

    widget.ScaleUp = ag;
end

local function PrepareAnimationForSlot(slotButton)
    if not slotButton.gamepad then
        CreateScaleUpAnimationOnWidget(slotButton.Border);
        CreateScaleUpAnimationOnWidget(slotButton.Border.BorderMask);
        CreateScaleUpAnimationOnWidget(slotButton.Icon);
        CreateScaleUpAnimationOnWidget(slotButton.IconMask);
        slotButton.gamepad = true;
    end
end

NarciGamePadSlotOverlayMixin = {};

function NarciGamePadSlotOverlayMixin:UpdateQualityColor(slotButton)
    if not slotButton then return end;
    
    local quality = slotButton.itemQuality;
    if not quality then
        if slotButton.itemLocation then
            quality = C_Item.GetItemQuality(slotButton.itemLocation);
        end
    end
    self.HexGlow:SetVertexColor(GetItemQualityColor(quality));
end

function NarciGamePadSlotOverlayMixin:AnchorToSlotButton(slotButton)
    if LAST_BUTTON and LAST_BUTTON.gamepadOverlay then
        LAST_BUTTON.gamepadOverlay = nil;
    end
    LAST_BUTTON = slotButton;
    LAST_BUTTON.gamepadOverlay = self;

    self.HexGlow:SetScale(1);
    if not slotButton then
        self:Hide();
        return
    end

    PrepareAnimationForSlot(slotButton);
    self:UpdateQualityColor(slotButton);
    self.HexGlow.FadeIn:Stop();
    self.HexGlow.FadeIn:Play();
    self:SetParent(slotButton);
    self:ClearAllPoints();
    self:SetPoint("CENTER", slotButton, "CENTER", 0, 0);
    self:Show();

    local f = self.ButtonNote;
    f.Background:ClearAllPoints();
    local usable = IsSlotUsable(slotButton.slotID);
    local pad1, pad3;
    
    if slotButton.isRight or slotButton.isFlyout then
        if slotButton.isFlyout then
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Equip", f, "LEFT", f, "RIGHT", 8, 0, 1);
        else
            if usable then
                pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "Use", f, "BOTTOMLEFT", f, "RIGHT", 8, 4, 1);
                pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "TOPLEFT", f, "RIGHT", 8, -4, 1);
            else
                pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "LEFT", f, "RIGHT", 8, 0, 1);
            end
        end
        f.Background:SetPoint("LEFT", f, "RIGHT", -56, 0);
    else
        if usable then
            pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "Use", f, "BOTTOMRIGHT", f, "LEFT", -8, 4, -1);
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "TOPRIGHT", f, "LEFT", -8, -4, -1);
        else
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "RIGHT", f, "LEFT", -8, 0, -1);
        end
        f.Background:SetPoint("RIGHT", f, "LEFT", 56, 0);
    end
    --[[
    local f = NarciEquipmentTooltip;
    if slotButton.isRight then
        if usable then
            pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "Use", f, "BOTTOMLEFT", f, "RIGHT", 8, 4, 1);
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "TOPLEFT", f, "RIGHT", 8, -4, 1);
        else
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "LEFT", f, "RIGHT", 8, 0, 1);
        end
    else
        if usable then
            pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "Use", f, "BOTTOMLEFT", f, "TOPLEFT", 0, 8, 1);
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "BOTTOMLEFT", f, "TOPLEFT", 96, 8, 1);
        else
            pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "Select", f, "BOTTOMLEFT", f, "TOPLEFT", 0, 8, 1);
        end
    end
    self.ButtonNote.Background:SetPoint("CENTER", f, "TOPLEFT", 48, 0);--]]
    self.ButtonNote.FadeIn:Stop();
    self.ButtonNote.FadeIn:Play();
end

function NarciGamePadSlotOverlayMixin:OnHide()
    self:Hide();
    self:SetScale(1);
    self:StopAnimating();
end