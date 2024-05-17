local _, addon = ...
local Gemma = addon.Gemma;
local CallbackRegistry = addon.CallbackRegistry;

local GetContainerNumSlots = C_Container.GetContainerNumSlots;
local GetContainerItemLink = C_Container.GetContainerItemLink;
local GetContainerItemID = C_Container.GetContainerItemID;
local GetInventoryItemLink = GetInventoryItemLink;
local GetItemGemID = C_Item.GetItemGemID;
local GetItemNumSockets = C_Item.GetItemNumSockets;
local IsEquippableItem = C_Item.IsEquippableItem;
local GetItemCount = C_Item.GetItemCount;


local BagScan = CreateFrame("Frame");
Gemma.BagScan = BagScan;

function BagScan:SetProcessor(processItem, equipmentSlots)
    self:SetScript("OnUpdate", nil);
    self.ProcessItem = processItem;
    self.equipmentSlots = equipmentSlots;
end

function BagScan:OnStart()
    CallbackRegistry:Trigger("GemManager.BagScan.OnStart");
end

function BagScan:OnStop()
    CallbackRegistry:Trigger("GemManager.BagScan.OnStop");
end

function BagScan:OnBagChanged(bag)
	self.bagChanged = true;
	self.bagDirty[bag] = true;
end
BagScan.bagChanged = true;

function BagScan:ProcessItem(_, itemLink, id1, id2)
    --id1, id2: bag, slot
    --id1, id2: inventorySlotID, nil
end

function BagScan:ProcessBag(bag)
    self.isProcessing = true;

    local itemLink;

    for slot = 1, GetContainerNumSlots(bag) do
        itemLink = GetContainerItemLink(bag, slot);
        if itemLink then
            self.ProcessItem(itemLink, bag, slot);
        end
    end
end

function BagScan:FullUpdate()
    if not self.bagChanged then return end;

    self:OnStart();

    for bag = 0, 4 do
        self:ProcessBag(bag);
    end

    if self.equipmentSlots then
        local itemLink;
        for _, slotID in ipairs(self.equipmentSlots) do
            itemLink = GetInventoryItemLink("player", slotID);
            if itemLink then
                self.ProcessItem(itemLink, slotID);
            end
        end
    end

    self:OnComplete();
end

function BagScan:OnComplete()
    self:RegisterEvent("BAG_UPDATE");
    self.bagChanged = false;
    self:Stop();

    Gemma.MainFrame:OnBagUpdateComplete();
end

function BagScan:Stop()
    if self.isProcessing then
        self.isProcessing = false;
        BagScan:OnStop();
    end
end

function BagScan:StopIfProcessorSame(ProcessItem)
    if self.isProcessing and ProcessItem == self.ProcessItem then
        self:Stop();
    end
end

function BagScan:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:FullUpdate();
    end
end

function BagScan:UpdateAfter(delay)
    delay = delay or 0;
    self.t = -delay;
    self:SetScript("OnUpdate", self.OnUpdate);
end

function BagScan:OnEvent(event, ...)
    if event == "BAG_UPDATE" then
        self:UnregisterEvent(event);
        self.bagChanged = true;
        self:UpdateAfter(0.0);
        if Gemma.MainFrame:IsShown() or Gemma.PaperdollWidget:IsShown() then
            self:UpdateAfter(0.0);
        end
    end
end
BagScan:SetScript("OnEvent", BagScan.OnEvent);


function BagScan:GetGemPositionInBagEquipment(gemItemID)
    local itemLink, itemID, numSockets;

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            itemLink = GetContainerItemLink(bag, slot);
            if itemLink and IsEquippableItem(itemLink) then
                numSockets = GetItemNumSockets(itemLink);
                if numSockets > 0 then
                    for index = 1, GetItemNumSockets(itemLink) do
                        itemID = GetItemGemID(itemLink, index);
                        if itemID == gemItemID then
                            return bag, slot, index
                        end
                    end
                end
            end
        end
    end
end

function BagScan:CanPickUpGem(gemItemID, scanBag)
    local count = GetItemCount(gemItemID);
    if count > 0 then
        return true
    end

    if scanBag then
        local itemID
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                itemID = GetContainerItemID(bag, slot);
                if itemID and itemID == gemItemID then
                    return true
                end
            end
        end
    end
end