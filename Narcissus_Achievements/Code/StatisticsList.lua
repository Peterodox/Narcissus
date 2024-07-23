local _, addon = ...
local PinUtil = addon.PinUtil;

local type = type;

local list = {};    --Data on the bottom


local STAT_CATERGORY_ID = -2;

local isBossCard = {};

local isCustomCategory = {
    [12080000] = true,   --Reserved for Narcissus usage
    --Scroll to bottom to see Dungeons & Raids
};

local bossData = {};

local function IsBossCard(achievementID)
    return isBossCard[achievementID]
end

local function GetBossData(achievementID)
    return bossData[achievementID]
end


local GetCategoryNumAchievements = GetCategoryNumAchievements;

local function GetCustomCategoryNumAchievements(categoryID, includeAll)
    if categoryID then
        if categoryID == STAT_CATERGORY_ID then
            local numPinned = PinUtil:GetTotal();
            return numPinned, numPinned, 0
        else
            if list[categoryID] then
                local numCategory = #list[categoryID];
                return numCategory, numCategory, 0
            else
                return GetCategoryNumAchievements(categoryID, includeAll);
            end
        end
    end
end


local GetAchievementInfo = GetAchievementInfo;

local function GetStatisticInfo(id, index)
    if index then
        if id == STAT_CATERGORY_ID then
            return PinUtil:GetID(index);
        end
        if isCustomCategory[id] then
            if list[id][index] then
                if type(list[id][index]) == "table" then
                    return list[id][index][1][1];
                else
                    return list[id][index];
                end
            end
        else
            return GetAchievementInfo(id, index)
        end
    else
        return GetAchievementInfo(id, index)
    end
end

addon.IsBossCard = IsBossCard;
addon.GetBossData = GetBossData;
addon.GetCustomCategoryNumAchievements = GetCustomCategoryNumAchievements;
addon.GetStatisticInfo = GetStatisticInfo;




--Data--
local difficultyTypes = {
    [4] = {"LFR", "Normal", "Heroic", "Mythic"},
    [3] = {"Normal", "Heroic", "Mythic"},
    [2] = {"Normal", "Heroic"},
    [1] = {"Normal"},

    [20] = {"All"},     --Stats in Normal&Heroic are combined in BC
    [22] = {"Heroic", "Mythic"},

    [32] = {"10N", "25N"},

    [90] = {"LFR"},
    [91] = {"Normal"},
    [92] = {"Heroic"},
    [93] = {"Mythic"},

    [54] = {"10N", "25N", "10H", "25H"},
    [56] = {"10H", "25H"},      --Heroic Only Bosses: Sinestra, Ra-den
    [57] = {"LFR", "Flexible"}, --Siege of Orgrimmar Flexible Mode
    
}

addon.difficultyTypes = difficultyTypes;


---- Raid InstanceID --
local raidInstanceID = {
    1190, 1193, 1195,
    1031, 1176, 1177, 1179, 1180,
    768, 786, 861, 875, 946,
    477, 457, 669,
    317, 330, 320, 362, 369,
    75, 73, 74, 72, 78, 187,
    754, 753, 759, 757, 284, 758,
    --756, 
}

local isInstanceRaid = {};

for _, id in pairs(raidInstanceID) do
    isInstanceRaid[id] = true;
end

raidInstanceID = nil;

local function IsRaid(instanceID)
    return isInstanceRaid[instanceID]
end

addon.IsRaid = IsRaid;


---- Faction-Specific Entries ----
local factionData;

if UnitFactionGroup("player") == "Alliance" then    --After  PLAYER_ENTERING_WORLD
    factionData = {
        bd1 = { {13328, 13329, 13330, 13331}, 4, 2484339, 1176},        --Battle of Dazar'alor Boss #1
        bd2 = { {13349, 13350, 13351, 13353}, 4, 2484336, 1176},        --Battle of Dazar'alor Boss #2 Jadefire Master
        bd3 = { {13344, 13346, 13347, 13348}, 4, 2484333, 1176},        --Grong the Revenant
    }

else
    factionData = {
        bd1 = { {13328, 13329, 13330, 13331}, 4, 2484330, 1176},        --Battle of Dazar'alor Boss #1
        bd2 = { {13332, 13333, 13334, 13336}, 4, 2484332, 1176},        --Grong
        bd3 = { {13354, 13355, 13356, 13357}, 4, 2484336, 1176},        --Battle of Dazar'alor Boss #3

    }
end


---- Shared Entries ----
--[categoryID] = { {achievementIDs}, difficultyType, icon, instanceID(optional) }

list[15430] = {
    --Dungeons & Raids - Shadowlands 15430
    { {14387, 14388, 14389}, 3, 3601564, 1188},    --DeOtherSide
    { {14390, 14391, 14392}, 3, 3601530, 1185},    --Atonement
    { {14393, 14394, 14395}, 3, 3601534, 1184},    --Mists
    { {14396, 14397, 14398}, 3, 3601539, 1183},    --Plaguefall
    { {14201, 14202, 14203}, 3, 3601542, 1189},   --Sanguine
    { {14399, 14400, 14401}, 3, 3601548, 1186},   --SpiresOfAscension
    { {14402, 14403, 14404}, 3, 3601558, 1182},   --NecroticWake
    { {14405, 14406, 14407}, 3, 3601554, 1187},   --Theater of Pain
    { {15168}, 1, 3601562, 1194},   --Tazavesh Veiled Market

    -1190, --Castle Nathria
    { {14422, 14419, 14420, 14421}, 4, 3614368, 1190},    --Shriekwing
    { {14426, 14423, 14424, 14425}, 4, 3614359, 1190},    --Huntsman Altimor
    { {14430, 14427, 14428, 14429}, 4, 3614363, 1190},    --Hungering Destroyer
    { {14434, 14431, 14432, 14433}, 4, 3614360, 1190},    --Artificer Xy'mox
    { {14438, 14435, 14436, 14437}, 4, 3614365, 1190},    --Sun King
    { {14442, 14439, 14440, 14441}, 4, 3614366, 1190},    --Lady Inerva Darkvein
    { {14446, 14443, 14444, 14445}, 4, 3614367, 1190},    --Council of Blood
    { {14450, 14447, 14448, 14449}, 4, 3614368, 1190},    --Sludgefist
    { {14454, 14451, 14452, 14453}, 4, 3614362, 1190},    --Stone Legion Generals
    { {14458, 14455, 14456, 14457}, 4, 3670321, 1190},    --Sire Denathrius

    -1193,  --Sanctum Of Domination
    {{15136, 15137, 15138, 15139}, 4, 4062739, 1193},    --Tarragrue
    {{15140, 15141, 15142, 15143}, 4, 4069937, 1193},    --Eye of Jailor
    {{15144, 15145, 15146, 15147}, 4, 4062741, 1193},    --The Nine
    {{15152, 15153, 15154, 15155}, 4, 4062737, 1193},    --Soulrender Dormazain
    {{15148, 15149, 15150, 15151}, 4, 4062736, 1193},    --Remnant of Ner'zhul
    {{15156, 15157, 15158, 15159}, 4, 4062735, 1193},    --Painsmith Raznal
    {{15160, 15161, 15162, 15163}, 4, 4062733, 1193},    --Guardian of the First Ones
    {{15164, 15165, 15166, 15167}, 4, 4062732, 1193},    --Fatescribe Roh-Kalo
    {{15169, 15170, 15171, 15172}, 4, 4062734, 1193},    --Kel'Thuzad
    {{15173, 15174, 15175, 15176}, 4, 4062738, 1193},    --Sylvanas

    -1195,  --Sepulcher of the First Ones
    {{15424, 15425, 15426, 15427}, 4, 4254081, 1195},    --Vigilant Guardian
    {{15428, 15429, 15430, 15431}, 4, 4254082, 1195},    --Skolex
    {{15432, 15433, 15434, 15435}, 4, 4254076, 1195},    --Artificer Xy'mox2
    {{15436, 15437, 15438, 15439}, 4, 4254078, 1195},    --Dausegne
    {{15440, 15441, 15442, 15443}, 4, 4254087, 1195},    --Prototype Pantheon
    {{15444, 15445, 15446, 15447}, 4, 4254089, 1195},    --Lihuvim
    {{15448, 15449, 15450, 15451}, 4, 4254083, 1195},    --Halondrus
    {{15452, 15453, 15454, 15455}, 4, 4254075, 1195},    --Anduin
    {{15456, 15457, 15458, 15459}, 4, 4254079, 1195},    --Lords of Dread
    {{15460, 15461, 15462, 15463}, 4, 4254077, 1195},    --Rygelon
    {{15464, 15465, 15466, 15467}, 4, 4254080, 1195},    --The Jailer
};

list[15409] = {
    --Dungeons & Raids - BFA
    { {12720, 12748, 12749}, 3, 2011155, 968},      --Atal'Dazar
    { {12750, 12751, 12752}, 3, 2011116, 1001},     --Freehold
    { {12763}, 93, 2011122, 1041},                  --Kings' Rest
    { {12766, 12767, 12768}, 3, 2011153, 1036},     --Shrine of the Storm
    { {12773}, 93, 2011139, 1023},                  --Siege of Boralus
    { {12774, 12775, 12776}, 3, 2011106, 1030},     --Avatar of Sethraliss
    { {12777, 12778, 12779}, 3, 2011128, 1012},     --Motherlode
    { {12728, 12729, 12745}, 3, 2011150, 1022},     --Underrot
    { {12780, 12781, 12782}, 3, 2011130, 1002},     --Tol Dagor
    { {12783, 12784, 12785}, 3, 2011114, 1021},     --Waycrest Manor
    { {13620}, 93, 2620862},    --King Mechagon, Mythic Operation: Mechagon
    { {14056}, 92, 2620862},    --King Mechagon, Heoric Operation: Workshop
    { {14057}, 92, 2574427},    --HK8 Opression, Heoric Operation: Junkyard
    
    -1031,
    { {12786, 12787, 12788, 12789}, 4, 2032226, 1031},      --Taloc
    { {12790, 12791, 12792, 12793}, 4, 2032224, 1031},      --MOTHER
    { {12794, 12795, 12796, 12797}, 4, 2032222, 1031},      --Fetid Devourer
    { {12798, 12799, 12800, 12801}, 4, 2032227, 1031},      --Zek'voz Herald of N'Zoth
    { {12802, 12803, 12804, 12805}, 4, 2032221, 1031},      --Vectis
    { {12808, 12809, 12810, 12811}, 4, 2032228, 1031},      --Zul Reborn
    { {12813, 12814, 12815, 12816}, 4, 2032225, 1031},      --Mythrax
    { {12817, 12818, 12819, 12820}, 4, 2032223, 1031},      --G'huun

    -1176,
    factionData.bd1,
    factionData.bd2,
    factionData.bd3,
    { {13358, 13359, 13361, 13362}, 4, 2484341, 1176},      --Opulence
    { {13363, 13364, 13365, 13366}, 4, 2484335, 1176},      --Conclave of the Chosen
    { {13367, 13368, 13369, 13370}, 4, 2484340, 1176},      --King Rastakhan
    { {13371, 13372, 13373, 13374}, 4, 2484337, 1176},      --Mekkatorque
    { {13375, 13376, 13377, 13378}, 4, 2484329, 1176},      --Stormwall Blockade
    { {13379, 13380, 13381, 13382}, 4, 2484334, 1176},      --Jaina

    -1177,
    { {13404, 13405, 13406, 13407}, 4, 2486646, 1177},      --Restless Cabal
    { {13408, 13411, 13412, 13413}, 4, 2486645, 1177},      --Uu'nat Harbinger of the Void

    -1179,
    { {13587, 13588, 13589, 13590}, 4, 3012071, 1179},      --Abyssal Commander Sivara
    { {13591, 13592, 13593, 13594}, 4, 3012075, 1179},      --Blackwater Behemoth
    { {13595, 13596, 13597, 13598}, 4, 3012074, 1179},      --Radiance of Azshara
    { {13600, 13601, 13602, 13603}, 4, 3012067, 1179},      --Lady Ashvane
    { {13604, 13605, 13606, 13607}, 4, 3012073, 1179},      --Orgozoa
    { {13608, 13609, 13610, 13611}, 4, 3012069, 1179},      --The Queen's Court
    { {13612, 13613, 13614, 13615}, 4, 3012070, 1179},      --Za'qul
    { {13616, 13617, 13618, 13619}, 4, 3012068, 1179},      --Azshara

    -1180,
    { {14078, 14079, 14080, 14082}, 4, 3194615, 1180},      --Wrathion
    { {14089, 14091, 14093, 14094}, 4, 3194608, 1180},      --Maut
    { {14095, 14096, 14097, 14098}, 4, 3194613, 1180},      --The Prophet Skitra
    { {14101, 14102, 14104, 14105}, 4, 3194616, 1180},      --Dark Inquisitor Xanesh
    { {14107, 14108, 14109, 14110}, 4, 3194606, 1180},      --The Hivemind
    { {14111, 14112, 14114, 14115}, 4, 3194612, 1180},      --Shad'har the Insatiable
    { {14117, 14118, 14119, 14120}, 4, 3194605, 1180},      --Drest'agath
    { {14207, 14208, 14210, 14211}, 4, 3194607, 1180},      --Il'gynoth, Corruption Reborn
    { {14123, 14124, 14125, 14126}, 4, 3194614, 1180},      --Vexiona
    { {14127, 14128, 14129, 14130}, 4, 3194611, 1180},      --Ra-den the Despoiled
    { {14131, 14132, 14133, 14134}, 4, 3194604, 1180},      --Carapace of N'Zoth
    { {14135, 14136, 14137, 14138}, 4, 3194610, 1180},      --N'Zoth the Corruptor
};

list[15264] = {
    --Dungeons & Raids - Legion
    { {10878, 10879, 10880}, 3, 1417426, 716},      --Wrath of Azshara
    { {10881, 10882, 10883}, 3, 1417425, 762},      --Shade of Xavius
    { {10884, 10885, 10886}, 3, 1417429, 767},      --Dargrul Neltharion's Lair
    { {10887, 10888, 10889}, 3, 1417427, 721},      --Odyn
    { {10890, 10891, 10892}, 3, 1417432, 777},      --Fel Lord Betrug Violet Hold
    { {10893, 10894, 10895}, 3, 1417432, 777},      --Sael'orn Violet Hold
    { {10896, 10897, 10898}, 3, 1417431, 707},      --Cordana
    { {10899, 10900, 10901}, 3, 1417423, 740},      --Kur'talos Ravencrest
    { {10902, 10903, 10904}, 3, 1417428, 727},      --Helya Maw of Souls
    { {10907}, 93, 1417430, 726},       --Advisor Vandros Arcway
    { {10910}, 93, 1417424, 800},       --Advisor Melandrius Court of Stars
    { {12610, 12611}, 22, 1378283, 900},      --Mephistroth Cathedral of Eternal Light
    { {12612, 12613}, 22, 1711336, 945},      --L'ura Seat of the Triumvirate
    { {11406}, 93, 1530372, 860},       --Viz'aduum Karazhan

    -768,
    { {10911, 10912, 10913, 10914}, 4, 1413869, 768},      --Nythendra
    { {10920, 10921, 10922, 10923}, 4, 1413867, 768},      --Elerethe Renferal
    { {10924, 10925, 10926, 10927}, 4, 1413868, 768},      --Ill'gynoth
    { {10915, 10916, 10917, 10919}, 4, 1413870, 768},      --Ursoc
    { {10928, 10929, 10930, 10931}, 4, 1413866, 768},      --Dragons of Nightmare
    { {10932, 10933, 10934, 10935}, 4, 1413865, 768},      --Cenarius
    { {10936, 10937, 10938, 10939}, 4, 1413871, 768},      --Xavius

    -861,
    { {11407, 11408, 11409, 11410}, 4, 1530371, 861},      --Odyn
    { {11411, 11412, 11413, 11414}, 4, 1530369, 861},      --Guarm
    { {11415, 11416, 11417, 11418}, 4, 1530370, 861},      --Helya

    -786,
    { {10940, 10941, 10942, 10943}, 4, 1413859, 786},      --Skoryron
    { {10944, 10945, 10946, 10947}, 4, 1413854, 786},      --Chronomatic Anomaly
    { {10948, 10949, 10950, 10951}, 4, 1413863, 786},      --Trillax
    { {10952, 10953, 10954, 10955}, 4, 1413860, 786},      --Spellblade Aluriel
    { {10956, 10957, 10959, 10960}, 4, 1413861, 786},      --Staraugur Etraeus
    { {10961, 10962, 10963, 10964}, 4, 1413857, 786},      --Highbotanist Telam
    { {10965, 10966, 10967, 10968}, 4, 1413862, 786},      --Tichondrius
    { {10969, 10970, 10971, 10972}, 4, 1413858, 786},      --Krosus
    { {10973, 10974, 10975, 10976}, 4, 1413855, 786},      --Grand Magistrix Elisande
    { {10977, 10978, 10979, 10980}, 4, 1413856, 786},      --Gul'dan

    -875,
    { {11877, 11878, 11879, 11880}, 4, 1546414, 875},      --Goroth
    { {11881, 11882, 11883, 11884}, 4, 1546411, 875},      --Demonic Inquisition
    { {11885, 11886, 11887, 11888}, 4, 1546413, 875},      --Harjatan
    { {11889, 11890, 11891, 11892}, 4, 1568516, 875},      --Sisters of the Moon
    { {11893, 11894, 11895, 11896}, 4, 1546415, 875},      --Mistress Sassz'ine
    { {11897, 11898, 11899, 11900}, 4, 1546416, 875},      --The Desolate Host
    { {11901, 11902, 11903, 11904}, 4, 1622132, 875},      --Maiden of Vigilance
    { {11905, 11906, 11907, 11908}, 4, 1546417, 875},      --Fallen Avatar
    { {11909, 11910, 11911, 11912}, 4, 1546412, 875},      --Kil'jaedan

    -946,
    { {12117, 11954, 11955, 11956}, 4, 1711328, 946},      --Garothi Worldbreaker
    { {12118, 11957, 11958, 11959}, 4, 1711330, 946},      --Hounds of Sargeras
    { {12119, 11960, 11961, 11962}, 4, 1711331, 946},      --Antoran High Command
    { {12120, 11963, 11964, 11965}, 4, 1711329, 946},      --Portal Keeper Hasabel
    { {12121, 11966, 11967, 11968}, 4, 1711327, 946},      --Eonar
    { {12122, 11969, 11970, 11971}, 4, 1711326, 946},      --Imonar the Soulhunter
    { {12123, 11972, 11973, 11974}, 4, 1711333, 946},      --Kin'garoth
    { {12124, 11975, 11976, 11977}, 4, 1711334, 946},      --Varimathras
    { {12125, 11978, 11979, 11980}, 4, 1711332, 946},      --The Coven of Shivarra
    { {12126, 11981, 11982, 11983}, 4, 1711325, 946},      --Aggramar
    { {12127, 11984, 11985, 11986}, 4, 1711335, 946},      --Argus the Unmaker
};

list[15233] = {
    --Dungeons & Raids - WoD
    { {9258, 9259, 10192}, 3, 1002599, 385},      --Gug'rokk Bloodmaul Slag Mines
    { {9260, 9261, 10193}, 3, 1003154, 558},      --Skulloc Iron Docks
    { {9262, 9263, 10194}, 3, 1002597, 547},      --Teron'gor Auchindoun
    { {9266, 9267, 10195}, 3, 1002596, 476},      --High Sage Viryx Skyreach
    { {9268, 9269, 10196}, 3, 1002598, 536},      --Skylord Tovra Grimrail Depot
    { {9271, 9272, 10197}, 3, 967517, 556},       --Yalnu
    { {9273, 9274, 10198}, 3, 1002600, 537},      --Ner'zhul Shadowmoon Burial Grounds
    { {9275, 9276, 10199}, 3, 1002601, 559},      --Warlord Zaela Upper Blackrock Spire

    { {9277}, 91, 1058939},         --Drov the Ruiner
    { {9278}, 91, 254105},          --Tarlna the Ageless
    { {9279}, 91, 840662},          --Rukhmar
    { {10200}, 92, 615103},         --Supreme Lord Kazzak

    -477,
    { {9280, 9282, 9284, 9285}, 4, 1005701, 477},      --Kargath Bladefist Highmaul
    { {9286, 9287, 9288, 9289}, 4, 1006454, 477},      --The Butcher
    { {9290, 9292, 9293, 9294}, 4, 1006111, 477},      --Tectus
    { {9295, 9297, 9298, 9300}, 4, 1019378, 477},      --Brackenspore
    { {9301, 9302, 9303, 9304}, 4, 1019377, 477},      --Twin Ogron
    { {9306, 9308, 9310, 9311}, 4, 1006455, 477},      --Ko'ragh
    { {9312, 9313, 9314, 9315}, 4, 1030796, 477},      --Imperator Mar'gok

    -457,
    { {9316, 9317, 9318, 9319}, 4, 1003742, 457},      --Gruul
    { {9320, 9321, 9322, 9323}, 4, 1003743, 457},      --Oregorger
    { {9324, 9327, 9328, 9329}, 4, 1035504, 457},      --Hans'gar and Franzok
    { {9330, 9331, 9332, 9333}, 4, 1004899, 457},      --Flamebender Ka'graz
    { {9334, 9336, 9337, 9338}, 4, 1004898, 457},      --Beastlord Darmac
    { {9339, 9340, 9341, 9342}, 4, 1006456, 457},      --Operator Thogar
    { {9343, 9349, 9351, 9353}, 4, 1003741, 457},      --Blast Furnace
    { {9354, 9355, 9356, 9357}, 4, 1030797, 457},      --Kromog
    { {9358, 9359, 9360, 9361}, 4, 1006112, 457},      --Iron Maidens
    { {9362, 9363, 9364, 9365}, 4, 1005700, 457},      --Blackhand

    -669,
    { {10201, 10202, 10203, 10204}, 4, 1113440, 669},      --Hellfire Assault
    { {10205, 10206, 10207, 10208}, 4, 1113436, 669},      --Iron Reaver
    { {10209, 10210, 10211, 10212}, 4, 1113434, 669},      --Kormrok
    { {10213, 10214, 10215, 10216}, 4, 1113435, 669},      --Hellfire High Council
    { {10217, 10218, 10219, 10220}, 4, 1113438, 669},      --Kilrogg Deadeye
    { {10221, 10222, 10223, 10224}, 4, 1113437, 669},      --Gorefiend
    { {10225, 10226, 10227, 10228}, 4, 1113432, 669},      --Shadow-Lord Iskar
    { {10229, 10230, 10231, 10232}, 4, 1113441, 669},      --Socrethar the Eternal
    { {10233, 10234, 10235, 10236}, 4, 1113433, 669},      --Fel Lord Zakuun
    { {10237, 10238, 10239, 10240}, 4, 1113442, 669},      --Xhul'horac
    { {10241, 10242, 10243, 10244}, 4, 1113430, 669},      --Tyrant Velhari
    { {10245, 10246, 10247, 10248}, 4, 1113439, 669},      --Mannoroth
    { {10249, 10250, 10251, 10252}, 4, 1113431, 669},      --Archimonde
};

list[15164] = {
    --Dungeons & Raids - Pandaria
    { {6675, 6676}, 2, 603529, 313},        --Sha of Doubt
    { {6677, 6679}, 2, 594272, 302},        --Yan-zhu the Uncasked
    { {6678, 6680}, 2, 615499, 321},        --Xin the Weaponmaster
    { {6681, 6682}, 2, 603795, 312},        --Taran Zhu
    { {6783}, 92, 603962, 303},        --Raigonn Gate of the Setting Sun
    { {6784}, 92, 133154, 311},        --Flameweaver Koegler Scarlet Halls
    { {6785}, 92, 135955, 316},        --High Inquisitor Whitemane Scarlet Monastery
    { {6787}, 92, 135974, 246},        --Darkmaster Gandling Scholomance
    { {6788}, 92, 615986, 313},        --Wing Leader Ner'onok Siege of Niuzao Temple
    { {6989}, 91, 651089},        --Sha of Anger
    { {6990}, 91, 646378},        --Salyis's Warband

    -317,
    { {6983}, 90, 625905, 317},     --Stone Guard Mogu'shan Vaults
    { {6789, 7914, 6790, 7915}, 54, 625905, 317},      --Stone Guard
    { {6984}, 90, 625906, 317},     --Feng the Accursed
    { {6791, 7917, 6792, 7918}, 54, 625906, 317},      --Feng the Accursed
    { {6985}, 90, 625907, 317},     --Gara'jal the Spiritbinder
    { {6793, 7919, 6794, 7920}, 54, 625907, 317},      --Gara'jal the Spiritbinder
    { {6986}, 90, 625908, 317},     --Four Kings
    { {6795, 7921, 6796, 7922}, 54, 625908, 317},      --Four Kings
    { {6987}, 90, 656166, 317},     --Elegon
    { {6797, 7923, 6798, 7924}, 54, 656166, 317},      --Elegon
    { {6988}, 90, 625910, 317},     --Will of the Emperor
    { {6799, 7926, 6800, 7927}, 54, 625910, 317},      --Will of the Emperor

    -330,
    { {6991}, 90, 624007, 330},     --Imperial Vizier Zor'lok Heart of Fear
    { {6801, 7951, 6802, 7953}, 54, 624007, 330},      --Imperial Vizier Zor'lok
    { {6992}, 90, 624008, 330},     --Blade Lord Ta'yak
    { {6803, 7954, 6804, 7955}, 54, 624008, 330},      --Blade Lord Ta'yak
    { {6993}, 90, 624010, 330},     --Garalon
    { {6805, 7956, 6806, 7957}, 54, 624010, 330},      --Garalon
    { {6994}, 90, 624009, 330},     --Wind Lord Mel'jarak
    { {6807, 7958, 6808, 7960}, 54, 624009, 330},      --Wind Lord Mel'jarak
    { {6995}, 90, 624011, 330},     --Amber-Shaper Un'sok
    { {6809, 7961, 6810, 7962}, 54, 624011, 330},      --Amber-Shaper Un'sok
    { {6996}, 90, 624012, 330},     --Grand Empress Shek'zeer
    { {6811, 7963, 6812, 7964}, 54, 624012, 330},      --Grand Empress Shek'zeer

    -320,
    { {6997}, 90, 627682, 320},     --Protectors of the Endless  Terrace of Endless Spring
    { {6813, 7965, 6814, 7966}, 54, 627682, 320},      --Protectors of the Endless
    { {6998}, 90, 627683, 320},     --Tsulong
    { {6815, 7967, 6816, 7968}, 54, 627683, 320},      --Tsulong
    { {6999}, 90, 627684, 320},     --Lei Shi
    { {6817, 7969, 6818, 7970}, 54, 627684, 320},      --Lei Shi
    { {7000}, 90, 627685, 320},     --Sha of Fear
    { {6819, 7971, 6820, 7972}, 54, 627685, 320},      --Sha of Fear

    { {8146}, 91, 624007},     --Nalak
    { {8147}, 91, 797328},     --Oondasta

    -362,
    { {8141}, 90, 798060, 362},     --Jin'rokh the Breaker Throne of Thunder
    { {8142, 8143, 8144, 8145}, 54, 798060, 362},      --Jin'rokh the Breaker
    { {8148}, 90, 798552, 362},     --Horridon
    { {8149, 8150, 8151, 8152}, 54, 798552, 362},      --Horridon
    { {8153}, 90, 798551, 362},     --Council of Elders
    { {8154, 8155, 8156, 8157}, 54, 798551, 362},      --Council of Elders
    { {8158}, 90, 798557, 362},     --Tortos
    { {8159, 8160, 8162, 8161}, 54, 798557, 362},      --Tortos
    { {8163}, 90, 800829, 362},     --Megaera
    { {8164, 8165, 8166, 8167}, 54, 800829, 362},      --Megaera
    8291,   --Gastropod meals provided
    { {8168}, 90, 800879, 362},     --Jikun
    { {8169, 8170, 8171, 8172}, 54, 800879, 362},      --Jikun
    { {8173}, 90, 800992, 362},     --Durumu the Forgotten
    { {8174, 8175, 8176, 8177}, 54, 800992, 362},      --Durumu the Forgotten
    { {8178}, 90, 801131, 362},     --Primordius
    { {8179, 8182, 8181, 8180}, 54, 801131, 362},      --Primordius
    { {8183}, 90, 839610, 362},     --Dark Animus
    { {8184, 8185, 8186, 8187}, 54, 839610, 362},      --Dark Animus
    { {8188}, 90, 839261, 362},     --Iron Qon
    { {8189, 8190, 8191, 8192}, 54, 839261, 362},      --Iron Qon
    { {8193}, 90, 839399, 362},     --Twin Consorts
    { {8194, 8195, 8196, 8197}, 54, 839399, 362},      --Twin Consorts
    { {8198}, 90, 840303, 362},     --Lei Shen
    { {8199, 8200, 8202, 8201}, 54, 840303, 362},      --Lei Shen

    { {8203, 8256}, 56, 800880, 362},      --Ra-den

    { {8544}, 92, 877514},     --Chi-ji
    { {8545}, 92, 900317},     --Niuzao
    { {8546}, 92, 877410},     --Xuen
    { {8547}, 92, 877408},     --Yu'on
    { {8548}, 92, 518970},     --Ordos

    -369,
    { {8549, 8550}, 57, 896623, 369},     --Immerseus
    { {8551, 8552, 8553, 8554}, 54, 896623, 369},      --Immerseus
    { {8555, 8556}, 57, 897027, 369},     --Fallen Protectors
    { {8557, 8558, 8559, 8560}, 54, 897027, 369},      --Fallen Protectors
    { {8561, 8562}, 57, 897064, 369},     --Norushen
    { {8563, 8564, 8565, 8566}, 54, 897064, 369},      --Norushen
    { {8567, 8568}, 57, 651086, 369},     --Sha of Pride
    { {8569, 8570, 8571, 8573}, 54, 651086, 369},      --Norushen
    { {8574, 8575}, 57, 896665, 369},     --Galakras
    { {8576, 8577, 8578, 8579}, 54, 896665, 369},      --Galakras
    { {8580, 8581}, 57, 896624, 369},     --Iron Juggernaut
    { {8582, 8583, 8584, 8585}, 54, 896624, 369},      --Iron Juggernaut
    { {8586, 8587}, 57, 897028, 369},     --Dark Shaman
    { {8588, 8589, 8590, 8591}, 54, 897028, 369},      --DKor'kron Dark Shaman
    { {8593, 8594}, 57, 897144, 369},     --General Nazgrim
    { {8595, 8596, 8597, 8598}, 54, 897144, 369},      --General Nazgrim
    { {8599, 8600}, 57, 897029, 369},     --Malkorok
    { {8601, 8602, 8603, 8604}, 54, 897029, 369},      --Malkorok
    { {8605, 8606}, 57, 897406, 369},     --Spoils of Pandaria
    { {8608, 8609, 8610, 8612}, 54, 897406, 369},      --Spoils of Pandaria
    { {8614, 8615}, 57, 896625, 369},     --Thok the Bloodthristy
    { {8616, 8617, 8618, 8619}, 54, 896625, 369},      --Thok the Bloodthristy
    { {8620, 8621}, 57, 897633, 369},     --Siegecrafter Blackfuse
    { {8622, 8623, 8624, 8625}, 54, 897633, 369},      --Siegecrafter Blackfuse
    { {8626, 8627}, 57, 897697, 369},     --Paragons of the Klaxxi
    { {8628, 8629, 8630, 8631}, 54, 897697, 369},      --Paragons of the Klaxxi
    { {8632, 8634}, 57, 896622, 369},     --Garrosh Hellscream
    { {8635, 8636, 8637, 8638}, 54, 896622, 369},      --Garrosh Hellscream
};

list[15096] = {
    --Dungeons & Raids - Cataclysm
    { {5724, 5725}, 2, 409594, 66},    --Ascendant Lord Obsidius
    { {5726, 5727}, 2, 409600, 65},    --Ozumat
    { {5728, 5729}, 2, 409595, 67},    --High Priestess Azil Stonecore
    { {5730, 5731}, 2, 409599, 68},    --Asaad Vortext Pinnacle
    { {5732, 5733}, 2, 409596, 71},    --Erudax Grim Batol
    { {5735, 5736}, 2, 409597, 70},    --Rajh Halls of Origination
    { {5736, 5737}, 2, 409598, 69},    --Siamat Lost City of the Tol'vir
    { {5738}, 92, 409594, 63},         --Vanessa VanCleef
    { {5739}, 92, 412514, 64},         --Lord Godfrey
    { {5773}, 92, 515994, 77},         --Daakara Zul'Aman
    { {5774}, 92, 512828, 76},         --Jin'do Zul'Gurub

    -75,
    { {5578}, 91, 236423, 75},         --Argaloth Baradin Hold
    { {5981}, 91, 237298, 75},         --Occu'thar
    { {6170}, 91, 574999, 75},         --Alizabal

    -73,
    5756,   --Death to Elavator
    { {5555, 5556}, 2, 236197, 73},    --Magmaw Blackwing Descent
    { {5557, 5558}, 2, 415046, 73},    --Omnotron
    { {5559, 5560}, 2, 429380, 73},    --Maloriak
    { {5561, 5562}, 2, 426494, 73},    --Atramedes
    { {5564, 5563}, 2, 462337, 73},    --Chimaeron
    { {5565, 5566}, 2, 454028, 73},    --Nefarion

    -72,
    { {5554, 5553}, 2, 432001, 72},    --Halfus Wyrmbreaker Bastion of Twilight
    { {5567, 5568}, 2, 429379, 72},    --Valiona and Theralion
    { {5569, 5570}, 2, 429378, 72},    --Ascendant Council
    { {5572, 5571}, 2, 429376, 72},    --Cho'gall
    { {5573}, 92, 429377, 72},    --Sinestra

    -74,
    { {5575, 5574}, 2, 236154, 74},    --Conclave of Wind
    { {5576, 5577}, 2, 254501, 74},    --Al'Akir

    -78,
    { {5964, 5965}, 2, 524349, 78},    --Beth'tilac Firelands
    { {5966, 5967}, 2, 524350, 78},    --Lord Rhyolith
    { {5968, 5969}, 2, 524351, 78},    --Shannox
    { {5970, 5971}, 2, 512826, 78},    --Alysrazor
    { {5972, 5973}, 2, 515033, 78},    --Baleroc
    { {5974, 5975}, 2, 512827, 78},    --Majordomo Fandral Staghelm
    { {5976, 5977}, 2, 512617, 78},    --Ragnaros

    { {6150}, 92, 298656, 184},    --Murozond End Time
    { {6151}, 92, 574792, 185},    --Mannoroth Well of Eternity
    { {6152}, 92, 574795, 186},    --Archbishop Benedictus Hour of Twilight

    -187,
    { {6153, 6154}, 2, 574789, 187},    --Morchok Dragon Soul
    { {6155, 6156}, 2, 574794, 187},    --Warlord Zon'ozz
    { {6157, 6158}, 2, 574793, 187},    --Yor'sahj the Unsleeping
    { {6159, 6160}, 2, 574787, 187},    --Hagara the Stormbinder
    { {6161, 6162}, 2, 574791, 187},    --Ultraxion
    { {6163, 6164}, 2, 574786, 187},    --Warmaster Blackhorn
    { {6165, 6166}, 2, 574790, 187},    --Spine of Deathwing
    { {6167, 6168}, 2, 574788, 187},    --Deathwing
};

list[14821] = {
    --Dungeons & Raids - Classic
    { {6135}, 91, 135726, 226},     --Lava Guard Gordoth Ragefire Chasm
    { {1091}, 91, 134169, 63},      --Captain Cookie
    { {6136}, 91, 236425, 240},     --Mutanus the Devourer Wailing Caverns
    { {1092}, 91, 412514, 64},      --Lord Godfrey
    { {6137}, 91, 236403, 227},     --Aku'mai Blackfathom Deeps
    { {6138}, 91, 134163, 238},     --Hogger
    { {6139}, 91, 236405, 234},     --Charlga Razorflank Razorfin Kraul
    { {6141}, 91, 236400, 233},     --Razorfen Downs
    { {6140}, 91, 236424, 231},     --Mekgineer Thermaplugg
    { {6786}, 91, 133154, 311},     --Scarlet Halls
    { {1093}, 91, 135955, 316},     --Scarlet Monastery
    { {6142}, 91, 236401, 239},     --Archaedas Uldaman
    { {1094}, 91, 236406, 241},     --Chief Ukorz Sandscalp Zul'Farrak
    { {6143}, 91, 236432, 232},     --Princess Theradras Maraudon
    { {6144}, 91, 236434, 237},     --Eranikus Sunken Temple
    { {1097}, 91, 237511, 236},     --Aurius Rivendare Stratholme
    { {1095}, 91, 236410, 228},     --Dagran Thaurissan Blackrock Depths
    { {6145}, 91, 236429, 229},     --Overlord Wyrmthalak Lower Blackrock Spire
    { {1096}, 91, 254648, 559},     --General Drakkisath Upper Blackrock Spire
    { {6146}, 91, 236695, 230},     --King Gordok Dire Maul
    { {6337}, 91, 236428, 743},     --Ossirian the Unscarred Ruins of Ahn'Qiraj
    { {1098}, 91, 254650, 760},     --Onyxia
    { {1099}, 91, 254652, 741},     --Ragnaros
    { {1100}, 91, 254649, 742},     --Nefarian
    { {1101}, 91, 236407, 744},     --C'Thun
};

list[14822] = {
    --Dungeons & Raids - Buring Crusade
    { {6147}, 20, 236427, 248},     --Hellfire Ramparts
    { {1068}, 20, 236417, 256},     --The Blood Furnace     Keli'dan the Breaker
    { {1078}, 20, 254093, 259},     --The Shattered Halls   Warchief Kargath Bladefist
    { {1071}, 20, 236433, 260},     --Slave Pens        Quagmirran
    { {1072}, 20, 254502, 262},     --Underbog          The Black Stalker
    { {1077}, 20, 236436, 261},     --The Steamvault    Warlord Kalithresh
    { {1073}, 20, 236411, 247},     --Auchenai Crypts   Exarch Maladaar
    { {1074}, 20, 236435, 252},     --Sethekk Halls     Talon King Ikiss
    { {1075}, 20, 254501, 253},     --Shadow Labyrinth  Murmur
    { {1069}, 20, 236426, 250},     --Mana Tombs        Nexus-Prince Shaffar
    { {1079}, 20, 236430, 258},     --The Mechanar      Pathaleon the Calculator
    { {1080}, 20, 236437, 257},     --The Botanica      Warp Splinter
    { {1081}, 20, 236414, 254},     --The Arcatraz      Harbinger Skyriss
    { {1070}, 20, 254647, 251},     --Durnholde Old Hillsbrad Foothills
    { {1076}, 20, 254086, 255},     --Opening of the Dark Portal    Aeonus
    { {1082}, 20, 250117, 249},     --Magister's Terrace

    { {1083}, 91, 254651, 745},     --Karazhan          Prince Malchezaar
    { {1084}, 91, 236438, 77},      --Zul'Aman          Zul'jin

    { {1085}, 91, 236412, 746},     --Gruul's Lair
    { {1086}, 91, 236423, 747},     --Magtheridon's Lair
    { {1087}, 91, 236422, 748},     --Lady Vashj Serpentshrine Cavern
    { {1088}, 91, 236440, 749},     --Kael'thas Sunstrider Tempest Keep The Eye
    { {6148}, 91, 236402, 750},     --Archimonde The Battle for Mount Hyjal
    { {1089}, 91, 236415, 751},     --Illidan Black Temple
    { {1090}, 91, 236418, 752},     --Kil'jaeden Sunwell Plateau
};

list[14823] = {
    --Dungeons & Raids - Lich King
    { {1242, 1504}, 2, 133112, 285},    --Utgarde Keep  Ingvar the Plunderer
    { {1240, 1514}, 2, 236419, 286},    --Utgarde Pinnacle  King Ymiron
    { {1231, 1505}, 2, 298658, 281},    --Nexus Keristrasza
    { {1239, 1513}, 2, 298646, 282},    --Oculus Ley-Guardian Eregos
    { {1232, 1506}, 2, 236467, 272},    --Azjol-Nerub
    { {1233, 1507}, 2, 298654, 271},    --Ahn'kahet: The Old Kingdom
    { {1234, 1508}, 2, 250121, 273},    --Drak'Tharon Keep
    { {1235, 1509}, 2, 298644, 283},    --Violet Hold Cyanigosa
    { {1236, 1510}, 2, 298648, 274},    --Gundrak   Gal'darah
    { {1237, 1511}, 2, 298671, 277},    --Halls of Stone    Sjonnir the Ironshaper
    { {1238, 1512}, 2, 236522, 275},    --Halls of Lightning    Loken
    { {1241, 1515}, 2, 236477, 279},    --The Culling of Stratholme Mal'Ganis

    -754,
    { {1361, 1368}, 32, 135442, 754},    --Anub'Rekhan
    { {1372, 1378}, 32, 136182, 754},    --Gluth
    { {1366, 1379}, 32, 135771, 754},    --Gothik the Harvest
    { {1362, 1380}, 32, 298651, 754},    --Grand Widow Faerlina
    { {1371, 1381}, 32, 136182, 754},    --Grobbulus
    { {1369, 1382}, 32, 298653, 754},    --Heigan the Unclean
    { {1375, 1383}, 32, 298647, 754},    --Four Horsemen
    { {1374, 1384}, 32, 135771, 754},    --Instructor Razuvious
    { {1370, 1385}, 32, 298662, 754},    --Loatheb
    { {1363, 1386}, 32, 298663, 754},    --Maexxna
    { {1365, 1387}, 32, 133781, 754},    --Noth the Plaguebringer
    { {1364, 1367}, 32, 298667, 754},    --Patchwerk
    { {1373, 1388}, 32, 298675, 754},    --Thaddius
    { {1376, 1389}, 32, 254100, 754},    --Sapphiron
    { {1377, 1390}, 32, 254094, 754},    --Kel'Thuzad
    2596,   --Mr.Bigglesworth kills?

    -756,
    { {1391, 1394}, 32, 254096, 756},    --Malygos

    -753,
    { {1753, 1754}, 32, 134449, 753},    --Vault of Archavon    Archavon the Stone Watcher
    { {2870, 3236}, 32, 134452, 753},    --Emalon the Storm Watcher
    { {4074, 4075}, 32, 135829, 753},    --Koralon the Flame Watcher
    { {4657, 4658}, 32, 135847, 753},    --Toravon the Ice Watcher

    -759,
    { {2856, 2872}, 32, 254102, 759},    --Flame Leviathan
    { {2857, 2873}, 32, 298670, 759},   --Razorscale
    { {2858, 2874}, 32, 254092, 759},    --Ignis the Furnace Master
    { {2859, 2884}, 32, 254104, 759},    --XT-002 Deconstructor
    { {2860, 2885}, 32, 254108, 759},    --Assembly of Iron
    { {2861, 2875}, 32, 254095, 759},    --Kologarn
    { {2868, 2882}, 32, 254088, 759},    --Auriaya
    { {2862, 3256}, 32, 254091, 759},    --Hodir
    { {2863, 3257}, 32, 298676, 759},    --Thorim
    { {2864, 3258}, 32, 254089, 759},    --Freya
    { {2865, 2879}, 32, 254097, 759},    --Mimiron
    { {2866, 2880}, 32, 254090, 759},    --General Vezax
    { {2869, 2883}, 32, 458238, 759},    --Yogg-Saron
    { {2867, 2881}, 32, 254087, 759},    --Algalon the Observer

    -284,
    { {4018, 4019}, 2, 626000, 284},   --Hunter Trial of Champion
    { {4048, 4049}, 2, 626001, 284},   --Mage
    { {4050, 4051}, 2, 626005, 284},   --Rogue
    { {4052, 4053}, 2, 626006, 284},   --Shaman
    { {4054, 4055}, 2, 626008, 284},   --Warrior
    { {4024, 4025}, 2, 133146, 284},   --Eadric the Pure
    { {4022, 4023}, 2, 133154, 284},   --Argent Confessor Paletress
    { {4026, 4027}, 2, 133112, 284},   --The Black Knight

    -757,
    { {4028, 4030, 4031, 4029}, 54, 2429952, 757},    --Trial of the Crusader/Grand Grusader Beasts of Northrend
    { {4032, 4033, 4034, 4035}, 54, 236297, 757},    --Lord Jaraxxus
    { {4036, 4037, 4038, 4039}, 54, 1322720, 757},    --Faction Champions
    { {4040, 4041, 4042, 4043}, 54, 298674, 757},    --Val'kyr Twins
    { {4044, 4045, 4046, 4047}, 54, 298643, 757},    --Times Complete the Trial Anub'arak

    { {4715, 4716}, 2, 343632, 280},   --Forge of Souls Devourer of Souls
    { {4717, 4728}, 2, 342914, 278},   --Pit of Saron Forgemaster Garfrost
    { {4718, 4719}, 2, 342915, 278},   --Pit of Saron Ick and Krick
    { {4720, 4721}, 2, 341764, 278},   --Pit of Saron Scourgelord Tyrannus
    { {4722, 4723}, 2, 343667, 276},   --Halls of Reflection Falric
    { {4724, 4725}, 2, 133188, 276},   --Halls of Reflection Marwyn
    { {4726, 4727}, 2, 630787, 276},   --Halls of Reflection Lich King escapes

    --10 25 10H 25H
    -758,
    { {4639, 4641, 4640, 4642}, 54, 342917, 758},    --Icecrown Citadel Lord Marrowgar
    { {4643, 4655, 4654, 4656}, 54, 342916, 758},    --Lady Deathwhisper
    { {4644, 4660, 4659, 4661}, 54, 342918, 758},    --Gunship
    { {4645, 4663, 4662, 4664}, 54, 343634, 758},    --Deathbringer Saurfang
    { {4646, 4666, 4665, 4667}, 54, 344804, 758},    --Festergut
    { {4647, 4669, 4668, 4670}, 54, 342913, 758},    --Rotface
    { {4648, 4672, 4671, 4673}, 54, 298669, 758},    --Blood Prince Council
    { {4649, 4675, 4649, 4676}, 54, 341763, 758},    --Valithria Dreamwalker
    { {4650, 4678, 4677, 4679}, 54, 341459, 758},    --Professor Putricide
    { {4651, 4681, 4680, 4682}, 54, 343633, 758},    --Blood Queen Lana'thel
    { {4652, 4683, 4684, 4685}, 54, 341980, 758},    --Sindragosa
    { {4653, 4687, 4686, 4688}, 54, 341221, 758},    --Lich King

    -761,
    { {4821, 4820, 4822, 4823}, 54, 461145},   --Halion Ruby Sanctum
};

--if true then return end;

for categoryID, subList in pairs(list) do
    isCustomCategory[categoryID] = true;
    local id ;
    for i = 1, #subList do
        if type(subList[i]) == "table" then
            id = subList[i][1][1];
            isBossCard[id] = true;
            bossData[id] = subList[i];
        end
    end
end

--Narcissus Custom Statistics
local S = Narci.L.S;

local function SecondsToTime(seconds)
    seconds = tonumber(seconds);
    local timeString = "";
    local hours = math.floor(seconds/3600);
    if hours > 0 then
        timeString = timeString.. string.format(HOURS_ABBR, hours) .. ", ";
    end
    seconds = seconds - 3600 * hours;
    local minutes = math.floor(seconds / 60);
    timeString = timeString.. string.format(MINUTES_ABBR, minutes);
    return timeString;
end

local function GetTimeSpentInNarcissus()
    local timeSpent = NarciStatisticsDB.TimeSpentInNarcissus or 0;
    timeSpent = SecondsToTime(timeSpent);

    local installedDate = NarciStatisticsDB.InstalledDate;
    if installedDate then
        local installedDateString = date("%d %m %y", installedDate);
        local day, month, year = string.split(" ", installedDateString);
        if day and month and year then
            day = tonumber(day);
            month = tonumber(month);
            year = tonumber(year);
            local dateString = FormatShortDate(day, month, year);
            timeSpent = timeSpent .." "..string.format(S["Format Since"], dateString);
        end
    end

    return string.lower(timeSpent)
end

local function GetScreenshotsTaken()
    return NarciStatisticsDB.ScreenshotsTakenInNarcissus or 0;
end

local function GetQuestReading()
    if NarciStatisticsDB.SLQuestReadingTime then
        local locale, numQuests, numWords, timeReading, speed = unpack(NarciStatisticsDB.SLQuestReadingTime);
        if locale then
            local f = S["Quest Text Reading Speed Format"];
            return string.format(f, numQuests, numWords, timeReading, speed);
        else
            return NONE;
        end
    else
        return NONE;
    end
end

local customStatData = {
    [12080001] = {
        --Time spent in Narcissus
        name = S["Narcissus Played"],
        valueFunc = GetTimeSpentInNarcissus,
    },

    [12080002] = {
        --Screenshots taken in Narcissus
        name = S["Screenshots"],
        valueFunc = GetScreenshotsTaken,
    },

    [12080003] = {
        --Reading Quest
        name = S["Shadowlands Quests"],
        valueFunc = GetQuestReading,
    }
}

list[12080000] = {
    12080001,
    12080002,
    12080003,
};

local function GetCustomStatInfo(statID)
    return customStatData[statID].name, customStatData[statID].valueFunc()
end

addon.GetCustomStatInfo = GetCustomStatInfo;