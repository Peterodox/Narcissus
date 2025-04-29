local _, addon = ...

local unpack = unpack;
local ipairs = ipairs;

local API = {};
addon.BagItemSearchAPI = API;


local PrimarySearchBox;
local SearchBoxAssignee = {};

do
    local blizzardSearchBox = _G["BagItemSearchBox"];
    if blizzardSearchBox then
        PrimarySearchBox = blizzardSearchBox;
    end
end


local EventListener = CreateFrame("Frame");
EventListener:RegisterEvent("MAIL_SHOW");
EventListener:RegisterEvent("MAIL_CLOSED");
EventListener:RegisterEvent("AUCTION_HOUSE_SHOW");
EventListener:RegisterEvent("AUCTION_HOUSE_CLOSED");
EventListener.callbackList = {};


---- Custom Event ----
-- PRIMARY_BAG_OPEN / PRIMARY_BAG_CLOSED   --ContainerFrame1
local LIST_LENGTH = 0;

local function TriggerEvent(event, ...)
    for i = 1, LIST_LENGTH do
        EventListener.callbackList[i]:OnEvent(event, ...);
    end
end

local function ItemSocketingFrame_OnShow()
    TriggerEvent("ITEM_SOCKETING_FRAME_SHOW");
end

local function ItemSocketingFrame_OnHide()
    TriggerEvent("ITEM_SOCKETING_FRAME_CLOSED");
end


local function PrimarySearchboxTextChanged(f, userInput)
    if userInput then
        TriggerEvent("SEARCH_CHANGED_MANUALLY");
    end

    if f:GetText() == "" then
        TriggerEvent("SEARCH_CLEARED");
    end
end

local PRIMARY_BAG_OPENED = false;

local function PrimaryBag_OnShow()
    TriggerEvent("PRIMARY_BAG_OPEN");
end

local function PrimaryBag_OnHide()
    TriggerEvent("PRIMARY_BAG_CLOSED");
end

local function IsPrimaryBagOpened()
    return PRIMARY_BAG_OPENED
end

API.IsPrimaryBagOpened = IsPrimaryBagOpened;

local function Bagnon_FrameNew(frame, id)
    if id == "inventory" then
        local bagFrame = _G["BagnonInventoryFrame1"];
        if bagFrame then
            local addonName = "Bagnon";
            local searchbox = bagFrame.searchFrame;
            if searchbox then
                PrimarySearchBox = searchbox;
            else
                addonName = "Blizzard";
                if not PrimarySearchBox then
                    PrimarySearchBox = CreateFrame("EditBox", nil, UIParent);
                    PrimarySearchBox:Hide();
                    PrimarySearchBox:SetFontObject("GameFontNormal");
                    PrimarySearchBox:SetSize(8, 8);
                    PrimarySearchBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -400);
                end
            end

            if PrimarySearchBox:GetScript("OnTextChanged") then
                PrimarySearchBox:HookScript("OnTextChanged", PrimarySearchboxTextChanged);
            else
                print("no OnTextChanged")
            end

            local alienSerach = true;
            for _, callback in ipairs(SearchBoxAssignee) do
                callback(addonName, searchbox, alienSerach);
            end
        end
    end
end

local function Bagnon_Hook()
    if Bagnon and Bagnon.Frame and Bagnon.Frame.New then
        hooksecurefunc(Bagnon.Frame, "New", Bagnon_FrameNew);
    else
        print("Pitcher: Failed to hook Bagnon");
    end
end

local function FindPrimarySearchBox()
    local BagAddonFrames = {
        --{addonName = "Bagnon", callback = Bagnon_Hook },  --It seems impossible to support Bagnon: It rearanges itembuttons and removes their slotID, so we can't iterate them
        {addonName = "ElvUI", bagName = "ElvUI_ContainerFrame", editboxName = "ElvUI_ContainerFrameEditBox", alienSearch = true},   --Addon Name, Bag Name, SearchBox Name
    };

    local _G = _G;
    local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
    local addonName;
    local primaryBag;
    local alienSerach;  --addon is using its own search method
    local searchBox;

    for i, addonData in ipairs(BagAddonFrames) do
        --print(addonData.addonName, IsAddOnLoaded(addonData.addonName))
        if IsAddOnLoaded(addonData.addonName) then
            if addonData.callback then
                addonData.callback();
                return
            end
            primaryBag = _G[addonData.bagName];
            searchBox = (addonData.editboxName and _G[ addonData.editboxName ]) or (addonData.editboxKey and _G[addonData.bagName][addonData.editboxKey]);
            if primaryBag and searchBox then
                --Check if the bag module in ElvUI is enabled
                addonName = addonData.addonName;
                PrimarySearchBox = searchBox;
                alienSerach = addonData.alienSearch;
            end
            break
        end
    end

    if not addonName then
        addonName = "Blizzard";
    end

    if not primaryBag then
        local useCombinedBags = C_CVar.GetCVarBool("combinedBags");

        if useCombinedBags then
            primaryBag = _G["ContainerFrameCombinedBags"];
        else
            primaryBag = _G["ContainerFrame1"];
        end
    end

    if primaryBag then
        --primaryBag:HookScript("OnShow", PrimaryBag_OnShow);
        --primaryBag:HookScript("OnHide", PrimaryBag_OnHide);
        EventRegistry:RegisterCallback("ContainerFrame.OpenAllBags", PrimaryBag_OnShow, {});
        EventRegistry:RegisterCallback("ContainerFrame.CloseAllBags", PrimaryBag_OnHide, {});
    end

    --If no searchbox, create a pseudo one
    if not PrimarySearchBox then
        PrimarySearchBox = CreateFrame("EditBox", nil, UIParent);
        PrimarySearchBox:Hide();
        PrimarySearchBox:SetFontObject("GameFontNormal");
        PrimarySearchBox:SetSize(8, 8);
        PrimarySearchBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -400);
    end

    if PrimarySearchBox:GetScript("OnTextChanged") then
        PrimarySearchBox:HookScript("OnTextChanged", PrimarySearchboxTextChanged);
    end

    for _, callback in ipairs(SearchBoxAssignee) do
        callback(addonName, PrimarySearchBox, alienSerach);
    end

    SearchBoxAssignee = {};
    BagAddonFrames = {};
end

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        --self:RegisterEvent("ADDON_LOADED");
        --FindPrimarySearchBox();
    elseif event == "ADDON_LOADED" then
        local name = ...
        if name == "Blizzard_ItemSocketingUI" then
            self:UnregisterEvent(event);
            local f = _G["ItemSocketingFrame"];
            if f then
                f:HookScript("OnShow", ItemSocketingFrame_OnShow);
                f:HookScript("OnHide", ItemSocketingFrame_OnHide);
            end
        end
    else
        TriggerEvent(event, ...);
    end
end);

--EventListener:RegisterEvent("PLAYER_ENTERING_WORLD");
EventListener:RegisterEvent("ADDON_LOADED");
C_Timer.After(0.5, FindPrimarySearchBox);     --10.2.0 We changed this addon to load-on-demand (loaded after PLAYER_ENTERING_WORLD)


local function IsFrameOpened(frameName)
    return _G[frameName] and _G[frameName]:IsShown();
end

function API.IsAtAuctionHouse()
    return IsFrameOpened("AuctionHouseFrame");
end

function API.IsViewingMail()
    return IsFrameOpened("MailFrame");
end

function API.IsSocketingItem()
    return IsFrameOpened("ItemSocketingFrame");
end


local GetSocketTypes = GetSocketTypes;
local HasExtraActionBar = HasExtraActionBar;
local GetActionInfo = GetActionInfo;

function API.IsUsingPrimodialStoneSystem()
    if GetSocketTypes(1) == "Primordial" then
        return true
    end

    if HasExtraActionBar() then
        local actionType, id, subType = GetActionInfo(217);
        if id == 405721 then
            return true
        end
    end
end


function API.AddToEventListner(frame)
    for i, f in ipairs(EventListener.callbackList) do
        if f == frame then
            return
        end
    end
    LIST_LENGTH = LIST_LENGTH + 1;
    EventListener.callbackList[LIST_LENGTH] = frame;
end

function API.AddSearchBoxAssignee(callbackFunc)
    table.insert(SearchBoxAssignee, callbackFunc);
end



---- Color Preset ----
local COLORS = {
    LightBrown = {0.77, 0.76, 0.62},
};

function API.GetColorByName(colorName)
    if COLORS[colorName] then
        return unpack(COLORS[colorName])
    else
        return 1, 1, 1
    end
end



local EasingFunctions = {};
addon.EasingFunctions = EasingFunctions;

local pow = math.pow;

function EasingFunctions.outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end