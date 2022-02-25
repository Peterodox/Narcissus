local _, ParticleSystem = ...;

local ParticleMixin = ParticleSystem.ParticleMixin;
local Deformer = ParticleSystem.Deformer;
local Collider = ParticleSystem.Collider;
local Attractor = ParticleSystem.Attractor;

local random = math.random;
local tinsert = table.insert;
local tremove = table.remove;

local function Mixin(object, mixin)
    for k, v in pairs(mixin) do
        object[k] = v;
    end
	return object;
end

local function GetRandom()
    return (random(100, 200)/100);
end

local MAX_PARTICLES = 400;
local NUM_PARTICLE_PER_PULSE = 8;

local Emitter = CreateFrame("Frame");


local Pool = {};
Pool.all = {};
Pool.dead = {};
Pool.live = {};
Pool.numAll = 0;
Pool.numDead = 0;
Pool.numLive = 0;

function ParticleMixin:Kill()
    self:Hide();
    self.isLive = nil;
    self:ClearAllPoints();
    --Add to the "deadpool"
    Pool:Collect(self);
end

local testContainer = CreateFrame("Frame");
testContainer:SetSize(256, 256);
testContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

local colliderTexture = testContainer:CreateTexture(nil, "OVERLAY");
colliderTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Particles\\Collider.tga");
colliderTexture:SetSize(64, 64);
colliderTexture:SetPoint("CENTER", testContainer, "TOPLEFT", 128, -48);

local labels = {"Total: ", "Live: ", "Dead: "};
local indicators = {};
for i = 1, 3 do
    indicators[i] = testContainer:CreateFontString(nil, "OVERLAY", "NarciTooltipDescriptionFontSmall");
    indicators[i]:SetPoint("TOPLEFT", testContainer, "TOPLEFT", -80,  -12 * i);
    local label = testContainer:CreateFontString(nil, "OVERLAY", "NarciTooltipDescriptionFontSmall");
    label:SetPoint("TOPLEFT", testContainer, "TOPLEFT", -110,  -12 * i);
    label:SetText(labels[i]);
end

function Pool:Accquire()
    local numDead = self.numDead;
    local p = self.dead[numDead];
    if p then
        self.dead[numDead] = nil;
        self.numDead = numDead - 1;
    else
        local numAll = self.numAll;
        if numAll < MAX_PARTICLES then
            p = testContainer:CreateTexture(nil, "OVERLAY", "NarciDynamicTextParticleTemplate");
            Mixin(p, ParticleMixin);
            numAll = numAll + 1;
            --self.all[numAll] = p;
            tinsert(self.all, p);
            self.numAll = numAll;
            p:ClearAllPoints();
            p:SetParticleTexture("Interface\\AddOns\\Narcissus\\Art\\Particles\\Sphere.tga");
            p:SetRadius(4);
        end
    end

    if p then
        self.numLive = self.numLive + 1;
        self.live[self.numLive] = p;
        return p
    end
end

function Pool:Collect(particle)
    for i = 1, self.numLive do
        if particle == self.live[i] then
            tremove(self.live, i);
            self.numLive = self.numLive - 1;
            break
        end
    end
    local numDead = self.numDead + 1;
    self.numDead = numDead;
    self.dead[numDead] = particle;
end

Deformer:SetParticleGroup(Pool.live);


function Emitter:SetPosition(point, relativeTo, relativePoint, x, y)
    self:SetPoint(point, relativeTo, relativePoint, x, y);
    self.point = point;
    self.relativeTo = relativeTo;
    self.relativePoint = relativePoint;
    self.x0 = x;
    self.y0 = y;
end

function Emitter:SetVelocity(vX, vY)
    self.vX = vX or 0;
    self.vY = vY or 0;
end

function Emitter:SetBirthrate(birthrate)

end

function Emitter:SetInterval(interval)
    self.interval = interval or 0;
end

function Emitter:Start()
    self.t = 0;
    self:SetScript("OnUpdate", function(f, elapsed)
        self.t = self.t + elapsed;
        if self.t >= self.interval then
            self.t = 0;
            self:Emit();

            --Counter
            indicators[1]:SetText(Pool.numAll);
            indicators[2]:SetText(Pool.numLive);
            indicators[3]:SetText(Pool.numDead);
        end
    end);
end

function Emitter:Stop()
    self:SetScript("OnUpdate", nil);
end

function Emitter:Emit()
    local p;
    for i = 1, NUM_PARTICLE_PER_PULSE do
        p = Pool:Accquire();
        if p then
            p:Init(self.vX, self.vY);
            p:SetWeight( 1 );   --GetRandom()
            p:SetPosition(testContainer, "TOPLEFT", 0, -32 -4 * i);
            p:Show();
        end
    end
end

Emitter:SetVelocity(0, 0);
Emitter:SetInterval(0.2);


--Public
--/run TestEmitter()
function TestEmitter()
    Emitter:SetVelocity(200, 0);
    Emitter:SetInterval(0.1);
    Emitter:Start();
    Deformer:Start();
end



local GetCursorPosition = GetCursorPosition;
local UpdateFrame = CreateFrame("Frame");
UpdateFrame.t = 0
UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.x, self.y = GetCursorPosition();
    colliderTexture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.x, self.y);
    self.t = self.t + elapsed;
    if self.t > 0.0 then
        self.t = 0;
        if not self.x0 then
            self.x0 = testContainer:GetLeft();
            self.y0 = testContainer:GetTop();
        end
        --Collider:SetOffset(self.x - self.x0, self.y - self.y0);
        Attractor:SetOffset(self.x - self.x0, self.y - self.y0);
    end
end);