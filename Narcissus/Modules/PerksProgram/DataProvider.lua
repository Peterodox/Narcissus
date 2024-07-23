local _, addon = ...

local DataProvider = {};
addon.PerksProgramDataProvider = DataProvider;

local PerksProgramAPI = C_PerksProgram;
local C_TransmogCollection = C_TransmogCollection;

if PerksProgramAPI then
    DataProvider.programExisted = true;
else
    PerksProgramAPI = {};
end

local CURRENCY_ID = Constants.CurrencyConsts.CURRENCY_ID_PERKS_PROGRAM_DISPLAY_INFO or 2032;

local GetVendorItemInfo = PerksProgramAPI.GetVendorItemInfo;
local GetTimeRemaining = PerksProgramAPI.GetTimeRemaining;
local GetCurrencyAmount = PerksProgramAPI.GetCurrencyAmount;     --Returns the amount of Trader's Tendor (2032) Constants.CurrencyConsts.CURRENCY_ID_PERKS_PROGRAM_DISPLAY_INFO

local GetCurrentCalendarTime = C_DateAndTime.GetCurrentCalendarTime;
local type = type;



local VendorItemDataCache = {};
local DB;

local IGNORED_KEYS = {
    purchased = true,
    perksVendorItemID = true,
    timeRemaining = true,
    refundable = true,
    pending = true,
};

local DELIMITER = "::";

local function CompressTable(tbl)
    local output = DELIMITER;
    local valueType;

    for k, v in pairs(tbl) do
        if not IGNORED_KEYS[k] then
            valueType = type(v);
            if valueType == "number" or valueType == "string" and v ~= 0 and v ~= "" then
                output = output ..k ..DELIMITER.. v ..DELIMITER;
            end
        end
    end

    return output
end

local function DecompressData(dataString)
    local key, value, seg;
    local numericVal;
    local tonumber = tonumber;
    local find = string.find;
    local strsub = string.sub;

    local tbl = {};
    local isKey = true;
    local stringLen = string.len(dataString);

    local initPos = 3;
    local fromIndex, toIndex = find(dataString, DELIMITER, initPos);

    while fromIndex and toIndex do
        seg = strsub(dataString, initPos, fromIndex - 1);
        initPos = toIndex + 1;
        fromIndex, toIndex = find(dataString, DELIMITER, initPos);
        if isKey then
            key = seg;
        else
            value = seg;
            numericVal = tonumber(value);
            if numericVal then
                tbl[key] = numericVal;
            else
                tbl[key] = value;
            end
        end
        isKey = not isKey;
    end

    return tbl
end

function DataProvider:DoesPerksProgramExist()
    return self.programExisted
end

function DataProvider:IsNewVendorItem(vendorItemID)
    return vendorItemID and DB.VendorItems[vendorItemID] == nil
end

function DataProvider:SaveVendorItemData(vendorItemID, overwrite)
    if vendorItemID and (overwrite or self:IsNewVendorItem(vendorItemID)) then
        local info = GetVendorItemInfo(vendorItemID);
        if info and info.perksVendorItemID and info.perksVendorItemID ~= 0 then
            if info.name == "" or info.description == "" then
                return false
            end
            local dataString = CompressTable(info);
            local month, year = self:GetActivePerksDate();
            local date = year.."/"..month;
            dataString = dataString .. "addedDate" ..DELIMITER.. date ..DELIMITER;

            VendorItemDataCache[vendorItemID] = info;
            info.addedInYear = year;
            info.addedInMonth = month;

            DB.VendorItems[vendorItemID] = dataString;

            return dataString
        end
    end
end

function DataProvider:GetVendorItemInfoFromDatabase(vendorItemID)
    local info;
    if DB.VendorItems[vendorItemID] then
        info = DecompressData( DB.VendorItems[vendorItemID] );
        info.isCache = true;
        return info
    end
end

function DataProvider:GetAndCacheVendorItemInfo(vendorItemID)
    if not VendorItemDataCache[vendorItemID] then
        local info = GetVendorItemInfo(vendorItemID);
        --! After patch ?, the perksVendorItemID will not return 0 even you haven't visited Trading Post during the game session
        --! So (perksVendorItemID ~= 0) is no longer a reliable way to check if we need to decompress data from our SavedVariables
        if info and info.perksVendorItemID ~= 0 then
            if info.name and info.name ~= "" then
                VendorItemDataCache[vendorItemID] = info;
            end
            return info
        else
            VendorItemDataCache[vendorItemID] = self:GetVendorItemInfoFromDatabase(vendorItemID);
        end
    end
    return VendorItemDataCache[vendorItemID]
end

function DataProvider:GetVendorItemName(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info then
        return info.name
    else
        return ""
    end
end

function DataProvider:GetVendorItemCategory(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info then
        return info.perksVendorCategoryID
    else
        return 128
    end
end

function DataProvider:GetVendorItemDescription(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info then
        return info.description
    else
        return ""
    end
end

function DataProvider:GetVendorItemPrice(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info then
        if info.isCache then
            return info.price or 0
        else
            local cachedData = self:GetVendorItemInfoFromDatabase(vendorItemID);
            local price = cachedData and cachedData.price;
            if price then
                return price
            end
        end
    end
    return 0
end

function DataProvider:GetVendorItemTransmogSetID(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info and info.transmogSetID ~= 0 then
        return info.transmogSetID
    else
        local cachedData = self:GetVendorItemInfoFromDatabase(vendorItemID);
        return cachedData and cachedData.transmogSetID or nil;
    end
end

function DataProvider:GetVendorItemTransmogSourceID(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info and info.itemModifiedAppearanceID ~= 0 then
        return info.itemModifiedAppearanceID
    else
        local cachedData = self:GetVendorItemInfoFromDatabase(vendorItemID);
        if cachedData and cachedData.itemModifiedAppearanceID and cachedData.itemModifiedAppearanceID ~= 0 then
            return cachedData.itemModifiedAppearanceID
        end
    end
end

function DataProvider:IsVendorItemPurchased(vendorItemID)
    local info = self:GetAndCacheVendorItemInfo(vendorItemID);
    if info then
        if info.isCache or (info.price == 0) then
            --Player didn't visit Trading Post during this session, use cache
            --[[
1 Transmog
2 Mount
3 Pet
5 Toy
7 Illusion
8 Transmogset
            --]]
            local itemID = info.itemID;
            local category = info.perksVendorCategoryID;

            if category == 1 then
                local appearanceID;
                local sourceID = info.itemModifiedAppearanceID;
                if (not sourceID) or sourceID == 0 then
                    appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemID);
                end
                if sourceID and sourceID ~= 0 then
                    return C_TransmogCollection.PlayerKnowsSource(sourceID);
                end

            elseif category == 2 then
                local mountID = C_MountJournal.GetMountFromItem(itemID);
                if mountID then
                    local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID));
                    return isCollected
                end
            
            elseif category == 3 then
                local petName = C_PetJournal.GetPetInfoByItemID(itemID);
                if petName then
                    local _, petGUID = C_PetJournal.FindPetIDByName(petName);
                    return petGUID ~= nil
                end

            elseif category == 5 then
                return PlayerHasToy(itemID);

            elseif category == 7 then
                local illusionID = info.illusionID;
                if illusionID then
                    local tbl = C_TransmogCollection.GetIllusionInfo(illusionID);
                    return tbl and tbl.isCollected
                end

            elseif category == 8 then
                local transmogSetID = info.transmogSetID;
                if transmogSetID == 0 then
                    local itemInfo = DataProvider:GetVendorItemInfoFromDatabase(vendorItemID);
                    transmogSetID = itemInfo and itemInfo.transmogSetID;
                end
                if transmogSetID then
                    local sourceIDs = C_TransmogSets.GetAllSourceIDs(transmogSetID);
                    if sourceIDs and sourceIDs[1] then
                        return C_TransmogCollection.PlayerKnowsSource( sourceIDs[1] );
                    end
                end
            end
        end

        return info.purchased
    end
end

function DataProvider:GetVendorItemPriceBySourceID(sourceID)
    local vendorItemIDs = self:GetCurrentMonthItems();
    if vendorItemIDs then
        for _, vendorItemID in ipairs(vendorItemIDs) do
            if self:GetVendorItemTransmogSourceID(vendorItemID) == sourceID then
                return self:GetVendorItemPrice(vendorItemID), self:IsVendorItemPurchased(vendorItemID)
            end
        end
    end
end

function DataProvider:UpdateActivePerksMonthInfo()
    if not (self.month and self.currentMonthName) then
        local activitiesInfo = C_PerksActivities.GetPerksActivitiesInfo();
        local month  = activitiesInfo.activePerksMonth;
        local currentCalendarTime = GetCurrentCalendarTime();
        local year = currentCalendarTime.year;
        self.currentMonthName = activitiesInfo.displayMonthName;
        self.year = year;
        self.month = month;

        for _, monthInfo in ipairs(DB.MonthNames) do
            if month == monthInfo.m and year == monthInfo.y then
                return
            end
        end
    
        table.insert(DB.MonthNames, {
            y = year,
            m = month,
            n = activitiesInfo.displayMonthName,
        });
    end
end

function DataProvider:GetActivePerksDate()
    self:UpdateActivePerksMonthInfo();
    return self.month, self.year
end

function DataProvider:GetCurrentDisplayMonthName()
    self:UpdateActivePerksMonthInfo();
    return self.currentMonthName;
end

function DataProvider:GetDisplayMonthName(year, month)
    if type(year) == "string" then
        year, month = string.match(year, "(%d+)/(%d+)");
        year = tonumber(year);
        month = tonumber(month);
    end

    if not self.monthNames then
        --[year] = {[month] = name},
        self.monthNames = {};
        for _, monthInfo in ipairs(DB.MonthNames) do
            if not self.monthNames[monthInfo.y] then
                self.monthNames[monthInfo.y] = {};
            end
            self.monthNames[monthInfo.y][monthInfo.m] = monthInfo.n;
        end
    end

    if not self.monthNames[year] then
        self.monthNames[year] = {};
    end

    if not self.monthNames[year][month] then
        self.monthNames[year][month] = self:GetCurrentDisplayMonthName();
    end

    return self.monthNames[year][month]
end


local EventListener = CreateFrame("Frame");

if DataProvider:DoesPerksProgramExist() then
    EventListener:RegisterEvent("PERKS_ACTIVITIES_UPDATED");
    EventListener:RegisterEvent("PERKS_ACTIVITY_COMPLETED");
    EventListener:RegisterEvent("PERKS_PROGRAM_DATA_REFRESH");
    EventListener:RegisterEvent("PERKS_PROGRAM_CURRENCY_REFRESH");
    EventListener:RegisterEvent("PERKS_PROGRAM_REFUND_SUCCESS");
    EventListener:RegisterEvent("PERKS_PROGRAM_PURCHASE_SUCCESS");
end

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PERKS_ACTIVITIES_UPDATED" or event == "PERKS_ACTIVITY_COMPLETED" then
        DataProvider:ClearActivityCache();
    elseif event == "PERKS_PROGRAM_DATA_REFRESH" then
        local vendorItemIDs = C_PerksProgram.GetAvailableVendorItemIDs();

        for _, vendorItemID in pairs(vendorItemIDs) do
            GetVendorItemInfo(vendorItemID);
        end

        C_Timer.After(1, function()
            for _, vendorItemID in pairs(vendorItemIDs) do
                GetVendorItemInfo(vendorItemID);
                DataProvider:SaveVendorItemData(vendorItemID);
            end
        end);

        DataProvider:UpdateActivePerksMonthInfo();

        if not self.monthItemUpdated then
            self.monthItemUpdated = true;
            local forceUpdate = true;
            DataProvider:SaveCurrentMonthItems(vendorItemIDs, forceUpdate);
        end

    elseif event == "PERKS_PROGRAM_CURRENCY_REFRESH" then
        DataProvider.ownedCurrencyAmount = nil;
    elseif event == "PERKS_PROGRAM_REFUND_SUCCESS" or event == "PERKS_PROGRAM_PURCHASE_SUCCESS" then
        local vendorItemID = ...;
        local isOwned = event == "PERKS_PROGRAM_PURCHASE_SUCCESS";
        if vendorItemID and VendorItemDataCache[vendorItemID] then
            VendorItemDataCache[vendorItemID].purchased = isOwned;
            VendorItemDataCache[vendorItemID].refundable = isOwned;
        end
        DataProvider.ownedCurrencyAmount = nil;
    end
end);

function DataProvider:ClearActivityCache()
    self.unclaimedPoints = nil;
    self.unearnedPoints = nil;
    self.currentMonthName = nil;
    self.month = nil;
end

function DataProvider:CacheActivityInfo()
    if not self.unclaimedPoints then
        local pendingRewards = PerksProgramAPI.GetPendingChestRewards();
        local numUnclaimed = 0;

        if pendingRewards then
            for _, reward in pairs(pendingRewards) do
                numUnclaimed = numUnclaimed + (reward.rewardAmount or 0);
            end
        end

        self.unclaimedPoints = numUnclaimed;
    end

    if not self.unearnedPoints then
        local activitiesInfo = C_PerksActivities.GetPerksActivitiesInfo();
        local currentPoints = 0;
        local numUnearned = 0;

        for _, activityInfo in pairs(activitiesInfo.activities) do
            if activityInfo.completed then
                currentPoints = currentPoints + activityInfo.thresholdContributionAmount;
            end
        end

        for _, thresholdInfo in pairs(activitiesInfo.thresholds) do
            if thresholdInfo.requiredContributionAmount > currentPoints then
                numUnearned = numUnearned + thresholdInfo.currencyAwardAmount;
            end
        end

        self.unearnedPoints = numUnearned;
    end
end

function DataProvider:GetAvailableCurrency()
    --Returns the amounts of unclaimed and unearned token
    self:CacheActivityInfo();
    return self.unclaimedPoints or 0, self.unearnedPoints or 0;
end

function DataProvider:GetCurrencyAmount()
    if not self.ownedCurrencyAmount then
        self.ownedCurrencyAmount = GetCurrencyAmount() or 0;
    end
    return self.ownedCurrencyAmount
end

function DataProvider:SaveCurrentMonthItems(vendorItemIDs, forceUpdate)
    --Sometimes not all items are immediately available on day 1
    local month = self:GetActivePerksDate();
    if month ~= DB.CurrentMonthData.month or forceUpdate then
        local tbl = {};
        local total = 0;
        for i, id in ipairs(vendorItemIDs) do
            if id ~= 0 then
                total = total + 1;
                tbl[total] = id;
            end
        end
        DB.CurrentMonthData.items = tbl;
        DB.CurrentMonthData.month = month;
    end
end

function DataProvider:GetCurrentMonthItems()
    local month = self:GetActivePerksDate();
    if month and month == DB.CurrentMonthData.month then
        return DB.CurrentMonthData.items
    else
        DB.CurrentMonthData = {};
    end
end

function DataProvider:GetVendorItemAddedMonthName(vendorItemID)
    local info = self:GetVendorItemInfoFromDatabase(vendorItemID);
    if info and info.addedDate then
        if not self.currentMonthDate then
            local month, year = self:GetActivePerksDate();
            self.currentMonthDate = year.."/"..month;
        end

        local monthName = DataProvider:GetDisplayMonthName(info.addedDate);
        return monthName, (self.currentMonthDate == info.addedDate);
    else
        return nil, true
    end
end

function DataProvider:IsValidItem(vendorItemID)
    local categoryID = self:GetVendorItemCategory(vendorItemID);
    return categoryID and categoryID ~=0 and categoryID ~= 128
end


do
    local time = time;
    local EpochToDate = NarciAPI.EpochToDate;

    function DataProvider:SaveUserData(dataKey, data)
        DB[dataKey] = data;
    end

    function DataProvider:GetUserData(dataKey)
        return DB[dataKey]
    end

    function DataProvider:SetTimeLimitedData(dataKey, data)
        --Data saved in DB that expire next month
        local tbl = {};
        tbl.timeChanged = time();
        tbl.data = data;
        self:SaveUserData(dataKey, tbl);
    end

    function DataProvider:GetTimeLimitedData(dataKey)
        local data = self:GetUserData(dataKey);
        if data then
            local currentDate = EpochToDate(time());
            local oldDate =  EpochToDate(data.timeChanged);
            if currentDate.month == oldDate.month then
                return data.data
            end
        end
    end
end


local function LoadDatabase()
    if not NarcissusDB.PerksProgramDB then
        NarcissusDB.PerksProgramDB = {};
    end

    DB = NarcissusDB.PerksProgramDB;

    if not DB.VendorItems then
        DB.VendorItems = {};
    end

    if not DB.MonthNames then
        DB.MonthNames = {};
    end

    if not DB.CurrentMonthData then
        DB.CurrentMonthData = {};
    end
end

addon.AddInitializationCallback(LoadDatabase);


--[[
local activitiesInfo = C_PerksActivities.GetPerksActivitiesInfo();
[thresholds]
[displayMonthName]


Enum.PerksVendorCategoryType
1 Transmog
2 Mount
3 Pet
5 Toy
7 Illusion
8 Transmogset
--]]
