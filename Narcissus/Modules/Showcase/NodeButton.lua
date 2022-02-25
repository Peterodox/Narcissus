NarciShowcaseNodeButtonMixin = {};

function NarciShowcaseNodeButtonMixin:OnLoad()
    self.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\NodeButton", nil, nil, "TRILINEAR");
    self.HighlightTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\NodeButton", nil, nil, "TRILINEAR");
    self.Border:SetVertexColor(0.25, 0.25, 0.25);
    self.HighlightTexture:SetVertexColor(0.5, 0.5, 0.5);
end

function NarciShowcaseNodeButtonMixin:OnClick()
    for _, node in pairs(self:GetParent().Nodes) do
        if node ~= self then
            node:SetSelection(false);
        end
    end
    self:SetSelection(true, not self.selected);
    if self.onClickFunc then
        self.onClickFunc(self);
    end
end

function NarciShowcaseNodeButtonMixin:OnEnter()
    if self.Label then
        self.Label:SetTextColor(0.8, 0.8, 0.8);
    end
end

function NarciShowcaseNodeButtonMixin:OnLeave()
    if self.Label and not self.selected then
        self.Label:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciShowcaseNodeButtonMixin:SetSelection(state, playAnimation)
    self.AnimScale:Stop();
    if state then
        self.Border:SetVertexColor(0.5, 0.5, 0.5);
        self.Border:SetTexCoord(0.25, 0.5, 0.25, 0.5);
        self.HighlightTexture:SetVertexColor(0, 0.68, 0.94);
        self:LockHighlight();
        if playAnimation then
            self.AnimScale:Play();
        end
    else
        self.Border:SetVertexColor(0.25, 0.25, 0.25);
        self.Border:SetTexCoord(0, 0.25, 0.25, 0.5);
        self.HighlightTexture:SetTexCoord(0.75, 1, 0, 0.25);
        self.HighlightTexture:SetVertexColor(0.6, 0.6, 0.6);
        self:UnlockHighlight();
    end
    if self.onSelectedFunc then
        self.onSelectedFunc(self, state, playAnimation);
    end
    self.selected = state or nil;
end