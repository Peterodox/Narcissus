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



local COLOR_PRESETS = {
    red = {0.9333, 0.1961, 0.1412},
    green = {0.4862, 0.7725, 0.4627},
    yellow = {0.9882, 0.9294, 0},
    grey = {0.4, 0.4, 0.4},
    focused = {0.8, 0.8, 0.8},
    disabled = {0.2, 0.2, 0.2},
};

local function GetColorByKey(k)
    if COLOR_PRESETS[k] then
        return COLOR_PRESETS[k][1], COLOR_PRESETS[k][2], COLOR_PRESETS[k][3]
    else
        return 0.5, 0.5, 0.5
    end
end
API.GetColorByKey = GetColorByKey;


do
    local version = GetBuildInfo();
    local expansionID = string.match(version, "(%d+)%.");
	local isDF = (tonumber(expansionID) or 1) >= 10;
	
    local function IsDragonflight()
        return isDF
    end

    addon.IsDragonflight = IsDragonflight;
end