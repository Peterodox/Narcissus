local _, addon = ...

local DataProvider = {};

addon.Gemma:AddDataProvider("Pandaria", DataProvider);

local GEM_TYPES = {
    [1] = "META",
    [2] = "COGWHEEL",
    [3] = "TINKER",
    [4] = "PRISMATIC",
};

local GEM_DATA = {
    --[itemID] = {type, spellID, role, uiOrder}
    --role: bits 000 (Tank/Healer/DPS): Tank 100(4), DPS 001(1), H/D 011(3), H 010(2)

    [221982] = {1, 447598, 4, 00},  --Bulwark of the Black Ox: Charge, Taunt, Ward
    [221977] = {1, 447566, 1, 20},  --Funeral Pyre: Stat, Self Harm
    [220211] = {1, 444954, 2, 60},  --Precipice of Madness: Ward
    [220120] = {1, 444677, 4, 70},  --Soul Tether: Redirect Damage
    [220117] = {1, 444622, 2, 90},  --Ward of Salvation: Restore HP, Overhealing to Ward, AoE
    [219878] = {1, 444128, 7, 85},  --Tireless Spirit: Reduce Resouce Cost
    [219386] = {1, 443389, 7, 35},  --Locus of Power: Stats
    [216974] = {1, 437495, 1, 40},  --Morphing Elements: Summon Portal, AoE
    [216711] = {1, 426268, 3, 10},  --Chi-ji, the Red Crane
    [216695] = {1, 437011, 3, 30},  --Lifestorm: Damage then Restore HP and Haste
    [216671] = {1, 426748, 7, 80},  --Thundering Orb: Transform, DR, Movement
    [216663] = {1, 435313, 1, 50},  --Oblivion Sphere: Crit Damage Taken, AoE, Control

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
    [216630] = {2, 427031, 7, 25},  --Heroic Leap
    [216629] = {2, 427053, 7, 05},  --Blink

    [219944] = {3, 444455, 2, 03},  --Bloodthirsty Coral: Damage taken to Healing
    [219818] = {3, 429007, 7, 06},  --Brilliance: Party Resouce Regen
    [219817] = {3, 429026, 7, 18},  --Freedom: Ckear Loss of Control
    [219801] = {3, 427064, 7, 00},  --Ankh of Reincarnation: Self-rez
    [219977] = {3, 428854, 4, 21},  --Grounding: Redirect Harmful Spell
    [219527] = {3, 443855, 7, 63},  --Vampiric Aura: +Leech, Party Leech
    [219523] = {3, 443834, 1, 57},  --Storm Overload: AoE, Control
    [219516] = {3, 443670, 3, 54},  --Static Charge: Heal or Damage
    [219389] = {3, 443498, 3, 30},  --Lightning Rod: Crit on Ally or Dot on Enemy
    [217964] = {3, 441209, 2, 27},  --Holy Martyr: Damage Taken to Party Healing
    [217961] = {3, 441198, 2, 42},  --Righteous Frency: Healing Proc Haste on Ally
    [217957] = {3, 441165, 2, 15},  --Deliverance: Store Healing. Healing when Low HP
    [217927] = {3, 441150, 2, 45},  --Savior: Healing Low HP Ally Grants Ward
    [217907] = {3, 441115, 4, 72},  --Warmth: +Healing Taken, Redistribute Overhealing
    [217903] = {3, 441092, 3, 69},  --Vindication: Damage Done Heals Allies
    [216651] = {3, 436586, 3, 48},  --Searing Light: Healing to Heal and AoE Damage
    [216650] = {3, 436583, 7, 36},  --Memory of Vegeance: For every 10s, gain primary stat for every 5% missing HP 
    [216649] = {3, 436578, 1, 09},  --Brittle: Store Damage Done, Death Trigger AoE
    [216648] = {3, 436577, 7, 12},  --Cold Front: Allies Ward, Enemies Debuff
    [216647] = {3, 436571, 1, 24},  --Hailstorm: AoE and Debuff
    [216628] = {3, 436467, 3, 66},  --Victory Fire: Enemy Death trigger AoE Damage and Healing
    [216627] = {3, 429230, 2, 60},  --Tinkmaster's Shield: Ward after not being damaged for 5s
    [216626] = {3, 429378, 1, 51},  --Slay: Extra Damage to Low Health Enemy
    [216625] = {3, 429373, 1, 39},  --Quick Strike: Melee Ability Triggers Additional Autoattacks
    [216624] = {3, 436461, 5, 33},  --Mark of Arrogance: Dot on Attackers

    [210715] = {4, nil, 0, 32},  --Mastery +
    [216640] = {4, nil, 0, 22},  --Mastery ++
    [211106] = {4, nil, 0, 12},  --Mastery +++
    [211108] = {4, nil, 0, 02},  --Mastery +++, STAM
    [210714] = {4, nil, 0, 30},  --Crit +
    [216644] = {4, nil, 0, 20},  --Crit ++
    [211123] = {4, nil, 0, 10},  --Crit +++
    [211102] = {4, nil, 0, 00},  --Crit +++, STAM
    [210681] = {4, nil, 0, 31},  --Haste +
    [216643] = {4, nil, 0, 21},  --Haste ++
    [211107] = {4, nil, 0, 11},  --Haste +++
    [211110] = {4, nil, 0, 01},  --Haste +++, STAM
    [220371] = {4, nil, 0, 33},  --Vers +
    [220372] = {4, nil, 0, 23},  --Vers ++
    [220374] = {4, nil, 0, 13},  --Vers +++
    [220373] = {4, nil, 0, 03},  --Vers +++, STAM
    [220367] = {4, nil, 0, 35},  --Armor +
    [220368] = {4, nil, 0, 25},  --Armor ++
    [220370] = {4, nil, 0, 15},  --Armor +++
    [220369] = {4, nil, 0, 05},  --Armor +++, STAM
    [211109] = {4, nil, 0, 36},  --Regen +
    [216642] = {4, nil, 0, 26},  --Regen ++
    [211125] = {4, nil, 0, 16},  --Regen +++
    [211105] = {4, nil, 0, 06},  --Regen +++, STAM
    [210717] = {4, nil, 0, 37},  --Leech +
    [216641] = {4, nil, 0, 27},  --Leech ++
    [210718] = {4, nil, 0, 17},  --Leech +++
    [211103] = {4, nil, 0, 07},  --Leech +++, STAM
    [210716] = {4, nil, 0, 38},  --Speed +
    [216639] = {4, nil, 0, 28},  --Speed ++
    [211124] = {4, nil, 0, 18},  --Speed +++
    [211101] = {4, nil, 0, 08},  --Speed +++, STAM
};


local function SortFunc_UIOrder(a, b)
    return GEM_DATA[a][4] < GEM_DATA[b][4]
end

function DataProvider:GetSortedItemList()
    local gemType;
    local tinsert = table.insert;

    local tbl = {};
    local numTypes = #GEM_TYPES;

    for i = 1, numTypes do
        tbl[i] = {};
    end

    for itemID, data in pairs(GEM_DATA) do
        tinsert(tbl[gemType], itemID);
    end

    for gemType, gems in pairs(tbl) do
        table.sort(gems, SortFunc_UIOrder);
    end

    return tbl
end