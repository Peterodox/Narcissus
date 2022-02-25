local floor = math.floor;

local function round(n, digits)
    digits = digits or 0;
    local a = 10 ^ digits;
    return floor(n*a + 0.5)/a
end

NarciAchievementTabButtonMixin = {};

function NarciAchievementTabButtonMixin:OnLoad()
    self:SetDarken(true);
end

function NarciAchievementTabButtonMixin:SetDarken(darken)
    if darken then
        self.normalLeft:SetVertexColor(0.66, 0.66, 0.66);
        self.normalMiddle:SetVertexColor(0.66, 0.66, 0.66);
        self.normalRight:SetVertexColor(0.66, 0.66, 0.66);
    else
        self.normalLeft:SetVertexColor(1, 1, 1);
        self.normalMiddle:SetVertexColor(1, 1, 1);
        self.normalRight:SetVertexColor(1, 1, 1);
    end
end

function NarciAchievementTabButtonMixin:Resize()
    local textWidth = self.label:GetWidth();
    if textWidth < 32 then
        textWidth = 32;
    end
    textWidth = round(textWidth);
    self.normalMiddle:SetWidth(textWidth);
    self:SetWidth(40 + textWidth);
end

function NarciAchievementTabButtonMixin:SetLabel(text)
    self.label:SetText(text);
    self:Resize();
end

function NarciAchievementTabButtonMixin:Select()
    self.isSelected = true;
    self.label:SetTextColor(1, 0.91, 0.647);
    self:SetDarken(false);
end

function NarciAchievementTabButtonMixin:Deselect()
    self.isSelected = nil;
    self.label:SetTextColor(0.8, 0.8, 0.8);
    self:SetDarken(true);
    --self.highlight:SetAlpha(0);
end

function NarciAchievementTabButtonMixin:OnClick()
    
end

function NarciAchievementTabButtonMixin:ShowPushedTexture()
    local texOffset = 0;
    self.normalLeft:SetTexCoord(texOffset + 0, texOffset + 0.125, 0.5, 1);
    self.normalMiddle:SetTexCoord(texOffset + 0.125, texOffset + 0.375, 0.5, 1);
    self.normalRight:SetTexCoord(texOffset + 0.375, texOffset + 0.5, 0.5, 1);
    --self.label:SetScale(0.95);
    self.label:SetAlpha(0.6);
end

function NarciAchievementTabButtonMixin:ShowNormalTexture()
    local texOffset = 0;
    self.normalLeft:SetTexCoord(texOffset + 0, texOffset + 0.125, 0, 0.5);
    self.normalMiddle:SetTexCoord(texOffset + 0.125, texOffset + 0.375, 0, 0.5);
    self.normalRight:SetTexCoord(texOffset + 0.375, texOffset + 0.5, 0, 0.5);
    --self.label:SetScale(1);
    self.label:SetAlpha(1);
end

function NarciAchievementTabButtonMixin:OnEnter()
    self:SetDarken(false);
end

function NarciAchievementTabButtonMixin:OnLeave()
    if not self.isSelected then
        self:SetDarken(true);
    end
end

function NarciAchievementTabButtonMixin:SetTextOffset(offsetY)
    offsetY = offsetY or 20; --28/20
    self.inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, offsetY);
end

function NarciAchievementTabButtonMixin:SetButtonTexture(filePath)
    self.normalLeft:SetTexture(filePath);
    self.normalMiddle:SetTexture(filePath);
    self.normalRight:SetTexture(filePath);
end