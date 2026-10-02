local _, addon = ...

local NarciAPI = NarciAPI;
local L = Narci.L;
local FadeFrame = NarciFadeUI.Fade;


---@class AmmoUtil
local AmmoUtil = {};
do
    AmmoUtil.dpsCache = {};

    local Ammos = {
        -- Ammo itemID, item level from high to low
        arrow = {274387, 18042, 19316, 11285, 3464, 3030, 2515, 2512},
        bullet = {274388, 15997, 19317, 11630, 10513, 11284, 10512, 3465, 8069, 3033, 8068, 5568, 2519, 8067, 4960, 2516},
    };

    ---@param ammoType "arrow"|"bullet"
    ---@return table? itemIDs
    function AmmoUtil.GetAvailableAmmosByType(ammoType)
        local tbl = {};
        local n = 0;
        local GetItemCount = C_Item.GetItemCount;

        if Ammos[ammoType] then
            for _, itemID in ipairs(Ammos[ammoType]) do
                if GetItemCount(itemID) > 0 then
                    n = n + 1;
                    tbl[n] = itemID;
                end
            end

            if not AmmoUtil.testDone then
                AmmoUtil.testDone = true;

                local lastButton;
                for _, itemID in ipairs(Ammos[ammoType]) do
                    local button = CreateFrame("Button", nil, UIParent, "NarciAmmoFlyoutButtonTemplate");
                    button:SetItemByID(itemID);
                    if lastButton then
                        button:SetPoint("TOP", lastButton, "BOTTOM", 0, -4);
                    else
                        button:SetPoint("TOP", UIParent, "CENTER", 0, 96);
                    end
                    lastButton = button;
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

    function AmmoSlotMixin:SetAmmoType(ammoType)
        self.ammoType = ammoType;
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

        if currentAmmoType ~= self.ammoType or true then
            -- Auto-swap ammo if not match
            local ammos = AmmoUtil.GetAvailableAmmosByType(self.ammoType);
            if ammos then
                local bestAmmoItemID = ammos[1];
                if bestAmmoItemID ~= itemID then
                    itemName = L["Item Switching In Progress"];
                    r, g, b = 0.5, 0.5, 0.5;
                    count = "";
                    C_Timer.After(0.1, function()
                        if not InCombatLockdown() then
                           NarciAPI.PickupContainerItemByItemID(bestAmmoItemID);
                            if CursorHasItem() then
                                PickupInventoryItem(18);
                            end
                            ClearCursor();
                        end
                    end);
                end
            end
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
    end

    function AmmoSlotMixin:OnClick()

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


local AmmoFlyoutButtonMixin = {};
do
    addon.AmmoFlyoutButtonMixin = AmmoFlyoutButtonMixin;

    function AmmoFlyoutButtonMixin:OnEnter()

    end

    function AmmoFlyoutButtonMixin:OnLeave()

    end

    function AmmoFlyoutButtonMixin:OnClick()

    end

    function AmmoFlyoutButtonMixin:OnMouseDown()

    end

    function AmmoFlyoutButtonMixin:OnMouseUp()

    end

    function AmmoFlyoutButtonMixin:SetItemByID(itemID)
        self.itemID = itemID;

        local icon = C_Item.GetItemIconByID(itemID);
        local name = C_Item.GetItemNameByID(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        local count = C_Item.GetItemCount(itemID);
        if count > 0 then
            count = AmmoUtil.WrapAmmoCountInColor(count);
        else
            count = nil;
        end
        local dps = AmmoUtil.GetDpsByItemID(itemID);

        self.Icon:SetTexture(icon);
        self.Name:SetText(name);
        local r, g, b = NarciAPI.GetItemQualityColor(quality);
        self.Name:SetTextColor(r, g, b);
        self.ItemCount:SetText(count);
        self.DamageText:SetText(dps);
    end
end
