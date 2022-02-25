local UIFrameFadeIn = UIFrameFadeIn;

NarciSimpleButtonMixin = {};

function NarciSimpleButtonMixin:SetStaticWidth(width)
    self.staticWidth = width;
    self.label:SetWidth(width);
    self:SetWidth(width + 24);
end

function NarciSimpleButtonMixin:SetLabelText(text)
    self.label:SetText(text);
    if not self.staticWidth then
        self:SetWidth(self.label:GetWidth() + 24);
    end
end

function NarciSimpleButtonMixin:FadeIn()
    UIFrameFadeIn(self, 0.15, self:GetAlpha(), 1);
end

function NarciSimpleButtonMixin:FadeOut()
    UIFrameFadeIn(self, 0.2, self:GetAlpha(), 0);
end

function NarciSimpleButtonMixin:OnMouseDown()
    self.middle:SetAlpha(1);
    self.left:SetAlpha(1);
    self.right:SetAlpha(1);
end

function NarciSimpleButtonMixin:OnMouseUp()
    self.middle:SetAlpha(.5);
    self.left:SetAlpha(.5);
    self.right:SetAlpha(.5);
end

function NarciSimpleButtonMixin:OnEnter()
    UIFrameFadeIn(self.highlight, 0.15, self.highlight:GetAlpha(), 0.5);
    self.label:SetTextColor(1, 1, 1);
end

function NarciSimpleButtonMixin:OnLeave()
    UIFrameFadeIn(self.highlight, 0.15, self.highlight:GetAlpha(), 0);
    self.label:SetTextColor(0.8, 0.8, 0.8);
end