local L = Narci.L;

local GemData = {
    --[itemID] = {"attribute", amount},

    ----9 SL----
    [173127] = {"crit", 16},        --Deadly Jewel Cluster
    [173128] = {"haste", 16},       --Quick Jewel Cluster
    [173129] = {"versatility", 16}, --Versatile Jewel Cluster
    [173130] = {"mastery", 16},     --Masterful Jewel Cluster

    [173121] = {"crit", 12},        --Deadly Jewel Doublet
    [173122] = {"haste", 12},       --Quick Jewel Doublet
    [173123] = {"versatility", 12}, --Versatile Jewel Doublet
    [173124] = {"mastery", 12},     --Masterful Jewel Doublet

    [173125] = {"HP", 0},           --**Revitalizing Jewel Doublet
    [173126] = {"MSPD", 0},         --**Straddling Jewel Doublet

    ----8 BFA----
    [168636] = {"STR", 7},        --Leviathan's Eye of Strength
    [168637] = {"AGI", 7},        --Leviathan's Eye of Agility
    [168638] = {"INT", 7},        --Leviathan's Eye of Intellect

    [168639] = {"crit", 7},        --Deadly Lava Lazuli
    [168640] = {"mastery", 7},     --Masterful Sea Currant
    [168641] = {"haste", 7},       --Quick Sand Spinel
    [168642] = {"versatility", 7}, --Versatile Dark Opal
    [169220] = {"MSPD", 5},         --***Straddling Sage Agate

    [154126] = {"crit", 6},        --Deadly Amberblaze
    [154127] = {"haste", 6},       --Quick Owlseye
    [154128] = {"versatility", 6}, --Versatile Royal Quartz
    [154129] = {"mastery", 6},     --Masterful Tidal Amethyst

    [153707] = {"STR", 6},         --Kraken's Eye of Strength
    [153708] = {"AGI", 6},         --Kraken's Eye of Agility
    [153709] = {"INT", 6},         --Kraken's Eye of Intellect

    [153710] = {"crit", 4},        --Deadly Solstone
    [153711] = {"haste", 4},       --Quick Golden Beryl
    [153712] = {"versatility", 4}, --Versatile Kyanite
    [153713] = {"mastery", 4},     --Masterful Kubiline
    [153714] = {"EXP", 5},          --***Insightful Rubellite 
    [153715] = {"MSPD", 3},         --***Straddling Viridium

    ----7 LEG----
    [151580] = {"crit", 7},        --Deadly Deep Chemirine
    [151583] = {"haste", 7},       --Quick Lightsphene
    [151584] = {"mastery", 7},     --Masterful Argulite
    [151585] = {"versatility", 7}, --Versatile Labradorite

    [130219] = {"crit", 6},         --Deadly Eye of Prophecy
    [130220] = {"haste", 6},        --Quick Dawnlight
    [130221] = {"versatility", 6},   --Versatile Maelstrom Sapphire
    [130222] = {"mastery", 6},      --Masterful Shadowruby

    [130215] = {"crit", 4},         --Deadly Deep Amber
    [130216] = {"haste", 4},        --Quick Azsunite
    [130217] = {"versatility", 4},  --Versatile Skystone
    [130218] = {"mastery", 4},      --Masterful Queen's Opal
}

Narci.GemData = GemData;

local EnchantData= {
    --[enchantID] = {"attribute", amount, craftingSpellID, [itemID]},  --need to be parsed from itemstring

    ----9 SL----
    ----Temp----
    [6225] = {"stamina", 32, 324088, 172347},       --Heavy Desolate Armor Kit
    [6224] = {"stamina", 16, 324087, 172346},       --Desolate Armor Kit
    [6200] = {"AP", 20, 307718, 171437},            --Shaded Sharpening Stone
    [6198] = {"AP", 16, 307717, 171436},            --Porous Sharpening Stone
    [6201] = {"AP", 20, 307720, 171439},            --Shaded Weightstone (Mace & Staff)
    [6199] = {"AP", 16, 307719, 171438},            --Porous Weightstone (Mace & Staff)
    [6188] = {"damage", 220, 307118, 171285},       --Shadowcore Oil
    [6190] = {"heal", 330, 307119, 171286},         --Embalmer's Oil

    ----Ring----
    [6163] = {"crit", 12, 309612},          --Bargain of Critical Strike
    [6165] = {"haste", 12, 309613},         --Bargain of Haste
    [6167] = {"mastery", 12, 309614},       --Bargain of Mastery
    [6169] = {"versatility", 12, 309615},   --Bargain of Versatility

    [6164] = {"crit", 16, 309616},          --Tenet of Critical Strike
    [6166] = {"haste", 16, 309617},         --Tenet of Haste
    [6168] = {"mastery", 16, 309618},       --Tenet of Mastery
    [6170] = {"versatility", 16, 309619},   --Tenet of Versatility

    --Weapon
    [6195] = {"haste", 0, 310534},          --Infra-green Reflex Sight
    [6196] = {"crit", 0, 310533},           --Optical Target Embiggener
    [6229] = {"STR", 0, 309627},            --Celestial Guidance    sometimes increase your <Primary Stat> by 5%
    [6223] = {"AGI", 0, 309620},            --Lightless Force       send out a wave of Shadow energy in front of you
    [6226] = {"INT", 0, 309621},            --Eternal Grace         healing on the target of your helpful spells and abilities
    [6227] = {"STR", 0, 309622},            --Ascended Vigor        increase your healing received by 12% for 10 sec when taking damage
    [6228] = {"AGI", 0, 309623},            --Sinful Revelation     reveal the sins of your target, causing them to suffer an additional 6% damage from you

    --Chest
    [6216] = {"AGI", 20, 323762},           --Sacred Stats      All Stats +20
    [6230] = {"AGI", 30, 324773},           --Eternal Stats     All Stats +30
    [6214] = {"AGI", 20, 323760},           --Eternal Skirmish  increase your Strength or Agility by 20 and give your auto-attacks and auto-shots a chance to deal additional shadow damage
    [6213] = {"AGI", 20, 309535},           --Eternal Bulwark   +25 Armor & +20 Primary Stat
    [6217] = {"INT", 20, 323761},           --Eternal Bounds    +20 Intellect & +6% Mana
    [6265] = {"INT", 20, 342316},           --Eternal Insight   increase your Intellect by 20 and give your spells and abilities a chance to deal additional shadow damage

    --Wrist
    [6220] = {"INT", 15, 309609},           --Eternal Intellect
    [6219] = {"INT", 10, 309608},           --Illuminated Soul
    [6222] = {"hearthstone", 0, 309610},    --Shaded Hearthing

    --Hands
    [6205] = {"gather", 0, 309524},         --Shadowlands Gathering
    [6210] = {"STR", 15, 309526},           --Eternal Strength
    [6209] = {"STR", 10, 309525},           --Strength of Soul

    --Feet
    [6207] = {"fall", 0, 323609},           --Soul Treads
    [6211] = {"AGI", 15, 309534},           --Eternal Agility
    [6212] = {"AGI", 10, 309532},           --Agile Soulwalker

    --Back
    [6203] = {"stamina", 20, 309530},       --Fortified Avoidance
    [6204] = {"stamina", 20, 309531},       --Fortified Leech
    [6202] = {"stamina", 20, 309528},       --Fortified Speed
    [6208] = {"stamina", 30, 323755},       --Soul Vitality



    ----8 BFA----
    ----Ring----
    [5938] = {"crit", 4, 255094},          --Seal of Critical Strike
    [5939] = {"haste", 4, 255095},         --Seal of Haste
    [5940] = {"mastery", 4, 255096},       --Seal of Mastery
    [5941] = {"versatility", 4, 255097},   --Seal of Versatility

    [5942] = {"crit", 6, 255098},          --Pact of Critical Strike
    [5943] = {"haste", 6, 255099},         --Pact of Haste
    [5944] = {"mastery", 6, 255100},       --Pact of Mastery
    [5945] = {"versatility", 6, 255101},   --Pact of Versatility

    [6108] = {"crit", 9, 298011},          --Accord of Critical Strike
    [6109] = {"haste", 9, 298016},         --Accord of Haste
    [6110] = {"mastery", 9, 298002},       --Accord of Mastery
    [6111] = {"versatility", 9, 297999},   --Accord of Versatility

    ----Weapon----
    [5946] = {"heal", 0, 255105},           --Coastal Surge***
    [5948] = {"leech", 0, 255112},          --Siphoning***
    [5949] = {"spell", 0, 255131},          --Torrent of Elements       proc an aura which increases your elemental spell damage by 10%
    [5950] = {"speed", 0, 255143},          --Gale-Force Striking       increases your attack speed by 15% for 15 sec
    [5962] = {"versatility", 0, 268879},    --Versatile Navigation      +50 per stack, up to 10 stacks
    [5963] = {"haste", 0, 268897},          --Quick Navigation
    [5964] = {"mastery", 0, 268903},        --Masterful Navigation
    [5965] = {"crit", 0, 268909},           --Deadly Navigation
    [5966] = {"armor", 0, 268915},          --Stalwart Navigation

    [6112] = {"INT", 0, 300770},            --Machinist's Brilliance    occasionally increase Intellect and Mastery, Haste, or Critical Strike. Your highest stat is always chosen.
    [6148] = {"STR", 0, 300788},            --Force Multiplier          occasionally increase Strength or Agility and Mastery, Haste, or Critical Strike. Your highest stat is always chosen.
    [6150] = {"AGI", 0, 300789},            --Naga Hide                 When you Block, Dodge, or Parry, you have a chance to increase Strength or Agility
    [6149] = {"INT", 0, 298515},            --Oceanic Restoration       occasionally increase Intellect and restore mana

    ----7 LEG----
    ----Ring----
    [5423] = {"crit", 2, 190866},           --Word of Critical Strike
    [5424] = {"haste", 2, 190867},          --Word of Haste
    [5425] = {"mastery", 2, 190868},        --Word of Mastery
    [5426] = {"versatility", 2, 190869},    --Word of Versatility

    [5427] = {"crit", 3, 190870},           --Binding of Critical Strike
    [5428] = {"haste", 3, 190871},          --Binding of Haste
    [5429] = {"mastery", 3, 190872},        --Binding of Mastery
    [5430] = {"versatility", 3, 190873},    --Binding of Versatility
    
    ----Cloak----
    [5431] = {"STR", 2, 190874},            --Word of Strength
    [5432] = {"AGI", 2, 190875},            --Word of Agility
    [5433] = {"INT", 2, 190876},            --Word of Intellect

    [5434] = {"STR", 3, 190877},            --Binding of Strength
    [5435] = {"AGI", 3, 190878},            --Binding of Agility
    [5436] = {"INT", 3, 190879},            --Binding of Intellect
    
}

Narci.EnchantData = EnchantData;

local function GetEnchantDataByEnchantID(enchantID)
    return EnchantData[enchantID];
end

NarciAPI.GetEnchantDataByEnchantID = GetEnchantDataByEnchantID;


local TypeAbbr = {
	crit = "cri",	  --CRI
	haste = "has",	 --HAS
	mastery = "mst", --MST
	versatility = "ver",	 --VER
	STR = "str",	 --STR
	AGI = "agi",	 --AGI
	INT = "int",	 --INT
	speed = "spd",	 --SPD
	armor = "arm",	 --ARM
	heal = "hil", 	 --HIL
	leech = "bld",	 --BLD
	spell = "mgc",	 --MGC
    stamina = "con",    --constitution
    hearthstone = "hrt",
    gather = "gtr",
    damage = "dmg",
    fall = "fal",   --Fall Damage Reduction
    AP = "atk",
};

local LatinRunic = {
    a = "ᚨ",
    b = "ᛒ",
    c = "ᚲ",
    d = "ᛞ",
    e = "ᛖ",
    f = "ᚠ",
    g = "ᚷ",
    h = "ᚺ",
    i = "ᛁ",
    j = "ᛋ",
    k = "ᚴ",
    l = "ᛚ",
    m = "ᛗ",
    n = "ᚾ",
    o = "ᛟ",
    p = "ᛈ",
    q = "ᚳ",
    r = "ᚱ",
    s = "ᛊ",
    t = "ᛏ",
    u = "ᚢ",
    v = "ᚹ",
    w = "ᚢ",
    x = "ᛋ",
    y = "ᛁ",
    z = "ᛉ",
};

local RunicLetters = {};

for attribute, abbr in pairs(TypeAbbr) do
    local letter;
    local runic;
    local rune;
    for i = 1, 3 do
        letter = string.sub(abbr, i, i);
        runic = LatinRunic[letter];
        if i == 1 then
            rune = runic;
        else
            rune = rune.."\n"..runic;
        end
    end
    RunicLetters[attribute] = rune;
end

local function GetVerticalRunicLetters(attributeType)
    return RunicLetters[attributeType];
end

local function GetAttributeAbbrByEnchantID(enchantID)
    if EnchantData[enchantID] then
        return TypeAbbr[ EnchantData[enchantID][1] ]
    else
        return "enh"
    end
end

NarciAPI.GetVerticalRunicLetters = GetVerticalRunicLetters;
NarciAPI.GetAttributeAbbrByEnchantID = GetAttributeAbbrByEnchantID;
