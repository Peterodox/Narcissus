local _, addon = ...
local Gemma = addon.Gemma;
local ItemCache = Gemma.ItemCache;

Gemma:SetDataProviderByName("Pandaria");

function DLIN()
    local itemList = Gemma:GetSortedItemList()
    local name;
    for gemType, gems in ipairs(itemList) do
        for index, itemID in ipairs(gems) do
            name = ItemCache:GetItemName(itemID);
            if name then
                print(name)
            end
        end
    end
end
