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

local ICON_AVOIDANCE = 132301;
local ICON_LEECH = 136231;
local ICON_SPEED = 648208;

local enchantData = {
    --[slotID] = { {spellID, itemID, enchantID, [icon], [requirement]} }     --default icon: 463531          --requirementID: 1(Bladed), 2(Blunt), 3(Hunter Ranged Weapon)
    --Shadowlands and on
    --Dragonflight Crafing: https://wow.tools/dbc/?dbc=craftingdataenchantquality
    --EnchantID: https://wago.tools/db2/SpellItemEnchantment

    [1] = {     --Head
        {1236084, 244007, 8017, ICON_AVOIDANCE},     --T2 Empowered Rune of Avoidance
        {1236084, 244006, 8016, ICON_AVOIDANCE},     --T1 Empowered Rune of Avoidance

        {1236056, 243951, 7961, ICON_LEECH},     --T2 Empowered Hex of Leeching
        {1236056, 243950, 7960, ICON_LEECH},     --T1 Empowered Hex of Leeching

        {1236071, 243981, 7991, ICON_SPEED},     --T2 Empowered Blessing of Speed
        {1236071, 243980, 7990, ICON_SPEED},     --T1 Empowered Blessing of Speed

        {1236083, 244005, 8015, ICON_AVOIDANCE},     --T2 Rune of Avoidance
        {1236083, 244004, 8014, ICON_AVOIDANCE},     --T1 Rune of Avoidance

        {1236055, 243949, 7959, ICON_LEECH},     --T2 Hex of Leeching
        {1236055, 243948, 7958, ICON_LEECH},     --T1 Hex of Leeching

        {1236070, 243979, 7989, ICON_SPEED},     --T2 Blessing of Speed
        {1236070, 243978, 7988, ICON_SPEED},     --T1 Blessing of Speed
    },

    [3] = {     --Shoulder
        {1236076, 243991, 8001, ICON_AVOIDANCE},     --T2 Amirdrassil's Grace
        {1236076, 243990, 8000, ICON_AVOIDANCE},     --T1 Amirdrassil's Grace

        {1236091, 244021, 8031, ICON_LEECH},     --T2 Silvermoon's Mending
        {1236091, 244020, 8030, ICON_LEECH},     --T1 Silvermoon's Mending

        {1236062, 243963, 7973, ICON_SPEED},     --T2 Akil'zon's Swiftness
        {1236062, 243962, 7972, ICON_SPEED},     --T1 Akil'zon's Swiftness

        {1236075, 243989, 7999, ICON_AVOIDANCE},     --T2 Nature's Grace
        {1236075, 243988, 7998, ICON_AVOIDANCE},     --T1 Nature's Grace

        {1236090, 244019, 8029, ICON_LEECH},     --T2 Thalassian Recovery
        {1236090, 244020, 8028, ICON_LEECH},     --T1 Thalassian Recovery

        {1236061, 243961, 7971, ICON_SPEED},     --T2 Flight of the Eagle
        {1236061, 243960, 7970, ICON_SPEED},     --T1 Flight of the Eagle
    },

    [5] = {     --Chest
        {1236069, 243977, 7987},             --T2 Mark of the Worldsoul (Primary Stat)
        {1236069, 243976, 7986},             --T1 Mark of the Worldsoul

        {1236054, 243947, 7957},             --T2 Mark of Nalorakk (STR, HP)
        {1236054, 243946, 7956},             --T1 Mark of Nalorakk

        {1236068, 243975, 7985},             --T2 Mark of Rootwarden (AGI, Speed)
        {1236068, 243974, 7984},             --T1 Mark of Rootwarden

        {1236082, 244003, 8013},             --T2 Mark of Magister (INT, MP)
        {1236082, 244002, 8012},             --T1 Mark of Magister


        {445333, 223692, 7364},             --T3 Crystalline Radiance (Primary Stat)
        {445333, 223691, 7363},             --T2 Crystalline Radiance
        {445333, 223690, 7362},             --T1 Crystalline Radiance

        {445321, 223689, 7361, 136101},     --T3 Oathsworn's Strength (STR, HP)
        {445321, 223688, 7360, 136101},     --T2 Oathsworn's Strength
        {445321, 223687, 7359, 136101},     --T1 Oathsworn's Strength

        {445353, 223683, 7355, 135879},     --T3 Stormrider's Agility (AGI, Speed)
        {445353, 223682, 7354, 135879},     --T2 Stormrider's Agility
        {445353, 223681, 7353, 135879},     --T1 Stormrider's Agility

        {445322, 223686, 7358, 135932},     --T3 Council's Intellect (INT, MP)
        {445322, 223685, 7357, 135932},     --T2 Council's Intellect
        {445322, 223684, 7356, 135932},     --T1 Council's Intellect
    },

    [6] = {     --Waist

    },

    [7] = {     --Legs
        {1243976, 244641, 8159},    --T2 Forest Hunter's Armor Kit
        {1243975, 244640, 8158},    --T1 Forest Hunter's Armor Kit

        {1243980, 244643, 8163},    --T2 Blood Knight's Armor Kit
        {1243979, 244642, 8162},    --T1 Blood Knight's Armor Kit

        {1229442, 240133, 7935},    --T2 Sunfire Silk Spellthread
        {1229437, 240094, 7934},    --T1 Sunfire Silk Spellthread

        {1229454, 240155, 7937},    --T2 Sunfire Silk Spellthread
        {1229453, 240154, 7936},    --T1 Sunfire Silk Spellthread

        {1243978, 244645, 8161},    --T2 Thalassian Scout Armor Kit
        {1243977, 244644, 8160},    --T1 Thalassian Scout Armor Kit

        {1229457, 240157, 7939},    --T2 Bright Linen Spellthread
        {1229456, 240156, 7938},    --T1 Bright Linen Spellthread


        {457623, 222893, 7534},             --T3 Sunset Spellthread (++Int, HP)
        {457622, 222892, 7533},             --T2 Sunset Spellthread
        {457621, 222891, 7532},             --T1 Sunset Spellthread

        {457620, 222896, 7531},             --T3 Daybreak Spellthread (INT, Mana)
        {457619, 222895, 7530},             --T2 Daybreak Spellthread
        {457618, 222894, 7529},             --T1 Daybreak Spellthread

        {457626, 222890, 7537},             --T3 Weavecloth Spellthread (INT)
        {457625, 222889, 7536},             --T2 Weavecloth Spellthread
        {457624, 222888, 7535},             --T1 Weavecloth Spellthread

        {451825, 219911, 7601},             --T3 Stormbound Armor Kit (++AGI/STR, HP)
        {451825, 219910, 7600},             --T2 Stormbound Armor Kit
        {451825, 219909, 7599},             --T1 Stormbound Armor Kit

        {451828, 219908, 7595},             --T3 Defender's Armor Kit (AGI/STR, Armor)
        {451828, 219907, 7594},             --T2 Defender's Armor Kit
        {451828, 219906, 7593},             --T1 Defender's Armor Kit

        {451831, 219914, 7598},             --T3 Dual Layered Armor Kit (AGI/STR, HP)
        {451831, 219913, 7597},             --T2 Dual Layered Armor Kit
        {451831, 219912, 7596},             --T1 Dual Layered Armor Kit
    },

    [8] = {     --Feet
        {1236057, 243953, 7963, ICON_AVOIDANCE},     --T2 Lynx's Hunt
        {1236057, 243952, 7962, ICON_AVOIDANCE},     --T1 Lynx's Hunt

        {1236072, 243983, 7993, ICON_LEECH},     --T2 Shaladrassil's Hunt
        {1236072, 243982, 7992, ICON_LEECH},     --T1 Shaladrassil's Hunt

        {1236085, 244009, 8019, ICON_SPEED},     --T2 Farstrider's Hunt
        {1236085, 244008, 8018, ICON_SPEED},     --T1 Farstrider's Hunt


        {445335, 223650, 7421, 136103},     --T3 Cavalry's March (Mounted Speed)
        {445335, 223649, 7420, 136103},     --T2 Cavalry's March
        {445335, 223648, 7419, 136103},     --T1 Cavalry's March

        {445396, 223656, 7424, 136112},     --T3 Defender's March (HP)
        {445396, 223655, 7423, 136112},     --T2 Defender's March
        {445396, 223654, 7422, 136112},     --T1 Defender's March

        {445368, 223653, 7418, ICON_SPEED},     --T3 Scout's March (Speed)
        {445368, 223652, 7417, ICON_SPEED},     --T2 Scout's March
        {445368, 223651, 7416, ICON_SPEED},     --T1 Scout's March
    },

    [9] = {     --Wrist
        {445334, 223713, 7385, ICON_AVOIDANCE},     --T3 Chant of Armored Avoidance
        {445334, 223712, 7384, ICON_AVOIDANCE},     --T2 Chant of Armored Avoidance
        {445334, 223711, 7383, ICON_AVOIDANCE},     --T1 Chant of Armored Avoidance

        {445325, 223719, 7391, ICON_LEECH},     --T3 Chant of Armored Leech
        {445325, 223718, 7390, ICON_LEECH},     --T2 Chant of Armored Leech
        {445325, 223717, 7389, ICON_LEECH},     --T1 Chant of Armored Leech

        {445330, 223725, 7397, ICON_SPEED},     --T3 Chant of Armored Speed
        {445330, 223724, 7396, ICON_SPEED},     --T2 Chant of Armored Speed
        {445330, 223723, 7395, ICON_SPEED},     --T1 Chant of Armored Speed

        {445392, 223710, 7382, ICON_AVOIDANCE},     --T3 Whisper of Armored Avoidance
        {445392, 223709, 7381, ICON_AVOIDANCE},     --T2 Whisper of Armored Avoidance
        {445392, 223708, 7380, ICON_AVOIDANCE},     --T1 Whisper of Armored Avoidance

        {445374, 223716, 7388, ICON_LEECH},     --T3 Whisper of Armored Leech
        {445374, 223715, 7387, ICON_LEECH},     --T2 Whisper of Armored Leech
        {445374, 223714, 7386, ICON_LEECH},     --T1 Whisper of Armored Leech

        {445376, 223722, 7394, ICON_SPEED},     --T3 Whisper of Armored Speed
        {445376, 223721, 7393, ICON_SPEED},     --T2 Whisper of Armored Speed
        {445376, 223720, 7392, ICON_SPEED},     --T1 Whisper of Armored Speed
    },

    [10] = {    --Hand

    },

    [11] = {     --Finger
        {1236059, 243957, 7967},            --T2 Eyes of the Eagle (crit strike effectiveness)
        {1236059, 243956, 7966},            --T1 Eyes of the Eagle

        {1236074, 243987, 7997},            --T2 Nature's Fury
        {1236074, 243986, 7996},            --T1 Nature's Fury

        {1236088, 244015, 8025},            --T2 Silvermoon's Alacrity
        {1236088, 244014, 8024},            --T1 Silvermoon's Alacrity

        {1236060, 243959, 7969},            --T2 Zul'jin's Mastery
        {1236060, 243958, 7968},            --T1 Zul'jin's Mastery

        {1236089, 244017, 8027},            --T2 Silvermoon's Tenacity
        {1236089, 244016, 8026},            --T1 Silvermoon's Tenacity

        {1236073, 243985, 7995},            --T2 Nature's Wrath
        {1236073, 243984, 7994},            --T1 Nature's Wrath

        {1236058, 243955, 7965},            --T2 Amani Mastery
        {1236058, 243954, 7964},            --T1 Amani Mastery

        {1236087, 244013, 8023},            --T2 Thalassian Versatility
        {1236087, 244012, 8022},            --T1 Thalassian Versatility


        {445394, 223787, 7470},             --T3 Cursed Critical Strike (-Haste, +Crit)
        {445394, 223786, 7469},             --T2 Cursed Critical Strike
        {445394, 223785, 7468},             --T1 Cursed Critical Strike

        {445388, 223790, 7473},             --T3 Cursed Haste (-Versa, +Haste)
        {445388, 223789, 7472},             --T2 Cursed Haste
        {445388, 223788, 7471},             --T1 Cursed Haste

        {445359, 223793, 7479},             --T3 Cursed Mastery (-Crit, +Mastery)
        {445359, 223792, 7478},             --T2 Cursed Mastery
        {445359, 223791, 7477},             --T1 Cursed Mastery

        {445383, 223796, 7476},             --T3 Cursed Versatility (-Mastery, + Versa)
        {445383, 223795, 7475},             --T3 Cursed Versatility
        {445383, 223794, 7474},             --T3 Cursed Versatility

        {445387, 223662, 7334},             --T3 Radiant Critical Strike
        {445387, 223661, 7333},             --T2 Radiant Critical Strike
        {445387, 223660, 7332},             --T1 Radiant Critical Strike

        {445320, 223674, 7340},             --T3 Radiant Haste
        {445320, 223673, 7339},             --T2 Radiant Haste
        {445320, 223672, 7338},             --T1 Radiant Haste

        {445375, 223677, 7346},             --T3 Radiant Mastery
        {445375, 223676, 7345},             --T2 Radiant Mastery
        {445375, 223675, 7344},             --T1 Radiant Mastery

        {445349, 223680, 7352},             --T3 Radiant Versatility
        {445349, 223679, 7351},             --T2 Radiant Versatility
        {445349, 223678, 7350},             --T1 Radiant Versatility

        {445358, 223659, 7331},             --T3 Glimmering Critical Strike
        {445358, 223658, 7330},             --T2 Glimmering Critical Strike
        {445358, 223657, 7329},             --T1 Glimmering Critical Strike

        {445384, 223665, 7337},             --T3 Glimmering Haste
        {445384, 223664, 7336},             --T2 Glimmering Haste
        {445384, 223663, 7335},             --T1 Glimmering Haste

        {445381, 223668, 7343},             --T3 Glimmering Mastery
        {445381, 223667, 7342},             --T2 Glimmering Mastery
        {445381, 223666, 7341},             --T1 Glimmering Mastery

        {445340, 223671, 7349},             --T3 Glimmering Versatility
        {445340, 223670, 7348},             --T2 Glimmering Versatility
        {445340, 223669, 7347},             --T1 Glimmering Versatility
    },

    [15] = {    --Back
        {445386, 223731, 7403, ICON_AVOIDANCE},     --T3 Chant of Winged Grace (Avoidance, Fall Damage Reduction)
        {445386, 223730, 7402, ICON_AVOIDANCE},     --T3 Chant of Winged Grace
        {445386, 223729, 7401, ICON_AVOIDANCE},     --T3 Chant of Winged Grace

        {445393, 223737, 7409, ICON_LEECH},     --T3 Chant of Leeching Fangs (Leech, HP Regen)
        {445393, 223736, 7408, ICON_LEECH},     --T2 Chant of Leeching Fangs
        {445393, 223735, 7407, ICON_LEECH},     --T1 Chant of Leeching Fangs

        {445389, 223800, 7415, ICON_SPEED},     --T3 Chant of Burrowing Rapidity (Speed, Hearthstone CD)
        {445389, 223799, 7414, ICON_SPEED},     --T2 Chant of Burrowing Rapidity
        {445389, 223798, 7413, ICON_SPEED},     --T1 Chant of Burrowing Rapidity

        {445344, 223728, 7400, ICON_AVOIDANCE},     --T3 Whisper of Silken Avoidance
        {445344, 223727, 7399, ICON_AVOIDANCE},     --T2 Whisper of Silken Avoidance
        {445344, 223726, 7398, ICON_AVOIDANCE},     --T1 Whisper of Silken Avoidance

        {445348, 223734, 7406, ICON_LEECH},     --T3 Whisper of Silken Leech
        {445348, 223733, 7405, ICON_LEECH},     --T2 Whisper of Silken Leech
        {445348, 223732, 7404, ICON_LEECH},     --T1 Whisper of Silken Leech

        {445373, 223740, 7412, ICON_SPEED},     --T3 Whisper of Silken Speed
        {445373, 223739, 7411, ICON_SPEED},     --T2 Whisper of Silken Speed
        {445373, 223738, 7410, ICON_SPEED},     --T1 Whisper of Silken Speed
    },

    [16] = {    --Weapon
        {1236095, 244029, 8039, 4913234},    --T2 Acuity of the Ren'dorei
        {1236095, 244028, 8038, 4913234},    --T1 Acuity of the Ren'dorei

        {1236094, 244027, 8037, 526578},    --T2 Flames of the Sin'dorei
        {1236094, 244026, 8036, 526578},    --T1 Flames of the Sin'dorei

        {1236065, 243969, 7979, 132140},    --T2 Strength of Halazzi
        {1236065, 243968, 7978, 132140},    --T1 Strength of Halazzi

        {1236080, 243999, 8009, 1769069},    --T2 Worldsoul Aegis
        {1236080, 243998, 8008, 1769069},    --T1 Worldsoul Aegis

        {1236079, 243997, 8007, 2065602},    --T2 Worldsoul Cradle
        {1236079, 243996, 8006, 2065602},    --T1 Worldsoul Cradle

        {1236066, 243971, 7981, 6119038},    --T2 Jan'alai's Precision
        {1236066, 243970, 7980, 6119038},    --T1 Jan'alai's Precision

        {1236067, 243973, 7983, 236310},    --T2 Berserker's Rage
        {1236067, 243972, 7982, 236310},    --T1 Berserker's Rage

        {1236097, 244031, 8041, 1391778},    --T2 Arcane Mastery
        {1236097, 244030, 8040, 1391778},    --T1 Arcane Mastery

        {1236081, 244001, 8011, 2065559},    --T2 Worldsoul Tenacity
        {1236081, 244000, 8010, 2065559},    --T1 Worldsoul Tenacity

        {1262300, 257748, 8613},    --T2 Smuggler's Lynxeye
        {1262297, 257747, 8612},    --T1 Smuggler's Lynxeye

        {1262344, 257746, 8615},    --T2 Farstrider's Hawkeye
        {1262341, 257745, 8614},    --T1 Farstrider's Hawkeye


        {445331, 223775, 7451, 1029585},    --T3 Authority of Air (Absorb)
        {445331, 223774, 7450, 1029585},    --T2 Authority of Air
        {445331, 223773, 7449, 1029585},    --T1 Authority of Air

        {445403, 223778, 7454, 135917},     --T3 Authority of Fiery Resolve (Heal)
        {445403, 223777, 7453, 135917},     --T2 Authority of Fiery Resolve
        {445403, 223776, 7452, 135917},     --T1 Authority of Fiery Resolve

        {445339, 223781, 7463, 5764908},    --T3 Authority of Radiant Power (DMG, Primary Stat)
        {445339, 223780, 7462, 5764908},    --T2 Authority of Radiant Power
        {445339, 223779, 7461, 5764908},    --T1 Authority of Radiant Power

        {445336, 223771, 7457, 136111},     --T3 Authority of Storms (AoE DMG)
        {445336, 223770, 7456, 136111},     --T2 Authority of Storms
        {445336, 223769, 7455, 136111},     --T1 Authority of Storms

        {445341, 223783, 7460, 136160},     --T3 Authority of the Depths (Dot)
        {445341, 223782, 7459, 136160},     --T2 Authority of the Depths
        {445341, 223781, 7458, 136160},     --T1 Authority of the Depths

        {445379, 223759, 7439, 1016352},    --T3 Council's Guile (Crit)
        {445379, 223758, 7438, 1016352},    --T2 Council's Guile
        {445379, 223757, 7437, 1016352},    --T1 Council's Guile

        {445351, 223768, 7448, 237427},     --T3 Oathsworn's Tenacity (Versatility)
        {445351, 223767, 7447, 237427},     --T2 Oathsworn's Tenacity
        {445351, 223766, 7446, 237427},     --T1 Oathsworn's Tenacity

        {445385, 223765, 7445, 134464},     --T3 Stonebound Artistry (Mastery)
        {445385, 223764, 7444, 134464},     --T2 Stonebound Artistry
        {445385, 223763, 7443, 134464},     --T1 Stonebound Artistry

        {445317, 223762, 7442, 463562},     --T3 Stormrider's Fury (Haste)
        {445317, 223761, 7441, 463562},     --T2 Stormrider's Fury
        {445317, 223760, 7440, 463562},     --T1 Stormrider's Fury

        --Scopes
        --{386154, 198318, 6528, 4548899, 3},    --High Intensity Thermal Scanner T3
    },
};


local DataProvider = {};
addon.EnchantDataProvider = DataProvider;

DataProvider.filteredData = {};

local subset = enchantData[11];
local LAST_SLOT_ID = -1;

function DataProvider:SetSubset(slotID)
    if slotID == 12 then
        slotID = 11;
    elseif slotID == 14 then
        slotID = 13;
    elseif slotID == 17 then
        slotID = 16;
    end
    subset = enchantData[slotID] or {};

    if subset and #subset > 0 then
        local categoryChanged = slotID ~= LAST_SLOT_ID;
        LAST_SLOT_ID = slotID;
        return true, categoryChanged
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


local TooltipLines = {
    Generic = {3, 4, 5},
};

function DataProvider:GetItemTooltipLines(itemID)
    return TooltipLines.Generic
end
