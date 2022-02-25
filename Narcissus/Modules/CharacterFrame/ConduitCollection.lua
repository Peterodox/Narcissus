local cos = math.cos;
local pow = math.pow;
local sqrt = math.sqrt;
local pi = math.pi;

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

local FadeFrame = NarciFadeUI.Fade;

NarciConduitCollectionMixin = {};

function NarciConduitCollectionMixin:HighlightButton(button)
    if true then return end;
    
    if button then
        self.ButtonHighlight:ClearAllPoints();
        self.ButtonHighlight:SetPoint("CENTER", button, "CENTER", 0, 0);
        FadeFrame(self.ButtonHighlight, 0.15, 1, 0);
    else
        self.ButtonHighlight:Hide();
    end
end


local animExpand = NarciAPI_CreateAnimationFrame(0.5);
animExpand:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
	local h = inOutSine(self.total, self.fromH, self.toH, self.duration);

	if self.total >= self.duration then
		h = self.toH;
		self:Hide();
	end

    self.object:SetHeight(h);
end);


NarciConduitTooltipMixin = {};

function NarciConduitTooltipMixin:OnLoad()
    local BonusTextFrame = self.BonusTextFrame;
    self.Text1:SetParent(BonusTextFrame);
    self.TextLeft2:SetParent(BonusTextFrame);
    self.TextRight2:SetParent(BonusTextFrame);
end

function NarciConduitTooltipMixin:SetButtonTooltip(button, text, leftText, rightText)
    self.Name:SetText(button.Name:GetText());
    self.ItemLevel:SetText(button.ItemLevel:GetText());
    self.Name:Show();
    self.ItemLevel:Show();
    self.Text1:SetText(text);
    local r, g, b = button.Name:GetTextColor();
    self.Name:SetTextColor(r, g, b);

    local extraHight = 0;
    if leftText then
        self.TextLeft2:SetText("|cff816c2b".."Item Level".."|r\n"..leftText);
        self.TextLeft2:Show();
        extraHight = self.TextLeft2:GetHeight() + 2;
    else
        self.TextLeft2:SetText("");
        self.TextLeft2:Hide();
    end
    if rightText then
        self.TextRight2:SetText("|cff808080".."Effect".."|r\n"..rightText);
        self.TextRight2:Show();
    else
        self.TextRight2:SetText("");
        self.TextRight2:Hide();
    end

    animExpand.object = self.BonusTextFrame;
    animExpand.fromH = 32;
    local textHeight = self.Text1:GetHeight() + extraHight + 34;
    animExpand.toH =  textHeight;
    animExpand.duration = textHeight/250;

    self:ShowBonusText();
end

function NarciConduitTooltipMixin:ResetTooltip()
    self.Name:Hide();
    self.ItemLevel:Hide();
    self.BonusTextFrame:SetHeight(32);
    self.BonusTextFrame:Hide();
    animExpand:Hide();
end

function NarciConduitTooltipMixin:ShowBonusText()
    animExpand:Show();
    FadeFrame(self.BonusTextFrame, 0.45, 1, 0);
end

function NarciConduitTooltipMixin:FadeInHighlight(button)
    self:ResetTooltip();
    self:SetFrameLevel(button:GetFrameLevel() + 1);
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
    local r, g, b = button.Name:GetTextColor();
    self.BorderHighlight:SetVertexColor(r, g, b);
    self:Show();

    FadeFrame(self.BorderHighlight, 0.2, 0.6, 0);
    FadeFrame(self.ButtonHighlightTop, 0.2, 1, 0);
    FadeFrame(self.BottomHighlightLeft, 0.2, 1, 0);
    FadeFrame(self.BottomHighlightRight, 0.2, 1, 0);
end