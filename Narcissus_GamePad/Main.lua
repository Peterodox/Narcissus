local _, addon = ...


local SetOverrideBindingClick = SetOverrideBindingClick;
local ClearOverrideBindings = ClearOverrideBindings;
local IsKeyDown = IsKeyDown;

local GamePadButtonPool = addon.GamePadButtonPool;
local ACTION_GOUPS = addon.actionGroups;

local ActiveGroup = {};

local KeyListener, Repeater;
local Loader = CreateFrame("Frame");


local ModuleManager = Narci.ModuleManager;

local function SignalGamePadActive()
end

if ModuleManager then
    function SignalGamePadActive()
        ModuleManager:OnGamePadActiveChanged(true);
    end
    ModuleManager:AddGamePadCallbackWidget(Loader);
end


local function SelectActionGroup(name, mode)
    if ACTION_GOUPS[name] then
        if ActiveGroup.currentObj and ActiveGroup.currentObj.OnLeave then
            ActiveGroup.currentObj:OnLeave();
        end
        GamePadButtonPool:HideAllButtons();
        ActiveGroup = ACTION_GOUPS[name];
        ActiveGroup:Activate(mode);
        Repeater:SetInterval(ActiveGroup.repeatInterval);

        --print("Action Group: "..name);
    else
        print("Failed to find: "..name);
    end
end

addon.SelectActionGroup = SelectActionGroup;


--courtesy of Munk (dev of ConsolePort and Immersion)
local Proxy = CreateFrame("Button", "NarciPadClickProxy", nil, "InsecureActionButtonTemplate");
addon.ClickProxy = Proxy;
Proxy:SetAttribute("type", "click");

function Proxy:SetClickTarget(object)
    SetOverrideBindingClick(Proxy, true, "PAD3", "NarciPadClickProxy");
    self:SetAttribute("type", "click");
    self:SetAttribute("clickbutton", object);
end

function Proxy:SetUseItem(slotID)
    SetOverrideBindingClick(Proxy, true, "PAD3", "NarciPadClickProxy");
	self:SetAttribute("type", "item");
	self:SetAttribute("item", slotID);
end

function Proxy:SetRunMacro(macroText)
    if macroText then
        SetOverrideBindingClick(Proxy, true, "PAD3", "NarciPadClickProxy");
        self:SetAttribute("type", "macro");
        self:SetAttribute("macrotext", macroText);
    else
        self:Remove();
    end
end

function Proxy:SetCancelCast()
    ClearOverrideBindings(self)
    SetOverrideBindingClick(Proxy, true, "PAD2", "NarciPadClickProxy");
    self:SetAttribute("type", "macro");
    self:SetAttribute("macrotext", "/stopcasting");
end

function Proxy:Remove()
    ClearOverrideBindings(self)
end


local IsNavigationKeys = {
    ["PADRSHOULDER"] = true,
    ["PADLSHOULDER"] = true,
    ["PADDLEFT"] = true,
    ["PADDRIGHT"] = true,
    ["PADDUP"] = true,
    ["PADDDOWN"] = true,
};

local SIGNAL_PRESS = {
    ["PAD1"] = true,
    ["PAD2"] = true,
    ["PAD3"] = true,
    ["PAD4"] = true,
}



--Process hardware input
KeyListener = CreateFrame("Frame");
KeyListener.isButtonDown = {};
KeyListener:Hide();
KeyListener:SetPropagateKeyboardInput(false);

Repeater = CreateFrame("Frame", nil, KeyListener);
Repeater:Hide();

KeyListener:RegisterEvent("PLAYER_REGEN_DISABLED");
KeyListener:RegisterEvent("MODIFIER_STATE_CHANGED");

KeyListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Deactivate();
    else
        self:SetModifierState(...)
    end
end);

function KeyListener:SetModifierState(key, down)
    self.isButtonDown[key] = down == 1;
end

function KeyListener:IsButtonDown(key)
    return self.isButtonDown[key]
end

function KeyListener:ResetButtonStates()
    self.isButtonDown = {};
end

KeyListener:SetScript("OnKeyDown", function(self, key, down)
    --print("|cFF8cd964"..key);
    self:SetPropagateKeyboardInput(true);
end);

KeyListener:SetScript("OnKeyUp", function(self, key, down)
    --print("|cFFff8000"..key);
    self:SetPropagateKeyboardInput(true);
end);

KeyListener:SetScript("OnGamePadStick", function(self, ...)
    if self:IsButtonDown("PADRTRIGGER") or self:IsButtonDown("RCTRL") then
        local stick, x, y, a = ...
        if stick == "Right" then
            y = 0.1 * y;
            if y > 0 then
                CameraZoomIn(y);
            elseif y < 0 then
                CameraZoomOut(-y);
            else

            end
            self:SetPropagateKeyboardInput(false);
        end
    else
        local stick, x, y, a = ...
        if stick == "Right" then
            addon.CameraRotater:Yaw(x);
            self:SetPropagateKeyboardInput(false);
        end
    end
end)

KeyListener:SetScript("OnGamePadButtonDown", function(self, key)
    --print("|cFF8cd964"..key);
    if key == "PADBACK" or key == "PADSYSTEM" then
        Narci:CloseCharacterUI();
        return
    end

    self.isButtonDown[key] = true;
    SignalGamePadActive();
    local hold, propagate = self:ProcessKeyDown(key);
    if hold and IsNavigationKeys[key] then
        self:HoldKey(key);
    else
        Repeater:Stop();
    end

    self:SetPropagateKeyboardInput(propagate);
    if SIGNAL_PRESS[key] then
        GamePadButtonPool:SignalPress(key);
    end
end)

KeyListener:SetScript("OnGamePadButtonUp", function(self, key)
    --print("|cFFff8000"..key);
    self.isButtonDown[key] = false;
    Repeater:Stop();
    self:ProcessKeyUp(key);
end)

function KeyListener:ProcessKeyDown(key, isRepeated)
    local hold, propagate;
    if IsNavigationKeys[key] then
        if key == "PADDLEFT" then
            hold, propagate = ActiveGroup:Navigate(-1, 0);
        elseif key == "PADDRIGHT" then
            hold, propagate = ActiveGroup:Navigate(1, 0);
        elseif key == "PADDUP" then
            hold, propagate = ActiveGroup:Navigate(0, 1);
        elseif key == "PADDDOWN" then
            hold, propagate = ActiveGroup:Navigate(0, -1);
        elseif key == "PADLSHOULDER" then
            hold, propagate = ActiveGroup:Switch(-1);
        elseif key == "PADRSHOULDER" then
            hold, propagate = ActiveGroup:Switch(1);
        else

        end
    else
        hold, propagate = ActiveGroup:KeyDown(key);
    end

    if propagate == nil then
        propagate = false;
    end

    return hold, propagate
end

function KeyListener:ProcessKeyUp(key)
    ActiveGroup:KeyUp(key);
end

function KeyListener:HoldKey(key)
    Repeater:SetKeyAndStart(key);
end

function KeyListener:Activate()
    self:Show();
    self:EnableGamePadButton(true);
    self:EnableKeyboard(true);
    self:SetFrameStrata("FULLSCREEN_DIALOG");
    self:SetFrameLevel(1208);
end

function KeyListener:Deactivate()
    self:Hide();
    self:SetPropagateKeyboardInput(true);
    Proxy:Remove();
end


--Hold to Repeat Aey Actions
Repeater.t = 0;
Repeater.interval = 0.25;
Repeater:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > self.interval then
        self.t = 0;
        if self.key and KeyListener:IsButtonDown(self.key) then
            local isValid = KeyListener:ProcessKeyDown(self.key, true);
            if not isValid then
                self:Hide();
            end
        else
            self:Hide();
        end
    end
end);

Repeater:SetScript("OnHide", function(self)
    self.callBack = nil;
    self.t = 0;
end);

function Repeater:SetInterval(interval)
    self.interval = interval or 0.25;
end

function Repeater:SetKeyAndStart(key)
    if key then
        self:Hide();
        self.key = key;
        self:Start();
    else
        self:Stop();
    end
end

function Repeater:Start()
    self.t = -0.25;     --initial delay
    self:Show();
end

function Repeater:Stop()
    self:Hide();
end





------------------------------------------------------
Loader:RegisterEvent("ADDON_LOADED");
--[[
Loader:RegisterEvent("GAME_PAD_ACTIVE_CHANGED");
Loader:RegisterEvent("GAME_PAD_CONFIGS_CHANGED");
Loader:RegisterEvent("GAME_PAD_CONNECTED");
Loader:RegisterEvent("GAME_PAD_DISCONNECTED");

function Loader:OnActiveChanged(isActive)
    if isActive then
        print("Game pad is active");
    else
        print("Game pad is inactive");
    end
end

function Loader:OnConfigChanged()
    print("Game pad config changed");
end

function Loader:OnConnected()
    print("Game pad connected");
end

function Loader:OnDisconnected()
    print("Game pad disconnected");
end
--]]

function Loader:Init()
    hooksecurefunc("Narci_Open", function()
        if Narci.isActive then
            KeyListener:Activate();
            SelectActionGroup("EquipmentSlot");  --CharacterFrame
        else
            self:ExitGamePadMode();
        end
    end)


    local EquipmentOption = Narci_EquipmentOption;
    hooksecurefunc(EquipmentOption, "SetFromSlotButton", function(f, slotButton, returnHome)
        SelectActionGroup("EquipmentOption", true);
    end);

    hooksecurefunc(EquipmentOption, "CloseUI", function()
        SelectActionGroup("EquipmentSlot");
    end);


    local EquipmentFlyout = Narci_EquipmentFlyoutFrame;

    hooksecurefunc(EquipmentFlyout, "DisplayItemsBySlotID", function(f, slotButton, slotChanged)
        SelectActionGroup("SwapItem", slotChanged);
    end);

    EquipmentFlyout:HookScript("OnHide", function(frame)
        SelectActionGroup("EquipmentSlot");
    end);


    hooksecurefunc(Narci_NavBar, "SelectTab", function(f, tabID)
        if tabID == 1 then
            SelectActionGroup("CharacterFrame", 1);
        elseif tabID == 2 then
            SelectActionGroup("SetManager");
        elseif tabID == 3 then
            SelectActionGroup("MythicPlus");
        elseif tabID == 4 then
            --SelectActionGroup("Soulbind");
        end
    end);


    EquipmentOption.ItemList:HookScript("OnShow", function(frame)
        SelectActionGroup("EnhancementList");
    end);

    EquipmentOption.ItemList:HookScript("OnHide", function(frame)
        SelectActionGroup("EquipmentOption");
    end);

    Narci_TitleFrame:HookScript("OnShow", function(frame)
        SelectActionGroup("TitleManager");
    end);
    Narci_TitleFrame:HookScript("OnHide", function(frame)
        SelectActionGroup("CharacterFrame");
    end);
end

function Loader:ExitGamePadMode()
    KeyListener:Deactivate();
    self:ResetNavigation();
end

function Loader:ResetNavigation()
    addon.CameraRotater:Stop();
    for name, actionGroup in pairs(ACTION_GOUPS) do
        actionGroup:ResetNavigation();
    end
end

function Loader:OnGamePadActiveChanged(isActive)
    if isActive then
        addon.GamePadNavBar:Show();
    else
        addon.GamePadNavBar:Hide();
        if ActiveGroup.currentObj and ActiveGroup.currentObj.OnLeave and not ActiveGroup.currentObj:IsMouseOver() then
            ActiveGroup.currentObj:OnLeave();
        end
        self:ResetNavigation();
    end
    GamePadButtonPool:OnGamePadActiveChanged(isActive);
end

Loader:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Narcissus_GamePad" then
            self:UnregisterEvent(event);
            self:Init();
        end
    elseif event == "GAME_PAD_ACTIVE_CHANGED" then
        self:OnActiveChanged(...);
    elseif event == "GAME_PAD_CONFIGS_CHANGED" then
        self:OnConfigChanged(...);
    elseif event == "GAME_PAD_CONNECTED" then
        self:OnConnected(...);
    elseif event == "GAME_PAD_DISCONNECTED" then
        self:OnDisconnected(...);
    end
end)