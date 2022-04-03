local _, addon = ...

NarciGamePadAPI = {};

local ACTION_GOUPS = {};
addon.actionGroups = ACTION_GOUPS;


local MAPPING_XBOX = {
    ["A"] = 1,
    ["B"] = 2,
    ["X"] = 3,
    ["Y"] = 4,
};

local ACTIVE_MAPPING = MAPPING_XBOX;

local function GetPadKeyIndexByName(name)
    return ACTIVE_MAPPING[name] or 0
end

addon.GetPadKeyIndexByName = GetPadKeyIndexByName;