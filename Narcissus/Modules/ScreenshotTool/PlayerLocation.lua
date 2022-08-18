local _, addon = ...


local UPDATE_INTERVAL_MOVING = 0.5;
local UPDATE_INTERVAL_STOPPED = 1;

local format = string.format;
local GetBestMapForUnit = C_Map.GetBestMapForUnit;
local GetMapInfo = C_Map.GetMapInfo;
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition;
local GetMinimapZoneText = GetMinimapZoneText;
local IsPlayerMoving = IsPlayerMoving;
local IsInInstance = IsInInstance;

local ZONE_CHANGED_EVENTS = {
    MAP_EXPLORATION_UPDATED = true,
    ZONE_CHANGED_NEW_AREA = true,
    ZONE_CHANGED_INDOORS = true,
    ZONE_CHANGED = true,
};


NarciPlayerLocationFrameMixin = {};

function NarciPlayerLocationFrameMixin:OnLoad()
    self.threshhold = UPDATE_INTERVAL_STOPPED;
    self:RegisterEvent("DISPLAY_SIZE_CHANGED");
    self:UpdateFontSize();
end

function NarciPlayerLocationFrameMixin:UpdateFontSize()
    local fontName = "NarciFontNormal10Outline";
    local _, screenHeight = GetPhysicalScreenSize();
    local pixel = 768 / screenHeight;
    local fontHeight = 18 * pixel;
    if _G[fontName] then
        local fontPath =  _G[fontName]:GetFont();
        if fontPath then
            self.Location:SetFont(fontPath, fontHeight, "OUTLINE");
        end
    end
end

function NarciPlayerLocationFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_STARTED_MOVING");
    self:RegisterEvent("PLAYER_STOPPED_MOVING");
    self:RegisterEvent("MAP_EXPLORATION_UPDATED");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("ZONE_CHANGED_INDOORS");
    self:RegisterEvent("ZONE_CHANGED");

    self:UpdateMovingStatus();
    self:OnEvent("ZONE_CHANGED");
end

function NarciPlayerLocationFrameMixin:OnHide()
    self:UnregisterEvent("PLAYER_STARTED_MOVING");
    self:UnregisterEvent("PLAYER_STOPPED_MOVING");
    self:UnregisterEvent("MAP_EXPLORATION_UPDATED");
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
    self:UnregisterEvent("ZONE_CHANGED_INDOORS");
    self:UnregisterEvent("ZONE_CHANGED");
end

function NarciPlayerLocationFrameMixin:UpdateMovingStatus()
    if IsPlayerMoving() then
        self:OnEvent("PLAYER_STARTED_MOVING");
    else
        self:OnEvent("PLAYER_STOPPED_MOVING");
    end
end

local function PlayerLocationFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    if self.t > self.threshhold then
        self.t = 0;
        if self.updateZone then
            self.updateZone = nil;
            self:UpdateZone();
            self:UpdateMovingStatus();
        end

        if self.inInstance then
            self:SetScript("OnUpdate", nil);
        else
            self:UpdateCoordinates();
        end
    else
        return
    end
end

function NarciPlayerLocationFrameMixin:OnEvent(event, ...)
    if event == "PLAYER_STARTED_MOVING" then
        self.threshhold = UPDATE_INTERVAL_MOVING;
    elseif event == "PLAYER_STOPPED_MOVING" then
        self.t = 2;     --call update on next frame
        self.threshhold = UPDATE_INTERVAL_STOPPED;
    elseif event == "DISPLAY_SIZE_CHANGED" then
        self:UpdateFontSize();
    else
        --Zone changed
        self.t = 0;
        self.threshhold = 0.1;
        self.updateZone = true;
        self:SetScript("OnUpdate", PlayerLocationFrame_OnUpdate);
    end
end

function NarciPlayerLocationFrameMixin:UpdateZone()
    local mapName;

    local mapID = GetBestMapForUnit("player");
    self.mapID = mapID;

    if mapID then
        local mapInfo = GetMapInfo(mapID);
        if mapInfo then
            mapName = mapInfo.name;
        end
    end

    local zoneName = GetMinimapZoneText();
    if zoneName then
        if mapName and zoneName ~= mapName then
            mapName = mapName .. ": "..zoneName
        else
            mapName = zoneName;
        end
    end

    self.locationText = mapName;

    if IsInInstance() then
        self.inInstance = true;
        self.Location:SetText(mapName);
    else
        self.inInstance = nil;
        self:UpdateCoordinates();
    end
end

function NarciPlayerLocationFrameMixin:UpdateCoordinates()
    if not (self.mapID and self.locationText) then return end;

    local position = GetPlayerMapPosition(self.mapID, "player");

    if not position then return end;

    local x = position.x or 0;
    local y = position.y or 0;

    self.Location:SetText(format("%s  %.1f, %.1f", self.locationText, 100*x, 100*y));
end