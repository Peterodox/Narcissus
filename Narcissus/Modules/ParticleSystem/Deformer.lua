local _, ParticleSystem = ...;

local Deformer = CreateFrame("Frame");
ParticleSystem.Deformer = Deformer;

local sqrt = math.sqrt;
local cos = math.cos;
local sin = math.sin;
local pow = math.pow;
local modf = math.modf;
local ceil = math.ceil;
local atan2 = math.atan2;
local pi = math.pi;

local function inOutSineCycle(startValue, endValue, amount)
    if amount > 1 then
        local r = amount % 2;
        if r > 1 then
            amount = 2 - r;
        else
            amount = r;
        end
    end
	return (startValue - endValue) / 2 * (cos(pi * amount) - 1) + startValue
end


local Attractor = {};
ParticleSystem.Attractor = Attractor;
Attractor.x = 128;
Attractor.y = -48;
Attractor.falloff = 64;
Attractor.f = 400;

function Attractor:GetForce(pX, pY)
    local dx, dy = self.x - pX, self.y - pY;
    local r = atan2(dy, dx);
    local a;
    if not dx == 0 and dy == 0 then
        a = 1/(dx*dx + dy*dy)
        if a > 1 then
            --a = 1;
        end
    else
        a = 1;
    end
    a = a * self.f;
    return a * cos(r), a * sin(r);
end

function Attractor:SetOffset(x, y)
    self.x = x;
    self.y = y;
end


function Deformer:SetParticleGroup(particleGroup)
    self.particles = particleGroup;
end

function Deformer:Start()
    print("Deformer Start")
    self.t = 0;
    self.tCount = 0;
    self:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        local aX, aY;
        --aX = 200;
        --aY = inOutSineCycle(80, -80, self.t / 1);
        local numParticles = 1;
        local p = self.particles[1];
        while p do
            aX, aY = Attractor:GetForce(p.x, p.y);
            p:SetOffsetByAcceleration(aX, aY, elapsed);
            if p:IsLive() then
                numParticles = numParticles + 1;
            end
            p = self.particles[numParticles];
        end
    end);
end

function Deformer:Stop()
    self:SetScript("OnUpdate", nil);
    self.t = 0;
end