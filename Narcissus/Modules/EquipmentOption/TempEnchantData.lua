local _, addon = ...;
local GetItemCount = C_Item.GetItemCount;
local unpack = unpack;

--[[
        Inventory slots         https://www.townlong-yak.com/framexml/ptr/Constants.lua
    INVSLOT_AMMO		= 0;
    INVSLOT_HEAD 		= 1;
    INVSLOT_NECK		= 2;
    INVSLOT_SHOULDER	= 3;
    INVSLOT_BODY		= 4;
    INVSLOT_CHEST		= 5;
    INVSLOT_WAIST		= 6;
    INVSLOT_LEGS		= 7;
    INVSLOT_FEET		= 8;
    INVSLOT_WRIST		= 9;
    INVSLOT_HAND		= 10;
    INVSLOT_FINGER1		= 11;
    INVSLOT_FINGER2		= 12;
    INVSLOT_TRINKET1	= 13;
    INVSLOT_TRINKET2	= 14;
    INVSLOT_BACK		= 15;
    INVSLOT_MAINHAND	= 16;
    INVSLOT_OFFHAND		= 17;
    INVSLOT_RANGED		= 18;
    INVSLOT_TABARD		= 19;
--]]

local enchantData = {
    --[slotID] = { {spellID, itemID, enchantID, [requirementID]} }     --requirementID: 1(Bladed), 2(Blunt), 3(Hunter Ranged Weapon)
    --Shadowlands and on


    [16] = {    --Weapon
        {451874, 224107, 7495},        --T3 Algari Mana Oil (Crit, Haste)
        {451873, 224106, 7494},        --T2 Algari Mana Oil
        {451869, 224105, 7493},        --T1 Algari Mana Oil

        {451902, 224113, 7498},        --T3 Oil of Deep Toxins (DMG)
        {451901, 224112, 7497},        --T2 Oil of Deep Toxins
        {451882, 224111, 7496},        --T1 Oil of Deep Toxins

        {451927, 224110, 7502},        --T3 Oil of Beledar's Grace (Heal)
        {451925, 224109, 7501},        --T2 Oil of Beledar's Grace
        {451926, 224108, 7500},        --T1 Oil of Beledar's Grace

        {458934, 222504, 7545, 2},     --T3 Ironclaw Whetstone (Bladed)
        {458933, 222503, 7544, 2},     --T2 Ironclaw Whetstone
        {458932, 222502, 7543, 2},     --T1 Ironclaw Whetstone

        {458937, 222510, 7551, 1},     --T3 Ironclaw Weightstone (Blunt)
        {458936, 222509, 7550, 1},     --T3 Ironclaw Weightstone
        {458935, 222508, 7549, 1},     --T3 Ironclaw Weightstone

        {444755, 220156, 7467},        --Bubbling Wax (Rogue)
    },
};


local DataProvider = {};
addon.TempDataProvider = DataProvider;

DataProvider.filteredData = {};

local subset = enchantData[5];

function DataProvider:SetSubset(slotID)
    if slotID == 12 then
        slotID = 11;
    elseif slotID == 14 then
        slotID = 13;
    elseif slotID == 17 then
        slotID = 16;
    end
    subset = enchantData[slotID] or {};
end

function DataProvider:ApplyFilter(ownedOnly)
    self.filteredData = {};
    local numData = 0;
    if ownedOnly then
        for i = 1, #subset do
            if GetItemCount(subset[i][2]) > 0 then
                numData = numData + 1;
                self.filteredData[numData] = subset[i];
            end
        end
        return numData
    else
        DataProvider.filteredData = subset;
        return #self.filteredData
    end
end

function DataProvider:GetDataByIndex(index)
    local data = self.filteredData[index];
    if data then
        return unpack(data);
    end
end


local TooltipLines = {
    Generic = {3, 4, 5},
};

function DataProvider:GetItemTooltipLines(itemID)
    return TooltipLines.Generic
end