local _, addon = ...
local DataProvider = addon.DataProvider;

local pairs = pairs;
local type = type;
local tinsert = table.insert;

local MAX_BOOKMARKS = 100;


local BookmarkUtil = {};
addon.BookmarkUtil = BookmarkUtil;

BookmarkUtil.isBookmarkedIDs = {};

function BookmarkUtil:GetDatabase()
    if not self.database then
        local db = NarciAchievementOptions;
        if not db then return {} end;

        if not db.BookmarkedAchievements then
            db.BookmarkedAchievements = {};
        end

        self.database = db.BookmarkedAchievements;
    end

    return self.database
end

function BookmarkUtil:Load()
    for _, id in pairs(self:GetDatabase()) do
        if type(id) == "number" then
            if not self.isBookmarkedIDs[id] then
                self.isBookmarkedIDs[id] = true;
            end
        end
    end

    self:MarkDirty();
end

function BookmarkUtil:Save()
    local tbl = {};
    local n = 0;
    local overflow = false;

    for id, state in pairs(self.isBookmarkedIDs) do
        if state and type(id) == "number" and not DataProvider:IsAchievementCompleted(id) then
            n = n + 1;
            if n > MAX_BOOKMARKS then
                overflow = true;
                break
            end
            tbl[n] = id;
        end
    end

    table.sort(tbl);
    NarciAchievementOptions.BookmarkedAchievements = tbl;
    self.database = tbl;

    self:MarkDirty();

    if overflow then
        UIErrorsFrame:AddMessage(string.format(Narci.L["Error Alert Bookmarks Too Many"], MAX_BOOKMARKS), 1.000, 0.282, 0.000, 1.0, 0);
        return false
    else
        return true
    end
end

function BookmarkUtil:IsBookmarked(id)
    return self.isBookmarkedIDs[id] and true
end

function BookmarkUtil:SetBookmark(id)
    if DataProvider:IsAchievementCompleted(id) then
        --Only allow to bookmark incomplete ACHV
        return
    end

    self.isBookmarkedIDs[id] = true;
    return BookmarkUtil:Save()
end

function BookmarkUtil:RemoveBookmark(id)
    if self:IsBookmarked(id) then
        self.isBookmarkedIDs[id] = false;
        return BookmarkUtil:Save();
    end
end

function BookmarkUtil:GetList()
    local list = {};
    local n = 0;

    for _, id in pairs(self:GetDatabase()) do
        if type(id) == "number" and not DataProvider:IsAchievementCompleted(id) then
            n = n + 1;
            list[n] = id;
        end
    end

    return list
end

function BookmarkUtil:ToggleBookmark(id)
    if self:IsBookmarked(id) then
        return self:RemoveBookmark(id);
    else
        return self:SetBookmark(id);
    end
end

function BookmarkUtil:BuildCategoryList()
    local categories = {};
    local categoryAchievements = {};
    local isAdded = {};

    local categoryID;
    local n = 0;

    for _, id in pairs(self:GetDatabase()) do
        categoryID = DataProvider:GetAchievementCategory(id);
        if categoryID then
            if not isAdded[categoryID] then
                isAdded[categoryID] = true;
                n = n + 1;
                categories[n] = categoryID;
                categoryAchievements[categoryID] = {};
            end
            tinsert(categoryAchievements[categoryID], id);
        end
    end

    table.sort(categories);
    self.categories = categories;
    self.categoryAchievements = categoryAchievements;
end

function BookmarkUtil:GetCategoryList()
    if not self.categories then
        self:BuildCategoryList();
    end

    return self.categories
end

function BookmarkUtil:GetNumAchievementsInCategory(categoryID)
    if not self.categories then
        self:BuildCategoryList();
    end

    if categoryID == -5 then    --reserved for show all achievements
        return #self:GetDatabase()
    else
        local numAchievements, numChildAchievements;
        numAchievements = (self.categoryAchievements[categoryID] and #self.categoryAchievements[categoryID]) or 0;

        if DataProvider:IsRootCategory(categoryID) then
            numChildAchievements = 0;
            local _, parentID;
            for cateID, achievements in pairs(self.categoryAchievements) do
                _, parentID = DataProvider:GetCategoryInfo(cateID);
                if parentID == categoryID then
                    numChildAchievements = numChildAchievements + #achievements;
                end
            end
        end

        return numAchievements, numChildAchievements
    end

end

function BookmarkUtil:GetAchievementIDInCategory(categoryID, index)
    if categoryID == -5 then
        return self:GetDatabase()[index]
    else
        if self.categoryAchievements[categoryID] then
            return self.categoryAchievements[categoryID][index]
        end
    end
end

function BookmarkUtil:MarkDirty()
    self.dirty = true;
end

function BookmarkUtil:OnTabSelected()
    if not self.dirty then return end;
    self.dirty = false;

    self:BuildCategoryList();
    return true
end