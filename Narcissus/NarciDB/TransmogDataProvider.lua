local _, addon = ...

local ipairs = ipairs;
local MogAPI = C_TransmogCollection;
local PlayerHasTransmog = MogAPI.PlayerHasTransmogItemModifiedAppearance;
local IsAppearanceFavorite = MogAPI.GetIsAppearanceFavorite;
local GetSourceInfo = MogAPI.GetSourceInfo;
local C_TransmogSets = C_TransmogSets;
local CreateItemTransmogInfo = ItemUtil.CreateItemTransmogInfo;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local strsplit = strsplit;

local LocalizedData = addon.LocalizedData;

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


do  --Find if an item is a piece of Transmog Set    --Debug
    local SourceIDXTransmogSetID;

    function DataProvider:GetOwnerSetID(sourceID)
        if not sourceID then return end;

        if not SourceIDXTransmogSetID then
            SourceIDXTransmogSetID = {};

            local ipairs = ipairs;
            local GetSetInfo = C_TransmogSets.GetSetInfo;
            local GetAllSourceIDs = C_TransmogSets.GetAllSourceIDs;
            local info, expansionID, sources;

            for setID = 5000, 1, -1 do
                info = GetSetInfo(setID);
                if info then
                    expansionID = info.expansionID;
                    if expansionID and expansionID >= 9 then
                        sources = GetAllSourceIDs(setID);
                        if sources then
                            for _, id in ipairs(sources) do
                                SourceIDXTransmogSetID[id] = setID;
                            end
                        end
                    else
                        break
                    end
                end
            end
        end

        return SourceIDXTransmogSetID[sourceID]
    end

    function DataProvider:IsSoucePartOfTransmogSet(sourceID)
        return self:GetOwnerSetID(sourceID) ~= nil
    end

    function DataProvider:GetOwnerSetName(sourceID)
        local setID = self:GetOwnerSetID(sourceID);
        if setID then
            local info = C_TransmogSets.GetSetInfo(setID);
            return info.name
        end
    end

    function DataProvider:GetOwnerSetInfo(sourceID)
        local setID = self:GetOwnerSetID(sourceID);
        if setID then
            local customInfo = {};
            local info = C_TransmogSets.GetSetInfo(setID);
            customInfo.name = info.name;
            customInfo.sources = C_TransmogSets.GetAllSourceIDs(setID);
            return customInfo
        end
    end

    function DataProvider:ClearTransmogSetCache()
        --Called by our PerksProgram Module
        SourceIDXTransmogSetID = nil;
    end
end


do  --Transmog Set invType to slotID, Slot Sorting
    --invType from C_Transmog.GetAllSetAppearancesByID is offset by 1
    local InvTypeSlotID_Armor = {
        INVTYPE_HEAD = 1,
        INVTYPE_SHOULDER = 3,
        INVTYPE_CLOAK = 15,
        INVTYPE_CHEST = 5,
        INVTYPE_ROBE = 5,
        INVTYPE_BODY = 4,
        INVTYPE_TABARD = 19,
        INVTYPE_WRIST = 9,
        INVTYPE_HAND = 10,
        INVTYPE_WAIST = 6,
        INVTYPE_LEGS = 7,
        INVTYPE_FEET = 8,
    };

    local InvTypeSlotID_Weapon = {
        INVTYPE_WEAPON = 16,
        INVTYPE_WEAPONMAINHAND = 16,
        INVTYPE_2HWEAPON = 16,
        INVTYPE_RANGEDRIGHT = 16,
        INVTYPE_WEAPONOFFHAND = 17,
        INVTYPE_RANGED = 17,
        INVTYPE_SHIELD = 17,
        INVTYPE_HOLDABLE = 17,
    };

    local InvTypeOrder = {
        "INVTYPE_HEAD",
        "INVTYPE_SHOULDER",
        "INVTYPE_CLOAK",
        "INVTYPE_CHEST",
        "INVTYPE_ROBE",
        "INVTYPE_BODY",
        "INVTYPE_TABARD",
        "INVTYPE_WRIST",
        "INVTYPE_HAND",
        "INVTYPE_WAIST",
        "INVTYPE_LEGS",
        "INVTYPE_FEET",

        "INVTYPE_WEAPON",
        "INVTYPE_WEAPONMAINHAND",
        "INVTYPE_2HWEAPON",
        "INVTYPE_RANGEDRIGHT",
        "INVTYPE_WEAPONOFFHAND",
        "INVTYPE_RANGED",
        "INVTYPE_SHIELD",
        "INVTYPE_HOLDABLE",
    };

    do
        local Temp = {};
        for i, invType in ipairs(InvTypeOrder) do
            Temp[invType] = i;
        end
        InvTypeOrder = Temp;
    end

    function DataProvider:GetSlotIDBySetInvType(invType)
        return InvTypeSlotID_Armor[invType] or InvTypeSlotID_Weapon[invType] or 0
    end

    function DataProvider:GetLongestLabelWidth(frame, fontObject)
        if not self.testObject then
            self.testObject = frame:CreateFontString(nil, "BACKGROUND", fontObject);
            self.testObject:Hide();
            self.testObject:SetPoint("CENTER", frame, "CENTER", 0, 0);
        end

        local _G = _G;
        local name, width;
        local maxWidth_Armor = 12;
        local maxWidth_Weapon = 12;

        for invType in pairs(InvTypeSlotID_Armor) do
            name = _G[invType];
            if name then
                self.testObject:SetText(name);
                width = self.testObject:GetWrappedWidth();
                if width > maxWidth_Armor then
                    maxWidth_Armor = width;
                end
            end
        end

        for invType in pairs(InvTypeSlotID_Weapon) do
            name = _G[invType];
            if name then
                self.testObject:SetText(name);
                width = self.testObject:GetWrappedWidth();
                if width > maxWidth_Weapon then
                    maxWidth_Weapon = width;
                end
            end
        end

        self.testObject:SetText(nil);

        return math.ceil(maxWidth_Armor), math.ceil(maxWidth_Weapon)
    end

    local function SortFunc_SetItems(a, b)
        local m, n;
        m = a.invType and InvTypeOrder[a.invType] or 128;
        n = b.invType and InvTypeOrder[b.invType] or 128;
        if m ~= n then
            return m < n
        end
        return a.origianlOrder < b.origianlOrder
    end

    function DataProvider:SortSetItems(setItems)
        --local setItems = C_Transmog.GetAllSetAppearancesByID(setID)
        for i, v in ipairs(setItems) do
            v.origianlOrder = i;
        end
        table.sort(setItems, SortFunc_SetItems);
    end
end


--Debug
--[[
function GetTransmogStringByOutfitID(outfitID)
    local itemTransmogInfoList = C_TransmogCollection.GetOutfitItemTransmogInfoList(outfitID);
    return DataProvider:ConvertTransmogListToString(itemTransmogInfoList);
end
--]]

local SOURCE_TEXTS = {};
local ITEM_SOURCE_TEXT_IDS = {};

do
    local _, argus = GetAchievementInfo(12078);                                  --Argus Weapon Transmogs: Arsenal: Weapons of the Lightforged
    argus = argus or "Commander of Argus";
    argus = "|cFFFFD100"..(TRANSMOG_SOURCE_5 or "Achievement") .."|r "..argus;
    SOURCE_TEXTS[1] = argus;

    local _, _, promotionShadowlands = C_MountJournal.GetMountInfoExtraByID(1289);         --EnsorcelledEverwyrm   Promotion: Shadowlands Heroic Edition
    SOURCE_TEXTS[2] = promotionShadowlands;

    SOURCE_TEXTS[3] = Narci.L["Heritage Armor"] or "Heritage Armor";
    SOURCE_TEXTS[4] = Narci.L["Secret Finding"] or "Secret Finding";
    SOURCE_TEXTS[5] = DUNGEON_FLOOR_HELHEIMRAID1 or "Trial of Valor";

    local HeritageArmorItemIDs = {
        165931, 165932, 165933, 165934, 165935, 165936, 165937, 16598,                      --Dwarf
        161008, 161009, 161010, 161011, 161012, 161013, 161014, 161015,                     --Dark Iron
        156668, 156669, 156670, 156671, 156672, 156673, 156674, 156684,                     --Highmountain
        156699, 156700, 156701, 156702, 156703, 156704, 156705, 156706,                     --Lightforged
        161050, 161051, 161052, 161054, 161055, 161056, 161057, 161058,                     --Mag'har Orc (Blackrock Recolor)
        161059, 161060, 161061, 161062, 161063, 161064, 161065, 161066,                     --Mag'har Orc (Frostwolf Recolor)
        160992, 160993, 160994, 160999, 161000, 161001, 161002, 161003,                     --Mag'har Orc (Warsong Recolor)
        156690, 156691, 156692, 156693, 156694, 156695, 156696, 156697, 157758, 158917,     --Void Elf
        156675, 156676, 156677, 156678, 156679, 156680, 156681, 156685,                     --Nightborne
        166348, 166349, 166351, 166352, 166353, 166354, 166355, 166356, 166357,             --Blood Elf
        164993, 164994, 164995, 164996, 164997, 164998, 164999, 165000,                     --Zandalari
        165002, 165003, 165004, 165005, 165006, 165007, 165008, 165009,                     --Kul'tiran
        168282, 168283, 168284, 168285, 168286, 168287, 168288, 168289, 168290,             --Gnome
        168291, 168292, 168293, 168294, 168295, 168296, 168297, 168298, 170063,             --Tauren
        173968, 173966, 173970, 173971, 173967, 173969, 174354, 174355,                     --Vulpera
        173961, 173962, 173963, 173964, 173958, 173972,                                     --Mechagnome
        174000, 174001, 174002, 174003, 174004, 174005, 174006, 173999, 173998,             --Worgen 
    };

    local Ensemble_TheChosenDead = {
        142423, 142421, 142422, 142434, 142420, 142433,     --Mail
        142427, 142425, 142431, 142435, 142426, 142424,     --Plate
        142419, 142430, 142432, 142417, 142418, 142416,     --Leather
        142415, 142411, 142410, 142413, 142429, 142414,     --Cloth
        143355, 143345, 143334, 143354, 143346, 143347,
        143356, 143339, 143349, 143342, 143344, 143335,
        143353, 143368, 143340, 143337, 143348, 143341,
        143343, 143367, 143336, 143352, 143366, 143351,
        143360, 143358, 143350, 143361, 143364, 143359,
        143338, 143369, 143365, 143363, 143362, 143357,
    };

    local LightforgedWeapons = {
        152332, 152333, 152334, 152335, 152336, 152337, 152338, 152339, 152340, 152341, 152342, 152343,
    };

    local ShadowlandsPromotion = {
        172075, 172076, 172077, 172078, 172079, 172080, 172081, 172082, 172083,
    };

    local function DesignateSourceTextID(itemIDTable, sourceTextID)
        for _, id in ipairs(itemIDTable) do
            ITEM_SOURCE_TEXT_IDS[id] = sourceTextID;
        end
    end

    DesignateSourceTextID(LightforgedWeapons, 1);
    DesignateSourceTextID(ShadowlandsPromotion, 2);
    DesignateSourceTextID(HeritageArmorItemIDs, 3);
    DesignateSourceTextID(Ensemble_TheChosenDead, 5);

    ITEM_SOURCE_TEXT_IDS[162690] = 4;   --Waist of Time

end

function DataProvider:GetSpecialItemSourceText(sourceID, itemID, modID)
    local legionArtifactName = self:GetArtifactAppearanceSetName(sourceID);
    if legionArtifactName then
        return legionArtifactName
    end

    if itemID and ITEM_SOURCE_TEXT_IDS[itemID] then
        return SOURCE_TEXTS[ ITEM_SOURCE_TEXT_IDS[itemID] ]
    end
end


local ArtifactSourceIDXArtifactSetID = {
    [69077] = 3,
    [69078] = 3,
    [69079] = 3,
    [69080] = 3,
    [70215] = 4,
    [70216] = 4,
    [70217] = 4,
    [70218] = 4,
    [70219] = 5,
    [70220] = 6,
    [70221] = 6,
    [70222] = 6,
    [70223] = 6,
    [70224] = 7,
    [70225] = 7,
    [70226] = 7,
    [70227] = 7,
    [72790] = 8,
    [72810] = 8,
    [72791] = 8,
    [72811] = 8,
    [72792] = 8,
    [72812] = 8,
    [72793] = 8,
    [72813] = 8,
    [72794] = 9,
    [72814] = 9,
    [72795] = 9,
    [72815] = 9,
    [72796] = 9,
    [72816] = 9,
    [72797] = 9,
    [72817] = 9,
    [72798] = 10,
    [72818] = 10,
    [72799] = 10,
    [72819] = 10,
    [72800] = 10,
    [72820] = 10,
    [72801] = 10,
    [72821] = 10,
    [72802] = 11,
    [72822] = 11,
    [72803] = 11,
    [72823] = 11,
    [72804] = 11,
    [72824] = 11,
    [72805] = 11,
    [72825] = 11,
    [72806] = 12,
    [72826] = 12,
    [72807] = 12,
    [72827] = 12,
    [72808] = 12,
    [72828] = 12,
    [72809] = 12,
    [72829] = 12,
    [73398] = 13,
    [73399] = 13,
    [73400] = 13,
    [73401] = 13,
    [73402] = 14,
    [73403] = 14,
    [73404] = 14,
    [73405] = 14,
    [73409] = 15,
    [73410] = 15,
    [73411] = 15,
    [73412] = 15,
    [73415] = 16,
    [73416] = 16,
    [73417] = 16,
    [73418] = 16,
    [73419] = 17,
    [73420] = 17,
    [73421] = 17,
    [73422] = 17,
    [73888] = 20,
    [73908] = 20,
    [73502] = 21,
    [73522] = 21,
    [73503] = 21,
    [73523] = 21,
    [73504] = 21,
    [73524] = 21,
    [73505] = 21,
    [73525] = 21,
    [73506] = 22,
    [73526] = 22,
    [73507] = 22,
    [73527] = 22,
    [73508] = 22,
    [73528] = 22,
    [73509] = 22,
    [73529] = 22,
    [73510] = 23,
    [73530] = 23,
    [73511] = 23,
    [73531] = 23,
    [73512] = 23,
    [73532] = 23,
    [73513] = 23,
    [73533] = 23,
    [73514] = 24,
    [73534] = 24,
    [73515] = 24,
    [73535] = 24,
    [73516] = 24,
    [73536] = 24,
    [73517] = 24,
    [73537] = 24,
    [73518] = 25,
    [73538] = 25,
    [73519] = 25,
    [73539] = 25,
    [73520] = 25,
    [73540] = 25,
    [73521] = 25,
    [73541] = 25,
    [76520] = 32,
    [76523] = 33,
    [76521] = 39,
    [76522] = 39,
    [76984] = 33,
    [76534] = 40,
    [77278] = 40,
    [75200] = 41,
    [73695] = 42,
    [73675] = 42,
    [76536] = 43,
    [76537] = 43,
    [76535] = 44,
    [73717] = 44,
    [76533] = 45,
    [76173] = 46,
    [77409] = 46,
    [76530] = 47,
    [76529] = 50,
    [76527] = 51,
    [77351] = 51,
    [76526] = 52,
    [73865] = 53,
    [73866] = 53,
    [73867] = 53,
    [73868] = 53,
    [73869] = 54,
    [73870] = 54,
    [73871] = 54,
    [73872] = 54,
    [73873] = 55,
    [73874] = 55,
    [73875] = 55,
    [73876] = 55,
    [73877] = 56,
    [73878] = 56,
    [73879] = 56,
    [73880] = 56,
    [73881] = 57,
    [73882] = 57,
    [73883] = 57,
    [73884] = 57,
    [73887] = 20,
    [73907] = 20,
    [73886] = 20,
    [73906] = 20,
    [73885] = 20,
    [73905] = 20,
    [73889] = 61,
    [73909] = 61,
    [73890] = 61,
    [73910] = 61,
    [73891] = 61,
    [73911] = 61,
    [73892] = 61,
    [73912] = 61,
    [73893] = 58,
    [73913] = 58,
    [73894] = 58,
    [73914] = 58,
    [73895] = 58,
    [73915] = 58,
    [73896] = 58,
    [73916] = 58,
    [73897] = 59,
    [73917] = 59,
    [73898] = 59,
    [73918] = 59,
    [73899] = 59,
    [73919] = 59,
    [73900] = 59,
    [73920] = 59,
    [73901] = 60,
    [73921] = 60,
    [73902] = 60,
    [73922] = 60,
    [73903] = 60,
    [73923] = 60,
    [73904] = 60,
    [73924] = 60,
    [74460] = 64,
    [74461] = 64,
    [74462] = 64,
    [74463] = 64,
    [74464] = 65,
    [74465] = 65,
    [74466] = 65,
    [74467] = 65,
    [74468] = 66,
    [74469] = 66,
    [74470] = 66,
    [74471] = 66,
    [74472] = 67,
    [74473] = 67,
    [74474] = 67,
    [74475] = 67,
    [74476] = 68,
    [74477] = 68,
    [74478] = 68,
    [74479] = 68,
    [74595] = 49,
    [74596] = 49,
    [74597] = 49,
    [74598] = 49,
    [74599] = 69,
    [74600] = 69,
    [74601] = 69,
    [74602] = 69,
    [74603] = 70,
    [74604] = 70,
    [74605] = 70,
    [74606] = 70,
    [74607] = 71,
    [74608] = 71,
    [74609] = 71,
    [74610] = 71,
    [74611] = 72,
    [74612] = 72,
    [74613] = 72,
    [74614] = 72,
    [75201] = 41,
    [75202] = 41,
    [75203] = 41,
    [75204] = 73,
    [75205] = 73,
    [75206] = 73,
    [75207] = 73,
    [75208] = 74,
    [75209] = 74,
    [75210] = 74,
    [75211] = 74,
    [75212] = 75,
    [75213] = 75,
    [75214] = 75,
    [75215] = 75,
    [75216] = 76,
    [75217] = 76,
    [75218] = 76,
    [75220] = 76,
    [73696] = 42,
    [73676] = 42,
    [73697] = 42,
    [73677] = 42,
    [73698] = 42,
    [73678] = 42,
    [73699] = 77,
    [73679] = 77,
    [73700] = 77,
    [73680] = 77,
    [73703] = 78,
    [73683] = 78,
    [73707] = 79,
    [73687] = 79,
    [73701] = 77,
    [73681] = 77,
    [73702] = 77,
    [73682] = 77,
    [73704] = 78,
    [73684] = 78,
    [73705] = 78,
    [73685] = 78,
    [73706] = 78,
    [73686] = 78,
    [73708] = 79,
    [73688] = 79,
    [73709] = 79,
    [73689] = 79,
    [73710] = 79,
    [73690] = 79,
    [75221] = 81,
    [76174] = 46,
    [77410] = 46,
    [76175] = 46,
    [77411] = 46,
    [76176] = 46,
    [77412] = 46,
    [76177] = 82,
    [77413] = 82,
    [76178] = 82,
    [77414] = 82,
    [76179] = 82,
    [77415] = 82,
    [76180] = 82,
    [77416] = 82,
    [76181] = 83,
    [77417] = 83,
    [76182] = 83,
    [77418] = 83,
    [76183] = 83,
    [77419] = 83,
    [76184] = 83,
    [77420] = 83,
    [76185] = 84,
    [77421] = 84,
    [76186] = 84,
    [77422] = 84,
    [76187] = 84,
    [77423] = 84,
    [76188] = 84,
    [77424] = 84,
    [76189] = 85,
    [77425] = 85,
    [76190] = 85,
    [77426] = 85,
    [76191] = 85,
    [77427] = 85,
    [76192] = 85,
    [77428] = 85,
    [76335] = 48,
    [73655] = 48,
    [76336] = 48,
    [76339] = 48,
    [76337] = 48,
    [76340] = 48,
    [76338] = 48,
    [76341] = 48,
    [96471] = 86,
    [97334] = 86,
    [96475] = 87,
    [97338] = 87,
    [96478] = 88,
    [97341] = 88,
    [96487] = 89,
    [97350] = 89,
    [96470] = 86,
    [97333] = 86,
    [96472] = 86,
    [97335] = 86,
    [96473] = 86,
    [97336] = 86,
    [96474] = 87,
    [97337] = 87,
    [96476] = 87,
    [97339] = 87,
    [96477] = 87,
    [97340] = 87,
    [96479] = 88,
    [97342] = 88,
    [96480] = 88,
    [97343] = 88,
    [96481] = 88,
    [97344] = 88,
    [96486] = 89,
    [97349] = 89,
    [96488] = 89,
    [97351] = 89,
    [96489] = 89,
    [97352] = 89,
    [77022] = 91,
    [77234] = 91,
    [76525] = 116,
    [76528] = 129,
    [73770] = 138,
    [77121] = 138,
    [73672] = 147,
    [76531] = 147,
    [76532] = 152,
    [76538] = 178,
    [76539] = 188,
    [76540] = 193,
    [77771] = 193,
    [76543] = 44,
    [80554] = 44,
    [76546] = 170,
    [80557] = 170,
    [76550] = 172,
    [80561] = 172,
    [76554] = 171,
    [80565] = 171,
    [76558] = 173,
    [80569] = 173,
    [76544] = 44,
    [80555] = 44,
    [76545] = 44,
    [80556] = 44,
    [76547] = 170,
    [80558] = 170,
    [76548] = 170,
    [80559] = 170,
    [76549] = 170,
    [80560] = 170,
    [76551] = 172,
    [80562] = 172,
    [76552] = 172,
    [80563] = 172,
    [76553] = 172,
    [80564] = 172,
    [76555] = 171,
    [80566] = 171,
    [76556] = 171,
    [80567] = 171,
    [76557] = 171,
    [80568] = 171,
    [76559] = 173,
    [80570] = 173,
    [76560] = 173,
    [80571] = 173,
    [76561] = 173,
    [80572] = 173,
    [76823] = 179,
    [76827] = 180,
    [76831] = 181,
    [76835] = 182,
    [76820] = 178,
    [76821] = 178,
    [76822] = 178,
    [76836] = 182,
    [76837] = 182,
    [76838] = 182,
    [76832] = 181,
    [76833] = 181,
    [76834] = 181,
    [76828] = 180,
    [76829] = 180,
    [76830] = 180,
    [76824] = 179,
    [76825] = 179,
    [76826] = 179,
    [76930] = 129,
    [76932] = 130,
    [76936] = 132,
    [76940] = 131,
    [76944] = 133,
    [76931] = 129,
    [75222] = 129,
    [76933] = 130,
    [76934] = 130,
    [76935] = 130,
    [76937] = 132,
    [76938] = 132,
    [76939] = 132,
    [76941] = 131,
    [76942] = 131,
    [76943] = 131,
    [76945] = 133,
    [76946] = 133,
    [76947] = 133,
    [76950] = 32,
    [76951] = 32,
    [76952] = 32,
    [76953] = 92,
    [76957] = 93,
    [76961] = 94,
    [76954] = 92,
    [76955] = 92,
    [76956] = 92,
    [76958] = 93,
    [76959] = 93,
    [76960] = 93,
    [76962] = 94,
    [76963] = 94,
    [76964] = 94,
    [76968] = 96,
    [77179] = 96,
    [76972] = 99,
    [77183] = 99,
    [76976] = 97,
    [77187] = 97,
    [76980] = 98,
    [77191] = 98,
    [76965] = 39,
    [77176] = 39,
    [76966] = 39,
    [77177] = 39,
    [76967] = 39,
    [77178] = 39,
    [76969] = 96,
    [77180] = 96,
    [76970] = 96,
    [77181] = 96,
    [76971] = 96,
    [77182] = 96,
    [76973] = 99,
    [77184] = 99,
    [76974] = 99,
    [77185] = 99,
    [76975] = 99,
    [77186] = 99,
    [76977] = 97,
    [77188] = 97,
    [76978] = 97,
    [77189] = 97,
    [76979] = 97,
    [77190] = 97,
    [76981] = 98,
    [77192] = 98,
    [76982] = 98,
    [77193] = 98,
    [76983] = 98,
    [77194] = 98,
    [76985] = 33,
    [76986] = 33,
    [76987] = 102,
    [76991] = 100,
    [76995] = 101,
    [76999] = 103,
    [76988] = 102,
    [76989] = 102,
    [76990] = 102,
    [76992] = 100,
    [76993] = 100,
    [76994] = 100,
    [76996] = 101,
    [76997] = 101,
    [76998] = 101,
    [77000] = 103,
    [77001] = 103,
    [77002] = 103,
    [77006] = 108,
    [77010] = 109,
    [77014] = 111,
    [77018] = 110,
    [77003] = 81,
    [77004] = 81,
    [77005] = 81,
    [77007] = 108,
    [77008] = 108,
    [77009] = 108,
    [77011] = 109,
    [77012] = 109,
    [77013] = 109,
    [77015] = 111,
    [77016] = 111,
    [77017] = 111,
    [77019] = 110,
    [77020] = 110,
    [77021] = 110,
    [76524] = 91,
    [73667] = 91,
    [77023] = 91,
    [77235] = 91,
    [77024] = 91,
    [77236] = 91,
    [96451] = 112,
    [97354] = 112,
    [96458] = 115,
    [97361] = 115,
    [96454] = 113,
    [97357] = 113,
    [96462] = 114,
    [97365] = 114,
    [96450] = 112,
    [97353] = 112,
    [96452] = 112,
    [97355] = 112,
    [96453] = 112,
    [97356] = 112,
    [96459] = 115,
    [97362] = 115,
    [96460] = 115,
    [97363] = 115,
    [96461] = 115,
    [97364] = 115,
    [96455] = 113,
    [97358] = 113,
    [96456] = 113,
    [97359] = 113,
    [96457] = 113,
    [97360] = 113,
    [96463] = 114,
    [97366] = 114,
    [96464] = 114,
    [97367] = 114,
    [96465] = 114,
    [97368] = 114,
    [77028] = 117,
    [77032] = 118,
    [77036] = 119,
    [77040] = 120,
    [77025] = 116,
    [77026] = 116,
    [77027] = 116,
    [77029] = 117,
    [77030] = 117,
    [77031] = 117,
    [77033] = 118,
    [77034] = 118,
    [77035] = 118,
    [77037] = 119,
    [77038] = 119,
    [77039] = 119,
    [77041] = 120,
    [77042] = 120,
    [77043] = 120,
    [77045] = 52,
    [77046] = 52,
    [77047] = 52,
    [77048] = 121,
    [77052] = 122,
    [77056] = 123,
    [77060] = 124,
    [77049] = 121,
    [77050] = 121,
    [77051] = 121,
    [77057] = 123,
    [77058] = 123,
    [77059] = 123,
    [77053] = 122,
    [77054] = 122,
    [77055] = 122,
    [77061] = 124,
    [77062] = 124,
    [77063] = 124,
    [77067] = 125,
    [77355] = 125,
    [77071] = 127,
    [77359] = 127,
    [77075] = 126,
    [77363] = 126,
    [77079] = 128,
    [77367] = 128,
    [77064] = 51,
    [77352] = 51,
    [77065] = 51,
    [77353] = 51,
    [77066] = 51,
    [77354] = 51,
    [77068] = 125,
    [77356] = 125,
    [77069] = 125,
    [77357] = 125,
    [77070] = 125,
    [77358] = 125,
    [77072] = 127,
    [77360] = 127,
    [77073] = 127,
    [77361] = 127,
    [77074] = 127,
    [77362] = 127,
    [77076] = 126,
    [77364] = 126,
    [77077] = 126,
    [77365] = 126,
    [77078] = 126,
    [77366] = 126,
    [77080] = 128,
    [77368] = 128,
    [77081] = 128,
    [77369] = 128,
    [77082] = 128,
    [77370] = 128,
    [77086] = 134,
    [77090] = 137,
    [77094] = 135,
    [77098] = 136,
    [77083] = 50,
    [77084] = 50,
    [77085] = 50,
    [77087] = 134,
    [77088] = 134,
    [77089] = 134,
    [77091] = 137,
    [77092] = 137,
    [77093] = 137,
    [77095] = 135,
    [77096] = 135,
    [77097] = 135,
    [77099] = 136,
    [77100] = 136,
    [77101] = 136,
    [77105] = 139,
    [77125] = 139,
    [77109] = 140,
    [77129] = 140,
    [77113] = 141,
    [77133] = 141,
    [77117] = 142,
    [77137] = 142,
    [77102] = 138,
    [77122] = 138,
    [77103] = 138,
    [77123] = 138,
    [77104] = 138,
    [77124] = 138,
    [77106] = 139,
    [77126] = 139,
    [77107] = 139,
    [77127] = 139,
    [77108] = 139,
    [77128] = 139,
    [77110] = 140,
    [77130] = 140,
    [77111] = 140,
    [77131] = 140,
    [77112] = 140,
    [77132] = 140,
    [77114] = 141,
    [77134] = 141,
    [77115] = 141,
    [77135] = 141,
    [77116] = 141,
    [77136] = 141,
    [77118] = 142,
    [77138] = 142,
    [77119] = 142,
    [77139] = 142,
    [77120] = 142,
    [77140] = 142,
    [77238] = 143,
    [77250] = 145,
    [77246] = 146,
    [77242] = 144,
    [77145] = 47,
    [77146] = 47,
    [77237] = 47,
    [77251] = 145,
    [77252] = 145,
    [77253] = 145,
    [77239] = 143,
    [77155] = 90,
    [77214] = 90,
    [77156] = 90,
    [77215] = 90,
    [77157] = 90,
    [77216] = 90,
    [77158] = 90,
    [77217] = 90,
    [77159] = 104,
    [77218] = 104,
    [77160] = 104,
    [77219] = 104,
    [77161] = 104,
    [77220] = 104,
    [77162] = 104,
    [77221] = 104,
    [77163] = 106,
    [77222] = 106,
    [77164] = 106,
    [77223] = 106,
    [77165] = 106,
    [77224] = 106,
    [77166] = 106,
    [77225] = 106,
    [77167] = 105,
    [77226] = 105,
    [77168] = 105,
    [77227] = 105,
    [77169] = 105,
    [77228] = 105,
    [77170] = 105,
    [77229] = 105,
    [77171] = 107,
    [77230] = 107,
    [77172] = 107,
    [77231] = 107,
    [77173] = 107,
    [77232] = 107,
    [77174] = 107,
    [77233] = 107,
    [77308] = 95,
    [77309] = 95,
    [77310] = 95,
    [77311] = 95,
    [77240] = 143,
    [77241] = 143,
    [77243] = 144,
    [77244] = 144,
    [77245] = 144,
    [77247] = 146,
    [77248] = 146,
    [77249] = 146,
    [73711] = 80,
    [73691] = 80,
    [73712] = 80,
    [73692] = 80,
    [73713] = 80,
    [73693] = 80,
    [73714] = 80,
    [73694] = 80,
    [77729] = 193,
    [77772] = 193,
    [77730] = 193,
    [77773] = 193,
    [77731] = 193,
    [77774] = 193,
    [77732] = 194,
    [77775] = 194,
    [77733] = 194,
    [77776] = 194,
    [77734] = 194,
    [77777] = 194,
    [77735] = 194,
    [77778] = 194,
    [77736] = 195,
    [77779] = 195,
    [77737] = 195,
    [77780] = 195,
    [77738] = 195,
    [77781] = 195,
    [77739] = 195,
    [77782] = 195,
    [77740] = 196,
    [77783] = 196,
    [77741] = 196,
    [77784] = 196,
    [77742] = 196,
    [77785] = 196,
    [77743] = 196,
    [77786] = 196,
    [77744] = 197,
    [77787] = 197,
    [77745] = 197,
    [77788] = 197,
    [77746] = 197,
    [77789] = 197,
    [77747] = 197,
    [77790] = 197,
    [77653] = 40,
    [77279] = 40,
    [77654] = 40,
    [77280] = 40,
    [77655] = 40,
    [77281] = 40,
    [77656] = 166,
    [78644] = 166,
    [77657] = 166,
    [78645] = 166,
    [77658] = 166,
    [78646] = 166,
    [77659] = 166,
    [78647] = 166,
    [77660] = 167,
    [78648] = 167,
    [77661] = 167,
    [78649] = 167,
    [77662] = 167,
    [78650] = 167,
    [77663] = 167,
    [78651] = 167,
    [77664] = 168,
    [78652] = 168,
    [77665] = 168,
    [78653] = 168,
    [77666] = 168,
    [78654] = 168,
    [77667] = 168,
    [78655] = 168,
    [77668] = 169,
    [78656] = 169,
    [77669] = 169,
    [78657] = 169,
    [77670] = 169,
    [78658] = 169,
    [77671] = 169,
    [78659] = 169,
    [73716] = 161,
    [77751] = 161,
    [77429] = 161,
    [77752] = 161,
    [77430] = 161,
    [77753] = 161,
    [77431] = 161,
    [77754] = 161,
    [77432] = 162,
    [77755] = 162,
    [77434] = 162,
    [77756] = 162,
    [77435] = 162,
    [77757] = 162,
    [77436] = 162,
    [77758] = 162,
    [77437] = 164,
    [77759] = 164,
    [77438] = 164,
    [77760] = 164,
    [77439] = 164,
    [77761] = 164,
    [77440] = 164,
    [77762] = 164,
    [77313] = 147,
    [77283] = 147,
    [77314] = 147,
    [77284] = 147,
    [77315] = 147,
    [77285] = 147,
    [77316] = 148,
    [77286] = 148,
    [77317] = 148,
    [77287] = 148,
    [77318] = 148,
    [77288] = 148,
    [77319] = 148,
    [77289] = 148,
    [77320] = 149,
    [77290] = 149,
    [77321] = 149,
    [77291] = 149,
    [77322] = 149,
    [77292] = 149,
    [77323] = 149,
    [77293] = 149,
    [77324] = 150,
    [77294] = 150,
    [77325] = 150,
    [77295] = 150,
    [77326] = 150,
    [77296] = 150,
    [77327] = 150,
    [77297] = 150,
    [77328] = 151,
    [77298] = 151,
    [77329] = 151,
    [77299] = 151,
    [77330] = 151,
    [77300] = 151,
    [77331] = 151,
    [77301] = 151,
    [78421] = 5,
    [78422] = 5,
    [78423] = 5,
    [77371] = 152,
    [77372] = 152,
    [77373] = 152,
    [77374] = 153,
    [77375] = 153,
    [77376] = 153,
    [77377] = 153,
    [77386] = 156,
    [77387] = 156,
    [77388] = 156,
    [77389] = 156,
    [77382] = 154,
    [77383] = 154,
    [77384] = 154,
    [77385] = 154,
    [77378] = 155,
    [77379] = 155,
    [77380] = 155,
    [77381] = 155,
    [77390] = 45,
    [77391] = 45,
    [77392] = 45,
    [77393] = 157,
    [77394] = 157,
    [77395] = 157,
    [77396] = 157,
    [77397] = 158,
    [77398] = 158,
    [77399] = 158,
    [77400] = 158,
    [77401] = 159,
    [77402] = 159,
    [77403] = 159,
    [77404] = 159,
    [77405] = 160,
    [77406] = 160,
    [77407] = 160,
    [77408] = 160,
    [77441] = 163,
    [77763] = 163,
    [77442] = 163,
    [77764] = 163,
    [77443] = 163,
    [77765] = 163,
    [77444] = 163,
    [77766] = 163,
    [77445] = 165,
    [77767] = 165,
    [77446] = 165,
    [77768] = 165,
    [77447] = 165,
    [77769] = 165,
    [77448] = 165,
    [77770] = 165,
    [77672] = 43,
    [77691] = 43,
    [77673] = 43,
    [77692] = 43,
    [77674] = 43,
    [77693] = 43,
    [77675] = 174,
    [77694] = 174,
    [77676] = 174,
    [77695] = 174,
    [77677] = 174,
    [77696] = 174,
    [77678] = 174,
    [77697] = 174,
    [77679] = 175,
    [77698] = 175,
    [77680] = 175,
    [77699] = 175,
    [77681] = 175,
    [77700] = 175,
    [77682] = 175,
    [77701] = 175,
    [77683] = 176,
    [77702] = 176,
    [77684] = 176,
    [77703] = 176,
    [77685] = 176,
    [77704] = 176,
    [77686] = 176,
    [77705] = 176,
    [77687] = 177,
    [77706] = 177,
    [77688] = 177,
    [77707] = 177,
    [77689] = 177,
    [77708] = 177,
    [77690] = 177,
    [77709] = 177,
    [77710] = 188,
    [77711] = 188,
    [77712] = 188,
    [77713] = 189,
    [77714] = 189,
    [77715] = 189,
    [77716] = 189,
    [77717] = 190,
    [77718] = 190,
    [77719] = 190,
    [77720] = 190,
    [77721] = 191,
    [77722] = 191,
    [77723] = 191,
    [77724] = 191,
    [77725] = 192,
    [77726] = 192,
    [77727] = 192,
    [77728] = 192,
    [77887] = 183,
    [78890] = 183,
    [77888] = 183,
    [80363] = 183,
    [77889] = 183,
    [80364] = 183,
    [77890] = 183,
    [80365] = 183,
    [77891] = 184,
    [80366] = 184,
    [77892] = 184,
    [80367] = 184,
    [77893] = 184,
    [80368] = 184,
    [77894] = 184,
    [80369] = 184,
    [77895] = 185,
    [80370] = 185,
    [77896] = 185,
    [80371] = 185,
    [77897] = 185,
    [80372] = 185,
    [77898] = 185,
    [80373] = 185,
    [77899] = 186,
    [80374] = 186,
    [77900] = 186,
    [80375] = 186,
    [77901] = 186,
    [80376] = 186,
    [77902] = 186,
    [80377] = 186,
    [77903] = 187,
    [80378] = 187,
    [77904] = 187,
    [80379] = 187,
    [77905] = 187,
    [80380] = 187,
    [77906] = 187,
    [80381] = 187,
    [96466] = 203,
    [97369] = 203,
    [96467] = 203,
    [97370] = 203,
    [96468] = 203,
    [97371] = 203,
    [96469] = 203,
    [97372] = 203,
    [80545] = 212,
    [80546] = 212,
    [80547] = 212,
    [80548] = 212,
    [80603] = 229,
    [80599] = 229,
    [80604] = 229,
    [80600] = 229,
    [80605] = 229,
    [80601] = 229,
    [80606] = 229,
    [80602] = 229,
    [80632] = 217,
    [80636] = 217,
    [80633] = 217,
    [80637] = 217,
    [80634] = 217,
    [80638] = 217,
    [80635] = 217,
    [80639] = 217,
    [80776] = 245,
    [80772] = 245,
    [80777] = 245,
    [80773] = 245,
    [80778] = 245,
    [80774] = 245,
    [80779] = 245,
    [80775] = 245,
    [80696] = 230,
    [80697] = 230,
    [80698] = 230,
    [80699] = 230,
    [80612] = 214,
    [80616] = 214,
    [80613] = 214,
    [80617] = 214,
    [80614] = 214,
    [80618] = 214,
    [80615] = 214,
    [80619] = 214,
    [80644] = 220,
    [80645] = 220,
    [80646] = 220,
    [80647] = 220,
    [80550] = 238,
    [80573] = 238,
    [80551] = 238,
    [80574] = 238,
    [80552] = 238,
    [80575] = 238,
    [80553] = 238,
    [80576] = 238,
    [80724] = 235,
    [80728] = 235,
    [80725] = 235,
    [80729] = 235,
    [80726] = 235,
    [80730] = 235,
    [80727] = 235,
    [80731] = 235,
    [80668] = 224,
    [80669] = 224,
    [80670] = 224,
    [80671] = 224,
    [80732] = 236,
    [80736] = 236,
    [80733] = 236,
    [80737] = 236,
    [80734] = 236,
    [80738] = 236,
    [80735] = 236,
    [80739] = 236,
    [80660] = 223,
    [80664] = 223,
    [80661] = 223,
    [80665] = 223,
    [80662] = 223,
    [80666] = 223,
    [80663] = 223,
    [80667] = 223,
    [80740] = 237,
    [80744] = 237,
    [80741] = 237,
    [80745] = 237,
    [80742] = 237,
    [80746] = 237,
    [80743] = 237,
    [80747] = 237,
    [80716] = 234,
    [80720] = 234,
    [80717] = 234,
    [80721] = 234,
    [80718] = 234,
    [80722] = 234,
    [80719] = 234,
    [80723] = 234,
    [80764] = 243,
    [80765] = 243,
    [80766] = 243,
    [80767] = 243,
    [80704] = 232,
    [80705] = 232,
    [80706] = 232,
    [80707] = 232,
    [80760] = 242,
    [80761] = 242,
    [80762] = 242,
    [80763] = 242,
    [80648] = 221,
    [80649] = 221,
    [80650] = 221,
    [80651] = 221,
    [80608] = 213,
    [80609] = 213,
    [80610] = 213,
    [80611] = 213,
    [80748] = 239,
    [80752] = 239,
    [80749] = 239,
    [80753] = 239,
    [80750] = 239,
    [80754] = 239,
    [80751] = 239,
    [80755] = 239,
    [80640] = 218,
    [80641] = 218,
    [80642] = 218,
    [80643] = 218,
    [80676] = 226,
    [80677] = 226,
    [80678] = 226,
    [80679] = 226,
    [80386] = 241,
    [80382] = 241,
    [80387] = 241,
    [80383] = 241,
    [80388] = 241,
    [80384] = 241,
    [80389] = 241,
    [80385] = 241,
    [80680] = 227,
    [80684] = 227,
    [80681] = 227,
    [80685] = 227,
    [80682] = 227,
    [80686] = 227,
    [80683] = 227,
    [80687] = 227,
    [80620] = 215,
    [80621] = 215,
    [80622] = 215,
    [80623] = 215,
    [80708] = 233,
    [80712] = 233,
    [80709] = 233,
    [80713] = 233,
    [80710] = 233,
    [80714] = 233,
    [80711] = 233,
    [80715] = 233,
    [80700] = 231,
    [80701] = 231,
    [80702] = 231,
    [80703] = 231,
    [80672] = 225,
    [80673] = 225,
    [80674] = 225,
    [80675] = 225,
    [80768] = 244,
    [80780] = 244,
    [80769] = 244,
    [80781] = 244,
    [80770] = 244,
    [80782] = 244,
    [80771] = 244,
    [80783] = 244,
    [80652] = 200,
    [80653] = 200,
    [80654] = 200,
    [80655] = 200,
    [80756] = 240,
    [80757] = 240,
    [80758] = 240,
    [80759] = 240,
    [80656] = 222,
    [80657] = 222,
    [80658] = 222,
    [80659] = 222,
    [80688] = 228,
    [80689] = 228,
    [80690] = 228,
    [80691] = 228,
    [80624] = 216,
    [80628] = 216,
    [80625] = 216,
    [80629] = 216,
    [80626] = 216,
    [80630] = 216,
    [80627] = 216,
    [80631] = 216,
    [96482] = 219,
    [97345] = 219,
    [96483] = 219,
    [97346] = 219,
    [96484] = 219,
    [97347] = 219,
    [96485] = 219,
    [97348] = 219,
};

function DataProvider:GetArtifactAppearanceSetName(sourceID)
    if sourceID and ArtifactSourceIDXArtifactSetID[sourceID] then
        return LocalizedData.ArtifactSetNames[ ArtifactSourceIDXArtifactSetID[sourceID] ]
    end
end

function DataProvider:IsLegionArtifactBySourceID(sourceID)
    return sourceID and ArtifactSourceIDXArtifactSetID[sourceID]
end