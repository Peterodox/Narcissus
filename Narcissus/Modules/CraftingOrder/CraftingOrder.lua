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