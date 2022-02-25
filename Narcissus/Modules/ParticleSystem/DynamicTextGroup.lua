local MOUSE_UPDATE_RATE = 1/60;     --1/25
local PARTICLE_LIFESPAN = 2;        --2 seconds
local ERASE_SPEED = 96;
local PIXEL_SCALE = 1;
local ERASE_DELAY = -3;
local tinsert = table.insert;
local strsplit = strsplit;
local gsub = string.gsub;
local strlen = string.len;
local strlenutf8 = strlenutf8;
local sqrt = math.sqrt;
local cos = math.cos;
local sin = math.sin;
local pow = math.pow;
local modf = math.modf;
local ceil = math.ceil;
local pi = math.pi;
local GetCursorPosition = GetCursorPosition;

local function Lerp(startValue, endValue, amount)
    --print(amount)
	return (1 - amount) * startValue + amount * endValue;
end

local function LerpSnap(startValue, endValue, amount)
    if amount > 1 then
        return endValue
    end
	return (1 - amount) * startValue + amount * endValue;
end

local function LerpCycle(startValue, endValue, amount)
    if amount > 1 then
        local r = amount % 2;
        if r > 1 then
            amount = 2 - r;
        else
            amount = r;
        end
    end
	return (1 - amount) * startValue + amount * endValue;
end

local function inOutSine(startValue, endValue, amount)
	return (startValue - endValue) / 2 * (cos(pi * amount) - 1) + startValue
end

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

local function outQuart(startValue, endValue, amount)
    if amount > 1 then
        amount = 1;
    elseif amount < 0 then
        amount = 0;
    end
    amount = amount - 1;
    return (startValue - endValue) * (pow(amount, 4) - 1) + startValue
end

local function Distance(x, y)
    return sqrt(x*x + y*y)
end

local function Mixin(object, mixin)
    for k, v in pairs(mixin) do
        object[k] = v;
    end
	return object;
end

local function UTF8toChars(input)
    local list = {};
    local len  = strlen(input);
    local index = 1;
    local lenutf8 = 0;
    while index <= len do
       local c = string.byte(input, index)
       local offset = 1
       if c < 0xc0 then
           offset = 1
       elseif c < 0xe0 then
           offset = 2
       elseif c < 0xf0 then
           offset = 3
       elseif c < 0xf8 then
           offset = 4
       elseif c < 0xfc then
           offset = 5
       end
       local str = string.sub(input, index, index + offset-1)
       index = index + offset;
       lenutf8 = lenutf8 + 1;
       tinsert(list, str);
    end

    return list, lenutf8
end


local defaultContainer = CreateFrame("Frame");
--defaultContainer:Hide();


--------------------------------------------------------------------------------------------------------
local DataProvider = {};

function DataProvider:GetLetterBinaryzation(letter)
    --32*32
    return self.letters[letter];
end


--------------------------------------------------------------------------------------------------------
--Particle System
local DynamicParticleMixin = {};

function DynamicParticleMixin:SetPosition(point, relativeTo, relativePoint, x, y)
    self:SetPoint(point, relativeTo, relativePoint, x, y);
    self.point = point;
    self.relativeTo = relativeTo;
    self.relativePoint = relativePoint;
    self.x0 = x;
    self.y0 = y;
    self.left = self:GetLeft();
    self:ResetMotion();
end

function DynamicParticleMixin:SetOffset(x, y)
    self:SetPoint(self.point, self.relativeTo, self.relativePoint, self.x0 + x, self.y0 + y);
end

function DynamicParticleMixin:ResetMotion()
    self.isActive = true;
    self.accuX, self.accuY = 0, 0;
    self.vX, self.vY = 0, 0;
    self.lifespan = 0;
end

function DynamicParticleMixin:SetAccumulativeOffset(relX, relY)
    self.accuX, self.accuY = self.accuX + relX, self.accuY + relY;
    self:SetOffset(self.accuX, self.accuY)
end

function DynamicParticleMixin:SetOffsetByAcceleration(aX, aY, elapsed)
    self.lifespan = self.lifespan + elapsed;
    self.vX = self.vX + aX * elapsed;
    if self.vX > 600 then
        self.vX = 600
    end
    self.vY = self.vY + aY * elapsed;
    self.accuX, self.accuY = self.accuX + self.vX*elapsed, self.accuY + self.vY*elapsed;
    self:SetOffset(self.accuX, self.accuY);
    if self.lifespan > PARTICLE_LIFESPAN then
        self:Kill();
        return false;
    else
        return true
    end
end

function DynamicParticleMixin:SetPixelSize(a)
    self:SetSize(a, a);
end

function DynamicParticleMixin:Kill()
    self:Hide();
    self.isActive = nil;
end

local ParticleSystem = {};
ParticleSystem.objects = {};
ParticleSystem.numObjects = 0;
ParticleSystem.numMaxParticles = 1000;

function ParticleSystem:Accquire(index)
    if index > self.numMaxParticles then
        index = index - self.numMaxParticles;
    end
    if not self.objects[index] then
        self.objects[index] = defaultContainer:CreateTexture(nil, "OVERLAY", "NarciDynamicTextParticleTemplate");
        self.numObjects = self.numObjects + 1;
        Mixin(self.objects[index], DynamicParticleMixin);
    end
    self.objects[index]:Show();
    return self.objects[index];
end

function ParticleSystem:NewParticle()
    local object = defaultContainer:CreateTexture(nil, "OVERLAY", "NarciDynamicTextParticleTemplate");
    Mixin(object, DynamicParticleMixin);
    return object
end

function ParticleSystem:KillAll()
    for i = 1, #self.objects do
        self.objects[i]:SetParent(defaultContainer);
        self.objects[i]:ClearAllPoints();
        self.objects[i]:Hide();
    end
end

function ParticleSystem:CreateLetter(container, letter, offsetX, offsetY, amp, texAmp, particleColor, step)
    --ParticleSystem:KillAll();
    local data = DataProvider:GetLetterBinaryzation(letter);
    local res = 32;
    local pixelSize = 1;
    local obj;
    local index, row, col;
    local particles = {};
    local particlePos = {};
    local r, g, b;
    amp = amp or 1;
    texAmp = texAmp or 1;
    if particleColor then
        r, g, b = unpack(particleColor);
    else
        r, g, b = 0.75, 0.86, 0.84;
    end
    step = step or 1;
    if data then
        for i = 1, #data, step do
            index = data[i];
            col = ((index - 1) % res);
            row = modf(index / res);
            obj = ParticleSystem:NewParticle(i);   --Accquire
            obj:ClearAllPoints();
            obj:SetPixelSize(2*texAmp); --pixelSize * PIXEL_SCALE
            obj:SetParent(container);
            obj:SetPosition("TOPLEFT", container, "TOPLEFT", amp*(col*pixelSize + offsetX), amp*(-row*pixelSize + offsetY));
            --particles[i] = obj;
            tinsert(particles, obj);
            particlePos[obj] = {row = row, col = col};

            obj:SetVertexColor(r, g, b);
        end
    end

    local fromLeft = true;

    if fromLeft then
        local sortFunc = function(a, b)
            if particlePos[a].col == particlePos[b].col then
                return particlePos[a].row < particlePos[b].row
            else
                return particlePos[a].col < particlePos[b].col
            end
            
        end
        table.sort(particles, sortFunc);
    end

    return particles
end
--------------------------------------------------------------------------------------------------------
local function CreateDynamicTextGroup(parentFrame)
    local object = CreateFrame("Frame", nil, parentFrame, "NarciDynamicTextGroupTemplate");
    return object
end

NarciAPI.CreateDynamicTextGroup = CreateDynamicTextGroup;


local function PrintLetter(letter)
    ParticleSystem:KillAll();
    local data = DataProvider:GetLetterBinaryzation(letter);
    local res = 32;
    local pixelSize = 1;
    local obj;
    local index, row, col;
    local container = NarciDynamicTextGroupTemplate;
    if data then
        for i = 1, #data do
            index = data[i];
            col = ((index - 1) % res);
            row = modf(index / res);
            obj = ParticleSystem:Accquire(i);
            obj:ClearAllPoints();
            obj:SetPixelSize(pixelSize);
            obj:SetPosition("TOPLEFT", container, "TOPLEFT", col*pixelSize, -row*pixelSize);
        end
    end
end

NarciAPI.PrintLetter = PrintLetter


--------------------------------------------------------------------------------------------------------
local DynamicFontStringMixin = {};

function DynamicFontStringMixin:SetFontType(fontObject)
    if fontObject ~= self.fontType then
        self:SetFontObject(fontObject);
        self.fontType = fontObject;
    end
end

function DynamicFontStringMixin:IsActive()
    return self.isActive;
end

function DynamicFontStringMixin:SetCharacter(txt)
    self:SetText(txt);
    self.isActive = true;
end

function DynamicFontStringMixin:Release()
    self:SetText(nil);
    self.isActive = nil;
    self:ClearAllPoints();
    self:SetParent(defaultContainer);
end

function DynamicFontStringMixin:SetPosition(point, relativeTo, relativePoint, x, y)
    self:SetPoint(point, relativeTo, relativePoint, x, y);
    self.point = point;
    self.relativeTo = relativeTo;
    self.relativePoint = relativePoint;
    self.x0 = x;
    self.y0 = y;
end

function DynamicFontStringMixin:SetOffset(x, y)
    self:SetPoint(self.point, self.relativeTo, self.relativePoint, self.x0 + x, self.y0 + y);
    self.hitRectY = -y;
end

function DynamicFontStringMixin:IsInRange()
    return self:IsMouseOver(0, self.hitRectY or 0, 0, 0);
end

function DynamicFontStringMixin:SetValue(v, a)
    self:SetTextColor(v, v, v, a);
end

local function GetPressure(distance)
    if distance < 0 then
        distance = -distance;
    end
    local p = 24 - 0.5 * distance;
    local b = 1.5 - 0.025 * distance;
    if p < 0 then
        p = 0;
    end
    if b < 0.5 then
        b = 0.5;
    elseif b > 1 then
        b = 1;
    end
    return p, b
end

local function TestOnUpdate(textGroup, elapsed)
    textGroup.t = textGroup.t + elapsed;
    if textGroup.t > MOUSE_UPDATE_RATE then
        --print(elapsed)
        textGroup.t = 0;
        local numObjects = #textGroup.objects;
        --[[
        for i = 1, numObjects do
            if textGroup.objects[i]:IsInRange() then
                local uiScale = UIParent:GetEffectiveScale();
                local centerObj = textGroup.objects[i];
                local cursorX, cursorY = GetCursorPosition();
                local x, y = centerObj:GetCenter();
                local w0 = centerObj:GetWidth();
                local diffX = x - cursorX;
                print(diffX)
                centerObj:SetOffset( 0, GetPressure(diffX) );
                for j = i + 1, numObjects do
                    diffX = textGroup.objects[j]:GetCenter() - cursorX;
                    textGroup.objects[j]:SetOffset( 0, GetPressure(diffX) );
                end
                for j = i - 1, 1, -1 do
                    diffX = textGroup.objects[j]:GetCenter() - cursorX;
                    textGroup.objects[j]:SetOffset( 0, GetPressure(diffX) );
                end
                return
            end
        end
        --]]

        for i = 1, numObjects do
            
            local uiScale = UIParent:GetEffectiveScale();
            --local obj;
            local cursorX, cursorY = GetCursorPosition();
            --cursorX = cursorX / uiScale
            local x, y =  textGroup.objects[i]:GetCenter();
            local diffX = cursorX - x;
            local diffY = cursorY - y;
            diffY = diffY * 0.8;
            
            local p, v = GetPressure( Distance(diffX, diffY) );
            
            textGroup.objects[i]:SetOffset(0, p);
            textGroup.objects[i]:SetValue(v);
        end
    end
end


--------------------------------------------------------------------------------------------------------
local FontStringPool = {};
FontStringPool.objects = {};
FontStringPool.numObjects = 0;

function FontStringPool:AccquireAndSetCharacter(textGroup, txt)
    local obj;
    for i = 1, self.numObjects do
        obj = self.objects[i];
        if not obj:IsActive() then
            obj:SetCharacter(txt);
            return obj
        end
    end

    obj = textGroup:CreateFontString(textGroup, "OVERLAY", "NarciDynamicFontStringTemplate");
    Mixin(obj, DynamicFontStringMixin);
    obj:SetCharacter(txt);
    tinsert(self.objects, obj);
    self.numObjects = self.numObjects + 1;
    return obj
end


--------------------------------------------------------------------------------------------------------
--Public

NarciDynamicTextGroupMixin = {};

function NarciDynamicTextGroupMixin:PlayClipText()
    local f = self.updateFrame;
    if not f then
        f = CreateFrame("Frame");
        f:Hide();
        f.t = 0;
        self.updateFrame = f;
    end

    local clip = self.ClipFrame;
    local translationX = clip:GetWidth() + 2;
    local duration = translationX/ERASE_SPEED;
    f.t = ERASE_DELAY;
    f:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        if f.t > 0 then
            local offsetX = Lerp(0, translationX, f.t/duration);
            if f.t > duration then
                offsetX = translationX;
                f:Hide();
            end
            clip:SetPoint("LEFT", self, "LEFT", offsetX, 0);
        end
    end)
    f:Show();

    clip:SetPoint("LEFT", self, "LEFT", 0, 0);
end

function NarciDynamicTextGroupMixin:SetText(txt)
    self:SetSize(8, 8);
    local characters, lenutf8 = UTF8toChars(txt);
    self.fullText = txt;
    self.objects = {};
    local obj, char;
    local totalWidth = 0;
    local container = self.ClipFrame;
    for i = 1, lenutf8 do
        char = characters[i];
        print(char)
        obj = FontStringPool:AccquireAndSetCharacter(self, char);
        obj:ClearAllPoints();
        obj:SetParent(container);
        self.objects[i] = obj;
        obj:SetPosition("LEFT", self, "LEFT", totalWidth, 0);
        totalWidth = totalWidth + obj:GetWidth();
    end
    self:SetWidth(totalWidth);
    self:SetHeight(obj:GetHeight());
    container:SetWidth(totalWidth);
    --container:SetHeight(obj:GetHeight());
    --self:SetScript("OnUpdate", TestOnUpdate);
end

function NarciDynamicTextGroupMixin:SetTextParticle(letter, offsetX, offsetY, amp, texAmp, color, step)
    offsetX = offsetX or 0;
    if not self.particles then
        self.particles = {};
    end
    tinsert(self.particles, ParticleSystem:CreateLetter(self, letter, offsetX, offsetY, amp, texAmp, color, step));
end

function NarciDynamicTextGroupMixin:SetTextColor(r, g, b, a)
    self.FontString1:SetTextColor(r, g, b, a);
end

function NarciDynamicTextGroupMixin:SetAlphaGradient(startPos)
    self.FontString1:SetAlphaGradient(startPos, 8);
end

--/run NarciDynamicTextGroupTemplate:PlayFadeIn()
function NarciDynamicTextGroupMixin:PlayFadeIn()
    local len = strlenutf8(self.FontString1:GetText());
    self.fromPos = 0;
    self.toPos = len;
    self.duration = len/20;
    self.t = 0;
    self:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        local offset = Lerp(self.fromPos, self.toPos, self.t / self.duration)
        self:SetAlphaGradient(offset);
        if self.t >= self.duration then
            self:SetScript("OnUpdate", nil);
        end
    end);
end

--/run NarciDynamicTextGroupTemplate:PlayFreeFall()
function NarciDynamicTextGroupMixin:PlayFreeFall()
    local numObjects = #self.objects;
    self.duration = 4;
    self.t = 0;
    local offsetXPerSec = 256;
    local offsetYPerSec = -128;
    for i = 1, numObjects do
        self.objects[i]:SetOffset(0, 0);
        self.objects[i]:SetAlpha(1);
    end
    self:SetScript("OnUpdate", function(self, elapsed)
        local t = self.t + elapsed;
        self.t = t;
        offsetYPerSec = inOutSine(-128, 256, t/self.duration);
        for i = 1, numObjects do
            local oT = t - (i - 1)*0.5;
            if oT > 0 then
                local offsetX = offsetXPerSec * (oT)^2;
                local offsetY = offsetYPerSec * (oT)^2;
                
                self.objects[i]:SetOffset(offsetX, offsetY);
                local alpha = 1 - oT*0.8;
                if alpha < 0 then
                    alpha = 0;
                end
                self.objects[i]:SetAlpha(alpha)
            end
        end
        if self.t >= self.duration then
            --self:SetScript("OnUpdate", nil);
        end
    end);
end

--/run NarciDynamicTextGroupTemplate:PlayFlyIn()
function NarciDynamicTextGroupMixin:PlayFlyIn()
    self.t = 0;
    local numObjects = #self.objects;
    local duration = 0.6;
    for i = 1, numObjects do
        self.objects[i]:SetValue(1, 0);
    end
    self:SetScript("OnUpdate", function(self, elapsed)
        local t = self.t + elapsed;
        self.t = t;
        for i = 1, numObjects do
            local oT = t - (i - 1)*0.1;
            if oT > 0 then
                local offsetX = 0;
                local offsetY = outQuart(-128, 0, oT/duration);
                if offsetY > 0 then
                    offsetY = 0;
                end
                self.objects[i]:SetOffset(offsetX, offsetY);
                local alpha = 1 + offsetY / 64;
                if alpha < 0 then
                    alpha = 0;
                end
                --self.objects[i]:SetAlpha(alpha);
                local v = 1 - (oT - 2);
                if v < 0.5 then
                    v = 0.5;
                end
                self.objects[i]:SetValue(v, alpha);
            end
        end
    end);
end

--/run NarciDynamicTextGroupTemplate:PlayWind()
function NarciDynamicTextGroupMixin:PlayWind()
    self.duration = 4;
    self.t = ERASE_DELAY;
    self.counter = 0;
    local particleGroup;
    local numGroup = #self.particles
    local weights = {};
    local leftMost = 9999;
    local numParticles = 0;
    for o = 1, numGroup do
        particleGroup = self.particles[o];

        local numObjects = #particleGroup;
        local left;
        for i = 1, numObjects do
            particleGroup[i]:SetOffset(0, 0);
            particleGroup[i]:SetAlpha(1);
            particleGroup[i]:ResetMotion();
            left = particleGroup[i].left;
            if left < leftMost then
                leftMost = left;
            end
        end
        
        
        local random = math.random;
        weights[o] = {};
        for i = 1, numObjects do
            weights[o][i] = random(100, 200)/100;
            --print(weights[i])
        end

    end

    print("Left Base: "..leftMost)
    --Reassign Time Offset based on position: left to right
    for o = 1, numGroup do
        particleGroup = self.particles[o];
        for i = 1, #particleGroup do
            particleGroup[i].timeOffset = (leftMost - particleGroup[i].left)/ERASE_SPEED;
            numParticles = numParticles + 1;
        end
    end
    print("numParticles: "..numParticles)

    local offsetXPerSec = 512;
    local offsetYPerSec = 0;
    local accX, accY;   --acceleration
    self:SetScript("OnUpdate", function(self, elapsed)
        local t = self.t + elapsed;
        self.t = t;
        local oT;
        local pIndex = 0;
        local isLive;
        local numLive = 0;
        for gIndex = 1, numGroup do
            particleGroup = self.particles[gIndex];
            for i = 1, #particleGroup do
                pIndex = pIndex + 1;
                oT = t + particleGroup[i].timeOffset;
                if oT > 0 then
                    if particleGroup[i].isActive then
                        offsetYPerSec = inOutSineCycle(40, -50, t/2);
                        accX = offsetXPerSec * weights[gIndex][i];
                        accY = offsetYPerSec * weights[gIndex][i];
                        local alpha = 1 - oT*1;
                        if alpha < 0 then
                            alpha = 0;
                            particleGroup[i]:Hide();
                        else
                            if alpha > 1 then
                                alpha = 1;
                            end
                            particleGroup[i]:Show();
                        end
                        particleGroup[i]:SetAlpha(alpha);
                        isLive = particleGroup[i]:SetOffsetByAcceleration(accX, accY, elapsed);
                        if isLive then
                            numLive = numLive + 1;
                        end
                    end
                else
                    particleGroup[i]:Hide();
                end
            end
        end

        self.counter = self.counter + elapsed;
        if self.counter > 0.5 then
            self.counter = 0;
            print("Active Particles: "..numLive);
        end

        if self.t > 1 and numLive < 4 then
            self:SetScript("OnUpdate", nil);
        end
    end);
end

local letterWidth = {
    D = 17,
    W = 24,
    R = 20,
    e = 14,
    a = 14,
    h = 12,
    i = 10,
    p = 16,
    r = 13,
    s = 13,
    t = 14,
    l = 13,
    ['\''] = 10,
    space = 15,

}
function NarciDynamicTextGroupMixin:OnLoad()
    if false then return end
    self.t = 0;
    local txt = "Rae'shalare"; -- in like in the old classic versions of WoW.";
    self:SetText(txt);
    local letters, numLetters = UTF8toChars(txt);
    local offsetX = -8   ---numLetters * 20 / 2;
    local offsetY = 2.5;
    local letter;
    local totalWidth = 0;
    local extraWidth;
    for i = 1, #letters do
        letter = letters[i];
        if letter and letter ~= " " then
            self:SetTextParticle(letter, offsetX + PIXEL_SCALE*( totalWidth ), offsetY, nil, nil, nil, 4);
            extraWidth = letterWidth[letter];
        else
            extraWidth = letterWidth.space;
        end
        totalWidth = totalWidth + extraWidth;
    end

    txt = "Rae sha are";
    letters, numLetters = UTF8toChars(txt);
    totalWidth = 0;
    for i = 1, #letters do
        letter = letters[i];
        if letter and letter ~= " " then
            self:SetTextParticle(letter, offsetX + PIXEL_SCALE*( totalWidth ), offsetY - 4, 1, 0.8, {0, 0, 0}, 4);
            extraWidth = letterWidth[letter];
        else
            extraWidth = letterWidth.space;
        end
        totalWidth = totalWidth + extraWidth;
    end

    --Create Sigil
    local sigOffsetX = 27;
    local sigOffsetY = 42;
    tinsert(self.particles, ParticleSystem:CreateLetter(self, "SylvanasBackground", sigOffsetX, sigOffsetY, 2, 1.5, {0, 0, 0} ));
    tinsert(self.particles, ParticleSystem:CreateLetter(self, "SylvanasDark", sigOffsetX, sigOffsetY, 2, 1.4, {0.29, 0.37, 0.41}));
    tinsert(self.particles, ParticleSystem:CreateLetter(self, "SylvanasLight", sigOffsetX, sigOffsetY, 2, 1.4 ));
    tinsert(self.particles, ParticleSystem:CreateLetter(self, "SylvanasBlood", sigOffsetX, sigOffsetY, 2, 1.5, {1, 0, 0} ));
    

    letters = UTF8toChars("le e  ar lte D ep i e");
    extraWidth = 0;
    offsetX = -112;
    offsetY = 34;
    for i = 1, #letters do
        letter = letters[i];
        if letter and letter ~= " " then
            self:SetTextParticle(letter, offsetX + PIXEL_SCALE*( totalWidth ), offsetY, 0.4, 0.8, {0.53, 0.7, 0.741}, 2);
            extraWidth = letterWidth[letter];
        else
            extraWidth = letterWidth.space;
        end
        totalWidth = totalWidth + extraWidth;
    end
end



NarciItemCelebrationMixin = {};

function NarciItemCelebrationMixin:OnLoad()
    NarciAPI.SetBorderTexture(self.Sigil, "Sylvanas");
    self.Sigil:SetParent(self.DynamicText.ClipFrame);
    self.Header:SetParent(self.DynamicText.ClipFrame);
end

function NarciItemCelebrationMixin:PlayCelebration()
    UIFrameFadeIn(self, 0.25, 0, 1);
    self.DynamicText:PlayWind();
    self.DynamicText:PlayClipText();
end

--/run NarciItemCelebrationFrame:PlayCelebration();

--------------------------------------------------------------------------------------------------------
DataProvider.letters = {
    --32*32
    D = {169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 265, 266, 267, 275, 276, 277, 278, 297, 298, 299, 308, 309, 310, 311, 329, 330, 331, 341, 342, 343, 344, 361, 362, 363, 373, 374, 375, 376, 393, 394, 395, 406, 407, 408, 425, 426, 427, 438, 439, 440, 457, 458, 459, 470, 471, 472, 489, 490, 491, 502, 503, 504, 521, 522, 523, 534, 535, 536, 553, 554, 555, 566, 567, 568, 585, 586, 587, 597, 598, 599, 600, 617, 618, 619, 629, 630, 631, 649, 650, 651, 660, 661, 662, 663, 681, 682, 683, 691, 692, 693, 694, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 745, 746, 747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 777, 778, 779, 780, 781, 782, 783, 784, 785},
    W = {164, 165, 166, 175, 176, 177, 186, 187, 188, 189, 196, 197, 198, 207, 208, 209, 210, 218, 219, 220, 228, 229, 230, 231, 238, 239, 240, 241, 242, 250, 251, 252, 261, 262, 263, 270, 271, 272, 273, 274, 282, 283, 284, 293, 294, 295, 302, 303, 304, 305, 306, 307, 313, 314, 315, 316, 325, 326, 327, 334, 335, 337, 338, 339, 345, 346, 347, 357, 358, 359, 360, 365, 366, 367, 369, 370, 371, 377, 378, 379, 390, 391, 392, 397, 398, 399, 402, 403, 409, 410, 411, 422, 423, 424, 429, 430, 431, 434, 435, 436, 441, 442, 454, 455, 456, 461, 462, 466, 467, 468, 472, 473, 474, 487, 488, 492, 493, 494, 498, 499, 500, 504, 505, 506, 519, 520, 521, 524, 525, 526, 531, 532, 533, 536, 537, 538, 551, 552, 553, 556, 557, 563, 564, 565, 568, 569, 583, 584, 585, 587, 588, 589, 595, 596, 597, 599, 600, 601, 616, 617, 619, 620, 621,
        628, 629, 631, 632, 633, 648, 649, 650, 651, 652, 653, 660, 661, 662, 663, 664, 665, 680, 681, 682, 683, 684, 692, 693, 694, 695, 696, 712, 713, 714, 715, 716, 724, 725, 726, 727, 728, 745, 746, 747, 748, 757, 758, 759, 760, 777, 778, 779, 789, 790, 791, 792},
    R = {171, 172, 173, 174, 175, 176, 177, 178, 179, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 267, 268, 269, 276, 277, 278, 279, 299, 300, 301, 308, 309, 310, 311, 331, 332, 333, 341, 342, 343, 363, 364, 365, 373, 374, 375, 395, 396, 397, 404, 405, 406, 407, 427, 428, 429, 435, 436, 437, 438, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 523, 524, 525, 526, 527, 528, 529, 530, 531, 555, 556, 557, 562, 563, 564, 587, 588, 589, 594, 595, 596, 619, 620, 621, 627, 628, 629, 651, 652, 653, 659, 660, 661, 662, 683, 684, 685, 692, 693, 694, 715, 716, 717, 725, 726, 727, 747, 748, 749, 757, 758, 759, 760, 779, 780, 781, 790, 791, 792},
    a = {332, 333, 334, 335, 336, 337, 338, 339, 340, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 396, 397, 402, 403, 404, 405, 435, 436, 437, 467, 468, 469, 499, 500, 501, 525, 526, 527, 528, 529, 530, 531, 532, 533, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 586, 587, 588, 589, 595, 596, 597, 618, 619, 620, 627, 628, 629, 650, 651, 652, 659, 660, 661, 682, 683, 684, 691, 692, 693, 714, 715, 716, 717, 721, 722, 723, 724, 725, 747, 748, 749, 750, 751, 752, 753, 754, 756, 757, 780, 781, 782, 783, 784, 785, 788, 789},
    e = {334, 335, 336, 337, 338, 339, 340, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 396, 397, 398, 403, 404, 405, 406, 427, 428, 429, 436, 437, 438, 459, 460, 461, 469, 470, 471, 491, 492, 493, 501, 502, 503, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 587, 588, 589, 619, 620, 621, 651, 652, 653, 683, 684, 685, 686, 716, 717, 718, 719, 725, 726, 749, 750, 751, 752, 753, 754, 755, 756, 757, 758, 782, 783, 784, 785, 786, 787, 788, 789},
    h = {138, 139, 140, 170, 171, 172, 202, 203, 204, 234, 235, 236, 266, 267, 268, 298, 299, 300, 330, 331, 332, 335, 336, 337, 338, 339, 340, 341, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 394, 395, 396, 397, 398, 399, 403, 404, 405, 406, 426, 427, 428, 429, 436, 437, 438, 458, 459, 460, 461, 468, 469, 470, 490, 491, 492, 493, 500, 501, 502, 522, 523, 524, 532, 533, 534, 554, 555, 556, 564, 565, 566, 586, 587, 588, 596, 597, 598, 618, 619, 620, 628, 629, 630, 650, 651, 652, 660, 661, 662, 682, 683, 684, 692, 693, 694, 714, 715, 716, 724, 725, 726, 746, 747, 748, 756, 757, 758, 778, 779, 780, 788, 789, 790},
    i = {144, 145, 175, 176, 177, 178, 207, 208, 209, 335, 336, 337, 367, 368, 369, 399, 400, 401, 431, 432, 433, 463, 464, 465, 495, 496, 497, 527, 528, 529, 559, 560, 561, 591, 592, 593, 623, 624, 625, 655, 656, 657, 687, 688, 689, 719, 720, 721, 751, 752, 753, 783, 784, 785},
    p = {330, 331, 332, 335, 336, 337, 338, 339, 340, 362, 363, 364, 366, 367, 368, 369, 370, 371, 372, 373, 394, 395, 396, 397, 398, 403, 404, 405, 406, 426, 427, 428, 429, 436, 437, 438, 458, 459, 460, 461, 468, 469, 470, 471, 490, 491, 492, 501, 502, 503, 522, 523, 524, 533, 534, 535, 554, 555, 556, 565, 566, 567, 586, 587, 588, 597, 598, 599, 618, 619, 620, 621, 629, 630, 631, 650, 651, 652, 653, 660, 661, 662, 663, 682, 683, 684, 685, 686, 692, 693, 694, 714, 715, 716, 717, 718, 719, 722, 723, 724, 725, 726, 746, 747, 748, 750, 751, 752, 753, 754, 755, 756, 757, 778, 779, 780, 783, 784, 785, 786, 787, 788, 810, 811, 812, 842, 843, 844, 874, 875, 876, 906, 907, 908, 938, 939, 940, 970, 971, 972, 1003, 1004},
    r = {333, 334, 335, 338, 339, 340, 341, 365, 366, 367, 369, 370, 371, 372, 373, 397, 398, 399, 400, 401, 402, 403, 429, 430, 431, 432, 433, 461, 462, 463, 464, 493, 494, 495, 496, 525, 526, 527, 557, 558, 559, 589, 590, 591, 621, 622, 623, 653, 654, 655, 685, 686, 687, 717, 718, 719, 749, 750, 751, 781, 782, 783},
    s = {333, 334, 335, 336, 337, 338, 339, 340, 341, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 396, 397, 398, 404, 427, 428, 429, 460, 461, 462, 492, 493, 494, 495, 496, 525, 526, 527, 528, 529, 530, 558, 559, 560, 561, 562, 563, 564, 593, 594, 595, 596, 597, 627, 628, 629, 659, 660, 661, 691, 692, 693, 716, 717, 722, 723, 724, 725, 748, 749, 750, 751, 752, 753, 754, 755, 756, 780, 781, 782, 783, 784, 785, 786, 787},
    t = {239, 240, 271, 272, 302, 303, 304, 333, 334, 335, 336, 337, 338, 339, 340, 341, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 398, 399, 400, 401, 430, 431, 432, 462, 463, 464, 494, 495, 496, 526, 527, 528, 558, 559, 560, 590, 591, 592, 622, 623, 624, 654, 655, 656, 686, 687, 688, 689, 718, 719, 720, 721, 722, 751, 752, 753, 754, 755, 756, 757, 784, 785, 786, 787, 788, 789},
    l = {143, 144, 145, 175, 176, 177, 207, 208, 209, 239, 240, 241, 271, 272, 273, 303, 304, 305, 335, 336, 337, 367, 368, 369, 399, 400, 401, 431, 432, 433, 463, 464, 465, 495, 496, 497, 527, 528, 529, 559, 560, 561, 591, 592, 593, 623, 624, 625, 655, 656, 657, 687, 688, 689, 719, 720, 721, 751, 752, 753, 783, 784, 785},
    ['\'']= {175, 176, 177, 208, 209, 240, 241, 272, 273, 304, 305, 336, 337, 368, 369},

    SylvanasBackground = {174, 175, 176, 179, 204, 205, 206, 207, 208, 212, 213, 235, 236, 237, 238, 239, 240, 245, 246, 265, 266, 267, 268, 269, 270, 271, 273, 274, 279, 280, 295, 296, 297, 298, 300, 301, 302, 305, 306, 307, 312, 313, 314, 326, 327, 330, 336, 338, 339, 340, 344, 345, 346, 347, 359, 360, 363, 368, 373, 376, 377, 378, 379, 391, 392, 394, 395, 401, 409, 410, 411, 423, 426, 427, 436, 443, 465, 505, 519, 520, 531, 532, 533, 534, 535, 536, 537, 538, 539, 551, 552, 553, 554, 563, 564, 565, 566, 569, 570, 571, 585, 586, 597, 618, 619, 625, 628, 629, 649, 650, 651, 656, 657, 660, 662, 666, 667, 679, 680, 681, 682, 683, 684, 689, 691, 692, 693, 694, 697, 698, 699, 712, 713, 716, 724, 725, 726, 730, 754, 755, 757, 758, 787, 788, 819, 820, 851},
    SylvanasBlood = {84, 116, 150, 168, 169, 184, 199, 200, 202, 228, 229, 230, 231, 232, 260, 261, 262, 285, 293, 294, 317, 325, 326, 357, 375, 389, 413, 414, 453, 454, 676, 677, 708, 730, 731, 742, 743, 761, 762, 763, 766, 775, 793, 794, 823, 824, 845},
    SylvanasDark = {16, 17, 47, 48, 49, 50, 77, 78, 79, 80, 81, 82, 84, 108, 109, 110, 112, 115, 116, 117, 138, 139, 140, 145, 149, 150, 151, 152, 168, 169, 182, 183, 184, 185, 199, 200, 201, 202, 210, 216, 217, 218, 219, 228, 229, 230, 231, 232, 242, 243, 244, 250, 251, 252, 253, 260, 261, 262, 276, 277, 278, 284, 285, 293, 294, 309, 310, 316, 317, 325, 326, 333, 334, 342, 343, 349, 357, 365, 366, 367, 374, 375, 389, 397, 398, 404, 407, 408, 413, 414, 421, 425, 430, 431, 432, 434, 435, 437, 438, 439, 440, 441, 445, 453, 454, 455, 456, 457, 458, 459, 462, 463, 464, 466, 467, 470, 471, 472, 473, 474, 475, 476, 477, 490, 491, 492, 493, 494, 495, 498, 503, 504, 506, 507, 508, 509, 517, 523, 524, 525, 526, 527, 549, 555, 556, 557, 558, 581, 588, 599, 600, 601, 602, 605, 613, 623, 631, 632, 633, 646, 654, 664, 676, 677, 678, 708, 720, 728, 729, 730, 731, 741, 742, 743, 746, 750, 751, 752, 760, 761, 762, 763, 764, 766, 775, 776, 777, 778, 783, 784, 785, 793, 794, 809, 810, 811, 812, 815, 816, 817, 823, 824, 842, 843, 844, 845, 848, 849, 876, 877, 878, 879, 881, 910, 911, 912, 913, 919, 944, 945, 
    952},
    SylvanasLight = {49, 116, 117, 139, 149, 150, 151, 169, 183, 184, 185, 210, 217, 218, 243, 251, 252, 276, 277, 278, 284, 285, 309, 310, 342, 343, 366, 375, 407, 430, 437, 438, 440, 441, 463, 464, 467, 470, 471, 495, 524, 525, 526, 555, 556, 557, 558, 720, 752, 776, 777, 783, 784, 810, 811, 816, 843, 844, 845, 877, 878, 911, 912},
}