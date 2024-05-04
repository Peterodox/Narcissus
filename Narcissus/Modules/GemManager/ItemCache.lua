local _, addon = ...
local Gemma = addon.Gemma;

local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID;
local GetItemInfo = C_Item.GetItemInfo;
local GetItemIcon = C_Item.GetItemIconByID;
local IsItemDataCachedByID = C_Item.IsItemDataCachedByID;
local type = type;

local ItemCache = CreateFrame("Frame");
Gemma.ItemCache = ItemCache;

ItemCache:SetScript("OnEvent", function(self, event, ...)
    if event == "ITEM_DATA_LOAD_RESULT" then
        local id, success = ...
        if self.callbacks[id] then
            if success then
                self:CacheItem(id, true);
                if type(self.callbacks[id]) ~= "boolean" then
                    self.callbacks[id]:OnItemLoaded(id);
                end
            end
            self.callbacks[id] = nil;
        end
        self.t = 0;
    end
end);

function ItemCache:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.5 then
        self.t = 0;
        self.counter = self.counter + 1;

        local anyPending;

        for k, v in pairs(self.callbacks) do
            anyPending = true;
            break
        end

        if anyPending and self.counter < 2 then

        else
            self:StopLoading();
        end
    end
end

function ItemCache:StopLoading()
    self:SetScript("OnUpdate", nil);
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
    self.isCaching = nil;
    self.callbacks = nil;
    self.t = nil;
    self.counter = nil;
end

function ItemCache:RequestItemData(itemID, object)
    self.t = 0;
    self.counter = 0;
    self:SetScript("OnUpdate", self.OnUpdate);

    if not self.isCaching then
        self.isCaching = true;
        self:RegisterEvent("ITEM_DATA_LOAD_RESULT");
        if not self.callbacks then
            self.callbacks = {};
        end
    end

    self.callbacks[itemID] = object or true;

    RequestLoadItemDataByID(itemID);
end

function ItemCache:CacheItem(itemID, fromEvent, object)
    if not ItemCache[itemID] then
        if IsItemDataCachedByID(itemID) then
            local itemName, _, quality = GetItemInfo(itemID);
            local icon = GetItemIcon(itemID);
            ItemCache[itemID] = {itemName, icon, quality};

            --print(string.format("|T%s:0:0:0:0|t %s", icon, itemName));--debug
        elseif not fromEvent then
            self:RequestItemData(itemID, object);
        end
    end
end

function ItemCache:GetCacheItemDataByIndex(itemID, index, object)
    self:CacheItem(itemID, false, object);

    if ItemCache[itemID] then
        return ItemCache[itemID][index]
    end
end

function ItemCache:GetItemName(itemID, object)
    return self:GetCacheItemDataByIndex(itemID, 1, object)
end

function ItemCache:GetItemIcon(itemID, object)
    return self:GetCacheItemDataByIndex(itemID, 2, object)
end

function ItemCache:GetItemQuality(itemID, object)
    return self:GetCacheItemDataByIndex(itemID, 3, object)
end