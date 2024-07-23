local _, addon = ...

local DataProvider = addon.BagItemSearchDataProvider;


local GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots;
local NUM_BAG_SLOTS = 5;

local PopupFrame;
local Processor = CreateFrame("Frame");
addon.BagProcessor = Processor;

Processor.bagQueue = {};


local function ProcessBagItem_OnUpdate(self, elapased)
	--The whole thing seems pretty efficient so we don't cap the number of requests per frame
	self.t = self.t + elapased;

	if self.t >= 0 then
		for slot = self.slot, self.maxSlots do
			if not DataProvider:CacheBagItem(self.bag, slot) then
				self.slot = slot;
				self.t = -0.1;
				return
			end
		end

		self.bag = self.bag + 1;

		if self.bag > NUM_BAG_SLOTS then
			self:SetScript("OnUpdate", nil);
		else
			self.maxSlots = GetContainerNumSlots(self.bag);
		end
	end
end

--Processor:RegisterEvent("PLAYER_ENTERING_WORLD");
Processor:RegisterEvent("BAG_UPDATE");

Processor:SetScript("OnEvent", function(self, event, ...)
    if event == "BAG_UPDATE" then
		self:OnBagChanged(...);
	end

	--[[	--No Initial Cache
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent(event);
		C_Timer.After(2, function()
       		self:StartFullUpdate();
		end)
    end
	--]]
end)

function Processor:StartFullUpdate()
	self.t = 0;
	self.slot = 1;
	self.bag = 0;
	self.maxSlots = GetContainerNumSlots(self.bag);
	self:SetScript("OnUpdate", ProcessBagItem_OnUpdate);
end


local function UpdateComplete_OnUpdate(self, elapased)
	Processor:OnUpdateComplete();
	self:SetScript("OnUpdate", nil);
end

local function UpdateDirtyBags_OnUpdate(self, elapased)
	self.t = self.t + elapased;
	if self.t < 0 then
		return
	end

	local count = 0;

	if self.lastBag and self.lastSlot then
		local bag = self.lastBag;
		for slot = self.lastSlot, GetContainerNumSlots(bag) do
			count = count + 1;
			if count > 31 then
				self.lastBag = bag;
				self.lastSlot = slot;
				self.t = 0;
				return
			elseif not DataProvider:CacheBagItem(bag, slot) then
				self.lastBag = bag;
				self.lastSlot = slot;
				self.t = -0.1;
				return
			end
		end
		self.bagQueue[bag] = nil;
		self.lastBag = nil;
		self.lastSlot = nil;
	end

	for bag in pairs(self.bagQueue) do
		for slot = 1, GetContainerNumSlots(bag) do
			count = count + 1;
			if count > 31 then
				self.lastBag = bag;
				self.lastSlot = slot;
				self.t = 0;
				return
			elseif not DataProvider:CacheBagItem(bag, slot) then
				self.lastBag = bag;
				self.lastSlot = slot;
				self.t = -0.1;
				return
			end
		end
		self.bagQueue[bag] = nil;
		self.lastBag = nil;
		self.lastSlot = nil;
	end

	self:SetScript("OnUpdate", UpdateComplete_OnUpdate);
end

function Processor:OnBagChanged(bag)
	self.needsUpdate = true;
	self.bagQueue[bag] = true;
end

function Processor:ProcessDirtyBags()
	if self.needsUpdate then
		DataProvider:ResetMarkers();
		self.needsUpdate = nil;
		self.t = 1;
		self:SetScript("OnUpdate", UpdateDirtyBags_OnUpdate);

		return true
	end
end

function Processor:OnUpdateComplete()
	DataProvider:UpdateMarkers();
	if PopupFrame then
		PopupFrame:OnUpdateComplete();
	end
end

function Processor:SetCallbackFrame(frame)
	PopupFrame = frame;
end

for bag = 0, 4 do
	Processor:OnBagChanged(bag);
end