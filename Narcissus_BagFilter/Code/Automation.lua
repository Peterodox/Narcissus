-- (Optional) Automatically filters items when visiting:
-- Mail, Auction House

local _, addon = ...
local ItemFilter = addon.ItemFilter;
local API = addon.BagItemSearchAPI;

local MANUALLY_CHANGED; --pause when searchbox changed manually
local PrimarySearchBox;

local Automation = {};

API.AddToEventListner(Automation);

function Automation:OnEvent(event, ...)
    if self.enabled then
        if self.anyOn then
            if event == "MAIL_SHOW" then
                MANUALLY_CHANGED = false;

            elseif event == "AUCTION_HOUSE_SHOW" then
                --ItemFilter.ShowAuctionable();
                self:HookAuctionHouse();
                MANUALLY_CHANGED = false;

            elseif event == "PRIMARY_BAG_OPEN" then
                --this is a custom event
                self:OnBagOpened();
            elseif event == "ITEM_SOCKETING_FRAME_SHOW" then
                --this is a custom event
                if API.IsPrimaryBagOpened() then
                    self:OnBagOpened();
                end
            elseif event == "SEARCH_CHANGED_MANUALLY" then
                MANUALLY_CHANGED = true;
            end
        end
    end
end

local function OnMailTabActive(_, tabID)
    if Automation.enabled and Automation.enableMail then
        if tabID == 2 then
            if (not MANUALLY_CHANGED) or PrimarySearchBox:GetText() == "" then
                --Apply filter if the user doesn't change the searchbox themselves
                ItemFilter.ShowMailable();
            end
        elseif not MANUALLY_CHANGED then
            --Remove filter if the user doesn't change the searchbox themselves
            ItemFilter.Remove();
        end
    end
end

function Automation:HookMail()
    if not self.mailHooked then
        self.mailHooked = true;
        if MailFrameTab_OnClick then
            hooksecurefunc("MailFrameTab_OnClick", OnMailTabActive);
        end
    end
end

local function OnAuctionHouseDisplayModeChanged(self, displayMode)
    if not Automation.enableAuction then return end;

    if displayMode == AuctionHouseFrameDisplayMode.ItemSell or displayMode == AuctionHouseFrameDisplayMode.CommoditiesSell then
        if (not MANUALLY_CHANGED) or PrimarySearchBox:GetText() == "" then
            ItemFilter.ShowAuctionable();
        end
    else
        if not MANUALLY_CHANGED then
            ItemFilter.Remove();
        end
    end
end

function Automation:HookAuctionHouse()
    if not self.ahHooked then
        self.ahHooked = true;
        local f = _G["AuctionHouseFrame"];
        if f and f.SetDisplayMode and AuctionHouseFrameDisplayMode then
            hooksecurefunc(f, "SetDisplayMode", OnAuctionHouseDisplayModeChanged);
        end
    end
end

function Automation:OnBagOpened()
    if self.enableGem then
        if API.IsUsingPrimodialStoneSystem() then
            MANUALLY_CHANGED = false;
            ItemFilter.ShowPrimordialStones();
        elseif API.IsSocketingItem() then
            MANUALLY_CHANGED = false;
            ItemFilter.ShowGem();
        end
    end
end

function Automation:UpdateState()
    if self.enableMail or self.enableAuction or self.enableGem then
        if not self.anyOn then
            --print("Auto Filter ON");
        end
        self.anyOn = true;
    else
        if self.anyOn then
            --print("Auto Filter OFF");
        end
        self.anyOn = nil;
    end
end


local function AssginSearchBox(addonName, searchbox, notUsingBlizzardSearch)
    PrimarySearchBox = searchbox;
end

API.AddSearchBoxAssignee(AssginSearchBox);



---- Settings ----
local function AutoFilterMail(state, db)
    if state == nil and db then
        state = db["AutoFilterMail"];
    end

    if state then
        Automation:HookMail();
        Automation.enableMail = true;
    else
        Automation.enableMail = nil;
    end

    Automation:UpdateState();
end

local function AutoFilterAuction(state, db)
    if state == nil and db then
        state = db["AutoFilterAuction"];
    end

    if state then
        Automation.enableAuction = true;
    else
        Automation.enableAuction = nil;
    end

    Automation:UpdateState();
end

local function AutoFilterGem(state, db)
    if state == nil and db then
        state = db["AutoFilterGem"];
    end

    if state then
        Automation.enableGem = true;
    else
        Automation.enableGem = nil;
    end

    Automation:UpdateState();
end

addon.SettingFunctions.AutoFilterMail = AutoFilterMail;
addon.SettingFunctions.AutoFilterAuction = AutoFilterAuction;
addon.SettingFunctions.AutoFilterGem = AutoFilterGem;


local function EnableAutoFilter(state)
    Automation.enabled = state;
end
API.EnableAutoFilter = EnableAutoFilter;