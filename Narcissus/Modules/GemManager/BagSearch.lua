local _, addon = ...
local Gemma = addon.Gemma;

local GetContainerNumSlots = C_Container.GetContainerNumSlots;
local GetContainerItemLink = C_Container.GetContainerItemLink;

local BagSearch = {};
Gemma.BagSearch = BagSearch;

function BagSearch:SetProcessor(processItem)
    self.ProcessItem = processItem;
end

function BagSearch:AddOnStartCallback(callback)
    if not self.onStartCallbacks then
        self.onStartCallbacks = {};
    end

    table.insert(self.onStartCallbacks, callback);
end

function BagSearch:AddOnStopCallback(callback)
    if not self.onStopCallbacks then
        self.onStopCallbacks = {};
    end

    table.insert(self.onStopCallbacks, callback);
end

function BagSearch:OnStart()
    if self.onStartCallbacks then
        for i, callback in ipairs(self.onStartCallbacks) do
            callback();
        end
    end
end

function BagSearch:OnStop()
    if self.onStopCallbacks then
        for i, callback in ipairs(self.onStopCallbacks) do
            callback();
        end
    end
end

function BagSearch:OnBagChanged(bag)
	self.needsUpdate = true;
	self.bagDirty[bag] = true;
end

function BagSearch:ProcessItem(itemLink)

end

function BagSearch:ProcessBag(bag)
    local itemLink;

    for slot = 1, GetContainerNumSlots(bag) do
        itemLink = GetContainerItemLink(bag, slot);
        if itemLink then
            self:ProcessItem(itemLink);
        end
    end
end

function BagSearch:FullUpdate()
    self:OnStart();

    self.result = {};

    for bag = 0, 4 do
        self:ProcessBag(bag);
    end

    self:OnStop();
end