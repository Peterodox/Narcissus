local _, addon = ...

local Gemma = {};
addon.Gemma = Gemma;
Gemma.dataProviders = {};

function Gemma:SetDataProvider(dataProvider)
    self.activeDataProvider = dataProvider;
end

function Gemma:SetDataProviderByName(name)
    self:SetDataProvider(self.dataProviders[name])
end

function Gemma:AddDataProvider(name, dataProvider)
    self.dataProviders[name] = dataProvider;
end

function Gemma:GetSortedItemList()
    return self.activeDataProvider:GetSortedItemList();
end