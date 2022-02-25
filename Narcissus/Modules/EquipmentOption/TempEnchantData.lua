local _, addon = ...;
local GetItemCount = GetItemCount;
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

    [5] = {     --Chest
        {324068, 172347, 6225},     --Heavy Desolate Armor Kit
        {324064, 172346, 6224},     --Desolate Armor Kit
    },

    [16] = {    --Weapon
        {320798, 171285, 6188},     --Shadowcore Oil
        {321389, 171286, 6190},     --Embalmer's Oil    --Heal
        {322762, 171437, 6200, 1},     --Shaded Sharpening Stone
        {322749, 171436, 6198, 1},     --Porous Sharpening Stone
        {322763, 171439, 6201, 2},     --Shaded Weightstone (Mace & Staff)
        {322761, 171438, 6199, 2},     --Porous Weightstone (Mace & Staff)
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

