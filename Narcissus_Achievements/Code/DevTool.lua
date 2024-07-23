local After = C_Timer.After;
local GetAchievementInfo = GetAchievementInfo;
local GetAchievementNumCriteria = GetAchievementNumCriteria;
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo;
local GetPreviousAchievement = GetPreviousAchievement;
local GetNextAchievement = GetNextAchievement;

local ITERATION_PER_FRAME = 5;

local outputTable;
local playerCategories = {};
local guildCategories = {};

local function BuildCategories(isGuild)
    local categories;
    local targetTable;
    if isGuild then
        categories = GetGuildCategoryList();
        targetTable = guildCategories;
    else
        categories = GetCategoryList();
        targetTable = playerCategories;
    end

    local name, parentID, categoryID;
    for i = 1, #categories do
        categoryID = categories[i];
        if categoryID ~= 15093 and categoryID ~= 15234 and categoryID ~= 81 then
            name, parentID = GetCategoryInfo(categoryID);
            if parentID ~= 15234 and parentID ~= 81 and parentID ~= 15093 then
                tinsert(targetTable, categoryID);
            end
        end
    end

    if isGuild then
        print("Num Guild Categories: "..#targetTable);
    else
        print("Num Player Categories: "..#targetTable);
    end
end

local function BuildParentAchievement(achievementID, parentAchievementName)
    local numCriteria =  GetAchievementNumCriteria(achievementID);
    if numCriteria and numCriteria > 0 then
        for i = 1, numCriteria do
            local criteriaString, criteriaType, _, _, _, _, flags, subAchievementID = GetAchievementCriteriaInfo(achievementID, i);
            if criteriaType == 8 and subAchievementID then
                outputTable[subAchievementID] = achievementID;
                print("|cFFFFD100"..criteriaString.."|r "..subAchievementID.."|cFF808080  >>  |r|cFFFFD100"..parentAchievementName.."|r "..achievementID.."" )
            end
        end
    end
end

local function GetAchievementStructure(categoryID, fromIndex, maxIndex)
    for i = fromIndex, fromIndex + ITERATION_PER_FRAME do
        if i > maxIndex then
            return i, true
        else
            local baseAchievementID, name = GetAchievementInfo(categoryID, i);
            BuildParentAchievement(baseAchievementID, name);

            --Achievement Chain
            local achievementID = GetPreviousAchievement(baseAchievementID);
            while achievementID do
                BuildParentAchievement(achievementID, name);
                achievementID = GetPreviousAchievement(achievementID);
            end
            achievementID = GetNextAchievement(baseAchievementID);
            while achievementID do
                BuildParentAchievement(achievementID, name);
                achievementID = GetNextAchievement(achievementID);
            end
        end
    end
    return fromIndex + ITERATION_PER_FRAME, false
end


local Loader = CreateFrame("Frame");
Loader:Hide();
Loader:SetScript("OnUpdate", function(self, elapsed)
    local finisehdID, isComplete = GetAchievementStructure(self.categoryID, self.fromIndex, self.maxIndex);
    if isComplete then
        self:Hide();
        self.fromIndex = 1;
        self.maxIndex = 0;
        After(0, function()
            self.categoryIndex = self.categoryIndex + 1;
            if self.categoryIndex < self.maxCategoryIndex then
                local categoryID = self.categories[self.categoryIndex];
                self:GetStructure(categoryID);
            else
                print("");
                print("Finisehd!");
            end
        end);
    else
        self.fromIndex = finisehdID + 1;
    end
end)

function Loader:GetStructure(categoryID)
    local numAchievements = GetCategoryNumAchievements(categoryID, false);
    local categoryName = GetCategoryInfo(categoryID);
    print("|cff7cc576"..categoryName.."|r "..categoryID.."\n");
    Loader:Hide();
    Loader.categoryID = categoryID;
    Loader.fromIndex = 1;
    Loader.maxIndex = numAchievements;
    Loader:Show();
end

function Loader:LoadList(category)
    local numCategories = #category;
    self.categoryIndex = 1;
    self.maxCategoryIndex = numCategories;
    self.categories = category;
    self:GetStructure(category[1]);
end



function GetAchievementRelationship(isGuild)
    --Save the output to Narcissus\Modules\Achievement\Meta.lua
    --Run this on Horde and Alliance characters (some achievements are faction-based)
    if not NarciDevToolOutput then
        NarciDevToolOutput = {};
    end
    NarciDevToolOutput.parentAchievementData = NarciDevToolOutput.parentAchievementData or {};
    if not outputTable then
        outputTable = NarciDevToolOutput.parentAchievementData;
    end
    BuildCategories(isGuild);
    After(1, function()
        Loader:LoadList((isGuild and guildCategories) or playerCategories);
    end);
end