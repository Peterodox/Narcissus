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
    --[slotID] = { {spellID, itemID, enchantID, [icon], [requirement]} }     --default icon: 463531
    --Shadowlands and on

    [5] = {     --Chest
        {342316, 183738, 6265, 631503},     --Eternal Insight
        {309535, 172418, 6213, 134950},     --Eternal Bulwark
        {323761, 177715, 6217, 135913},     --Eternal Bounds
        {323760, 177659, 6214, 631503},     --Eternal Skirmish
        {324773, 177962, 6230},             --Eternal Stats
        {323762, 177716, 6216},             --Sacred Stats
    },

    [8] = {     --Feet
        {323609, 177661, 6207, 135992},     --Soul Treads
        {309534, 172419, 6211, 135879},     --Eternal Agility
        {309532, 172413, 6212, 135879},     --Agile Soulwalker
    },

    [9] = {     --Wrist
        {309610, 172416, 6222, 134414},     --Shaded Hearthing
        {309609, 172415, 6220, 135932},     --Eternal Intellect
        {309608, 172414, 6219, 135932},     --Illuminated Soul
    },

    [10] = {    --Hand
        {309524, 172406, 6205, 999951},     --Shadowlands Gathering
        {309526, 172408, 6210, 136101},     --Eternal Strength
        {309525, 172407, 6209, 136101},     --Strength of Soul
    },

    [11] = {     --Finger
        {309616, 172361, 6164},    --Tenet of Critical Strike
        {309617, 172362, 6166},    --Tenet of Haste
        {309618, 172363, 6168},    --Tenet of Mastery
        {309619, 172364, 6170},    --Tenet of Versatility

        {309612, 172357, 6163},    --Bargain of Critical Strike
        {309613, 172358, 6165},    --Bargain of Haste
        {309614, 172359, 6167},    --Bargain of Mastery
        {309615, 172360, 6169},    --Bargain of Versatility
    },

    [15] = {    --Back
        {309530, 172411, 6203, 132301},     --Fortified Avoidance
        {309531, 172412, 6204, 136231},     --Fortified Leech
        {309528, 172410, 6202, 648208},     --Fortified Speed
        {323755, 177660, 6208},             --Soul Vitality
    },

    [16] = {    --Weapon
        {309627, 172366, 6229, 636335},     --Celestial Guidance
        {309623, 172368, 6228, 462651},     --Sinful Revelation
        {309622, 172365, 6227, 135905},     --Ascended Vigor
        {309621, 172367, 6226, 1519263},    --Eternal Grace
        {309620, 172370, 6223, 631519},     --Lightless Force

        {321536, 172920, 6196, 3610512, 3},    --Optical Target Embiggener
        {321535, 172921, 6195, 3610513, 3},    --Infra-green Reflex Sight
    },
};


local DataProvider = {};
addon.EnchantDataProvider = DataProvider;

DataProvider.filteredData = {};

local subset = enchantData[11];

function DataProvider:SetSubset(slotID)
    if slotID == 12 then
        slotID = 11;
    elseif slotID == 14 then
        slotID = 13;
    elseif slotID == 17 then
        slotID = 16;
    end
    subset = enchantData[slotID] or {};
    if enchantData[slotID] then
        return true
    else
        return false
    end
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

