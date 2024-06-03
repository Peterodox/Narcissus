local _, addon = ...

local Gemma = {};
addon.Gemma = Gemma;
Gemma.dataProviders = {};


local GetItemCount = C_Item.GetItemCount;
local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown;
local GetActionInfo = GetActionInfo;
local HasExtraActionBar = HasExtraActionBar;
local GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots;
local GetExistingSocketInfo = GetExistingSocketInfo;
local GetNewSocketInfo = GetNewSocketInfo;


local GemData = {};


function Gemma:AddDataProvider(name, dataProvider)
    self.dataProviders[name] = dataProvider;
end

function Gemma:GetDataProviderByName(name)
    return self.dataProviders[name]
end

function Gemma:SetDataProvider(dataProvider)
    self.activeDataProvider = dataProvider;
    return dataProvider
end

function Gemma:SetDataProviderByName(name)
    return self:SetDataProvider(self.dataProviders[name])
end

function Gemma:GetActiveSchematic()
    return self.activeDataProvider.schematic
end

function Gemma:GetActiveTabData()
    return self.activeDataProvider.schematic.tabData
end

function Gemma:GetSortedItemList()
    return self.activeDataProvider:GetSortedItemList();
end

function Gemma:GetActiveMethods()
    return self.activeDataProvider.GemManagerMixin
end

function Gemma:GetGemSpell(itemID)
    if self.activeDataProvider.GetGemSpell then
        return self.activeDataProvider:GetGemSpell(itemID)
    end
end

function Gemma:GetActionButtonMethod(itemID)
    if self.activeDataProvider.GetActionButtonMethod then
        return self.activeDataProvider:GetActionButtonMethod(itemID)
    end
end

function Gemma:GetActiveGems()
    return self.activeDataProvider:GetActiveGems();
end

function Gemma:GetNumAvailableGemForStat(statType)
    return self.activeDataProvider:GetNumAvailableGemForStat(statType)
end

function Gemma:GetBestStatGemForAction(statType, direction)
    return self.activeDataProvider:GetBestStatGemForAction(statType, direction)
end

function Gemma:CanSwapGemInOneStep(itemID)
    return self.activeDataProvider:CanSwapGemInOneStep(itemID)
end

function Gemma:GetGemInventorySlotAndIndex(itemID)
    return self.activeDataProvider:GetGemInventorySlotAndIndex(itemID)
end

function Gemma:GetGemPositionInBagEquipment(itemID)
    return self.activeDataProvider:GetGemPositionInBagEquipment(itemID)
end

function Gemma:GetBestSlotToPlaceGem(itemID)
    return self.activeDataProvider:GetBestSlotToPlaceGem(itemID)
end

function Gemma:SetGemRemovalTool(gemItemID, tool)
    --tool = {type, id}; {"spell", spellID}, {"item", itemID}
    if not GemData[gemItemID] then
        GemData[gemItemID] = {};
    end

    GemData[gemItemID].removalTool = tool;
end

function Gemma:GetGemRemovalTool(gemItemID)
    return GemData[gemItemID] and GemData[gemItemID].removalTool
end

function Gemma:IsGemRemovable(gemItemID)
    local tool = self:GetGemRemovalTool(gemItemID);
    local canRemove, requirementMet;

    if tool then
        canRemove = true;
        local type = tool[1];
        if type == "spell" then
            local spellID = tool[2];
            requirementMet = IsSpellKnownOrOverridesKnown(spellID);
            if not requirementMet then
                if HasExtraActionBar() then
                    local actionType, id, subType = GetActionInfo(217); --ExtraActionButton
                    if actionType == "spell" and id == spellID then
                        requirementMet = true;
                    end
                end
            end
        elseif type == "item" then
            local count = GetItemCount(tool[2]);
            requirementMet = count and count > 0;
        end
    else
        canRemove = false;
        requirementMet = false;
    end

    return canRemove, requirementMet
end

function Gemma:DoesBagHaveFreeSlot()
    for bagIndex = 0, 4 do
        local numFreeSlots, bagType = GetContainerNumFreeSlots(bagIndex);
        if (numFreeSlots and numFreeSlots > 0) and (bagType == 0 or bagType == 10) then
            return true
        end
    end
end

function Gemma:DoesBagHaveEnoughSpace(requiredBagSpace)
    local totalFree = 0;

    for bagIndex = 0, 4 do
        local numFreeSlots, bagType = GetContainerNumFreeSlots(bagIndex);
        if (bagType == 0 or bagType == 10) then
            totalFree = totalFree + numFreeSlots;
        end
    end

    return totalFree >= requiredBagSpace
end

function Gemma.IsSocketOccupied(socketIndex)
    local a = GetExistingSocketInfo(socketIndex);
    local b = GetNewSocketInfo(socketIndex);
    return a or b
end