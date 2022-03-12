local _, addon = ...;
local GetItemCount = GetItemCount;

local gemData = {
    173127,     --Deadly Jewel Cluster
    173128,     --Quick Jewel Cluster
    173129,     --Versatile Jewel Cluster
    173130,     --Masterful Jewel Cluster

    173121,     --Deadly Jewel Doublet
    173122,     --Quick Jewel Doublet
    173123,     --Versatile Jewel Doublet
    173124,     --Masterful Jewel Doublet

    173125,     --**Revitalizing Jewel Doublet
    173126,     --**Straddling Jewel Doublet

    ----8 BFA----
    168636,     --Leviathan's Eye of Strength
    168637,     --Leviathan's Eye of Agility
    168638,     --Leviathan's Eye of Intellect

    168639,     --Deadly Lava Lazuli
    168640,     --Masterful Sea Currant
    168641,     --Quick Sand Spinel
    168642,     --Versatile Dark Opal
    169220,     --***Straddling Sage Agate

    154126,     --Deadly Amberblaze
    154127,     --Quick Owlseye
    154128,     --Versatile Royal Quartz
    154129,     --Masterful Tidal Amethyst

    153707,     --Kraken's Eye of Strength
    153708,     --Kraken's Eye of Agility
    153709,     --Kraken's Eye of Intellect

    153710,     --Deadly Solstone
    153711,     --Quick Golden Beryl
    153712,     --Versatile Kyanite
    153713,     --Masterful Kubiline
    153714,      --***Insightful Rubellite
    153715,     --***Straddling Viridium
};

local shardData = {
    187079,     --Zed R1    Healing
    187292,     --Zed R2
    187301,     --Zed R3
    187310,     --Zed R4
    187320,     --Zed R5

    187076,     --Oth R1    Tertiary
    187291,     --Oth R2
    187300,     --Oth R3
    187309,     --Oth R4
    187319,     --Oth R5

    187073,     --Dyz R1    Offensive
    187290,     --Dyz R2
    187299,     --Dyz R3
    187308,     --Dyz R4
    187318,     --Dyz R5

    --Frost
    187071,     --Tel R1    Healing
    187289,     --Tel R2
    187298,     --Tel R3
    187307,     --Tel R4
    187317,     --Tel R5

    187065,     --Kyr R1    Defensive
    187288,     --Kyr R2
    187297,     --Kyr R3
    187306,     --Kyr R4
    187316,     --Kyr R5

    187063,     --Cor R1    Offensive
    187287,     --Cor R2
    187296,     --Cor R3
    187305,     --Cor R4
    187315,     --Cor R5

    --Blood
    187061,     --Rev R1    Tertiary
    187286,     --Rev R2
    187295,     --Rev R3
    187304,     --Rev R4
    187314,     --Rev R5

    187059,     --Jas R1    Healing
    187285,     --Jas R2
    187294,     --Jas R3
    187303,     --Jas R4
    187313,     --Jas R5

    187057,     --Bek R1    Offensive
    187284,     --Bek R2
    187293,     --Bek R3
    187302,     --Bek R4
    187312,     --Bek R5
};

local cypherData = {
    --Crystallic Spheroid
    189723,
    189722,
    189732,
    189560,
    189763,
    189724,
    189725,
    189726,
    189762,
    189727,
    189728,
    189729,
    189730,
    189731,
    189764,
    189733,
    189734,
    189760,
    189761,
    189735,
};


local DataProvider = {};
addon.GemDataProvider = DataProvider;

DataProvider.filteredData = {};

local subset = {};

function DataProvider:SetSubset(dataSetID)
    self.isDominationItem = dataSetID == 2;
    if dataSetID == 1 then
        subset = gemData or {};
    elseif dataSetID == 2 then
        subset = shardData or {};
    elseif dataSetID == 3 then
        subset = cypherData or {};
    end
end

function DataProvider:ApplyFilter(ownedOnly)
    self.filteredData = {};
    local numData = 0;
    if ownedOnly then
        if self.isDominationItem then
            local startIndex = 5;
            local index;
            while startIndex <= 45 do
                for offset = 0, -4, -1 do
                    index = startIndex + offset;
                    if GetItemCount(shardData[index]) > 0 then
                        numData = numData + 1;
                        self.filteredData[numData] = shardData[index];
                        break
                    end
                end
                startIndex = startIndex + 5;
            end
        else
            for i = 1, #subset do
                if GetItemCount(subset[i]) > 0 then
                    numData = numData + 1;
                    self.filteredData[numData] = subset[i];
                end
            end
        end
        return numData
    else
        self.filteredData = subset;
        return #self.filteredData
    end
end

function DataProvider:GetDataByIndex(index)
    return self.filteredData[index];
end