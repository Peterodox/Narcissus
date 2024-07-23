--Not Used

--Patch: 9.1.0
--Features: Shards of Domination (Special Gems)

--Determine items by itemIDs?
--or socket texture?

--https://www.wowhead.com/guides/sanctum-of-domination-raid-loot-chains-of-domination-9-1#accessories

local NUM_SHARDS_MAX = 5;
local COLOR_GREEN = "|cff20ff20";
local COLOR_DOMINATION = "|cff66bbff";

local unpack = unpack;
local After = C_Timer.After;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local ItemLocation = ItemLocation;
local DoesItemExist = C_Item.DoesItemExist;
local GetItemLink = C_Item.GetItemLink;
local GetItemID = C_Item.GetItemID;
local GetPlayerAuraBySpellID = GetPlayerAuraBySpellID;
local GetBestMapForUnit = C_Map.GetBestMapForUnit;
local GetMapInfo = C_Map.GetMapInfo;
local GetShardEffect = NarciAPI.GetDominationShardEffect;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;


local function IsZoneValidForDomination()
    --Shard of Domination is only functioning in the Maw since 9.2
    local mapID = GetBestMapForUnit("player");
    if mapID then
        if mapID == 1543 then
            return true
        end
        local info = GetMapInfo(mapID);
        if info and info.parentMapID and info.parentMapID == 1543 then
            return true
        end
    end
    return false
end

local function Mixin(object, mixin)
    for k, v in pairs(mixin) do
        object[k] = v;
    end
end

local SHARD_OF_DOMINATION = "Shard of Domination";

local dominationItems = {
    186287, 186325, 186324, 186286, 186320, 186282, 186322, 186284, 186283, 186321, --Cloth
    186330, 186292, 186298, 186336, 186296, 186334, 186295, 186333, 186363, 186337, 186299, --Leather
    186341, 186304, 186342, 186305, 186340, 186303, 186338, 186301, 186343, 186306, --Mail
    186350, 186315, 186314, 186349, 186347, 186312, 186316, 186351, 186369, 186346, 186311, --Plate

    --Sold by Death's Advance
    187538, 187539, 187540, 187541,

    --Sold by the Archivist
    187534, 187535, 187536, 187537,
};

local shardData = {
    --R2 Ominious     R3 Desolate     R4 Forboding     R5 Portentous

    --[itemID] = {typeID, rank, effectID},    typeID: 1 Unholy/ 2 Frost/ 3 Blood        effectID: 1 Healing(SHOW_COMBAT_HEALING) / 2 Defensive(ABSORB)/ 3 Tertiary(STAT_SPEED)/ 4 Tertiary(STAT_LIFESTEAL)/ 5 Offensive(CLUB_FINDER_DAMAGE)
    --Unholy
    [187079] = {2, 1, 6},     --Zed R1    Healing
    [187292] = {2, 2, 6},     --Zed R2
    [187301] = {2, 3, 6},     --Zed R3
    [187310] = {2, 4, 6},     --Zed R4
    [187320] = {2, 5, 6},     --Zed R5

    [187076] = {2, 1, 3},     --Oth R1    Tertiary
    [187291] = {2, 2, 3},     --Oth R2
    [187300] = {2, 3, 3},     --Oth R3
    [187309] = {2, 4, 3},     --Oth R4
    [187319] = {2, 5, 3},     --Oth R5

    [187073] = {2, 1, 5},     --Dyz R1    Offensive
    [187290] = {2, 2, 5},     --Dyz R2
    [187299] = {2, 3, 5},     --Dyz R3
    [187308] = {2, 4, 5},     --Dyz R4
    [187318] = {2, 5, 5},     --Dyz R5

    --Frost
    [187071] = {1, 1, 1},     --Tel R1    Healing
    [187289] = {1, 2, 1},     --Tel R2
    [187298] = {1, 3, 1},     --Tel R3
    [187307] = {1, 4, 1},     --Tel R4
    [187317] = {1, 5, 1},     --Tel R5

    [187065] = {1, 1, 2},     --Kyr R1    Defensive
    [187288] = {1, 2, 2},     --Kyr R2
    [187297] = {1, 3, 2},     --Kyr R3
    [187306] = {1, 4, 2},     --Kyr R4
    [187316] = {1, 5, 2},     --Kyr R5

    [187063] = {1, 1, 5},     --Cor R1    Offensive
    [187287] = {1, 2, 5},     --Cor R2
    [187296] = {1, 3, 5},     --Cor R3
    [187305] = {1, 4, 5},     --Cor R4
    [187315] = {1, 5, 5},     --Cor R5

    --Blood
    [187061] = {3, 1, 4},     --Rev R1    Tertiary
    [187286] = {3, 2, 4},     --Rev R2
    [187295] = {3, 3, 4},     --Rev R3
    [187304] = {3, 4, 4},     --Rev R4
    [187314] = {3, 5, 4},     --Rev R5

    [187059] = {3, 1, 1},     --Jas R1    Healing
    [187285] = {3, 2, 1},     --Jas R2
    [187294] = {3, 3, 1},     --Jas R3
    [187303] = {3, 4, 1},     --Jas R4
    [187313] = {3, 5, 1},     --Jas R5

    [187057] = {3, 1, 5},     --Bek R1    Offensive
    [187284] = {3, 2, 5},     --Bek R2
    [187293] = {3, 3, 5},     --Bek R3
    [187302] = {3, 4, 5},     --Bek R4
    [187312] = {3, 5, 5},     --Bek R5
};



Narci.DominationShards = shardData;

local shardEffects = {
    [1] = SHOW_COMBAT_HEALING,
    [2] = ABSORB,
    [3] = STAT_SPEED,
    [4] = STAT_LIFESTEAL,
    [5] = CLUB_FINDER_DAMAGE,
    [6] = DRAINS,
}

local shardTypes = {
    [1] = "Frost",
    [2] = "Unholy",
    [3] = "Blood",
};

local typeColors = {
    [1] = "C41E3A",
    [2] = "",
    [3] = "",
};

local shardSchool = {
    {name = "FROST", spellIcon = 135833, color = {66, 129, 220},
        spellIDs = {
            [1] = 355724,
            [2] = 359387,
            [3] = 359423,
            [4] = 359424,
            [5] = 359425,
        }
    },
    {name = "UNHOLY", spellIcon = 425955, color = {144, 33, 255},
        spellIDs = {
            [1] = 356046,
            [2] = 359396,
            [3] = 359435,
            [4] = 359436,
            [5] = 359437,
        }
    },
    {name = "BLOOD", spellIcon = 132096, color = {200, 28, 28},
        spellIDs = {
            [1] = 355768,
            [2] = 359395,
            [3] = 359420,
            [4] = 359421,
            [5] = 359422,
        }
    },
};

for k, v in pairs(shardSchool) do
    local name = _G["RUNE_COST_"..v.name];
    if name then
        name = string.gsub(name, "%%s", "");                --Remove %s
        name = string.gsub(name, "^%s*(.-)%s*$", "%1");     --Remove space
        v.localizedName = name;
    else
        v.localizedName = name;
    end
end

local function GetShardBonus(itemID)
    if itemID then
        local data = shardData[itemID];
        if data then
            return "|cff808080R"..data[2].."|r  ".. (shardEffects[ data[3] ] or "")
        end
    end
end

local function GetDominationBorderTexture(shardID)
    if shardID then
        local data = shardData[shardID];
        if data then
            return "Interface/AddOns/Narcissus/Art/GemBorder/Domination/"..(shardTypes[data[1]] or "Empty");
        end
    else
        return "Interface/AddOns/Narcissus/Art/GemBorder/Domination/Empty";
    end
end

local isDominationItem = {};

for _, id in pairs(dominationItems) do
    isDominationItem[id] = true;
end

dominationItems = nil;

local function DoesItemHaveDomationSocket(itemID)
    return isDominationItem[itemID]
end

local function GetItemDominationGem(itemLink)   --the old method is subjective to cache issue?
    if not itemLink then return; end

    local gemName;
    local gemID = string.match(itemLink, "item:%d+:%d*:(%d*)");
    if gemID then
        return "PH", tonumber(gemID);
    else
        return "Empty";
    end
end

local DataProvider = {};

function DataProvider:GetShardInfo(shard)
    --return type, rank
    if not shard then return 0, 0 end
    local itemID;
    if type(shard) == "string" then
        itemID = GetItemInfoInstant(shard);
    else
        itemID = shard;
    end
    if itemID and shardData[itemID] then
        return unpack(shardData[itemID]);
    else
        return 0, 0
    end
end

function DataProvider:GetShardTypeLocalizedName(shardType)
    return shardSchool[shardType].localizedName;
end

function DataProvider:GetBonusSpellInfo(shardType, rank)
    rank = rank or 1;
    local spellID = shardSchool[shardType].spellIDs[rank];
    if not spellID then return end;
    if C_Spell.IsSpellDataCached(spellID) then
        local name = GetSpellInfo(spellID);
        return name, GetSpellDescription(spellID);
    else
        C_Spell.RequestLoadSpellData(spellID);
    end
end

function DataProvider:GetHeaderText()
    return SHARD_OF_DOMINATION
end

local candidateSlots = {
    [1] = "Head",
    [3] = "Shoulder",
    [5] = "Chest",
    [6] = "Waist",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
};

local function SortFunc_Items(a,b)
    local typeA, rankA = DataProvider:GetShardInfo(a.gemLink);
    local typeB, rankB = DataProvider:GetShardInfo(b.gemLink);
    if typeA == typeB then
        if rankA == rankB then
            return a.slotID < b.slotID;
        else
            return rankA > rankB;
        end
    else
        return typeA < typeB
    end
end

local function GetEquippedDomiationGearData()
    local itemID, itemLink;
    local gemName, gemLink;
    local numItems = 0;
    local data = {};
    local itemLocation = ItemLocation:CreateEmpty();
    for slotID in pairs(candidateSlots) do
        itemLocation:SetEquipmentSlot(slotID);
        if DoesItemExist(itemLocation) then
            itemID = GetItemID(itemLocation);
            if DoesItemHaveDomationSocket(itemID) then
                numItems = numItems + 1;
                itemLink = GetItemLink(itemLocation);
                gemName, gemLink = GetItemDominationGem(itemLink);
                data[numItems] = {slotID = slotID, gemName = gemName, gemLink = gemLink};
            end
        end
    end
    if numItems > 0 then
        table.sort(data, SortFunc_Items);
        return data
    end
end

local SlotHighlighter = {};

function SlotHighlighter:Load()
    self.slots = {};
    self.highlights = {};
    for slotID, slotName in pairs(candidateSlots) do
        self.slots[slotID] = _G["Character"..slotName.."Slot"];
    end
    self.Load = nil;
end


function SlotHighlighter:HighlightSlot(slotID, shardType, shardRank)
    if self.Load then
        self:Load();
    end

    local slotButton = self.slots[slotID];
    if slotButton then
        local highlight = self.highlights[slotID];
        if not highlight then
            highlight = CreateFrame("Frame", nil, slotButton, "NarciDomimationItemHighlight");
            highlight:ClearAllPoints();
            highlight:SetPoint("TOPLEFT", slotButton, "TOPLEFT", -18, 18);
            highlight:SetPoint("BOTTOMRIGHT", slotButton, "BOTTOMRIGHT", 18, -18);
            local a = 2 * highlight:GetSize();
            highlight.BorderHighlight:SetSize(a, a);
            self.highlights[slotID] = highlight;
        end
        highlight:Set(shardType, shardRank);
        highlight:Shine();
    end
end

function SlotHighlighter:DehighlightAllSlots()
    if self.highlights then
        for k, highlight in pairs(self.highlights) do
            highlight:Hide();
        end
    end
end

function SlotHighlighter:HighlightAllSlots()
    self:DehighlightAllSlots();

    local itemData = GetEquippedDomiationGearData();
    if itemData then
        local itemLink, shardType, shardRank;
        for _, data in pairs(itemData) do
            itemLink = data.gemLink;
            shardType, shardRank = DataProvider:GetShardInfo(itemLink);
            SlotHighlighter:HighlightSlot(data.slotID, shardType, shardRank);
        end
    end
end


local function GetShardRectBorderTexCoord(itemSubClassID, shardID)
    if not shardID then
        return 0.875, 1
    end

    local shardType = DataProvider:GetShardInfo(shardID);
    if shardType == 1 then
        return 0.375, 0.5    --Blue
    elseif shardType == 2 then
        return 0.5, 0.625    --Purple
    elseif shardType == 3 then
        return 0.625, 0.75   --Red
    else
        return 0.875, 1    --Grey
    end
end

local function IsItemDominationShard(itemID)
    return not(shardData[itemID] == nil)
end


NarciAPI.GetDominationShardBonus = GetShardBonus;
NarciAPI.DoesItemHaveDomationSocket = DoesItemHaveDomationSocket;
NarciAPI.GetItemDominationGem = GetItemDominationGem;
NarciAPI.GetEquippedDomiationGearData = GetEquippedDomiationGearData;
NarciAPI.GetDominationBorderTexture = GetDominationBorderTexture;
NarciAPI.GetShardRectBorderTexCoord = GetShardRectBorderTexCoord;
NarciAPI.IsItemDominationShard = IsItemDominationShard;


---------------------------------------------------------------
NarciDominationItemHighlightMixin = {};

function NarciDominationItemHighlightMixin:Set(shardType, rank)
    local r, g, b;
    if shardType and shardSchool[shardType] then
        r, g, b = unpack(shardSchool[shardType].color);
        r, g, b = r/255, g/255, b/255;
    else
        shardType = 4;
        r, g, b = 1, 1, 1;
    end
    self.BorderHighlight:SetVertexColor(r, g, b);
    --self.BorderHighlight:SetTexCoord(0.25 * (shardType - 1), 0.25 * shardType, 0.5, 0.75);

    if rank and rank <= 5 then
        self.RankIndicator:Show();
        local texX, texY;
        if rank < 5 then
            texY = 0;
            texX = (rank - 1) * 0.25;
        else
            texY = 0.5;
            texX = (rank - 5) * 0.25;
        end
        self.RankIndicator:SetTexCoord(texX, texX + 0.25, texY, texY + 0.5);
        self.RankIndicator:SetVertexColor(r, g, b);
    else
        self.RankIndicator:Hide();
    end
end

function NarciDominationItemHighlightMixin:Shine()
    self:Show();
    self.BorderHighlight:Show();
    self.BorderHighlight.Shine:Stop();
    self.BorderHighlight.Shine:Play();
end




--Test

NarciAPI.HighlightDominationItems = function()
    SlotHighlighter:HighlightAllSlots();
end

--[[
GameTooltip:HookScript("OnTooltipSetItem", function(f)
    local name, link = f:GetItem();
    link = string.match(link, "item:([%-?%d:]+)")
    GameTooltip:AddLine(link);
    GameTooltip:Show();
end);


/script DEFAULT_CHAT_FRAME:AddMessage("\124cffa335ee\124Hitem:187284::::::::60:::::\124h[Ominous Shard of Bek]\124h\124r");
--]]

local ShardMixin = {};

function ShardMixin:Shine()

end

function ShardMixin:SetType(typeID)
    typeID = typeID or 4;   --4 is Empty
    if typeID == 0 then
        typeID = 4;
    end
    self:SetTexCoord(0.25 * (typeID - 1), 0.25 *typeID, 0, 1);
end


NarciDominationIndicatorMixin = {};

function NarciDominationIndicatorMixin:OnLoad()
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);

    NarciPaperDollWidgetController:AddWidget(self, 1);
end

function NarciDominationIndicatorMixin:ResetAnchor()
    self:ClearAllPoints();
    self:SetParent(self.parent);
    self:SetPoint("CENTER", self.parent, "CENTER", 0, 0);
end

function NarciDominationIndicatorMixin:OnEnter()
    local data = GetEquippedDomiationGearData();
    if not data then return end;

    local tooltip = GameTooltip;
	SharedTooltip_SetBackdropStyle(tooltip, GAME_TOOLTIP_BACKDROP_STYLE_RUNEFORGE_LEGENDARY);
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -10);
    tooltip:SetMinimumWidth(320);
    GameTooltip_AddBlankLineToTooltip(tooltip);
    local isFristLine = true;
    local itemLink, shardEffect, shardType, typeName, shardRank;
    local lastType = 0;
    local numData = #data;
    self:SetNodeLayout(numData);
    for i = 1, numData do
        itemLink = data[i].gemLink;
        shardEffect = GetShardEffect(itemLink);
        shardType, shardRank = DataProvider:GetShardInfo(itemLink);
        self.nodes[i]:SetType(shardType);
        if isFristLine then
            isFristLine = false;
            tooltip:SetText( DataProvider:GetHeaderText() );
            local completeTypeID = self.completeTypeID;
            if completeTypeID then
                local spellName, spellDescription = DataProvider:GetBonusSpellInfo(completeTypeID, self.setBonusRank);
                if spellName and spellDescription then
                    tooltip:AddLine(spellName, 1, 1, 1, true);
                    if self.setBonusRank then
                        tooltip:AddLine(COLOR_DOMINATION.."Rank "..self.setBonusRank.."|r", 1, 1, 1, true);
                    end
                    tooltip:AddLine(spellDescription, 0.1255, 1, 0.1255, true);
                else
                    After(0.25, function()
                        if self:IsMouseOver() then
                            self:OnEnter();
                        end
                    end)
                end
            end
            if self.numEmpty then
                tooltip:AddLine(self.numEmpty.. " "..EMPTY.." " .. EMPTY_SOCKET_DOMINATION, 0.5, 0.5, 0.5, true);
            end
        end
        if shardType ~= 0 and shardType ~= lastType then
            lastType = shardType;
            typeName = DataProvider:GetShardTypeLocalizedName(shardType);
            GameTooltip_AddBlankLineToTooltip(tooltip);
            tooltip:AddLine(typeName, 1, 1, 1, true);
        end
        if shardEffect then
            tooltip:AddLine(COLOR_DOMINATION.."Rank "..shardRank.."|r  "..shardEffect, 0.8, 0.8, 0.8, true, 0);
        end

        --Highlight Slot
        SlotHighlighter:HighlightSlot(data[i].slotID, shardType, shardRank);
    end

    tooltip:Show();
    self.Highlight:Show();
    self:CheckSetBonus();
end

function NarciDominationIndicatorMixin:OnLeave()
    GameTooltip:Hide();
    SlotHighlighter:DehighlightAllSlots();
    self.Highlight:Hide();
end

function NarciDominationIndicatorMixin:OnShow()

end

function NarciDominationIndicatorMixin:OnHide()

end

function NarciDominationIndicatorMixin:IsNarcissusUI()
    local id = self:GetID();
    return (id and id == 1)
end

function NarciDominationIndicatorMixin:Update()
    local data;

    if IsZoneValidForDomination() then
        data = GetEquippedDomiationGearData();
        if data then
            self:Show();
        else
            self:Hide();
            return false
        end
    else
        self:Hide();
        return false
    end

    local numShards = #data;
    self:SetNodeLayout(numShards);
    self.completeTypeID = nil;
    self.setBonusRank = nil;
    local itemLink, shardEffect, shardType, shardRank;
    local lastType;
    local numSetPiece = 0;
    local numEmpty = 0;
    local minRank = 5;
    for i = 1, numShards do
        itemLink = data[i].gemLink;
        shardEffect = GetShardEffect(itemLink);            --Load Data
        shardType, shardRank = DataProvider:GetShardInfo(itemLink);
        self.nodes[i]:SetType(shardType);
        if shardType == 0 then
            numEmpty = numEmpty + 1;
        else
            if shardType ~= lastType then
                numSetPiece = 1;
                lastType = shardType;
                minRank = 5;
                if shardRank < minRank then
                    minRank = shardRank;
                end
            else
                numSetPiece = numSetPiece + 1;
                if shardRank < minRank then
                    minRank = shardRank;
                end
                if numSetPiece >= 3 then
                    self.completeTypeID = shardType;
                    self.setBonusRank = minRank;
                end
            end
        end
    end
    if numEmpty > 0 then
        self.numEmpty = numEmpty;
    else
        self.numEmpty = nil;
    end
    self:CheckSetBonus();

    return true;
end

function NarciDominationIndicatorMixin:ShowTooltip(tooltip, point, relativeTo, relativePoint, offsetX, offsetY)
    local data = GetEquippedDomiationGearData();
    if not data or not tooltip then return end;

	SharedTooltip_SetBackdropStyle(tooltip, GAME_TOOLTIP_BACKDROP_STYLE_RUNEFORGE_LEGENDARY);
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    tooltip:SetMinimumWidth(320);
    GameTooltip_AddBlankLineToTooltip(tooltip);
    local isFristLine = true;
    local itemLink, shardEffect, shardType, typeName, shardRank;
    local lastType = 0;
    local numData = #data;
    for i = 1, numData do
        itemLink = data[i].gemLink;
        shardEffect = GetShardEffect(itemLink);
        shardType, shardRank = DataProvider:GetShardInfo(itemLink);
        if isFristLine then
            isFristLine = false;
            tooltip:SetText( DataProvider:GetHeaderText() );
            local completeTypeID = self.completeTypeID;
            if completeTypeID then
                local spellName, spellDescription = DataProvider:GetBonusSpellInfo(completeTypeID, self.setBonusRank);
                if spellName and spellDescription then
                    tooltip:AddLine(spellName, 1, 1, 1, true);
                    if self.setBonusRank then
                        tooltip:AddLine(COLOR_DOMINATION.."Rank "..self.setBonusRank.."|r", 1, 1, 1, true);
                    end
                    tooltip:AddLine(spellDescription, 0.1255, 1, 0.1255, true);
                else
                    After(0.25, function()
                        if self:IsMouseOver() then
                            self:ShowTooltip(tooltip, point, relativeTo, relativePoint, offsetX, offsetY);
                        end
                    end)
                end
            end
            if self.numEmpty then
                tooltip:AddLine(self.numEmpty.. " "..EMPTY.." " .. EMPTY_SOCKET_DOMINATION, 0.5, 0.5, 0.5, true);
            end
        end
        if shardType ~= 0 and shardType ~= lastType then
            lastType = shardType;
            typeName = DataProvider:GetShardTypeLocalizedName(shardType);
            GameTooltip_AddBlankLineToTooltip(tooltip);
            tooltip:AddLine(typeName, 1, 1, 1, true);
        end
        if shardEffect then
            tooltip:AddLine(COLOR_DOMINATION.."Rank "..shardRank.."|r  "..shardEffect, 0.8, 0.8, 0.8, true, 0);
        end
    end
    tooltip:Show();
end

local nodeLayout = {
    [1] = {0},
    [2] = {1, -1},
    [3] = {2, 0, -2},
    [4] = {2, 1, -1, -2},
    [5] = {2, 1, 0, -1, -2},
};

function NarciDominationIndicatorMixin:SetNodeLayout(numShards)
    if not self.nodes then
        self.nodes = {};
    end
    local isNarcissus = self:IsNarcissusUI();
    if numShards > 0 then
        local layout = nodeLayout[numShards];
        if not layout then return end;
        local node;
        local pi2 = 2 * math.pi;
        for i = 1, numShards do
            node = self.nodes[i];
            if not node then
                node = self:CreateTexture(nil, "OVERLAY", "NarciDominationIndicatorNodeTemplate", 5);
                node:ClearAllPoints();
                node:SetPoint("CENTER", self, "CENTER", 0, 0);
                local a = self:GetWidth();
                node:SetSize(a/2, a);
                if isNarcissus then
                    node:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\Domination\\ShardNode");
                else
                    node:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\Domination\\ShardNodeTiny");
                end
                Mixin(node, ShardMixin);
                node:SetType(4);
                self.nodes[i] = node;
            end
            node:SetRotation(layout[i]/6 * pi2);
            node:Show();
        end

        for i = numShards + 1, #self.nodes do
            self.nodes[i]:Hide();
        end
    else
        for i = 1, #self.nodes do
            self.nodes[i]:Hide();
        end
    end
end


function NarciDominationIndicatorMixin:CheckSetBonus()
    local setID = self.completeTypeID;
    if setID then
        local icon = shardSchool[setID].spellIcon;
        if self.IconBorder then
            self.IconBorder:Show();
        else
            self.Background:SetTexCoord(0.25, 0.5, 0, 0.25);
        end
        self.SpellIcon:Show();
        self.SpellIcon:SetTexture(icon);
        local _, isBonusActive = GetPlayerAuraBySpellID(355752);    --Runic Dominion Maw & Torghast
        if isBonusActive then
            self.SpellIcon:SetVertexColor(1, 1, 1);
            self.SpellIcon:SetDesaturated(false);
        else
            self.SpellIcon:SetVertexColor(0.6, 0.6, 0.6);
            self.SpellIcon:SetDesaturated(true);
        end
    else
        if self.IconBorder then
            self.IconBorder:Hide();
        else
            self.Background:SetTexCoord(0, 0.25, 0, 0.25);
        end
        self.SpellIcon:Hide();
    end
end



----No Effect Alert for Patch 9.2----

NarciDominationNoEffectAlertMixin = {};

function NarciDominationNoEffectAlertMixin:OnLoad()
    self.Header:SetTextColor(214/255, 31/255, 38/255);
    self.Header:SetText(Narci.L["No Service"]); --AB1 are disabled outside B33
    self:SetText(Narci.L["Shards Disabled"]);
    self:RegisterForDrag("LeftButton");

    local wave;
    for i = 1, 6 do
        wave = self:CreateTexture(nil, "ARTWORK", "NarciDominationAlertWaveTexture");
        wave:ClearAllPoints();
        wave:SetPoint("CENTER", self.BackgroundLeft, "CENTER", 0, 5);
    end

    NarciAPI.NineSliceUtil.SetUp(self, "shadowLargeR0", "border");
end

function NarciDominationNoEffectAlertMixin:OnMouseDown(button)
    self:Hide();
end

function NarciDominationNoEffectAlertMixin:PlayIntro()
    self:StopAnimating();
    self.AnimIn:Play();
    for i = 1, #self.Waves do
        self.Waves[i].Anim:SetLooping("NONE");
        self.Waves[i]:Hide();
    end
    self:Show();
end

function NarciDominationNoEffectAlertMixin:PlayWaves()
    local function ClearDelay(f)
        f.A1:SetStartDelay(0);
        f.S1:SetStartDelay(0);
        f:SetScript("OnFinished", nil);
        f:SetLooping("REPEAT");
        f:Play();
    end

    local delay = 0.3;
    local offset = 0;
    local wave;
    for i = 1, #self.Waves do
        wave = self.Waves[i];
        wave:ClearAllPoints();
        wave:SetPoint("CENTER", self.BackgroundLeft, "CENTER", 0, 5);
        wave.Anim:SetScript("OnFinished", ClearDelay);
        if i <= 3 then
            wave.Anim.A1:SetStartDelay((i - 1) * delay + offset);
            wave.Anim.S1:SetStartDelay((i - 1) * delay + offset);
        else
            wave:SetTexCoord(1, 0.5, 0.5, 1);
            wave.Anim.A1:SetStartDelay((i - 4) * delay + offset);
            wave.Anim.S1:SetStartDelay((i - 4) * delay + offset);
        end
        wave.Anim:Stop();
        wave:SetAlpha(0);
        wave.Anim:Play();
        wave:Show();
    end

    self.AnimText:Play();
end

function NarciDominationNoEffectAlertMixin:SetText(text)
    self.Text1:SetText(text);
    local textWidth = self.Text1:GetWidth();
    if textWidth > 160 then
        self.Text1:SetWidth(162);
        textWidth = self.Text1:GetWrappedWidth();
    end
    local textHeight = self.Header:GetHeight() + self.Text1:GetHeight() + 4;
    local offsetY = (64 - textHeight) * 0.5;
    self.Header:ClearAllPoints();
    self.Header:SetPoint("TOPLEFT", self.BackgroundLeft, "TOPRIGHT", 2, -offsetY);
    local rightWidth = textWidth + 2 + 16;
    self.BackgroundRight:SetWidth(rightWidth);
    self:SetWidth(64 + rightWidth);
end

function NarciDominationNoEffectAlertMixin:OnEnter()
	self.Highlight:Show();
    self.Highlight.Blink:Play();
    self.Highlight.Blink:SetLooping("REPEAT");
end

function NarciDominationNoEffectAlertMixin:OnLeave()
    self.Highlight.Blink:SetLooping("NONE");
end

function NarciDominationNoEffectAlertMixin:OnHide()
    self:Hide();
    self:StopAnimating();
    self:SetParent(nil);
    self:ClearAllPoints();
    Narci_Attribute:SetScript("OnShow", nil);
end

function NarciDominationNoEffectAlertMixin:OnShow()
    if self.onShowFunc then
        self.onShowFunc();
    end
end

function NarciDominationNoEffectAlertMixin:ShowAlert()
    if GetEquippedDomiationGearData() then
        if not IsZoneValidForDomination() then
            self:PlayIntro();
        end
    else
        self:OnShow();
    end
end