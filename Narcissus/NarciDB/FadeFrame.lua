local GAP = 0.0167    --FPS 60

local abs = math.abs;
local tinsert = tinsert;
local wipe = wipe;

local fadeInfo = {};
local fadingFrames = {};

local f = CreateFrame("Frame", "NarciFadeUI");

local function OnUpdate(self, elapsed)
    local i = 1;
    local frame, info, timer, alpha;
    local isComplete = true;
    while fadingFrames[i] do
        frame = fadingFrames[i];
        info = fadeInfo[frame];
        if info then
            timer = info.timer + elapsed;
            if timer >= info.duration then
                alpha = info.toAlpha;
                fadeInfo[frame] = nil;
                if info.alterShownState and alpha <= 0 then
                    frame:Hide();
                end
            else
                alpha = info.fromAlpha + (info.toAlpha - info.fromAlpha) * timer/info.duration;
                info.timer = timer;
            end
            frame:SetAlpha(alpha);
            isComplete = false;
        end
        i = i + 1;
    end

    if isComplete then
        f:Clear();
    end
end

function f:Clear()
    self:SetScript("OnUpdate", nil);
    wipe(fadingFrames);
    wipe(fadeInfo);
end

function f:Add(frame, fullDuration, fromAlpha, toAlpha, alterShownState, useConstantDuration)
    local alpha = frame:GetAlpha();
    if alterShownState then
        if toAlpha > 0 then
            frame:Show();
        end
        if toAlpha == 0 then
            if not frame:IsShown() then
                frame:SetAlpha(0);
                alpha = 0;
            end
            if alpha == 0 then
                frame:Hide();
            end
        end
    end
    if fromAlpha == toAlpha or alpha == toAlpha then
        if fadeInfo[frame] then
            fadeInfo[frame] = nil;
        end
        return;
    end
    local duration;
    if useConstantDuration then
        duration = fullDuration;
    else
        if fromAlpha then
            duration = fullDuration * (alpha - toAlpha)/(fromAlpha - toAlpha);
        else
            duration = fullDuration * abs(alpha - toAlpha);
        end
    end
    if duration <= 0 then
        frame:SetAlpha(toAlpha);
        if toAlpha == 0 then
            frame:Hide();
        end
        return;
    end
    fadeInfo[frame] = {
        fromAlpha = alpha,
        toAlpha = toAlpha,
        duration = duration,
        timer = 0,
        alterShownState = alterShownState,
    };
    for i = 1, #fadingFrames do
        if fadingFrames[i] == frame then
            return;
        end
    end
    tinsert(fadingFrames, frame);
    self:SetScript("OnUpdate", OnUpdate);
end

function f:SimpleFade(frame, toAlpha, alterShownState, speedMultiplier)
    --Use a constant fading speed: 1.0 in 0.25s
    --alterShownState: if true, run Frame:Hide() when alpha reaches zero / run Frame:Show() at the beginning
    speedMultiplier = speedMultiplier or 1;
    local alpha = frame:GetAlpha();
    local duration = abs(alpha - toAlpha) * 0.25 * speedMultiplier;
    if duration <= 0 then
        return;
    end
    
    self:Add(frame, duration, alpha, toAlpha, alterShownState, true);
end

function f:Snap()
    local i = 1;
    local frame, info;
    while fadingFrames[i] do
        frame = fadingFrames[i];
        info = fadeInfo[frame];
        if info then
            frame:SetAlpha(info.toAlpha);
        end
        i = i + 1;
    end
    self:Clear();
end

function f:Print()
    --/run NarciFadeUI:Print()
    local i = 1;
    local frame, name;
    local numFrames = 0;
    local unamedFrames = {};
    while fadingFrames[i] do
        numFrames = numFrames + 1;
        frame = fadingFrames[i];
        name = frame:GetName();
        if name then
            print("#".. numFrames .."  "..name);
        else
            tinsert(unamedFrames, frame);
        end
        i = i + 1;
    end
    print("Fading Frames: ".. numFrames);
    print("Unamed Frames: ".. #unamedFrames);
    NARCI_DEBUG_FADING_FRAMES = unamedFrames;

    local numInfo = 0;
    for k, v in pairs(fadeInfo) do
        numInfo = numInfo + 1;
    end
    if numInfo > 0 then
        print("");
        print("Fading Info: "..numInfo);
    end
end

local function UIFrameFade(frame, duration, toAlpha, initialAlpha)
    if initialAlpha then
        frame:SetAlpha(initialAlpha);
        f:Add(frame, duration, initialAlpha, toAlpha, true, false);
    else
        f:Add(frame, duration, nil, toAlpha, true, false);
    end
end

local function UIFrameFadeIn(frame, duration)
    frame:SetAlpha(0);
    f:Add(frame, duration, 0, 1, true, false);
end


f.Fade = UIFrameFade;       --from current alpha
f.FadeIn = UIFrameFadeIn;   --from 0 to 1




--Add FadeIn, FadeOut methods to a frame
local FadeMixin = {};

local function FadeController_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self.alpha = self.alpha + self.delta*elapsed;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
        elseif self.alpha <= 0 then
            self.alpha = 0;
            self:SetScript("OnUpdate", nil);
            if not self.keepInvisibleFrame then
                self.owner:Hide();
            end
        end
        self.owner:SetAlpha(self.alpha);
    end
end

function FadeMixin:FadeIn(duration, delay)
    local alpha = self:GetAlpha();

    if alpha >= 1 then
        self.fadeController:SetScript("OnUpdate", nil);
    else
        duration = duration or 0.15;
        delay = (delay and -delay) or 0;
        self.fadeController.t = delay;
        self.fadeController.delta = 1 / duration;
        self.fadeController.alpha = alpha;
        self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
    end
end

function FadeMixin:FadeOut(duration, delay)
    if not self:IsShown() then
        self:SetAlpha(0);
        self.fadeController:SetScript("OnUpdate", nil);
        return
    end

    local alpha = self:GetAlpha();

    if alpha <= 0 then
        self.fadeController:SetScript("OnUpdate", nil);
    else
        duration = duration or 0.15;
        delay = (delay and -delay) or 0;
        self.fadeController.t = delay;
        self.fadeController.delta = -1 / duration;
        self.fadeController.alpha = alpha;
        self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
    end
end

local function CreateFadeObject(owner, keepInvisibleFrame)
    if not (owner.fadeController or owner.FadeIn or owner.FadeOut) then
        local f = CreateFrame("Frame", nil, owner);
        owner.fadeController = f
        f.owner = owner;
        f.keepInvisibleFrame = keepInvisibleFrame;
        owner.FadeIn = FadeMixin.FadeIn;
        owner.FadeOut = FadeMixin.FadeOut;
    end
end
f.CreateFadeObject = CreateFadeObject;