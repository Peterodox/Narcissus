local _, addon = ...

--Hotkey
local RotateBarberShopCamera = C_BarberShop.RotateCamera;
local CameraRotator = CreateFrame("Frame");
CameraRotator:Hide();
CameraRotator.speed = 0;
CameraRotator.maxSpeed = 2.5;
CameraRotator.direction = 1;    --Counterclockwise
CameraRotator:SetScript("OnUpdate", function(self, elapsed)
    local direction = self.direction;
    local speed = self.speed + 12 * elapsed * direction;
    if direction > 0 then
        if speed > self.maxSpeed then
            speed = self.maxSpeed;
        end
    elseif direction < 0 then
        if speed <= -self.maxSpeed then
            speed = -self.maxSpeed;
        end
    else
        --inertia
        if self.lastDirection > 0 then
            speed = speed - 16 * elapsed;
            if speed <= 0 then
                speed = 0;
                self.lastDirection = 0;
                self:Hide();
            end
        else
            speed = speed + 16 * elapsed;
            if speed >= 0 then
                speed = 0;
                self.lastDirection = 0;
                self:Hide();
            end
        end
    end

    self.speed = speed;
    RotateBarberShopCamera(speed);
end)

local ZoomCamera = C_BarberShop.ZoomCamera;
local CameraZoomer = CreateFrame("Frame");
CameraZoomer:Hide();
CameraZoomer.direction = 1;
CameraZoomer.amountPerSecond = 150;
CameraZoomer:SetScript("OnUpdate", function(self, elapsed)
    ZoomCamera( self.direction * self.amountPerSecond * elapsed );
end)


local function RotateBarberShopCameraLeft()
    CameraRotator:Hide();
    CameraRotator.direction = -1;
    CameraRotator.lastDirection = -1;
    CameraRotator:Show();
end

local function RotateBarberShopCameraRight()
    CameraRotator:Hide();
    CameraRotator.direction = 1;
    CameraRotator.lastDirection = 1;
    CameraRotator:Show();
end

local function StopRotatingCamera()
    CameraRotator.direction = 0;
end

local function ZoomCameraIn()
    CameraZoomer:Hide();
    CameraZoomer.direction = 1;
    CameraZoomer:Show();
end

local function ZoomCameraOut()
    CameraZoomer:Hide();
    CameraZoomer.direction = -1;
    CameraZoomer:Show();
end

local function StopZoomingCamera()
    CameraZoomer:Hide();
end


local HotkeyList = {
    --[key] = {downFunc, upFunc, commandName},
};

local HotkeyManager = {};
addon.HotkeyManager = HotkeyManager;


HotkeyManager.buttons = {};

HotkeyManager.ignoredKeys = {
	LALT = 1,
	RALT = 2,
	LCTRL = 3,
	RCTRL = 4,
	LSHIFT = 5,
	RSHIFT = 6,
	LMETA = 7,
	RMETA = 8,
	ALT = 9,
	CTRL = 10,
	SHIFT = 11,
    META = 12,
    UNKNOWN = true,
	BUTTON1 = true,
    BUTTON2 = true,
    BUTTON3 = true,
};

HotkeyManager.CommandList = {
    --[name] = {downFunc, upFunc, defaultKey, customKey},
    ["RotateLeft"] = {
        onMouseDownFunc = RotateBarberShopCameraLeft,
        onMouseUpFunc = StopRotatingCamera,
        defaultKey = "A",
        defaultKeyFrench = "Q",
    },

    ["RotateRight"] = {
        onMouseDownFunc = RotateBarberShopCameraRight,
        onMouseUpFunc = StopRotatingCamera,
        defaultKey = "D",
        defaultKeyFrench = "D",
    },

    ["ZoomIn"] = {
        onMouseDownFunc = ZoomCameraIn,
        onMouseUpFunc = StopZoomingCamera,
        defaultKey = "W",
        defaultKeyFrench = "Z",
    },

    ["ZoomOut"] = {
        onMouseDownFunc = ZoomCameraOut,
        onMouseUpFunc = StopZoomingCamera,
        defaultKey = "S",
        defaultKeyFrench = "S",
    },
};

function HotkeyManager:LoadHotkeys()
    --Check French Keyboard
    --GetOSLocale, GetLocale
    local isAZERTY = false;
    local key1, key2 = GetBindingKey("MOVEFORWARD");
    if key1 == "Z" or key2 == "Z" then
        isAZERTY = true;
    end

    ----
    local DB = NarciBarberShopDB;
    if not DB.Hotkeys then
        DB.Hotkeys = {};
    end
    for command, data in pairs(self.CommandList) do
        local key = DB.Hotkeys[command];
        if not key then
            if isAZERTY then
                key = data.defaultKeyFrench;
            else
                key = data.defaultKey;
            end
            DB.Hotkeys[command] = key;
        end
        if key ~= "NONE" then
            HotkeyList[key] = {data.onMouseDownFunc, data.onMouseUpFunc, command};
        end
    end
end

local function IsKeyValidForUse(key)
    if not key then return true end     --clear keybind

    if key == "ESCAPE" or key == "SPACE" then
        return false
    else
        local keybind = GetBindingFromClick(key);
        if keybind and (keybind == "TOGGLEMUSIC" or keybind == "TOGGLESOUND" or keybind == "SCREENSHOT") then
            return false
        end
    end

    return true
end

function HotkeyManager:SetHotkey(command, newKey)
    if not IsKeyValidForUse(newKey) then
        return
    end

    if command and self.CommandList[command] then
        local overriddenCommand;
        --Check conflicted command
        for key, v in pairs(HotkeyList) do
            if v then
                if v[3] == command then
                    HotkeyList[key] = nil;
                elseif key == newKey then
                    overriddenCommand = v[3];
                    HotkeyList[key] = nil;
                    NarciBarberShopDB.Hotkeys[overriddenCommand] = "NONE";
                    --print("Conflict: "..overriddenCommand)
                end
            end
        end

        local success;
        if newKey then
            if self.ignoredKeys[newKey] then
                success = false;
            else
                HotkeyList[newKey] = {self.CommandList[command].onMouseDownFunc, self.CommandList[command].onMouseUpFunc, command};
                NarciBarberShopDB.Hotkeys[command] = newKey;
                success = true;
            end
        else
            --An empty newKey will unbind the command
            NarciBarberShopDB.Hotkeys[command] = "NONE";
            success = true;
        end

        self:RefreshKeybindingButtons();

        return success
    end
end

function HotkeyManager:GetHotkey(command)
    if command and self.CommandList[command] then
        return NarciBarberShopDB.Hotkeys[command];
    end
end

function HotkeyManager:RefreshKeybindingButtons()
    for i = 1, #self.buttons do
        local key = self:GetHotkey(self.buttons[i].command);
        self.buttons[i]:SetText( key );
    end
end

function HotkeyManager:RunCommandByKeyState(key, down)
    if HotkeyList[key] then
        if down then
            if HotkeyList[key][1] then
                HotkeyList[key][1]();
                return true
            end
        else
            if HotkeyList[key][2] then
                HotkeyList[key][2]();
                return true
            end
        end
    end
end

function HotkeyManager:StopMovingCamera()
    CameraZoomer:Hide();
    CameraRotator:Hide();
end



local function KeybindingButton_OnKeyDown(self, key)
    self:Deactivate();
    if HotkeyManager:SetHotkey(self.command, key) then
        self:SetText(key);
    end
end

NarciBarberShopSettingKeyBindingButtonMixin = {};

function NarciBarberShopSettingKeyBindingButtonMixin:OnLoad()
    table.insert(HotkeyManager.buttons, self);
    self:OnLeave();
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnEnter()
    self.Background:SetVertexColor(1, 1, 1);
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnLeave()
    if not self.isOn then
        self.Background:SetVertexColor(0.6, 0.6, 0.6);
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:Activate()
    self.Background:SetTexCoord(0, 1, 0.5, 1);
    self.ButtonText:SetTextColor(0, 0, 0);
    self:SetScript("OnKeyDown", KeybindingButton_OnKeyDown);
    self:SetPropagateKeyboardInput(false);
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingKeyBindingButtonMixin:Deactivate()
    self.Background:SetTexCoord(0, 1, 0, 0.5);
    self.ButtonText:SetTextColor(1, 0.82, 0);
    self:SetScript("OnKeyDown", nil);
    self.isOn = false;
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    if not self:IsMouseOver() then
        self.Background:SetVertexColor(0.6, 0.6, 0.6);
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnClick(button)
    if button == "RightButton" then
        HotkeyManager:SetHotkey(self.command, nil);
        self:SetText("NONE");
    else
        self.isOn = not self.isOn;
        if self.isOn then
            self:Activate();
        else
            self:Deactivate();
        end
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnEvent()
    if not self:IsMouseOver() then
        self:Deactivate();
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnHide()
    if self.isOn then
        self:Deactivate();
    end
end