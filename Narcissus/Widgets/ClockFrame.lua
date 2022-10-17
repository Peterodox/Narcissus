local _, addon = ...

local ceil = math.ceil;
local sin = math.sin;
local cos = math.cos;
local acos = math.acos;
local tan = math.tan;

local pi = math.pi;

local UPDATE_THRESHHOLD = 1/1000;    --update once when Δprogress > threshhold
local MAX_POLYGON_SIDES = 8;        --A polygon will be deemed as a cicle if the number of its sides is larger than this

local function SwipeTrail_PolygonInterection(radius, progress, numSides)
    --The intersection point of the polygon and a line (y = x*tanA);
    local sector = ceil(progress * numSides);
    if sector == 0 then
        return 0, radius, 0
    else
        --print("Sector: "..sector)
        local a = 2 * pi / numSides;
        local radian1 = a * (sector - 1);
        local x1, y1 = radius * sin(radian1), radius * cos(radian1);
        --print(x1, y1);
        local radian2 = a * sector;
        local x2, y2 = radius * sin(radian2), radius * cos(radian2);
        --print(x2, y2)
        local radian = 2 * pi * progress;
        local k;
        if x1 == x2 then
            local x = x2;
            local y = x * acos(radian);
            return x, y, radian
        else
            k = (y1 - y2)/(x1 - x2);
            local b = y1 - k * x1;
            local c = tan(pi/2 - radian);
            local x = b/(c - k);
            local y = c * x;
            return x, y, radian
        end
    end
end

local function SwipeTrail_PolygonAlignment(radius, progress, numSides)
    --A point moves along the edges of the polygon at a constant speed
    local sideProgress = progress * numSides;
    local sector = ceil(sideProgress);
    if sector == 0 then
        return 0, radius, 0
    else
        local a = 2 * pi / numSides;
        local radian1 = a * (sector - 1);
        local x1, y1 = radius * sin(radian1), radius * cos(radian1);
        local radian2 = a * sector;
        local x2, y2 = radius * sin(radian2), radius * cos(radian2);
        local sectorProgress = sideProgress - sector + 1;        --Won't be zero    --(progress - sectorPercentage * (sector - 1))/sectorPercentage
        local texRad = a * (sector - 2) + pi/2;
        if sectorProgress < 0.1 then
            local lastRad = texRad - a/2;
            local p = sectorProgress/0.1;
            texRad = lastRad * (1 - p) + p * texRad;
        elseif sectorProgress > 0.9 then
            local nextRad = texRad + a/2;
            local p = (0.1 - 1 + sectorProgress)/0.1;
            texRad = nextRad * p + (1 - p) * texRad;
        end
        return x2*sectorProgress + x1*(1 - sectorProgress), y2*sectorProgress + y1*(1 - sectorProgress), texRad --(2 * pi * progress)
    end
end

local function SwipeTrail_Circle(radius, progress)
    --The basic circular trail
    local radian = 2 * pi * progress;
    return radius * sin(radian), radius * cos(radian), radian
end


local SwipeTrailFunctions = {};
addon.SwipeTrailFunctions = SwipeTrailFunctions;
SwipeTrailFunctions.Polygon = SwipeTrail_PolygonAlignment;
SwipeTrailFunctions.Circle = SwipeTrail_Circle;


local function ClockFrame_OnUpdate(f, elapsed)
    f.t = f.t + elapsed;
    if f.t >= f.duration then
        f.percentage = 1;
        f:Finish();
    else
        f.percentage = f.t / f.duration;
        if f.percentage < 0 then
            f.percentage = 0;
        end
    end

    if (f.percentage - f.lastProgress) >= UPDATE_THRESHHOLD then
        local x, y, radian = f.positionFunc(f.radius, f.percentage, f.numSides);
        f.Pointer:SetPoint("CENTER", f, "CENTER", x, y);
        f.Pointer:SetRotation(-radian);
        f.lastProgress = f.percentage;
    end
end


NarciClockFrameMixin = {};

function NarciClockFrameMixin:SetSwipeRadius(radius)
    radius = radius or self.swipeRadius or self:GetHeight()/2;
    self.radius = radius;
end

function NarciClockFrameMixin:SetSwipeTrail(numSides)
    numSides = numSides or self.numPolygonSides or 0;
    if numSides > MAX_POLYGON_SIDES then
        numSides = 0;
        self.positionFunc = SwipeTrail_Circle;
    elseif numSides >= 3 then
        self.positionFunc = SwipeTrail_PolygonAlignment;
    else
        self.positionFunc = SwipeTrail_Circle;
    end
    self.numSides = numSides;
end

function NarciClockFrameMixin:Init(radius, numSides)
    self:SetSwipeRadius(radius);
    self:SetSwipeTrail(numSides);
end

function NarciClockFrameMixin:Start(fullDuration, startTime)
    self:Show();
    self.lastProgress = -1;
    self.Pointer:ClearAllPoints();
    self.duration = fullDuration;
    if not startTime then
        startTime = 0;
    elseif startTime > fullDuration then
        startTime = fullDuration;
    end
    self.t = startTime;
    self:SetScript("OnUpdate", ClockFrame_OnUpdate);
end

function NarciClockFrameMixin:Stop()
    self:SetScript("OnUpdate", nil);
    self:Hide();
end

function NarciClockFrameMixin:Finish()
    self:Stop();
    if self.onFinishedFunc then
        self.onFinishedFunc(self);
    end
end

function NarciClockFrameMixin:OnHide()
    if not self.keepOnHide then
        self:Stop();
    end
end

function NarciClockFrameMixin:SetPointerTexture(texFile)
    self.Pointer:SetTexture(texFile, nil, nil, "LINEAR");
end