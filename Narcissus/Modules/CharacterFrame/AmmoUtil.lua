local _, addon = ...

---@class AmmoUtil
local AmmoUtil = {};
addon.AmmoUtil = AmmoUtil;

local Ammos = {
    -- Ammo itemID, item level from high to low
    arrow = {274387, 18042, 19316, 11285, 3464, 3030, 2515, 2512},
    bullet = {274388, 15997, 19317, 11630, 10513, 11284, 10512, 3465, 8069, 3033, 8068, 5568, 2519, 8067, 4960, 2516},
};

---@param ammoType "arrow"|"bullet"
---@return table? itemIDs
function AmmoUtil.GetAvailableAmmosByType(ammoType)
    local tbl = {};
    local n = 0;
    local GetItemCount = C_Item.GetItemCount;

    if Ammos[ammoType] then
        for _, itemID in ipairs(Ammos[ammoType]) do
            if GetItemCount(itemID) > 0 then
                n = n + 1;
                tbl[n] = itemID;
            end
        end
    end

    if n > 0 then
        return tbl;
    end
end
