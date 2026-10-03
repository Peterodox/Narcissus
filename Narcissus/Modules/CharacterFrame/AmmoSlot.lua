local _, addon = ...

local NarciAPI = NarciAPI;
local L = Narci.L;
local FadeFrame = NarciFadeUI.Fade;
local SharedBlackScreen = addon.SharedBlackScreen;

---@class AmmoUtil
local AmmoUtil = {};


local FlyoutFrame;
local CreateFlyoutFrame;


do  -- AmmoUtil
    AmmoUtil.dpsCache = {};

    local Ammos = {
        -- Ammo itemID, item level from high to low
        arrow = {274387, 18042, 19316, 11285, 3464, 3030, 2515, 2512},
        bullet = {274388, 15997, 19317, 11630, 10513, 11284, 10512, 3465, 8069, 3033, 8068, 5568, 2519, 8067, 4960, 2516},
    };

    ---@param ammoType "arrow"|"bullet"
    ---@param includeUnowned boolean? Used for debugging. Show full list.
    ---@return table? itemIDs
    function AmmoUtil.GetAvailableAmmosByType(ammoType, includeUnowned)
        local tbl = {};
        local n = 0;
        local GetItemCount = C_Item.GetItemCount;

        if Ammos[ammoType] then
            for _, itemID in ipairs(Ammos[ammoType]) do
                if GetItemCount(itemID) > 0 or includeUnowned then
                    n = n + 1;
                    tbl[n] = itemID;
                end
            end
        end

        if n > 0 then
            return tbl;
        end
    end

    function AmmoUtil.GetDpsByItemID(itemID)
        if not AmmoUtil.dpsCache[itemID] then
            AmmoUtil.dpsCache[itemID] = NarciAPI.GetAmmoDps(itemID);
        end
        return AmmoUtil.dpsCache[itemID];
    end

    function AmmoUtil.WrapAmmoCountInColor(count)
        if not count then return; end
        if count > 9999 then
            count = "|cffffffff".."9999+".."|r";
        elseif count <= 50 then
            count = "|cffff0000"..count.."|r"
        elseif count <= 200 then
            count = "|cffffD100"..count.."|r"
        end
        return count;
    end

    function AmmoUtil.TryEquipAmmo(itemID)
        local successInternal;
        if not InCombatLockdown() then
            NarciAPI.PickupContainerItemByItemID(itemID);
            if CursorHasItem() then
                PickupInventoryItem(18);
                successInternal = true;
            end
            ClearCursor();
        end
        return successInternal;
    end

    function AmmoUtil.ShowFlyout(ammoSlot)
        if not FlyoutFrame then
            CreateFlyoutFrame();
        end
        FlyoutFrame:InitFromSlotButton(ammoSlot);
    end

    function AmmoUtil.HideFlyout()
        if FlyoutFrame then
            FlyoutFrame:Hide();
        end
    end

    function AmmoUtil.ToggleFlyout(ammoSlot)
        if FlyoutFrame and FlyoutFrame:IsShown() then
            FlyoutFrame:Hide();
        else
            AmmoUtil.ShowFlyout(ammoSlot)
        end
    end
end


local AmmoSlotMixin = {};
do
    addon.AmmoSlotMixin = AmmoSlotMixin;

    function AmmoSlotMixin:OnLoad()
        local slotID = 0;
        self.slotName = "AmmoSlot";
        self:SetID(slotID);
        self.slotID = slotID;
    end

    ---Called by the RangedSlot. Also resets auto-equip retry times.
    function AmmoSlotMixin:SetAmmoType(ammoType, ammoTypeName)
        self.ammoType = ammoType;
        self.ammoTypeName = ammoTypeName;
        self.retryTimes = 0;
    end

    function AmmoSlotMixin:CanRetry()
        return self.retryTimes and self.retryTimes < 3;
    end

    function AmmoSlotMixin:TryEquipAmmo(ammoItemID)
        if not self:CanRetry() then return; end

        if AmmoUtil.TryEquipAmmo(ammoItemID) then
            return true;
        else
            self.retryTimes = self.retryTimes + 1;
            return false;
        end
    end

    function AmmoSlotMixin:Refresh()
        self.isSlotDirty = nil;

        local itemName, itemIcon, count, currentAmmoType;
        local r, g, b;
        local quality = 0;
        local itemID = GetInventoryItemID("player", 0);
        self.itemID = itemID;

        if itemID then
            itemName, _, quality = C_Item.GetItemInfo(itemID);
            itemIcon = GetInventoryItemTexture("player", 0)
            count = GetInventoryItemCount("player", 0);
            count = AmmoUtil.WrapAmmoCountInColor(count);
            local subClassID = select(7, C_Item.GetItemInfoInstant(itemID));
            currentAmmoType = (subClassID == 2 and "arrow") or (subClassID == 3 and "bullet");
        else
            itemName = SPELL_FAILED_NO_AMMO;
            itemIcon = 136520;	--ranged slot texture
            r, g, b = 1, 0, 0;
        end

        if currentAmmoType ~= self.ammoType then
            local hasCandidateItem;
            if self:CanRetry() then
                -- Auto-swap ammo if not match
                local ammos = AmmoUtil.GetAvailableAmmosByType(self.ammoType);
                if ammos then
                    hasCandidateItem = true;
                    local bestAmmoItemID = ammos[1];
                    if bestAmmoItemID ~= itemID then

                        C_Timer.After(0.1, function()
                            if not self:TryEquipAmmo(bestAmmoItemID) then
                                self:Refresh();
                            end
                        end);
                    end
                end
            end

            if hasCandidateItem then
                itemName = L["Item Switching In Progress"];
                r, g, b = 0.5, 0.5, 0.5;
            else
                r, g, b = 1, 0, 0;
            end

            count = "";
        end

        if not b then
            r, g, b = NarciAPI.GetItemQualityColor(quality);
        end

        self.Name:SetText(itemName);
        self.Name:SetTextColor(r, g, b);
        self.ItemCount:SetText(count);
        self.Icon:SetTexture(itemIcon);

        NarciAPI.SetBorderTexture(self.Border, quality, 2);

        self.GradientBackground:SetWidth(math.max(self.Name:GetWrappedWidth(), 48) + 48);

        -- Update flyout if shown
        if FlyoutFrame and FlyoutFrame:IsShown() then
            AmmoUtil.ShowFlyout(self);
        end
    end

    function AmmoSlotMixin:OnClick()
        AmmoUtil.ToggleFlyout(self);
        Narci:HideButtonTooltip();
    end

    function AmmoSlotMixin:OnEnter()
        FadeFrame(self.Highlight, 0.15, 1);
        NarciGameTooltip:SetFromSlotButton(self, -2, 6);
    end

    function AmmoSlotMixin:OnLeave()
        FadeFrame(self.Highlight, 0.25, 0);
        Narci:HideButtonTooltip();
    end

    function AmmoSlotMixin:OnShow()
		-- We need this event to update Ammo Slot because "PLAYER_EQUIPMENT_CHANGED" doesn't fire for that
        self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player");
    end

    function AmmoSlotMixin:OnHide()
        self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
    end

    function AmmoSlotMixin:OnEvent(event, ...)
        if event == "UNIT_INVENTORY_CHANGED" then
            self:RequestUpdate();
        end
    end

    function AmmoSlotMixin:RequestUpdate()
        if not self.t then
            self:SetScript("OnUpdate", self.OnUpdate);
        end
        self.isSlotDirty = true;
        self.t = 0;
    end

    function AmmoSlotMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.1 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            if self.isSlotDirty then
                self:Refresh();
            end
        end
    end
end


do  -- FlyoutFrame
    local FlyoutFrameMixin = {};

    function FlyoutFrameMixin:OnShow()
        self:RegisterEvent("GLOBAL_MOUSE_UP");
    end

    function FlyoutFrameMixin:OnHide()
        self:Hide();
        self:SetAlpha(0);
        self.itemCallbacks = nil;
        self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
        self:UnregisterEvent("GLOBAL_MOUSE_UP");
        SharedBlackScreen:TryHide();
    end

    function FlyoutFrameMixin:OnEvent(event, ...)
        if event == "ITEM_DATA_LOAD_RESULT" then
            local itemID, success = ...
            if self.itemCallbacks then
                if self.itemCallbacks[itemID] then
                    self.itemCallbacks[itemID]:SetItemByID(itemID, itemID == self.equippedItemID);
                end
            else
                self:UnregisterEvent(event);
            end
        elseif event == "GLOBAL_MOUSE_UP" then
            if not self:IsFocused() then
                self:Hide();
            end
        end
    end

    function FlyoutFrameMixin:AddItemCallbacks(itemID, button)
        if not self.itemCallbacks then
            self.itemCallbacks = {};
            self:RegisterEvent("ITEM_DATA_LOAD_RESULT");
        end
        self.itemCallbacks[itemID] = button;
    end

    function FlyoutFrameMixin:DisplayItems(items)
        self.buttonPool:ReleaseAll();
        self.itemCallbacks = nil;

        local n = 0;
        local buttonHeight = 24;
        local gap = 0;

        if items and #items > 0 then
            for _, itemID in ipairs(items) do
                local button = self.buttonPool:Acquire();
                n = n + 1;
                button:ClearAllPoints();
                button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, (1 - n) * (buttonHeight + gap));
                button:Show();
                if not C_Item.IsItemDataCachedByID(itemID) then
                    self:AddItemCallbacks(itemID, button);
                    C_Item.RequestLoadItemDataByID(itemID);
                end
                button:SetItemByID(itemID, itemID == self.equippedItemID);
            end
            self.AlertText:Hide();
        else
            n = 1;
            if self.ammoTypeName then
                self.AlertText:SetText(L["ItemType Not Found Format"]:format(self.ammoTypeName));
            else
                self.AlertText:SetText(L["No Item Alert"]);
            end
            self.AlertText:Show();
        end

        self:SetHeight(n * (buttonHeight + gap) - gap);
    end

    function FlyoutFrameMixin:InitFromSlotButton(ammoSlot)
        self.ammoSlot = ammoSlot;

        local includeUnowned = false; -- Set to "true" when debugging. Some items in the database may never get used.
        local items = AmmoUtil.GetAvailableAmmosByType(ammoSlot.ammoType, includeUnowned);
        self.equippedItemID = ammoSlot.itemID;
        self.ammoTypeName = ammoSlot.ammoTypeName;

        self:ClearAllPoints();
        self:SetPoint("TOPLEFT", ammoSlot, "RIGHT", 4, 12);
        self:DisplayItems(items);
        self:Show();
        FadeFrame(self, 0.15, 1);

        SharedBlackScreen:TryShow();
        SharedBlackScreen:RaiseFrameLevel(ammoSlot);

        self:SetFrameLevel(ammoSlot:GetFrameLevel() + 2);
    end

    function FlyoutFrameMixin:IsFocused()
        return self:IsMouseOver() or (self.ammoSlot and self.ammoSlot:IsMouseOver());
    end

    function CreateFlyoutFrame()
        local f = CreateFrame("Frame", nil, Narci_Character);
        FlyoutFrame = f;
        f:Hide();
        f:SetAlpha(0);
        f:SetSize(240, 24);
        f:SetClampedToScreen(true);
        f:SetFrameStrata("DIALOG");
        Mixin(f, FlyoutFrameMixin);

        f.buttonPool = CreateFramePool("Button", f, "NarciAmmoFlyoutButtonTemplate");

        f.Background = f:CreateTexture(nil, "BACKGROUND");
        f.Background:SetAllPoints(true);
        f.Background:SetColorTexture(0.1, 0.1, 0.1);
        NarciAPI.NineSliceUtil.SetUpBackdrop(f, "shadowHugeR0", 1);

        f.AlertText = f:CreateFontString(nil, "OVERLAY", "NarciFontNormal10White");
        f.AlertText:SetPoint("CENTER", f, "CENTER", 0, 0);
        f.AlertText:Hide();
        f.AlertText:SetTextColor(0.5, 0.5, 0.5);

        f:SetScript("OnShow", f.OnShow);
        f:SetScript("OnHide", f.OnHide);
        f:SetScript("OnEvent", f.OnEvent);

        SharedBlackScreen:AddOwner(f);
    end
end


local AmmoFlyoutButtonMixin = {};
do
    addon.AmmoFlyoutButtonMixin = AmmoFlyoutButtonMixin;

    function AmmoFlyoutButtonMixin:OnEnter()
        self.Highlight:Show();
        self:OnMouseUp();
    end

    function AmmoFlyoutButtonMixin:OnLeave()
        self.Highlight:Hide();
    end

    function AmmoFlyoutButtonMixin:OnMouseDown()
        self.Highlight:SetColorTexture(0.2, 0.2, 0.2);
    end

    function AmmoFlyoutButtonMixin:OnMouseUp()
        self.Highlight:SetColorTexture(0.25, 0.25, 0.25);
    end

    function AmmoFlyoutButtonMixin:OnClick()
        local itemID = GetInventoryItemID("player", 0);
        if itemID ~= self.itemID then
            AmmoUtil.TryEquipAmmo(self.itemID);
        end
        AmmoUtil.HideFlyout();
    end

    function AmmoFlyoutButtonMixin:SetItemByID(itemID, isEquipped)
        self.itemID = itemID;

        local icon = C_Item.GetItemIconByID(itemID);
        local name = C_Item.GetItemNameByID(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        local count = C_Item.GetItemCount(itemID);
        local dps = AmmoUtil.GetDpsByItemID(itemID);

        if count > 0 then
            count = AmmoUtil.WrapAmmoCountInColor(count);
        else
            count = nil;
        end

        if isEquipped then
            name = "|TInterface\\AddOns\\Narcissus\\Art\\EquipmentOption\\ToggleCheck:24:24|t"..name;
            self.Name:SetPoint("LEFT", self, "LEFT", 21, 0);
        else
            self.Name:SetPoint("LEFT", self, "LEFT", 26, 0);
        end

        self.Icon:SetTexture(icon);
        self.Name:SetText(name);
        local r, g, b = NarciAPI.GetItemQualityColor(quality);
        self.Name:SetTextColor(r, g, b);
        self.ItemCount:SetText(count);
        self.DamageText:SetText(dps);
    end
end
