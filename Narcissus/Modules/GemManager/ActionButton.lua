local _, addon = ...
local Gemma = addon.Gemma;

local SPELL_EXTRACT_GEM = 433397;
local SPELLNAME_EXTRACT_GEM;

local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local PickupContainerItem = C_Container.PickupContainerItem;
local SocketContainerItem = C_Container.SocketContainerItem
local GetItemSpell = C_Item.GetItemSpell;
local SocketInventoryItem = SocketInventoryItem;
local ClearCursor = ClearCursor;
local ClickSocketButton = ClickSocketButton;
local AcceptSockets = AcceptSockets;
local CloseSocketInfo = CloseSocketInfo;
local GetSpellInfo = GetSpellInfo;
local InCombatLockdown = InCombatLockdown;

local UIParent = UIParent;

local ActionButton;

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

local ActionButtonMixin = {};

function ActionButtonMixin:PreClick(button)
    if button == "LeftButton" then
        if self.socketFunc then
            SocketHelper:SuppressItemSocketingFrame();
            SocketHelper:RegisterEvent("SOCKET_INFO_UPDATE");
            SocketHelper.mode = "extract";
            self.socketFunc();
        end
    end
end

function ActionButtonMixin:PostClick()
    Gemma.MainFrame:HideTooltip();
    Gemma.MainFrame:AnchorSpinnerToButton(self.parent);
end

function ActionButtonMixin:SetMacroText(macroText, mouseButton)
    self.macroText = macroText;

    if mouseButton == "RightButton" then
        self:SetAttribute("type2", "macro");
        self:RegisterForClicks("RightButtonDown", "RightButtonUp");
    else
        self:SetAttribute("type1", "macro");
        self:RegisterForClicks("LeftButtonDown", "LeftButtonUp");
    end
    
    self:SetAttribute("macrotext", macroText);

end

function ActionButtonMixin:ExtractInventoryItem(slotID, socketIndex)
    if not SPELLNAME_EXTRACT_GEM then
        SPELLNAME_EXTRACT_GEM = GetSpellName();
    end

    self.socketFunc = function()
        SocketInventoryItem(slotID);
    end;

    SocketHelper:SetExtractSocketIndex(socketIndex);

    local macroText = string.format("/cast %s\r/run ClickSocketButton(%d)", SPELLNAME_EXTRACT_GEM, socketIndex);
    self:SetMacroText(macroText);
end

function ActionButtonMixin:ClearAction()
    if self.macroText then
        self.macroText = nil;
        self.socketFunc = nil;
        self:SetAttribute("type", nil);
        self:SetAttribute("type1", nil);
        self:SetAttribute("type2", nil);
        self:SetAttribute("macrotext", nil);
    end
end

function ActionButtonMixin:ClearScripts()
    self:SetScript("PreClick", nil);
    --self:SetScript("PostClick", nil);
    self.onEnterFunc = nil;
    self.onLeaveFunc = nil;
end

function ActionButtonMixin:Remove()
    if self:IsShown() then

    else
        return true
    end

    if InCombatLockdown() then return false end;

    self:Hide();
    self:ClearAllPoints();
    self:SetParent(nil);
    self:ClearAction();
    self:ClearScripts();

    return true
end

function ActionButtonMixin:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function ActionButtonMixin:OnHide()
    self:Remove();
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
end

function ActionButtonMixin:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Remove();
    end
end

function ActionButtonMixin:SetParentFrame(object)
    if self:Remove() then
        self.parent = object;
        self.onEnterFunc = object.OnEnter;
        self.onLeaveFunc = object.OnLeave;
        self:SetParent(object);
        self:SetFrameLevel(object:GetFrameLevel() + 1);
        self:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0);
        self:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 0, 0);
        self:Show();
        return true
    end
end

function ActionButtonMixin:OnEnter()
    if self.onEnterFunc then
        self.onEnterFunc(self.parent, false);
    end
end

function ActionButtonMixin:OnLeave()
    if self.onLeaveFunc then
        self.onLeaveFunc(self.parent, nil, true);
    end
    self:Remove();
end

local function CreateActionButton()
    local f = CreateFrame("Button", nil, UIParent, "InsecureActionButtonTemplate");
    f:SetSize(40, 40);
    f:Hide();

    Mixin(f, ActionButtonMixin);

    f:SetScript("PreClick", f.PreClick);
    f:SetScript("PostClick", f.PostClick);
    f:SetScript("OnShow", f.OnShow);
    f:SetScript("OnHide", f.OnHide);
    f:SetScript("OnEvent", f.OnEvent);
    f:SetScript("OnEnter", f.OnEnter);
    f:SetScript("OnLeave", f.OnLeave);

    --debug
    local bg = f:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(true);
    --bg:SetColorTexture(1, 0, 0, 0.5);

    return f
end

do
    local function GetActionButton(parent)
        if InCombatLockdown() then return end;

        if not ActionButton then
            ActionButton = CreateActionButton();
        end

        if ActionButton:SetParentFrame(parent) then
            return ActionButton
        end
    end

    Gemma.GetActionButton = GetActionButton;
end

--local ActionButton = CreateActionButton();
--ActionButton:ExtractInventoryItem(10, 1);

--[[
function TTG()
    local slot = 10
    local itemID = 216625;
    local socketIndex = 1;
    PlaceGemInSlot(slot, itemID, socketIndex)
end
--]]


do
    local function MarcoText_UseItemOnSlot(itemID, slotID)
        return string.format("/stopcasting\r/use item:%s\r/use %s\r/stopspelltarget", itemID, slotID);
    end

    function ActionButtonMixin:SetWatchedSpell(spellID)
        Gemma.MainFrame:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetWatchedItem(itemID)
        local _, spellID = GetItemSpell(itemID);
        self:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetAction_RemoveTinker()
        --Engineering Tinker
        --Tinker Module can be removed when bags are full. Sent by Postmaster

        local itemID = 202087;  --Tinker Removal Kit
        local slotID = 1;       --Head

        local macroText = MarcoText_UseItemOnSlot(itemID, slotID);
        self:SetMacroText(macroText, "RightButton");

        self:SetWatchedItem(itemID);
    end

    function ActionButtonMixin:SetAction_RemovePrimordialStone()
        local spellID = 405805; --Pluck Out Primordial Stone
        local socketIndex = 1;

        local macroText = string.format("/click ExtraActionButton1\r/run ClickSocketButton(%d)", socketIndex);
        self:SetMacroText(macroText, "RightButton");
        self:SetWatchedSpell(spellID);
    end
end