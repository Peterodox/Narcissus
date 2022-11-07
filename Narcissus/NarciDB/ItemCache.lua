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
