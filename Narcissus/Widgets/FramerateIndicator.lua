local FREQUENCY = 0.25;
local NUM_BLIPS = 10 --math.floor(1.5/FREQUENCY);
local INDEX = 1;

local BLIP_RANGE_Y = 20;
local FPS_CEILING = 60;
local FPS_FLOOR = 50;
local FPS_RANGE = 10;

local GetFramerate = GetFramerate;

local function GetBlipColor(fps)
    local ratio = (fps - 30)*0.033;
    if ratio >= 1 then
        return 0, 1, 0
    elseif ratio > 0.5 then
        return 1 - (ratio - 0.5)*2, 1, 0
    else
        return 1, ratio*2, 0
    end
end

local function GetOffsetY(fps)
    return fps*2
end

local function GetFPS(offsetY)
    return offsetY*FPS_RANGE/BLIP_RANGE_Y + FPS_FLOOR
end

NarciFramerateIndicatorMixin = {};

function NarciFramerateIndicatorMixin:OnLoad()
    self.y0 = 0;
end

function NarciFramerateIndicatorMixin:OnShow()
    self.t = 0;
    INDEX = 1;
    self.lastFPS = GetFramerate();
    self.bottomFPS = self.lastFPS;
    self.offsetY = -GetOffsetY(self.bottomFPS);
    self.RefTexture:SetPoint("CENTER", self, "CENTER", 0, self.offsetY);
    self.fromY = GetOffsetY(self.lastFPS);
    self.toY = self.fromY;
    self.lastY = 0;
    if not self.blips then
        self.blips = {};
    end
end

function NarciFramerateIndicatorMixin:AcquireBlip()
    local blip = self.blips[INDEX];
    if not blip then
        self.blips[INDEX] = self:CreateTexture(nil, "OVERLAY", "NarciFramerateIndictorBlipTemplate");
        blip = self.blips[INDEX];
    end
    blip:ClearAllPoints();
    blip.AnimFade:Stop();
    INDEX = INDEX + 1;
    if INDEX > NUM_BLIPS then
        INDEX = 1;
    end
    return blip
end

function NarciFramerateIndicatorMixin:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t >= FREQUENCY then
        self.t = self.t - FREQUENCY;
        self.fromY = self.toY;
    else
        --local fps = GetFramerate();
        self.ratio = self.t/FREQUENCY;
        self.y = (1 - self.ratio)*self.fromY + (self.ratio)*self.toY;
        local dY = self.offsetY + self.y;
        --[[
        if dY > 8 or dY < -8 then
            if dY > 0 then
                self.offsetY = self.offsetY - dY + 8;
            else
                self.offsetY = self.offsetY - dY - 8;
            end
            self.RefTexture:SetPoint("CENTER", self, "CENTER", 0, self.offsetY);
        --]]
        if dY > 1 or dY < -1 then
            local d;
            if dY > 16 or -dY < 16 then
                d = 16;
            elseif dY > 8 or -dY < -8 then
                d = 4;
            else
                d = 4;
            end
            self.offsetY = self.offsetY - dY * elapsed * d;
            self.RefTexture:SetPoint("CENTER", self, "CENTER", 0, self.offsetY);
        end
        self.MainBlip:SetPoint("CENTER", self.RefTexture, "BOTTOM", 0, self.y);
        self.MainBlip:SetVertexColor(GetBlipColor(self.y));
        if (self.y - self.lastY) > 4 or (self.y - self.lastY) < -4 then
            local blip = self:AcquireBlip();
            blip:SetPoint("CENTER", self.RefTexture, "BOTTOM", 0, self.y);
            blip:SetVertexColor(GetBlipColor(self.y));
            blip.AnimFade:Play();
            self.lastY = self.y;
        end
        return
    end
    local fps = GetFramerate();
    self.FPSText:SetText(string.format("%.1f", fps));
    self.toY = GetOffsetY(fps);
    local blip = self:AcquireBlip();
    blip:SetPoint("CENTER", self.RefTexture, "BOTTOM", 0, self.fromY);
    blip.AnimFade:Play();
    blip:SetVertexColor(GetBlipColor(self.fromY));
end
