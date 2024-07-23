local UnitCastingInfo = UnitCastingInfo;

local unitEvents = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
};

local BAR_WIDTH = 240;

local sin = math.sin;
local pi = math.pi;

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

NarciCastingBarMixin = {};

function NarciCastingBarMixin:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_START" then
        self:OnSpellCastStart(...);
    elseif event == "UNIT_SPELLCAST_STOP" then
        --Canceled manually (macro)
        --self:OnSpellCastFailed(...);
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        self:OnSpellCastFailed(...);
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnSpellCastSucceeded(...);
    elseif event == "UI_ERROR_MESSAGE" then
        self:OnError(...);
    end
end;

function NarciCastingBarMixin:OnShow()
    self:ListenEvents(true);
end

function NarciCastingBarMixin:OnHide()
    self:ListenEvents(false);
    self:ResetUI();
end

function NarciCastingBarMixin:ListenEvents(state)
    if state then
        local unit = "player";
        for _, event in pairs(unitEvents) do
            self:RegisterUnitEvent(event, unit);
        end
        self:RegisterEvent("UI_ERROR_MESSAGE");
    else
        for _, event in pairs(unitEvents) do
            self:UnregisterEvent(event);
        end
        self:UnregisterEvent("UI_ERROR_MESSAGE");
    end
end

function NarciCastingBarMixin:WatchSpell(spellID)
    self.watchedSpell = spellID;
end



------------------- Events -------------------
function NarciCastingBarMixin:OnSpellCastStart(unitTarget, castGUID, spellID)
    self.currentSpell = spellID;
    self.failedSpell = nil;
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player");
    local duration = (endTime - startTime)/1000;
    --print("isTradeSkill", isTradeSkill);
    self.SpellName:SetTextColor(0.92, 0.92, 0.92);
    self.SpellName:SetText(name);
    self:ShowBar(duration);

    local RuneAnim = NarciRuneAnimationOverlay;
    RuneAnim:SetDuration(duration + 0.3);
    RuneAnim:PlayAnimation();

    self:UnregisterEvent("UI_ERROR_MESSAGE");
end

function NarciCastingBarMixin:OnSpellCastFailed(unitTarget, castGUID, spellID)
    if self.currentSpell and spellID ~= self.failedSpell then
        self.failedSpell = spellID;
        self:SetBarFailure();
        self:GetParent():OnCastCanceled();
    end
end

function NarciCastingBarMixin:OnSpellCastSucceeded(unitTarget, castGUID, spellID)
    self.SpellName:SetText(CRITERIA_COMPLETED);
    self:HideBar(0);
    self:GetParent():OnCastSucceeded();
end

function NarciCastingBarMixin:OnSpellCastStop(unitTarget, castGUID, spellID)
    self.currentSpell = nil;
    self:SetBarFailure();
end

function NarciCastingBarMixin:OnError(errorType, errorMsg)
    self:GetParent():OnCastFailed(errorMsg);
    self:UnregisterEvent("UI_ERROR_MESSAGE");
end

----------------------------------------------


----------------- Animations -----------------
local animFill, animShow

function NarciCastingBarMixin:InitAnimation()
    animFill = CreateFrame("Frame");
    animFill:Hide();
    animFill:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        local width;
        if f.t < self.duration then
            width = BAR_WIDTH * f.t / self.duration;
        else
            width = BAR_WIDTH;
            f:Hide();
        end
        self.Fill:SetWidth(width);
    end);

    animShow = CreateFrame("Frame");
    animShow:Hide();
    animShow:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        local offsetY;
        if f.t > 0 then
            if f.t < 0.25 then
                offsetY = outSine(f.t, f.fromY, f.toY, 0.25);
            else
                offsetY = f.toY;
                f:Hide();
            end
            self.Shadow:SetPoint("BOTTOM", self, "BOTTOM", 0, offsetY);
        end
    end);

    self.InitAnimation = nil;
end

function NarciCastingBarMixin:ShowBar(duration)
    if self.InitAnimation then
        self:InitAnimation();
    end
    self:StopAnimating();
    self.Blip.Anim:SetLooping("REPEAT");
    self.Blip.Anim:Play();
    self.Blip:Show();
    self.Tail:Show();
    self.Fill:SetColorTexture(0.2, 0.2, 0.2);
    self.Fill:SetAlpha(1);
    self.SpellName.Blink:Play();

    if duration > 0 then
        self.duration = duration;
        animFill.t = 0;
        animFill:Show();
        local toY = -2;
        if animShow.toY ~= toY then
            local _, _, _, _, fromY = self.Shadow:GetPoint();
            animShow.fromY = fromY;
            animShow.toY = toY;
            animShow.t = 0;
            animShow:Show();
        end
    end
end

function NarciCastingBarMixin:SetBarFailure()
    if animFill then
        animFill:Hide();
    end
    self:StopAnimating();
    self.Tail:Hide();
    self.Blip:Hide();
    self.Fill:SetWidth(BAR_WIDTH);
    self.Fill:SetColorTexture(0.8, 0, 0);
    self.Fill.Shine:Play();
    self.SpellName:SetTextColor(0.5, 0.5, 0.5);
    self.SpellName:SetText(CLUB_FINDER_CANCELED);
    self:HideBar(-1);
end

function NarciCastingBarMixin:HideBar(delay)
    self.Blip.Anim:SetLooping("NONE");

    if animFill then
        animFill:Hide();
    end

    if animShow then
        local toY = -8;
        if animShow.toY ~= toY then
            local _, _, _, _, fromY = self.Shadow:GetPoint();
            animShow.fromY = fromY;
            animShow.toY = toY;
            animShow.t = delay;
            animShow:Show();
        end
    end
end

function NarciCastingBarMixin:ResetUI()
    if animFill then
        animFill:Hide();
    end
    if animShow then
        animShow:Hide();
        animShow.toY = -8;
    end
    self:StopAnimating();
    self.Shadow:SetPoint("BOTTOM", self, "BOTTOM", 0, -8);
    self.Tail:Hide();
    self.Blip:Hide();
end
----------------------------------------------