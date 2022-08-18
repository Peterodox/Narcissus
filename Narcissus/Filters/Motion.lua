

--[[
local _, addon = ...

local FOV_MIN = 60;
local FOV_MAX = 90;
local MIN_BLEND_TIME = 0.25;
local MAX_ZOOM = 8;

local CameraFrame = CreateFrame("Frame", "FoVFrame");
local outQuart = addon.EasingFunctions.outQuart;
local inOutSine = addon.EasingFunctions.inOutSine;   --(t, b, e, d)
local linear = addon.EasingFunctions.linear;

local GetCVar = GetCVar;
local SetCVar = SetCVar;
local ConsoleExec = ConsoleExec;
local GetUnitSpeed = GetUnitSpeed;
local GetCameraZoom = GetCameraZoom;
local FadeFrame = NarciFadeUI.Fade;

local BlurOverlay = CameraFrame:CreateTexture(nil, "OVERLAY");
BlurOverlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
BlurOverlay:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0);
BlurOverlay:SetAlpha(1);
BlurOverlay:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Filters\\MotionBlurStrip");
BlurOverlay:SetBlendMode("ADD");

local BlurMask = CameraFrame:CreateMaskTexture("MK", "OVERLAY");
BlurMask:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
BlurMask:SetSize(320, 180);
BlurOverlay:AddMaskTexture(BlurMask);
BlurMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Filters\\MotionBlurMaskRing", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");



local BlurController = CreateFrame("Frame", "BC");
BlurController.blurDuration = 0.5;
BlurController.fadeDelay = 0.25;

local function Blur_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.fadeDelay then
        local alpha = 1 - 4*(self.t - self.fadeDelay);
        if alpha < 0 then
            alpha = 0;
            BlurOverlay:SetAlpha(0);
            self:SetScript("OnUpdate", nil);
        elseif alpha < 1 then
            BlurOverlay:SetAlpha(alpha);
        end
    end

    if self.t <= self.blurDuration then
        local scale = outQuart(self.t, 3, 13, self.blurDuration);
        BlurMask:SetScale(scale);
    end
end

function BlurController:Start()
    self.t = 0;
    BlurOverlay:SetAlpha(1);
    BlurMask:SetScale(1);
    self:SetScript("OnUpdate", Blur_OnUpdate);
end


local function FoV_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    local fov;

    if self.t <= self.maxDuration then
        fov = self.easeFunc(self.t, self.fromFoV, self.toFoV, self.maxDuration);
    else
        self:SetScript("OnUpdate", nil);
    end

    if fov then
        SetCVar("camerafov", fov);
    end
end

local function GetBlendTime(baseTime, fromValue, toValue)
    local t = baseTime * math.abs(fromValue - toValue)/(FOV_MAX - FOV_MIN);
    if t < MIN_BLEND_TIME then
        return MIN_BLEND_TIME
    else
        return t
    end
end

function CameraFrame:In()
    if not self.zoomIn then
        self.zoomIn = true;
    else
        return
    end

    self.t = 0;
    self.easeFunc = outQuart;
    self.fromFoV = tonumber(GetCVar("camerafov"));
    self.toFoV = FOV_MAX;
    self.maxDuration = GetBlendTime(1, self.fromFoV, self.toFoV);
    self:SetScript("OnUpdate", FoV_OnUpdate);
    self.fromZoom = GetCameraZoom();
    CameraZoomOut(MAX_ZOOM);
    self.cameraChanged = true;

    BlurController:Start();
end

function CameraFrame:Out()
    if self.zoomIn then
        self.zoomIn = false;
    else
        return
    end

    self.t = 0;
    self.easeFunc = inOutSine;
    self.fromFoV = tonumber(GetCVar("camerafov"));
    self.toFoV = FOV_MIN;
    self.maxDuration = GetBlendTime(2, self.fromFoV, self.toFoV);
    self:SetScript("OnUpdate", FoV_OnUpdate);
    if self.cameraChanged then
        self.cameraChanged = false;
        local diff = GetCameraZoom() - self.fromZoom;
        if diff > 0 then
            CameraZoomIn(diff);
        end
    end
end


local SpeedWatcher = CreateFrame("Frame");
SpeedWatcher:SetScript("OnUpdate", function(self, elapsed)
    self.currentSpeed, self.runSpeed = GetUnitSpeed("player");
    self.speed = self.runSpeed;
    if self.speed ~= self.lastSpeed then
        if self.lastSpeed then
            local speedDiff = self.speed - self.lastSpeed;
            if speedDiff > 0 then
                if speedDiff > 50 then
                    CameraFrame:In()
                end
            else
                CameraFrame:Out()
            end
        end
        self.lastSpeed = self.speed;
        print("Speed: "..self.speed);
    end
end)
--]]