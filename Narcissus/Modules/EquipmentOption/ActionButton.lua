local _, addon = ...

local L = Narci.L;

local InCombatLockdown = InCombatLockdown;
local FadeFrame = NarciFadeUI.Fade;
local GetSlotNameByID = NarciAPI.GetSlotButtonNameBySlotID;
local GetGemBonus = NarciAPI.GetGemBonus;
local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local PickupContainerItem = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem;

local MainFrame, SelectionOverlay, EnchantActionButton, GemActionButton;


local function FormatReplacementString(effectText, isNew)
    if effectText then
        if isNew then
            if string.sub(effectText, 0, 1) ~= "+" then
                effectText = "+ "..effectText;
            end
        else
            if string.sub(effectText, 0, 1) == "+" then
                effectText = string.gsub(effectText, "+", "-", 1);
            else
                effectText = "- "..effectText;
            end
        end
        return effectText
    end
end

local function RegisterClicks(actionButton)
    if C_CVar.GetCVarBool("ActionButtonUseKeyDown") then
        actionButton:RegisterForClicks("LeftButtonDown", "RightButtonDown", "RightButtonUp");
    else
        actionButton:RegisterForClicks("LeftButtonUp", "RightButtonDown", "RightButtonUp");
    end
end


NarciEquipmentEnchantActionButtonMixin = {};

function NarciEquipmentEnchantActionButtonMixin:OnLoad()
    EnchantActionButton = self;
    self:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp");
end

function NarciEquipmentEnchantActionButtonMixin:InitFromButton(button, slotID, inUseEnchantID)
    if InCombatLockdown() then
        return
    end
    self:Clear();
    self.isReleased = false;
    button:Hide();
    --button.FadeOut:Play();
    --FadeFrame(button, 0.2, 0);
    self.sourceButton = button;
    self.NewItemName:SetText(FormatReplacementString(button.Text1:GetText(), true));
    if inUseEnchantID then
        local inUseEnchant = NarciAPI.GetEnchantTextByEnchantID(inUseEnchantID);
        self.Header:SetText(FormatReplacementString(inUseEnchant, false));
        self.Header:SetTextColor(0.5, 0.5, 0.5);
    else
        self.Header:SetText(ANIMA_DIVERSION_CLICK_CHANNEL);
        self.Header:SetTextColor(0.92, 0.92, 0.92);
    end
    if button.itemID then
        self:SetUsingItem(button.itemID, slotID);
        NarciRuneAnimationOverlay:SetRuneByEnchantID(button.enchantID);
    else
        self:MarkActive(false);
        return
    end
    self:SetPoint("LEFT", button, "LEFT", 0, 0);
    self:SetParent(MainFrame.ItemList);
    self:Show();
    self:SetFrameStrata("DIALOG");
    self:SetFrameLevel(50);
    self:StopAnimating();
    self:ShowConfirm();
    self.Backdrop:Show();
    self.AnimConfirm:Play();
    self:MarkActive(true);
    FadeFrame(SelectionOverlay, 0.2, 1);
end

function NarciEquipmentEnchantActionButtonMixin:Clear()
    if self.sourceButton then
        FadeFrame(self.sourceButton, 0.2, 1, 0);
        self.sourceButton = nil;
    end
    self:StopAnimating();
    self:SetScript("OnUpdate", nil);
    self.t = 0;
    self.macroText = nil;
    if not self.isReleased then
        self.isReleased = true;
        self:Hide();
        self:ClearAllPoints();
        self:SetParent(NarciSecureFrameContainer);
    end
    self:MarkActive(false);
    self.Backdrop:Hide();
end

function NarciEquipmentEnchantActionButtonMixin:PostClick(button)
    if button == "RightButton" then
        self:Clear();
        if SelectionOverlay then
            SelectionOverlay:Hide();
        end
        if self.stopCasting then
            self.stopCasting = nil;
            self.CastFrame:OnSpellCastFailed(nil, nil, 0);
        end
        return
    end
    self:ShowCastBar();
    --[[
    if StaticPopup1Button1 and StaticPopup1Button1:IsShown() then
        StaticPopup1Button1:Click();
    end
    --]]
    self:SetClickToCancel();
    ClearCursor();
end

function NarciEquipmentEnchantActionButtonMixin:OnLeave()
end

function NarciEquipmentEnchantActionButtonMixin:SetUsingItem(itemID, slotID)
    RegisterClicks(self);
    local slotName = GetSlotNameByID(slotID);
    local macroText = string.format("/use item:%s\r/click %s\r/click StaticPopup1Button1\r/click %s", itemID, slotName or "", slotName or "");
    self:SetAttribute("type1", "macro");
    self:SetAttribute("type2", nil);
    self:SetAttribute("macrotext", macroText);
    self.stopCasting = nil;
    self.macroText = macroText;
end

function NarciEquipmentEnchantActionButtonMixin:GetMacroText()
    return self.macroText;
end

function NarciEquipmentEnchantActionButtonMixin:SetClickToCancel()
    RegisterClicks(self);
    self:SetAttribute("type1", nil);
    self:SetAttribute("type2", "macro");
    self:SetAttribute("macrotext", "/stopcasting");
    self.stopCasting = true;
end

function NarciEquipmentEnchantActionButtonMixin:ShowCastBar()
    if not self.CastFrame:IsVisible() then
        self.Header.FlyDown:Play();
        self.NewItemName:Hide();
        self.Backdrop:Show();
        self.CastText:SetText(CHANNELING);
        self.CastText:Show();
        self.CastText:SetTextColor(0.92, 0.92, 0.92)
        self.CastText.FlyIn:Play();
        self.CastFrame:Show();
    end
end

function NarciEquipmentEnchantActionButtonMixin:ShowConfirm()
    self.Header:Show();
    self.NewItemName:Show();
    self.Backdrop:Show();
    self.CastText:Hide();
    self.CastFrame:Hide();
end

local function Cancel_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 1 then
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self:Clear();
        if SelectionOverlay then
            SelectionOverlay:Hide();
        end
    end
end

function NarciEquipmentEnchantActionButtonMixin:OnCastCanceled()
    self.t = 0;
    self:SetScript("OnUpdate", Cancel_OnUpdate);
    self.CastText:SetText(CLUB_FINDER_CANCELED);
    self.CastText:SetTextColor(0.5, 0.5, 0.5);
    self.CastText:StopAnimating();
    NarciRuneAnimationOverlay:StopAnimation();
end

function NarciEquipmentEnchantActionButtonMixin:OnCastSucceeded()
    local slot = MainFrame.slotButton;
    if slot then
        C_Timer.After(0.5, function()
            slot:Refresh();
        end);
    end
    MainFrame:CloseUI(0.5);
end

function NarciEquipmentEnchantActionButtonMixin:OnCastFailed(errorMsg)
    --Invalid items, etc.
    self.t = -1;
    self:SetScript("OnUpdate", Cancel_OnUpdate);
    self.CastText:SetText(errorMsg);
    self.CastText:SetTextColor(1, 0.3137, 0.3137);
    self.CastText:StopAnimating();
    NarciRuneAnimationOverlay:StopAnimation();
end

function NarciEquipmentEnchantActionButtonMixin:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function NarciEquipmentEnchantActionButtonMixin:OnHide()
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:Clear();
end

function NarciEquipmentEnchantActionButtonMixin:OnEvent()
    self:Clear();
end

function NarciEquipmentEnchantActionButtonMixin:MarkActive(state)
    if state then
        self.isActive = state;
    else
        self.isActive = nil;
    end
end

function NarciEquipmentEnchantActionButtonMixin:PreClick()

end

-------- Item Socketing --------

local function CloseSocketingFrame()
    if ItemSocketingFrame and ItemSocketingFrame:IsShown() then
        CloseSocketInfo();
    end
end

addon.CloseSocketingFrame = CloseSocketingFrame;

local function PlaceGemInSlot(gemID, slotID, socketOrderID)
    ClearCursor();
    if not slotID or not gemID then return; end
    --PickupItem("item:"..gemID);   --Somehow doesn't work
    local bagID, slotIndex = GetItemBagPosition(gemID);
    if not(bagID and slotIndex) then return; end

    PickupContainerItem(bagID, slotIndex);
    SocketInventoryItem(slotID);
    ClickSocketButton(socketOrderID);
    ClearCursor();
    AcceptSockets();
end

local function SocketingEventFrame_OnShow(self)
    self:RegisterEvent("SOCKET_INFO_SUCCESS");
    self:RegisterEvent("SOCKET_INFO_FAILURE");
end

local function SocketingEventFrame_OnHide(self)
    self:UnregisterEvent("SOCKET_INFO_SUCCESS");
    self:UnregisterEvent("SOCKET_INFO_FAILURE");
    self:UnregisterEvent("UI_ERROR_MESSAGE");
end

local function SocketingEventFrame_OnEvent(self, event, ...)
    if event == "UI_ERROR_MESSAGE" then
        self:UnregisterEvent(event);
        local errorType, errorMsg = ...;
        GemActionButton:OnActionFailed(errorMsg);
    elseif event == "SOCKET_INFO_SUCCESS" then
        GemActionButton:OnActionSucceed();
        self:UnregisterEvent("UI_ERROR_MESSAGE");
    elseif event == "SOCKET_INFO_FAILURE" then
        GemActionButton:OnActionFailed(FAILED);
        self:UnregisterEvent("UI_ERROR_MESSAGE");
    end
end

NarciEquipmentGemActionButtonMixin = {};

function NarciEquipmentGemActionButtonMixin:OnLoad()
    self:ClearAllPoints();

    GemActionButton = self;
    MainFrame = self:GetParent():GetParent();

    SelectionOverlay = self:GetParent().SelectionOverlay;
    SelectionOverlay:SetScript("OnMouseDown", function(f)
        EnchantActionButton:Clear();
        GemActionButton:Clear();
        f:Hide();
    end);
    SelectionOverlay:SetScript("OnMouseWheel", function(f)
        EnchantActionButton:Clear();
        GemActionButton:Clear();
        f:Hide();
    end);
    SelectionOverlay:SetScript("OnHide", function(f)
        f:Hide();
        f:SetAlpha(0);
    end);

    self.EventFrame:SetScript("OnEvent", SocketingEventFrame_OnEvent);
    self.EventFrame:SetScript("OnShow", SocketingEventFrame_OnShow);
    self.EventFrame:SetScript("OnHide", SocketingEventFrame_OnHide);
end

function NarciEquipmentGemActionButtonMixin:OnHide()
    self:Clear();
end

function NarciEquipmentGemActionButtonMixin:InitFromButton(button, slotID, inUseGemID)
    local hasItemName;
    if inUseGemID then
        local inUseEnchant = GetGemBonus(inUseGemID);               --Domination shard will be required to remove first
        if not inUseEnchant then
            inUseEnchant = C_Item.GetItemInfo(inUseGemID);     --Gem name
        end

        if inUseEnchant then
            hasItemName = true;
            self.Header:SetText(FormatReplacementString(inUseEnchant, false));
            self.Header:SetTextColor(0.5, 0.5, 0.5);
        end
    end
    if not hasItemName then
        self.Header:SetText(L["Click To Insert"]);
        self.Header:SetTextColor(0.92, 0.92, 0.92);
    end

    self:Clear();
    button:Hide();
    self.sourceButton = button;
    self.NewItemName:SetText(FormatReplacementString(button.Text1:GetText(), true));
    self.slotID = slotID;
    self.itemID = button.itemID;

    self:SetPoint("LEFT", button, "LEFT", 0, 0);
    self:Show();
    self:SetFrameStrata("DIALOG");
    self:SetFrameLevel(50);
    self:StopAnimating();

    self.AnimConfirm:Play();

    self.Header:Show();
    self.NewItemName:Show();
    self.Backdrop:Show();
    self.ResultText:Hide();
    self.EventFrame:Hide();

    self:MarkActive(true);

    FadeFrame(SelectionOverlay, 0.2, 1);
end

function NarciEquipmentGemActionButtonMixin:Clear()
    if self:IsShown() and self.sourceButton then
        FadeFrame(self.sourceButton, 0.2, 1, 0);
        self.sourceButton = nil;
    end
    self.actionFailed = nil;
    self:StopAnimating();
    self:SetScript("OnUpdate", nil);
    self.t = 0;
    self:Hide();
    self:ClearAllPoints();
    self:MarkActive(false);
    self.Backdrop:Hide();
end

function NarciEquipmentGemActionButtonMixin:MarkActive(state)
    if state then
        self.isActive = state;
    else
        self.isActive = nil;
    end
end

function NarciEquipmentGemActionButtonMixin:OnClick(button)
    if button == "RightButton" or self.actionFailed then
        self:Clear();
        if SelectionOverlay then
            SelectionOverlay:Hide();
        end
        return
    end
    self:ShowEventFrame();
    PlaceGemInSlot(self.itemID, self.slotID, MainFrame:GetSocketOrderID());
end

function NarciEquipmentGemActionButtonMixin:ShowEventFrame()
    if not self.EventFrame:IsVisible() then
        self.Header.FlyDown:Play();
        self.NewItemName:Hide();
        self.ResultText:SetText( string.gsub(BLIZZARD_STORE_PROCESSING, "%.…", ""));
        self.ResultText:Show();
        self.ResultText:SetTextColor(0.92, 0.92, 0.92);
        self.ResultText.FlyIn:Play();
        self.ResultText.Blink:SetLooping("REPEAT");
        self.EventFrame:Show();
    end

    self.EventFrame:RegisterEvent("UI_ERROR_MESSAGE");
end

function NarciEquipmentGemActionButtonMixin:OnActionFailed(errorMsg)
    self.actionFailed = true;
    self.ResultText:SetText(errorMsg);
    self.ResultText:SetTextColor(1, 0.3137, 0.3137);
    self.ResultText.Blink:SetLooping("NONE");
end

function NarciEquipmentGemActionButtonMixin:OnActionSucceed()
    CloseSocketingFrame();
    if MainFrame.isNarcissusUI then
        self.ResultText.Blink:SetLooping("NONE");
        NarciGemSlotOverlay:StartAnimation();
        PlaySound(84378);
        MainFrame:CloseUI(0.5);
        local slot = Narci.GetEquipmentSlotByID(self.slotID);
        C_Timer.After(1, function()
            slot:Refresh();
        end);
    else
        --[[
        C_Timer.After(0.75, function()
            self:OnClick("RightButton");
            MainFrame.ItemList:Reset();
        end);
        --]]
    end
    self.ResultText:SetText(CRITERIA_COMPLETED);
    self.ResultText:SetTextColor(0.92, 0.92, 0.927);
    self.ResultText.Blink:SetLooping("NONE");
    --self:GetParent():Reset();       --Refresh item list
end