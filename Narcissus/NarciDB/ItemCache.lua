--The tooltip data of some items, though C_Item.IsItemDataCached returns true, may be incomplete (missing effect descriptions), so we have to create our own cache

local _, addon = ...

local ItemCacheUtil = {};
addon.ItemCacheUtil = ItemCacheUtil;

local CachedItemIDs = {};

local type = type;
local RequestLoadItemDataByItemLocation = C_Item.RequestLoadItemData;
local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID;
local GetItemID = C_Item.GetItemID;
local GetItemInfoInstant = GetItemInfoInstant;

function ItemCacheUtil:IsItemDataCached(item)
    if type(item) == "number" then
        if CachedItemIDs[item] then
            return true
        end
        CachedItemIDs[item] = true;
        RequestLoadItemDataByID(item);
    elseif type(item) == "table" then   --itemLocation
        local itemID = GetItemID(item);
        if not itemID then return end
        if CachedItemIDs[itemID] then
            return true
        end
        CachedItemIDs[itemID] = true;
        RequestLoadItemDataByItemLocation(item);
    else    --itemlink
        local itemID = GetItemInfoInstant(item);
        if not itemID then return end
        if CachedItemIDs[itemID] then
            return true
        end
        CachedItemIDs[itemID] = true;
        RequestLoadItemDataByID(item);
    end

    return false
end



---- Debug Test Find Quest Item And Its Quest
--[[
function NarciDebug_GetQuestTitles()
    if not NarcissusTestDB then
        NarcissusTestDB = {};
    end

    if not NarcissusTestDB.questTitles then
        NarcissusTestDB.questTitles = {};
    end

    local db = NarcissusTestDB.questTitles;

    local IsWorldQuest = C_QuestLog.IsWorldQuest;
    local IsQuestTask = C_QuestLog.IsQuestTask;
    local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted;
    local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID;
    local GetQuestExpansion = GetQuestExpansion;
    local tinsert = table.insert;

    local targetExpansion = 9;
    local questID, title, expansionID;
    local offset = 76000;   --74378
    local total = 0;

    for i = 1, 14000 do
        questID = offset - i;
        if not db[questID] then
            if not (IsQuestTask(questID) or IsWorldQuest(questID)) then
                expansionID = GetQuestExpansion(questID);
                if expansionID == targetExpansion and (not IsQuestFlaggedCompleted(questID)) then
                    title = GetTitleForQuestID(questID);
                    if title and title ~= "" then
                        total = total + 1;
                        db[questID] = title;
                        if total <= 100 then
                            print(questID, GetQuestExpansion(questID), title);
                        end
                    end
                end
            end
        end
    end

    print("New Total: "..total);
end


function NarciDebug_GetQuestItems()
    if not NarcissusTestDB then
        NarcissusTestDB = {};
    end

    if not NarcissusTestDB.questItems then
        NarcissusTestDB.questItems = {};
    end

    local db = NarcissusTestDB.questItems;

    local GetItemInfoInstant = GetItemInfoInstant;
    local _, classID;
    local total = 0;
    for itemID = 179921, 223716 do
        _, _, _, _, _, classID = GetItemInfoInstant(itemID);
        if classID and classID == 12 then
            if not db[itemID] then
                db[itemID] = true;
                total = total + 1;
            end
        end
    end

    print("Quest Items: "..total)
end

function NarciDebug_GetQuestItemNames()
    if not (NarcissusTestDB and NarcissusTestDB.questItems) then
        return
    end

    if not NarcissusTestDB.questItemNames then
        NarcissusTestDB.questItemNames = {};
    end

    local db = NarcissusTestDB.questItemNames;
    
    local GetItemNameByID = C_Item.GetItemNameByID;
    local name;
    local total = 0;

    for itemID in pairs(NarcissusTestDB.questItems) do
        if not db[itemID] then
            name = GetItemNameByID(itemID);
            if name and name ~= "" then
                db[itemID] = name;
                total = total + 1;
            end
        end
    end

    print("New Names: "..total);
end

local KNOWN_ITEMS = {};

do
    local knownItems = {
        198475, 198626, 198543, 199841, 199840, 199843, 199842, 199895, 199893, 198540,
    };

    for _, itemID in ipairs(knownItems) do
        KNOWN_ITEMS[itemID] = true;
    end
end

function NarciDebug_FindSameNames()
    local itemNames = NarcissusTestDB.questItemNames
    local questNames = {};

    for questID, name in pairs(NarcissusTestDB.questTitles) do
        questNames[name] = questID;
    end

    local idMatch = {};

    for itemID, name in pairs(itemNames) do
        if questNames[name] then
            table.insert(idMatch, itemID);
        end
    end

    table.sort(idMatch);

    local name;

    for _, itemID in ipairs(idMatch) do
        if not KNOWN_ITEMS[itemID] then
            name = itemNames[itemID];
            print(itemID, questNames[name], name);
        end
    end
end
--]]