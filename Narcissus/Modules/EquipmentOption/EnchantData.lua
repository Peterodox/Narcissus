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
    --[slotID] = { {spellID, itemID, enchantID, [icon], [requirement]} }     --default icon: 463531
    --Shadowlands and on
    --Dragonflight Crafing: https://wow.tools/dbc/?dbc=craftingdataenchantquality
    --EnchantID: https://wago.tools/db2/SpellItemEnchantment

    [5] = {     --Chest
        {389419, 200029, 6622, 136101},     --Sustained Strength T3 STR + HP
        {389419, 199987, 6621, 136101},     --Sustained Strength T2 STR + HP
        {389419, 199945, 6620, 136101},     --Sustained Strength T1 STR + HP

        {389416, 200027, 6616, 135879},     --Accelerated Agility T3 AGI + Speed
        {389416, 199985, 6615, 135879},     --Accelerated Agility T2 AGI + Speed
        {389416, 199943, 6614, 135879},     --Accelerated Agility T1 AGI + Speed

        {389417, 200028, 6619, 135932},     --Reserve of Intellect T3 INT + MP
        {389417, 199986, 6618, 135932},     --Reserve of Intellect T2 INT + MP
        {389417, 199944, 6617, 135932},     --Reserve of Intellect T1 INT + MP

        {389410, 200030, 6625},             --Waking Stats T3 +All Primary Stats
        {389410, 199988, 6624},             --Waking Stats T2
        {389410, 199946, 6623},             --Waking Stats T1

        ----SL----
        {342316, 183738, 6265, 631503},     --Eternal Insight
        {309535, 172418, 6213, 134950},     --Eternal Bulwark
        {323761, 177715, 6217, 135913},     --Eternal Bounds
        {323760, 177659, 6214, 631503},     --Eternal Skirmish
        {324773, 177962, 6230},             --Eternal Stats
        {323762, 177716, 6216},             --Sacred Stats
    },

    [6] = {     --Waist
        {411897, 205039, 6904},     --Shadowed Belt Clasp T3 Stamina
        {411898, 205044, 6905},     --Shadowed Belt Clasp T2
        {411899, 205043, 6906},     --Shadowed Belt Clasp T1
    },

    [7] = {     --Legs
        {406299, 204702, 6830},     --Lambent Armor Kit T3 Primary + Versatility
        {406298, 204701, 6829},     --Lambent Armor Kit T2
        {406295, 204700, 6828},     --Lambent Armor Kit T1

        {376848, 193565, 6490},     --Fierce Armor Kit T3 Stamina + Agility/Strength
        {376844, 193561, 6489},     --Fierce Armor Kit T2
        {376822, 193557, 6488},     --Fierce Armor Kit T1

        {376847, 193564, 6496},     --Frosted Armor Kit T3 Armor + Agility/Strength
        {376845, 193560, 6495},     --Frosted Armor Kit T2
        {376819, 193556, 6494},     --Frosted Armor Kit T1

        {387294, 194013, 6541},     --Frozen Spellthread T3 Stamina + INT
        {387293, 194012, 6540},     --Frozen Spellthread T2
        {387291, 194011, 6539},     --Frozen Spellthread T1

        {387298, 194016, 6544},     --Temporal Spellthread T3 Mana + INT
        {387296, 194015, 6543},     --Temporal Spellthread T2
        {387295, 194014, 6542},     --Temporal Spellthread T1
    },

    [8] = {     --Feet
        {389484, 200020, 6613, 136112},     --Watcher's Loam T3 + Stamina
        {389484, 199978, 6612, 136112},     --Watcher's Loam T2
        {389484, 199936, 6611, 136112},     --Watcher's Loam T1

        {389479, 200018, 6607, 648208},     --Plainsrunner's Breeze T3 + Speed
        {389479, 199976, 6606, 648208},     --Plainsrunner's Breeze T2
        {389479, 199934, 6605, 648208},     --Plainsrunner's Breeze T1

        {389480, 200019, 6610, 136103},     --Rider's Reassurance T3 + Mounted Speed
        {389480, 199977, 6609, 136103},     --Rider's Reassurance T2
        {389480, 199935, 6608, 136103},     --Rider's Reassurance T1

        ----SL----
        {323609, 177661, 6207, 135992},     --Soul Treads
        {309534, 172419, 6211, 135879},     --Eternal Agility
        {309532, 172413, 6212, 135879},     --Agile Soulwalker
    },

    [9] = {     --Wrist
        {389301, 200021, 6574, 132301},     --Devotion of Avoidance T3
        {389301, 199979, 6573, 132301},     --Devotion of Avoidance T2
        {389301, 199937, 6572, 132301},     --Devotion of Avoidance T1

        {389303, 200022, 6580, 136231},     --Devotion of Leech T3
        {389303, 199980, 6579, 136231},     --Devotion of Leech T2
        {389303, 199938, 6578, 136231},     --Devotion of Leech T1

        {389304, 200023, 6586, 648208},     --Devotion of Speed T3
        {389304, 199981, 6585, 648208},     --Devotion of Speed T2
        {389304, 199939, 6584, 648208},     --Devotion of Speed T1

        {389297, 200024, 6571, 132301},     --Writ of Avoidance T3
        {389297, 199982, 6570, 132301},     --Writ of Avoidance T2
        {389297, 199940, 6569, 132301},     --Writ of Avoidance T1

        {389298, 200025, 6577, 136231},     --Writ of Leech T3
        {389298, 199983, 6576, 136231},     --Writ of Leech T2
        {389298, 199941, 6575, 136231},     --Writ of Leech T1

        {389300, 200026, 6583, 648208},     --Writ of Speed T3
        {389300, 199984, 6582, 648208},     --Writ of Speed T2
        {389300, 199942, 6581, 648208},     --Writ of Speed T1

        ----SL----
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
        {389292, 200037, 6550},    --Devotion of Critical Strike T3
        {389292, 199995, 6549},    --Devotion of Critical Strike T2
        {389292, 199953, 6548},    --Devotion of Critical Strike T1

        {389293, 200038, 6556},    --Devotion of Haste T3
        {389293, 199996, 6555},    --Devotion of Haste T2
        {389293, 199954, 6554},    --Devotion of Haste T1

        {389294, 200039, 6562},    --Devotion of Mastery T3
        {389294, 199997, 6561},    --Devotion of Mastery T2
        {389294, 199955, 6560},    --Devotion of Mastery T1

        {389295, 200040, 6568},    --Devotion of Versatility T3
        {389295, 199998, 6567},    --Devotion of Versatility T3
        {389295, 199956, 6566},    --Devotion of Versatility T1

        {388930, 200041, 6547},    --Writ of Critical Strike T3
        {388930, 199999, 6546},    --Writ of Critical Strike T2
        {388930, 199957, 6545},    --Writ of Critical Strike T1

        {389135, 200042, 6553},    --Writ of Haste T3
        {389135, 200000, 6552},    --Writ of Haste T2
        {389135, 199958, 6551},    --Writ of Haste T1

        {389136, 200043, 6559},    --Writ of Mastery T3
        {389136, 200001, 6558},    --Writ of Mastery T2
        {389136, 199959, 6557},    --Writ of Mastery T1

        {389151, 200044, 6565},    --Writ of Versatility T3
        {389151, 200002, 6564},    --Writ of Versatility T2
        {389151, 199960, 6563},    --Writ of Versatility T1

        ----SL----
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
        {389403, 200031, 6592, 132301},     --Graceful Avoidance T3 Voidance & Slow Fall
        {389403, 199989, 6591, 132301},     --Graceful Avoidance T2 Voidance & Slow Fall
        {389403, 199947, 6590, 132301},     --Graceful Avoidance T1 Voidance & Slow Fall

        {389404, 200033, 6598, 136231},     --Regenerative Leech T3 Leech & out-of-combat regen
        {389404, 199991, 6597, 136231},     --Regenerative Leech T2 Leech & out-of-combat regen
        {389404, 199949, 6596, 136231},     --Regenerative Leech T1 Leech & out-of-combat regen

        {389405, 200032, 6604, 648208},     --Homebound Speed T3 Speed & Hearthstone CD Reduction
        {389405, 199990, 6603, 648208},     --Homebound Speed T3 Speed & Hearthstone CD Reduction
        {389405, 199948, 6602, 648208},     --Homebound Speed T3 Speed & Hearthstone CD Reduction

        {389397, 200034, 6589, 132301},     --Writ of Avoidance T3
        {389397, 199992, 6588, 132301},     --Writ of Avoidance T2
        {389397, 199950, 6587, 132301},     --Writ of Avoidance T1

        {389398, 200035, 6595, 136231},     --Writ of Leech T3
        {389398, 199993, 6594, 136231},     --Writ of Leech T2
        {389398, 199951, 6593, 136231},     --Writ of Leech T1

        {389400, 200036, 6601, 648208},     --Writ of Speed T3
        {389400, 199994, 6600, 648208},     --Writ of Speed T2
        {389400, 199952, 6599, 648208},     --Writ of Speed T1

        ----SL----
        {309530, 172411, 6203, 132301},     --Fortified Avoidance
        {309531, 172412, 6204, 136231},     --Fortified Leech
        {309528, 172410, 6202, 648208},     --Fortified Speed
        {323755, 177660, 6208},             --Soul Vitality
    },

    [16] = {    --Weapon
        {405076, 204623, 6827, 5009071},    --Shadowflame Wreathe T3
        {405076, 204622, 6826, 5009071},    --Shadowflame Wreathe T2
        {405076, 204621, 6825, 5009071},    --Shadowflame Wreathe T1

        {404859, 204615, 6824, 5041801},    --Spore Tender T3
        {404859, 204614, 6823, 5041801},    --Spore Tender T2
        {404859, 204613, 6822, 5041801},    --Spore Tender T1

        {389547, 200050, 6631, 4554438},    --Burning Devotion T3 Heal
        {389547, 200008, 6630, 4554438},    --Burning Devotion T2 
        {389547, 199966, 6629, 4554438},    --Burning Devotion T1

        {389549, 200052, 6637, 4554437},    --Earthen Devotion T3 Armor
        {389549, 200010, 6636, 4554437},    --Earthen Devotion T2
        {389549, 199968, 6635, 4554437},    --Earthen Devotion T1

        {389551, 200056, 6649, 4554439},    --Frozen Devotion T3 Frontal AoE T3
        {389551, 200014, 6648, 4554439},    --Frozen Devotion T2
        {389551, 199972, 6647, 4554439},    --Frozen Devotion T1

        {389550, 200054, 6643, 4554442},    --Sophic Devotion T3 Primary Stats
        {389550, 200012, 6642, 4554442},    --Sophic Devotion T2
        {389550, 199970, 6641, 4554442},    --Sophic Devotion T1

        {389558, 200058, 6655, 4554434},    --Wafting Devotion T3 Haste & Speed
        {389558, 200016, 6654, 4554434},    --Wafting Devotion T2
        {389558, 199974, 6653, 4554434},    --Wafting Devotion T1

        {389537, 200051, 6628, 4554448},    --Burning Writ T3 Crit
        {389537, 200009, 6627, 4554448},    --Burning Writ T2
        {389537, 199967, 6626, 4554448},    --Burning Writ T1

        {389540, 200053, 6634, 4554447},    --Earthen Writ T3 Mastery
        {389540, 200011, 6633, 4554447},    --Earthen Writ T2
        {389540, 199969, 6632, 4554447},    --Earthen Writ T1

        {389543, 200057, 6644, 4554449},    --Frozen Writ T3 Versatility
        {389543, 200015, 6644, 4554449},    --Frozen Writ T2
        {389543, 199973, 6644, 4554449},    --Frozen Writ T1

        {389542, 200055, 6640, 4554452},    --Sophic Writ T3 Primary Stats
        {389542, 200013, 6639, 4554452},    --Sophic Writ T2
        {389542, 199971, 6638, 4554452},    --Sophic Writ T1

        {389546, 200059, 6652, 4554444},    --Wafting Writ T3 Haste
        {389546, 200017, 6651, 4554444},    --Wafting Writ T2
        {389546, 199975, 6650, 4554444},    --Wafting Writ T1

        --Scopes
        {386154, 198318, 6528, 4548899, 3},    --High Intensity Thermal Scanner T3
        {386153, 198317, 6527, 4548899, 3},    --High Intensity Thermal Scanner T2
        {386152, 198316, 6526, 4548899, 3},    --High Intensity Thermal Scanner T1

        {385775, 198315, 6525, 4548898, 3},    --Projectile Propulsion Pinion T3
        {385773, 198314, 6524, 4548898, 3},    --Projectile Propulsion Pinion T2
        {385772, 198313, 6523, 4548898, 3},    --Projectile Propulsion Pinion T1

        {385770, 198312, 6522, 4548897, 3},    --Gyroscopic Kaleidoscope T3
        {385768, 198311, 6521, 4548897, 3},    --Gyroscopic Kaleidoscope T2
        {385766, 198310, 6520, 4548897, 3},    --Gyroscopic Kaleidoscope T1

        ----SL----
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

