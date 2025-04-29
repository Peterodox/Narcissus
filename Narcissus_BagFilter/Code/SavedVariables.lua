-- Based on Update --
local VERSION = "1.0.1";
local VERSION_NUMBER = 10010;

local TIME_SINCE_LAST_UPDATE = 0;
do
    local VERSION_DATE = 1663379876;
    TIME_SINCE_LAST_UPDATE = ((time and time()) or (VERSION_DATE)) - VERSION_DATE;
    if TIME_SINCE_LAST_UPDATE < 0 then
        TIME_SINCE_LAST_UPDATE = 0;
    end
end

local ADDON_VERSION_UPDATED = false;


-- SavedVariables: NarcissusBagFilterDB

local _, addon = ...

local SettingFunctions = {};
addon.SettingFunctions = SettingFunctions;

NarciBagItemFilterSettings = SettingFunctions;  --Global


local DefaultValues = {
    --Search Suggestion
    SearchSuggestEnable = true,
    SearchSuggestAnchor = 1,
    SearchSuggestDirection = 1;
    AutoFilterMail = true,
    AutoFilterAuction = true,
    AutoFilterGem = true,
};


local function IsAddonJustUpdated()
    return ADDON_VERSION_UPDATED;
end

addon.IsAddonJustUpdated = IsAddonJustUpdated;


local function GetVersionInfo()
    local installTime = NarcissusBagFilterDB.installTime;
    if not installTime then
        installTime = time();
    end
    local dateString;
    local timeString = date("%d %m %y", installTime);
    local day, month, year = string.split(" ", timeString);
    if day and month and year then
        day = tonumber(day);
        month = tonumber(month);
        year = tonumber(year);
        dateString = FormatShortDate(day, month, year);
    end

    -- time since last update
    local timeDiff;
    local days = math.floor(TIME_SINCE_LAST_UPDATE / 86400 + 0.5);
    if days > 2 then
        if days < 60 then
            timeDiff = (D_DAYS and D_DAYS:format(days)) or days.." Days";
            timeDiff = string.format("%s ago", timeDiff);
        else
            local months = math.floor(days / 30.5 + 0.5);
            timeDiff = string.format("%d Months ago");
        end
    else
        timeDiff = string.lower(KBASE_RECENTLY_UPDATED or "recently updated");
    end

    return VERSION, dateString, timeDiff
end

addon.GetVersionInfo = GetVersionInfo;



local function LoadSettings()
    local db = NarcissusDB;
    if db then
        for _, func in pairs(SettingFunctions) do
            func(nil, db);
        end
    end
end

local function InitDatabase()
    --[[
    local type = type;

    local db = NarcissusDB;

    for k, v in pairs(DefaultValues) do
        if (db[k] == nil) or (type(db[k]) ~= type(v)) then
            db[k] = v;
        end
    end

    if not db.installTime or type(db.installTime) ~= "number" then
        db.installTime = time();
    end

    if not db.version or (type(db.version) == "number" and db.version < VERSION_NUMBER) then
        db.version = VERSION_NUMBER;
        ADDON_VERSION_UPDATED = true;
    end
    --]]

    C_Timer.After(0, function()
        LoadSettings();
    end);
end


local f = CreateFrame("Frame");
f:RegisterEvent("ADDON_LOADED");
f:SetScript("OnEvent",function(self,event,...)
    local name = ...
    if name == "Narcissus_BagFilter" then
        self:UnregisterEvent(event);
        InitDatabase();
    end
end)