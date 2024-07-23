local NUM_RUNES = 3;
local RUNE_TEX_PATH = "Interface\\AddOns\\Narcissus\\Art\\Runes\\Letters\\";

local GetAttributeAbbrByEnchantID = NarciAPI.GetAttributeAbbrByEnchantID;

--[[
    Final Size = 16, Gap = 8
--]]


NarciRuneAnimationMixin = {};

function NarciRuneAnimationMixin:OnLoad()
    self:SetRuneSize(16);
    self:SetRuneDistance(8);
    self:SetRuneTexture(1, "C");
    self:SetRuneTexture(2, "R");
    self:SetRuneTexture(3, "I");
    self:SetDirection(1);
    self:SetDuration(2.3);
    --self:RegisterForDrag("LeftButton");
end

function NarciRuneAnimationMixin:OnShow()
    self:SetFrameStrata("TOOLTIP");
end

function NarciRuneAnimationMixin:OnHide()
    self:Hide();
    self:StopAnimating();
end

function NarciRuneAnimationMixin:SetRuneTexture(i, letter)
    if self["Rune"..i] then
        self["Rune"..i]:SetTexture(RUNE_TEX_PATH..string.lower(letter));
    end
end

function NarciRuneAnimationMixin:SetRuneSize(a)
    for i = 1, NUM_RUNES do
        self["Rune"..i]:SetSize(a, a);
    end
end

function NarciRuneAnimationMixin:SetRuneDistance(d)
    local y0 = (NUM_RUNES - 1) * 0.5 * d;
    for i = 1, NUM_RUNES do
        self["Rune"..i]:ClearAllPoints();
        self["Rune"..i]:SetPoint("CENTER", self, "CENTER", 0, y0 + (1 - i) * d);
    end
end

function NarciRuneAnimationMixin:SetRuneByEnchantID(enchantID)
    local abbr = GetAttributeAbbrByEnchantID(enchantID);
    if not abbr then
        self.hasRune = false;
        return
    end
    for i = 1, 3 do
        self:SetRuneTexture(i, string.sub(abbr, i, i));
    end
    self.hasRune = true;
end

function NarciRuneAnimationMixin:SetAnimationDuration(t)

end

function NarciRuneAnimationMixin:PlayAnimation()
    if not self.hasRune then return end;
    self:StopAnimating();
    self:SetAlpha(1);
    for i = 1, NUM_RUNES do
        self["Rune"..i].Anim:Play();
    end
    self.Shine.Anim:Play();
    self:Show();
end

function NarciRuneAnimationMixin:StopAnimation()
    local anyPlaying = false;

    for i = 1, NUM_RUNES do
        local rune = self["Rune"..i];
        if rune.Anim:IsPlaying() then
            anyPlaying = true;
            rune.Anim:Pause();
        end
    end
    self.Shine.Anim:Pause();
    if self:IsShown() and anyPlaying then
        self.FadeOut:Play();
    end
end

function NarciRuneAnimationMixin:SetDirection(d)
    if d < 0 then
        self.Shine:SetTexCoord(0, 1, 0, 1);
    else
        self.Shine:SetTexCoord(1, 0, 0, 1);
    end

    local a1 = self.Rune1.Anim;
    a1.Fly1:SetOffset(12 * d, 8);
    a1.Fly2:SetOffset(12 * d, 4);
    a1.Rotate2:SetDegrees(12 * d);
    a1.Fly3:SetOffset(-24 * d, -12);
    a1.Rotate3:SetDegrees(-12 * d);

    local a2 = self.Rune2.Anim;
    a2.Fly1:SetOffset(13 * d, 0);
    a2.Fly2:SetOffset(12 * d, 0);
    a2.Fly3:SetOffset(-25 * d, 0);

    local a3 = self.Rune3.Anim;
    a3.Fly1:SetOffset(14 * d, -8);
    a3.Fly2:SetOffset(10 * d, -4);
    a3.Rotate2:SetDegrees(-8 * d);
    a3.Fly3:SetOffset(-24 * d, 12);
    a3.Rotate3:SetDegrees(8 * d);
end

function NarciRuneAnimationMixin:SetDuration(t)
    self.Rune1.Anim.Fly2:SetDuration(t - 0.2);
    self.Rune1.Anim.Rotate2:SetDuration(t - 0.2);
    self.Rune2.Anim.Fly2:SetDuration(t - 0.4);
    self.Rune3.Anim.Fly2:SetDuration(t - 0.6);
    self.Rune3.Anim.Rotate2:SetDuration(t - 0.6);
    self.Shine.Anim.Hold:SetStartDelay(t);
end

--Debug
function NarciRuneAnimationMixin:OnMouseDown()
    self:PlayAnimation();
end

function NarciRuneAnimationMixin:OnDragStart()
    self:StartMoving();
end

function NarciRuneAnimationMixin:OnDragStop()
    self:StopMovingOrSizing();
end