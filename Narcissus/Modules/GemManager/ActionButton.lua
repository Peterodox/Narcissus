local _, addon = ...
local Gemma = addon.Gemma;
local BagScan = Gemma.BagScan;

local SPELL_EXTRACT_GEM = 433397;
local SPELLNAME_EXTRACT_GEM;

local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local IsSocketOccupied = Gemma.IsSocketOccupied;
local PickupContainerItem = C_Container.PickupContainerItem;
local SocketContainerItem = C_Container.SocketContainerItem
local GetItemSpell = C_Item.GetItemSpell;
local GetItemGemID = C_Item.GetItemGemID;
local GetItemNumSockets = C_Item.GetItemNumSockets;
local GetInventoryItemLink = GetInventoryItemLink;
local SocketInventoryItem = SocketInventoryItem;
local ClearCursor = ClearCursor;
local ClickSocketButton = ClickSocketButton;
local AcceptSockets = AcceptSockets;
local CloseSocketInfo = CloseSocketInfo;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local InCombatLockdown = InCombatLockdown;
local GetCVarBool = C_CVar.GetCVarBool;
local After = C_Timer.After;
local ipairs = ipairs;

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


local function IsUsingKeyDown()
    return GetCVarBool("ActionButtonUseKeyDown");
end

local BLIZZARD_UI_LOADED = false;
local function LoadBlizzardUI()
    if not BLIZZARD_UI_LOADED then
        if C_AddOns.IsAddOnLoaded("Blizzard_ItemSocketingUI") then
            BLIZZARD_UI_LOADED = true;
        else
            BLIZZARD_UI_LOADED = C_AddOns.LoadAddOn("Blizzard_ItemSocketingUI");
        end
    end
end


local SocketHelper = CreateFrame("Frame");
local BagEventWatcher = CreateFrame("Frame");

do  --Stop listening bag after 1.5s
    function BagEventWatcher:ListenBags()
        SocketHelper:RegisterEvent("BAG_UPDATE");
        self.t = -1.5;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function BagEventWatcher:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0 then
            self:UnlistenBags();
        end
    end

    function BagEventWatcher:UnlistenBags()
        if self.t then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            SocketHelper:UnregisterEvent("BAG_UPDATE");
            SocketHelper.pendingGemID = nil;
        end
    end
end

function SocketHelper:SuppressItemSocketingFrame()
    if not self.suppressed then
        self.suppressed = true;
        UIParent:UnregisterEvent("SOCKET_INFO_UPDATE");
        --UIParent:UnregisterEvent("ADDON_ACTION_FORBIDDEN");
        if ItemSocketingFrame then
            ItemSocketingFrame:UnregisterEvent("SOCKET_INFO_UPDATE");
            ItemSocketingFrame:UnregisterEvent("SOCKET_INFO_ACCEPT");
        end
        self:ListenEvents(true);
    end
end

function SocketHelper:UnsuppressItemSocketingFrame()
    CloseSocketInfo();
    if self.suppressed then
        self:ListenEvents(false);
        self.suppressed = nil;
        UIParent:RegisterEvent("SOCKET_INFO_UPDATE");
        --UIParent:RegisterEvent("ADDON_ACTION_FORBIDDEN");
        if ItemSocketingFrame then
            ItemSocketingFrame:RegisterEvent("SOCKET_INFO_UPDATE");
            ItemSocketingFrame:RegisterEvent("SOCKET_INFO_ACCEPT");
        end
    end
end

function SocketHelper:ListenEvents(state)
    local method;

    if state then
        method = self.RegisterEvent;
    else
        method = self.UnregisterEvent;
    end

    for _, event in ipairs(EVENTS) do
        method(self, event);
    end
end

local function PlaceGemInSlot(gemItemID, slotID, socketIndex, customLockDuration)
    if SocketHelper:IsActionLocked() then
        return
    else
        SocketHelper:LockAction(customLockDuration or 0.25);
    end

    ClearCursor();
    if not (gemItemID and slotID) then return; end

    local bagID, slotIndex = GetItemBagPosition(gemItemID);
    if not(bagID and slotIndex) then return; end

    SocketHelper:SuppressItemSocketingFrame();

    PickupContainerItem(bagID, slotIndex);
    SocketInventoryItem(slotID);

    if IsSocketOccupied(socketIndex) then
        --Something went wrong. Socket isn't empty

    else
        ClickSocketButton(socketIndex);
        ClearCursor();
        AcceptSockets();
    end

    SocketHelper:UnsuppressItemSocketingFrame();

    return true

    --Thank god none of the above requires hardware input :)
    --I jinx it :(
end

local function RemoveGemInSlot(arg1, arg2, arg3)
    if SocketHelper:IsActionLocked() then
        return
    else
        SocketHelper:LockAction(0);
    end

    local bag, slot, socketIndex;

    if arg3 then
        bag = arg1;
        slot = arg2;
        socketIndex = arg3;
    else
        slot = arg1;
        socketIndex = arg2;
    end

    ClearCursor();

    if not socketIndex then return; end

    if not Gemma:DoesBagHaveFreeSlot() then
        return
    end

    SocketHelper:SuppressItemSocketingFrame();

    if bag then
        SocketContainerItem(bag, slot);
    else
        SocketInventoryItem(slot);
    end

    --ClickSocketButton(socketIndex);
end

local function PlaceGemInSlot_EventDriven(gemItemID, slotID, socketIndex)
    ClearCursor();
    if not (gemItemID and slotID) then return; end

    local bagID, slotIndex = GetItemBagPosition(gemItemID);
    if not(bagID and slotIndex) then return; end

    SocketHelper:SuppressItemSocketingFrame();
    SocketHelper.mode = "in";
    SocketHelper.socketIndex = socketIndex or 1;

    PickupContainerItem(bagID, slotIndex);
    SocketInventoryItem(slotID);
end

local function RemoveGemInSlot_EventDriven(slotID, socketIndex)
    ClearCursor();
    if not (slotID and socketIndex) then return; end

    if not Gemma:DoesBagHaveFreeSlot() then
        return
    end

    SocketHelper:SuppressItemSocketingFrame();
    SocketHelper.mode = "out";
    SocketHelper.socketIndex = socketIndex;

    SocketInventoryItem(slotID);
end

function SocketHelper:OnUpdate(elapsed)
    --Throttle action frequency so it doesn't destroy existing gem
    self.lockTime = self.lockTime + elapsed;
    if self.lockTime > 0 then
        self.lockTime = nil;
        self:SetScript("OnUpdate", nil);
    end
end

function SocketHelper:LockAction(duration)
    if self.lockTime then return end;
    duration = duration or 0.5;
    self.lockTime = -duration;
    self:SetScript("OnUpdate", self.OnUpdate);
end

function SocketHelper:IsActionLocked()
    return self.lockTime ~= nil
end

function SocketHelper:OnEvent(event, ...)
    if event == "SOCKET_INFO_CLOSE" then
        self:UnregisterEvent(event);
        self:UnsuppressItemSocketingFrame();

    elseif event == "SOCKET_INFO_UPDATE" then
        self:UnregisterEvent(event);
        if not self.pauseUpdate then
            self.pauseUpdate = true;
            After(0, function()
                self.pauseUpdate = nil;
                self:UnsuppressItemSocketingFrame();
            end)
        end
    elseif event == "BAG_UPDATE" then
        --self:UnregisterEvent(event);
        if not self.pauseBagUpdate then
            self.pauseBagUpdate = true;
            After(0, function()
                self.pauseBagUpdate = nil;
                if self.pendingGemID then
                    if self:PlaceGemInBestSlot(self.pendingGemID, true) then
                        self.pendingGemID = nil;
                        self:UnregisterEvent(event);
                    end
                else

                end
            end)
        end
    end
end
SocketHelper:SetScript("OnEvent", SocketHelper.OnEvent);

function SocketHelper:SetExtractSocketIndex(socketIndex)
    self.extractSocketIndex = socketIndex;
end

local ActionButtonMixin = {};

function ActionButtonMixin:PreClick(button)
    if self.parent.onClickFunc and self.parent.onClickFunc(self.parent, button) then
        self.showActionBlockerAfterClick = false;
        return
    end

    if self.socketFunc then
        self.socketFunc(button);
    end

    self.showActionBlockerAfterClick = true;
end

function ActionButtonMixin:PostClick()
    Gemma.MainFrame:AnchorSpinnerToButton(self.parent);
    if self.showActionBlockerAfterClick then
        Gemma.MainFrame:ShowActionBlocker();
    end
    self:OnMouseUp();
end

function ActionButtonMixin:OnMouseDown(button)
    if self.parent.OnMouseDown then
        self.parent:OnMouseDown(button);
    end
end

function ActionButtonMixin:OnMouseUp()
    if self.parent.OnMouseUp then
        self.parent:OnMouseUp();
    end
end

function ActionButtonMixin:SetMacroText(macroText, mouseButton)
    self.macroText = macroText;

    if mouseButton == "RightButton" then
        self:SetAttribute("type2", "macro");
        if IsUsingKeyDown() then
            self:RegisterForClicks("RightButtonDown");
        else
            self:RegisterForClicks("RightButtonUp");
        end
    elseif mouseButton == "LeftButton" then
        self:SetAttribute("type1", "macro");
        if IsUsingKeyDown() then
            self:RegisterForClicks("LeftButtonDown");
        else
            self:RegisterForClicks("LeftButtonUp");
        end
    else
        self:SetAttribute("type", "macro");
        if IsUsingKeyDown() then
            self:RegisterForClicks("LeftButtonDown", "RightButtonDown");
        else
            self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
        end
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
    --self:SetScript("PreClick", nil);
    --self:SetScript("PostClick", nil);
    self.socketFunc = nil;
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
        self:SetFrameLevel(object:GetFrameLevel() + 4);
        self:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0);
        self:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 0, 0);
        local width, height = object:GetSize();
        self:SetSize(width, height);
        self:Show();
        return true
    end
end

function ActionButtonMixin:OnEnter()
    if self.onEnterFunc then
        self.onEnterFunc(self.parent, false, true);
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
    f:SetScript("OnMouseDown", f.OnMouseDown);
    f:SetScript("OnMouseUp", f.OnMouseUp);

    --debug
    local bg = f:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(true);
    --bg:SetColorTexture(1, 0, 0, 0.5);

    return f
end

do
    local function AcquireActionButton(parent)
        if not parent then return end;
        if InCombatLockdown() then return end;

        if not ActionButton then
            ActionButton = CreateActionButton();
        end

        if ActionButton:SetParentFrame(parent) then
            return ActionButton
        end
    end
    Gemma.AcquireActionButton = AcquireActionButton;

    
    local function HideActionButton()
        if ActionButton then
            ActionButton:Remove();
        end
    end
    Gemma.HideActionButton = HideActionButton;
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

    function SocketHelper:SocketInventoryItemByGemID(gemItemID)
        self:ClearPendingGem();

        local slot, index = Gemma:GetGemInventorySlotAndIndex(gemItemID);

        if not (slot and index) then
            return
        end

        SocketHelper:SetExtractSocketIndex(index);

        return slot, index
    end

    function SocketHelper:ExtractGemFromInventorySlot(gemItemID)
        self:ClearPendingGem();

        local slot, socketIndex = Gemma:GetGemInventorySlotAndIndex(gemItemID);

        if not (slot and socketIndex) then
            SocketHelper:UnsuppressItemSocketingFrame();
            return
        end

        --self:SetExtractSocketIndex(socketIndex);
        --SocketInventoryItem(slot);

        --After(0, function()
            RemoveGemInSlot(slot, socketIndex)
        --end);

        return true, socketIndex
    end

    function SocketHelper:ExtractGemFromContainer(gemItemID)
        self:ClearPendingGem();

        local bag, slot, socketIndex = BagScan:GetGemPositionInBagEquipment(gemItemID);

        if not socketIndex then
            SocketHelper:UnsuppressItemSocketingFrame();
            return
        end

        --self:SetExtractSocketIndex(index);
        --SocketInventoryItem(slot);

        --After(0, function()
            self:SetPendingGem(gemItemID);
            RemoveGemInSlot(bag, slot, socketIndex);
        --end);

        return true, socketIndex
    end

    function SocketHelper:SocketInventorySlot(slot)
        self:SuppressItemSocketingFrame();
        SocketInventoryItem(slot);
    end

    function SocketHelper:SocketContainerSlot(bag, slot)
        self:SuppressItemSocketingFrame();
        SocketContainerItem(bag, slot);
    end

    function SocketHelper:SetPendingGem(gemItemID)
        --Gem is removed from a gear then insert into an currently equipped gear
        self.pendingGemID = gemItemID;
        BagEventWatcher:ListenBags();
    end

    function SocketHelper:ClearPendingGem()
        if self.pendingGemID then
            self.pendingGemID = nil;
            BagEventWatcher:UnlistenBags();
        end
    end

    function SocketHelper:PlaceGemInBestSlot(gemItemID, scanBag)
        local isOwned = BagScan:CanPickUpGem(gemItemID, scanBag);    --GetItemCount: May be slower than BAG_UPDATE

        if isOwned then
            local slotID, socketIndex = Gemma:GetBestSlotToPlaceGem(gemItemID);
            if slotID and socketIndex then
                PlaceGemInSlot(gemItemID, slotID, socketIndex);
                return true
            else
                
            end
        end

        return false
    end

    function ActionButtonMixin:SetAction_RemovePrimordialStone(itemID)
        local spellID = 405805; --Pluck Out Primordial Stone

        self.socketFunc = function(button)
            SocketHelper:SuppressItemSocketingFrame();

            if button == "RightButton" and SocketHelper:ExtractGemFromInventorySlot(itemID) then
                local macroText = "/stopspelltarget\r/click ExtraActionButton1";
                self:SetMacroText(macroText, "RightButton");
            elseif button == "LeftButton" then
                if SocketHelper:PlaceGemInBestSlot(itemID) then
                    
                else
                    if SocketHelper:ExtractGemFromContainer(itemID) then
                        local macroText = "/stopspelltarget\r/click ExtraActionButton1";
                        self:SetMacroText(macroText, "LeftButton");
                    else
                        self:SetMacroText(nil, "LeftButton");
                    end
                end
            end
        end;

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");
        self:SetWatchedSpell(spellID);
    end

    local function GetSpellCastMacro()
        if not SPELLNAME_EXTRACT_GEM then
            SPELLNAME_EXTRACT_GEM = GetSpellName();
        end
        return string.format("/stopspelltarget\r/cast %s", SPELLNAME_EXTRACT_GEM);
    end

    local function GetRemoveSocketMacro(socketIndex)
        --For Remix Gem, Blizzard ties spellcasting to clicking socket button so removing gems caused error
        --So we load Blizzard_ItemSocketingUI here and /click button in the macro
        --Please notice three ItemSocketingSocket buttons are disabled upon "SOCKET_INFO_ACCEPT", see "ItemSocketingFrame_DisableSockets"

        LoadBlizzardUI();

        if not SPELLNAME_EXTRACT_GEM then
            SPELLNAME_EXTRACT_GEM = GetSpellName();
        end

        return string.format("/stopspelltarget\r/cast %s\r/click ItemSocketingSocket%s", SPELLNAME_EXTRACT_GEM, socketIndex);
    end

    function ActionButtonMixin:SetMacro_RemovePandariaGem_Equipped(itemID, mouseButton)
        local found, socketIndex = SocketHelper:ExtractGemFromInventorySlot(itemID);

        if found then
            local macroText = GetRemoveSocketMacro(socketIndex);
            self:SetMacroText(macroText, mouseButton);
        else
            self:SetMacroText(nil, mouseButton);
        end

        return found
    end

    function ActionButtonMixin:SetMacro_RemovePandariaGem_InBag(itemID, mouseButton)
        local found, socketIndex = SocketHelper:ExtractGemFromContainer(itemID);

        if found then
            local macroText = GetRemoveSocketMacro(socketIndex);
            self:SetMacroText(macroText, mouseButton);
        else
            self:SetMacroText(nil, mouseButton);
        end

        return found
    end

    function ActionButtonMixin:SetAction_RemovePandariaGem(itemID)
        local spellID = 433397;

        self.socketFunc = function(button)
            SocketHelper:SuppressItemSocketingFrame();

            if button == "RightButton" then
                self:SetMacro_RemovePandariaGem_Equipped(itemID, button);
            elseif button == "LeftButton" then
                if SocketHelper:PlaceGemInBestSlot(itemID) then

                else
                    self:SetMacro_RemovePandariaGem_InBag(itemID, button);
                end
            end
        end;

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");
        self:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetAction_RemovePandariaMetaGem(itemID)
        local spellID = 433397;

        self.socketFunc = function(button)
            SocketHelper:SuppressItemSocketingFrame();

            if button == "RightButton" then
                self:SetMacro_RemovePandariaGem_Equipped(itemID, button);
            elseif button == "LeftButton" then
                local dataProvider = Gemma:GetDataProviderByName("Pandaria");
                local existingGem = dataProvider:GetConflictGemItemID(itemID);

                if existingGem then
                    self:SetMacro_RemovePandariaGem_Equipped(existingGem, button);
                    SocketHelper:SetPendingGem(itemID);
                else
                    if SocketHelper:PlaceGemInBestSlot(itemID) then

                    else
                        self:SetMacro_RemovePandariaGem_InBag(itemID, button);
                    end
                end
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");
        self:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetAction_RemovePandariaPrimaryGem(itemID)
        local spellID = 433397;

        self.socketFunc = function(button)
            SocketHelper:SuppressItemSocketingFrame();

            if button == "LeftButton" then
                self:SetMacro_RemovePandariaGem_Equipped(itemID, button);
            else
                self:SetMacroText(nil, "RightButton");
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");
        self:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetAction_InsertPandariaPrimaryGem(itemID)
        self.socketFunc = function(button)
            SocketHelper:SuppressItemSocketingFrame();

            if button == "LeftButton" then
                if SocketHelper:PlaceGemInBestSlot(itemID) then

                else
                    self:SetMacro_RemovePandariaGem_InBag(itemID, button);
                end
            else
                self:SetMacroText(nil, "RightButton");
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");
        self:SetWatchedSpell(nil);
    end



    --Loadout
    function ActionButtonMixin:SetAction_RemovePandariaGemOnPlayer(slotID, socketIndex)
        self.socketFunc = function(button)
            if button == "LeftButton" then
                SocketHelper:SocketInventorySlot(slotID);
                local macroText = GetRemoveSocketMacro(socketIndex);
                self:SetMacroText(macroText, button);
            else
                self:SetMacroText(nil, "RightButton");
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");

        local spellID = 433397;
        self:SetWatchedSpell(spellID);
    end

    function ActionButtonMixin:SetAction_RemovePandariaGemInBag(gemItemID)
        self.socketFunc = function(button)
            if button == "LeftButton" then
                local bag, slot, socketIndex = BagScan:GetGemPositionInBagEquipment(gemItemID);
                if bag and slot then
                    SocketHelper:SocketContainerSlot(bag, slot);
                    local macroText = GetRemoveSocketMacro(socketIndex);
                    self:SetMacroText(macroText, button);
                else
                    self:SetMacroText(nil, "LeftButton");
                end
            else
                self:SetMacroText(nil, "RightButton");
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");

        local spellID = 433397;
        self:SetWatchedSpell(spellID);
    end
end


do  --Remove All Sockets
    local SOCKETABLE_SLOTS = {
        1, 2, 3, 5, 9,
        10, 6, 7, 8,
        11, 12, 13, 14,
    };

    local function GetSlotForExtract()
        local itemLink;
        for _, slotID in ipairs(SOCKETABLE_SLOTS) do
            itemLink = GetInventoryItemLink("player", slotID);
            if itemLink and GetItemNumSockets(itemLink) > 0 then
                for socketIndex = 1, 3 do
                    if GetItemGemID(itemLink, socketIndex) then
                        return slotID
                    end
                end
            end
        end
    end

    function ActionButtonMixin:SetAction_RemoveAllPandariaGems()
        self.socketFunc = function(button)
            if button == "LeftButton" then
                local slotID = GetSlotForExtract();
                if slotID then
                    if not SPELLNAME_EXTRACT_GEM then
                        SPELLNAME_EXTRACT_GEM = GetSpellName();
                    end
                    local macroText = string.format("/stopspelltarget\r/cast %s\r/use %s", SPELLNAME_EXTRACT_GEM, slotID);
                    self:SetMacroText(macroText, "LeftButton");
                else
                    self:SetMacroText(nil, "LeftButton");
                end
            else
                self:SetMacroText(nil, "RightButton");
            end
        end

        local macroText = "";
        self:SetMacroText(macroText, "AnyButton");

        local spellID = 433397;
        self:SetWatchedSpell(spellID);
    end
end