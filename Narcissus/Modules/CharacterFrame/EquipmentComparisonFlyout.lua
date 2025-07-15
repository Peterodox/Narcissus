--Parent: Narci_EquipmentFlyoutFrame (Narcissus.xml)
local _, addon = ...
local L = Narci.L;

local EquipmentFlyoutFrame;
local hasGapAdjusted = false;
local STAMINA_STRING = SPELL_STAT3_NAME;
local COMPARISON_HEIGHT = 160;
local FORMAT_DIGIT = "%.2f";
local floor = math.floor;

local ItemCacheUtil = addon.ItemCacheUtil;

local FormatLargeNumbers = NarciAPI.FormatLargeNumbers --BreakUpLargeNumbers;
local GetItemExtraEffect = NarciAPI.GetItemExtraEffect;
local IsItemSocketable = NarciAPI.IsItemSocketable;

local DoesItemExist = C_Item.DoesItemExist;
local GetItemLink = C_Item.GetItemLink;
local GetItemID = C_Item.GetItemID;
local GetItemIcon = C_Item.GetItemIcon;
local GetItemName = C_Item.GetItemName;
local GetItemQuality = C_Item.GetItemQuality;
local RequestLoadItemData = C_Item.RequestLoadItemData;
local GetCombatRating = GetCombatRating;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local IsAzeriteItemLocationBankBag = AzeriteUtil.IsAzeriteItemLocationBankBag or AzeriteUtil.IsAzeriteItemLocationBankTab;

local GetGemBorderTexture = NarciAPI.GetGemBorderTexture;
--local DoesItemHaveDomationSocket = NarciAPI.DoesItemHaveDomationSocket;
local GetDominationBorderTexture = NarciAPI.GetDominationBorderTexture;
local GetItemDominationGem = NarciAPI.GetItemDominationGem;
local GetSlotNameAndTexture = NarciAPI.GetSlotNameAndTexture;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local AbbreviateNumbers = AbbreviateNumbers;

local CR_ConvertRatio = {      --Combat Rating number/percent
    ["stamina"] = 20,              -- 1 stamina = 20 HP
};

Narci.ConvertRatio = CR_ConvertRatio;


local function SetCombatRatingRatio()
    local _;
	local mastery, bonusCoeff = GetMasteryEffect();
	local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;
	local masteryBase;
	if (masteryBonus > 0) then
        masteryBase = mastery - masteryBonus;
    else
        masteryBase = 0;
    end
    local critChance, critRating = Narci.GetEffectiveCrit();
	local extraCritChance = GetCombatRatingBonus(critRating);
	local critBase = critChance - extraCritChance;
	local versatilityBase = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
    local hasteBase = GetHaste() - GetCombatRatingBonus(CR_HASTE_MELEE);
    CR_ConvertRatio.critBase = critBase;
    CR_ConvertRatio.hasteBase = hasteBase;
    CR_ConvertRatio.masteryBase = masteryBase;
    CR_ConvertRatio.versatilityBase = versatilityBase;

    local crit = math.max(GetCombatRating(CR_CRIT_MELEE), GetCombatRating(CR_CRIT_RANGED), GetCombatRating(CR_CRIT_SPELL));
    local critBonus = math.max(GetCombatRatingBonus(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_SPELL));
    local haste = GetCombatRating(CR_HASTE_MELEE);
    mastery = GetCombatRating(CR_MASTERY);
    local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
    local stamina = UnitStat("player", LE_UNIT_STAT_STAMINA);
    local Health = UnitHealth("player");

    _, bonusCoeff = GetMasteryEffect();
    masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;

    if crit == 0 then
        CR_ConvertRatio.crit = 0;
    else
        CR_ConvertRatio.crit = critBonus / crit;
    end
    if haste == 0 then
        CR_ConvertRatio.haste = 0;
    else
        CR_ConvertRatio.haste = GetCombatRatingBonus(CR_HASTE_MELEE) / haste;
    end
    if mastery == 0 then
        CR_ConvertRatio.mastery = 0;
    else
        CR_ConvertRatio.mastery = masteryBonus / mastery;
    end
    if versatility == 0 then
        CR_ConvertRatio.versatility = 0;
    else
        CR_ConvertRatio.versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) / versatility;
    end

    --CR_ConvertRatio.stamina = Health / stamina;
    --[[
    print(STAT_CRITICAL_STRIKE.." "..floor(1/CR_ConvertRatio.crit + 0.5))
    print(STAT_HASTE.." "..floor(1/CR_ConvertRatio.haste + 0.5))
    print(STAT_MASTERY.." "..floor(1/CR_ConvertRatio.mastery + 0.5))
    print(STAT_VERSATILITY.." "..floor(1/CR_ConvertRatio.versatility + 0.5))
    --]]

    -----------------------
    --print("Combat Rating Ratio Refreshed")
end

local ColorTable = {
    Green = {r = 124, g = 197, b = 118},    --7cc576
    Red = {r = 255, g = 80, b = 80},        --ff5050 (1, 0.3137, 0.3137)
    Positive = {r = 98, g = 239, b = 165},
    Positive2 = {r = 135, g = 220, b = 153},
    Corrupt = {r = 148, g = 109, b = 209},  --946dd1
}

local function TextColor(Fontstring, color)
    local r, g, b = color.r/255, color.g/255, color.b/255
    Fontstring:SetTextColor(r, g, b);
end


local function Narci_Comparison_AdjustGap()
    local frame = Narci_Comparison;
    local defaultV1 = 60;
    local defaultV2 = 110;  --116
    local maxStringWidth = 60; --Default Gap is 80 = 60 + 20
    
    local statString = frame.StatsList;
    for i=1, #statString do
        local tempWidth = statString[i].Label:GetWidth();
        if maxStringWidth < tempWidth then
            maxStringWidth = tempWidth;
        end
    end
    
    local ajustedV1 = maxStringWidth + 30;
    local ajustedV2 = floor(defaultV2 -(ajustedV1 - defaultV1));
    local extraWidth = 0;
    local minimumGap = 60;

    if ajustedV2 < minimumGap then
        extraWidth = floor(minimumGap - ajustedV2);
        ajustedV2 = minimumGap;
        frame:SetWidth(frame:GetWidth() + extraWidth)
    end
    
    frame.GuideLineV1:SetPoint("LEFT", ajustedV1, 0)
    frame.GuideLineV2:SetPoint("LEFT", frame.GuideLineV1, ajustedV2, 0)
    hasGapAdjusted = true;
end


--[[
local function GetItemEnchant(itemLink)
    local EnchantID = 0;
    local _, a = string.find(itemLink, ":%d+:.-:")
    local _, b = string.find(itemLink, ":%d+:")

    if (b + 1) < (a -1) then
        EnchantID = string.sub(itemLink, b+1, a-1)
    end

    return tonumber(EnchantID)
end
--]]


local ItemStats = NarciAPI_GetItemStats;

local function DisplayComparison(key, name, number, baseNumber, ratio, CustomColor)
    local Textframe = Narci_Comparison[key];
    if not number then            --Set Number to "-"
        Textframe.Arrow:Hide();
        Textframe.NumDiff:Hide();
        Textframe.PctDiff:Hide();
        Textframe.Num:SetText("-");
        return;
    end

    local differentialNumber = tonumber(number) - tonumber(baseNumber);

    if differentialNumber > 0 then
        Textframe.Arrow:Show()
        Textframe.Arrow:SetTexCoord(0, 0.5, 0, 1)

        Textframe.NumDiff:Show();
        Textframe.PctDiff:Show();
        TextColor(Textframe.NumDiff, ColorTable.Green)
        TextColor(Textframe.PctDiff, ColorTable.Green)
    elseif differentialNumber < 0 then
        Textframe.Arrow:Show()
        Textframe.Arrow:SetTexCoord(0.5, 1, 0, 1)

        Textframe.NumDiff:Show();
        Textframe.PctDiff:Show();
        TextColor(Textframe.NumDiff, ColorTable.Red)
        TextColor(Textframe.PctDiff, ColorTable.Red)
    else
        Textframe.Arrow:Hide()
        Textframe.NumDiff:Hide();
        Textframe.PctDiff:Hide();
    end

    differentialNumber = math.abs(differentialNumber)

    Textframe.Label:SetText(name)
    local labelAlpha = 1;
    if number ~= 0 then
        Textframe.Num:SetText(number);
        Textframe:Show();
    else
        Textframe.Num:SetText("-");
        labelAlpha = 0.6;
    end
    Textframe.NumDiff:SetText(differentialNumber);

    if CustomColor then
        Textframe.Label:SetTextColor(CustomColor[1], CustomColor[2], CustomColor[3], labelAlpha)
    else
        Textframe.Label:SetTextColor(1, 0.96, 0.41, labelAlpha);
    end

    if ratio then
        if name ~= STAMINA_STRING then
            Textframe.PctDiff:SetText(string.format(FORMAT_DIGIT, ratio*differentialNumber).."%");
        else
            Textframe.PctDiff:SetText(AbbreviateNumbers(ratio*differentialNumber));    --FormatLargeNumbers
        end
    else
        Textframe.PctDiff:SetText("");
    end
end

local function EmptyComparison()
    DisplayComparison("ilvl",STAT_AVERAGE_ITEM_LEVEL);
    DisplayComparison("prim", SPEC_FRAME_PRIMARY_STAT);
    DisplayComparison("stamina", STAMINA_STRING);
    DisplayComparison("crit", STAT_CRITICAL_STRIKE);
    DisplayComparison("haste", STAT_HASTE);
    DisplayComparison("mastery", STAT_MASTERY);
    DisplayComparison("versatility", STAT_VERSATILITY);
end

local function UntruncateText(frame, fontstring)
    local n = 1;
    frame:SetWidth(frame.WidthBAK)
    while fontstring:IsTruncated() do
        frame:SetWidth(frame.WidthBAK + 20*n);
        n = n + 1;
    end
end

local HEART_LEVEL = 0;
local CURRENT_SPEC = 1;
local MAX_TIER = 5;
local PRIMARY_STAT_NAME = "Primary";
local GetAllTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo;
local GetPowerInfo = C_AzeriteEmpoweredItem.GetPowerInfo;
local IsPowerSelected = C_AzeriteEmpoweredItem.IsPowerSelected;
local GetPowerText = C_AzeriteEmpoweredItem.GetPowerText;   --azeriteEmpoweredItemLocation, powerID, level
local IsPowerAvailableForSpec = C_AzeriteEmpoweredItem.IsPowerAvailableForSpec;
local TierInfos;

local function GetActiveTraits(itemLocation, itemButton)
    if not itemLocation then return; end
    local shouldCache = false;
    local PowerIDs, azeritePowerName, icon, unlockLevel, azeritePowerDescription;
    local ActiveTraits = {}  --[tier] = {PowerID, icon, name, description, unlockLevel}
    if (not DoesItemExist(itemLocation)) or (not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation)) then return; end
    TierInfos = GetAllTierInfo(itemLocation);
    if not TierInfos then return; end

    for i = 1, MAX_TIER do
        if (not TierInfos[i]) or (not TierInfos[i].azeritePowerIDs) then
            if shouldCache then
                if itemButton then
                    itemButton:Disable();
                    C_Timer.After(0.2, function()
                        itemButton:Enable();
                    end)
                end
            end            
            return ActiveTraits;
        end
        ActiveTraits[i] = {}
        PowerIDs = TierInfos[i].azeritePowerIDs;
        unlockLevel = TierInfos[i].unlockLevel or 0;
        for k, PowerID in pairs(PowerIDs) do
            azeritePowerName, _, icon = GetSpellInfo(GetPowerInfo(PowerID) and GetPowerInfo(PowerID).spellID);
            azeritePowerDescription = GetPowerText(itemLocation, PowerID, 0);
            
            if not azeritePowerDescription.description or azeritePowerDescription.description == "" then
                shouldCache = true;
                --print("shoud cache".." "..azeritePowerName)
            end
            if IsPowerSelected(itemLocation, PowerID) then
                ActiveTraits[i] = {PowerID, icon, azeritePowerName, azeritePowerDescription.description};
                break;
            else
                ActiveTraits[i] = {PowerID, nil, "", ""};
            end
        end
        tinsert(ActiveTraits[i], unlockLevel);
    end
    if shouldCache then
        if itemButton then
            itemButton:Disable();
            C_Timer.After(0.2, function()
                itemButton:Enable();
            end)
        end
    end
    return ActiveTraits;
end

local TraitsCache = {};

local function BuildAzeiteTraitsFrame(TraitsFrame, itemLocation, itemButton)
    TraitsCache = GetActiveTraits(itemLocation, itemButton);
    if not TraitsCache then return; end

    local rightSpec = false;
    for i = 1, MAX_TIER do
        local button = TraitsFrame.Traits[i];
        button.Icon:Hide();
        if (TraitsCache[i]) and (TraitsCache[i][5]) then
            if TraitsCache[i][5] > HEART_LEVEL then
                button.Level:SetText(TraitsCache[i][5]);
                button.Level:Show();
                button.Border0:SetTexCoord(0.5, 0.75, 0, 1);            --Desaturated
                button.Border1:SetDesaturated(true);
            else
                button.Level:Hide();
                button.Icon:SetTexture(TraitsCache[i][2]);
                button.Icon:Show();
                rightSpec = IsPowerAvailableForSpec(TraitsCache[i][1], CURRENT_SPEC);
                if rightSpec then
                    button.Border0:SetTexCoord(0, 0.25, 0, 1);          --Saturated
                    button.Border1:SetDesaturated(false);
                    button.Icon:SetDesaturated(false);
                else
                    if TraitsCache[i][2] then                           --Hasn't pick traits
                        button.Border0:SetTexCoord(0.5, 0.75, 0, 1);    --Desaturated
                        button.Border1:SetDesaturated(true);
                        button.Icon:SetDesaturated(true);
                    else
                        button.Border0:SetTexCoord(0, 0.25, 0, 1);      --Saturated
                        button.Border1:SetDesaturated(false);
                        button.Icon:SetDesaturated(false);
                    end
                end
            end
            button:Show();

            if i == 1 then
                TraitsFrame.Name1:SetText(TraitsCache[i][3]);
                TraitsFrame.Description1:SetText(TraitsCache[i][4]);
                if rightSpec then
                    TraitsFrame.Description1:SetTextColor(0.9, 0.8, 0.5);
                else
                    TraitsFrame.Description1:SetTextColor(0.5, 0.5, 0.5);
                end
            elseif i == 2 then
                TraitsFrame.Name2:SetText(TraitsCache[i][3]);
                TraitsFrame.Description2:SetText(TraitsCache[i][4]);
                if rightSpec then
                    TraitsFrame.Description2:SetTextColor(0.9, 0.8, 0.5);
                else
                    TraitsFrame.Description2:SetTextColor(0.5, 0.5, 0.5);
                end           
            end
        else
            button.Border0:SetTexCoord(0.5, 0.75, 0, 1);            --Desaturated
            button.Border1:SetDesaturated(true);
            button:Hide();
        end
    end

    --Base Item--
    if not EquipmentFlyoutFrame.BaseItem then return; end 
    TraitsCache = GetActiveTraits(EquipmentFlyoutFrame.BaseItem);
    if not TraitsCache or EquipmentFlyoutFrame.BaseItem == itemLocation then 
        for i = 1, MAX_TIER do
            TraitsFrame.Traits[i].BaseTrait:Hide();
        end
        return;
    end
    for i = 1, MAX_TIER do
        local button = TraitsFrame.Traits[i];
        local tinybutton = button.BaseTrait;
        if (TraitsCache[i]) and (TraitsCache[i][5]) then
            if TraitsCache[i][2] then
                tinybutton.Icon:SetTexture(TraitsCache[i][2]);
                tinybutton:Show();
                button:Show();
            else
                tinybutton:Hide();
            end
        else
            tinybutton:Hide();
        end
    end

    wipe(TraitsCache);
end


local function ComparisonFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.1 then
        self:SetScript("OnUpdate", nil);
        if self.watchID then
            self.watchID = nil;
            if self.itemButton then
                Narci_Comparison_SetComparison(self.itemButton.itemLocation, self.itemButton);
                self.itemButton = nil;
            end
        end
    end
end

local function ComparisonFrame_OnEvent(self, event, ...)
    local itemID, result = ...
    if itemID == self.watchID then
        self.watchID = nil;
        if self.itemButton then
            Narci_Comparison_SetComparison(self.itemButton.itemLocation, self.itemButton);
            self.itemButton = nil;
        end
    end
    self:SetScript("OnEvent", nil);
end

function Narci_Comparison_SetComparison(itemLocation, itemButton)
    if not itemLocation then return end;

    local frame = Narci_Comparison;
    local FlyOut = EquipmentFlyoutFrame;
    local slotName, slotTexture = GetSlotNameAndTexture(FlyOut.slotID);
    if not DoesItemExist(itemLocation) then
        frame.Label:SetText(CURRENTLY_EQUIPPED);
        frame.ItemName:SetText(EMPTY);
        frame.ItemName:SetTextColor(0.6, 0.6, 0.6);
        frame.EquipLoc:SetText(slotName)
        frame.Icon:SetTexture(slotTexture);
        frame.BonusButton1:Hide();
        frame.BonusButton2:Hide();
        frame.SubTooltip:Hide();
        frame.PawnText:Hide();
        EmptyComparison();
        return;
    end

    local itemLink = GetItemLink(itemLocation);
    local itemID = GetItemID(itemLocation);
    local itemIcon = GetItemIcon(itemLocation);
    local name = GetItemName(itemLocation);
    local quality = GetItemQuality(itemLocation);
    local r, g, b = GetItemQualityColor(quality);

    if not ItemCacheUtil:IsItemDataCached(itemLocation) then
        frame.watchID = itemID;
        frame.itemButton = itemButton;
        frame:RegisterEvent("ITEM_DATA_LOAD_RESULT");
        --frame:SetScript("OnEvent", ComparisonFrame_OnEvent);
        frame.t = 0;
        frame:SetScript("OnUpdate", ComparisonFrame_OnUpdate);
        RequestLoadItemData(itemLocation);
    elseif frame.watchID then
        frame.watchID = nil;
        frame.itemButton = nil;
        frame:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
        --frame:SetScript("OnEvent", nil);
        frame:SetScript("OnUpdate", nil);
    end

    local stats = ItemStats(itemLocation);
    local baseStats = ItemStats(FlyOut.BaseItem);

    local _, _, itemSubType = GetItemInfoInstant(itemLink);

    frame.ItemName:SetText(name);
    frame.ItemName:SetTextColor(r, g, b);
    frame.Icon:SetTexture(itemIcon);
    if FlyOut.slotID then
        if FlyOut.slotID == -1 then
            return
        end
        frame.EquipLoc:SetText(slotName);
    end
    frame.Label:SetText(itemSubType);

    DisplayComparison("ilvl", STAT_AVERAGE_ITEM_LEVEL, stats.ilvl, baseStats.ilvl, nil, {1, 0.82, 0});
    DisplayComparison("prim", PRIMARY_STAT_NAME, stats.prim, baseStats.prim, nil, {0.92, 0.92, 0.92});
    DisplayComparison("stamina", STAMINA_STRING, stats.stamina, baseStats.stamina, CR_ConvertRatio.stamina, {0.92, 0.92, 0.92});
    DisplayComparison("crit", STAT_CRITICAL_STRIKE, stats.crit, baseStats.crit, CR_ConvertRatio.crit);
    DisplayComparison("haste", STAT_HASTE, stats.haste, baseStats.haste, CR_ConvertRatio.haste);
    DisplayComparison("mastery", STAT_MASTERY, stats.mastery, baseStats.mastery, CR_ConvertRatio.mastery);
    DisplayComparison("versatility", STAT_VERSATILITY, stats.versatility, baseStats.versatility, CR_ConvertRatio.versatility);

    local iconPos;
    if stats.GemIcon and stats.GemPos then
        iconPos = frame[stats.GemPos];
        if iconPos then
            frame.BonusButton1.BonusIcon:SetTexture(stats.GemIcon);
            frame.BonusButton1:ClearAllPoints();
            frame.BonusButton1:SetPoint("LEFT", iconPos.Num, "RIGHT", 4, 0);
            frame.BonusButton1:Show();
        else
            frame.BonusButton1:Hide();
        end
    else
        frame.BonusButton1:Hide();
    end

    if stats.EnchantPos then
        iconPos = frame[stats.EnchantPos];
        if iconPos then
            frame.BonusButton2.BonusIcon:SetTexture(136244);
            frame.BonusButton2:ClearAllPoints();
            if frame.BonusButton1:IsShown() and ( stats.GemPos == stats.EnchantPos)then
                frame.BonusButton2:SetPoint("LEFT", iconPos.Num, "RIGHT", 14, 0);
            else
                frame.BonusButton2:SetPoint("LEFT", iconPos.Num, "RIGHT", 4, 0);
            end
            frame.BonusButton2:Show();
        else
            frame.BonusButton2:Hide();
        end
    else
        frame.BonusButton2:Hide();
    end

    if not hasGapAdjusted then
        Narci_Comparison_AdjustGap()
    end

    frame:SetFrameStrata("TOOLTIP");


    --Gem check
    local isDominationItem = false; --DoesItemHaveDomationSocket(itemID);
    local GemName, GemLink;
    if isDominationItem then
        GemName, GemLink = GetItemDominationGem(itemLink);
    else
        GemName, GemLink = IsItemSocketable(itemLink);
    end

    if GemName then
        local itemSubClassID = 9;
        local _, gemID, gemIcon, borderTexture;
        if GemLink then
            gemID, _, _, _, gemIcon, _, itemSubClassID = GetItemInfoInstant(GemLink);
            if isDominationItem then
                borderTexture = GetDominationBorderTexture(gemID);
            else
                borderTexture = GetGemBorderTexture(itemSubClassID, gemIcon);
            end
        else
            if isDominationItem then
                borderTexture = GetDominationBorderTexture(nil);
            else
                borderTexture = GetGemBorderTexture(nil);
            end
        end
        frame.GemSlot.GemBorder:SetTexture(borderTexture);
        frame.GemSlot.GemIcon:SetTexture(gemIcon);
        frame.GemSlot:Show();
        frame.GemSlot.GemIcon:Show();
    else
        frame.GemSlot:Hide();
    end

    --SubTooltip
    local SubTooltip = frame.SubTooltip;
    local TraitsFrame = SubTooltip.AzeriteTraits;
    local extraText = SubTooltip.Description;
    local headerText = SubTooltip.Header.Text;

    --Azerite Empowered Items
    if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
        headerText:SetText(L["Azerite Powers"]);
        SubTooltip.Header:SetWidth(math.max(74, headerText:GetWidth() + 14))
        BuildAzeiteTraitsFrame(TraitsFrame, itemLocation, itemButton);
        extraText:Hide();
        TraitsFrame:Show();
        SubTooltip:Show();
        return;
    else
        TraitsFrame:Hide();
    end

    --Extra Effect (Trinket/Usable)
    --print("CacheCheck Extra: "..tostring(C_Item.IsItemDataCachedByID(itemLink)))
    local headline, str = GetItemExtraEffect(itemLink, isDominationItem);
    if not headline then
        headline, str = GetItemExtraEffect(itemLink)
    end

    if headline then
        if false then   --IsCorruptedItem(itemLink) Corrupted Items
            str = str.."|cff959595"..ITEM_MOD_CORRUPTION.."|r "..stats.corruption;
            local corruptionDiff = stats.corruption - baseStats.corruption;
            if corruptionDiff >= 0 then
                corruptionDiff = "+"..corruptionDiff;
            end
            str = str.." ("..corruptionDiff..")";
            TextColor(extraText, ColorTable.Corrupt);
        else
            TextColor(extraText, ColorTable.Positive2);
        end
        extraText:SetText(str);
        headerText:SetText(headline);
        SubTooltip.Header:SetWidth(math.max(74, headerText:GetWidth() + 14))
        extraText:Show();
        SubTooltip:Show();
    else
        extraText:Hide();
        SubTooltip:Hide();
    end

    UntruncateText(SubTooltip, SubTooltip.Description)

    ---- Pawn ----
    frame.PawnText:Hide();
    if PawnGetItemData and PawnIsItemAnUpgrade and PawnAddValuesToTooltip then
        local Item = PawnGetItemData(itemLink);
        if Item then
            local UpgradeInfo, ItemLevelIncrease, BestItemFor, SecondBestItemFor, NeedsEnhancements = PawnIsItemAnUpgrade(Item);
            PawnAddValuesToTooltip(frame, Item.Values, UpgradeInfo, BestItemFor, SecondBestItemFor, NeedsEnhancements, Item.InvType);
        end
    end
end

--FlyOut Tooltip
local function UpdateSpectIDAndPrimaryStat()
    local PrimaryStatsList = {
        [LE_UNIT_STAT_STRENGTH] = NARCI_STAT_STRENGTH,
        [LE_UNIT_STAT_AGILITY] = NARCI_STAT_AGILITY,
        [LE_UNIT_STAT_INTELLECT] = NARCI_STAT_INTELLECT,
    };

    local currentSpec = GetSpecialization() or 1;
    local _, primaryStatID;
    CURRENT_SPEC, _, _, _, _, primaryStatID = GetSpecializationInfo(currentSpec);
    PRIMARY_STAT_NAME = PrimaryStatsList[primaryStatID] or PRIMARY_STAT_NAME;
end

local NT = CreateFrame("Frame");
NT:RegisterEvent("PLAYER_ENTERING_WORLD");
NT:RegisterEvent("PLAYER_LEVEL_UP");
NT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
NT:RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED");
NT:SetScript("OnEvent",function(self,event,...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        EquipmentFlyoutFrame = Narci_EquipmentFlyoutFrame;
    end

    if event ~= "AZERITE_ITEM_POWER_LEVEL_CHANGED" then
        if ( not self.pauseUpdate ) then
            self.pauseUpdate = true;
            C_Timer.After(0.5, function()    -- only want 1 update per 0.5s
                self.pauseUpdate = nil;
                SetCombatRatingRatio();
            end)
        end
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateSpectIDAndPrimaryStat();
    end

    if event == "AZERITE_ITEM_POWER_LEVEL_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
        if azeriteItemLocation then
            --Credit: flowerpew     Bug Fix: Can't retrieve level if Heart of Azeroth is in the bank
            if IsAzeriteItemLocationBankBag(azeriteItemLocation) then
                HEART_LEVEL = 0;
            else
                HEART_LEVEL = C_AzeriteItem.GetPowerLevel(azeriteItemLocation) or 0;
            end
        else
            HEART_LEVEL = 0;
        end
        UpdateSpectIDAndPrimaryStat();
    end
end)


function Narci_ShowComparisonTooltip(tooltip)
    local extraHeight = floor(tooltip.ItemName:GetHeight() + 0.5);
    tooltip:SetHeight(COMPARISON_HEIGHT + extraHeight);
    tooltip.Icon:SetWidth(COMPARISON_HEIGHT + extraHeight);
    tooltip:Show();
end


function Narci_CreateAzeriteTraitTooltip(self)
    self.Traits = { self.Trait1 };
    local maximumTraits = 5;
    local offset = 1;
    local startOffset = 8;
    local numButtons = 0;
    local trait;
    for i = 2, maximumTraits do
        trait = CreateFrame("Button", nil, self, "Narci_SubTooltip_Trait_Template");
        trait:SetPoint("LEFT", self.Traits[i-1], "RIGHT", offset, 0);
        tinsert(self.Traits, trait);
    end
end

function Narci:GetCombatRatings()
    local NA = "N/A";
    local crit = CR_ConvertRatio.crit;
    local haste = CR_ConvertRatio.haste;
    local mastery = CR_ConvertRatio.mastery;
    local versatility = CR_ConvertRatio.versatility;
    crit = floor( (1 / crit*100 + 0.5)) / 100 or NA;
    haste = floor( (1 / haste*100 + 0.5)) / 100 or NA;
    mastery = floor( (1 / mastery*100 + 0.5)) / 100 or NA;
    versatility = floor( (1 / versatility*100 + 0.5)) / 100 or NA;

    local YELLOW = "|cFFFFD100";
    local GREY = "|cffa6a6a6";
    local headline = "Conversion Rate";
    local str = string.format("1 Percentage of Stat requires:\nCrit: %s\nHaste: %s\nMastery: %s\nVersatility: %s", crit, haste, mastery, versatility);
    
    print(YELLOW.."1% Stat Requires:")
    print(crit..GREY.."  Critical Strike |r");
    print(haste..GREY.."  Haste |r");
    print(mastery..GREY.."  Mastery |r");
    print(versatility..GREY.."  Versatility |r");
    print(GREY.."1 Stamina  |r"..CR_ConvertRatio.stamina.." HP");
    return str;
end

local function ConvertRatingToPercentage(name, value)
    if CR_ConvertRatio[name] then
        return  string.format(" (%.2f%%)", floor( 100 * CR_ConvertRatio[name] * value )/100);
    else
        return ""
    end
end

NarciAPI.ConvertRatingToPercentage = ConvertRatingToPercentage;


NarciEquipmentComparisonMixin = {};

function NarciEquipmentComparisonMixin:OnSizeChanged()
    self.Icon:SetWidth(self:GetHeight());
end

function NarciEquipmentComparisonMixin:OnShow()
    self.Icon:SetAlpha(0.06);
    self:StopAnimating();
    self.animIn:Play();
end

function NarciEquipmentComparisonMixin:OnHide()
    self:Hide();
    self:SetScript("OnUpdate", nil);
end

function NarciEquipmentComparisonMixin:AddPawnText(text)
    if text then
        self.PawnText:Show();
        self.PawnText:SetText(text);

        local extraHeight = floor(self.PawnText:GetHeight() + self.ItemName:GetHeight() + 8);
        self:SetHeight(COMPARISON_HEIGHT + extraHeight);
    else
        self.PawnText:Hide();
    end
end

function NarciEquipmentComparisonMixin:AddLine(text, r, g, b, wrap)
    self:AddPawnText(text);
end

function NarciEquipmentComparisonMixin:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
    if leftText and rightText then
        self:AddPawnText(leftText.." "..rightText);
    end
end
