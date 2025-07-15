local _, addon = ...

local EnchantDataProvider = addon.EnchantDataProvider;
local GemDataProvider = addon.GemDataProvider;
local TempDataProvider = addon.TempDataProvider;
local GetAppliedEnhancement = addon.GetAppliedEnhancement;
local GetNewGemID = addon.GetNewGemID;
local PixelPerfectController = addon.PixelPerfectController;
local EquipmentManager_UnpackLocation = addon.TransitionAPI.EquipmentManager_UnpackLocation;

local L = Narci.L;

local DataProvider = GemDataProvider;

local MainFrame, FilterButton, Tooltip, ItemButtonHighlight;

local BUTTON_HEIGHT = 48;
local MAX_VISIBLE_BUTTONS = 4;
local TOOLTIP_PADDING = 12;

local TOOLTIP_PREFIX;
if UnitLevel("player") < 60 then
    TOOLTIP_PREFIX  = string.format(L["At Level"], 60).." ";
else
    TOOLTIP_PREFIX = "";
end

local GetSpellDescription = addon.TransitionAPI.GetSpellDescription;
local GetItemSpell = C_Item.GetItemSpell;

local tinsert = table.insert;
local tremove = table.remove;

local FadeFrame = NarciFadeUI.Fade;
local NarciAPI = NarciAPI;
--local IsItemDominationShard = NarciAPI.IsItemDominationShard;
local RemoveColorString = NarciAPI.RemoveColorString;
local GetCachedItemTooltipTextByLine = NarciAPI.GetCachedItemTooltipTextByLine;
local GetItemTempEnchantRequirement = NarciAPI.GetItemTempEnchantRequirement;
local GetSocketTypes = GetSocketTypes;
local C_Item = C_Item;

local GetContainerItemLink = C_Container.GetContainerItemLink;    --Dragonflight
local GetInventoryItemLink = GetInventoryItemLink;


local pow = math.pow;
local floor = math.floor;

local validSlotForTempEnchants = {
    --[5] = true,
    [16] = true,
    [17] = true,
};


local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

local animFrame = CreateFrame("Frame");
animFrame.duration = 0.5;
animFrame:Hide();
animFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    local offsetX;
    if self.t > self.duration then
        offsetX = self.toX;
        self:Hide();
    else
        offsetX = outQuart(self.t, self.fromX, self.toX, self.duration);
    end
    self.object:SetPoint("TOPRIGHT", self.objectAnchor, "TOPRIGHT", offsetX, 0);
end);

function animFrame:In()
    self.t = 0;
    local _;
    _, _, _, self.fromX = self.object:GetPoint();
    self.toX = 0;
    self:Show();
end

function animFrame:Out()
    self.t = 0;
    local _;
    _, _, _, self.fromX = self.object:GetPoint();
    self.toX = 48;
    self:Show();
end


local function SetButtonEnchant(button, ...)
    button:SetEnchantData(...);
end

local function SetButtonGem(button, ...)
    button:SetGemData(...);
end

local function SetButtonShard(button, ...)
    button:SetDominationShardData(...);
end

local function SetButtonTempEnchant(button, ...)
    button:SetTempEnchantData(...);
end

local function SetButtonCrystallic(button, ...)
    button:SetCrystallicData(...);
end

local function SetButtonPrimordial(button, ...)
    button:SetPrimordialStone(...);
end

local SetButtonData = SetButtonEnchant;


local ViewUpdator = {};
ViewUpdator.buttons = {};
ViewUpdator.b = 0;

function ViewUpdator:WipeButtonData()
    self.b = 0;
    for _, button in pairs(self.buttons) do
        button:WipeData();
    end
end

function ViewUpdator:UpdateVisibleArea(offsetY, forcedUpdate)
    if forcedUpdate then
        for i = 1, self.numButtons do
            self.buttons[i]:SetPoint("TOPLEFT", 0, -(self.b + i - 1) * BUTTON_HEIGHT);
            SetButtonData(self.buttons[i], DataProvider:GetDataByIndex(i + self.b));
            self.buttons[i].i = i;
        end
    else
        local b = floor( offsetY / BUTTON_HEIGHT + 0.5) - 1;
        if b ~= self.b then --last offset
            local buttons = self.buttons;
            if b > self.b then
                local topButton = tremove(buttons, 1);
                tinsert(buttons, topButton);
            else
                local bottomButton = tremove(buttons);
                tinsert(buttons, 1, bottomButton);
            end
            for i = 1, self.numButtons do
                buttons[i]:SetPoint("TOPLEFT", 0, -(b + i - 1) * BUTTON_HEIGHT);
                buttons[i].i = i;
                SetButtonData(buttons[i], DataProvider:GetDataByIndex(i + b));
            end
            self.b = b;
        end
    end
end

function ViewUpdator:UpdateCurrentView()
    local b = self.b;
    for i = 1, self.numButtons do
        SetButtonData(self.buttons[i], DataProvider:GetDataByIndex(i + b));
    end
end

function ViewUpdator:FindFocusedButton()
    if not MainFrame:IsMouseOver(0, 0, 0, -8) then
        return
    end
    for _, button in pairs(self.buttons) do
        if button:IsMouseOver() then
            if button:IsVisible() then
                return button;
            end
            break
        end
    end
end

function ViewUpdator:GetTopButtonIndex()
    return self.b
end

local DelayedUpdate = {};

DelayedUpdate.callback = function(f)
    MainFrame:RefreshListForBlizzardUI();
    f:SetScript("OnUpdate", nil);
end

function DelayedUpdate:Start()
    if not self.f then
        self.f = CreateFrame("Frame");
    end
    self.f:SetScript("OnUpdate", self.callback);
end

local buttonData = {
    {1, 1030900, AUCTION_HOUSE_FILTER_CATEGORY_EQUIPMENT, },
    {2, 136244, ENCHANTS, SPELL_FAILED_CANT_BE_ENCHANTED},
    {3, 134071, AUCTION_CATEGORY_GEMS, L["No Socket"]},
    {4, 413594, L["Temp Enchant"], },
};


local function PositionGemOverlay(equipmentSlot)
    local gemSlot = equipmentSlot.GemSlot;
    local frame = NarciGemSlotOverlay;
    frame:ClearAllPoints();
    frame:SetParent(Narci_Character);
    frame:SetFrameStrata("HIGH");
    frame:SetPoint("CENTER", gemSlot, "CENTER", 0, 0);
    frame.GemBorder:SetTexture(gemSlot.GemBorder:GetTexture());
    frame.GemIcon:SetTexture(gemSlot.GemIcon:GetTexture());
    if equipmentSlot.isRight then
        frame.GemBorder:SetTexCoord(1, 0, 0, 1);
        frame.Bling:SetTexCoord(0.5, 0, 0, 1);
        frame.Pulse:SetTexCoord(1, 0, 0, 1);
    else
        frame.GemBorder:SetTexCoord(0, 1, 0, 1);
        frame.Bling:SetTexCoord(0, 0.5, 0, 1);
        frame.Pulse:SetTexCoord(0, 1, 0, 1);
    end
    frame:Show();
    return true
end


NarciEquipmentListFilterButtonMixin = {};

function NarciEquipmentListFilterButtonMixin:OnLoad()
    FilterButton = self;
    self:OnLeave();
    self:SetLabelText(L["Owned"]);
    self.needUpdate = true;
end

function NarciEquipmentListFilterButtonMixin:OnEnter()
    self.Label:SetTextColor(0.92, 0.92, 0.92);
    self.Check:SetVertexColor(1, 1, 1);
    self.Square:SetStrokeColor(0.12, 0.12, 0.12);
    self.Square:SetBorderColor(0.8, 0.8, 0.8);
end

function NarciEquipmentListFilterButtonMixin:OnLeave()
    self.Label:SetTextColor(0.5, 0.5, 0.5);
    self.Check:SetVertexColor(0.8, 0.8, 0.8);
    self.Square:SetStrokeColor(0, 0, 0);
    self.Square:SetBorderColor(0.5, 0.5, 0.5);
end

function NarciEquipmentListFilterButtonMixin:OnShow()
    if self.needUpdate then
        self.needUpdate = nil;
        self:UpdateState();
    end
    self.FlyUp:Play();
end

function NarciEquipmentListFilterButtonMixin:OnClick()
    NarcissusDB.OnlyShowOwnedUpgradeItem = not NarcissusDB.OnlyShowOwnedUpgradeItem;
    self:UpdateState();
    MainFrame:UpdateCurrentList(true);
    ItemButtonHighlight:Hide();
    Tooltip:Hide();
    MainFrame.ItemList:ClearActionButtons();
end

function NarciEquipmentListFilterButtonMixin:UpdateState()
    local isEnabled = NarcissusDB.OnlyShowOwnedUpgradeItem;
    self.Check:SetShown(isEnabled);
    if isEnabled and self:IsVisible() then
        self.Check.AnimIn:Play();
    end
end

function NarciEquipmentListFilterButtonMixin:SetLabelText(text)
    self.Label:SetText(text);
    local width = self.Label:GetWidth();
    if width < 72 then
        width = 72;
    end
    self:SetWidth(width);
    self.Shadow:SetWidth(width + 24);
end


NarciEquipmentOptionMixin = CreateFromMixins(NarciAnimatedSizingFrameMixin);

function NarciEquipmentOptionMixin:OnLoad()
    MainFrame = self;
    ItemButtonHighlight = self.ItemList.ScrollChild.HighlightFrame;

    self.maxHeight = BUTTON_HEIGHT * (MAX_VISIBLE_BUTTONS + 0.5);
    self:SetBackdropColor(0, 0, 0);
    self:SetBorderColor(0.5, 0.5, 0.5);
    self:SetFrameSize(240, 48 * 3);
    self:SetAnchor(nil, "LEFT");
    self:Init();
    self.hitrectTop = 16;

    animFrame.object = self.ArtFrame.Stain;
    animFrame.objectAnchor = self.ArtFrame;

    self:SetParent(Narci_Character);
    addon.AssignEnchantButtonWidgets();

    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciEquipmentOptionMixin:RegisterEventsForNarcissus(state)
    if state then
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        self:RegisterEvent("BAG_UPDATE_DELAYED");
        self:UnregisterEvent("SOCKET_INFO_UPDATE");
        self:UnregisterEvent("BAG_UPDATE");
    else
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        self:UnregisterEvent("BAG_UPDATE_DELAYED");
        self:RegisterEvent("SOCKET_INFO_UPDATE");
        self:RegisterEvent("BAG_UPDATE");
    end
end

function NarciEquipmentOptionMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:UnregisterEvent("SOCKET_INFO_UPDATE");
    self:UnregisterEvent("BAG_UPDATE");
    self:UnregisterEvent("BAG_UPDATE_DELAYED");
    self:Hide();
    self:StopAnimating();
    self.itemLink = nil;
    self.slotButton = nil;
    self.socketOrderID = nil;
    NarciGemSlotOverlay:HideIfIdle();
end

function NarciEquipmentOptionMixin:OnShow()
    local scale = self:GetEffectiveScale();
    if scale ~= self.scale then
        self.scale = scale;
        PixelPerfectController:SetScale(scale);
    end
end

function NarciEquipmentOptionMixin:IsFocused()
    return ( self:IsMouseOver(self.hitrectTop, -16, -16, 16) or FilterButton:IsMouseOver(12, -12, -12, 12) or (self.slotButton and self.slotButton:IsMouseOver(0, 0, -24, 24)) )
end

local function CloseDelay_OnUpdate(self, elapsed)
    self.countdown = self.countdown + elapsed;
    if self.countdown > 0 then
        self:CloseUI();
    end
end

function NarciEquipmentOptionMixin:CloseUI(delay)
    if delay then
        self.countdown = -0.5;
        self:SetScript("OnUpdate", CloseDelay_OnUpdate);
    else
        self:SetScript("OnUpdate", nil);
        self.countdown = nil;
        self:Hide();
        Narci_FlyoutBlack:Out();
    end
end

function NarciEquipmentOptionMixin:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not self:IsFocused() then
            self:CloseUI();
        end
    elseif event == "SOCKET_INFO_UPDATE" or event == "BAG_UPDATE" then
        --this event precedes "SocketContainerItem" so we use a delay here
        DelayedUpdate:Start();
    elseif event == "BAG_UPDATE_DELAYED" then
        --Refresh list after extracting gem
        self:UpdateItemList("gem");
    end
end

function NarciEquipmentOptionMixin:SetAnchor(object, direction)
    self.Pointer:ClearAllPoints();
    if direction == "LEFT" then
        self.Pointer:SetTexCoord(0.25, 0.5, 0.25, 0.5);
        self.PointerBackdrop:SetTexCoord(0.5, 0.75, 0.25, 0.5);
        self.Pointer:SetPoint("CENTER", self, "TOPRIGHT", 0, -24);
    elseif direction == "RIGHT" then
        self.Pointer:SetTexCoord(0.5, 0.25, 0.25, 0.5);
        self.PointerBackdrop:SetTexCoord(0.75, 0.5, 0.25, 0.5);
        self.Pointer:SetPoint("CENTER", self, "TOPLEFT", 0, -24);
    elseif direction == "TOP" then
        self.Pointer:SetTexCoord(0.25, 0.5, 0.5, 0.75);
        self.PointerBackdrop:SetTexCoord(0.5, 0.75, 0.5, 0.75);
        self.Pointer:SetPoint("CENTER", self, "BOTTOM", 0, 0);
    elseif direction == "BOTTOM" then
        self.Pointer:SetTexCoord(0.25, 0.5, 0.75, 0.5);
        self.PointerBackdrop:SetTexCoord(0.5, 0.75, 0.75, 0.5);
        self.Pointer:SetPoint("CENTER", self, "TOP", 0, 0);
    else
        self.Pointer:Hide();
        self.PointerBackdrop:Hide();
        return
    end
    self.Pointer:Show();
    self.PointerBackdrop:Show();
end

function NarciEquipmentOptionMixin:SetBackdropColor(r, g, b, alpha)
    alpha = alpha or 1;
    self.Backdrop:SetColorTexture(r, g, b, alpha);
    self.PointerBackdrop:SetVertexColor(r, g, b, alpha);
end

function NarciEquipmentOptionMixin:SetFromSlotButton(slotButton, returnHome)
    if (slotButton == self.slotButton) and returnHome and self.isHome then
        self:CloseUI();
        return
    end

    self.isNarcissusUI = true;
    local slotID = slotButton.slotID;
    self.slotID = slotID;
    self.slotButton = slotButton;
    self.itemLink = slotButton.itemLink;
    self.hitrectTop = 16;

    local runeOverlay = NarciRuneAnimationOverlay;
    if slotButton.isRight then
        self:SetPoint("TOPLEFT", slotButton, "TOPLEFT", 2 - 240, -12);
        runeOverlay:SetPoint("CENTER", slotButton.RuneSlot, "CENTER", 2, 0);
        runeOverlay:SetDirection(1);
    else
        self:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", -2, -12);
        runeOverlay:SetPoint("CENTER", slotButton.RuneSlot, "CENTER", -2, 0);
        runeOverlay:SetDirection(-1);
    end
    runeOverlay:SetParent(Narci_Character);

    self:SetParent(slotButton);
    self:SetFrameStrata("DIALOG");
    self:SetIgnoreParentScale(false);
    self:SetScale(1);
    self:RegisterEventsForNarcissus(true);

    local initialAlpha;
    if returnHome then
        initialAlpha = 0;
        self:ShowMenu();
    end
    FadeFrame(self, 0.15, 1, initialAlpha);

    Narci_EquipmentFlyoutFrame:Hide();
    Narci:HideButtonTooltip();

    local isWeaponValidForEnchant;
    self.inUseGemID, self.inUsedEnchantID, isWeaponValidForEnchant = GetAppliedEnhancement(slotID);
    GetNewGemID(false);
    local validForEnchant, categoryChanged = EnchantDataProvider:SetSubset(slotID);
    self.resetScrollNextTime = categoryChanged == true;

    validForEnchant = validForEnchant and isWeaponValidForEnchant;

    TempDataProvider:SetSubset(slotID);

    Narci_FlyoutBlack:In();
    Narci_FlyoutBlack:RaiseFrameLevel(slotButton);


    if validForEnchant then
        self.meunButtons[2]:Enable();
    else
        self.meunButtons[2]:Disable();
    end

    local numSocket, socketIsDiverse, lastType = NarciAPI.DoesItemHaveSockets(self.itemLink);
    if numSocket and numSocket > 0 and PositionGemOverlay(slotButton) then
        self.meunButtons[3]:Enable();
        GemDataProvider:SetSubsetBySocketName(lastType);
    else
        self.meunButtons[3]:Disable();
    end

    --Calculate available gears
    local button1 = self.meunButtons[1];
    local equipmentTable = {};
    GetInventoryItemsForSlot(slotID, equipmentTable);
    local numEquipment = 0;
    local invLocationPlayer = ITEM_INVENTORY_LOCATION_PLAYER;
    local _, _, inBags
    for location, hyperlink in pairs(equipmentTable) do
        if ( location - slotID ~= invLocationPlayer ) then      --Remove the currently equipped item from the list
            _, _, inBags = EquipmentManager_UnpackLocation(location);
            if inBags then
                numEquipment = numEquipment + 1;
            end
        end
    end
    equipmentTable = nil;
    if numEquipment > 0 then
        button1:Enable();
        button1:SetButtonText(button1.buttonName, string.format(SINGLE_PAGE_RESULTS_TEMPLATE, numEquipment));
    else
        button1:Disable();
        local slotName = NarciAPI.GetSlotNameAndTexture(slotID);
        button1:SetButtonText(button1.buttonName, string.format(L["No Other Item For Slot"], slotName));
    end
end

function NarciEquipmentOptionMixin:SetGemListFromSlotButton(slotButton)
    self:SetFromSlotButton(slotButton, false);
    self:ShowGemList(nil, true);
end

function NarciEquipmentOptionMixin:SetGemListForBlizzardUI(id1, id2)
    self.isNarcissusUI = false;
    local parentFrame = ItemSocketingFrame;
    if not parentFrame then
        self.itemLink = nil;
        self.itemID = nil;
        return
    end

    local itemLink;
    if id2 then
        itemLink = GetContainerItemLink(id1, id2);
    else
        itemLink = GetInventoryItemLink("player", id1);
    end
    self.itemLink = itemLink;

    if not itemLink then
        self.itemID = nil;
        return
    end

    local socketTypeName = GetSocketTypes(1);
    if not socketTypeName then
        return
    end

    local itemID, _, _, invType = C_Item.GetItemInfoInstant(itemLink);
    self.itemID = itemID;

    local slotID = NarciAPI.GetSlotIDByInvType(invType);
    self.slotID = slotID;
    self.slotButton = nil;
    self.inUseGemID, self.inUsedEnchantID = GetAppliedEnhancement(itemLink);

    EnchantDataProvider:SetSubset(slotID);
    GemDataProvider:SetSubsetBySocketName(socketTypeName);

    self:ClearAllPoints();
    self:SetIgnoreParentScale(true);
    local uiScale = UIParent:GetEffectiveScale();
    self:SetScale(math.max(uiScale, 0.75));
    self:SetParent(parentFrame);
    self:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 4, 0);
    self:Show();
    self:SetAlpha(1);
    self:ShowGemList(socketTypeName);
    self:RegisterEventsForNarcissus(false);

    self.meunButtons[1]:Disable();      --Equipment


    if self.isDominationItem then
        local gemLink = GetExistingSocketLink(1);
        if gemLink then
            local existingGemID, _, _, _, icon = C_Item.GetItemInfoInstant(gemLink);
            NarciItemPushOverlay:WatchIcon(icon);
        else
            NarciItemPushOverlay:HideIfIdle();
        end
    else
        NarciItemPushOverlay:HideIfIdle();
    end

    --flash the "Apply" button on the ItemSocketingFrame
    --Disabled: Taint during combat!
    --[[
    if newGemID then
        NarciRedButtonFlash:FlashButton(ItemSocketingSocketButton);
    else
        NarciRedButtonFlash:Hide();
    end
    --]]
end

function NarciEquipmentOptionMixin:SetItemPosition(id1, id2)
    self.itemPositions = {id1, id2};
end

function NarciEquipmentOptionMixin:RefreshListForBlizzardUI()
    self:SetGemListForBlizzardUI( unpack(self.itemPositions) );
end

function NarciEquipmentOptionMixin:GetCurrentSlot()
    return self.slotButton;
end

function NarciEquipmentOptionMixin:FadeOut()
    FadeFrame(self, 0.15, 0);
end

function NarciEquipmentOptionMixin:Init()
    self.ItemList.NoItemText:SetText(L["No Item Alert"]);
    local button;
    self.meunButtons = {};
    for i = 1, #buttonData do
        button = CreateFrame("Button", nil, self.Menu, "NarciEquipmentOptionButtonTemplate");
        button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -48 * (i - 1));
        button.type = buttonData[i][1];
        button.Icon:SetTexture(buttonData[i][2]);
        button.buttonName = buttonData[i][3];
        button:SetButtonText(button.buttonName);
        button.disabledText = buttonData[i][4];
        self.meunButtons[i] = button;

        if button.type == 4 then
            local tempEnchantFrame = CreateFrame("Frame", nil, button, "NarciSimpleTempEnchantIndicatorTemplate");
            tempEnchantFrame:SetSize(12, 12);
            button.TempEnchantIndicator = tempEnchantFrame;
            tempEnchantFrame:Hide();
            tempEnchantFrame:SetPoint("BOTTOMLEFT", button.Icon, "BOTTOMRIGHT", 7, 0);
        end
    end

    NarciAPI.CreateSmoothScroll(self.ItemList);
    self.ItemList:SetStepSize(48);
    self.ItemList:SetOnValueChangedFunc(function(value)
        ViewUpdator:UpdateVisibleArea(value);
    end);
    self.ItemList:SetOnResetFunc(function()
        ViewUpdator:WipeButtonData();
        self.ItemList:SetOffset(0);
        ViewUpdator:UpdateVisibleArea(0, true);
    end);
    self.ItemList:SetOnScrollStartedFunc(function()
        Tooltip:ClearAllPoints();
        Tooltip:FadeOut();
    end);
    self.ItemList:SetOnScrollFinishedFunc(function()
        local focusedButton = ViewUpdator:FindFocusedButton();
        if focusedButton then
            Tooltip:ShowButtonTooltip(focusedButton);
        end
    end);
    self.ItemList:SetUpdateInterval(0.05);

    self.ItemList:SetScript("OnMouseUp", addon.RightClickToReturnHome);
    self.ItemList.ActionBlocker:SetScript("OnMouseUp", addon.RightClickToReturnHome);
    self.ItemList.ActionBlocker.ErrorMsg:SetText(L["Combat Error"]);
end

function NarciEquipmentOptionMixin:ShowMenu()
    animFrame:In();
    self.isHome = true;
    self.Menu:Show();
    self.ItemList:Hide();
    self:StopAnimating();
    self:ToggleActionBlocker(false);
    local numButtons;
    if validSlotForTempEnchants[self.slotID] then
        numButtons = 4;
        local button4 = self.meunButtons[4];
        button4:Show();
        local hasTempEnchant = button4.TempEnchantIndicator:SetInventoryItem(self.slotID);
        if hasTempEnchant then
            button4:SetButtonText(button4.buttonName, " ");
            button4.TempEnchantIndicator:Show();
        else
            button4:SetButtonText(button4.buttonName);
            button4.TempEnchantIndicator:Hide();
        end
    else
        numButtons = 3;
        self.meunButtons[4]:Hide();
    end
    self:AnimateSize(240, numButtons*BUTTON_HEIGHT, 0.25);
end

function NarciEquipmentOptionMixin:GetNumActiveButtons()
    return (self.meunButtons[4]:IsShown() and 4) or 3
end

function NarciEquipmentOptionMixin:ShowEquipment()
    if self.slotButton then
        Narci_EquipmentFlyoutFrame:SetItemSlot(self.slotButton, true);
        FadeFrame(self, 0.12, 0);
    end
end

function NarciEquipmentOptionMixin:ShowItemList(listType, resetScroll)
    if self.CreateList then
        self:CreateList();
    end
    animFrame:Out();
    self.isHome = false;
    self.Menu:Hide();
    self.ItemList:Show();
    if listType ~= self.listType then
        self.listType = listType;
        self.ItemList:SetOffset(0);
    end
    self:UpdateCurrentList(resetScroll);
    self.hitrectTop = 32;
end

function NarciEquipmentOptionMixin:ShowGemList(specifiedTypeName, forceReset)
    DataProvider = GemDataProvider;

    local socketType = self.ItemList.SocketSelect:SetupFromItemLink(self.itemLink);

    if specifiedTypeName then
        socketType = specifiedTypeName;
    end

    socketType = socketType or "none";
    local socketTypeName = GemDataProvider:SetSubsetBySocketName(socketType);
    local resetScroll = forceReset or socketTypeName ~= self.socketTypeName;
    self.socketTypeName = socketTypeName;

    if self.socketTypeName == "domination" then
        SetButtonData = SetButtonShard;
    elseif self.socketTypeName == "cypher" then
        SetButtonData = SetButtonCrystallic;
    elseif self.socketTypeName == "primordial" then
        SetButtonData = SetButtonPrimordial;
    else
        SetButtonData = SetButtonGem;
    end

    self:ShowItemList("gem", resetScroll);

    local showActionBlocker = GemDataProvider:IsSocketRemovable(socketTypeName) and (self.inUseGemID ~= nil);
    self:ToggleActionBlocker(showActionBlocker);
end

function NarciEquipmentOptionMixin:GetSocketOrderID()
    return self.socketOrderID or 1;
end

function NarciEquipmentOptionMixin:SetSocketOrderID(id)
    self.socketOrderID = id or 1;
end

function NarciEquipmentOptionMixin:ShowEnchantList()
    DataProvider = EnchantDataProvider;
    SetButtonData = SetButtonEnchant;
    local resetScroll = self.resetScrollNextTime;
    self.resetScrollNextTime = nil;
    self:ShowItemList("enchant", resetScroll);
    self.ItemList.SocketSelect:Hide();
end

function NarciEquipmentOptionMixin:ShowTempEnchantList()
    DataProvider = TempDataProvider;
    SetButtonData = SetButtonTempEnchant;
    self:ShowItemList("temp", true);
    self.ItemList.SocketSelect:Hide();
end

function NarciEquipmentOptionMixin:UpdateItemList(listType)
    if listType and listType == self.listType then
        self:ShowItemList(listType);
    end
end

function NarciEquipmentOptionMixin:ToggleActionBlocker(state)
    self.ItemList.ActionBlocker:SetShown(state);
    if state then
        self.ItemList.ScrollChild:Hide();
        self.ItemList.ScrollBar:Hide();
        self.ItemList.Tooltip:Hide();
        self.ItemList.SelectionOverlay:Hide();
        self.ItemList.GemActionButton:Hide();

        local success = NarciItemSocketingActionButton:SetParentFrame(self.ItemList.ActionBlocker, self.isNarcissusUI); --combat lockdown
        self.ItemList.ActionBlocker.ErrorMsg:SetShown(not success);
    else
        if not self.ItemList.ScrollChild:IsShown() then
            FadeFrame(self.ItemList.ScrollChild, 0.2, 1, 0);
        end
    end
end

function NarciEquipmentOptionMixin:UpdateCurrentList(resetScroll)
    local numItems = DataProvider:ApplyFilter(NarcissusDB.OnlyShowOwnedUpgradeItem);
    if numItems > 4 then
        self.ItemList:SetScrollRange(BUTTON_HEIGHT*(numItems - MAX_VISIBLE_BUTTONS - 0.5));
        self:AnimateSize(240, BUTTON_HEIGHT * 4.5, 0.25);
    else
        self.ItemList:SetScrollRange(0);
        self:AnimateSize(240, BUTTON_HEIGHT * 4, 0.25);
    end

    self.isListEmpty = numItems == 0;
    self.ItemList.NoItemText:SetShown(self.isListEmpty and (not NarciItemSocketingActionButton:IsVisible()));
    self.inUseGemID, self.inUsedEnchantID = GetAppliedEnhancement(self.itemLink);
    local newGemID = GetNewGemID(true);

    if resetScroll then
        self.ItemList:Reset();
    else
        ViewUpdator:UpdateCurrentView();
    end
end

function NarciEquipmentOptionMixin:CreateList()
    local numButtons = 6;
    for i = 1, numButtons do
        local button = CreateFrame("Button", nil, self.ItemList.ScrollChild, "NarciEquipmentEnchantButtonTemplate");
        button:SetPoint("TOPLEFT", self.ItemList.ScrollChild, "TOPLEFT", 0, -48*(i-1));
        tinsert(ViewUpdator.buttons, button);
    end
    ViewUpdator.numButtons = numButtons;
    self.CreateList = nil;
end

function NarciEquipmentOptionMixin:HasMouseFocus()
    return (self:IsShown() and self:IsFocused());
end

function NarciEquipmentOptionMixin:IsCurrentListEmpty()
    return self.isListEmpty
end

function NarciEquipmentOptionMixin:GetCurrentEquipment()
    return self.itemID, self.itemLink
end

NarciEquipmentOptionButtonMixin = {};

function NarciEquipmentOptionButtonMixin:OnLoad()
    self:OnLeave();
end

function NarciEquipmentOptionButtonMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);
    self.Highlight:Show();
end

function NarciEquipmentOptionButtonMixin:OnLeave()
    self.Icon:SetVertexColor(0.72, 0.72, 0.72);
    self.Highlight:Hide();
end

function NarciEquipmentOptionButtonMixin:OnMouseDown(button)
    if not self:IsEnabled() then return end;

    if button == "LeftButton" then
        self.AnimPushed:Stop();
        self.AnimPushed.Hold:SetDuration(20);
        self.AnimPushed:Play();
    end
end

function NarciEquipmentOptionButtonMixin:OnMouseUp(button)
    if not self:IsEnabled() then return end;

    if button == "LeftButton" then
        self.AnimPushed.Hold:SetDuration(0);
    end
end

function NarciEquipmentOptionButtonMixin:OnClick()
    if MainFrame.CreateList then
        MainFrame:CreateList();
    end
    if self.type == 1 then
        MainFrame:ShowEquipment();
    elseif self.type == 2 then
        MainFrame:ShowEnchantList();
    elseif self.type == 3 then
        MainFrame:ShowGemList();
    elseif self.type == 4 then
        MainFrame:ShowTempEnchantList();
    end
end

function NarciEquipmentOptionButtonMixin:SetButtonText(text1, text2)
    self.Text1:SetText(text1);
    self.Text2:SetText(text2);

    if text2 then
        self.Text1:ClearAllPoints();
        self.Text1:SetPoint("BOTTOMLEFT", self.Icon, "RIGHT", 6, 1);
        self.Text1:SetJustifyV("BOTTOM");
        self.Text1:SetMaxLines(1);
        if text1 then
            self.Text2:Show();
        end
    else
        self.Text2:Hide();
        if text1 then
            self.Text1:ClearAllPoints();
            self.Text1:SetPoint("LEFT", self.Icon, "RIGHT", 6, 0);
            self.Text1:SetJustifyV("MIDDLE");
            self.Text1:SetMaxLines(2);
        end
    end
end

function NarciEquipmentOptionButtonMixin:OnEnable()
    self.Text1:SetTextColor(0.92, 0.92, 0.92);
    self.Text2:SetTextColor(0.5, 0.5, 0.5);
    self.Highlight:SetColorTexture(0.2, 0.2, 0.2);
    self.Icon:SetDesaturation(0);
    self:SetButtonText(self.buttonName);
end

function NarciEquipmentOptionButtonMixin:OnDisable()
    self.Text1:SetTextColor(0.6, 0.6, 0.6);
    self.Text2:SetTextColor(1, 0.3137, 0.3137);
    self.Highlight:SetColorTexture(0.25, 0, 0);
    self.Icon:SetDesaturation(1);
    if self.disabledText then
        self:SetButtonText(self.buttonName, self.disabledText);
    end
end


NarciEquipmentListTooltipMixin = CreateFromMixins(NarciAnimatedSizingFrameMixin);

function NarciEquipmentListTooltipMixin:OnLoad()
    Tooltip = self;
    self.ClipFrame.Description:SetPoint("TOPLEFT", self, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING);
    self.duration = 0;
    self:SetBackdropColor(0.08, 0.08, 0.08, 0.9);
end

function NarciEquipmentListTooltipMixin:OnHide()
    self:SetScript("OnUpdate", nil);
    self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
    self:SetAlpha(0);
end

function NarciEquipmentListTooltipMixin:SetSpell(spellID)
    self.spellID = spellID;
    self.itemID = nil;
    if not spellID then
        self:Hide();
    end
    local text = GetSpellDescription(spellID);
    local f = self.ClipFrame;
    if text and text ~= "" then
        --text = gsub(text, "(%d[%d,%%]*)","|cffFFFFFF%1|r");   --Make numbers green
        text = TOOLTIP_PREFIX..text;
        if self.parentButton.showFailureReason and (not self.parentButton:IsEnabled()) then
            local requirement = GetItemTempEnchantRequirement(self.parentButton.requirementID);
            if requirement then
                text = text.."\n\n|cffff5050"..requirement.."|r";
            end
        end
        f.Description:SetSize(0, 0);
        f.Description:SetText(text);
        f.Icon:Show();
        f.Description:Show();
        self:UpdateSize();
        self:OnDataReceived();
    else
        f.Description:Hide();
        f.Icon:Hide();
        self:LoadSpell(spellID);
    end
    self:FadeIn();
end

function NarciEquipmentListTooltipMixin:OnDataReceived()
    self.pendingID = nil;
    self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
    self.ClipFrame.LoadingIndicator:Hide();
    if not self.ClipFrame.Description:IsShown() then
        self.ClipFrame.Description.FadeIn:Play();
        self.ClipFrame.Description:Show();
    else
        self.ClipFrame.Description.FadeIn:Stop();
        self.ClipFrame.Description:SetTextColor(0.529, 0.863, 0.6, 1);
    end
end

function NarciEquipmentListTooltipMixin:UpdateSize()
    local f = self.ClipFrame;
    local textWidth = math.min(f.Description:GetWidth(), 240 - 2*TOOLTIP_PADDING);
    f.Description:SetWidth(textWidth + 0.2);
    textWidth = f.Description:GetWrappedWidth();
    local textHeight = f.Description:GetHeight();
    local frameHeight = textHeight + 2*TOOLTIP_PADDING;
    self:AnimateSize(textWidth + 2*TOOLTIP_PADDING, frameHeight);
    f.Icon:SetSize(frameHeight, frameHeight);
end

function NarciEquipmentListTooltipMixin:SetItem(itemID)
    self.itemID = itemID;
    self.spellID = nil;
    if itemID then
        if not C_Item.IsItemDataCachedByID(itemID) then
            self:LoadItem(itemID);
            self:FadeIn();
            return
        end
        local name, spellID = nil, nil; --GetItemSpell(itemID);     --TWW: For some reason regular gem yields spellID
        local isCrystallic = NarciAPI.GetCrystallicSpell(itemID);
        if isCrystallic then
            self:SetSpell(isCrystallic);
        elseif spellID then
            self:SetSpell(spellID);
        else
            local line = DataProvider:GetItemTooltipLines(itemID);
            self.ClipFrame.Description:SetSize(0, 0);
            local tooltipText, isCached = GetCachedItemTooltipTextByLine(itemID, line, function(newText)
                if self.itemID == itemID and self:IsTurningVisible() then
                    self:SetItem(itemID);
                end
            end);
            if isCached then
                tooltipText = RemoveColorString(tooltipText);
                self.ClipFrame.Description:SetText(tooltipText);
                self:OnDataReceived();
            else
                self.ClipFrame.Description:Hide();
                self:StartLoading();
            end
            self.pendingID = nil;
            self:UpdateSize();
            self:FadeIn();
        end
    else
        self:Hide();
    end
end

function NarciEquipmentListTooltipMixin:OnEvent(event, ...)
    if event == "SPELL_DATA_LOAD_RESULT" then
        local spellID, success = ...
        if spellID == self.pendingID and success then
            self:SetSpell(spellID);
        end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if itemID == self.pendingID and success then
            self:SetItem(itemID);
        end
    end
end

function NarciEquipmentListTooltipMixin:StartLoading()
    self.ClipFrame.LoadingIndicator.Rotate:Play();
    self.ClipFrame.LoadingIndicator:Show();
end

function NarciEquipmentListTooltipMixin:LoadSpell(spellID)
    C_Spell.RequestLoadSpellData(spellID);
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
    self:RegisterEvent("SPELL_DATA_LOAD_RESULT");
    self.pendingID = spellID;
    self:StartLoading();
end

function NarciEquipmentListTooltipMixin:LoadItem(itemID)
    C_Item.RequestLoadItemDataByID(itemID);
    self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    self.pendingID = itemID;
    self:StartLoading();
end

function NarciEquipmentListTooltipMixin:FadeIn()
    self.turningVisible = true;
    FadeFrame(self, 0.15, 1);
end

function NarciEquipmentListTooltipMixin:FadeOut()
    self.turningVisible = false;
    FadeFrame(self, 0.2, 0);
end

function NarciEquipmentListTooltipMixin:IsTurningVisible()
    return self.turningVisible
end

function NarciEquipmentListTooltipMixin:OnShow()
    self:SetFrameStrata("DIALOG");
end

function NarciEquipmentListTooltipMixin:ShowButtonTooltip(button)
    self.parentButton = button;
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", button, "TOPRIGHT", 4, 0);
    self.ClipFrame.Icon:SetTexture(button.Icon:GetTexture());

    if self:IsShown() then
        self.duration = 0.25;
    else
        self.duration = 0;
    end

    if button.spellID then
        self:SetSpell(button.spellID);
    elseif button.itemID then
        self:SetItem(button.itemID);
    else
        return
    end
end

local function ShouldAnchorToBlizzard()
    if Narci.deferGemManager then
        return false
    end

    return NarcissusDB.GemManager and (not Narci_Character:IsShown()) and (not MainFrame:IsShown() or MainFrame.isNarcissusUI)
end



----For GamePad----
NarciEquipmentOptionItemListMixin = {};

function NarciEquipmentOptionItemListMixin:OnShow()

end

function NarciEquipmentOptionItemListMixin:OnHide()

end

function NarciEquipmentOptionItemListMixin:GetNumItems()
    return #ViewUpdator.buttons, ViewUpdator.b
end

function NarciEquipmentOptionItemListMixin:GetItemButtons()
    return ViewUpdator.buttons
end

function NarciEquipmentOptionItemListMixin:ScrollByOneButton(delta)
    --for GamePad
    if delta > 0 then
        self:SmoothScrollByValue(-BUTTON_HEIGHT);
    elseif delta < 0 then
        self:SmoothScrollByValue(BUTTON_HEIGHT);
    end
end

function NarciEquipmentOptionItemListMixin:ClearActionButtons()
    self.SelectionOverlay:Hide();
    NarciEquipmentEnchantActionButton:Clear();
    self.GemActionButton:Clear();
end




local function SocketInventoryItem_Callback(slot)
    MainFrame:SetItemPosition(slot);
    if ShouldAnchorToBlizzard() then
        MainFrame:SetGemListForBlizzardUI(slot);
    end
end
hooksecurefunc("SocketInventoryItem", SocketInventoryItem_Callback);

local function SocketContainerItem_Callback(bag, slot)
    MainFrame:SetItemPosition(bag, slot);
    if ShouldAnchorToBlizzard() then
        MainFrame:SetGemListForBlizzardUI(bag, slot);
    end
end
hooksecurefunc(C_Container, "SocketContainerItem", SocketContainerItem_Callback);