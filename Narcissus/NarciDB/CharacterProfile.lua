local _, addon = ...
local TransmogDataProvider = addon.TransmogDataProvider;


local DB;
local CharacterData;   --NarciCharacterProfiles


local GetOutfitInfo = C_TransmogCollection.GetCustomSetInfo or C_TransmogCollection.GetOutfitInfo;
local GetOutfits = C_TransmogCollection.GetCustomSets or C_TransmogCollection.GetOutfits;
local GetOutfitItemTransmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList or C_TransmogCollection.GetOutfitItemTransmogInfoList;


local ProfileAPI = {};
addon.ProfileAPI = ProfileAPI;

local _, CURRENT_SERVER_ID, CURRENT_PLAYER_UID = strsplit("-", UnitGUID("player"));
if CURRENT_SERVER_ID then
    CURRENT_SERVER_ID = tonumber(CURRENT_SERVER_ID);
end

function ProfileAPI:GetCurrentPlayerUID()
    return CURRENT_PLAYER_UID
end

function ProfileAPI:Init()
    if CharacterData then return end;

    if not NarciCharacterProfiles then
        NarciCharacterProfiles = {};
    end
    DB = NarciCharacterProfiles;

    --Create this character table, playerUID as key
    local serverID, playerUID = CURRENT_SERVER_ID, CURRENT_PLAYER_UID;
    if not playerUID then return end;

    CharacterData = DB[playerUID];
    if not (CharacterData and type(CharacterData) == "table") then
        DB[playerUID] = {};
        CharacterData = DB[playerUID];
        CharacterData.birth = time();
    end

    if CharacterData then
        CharacterData.name = UnitName("player");
        CharacterData.serverID = serverID;
        CharacterData.lastVisit = time();

        local _, raceID, classID;
        _, _, raceID= UnitRace("player");
        CharacterData.race = raceID;

        _, _, classID= UnitClass("player");
        CharacterData.class = classID;
    end

    local total = 0;
    for uid, data in pairs(DB) do
        total = total + 1;
        if data.serverID then
            data.serverID = tonumber(data.serverID);
        end
    end

    if NarcissusDB then
        if not NarcissusDB.RealmNames then
            NarcissusDB.RealmNames = {};
        end

        local realmID = GetRealmID();
        local realmName = GetRealmName();

        if realmID and realmName then
            NarcissusDB.RealmNames[realmID] = realmName;
        end
    end
end

function ProfileAPI:SaveOutfits()
    self:Init();


    local outfitIDs =  GetOutfits();
    local numOutfits = (outfitIDs and #outfitIDs) or 0;

    CharacterData.outfits = {};

    local outfitID, name;
    for i = 1, numOutfits do
        outfitID = outfitIDs[i];
        name = GetOutfitInfo(outfitID);
        CharacterData.outfits[i] = {
            n = name;
            s = TransmogDataProvider:ConvertTransmogListToString(GetOutfitItemTransmogInfoList(outfitID))
        };
    end
end

local function SortByName(uid1, uid2)
    local data1 = DB[uid1];
    local data2 = DB[uid2];
    if data1.name == data2.name then
        return data1.serverID < data2.serverID
    else
        return data1.name < data2.name
    end
end


local function SortByServer(uid1, uid2)
    local data1 = DB[uid1];
    local data2 = DB[uid2];
    if data1.serverID == data2.serverID then
        return data1.name < data2.name
    else
        return data1.serverID < data2.serverID
    end
end

local function SortByRecent(uid1, uid2)
    local data1 = DB[uid1];
    local data2 = DB[uid2];
    return data1.lastVisit > data2.lastVisit
end

local SortMethodFuncs = {
    name = SortByName,
    recent = SortByRecent,
    server = SortByServer,
};

local function Filter_None()
    return true
end

local function Filter_AnyOutfit(data)
    return data.outfits and #data.outfits > 0
end

local DataFilters = {
    none = Filter_None,
    outfit = Filter_AnyOutfit,
};

function ProfileAPI:GetRoster(filter, sortMethod)
    self:Init();

    local uidList = {};
    local total = 0;
    local ignored = 0;

    local filterFunc;
    if type(filter) == "function" then
        filterFunc = filter;
    else
        filterFunc = filter and DataFilters[filter];
    end

    if filterFunc then
        for uid, data in pairs(DB) do
            if filterFunc(data) then
                total = total + 1;
                uidList[total] = uid;
            else
                ignored = ignored + 1;
            end
        end
    else
        for uid, data in pairs(DB) do
            total = total + 1;
            uidList[total] = uid;
        end
    end

    local sortFunc = sortMethod and SortMethodFuncs[sortMethod];
    if sortFunc then
        table.sort(uidList, sortFunc);
    end

    return uidList, total, ignored
end

function ProfileAPI:GetPlayerInfo(uid, key)
    if DB[uid] then
        if key then
            return DB[uid][key]
        else
            return DB[uid]
        end
    end
end

function ProfileAPI:GetPlayerName(uid, colorized)
    local name = self:GetPlayerInfo(uid, "name");
    if name then
        if colorized then
            name = NarciAPI.WrapNameWithClassColor(name, self:GetPlayerInfo(uid, "class"));
        end
        return name
    end
end

function ProfileAPI:GetOutfits(uid)
    return self:GetPlayerInfo(uid, "outfits")
end

function ProfileAPI:GetNumOutfits(uid)
    local outfits = self:GetOutfits(uid);
    return outfits and #outfits or 0
end

function ProfileAPI:DeleteCharacterOutfits(uid)
    local data = self:GetPlayerInfo(uid);
    if data then
        data.outfits = {};
    end
end

function ProfileAPI:GetCharacterLastVisit(uid)
    -- return X days/months ago
    local data = self:GetPlayerInfo(uid);
    if data and data.lastVisit then
        local current = time();
        return NarciAPI.ConvertSecondsToTimePassed(current - data.lastVisit);
    end
end

function ProfileAPI:GetRealmName(realmID)
    if realmID and NarcissusDB and NarcissusDB.RealmNames then
        return NarcissusDB.RealmNames[realmID]
    end
end

local GetRaceInfo = C_CreatureInfo.GetRaceInfo;
local GetClassInfo = C_CreatureInfo.GetClassInfo;

function ProfileAPI:CopyBasicInfo(uid)
    local data = self:GetPlayerInfo(uid);
    if data then
        local raceName, className;
        local info = GetRaceInfo(data.race);
        if info then
            raceName = info.raceName;
        end
        info = GetClassInfo(data.class);
        if info then
            className = info.className;
        end
        return {
            uid = uid,
            name = data.name,
            classID = data.class,
            raceID = data.race,
            serverID = data.serverID,
            lastVisit = data.lastVisit,
            raceName = raceName,
            className = className,
            fromOtherServer = CURRENT_SERVER_ID ~= data.serverID,
        }
    end
end
