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

    [5] = {     --Chest
        ----SL----
        {324068, 172347, 6225},     --Heavy Desolate Armor Kit
        {324064, 172346, 6224},     --Desolate Armor Kit
    },

    [16] = {    --Weapon
        {409660, 204973, 6839},     --Hissing Rune T3 Mastery (Melee)
        {409659, 204972, 6837},     --Hissing Rune T2
        {409654, 204971, 6838},     --Hissing Rune T1

        {385327, 194823, 6514},     --Buzzing Rune T3 Crit (Melee)
        {385326, 194822, 6513},     --Buzzing Rune T2
        {385325, 194821, 6512},     --Buzzing Rune T1

        {385577, 194820, 6518},     --Howling Rune T3 Haste (Melee)
        {385576, 194819, 6517},     --Howling Rune T2
        {385575, 194817, 6516},     --Howling Rune T1

        {396148, 194826, 6695},     --Chirping Rune T3 Heal (Melee)
        {396147, 194825, 6694},     --Chirping Rune T2
        {385330, 194824, 6515},     --Chirping Rune T1

        {396157, 191940, 6381, 1},     --Primal Whetstone T3 (Bladed)
        {396156, 191939, 6380, 1},     --Primal Whetstone T2
        {396155, 191933, 6379, 1},     --Primal Whetstone T1

        {371678, 191945, 6698, 2},     --Primal Whetstone T3 (Blunt)
        {371677, 191944, 6697, 2},     --Primal Whetstone T2
        {371676, 191943, 6696, 2},     --Primal Whetstone T1

        {386246, 198162, 6531, 3},     --Completely Safe Rockets T3 (Ranged)
        {386245, 198161, 6530, 3},     --Completely Safe Rockets T2
        {386243, 198160, 6529, 3},     --Completely Safe Rockets T1

        {386255, 198165, 6534, 3},     --Endless Stack of Needles T3 (Ranged)
        {386254, 198164, 6533, 3},     --Endless Stack of Needles T2
        {386252, 198163, 6532, 3},     --Endless Stack of Needles T1

        ----SL----
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

