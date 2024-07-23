local _, addon = ...
local Gemma = addon.Gemma;

local GetItemStats = C_Item.GetItemStats;
local floor = math.floor;

local function Round(x)
    return floor(x + 0.5)
end

local FORMAT_ITEMLINK_ONE_GEM;

local function CreateItemLinkFormat()
    local specIndex = GetSpecialization() or 1;
    local specID = GetSpecializationInfo(specIndex) or 0;
    local level = GetMaxLevelForLatestExpansion() or 70;

    --FORMAT_ITEMLINK_ONE_GEM = "|Hitem:%d:::%d:::::"..level..":"..specID.."::0:3:10920:10970:%d|h";
    FORMAT_ITEMLINK_ONE_GEM = "|Hitem:%d::%d::::::"..level..":"..specID.."::0:2:%d:%d|h";

    print(FORMAT_ITEMLINK_ONE_GEM)
end

local function GenerateLink()
    if not FORMAT_ITEMLINK_ONE_GEM then
        CreateItemLinkFormat()
    end
end

local function GetItemLevelBonusID(itemLevel)
    if itemLevel >= 452 then
        return 9918 + itemLevel - 452;
    elseif itemLevel >= 432 then
        return 9874 + itemLevel - 432;
    elseif itemLevel >= 412 then
        return 9834 + itemLevel - 412;
    elseif itemLevel >= 409 then
        return 9464 + itemLevel - 409
    elseif itemLevel >= 402 then
        return 9455 + itemLevel - 402;
    elseif itemLevel >= 202 then
        return 3130 + itemLevel - 202;
    else    --(1, 200]
        return 1472 + itemLevel - 1;
    end
end


--[[
function SetTooltipLevel(itemLevel)
    if not FORMAT_ITEMLINK_ONE_GEM then
        CreateItemLinkFormat()
    end

    local equipmentItemID = 208555; --213661 210523 208487 208555
    local versaGems = {220371, 220372, 220374};
    local gemItemID = versaGems[1]; --doesn't affect stat
    local ilvlID = GetItemLevelBonusID(itemLevel);
    local statIDs = {11123, 11124, 11125};
    local statID = statIDs[3];
    local link = string.format(FORMAT_ITEMLINK_ONE_GEM, equipmentItemID, gemItemID, ilvlID, statID);
    GameTooltip:SetHyperlink(link);
end
--]]


local function Budget_10_90(x)
    return 0.4407 * x - 3.4029
end

local function Budget_90_310(x)
    return 1.1186 * x - 72.6705
end

local function Budget_310_341(x)
    return 0.1620 * x*x - 93.9075 * x + 13811.9119
end

local function Budget_341_556(x)
    return 5.2057 * x - 1134.36411
end


--Neck/Ring
local function Budget2_10_90(x)
    return 0.2668 * x - 3.1888
end

local function Budget2_90_172(x)
    return 0.4545 * x - 20.71668
end

local function Budget2_172_312(x)
    return 0.9935 * x - 115.6187
end

local function Budget2_312_344(x)
    return 3.2152 * x - 810.81105
end

local function Budget2_344_556(x)
    return 4.6835 * x - 1310.9625
end


local function CalculateStat(itemLevel, slotType, gemTier)
    local budget;

    if slotType == 3 then
        if itemLevel <= 90 then
            budget = Budget2_10_90(itemLevel);
        elseif itemLevel <= 172 then
            budget = Budget2_90_172(itemLevel);
        elseif itemLevel < 312 then
            budget = Budget2_172_312(itemLevel);
        elseif itemLevel < 344 then
            budget = Budget2_312_344(itemLevel);
        else
            budget = Budget2_344_556(itemLevel);
        end
    else
        if itemLevel <= 90 then
            budget = Budget_10_90(itemLevel);
        elseif itemLevel <= 310 then
            budget = Budget_90_310(itemLevel);
        elseif itemLevel < 341 then
            budget = Budget_310_341(itemLevel);
        else
            budget = Budget_341_556(itemLevel);
        end
    end


    budget = budget / 0.9556;

    local budgetMultiplier;

    if slotType == 1 then
        budgetMultiplier = 1;
    elseif slotType == 2 then
        budgetMultiplier = 0.75
    else
        budgetMultiplier = 1;   --budgetMultiplier
    end

    local gemRatio;

    if gemTier == 1 then
        gemRatio = 0.4779;
    elseif gemTier == 2 then
        gemRatio = 0.7168;
    else
        gemRatio = 0.9556;
    end

    return Round(budget * budgetMultiplier * gemRatio)
end


local OutputFrame;

local function PrintText(text)
    if not OutputFrame then
        OutputFrame = CreateFrame("Frame", nil, nil, "Narci_OutPutFrameTemplate");
        OutputFrame.EditBox = OutputFrame.ScrollFrame.EditBox;
    end

    OutputFrame.EditBox:SetText(text);
    OutputFrame:Show();
end

function PrintStats()
    if not FORMAT_ITEMLINK_ONE_GEM then
        CreateItemLinkFormat()
    end

    local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo;
    local format = string.format;
    local link, ilvlID, actualIlvl, statValue, antiValue;
    local gemItemID = 220371;
    local equipments = {213661, 208555, 210523};    --Chest, Trinket, Neck/Ring
    local statIDs = {11123, 11124, 11125};  --Versa

    local slotType = 1;
    local gemTier = 1;

    local equipmentItemID = equipments[slotType];
    local statID = statIDs[gemTier];
    local text = "";

    for itemLevel = 1, 556, 50 do
        ilvlID = GetItemLevelBonusID(itemLevel);
        link = format(FORMAT_ITEMLINK_ONE_GEM, equipmentItemID, gemItemID, ilvlID, statID);
        local stats = GetItemStats(link);
        actualIlvl = GetDetailedItemLevelInfo(link);
        statValue = stats.ITEM_MOD_VERSATILITY or "NONE";
        antiValue = CalculateStat(actualIlvl, slotType, gemTier);

        text = text .. antiValue.."  "..statValue.."\n";
    end

    PrintText(text);
end

--[[
    +++ 2x
    ++  1.5x
    +   1x

    Chest, Legs
        9618:  "100% Crit [0.4779]" +
        10809: "100% Crit [0.7168]" ++
        10815: "100% Crit [0.9556]" +++


    Neck item:210523::gem1::::::level:spec:::

        0.4778 +++

    Ring item:208487::220373:220373:220373::::70:268:::7:9601:11125:10821:11125:10821:11125:10821:1:28:2793
    (11125 Versa, 10821 Stamina)
        11123 "100% Vers [0.4779]"
        11124 "100% Vers [0.7168]"
        11125 "100% Vers [0.9556]"



    Stat Budget Ratio
    Chest 1
    Trinket 0.75
    Ring, Neck: 0.73465


    [10, 90]:    0.4407  -3.4029
    (90 - 310]:  1.1186  -72.6705
    (310, 341):  0.1620 * x^2 -93.9075 * x + 13811.9119
    [341, 556]:  5.2057  -1134.36411
--]]