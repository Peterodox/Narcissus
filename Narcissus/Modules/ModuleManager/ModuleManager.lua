local _, addon = ...

local ClearCursor = ClearCursor;    --Temp fix for unable to clear curosr while gamepad is active

local EventToAddOn = {};

local Modules = {
    {name = "Narcissus_Barbershop", triggerEvent = "BARBER_SHOP_OPEN", triggerName = "Blizzard_BarbershopUI"},
    {name = "Narcissus_GamePad", triggerEvent = "GAME_PAD_CONNECTED", },
};

local LoadAddOn = C_AddOns.LoadAddOn;
local EnableAddOn = C_AddOns.EnableAddOn;

local Manager = CreateFrame("Frame");
addon.ModuleManager = Manager;
Narci.ModuleManager = Manager;

Manager:RegisterEvent("PLAYER_ENTERING_WORLD");

Manager:SetScript("OnEvent", function(self, event, ...)
    if EventToAddOn[event] then
        for i = 1, #EventToAddOn[event] do
            local name = EventToAddOn[event][i];
            --EnableAddOn(name);    --Forced Enable
            local loaded, reason = LoadAddOn(name);
            if loaded then
                self:UnregisterEvent(event);
            end
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if C_GamePad and C_GamePad.IsEnabled() then
            LoadAddOn("Narcissus_GamePad");
            self:RegisterEvent("GAME_PAD_CONNECTED");
            self:OnGamePadConnected();
        end
        self:UnregisterEvent(event);
    end

    if event == "GAME_PAD_ACTIVE_CHANGED" then
        self:OnGamePadActiveChanged(...);
    elseif event == "GAME_PAD_CONNECTED" then
        self:OnGamePadConnected();
    elseif event == "GAME_PAD_DISCONNECTED" then
        self:OnGamePadDisconnected();
    elseif event == "GLOBAL_MOUSE_DOWN" then
        self:OnGamePadActiveChanged(false);
    end
end);


function Manager:OnGamePadActiveChanged(isActive)
    self:NotifyGamePadChange(isActive);
    if isActive then
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    else
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        --ClearCursor();    --This affect ConsolePort behavior so we no longer use it. And I forgot what issue I was trying to fix when I put it here :(
    end
end

function Manager:OnGamePadConnected()
    self:RegisterEvent("GAME_PAD_ACTIVE_CHANGED");
    self:OnGamePadActiveChanged(true);
end

function Manager:OnGamePadDisconnected()
    self:UnregisterEvent("GAME_PAD_ACTIVE_CHANGED");
    self:OnGamePadActiveChanged(false);
end

function Manager:NotifyGamePadChange(isActive)
    if isActive ~= self.isGamePadActive then
        self.isGamePadActive = isActive;
        if self.callbackWidgets then
            for i = 1, #self.callbackWidgets do
                self.callbackWidgets[i]:OnGamePadActiveChanged(isActive);
            end
        end
        --print("GamePad is now "..tostring(isActive));
    end
end

function Manager:AddGamePadCallbackWidget(widget)
    if not self.callbackWidgets then
        self.callbackWidgets = {};
    end
    if not widget then
        --print("INVALID WIDGET")
    end
    table.insert(self.callbackWidgets, widget);
end

function Manager:IsGamePadActive()
    return self.isGamePadActive
end


for i = 1, #Modules do
    local mod = Modules[i];
    local event = mod.triggerEvent;
    if event then
        Manager:RegisterEvent(event);
        if not EventToAddOn[event] then
            EventToAddOn[event] = {};
        end
        table.insert(EventToAddOn[event], Modules[i].name);
    end
end