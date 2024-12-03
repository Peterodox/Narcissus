local _, addon = ...

local MainFrame;
local buttons = {};

local function UpdateTabButtonVisual(selectedID)
    for i, button in pairs(buttons) do
        button:SetSelected(i == selectedID);
    end
end

addon.UpdateTabButtonVisual = UpdateTabButtonVisual;

NarciMythicPlusTabButtonMixin = {};

function NarciMythicPlusTabButtonMixin:OnLoad()
    if not MainFrame then
        MainFrame = self:GetParent():GetParent();
    end

    table.insert(buttons, self);

    self.buttonIndex = self:GetID();
    local color;
    if self.buttonIndex == 1 then
        self.isSelected = true;
        self:SetButtonText(Narci.L["Complete In Time"]);
        self.Highlight:Show();
        color = "green";
    else
        self:SetButtonText(Narci.L["Complete Over Time"]);
        local t = 0.5;
        self.Left:SetTexCoord(0 + t, 0.125 + t, 0, 0.5);
        self.Center:SetTexCoord(0.125 + t, 0.375 + t, 0, 0.5);
        self.Right:SetTexCoord(0.375 + t, 0.5 + t, 0, 0.5);
        color = "red";
    end
    local v = 0.08;
    self.Left:SetVertexColor(v, v, v);
    self.Center:SetVertexColor(v, v, v);
    self.Right:SetVertexColor(v, v, v);
    local r, g, b = NarciAPI.GetColorPresetRGB(color);
    self.ButtonText:SetTextColor(r, g, b);
    self.Highlight:SetVertexColor(r, g, b);

    self:SetSelected(self.isSelected);
end

function NarciMythicPlusTabButtonMixin:OnEnter()
    self.ButtonText:SetAlpha(1);
end

function NarciMythicPlusTabButtonMixin:OnLeave()
    if not self.isSelected then
        self.ButtonText:SetAlpha(0.5);
    end
end

function NarciMythicPlusTabButtonMixin:OnMouseDown()
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, -1);
end

function NarciMythicPlusTabButtonMixin:OnMouseUp()
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciMythicPlusTabButtonMixin:OnClick()
    UpdateTabButtonVisual(self.buttonIndex);
    MainFrame:SetMapDetailInfoType(self.buttonIndex == 1);
end

function NarciMythicPlusTabButtonMixin:SetButtonText(text)
    self.ButtonText:SetText(text);
    local width = self.ButtonText:GetWidth() + 8;
    if width < 38 then
        width = 38;
    else
        width = math.floor(width + 0.5);
    end
    self.Center:SetWidth(width);
    self:SetWidth(width + 10);
end

function NarciMythicPlusTabButtonMixin:SetSelected(state)
    self.Highlight:SetShown(state);
    self.Left:SetShown(state);
    self.Center:SetShown(state);
    self.Right:SetShown(state);
    self.isSelected = state;
    if state then
        self.ButtonText:SetAlpha(1);
    else
        self.ButtonText:SetAlpha(0.5);
    end
end