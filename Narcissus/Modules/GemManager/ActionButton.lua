local _, addon = ...

local SPELL_EXTRACT_GEM = 433397;
local SPELLNAME_EXTRACT_GEM;

local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local PickupContainerItem = C_Container.PickupContainerItem;
local SocketContainerItem = C_Container.SocketContainerItem
local SocketInventoryItem = SocketInventoryItem;
local ClearCursor = ClearCursor;
local ClickSocketButton = ClickSocketButton;
local AcceptSockets = AcceptSockets;
local CloseSocketInfo = CloseSocketInfo;
local GetSpellInfo = GetSpellInfo;
local InCombatLockdown = InCombatLockdown;

local UIParent = UIParent;

local ExtractorActionButton;

local EVENTS = {
    "SOCKET_INFO_UPDATE",
    "SOCKET_INFO_SUCCESS",
    "SOCKET_INFO_FAILURE",
    "SOCKET_INFO_CLOSE",
    "SOCKET_INFO_ACCEPT",
};

local function GetSpellName()
    return GetSpellInfo(SPELL_EXTRACT_GEM);
end
addon.AddLoadingCompleteCallback(GetSpellName);


local SocketHelper = CreateFrame("Frame");

function SocketHelper:SuppressItemSocketingFrame()
    UIParent:UnregisterEvent("SOCKET_INFO_UPDATE");
    self:ListenEvents(true);
end

function SocketHelper:ListenEvents(state)
    local method;

    if state then
        method = self.RegisterEvent;
        self:SetScript("OnEvent", self.OnEvent);
    else
        method = self.UnregisterEvent;
        self:SetScript("OnEvent", nil);
    end

    for _, event in ipairs(EVENTS) do
        method(self, event);
    end
end

function SocketHelper:OnEvent(event, ...)
    print(event);

    if event == "SOCKET_INFO_CLOSE" then
        UIParent:RegisterEvent("SOCKET_INFO_UPDATE");
        self:ListenEvents(false);
    elseif event == "SOCKET_INFO_UPDATE" then
        --[[
        if self.mode == "extract" and self.extractSocketIndex then
            self:UnregisterEvent(event);
            ClickSocketButton(self.extractSocketIndex);
            print("CLICK", self.extractSocketIndex)
            self.extractSocketIndex = nil;
            CloseSocketInfo();
        end
        --]]
    end
end

function SocketHelper:SetExtractSocketIndex(socketIndex)
    self.extractSocketIndex = socketIndex;
end

local function PlaceGemInSlot(slotID, gemID, socketIndex)
    ClearCursor();
    if not slotID or not gemID then return; end

    local bagID, slotIndex = GetItemBagPosition(gemID);
    if not(bagID and slotIndex) then return; end

    SocketHelper:SuppressItemSocketingFrame();

    PickupContainerItem(bagID, slotIndex);
    SocketInventoryItem(slotID);
    ClickSocketButton(socketIndex);
    ClearCursor();
    AcceptSockets();

    CloseSocketInfo();

    --Thank god none of the above requires hardware input :)
end

local ExtractorMixin = {};

function ExtractorMixin:PreClick()
    if self.socketFunc then
        SocketHelper:SuppressItemSocketingFrame();
        SocketHelper:RegisterEvent("SOCKET_INFO_UPDATE");
        SocketHelper.mode = "extract";
        self.socketFunc();
    end
end

function ExtractorMixin:PostClick()
    C_Timer.After(1, function()
        TTG();
    end)
end

function ExtractorMixin:ExtractInventoryItem(slotID, socketIndex)
    if not SPELLNAME_EXTRACT_GEM then
        SPELLNAME_EXTRACT_GEM = GetSpellName();
    end

    self.socketFunc = function()
        SocketInventoryItem(slotID);
    end;

    SocketHelper:SetExtractSocketIndex(socketIndex);

    local macroText = string.format("/cast %s\r/run ClickSocketButton(%d)", SPELLNAME_EXTRACT_GEM, socketIndex);
    self:SetAttribute("type1", "macro");
    self:SetAttribute("macrotext", macroText);
    self:RegisterForClicks("LeftButtonDown", "LeftButtonUp");
end

function ExtractorMixin:Init()
    self.Icon:SetTexture(GetSpellTexture(SPELL_EXTRACT_GEM));
end

function ExtractorMixin:Clear()
    self:Hide();
    self:ClearAllPoints();
    self:SetParent(nil);
end

function ExtractorMixin:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function ExtractorMixin:OnHide()
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
end

function ExtractorMixin:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Clear();
    end
end

local function CreateActionButton()
    local f = CreateFrame("Button", nil, UIParent, "InsecureActionButtonTemplate");
    f:SetSize(46, 46);
    f:Hide();

    Mixin(f, ExtractorMixin);

    f:SetScript("PreClick", f.PreClick);
    f:SetScript("PostClick", f.PostClick);
    f:SetScript("OnShow", f.OnShow);
    f:SetScript("OnHide", f.OnHide);
    f:SetScript("OnEvent", f.OnEvent);

    f.Icon = f:CreateTexture(nil, "ARTWORK");
    f.Icon:SetAllPoints(true);

    f:Init();

    return f
end

do
    local function GetActionButton()
        if not ExtractorActionButton then
            ExtractorActionButton = CreateActionButton();
        end
    end

    addon.Gemma.GetActionButton = GetActionButton;
end

--local ExtractorActionButton = CreateActionButton();
--ExtractorActionButton:ExtractInventoryItem(10, 1);

--[[
function TTG()
    local slot = 10
    local itemID = 216625;
    local socketIndex = 1;
    PlaceGemInSlot(slot, itemID, socketIndex)
end
--]]