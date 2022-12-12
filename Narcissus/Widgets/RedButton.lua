local MIN_CENTER_WIDTH = 32;

NarciRectRedButtonMixin = {};

function NarciRectRedButtonMixin:SetButtonText(text, resize)
    self.ButtonText:SetText(text);
    local textWidth = math.max(self.ButtonText:GetWrappedWidth(), MIN_CENTER_WIDTH);
    if self.maxWidth then
        textWidth = math.min(self.maxWidth, textWidth);
    end
    self.ButtonText:SetWidth(textWidth + 4);

    if resize then
        local centerWidth = textWidth - 24;
        self.Center:SetWidth(centerWidth);
        self.HighlightCenter:SetWidth(centerWidth);
        self:SetWidth(centerWidth + 64);
    end
end

function NarciRectRedButtonMixin:SetButtonWidth(width)
    if width > 96 then
        self.Center:SetWidth(width - 64);
        self.HighlightCenter:SetWidth(width - 64);
        self:SetWidth(width);
    end
end

function NarciRectRedButtonMixin:ToggleHighlight(state)
    self.HighlightCenter:SetShown(state);
    self.HighlightLeft:SetShown(state);
    self.HighlightRight:SetShown(state);
end

function NarciRectRedButtonMixin:SetTexOffsetY(offsetY)
    self.Center:SetTexCoord(0.25, 0.75, offsetY, offsetY + 0.25);
    self.Left:SetTexCoord(0, 0.25, offsetY, offsetY + 0.25);
    self.Right:SetTexCoord(0.75, 1, offsetY, offsetY + 0.25);

    self.HighlightCenter:SetTexCoord(0.25, 0.75, offsetY + 0.5, offsetY + 0.75);
    self.HighlightLeft:SetTexCoord(0, 0.25, offsetY + 0.5, offsetY + 0.75);
    self.HighlightRight:SetTexCoord(0.75, 1, offsetY + 0.5, offsetY + 0.75);
end

function NarciRectRedButtonMixin:OnEnter()
    self:ToggleHighlight(true);
    self.ButtonText:SetTextColor(1, 1, 1);
end

function NarciRectRedButtonMixin:OnLeave()
    self:ToggleHighlight(false);
    self.ButtonText:SetTextColor(1, 0.82, 0);
end

function NarciRectRedButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self:SetTexOffsetY(0.25);
        self.ButtonText:SetPoint("CENTER", self, "CENTER", -2, -2);
    end
end

function NarciRectRedButtonMixin:OnMouseUp()
    self:SetTexOffsetY(0);
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciRectRedButtonMixin:OnLoad()
    self:OnLeave();
end

function NarciRectRedButtonMixin:OnDisable()
    self.Left:SetDesaturated(true);
    self.Right:SetDesaturated(true);
    self.Center:SetDesaturated(true);
    self.Left:SetVertexColor(0.8, 0.8, 0.8);
    self.Right:SetVertexColor(0.8, 0.8, 0.8);
    self.Center:SetVertexColor(0.8, 0.8, 0.8); 
    self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
end

function NarciRectRedButtonMixin:OnEnable()
    self.Left:SetDesaturated(false);
    self.Right:SetDesaturated(false);
    self.Center:SetDesaturated(false);
    self.Left:SetVertexColor(1, 1, 1);
    self.Right:SetVertexColor(1, 1, 1);
    self.Center:SetVertexColor(1, 1, 1);
    if self:IsMouseOver() then
        self:OnEnter();
    else
        self:OnLeave();
    end
end



NarciSquareRedButtonMixin = {};

function NarciSquareRedButtonMixin:SetIcon(icon)
    self.Icon:SetTexture(icon);
end

function NarciSquareRedButtonMixin:ToggleHighlight(state)
    self.HighlightLeft:SetShown(state);
    self.HighlightRight:SetShown(state);
end

function NarciSquareRedButtonMixin:SetTexOffsetY(offsetY)
    self.Left:SetTexCoord(0, 0.125, offsetY, offsetY + 0.25);
    self.Right:SetTexCoord(0.875, 1, offsetY, offsetY + 0.25);

    self.HighlightLeft:SetTexCoord(0, 0.125, offsetY + 0.5, offsetY + 0.75);
    self.HighlightRight:SetTexCoord(0.875, 1, offsetY + 0.5, offsetY + 0.75);
end

function NarciSquareRedButtonMixin:OnEnter()
    self:ToggleHighlight(true);
    self.Icon:SetVertexColor(1, 1, 1);
end

function NarciSquareRedButtonMixin:OnLeave()
    self:ToggleHighlight(false);
    self.Icon:SetVertexColor(1, 0.82, 0);
end

function NarciSquareRedButtonMixin:OnMouseDown()
    self:SetTexOffsetY(0.25);
    self.Icon:SetPoint("CENTER", self, "CENTER", -2, -2);
end

function NarciSquareRedButtonMixin:OnMouseUp()
    self:SetTexOffsetY(0);
    self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciSquareRedButtonMixin:OnLoad()
    self:OnLeave();
    if self.iconFile then
        self:SetIcon(self.iconFile);
        self.iconFile = nil;
    end
end