local _, addon = ...

local EXTRA_ACTION_BUTTON_ACTION = 217;
local FORBIDDEN_REACH_MAP_ID = 2151;

local ITEM_ID_RING = 203460;
local SPELL_ID_PLUCK = 405805;
local SPELL_ID_BREAK = 405721;

local GetActionInfo = GetActionInfo;
--local GetActionTexture = GetActionTexture;
local HasExtraActionBar = HasExtraActionBar;


local GetItemPositionByItemID = NarciAPI.GetItemPositionByItemID;

local SHOW_UI;

local EL;

local module = addon.CreateZoneTriggeredModule();
module:SetValidZones(FORBIDDEN_REACH_MAP_ID);

local function OnEnabledCallback()
    if not EL then
        EL = CreateFrame("Frame");

        EL:SetScript("OnEvent", function(self, event, ...)
            if HasExtraActionBar() then
                local actionType, id, subType = GetActionInfo(EXTRA_ACTION_BUTTON_ACTION);
                if id == SPELL_ID_PLUCK or id == SPELL_ID_BREAK then
                    if not SHOW_UI then
                        SHOW_UI = true;
                    end

                    if id == SPELL_ID_PLUCK then
                        local positionType, id1, id2 = GetItemPositionByItemID(ITEM_ID_RING);
                        if positionType == "inventory" then
                            SocketInventoryItem(id1);
                        elseif positionType == "container" then
                            C_Container.SocketContainerItem(id1, id2);
                        end
                    end
                end
            else
                if SHOW_UI then
                    SHOW_UI = false;
                    CloseSocketInfo();
                end
            end
        end);
    end

    EL:RegisterEvent("UPDATE_EXTRA_ACTIONBAR");
end

local function OnDisabledCallback()
    if EL then
        EL:UnregisterEvent("UPDATE_EXTRA_ACTIONBAR");
    end
end

module:SetOnEnabledCallback(OnEnabledCallback);
module:SetOnDisabledCallback(OnDisabledCallback);



--[[
API:
    actionType, id, subType = GetActionInfo(slot)   --"spell"
    GetActionTexture
    HasExtraActionBar

    ----
    ItemSocketingFrame_LoadUI


Pluck Out: spellID 405805
Break Down: spellID 405721

Plucking Method:
    #1
        /click ExtraActionButton1
        /click ItemSocketingSocket1

    #2
        /click ExtraActionButton1
        /run ClickSocketButton(1)

--]]

--[[
local LAST_RECIPE_ID, LAST_REAGENTS;

local function Tooltip_SetRecipeResultItem(tooltip, recipeID, craftingReagents, recraftItemGUID, recipeLevel, overrideQualityID)
    --C_TooltipInfo.GetRecipeResultItem(recipeID [, craftingReagents, recraftItemGUID, recipeLevel, overrideQualityID]) 
    --print(recipeID, recraftItemGUID, recipeLevel, overrideQualityID);
    if overrideQualityID and ( (recipeID and recipeID ~= LAST_RECIPE_ID) or (craftingReagents and LAST_REAGENTS ~= craftingReagents) ) then
        LAST_RECIPE_ID = recipeID;
        LAST_REAGENTS = craftingReagents
    else
        return
    end

    local fromQuality, toQuality;

    if overrideQualityID <= 3 then
        --items with 3 quality: Gems/Enchants
        fromQuality = 1;
        toQuality = 3;
    elseif overrideQualityID <= 8 then
        --items with 5 quality (4, 5, 6, 7, 8)
        fromQuality = 4;
        toQuality = 8;
    end

    local data;
    local tooltip = ItemRefTooltip;

    local excludeTypes = {11, 20, 28, 29};
    local isItemName = true;
    tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");

    for qualityID = fromQuality, toQuality do
        data = C_TooltipInfo.GetRecipeResultItem(recipeID, craftingReagents, recraftItemGUID, recipeLevel, qualityID);
        for i, lineData in ipairs(data.lines) do
            if isItemName then
                isItemName = false;
                tooltip:ProcessLineData(lineData);
            else
                tooltip:ProcessLineData(lineData, excludeTypes);
            end
        end
    end

    tooltip:Show();
end

if GameTooltip and GameTooltip.SetRecipeResultItem then
    hooksecurefunc(GameTooltip, "SetRecipeResultItem", Tooltip_SetRecipeResultItem);
end
--]]