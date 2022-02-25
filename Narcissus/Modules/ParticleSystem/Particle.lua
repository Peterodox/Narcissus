local _, ParticleSystem = ...;
local LIFESPAN = 4;
local MAX_SPEED_X = 1000;
local MAX_SPEED_Y = 1000;
local MAX_SPEED_SQUARE = MAX_SPEED_X^2 + MAX_SPEED_Y^2;
local MAX_COLLISIONS = 10;

local pi = math.pi;
local atan2 = math.atan2;
local sqrt = math.sqrt;
local sin = math.sin;
local cos = math.cos;

local Collider = {};
ParticleSystem.Collider = Collider;

Collider.x = 128;
Collider.y = -48;
Collider.r = 34;
Collider.r2 = (Collider.r)^2;
Collider.restitution = 0.8;

function Collider:IsInRange(pX, pY)
    return ( ((pX - self.x)^2 + (pY - self.y)^2) < self.r2 )
end

function Collider:GetIntersection(pX, pY)
    local dY = sqrt( (self.r + 1)^2 - (self.x - pX)^2);
    if pY < self.y then
        dY = - dY;
    end
    return pX, (self.y + dY);
end

function Collider:SetOffset(x, y)
    self.x = x;
    self.y = y;
    --print(x, y);
end


local ParticleMixin = {};
ParticleSystem.ParticleMixin = ParticleMixin;
ParticleMixin.lifespan = LIFESPAN;


function ParticleMixin:SetAttribute(killSpeed, lifespan)

end

function ParticleMixin:SetPosition(relativeTo, relativePoint, x, y)
    self:SetPoint("CENTER", relativeTo, relativePoint, x, y);
    self.relativeTo = relativeTo;
    self.relativePoint = relativePoint;
    self.x0 = x;
    self.y0 = y;
    self.x = x;
    self.y = y;
    self.left = self:GetLeft();
end

function ParticleMixin:SetOffset(x, y)
    self.x = self.x0 + x;
    self.y = self.y0 + y;
    --[[
    if Collider:IsInRange(self.x, self.y) and self.numCollisions < MAX_COLLISIONS then
        self.x, self.y = Collider:GetIntersection(self.x, self.y);
        self.numCollisions = self.numCollisions + 1;
        local a = pi - atan2(self.y - Collider.y, self.x - Collider.x);
        local b = atan2(self.vY, self.vX);
        local c = pi - 2*a - b;
        local v = sqrt(self.vX^2 + self.vY^2) * Collider.restitution;
        self.vX = v * cos(c);
        self.vY = v * sin(c);
        if self.numCollisions == 1 then
            self:SetVertexColor(42/255, 161/255, 191/255);
        elseif self.numCollisions == 2 then
            self:SetVertexColor(28/255, 108/255, 128/255);
        end
    end
    --]]
    self:SetPoint("CENTER", self.relativeTo, self.relativePoint, self.x, self.y);
    self.accuX = self.x - self.x0;
    self.accuY = self.y - self.y0;
end

function ParticleMixin:Init(velocityX, velocityY)
    self.isLive = true;
    self.accuX, self.accuY = 0, 0;
    self.vX, self.vY = velocityX, velocityY;
    self.age = 0;
    self.weight = 1;
    self.numCollisions = 0;
    self:SetVertexColor(1, 1, 1);
end

function ParticleMixin:SetWeight(weight)
    self.weight = weight or 1;
end

function ParticleMixin:SetAccumulativeOffset(relX, relY)
    self.accuX, self.accuY = self.accuX + relX, self.accuY + relY;
    self:SetOffset(self.accuX, self.accuY)
end

function ParticleMixin:SetOffsetByAcceleration(aX, aY, elapsed)
    self.age = self.age + elapsed;
    self.vX = self.vX + aX/self.weight * elapsed;
    self.vY = self.vY + aY/self.weight * elapsed;
    self.accuX, self.accuY = self.accuX + self.vX*elapsed, self.accuY + self.vY*elapsed;
    local speedSquare = self.vX*self.vX + self.vY*self.vY;
    if self.age >= LIFESPAN or speedSquare >= MAX_SPEED_SQUARE then
        self:Kill();
    else
        self:SetOffset(self.accuX, self.accuY);
        local alpha = 1 - 1*(self.age - LIFESPAN + 1) --1.5 - 4*speedSquare/MAX_SPEED_SQUARE
        if alpha < 0 then
            self:Kill();
        elseif alpha > 1 then
            alpha = 1;
        end
        self:SetAlpha(alpha);

        local scale = 1 - 0.5*(self.age - LIFESPAN + 2)
        if scale > 1 then
            scale = 1;
        end
        self:UpdateVisual(scale);
    end
end

function ParticleMixin:SetRadius(a)
    self.radius = a;
    self:SetSize(a, a);
end

function ParticleMixin:UpdateVisual(scale)
    if scale < 0.25 then
        scale = 0.25;
        --self:Kill();
        
    elseif scale > 1 then
        scale = 1;
    end
    self:SetSize( self.radius * scale, self.radius * scale);
    --self:SetAlpha(scale);
end

function ParticleMixin:Kill()
    self:Hide();
    self.isLive = nil;
    --Redefined in Emitter.lua
end

function ParticleMixin:IsLive()
    return self.isLive;
end

function ParticleMixin:SetParticleTexture(tex)
    self:SetTexture(tex, nil, nil, "TRILINEAR");
end
