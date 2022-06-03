local _, addon = ...

local MogAPI = C_TransmogCollection;
local PlayerHasTransmog = MogAPI.PlayerHasTransmogItemModifiedAppearance;
local IsAppearanceFavorite = MogAPI.GetIsAppearanceFavorite;
local GetSourceInfo = MogAPI.GetSourceInfo;

local CreateItemTransmogInfo = ItemUtil.CreateItemTransmogInfo;
local GetItemInfoInstant = GetItemInfoInstant;
local strsplit = strsplit;

local DataProvider = {};
addon.TransmogDataProvider = DataProvider;

local ValidSlotForSecondaryAppearance = {
    [16] = true,
    [17] = true,
};

do
    local version, build, date, tocversion = GetBuildInfo();
    if tocversion and tocversion > 90005 then
        --Use New API
        ValidSlotForSecondaryAppearance[3] = true;

        function DataProvider:GetIllusionName(illusionID)
            return MogAPI.GetIllusionStrings(illusionID)
        end

        function DataProvider:GetIllusionInfo(illusionID)
            local illusionInfo = MogAPI.GetIllusionInfo(illusionID);
            if illusionInfo then
                return illusionInfo.visualID, self:GetIllusionName(illusionID), illusionInfo.icon, illusionInfo.isCollected;
            end
        end

        function DataProvider:GetIllusionSourceText(illusionID)
            local name, hyperlink, sourceText = MogAPI.GetIllusionStrings(illusionID);
            return sourceText
        end
    else
        function DataProvider:GetIllusionName(illusionID)
            local _, name= MogAPI.GetIllusionSourceInfo(illusionID);
            return name;
        end

        function DataProvider:GetIllusionInfo(illusionID)
            local visualID, name, hyperlink, icon = MogAPI.GetIllusionSourceInfo(illusionID);
            return visualID, name, icon, false
        end

        function DataProvider:GetIllusionSourceText(illusionID)
            if not self.illusionSources then
                self.illusionSources = {};
                local illusionList = MogAPI.GetIllusions();
                for i, illusionInfo in pairs(illusionList) do
                    self.illusionSources[illusionInfo.sourceID] = illusionInfo.sourceText;
                end
            end
            return self.illusionSources[illusionID]
        end
    end
end


function DataProvider:GetVisualIDBySourceID(sourceID)
    if sourceID and sourceID > 0 then
        local info = MogAPI.GetAppearanceInfoBySource(sourceID);
        if info then
            return info.appearanceID
        else
            return 0
        end
    else
        return 0
    end
end

function DataProvider:IsSourceFavorite(sourceID)
    return IsAppearanceFavorite( self:GetVisualIDBySourceID(sourceID) )
end

function DataProvider:FindKnownSource(sourceID)
    if not sourceID then return end;
    local isKnown;
    if PlayerHasTransmog(sourceID) then
        return sourceID, true
    else
        if not self.sourceIDxKnownSourceID then
            self.sourceIDxKnownSourceID = {};
        end
        local knownID = self.sourceIDxKnownSourceID[sourceID];
        if knownID then
            return knownID, PlayerHasTransmog(knownID);
        end
        local sourceInfo = GetSourceInfo(sourceID);
        if sourceInfo then
            local visualID = sourceInfo.visualID;
            local sources = MogAPI.GetAllAppearanceSources(visualID);
            for i = 1, #sources do
                if sourceID ~= sources[i] then
                    if PlayerHasTransmog(sources[i]) then
                        isKnown = true;
                        self.sourceIDxKnownSourceID[sourceID] = sources[i];
                        sourceID = sources[i];
                        break
                    end
                end
            end
        end
    end

    return sourceID, isKnown
end

function DataProvider:FindKnwonSourceByVisualID(visualID)
    local isKnown, sourceID;
    local sources = MogAPI.GetAllAppearanceSources(visualID);
    for i = 1, #sources do
        if not sourceID then
            sourceID = sources[i];
        end

        if PlayerHasTransmog(sources[i]) then
            sourceID = sources[i];
            isKnown = true;
            break
        end
    end
    return sourceID, isKnown
end

function DataProvider:GetSourceIDFromTransmogInfo(transmogInfo)
    if transmogInfo then
        if transmogInfo.illusionID and transmogInfo.illusionID > 0 then
            return transmogInfo.appearanceID, transmogInfo.illusionID
        else
            return transmogInfo.appearanceID, transmogInfo.secondaryAppearanceID
        end
    end
end

function DataProvider:CanHaveSecondaryAppearanceForSlotID(slotID)
    return ValidSlotForSecondaryAppearance[slotID];
end

function DataProvider:GetSourceName(sourceID)
    local sourceInfo = GetSourceInfo(sourceID);
    if not sourceInfo then return end;
    return sourceInfo.name
end


DataProvider.isBow = {};

function DataProvider:IsSourceBow(sourceID)
    --Cache this cuz it might be frequently used
    if self.isBow[sourceID] == nil then
        local sourceInfo = GetSourceInfo(sourceID);
        if sourceInfo then
            local _, _, _, itemEquipLoc = GetItemInfoInstant(sourceInfo.itemID);
            self.isBow[sourceID] = itemEquipLoc == "INVTYPE_RANGED";
        end
    end
    return self.isBow[sourceID]
end




--Convert TransmogInfoList into string and vice versa
--Format: transmogInfo.appearanceID:secondaryAppearanceID:illusionID    (slot delimiter ",")
--Example: 123456:0:123

local TransmogSlotOrder = {
	INVSLOT_HEAD,       --1
	INVSLOT_SHOULDER,   --3
	INVSLOT_BACK,       --15
	INVSLOT_CHEST,      --5
	INVSLOT_BODY,       --4
	INVSLOT_TABARD,     --19
	INVSLOT_WRIST,      --9
	INVSLOT_HAND,       --10
	INVSLOT_WAIST,      --6
	INVSLOT_LEGS,       --7
	INVSLOT_FEET,       --8
	INVSLOT_MAINHAND,   --16
	INVSLOT_OFFHAND,    --17
};

function DataProvider:ConvertTransmogListToString(itemTransmogInfoList)
    if not (itemTransmogInfoList and type(itemTransmogInfoList) == "table") then return end

    local transmogString;
    local slotString;
    local transmogInfo;
    local primaryID, secondaryID, illusionID;

    for i, slotID in ipairs(TransmogSlotOrder) do
        transmogInfo = itemTransmogInfoList[slotID];
        if transmogInfo then
            primaryID = transmogInfo.appearanceID or 0;

            if transmogInfo.secondaryAppearanceID and transmogInfo.secondaryAppearanceID ~= 0 then
                secondaryID = transmogInfo.secondaryAppearanceID;
            else
                secondaryID = nil;
            end

            if transmogInfo.illusionID and transmogInfo.illusionID ~= 0 then
                illusionID = transmogInfo.illusionID;
            else
                illusionID = nil;
            end

            if secondaryID then
                if illusionID then
                    slotString = primaryID..":"..secondaryID..":"..illusionID;
                else
                    slotString = primaryID..":"..secondaryID;
                end
            elseif illusionID then
                slotString = primaryID..":0:"..illusionID;
            else
                slotString = primaryID;
            end
        else
            slotString = 0;
        end

        if transmogString then
            transmogString = transmogString..","..slotString;
        else
            transmogString = slotString;
        end
    end

    return transmogString
end

local function FormatAppearanceID(id)
    if id then
        return tonumber(id) or 0;
    else
        return 0
    end
end


function DataProvider:ConvertTransmogStringToList(itemTransmogString)
    local slotStrings = {strsplit(",", itemTransmogString)};

    local slotString;
    local primaryID, secondaryID, illusionID;

    local itemTransmogInfoList = {};

    for i, slotID in ipairs(TransmogSlotOrder) do
        slotString = slotStrings[i];
        if slotString then
            primaryID, secondaryID, illusionID = strsplit(":", slotString);
            primaryID = FormatAppearanceID(primaryID);
            secondaryID = FormatAppearanceID(secondaryID);
            illusionID = FormatAppearanceID(illusionID);
        else
            primaryID, secondaryID, illusionID = 0, 0, 0;
        end

        itemTransmogInfoList[slotID] = CreateItemTransmogInfo(primaryID, secondaryID, illusionID);
    end

    return itemTransmogInfoList
end


---- Read BetterWardrobe Extra Saved Outfits ----
local function IsBWDatabaseValid()
    return (BetterWardrobe_ListData and BetterWardrobe_ListData.OutfitDB and BetterWardrobe_ListData.OutfitDB.char)
    and (BetterWardrobe_SavedSetData and BetterWardrobe_SavedSetData.global and BetterWardrobe_SavedSetData.global.sets)
end

local function GetBWNumOutfits(profileKey, setType)
    if setType then
        if setType == "SavedExtra" then
            return BetterWardrobe_ListData.OutfitDB.char[profileKey] and BetterWardrobe_ListData.OutfitDB.char[profileKey].outfits and #BetterWardrobe_ListData.OutfitDB.char[profileKey].outfits or 0
        elseif setType == "SavedBlizzard" then
            return BetterWardrobe_SavedSetData.global.sets[profileKey] and #BetterWardrobe_SavedSetData.global.sets[profileKey] or 0
        end
    else
        return GetBWNumOutfits(profileKey, "SavedExtra") + GetBWNumOutfits(profileKey, "SavedBlizzard")
    end
end

function DataProvider:IsBWDatabaseValid()
    return IsBWDatabaseValid()
end

function DataProvider:GetBWCharacters(includeNoOutfitChar)
    if not IsBWDatabaseValid() then return {} end;

    local profileData = {};
    local profileKeys = {};
    local total = 0;

    local playerName, realmName, numOutfits;
    local match = string.match;

    if includeNoOutfitChar then
        for profileKey in pairs(BetterWardrobe_SavedSetData.profileKeys) do
            total = total + 1;
            playerName, realmName = match(profileKey, "(.+) %- (.+)");
            numOutfits = GetBWNumOutfits(profileKey);
            profileData[total] = {profileKey, playerName or profileKey, realmName, numOutfits};
        end
    else
        for profileKey in pairs(BetterWardrobe_SavedSetData.profileKeys) do
            numOutfits = GetBWNumOutfits(profileKey);
            if numOutfits > 0 then
                total = total + 1;
                playerName, realmName = match(profileKey, "(.+) %- (.+)");
                profileData[total] = {profileKey, playerName or profileKey, realmName, numOutfits};
            end
        end
    end

    local function SortByRealmThenName(a, b)
        --character name first, then realm name
        if a[2] and b[2] and a[3] and b[3] then
            if a[2] == b[2] then    --same name
                return a[3] < b[3]
            else
                return a[2] < b[2]
            end
        else
            return a[1] < b[1]
        end
    end

    table.sort(profileData, SortByRealmThenName);

    for i = 1, total do
        profileKeys[i] = profileData[i][1];
    end

    return profileKeys, total
end

function DataProvider:GetBWCharacterData(profileKey, key)
    if not IsBWDatabaseValid() then return end;

    if key then
        if key == "name" then
            local playerName, realmName = string.match(profileKey, "(.+) %- (.+)");
            return playerName or profileKey
        elseif key == "outfits" then
            local outfitStrings = {};
            local outfits = BetterWardrobe_SavedSetData.global.sets[profileKey];
            local total = 0;
            if outfits then
                for i, outfit in ipairs(outfits) do
                    if outfit.sources then
                        total = total + 1;
                        outfitStrings[total] = {
                            n = outfit.name or ("Unnamed Outfit "..total),
                            s = self:ConvertBWOutfitToString(outfit.sources),
                        };
                    end
                end
            end

            outfits = BetterWardrobe_ListData.OutfitDB.char[profileKey] and BetterWardrobe_ListData.OutfitDB.char[profileKey].outfits;
            if outfits then
                for i, outfit in ipairs(outfits) do
                    total = total + 1;
                    outfitStrings[total] = {
                        n = outfit.name or ("Unnamed Outfit "..total),
                        s = self:ConvertBWOutfitToString(outfit),
                    };
                end
            end
            return outfitStrings
        end
    else
        local data = {};
        local playerName, realmName = string.match(profileKey, "(.+) %- (.+)");
        data.name = playerName;
        data.numOutfits = GetBWNumOutfits(profileKey);

        return data
    end
end

function DataProvider:GetBWCharacterOutfitNames(profileKey)
    if not IsBWDatabaseValid() then return end;

    local data = BetterWardrobe_ListData.OutfitDB.char[profileKey];
    local outfitNames = {};
    local total = 0;

    if data and data.outfits then
        for k, v in ipairs(data.outfits) do
            total = total + 1;
            outfitNames[total] = v.name;
        end
    end
    return outfitNames
end

function DataProvider:ConvertBWOutfitToString(outfit)
    --BetterWardrobe\Data\Database.lua  --addon.GetSavedList()
    if not (outfit and type(outfit) == "table") then
        return
    end

    local transmogString;
    local slotString;
    local primaryID;

    for i, slotID in ipairs(TransmogSlotOrder) do
        primaryID = outfit[slotID] or 0;
        slotString = primaryID;

        if slotID == 3 then
            if outfit.offShoulder and outfit.offShoulder~= 0 then
                slotString = primaryID..":"..outfit.offShoulder;
            end
        elseif slotID == 16 then
            if outfit.mainHandEnchant and outfit.mainHandEnchant ~= 0 then
                slotString = primaryID..":0:"..outfit.mainHandEnchant;
            end
        elseif slotID == 17 then
            if outfit.offHandEnchant and outfit.offHandEnchant ~= 0 then
                slotString = primaryID..":0:"..outfit.offHandEnchant;
            end
        end

        if transmogString then
            transmogString = transmogString..","..slotString;
        else
            transmogString = slotString;
        end
    end

    return transmogString
end

--Debug
--[[
function GetTransmogStringByOutfitID(outfitID)
    local itemTransmogInfoList = C_TransmogCollection.GetOutfitItemTransmogInfoList(outfitID);
    return DataProvider:ConvertTransmogListToString(itemTransmogInfoList);
end
--]]