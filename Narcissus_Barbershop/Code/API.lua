local _, addon = ...

local API = {};
addon.API = API;


local ACTIVE_APPEARANCE_NAME;

local UnitRace = UnitRace;


local function GetPlayerRaceID()
    local _, _, raceID = UnitRace("player");
    if raceID == 25 or raceID == 26 then
        raceID = 24;        --Neutral Pandaren
    end
    return raceID
end
API.GetPlayerRaceID = GetPlayerRaceID;


local function SetActiveAppearanceName(name)
    ACTIVE_APPEARANCE_NAME = name;
end
API.SetActiveAppearanceName = SetActiveAppearanceName;


local function GetActiveAppearanceName(name)
    return ACTIVE_APPEARANCE_NAME
end
API.GetActiveAppearanceName = GetActiveAppearanceName;


local function IsMultiFormRace(raceID)
    return raceID == 22 or raceID == 52 or raceID == 70
end
API.IsMultiFormRace = IsMultiFormRace;


local function IsPlayerMultiForm()
    local raceID = GetPlayerRaceID();
    return IsMultiFormRace(raceID)
end
API.IsPlayerMultiForm = IsPlayerMultiForm;


local COLOR_PRESETS = {
    red = {0.9333, 0.1961, 0.1412},
    green = {0.4862, 0.7725, 0.4627},
    yellow = {0.9882, 0.9294, 0},
    grey = {0.4, 0.4, 0.4},
    focused = {0.8, 0.8, 0.8},
    disabled = {0.2, 0.2, 0.2},
};
COLOR_PRESETS.gray = COLOR_PRESETS.grey;

local function GetColorByKey(k)
    if COLOR_PRESETS[k] then
        return COLOR_PRESETS[k][1], COLOR_PRESETS[k][2], COLOR_PRESETS[k][3]
    else
        return 0.5, 0.5, 0.5
    end
end
API.GetColorByKey = GetColorByKey;

local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local GetClassInfo = GetClassInfo;
local FORMAT_PLAYER_REALM = "%s|cff666666 - |r|cffcccccc%s|r";
local format = string.format;

local function FormatPlayerName(playerName, realmName, classID)
    if classID then
        local _, classFile = GetClassInfo(classID)
        local classColorString = classFile and RAID_CLASS_COLORS[classFile] and RAID_CLASS_COLORS[classFile].colorStr;
        if classColorString then
            playerName = format("|c%s%s|r", classColorString, playerName);
        end
    end

    return format(FORMAT_PLAYER_REALM, playerName, realmName);
end
API.FormatPlayerName = FormatPlayerName;

do
    --local version = GetBuildInfo();
    --local expansionID = string.match(version, "(%d+)%.");
	--local isDF = (tonumber(expansionID) or 1) >= 10;
end

do
    local PIXEL = 1;
    local _, screenHeight = GetPhysicalScreenSize();
    PIXEL = 768/screenHeight;

    addon.pixel = PIXEL;
end

local DRUID_CHR_MODEL = {
    [189] = 5,   --Bear
    [190] = 1,   --Cat
    [194] = 31,  --Moonkin
    [193] = 29,  --Flight
    [191] = 4,   --Aquatic
    [192] = 3,   --Travel
};

local PET_CHR_MODEL = { --Customizable Pet
    --[chrModelID] = speciesID
    [212] = 4793,   --Weechi
};

local SHAPESHIFT_SPELLS = {
    [1]  = 768,     --Cat
    [2]  = 53691,   --Tree of Life
    [3]  = 783,     --Travel
    [4]  = 276012,  --Aquatic
    [5]  = 5487,    --Bear
    [29] = 165962,  --Flight
    [31] = 24858,   --Moonkin
    [36] = 114282,  --Treant
};


local SUPPORTED_FORMS = {
    [31] = true,    --Moonkin
};

local function IsFormSavable(formID)
    --formID = nil when viewing unshapeshift character
    return (not formID) or (formID and SUPPORTED_FORMS[formID])
end
API.IsFormSavable = IsFormSavable;

local function GetShapeshiftFormName(formID)
    local spellID = formID and SHAPESHIFT_SPELLS[formID];
    if spellID then
        local info = C_Spell.GetSpellInfo(spellID);
        if info then
            return info.name
        end
    end
end

local function GetMountNameByID(mountID)
    local name = C_MountJournal.GetMountInfoByID(mountID);
    return name
end

local MOUNT_CHR_MODEL = {
    --Dragonriding
    --/dump GetMouseFoci()[1].mountID
    [124] = 1589,
    [129] = 1590,
    [123] = 1563,
    [126] = 1591,
    [125] = 1588,
    [149] = 1744,
    [188] = 1830,
    [186] = 1792,   --Algarian Stormrider
    [202] = 2144,   --Delver's Dirigible
    [206] = 2296,   --Delver's Gob-Trotter
    [207] = 2512,   --Delver's Mana-skimmer
};

local function IsDragonridingChrModel(chrModelID)
    return chrModelID and MOUNT_CHR_MODEL[chrModelID] ~= nil
end
API.IsDragonridingChrModel = IsDragonridingChrModel;

local function GetChrModelName(chrModelID)
    if DRUID_CHR_MODEL[chrModelID] then
        local formID = DRUID_CHR_MODEL[chrModelID];
        return GetShapeshiftFormName(formID);
    end

    if MOUNT_CHR_MODEL[chrModelID] then
        local mountID = MOUNT_CHR_MODEL[chrModelID];
        return GetMountNameByID(mountID);
    end

    if PET_CHR_MODEL[chrModelID] then
        local speciesID = PET_CHR_MODEL[chrModelID];
        return C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    end
end
API.GetChrModelName = GetChrModelName;


--Camera Profiles---
local CAMERA_DATA_FILEID = {
    --/dump DressUpFrame.ModelScene:GetPlayerActor():GetModelFileID()
    [5548261] = {3.14, -0.11, -1.56, 0.52},     --Earthen M
    [5548259] = {3.25, -0.01, -1.56, 0.44},     --Earthen F

    [4207724] = {3.1, -0.58, -2.6, 0.52},       --Dracthyr 1554
    [4395382] = {3.38, 0.07, -1.88, 0.43},      --Visage M Dracthyr-alt 1583 (Void Elf)
    [4220488] = {3.51, -0.025, -1.745, 0.43},   --Visage F (Human)

    [878772] = {3.24, -0.08, -1.34, 0.44},      --Dwarf M
    [950080] = {3.43, -0.02, -1.34, 0.44},      --Dwarf F
    [1890765] = {3.24, -0.08, -1.34, 0.44},     --darkirondwarf-male
    [1890763] = {3.43, -0.02, -1.34, 0.44},     --DarkIron F

    [1721003] = {3.06, -0.05, -2.32, 0.43},     --kultiran-male
    [1886724] = {3.34, -0.01, -2.21, 0.43},     --kultiran-female

    [2622502] = {3.23, -0.05, -0.93, 0.43},     --mechagnome-male
    [2564806] = {3.37, -0.07, -0.9, 0.43},      --mechagnome-female

    [1890761] = {3.33, -0.05, -1.09, 0.26},     --vulpera-male
    [1890759] = {3.33, -0.04, -1.09, 0.26},     --vulpera-female

    [1630218] = {1.85, -0.35, -2.2, 0.43},      --highmountaintauren-male
    [1630402] = {2.82, -0.35, -2.4, 0.52},      --highmountaintauren-female

    [900914] = {3.23, -0.01, -0.92, 0.43},      --Gnome M
    [940356] = {3.37, -0.07, -0.9, 0.43},       --Gnome F

    [119376] = {3.24, 0, -1.08, 0.43},          --goblin-male
    [119369] = {3.40, -0.03, -1.14, 0.43},      --goblin-female

    [1005887] = {2.94, -0.19, -2.24, 0.43},     --draenei-male
    [1022598] = {3.40, -0.09, -2.14, 0.35},     --draenei F

    [1620605] = {2.94, -0.19, -2.24, 0.43},     --lightforgeddraenei-male
    [1593999] = {3.40, -0.09, -2.14, 0.35},     --lightforgeddraenei-female

    [1630447] = {3.16, 0.05, -2.55, 0.52},      --zandalaritroll M
    [1662187] = {3.35, 0.04, -2.51, 0.44},      --zandalaritroll F

    [1022938] = {2.79, -0.19, -2.01, 0.43},     --troll-male
    [1018060] = {3.43, 0.035, -2.19, 0.35},     --troll-female

    [959310] = {3.37, 0.03, -1.6, 0.43},        --scourge-male
    [997378] = {3.39, -0.035, -1.665, 0.43},    --scourge-female

    [535052] = {3.14, -0.11, -2.11, 0.43},      --pandaren M
    [589715] = {3.1, -0.16, -1.95, 0.43},       --pandaren F

    [307454] = {2.41, -0.18, -1.93, 0.43},      --worgen-male
    [307453] = {3.06, -0.04, -2.19, 0.52},      --worgen-female

    [917116] = {2.79, -0.06, -1.84, 0.35},      --magharorc-male hunched
    [1968587] = {3.11, -0.02, -2.08, 0.35},     --magharorc-male upright
    [949470] = {3.59, -0.02, -1.87, 0.35},      --magharorc-female

    [1011653] = {3.38, -0.04, -1.87, 0.35},     --Human M
    [1000764] = {3.51, -0.025, -1.745, 0.43},   --Human F

    [1814471] = {3.37, 0.01, -2.26, 0.35},      --Nightborne M
    [1810676] = {3.40, 0.05, -2.09, 0.43},      --Nightborne F

    [1734034] = {3.38, 0.07, -1.88, 0.43},      --VE M
    [1733758] = {3.54, -0.02, -1.75, 0.35},     --VE F

    [1100087] = {3.38, 0.07, -1.88, 0.43},      --BE M
    [1100258] = {3.54, -0.02, -1.75, 0.35},     --BE F

    [974343] = {3.26, -0.07, -2.21, 0.43},      --NE M
    [921844] = {3.38, -0.06, -2.09, 0.43},      --NE F


    --Dragonriding
    [4278602] = {-6.76, -1.98, -1.98, 0.61},    --Renewed Proto-drake   --{-20.58, -3.59, -4.9, 0.61}
    [4281540] = {-20.58, -3.77, -6.32, 0.61},   --Windrborne Velocidrake
    [4227968] = {-0.59, -1.86, -2.57, 0.44},    --Highland Drake
    [4252337] = {0.26, -0.74, -1.2, 0.44},      --Cliffside Wylderdrake
    [4252339] = {1.79, -5.96, -3.69, 0.78},     --Winding Slitherdrake   --{1.95, 5.96, -3.73, -0.79} --left face
    [5143343] = {-0.59, -1.86, -2.57, 0.44},    --Grotto Netherwing Drake
    [5228774] = {-0.24, -1.38, -2.56, 0.44},    --Flourishing Whimsydrake
    [5305977] = {0.2, -0.5, -1.87, 0.35},       --Algarian Stormrider
    [5486691] = {-2.75, -0.37, -1.76, 0.78},    --Delver's Dirigible (S1, S2, S3 mounts share the same file)


    --Druid
    [1139162] = {1.73, -0.22, -2.48, 0.61},     --Moonkin, Classic
    [5154480] = {1.7, -0.34, -2.55, 0.61},      --Moonkin, New Customizable
    [2205511] = {1.75, -0.21, -2.48, 0.61},     --Moonkin, Full Transform, Kul Tiran
    [1139164] = {1.75, -0.23, -2.46, 0.61},     --Moonkin, Full Transform, Tauren
    [2393672] = {1.67, -0.24, -2.49, 0.61},     --Moonkin, Full Transform, Highmountain Tauren
    [1949828] = {3.08, -0.2, -1.55, 0.61},      --Moonkin, Full Transform, Zandalari


    --Pet
    [6597704] = {2.91, -0.1, -0.55, 0.52},     --Weechi
};

CAMERA_DATA_FILEID[968705] = CAMERA_DATA_FILEID[1630218];   --Tauren
CAMERA_DATA_FILEID[986648] = CAMERA_DATA_FILEID[1630402];   --Tauren
CAMERA_DATA_FILEID[4675519] = CAMERA_DATA_FILEID[4278602];  --Storm-Easter Vault of the Incarnates
CAMERA_DATA_FILEID[4571488] = CAMERA_DATA_FILEID[4227968];  --Crimson Gladiator PvP
CAMERA_DATA_FILEID[4954741] = CAMERA_DATA_FILEID[4227968];  --Elemental Drake Aberrus
CAMERA_DATA_FILEID[4995347] = CAMERA_DATA_FILEID[4252339];  --Obsidian Gladiator

local function GetPortraitCameraInfoByModelFileID(fileID)
    --print(fileID)
    if fileID and CAMERA_DATA_FILEID[fileID] then
        return CAMERA_DATA_FILEID[fileID]
    end
end
API.GetPortraitCameraInfoByModelFileID = GetPortraitCameraInfoByModelFileID;


local function GetRaceIcon(raceID, sex, isAlteredForm)
    --Actually Atlas
    local info = C_CreatureInfo.GetRaceInfo(raceID);
    if info then
        local sexName = sex == 0 and "male" or "female";
        local fileName = string.lower(info.clientFileString);
        if isAlteredForm then
            if fileName == "dracthyr" then
                fileName = "dracthyrvisage";
            elseif fileName == "worgen" then
                fileName = "human";
            end
        end
        return string.format("raceicon-%s-%s", fileName, sexName);
    end
end
API.GetRaceIcon = GetRaceIcon;

--[[
local CAMERA_PROFILES_BY_RACE = {
    --modelX, modelY, modelZ, facing
    bloodelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    voidelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    draenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    lightforgeddraenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    dwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    darkirondwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    gnome = {
        male = {3.23, -0.01, -0.92, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    mechagnome = {
        male = {3.23, -0.05, -0.93, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    goblin = {
        male = {3.24, 0, -1.08, 0.43},
        female = {3.40, -0.03, -1.14, 0.43},
    },

    human = {
        male = {3.38, -0.04, -1.87, 0.35},
        female = {3.51, -0.025, -1.745, 0.43},
    },

    kultiran = {
        male = {3.06, -0.05, -2.32, 0.43},
        female = {3.34, -0.01, -2.21, 0.43},
    },

    nightborne = {
        male = {3.37, 0.01, -2.26, 0.35},
        female = {3.40, 0.05, -2.09, 0.43},
    },

    nightelf = {
        male = {3.26, -0.07, -2.21, 0.43},
        female = {3.38, -0.06, -2.09, 0.43},
    },

    orc = {
        male = {2.79, -0.06, -1.84, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    uprightorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    magharorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    pandaren = {
        male = {3.14, -0.11, -2.11, 0.43},
        female = {3.1, -0.16, -1.95, 0.43},
    },

    tauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    highmountaintauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    troll = {
        male = {2.79, -0.19, -2.01, 0.43},
        female = {3.43, 0.035, -2.19, 0.35},
    },

    scourge = {
        male = {3.37, 0.03, -1.6, 0.43},
        female = {3.39, -0.035, -1.665, 0.43},
    },

    vulpera = {
        male = {3.33, -0.05, -1.09, 0.26},
        female = {3.33, -0.04, -1.09, 0.26},
    },

    worgen = {
        male = {2.41, -0.18, -1.93, 0.43},
        female = {3.06, -0.04, -2.19, 0.52},
    },

    zandalaritroll = {
        male = {3.16, 0.05, -2.55, 0.52},
        female = {3.35, 0.04, -2.51, 0.44},
    },

    dracthyr = {
        male = {3.1, -0.58, -2.6, 0.52},
        female = {3.1, -0.58, -2.6, 0.52},
    },
};
--]]