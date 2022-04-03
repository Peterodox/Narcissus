local _, addon = ...
local UIContainer = NarciGamePadOverlay;

------------------------------------------------------
local GamePadButtonPool = {};
GamePadButtonPool.buttons = {};

addon.GamePadButtonPool = GamePadButtonPool;

function GamePadButtonPool:GetButton(name)
    if name then
        if not self.buttons[name] then
            self.buttons[name] = CreateFrame("Frame", nil, UIContainer, "NarciGamePadControllerButtonTemplate");
            self.buttons[name]:SetKey(name);
        end
        return self.buttons[name]
    end
end

function GamePadButtonPool:SetButtonLabel(name, label)
    local button = self:GetButton(name);
    button:SetLabel(label);
    return button
end

function GamePadButtonPool:SetupButton(name, label, parentFrame, point, anchorTo, relativePoint, offsetX, offsetY, labelDirection)
    if self.cursorMode then
        return
    end

    local button = self:GetButton(name);
    button:ClearAllPoints();
    if parentFrame and anchorTo then
        button:SetParent(parentFrame);
        button:SetPoint(point, anchorTo, relativePoint, offsetX, offsetY);
        button:SetLabelDirection(labelDirection or 1);
        button:SetFrameLevel(parentFrame:GetFrameLevel() + 2);
        button:StopAnimating();
        button:Show();
        if name == "PAD1" then
            button:PlayEntrance();
        end
    else
        button:ResetAnchor();
        button:Hide();
    end
    local width = button:SetLabel(label);
    return button, width or 24
end

function GamePadButtonPool:HideAllButtons()
    for name, button in pairs(self.buttons) do
        button:Hide();
    end
end

function GamePadButtonPool:OnGamePadActiveChanged(isActive)
    if isActive then
        self.cursorMode = nil;
    else
        self:HideAllButtons();
        self.cursorMode = true;
    end
end

function GamePadButtonPool:SignalPress(buttonName)
    if self.buttons[buttonName] then
        self.buttons[buttonName]:PlayPressFeedback();
    end
end

------------------------------------------------------
NarciGamePadControllerButtonMixin = {};

function NarciGamePadControllerButtonMixin:SetTheme()

end

function NarciGamePadControllerButtonMixin:SetKey(name)
    --ABXY
    if name == "PAD1" then
        self.ButtonIcon:SetTexCoord(0, 0.5, 0, 0.5);
    elseif name == "PAD2" then
        self.ButtonIcon:SetTexCoord(0.5, 1, 0, 0.5);
    elseif name == "PAD3" then
        self.ButtonIcon:SetTexCoord(0, 0.5, 0.5, 1);
    elseif name == "PAD4" then
        self.ButtonIcon:SetTexCoord(0.5, 1, 0.5, 1);
    end
    self.name = name;
end

function NarciGamePadControllerButtonMixin:SetLabel(text)
    if text then
        self.Label:SetText(text);
        self:Show();
    else
        self.Label:SetText("");
        self:Hide();
    end
    local width = 24 + 4 + (self.Label:GetWidth() or 0);
    return width
end

function NarciGamePadControllerButtonMixin:SetLabelDirection(x)
    self.Label:ClearAllPoints();
    if x < 0 then
        --label on the left
        self.Label:SetPoint("RIGHT", self, "CENTER", -16, 0);
    else
        self.Label:SetPoint("LEFT", self, "CENTER", 16, 0);
    end
end

function NarciGamePadControllerButtonMixin:OnLoad()
    self:SetFrameStrata("HIGH");
    self:SetFixedFrameStrata(true);
end

function NarciGamePadControllerButtonMixin:OnHide()
    self:ResetAnchor();
    self:StopAnimating();
end

function NarciGamePadControllerButtonMixin:PlayEntrance()
    self:StopAnimating();
    self.FadeIn:Stop();
    self.FadeIn:Play();
end

function NarciGamePadControllerButtonMixin:PlayPressFeedback()
    self:StopAnimating();
    if self:IsVisible() then
        self.ButtonIcon.PressFeedback:Play();
        self.ButtonOuterGlow.PressFeedback:Play();
    end
end

function NarciGamePadControllerButtonMixin:ResetAnchor()
    self:ClearAllPoints();
    self:Hide();
    self:SetParent(UIContainer);
    self:SetPoint("CENTER", 0, 0);
end