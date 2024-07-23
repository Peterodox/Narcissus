local modf = math.modf;
local After = C_Timer.After;
local GetTime = GetTime;

local framePool = {};


-----------------------------------------------------------------------
NarciItemCooldownUtil = {};

local function AccquireFrame(parentItemButton)
    local frame;
    for i = 1, #framePool do
        frame = framePool[i];
        if not frame.isActive then
            frame:ClearAllPoints();
            frame:SetParent(parentItemButton);
            frame:SetPoint("CENTER", parentItemButton, "CENTER", 0, 0);
            return framePool[i]
        end
    end
    frame = CreateFrame("Frame", nil, parentItemButton, "NarciItemCooldownFrameTemplate");
    frame:SetPoint("CENTER", parentItemButton, "CENTER", 0, 0);
    return frame
end

local function GetFrameCount()
    local numTotal = #framePool;
    local numActive = 0;
    for i = 1, numTotal do
        if framePool[i].isActive then
            numActive = numActive + 1;
        end
    end
    print("Total: "..numTotal);
    print("Active: "..numActive);
end


NarciItemCooldownUtil.AccquireFrame = AccquireFrame;
NarciItemCooldownUtil.GetFrameCount = GetFrameCount;


-----------------------------------------------------------------------
NarciItemCooldownFrameMixin = {};

function NarciItemCooldownFrameMixin:SetCooldown(start, duration)
    --start ~ timestamp \ duration ~ full duration
    local timestamp = GetTime();
    local activeDuration = timestamp - start;
    self.Cooldown:SetCooldown(start, duration);
    self.Cooldown:SetHideCountdownNumbers(false);
    self.ClockFrame:Start(duration, activeDuration);
    self.IconOverlay:Show();

    --Synchronize blip animation to the countdown
    local remainTime = (duration - activeDuration);
    if start ~= self.startTime then
        self.startTime = start;
        self.BlipTexture:Hide();
        self.BlipTexture.Blip:Stop();
        local _, r = modf(remainTime);
        After(r, function()
            self.BlipTexture.Blip:Stop();
            self.BlipTexture.Blip:Play();
            self.BlipTexture:Show();
        end)

        After(0, function()
            local color = self:GetParent().itemNameColor;
            if color then
                self.ClockFrame.Pointer:SetVertexColor(unpack(color));
            end
        end);
    end

    self.isActive = true;
end

function NarciItemCooldownFrameMixin:Clear()
    if self.isActive then
        self.isActive = nil;
        self.IconOverlay:Hide();
        self.BlipTexture:Hide();
        self.BlipTexture.Blip:Stop();
        self.Cooldown:Hide();
        self.Cooldown:Clear();
        self.ClockFrame:Hide();
        self.startTime = 0;
    end
end

function NarciItemCooldownFrameMixin:OnLoad()
    self.ClockFrame:SetPointerTexture("Interface\\AddOns\\Narcissus\\Art\\Cooldown\\ProgressPointer-Polygon");
    tinsert(framePool, self);

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciItemCooldownFrameMixin:OnHide()
    self:Clear();
    self.ReadyBling:Hide();
end

function NarciItemCooldownFrameMixin:OnCooldownDone()
    local bling = self.ReadyBling;
    bling:SetVertexColor(self:GetParent().Name:GetTextColor());
    bling:Show();
    bling.Shine:Play();
    self:Clear();
end