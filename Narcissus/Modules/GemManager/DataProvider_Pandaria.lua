local _, addon = ...
local L = Narci.L;
local DoesItemExistByID = addon.DoesItemExistByID;
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local BagScan = Gemma.BagScan;
local DataProvider = {};
local GemManagerMixin = {};
DataProvider.GemManagerMixin = GemManagerMixin;
Gemma:AddDataProvider("Pandaria", DataProvider);

local BagUtil = {};

local pairs = pairs;
local ipairs = ipairs;
local tsort = table.sort;

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";

local GetItemGemID = C_Item.GetItemGemID;
local GetItemNumSockets = C_Item.GetItemNumSockets;     --10.2.7
local IsEquippableItem = C_Item.IsEquippableItem;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetItemCount = C_Item.GetItemCount;
local GetInventoryItemLink = GetInventoryItemLink;
local GetCVarBool = C_CVar.GetCVarBool;


local MainFrame;

local GEM_TYPES = {
    [1] = "META",
    [2] = "COGWHEEL",
    [3] = "TINKER",
    [4] = "PRISMATIC",
};

local SLOT_ID = {
    HEAD = 1,
    FEET = 8,

    SHOULDER = 3,
    WRIST = 9,
    HANDS = 10,
    WAIST = 6,

    NECK = 2,
    CHEST = 5,
    LEGS = 7,
    RING1 = 11,
    RING2 = 12,
    TRINKET1 = 13,
    TRINKET2 = 14,
};

local GEM_DATA = {
    --[itemID] = {type, spellID, role, uiOrder, scaleWithIlvl}
    --role: bits 000 (Tank/Healer/DPS): Tank 100(4), DPS 001(1), H/D 011(3), H 010(2)

    --Total: 11
    [221982] = {1, 447598, 4, 00},  --Bulwark of the Black Ox: Charge, Taunt, Ward
    [221977] = {1, 447566, 1, 20},  --Funeral Pyre: Stat, Self Harm
    [220211] = {1, 444954, 2, 60},  --Precipice of Madness: Ward
    [220120] = {1, 444677, 4, 70},  --Soul Tether: Redirect Damage
    [220117] = {1, 444622, 2, 90},  --Ward of Salvation: Restore HP, Overhealing to Ward, AoE
    [219878] = {1, 444128, 7, 85},  --Tireless Spirit: Reduce Resouce Cost
    [219386] = {1, 443389, 7, 35},  --Locus of Power: Stats
    --[216974] = {1, 437495, 1, 40},  --Morphing Elements: Summon Portal, AoE
    [216711] = {1, 426268, 3, 10},  --Chi-ji, the Red Crane --426268, 437018
    [216695] = {1, 437011, 3, 30},  --Lifestorm: Damage then Restore HP and Haste
    [216671] = {1, 426748, 7, 80},  --Thundering Orb: Transform, DR, Movement
    [216663] = {1, 435313, 1, 50},  --Oblivion Sphere: Crit Damage Taken, AoE, Control

    --Total：17
    [218110] = {2, 441759, 7, 45},  --Soulshape
    [218109] = {2, 441749, 7, 10},  --Death's Advance
    [218108] = {2, 441741, 7, 05},  --Dark Pack
    [218082] = {2, 441617, 7, 55},  --Spiritwalker's Grace (Cast while Moving)
    [218046] = {2, 441576, 7, 50},  --Spirit Walk
    [218045] = {2, 441569, 7, 20},  --Door of Shadows
    [218044] = {2, 441564, 7, 35},  --Pursuit of Justice (Passive)
    [218043] = {2, 441559, 7, 80},  --Wild Charge
    [218005] = {2, 441493, 7, 65},  --Stampeding Roar
    [218004] = {2, 441479, 7, 75},  --Vanish
    [218003] = {2, 441467, 7, 30},  --Leap of Faith
    [217989] = {2, 441348, 7, 70},  --Trailblazer
    [217983] = {2, 441299, 7, 15},  --Disengage
    [216632] = {2, 427030, 7, 60},  --Sprint
    [216631] = {2, 427026, 7, 40},  --Roll
    [216630] = {2, 427033, 7, 25},  --Heroic Leap
    [216629] = {2, 427053, 7, 05},  --Blink

    --Total: 36
    [219801] = {3, 427064, 7, 00},  --Ankh of Reincarnation: Self-rez
    [212366] = {3, 429270, 3, 28},  --Arcanist's Edge: Consume shield to deal damage *
    [219944] = {3, 444455, 2, 03},  --Bloodthirsty Coral: Damage taken to Healing
    [219818] = {3, 429007, 7, 06},  --Brilliance: Party Resouce Regen
    [216649] = {3, 436578, 1, 09},  --Brittle: Store Damage Done, Death Trigger AoE
    [216648] = {3, 436577, 7, 12},  --Cold Front: Allies Ward, Enemies Debuff
    [217957] = {3, 441165, 2, 15},  --Deliverance: Store Healing. Healing when Low HP
    [212694] = {3, 433362, 3, 29},  --Enkindle: Grant shield, Damage attackers, Increase haste *
    [212749] = {3, 433361, 1, 102},  --Explosive Barrage: AoE
    [212365] = {3, 429389, 1, 103},  --Fervor: Consume HP to deal holy damage
    [219817] = {3, 429026, 7, 18},  --Freedom: Ckear Loss of Control
    [212916] = {3, 436528, 5, 104},  --Frost Armor: Damage and slow attackers
    [219777] = {3, 428854, 4, 21},  --Grounding: Redirect Harmful Spell
    [217964] = {3, 441209, 2, 27},  --Holy Martyr: Damage Taken to Party Healing
    [216647] = {3, 436571, 1, 24},  --Hailstorm: AoE and Debuff
    [212758] = {3, 433360, 1, 105},  --Incendiary Terror: Damage and Horrify
    [219389] = {3, 443498, 3, 30},  --Lightning Rod: Crit on Ally or Dot on Enemy
    [216624] = {3, 436461, 5, 33},  --Mark of Arrogance: Dot on Attackers
    [216650] = {3, 436583, 7, 36},  --Memory of Vegeance: For every 10s, gain primary stat for every 5% missing HP
    [212759] = {3, 433358, 1, 106},  --Metero Storm: AoE and stun
    [212361] = {3, 427054, 1, 107},  --Opportunist: Grant crit when damaging stunned enemey
    [216625] = {3, 429373, 1, 39},  --Quick Strike: Melee Ability Triggers Additional Autoattacks
    [217961] = {3, 441198, 2, 42},  --Righteous Frenzy: Healing Proc Haste on Ally
    [217927] = {3, 441150, 2, 45},  --Savior: Healing Low HP Ally Grants Ward
    [216651] = {3, 436586, 3, 48},  --Searing Light: Healing to Heal and AoE Damage
    [216626] = {3, 429378, 1, 51},  --Slay: Extra Damage to Low Health Enemy
    [219452] = {3, 443670, 3, 54},  --Static Charge: Heal or Damage
    [219523] = {3, 443834, 1, 57},  --Storm Overload: AoE, Control
    [212362] = {3, 436465, 1, 108},  --Sunstrider's Flourish: Crit cause AoE
    [216627] = {3, 429230, 2, 60},  --Tinkmaster's Shield: Ward after not being damaged for 5s
    [219527] = {3, 443855, 7, 63},  --Vampiric Aura: +Leech, Party Leech
    [216628] = {3, 436467, 3, 66},  --Victory Fire: Enemy Death trigger AoE Damage and Healing
    [217903] = {3, 441092, 3, 69},  --Vindication: Damage Done Heals Allies
    [217907] = {3, 441115, 4, 72},  --Warmth: +Healing Taken, Redistribute Overhealing
    [212760] = {3, 433356, 1, 109},  --Wildfire: Dot, Spreading
    [219516] = {3, 443787, 7, 110},  --Windweaver: +Movement Speed, Falling damage immunity, chance to increase party haste


    [210714] = {4, nil, 1, 30},  --Crit +
    [216644] = {4, nil, 1, 20},  --Crit ++
    [211123] = {4, nil, 1, 10},  --Crit +++
    [211102] = {4, nil, 1, 00},  --Crit +++, STAM
    [210681] = {4, nil, 2, 31},  --Haste +
    [216643] = {4, nil, 2, 21},  --Haste ++
    [211107] = {4, nil, 2, 11},  --Haste +++
    [211110] = {4, nil, 2, 01},  --Haste +++, STAM
    [210715] = {4, nil, 3, 32},  --Mastery +
    [216640] = {4, nil, 3, 22},  --Mastery ++
    [211106] = {4, nil, 3, 12},  --Mastery +++
    [211108] = {4, nil, 3, 02},  --Mastery +++, STAM
    [220371] = {4, nil, 4, 33},  --Vers +
    [220372] = {4, nil, 4, 23},  --Vers ++
    [220374] = {4, nil, 4, 13},  --Vers +++
    [220373] = {4, nil, 4, 03},  --Vers +++, STAM
    [220367] = {4, nil, 5, 35},  --Armor +
    [220368] = {4, nil, 5, 25},  --Armor ++
    [220370] = {4, nil, 5, 15},  --Armor +++
    [220369] = {4, nil, 5, 05},  --Armor +++, STAM
    --[211109] = {4, nil, 6, 36},  --Regen +
    --[216642] = {4, nil, 6, 26},  --Regen ++
    --[211125] = {4, nil, 6, 16},  --Regen +++
    --[211105] = {4, nil, 6, 06},  --Regen +++, STAM
    [210717] = {4, nil, 6, 37},  --Leech +
    [216641] = {4, nil, 6, 27},  --Leech ++
    [210718] = {4, nil, 6, 17},  --Leech +++
    [211103] = {4, nil, 6, 07},  --Leech +++, STAM
    [210716] = {4, nil, 7, 38},  --Speed +
    [216639] = {4, nil, 7, 28},  --Speed ++
    [211124] = {4, nil, 7, 18},  --Speed +++
    [211101] = {4, nil, 7, 08},  --Speed +++, STAM
};

local CUSTOM_SORT_ORDER = {
    [219801] = 3,   --Ankh of Reincarnation
    [212366] = 26,  --Arcanist's Edge
    [219944] = 10,  --Bloodthirsty Coral
    [219818] = 13,  --Brilliance
    [216649] = 11,  --Brittle
    [216648] = 16,  --Cold Front
    [217957] = 36,  --Deliverance
    [212694] = 8,   --Enkindle
    [212749] = 30,  --Explosive Barrage
    [212365] = 32,  --Fervor
    [219817] = 2,   --Freedom
    [212916] = 4,   --Frost Armor
    [219777] = 1,   --Grounding
    [216647] = 22,  --Hailstorm
    [217964] = 5,   --Holy Martyr
    [212758] = 31,  --Incendiary Terror
    [219389] = 33,  --Lightning Rod
    [216624] = 7,   --Mark of Arrogance
    [216650] = 9,   --Memory of Vegeance
    [212759] = 23,  --Metero Storm
    [212361] = 12,  --Opportunist
    [216625] = 29,  --Quick Strike
    [217961] = 27,  --Righteous Frenzy
    [217927] = 28,  --Savior
    [216651] = 35,  --Searing Light
    [216626] = 19,  --Slay
    [219452] = 14,  --Static Charge
    [219523] = 18,  --Storm Overload
    [212362] = 24,  --Sunstrider's Flourish
    [216627] = 21,  --Tinkmaster's Shield
    [219527] = 20,  --Vampiric Aura
    [216628] = 34,  --Victory Fire
    [217903] = 25,  --Vindication
    [217907] = 6,   --Warmth
    [212760] = 17,  --Wildfire
    [219516] = 15,  --Windweaver
};

local FALLBACK_TINKERS = {
    --When player doesn't own all saved tinkers and have empty sockets. Prioritize DPS gem
    216626, 219389, 212694, 219516, 212749, 212365,
    212758, 216647, 212362, 212760, 216649, 212759,
    219818, 216648, 219523, 219452, 216651, 216628,
    212916, 212366, 219801, 219944, 217957, 219817,
    219777, 217964, 216624, 216650, 212361, 216625,
    217961, 217927, 216627, 219527, 217903, 217907,
};

local STAT_GEMS = {
    [1] = {210714, 216644, 211123, 211102},     --Crit
    [2] = {210681, 216643, 211107, 211110},     --Haste
    [3] = {210715, 216640, 211106, 211108},     --Mastery
    [4] = {220371, 220372, 220374, 220373},     --Vers
    [5] = {220367, 220368, 220370, 220369},     --Armor
    --[6] = {211109, 216642, 211125, 211105},     --Regen
    [6] = {210717, 216641, 210718, 211103},     --Leech
    [7] = {210716, 216639, 211124, 211101},     --Speed
};

local GEM_REMOVAL_TOOL = {"spell", 433397};


local STATS_DATA = {
    --Data change dynamically
    --{name, }
    {STAT_CRITICAL_STRIKE, },
    {STAT_HASTE, },
    {STAT_MASTERY, },
    {STAT_VERSATILITY, },
    {STAT_ARMOR, },
    --{L["Stat Health Regen"], },
    {STAT_LIFESTEAL, },
    {STAT_SPEED},
};

local function SortFunc_UIOrder(a, b)
    if CUSTOM_SORT_ORDER[a] and CUSTOM_SORT_ORDER[b] then
        return CUSTOM_SORT_ORDER[a] < CUSTOM_SORT_ORDER[b]
    end

    if GEM_DATA[a][4] and GEM_DATA[b][4] then
        return GEM_DATA[a][4] < GEM_DATA[b][4]
    end

    return a < b
end

function DataProvider:GetSortedItemList()
    --Loaded once when used

    if self.gemList then return self.gemList end;

    local tinsert = table.insert;
    local tsort = tsort;

    local tbl = {};
    local numTypes = #GEM_TYPES;

    for i = 1, numTypes do
        tbl[i] = {};
    end

    for itemID, data in pairs(GEM_DATA) do
        if DoesItemExistByID(itemID) then
            local gemType = data[1];
            tinsert(tbl[gemType], itemID);
            Gemma:SetGemRemovalTool(itemID, GEM_REMOVAL_TOOL);
        else

        end
    end

    for gemType, gems in pairs(tbl) do
        tsort(gems, SortFunc_UIOrder);
    end

    self.gemList = tbl;

    return tbl
end

function DataProvider:GetGemTypeName(gemType)
    local lookup = "EMPTY_SOCKET_"..GEM_TYPES[gemType];
    if _G[lookup] then
        return _G[lookup]
    else
        return GEM_TYPES[gemType]
    end
end

function DataProvider:GetItemListByType(gemType)
    local itemList = self:GetSortedItemList();
    return itemList[gemType];
end

local function GetNumSocketsForSlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID);
    if itemLink then
        return GetItemNumSockets(itemLink) or 0
    else
        return 0
    end
end

local function GetItemGemFromSlot(slotID, index)
    local itemLink = GetInventoryItemLink("player", slotID);
    if itemLink then
        return GetItemGemID(itemLink, index);
    end
end

function DataProvider:DoesPlayerHaveHead()
    return GetNumSocketsForSlot(SLOT_ID.HEAD) > 0
end

function DataProvider:DoesPlayerHaveFeet()
    return GetNumSocketsForSlot(SLOT_ID.FEET) > 0
end

function DataProvider:GetHeadGem()
    return GetItemGemFromSlot(SLOT_ID.HEAD, 1)
end

function DataProvider:GetFeetGem()
    return GetItemGemFromSlot(SLOT_ID.FEET, 1)
end

function DataProvider:GetGemType(itemID)
    if GEM_DATA[itemID] then
        return GEM_DATA[itemID][1]
    end
end

function DataProvider:GetGemSpell(itemID)
    if GEM_DATA[itemID] then
        return GEM_DATA[itemID][2]
    end
end

function DataProvider:GetStatType(itemID)
    if self:GetGemType(itemID) == 4 then
        return GEM_DATA[itemID][3]
    end
end

function DataProvider:GetConflictGemItemID(itemID)
    local gemType = self:GetGemType(itemID);
    if gemType == 1 then
        local existingGem = self:GetHeadGem();
        if itemID ~= existingGem then
            return existingGem
        end
    elseif gemType == 2 then
        local existingGem = self:GetFeetGem();
        if itemID ~= existingGem then
            return existingGem
        end
    end
end

function DataProvider:GetActiveGems()
    return BagUtil.activeGemList
end




do  --Scan bag and equipment slot
    function BagUtil:ResetBagInfo()
        self.gemCount = {};             --Including all locations
        self.bagGemCount = {};          --Including those in equipment
        self.bagUsedGemCount = {};      --Gems in your bag equipment
        self.slotData = {};
        self.gemTypeAvailable = {};
        self.activeGemCount = {};
        self.activeGemList = nil;
    end

    local function SortFunc_ActiveTraits(itemID1, itemID2)
        local type1 = GEM_DATA[itemID1][1];
        local type2 = GEM_DATA[itemID2][1];

        if type1 ~= type2 then
            return type1 < type2
        end

        return itemID1 < itemID2
    end

    function BagUtil:OnScanComplete()
        if not self.activeGemCount then return end;

        local gemType, statType;
        local traitList = {};
        local statList = {};
        local n = 0;
        for itemID, count in pairs(self.activeGemCount) do
            gemType = DataProvider:GetGemType(itemID);
            if gemType then
                if gemType == 4 then
                    statType = GEM_DATA[itemID][3];
                    if not statList[statType] then
                        local name = STATS_DATA[statType][1];
                        statList[statType] = {0, name};
                    end

                    statList[statType][1] = statList[statType][1] + count;
                else
                    n = n + 1;
                    traitList[n] = itemID;
                end
            end
        end

        tsort(traitList, SortFunc_ActiveTraits);

        self.activeGemList = {
            traits = traitList,
            stats = statList,
        };

        if (not Gemma.MainFrame:IsShown()) and Gemma.PaperdollWidget:IsShown() and DataProvider:ShouldShowGreenDot() then
            Gemma.MainFrame:Show();
        end
    end

    local function BagUtil_ProcessItem(itemLink, id1, id2)
        if IsEquippableItem(itemLink) then
            local numSockets = GetItemNumSockets(itemLink);
            local slotData;

            if (not id2) and (numSockets > 0) then
                --id1: slotID
                slotData = {
                    gems = {},
                    numSockets = numSockets,
                    numMissing = 0,
                };
                BagUtil.slotData[id1] = slotData;
            end

            for index = 1, numSockets do
                local itemID = GetItemGemID(itemLink, index);
                if itemID and GEM_DATA[itemID] then
                    if not BagUtil.gemCount[itemID] then
                        BagUtil.gemCount[itemID] = 1;
                    else
                        BagUtil.gemCount[itemID] = BagUtil.gemCount[itemID] + 1;
                    end

                    if id2 then
                        --when there are supported gems in you bag
                        local gemType = DataProvider:GetGemType(itemID);
                        if not BagUtil.gemTypeAvailable[gemType] then
                            BagUtil.gemTypeAvailable[gemType] = true;
                        end

                        if not BagUtil.bagGemCount[itemID] then
                            BagUtil.bagGemCount[itemID] = 0;
                        end
                        BagUtil.bagGemCount[itemID] = BagUtil.bagGemCount[itemID] + 1;

                        if not BagUtil.bagUsedGemCount[itemID] then
                            BagUtil.bagUsedGemCount[itemID] = 0;
                        end
                        BagUtil.bagUsedGemCount[itemID] = BagUtil.bagUsedGemCount[itemID] + 1;
                    else
                        if not BagUtil.activeGemCount[itemID] then
                            BagUtil.activeGemCount[itemID] = 0;
                        end
                        BagUtil.activeGemCount[itemID] = BagUtil.activeGemCount[itemID] + 1;
                    end
                end

                if not id2 then
                    slotData.gems[index] = itemID;
                    if not itemID then
                        slotData.numMissing = slotData.numMissing + 1;
                    end
                end
            end
        else
            local itemID = GetItemInfoInstant(itemLink);
            if GEM_DATA[itemID] then
                if not BagUtil.gemCount[itemID] then
                    BagUtil.gemCount[itemID] = 1;
                else
                    BagUtil.gemCount[itemID] = BagUtil.gemCount[itemID] + 1;    --stackCount of stat gem isn't relevant here
                end

                if id2 then
                    local gemType = DataProvider:GetGemType(itemID);
                    if not BagUtil.gemTypeAvailable[gemType] then
                        BagUtil.gemTypeAvailable[gemType] = true;
                    end

                    if not BagUtil.bagGemCount[itemID] then
                        BagUtil.bagGemCount[itemID] = 0;
                    end
                    BagUtil.bagGemCount[itemID] = BagUtil.bagGemCount[itemID] + 1;
                end
            end
        end
    end

    local AdditionalScanSlots;

    function BagUtil:InitiateScan()
        if not AdditionalScanSlots then
            AdditionalScanSlots = {};
            local n = 0;
            for slotName, slotID in pairs(SLOT_ID) do
                n = n + 1;
                AdditionalScanSlots[n] = slotID;
            end
        end

        BagScan:SetProcessor(BagUtil_ProcessItem, AdditionalScanSlots);
        BagScan:FullUpdate();
    end

    function BagUtil:StopScan()
        BagScan:StopIfProcessorSame(BagUtil_ProcessItem);
    end


    local CallbackRegistry = addon.CallbackRegistry;

    local function PaperdollWidget_OnShow()
        BagUtil:InitiateScan();
    end

    local function PaperdollWidget_OnHide()
        BagUtil:StopScan();
    end

    CallbackRegistry:Register("PaperdollWidget.Gem.OnShow", PaperdollWidget_OnShow);
    CallbackRegistry:Register("PaperdollWidget.Gem.OnHide", PaperdollWidget_OnHide);

    CallbackRegistry:Register("GemManager.BagScan.OnStart", BagUtil.ResetBagInfo, BagUtil);
    CallbackRegistry:Register("GemManager.BagScan.OnStop", BagUtil.OnScanComplete, BagUtil);
end


local TINKER_SLOT = {
    SLOT_ID.SHOULDER, SLOT_ID.WRIST, SLOT_ID.HANDS, SLOT_ID.WAIST,
};

do  --Use the result from bag scan
    local META_SLOT = { SLOT_ID.HEAD };

    local COGWHEEL_SLOT = { SLOT_ID.FEET };

    local PRISMATIC_SLOT = {
        SLOT_ID.CHEST, SLOT_ID.LEGS, SLOT_ID.TRINKET1, SLOT_ID.TRINKET2, SLOT_ID.NECK, SLOT_ID.RING1, SLOT_ID.RING2
    };


    function DataProvider:GetSlotSocketsCount(slots, gemType)
        local slotData = BagUtil.slotData;
        local totalSockets = 0;
        local totalMissing = 0;

        for _, slotID in ipairs(slots) do
            if slotData[slotID] then
                totalSockets = totalSockets + slotData[slotID].numSockets;
                totalMissing = totalMissing + slotData[slotID].numMissing;
            end
        end

        local anySpareGemInBags = BagUtil.gemTypeAvailable and BagUtil.gemTypeAvailable[gemType]

        return totalSockets, totalMissing, anySpareGemInBags
    end

    function DataProvider:GetMetaSocketCount()
        return self:GetSlotSocketsCount(META_SLOT, 1)
    end

    function DataProvider:GetCogwheelSocketCount()
        return self:GetSlotSocketsCount(COGWHEEL_SLOT, 2)
    end

    function DataProvider:GetTinkerSocketCount()
        return self:GetSlotSocketsCount(TINKER_SLOT, 3)
    end
    
    function DataProvider:GetPrismaticSocketCount()
        return self:GetSlotSocketsCount(PRISMATIC_SLOT, 4)
    end

    function DataProvider:GetGemInventorySlotAndIndex(itemID)
        if not self:IsGemCollected(itemID) then return end;

        for slotID, slotData in pairs(BagUtil.slotData) do
            for socketIndex = 1, slotData.numSockets do
                if slotData.gems[socketIndex] == itemID then
                    return slotID, socketIndex
                end
            end
        end
    end

    function DataProvider:CanSwapGemInOneStep(itemID)
        --You will have to perform two actions if the target socket is occupied and
        --the gem you want to insert is in another equipment
        local existingGem = self:GetConflictGemItemID(itemID);
        local inbagCount = self:GetInBagGemCount(itemID);
        local spareCount = GetItemCount(itemID);

        if existingGem and (inbagCount > 0 and spareCount == 0) then
            return false
        end

        return true
    end

    function DataProvider:GetBestSlotToPlaceGem(itemID)
        if not self:IsGemCollected(itemID) then return end;

        local gemType = self:GetGemType(itemID);
        if not gemType then return end;

        local slots;

        if gemType == 1 then
            slots = META_SLOT;
        elseif gemType == 2 then
            slots = COGWHEEL_SLOT;
        elseif gemType == 3 then
            slots = TINKER_SLOT;
        elseif gemType == 4 then
            slots = PRISMATIC_SLOT;
        end

        local slotData;

        for _, slotID in ipairs(slots) do
            slotData = BagUtil.slotData[slotID];
            if slotData then
                for socketIndex = 1, slotData.numSockets do
                    if slotData.gems[socketIndex] == nil then
                        return slotID, socketIndex
                    end
                end
            end
        end
    end

    function DataProvider:GetInBagGemCount(itemID)
        return BagUtil.bagGemCount and BagUtil.bagGemCount[itemID] or 0;
    end

    function DataProvider:GetInBagUsedGemCount(itemID)
        return BagUtil.bagUsedGemCount and BagUtil.bagUsedGemCount[itemID] or 0;
    end

    function DataProvider:GetOnPlayerGemCount(itemID)
        return BagUtil.activeGemCount[itemID] and BagUtil.activeGemCount[itemID] or 0;
    end

    function DataProvider:IsGemActive(itemID)
        return self:GetOnPlayerGemCount(itemID) > 0
    end

    function DataProvider:IsGemCollected(itemID)
        return BagUtil.gemCount[itemID] and BagUtil.gemCount[itemID] > 0
    end

    function DataProvider:ShouldShowGreenDot()
        local totalSockets, totalMissing, anySpareGemInBags;
        local showGreenDot;

        if not showGreenDot then
            totalSockets, totalMissing, anySpareGemInBags = self:GetMetaSocketCount();
            showGreenDot = totalMissing > 0 and anySpareGemInBags;
        end

        if not showGreenDot then
            totalSockets, totalMissing, anySpareGemInBags = self:GetCogwheelSocketCount();
            showGreenDot = totalMissing > 0 and anySpareGemInBags;
        end

        if not showGreenDot then
            totalSockets, totalMissing, anySpareGemInBags = self:GetTinkerSocketCount();
            showGreenDot = totalMissing > 0 and anySpareGemInBags;
        end

        if not showGreenDot then
            totalSockets, totalMissing, anySpareGemInBags = self:GetPrismaticSocketCount();
            showGreenDot = totalMissing > 0 and anySpareGemInBags;
        end

        return showGreenDot
    end
end

do
    local ACTION_BUTTON_METHODS = {
        [1] = "SetAction_RemovePandariaMetaGem",
        [2] = "SetAction_RemovePandariaGem",
    };

    function DataProvider:GetActionButtonMethod(itemID)
        local gemType = self:GetGemType(itemID);
        if gemType == 1 or gemType == 2 then
            return ACTION_BUTTON_METHODS[1]
        elseif gemType == 3 then
            return ACTION_BUTTON_METHODS[2]
        end
    end
end


DataProvider.schematic = {
    background = "remix-ui-bg",
    topDivider = "remix-ui-divider",

    tabData = {
        {
            name = L["Pandamonium Gem Category 1"],  --Major
            method = "ShowMajors",
            background = nil,
            useCustomTooltip = false,
        },

        {
            name = L["Pandamonium Gem Category 2"],  --Tinker
            method = "ShowTraits",
            background = "remix-ui-tinker-bg",
            useCustomTooltip = true,
        },

        {
            name = L["Pandamonium Gem Category 3"],  --Prismatic
            method = "ShowStats",
            background = nil,
            useCustomTooltip = false,
        },
    },
};

local BorderTextures_Hexagon = {
    active = "remix-hexagon-yellow",
    inactive = "remix-hexagon-grey",
    available = "remix-hexagon-green",
    dimmed = "remix-hexagon-darkyellow",
};

local BorderTextures_BigSquare = {
    active = "remix-bigsquare-yellow",
    inactive = "remix-bigsquare-grey",
    available = "remix-bigsquare-green",
};


local function sin(deg)
    return math.sin(math.rad(deg));
end

local function cos(deg)
    return math.cos(math.rad(deg));
end

local function CreateSlotShadow(self, slotButton)
    local shadow = self:AcquireTexture("Back", "BACKGROUND");
    AtlasUtil:SetAtlas(shadow, "remix-bigsquare-shadow");
    shadow:SetPoint("CENTER", slotButton, "CENTER", 0, 0);
end


function GemManagerMixin:SetupMajorSlotButton(itemID)
    local button = self:AcquireSlotButton("BigSquare");
    button.borderTextures = BorderTextures_BigSquare;
    button:SetButtonSize(64, 53);   --buttonSize, iconSize

    if itemID then
        button:SetItem(itemID);
        button:SetActive();
    else
        button:ClearItem();
    end

    local shadow = self:AcquireTexture("Back", "BACKGROUND");
    AtlasUtil:SetAtlas(shadow, "remix-bigsquare-shadow");
    shadow:SetPoint("CENTER", button, "CENTER", 0, 0);

    return button
end

local function TooltipFunc_EmptyMeta(tooltip)
    tooltip:SetText(EMPTY_SOCKET_META, 1, 1, 1);
    tooltip:AddLine(L["Click To Show Gem List"], 0.098, 1.000, 0.098, true);
    tooltip:Show();
    return true
end

local function TooltipFunc_EmptyCogwheel(tooltip)
    tooltip:SetText(EMPTY_SOCKET_COGWHEEL, 1, 1, 1);
    tooltip:AddLine(L["Click To Show Gem List"], 0.098, 1.000, 0.098, true);
    tooltip:Show();
    return true
end

local function OnClickFunc_ShowMetaGemList(self, mouseButton)
    if DataProvider:GetHeadGem() and mouseButton == "RightButton" then
        MainFrame.autoShowGemList = 1;
        return false
    end

    GemManagerMixin.ShowGemList(MainFrame, 1);

    return true
end

local function OnClickFunc_ShowCogwheelGemList(self, mouseButton)
    if DataProvider:GetFeetGem() and mouseButton == "RightButton" then
        MainFrame.autoShowGemList = 2;
        return false
    end

    GemManagerMixin.ShowGemList(MainFrame, 2);

    return true
end

local function OnClickFunc_CloseGemList(self, mouseButton)
    if mouseButton == "RightButton" then
        --if not DataProvider:IsGemActive(self.itemID) then
            MainFrame:CloseGemList();
            return true
        --end
    elseif mouseButton == "LeftButton" then
        if DataProvider:IsGemActive(self.itemID) then
            MainFrame:CloseGemList();
            return true
        end
    end
end

function GemManagerMixin:ShowMajors()
    MainFrame = self;
    self.useSlotFrame = true;

    local shape = "BigSquare";
    local container = self.SlotFrame;

    local numButtons = 0;
    local button1, button2;

    local newlyEquippedSocket;

    if DataProvider:DoesPlayerHaveHead() then
        local itemID = DataProvider:GetHeadGem();
        local button = self:SetupMajorSlotButton(itemID);

        numButtons = numButtons + 1;
        button1 = button;

        local typeIcon = self:AcquireTexture("Front");
        AtlasUtil:SetAtlas(typeIcon, "gemtypeicon-offensive");
        typeIcon:SetPoint("CENTER", button, "BOTTOM", 0, 0);

        button.onClickFunc = OnClickFunc_ShowMetaGemList;

        if itemID then
            typeIcon:SetDesaturation(0);
        else
            typeIcon:SetDesaturation(1);
            button.tooltipFunc = TooltipFunc_EmptyMeta;
            local _, _, anySpareGemInBags = DataProvider:GetPrismaticSocketCount();  --GetMetaSocketCount
            if anySpareGemInBags then
                button:SetSelectable();
            else
                button:SetUncollected();
            end
        end

        if (not self.headGemID) and itemID then
            newlyEquippedSocket = button;
        end
        self.headGemID = itemID;
    else
        self.headGemID = nil;
    end

    if DataProvider:DoesPlayerHaveFeet() then
        local itemID = DataProvider:GetFeetGem();
        local button = self:SetupMajorSlotButton(itemID);

        numButtons = numButtons + 1;
        if not button1 then
            button1 = button;
        else
            button2 = button;
        end

        local typeIcon = self:AcquireTexture("Front");
        AtlasUtil:SetAtlas(typeIcon, "gemtypeicon-movement");
        typeIcon:SetPoint("CENTER", button, "BOTTOM", 0, 0);

        button.onClickFunc = OnClickFunc_ShowCogwheelGemList;

        if itemID then
            typeIcon:SetDesaturation(0);
        else
            typeIcon:SetDesaturation(1);
            button.tooltipFunc = TooltipFunc_EmptyCogwheel;
            local _, _, anySpareGemInBags = DataProvider:GetCogwheelSocketCount();
            if anySpareGemInBags then
                button:SetSelectable();
            else
                button:SetUncollected();
            end
        end

        if (not self.feetGemID) and itemID then
            if newlyEquippedSocket then
                newlyEquippedSocket = nil;
            else
                newlyEquippedSocket = button;
            end
        end
        self.feetGemID = itemID;
    else
        self.feetGemID = nil;
    end

    if numButtons == 0 then
        self:ShowNoSocketAlert(true);
    else
        if numButtons == 2 then
            local offsetX = 8;
            local offsetY = 16;
            button1:SetPoint("BOTTOMRIGHT", container, "CENTER", -offsetX, offsetY);
            button2:SetPoint("TOPLEFT", container, "CENTER", offsetX, -offsetY);
        elseif numButtons == 1 then
            button1:SetPoint("CENTER", container, "CENTER", 0, 0);
        end
        self:ShowNoSocketAlert(false);
    end

    self.SlotFrame.ButtonHighlight:SetShape(shape);
    self.UpdateCurrentTab = self.UpdateMajors;

    if self.autoShowGemList then
        self:ShowGemList(self.autoShowGemList);
        self.autoShowGemList = nil;
    else
        if newlyEquippedSocket then
            self:CloseGemList();

            local shine = self.SlotFrame.ButtonShine;
            shine.Mask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
            shine.Mask:SetSize(53, 53);
            shine.Texture:SetTexture(PATH.."SlotShine");
            shine.Texture:SetSize(80, 80);
            shine.Texture:SetBlendMode("ADD");

            self:ShineSlot(newlyEquippedSocket);
        else
            self:UpdateGemList();
        end
    end
end

function GemManagerMixin:UpdateMajors()
    self:ReleaseContent();
    self:ShowMajors();
end

function GemManagerMixin:UpdateGemList()
    if self.GemList:IsShown() and self.gemType then
        local activeGemID;
        if self.gemType == 1 then
            activeGemID = DataProvider:GetHeadGem();
        elseif self.gemType == 2 then
            activeGemID = DataProvider:GetFeetGem();
        end
        self.GemList.activeGemID = activeGemID;
        self.GemList:UpdatePage();
    end
end

function GemManagerMixin:ShowGemList(gemType)
    self.gemType = gemType;

    if not gemType then return end;

    local activeGemID;
    if gemType == 1 then
        activeGemID = DataProvider:GetHeadGem();
    elseif gemType == 2 then
        activeGemID = DataProvider:GetFeetGem();
    end
    self.GemList.activeGemID = activeGemID;

    local gems = DataProvider:GetItemListByType(gemType);
    self.GemList.onClickFunc = OnClickFunc_CloseGemList;
    self.GemList:SetItemList(gems, DataProvider:GetGemTypeName(gemType), DataProvider);

    self:OpenGemList();
end

function GemManagerMixin:ShowTraits()
    self.useSlotFrame = true;

    local shape = "Hexagon";
    local diagonal = 40;    --46
    local gap = 1;
    local container = self.SlotFrame;

    local deltaXPerRow = ((diagonal * cos(30)) + gap) * 0.5;
    local deltaYPerRow = (diagonal * cos(30) + gap) * cos(30);
    local offsetX = diagonal * cos(30) + gap;

    local contentHeight = 5 * deltaYPerRow + diagonal;

    local frameWidth = container:GetWidth();
    local frameHeight = container:GetHeight();

    local paddingY = (frameHeight - contentHeight) * 0.5;

    local refX = frameWidth * 0.5;
    refX = 0;
    local refY = (deltaYPerRow - diagonal * 0.5) - paddingY;

    local gemType = 3;  --Tinker
    local gems = DataProvider:GetItemListByType(gemType);

    local button;
    local row = 1;
    local col = 1;
    local maxCol = 1;
    local fromX, fromY = refX, refY;
    local x, y;

    for index, itemID in ipairs(gems) do
        button = self:AcquireSlotButton(shape);
        button:ResetButtonSize();
        button.borderTextures = BorderTextures_Hexagon;

        if col > maxCol then
            maxCol = maxCol + 1;
            col = 1;
            row = row + 1;

            fromX = refX - (row - 1) * deltaXPerRow;
            fromY = refY - (row - 1) * deltaYPerRow;
        end

        x = fromX + (col - 1) * offsetX;
        y = fromY;
        button:SetPoint("CENTER", self.SlotFrame, "TOP", x, y);
        button:SetItem(itemID);

        col = col + 1;
    end

    if self.SlotFrame.ButtonHighlight then
        self.SlotFrame.ButtonHighlight:SetShape(shape);
    end

    local shine = self.SlotFrame.ButtonShine;
    if shine then
        shine.Mask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
        shine.Mask:SetSize(32, 32);
        shine.Texture:SetTexture(PATH.."SlotShine");
        shine.Texture:SetSize(48, 48);
        shine.Texture:SetBlendMode("ADD");
    end

    self.UpdateCurrentTab = self.UpdateSlots;

    if not self.isLoadoutPlanner then
        if self.TooltipFrame then
            self.TooltipFrame:ClearAllPoints();
            self.TooltipFrame:SetPoint("TOP", container, "CENTER", 0, -contentHeight * 0.5 - 44);
    
            if GetCVarBool("colorblindMode") then
                self.TooltipFrame:SetDescriptionLine(7);
            else
                self.TooltipFrame:SetDescriptionLine(6);
            end
        end

        self:UpdateSlots();
    end
end

function GemManagerMixin:UpdateSlots()
    if not self.slotButtons then return end;

    local totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetTinkerSocketCount();
    self:SetPointDisplayAmount(totalMissing);

    local chooseItem = totalMissing > 0;

    for index, button in ipairs(self.slotButtons) do
        if button:IsShown() then
            if DataProvider:IsGemActive(button.itemID) then
                if chooseItem then
                    button:SetDimmed();
                else
                    button:SetActive();
                end
            elseif DataProvider:IsGemCollected(button.itemID) then
                if chooseItem then
                    button:SetAvailable();
                else
                    button:SetInactive();
                end
                
            else
                button:SetUncollected();
            end
        else
            break
        end
    end
end


do  --Stats Assignment Tab
    function DataProvider:GetNumAvailableGemForStat(statType)
        local gems = STAT_GEMS[statType];
        local total = 0;

        if gems then
            for _, itemID in ipairs(gems) do
                total = total + self:GetInBagGemCount(itemID);
            end
        end

        return total
    end

    function DataProvider:GetBestStatGemToRemove(statType)
        --From lower tier to higher
        local gems = STAT_GEMS[statType];
        if gems then
            for _, itemID in ipairs(gems) do
                if self:IsGemActive(itemID) then
                    return itemID
                end
            end
        end
    end

    function DataProvider:GetBestStatGemToInsert(statType)
        --From higher tier to lower
        local gems = STAT_GEMS[statType];
        if gems then
            local itemID;
            for i = #gems, 1, -1 do
                itemID = gems[i];
                if self:GetInBagGemCount(itemID) > 0 then
                    return itemID
                end
            end
        end
    end

    function DataProvider:GetBestStatGemForAction(statType, direction)
        if direction > 0 then   --Insert gem
            return self:GetBestStatGemToInsert(statType)
        else    --remove gem
            return self:GetBestStatGemToRemove(statType)
        end
    end

    function DataProvider:GetAvailableGemListForStat(statType)
        --Used in Loadout Action
        local gems = STAT_GEMS[statType];
        local statGemCount = {};

        if gems then
            local itemID, inBagCount, spareCount;
            local n = 0;

            for i = #gems, 1, -1 do
                itemID = gems[i];

                inBagCount = self:GetInBagUsedGemCount(itemID);
                spareCount = GetItemCount(itemID);

                --if inBagCount > 0 or spareCount > 0 then
                    local tbl = {
                        itemID = itemID,
                        inBagCount = inBagCount,
                        spareCount = spareCount,
                    };

                    n = n + 1;
                    statGemCount[n] = tbl;
                --end
            end
        end

        return statGemCount
    end

    function GemManagerMixin:ShowStats()
        self.useSlotFrame = true;

        local buttonHeight = 24;
        local gap = 0.2;    --Compensation for IsMouseOver()
        local numButtons = #STATS_DATA;
        local container = self.SlotFrame;
        local fromY = -0.5 * (container:GetHeight() - (numButtons * (buttonHeight + gap) -gap));

        local button;

        for i, statData in ipairs(STATS_DATA) do
            button = self:AcquireStatButton();
            button:SetPoint("TOP", container, "TOP", 0, fromY + (1 - i) * (buttonHeight + gap));
            button:SetName(statData[1]);
        end

        self.UpdateCurrentTab = self.UpdateStats;

        if not self.isLoadoutPlanner then
            self:UpdateStats();
        end
    end

    function GemManagerMixin:UpdateStats()
        local totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetPrismaticSocketCount();
        local isEditMode;

        if totalMissing > 0 then
            isEditMode = true;
            self.PointsDisplay:SetAmount(totalMissing);
            self.PointsDisplay:Show();
        else
            isEditMode = false;
            self.PointsDisplay:Hide();
        end
        
        local activeGems = DataProvider:GetActiveGems();
        local activeStatsGems = activeGems and activeGems.stats;

        local button, count;

        for i, statData in ipairs(STATS_DATA) do
            button = self.statButtons[i];
            count = activeStatsGems[i] and activeStatsGems[i][1] or 0;
            button:SetCount(count);
            button:SetPlusButtonVisibility( isEditMode and DataProvider:GetNumAvailableGemForStat(i) > 0 );
        end
    end
end


function GemManagerMixin:UpdateTabGreenDot()
    BagScan:FullUpdate();

    local totalSockets, totalMissing, anySpareGemInBags;
    local showGreenDot;

    --Meta and cogwheel are on the same tab
    totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetMetaSocketCount();
    showGreenDot = totalMissing > 0 and anySpareGemInBags;

    if not showGreenDot then
        totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetCogwheelSocketCount();
        showGreenDot = totalMissing > 0 and anySpareGemInBags;
    end

    self.tabButtons[1].GreenDot:SetShown(showGreenDot);

    totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetTinkerSocketCount();
    showGreenDot = totalMissing > 0 and anySpareGemInBags;
    self.tabButtons[2].GreenDot:SetShown(showGreenDot);

    totalSockets, totalMissing, anySpareGemInBags = DataProvider:GetPrismaticSocketCount();
    showGreenDot = totalMissing > 0 and anySpareGemInBags;
    self.tabButtons[3].GreenDot:SetShown(showGreenDot);
end




do --Loadout
    local function AddSlotGemCountToTable(tbl, slotID, gemType)
        local itemLink = GetInventoryItemLink("player", slotID);
        if itemLink then
            local gemItemID, statType;
            for socketIndex = 1, GetItemNumSockets(itemLink) do
                gemItemID = GetItemGemID(itemLink, socketIndex);
                if gemItemID then
                    --local gemType = DataProvider:GetGemType(gemItemID);
                    if gemType == 3 then
                        table.insert(tbl, gemItemID);
                    elseif gemType == 4 then
                        statType = DataProvider:GetStatType(gemItemID);
                        if not tbl[statType] then
                            tbl[statType] = 0;
                        end
                        tbl[statType] = tbl[statType] + 1;
                    end
                end
            end
        end
    end

    function DataProvider:GetEquippedLoadoutGemInfo()
        --[[--Structure:
            {
                head = 221977,
                feet = 218110,
                tinker = {219801, 212366, 219944, 219818},
                stats1 = {  --Chest Legs
                    crit = 1,
                    haste = 2,
                },

                stats2 = {}, --Trinkets
                stats3 = {}, --Neck/Rings
            }
        --]]

        local gemInfo = {};

        gemInfo.head = self:GetHeadGem();
        gemInfo.feet = self:GetFeetGem();


        gemInfo.tinker = {};
        for _, slotID in ipairs(TINKER_SLOT) do
            AddSlotGemCountToTable(gemInfo.tinker, slotID, 3);
        end

        tsort(gemInfo.tinker);

        gemInfo.stats1 = {};
        AddSlotGemCountToTable(gemInfo.stats1, SLOT_ID.CHEST, 4);
        AddSlotGemCountToTable(gemInfo.stats1, SLOT_ID.LEGS, 4);

        gemInfo.stats2 = {};
        AddSlotGemCountToTable(gemInfo.stats2, SLOT_ID.TRINKET1, 4);
        AddSlotGemCountToTable(gemInfo.stats2, SLOT_ID.TRINKET2, 4);

        gemInfo.stats3 = {};
        AddSlotGemCountToTable(gemInfo.stats3, SLOT_ID.NECK, 4);
        AddSlotGemCountToTable(gemInfo.stats3, SLOT_ID.RING1, 4);
        AddSlotGemCountToTable(gemInfo.stats3, SLOT_ID.RING2, 4);

        return gemInfo
    end

    function DataProvider:IsLeftStatGemBetter(gem1, gem2)
        if GEM_DATA[gem1][3] == GEM_DATA[gem2][3] then
            return GEM_DATA[gem1][4] < GEM_DATA[gem2][4]
        end
    end

    function DataProvider:GetFallbackTinkers(numEmptySockets, requiredTinker)
        local tbl = {};
        local n = 0;

        requiredTinker = requiredTinker or {};

        for _, itemID in ipairs(FALLBACK_TINKERS) do
            if (not requiredTinker[itemID]) and (self:IsGemCollected(itemID) and not self:IsGemActive(itemID)) then
                n = n + 1;
                if n <= numEmptySockets then
                    tbl[n] = itemID;
                else
                    break
                end
            end
        end

        return tbl
    end

    function DataProvider:GetFallbackMajorGem(gemType, requiredGem)
        local gems = self:GetItemListByType(gemType);
        for _, itemID in ipairs(gems) do
            if (itemID ~= requiredGem) and (self:IsGemCollected(itemID) and not self:IsGemActive(itemID)) then
                return itemID;
            end
        end
    end

    function DataProvider:GetFallbackMeta(requiredGem)
        return self:GetFallbackMajorGem(1, requiredGem)
    end

    function DataProvider:GetFallbackCogwheel(requiredGem)
        return self:GetFallbackMajorGem(2, requiredGem)
    end
end