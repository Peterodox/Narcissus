local _, addon = ...
local TransitionAPI = addon.TransitionAPI;
local RoundToDigit = addon.Math.RoundToDigit;
local PrivateAPI = addon.PrivateAPI;

local C_Item = C_Item;
local After = C_Timer.After;
local GetItemInfo = C_Item.GetItemInfo;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local UIFrameFadeIn = UIFrameFadeIn;
local UIFrameFadeOut = UIFrameFadeOut;
local FadeFrame = NarciFadeUI.Fade;
local PlaySound = PlaySound;
local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;

local find = string.find;
local match = string.match;
local strsub = string.sub;
local strsplit = strsplit;

local min = math.min;
local max = math.max;
local abs = math.abs;
local floor = math.floor;

local unpack = unpack;
local tinsert = table.insert;

local TEXT_LOCALE = GetLocale();

local Narci = Narci;
local NarciAPI = NarciAPI;


local SecureContainer = CreateFrame("Frame", "NarciSecureFrameContainer");
SecureContainer:Hide();


local function Mixin(object, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        for k, v in pairs(mixin) do
            object[k] = v;
        end
    end
    return object
end
NarciAPI.Mixin = Mixin;


--GetSlotVisualID
local IGNORED_MOG_SLOT = {
    [11] = true,
    [12] = true,
    [13] = true,
    [14] = true,
};

local function IsSlotValidForTransmog(slotID)
    return (slotID) and (not IGNORED_MOG_SLOT[slotID]) and slotID ~= 2
end
NarciAPI.IsSlotValidForTransmog = IsSlotValidForTransmog;


local function NarciAPI_GetSlotVisualID(slotID)
    if IGNORED_MOG_SLOT[slotID] then
        --slotID = 2 ~ Use neck to show right shoulder
        return 0, 0;
    end

    local isSecondaryAppearance;
    if slotID == 2 then
        isSecondaryAppearance = true;   --Enum.TransmogModification.Secondary
        slotID = 3;
    end

    local itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID);
    if not itemLocation or not C_Item.DoesItemExist(itemLocation) then
        return 0, 0;
    end
    local transmogLocation = CreateFromMixins(TransmogLocationMixin);
    local transmogType = 0;
    local modification = 0;
    if slotID == 3 then
        --Shoulders
        local itemTransmogInfo = C_Item.GetAppliedItemTransmogInfo(itemLocation);
        local hasSecondaryAppearance;
        if itemTransmogInfo then
            hasSecondaryAppearance = itemTransmogInfo.secondaryAppearanceID ~= 0;   --show direction mark
        end
        if isSecondaryAppearance then
            if not hasSecondaryAppearance then
                return 0, 0;
            end
            modification = 1;       --Enum.TransmogModification : 0 ~ Main, 1 ~ Secondary
        end
        transmogLocation:Set(slotID, transmogType, modification);
        local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo, isHideVisual, itemSubclass = C_Transmog.GetSlotVisualInfo(transmogLocation);
        if ( appliedSourceID == 0 ) then
            appliedSourceID = baseSourceID;
            appliedVisualID = baseVisualID;
        end
        return appliedSourceID, appliedVisualID, hasSecondaryAppearance;
    else
        transmogLocation:Set(slotID, transmogType, modification);

        local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo, isHideVisual, itemSubclass = C_Transmog.GetSlotVisualInfo(transmogLocation);
        if ( appliedSourceID == 0 ) then
            appliedSourceID = baseSourceID;
            appliedVisualID = baseVisualID;
        end

        return appliedSourceID, appliedVisualID;
    end
end
--/script for i =1, 17 do if C_Transmog.CanHaveSecondaryAppearanceForSlotID(i) then print(i) end end
--/script C_Transmog.GetSlotVisualInfo( CreateFromMixins(TransmogLocationMixin):Set(3, 0, 0) )
--/dump C_Item.GetAppliedItemTransmogInfo(ItemLocation:CreateFromEquipmentSlot(3))
--/dump C_Transmog.GetSlotVisualInfo((CreateFromMixins(TransmogLocationMixin)):Set(3, 0, 0));
NarciAPI.GetSlotVisualID = NarciAPI_GetSlotVisualID;

--------------------
----API Datebase----
--------------------

--[[
function GetArtifactVisualModID(colorID)
    colorID = colorID or 42;
    local PRINT = false;
    local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo, hideVisual = C_Transmog.GetSlotVisualInfo(16, 0);
    if not appliedSourceID or appliedSourceID == 0 then
        appliedSourceID = baseSourceID;
    end
    local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _ = C_TransmogCollection.GetAppearanceSourceInfo(appliedSourceID)
    local sourceInfo  = C_TransmogCollection.GetSourceInfo(appliedSourceID)
    if sourceInfo and PRINT then
        for k, v in pairs(sourceInfo) do
            print(k.." "..tostring(v))
        end
    else
        print(sourceInfo.itemModID);
    end
    itemID = sourceInfo.itemID or 127829;
    itemLink = "\124cffe5cc80\124Hitem:".. itemID .."::::::::120::16777472::2:::"..colorID..":::::::::::::\124h[".. (sourceInfo.name or "") .."]\124h\124r"
    DEFAULT_CHAT_FRAME:AddMessage(itemLink)
end
--]]


-----Color API------
local mapColors = {
    --[0] = { 35,  96, 147},	--default Blue  0.1372, 0.3765, 0.5765
    [0] = {78,  78,  78},   --Default Black
	[1] = {121,  31,  35},	--Orgrimmar
	[2] = { 49, 176, 107},	--Zuldazar
	[3] = {187, 161, 134},	--Vol'dun
	[4] = { 89, 140, 123},	--Tiragarde Sound
	[5] = {127, 164, 114},	--Stormsong
	[6] = {156, 165, 153},	--Drustvar
	[7] = { 42,  63,  79},	--Halls of Shadow


    --[UiMapID] = {r, g, b}
    --Shadowlands
    [1970] = {137, 218, 247},   --Zereth Mortis
    [1670] = {76, 86, 109},     --Oribos

    [1533] = {197, 185, 172},	--Bastion
    [1707] = {193, 199, 210},   --Elysian Hold
    [1708] = {168, 188, 232},   --Sanctum of Binding

    [1701] = {57, 66, 154},     --Heart of the Forest
    [1565] = {57, 66, 154},     --Ardenweald
    
    [1536] = {25, 97, 85},      --Maldraxxus
    [1698] = {25, 97, 85},      --Seat of the Primus

    [1525] = {48, 96, 153},      --Revendreth

    [1911] = {53, 80, 115},     --Torghast Entrance
    [1912] = {53, 80, 115},     --Runecrafter

    --Major City--
    [84]  = {129, 144, 155},	--Stormwind City
    
	[85]  = {121,  52,  55},	--Orgrimmar
    [86]  = {121,  31,  35},	--Orgrimmar - Cleft of Shadow
    [463] = {163,  99,  89},	--Echo Isles
    
    [87]  = {102,  64,  58},	--Ironforge
    [27]  = {151, 198, 213},	--Dun Morogh
    [469] = {151, 198, 213},	--New Tinkertown
    
    [88]  = {115, 140, 113},	--Thunder Bluff
    
    [89]  = {121,  31,  35},	--Darnassus	R.I.P.
    
    [90]  = { 42,  63,  79},	--Undercity

    [110] = {172,  58,  54},    --Silvermoon City

    [202]  = {78,  78,  78},    --Gilneas City
    [217]  = {78,  78,  78},    --Ruins of Gilneas
    [627] = {102,  58,  64},	--Dalaran  	Broken Isles
    [111] = {88,  108,  91},	--Shattrath City

    -- TBC --
    [107] = {181,  151, 93},	--Nagrand Outland
    [109] = {96,   48, 108},	--Netherstorm
    [102] = {61,   77, 162},	--Zangarmash
    [105] = {123, 104,  80},	--Blade's Edge Mountains

    -- MOP --
    [378] = {120, 107,  81},	--The Wandering Isle
    [371] = { 95, 132,  78},    --The Jade Forrest
    [379] = { 90, 119, 156},    --Kun-Lai Summit

    -- LEG --
    [641] = { 70, 128, 116},    --Val'sharah

    -- BFA --
    [81]  = { 98,  84,  77},    --Silithus
    [1473]= {168, 136,  90},    --Chamber of Heart
	[1163]= { 89, 140, 123},	--Dazar'alor - The Great Seal
	[1164]= { 89, 140, 123},	--Dazar'alor - Hall of Chroniclers
	[1165]= { 89, 140, 123},	--Dazar'alor
	[862] = { 89, 140, 123},	--Zuldazar
	[864] = {187, 161, 134},	--Vol'dun
	[863] = {113, 173, 183},	--Nazmir
	[895] = { 89, 140, 123},	--Tiragarde Sound
	[1161]= { 89, 140, 123},	--Boralus
	[942] = {127, 164, 114},	--Stormsong
    [896] = {156, 165, 153},	--Drustvar
    
    [1462] = {16, 156, 192},    --Mechagon
    [1355] = {41,  74, 127},    --Nazjatar

    [249]  = {180,149, 121},    --Uldum Normal
    [1527] = {180,149, 121},    --Uldum Assault
    [390]  = {150, 117, 94},    --Eternal Blossoms Normal
    [1530] = {150, 117, 94},    --Eternal Blossoms Assault  --{105, 71, 156}
    ["NZ"] = {105, 71, 156},    --During Assault: N'Zoth Purple Skybox

    [1580] = {105, 71, 156},    --Ny'alotha - Vision of Destiny
    [1581] = {105, 71, 156},    --Ny'alotha - Annex of Prophecy
    [1582] = {105, 71, 156},    --Ny'alotha - Ny'alotha
    [1590] = {105, 71, 156},    --Ny'alotha - The Hive
    [1591] = {105, 71, 156},    --Ny'alotha - Terrace of Desolation
    [1592] = {105, 71, 156},    --Ny'alotha - The Ritual Chamber
    [1593] = {105, 71, 156},    --Ny'alotha - Twilight Landing
    [1594] = {105, 71, 156},    --Ny'alotha - Maw of Gor'ma
    [1595] = {105, 71, 156},    --Ny'alotha - Warren of Decay
    [1596] = {105, 71, 156},    --Ny'alotha - Chamber of Rebirth
    [1597] = {105, 71, 156},    --Ny'alotha - Locus of Infinite Truths

    --Allied Race Starting Zone--
    [124]  = {87,  56, 132},    --DK
    [1186] = {117,  26, 22},    --Dark Iron
    [971]  = {65, 57, 124},     --Void Elf

    --Class Hall
	[625] = { 42,  63,  79},	--Dalaran, Broken Isles  Halls of Shadow
    [626] = { 42,  63,  79},	--Hall of Shadow
    [715] = {149, 180, 146},    --Emerald Dreamway
    [747] = { 70, 128, 116},    --The Dreamgrove

    --Frequently Visited
    [198]  = {78,  78,  78},    --Hyjal
};

NarciThemeUtil = {};
NarciThemeUtil.colorIndex = 0;

function NarciThemeUtil:GetColorTable()
    local R, G, B = unpack(mapColors[self.colorIndex]);
    return {R/255, G/255, B/255}
end

function NarciThemeUtil:GetColor()
    local R, G, B = unpack(mapColors[self.colorIndex]);
    return R/255, G/255, B/255
end

function NarciThemeUtil:GetColorIndex()
    return self.colorIndex
end

function NarciThemeUtil:SetColorIndex(index)
    if index and mapColors[index] then
        self.colorIndex = index
    else
        self.colorIndex = 0;
    end

    return self:GetColorTable()
end

----------------------------------------------------------------------
local function NarciAPI_ConvertHexColorToRGB(hexColor, includeHex)
    local r = tonumber(strsub(hexColor, 1, 2), 16) / 255;
    local g = tonumber(strsub(hexColor, 3, 4), 16) / 255;
    local b = tonumber(strsub(hexColor, 5, 6), 16) / 255;
    if includeHex then
        return {r, g, b, hexColor};
    else
        return {r, g, b};
    end
end

local function RGB2HSV(r, g, b)
	local Cmax = max(r, g, b);
	local Cmin = min(r, g, b);
	local dif = Cmax - Cmin;
	local Hue = 0;
	local Brightness = floor(100*(Cmax / 255) + 0.5)/100;
	local Stauration = 0;
	if Cmax ~= 0 then Stauration = floor(100*(dif / Cmax)+0.5)/100; end;

	if dif ~= 0 then
		if r == Cmax and g >= b then
			Hue = (g - b) / dif + 0;
		elseif r == Cmax and g < b then
			Hue = (g - b) / dif + 6;
		elseif g == Cmax then
			Hue = (b - r) / dif + 2;
		elseif b == Cmax then
			Hue = (r - g) / dif + 4;
		end
	end

	return floor(60*Hue + 0.5), Stauration, Brightness
end

local function RGBRatio2HSV(r, g, b)
	return RGB2HSV(255 * r, 255 * g, 255 * b)
end

local function HSV2RGB(h, s, v)
	local Cmax = 255 * v;
	local Cmin = Cmax * (1 - s);
	local i = floor(h / 60);
	local dif = h % 60;
	local Cmid = (Cmax - Cmin) * dif / 60;
	local r, g, b;

	if i == 0 or i == 6 then
		r, g, b = Cmax, Cmin + Cmid, Cmin;
	elseif i == 1 then
		r, g, b = Cmax - Cmid, Cmax, Cmin;
	elseif i == 2 then
		r, g, b = Cmin, Cmax, Cmin + Cmid;
	elseif i == 3 then
		r, g, b = Cmin, Cmax - Cmid, Cmax;
	elseif i == 4 then
		r, g, b = Cmin + Cmid, Cmin, Cmax;
	else
		r, g, b = Cmax, Cmin, Cmax - Cmid;
	end

	r, g, b = floor(r + 0.5)/255, floor(g + 0.5)/255, floor(b + 0.5)/255;
	return r, g, b
end

NarciAPI.ConvertHexColorToRGB = NarciAPI_ConvertHexColorToRGB;
NarciAPI.RGB2HSV = RGB2HSV;
NarciAPI.RGBRatio2HSV = RGBRatio2HSV;
NarciAPI.HSV2RGB = HSV2RGB;

Narci_FontColor = {
    ["Brown"] = {0.85098, 0.80392, 0.70588, "|cffd9cdb4"},
    ["DarkGrey"] = {0.42, 0.42, 0.42, "|cff6b6b6b"},
    ["LightGrey"] = {0.72, 0.72, 0.72, "|cffb8b8b8"},
    ["White"] = {0.88, 0.88, 0.88, "|cffe0e0e0"},
    ["Good"] = {0.4862, 0.7725, 0.4627, "|cff7cc576"},
    ["Bad"] = {1, 0.3137, 0.3137, 0.3137, "|cffff5050"},
    ["Corrupt"] = {0.584, 0.428, 0.82, "|cff946dd1"},
};

local CustomQualityColors= {
	[0] = "9d9d9d",	--Poor
	[1] = "ffffff",	--Common
	[2] = "1eff00",	--Uncommon
	[3] = "699eff",	--Rare 0070dd 699eff
	[4] = "b953ff",	--Epic a335ee
	[5] = "ff8000",	--Legend
	[6] = "e6cc80",	--Artifact
	[7] = "00ccff",	--Heirloom
	[8] = "00ccff",
	[9] = "ffffff",
};

for index, hex in pairs(CustomQualityColors) do
	CustomQualityColors[index] = NarciAPI_ConvertHexColorToRGB(hex, true);
end

local function GetCustomQualityColor(itemQuality)
    if (not itemQuality) or (not CustomQualityColors[itemQuality]) then
        itemQuality = 1;
    end
    return CustomQualityColors[itemQuality][1], CustomQualityColors[itemQuality][2], CustomQualityColors[itemQuality][3];
end

NarciAPI.GetItemQualityColor = GetCustomQualityColor;


local function GetCustomQualityColorByItemID(itemID)
    local itemQuality = C_Item.GetItemQualityByID(itemID);
    return GetCustomQualityColor(itemQuality);
end

NarciAPI.GetItemQualityColorByItemID = GetCustomQualityColorByItemID;

local function GetCustomQualityHexColor(itemQuality)
    if (not itemQuality) or (not CustomQualityColors[itemQuality]) then
        itemQuality = 1;
    end
    return CustomQualityColors[itemQuality][4]
end

NarciAPI.GetItemQualityHexColor = GetCustomQualityHexColor;


NarciAPI.GetItemQualityColorTable = function()
    local newTable = {};
    for k, v in pairs(CustomQualityColors) do
        newTable[k] = v;
    end
    return newTable;
end



--------------------
------Item API------
--------------------

local function GetItemEnchantID(itemLink)
    if itemLink then
        local _, _, _, linkType, linkID, enchantID = strsplit(":|H", itemLink);
        return tonumber(enchantID) or 0;
    else
        return 0
    end
end

NarciAPI.GetItemEnchantID = GetItemEnchantID;



local PrimaryStatsList = {
	[LE_UNIT_STAT_STRENGTH] = NARCI_STAT_STRENGTH,
	[LE_UNIT_STAT_AGILITY] = NARCI_STAT_AGILITY,
	[LE_UNIT_STAT_INTELLECT] = NARCI_STAT_INTELLECT,
};


local function NarciAPI_GetPrimaryStats()
    --Return name and value
	local currentSpec = GetSpecialization() or 1;
    local _, _, _, _, _, primaryStat = GetSpecializationInfo(currentSpec);
    primaryStat = primaryStat or 1;
    local value = UnitStat("player", primaryStat);
	local name = PrimaryStatsList[primaryStat];
	return name, value;
end

NarciAPI.GetPrimaryStats = NarciAPI_GetPrimaryStats;

local GemInfo = Narci.GemData;
local EnchantInfo = Narci.EnchantData;
local DoesItemExist = C_Item.DoesItemExist;
local GetCurrentItemLevel = C_Item.GetCurrentItemLevel;
local GetItemLink = C_Item.GetItemLink
local GetItemStats = C_Item.GetItemStats;
local GetItemGem = C_Item.GetItemGem;

function NarciAPI_GetItemStats(itemLocation)
    local statsTable = {};
    statsTable.gems = 0;
    if not itemLocation or not DoesItemExist(itemLocation) then
        statsTable.prim = 0;
        statsTable.stamina = 0;
        statsTable.crit = 0;
        statsTable.haste = 0;
        statsTable.mastery = 0;
        statsTable.versatility = 0;
        statsTable.corruption = 0;
        statsTable.GemIcon = "";
        statsTable.GemPos = "";
        statsTable.EnchantPos = "";
        statsTable.EnchantSpellID = nil;
        statsTable.ilvl = 0;
        return statsTable;
    end

    local ItemLevel = GetCurrentItemLevel(itemLocation)
    local itemLink = GetItemLink(itemLocation)
    local stats = GetItemStats(itemLink) or {};
    local prim = stats["ITEM_MOD_AGILITY_SHORT"] or stats["ITEM_MOD_STRENGTH_SHORT"] or stats["ITEM_MOD_INTELLECT_SHORT"] or 0;
    local stamina = stats["ITEM_MOD_STAMINA_SHORT"] or 0;
    local crit = stats["ITEM_MOD_CRIT_RATING_SHORT"] or 0;
    local haste = stats["ITEM_MOD_HASTE_RATING_SHORT"] or 0;
    local mastery = stats["ITEM_MOD_MASTERY_RATING_SHORT"] or 0;
    local versatility = stats["ITEM_MOD_VERSATILITY"] or 0;
    local corruption = stats["ITEM_MOD_CORRUPTION"] or 0;

    statsTable.prim = prim;
    statsTable.stamina = stamina;
    statsTable.crit = crit;
    statsTable.haste = haste;
    statsTable.mastery = mastery;
    statsTable.versatility = versatility;
    statsTable.corruption = corruption;
    statsTable.ilvl = ItemLevel;

    --Calculate bonus from Gems and Enchants--
    local gemIndex = 1;         --BFA 1 gem for each item.
    local gemName, gemLink = GetItemGem(itemLink, gemIndex);
    if gemLink then
        local gemID = GetItemInfoInstant(gemLink);
        local _, _, _, _, GemIcon, _, itemSubClassID = GetItemInfoInstant(gemLink);
        statsTable.GemIcon = GemIcon
        statsTable.gems = 1;

        if GemInfo[gemID] then
            local info = GemInfo[gemID]
            statsTable.GemPos = GemInfo[1];
            if info[1] == "crit" then
                statsTable.crit = statsTable.crit + info[2];
            elseif info[1] == "haste" then
                statsTable.haste = statsTable.haste + info[2];
            elseif info[1] == "mastery" then
                statsTable.mastery = statsTable.mastery + info[2];
            elseif info[1] == "versatility" then
                statsTable.versatility = statsTable.versatility + info[2];
            elseif info[1] == "AGI" or info[1] == "STR" or info[1] == "INT" then
                statsTable.prim = statsTable.prim + info[2];
                statsTable.GemPos = "prim";
            end
        end
    end

    local enchantID = GetItemEnchantID(itemLink);
    if enchantID ~= 0 and EnchantInfo[enchantID] then
        local data = EnchantInfo[enchantID]
        statsTable.EnchantPos = data[1];
        if data[1] == "crit" then
            statsTable.crit = statsTable.crit + data[2];
        elseif data[1] == "haste" then
            statsTable.haste = statsTable.haste + data[2];
        elseif data[1] == "mastery" then
            statsTable.mastery = statsTable.mastery + data[2];
        elseif data[1] == "versatility" then
            statsTable.versatility = statsTable.versatility + data[2];
        elseif data[1] == "AGI" or data[1] == "STR" or data[1] == "INT" then
            statsTable.prim = statsTable.prim + data[2];
            statsTable.EnchantPos = "prim";
        elseif data[1] == "stamina" then
            statsTable.stamina = statsTable.stamina + data[2];
            statsTable.EnchantPos = "stamina";
        end

        statsTable.EnchantSpellID = data[3];
    end

    return statsTable;
end

function NarciAPI_GetItemStatsFromSlot(slotID)
    local itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID);
    local itemLink = C_Item.GetItemLink(itemLocation)
    return GetItemStats(itemLink);
end


do
    local GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots;
    local GetContainerItemID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID;
    local GetContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink;
    local GetInventoryItemID = GetInventoryItemID;
    local GetItemCount = C_Item.GetItemCount;

    local function GetItemBagPosition(itemID, findHighestItemLevel)
        if findHighestItemLevel then
            local topLevel = -1;
            local level;
            local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;
            local id1, id2;

            for bagID = 0, (NUM_BAG_SLOTS or 4) do
                for slotID = 1, GetContainerNumSlots(bagID) do
                    if(GetContainerItemID(bagID, slotID) == itemID) then
                        level = GetDetailedItemLevelInfo( GetContainerItemLink(bagID, slotID) ) or 0;
                        if level > topLevel then
                            id1, id2 = bagID, slotID;
                        end
                    end
                end
            end

            return id1, id2;
        else
            for bagID = 0, (NUM_BAG_SLOTS or 4) do
                for slotID = 1, GetContainerNumSlots(bagID) do
                    if(GetContainerItemID(bagID, slotID) == itemID) then
                        return bagID, slotID
                    end
                end
            end
        end
    end
    NarciAPI.GetItemBagPosition = GetItemBagPosition;

    local function GetItemPositionByItemID(itemID)
        local count = GetItemCount(itemID);

        if count and count > 0 then
            local id;
            for slotID = 1, 19 do
                id = GetInventoryItemID("player", slotID);
                if id and id == itemID then
                    return "inventory", slotID
                end
            end

            local bagID, slotID = GetItemBagPosition(itemID);
            if bagID then
                return "container", bagID, slotID
            end
        end
    end
    NarciAPI.GetItemPositionByItemID = GetItemPositionByItemID;

    function PrivateAPI.DoesPlayerHaveAnyItems(itemList)
        if itemList then
            local count;
            for _, itemID in ipairs(itemList) do
                count = GetItemCount(itemID);
                if count > 0 then
                    return true
                end
            end
        end
    end
end


--------------------
---Formating API----
--------------------

local function NarciAPI_FormatLargeNumbers(value)
    value = tonumber(value) or 0;
    local formatedNumber = ""
    if value >= 1000 and value < 1000000 then
        formatedNumber = strsub(value, 1, -4) .. "," .. strsub(value, -3);
    elseif value >= 1000000 and value < 1000000000 then
        formatedNumber = strsub(value, 1, -7) .. "," .. strsub(value, -6, -4) .. "," .. strsub(value, -3);
    else
        formatedNumber  = tostring(value)
    end
    return formatedNumber
end

NarciAPI.FormatLargeNumbers = NarciAPI_FormatLargeNumbers;


local RemoveTextBeforeColon;

if TEXT_LOCALE == "zhCN" or TEXT_LOCALE == "zhTW" then
    function RemoveTextBeforeColon(text)
        if find(text, ": ") then
            return match(text, ": (.+)");
        elseif find(text, "：") then
            return match(text, "：(.+)");
        else
            return text
        end
    end
else
    function RemoveTextBeforeColon(text)
        if find(text, ":") then
            text = match(text, ":%s*(.+)");
        end

        if find(text, "- ") then
            text = match(text, "- (.+)");
        end

        return text
        --return string.gsub(text, "^.+[:-]%s*", "");   --May not working on Russian?
    end
end

NarciAPI.RemoveTextBeforeColon = RemoveTextBeforeColon;


--------------------
---Fade Frame API---
--------------------

local function SetFade_finishedFunc(frame)
	if frame.fadeInfo.mode == "OUT" then
		frame:Hide();
	elseif	frame.fadeInfo.mode == "IN" then
		frame:Show();
	end
end

function NarciAPI_FadeFrame(frame, time, mode)
	if mode == "IN" then
		UIFrameFadeIn(frame, time, frame:GetAlpha(), 1);
	elseif mode == "OUT" then
		if not frame:IsShown() then
			return;
		end
		UIFrameFadeOut(frame, time, frame:GetAlpha(), 0);
	elseif mode == "Forced_IN" then
		UIFrameFadeIn(frame, time, 0, 1);
	elseif mode == "Forced_OUT" then
	    UIFrameFadeOut(frame, time, 1, 0);
	end

	if not frame.fadeInfo then
		return;
	end

	frame.fadeInfo.finishedArg1 = frame;
	frame.fadeInfo.finishedFunc = SetFade_finishedFunc
end
------------------------------------------------------------------

--------------------
---UI Element API---
--------------------
NarciUIMixin = {};

function NarciUIMixin:Highlight(state)
    if state then
        self.Border.Highlight:SetAlpha(1);
        self.Border.Normal:SetAlpha(0);
    else
        self.Border.Highlight:SetAlpha(0);
        self.Border.Normal:SetAlpha(1);
    end
end

function NarciUIMixin:SetColor(r, g, b)
    if self.Color then
        self.Color:SetColorTexture(r/255, g/255, b/255);
    end
end

local SCREEN_WIDTH, SCREEN_HEIGHT = GetPhysicalScreenSize();    --Assume players don't change screen resolution (triggers DISPLAY_SIZE_CHANGED)

local function GetPixelForWidget(widget, pixelSize)
    local scale = widget:GetEffectiveScale();
    if pixelSize then
        return pixelSize * (768/SCREEN_HEIGHT)/scale
    else
        return (768/SCREEN_HEIGHT)/scale
    end
end

NarciAPI.GetPixelForWidget = GetPixelForWidget;


local function GetPixelByScale(scale, pixelSize)
    if pixelSize then
        return pixelSize * (768/SCREEN_HEIGHT)/scale
    else
        return (768/SCREEN_HEIGHT)/scale
    end
end

NarciAPI.GetPixelByScale = GetPixelByScale;


local function GetTexturePixelSize(texture)
    local scale = texture:GetEffectiveScale();
    local w, h = texture:GetSize();
    local pixel = (768/SCREEN_HEIGHT)/scale;

    return w/pixel, h/pixel
end

NarciAPI.GetTexturePixelSize = GetTexturePixelSize;

local function GetBestSizeForPixel(size, pixel)
    return floor(size/pixel + 0.5) * pixel
end

NarciAPI.GetBestSizeForPixel = GetBestSizeForPixel;

local function GetObjectScreenSize(objectSize, scale)
    local _, screenHeight = GetPhysicalScreenSize();
    if not scale then
        scale = UIParent:GetEffectiveScale();
    end
    return objectSize / ((768/SCREEN_HEIGHT)/scale)
end

NarciAPI.GetObjectScreenSize = GetObjectScreenSize;

function NarciAPI_OptimizeBorderThickness(self)
    if not self.HasOptimized then
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()

        local uiScale = self:GetEffectiveScale();
        local rate = (768/SCREEN_HEIGHT)/uiScale;
        local borderWeight = 2.0;
        local weight = borderWeight * rate;
        local weight2 = weight * math.sqrt(2);
        self.Border:SetPoint("TOPLEFT", self, "TOPLEFT", weight, -weight)
        self.Border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -weight, weight)

        if self.ThumbBorder then
            self.ThumbBorder:SetPoint("TOPLEFT", self.VirtualThumb, -weight2, weight2)
            self.ThumbBorder:SetPoint("BOTTOMRIGHT", self.VirtualThumb,weight2, -weight2)
        end

        if self.Marks then
            for i=1, #self.Marks do
                self.Marks[i]:SetWidth(weight);
            end
        end

        self.HasOptimized = true;
    end
end

function NarciAPI_SliderWithSteps_OnLoad(self)
    self.oldValue = -1208;
    self.Marks = {};
    local width = self:GetWidth();
    local step = self:GetValueStep();
    local sliderMin, sliderMax = self:GetMinMaxValues();
    local range = sliderMax - sliderMin;
    local num_Gap = floor((range / step) + 0.5);
    if num_Gap == 0 then return; end;
    local tex;
    local markOffset = 5;
    width = width - 2*markOffset;
    local pixel = GetPixelForWidget(self);
    for i = 1, (num_Gap + 1) do
        tex = self:CreateTexture(nil, "BACKGROUND", nil, 1);
        tex:SetSize(2*pixel, 20*pixel);
        tex:SetColorTexture(0.25, 0.25, 0.25);
        tex:SetPoint("CENTER", self, "LEFT", markOffset + (i-1)*width/num_Gap, 0);
        tinsert(self.Marks, tex);
    end

    --self.VirtualThumb:SetTexture("Interface/AddOns/Narcissus/Art/BasicShapes/Diamond", nil, nil, "TRILINEAR");
end



-----Smooth Scroll-----

local function SmoothScrollContainer_OnUpdate(self, elapsed)
    local value = self.scrollBar:GetValue();
    local step = max(abs(value - self.endValue)*(self.speedRatio)*(elapsed*60) , self.minOffset);		--if the step (Δy) is too small, the fontstring will jitter.    --Consider elapsed -- scroll duration should be constant regardless of FPS
    local remainedStep;
    if ( self.delta == 1 ) then
        --Up
        remainedStep = min(self.endValue - value, 0);
        if - remainedStep <= ( self.minOffset) then
            self:Hide();
            self.scrollBar:SetValue(min(self.maxVal, self.endValue));
            if self.onScrollFinishedFunc then
                self.onScrollFinishedFunc();
            end
        else
            self.scrollBar:SetValue(max(0, value - step));
        end
	else
        remainedStep = max(self.endValue - value, 0);
        if remainedStep <= ( self.minOffset) then
            self:Hide();
            self.scrollBar:SetValue(min(self.maxVal, self.endValue));
            if self.onScrollFinishedFunc then
                self.onScrollFinishedFunc();
            end
        else
            self.scrollBar:SetValue(min(self.maxVal, value + step));
        end
    end
end

local function NarciAPI_SmoothScroll_OnMouseWheel(self, delta, stepSize)
    if ( not self.scrollBar:IsVisible() ) then
        if self.parentScrollFunc then
            self.parentScrollFunc(delta);
        else
            return;
        end
    end
    
    local ScrollContainer = self.SmoothScrollContainer;
	stepSize = stepSize or self.stepSize or self.buttonHeight;

    ScrollContainer.stepSize = stepSize;
	ScrollContainer.maxVal = self.range;

	--self.scrollBar:SetValueStep(0.01);
	ScrollContainer.delta = delta;

	local current = self.scrollBar:GetValue();
    if not((current <= 0.1 and delta > 0) or (current >= self.range - 0.1 and delta < 0 )) then
        ScrollContainer:Show()
    else
        return;
	end
	
    local deltaRatio = ScrollContainer.deltaRatio or 1;
    if IsShiftKeyDown() then
        deltaRatio = 2 * deltaRatio;
    end

    local endValue = floor( (100 * min(max(0, ScrollContainer.endValue - delta*deltaRatio*self.buttonHeight), self.range) + 0.5)/100 );
    ScrollContainer.endValue = endValue;
    
    if self.positionFunc then
        local isTop = endValue <= 0.1;
        local isBottom = endValue >= self.range - 1;
        self.positionFunc(endValue, delta, self.scrollBar, isTop, isBottom);
    end
end

local function SetScrollRange(scrollFrame, range)
    range = max(range, 0);
    scrollFrame.scrollBar:SetMinMaxValues(0, range);
    scrollFrame.scrollBar:SetShown(range ~= 0);
    scrollFrame.range = range;
end


local SmoothScrollFrameMixin = {};

function SmoothScrollFrameMixin:GetEndPosition()
    return self.SmoothScrollContainer.endValue;
end

function SmoothScrollFrameMixin:SnapToEndPosition()
    local offset = self:GetEndPosition();
    self.SmoothScrollContainer:Hide();
    self.scrollBar:SetValue(offset);
end

function SmoothScrollFrameMixin:SnapToOffset(offset)
    if self.range and offset > self.range then
        offset = self.range;
    elseif offset < 0 then
        offset = 0;
    end
    self.SmoothScrollContainer:Hide();
    self.scrollBar:SetValue(offset);
    self.SmoothScrollContainer.endValue = offset;
end


function NarciAPI_SmoothScroll_Initialization(scrollFrame, updatedList, updateFunc, deltaRatio, speedRatio, minOffset, positionFunc, onScrollFinishedFunc)
    if updateFunc then
        scrollFrame.update = updateFunc;
    end
    if positionFunc then
        scrollFrame.positionFunc = positionFunc;
    end
    if updatedList then
        scrollFrame.updatedList = updatedList;
    end
    
    local parentName = scrollFrame:GetName();
    local frameName = parentName and (parentName .. "SmoothScrollContainer") or nil;
    
    local SmoothScrollContainer = CreateFrame("Frame", frameName, scrollFrame);
    SmoothScrollContainer:Hide();
    
    --local scale = match(GetCVar( "gxWindowedResolution" ), "%d+x(%d+)" );
    local uiScale = scrollFrame:GetEffectiveScale();
    local pixel = (768/SCREEN_HEIGHT)/uiScale;
    
    local scrollBar = scrollFrame.scrollBar;
    scrollBar:SetValue(0);
    scrollBar:SetValueStep(0.001);
    
    SmoothScrollContainer.stepSize = 0;
    SmoothScrollContainer.delta = 0;
    SmoothScrollContainer.animationDuration = 0;
    SmoothScrollContainer.endValue = 0;
	SmoothScrollContainer.maxVal = 0;
    SmoothScrollContainer.deltaRatio = deltaRatio or 1;
    SmoothScrollContainer.speedRatio = speedRatio or 0.5;
    SmoothScrollContainer.minOffset = minOffset or pixel;
    SmoothScrollContainer.scrollBar = scrollFrame.scrollBar;
    SmoothScrollContainer:SetScript("OnUpdate", SmoothScrollContainer_OnUpdate);
    SmoothScrollContainer:SetScript("OnShow", function(self)
        self.endValue = self:GetParent().scrollBar:GetValue();
    end);
    SmoothScrollContainer:SetScript("OnHide", function(self)
        self:Hide();
    end);
    scrollFrame.SmoothScrollContainer = SmoothScrollContainer;

    scrollFrame:SetScript("OnMouseWheel", NarciAPI_SmoothScroll_OnMouseWheel);  --a position-related function

    if onScrollFinishedFunc then
        SmoothScrollContainer.onScrollFinishedFunc = onScrollFinishedFunc;
    end

    scrollFrame.SetScrollRange = SetScrollRange;

    for k, v in pairs(SmoothScrollFrameMixin) do
        scrollFrame[k] = v;
    end
end

function NarciAPI_ApplySmoothScrollToScrollFrame(scrollFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range, parentScrollFunc, onScrollFinishedFunc)
    scrollFrame.buttonHeight = buttonHeight or floor(scrollFrame:GetHeight() + 0.5);
    scrollFrame.range = range or 0;
    scrollFrame.scrollBar:SetMinMaxValues(0, range or 0)
    scrollFrame.scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value);
        if self.onValueChangedFunc then
            self.onValueChangedFunc(value);
        end
    end)
    NarciAPI_SmoothScroll_Initialization(scrollFrame, nil, nil, deltaRatio, speedRatio, nil, positionFunc, onScrollFinishedFunc);
    scrollFrame.parentScrollFunc = parentScrollFunc;
end

function NarciAPI_ApplySmoothScrollToBlizzardUI(scrollFrame, deltaRatio, speedRatio, positionFunc)
    NarciAPI_SmoothScroll_Initialization(scrollFrame, nil, nil, deltaRatio, speedRatio, nil, positionFunc);
end



-----Create A List of Button----
--[[
function NarciAPI_BuildButtonList(self, buttonTemplate, buttonNameTable, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
	local button, buttonHeight, buttons, numButtons;

	local parentName = self:GetName();
	local buttonName = parentName and (parentName .. "Button") or nil;

	initialPoint = initialPoint or "TOPLEFT";
    initialRelative = initialRelative or "TOPLEFT";
    initialOffsetX = initialOffsetX or 0;
    initialOffsetY = initialOffsetY or 0;
	point = point or "TOPLEFT";
	relativePoint = relativePoint or "BOTTOMLEFT";
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;

	if ( self.buttons ) then
		buttons = self.buttons;
		buttonHeight = buttons[1]:GetHeight();
	else
		button = CreateFrame("BUTTON", buttonName and (buttonName .. 1) or nil, self, buttonTemplate);
		buttonHeight = button:GetHeight();
        button:SetPoint(initialPoint, self, initialRelative, initialOffsetX, initialOffsetY);
        button:SetID(0);
        buttons = {}
        button.Name:SetText(buttonNameTable[1])
		tinsert(buttons, button);
	end

	local numButtons = #buttonNameTable;

	for i = 2, numButtons do
		button = CreateFrame("BUTTON", buttonName and (buttonName .. i) or nil, self, buttonTemplate);
        button:SetPoint(point, buttons[i-1], relativePoint, offsetX, offsetY);
        button:SetID(i-1);
        button.Name:SetText(buttonNameTable[i])
		tinsert(buttons, button);
	end

	self.buttons = buttons;
end
--]]

-----Language Adaptor-----
local function LanguageDetector(str)
	local len = string.len(str)
	local i = 1
	while i <= len do
		local c = string.byte(str, i)
		local shift = 1
		if (c > 0 and c <= 127)then
			shift = 1
		elseif c == 195 then
			shift = 2	--Latin/Greek
		elseif (c >= 208 and c <=211) then
			shift = 2
			return "RU" --RU included
		elseif (c >= 224 and c <= 227) then
			shift = 3	--JP
			return "JP"
		elseif (c >= 228 and c <= 233) then
			shift = 3	--CN
			return "CN"
		elseif (c >= 234 and c <= 237) then
			shift = 3	--KR
			return "KR"
		elseif (c >= 240 and c <= 244) then
			shift = 4	--Unknown invalid
		end
		i = i + shift
	end
	return "RM"
end

local function GetFirstLetterLanguage(str)
    local c = string.byte(str, 1);
    if (c > 0 and c <= 127)then
        return "RM"
    elseif c == 195 then
        return "RM"	--Latin/Greek
    elseif (c >= 208 and c <=211) then
        return "RU"
    elseif (c >= 224 and c <= 227) then
        return "JP"
    elseif (c >= 228 and c <= 233) then
        return "CN"
    elseif (c >= 234 and c <= 237) then
        return "KR"
    elseif (c >= 240 and c <= 244) then
        return "CN"	--Unknown invalid
    end
end

NarciAPI.LanguageDetector = LanguageDetector;
--[[
function LDTest(string)
	local str = string
	local lenInByte = #str
	
	for i=1,lenInByte do
		local char = strsub(str, i,i)
		local curByte = string.byte(str, i)
		print(char.." "..curByte)
	end
	return "roman"
end

local Eng = "abcdefghijklmnopqrstuvwxyz" --abcdefghijklmnopqrstuvwxyz Z~90 z~122 1-1
local DE =  "äöüß" --195 1-2
local CN =  "乀氺" --228 229 230 233 HEX E4-E9 Hexadecimal UTF-8 CJK
local KR = "제" --237 236 235 234 1-3  EB-ED
local RU = "ѱӧ" --D0400-D04C0  208 209 210 211 1-2
local FR = "ÀÃÇÊÉÕàãçêõáéíóúà" --1-2 195 C3 -PR
local JP = "ひらがな" --1-3 227 E3 Kana
--LDTest("繁體繁体")
--local language = LanguageDetector("繁體中文")
--print("Str is: "..language)
--]]

local PlayerNameFont = {
	["CN"] = "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf",
	["RM"] = "Interface\\AddOns\\Narcissus\\Font\\SemplicitaPro-Semibold.otf",
	["RU"] = "Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf",
	["KR"] = "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf",
	["JP"] = "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf",
}

local EditBoxFont = {
	["CN"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["RM"] = {"Interface\\AddOns\\Narcissus\\Font\\SourceSansPro-Semibold.ttf", 9},
	["RU"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf", 8},
	["KR"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["JP"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
}

local NormalFont12 = {
	["CN"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 11},
	["RM"] = {"Interface\\AddOns\\Narcissus\\Font\\SourceSansPro-Semibold.ttf", 12},
	["RU"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf", 11},
	["KR"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 11},
	["JP"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 11},
}

local ActorNameFont = {
	["CN"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["RM"] = {"Interface\\AddOns\\Narcissus\\Font\\SourceSansPro-Semibold.ttf", 9},
	["RU"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf", 8},
	["KR"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["JP"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
}

local function SmartSetActorName(fontstring, text)
	--Automatically apply different font based on given text languange. Change text color after this step.
	if not fontstring then return; end;
	fontstring:SetText(text);
	local language = LanguageDetector(text);
	if language and ActorNameFont[language] then
		fontstring:SetFont(ActorNameFont[language][1] , ActorNameFont[language][2], "");
	end
end

local function SmartFontType(self, fontTable)
	local str = self:GetText();
	local language = LanguageDetector(str);
	--print(str.." Language is: "..Language);
    local height = self:GetHeight();
    if language and fontTable[language] then
		self:SetFont(fontTable[language] , height, "");
	end
end

local function SmartEditBoxFont(self, extraHeight)
	local str = self:GetText();
	local language = LanguageDetector(str);
    if language and EditBoxFont[language] then
        local height = extraHeight or 0;
		self:SetFont(EditBoxFont[language][1] , EditBoxFont[language][2] + height, "");
	end
end

local function NarciAPI_SmartFontType(fontString)
    SmartFontType(fontString, PlayerNameFont);
end

local function SmartSetName(fontString, str)
	local language = LanguageDetector(str);
    if language and NormalFont12[language] then
		fontString:SetFont(NormalFont12[language][1], NormalFont12[language][2], "");
	end
    fontString:SetText(str);
end

NarciAPI.SmartSetActorName = SmartSetActorName;
NarciAPI.SmartFontType = NarciAPI_SmartFontType;
NarciAPI.SmartSetName = SmartSetName;

function NarciAPI_SmartEditBoxType(self, isUserInput, extraHeight)
    SmartEditBoxFont(self, extraHeight);
end

--[[
function NarciAPI_EditBox_OnLanguageChanged(self, language)
    SmartEditBoxFont(self);
end
--]]

-----Filter Shared Functions-----
function NarciAPI_LetterboxAnimation(command)
	local frame = Narci_FullScreenMask;
	frame:StopAnimating();
	if command == "IN" then
		frame:Show();
		frame.BottomMask.animIn:Play();
		frame.TopMask.animIn:Play();
	elseif command == "OUT" then
		frame.BottomMask.animOut:Play();
		frame.TopMask.animOut:Play();
	else
        if NarcissusDB.LetterboxEffect then
			frame:Show();
			frame.BottomMask.animIn:Play();
			frame.TopMask.animIn:Play();
        else
            frame:Hide();
		end
	end
end

-----Format Normalization-----
local function SplitTooltipByLineBreak(str)
    local str1, _, str2 = strsplit("\n", str);
    return str1 or "", str2 or "";
end
NarciAPI.SplitTooltipByLineBreak = SplitTooltipByLineBreak;


-----Delayed Tooltip-----
local DelayedTP = CreateFrame("Frame");
DelayedTP:Hide();

DelayedTP:SetScript("OnShow", function(self)
    self.t = 0;                                            --Total time after ShowDelayedTooltip gets called
    --self.ScanTime = 0;                                   --Cursor scanning time
    --self.CursorX, self.CursorY = GetCursorPosition();    --Cursor position
end)
DelayedTP:SetScript("OnHide", function(self)
    self.t = 0;
    --self.ScanTime = 0;
end)

DelayedTP:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    --self.ScanTime = self.ScanTime + elapsed;
    if self.t >= 0.6 then
        self.t = 0;
        self:Hide();
        if self.focus and self.focus:IsMouseMotionFocus() then --self.focus and self.focus == GetMouseFocus() 
            NarciGameTooltip:ClearAllPoints();
            NarciGameTooltip:SetPoint(self.point, self.relativeTo, self.relativePoint, self.ofsx, self.ofsy);
            FadeFrame(NarciGameTooltip, 0.15, 1, 0);
            self.focus = nil;
        end
    end
end)

function NarciAPI_ShowDelayedTooltip(point, relativeTo, relativePoint, ofsx, ofsy)
    local tp = DelayedTP;
    tp:Hide();
    if point then
        tp.focus = GetMouseFocus();
        tp.point, tp.relativeTo, tp.relativePoint, tp.ofsx, tp.ofsy = point, relativeTo, relativePoint, ofsx, ofsy;
        tp:Show();
    else
        tp.focus = nil;
        tp.t = 0;
        FadeFrame(NarciGameTooltip, 0, 0);
    end
end

-----Run Delayed Function-----
local DelayedFunc = CreateFrame("Frame");
DelayedFunc:Hide();
DelayedFunc.delay = 0;
DelayedFunc.t = 0;

DelayedFunc:SetScript("OnHide", function(self)
    self.focus = nil;
    self.t = 0;
end)

DelayedFunc:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.delay then
        if self.focus == GetMouseFocus() then
            self.func();
        end
        self:Hide();
    end
end)

function NarciAPI_RunDelayedFunction(frame, delay, func)
    DelayedFunc:Hide();
    if func and type(func) == "function" then
        delay = delay or 0;
        DelayedFunc.focus = frame;
        DelayedFunc.delay = delay;
        DelayedFunc.func = func;
        DelayedFunc:Show();
    end
end

-----Alert Frame-----
NarciAlertFrameMixin = {};

function NarciAlertFrameMixin:AddShakeAnimation(frame)
    if frame.animError then return; end;

    local ag = frame:CreateAnimationGroup();
    local a1 = ag:CreateAnimation("Translation");
    a1:SetOrder(1);
    a1:SetOffset(4, 0);
    a1:SetDuration(0.05);
    local a2 = ag:CreateAnimation("Translation");
    a2:SetOrder(2);
    a2:SetOffset(-8, 0);
    a2:SetDuration(0.1);
    local a3 = ag:CreateAnimation("Translation");
    a3:SetOrder(3);
    a3:SetOffset(8, 0);
    a3:SetDuration(0.1);
    local a4 = ag:CreateAnimation("Translation");
    a4:SetOrder(4);
    a4:SetOffset(-4, 0);
    a4:SetDuration(0.05);

    ag:SetScript("OnPlay", function()
        PlaySound(138528);      --Mechagon_HK8_Lockon
    end);

    frame.animError = ag;
end

function NarciAlertFrameMixin:SetAnchor(frame, offsetY, AddErrorAnimation)
    if frame.RegisterErrorEvent then
        frame:RegisterErrorEvent();
        After(0.5, function()
            frame:UnregisterErrorEvent();
        end)
    else
        frame:RegisterEvent("UI_ERROR_MESSAGE");
        After(0.5, function()
            frame:UnregisterEvent("UI_ERROR_MESSAGE");
        end)
    end

	self:Hide();
    self:ClearAllPoints();
    self:SetScale(Narci_Character:GetEffectiveScale())
    offsetY = offsetY or 0
	self:SetPoint("BOTTOM", frame, "TOP", 0, offsetY);
    self:SetFrameLevel(50);
    self.anchor = frame;

    if AddErrorAnimation then
        self:AddShakeAnimation(frame);
    end
end

function NarciAlertFrameMixin:AddMessage(msg, UseErrorAnimation)
    self.Text:SetText(msg);
    self:UpdateFrameSize();
    FadeFrame(self, 0.2, 1);
    local anchorFrame = self.anchor;
    if anchorFrame then
        if anchorFrame.animError and UseErrorAnimation then
            anchorFrame.animError:Play();
        end
        anchorFrame:UnregisterEvent("UI_ERROR_MESSAGE");
    end
end

function NarciAlertFrameMixin:UpdateFrameSize()
    local textWidth = self.Text:GetWrappedWidth();
    local textHeight = self.Text:GetHeight();
    self:SetSize(textWidth + 24, textHeight + 24);
end


------------------------
--Filled Bar Animation--
------------------------
--Corruption Bar
--[[
local cos = math.cos;
local pi = math.pi;
local function inOutSine(t, b, c, d)
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local FluidAnim = CreateFrame("Frame");
FluidAnim:Hide();
FluidAnim.d = 0.5;
FluidAnim.d1 = 0.25;
FluidAnim.d2 = 0.5;

local function FluidLevel(self, elapsed)
	self.t = self.t + elapsed;
	local height = inOutSine(self.t, self.startHeight, self.endHeight - self.startHeight, self.d);
	if self.t >= self.d then
		height = self.endHeight;
		self:Hide();
	end
	self.Fluid:SetHeight(height);
end

local function FluidUp(self, elapsed)
	self.t = self.t + elapsed;
	local height;
	if self.t <= self.d1 then
		height = inOutSine(self.t, self.startHeight, 84 - self.startHeight, self.d1);
    elseif self.t < self.d3 then
        if not self.colorChanged then
            self.colorChanged = true;
            self.Fluid:SetColorTexture(self.r, self.g, self.b);
        end
		height = inOutSine(self.t - self.d1, 0.01, self.endHeight, self.d2);
	else
		height = self.endHeight;
		self:Hide();
	end
	self.Fluid:SetHeight(height);
end

local function FluidDown(self, elapsed)
	self.t = self.t + elapsed;
	local height;
	if self.t <= self.d1 then
		height = inOutSine(self.t, self.startHeight, 0.01 - self.startHeight, self.d1);
    elseif self.t < self.d3 then
        if not self.colorChanged then
            self.colorChanged = true;
            self.Fluid:SetColorTexture(self.r, self.g, self.b);
        end
		height = inOutSine(self.t - self.d1, 84, self.endHeight - 84, self.d2);
	else
		height = self.endHeight;
		self:Hide();
	end
	self.Fluid:SetHeight(height);
end

FluidAnim:SetScript("OnShow", function(self)
    self.t = 0;
    self.colorChanged = false;
end);

function NarciAPI_SmoothFluid(bar, newHeight, newLevel, r, g, b)
	local FluidAnim = FluidAnim;
	FluidAnim:Hide();
    FluidAnim.endHeight = newHeight;
    FluidAnim.Fluid = bar;
    FluidAnim.r, FluidAnim.g, FluidAnim.b = r, g, b;

	local oldLevel = FluidAnim.oldCorruptionLevel or newLevel;
	FluidAnim.oldCorruptionLevel = newLevel;

	local t1, t2;
	local h = FluidAnim.Fluid:GetHeight();
	FluidAnim.startHeight = h;

	if newLevel == oldLevel then
		FluidAnim:SetScript("OnUpdate", FluidLevel);
        FluidAnim.d = max( abs(h - FluidAnim.endHeight) / 84 , 0.35); 
        bar:SetColorTexture(r, g, b);
	elseif newLevel < oldLevel then
		FluidAnim:SetScript("OnUpdate", FluidDown);
		t1 = math.max(h / 84, 0);
		t2 = math.max((84 - FluidAnim.endHeight) / 84, 0.4);
		FluidAnim.d1 = t1
		FluidAnim.d2 = t2
		FluidAnim.d3 = t1 + t2;
	else
		FluidAnim:SetScript("OnUpdate", FluidUp);
		t1 = math.max((84 - h) / 84, 0);
		t2 = math.max(FluidAnim.endHeight / 84, 0.4);
		FluidAnim.d1 = t1
		FluidAnim.d2 = t2
		FluidAnim.d3 = t1 + t2;
	end
	
	After(0, function()
		FluidAnim:Show();
	end)

	return t1
end


local EyeballTexture = "Interface\\AddOns\\Narcissus\\ART\\Widgets\\CorruptionSystem\\Eyeball-Orange";
local CorruptionColor = "|cfff57f20";
local FluidColors = {0.847, 0.349, 0.145};
        
function NarciAPI_GetEyeballColor()
    return EyeballTexture, CorruptionColor, FluidColors[1], FluidColors[2], FluidColors[3];
end

function NarciAPI_SetEyeballColor(index)
    if index == 4 then
        EyeballTexture = "Interface\\AddOns\\Narcissus\\ART\\Widgets\\CorruptionSystem\\Eyeball-Blue";
        CorruptionColor = "|cff83c7e7";
        FluidColors = {0.596, 0.73, 0.902};
    elseif index == 2 then
        EyeballTexture = "Interface\\AddOns\\Narcissus\\ART\\Widgets\\CorruptionSystem\\Eyeball-Purple";
        CorruptionColor = "|cfff019ff";
        FluidColors = {0.87, 0.106, 0.949};
    elseif index == 3 then
        EyeballTexture = "Interface\\AddOns\\Narcissus\\ART\\Widgets\\CorruptionSystem\\Eyeball-Green";
        CorruptionColor = "|cff8cdacd";
        FluidColors = {0.56, 0.855, 0.757};
    else
        index = 1;
        EyeballTexture = "Interface\\AddOns\\Narcissus\\ART\\Widgets\\CorruptionSystem\\Eyeball-Orange";
        CorruptionColor = "|cfff57f20";
        FluidColors = {0.847, 0.349, 0.145};
    end

    NarcissusDB.EyeColor = index;
    local Preview = Narci_EyeColorPreview;
    local ColorButtons = Preview:GetParent().ColorButtons;
    Preview:SetTexCoord(0.25*(index - 1), 0.25*index, 0, 1);
    for i = 1, #ColorButtons do
        --ColorButtons[i]Highlight(false);
    end
    --ColorButtons[index]:Highlight(true);

    Narci:SetItemLevel();
end
--]]

--------------------
--UI 3D Animation---
--------------------
Narci.AnimSequenceInfo = 
{	["Controller"] = {
		["TotalFrames"] = 30,
		["cX"] = 0.205078125,
		["cY"] = 0.1171875,
		["Column"] = 4,
		["Row"] = 8,
	},

	["Heart"] = {
		["TotalFrames"] = 28,
		["cX"] = 0.25,
		["cY"] = 0.140625,
		["Column"] = 4,
		["Row"] = 7,
    },

	["ActorPanel"] = {
		["TotalFrames"] = 26,
		["cX"] = 0.4296875,
		["cY"] = 0.056640625,
		["Column"] = 2,
		["Row"] = 17,
    },
}

function NarciAPI_PlayAnimationSequence(index, SequenceInfo, Texture)
	local Frames = SequenceInfo["TotalFrames"];
	local cX, cY = SequenceInfo["cX"], SequenceInfo["cY"];
	local col, row = SequenceInfo["Column"], SequenceInfo["Row"]

	if index > Frames or index < 1 then
		return false;
	end

	local n = math.modf((index -1)/ row) + 1;
	local m = index % row
	if m == 0 then
		m = row;
	end

	local left, right = (n-1)*cX, n*cX;
	local top, bottom = (m-1)*cY, m*cY;
	Texture:SetTexCoord(left, right, top, bottom);
    Texture:SetAlpha(1);
    Texture:Show();
	return true;
end



--------------------
-----Play Voice-----
--------------------

local ERROR_NOTARGET, ALERT_INCOMING;

do
    local _, _, raceID = UnitRace("player");
    local genderID = UnitSex("player") or 2;
    raceID = raceID or 1;
    genderID = genderID - 1;    --(2→1) Male (3→2) Female
    if raceID == 25 or raceID == 26 then
        --Pandaren faction
        raceID = 24;
    elseif raceID == 52 or raceID == 70 then
        raceID = 52;
    end

    if raceID == 37 then    --Mechagnome
        IGNORED_MOG_SLOT[8] = true;     --feet
        IGNORED_MOG_SLOT[9] = true;     --wrist
        IGNORED_MOG_SLOT[10] = true;    --hands
    elseif raceID == 52 then    --Dracthyr

    end

    local VOICE_BY_RACE = {
    --[raceID] = { [gender] = {Error_NoTarget, ALERT_INCOMING} }
	[1] = {[1] = {1906, 2669, },
				[2] = {2030, 2681, }},		            --1 Human 

	[2] = {[1] = {2317, 2693, },
				[2] = {2372, 2705, }},		            --2 Orc

	[3] = {[1] = {1614, 2717, },
				[2] = {1684, 2729, }},		            --3 Dwarf 

	[4] = {[1] = {56231, 56311, },
				[2] = {56096, 56174, }},		        --4 NE 

	[5] = {[1] = {2085, 2765, },
				[2] = {2205, 2777, }},		            --5 UD 

	[6] = {[1] = {2459, 2789, },
				[2] = {2458, 2802, }},		            --6 Tauren

	[7] = {[1] = {1741, 2827, },
				[2] = {1796, 2839, }},		            --7 Gnome 

	[8] = {[1] = {1851, 2851, },
				[2] = {1961, 2863, }},		            --8 Troll 

	[9] = {[1] = {19109, 19137, },
				[2] = {19218, 19246}},		            --9 Goblin 

	[10] = {[1] = {9597, 9664, },
				[2] = {9598, 9624, }},		            --10 BloodElf

	[11] = {[1] = {9463, 9714, },
				[2] = {9514, 9689, }},		            --11 Goat 
			
	[22] = {[1] = {18991, 19346, },
				[2] = {18719, 19516, }},	            --22 Worgen

	[24] = {[1] = {28846, 28924, },
				[2] = {29899, 29812, }},		        --24 Pandaren

	[27] = {[1] = {96356, 96383, },
				[2] = {96288, 96315, }},		        --27 Nightborne

	[28] = {[1] = {95931, 95844, },
                [2] = {95510, 95543, }},		        --28 Highmountain Tauren
                
	[29] = {[1] = {95636, 95665, },
				[2] = {95806, 95857, }},		        --29 Void Elf

	[30] = {[1] = {96220, 96247, },
                [2] = {96152, 96179, }},		        --30 Light-forged
                
	[31] = {[1] = {127289, 1273128, },
				[2] = {126915, 126944, }},		        --31 Zandalari

	[32] = {[1] = {127102, 127131, },
				[2] = {127008, 127037, }},	            --32 Kul'Tiran 

	[34] = {[1] = {101933, 101962, },
                [2] = {101859, 101888, }},		        --36 Dark Iron Dwarf

	[35] = {[1] = {144073, 144111, },
                [2] = {143981, 144019, }},		        --35 Vulpera     
                      
	[36] = {[1] = {110370, 110399, },
                [2] = {110295, 110324, }},		        --36 Mag'har
                
	[37] = {[1] = {143863, 143892, },
				[2] = {144223, 144275, }},		        --37 Mechagnome!!!!

    [52] = {[1] = {212644, 212598, },
        [2] = {212644, 212688, }},		                --52 Dracthyr
    };

    if VOICE_BY_RACE[raceID] then
        ERROR_NOTARGET = VOICE_BY_RACE[raceID][genderID][1];
        ALERT_INCOMING = VOICE_BY_RACE[raceID][genderID][2];
    end

    ERROR_NOTARGET = ERROR_NOTARGET or 2030;
    ALERT_INCOMING = ALERT_INCOMING or 2669;

    VOICE_BY_RACE = nil;
end


function Narci:PlayVoice(name)
    if name == "ERROR" then
        PlaySound(ERROR_NOTARGET, "Dialog");
    elseif name == "DANGER" then
        PlaySound(ALERT_INCOMING, "Dialog");
    end
end

--Time
--C_DateAndTime.GetCurrentCalendarTime

local DEFAULT_ACTOR_INFO_ID = 1620; --438 Pre-DF
local ActorIDByRace = {
    --local GenderID = UnitSex(unit);   2 Male 3 Female
	--[raceID] = {male actorID, female actorID, bustOffsetZ_M, bustOffsetZ_F},
    [2]  = {483, 483},		-- Orc bow
    [3]  = {471, nil},		-- Dwarf
    [5]  = {472, 487},		-- UD   0.9585 seems small
    [6]  = {449, 484},		-- Tauren
    [7]  = {450, 450},		-- Gnome
    [8]  = {485, 486},		-- Troll  0.9414 too high?
    [9]  = {476, 477},		-- Goblin
    [11] = {475, 501},		-- Goat
    [22] = {474, 500},      -- Worgen
    [24] = {473, 473},		-- Pandaren
    [28] = {490, 491},		-- Highmountain Tauren
    [30] = {488, 489},		-- Lightforged Draenei
    [31] = {492, 492},		-- Zandalari
    [32] = {494, 497},		-- Kul'Tiran
    [34] = {499, nil},		-- Dark Iron Dwarf
    [35] = {924, 923},      -- Vulpera
    [36] = {495, 498},		-- Mag'har
    [37] = {929, 931},      -- Mechagnome
    [52] = {1554, 1554},    -- Dracthyr
    [70] = {1554, 1554},    -- Dracthyr
    [84] = {2152, 2154},    -- Earthen
    [85] = {2152, 2154},    -- Earthen
};

local ActorIDByModelFileID = {
    --/dump DressUpFrame.ModelScene:GetPlayerActor():GetModelFileID()
    --https://wago.tools/db2/UiModelSceneActor
    [4207724] = 1653,   --Dracthyr 1554
    [4395382] = 1654,   --Visage M Dracthyr-alt 1583
    [4220488] = 1654,   --Visage F

    [878772] = 1623,    --Dwarf M
    --[950080] = Dwarf F
    [1890765] = 1644,   --darkirondwarf-male
    --[1890763] = DarkIron F

    [1721003] = 1640,   --kultiran-male
    [1886724] = 1642,   --kultiran-female

    [2622502] = 1649,   --mechagnome-male
    [2564806] = 1650,   --mechagnome-female

    [1890761] = 1648,   --vulpera-male
    [1890759] = 1647,   --vulpera-female

    [1630218] = 1637,   --highmountaintauren-male
    [1630402] = 1638,   --highmountaintauren-female
    
    [900914] = 1622,    --Gnome M
    [940356] = 1622,    --Gnome F

    [119376] = 1628,    --goblin-male
    [119369] = 1629,    --goblin-female

    [1005887] = 1627,   --draenei-male
    --[1022598] = draenei F

    [1620605] = 1635,   --lightforgeddraenei-male
    [1593999] = 1636,   --lightforgeddraenei-female

    [1630447] = 1639,     --zandalaritroll M
    [1662187] = 1639,     --zandalaritroll F

    [1022938] = 1632,   --troll-male
    [1018060] = 1633,   --troll-female

    [959310] = 1624,    --scourge-male
    [997378] = 1634,    --scourge-female

    [535052] = 1625,    --pandaren M
    [589715] = 1625,    --pandaren F

    [307454] = 1626,    --worgen-male
    [307453] = 1645,    --worgen-female

    [917116] = 1641,     --magharorc-male hunched
    [1968587] = 1641,     --magharorc-male straght
    [949470] = 1643,     --magharorc-female

    [5548261] = 2152,   --earthendwarf-male
    [5548259] = 2154,   --earthendwarf-female

    --[1011653] = Human M
    --[1000764] = Human F

    --[1814471] = Nightborne M
    --[1810676] = Nightborne F

    --[1734034] = VE M
    --[1733758] = VE F

    --[1100087] = BE M
    --[1100258] = BE F

    --[974343] = NE M
    --[921844] = NE F
};


local GetModelSceneActorInfoByID = C_ModelInfo.GetModelSceneActorInfoByID;

local function GetActorInfoByFileID(fileID)
    --print("FileID: ", fileID)
    local infoID;
    if fileID and ActorIDByModelFileID[fileID] then
        infoID = ActorIDByModelFileID[fileID];
    else
        infoID = DEFAULT_ACTOR_INFO_ID;
    end
    return GetModelSceneActorInfoByID(infoID);
end
addon.GetActorInfoByFileID = GetActorInfoByFileID;

--Re-check this↑ table every major patch

function Narci_FindActorIDBy(name)
    local id = 300;
    local info, tag;
    local find = string.find;
    while id < 2000 do
        id = id + 1;
        info = C_ModelInfo.GetModelSceneActorInfoByID(id);
        if info then
            tag = info.scriptTag;
            if tag and find(tag, name) then
                print(id, tag);
                --return
            end
        end
    end
end



local ZoomDistanceByRace = {
    --[raceID] = {male Zoom, female Zoom, bustOffsetZ_M, bustOffsetZ_F},
    [1]  = {2.4, 2},		-- Human
    [2]  = {2.5, 2},		-- Orc bow
    [3]  = {2.5, 2},		-- Dwarf
    [4]  = {2.2, 2.1},      -- Night Elf
    [5]  = {2.5, 2},		-- UD
    [6]  = {3, 2.5},		-- Tauren
    [7]  = {2.6, 2.8},		-- Gnome
    [8]  = {2.5, 2},		-- Troll
    [9]  = {2.9, 2.9},		-- Goblin
    [10] = {2, 2},          -- Blood Elf
    [11] = {2.4, 2},		-- Goat
    [22] = {2.8, 2},        -- Worgen
    [24] = {2.9, 2.4},		-- Pandaren
    [27] = {2, 2},		-- Nightborne
    --[29] = {2, 2},            -- Void Elf
    --[28] = {2, 2},		-- Highmountain Tauren
    --[30] = {2, 2},		-- Lightforged Draenei
    [31] = {2.2, 2},		-- Zandalari
    [32] = {2.4, 2.3},		-- Kul'Tiran
    --[34] = {2, 2},		-- Dark Iron Dwarf
    [35] = {2.6, 2.1},      -- Vulpera
    --[36] = {2, 2},		-- Mag'har
    --[37] = {2, 2},      -- Mechagnome
}

function NarciAPI_GetCameraZoomDistanceByUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or not CanInspect(unit, false) then return; end
    
    local _, _, raceID = UnitRace(unit);
    local genderID = UnitSex(unit);
    if raceID == 25 or raceID == 26 then --Pandaren A|H
        raceID = 24;
    elseif raceID == 29 then
        raceID = 10;
    elseif raceID == 37 then
        raceID = 7;
    elseif raceID == 30 then
        raceID = 11;
    elseif raceID == 28 then
        raceID = 6;
    elseif raceID == 34 then
        raceID = 3;
    elseif raceID == 36 then
        raceID = 2;
    elseif raceID == 22 then
        if unit == "player" then
            local _, inAlternateForm = HasAlternateForm();
            if not inAlternateForm then
                --Wolf
                raceID = 22;
            else
                raceID = 1;
            end
        end
    end
    if not (raceID and genderID) then
        return 2
    elseif ZoomDistanceByRace[raceID] then
        return ZoomDistanceByRace[raceID][genderID - 1] or 2;
    else
        return 2
    end
end


local PanningYOffsetByRace = {
    --[raceID] = { { male = {offsetY1 when frame maximiazed, offsetY2} }, {female = ...} }
    [0] = {     --default
        {-290, -110},
    },

    [4] = { --NE
        {-317, -117},
        {-282, -115.5},
    },

    [10] = {    --BE
        {-282, -110},
        {-290, -116}, 
    }
    --/dump DressUpFrame.ModelScene:GetActiveCamera().panningYOffset
}

PanningYOffsetByRace[29] = PanningYOffsetByRace[10];

local function GetPanningYOffset(raceID, genderID)
    genderID = genderID -1;
    if PanningYOffsetByRace[raceID] and PanningYOffsetByRace[raceID][genderID] then
        return PanningYOffsetByRace[raceID][genderID]
    else
        return PanningYOffsetByRace[0][1]
    end
end

function NarciAPI_GetActorInfoByUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or not CanInspect(unit, false) then return nil, PanningYOffsetByRace[0][1]; end
    
    local _, _, raceID = UnitRace(unit);
    local genderID = UnitSex(unit);
    if raceID == 25 or raceID == 26 then --Pandaren A|H
        raceID = 24
    end

    local actorInfoID;
    if not (raceID and genderID) then
        actorInfoID = DEFAULT_ACTOR_INFO_ID;     --438
    elseif ActorIDByRace[raceID] then
        actorInfoID = ActorIDByRace[raceID][genderID - 1] or DEFAULT_ACTOR_INFO_ID;
    else
        actorInfoID = DEFAULT_ACTOR_INFO_ID;     --438
    end

    return GetModelSceneActorInfoByID(actorInfoID), GetPanningYOffset(raceID, genderID)
end


NarciModelSceneActorMixin = CreateFromMixins(ModelSceneActorMixin);

function NarciModelSceneActorMixin:OnAnimFinished()
    if self.oneShot then
        --self:Hide();
        if self.finalSequence then
            self:SetAnimation(0, 0, 0, self.finalSequence);
        else
            self:Hide();
        end
    end
    if self.onfinishedCallback then
        self.onfinishedCallback();
    end
end


function NarciAPI_SetupModelScene(modelScene, modelFileID, zoomDistance, view, actorIndex, UseTransit)
    local pi = math.pi;
    local model = modelScene;

    local actorTag;
    if not actorIndex then
        actorTag = "narciEffectActor";
    else
        actorTag = "narciEffectActor"..actorIndex
    end

    local actor = model[actorTag];

    if not actor then
        local actorID = 156;    --effect    C_ModelInfo.GetModelSceneActorInfoByID(156)
        local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(actorID);
        --actor = model:AcquireAndInitializeActor(actorInfo);
        actor = model:CreateActor(nil, "NarciModelSceneActorTemplate");
        actor:SetYaw(pi);
        model[actorTag] = actor;

        local parentFrame = model:GetParent();
        if parentFrame then
            model:SetFrameLevel(parentFrame:GetFrameLevel() + 1 or 20);
        else
            model:SetFrameLevel(20);
        end
    end


    --local cameraTag = "NarciUI";
    local camera = model.narciCamera;
    if not camera then
        camera = CameraRegistry:CreateCameraByType("OrbitCamera");
        if camera then
            model.narciCamera = camera;
            model:AddCamera(camera);
            local modelSceneCameraInfo = C_ModelInfo.GetModelSceneCameraInfoByID(114);
            camera:ApplyFromModelSceneCameraInfo(modelSceneCameraInfo, 1, 1);    --1 ~ CAMERA_TRANSITION_TYPE_IMMEDIATE / CAMERA_MODIFICATION_TYPE_DISCARD
        end
    end

    model:SetActiveCamera(camera);

    if modelFileID then
        actor:SetModelByFileID(modelFileID);
    end
    
    if zoomDistance then
        if UseTransit then
            --change camera.targetInterpolationAmount for smoothing time    --:GetTargetInterpolationAmount() :SetTargetInterpolationAmount(value)
            camera:SetZoomDistance(1);
            camera:SnapAllInterpolatedValues();
            After(0, function()
                camera:SetZoomDistance(zoomDistance);
            end);    
        else
            camera:SetZoomDistance(zoomDistance);
            camera:SynchronizeCamera();
        end
    end

    if view then
        local pitch, yaw;
        if type(view) == "string" then
            view = strupper(view);
            if view == "FRONT" then
                pitch = 0;
                yaw = pi;
            elseif view == "BACK" then
                pitch = 0;
                yaw = 0;
            elseif view == "TOP" then
                pitch = pi/2;
                yaw = pi; 
            elseif view == "BOTTOM" then
                pitch = -pi/2;
                yaw = pi;
            elseif view == "LEFT" then
                pitch = 0;
                yaw = -pi/2;  
            elseif view == "RIGHT" then
                pitch = 0;
                yaw = pi/2;
            else
                return;                    
            end
        elseif type(view) == "table" then
            pitch = view[1];
            yaw = view[2];
            if not (pitch and yaw) then
                return;
            end
        end

        actor:SetPitch(pitch);
        actor:SetYaw(yaw);
    end

    return actor, camera
    --[[
    if rollDegree then
        actor:SetRoll(rad(-rollDegree))     --Clockwise
    end
    --]]
end

--[[
    ScriptAnimatedEffectController:GetCurrentEffectID()

/dump ScriptedAnimationEffectsUtil.GetEffectByID()    101 Center Rune Wind Cyan
effect = {visual(fileID), visualScale, animationSpeed, ...}
fileID, effectID:
3483475 --Black Swirl 52
984698  --Center Rune Wind Cyan 101
3655832 --Circle Rune Effect 73
3656114 --69
--]]

------------------------------------------------------------------------------
local function ReAnchorFrame(frame)
    --maintain frame top position when changing its height
    local oldCenterX = frame:GetCenter();
    --local oldBottom = frame:GetBottom();
    local oldTop = frame:GetTop();
    local screenWidth = WorldFrame:GetWidth();
    local screenHeight = WorldFrame:GetHeight();
    local scale = frame:GetEffectiveScale();
    if not scale or scale == 0 then
        scale = 1;
    end
    local width = frame:GetWidth()/2;
    frame:ClearAllPoints();
    --frame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", oldCenterX + width - screenWidth / scale , oldBottom);
    frame:SetPoint("TOPRIGHT", nil, "TOPRIGHT", oldCenterX + width - screenWidth / scale , oldTop - screenHeight/scale);
end

local function ParserButton_ShowTooltip(self)
    if self.itemLink then
        local frame = self:GetParent();
        local tp = frame.tooltip;
        --GameTooltip_SetBackdropStyle(TP, GAME_TOOLTIP_BACKDROP_STYLE_CORRUPTED_ITEM);
        tp:SetOwner(self, "ANCHOR_NONE");
        tp:SetPoint("TOP", frame.ItemString, "BOTTOM", 0, -14);
        tp:SetHyperlink(self.itemLink);
        tp:SetMinimumWidth(254 / 0.8);
        tp:Show();
        frame:SetHeight( max (floor(tp:GetHeight() - 260), 0) + 400);
        ReAnchorFrame(frame);
    end
end

local function ParserButton_GetCursor(self)
    local infoType, itemID, itemLink = GetCursorInfo();
    self.Highlight:Hide()

    if not (infoType and infoType == "item") then return end

    self.itemLink = itemLink;

    local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemLink);
    local itemString = match(itemLink, "item:([%-?%d:]+)");
    local enchantID = GetItemEnchantID(itemLink);
    local r, g, b = GetCustomQualityColor(itemQuality);

    --Show info
    self.ItemIcon:SetTexture(itemIcon);
    local frame = self:GetParent();
    frame.ItemName:SetText(itemName);
    frame.ItemName:SetTextColor(r, g, b);
    frame.ItemString:SetText(itemString);

    frame.Pointer:Hide();
    ParserButton_ShowTooltip(self);

    ClearCursor();
end


--[[
function Narci_ItemParser_OnLoad(self)
    self:SetUserPlaced(false)
    self:ClearAllPoints();
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    self:RegisterForDrag("LeftButton");
    self:SetScript("OnShow", ReAnchorFrame);
    self.ItemButton:SetScript("OnReceiveDrag", ParserButton_GetCursor);
    self.ItemButton:SetScript("OnClick", ParserButton_GetCursor);
    self.ItemButton:SetScript("OnEnter", ParserButton_ShowTooltip);

    local locale = TEXT_LOCALE;
    local version, build, date, tocversion = GetBuildInfo();

    self.ClientInfo:SetText(locale.."  "..version.."."..build.."  "..NARCI_VERSION_INFO);

    local tooltip = CreateFrame("GameTooltip", "Narci_ItemParserTooltip", self, "GameTooltipTemplate");
    tooltip:Hide();
    self.tooltip = tooltip;

    local scale = 0.8;
    local tooltipScale = 0.8;
    self:SetScale(0.8);
    tooltip:SetScale(tooltipScale);
end
--]]


----------------------------
-----Item Import/Export-----
----------------------------
local WOWHEAD_ENCODING = "0zMcmVokRsaqbdrfwihuGINALpTjnyxtgevElBCDFHJKOPQSUWXYZ123456789";  --version: 9    WH.calc.hash.getEncoding(9)
local WOWHEAD_DELIMITER = 8;                        --WH.calc.hash.getDelimiter(9)
local COMPRESSION_INDICATOR = 7;                    --WH.calc.hash.getZeroDelimiterCompressionIndicator(9) :7 + single letter
local WOWHEAD_MAXCODING_INDEX = 58                  --WH.calc.hash.getMaxEncodingIndex(a);  //9 ~ 58
local WOWHEAD_CUSTOMIZATION = "0zJ89b";

local EncodeValue = {}
for i = 0, #WOWHEAD_ENCODING do
    EncodeValue[i] = strsub(WOWHEAD_ENCODING, i+1, i+1);
end

local EquipmentOrderToCharacterSlot = {
    [1] = 1,
    [2] = 3,
    [3] = 15,
    [4] = 5,
    [5] = 4,
    [6] = 19,
    [7] = 9,
    [8] = 10,
    [9] = 6,
    [10]= 7,
    [11]= 8,
    [12]= 16,
    [13]= 17,
};

local CharacterSlotToEquipmentOrder = {}
for k, v in pairs(EquipmentOrderToCharacterSlot) do
    CharacterSlotToEquipmentOrder[v] = tostring(k);
    v = tostring(v);
end

local function EncodeLongValue(number)
    local m = WOWHEAD_MAXCODING_INDEX;
    if number <= m then
        return EncodeValue[number];
    end

    local floor = floor;
    local shortValues = {number};
    local v = 0;
    while(shortValues[1] > m) do
        v = floor(shortValues[1] / m);
        tinsert(shortValues, shortValues[1] - m * v);
        shortValues[1] = v;
    end

    local str = EncodeValue[ shortValues[1] ];
    for i = #shortValues, 2, -1 do
        if shortValues[2] ~= "0" then
            str = str .. EncodeValue[ shortValues[i] ]
        else
            str = str .. "7"
        end
    end
    return str
end

local function EncodeItemlist(itemlist, unitInfo)
    if not itemlist or type(itemlist) ~= "table" or itemlist == {} then return ""; end
    --itemlist = {[slot] = {itemID, bonusID}}

    local raceID, genderID, classID;

    if unitInfo then
        raceID, genderID, classID = unitInfo.raceID, unitInfo.genderID, unitInfo.classID;
    else
        local _;
        local unit = "player";
        _, _, raceID = UnitRace(unit);
        genderID = UnitSex(unit);
        _, _, classID = UnitClass(unit);
    end

    if not (raceID and genderID and classID) then
        local _;
        local unit = "player";
        _, _, raceID = UnitRace(unit);

        _, _, classID = UnitClass(unit);
        genderID = UnitSex(unit) or 2;
        raceID = raceID or 1;
        classID = classID or 1;
    end
    genderID = genderID - 2;      --Male 2 → 0  Female 3 → 1

    local wowheadLink = "https://www.wowhead.com/dressing-room#s".. EncodeValue[raceID] .. EncodeValue[genderID] .. EncodeValue[classID] .. WOWHEAD_CUSTOMIZATION.. WOWHEAD_DELIMITER;
    
    local segment, slot, item;
    local blanks = 0;
    for i = 1, #EquipmentOrderToCharacterSlot do
        --item = { itemID, bonusID }
        slot = EquipmentOrderToCharacterSlot[i]
        item = itemlist[slot];
        if item and item[1] then
            segment = EncodeLongValue(item[1])
            if #segment < 3 then
                segment = "7".. CharacterSlotToEquipmentOrder[slot] .. segment
            end
            item[2] = item[2] or 0; --bonusID
            if slot == 16 and item[2] > 0 and item[2] < 99 then
                local offHand = itemlist[17];
                if offHand and offHand[1] then
                    segment = segment .. WOWHEAD_DELIMITER .. "0" .. WOWHEAD_DELIMITER .. EncodeLongValue(offHand[1]) .. WOWHEAD_DELIMITER .. "7c" .. EncodeValue[ item[2] ];
                else
                    segment = segment .. WOWHEAD_DELIMITER .. "7V" .. EncodeValue[ item[2] ];
                end
                wowheadLink = wowheadLink .. segment;
                break;
            else
                segment = segment .. WOWHEAD_DELIMITER .. EncodeLongValue(item[2]) .. WOWHEAD_DELIMITER;
            end
            wowheadLink = wowheadLink .. segment;
        else
            blanks = blanks + 1;
            wowheadLink = wowheadLink .. "7M"
        end
    end

    return wowheadLink
end

NarciAPI.EncodeItemlist = EncodeItemlist;

--------------------
----Model Widget----
--------------------
local function NarciAPI_InitializeModelLight(model)
    --Model: DressUpModel/Cinematic Model/...
    --Not ModelScene
    --model:SetLight(true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 172/255, 172/255, 172/255, 1, 0.8, 0.8, 0.8);
    TransitionAPI.SetModelLight(model, true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 172/255, 172/255, 172/255, 1, 0.8, 0.8, 0.8);
end

NarciAPI.InitializeModelLight = NarciAPI_InitializeModelLight;


----------------------------
----UI Animation Generic----
----------------------------
function NarciAPI_CreateAnimationFrame(duration, frameName)
    local frame = CreateFrame("Frame", frameName);
    frame:Hide();
    frame.total = 0;
    frame.duration = duration;
    frame:SetScript("OnHide", function(self)
        self.total = 0;
    end);
    return frame;
end

function NarciAPI_CreateFadingFrame(parentObject)
    local animFade = NarciAPI_CreateAnimationFrame(0.2);
    animFade.timeFactor = 1;
    parentObject.animFade = animFade;
    animFade:SetScript("OnUpdate", function(frame, elapsed)
        frame.t = frame.t + elapsed;
        if frame.t > 0 then
            local alpha = frame.fromAlpha;
            alpha = alpha + frame.timeFactor * elapsed;
            frame.fromAlpha = alpha;
            if alpha >= 1 then
                alpha = 1;
                frame:Hide();
            elseif alpha <= 0 then
                alpha = 0;
                frame:Hide();
            end
            parentObject:SetAlpha(alpha);
        end
    end);

    function parentObject:FadeOut(duration, delay)
        delay = delay or 0;
        animFade.t = -delay;
        duration = duration or 0.15;

        if duration == 0 then
            animFade:Hide();
            parentObject:SetAlpha(0);
            return
        end

        local alpha = parentObject:GetAlpha();
        animFade.fromAlpha = alpha;
        animFade.timeFactor = -1/duration;
        if alpha == 0 then
            animFade:Hide();
        else
            animFade:Show();
        end
    end

    function parentObject:FadeIn(duration, delay)
        delay = delay or 0;
        animFade.t = -delay;
        duration = duration or 0.2;

        if duration == 0 then
            animFade:Hide();
            parentObject:SetAlpha(1);
            return
        end

        local alpha = parentObject:GetAlpha();
        animFade.fromAlpha = alpha;
        animFade.timeFactor = 1/duration;
        parentObject:Show();
        if alpha ~= 1 then
            animFade:Show();
        end
    end

    return animFade
end


-------------------------------------------
local DelayedFadeIn = NarciAPI_CreateAnimationFrame(1);
DelayedFadeIn:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide();
        if self.anchor == GetMouseFocus() then
            FadeFrame(self.object, 0.25, 1);
        end
    end
end);

NarciHotkeyNotificationMixin = {};

function NarciHotkeyNotificationMixin:SetKey(hotkey, mouseButton, description, alwaysShown, enableListener)
    local ICON_HEIGHT = 20;
    self.alwaysShown = alwaysShown;
    self.enableListener = enableListener;
    self.Label:SetText(description);

    if description then
        self.GradientM:Show();
        self.GradientR:Show();
    else
        self.GradientM:Hide();
        self.GradientR:Hide();
    end

    if alwaysShown then
        self:SetAlpha(1);
    else
        self:SetAlpha(0);
    end

    local width = self.Label:GetWidth();

    if hotkey then
        self.KeyIcon:SetTexture("Interface/AddOns/Narcissus/Art/Keyboard/Key", nil, nil, "TRILINEAR");
        self.KeyIcon:Show();
        if string.lower(hotkey) == "alt" then
            hotkey = NARCI_MODIFIER_ALT;
        end
        self.KeyLabel:SetText(hotkey);
        self.KeyLabel:SetShadowColor(0, 0, 0);
        self.KeyLabel:SetShadowOffset(0, 1.4);

        local texWidth;
        if string.len(hotkey) > 5 then
            texWidth = 146;
            self.KeyIcon:SetTexCoord(0, texWidth/256, 0.25, 0.5);
            self.isLongButton = true
        else
            texWidth = 118;
            self.isLongButton = nil;
            self.KeyIcon:SetTexCoord(0, texWidth/256, 0, 0.25);
        end
        self.keyTexCoord = texWidth/256;
        self.KeyIcon:SetSize(texWidth/64*ICON_HEIGHT, ICON_HEIGHT);
        width = width + texWidth/64*ICON_HEIGHT;
    end

    if mouseButton then
        self.key = mouseButton;
        self.MouseIcon:SetTexture("Interface/AddOns/Narcissus/Art/Keyboard/Mouse", nil, nil, "TRILINEAR");
        self.MouseIcon:Show();
        self.MouseIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT);
        if mouseButton == "LeftButton" then
            self.MouseIcon:SetTexCoord(0, 0.25, 0, 1);
        elseif mouseButton == "RightButton" then
            self.MouseIcon:SetTexCoord(0.25, 0.5, 0, 1);
        elseif mouseButton == "MiddleButton" then
            self.MouseIcon:SetTexCoord(0.5, 0.75, 0, 1);
        elseif mouseButton == "MouseWheel" then
            self.MouseIcon:SetTexCoord(0.75, 1, 0, 1);
        end

        if hotkey then
            self.KeyIcon:ClearAllPoints();
            self.KeyIcon:SetPoint("RIGHT", self.MouseIcon, "LEFT", 0, 0);
            width = width + ICON_HEIGHT;
        end
    end

    self:SetWidth(width);
end

function NarciHotkeyNotificationMixin:ShowTooltip()
    DelayedFadeIn:Hide();
    DelayedFadeIn.anchor = GetMouseFocus();
    DelayedFadeIn.object = self;
    DelayedFadeIn:Show();
end

function NarciHotkeyNotificationMixin:FadeIn()
    DelayedFadeIn:Hide();
    FadeFrame(self, 0.25, 1);
end

function NarciHotkeyNotificationMixin:FadeOut()
    DelayedFadeIn:Hide();
    FadeFrame(self, 0.25, 0);
end

function NarciHotkeyNotificationMixin:JustHide()
    DelayedFadeIn:Hide();
    FadeFrame(self, 0, 0);
end

function NarciHotkeyNotificationMixin:OnShow()
    if self.enableListener then
        self:RegisterEvent("GLOBAL_MOUSE_UP");
    end
end

function NarciHotkeyNotificationMixin:OnHide()
    if not self.alwaysShown then
        DelayedFadeIn:Hide();
        self:Hide();
        self:SetAlpha(0);
    end

    if self.enableListener then
        self:UnregisterEvent("GLOBAL_MOUSE_UP");
    end
end

function NarciHotkeyNotificationMixin:OnEvent(event, key)
    if key == self.key then
        self:UnregisterEvent("GLOBAL_MOUSE_UP");
        self:FadeOut();
    end
end

function NarciHotkeyNotificationMixin:SetHighlight(state)
    if self.keyTexCoord then
        local texCoordY;
        if self.isLongButton then
            texCoordY = 0.25;
        else
            texCoordY = 0;
        end
        if state then
            texCoordY = texCoordY + 0.5;
            self.KeyIcon:SetTexCoord(0, self.keyTexCoord, texCoordY + 0.25, texCoordY);
            self.KeyLabel:SetPoint("CENTER", 0, -1);
            self.KeyLabel:SetTextColor(0.72, 0.72, 0.72);
        else
            self.KeyIcon:SetTexCoord(0, self.keyTexCoord, texCoordY, texCoordY + 0.25);
            self.KeyLabel:SetPoint("CENTER", 0, 0);
            self.KeyLabel:SetTextColor(0.6, 0.6, 0.6);
        end
    end
end


-----------------------------------------------------------
NarciDarkRoundButtonMixin = {};

function NarciDarkRoundButtonMixin:OnLoad()
    self.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Buttons\\Button-Round", nil, nil, "TRILINEAR");
end

function NarciDarkRoundButtonMixin:SetLabelText(label)
    self.Label:SetText("");
    self.Label:SetText(label);
    local textWidth = self.Label:GetWidth();
    self.effectiveWidth = floor( self:GetWidth() + textWidth + 2 + 2);
end

function NarciDarkRoundButtonMixin:Initialize(groupIndex, label, tooltip, onClickFunc)
    self:SetLabelText(label);

    if tooltip then
        self.tooltip = tooltip;
    end

    if groupIndex then
        self.groupIndex = groupIndex;
        local parent = self:GetParent();
        if not parent.buttonGroups then
            parent.buttonGroups = {};
        end
        if not parent.buttonGroups[groupIndex] then
            parent.buttonGroups[groupIndex] = {};
        end
        tinsert(parent.buttonGroups[groupIndex], self);
    end

    if onClickFunc then
        self.onClickFunc = onClickFunc;
    end
end

function NarciDarkRoundButtonMixin:GetEffectiveWidth()
    return self.effectiveWidth or self:GetWidth()
end

function NarciDarkRoundButtonMixin:GetGroupEffectiveWidth()
    if self.groupIndex then
        local buttons = self:GetParent().buttonGroups[self.groupIndex];
        local width = 0;
        local maxWidth = 0;
        for i = 1, #buttons do
            width = buttons[i]:GetEffectiveWidth();
            if width > maxWidth then
                maxWidth = width;
            end
        end
        return maxWidth
    else
        return self:GetEffectiveWidth();
    end
end

function NarciDarkRoundButtonMixin:Select()
    self.SelectedIcon:Show();
    self.isSelected = true;
end

function NarciDarkRoundButtonMixin:Deselect()
    self.SelectedIcon:Hide();
    self.isSelected = nil;
end

function NarciDarkRoundButtonMixin:UpdateVisual()
    if self.groupIndex then
        local buttons = self:GetParent().buttonGroups[self.groupIndex];
        for i = 1, #buttons do
            buttons[i]:Deselect()
        end
    end
    self:Select();
end

function NarciDarkRoundButtonMixin:OnClick()
    self:UpdateVisual();
    if self.onClickFunc then
        self.onClickFunc();
    end
end

function NarciDarkRoundButtonMixin:OnMouseDown()
    self.PushedHighlight:Show();
end

function NarciDarkRoundButtonMixin:OnMouseUp()
    self.PushedHighlight:Hide();
end

function NarciDarkRoundButtonMixin:UpdateGroupHitBox()
    if self.groupIndex then
        local maxWidth = self:GetGroupEffectiveWidth();
        local buttons = self:GetParent().buttonGroups[self.groupIndex];
        for i = 1, #buttons do
            buttons[i]:SetHitRectInsets(0, buttons[i]:GetWidth() - maxWidth, 0, 0);
        end
        return maxWidth
    end
end


NarciDarkSquareButtonMixin = {};

function NarciDarkSquareButtonMixin:OnLoad()
    self.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Buttons\\Button-RoundedSquare", nil, nil, "TRILINEAR");
end

function NarciDarkSquareButtonMixin:Initialize(groupIndex, icon, texCoord, tooltip, onClickFunc)
    if tooltip then
        self.tooltip = tooltip;
    end

    if icon then
        self.Icon:SetTexture(icon, nil, nil, "TRILINEAR");
        if texCoord then
            self.Icon:SetTexCoord( unpack(texCoord) );
        end
    end

    if groupIndex then
        self.groupIndex = groupIndex;
        local parent = self:GetParent();
        if not parent.buttonGroups then
            parent.buttonGroups = {};
        end
        if not parent.buttonGroups[groupIndex] then
            parent.buttonGroups[groupIndex] = {};
        end
        tinsert(parent.buttonGroups[groupIndex], self);
    end

    if onClickFunc then
        self.onClickFunc = onClickFunc;
    end
end

function NarciDarkSquareButtonMixin:OnClick()
    self:UpdateVisual();
    if self.onClickFunc then
        self.onClickFunc();
    end
end

function NarciDarkSquareButtonMixin:UpdateVisual()
    if self.groupIndex then
        local button;
        local buttons = self:GetParent().buttonGroups[self.groupIndex];
        for i = 1, #buttons do
            button = buttons[i];
            if self ~= button then
                button:Deselect();
            end
        end
    end
    self:Select();
end

function NarciDarkSquareButtonMixin:OnEnter()
    self.Icon:SetAlpha(1);
end

function NarciDarkSquareButtonMixin:OnLeave()
    if not self.isSelected then
        self.Icon:SetAlpha(0.5);
    end
end

function NarciDarkSquareButtonMixin:OnMouseDown()
    self.PushedHighlight:Show();
end

function NarciDarkSquareButtonMixin:OnMouseUp()
    self.PushedHighlight:Hide();
end

function NarciDarkSquareButtonMixin:Select()
    self.Background:SetTexCoord(0.25, 0.5, 0, 1);
    self.Icon:SetAlpha(1);
    self.isSelected = true;
end

function NarciDarkSquareButtonMixin:Deselect()
    self.Background:SetTexCoord(0, 0.25, 0, 1);
    self.Icon:SetAlpha(0.5);
    self.isSelected = nil;
end

-----------------------------------------------------------
--Clipboard
NarciClipboardMixin = {};

function NarciClipboardMixin:OnLoad()
    self.Tooltip:SetText(Narci.L["Copied"]);
end

function NarciClipboardMixin:SetText(text)
    self.EditBox:SetText(text);
end

function NarciClipboardMixin:SetFocus()
    self.EditBox:SetFocus();
end

function NarciClipboardMixin:ClearFocus()
    self.EditBox:ClearFocus();
end

function NarciClipboardMixin:ShowClipboard()
    self:Show();
    self.EditBox:Show();
    self:StopAnimating();
    self.Tooltip:SetAlpha(0);
end

function NarciClipboardMixin:HasFocus()
    return self.EditBox.hasFocus;
end


function NarciClipboardMixin:ReAnchorTooltipToObject(object)
    if object then
        self.Tooltip:ClearAllPoints();
        self.Tooltip:SetPoint("CENTER", object, "CENTER", 0, 0);
    end
end


NarciNonEditableEditBoxMixin = {};

function NarciNonEditableEditBoxMixin:OnLoad()

end

function NarciNonEditableEditBoxMixin:OnEditFocusGained()
    self.hasFocus = true;
    self:SelectText();
end

function NarciNonEditableEditBoxMixin:OnEditFocusLost()
    self.hasFocus = nil;
    self:Quit();
end

function NarciNonEditableEditBoxMixin:SelectText()
    self:SetCursorPosition(self.defaultCursorPosition or 0);
    self:HighlightText();
end

function NarciNonEditableEditBoxMixin:OnHide()
    self:StopAnimating();
end

function NarciNonEditableEditBoxMixin:Quit()
    self:ClearFocus();
    if self.onQuitFunc then
        self.onQuitFunc();
    end
end

function NarciNonEditableEditBoxMixin:OnTextChanged(isUserInput)
    if isUserInput then
        self:Quit();
    end
end

function NarciNonEditableEditBoxMixin:OnKeyDown(key, down)
    local keys = CreateKeyChordStringUsingMetaKeyState(key);
    if keys == "CTRL-C" or key == "COMMAND-C" then
        self.hasCopied = true;
        After(0, function()
            self:GetParent().Tooltip.good:Play();
            self:Hide();
        end);
    end
end

-----------------------------------------------------------
NarciLanguageUtil = {};
NarciLanguageUtil.wowheadLinkPrefix = {
    ["default"] = "www",
    ["deDE"] = "de",
    ["esES"] = "es",
    ["esMX"] = "es",
    ["frFR"] = "fr",
    ["itIT"] = "it",
    ["ptBR"] = "pt",
    ["ruRU"] = "ru",
    ["koKR"] = "ko",
    ["zhCN"] = "cn",
    ["zhTW"] = "cn",
};

NarciLanguageUtil.wowheadLinkPrefix.primary = NarciLanguageUtil.wowheadLinkPrefix[TEXT_LOCALE] or "www";

function NarciLanguageUtil:GetWowheadLink(specificLanguage)
    local prefix;
    if specificLanguage then
        prefix = self.wowheadLinkPrefix[ tostring(specificLanguage) ] or "www";
    else
        prefix = self.wowheadLinkPrefix.primary;
    end
    return ( "https://".. prefix .. ".wowhead.com/");
end


local function GetAllSelectedTalentIDsAndIcons(ignorePlayerLevel)
    local talentInfo = {}
    local maxTiers;
    if ignorePlayerLevel then
        maxTiers = 7;
    else
        maxTiers = GetMaxTalentTier();    --based on the character's level
    end
    local talentGroup = GetActiveSpecGroup();
    local _, _, classID = UnitClass("player");
    talentInfo.classID = classID;

    if not talentGroup then
        talentInfo.talentGroup = false;
        return;
    else
        talentInfo.talentGroup = talentGroup;
    end

    local column, tierUnlockLevel, talentID, iconTexture, selected;
    for tier = 1, maxTiers do
        _, column, tierUnlockLevel = GetTalentTierInfo(tier, talentGroup);
        if column then
            talentID, _, iconTexture, selected = GetTalentInfo(tier, column, talentGroup);
            talentInfo[tier] = {talentID, iconTexture, tierUnlockLevel};
        else
            talentInfo[tier] = {false, 134400};     --Question Mark Icon
        end
    end

    return talentInfo
end

NarciAPI.GetAllSelectedTalentIDsAndIcons = GetAllSelectedTalentIDsAndIcons;


local function CreateColor(r, g, b)
    return RoundToDigit(r/255, 4), RoundToDigit(g/255, 4), RoundToDigit(b/255, 4);
end

NarciAPI.CreateColor = CreateColor;


local timeStartNarcissus;
local function UpdateSessionTime()
    local t = time();
    if timeStartNarcissus then
        local session = t - timeStartNarcissus;
        local timeSpent = NarciStatisticsDB.TimeSpentInNarcissus;
        if not timeSpent or type(timeSpent) ~= "number" then
            timeSpent = 0;
        end
        NarciStatisticsDB.TimeSpentInNarcissus = timeSpent + session;
        timeStartNarcissus = nil;
    else
        timeStartNarcissus = t;
    end
end

NarciAPI.UpdateSessionTime = UpdateSessionTime;


local function UpdateScreenshotsCounter()
    if Narci.isActive then
        local numTaken = NarciStatisticsDB.ScreenshotsTakenInNarcissus;
        if not numTaken or type(numTaken) ~= "number" then
            numTaken = 0;
        end
        NarciStatisticsDB.ScreenshotsTakenInNarcissus = numTaken + 1;
    end
end

NarciAPI.UpdateScreenshotsCounter = UpdateScreenshotsCounter;

local function GetClassColorByClassID(classID)
    local classInfo = classID and C_CreatureInfo.GetClassInfo(classID);
    if classInfo then
        return C_ClassColor.GetClassColor(classInfo.classFile);
    end
end

local function WrapNameWithClassColor(name, classID, specID, showIcon, offsetY)
    local classInfo = C_CreatureInfo.GetClassInfo(classID);
    if classInfo then
        local color = GetClassColorByClassID(classID);
        if color then
            if specID and showIcon then
                local str = color:WrapTextInColorCode(name);
                local _, _, _, icon, role = GetSpecializationInfoByID(specID);
                if icon then
                    offsetY = offsetY or 0;
                    str = "|T"..icon..":12:12:-1:"..offsetY..":64:64:4:60:4:60|t" ..str;
                end
                return str
            else
                return color:WrapTextInColorCode(name);
            end
        else
            return name
        end
    else
        return name
    end
end

NarciAPI.GetClassColorByClassID = GetClassColorByClassID;
NarciAPI.WrapNameWithClassColor = WrapNameWithClassColor;


local function GetOutfitSlashCommand()
	local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
	local itemTransmogInfoList = playerActor and playerActor:GetItemTransmogInfoList();
    local slashCommand = TransmogUtil.CreateOutfitSlashCommand(itemTransmogInfoList);
    return slashCommand
end

NarciAPI.GetOutfitSlashCommand = GetOutfitSlashCommand;


NarciAPI.GetScreenPixelSize = function()
    return 768 / SCREEN_HEIGHT
end


local function PixelPerfectDriver_Update(self)
    local scale = self:GetParent():GetEffectiveScale();

    if scale == self.scale then
        return
    else
        self.scale = scale;
    end

    local p = 768 / SCREEN_HEIGHT / scale;

    for i, tex in ipairs(self.textures) do
        if tex.w then
            tex:SetWidth(p * tex.w);
        end
        if tex.h then
            tex:SetHeight(p * tex.h);
        end
    end
end

local function AddPixelPerfectTexture(frame, texture, pixelWidth, pixelHeight)
    if not frame.pixelDriver then
        frame.pixelDriver= CreateFrame("Frame", nil, frame);
        frame.pixelDriver.textures = {};
        frame.pixelDriver:SetScript("OnShow", PixelPerfectDriver_Update);
    end
    texture.w = pixelWidth;
    texture.h = pixelHeight;

    --[[
    for i, obj in ipairs(frame.pixelDriver.textures) do
        if obj == texture then
            return
        end
    end
    --]]
    tinsert(frame.pixelDriver.textures, texture);
end

NarciAPI.AddPixelPerfectTexture = AddPixelPerfectTexture;

local function SetFramePointPixelPerfect(frame, point, relativeTo, relativePoint, offsetX, offsetY)
    if relativeTo then
        local pixel = GetPixelForWidget(frame);
        frame:ClearAllPoints();
        local right0 = relativeTo:GetRight();
        local right1 = floor( (right0 + offsetX) * pixel + 0.5) / pixel;
        local top0 = relativeTo:GetTop();
        local top1 = floor( (top0 + offsetY) * pixel) / pixel;
        frame:SetPoint(point, relativeTo, relativePoint, right1 - right0, top1 - top0);
    end
end

NarciAPI.SetFramePointPixelPerfect = SetFramePointPixelPerfect;


local function IsPlayerAtMaxLevel()
    local playerLevel = UnitLevel("player") or 0;

    local maxPlayerLevel;
    if GetMaxLevelForLatestExpansion then
        maxPlayerLevel = GetMaxLevelForLatestExpansion();
    else
        local expansionLevel = GetExpansionLevel() or 0;
        maxPlayerLevel = GetMaxLevelForExpansionLevel(expansionLevel);
    end

    return playerLevel >= maxPlayerLevel;
end

NarciAPI.IsPlayerAtMaxLevel = IsPlayerAtMaxLevel;


do
    local IsInteractingWithNpcOfType = C_PlayerInteractionManager.IsInteractingWithNpcOfType;
    local TYPE_GOSSIP = Enum.PlayerInteractionType and Enum.PlayerInteractionType.Gossip or 3;
    local TYPE_QUEST_GIVER = Enum.PlayerInteractionType and Enum.PlayerInteractionType.QuestGiver or 4;
    local GetQuestID = GetQuestID;
    local ItemTextGetItem = ItemTextGetItem;
    local INTERACT_RECENELY = false;

    local function IsInteractingWithDialogNPC()
        if INTERACT_RECENELY then return true end;

        local currentQuestID = GetQuestID();
        return IsInteractingWithNpcOfType(TYPE_GOSSIP) or IsInteractingWithNpcOfType(TYPE_QUEST_GIVER) or (currentQuestID ~= nil and currentQuestID ~= 0) or (ItemTextGetItem() ~= nil)
    end
    addon.IsInteractingWithDialogNPC = IsInteractingWithDialogNPC;

    local DialogEventHandler;

    local function DialogEventHandler_Check()
        if C_AddOns.IsAddOnLoaded("DialogueUI") then
            local events = {
                "GOSSIP_SHOW", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_GREETING",
            };

            DialogEventHandler = CreateFrame("Frame");

            for _, event in ipairs(events) do
                DialogEventHandler:RegisterEvent(event)
            end

            local function OnUpdate(self, elapsed)
                self.t = self.t + elapsed;
                if self.t >= 1 then
                    self:SetScript("OnUpdate", nil);
                    self.t = nil;
                    INTERACT_RECENELY = false;
                end
            end

            DialogEventHandler:SetScript("OnEvent", function(self, event, ...)
                self.t = 0;
                INTERACT_RECENELY = true;
                self:SetScript("OnUpdate", OnUpdate);
            end);
        end
    end

    addon.AddLoadingCompleteCallback(DialogEventHandler_Check);
end

do
    local BindHelper;

    local BindEvents = {
        "ACTION_WILL_BIND_ITEM",
        "EQUIP_BIND_REFUNDABLE_CONFIRM",
        "EQUIP_BIND_TRADEABLE_CONFIRM",
        "EQUIP_BIND_CONFIRM",
        "END_BOUND_TRADEABLE",
    };

    local function HideStaticPopup()
        if StaticPopup1 then
            StaticPopup1:Hide();
        end
    end

    local function ConfirmBinding()
        if not BindHelper then
            BindHelper = CreateFrame("Frame");
            BindHelper:Hide();

            BindHelper:SetScript("OnEvent", function(self, event, ...)
                if event == "ACTION_WILL_BIND_ITEM" then
                    if self.pending then
                        self.pending = nil;
                        C_Item.ActionBindsItem();
                    end
                elseif event == "EQUIP_BIND_REFUNDABLE_CONFIRM" or event == "EQUIP_BIND_TRADEABLE_CONFIRM" or event == "EQUIP_BIND_CONFIRM" then
                    if self.pending then
                        self.pending = nil;
                        local slot = ...
                        EquipPendingItem(slot);
                    end
                elseif event == "END_BOUND_TRADEABLE" then
                    if self.pending then
                        self.pending = nil;
                        local reason = ...
                        C_Item.EndBoundTradeable(reason);
                    end
                end

                HideStaticPopup();

                for _, v in ipairs(BindEvents) do
                    self:UnregisterEvent(v);
                end
            end);

            BindHelper:SetScript("OnUpdate", function(self, elapsed)
                self.t = self.t + elapsed;
                if self.t > 0.5 then
                    self.t = nil;
                    self.pending = nil;
                    self:Hide();
                    for _, v in ipairs(BindEvents) do
                        self:UnregisterEvent(v);
                    end
                end
            end);
        end

        for _, v in ipairs(BindEvents) do
            BindHelper:RegisterEvent(v);
        end

        BindHelper.t = 0;
        BindHelper.pending = true;
        BindHelper:Show();
    end
    addon.ConfirmBinding = ConfirmBinding;
end

local function DoesItemExistByID(itemID)
    itemID = GetItemInfoInstant(itemID)
    return itemID ~= nil
end
addon.DoesItemExistByID = DoesItemExistByID;

local function CopyTable(tbl)
    --Blizzard TableUtil.lua
    if not tbl then return; end;
	local copy = {};
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = CopyTable(v);
		else
			copy[k] = v;
		end
	end
	return copy;
end
addon.CopyTable = CopyTable;

do
    local SOUND_FILE_ID = 567520;
    local MuteSoundFile = MuteSoundFile;
    local UnmuteSoundFile = UnmuteSoundFile;

    local function MuteTargetLostSound(state)
        if state then
            MuteSoundFile(SOUND_FILE_ID);
        else
            UnmuteSoundFile(SOUND_FILE_ID);
        end
    end
    NarciAPI.MuteTargetLostSound = MuteTargetLostSound;
end

do  --11.0 Menu Formatter
    function NarciAPI.TranslateContextMenu(ownerRegion, schematic, contextData)
        --Currently we only use this function to create a minimap menu.
        --Owner is set to UIParent so when the mini button is hidden by addon manager, the menu won't hide with it.
        ownerRegion = UIParent;

        local menu = MenuUtil.CreateContextMenu(ownerRegion, function(ownerRegion, rootDescription)
            rootDescription:SetTag(schematic.tag, contextData);

            for _, info in ipairs(schematic.objects) do
                local elementDescription;
                if info.type == "Title" then
                    elementDescription = rootDescription:CreateTitle();
                    elementDescription:AddInitializer(function(f, description, menu)
                        f.fontString:SetText(info.name);
                    end);
                elseif info.type == "Divider" then
                    elementDescription = rootDescription:CreateDivider();
                elseif info.type == "Spacer" then
                    elementDescription = rootDescription:CreateSpacer();
                elseif info.type == "Button" then
                    elementDescription = rootDescription:CreateButton(info.name, info.OnClick);
                elseif info.type == "Checkbox" then
                    elementDescription = rootDescription:CreateCheckbox(info.name, info.IsSelected, info.ToggleSelected);
                end

                if info.tooltip then
                    elementDescription:SetTooltip(function(tooltip, elementDescription)
                        GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
                        GameTooltip_AddNormalLine(tooltip, info.tooltip);
                        --GameTooltip_AddInstructionLine(tooltip, "Test Tooltip Instruction");
                        --GameTooltip_AddErrorLine(tooltip, "Test Tooltip Colored Line");
                    end);
                end

                if info.rightText then
                    local rightText;
                    if type(info.rightText) == "function" then
                        rightText = info.rightText();
                    else
                        rightText = info.rightText;
                    end
                    elementDescription:AddInitializer(function(button, description, menu)
                        --local rightTexture = button:AttachTexture();
                        --rightTexture:SetSize(18, 18);
                        --rightTexture:SetPoint("RIGHT");
                        --rightTexture:SetTexture(nil);

                        local fontString = button.fontString;
                        fontString:SetTextColor(NORMAL_FONT_COLOR:GetRGB());

                        local fontString2 = button:AttachFontString();
                        fontString2:SetHeight(20);
                        fontString2:SetPoint("RIGHT", button, "RIGHT", 0, 0);
                        fontString2:SetJustifyH("RIGHT");
                        fontString2:SetText(rightText);
                        fontString2:SetTextColor(0.5, 0.5, 0.5);

                        local pad = 20;
                        local width = pad + fontString:GetWrappedWidth() + fontString2:GetWrappedWidth();

                        local height = 20;
                        return width, height;
                    end);
                end
            end
        end);

        if schematic.onMenuClosedCallback then
            menu:SetClosedCallback(schematic.onMenuClosedCallback);
        end

        return menu
    end
end

do  --Model Util
    local ModelUtil = {};
    ModelUtil.validDisplayIDs = {};
    ModelUtil.validFileIDs = {};

    function ModelUtil:CreateUitlityModel()
        local m = CreateFrame("CinematicModel", nil, UIParent);
        m:SetKeepModelOnHide(true);
        m:SetSize(2, 2);
        m:SetPoint("TOP", UIParent, "BOTTOM", 0, -3);
        m:Hide();
        return m
    end

    function NarciAPI.DoesCreatureDisplayIDExist(id)
        if not id then return false end;

        if not ModelUtil.displayModel then
            ModelUtil.displayModel = ModelUtil:CreateUitlityModel();
            ModelUtil.displayModel:SetScript("OnModelLoaded", function(self)
                local displayID = self:GetDisplayInfo();
                if displayID and displayID ~= 0 then
                    ModelUtil.validDisplayIDs[displayID] = true;
                end
                self:ClearModel();
            end);
        end

        if ModelUtil.validDisplayIDs[id] ~= nil then
            return ModelUtil.validDisplayIDs[id];
        else
            ModelUtil.displayModel:ClearModel();
            ModelUtil.displayModel:SetDisplayInfo(id);
        end
    end

    function NarciAPI.DoesModelFileExist(file)
        --Unused. Invalid file sometimes crash the game
        if (not file) or file == 0 then return false end;

        if not ModelUtil.fileModel then
            ModelUtil.fileModel = ModelUtil:CreateUitlityModel();
            ModelUtil.fileModel:SetScript("OnModelLoaded", function(self)
                local fileID = self:GetModelFileID();
                if fileID and fileID ~= 0 then
                    ModelUtil.validFileIDs[fileID] = true;
                end
                self:ClearModel();
            end);
        end

        if ModelUtil.validFileIDs[file] ~= nil then
            return ModelUtil.validFileIDs[file];
        else
            ModelUtil.fileModel:ClearModel();
            ModelUtil.fileModel:SetModel(file);
        end
    end
end

do  --AddOn Compatibility
    function NarciAPI.IsLeatrixMinimapEnabled()
        if C_AddOns.IsAddOnLoaded("Leatrix_Plus") then
            if LeaPlusDB and LeaPlusDB["MinimapModder"] == "On" then
                return true
            end
        end
        return false
    end
end

do  --Show GameTooltip After Delay
    local DGT = {};

    function DGT:Init()
        self.Init = nil;
        self.f = CreateFrame("Frame", nil, UIParent);
    end

    function DGT.OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t > self.delay then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            if self.object and self.object:IsMouseMotionFocus() and self.info then
                local tooltip = GameTooltip;
                local info = self.info;
                local descAdded = false;

                local point = info.point or "BOTTOMLEFT";
                local relativeTo = info.relativeTo or self.object;
                local relativePoint = info.relativePoint or "TOPRIGHT";
                local offsetX = info.offsetX or 0;
                local offsetY = info.offsetY or 0;

                tooltip:Hide();
                tooltip:SetOwner(self.object, "ANCHOR_NONE");
                tooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

                if info.title then
                    tooltip:SetText(info.title, info.titleR or 1, info.titleG or 1, info.titleB or 1, true);
                elseif info.tooltip then
                    tooltip:SetText(info.tooltip, info.r or 1, info.g or 1, info.b or 1, true);
                    descAdded = true;
                end

                if (not descAdded) and info.tooltip then
                    tooltip:AddLine(info.tooltip, info.r or 1, info.g or 0.82, info.b or 0, true);
                end

                if info.setupFunc then
                    info.setupFunc(tooltip);
                end

                tooltip:Show();
            end
            self.info = nil;
        end
    end

    function DGT.ShowTooltipAfterDelay(object, info)
        if object and info then
            if DGT.Init then
                DGT:Init();
            end
            local f = DGT.f;
            f.t = 0;
            f.object = object;
            f.info = info;
            f.delay = info.delay or 0.5;
            f:SetScript("OnUpdate", DGT.OnUpdate);
        else
            local f = DGT.f;
            if f then
                f:SetScript("OnUpdate", nil);
                f.t = 0;
                f.info = nil;
            end
            GameTooltip:Hide();
        end
    end
    NarciAPI.ShowTooltipAfterDelay = DGT.ShowTooltipAfterDelay;
end

do  --Scripts
    local ValidScripts = {
        "OnEnter", "OnLeave", "OnClick", "OnMouseDown", "OnMouseUp", "OnMouseWheel",
        "OnEscapePressed", "OnEnterPressed", "OnTabPressed", "OnEditFocusGained", "OnEditFocusLost", "OnTextChanged",
    };

    function PrivateAPI.MixScripts(object, scripts)
        for _, name in ipairs(ValidScripts) do
            if scripts[name] then
                object:SetScript(name, scripts[name]);
            end
        end
    end
end