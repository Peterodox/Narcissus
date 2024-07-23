local _, addon = ...

local TransitionAPI = addon.TransitionAPI;
local LightControl = addon.PhotoModeLightController;

local FadeFrame = NarciFadeUI.Fade;

local BUTTONS_PER_PAGE = 8;
local MAX_SAVES = 50;
local PRESET_BUTTON_HEIGHT = 24;

local MainFrame;
local PresetButtons;

local function RemoveData(data)
    local profile = MainFrame:GetProfile();

    for i, d in ipairs(profile) do
        if d == data then
            table.remove(profile, i);
            return true
        end
    end
end

local function Shared_OnDragStart()
    MainFrame:StartMoving();
end

local function Shared_OnDragStop()
	MainFrame:StopMovingOrSizing();
end

local function Shared_OnEnter()
    MainFrame:FadeIn();
end

local function Shared_OnLeave()
    if not MainFrame:IsMouseOver() then
        MainFrame:FadeOut();
    end
end

---- Preset Button: Displays Location and Time, Colors
NarciPhotoModeLightingPresetButtonMixin = {};

function NarciPhotoModeLightingPresetButtonMixin:OnEnter()
    self.LocationText:SetTextColor(1, 1, 1, 1);
end

function NarciPhotoModeLightingPresetButtonMixin:OnLeave()
    self.LocationText:SetTextColor(0.72, 0.72, 0.72);
end

function NarciPhotoModeLightingPresetButtonMixin:OnClick(button)
    --Apply color settings
    if not self.data then return end;

    local data = self.data;

    if button == "LeftButton" then
        TransitionAPI.SetModelLight( Narci:GetActiveActor(), data.enabled, data.omni, data.dirX, data.dirY, data.dirZ, data.ambIntensity, data.ambR, data.ambG, data.ambB, data.dirIntensity, data.dirR, data.dirG, data.dirB );
        LightControl:SetLightWidgetFromActiveModel();
    elseif button == "MiddleButton" then
        local result = RemoveData(data);
        if result then
            MainFrame:LoadProfile();
        end
    end
end

function NarciPhotoModeLightingPresetButtonMixin:SetData(data)
    self.data = data;

    local zoneName = data.zoneName or "Preset";

    if data.time then
        zoneName = zoneName.."  "..data.time
    end

    self.LocationText:SetText(zoneName);

    local a1 = data.dirIntensity;
    local r1, g1, b1 = data.dirR, data.dirG, data.dirB;
    local minColor1 = CreateColor(a1*r1, a1*g1, a1*b1, 1);
    local maxColor1 = CreateColor(a1*r1, a1*g1, a1*b1, 0);
    self.DirectionalLightTexture:SetGradient("HORIZONTAL", minColor1, maxColor1);

    local a2 = data.ambIntensity;
    local r2, g2, b2 = data.ambR, data.ambG, data.ambB;
    local minColor2 = CreateColor(a2*r2, a2*g2, a2*b2, 0);
    local maxColor2 = CreateColor(a2*r2, a2*g2, a2*b2, 1);
    self.AmbientLightTexture:SetGradient("HORIZONTAL", minColor2, maxColor2);
end


NarciPhotoModeLightingPresetFrameMixin = {};

function NarciPhotoModeLightingPresetFrameMixin:OnLoad()
    MainFrame = self;
    self.page = 1;
    self.maxPage = 0;

    local footerHeight = 12;

    self:SetHeight( (PRESET_BUTTON_HEIGHT) * BUTTONS_PER_PAGE + footerHeight);

    self:RegisterForDrag("LeftButton");
    self:SetScript("OnDragStart", Shared_OnDragStart);
    self:SetScript("OnDragStop", Shared_OnDragStop);
    self:SetScript("OnEnter", Shared_OnEnter);
    self:SetScript("OnLeave", Shared_OnLeave);

    local function AddButton_OnEnter(f)
        f.Icon:SetVertexColor(1, 1, 1);
    end

    local function AddButton_OnLeave(f)
        f.Icon:SetVertexColor(0.72, 0.72, 0.72);
    end

    local function AddButton_OnClick(f)
        MainFrame:SaveCurrentLighting();
    end

    self.Footer.AddButton:SetScript("OnEnter", AddButton_OnEnter);
    self.Footer.AddButton:SetScript("OnLeave", AddButton_OnLeave);
    self.Footer.AddButton:SetScript("OnClick", AddButton_OnClick);
    AddButton_OnLeave(self.Footer.AddButton);
end

function NarciPhotoModeLightingPresetFrameMixin:UpdatePage()
    local profile = self:GetProfile();
    local index;
    local indexOffset = (self.page - 1) * BUTTONS_PER_PAGE;
    local button;

    for i = 1, BUTTONS_PER_PAGE do
        index = i + indexOffset;
        if profile[index] then
            button = self:AcquireButton(i);
            button:SetData(profile[index]);
            button:Show();
        else
            if PresetButtons and PresetButtons[i] then
                PresetButtons[i]:Hide();
            end
        end
    end
end

function NarciPhotoModeLightingPresetFrameMixin:AcquireButton(index)
    if not PresetButtons then
        PresetButtons = {};
    end

    if not PresetButtons[index] then
        PresetButtons[index] = CreateFrame("Button", nil, self, "NarciPhotoModeLightingPresetButton");
        PresetButtons[index]:SetPoint("TOP", self, "TOP", 0, (PRESET_BUTTON_HEIGHT)*(1 - index));
        PresetButtons[index]:OnLeave();
        PresetButtons[index]:RegisterForDrag("LeftButton");
        PresetButtons[index]:SetScript("OnDragStart", Shared_OnDragStart);
        PresetButtons[index]:SetScript("OnDragStop", Shared_OnDragStop);
        PresetButtons[index]:SetScript("OnEnter", Shared_OnEnter);
        PresetButtons[index]:SetScript("OnLeave", Shared_OnLeave);
    end

    return PresetButtons[index]
end

function NarciPhotoModeLightingPresetFrameMixin:SaveCurrentLighting()
    local profile = self:GetProfile();
    if #profile >= MAX_SAVES then return end;

    local model = Narci:GetActiveActor();
    if not model then return end;

    --local enabled, light = model:GetLight();
    local mapID = C_Map.GetBestMapForUnit("player");
    local zoneName = GetMinimapZoneText();
    local calendarTime = C_DateAndTime.GetCurrentCalendarTime();

    local data = {};

    if mapID then
        data.mapID = mapID;
    end

    if zoneName and zoneName ~= "" then
        data.zoneName = zoneName;
    end

    if calendarTime and calendarTime.hour and calendarTime.minute then
        local minute = calendarTime.minute;
        if minute < 10 then
            minute = "0"..minute;
        end
        data.time = calendarTime.hour..":"..minute;
    end

    data.enabled, data.omni, data.dirX, data.dirY, data.dirZ, data.ambIntensity, data.ambR, data.ambG, data.ambB, data.dirIntensity, data.dirR, data.dirG, data.dirB = TransitionAPI.GetModelLight(model);

    table.insert(profile, 1, data);

    self:LoadProfile();
end

function NarciPhotoModeLightingPresetFrameMixin:LoadProfile(resetPage)
    local profile = self:GetProfile();
    self.maxPage = math.ceil(#profile / MAX_SAVES);
    if resetPage then
        self.page = 1;
    end
    self:UpdatePage();
end

function NarciPhotoModeLightingPresetFrameMixin:GetProfile()
    if not NarciPhotoModeDB.SavedLightings then
        NarciPhotoModeDB.SavedLightings = {};
    end

    return NarciPhotoModeDB.SavedLightings;
end

function NarciPhotoModeLightingPresetFrameMixin:OnMouseWheel(delta)
    if delta < 0 and self.page < self.maxPage then
        self.page = self.page + 1;
    elseif delta > 0 and self.page > 1 then
        self.page = self.page - 1;
    else
        return
    end

    self:UpdatePage();
end

function NarciPhotoModeLightingPresetFrameMixin:OnShow()
    self:LoadProfile();
end

local function Fade_OnUpdate(self, elapsed)
    self.alpha = self.alpha + self.delta * elapsed;
    if self.alpha > 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    elseif self.alpha < 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha)
end

function NarciPhotoModeLightingPresetFrameMixin:FadeIn()
    self.alpha = self:GetAlpha();
    self.delta = 5;
    self:SetScript("OnUpdate", Fade_OnUpdate);
end

function NarciPhotoModeLightingPresetFrameMixin:FadeOut()
    self.alpha = self:GetAlpha();
    self.delta = -5;
    self:SetScript("OnUpdate", Fade_OnUpdate);
end