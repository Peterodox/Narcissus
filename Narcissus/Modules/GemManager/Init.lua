local _, addon = ...

local Gemma = {};
addon.Gemma = Gemma;
Gemma.dataProviders = {};

function Gemma:SetDataProvider(dataProvider)
    self.activeDataProvider = dataProvider;
    return dataProvider
end

function Gemma:GetActiveSchematic()
    return self.activeDataProvider.schematic
end

function Gemma:GetActiveTabData()
    return self.activeDataProvider.schematic.tabData
end

function Gemma:SetDataProviderByName(name)
    return self:SetDataProvider(self.dataProviders[name])
end

function Gemma:AddDataProvider(name, dataProvider)
    self.dataProviders[name] = dataProvider;
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