local MAX_BAG_ID = 6;					--Reagent Bag 
local BACKPACK_EXTENTED_SIZE = 20;		--the starup backpack can be extended to 20 slots Authenticator

local _, addon = ...

local ItemDataProvider = addon.BagItemSearchDataProvider;

local ItemFilter = {};
addon.ItemFilter = ItemFilter;

local _G = _G;

local find = string.find;
local ItemLocation = ItemLocation;
local IsBound = C_Item.IsBound;
local IsCosmeticItem = C_Item.IsCosmeticItem;
local IsSellItemValid = C_AuctionHouse.IsSellItemValid;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local SetItemSearch = C_Container.SetItemSearch;

local GetContainerItemID = C_Container.GetContainerItemID;
local GetContainerNumSlots = C_Container.GetContainerNumSlots;
local CombinedBag = ContainerFrameCombinedBags;

local IsContainerItemFiltered;
do
	local GetContainerItemInfo = C_Container.GetContainerItemInfo;
	local tempTbl = {};

	function IsContainerItemFiltered(bag, slot)
		tempTbl = GetContainerItemInfo(bag, slot);
		return tempTbl and tempTbl.isFiltered
	end
end

local PrimarySearchBox = addon.PrimarySearchBox;


local function SetMatchesSearch(itemButton, matchesSearch)
	--itemButton.matchesSearch = matchesSearch;	--this somehow increase RAM usage (when this method get called by Blizzard UI  (e.g. open bags, move items), the RAM usage is counted towards our addon)
	if matchesSearch then
		itemButton.ItemContextOverlay:Hide();
	else
		itemButton.ItemContextOverlay:Show();
	end
end

local function IterateItemButtons(mode, conditionFunc, arg1, arg2)
	--Doesn't work on Locked Slots(4 Extra Slots unlocked by activating Aunthenticator)
	local GetContainerItemID = GetContainerItemID;
	local _G = _G;
	local bag, slot;
	local isCombinedBagShown = CombinedBag and CombinedBag:IsShown();
	local reagentBag = _G["ContainerFrame6"];

	local processMethod;

	if mode == 1 then
		local itemLocation = ItemLocation:CreateEmpty();

		local function IterateItemLocation(bagFrame)
			if bagFrame.Items then
				for j, itemButton in ipairs(bagFrame.Items) do
					slot, bag = itemButton:GetSlotAndBagID();
					if GetContainerItemID(bag, slot) then
						itemLocation:SetBagAndSlot(bag, slot);
						SetMatchesSearch(itemButton, conditionFunc(itemLocation, itemButton, arg1, arg2))
					else
						SetMatchesSearch(itemButton, true);
					end
				end
			end
		end

		processMethod = IterateItemLocation;
	else
		local itemID;

		local function IterateItemID(bagFrame)
			if bagFrame.Items then
				for j, itemButton in ipairs(bagFrame.Items) do
					slot, bag = itemButton:GetSlotAndBagID();
					itemID = GetContainerItemID(bag, slot);
					if itemID then
						SetMatchesSearch(itemButton, conditionFunc(itemID, itemButton, arg1, arg2))
					else
						SetMatchesSearch(itemButton, true);
					end
				end
			end
		end

		processMethod = IterateItemID;
	end

	if isCombinedBagShown then
		processMethod(CombinedBag);
		if reagentBag and reagentBag:IsShown() then
			processMethod(reagentBag);
		end
	else
		local frame, frameName;
		for i = 1, MAX_BAG_ID do
			frameName = "ContainerFrame"..i;
			frame = _G[frameName];
			if frame and frame:IsShown() then
				processMethod(frame);
			end
		end
	end
end

local ITERTATE_BUTTONS = IterateItemButtons;



local function StartSearching_Native(keyword)
	local currentText = PrimarySearchBox:GetText();
	if currentText ~= "" and find(keyword, currentText, 1) then
		SetItemSearch("");
		SetItemSearch(keyword);
	else
		PrimarySearchBox:SetText(keyword);
	end
end

local function StartSearching_Alien(keyword)
	--Some addons use libs instead of the Blizzard item search
	--So we need to call SetItemSearch here

	--PrimarySearchBox:SetText(keyword);	--Cause the bag addon to run its own search and cause stutter.
	PrimarySearchBox:SetText(" ");
	SetItemSearch("");		--Clear Last Search
	SetItemSearch(keyword);
end

local START_SEARCHING = StartSearching_Native;


local LAST_METHOD;	--For reapplying filter
local LAST_ARG1;
local PAUSE_UPDATE;

local SearchEventFrame = CreateFrame("Frame");		--run something after the default item search completes

local function SearchEventFrame_OnUpdate(self, elapsed)
	self.frameIndex = self.frameIndex + 1;
	if self.frameIndex < 2 then return end;

	if self.postSearchCallback then
		self.postSearchCallback(self.arg1, self.arg2);
		self.postSearchCallback = nil;
	end

	self:SetScript("OnUpdate", nil);
end

local function BagUpdate_Callback(self, elapsed)
	if LAST_METHOD ~= nil then
		ItemFilter.ReapplyLastFilter();
	end
	self:SetScript("OnUpdate", nil);
end

SearchEventFrame:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event);
	self.frameIndex = 0;

	if event == "INVENTORY_SEARCH_UPDATE" then
		self:SetScript("OnUpdate", SearchEventFrame_OnUpdate);
	elseif event == "BAG_UPDATE" then
		if LAST_METHOD ~= nil then
			ItemFilter.ReapplyLastFilter();	--have to run it twice to prevent flickering
			self:SetScript("OnUpdate", SearchEventFrame_OnUpdate);
		end
	end
end);


local function Condition_ClearFilter()
	return true
end

local function Condition_NotBound(itemLocation)
    return not IsBound(itemLocation)
end

local function Condition_Auctionable(itemLocation)
	return IsSellItemValid(itemLocation, false);		--false: Hide error message
end

local function Condition_Mailable(itemLocation, itemButton)
	if itemButton.matchesSearch == nil or itemButton.matchesSearch then
		return true
	else
		return IsSellItemValid(itemLocation, false);
	end
end


local function SaveLastFilter(filterFunc, arg1)
	LAST_METHOD = filterFunc;
	LAST_ARG1 = arg1;

	SearchEventFrame:RegisterEvent("BAG_UPDATE");
end

local DelayFilter = CreateFrame("Frame");

local function DelayFilter_OnUpdate(self, elapsed)
	self:SetScript("OnUpdate", nil);
	if LAST_METHOD then
		LAST_METHOD(LAST_ARG1);
	end
	PAUSE_UPDATE = nil;
end

function ItemFilter.ReapplyLastFilter()
	if LAST_METHOD then
		if not PAUSE_UPDATE then
			PAUSE_UPDATE = true;
			DelayFilter:SetScript("OnUpdate", DelayFilter_OnUpdate);
		end
	end
end

function ItemFilter.RemoveLastFilter()
	LAST_METHOD = nil;
	LAST_ARG1 = nil;
	SearchEventFrame:UnregisterEvent("BAG_UPDATE");
end

function ItemFilter.IsAnyFilterApplied()
	return LAST_METHOD ~= nil
end


function ItemFilter.ShowAuctionable()
    --ITERTATE_BUTTONS(1, Condition_Auctionable);   --This somehow increases memory usage everytime you open bags (leaks?)

	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = ITERTATE_BUTTONS;
	SearchEventFrame.arg1 = 1;
	SearchEventFrame.arg2 = Condition_Auctionable;
	START_SEARCHING(AUCTIONS or "Auctions");
	SaveLastFilter(ItemFilter.ShowAuctionable);
end



local function SearchCallback_Cosmetic()
	ITERTATE_BUTTONS(2, IsCosmeticItem);
end

local function IsTransportationItem(itemID)
	return ItemDataProvider:IsTransportationItem(itemID);
end

local function SearchCallback_Teleport()
	ITERTATE_BUTTONS(2, IsTransportationItem);
end

local function IsGem(itemID)
	local _, _, _, _, _, classID = GetItemInfoInstant(itemID);
	return classID == 3
end

local function SearchCallback_Gem()
	ITERTATE_BUTTONS(2, IsGem);
end

local function IsConjuredItem(itemID)
	return ItemDataProvider:IsConjuredItem(itemID);
end


function ItemFilter.ShowCosmetic()
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = SearchCallback_Cosmetic;
	SearchEventFrame.arg1 = nil;
	START_SEARCHING(ITEM_COSMETIC or "Cosmetic");

	SaveLastFilter(ItemFilter.ShowCosmetic);
end

function ItemFilter.ShowTeleport()
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = SearchCallback_Teleport;
	SearchEventFrame.arg1 = nil;
	START_SEARCHING(TUTORIAL_TITLE35 or "Travel");

	SaveLastFilter(ItemFilter.ShowTeleport);
end

function ItemFilter.ShowGem()
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = SearchCallback_Gem;
	SearchEventFrame.arg1 = nil;
	START_SEARCHING(AUCTION_CATEGORY_GEMS or "Gems");
	SaveLastFilter(ItemFilter.ShowGem);
end

function ItemFilter.ShowPrimordialStones()
	local name = NarciAPI.GetCachedItemTooltipTextByLine(204002, 2) or "Primordial Stone";
	ItemFilter.SearchKeyword(name);
end

function ItemFilter.Remove()
	SearchEventFrame:UnregisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = nil;
	SearchEventFrame.arg1 = nil;
	START_SEARCHING("");
	ITERTATE_BUTTONS(2, Condition_ClearFilter);

	SaveLastFilter(nil);
end


function ItemFilter.ShowMailable_Native()
	-- 1. Show Auctionable;
	-- 2. Add Account Bound Item
	--Deprecated Method: First set searchbox "Account Bound" ITEM_BNETACCOUNTBOUND
    --IterateItemButtons(Condition_NotBound);   --false: Hide error messages
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	--SearchEventFrame.postSearchCallback = ItemFilter.ReverseMatch;
	--SearchEventFrame.arg1 = IsConjuredItem;
	SearchEventFrame.postSearchCallback = ITERTATE_BUTTONS;
	SearchEventFrame.arg1 = 1;
	SearchEventFrame.arg2 = Condition_Mailable;
	START_SEARCHING(ITEM_ACCOUNTBOUND or "Warbound");	--Changed to Warbound after 11.0

	SaveLastFilter(ItemFilter.ShowMailable_Native);
end

ItemFilter.ShowMailable = ItemFilter.ShowMailable_Native;


function ItemFilter.SearchKeywordSimple(keyword)
	START_SEARCHING(keyword);

	SaveLastFilter(ItemFilter.SearchKeywordSimple, keyword);
	--ItemFilter.RemoveLastFilter();
end

function ItemFilter.SearchKeywordCallback(keyword)
	--For addons
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = ITERTATE_BUTTONS;
	SearchEventFrame.arg1 = 3;
	START_SEARCHING(keyword);

	SaveLastFilter(ItemFilter.SearchKeywordCallback, keyword);
end

ItemFilter.SearchKeyword = ItemFilter.SearchKeywordSimple;


function NarciSearchItemByKeyword(keyword)
	--Test Globals
	ItemFilter.SearchKeyword(keyword)
end

function ItemFilter.ReverseMatch(additionalCondition)
	--hightlight the unfiltered item buttons

	local _G = _G;
	local frameName;
	local frame, itemButton;
	local bag, slot;
	local GetContainerNumSlots = GetContainerNumSlots;
	local GetContainerItemID = GetContainerItemID;

	if additionalCondition then
		local itemID;
		for i = 1, MAX_BAG_ID do
			frameName = "ContainerFrame"..i;
			frame = _G[frameName];
			if frame and frame:IsShown() then
				bag = frame:GetID();
				frameName = frameName.."Item";
	
				for j = 1, GetContainerNumSlots(bag) do
					itemButton = _G[frameName..j] or frame["Item"..j];
					slot = itemButton:GetID();
					itemID = GetContainerItemID(bag, slot);
					if itemID then
						if additionalCondition(itemID) then
							itemButton:SetMatchesSearch(false);
						else
							itemButton:SetMatchesSearch( not itemButton.matchesSearch );
						end
					else
						itemButton:SetMatchesSearch(true);
					end
				end
			end
		end
	else
		for i = 1, MAX_BAG_ID do
			frameName = "ContainerFrame"..i;
			frame = _G[frameName];
			if frame and frame:IsShown() then
				bag = frame:GetID();
				frameName = frameName.."Item";
	
				for j = 1, GetContainerNumSlots(bag) do
					itemButton = _G[frameName..j] or frame["Item"..j];
					slot = itemButton:GetID();
					if GetContainerItemID(bag, slot) then
						itemButton:SetMatchesSearch( not itemButton.matchesSearch );
					else
						itemButton:SetMatchesSearch(true);
					end
				end
			end
		end
	end
end



---- Addon Compatibility ----
local EmptySlots = {};

local function GetItemButtonsByBagID_Void(bag, slot)
	return EmptySlots
end

local function GetItemButtonsByBagID_ElvUI(bag, slot)
	return ElvUI_ContainerFrame.Bags[bag][slot]
	--[[
	local bagFrame = _G["ElvUI_ContainerFrame"];
	if bagFrame then
		return bagFrame.Bags[bag] or EmptySlots
	else
		print("Bag Search Suggestion: Can't find ElvUI bag frame");
		return EmptySlots
	end
	--]]
end

local function GetItemButtonsByBagID_Bagnon(bag, slot)
	--/script for k, v in pairs(Bagnon.Frame.ItemGroup) do print(k) end
	return _G["ContainerFrame"..(bag+1).."Item"..slot]
end

local GET_ITEM_BUTTONS_BY_BAG = GetItemButtonsByBagID_Void;


local function IterateItemButtons_AddOn(mode, conditionFunc, arg1, arg2)
	local GetContainerItemID = GetContainerItemID;
    local GetContainerNumSlots = GetContainerNumSlots;
	local itemButton;
	local slots;

	if mode == 1 then
		--use ItemLocation
		local itemLocation = ItemLocation:CreateEmpty();
		for bag = 0, 4 do
			--slots = GET_ITEM_BUTTONS_BY_BAG(bag);
			for id = 1, GetContainerNumSlots(bag) do
				itemButton = GET_ITEM_BUTTONS_BY_BAG(bag, id)	--slots[id];
				if itemButton then
					if GetContainerItemID(bag, id) then
						itemLocation:SetBagAndSlot(bag, id);
						itemButton.searchOverlay:SetShown( not conditionFunc(itemLocation, itemButton, arg1, arg2) );
					else
						itemButton.searchOverlay:Hide();
					end
				end
			end
		end
	elseif mode == 2 then
		--use ItemID
		local itemID;
		for bag = 0, 4 do
			--slots = GET_ITEM_BUTTONS_BY_BAG(bag);
			for id = 1, GetContainerNumSlots(bag) do
				itemButton = GET_ITEM_BUTTONS_BY_BAG(bag, id)--slots[id];
				if itemButton then
					itemID = GetContainerItemID(bag, id);
					if itemID then
						itemButton.searchOverlay:SetShown( not conditionFunc(itemID, itemButton, arg1, arg2) );
					else
						itemButton.searchOverlay:Hide();
					end
				end
			end
		end
	elseif mode == 3 then
		--use Bag and Slot
		--local texture, itemCount, locked, quality, readable, itemLink, isFiltered, noValue, itemID, isBound, _;
		local IsContainerItemFiltered = IsContainerItemFiltered;
		for bag = 0, 4 do
			--slots = GET_ITEM_BUTTONS_BY_BAG(bag);
			for id = 1, GetContainerNumSlots(bag) do
				itemButton = GET_ITEM_BUTTONS_BY_BAG(bag, id)--slots[id];
				if itemButton then
					if IsContainerItemFiltered(bag, id) then
						itemButton.searchOverlay:Show();
					else
						itemButton.searchOverlay:Hide();
					end
				end
			end
		end
	end
end


local function IterateItemButtons_AddOn_FindMailable()
	local itemButton, slots;
	local IsContainerItemFiltered = IsContainerItemFiltered;
	local GetContainerNumSlots = GetContainerNumSlots;
	local itemLocation = ItemLocation:CreateEmpty();

	for bag = 0, 4 do
		--slots = GET_ITEM_BUTTONS_BY_BAG(bag);
		for id = 1, GetContainerNumSlots(bag) do
			itemButton = GET_ITEM_BUTTONS_BY_BAG(bag, id)--slots[id];
			if itemButton then
				if IsContainerItemFiltered(bag, id) then
					itemLocation:SetBagAndSlot(bag, id);
					if Condition_Auctionable(itemLocation) then
						itemButton.searchOverlay:Hide();
					else
						itemButton.searchOverlay:Show();
					end
				else
					itemButton.searchOverlay:Hide();
				end
			end
		end
	end
end

function ItemFilter.ShowMailable_Alien()
	SearchEventFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	SearchEventFrame.postSearchCallback = IterateItemButtons_AddOn_FindMailable;
	SearchEventFrame.arg1 = nil;
	StartSearching_Alien(ITEM_ACCOUNTBOUND or "Warbound");

	SaveLastFilter(ItemFilter.ShowMailable_Alien);
end


local function AssginSearchBox(addonName, searchbox, notUsingBlizzardSearch)
	PrimarySearchBox = searchbox;

	if addonName == "ElvUI" then
		ITERTATE_BUTTONS = IterateItemButtons_AddOn;
		START_SEARCHING = StartSearching_Alien;
		GET_ITEM_BUTTONS_BY_BAG = GetItemButtonsByBagID_ElvUI;
		ItemFilter.SearchKeyword = ItemFilter.SearchKeywordCallback;
		ItemFilter.ShowMailable = ItemFilter.ShowMailable_Alien;
	elseif addonName == "Bagnon" then
		ITERTATE_BUTTONS = IterateItemButtons_AddOn;
		START_SEARCHING = StartSearching_Alien;
		GET_ITEM_BUTTONS_BY_BAG = GetItemButtonsByBagID_Bagnon;
		ItemFilter.SearchKeyword = ItemFilter.SearchKeywordCallback;
		ItemFilter.ShowMailable = ItemFilter.ShowMailable_Alien;
	end
end

addon.BagItemSearchAPI.AddSearchBoxAssignee(AssginSearchBox);