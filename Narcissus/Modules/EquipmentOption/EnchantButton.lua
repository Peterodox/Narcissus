local _, addon = ...;
local GemDataProvider = addon.GemDataProvider;

local MainFrame, ScrollFrame, Tooltip, ButtonHighlight, GemActionButton;

local FadeFrame = NarciFadeUI.Fade;
local NarciAPI = NarciAPI;
local GetEnchantText = NarciAPI.GetEnchantTextByEnchantID;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;
local GetGemBonus = NarciAPI.GetGemBonus;
local GetShardBonus = NarciAPI.GetDominationShardBonus;
local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local GetItemTempEnchantType = NarciAPI.GetItemTempEnchantType;
local IsWeaponValidForEnchant = NarciAPI.IsWeaponValidForEnchant;

local C_Item = C_Item;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local GetSpellDescription = GetSpellDescription;
local GetItemCount = C_Item.GetItemCount;
local GetItemIcon = C_Item.GetItemIconByID;
local GetItemInfo = C_Item.GetItemInfo;
local IsMouseButtonDown = IsMouseButtonDown;

local PickupContainerItem = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem;
local GetContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink;
local GetInventoryItemLink = GetInventoryItemLink;

local InUseIDs = {
    gemID = nil,
    enchantID = nil,
    tempEnchantID = nil,
    requirementID = nil,
    newGemID = nil;
};

--[[
Button Info Types:
    1. Enchant Permanent
    2. Enchant Temporary
    3. Generic Gem (+100 Stat)
    4. Shard of Domination
    5. Crystallic Cypher
    6. Primordial Stone
--]]

local function GetAppliedEnhancement(id1, id2)
    --GetContainerItemLink
    local itemLink, slotID;
    if type(id1) == "string" then
        itemLink = id1;
    else
        if id2 then
            itemLink = GetContainerItemLink(id1, id2);
        else
            itemLink = GetInventoryItemLink("player", id1);
            slotID = id1;
        end
    end

    --local _, _, _, linkType, id, enchantID, gemID;

    local enchantID, gemID1, gemID2, gemID3
    if itemLink then
        --_, _, _, linkType, id, enchantID, gemID = strsplit(":|H", itemLink);
        enchantID, gemID1, gemID2, gemID3 = string.match(itemLink, "item:%d+:(%d*):(%d*):(%d*):(%d*)");
    end
    
    enchantID = (enchantID and tonumber(enchantID)) or nil;
    gemID1 = (gemID1 and tonumber(gemID1)) or nil;
    gemID2 = (gemID2 and tonumber(gemID2)) or nil;
    gemID3 = (gemID3 and tonumber(gemID3)) or nil;

    InUseIDs.gemIDs = {gemID1, gemID2, gemID3};
    InUseIDs.enchantID = enchantID;
    InUseIDs.requirementID = GetItemTempEnchantType(itemLink);

    local validForEnchant;
    if slotID and slotID == 17 then
        validForEnchant = IsWeaponValidForEnchant(itemLink);
    else
        validForEnchant = true;
    end

    local socketID = MainFrame:GetSocketOrderID();
    local gemID = InUseIDs.gemIDs[socketID];
    InUseIDs.gemID = gemID;

    return gemID, enchantID, validForEnchant
end

local function GetNewGemID(state)
    if state then
        local socketID = MainFrame:GetSocketOrderID();
        local gemLink = GetNewSocketLink(socketID);
        if gemLink then
            local gemID = C_Item.GetItemInfoInstant(gemLink);
            if gemID == 0 then
                gemID = nil;
            end
            InUseIDs.newGemID = gemID;
            return gemID
        else
            InUseIDs.newGemID = nil;
        end
    else
        InUseIDs.newGemID = nil;
    end
end

local function PlaceGem(gemID, socketOrderID)
    ClearCursor();
    local findHighestItemLevel = true;
    local bagID, slotIndex = GetItemBagPosition(gemID, findHighestItemLevel);
    if not(bagID and slotIndex) then return; end
    PickupContainerItem(bagID, slotIndex);
    ClickSocketButton(socketOrderID);
    ClearCursor();
end

addon.GetAppliedEnhancement = GetAppliedEnhancement;
addon.GetNewGemID = GetNewGemID;

local function GetGemEffect(itemID, callback)
    local effect = GemDataProvider:GetGemEffect(itemID);
    if effect then
        return effect
    end
    return GetGemBonus(itemID, callback)
end


local function RightClickToReturnHome(f, mouseButton)
    if mouseButton == "RightButton" then
        if MainFrame.isNarcissusUI then
            MainFrame:ShowMenu();
        end
    end
end

addon.RightClickToReturnHome = RightClickToReturnHome;


local EventListener = CreateFrame("Frame");
EventListener.t = 0;
EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELL_DATA_LOAD_RESULT" then
        local spellID, success = ...
        if self.spellQueue[spellID] then
            for _, button in pairs(self.spellQueue[spellID]) do
                if button.spellID == spellID then
                    self.spellQueue[spellID] = nil;

                    if button.infoType == 5 then
                        button:SetCrystallicData(button.itemID, true);
                    else
                        local name = GetSpellInfo(spellID);
                        button.Text1:SetText(name);
                        button:ShowLoadingIcon(false);
                        button.itemName = name;
                    end

                    break
                end
            end
        end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if self.itemQueue[itemID] then
            for _, button in pairs(self.itemQueue[itemID]) do
                if button.itemID == itemID then
                    self.itemQueue[itemID] = nil;

                    local quality = C_Item.GetItemQualityByID(itemID);
                    local r, g, b = GetItemQualityColor(quality);

                    if button:IsEnabled() then
                        button.Text2:SetTextColor(r, g, b, 1);
                    else
                        button.Text2:SetTextColor(r, g, b, 0.6);
                    end

                    local infoType = button.infoType;
                    local name = GetItemInfo(itemID);

                    if infoType == 1 or infoType == 2 then
                        button:SetEnchantText(button.enchantID);
                    elseif infoType == 3 then
                        button:SetButtonText(GetGemEffect(itemID), name);
                    elseif infoType == 6 then
                        button:SetButtonText(NarciAPI.GetColorizedPrimordialStoneName(itemID));
                    elseif infoType == 4 then
                        button:SetButtonText(GetShardBonus(itemID), name);
                    end

                    button:ShowLoadingIcon(false);
                    button.itemName = name;

                    break
                end
            end
        end
    end

    local loadingComplete = true;

    if self.itemQueue then
        for k, v in pairs(self.itemQueue) do
            if k and v then
                loadingComplete = false;
                break
            end
        end
    end

    if loadingComplete and self.spellQueue then
        for k, v in pairs(self.spellQueue) do
            if k and v then
                loadingComplete = false;
                break
            end
        end
    end

    if loadingComplete then
        self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    end
end);

local function EventListener_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.5 then
        local numEnchants = 0;
        for enchantID, object in pairs(self.enchantQueue) do
            numEnchants = numEnchants + 1;
            object[2] = object[2] + 0.5;
            if object[2] >= 0.5 then
                object[2] = 0;
                if object[1]:SetEnchantText(enchantID) or object[3] > 3 then
                    numEnchants = numEnchants - 1;
                    self.enchantQueue[enchantID] = nil;
                else
                    object[3] = object[3] + 1;
                end
            end
        end
        if numEnchants <= 0 then
            self:SetScript("OnUpdate", nil);
            self.t = 0;
        end
    end
end

function EventListener:AddEnchant(enchantID, button)
    if not self.enchantQueue then
        self.enchantQueue = {};
    end
    self.enchantQueue[enchantID] = {button, 0, 0};  --{button, duration, repeat}
    self:SetScript("OnUpdate", EventListener_OnUpdate);
end

function EventListener:AddSpell(spellID, button)
    if not self.spellQueue then
        self.spellQueue = {};
    end
    if not self.spellQueue[spellID] then
        self.spellQueue[spellID] = {};
    end
    table.insert(self.spellQueue[spellID], button);
    C_Spell.RequestLoadSpellData(spellID);
    self:RegisterEvent("SPELL_DATA_LOAD_RESULT");
end

function EventListener:AddItem(itemID, button)
    if not self.itemQueue then
        self.itemQueue = {};
    end
    if not self.itemQueue[itemID] then
        self.itemQueue[itemID] = {};
    end
    table.insert(self.itemQueue[itemID], button);
    C_Item.RequestLoadItemDataByID(itemID);
    self:RegisterEvent("ITEM_DATA_LOAD_RESULT");
end

function EventListener:Wipe()
    if self.itemQueue then
        self.itemQueue = nil;
    end
    if self.enchantQueue then
        self.enchantQueue = nil;
    end
    if self.spellQueue then
        self.spellQueue = nil;
    end
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
    self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    self:SetScript("OnUpdate", nil);
end


local function AssignWidgets()
    MainFrame = Narci_EquipmentOption;
    ScrollFrame = MainFrame.ItemList;
    Tooltip = ScrollFrame.Tooltip;
    GemActionButton = ScrollFrame.GemActionButton;
end

addon.AssignEnchantButtonWidgets = AssignWidgets;


NarciEquipmentEnchantButtonMixin = {};

function NarciEquipmentEnchantButtonMixin:OnLoad()
    self:SetEnabledVisual();
end

function NarciEquipmentEnchantButtonMixin:OnEnter(button, motion, isGamepad)
    if not self:IsVisible() then
        return false;
    end
    ButtonHighlight:SetParentButton(self);
    if self:IsEnabled() then
        self.Icon:SetVertexColor(1, 1, 1);
    else
        self.Icon:SetVertexColor(0.72, 0.72, 0.72);
    end
    if not ScrollFrame:IsScrolling() and not isGamepad then
        if not IsMouseButtonDown() then
            if not ScrollFrame:ScrollToWidget(self) then
                Tooltip:ShowButtonTooltip(self);
            end
        end
    end
    return true
end

function NarciEquipmentEnchantButtonMixin:OnLeave()
    --FadeFrame(self.BorderLeft, 0.5, 0.25);
    --FadeFrame(self.BorderRight, 0.5, 0.25);
    ButtonHighlight:Hide();
    --self.Highlight.Anim:Stop();
    if self:IsEnabled() then
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
        --self:SetAlpha(0.8);
    else
        self.Icon:SetVertexColor(0.5, 0.5, 0.5);
        --self:SetAlpha(0.8);
    end
    Tooltip:FadeOut();
end

function NarciEquipmentEnchantButtonMixin:SetEnabledVisual()
    self.Icon:SetDesaturation(0);
    self.Text1:SetTextColor(0.920, 0.920, 0.920);
    self.ItemCount:SetTextColor(0.920, 0.920, 0.920);
    self.IconBorder:SetVertexColor(1, 1, 1);
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    self.Text2:SetAlpha(1);
end

function NarciEquipmentEnchantButtonMixin:SetDisabledVisual(redNumber)
    self.Icon:SetDesaturation(0.5);
    self.Text1:SetTextColor(0.6, 0.6, 0.6);
    if redNumber ~= nil then
        if redNumber then
            self.ItemCount:SetTextColor(1, 0.3137, 0.3137);
        else
            self.ItemCount:SetTextColor(0.920, 0.920, 0.920);
        end
    end
    self.IconBorder:SetVertexColor(0.5, 0.5, 0.5);
    self.Icon:SetVertexColor(0.5, 0.5, 0.5);
    self.Text2:SetAlpha(0.6);
end

function NarciEquipmentEnchantButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self.AnimPushed:Stop();
        self.AnimPushed.Hold:SetDuration(20);
        self.AnimPushed:Play();
    end
end

function NarciEquipmentEnchantButtonMixin:OnMouseUp(button)
    self.AnimPushed.Hold:SetDuration(0);
    RightClickToReturnHome(self, button);
end

function NarciEquipmentEnchantButtonMixin:OnClick()
    local actionButton = NarciEquipmentEnchantActionButton;

    if self.infoType == 1 then  --Perma Enchant
        actionButton:InitFromButton(self, MainFrame.slotID, InUseIDs.enchantID);
    elseif self.infoType == 2 then  --Temp Enchant
        actionButton:InitFromButton(self, MainFrame.slotID);
    else
        --Gem/Shard
        if MainFrame.isNarcissusUI then
            GemActionButton:InitFromButton(self, MainFrame.slotID, InUseIDs.gemID, MainFrame:GetSocketOrderID());
        else
            PlaceGem(self.itemID, MainFrame:GetSocketOrderID());
        end
    end
end

function NarciEquipmentEnchantButtonMixin:ShowLoadingIcon(state)
    if state then
        self.LoadingIndicator:Show();
        self.LoadingIndicator.Rotate:Play();
    else
        self.LoadingIndicator:Hide();
        self.LoadingIndicator.Rotate:Stop();
    end
end

function NarciEquipmentEnchantButtonMixin:SetButtonText(text1, text2)
    self.Text1:SetText(text1);
    self.Text2:SetText(text2);

    if text2 then
        self.Text1:ClearAllPoints();
        self.Text1:SetPoint("BOTTOMLEFT", self.Icon, "RIGHT", 7, 1);
        self.Text1:SetJustifyV("BOTTOM");
        self.Text1:SetMaxLines(1);
        if text1 then
            self.Text2:Show();
        end
    else
        self.Text2:Hide();
        if text1 then
            self.Text1:ClearAllPoints();
            self.Text1:SetPoint("LEFT", self.Icon, "RIGHT", 7, 0);
            self.Text1:SetJustifyV("MIDDLE");
            self.Text1:SetMaxLines(2);
        end
    end
end

function NarciEquipmentEnchantButtonMixin:SetUsed(state, pending)
    self.InUseMark:SetShown(state);
    self.isUsed = state;
    if state then
        self.InUseMark:SetColorTexture(0.3725, 0.7412, 0.4196);
    else
        if pending then
            self.InUseMark:Show();
            self.InUseMark:SetColorTexture(0.9686, 0.8941, 0);
        end
    end
end

function NarciEquipmentEnchantButtonMixin:SetItemCount(itemID)
    if itemID then
        local count = GetItemCount(itemID);
        if count <= 0 or self.isUsed then
            self:Disable();
            self:SetDisabledVisual(count <= 0);
        else
            self:Enable();
            self:SetEnabledVisual();
        end
        self.ItemCount:SetText(count);
        self.ItemCount:Show();
        self.ItemCountBackdrop:Show();
    else
        self.ItemCount:Hide();
        self.ItemCountBackdrop:Hide();
    end
end

function NarciEquipmentEnchantButtonMixin:SetEnchantData(spellID, itemID, enchantID, iconFileID)
    if spellID ~= self.spellID then
        self.spellID = spellID;
    else
        if not spellID then
            self:Hide();
        end
        self:SetItemCount(itemID);
        return
    end

    self.infoType = 1;
    self.enchantID = enchantID;
    self.itemID = itemID;

    if spellID then
        self:SetUsed(enchantID == InUseIDs.enchantID);
        self:SetItemCount(itemID);
        self.Icon:SetTexture(iconFileID or 463531);
        self.Text2:SetTextColor(0.5, 0.5, 0.5);
        local name = GetSpellInfo(spellID);
        local enchantText = GetEnchantText(enchantID);
        local notLoaded;
        if not enchantText then
            EventListener:AddEnchant(enchantID, self);
            notLoaded = true;
        end
        if name and name ~= "" then
            notLoaded = notLoaded or false
            if name == enchantText then
                name = nil;
            end
            self.itemName = name;
            self:SetButtonText(enchantText, name);
            self:ShowLoadingIcon(false);
        else
            notLoaded = true;
            EventListener:AddSpell(spellID, self);
        end
        C_Item.GetItemQualityByID(itemID);  --cache
        self:ShowLoadingIcon(notLoaded);
        self:Show();
    else
        self:Hide();
    end
    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentEnchantButtonMixin:SetTempEnchantData(spellID, itemID, enchantID, requirementID)
    if spellID ~= self.spellID then
        self.spellID = spellID;
    else
        if not spellID then
            self:Hide();
        end
        self:SetItemCount(itemID);
        return
    end

    self.infoType = 2;
    self.enchantID = enchantID;
    self.itemID = itemID;
    self.requirementID = requirementID;

    if spellID then
        self:SetUsed(false);
        self.Icon:SetTexture( GetItemIcon(itemID) );
        
        local enchantText = GetEnchantText(enchantID);
        local notLoaded;
        if not enchantText then
            EventListener:AddEnchant(enchantID, self);
            notLoaded = true;
        end

        local name = GetItemInfo(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        if name and name ~= "" and quality and enchantText then
            local r, g, b;
            if quality == 1 then
                r, g, b = 0.92, 0.92, 0.92;
            else
                r, g, b = GetItemQualityColor(quality);
            end
            self.Text2:SetTextColor(r, g, b, 1);
            if name == enchantText then
                name = nil;
            end
            self:SetButtonText(enchantText, name);
            self:ShowLoadingIcon(false);
            self.itemName = name;
        else
            EventListener:AddItem(itemID, self);
            notLoaded = true;
        end

        self:SetItemCount(itemID);
        self:ShowLoadingIcon(notLoaded);
        self:Show();

        if requirementID and requirementID ~= InUseIDs.requirementID then
            self.showFailureReason = true;
            self:Disable();
            self:SetDisabledVisual();
        else
            self.showFailureReason = nil;
        end
    else
        self:Hide();
    end
    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentEnchantButtonMixin:SetEnchantText(enchantID)
    if not self.spellID then
        return
    end

    local name;
    if self.useActionButton == 2 then
        name = GetItemInfo(self.itemID);
    else
        name = GetSpellInfo(self.spellID);
    end

    local enchantText = GetEnchantText(enchantID);
    if name and name ~= "" and enchantText then
        if name == enchantText then
            name = nil;
        end
        self:SetButtonText(enchantText, name);
        self:ShowLoadingIcon(false);
        return true
    else
        EventListener:AddEnchant(enchantID, self);
        self:ShowLoadingIcon(true);
    end

    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentEnchantButtonMixin:SetGemData(itemID)
    if itemID ~= self.itemID then
        self.itemID = itemID;
    else
        if not itemID then
            self:Hide();
        end
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        self:SetItemCount(itemID);
        return
    end

    self.infoType = 3;
    self.spellID = nil;
    self.enchantID = nil;

    if itemID then
        local icon = GetItemIcon(itemID);
        self.Icon:SetTexture(icon);
        local name = GetItemInfo(itemID);

        local function TooltipUpdateCallback()
            if itemID == self.itemID then
                self:SetButtonText(GetGemEffect(itemID, TooltipUpdateCallback), self.itemName);
                self:ShowLoadingIcon(false)
            end
        end

        local gemBonus = GetGemEffect(itemID, TooltipUpdateCallback);
        local quality = C_Item.GetItemQualityByID(itemID);
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        if name and name ~= "" and gemBonus and gemBonus ~= "" and quality then
            local r, g, b = GetItemQualityColor(quality);
            self.Text2:SetTextColor(r, g, b, 1);
            self:SetButtonText(gemBonus, name);
            self:ShowLoadingIcon(false);
            self.itemName = name;
        else
            self:ShowLoadingIcon(true);
            EventListener:AddItem(itemID, self);
        end
        self:SetItemCount(itemID);
        self:Show();
    else
        self:Hide();
    end
    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentEnchantButtonMixin:SetDominationShardData(itemID)
    if itemID ~= self.itemID then
        self.itemID = itemID;
    else
        if not itemID then
            self:Hide();
        end
        return
    end

    self.infoType = 4;
    self.spellID = nil;
    self.enchantID = nil;

    if itemID then
        local icon = GetItemIcon(itemID);
        self.Icon:SetTexture(icon);
        local name = GetItemInfo(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        if name and name ~= "" and quality then
            local r, g, b = GetItemQualityColor(quality);
            self.Text2:SetTextColor(r, g, b, 1);
            self:SetButtonText(GetShardBonus(itemID), name);
            self:ShowLoadingIcon(false);
            self.itemName = name;
        else
            EventListener:AddItem(itemID, self);
            self:ShowLoadingIcon(true);
        end
        self:SetItemCount(itemID);
        self:Show();
    else
        self:Hide();
    end
    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentEnchantButtonMixin:SetCrystallicData(itemID, forceUpdate)
    if itemID ~= self.itemID then
        self.itemID = itemID;
    elseif not forceUpdate then
        if not itemID then
            self:Hide();
        end
        return
    end

    self.infoType = 5;
    self.spellID = nil;
    self.enchantID = nil;

    if itemID then
        local spellID = NarciAPI.GetCrystallicSpell(itemID);
        self.spellID = spellID;
        local name, _, icon = GetSpellInfo(spellID);
        local gemBonus = GetSpellDescription(spellID);
        self.Icon:SetTexture(icon);
        local quality = 2;
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        local r, g, b = GetItemQualityColor(quality);
        self.Text2:SetTextColor(r, g, b, 1);
        if name and name ~= "" and gemBonus and gemBonus ~= "" then
            self:SetButtonText(gemBonus, name);
            self:ShowLoadingIcon(false);
            self.itemName = name;
        else
            EventListener:AddSpell(spellID, self);
            self:ShowLoadingIcon(true);
        end
        self:SetItemCount(itemID);
        self:Show();
    else
        self:Hide();
    end
    self:SetScript("OnUpdate", nil);
end

local function LoadingPrimodrialStone_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.25 then
        local itemID = self.itemID;
        if C_Item.DoesItemExistByID(itemID) then
            self.itemID = nil;
            self:SetPrimordialStone(itemID);
        else
            self:SetScript("OnUpdate", nil);
        end
    end
end

function NarciEquipmentEnchantButtonMixin:SetPrimordialStone(itemID)
    if itemID ~= self.itemID then
        self.itemID = itemID;
    else
        if not itemID then
            self:Hide();
        end
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        self:SetItemCount(itemID);
        return
    end

    self.infoType = 6;
    self.spellID = nil;
    self.enchantID = nil;

    self:SetScript("OnUpdate", nil);

    if itemID then
        local icon = GetItemIcon(itemID);
        self.Icon:SetTexture(icon);
        local name = NarciAPI.GetColorizedPrimordialStoneName(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        self:SetUsed(itemID == InUseIDs.gemID, itemID == InUseIDs.newGemID);
        if name and name ~= "" and quality then
            local r, g, b = GetItemQualityColor(quality);
            self.Text2:SetTextColor(r, g, b, 1);
            self:SetButtonText(name);   --Button is too short to display bonus
            self:ShowLoadingIcon(false);
            self.itemName = name;
        else
            self:ShowLoadingIcon(true);
            --EventListener:AddItem(itemID, self);
            self.t = 0;
            self:SetScript("OnUpdate", LoadingPrimodrialStone_OnUpdate);
        end
        self:SetItemCount(itemID);
        self:Show();
    else
        self:Hide();
    end
end

function NarciEquipmentEnchantButtonMixin:WipeData()
    self.itemID = nil;
    self.spellID = nil;
    self.enchantID = nil;
    self.requirementID = nil;
    self.isUsed = nil;
    self.showFailureReason = nil;
end


NarciItemListButtonHighlightMixin = {};

function NarciItemListButtonHighlightMixin:OnLoad()
    ButtonHighlight = self;
end

function NarciItemListButtonHighlightMixin:SetParentButton(button)
    self:ClearAllPoints();
    --self:SetParent(button);
    --self:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 0);
    --self:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, 0);
    self:SetPoint("CENTER", button, "CENTER", 0, 0);
    self:Show();
    if button:IsEnabled() then
        self.Highlight:SetColorTexture(0.2, 0.2, 0.2);
    else
        self.Highlight:SetColorTexture(0.25, 0, 0);
    end
    self.IconRight:SetTexture(button.Icon:GetTexture());
    self.IconRight.FlyIn:Stop();
    self.IconRight.FlyIn:Play();
end