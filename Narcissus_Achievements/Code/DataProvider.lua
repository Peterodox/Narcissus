local _, addon = ...;
local DataProvider = {};
addon.DataProvider = DataProvider;

local GetAchievementCategory = GetAchievementCategory;
local GetCategoryInfo = GetCategoryInfo;
local GetAchievementInfo = GetAchievementInfo;
local SetFocusedAchievement= SetFocusedAchievement;

--Changed in 10.1.5 (C_ContentTracking)
local GetTrackedAchievements = GetTrackedAchievements;
local RemoveTrackedAchievement = RemoveTrackedAchievement;
local AddTrackedAchievement = AddTrackedAchievement;

do
    local TRACKING_TYPE_ACHV = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2;

    if C_ContentTracking then
        if C_ContentTracking.GetTrackedIDs then
            GetTrackedAchievements = function()
                return unpack(C_ContentTracking.GetTrackedIDs(TRACKING_TYPE_ACHV))
            end
        end

        if C_ContentTracking.StopTracking then
            RemoveTrackedAchievement = function(id)
                C_ContentTracking.StopTracking(TRACKING_TYPE_ACHV, id, Enum.ContentTrackingStopType.Manual);
            end
        end

        if C_ContentTracking.StartTracking then
            AddTrackedAchievement = function(id)
                AchievementFrame_LoadUI();  --Due to the change of Objective Tracker in 10.1.5;

                local trackingError = C_ContentTracking.StartTracking(TRACKING_TYPE_ACHV, id);
                if trackingError then
                	ContentTrackingUtil.DisplayTrackingError(trackingError);
                end
            end
        end

        if C_ContentTracking.IsTracking then
            function DataProvider:IsTrackedAchievement(id)
                return C_ContentTracking.IsTracking(TRACKING_TYPE_ACHV, id)
            end
        end
    else
        function DataProvider:IsTrackedAchievement(id)
            return self.isTrackedAchievements[id]
        end
    end
end


local NARCI_CATE_ID = 12080000;

DataProvider.categoryCache = {
    [NARCI_CATE_ID] = {"Narcissus", -1},
};

DataProvider.achievementCache = {};
DataProvider.achievementOrderCache = {};
DataProvider.id2Button = {};
DataProvider.currentCategory = 0;
DataProvider.isTrackedAchievements = {};
DataProvider.trackedAchievements = {};
DataProvider.rootCategories = {};

function DataProvider:ClearCache()
    self.categoryCache = {};
    self.achievementCache = {};
    collectgarbage("collect");
end

function DataProvider:GetCategoryInfo(id, index)
    if id and id >= NARCI_CATE_ID or id < 0 then
        return "Narcissus", -1
    end
    if not self.categoryCache[id] then
        local name, parentID, flags = GetCategoryInfo(id);
        if name then
            self.categoryCache[id] = { name, parentID, flags };
        end
        return name, parentID, flags;
    else
        if index then
            return self.categoryCache[id][index];
        else
            return unpack( self.categoryCache[id] );
        end
    end
end

function DataProvider:GetAchievementCategory(achievementID)
    if achievementID and achievementID > NARCI_CATE_ID or achievementID < 0 then
        return NARCI_CATE_ID
    else
        return GetAchievementCategory(achievementID)
    end
end

function DataProvider:GetAchievementInfo(id, index)
    if not id or id < 0 then
        return id
    end
    if id > NARCI_CATE_ID then
        --reserved for Narcissus Statistics
        return id
    end
    if not self.achievementCache[id] then
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(id);
        if isGuild then
            SetFocusedAchievement(id);
        end
        if description then
            self.achievementCache[id] = {id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, true, isStatistic};
        end
        if index then
            if self.achievementCache[id] then
                return self.achievementCache[id][index];
            end
        else
            return id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic
        end
    else
        if index then
            return self.achievementCache[id][index];
        else
            return unpack( self.achievementCache[id] );
        end
    end
end

function DataProvider:IsStatistic(id)
    if id > NARCI_CATE_ID or id < 0 then
        --reserved for Narcissus Statistics
        return true
    end
    if self.achievementCache[id] then
        return self.achievementCache[id][15]
    else
        local isStatistic = select(15, GetAchievementInfo(id));
        return isStatistic
    end
end

function DataProvider:UpdateAchievementCache(id)
    if self.achievementCache[id] then
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(id);
        if isGuild then
            SetFocusedAchievement(id);
        end
        if description then
            self.achievementCache[id] = {id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe};
        end
    end
end

function DataProvider:GetAchievementInfoByOrder(categoryID, order)
    if not self.achievementOrderCache[categoryID] then
        self.achievementOrderCache[categoryID] = {};
    end

    if not self.achievementOrderCache[categoryID][order] then
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(categoryID, order);
        if isGuild then
            SetFocusedAchievement(id);
        end
        if description then
            self.achievementOrderCache[categoryID][order] = id;
            self.achievementCache[id] = {id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe};
        end
        return id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy
    else
        local id = self.achievementOrderCache[categoryID][order];
        return self:GetAchievementInfo(id)
    end
end

function DataProvider:GetCategoryButtonByID(categoryID, isGuild)
    return self.id2Button[categoryID];
end

function DataProvider:GetTrackedAchievements()
    local new = {GetTrackedAchievements()} or {};
    local old = self.trackedAchievements;
    local numNew, numOld = #new, #old;
    local dif;

    if numNew >= numOld then
        local lookup = {};
        for i = 1, #old do
            lookup[ old[i] ] = true;
        end
        for i = 1, #new do
            if not lookup[ new[i] ] then
                dif = new[i];
                break
            end
        end
    else
        local lookup = {};
        for i = 1, #new do
            lookup[ new[i] ] = true;
        end
        for i = 1, #old do
            if not lookup[ old[i] ] then
                dif = old[i];
                break
            end
        end
    end

    self.trackedAchievements = new;
    self.numTrackedAchievements = #new;
    self.isTrackedAchievements = {};
    for index, id in pairs(new) do
        self.isTrackedAchievements[id] = true;
    end
    return dif
end

function DataProvider:StopTracking(id)
    RemoveTrackedAchievement(id);
end

function DataProvider:StartTracking(id)
    AddTrackedAchievement(id);
end

function DataProvider:IsAchievementCompleted(id)
    return self:GetAchievementInfo(id, 4) and true
end

function DataProvider:IsRootCategory(categoryID)
    if self.rootCategories[categoryID] == nil then
        local name, parentID = self:GetCategoryInfo(categoryID);
        self.rootCategories[categoryID] = (parentID == -1 or parentID == 15076) or false;
    end
    return self.rootCategories[categoryID]
end