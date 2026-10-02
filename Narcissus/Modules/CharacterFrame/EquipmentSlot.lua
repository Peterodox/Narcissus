local _, addon = ...
local L = Narci.L;

local NarciAPI = NarciAPI;

local DefaultTooltip = NarciGameTooltip; -- Created in Module\GameTooltip.lua
local ItemTooltip = NarciEquipmentTooltip;
local SharedBlackScreen = addon.SharedBlackScreen;

local AmmoUtil = addon.AmmoUtil; ---@class AmmoUtil
local FadeFrame = NarciFadeUI.Fade;
local GetBorderArtByItemID = NarciAPI.GetBorderArtByItemID;
local GetGemBorderTexture = NarciAPI.GetGemBorderTexture;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;
local GetSlotVisualID = NarciAPI.GetSlotVisualID;
local IsItemSocketable = NarciAPI.IsItemSocketable;
local QueueFrame = NarciAPI.CreateProcessor(nil, 0.5);
local SetBorderTexture = NarciAPI.SetBorderTexture;
local SlotButtonOverlayUtil = addon.SlotButtonOverlayUtil;
local TransmogDataProvider = addon.TransmogDataProvider;
local GetOverrideItemIcon = NarciAPI.GetOverrideItemIcon;


local SLOT_TABLE = {};
Narci.slotTable = SLOT_TABLE;


---@alias WidgetOrientation
---| "left"   on the left side
---| "right"  on the right side


local Def = {
    MOG_MODE = false,
    SHOW_MISSING_ENCHANT_ALERT = false,
};

local function SetEquipmentSlotFlag(flag, value)
    if Def[flag] ~= nil then
        Def[flag] = value;
    end
end
addon.SetEquipmentSlotFlag = SetEquipmentSlotFlag;


local RuneSlotMixin = {};
do  -- An area on the hex border to display enchants
    addon.RuneSlotMixin = RuneSlotMixin;

    ---@param orientation WidgetOrientation
    function RuneSlotMixin:SetOrientation(orientation)
        self.isRight = orientation == "right";
        self.RuneLetter:ClearAllPoints();
        if self.isRight then
            self.RuneLetter:SetPoint("CENTER", self, "CENTER", 0, 0);
        else
            self.RuneLetter:SetPoint("CENTER", self, "CENTER", 3, 0);
        end
    end

    function RuneSlotMixin:OnEnter()
        if (self.isFlyoutButton or not self.spellID) then return; end

        DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
        if self.isRight then
            DefaultTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", 8, 8);
        else
            DefaultTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 8);
        end
        DefaultTooltip:SetSpellByID(self.spellID);
        DefaultTooltip:Show();
        DefaultTooltip:FadeIn();
    end

    function RuneSlotMixin:OnLeave()
        if not self.isFlyoutButton then
            Narci:HideButtonTooltip();
        end
    end

    function RuneSlotMixin:OnLoad()
        self:SetOrientation(self.orientation);
    end

    -- enchantID will be obtained from the itemLink
    function RuneSlotMixin:SetEquipmentItemLink(itemLink)
        local enchantID = itemLink and NarciAPI.GetItemEnchantID(itemLink);
        if enchantID then
            self.spellID = addon.EnchantDataProvider:GetSpellIDByEnchantID(enchantID);
            self.RuneLetter:SetText(NarciAPI.GetVerticalRunicLetters("undefined"));
            self.RuneLetter:Show();
            self:Show();
        else
            self.spellID = nil;
            self.RuneLetter:Hide();
            self:Hide();
        end
    end
end


local ItemButtonSharedMixin = {};
do
    function ItemButtonSharedMixin:RegisterErrorEvent()
        self:RegisterEvent("UI_ERROR_MESSAGE");
    end

    function ItemButtonSharedMixin:UnregisterErrorEvent()
        if self.isListeningErrors then
            self.isListeningErrors = nil;
            self:UnregisterEvent("UI_ERROR_MESSAGE");
        end
    end

    function ItemButtonSharedMixin:OnErrorMessage(...)
        self:UnregisterErrorEvent();
        local _, msg = ...
        Narci_AlertFrame_Autohide:AddMessage(msg, true);
    end

    function ItemButtonSharedMixin:AnchorAlertFrame()
        if not self.isListeningErrors then
            self.isListeningErrors = true;
            self:RegisterErrorEvent();
            Narci_AlertFrame_Autohide:SetAnchor(self, -12, true);
        end
    end

    function ItemButtonSharedMixin:PlayGamePadAnimation()
        if self.hasGamepadAnimation then
            self.Icon.ScaleUp:Play();
            self.IconMask.ScaleUp:Play();
            self.Border.ScaleUp:Play();
            self.Border.BorderMask.ScaleUp:Play();
        end
    end

    function ItemButtonSharedMixin:ResetAnimation()
        if self.hasGamepadAnimation then
            self.Icon.ScaleUp:Stop();
            self.Border.ScaleUp:Stop();
            self.Border.BorderMask.ScaleUp:Stop();
            self.IconMask.ScaleUp:Stop();
            self.Icon:SetScale(1);
            self.Border:SetScale(1);
            self.IconMask:SetScale(1);
            self.Border.BorderMask:SetScale(1);
            if self.gamepadOverlay then
                self.gamepadOverlay:Hide();
                self.gamepadOverlay = nil;
            end
        end
    end

    function ItemButtonSharedMixin:SetBorderTexture(border, texKey)
        SetBorderTexture(border, texKey, 2);
    end

    function ItemButtonSharedMixin:ShowAlphaChannel()
        self.Icon:SetColorTexture(1, 1, 1);
        self.Border:SetColorTexture(1, 1, 1);
        self.Border.textureKey = -1;
    end
end


local function GetRuneForgeLegoIcon(itemLocation)
	local componentInfo = C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo(itemLocation);
	if componentInfo and componentInfo.powerID then
		local powerInfo = C_LegendaryCrafting.GetRuneforgePowerInfo(componentInfo.powerID);
		return powerInfo and powerInfo.iconFileID
	end
end

local function GetAzeriteArmorIcons(itemLocation)
    if not itemLocation then return; end
    local tierInfos = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLocation);
	if not tierInfos then return; end

	local isRightSpec = true;
	local traitIcons = {};
	local specIndex = C_SpecializationInfo.GetSpecialization() or 1;
	local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex) or 0;
	local maxTiers = 5;

    for i = 1, maxTiers do
        if (not tierInfos[i]) or (not tierInfos[i].azeritePowerIDs) then
            return traitIcons;
        end
		local powerIDs = tierInfos[i].azeritePowerIDs;
        for _, powerID in pairs(powerIDs) do
			if C_AzeriteEmpoweredItem.IsPowerSelected(itemLocation, powerID) then
				local powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
				isRightSpec = isRightSpec and C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(powerID, specID);
				local icon;
                if powerInfo and powerInfo.spellID then
                    icon = C_Spell.GetSpellTexture(powerInfo.spellID);
                end
                traitIcons[i] = icon;
                break;
            else
                traitIcons[i] = "";
            end
        end
	end

    return traitIcons, isRightSpec;
end

local function SetItemSocketingFramePosition(self)		--Let ItemSocketingFrame appear on the side of the slot
    local f = ItemSocketingFrame;
	if f then
		if self.GemSlot:IsShown() then
			f:Show()
		else
			f:Hide()
			return;
		end
		f:ClearAllPoints();
		if self.isRight then
			f:SetPoint("TOPRIGHT", self, "TOPLEFT", 4, 0);
		else
			f:SetPoint("TOPLEFT", self, "TOPRIGHT", -4, 0);
		end
		DefaultTooltip:HideTooltip();
	end
end


local EquipmentSlotMixin = CreateFromMixins(ItemButtonSharedMixin);
do
    addon.EquipmentSlotMixin = EquipmentSlotMixin;

    function EquipmentSlotMixin:SetTransmogSourceID(appliedSourceID, secondarySourceID)
        self.sourceID = appliedSourceID;

        if appliedSourceID and appliedSourceID > 0 then
            self.Icon:SetDesaturated(false);
            self.Name:Show();
            self.ItemLevel:Show();
            self.GradientBackground:Show();
        else
            self.Icon:SetDesaturated(true);
            self.Icon:SetTexture(self.emptyTexture);
            self.Name:SetText(nil);
            self.ItemLevel:SetText(nil);
            self.GradientBackground:Hide();	
            self:SetBorderTexture(self.Border, 0);
            if self.slotID == 2 then
                self:DisplayDirectionMark(false);
            end
            return
        end

        local itemName, itemIcon, itemQuality, subText;
        local sourceInfo = C_TransmogCollection.GetSourceInfo(appliedSourceID);
        itemName = sourceInfo and sourceInfo.name;

        if not itemName or itemName == "" then
            QueueFrame:Add(self, self.Refresh);
            return
        end

        self.itemID = sourceInfo.itemID;
        self.itemModID = sourceInfo.itemModID;
        itemQuality = sourceInfo.quality or 1;
        itemIcon = C_TransmogCollection.GetSourceIcon(appliedSourceID);

        subText = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID);

        if subText then
            self.sourcePlainText = NarciAPI.RemoveColorString(subText);
            _, _, self.hyperlink = TransmogDataProvider.GetFormattedSourceText(sourceInfo);
        else
            subText, self.sourcePlainText, self.hyperlink = TransmogDataProvider.GetFormattedSourceText(sourceInfo);
        end

        if not subText then
            subText = " ";
        end

        if self.hyperlink then
            _, self.hyperlink = C_Item.GetItemInfo(self.hyperlink);																		--original hyperlink cannot be printed (workaround)
        end

        local bonusID;
        if itemQuality == 6 then
            if self.slotID == 16 then
                bonusID = (sourceInfo.itemModID or 0);	--Artifact use itemModID "7V0" + modID - 1
            else
                bonusID = 0;
            end
        end

        self.bonusID = bonusID;


        local bR, bG, bB = GetItemQualityColor(itemQuality);
        local borderTexKey = itemQuality;
        self:SetBorderTexture(self.Border, borderTexKey);

        if self:IsVisible() then
            if itemIcon then
                self.IconOverlay:SetTexture(itemIcon);
                self.Icon.anim:Play();
            end
            self.ItemLevel.anim1:SetScript("OnFinished", function(f)
                self.ItemLevel:SetText(subText);
                self.ItemLevel.anim2:Play();
                f:SetScript("OnFinished", nil);
            end)
            self.Name.anim1:SetScript("OnFinished", function(f)
                self.Name:SetText(itemName);
                self.Name:SetTextColor(bR, bG, bB);
                self.Name.anim2:Play();
                f:SetScript("OnFinished", nil);
                C_Timer.After(0, function()
                    self:UpdateGradientSize();
                end)
            end)
            self.ItemLevel.anim1:Play();
            self.Name.anim1:Play();
        else
            self.ItemLevel:SetText(subText);
            self.Name:SetText(itemName);
            self.Name:SetTextColor(bR, bG, bB);
            if itemIcon then
                self.Icon:SetTexture(itemIcon);
            end
            self:UpdateGradientSize();
        end

        if self.slotID == 3 then
            --shoulder
            if secondarySourceID and secondarySourceID > 0 and secondarySourceID ~= appliedSourceID then
                self:DisplayDirectionMark(true, itemQuality);
                SLOT_TABLE[2]:SetTransmogSourceID(secondarySourceID, secondarySourceID);
            else
                self:DisplayDirectionMark(false);
            end
        elseif self.slotID == 2 then
            self:DisplayDirectionMark(appliedSourceID, itemQuality);
        end
    end

    function EquipmentSlotMixin:Refresh(forceRefresh)
        if forceRefresh then
            -- Our update will stop at one point if itemLink is unchanged
            self.itemLink = nil;
        end

        self:RefreshAmmoSlot();

        local _;
        local slotID = self.slotID;
        local itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID);
        --print(slotName..slotID)
        --local texture = CharacterHeadSlot.popoutButton.icon:GetTexture()
        local itemLink;
        local itemIcon, itemName, itemQuality, effectiveLvl, gemName, gemLink, gemID;
        local borderTexKey;
        local isAzeriteEmpoweredItem = false;		--3 Pieces	**likely to be changed in patch 8.2
        local isAzeriteItem = false;				--Heart of Azeroth
        local bR, bG, bB;		--Item Name Color

        if C_Item.DoesItemExist(itemLocation) then
            if Def.MOG_MODE then
                self:UntrackCooldown();
                self:UntrackTempEnchant();
                self:ClearOverlay();
                self:HideVFX();
                self.GemSlot:HideSlot();
                self.itemLink = nil;
                self.isSlotHidden = false;	--Undress an item from player model
                self.RuneSlot:Hide();

                if TransmogDataProvider.RequestUpdateCharacterUI() then
                    return true
                end

                self.GradientBackground:Show();
                local appliedSourceID, appliedVisualID, hasSecondaryAppearance = GetSlotVisualID(slotID);
                self.sourceID = appliedSourceID;

                if appliedVisualID > 0 then
                    local sourceInfo = C_TransmogCollection.GetSourceInfo(appliedSourceID);
                    itemName = sourceInfo and sourceInfo.name;
                    if not itemName or itemName == "" then
                        QueueFrame:Add(self, self.Refresh);
                        return
                    end
                    self.itemID = sourceInfo.itemID;
                    itemQuality = sourceInfo.quality;
                    self.itemModID = sourceInfo.itemModID;
                    itemIcon = C_TransmogCollection.GetSourceIcon(appliedSourceID);

                    effectiveLvl = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID);

                    if effectiveLvl then
                        self.sourcePlainText = NarciAPI.RemoveColorString(effectiveLvl);
                        _, _, self.hyperlink = TransmogDataProvider.GetFormattedSourceText(sourceInfo);
                    else
                        effectiveLvl, self.sourcePlainText, self.hyperlink = TransmogDataProvider.GetFormattedSourceText(sourceInfo);
                    end

                    if self.hyperlink then
                        _, self.hyperlink = C_Item.GetItemInfo(self.hyperlink);																		--original hyperlink cannot be printed (workaround)
                    end

                    local bonusID;
                    if itemQuality == 6 then
                        if slotID == 16 then
                            bonusID = (sourceInfo.itemModID or 0);	--Artifact use itemModID "7V0" + modID - 1
                        else
                            bonusID = 0;
                        end
                    end
                    self.bonusID = bonusID;

                    if effectiveLvl == nil then
                        effectiveLvl = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID) or " ";
                    end

                else	--irrelevant slot
                    itemName = " ";
                    itemQuality = 0;
                    itemIcon = GetInventoryItemTexture("player", slotID);
                    self.Icon:SetDesaturated(true);
                    self.Name:Hide();
                    self.ItemLevel:Hide();
                    self.GradientBackground:Hide();
                    self.bonusID = nil;
                end
                self:DisplayDirectionMark(hasSecondaryAppearance, itemQuality);

            else
                self:TrackCooldown();
                self:DisplayDirectionMark(false);
                self.Icon:SetDesaturated(false)
                self.Name:Show();
                self.ItemLevel:Show();
                self.GradientBackground:Show();
                self.sourceID = nil;
                self.hyperlink = nil;
                self.sourcePlainText = nil;

                itemLink = C_Item.GetItemLink(itemLocation);

                if slotID == 16 or slotID == 17 then -- ValidForTempEnchant
                    local hasTempEnchant = NarciTempEnchantIndicatorController:InitFromSlotButton(self);
                    if hasTempEnchant ~= self.hasTempEnchant then
                        self.hasTempEnchant = hasTempEnchant;
                    else
                        if itemLink == self.itemLink then
                            return
                        end
                    end
                else
                    if itemLink == self.itemLink then
                        return
                    end
                end

                self.itemLink = itemLink;

                local itemVFX, hideItemIcon;
                local itemID = C_Item.GetItemID(itemLocation);
                borderTexKey, itemVFX, bR, bG, bB, hideItemIcon = GetBorderArtByItemID(itemID);

                itemIcon = itemID and GetOverrideItemIcon(itemID);
                if not itemIcon then
                    itemIcon = ((not hideItemIcon) and GetInventoryItemTexture("player", slotID)) or nil;
                end
                itemName = C_Item.GetItemName(itemLocation);
                itemQuality = C_Item.GetItemQuality(itemLocation);
                effectiveLvl = C_Item.GetCurrentItemLevel(itemLocation);
                self.ItemLevelCenter.ItemLevel:SetText(effectiveLvl);

                --Debug
                --if effectiveLvl and effectiveLvl > 1 then
                --	NarciDebug:CalculateAverage(effectiveLvl);
                --end

                if not hideItemIcon then
                    if slotID == 13 or slotID == 14 then
                        if itemID == 167555 then	--Pocket-Sized Computation Device
                            gemName, gemLink = IsItemSocketable(itemLink, 2);
                        else
                            gemName, gemLink = IsItemSocketable(itemLink);
                        end
                    else
                        gemName, gemLink = IsItemSocketable(itemLink);
                    end
                end

                self.GemSlot.ItemLevel = effectiveLvl;
                self.gemLink = gemLink;		--Later used in OnEnter func in NarciSocketing.lua

                if slotID == 2 then
                    isAzeriteItem = C_AzeriteItem.IsAzeriteItem(itemLocation);
                    self.isAzeriteItem = isAzeriteItem;
                    if isAzeriteItem then
                        itemVFX = "Heart";
                    end
                elseif slotID == 1 or slotID == 3 or slotID == 5 then
                    isAzeriteEmpoweredItem = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation);
                end

                if slotID == 15 then
                    --Backslot
                    if itemID == 169223 then 	--Ashjra'kamas, Shroud of Resolve Legendary Cloak
                        local rank, corruptionResistance = NarciAPI.GetItemRankText(itemLink, "ITEM_MOD_CORRUPTION_RESISTANCE");
                        effectiveLvl = effectiveLvl.."  "..rank.."  |cFFFFD100"..corruptionResistance.."|r";
                        borderTexKey = "BlackDragon";
                        itemVFX = "DragonFire";
                    end
                end

                if slotID ~= 13 and slotID ~= 14 then
                    local isRuneforgeLegendary = C_LegendaryCrafting.IsRuneforgeLegendary(itemLocation);
                    if isRuneforgeLegendary then
                        itemVFX = "Runeforge";
                        borderTexKey = "Runeforge";
                        itemIcon = GetRuneForgeLegoIcon(itemLocation) or itemIcon;
                    end
                end

                local enchantText, isEnchanted = NarciAPI.GetEnchantTextByItemLink(itemLink, true, self.isRight);	--enchantText (effect texts) may not be available yet

                if enchantText then
                    if self.isRight then
                        effectiveLvl = enchantText.."  "..effectiveLvl;
                    else
                        effectiveLvl = effectiveLvl.."  "..enchantText;
                    end
                    self:ClearOverlay();
                elseif not isEnchanted then
                    if Def.SHOW_MISSING_ENCHANT_ALERT and SlotButtonOverlayUtil:IsSlotValidForEnchant(slotID, itemID) then
                        SlotButtonOverlayUtil:ShowEnchantAlert(self, slotID, itemID);
                        if self.isRight then
                            effectiveLvl = effectiveLvl .. "  ".. L["Missing Enchant"];
                        else
                            effectiveLvl = L["Missing Enchant"].."  "..effectiveLvl;
                        end
                    end
                end

                --Enchant Frame--
                if itemQuality then	--and not isRuneforgeLegendary
                    self.RuneSlot:SetEquipmentItemLink(itemLink);
                else
                    self.RuneSlot:Hide();
                end

                --Item Visual Effects
                if itemVFX then
                    self:ShowVFX(itemVFX);
                else
                    self:HideVFX();
                end
            end

            if not itemName or itemName == "" then
                QueueFrame:Add(self, self.Refresh);
                return
            end
        else
            self:UntrackCooldown();
            self:UntrackTempEnchant();
            self:ClearOverlay();
            self:HideVFX();
            self:DisplayDirectionMark(false);
            self.GradientBackground:Hide();
            self.Icon:SetDesaturated(false);
            self.ItemLevelCenter.ItemLevel:SetText("");
            self.itemID = nil;
            self.bonusID = nil;
            self.itemLink = nil;
            self.gemLink = nil;
            itemQuality = 0;
            itemIcon = self.emptyTexture;
            itemName = " " ;
            effectiveLvl = "";
            self.RuneSlot:Hide();
        end

        self.itemQuality = itemQuality;

        if itemQuality and not bR then --itemQuality sometimes return nil. This is a temporary solution
            bR, bG, bB = GetItemQualityColor(itemQuality);
            if not borderTexKey then
                borderTexKey = itemQuality;
            end
        end
        bR = bR or 1;
        bG = bG or 1;
        bB = bB or 1;

        if isAzeriteEmpoweredItem then
            borderTexKey = "Azerite";
            if not Def.MOG_MODE then
                local icons, isRightSpec = GetAzeriteArmorIcons(itemLocation);
                for i = 1, #icons do
                    effectiveLvl = effectiveLvl.." |T"..icons[i]..":12:12:0:0:64:64:4:60:4:60|t";
                end
            end
        end

        if isAzeriteItem then
            local heartLevel = C_AzeriteItem.GetPowerLevel(itemLocation);
            local xp_Current, xp_Needed =  C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation);
            local GetEssenceInfo = C_AzeriteEssence.GetEssenceInfo;
            local GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence;
            if not C_AzeriteItem.IsAzeriteItemAtMaxLevel() then
                heartLevel = heartLevel .. "  |CFFf8e694" .. floor((xp_Current/xp_Needed)*100 + 0.5) .. "%";
            end
            effectiveLvl = effectiveLvl.."  |cFFFFD100"..heartLevel;

            local essenceID = GetMilestoneEssence(115);
            if essenceID then
                borderTexKey = "Heart";
                local EssenceInfo = GetEssenceInfo(essenceID);
                bR, bG, bB = GetItemQualityColor(EssenceInfo.rank + 1);
                itemName = EssenceInfo.name;
                itemIcon = EssenceInfo.icon;
            end

            for i = 116, 119 do
                --116, 117, 119  3 minor slots
                if i ~= 118 then
                    essenceID = GetMilestoneEssence(i);
                    if essenceID then
                        local icon = GetEssenceInfo(essenceID).icon;
                        effectiveLvl = effectiveLvl.." |T"..icon..":12:12:0:0:64:64:4:60:4:60|t";
                    end
                end
            end
        end

        --Gem Slot--
        if gemName ~= nil then
            local gemBorder, gemIcon, itemSubClassID;

            --regular gems
            if gemLink then
                gemID, _, _, _, gemIcon, _, itemSubClassID = C_Item.GetItemInfoInstant(gemLink);
                gemBorder = GetGemBorderTexture(itemSubClassID, gemID);
            else
                gemBorder = GetGemBorderTexture(nil);
            end

            self.GemSlot.GemBorder:SetTexture(gemBorder);
            self.GemSlot.GemIcon:SetTexture(gemIcon);
            self.GemSlot.GemIcon:Show();
            self.GemSlot.sockedGemItemID = gemID;
            if self:IsVisible() then
                self.GemSlot:FadeIn();
            else
                self.GemSlot:ShowSlot();
            end
        else
            if self:IsVisible() then
                self.GemSlot:FadeOut();
            else
                self.GemSlot:HideSlot();
            end
            self.GemSlot.sockedGemItemID = nil;
        end

        if self:IsVisible() then
            self:SetBorderTexture(self.Border, borderTexKey);
            if itemIcon then
                self.IconOverlay:SetTexture(itemIcon);
                self.Icon.anim:Play();
            end
            self.ItemLevel.anim1:SetScript("OnFinished", function(f)
                self.ItemLevel:SetText(effectiveLvl);
                self.ItemLevel.anim2:Play();
                f:SetScript("OnFinished", nil);
            end)
            self.Name.anim1:SetScript("OnFinished", function(f)
                self.Name:SetText(itemName);
                self.Name:SetTextColor(bR, bG, bB);
                self.Name.anim2:Play();
                f:SetScript("OnFinished", nil);
                C_Timer.After(0, function()
                    self:UpdateGradientSize();
                end)
            end)
            self.ItemLevel.anim1:Play();
            self.Name.anim1:Play();
        else
            self.ItemLevel:SetText(effectiveLvl);
            self.Name:SetText(itemName);
            self.Name:SetTextColor(bR, bG, bB);
            self:SetBorderTexture(self.Border, borderTexKey);
            if itemIcon then
                self.Icon:SetTexture(itemIcon);
            end
            self:UpdateGradientSize();
        end
        --self.GradientBackground:SetHeight(self.Name:GetHeight() + self.ItemLevel:GetHeight() + 18);
        self.itemNameColor = {bR, bG, bB};

        return true
    end

    function EquipmentSlotMixin:UpdateGradientSize()
        local text2Width = self.ItemLevel:GetWrappedWidth();
        local extraWidth;
        if self.TempEnchantIndicator then
            extraWidth = 48;
            self.TempEnchantIndicator:ClearAllPoints();
            if self.isRight then
                self.TempEnchantIndicator:SetPoint("TOPRIGHT", self.ItemLevel, "TOPRIGHT", -text2Width - 6, 0);
            else
                if self.ItemLevel:IsTruncated() then
                    text2Width = self.ItemLevel:GetWidth();
                end
                self.TempEnchantIndicator:SetPoint("TOPLEFT", self.ItemLevel, "TOPLEFT", text2Width + 6, 0);
            end
        else
            extraWidth = 0;
        end
        self.GradientBackground:SetHeight(self.Name:GetHeight() + self.ItemLevel:GetHeight() + 18);
        self.GradientBackground:SetWidth(math.max(self.Name:GetWrappedWidth(), text2Width + extraWidth, 48) + 48);
    end

    function EquipmentSlotMixin:OnLoad()
        self:RegisterForDrag("LeftButton");

        local level = SharedBlackScreen:GetBaseFrameLevel() - 1;
        self:SetFrameLevel(level);
    end

    function EquipmentSlotMixin:OnEvent(event, ...)
        if event == "MODIFIER_STATE_CHANGED" then
            local key, state = ...
            if ( key == "LALT" and self:IsMouseOver() ) then
                local flyout = Narci_EquipmentFlyoutFrame;
                if state == 1 then
                    if flyout:IsShown() and flyout.slotID == self:GetID() then
                        flyout:Hide();
                    else
                        flyout:SetItemSlot(self, true);
                    end
                else
                    if not Def.MOG_MODE then
                        ItemTooltip:SetFromSlotButton(self, -2, 6);
                    end
                end
            end
        elseif event == "UI_ERROR_MESSAGE" then
            self:OnErrorMessage(...);
        end
    end

    function EquipmentSlotMixin:UntrackCooldown()
        if self.CooldownFrame then
            self.CooldownFrame:Clear();
            self.CooldownFrame = nil;
        end
    end

    function EquipmentSlotMixin:ClearOverlay()
        if Def.SHOW_MISSING_ENCHANT_ALERT and self.slotOverlay then
            SlotButtonOverlayUtil:ClearOverlay(self);
            self.slotOverlay = nil;
        end
    end

    function EquipmentSlotMixin:TrackCooldown()
        local start, duration, enable = GetInventoryItemCooldown("player", self:GetID());
        if enable and enable ~= 0 and start > 0 and duration > 0 then
            if not self.CooldownFrame then
                self.CooldownFrame = NarciItemCooldownUtil.AccquireFrame(self);
            end
            self.CooldownFrame:SetCooldown(start, duration);
            return true
        else
            self:UntrackCooldown();
        end
        return false
    end

    function EquipmentSlotMixin:UntrackTempEnchant()
        if self.TempEnchantIndicator then
            self.TempEnchantIndicator:Hide();
            self.TempEnchantIndicator = nil;
        end
    end

    function EquipmentSlotMixin:OnEnter(motion, isGamepad)
        self:RegisterEvent("MODIFIER_STATE_CHANGED");

        if isGamepad then
            self:PlayGamePadAnimation();
        else
            FadeFrame(self.Highlight, 0.15, 1);
        end

        local flyout = Narci_EquipmentFlyoutFrame;

        if IsAltKeyDown() and not Def.MOG_MODE then
            flyout:SetItemSlot(self, true);
            return
        end

        if flyout:IsShown() then
            Narci_Comparison_SetComparison(flyout.BaseItem, self);
            return;
        end

        if Def.MOG_MODE then
            ItemTooltip:SetTransmogFromSlotButton(self, -2, 6);
        else
            ItemTooltip:SetFromSlotButton(self, -2, 6, isGamepad and 0.4);	--delay 0.4s
        end
    end

    function EquipmentSlotMixin:OnLeave()
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self:UnregisterErrorEvent();
        FadeFrame(self.Highlight, 0.25, 0);
        Narci:HideButtonTooltip();
        self:ResetAnimation();
    end

    function EquipmentSlotMixin:OnHide()
        self.Highlight:Hide();
        self.Highlight:SetAlpha(0);
        self:ResetAnimation();
    end

    function EquipmentSlotMixin:PreClick(button)

    end

    function EquipmentSlotMixin:PostClick(button, down)
        if CursorHasItem() and button == "LeftButton" then
            EquipCursorItem(self:GetID());
            return
        end

        ClearCursor();

        if ( IsModifiedClick() ) then
            if IsAltKeyDown() and button == "LeftButton" then
                local action = EquipmentManager_UnequipItemInSlot(self:GetID())
                if action then
                    EquipmentManager_RunAction(action)
                end
                return;
            elseif IsShiftKeyDown() and button == "LeftButton" then
                if self.hyperlink then
                    if ChatEdit_InsertLink(self.hyperlink) then
                        return
                    elseif SocialPostFrame and Social_IsShown() then
                        Social_InsertLink(self.hyperlink);
                        return
                    end
                end
            else
                PaperDollItemSlotButton_OnModifiedClick(self, button);
                Narci.TakeOutFrames(true);
                SetItemSocketingFramePosition(self);
            end
        else
            if button == "LeftButton" then
                if not Def.MOG_MODE then	--Undress an item from player model while in Xmog Mode
                    --EquipmentFlyoutFrame:SetItemSlot(self);
                    Narci_EquipmentOption:SetFromSlotButton(self, true);
                end
            elseif button == "RightButton" then
                local useKeyDown = C_CVar.GetCVarBool("ActionButtonUseKeyDown");
                if (useKeyDown and down) or (not useKeyDown and not down) then
                    self:AnchorAlertFrame();
                end
            end
        end
    end

    function EquipmentSlotMixin:OnDragStart()
        local itemLocation = ItemLocation:CreateFromEquipmentSlot(self:GetID())
        if C_Item.DoesItemExist(itemLocation) then
            C_Item.UnlockItem(itemLocation);
            PickupInventoryItem(self:GetID());
        end
    end

    function EquipmentSlotMixin:OnReceiveDrag()
        PickupInventoryItem(self:GetID());	--In fact, attemp to equip cursor item
    end

    function EquipmentSlotMixin:DisplayDirectionMark(visible, itemQuality)
        if self.slotID == 2 or self.slotID == 3 then
            if visible then
                if not self.DirectionMark then
                    self.DirectionMark = CreateFrame("Frame", nil, self, "NarciTransmogSlotDirectionMarkTemplate");
                    self.DirectionMark:SetPoint("RIGHT", self, "LEFT", 9, 0);
                    self.DirectionMark:SetDirection(self.slotID - 1);
                end
                FadeFrame(self.DirectionMark, 0.25, 1);
                if itemQuality then
                    self.DirectionMark:SetQualityColor(itemQuality);
                end
            else
                if self.DirectionMark then
                    self.DirectionMark:Hide();
                    self.DirectionMark:SetAlpha(0);
                end
            end
        end
    end

    function EquipmentSlotMixin:ShowVFX(effectName)
        if effectName then
            if self.VFX then
                self.VFX:SetUpByName(effectName);
            else
                self.VFX = NarciItemVFXContainer:AcquireAndSetModelScene(self, effectName);
            end
        else
            self:HideVFX();
        end
    end

    function EquipmentSlotMixin:HideVFX()
        if self.VFX then
            self.VFX:Remove();
        end
    end

    ---@param orientation WidgetOrientation
    function EquipmentSlotMixin:SetOrientation(orientation)
        self.isRight = orientation == "right";
        self.RuneSlot:SetOrientation(orientation);

        -- for Right Slot: rune, gem are shown on the right, item name and level on the left
        local alpha00 = CreateColor(0, 0, 0, 0);
        local alpha80 = CreateColor(0, 0, 0, 0.8);
        self.GradientBackground:ClearAllPoints();
        self.Name:ClearAllPoints();
        self.ItemLevel:ClearAllPoints();
        self.GemSlot:ClearAllPoints();

        if self.isRight then
            self.GradientBackground:SetPoint("RIGHT", self, "LEFT", 32, 0);
            self.GradientBackground:SetGradient("HORIZONTAL", alpha00, alpha80);
            self.Name:SetPoint("TOPRIGHT", self.GradientBackground, "TOPRIGHT", -30, -7);
            self.Name:SetJustifyH("RIGHT");
            self.ItemLevel:SetPoint("BOTTOMRIGHT", self.GradientBackground, "BOTTOMRIGHT", -30, 6);
            self.ItemLevel:SetJustifyH("RIGHT");
            self.GemSlot:SetPoint("LEFT", self, "RIGHT", -11, 0);
            self.GemSlot:SetHitRectInsets(8, 2, 4, 4);
            self.GemSlot.GemBorder:SetTexCoord(1, 0, 0, 1);
            self.GemSlot.GemBorderShadow:SetTexCoord(1, 0, 0, 1);
            self.animOut.Translation1:SetOffset(120, 0);
        else
            self.GradientBackground:SetPoint("LEFT", self, "RIGHT", -32, 0);
            self.GradientBackground:SetGradient("HORIZONTAL", alpha80, alpha00);
            self.Name:SetPoint("TOPLEFT", self.GradientBackground, "TOPLEFT", 30, -7);
            self.Name:SetJustifyH("LEFT");
            self.ItemLevel:SetPoint("BOTTOMLEFT", self.GradientBackground, "BOTTOMLEFT", 30, 6);
            self.ItemLevel:SetJustifyH("LEFT");
            self.GemSlot:SetPoint("RIGHT", self, "LEFT", 11, 0);
            self.GemSlot:SetHitRectInsets(2, 8, 4, 4);
            self.GemSlot.GemBorder:SetTexCoord(0, 1, 0, 1);
            self.GemSlot.GemBorderShadow:SetTexCoord(0, 1, 0, 1);
            self.animOut.Translation1:SetOffset(-120, 0);
        end
    end

    function EquipmentSlotMixin:SetSlotByName(slotName)
        local slotID, texture = GetInventorySlotInfo(slotName);
        self.slotName = slotName;
        self.emptyTexture = texture;
        self:SetID(slotID);
        self.slotID = slotID;

        SLOT_TABLE[slotID] = self;

        if not InCombatLockdown() then
            self:SetAttribute("type2", "item");
            self:SetAttribute("item", slotID);
        end
    end

    function EquipmentSlotMixin:RefreshAmmoSlot()
        local ammoType;

        if self.slotID == 18 then
            local itemID = GetInventoryItemID("player", self.slotID);
            if itemID then
                local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID);
                if subClassID == 2 or subClassID == 18 then
                    ammoType = "arrow";
                elseif subClassID == 3 then
                    ammoType = "bullet";
                end
            end
        end

        if ammoType then
            if not self.AmmoSlot then
                self.AmmoSlot = CreateFrame("Button", nil, self, "NarciAmmoSlotButtonTemplate");
                self.AmmoSlot:SetPoint("CENTER", self, "CENTER", 25, -43);
            end
            self.AmmoSlot:SetAmmoType(ammoType);
            if not self.AmmoSlot:IsShown() then
                self.AmmoSlot.AnimIn:Play();
                self.AmmoSlot:Show();
            end
            self.AmmoSlot:Refresh();
        elseif self.AmmoSlot then
            self.AmmoSlot:Hide();
        end
    end
end


local EquipmentFlyoutButtonMixin = CreateFromMixins(ItemButtonSharedMixin);
do
    addon.EquipmentFlyoutButtonMixin = EquipmentFlyoutButtonMixin;

    function EquipmentFlyoutButtonMixin:OnClick(button, down, isGamepad)
        if button == "LeftButton" then
            local action = EquipmentManager_EquipItemByLocation(self.location, self.slotID)
            if action then
                self:AnchorAlertFrame();
                NarciAPI.ConfirmBinding();
                EquipmentManager_RunAction(action);
            end
            self:Disable();
            if isGamepad then
                EquipmentFlyoutFrame.gamepadButton = self;
            end
        end
    end

    function EquipmentFlyoutButtonMixin:OnLeave()
        FadeFrame(self.Highlight, 0.25, 0);
        Narci:HideButtonTooltip();
        self:ResetAnimation();
    end

    function EquipmentFlyoutButtonMixin:OnEnter(motion, isGamepad)
        Narci_Comparison_SetComparison(self.itemLocation, self);
        if isGamepad then
            self:PlayGamePadAnimation();
        else
            FadeFrame(self.Highlight, 0.15, 1);
        end
    end

    function EquipmentFlyoutButtonMixin:OnEvent(event, ...)
        if event == "UI_ERROR_MESSAGE" then
            self:OnErrorMessage(...);
        end
    end

    function EquipmentFlyoutButtonMixin:SetUp(maxItemLevel)
        self.FlyUp:Stop();
        local itemLocation = self.itemLocation;
        self.hyperlink = C_Item.GetItemLink(itemLocation)
        if ( not itemLocation ) then
            return;
        end

        local itemID = C_Item.GetItemID(itemLocation);
        local itemQuality = C_Item.GetItemQuality(itemLocation);
        local itemLevel = C_Item.GetCurrentItemLevel(itemLocation);
        local itemIcon = GetOverrideItemIcon(itemID);
        if not itemIcon then
            itemIcon = C_Item.GetItemIcon(itemLocation);
        end
        local itemLink = C_Item.GetItemLink(itemLocation)

        if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
            itemQuality = "Azerite";	--AzeriteEmpoweredItem
        elseif C_AzeriteItem.IsAzeriteItem(itemLocation) then
            itemQuality = "Heart";
        elseif C_Item.IsCorruptedItem(itemLink) then
            itemQuality = "NZoth";
        elseif C_LegendaryCrafting.IsRuneforgeLegendary(itemLocation) then
            itemQuality = "Runeforge";
            itemIcon = GetRuneForgeLegoIcon(itemLocation) or itemIcon;
        end

        itemQuality = GetBorderArtByItemID(itemID) or itemQuality;

        if maxItemLevel and itemLevel < maxItemLevel and itemQuality ~= "Runeforge" then
            itemQuality = 0;
            self.Icon:SetDesaturated(true);
        else
            self.Icon:SetDesaturated(false);
        end

        self.Icon:SetTexture(itemIcon)
        --self.Border:SetTexture(BorderTexture[itemQuality])
        self:SetBorderTexture(self.Border, itemQuality);
        self.ItemLevelCenter.ItemLevel:SetText(itemLevel);
        self.ItemLevelCenter:Show();

        self.RuneSlot:SetEquipmentItemLink(itemLink);
    end

    function EquipmentFlyoutButtonMixin:HideButton()
        self:Hide();
        self.location = nil;
        self.hyperlink = nil;
    end
end
