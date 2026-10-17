local _, addon = ...


local Def = {
    LabelPadding = 10,
    ButtonMinWidth = 48,
};


local TabButtonMixin = {};
addon.CharacterUITabButtonMixin = TabButtonMixin;

function TabButtonMixin:SetText(text)
    self.Label:SetText(text);
    local width = math.max(Def.ButtonMinWidth, self.Label:GetUnboundedStringWidth() + 2 * Def.LabelPadding);
    self:SetButtonWidth(width);
    return width;
end

function TabButtonMixin:SetSelected(selected)
    self.selected = selected;
    self:UpdateVisual();
end

function TabButtonMixin:SetButtonWidth(width)
    self:SetWidth(width);
    self.Label:SetWidth(width + 0.1 - 2 * Def.LabelPadding);
end

function TabButtonMixin:UpdateVisual()
    if self.selected then
        self.Label:SetTextColor(0.92, 0.92, 0.92);
        self.Highlight:Show();
    else
        if self:IsMouseMotionFocus() then
            self.Label:SetTextColor(0.85, 0.85, 0.85);
        else
            self.Label:SetTextColor(0.5, 0.5, 0.5);
        end
        self.Highlight:Hide();
    end
end

function TabButtonMixin:OnEnter()
    self:UpdateVisual();
end

function TabButtonMixin:OnLeave()
    self:UpdateVisual();
end

function TabButtonMixin:OnMouseDown()
    if not self.selected then
        self.Label:SetPoint("CENTER", self, "CENTER", 0, -1);
    end
end

function TabButtonMixin:OnMouseUp()
    self.Label:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function TabButtonMixin:OnClick()
    self:SelectTab();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function TabButtonMixin:SelectTab()
    -- Override
end


function addon.CreateTabSystem(frame, enableBackground, enableDivider)
    local tabButtonHeight = 24;

    if not frame then
        frame = CreateFrame("Frame", nil, UIParent);
    end

    addon.SeupTabSystem(frame);

    frame:SetTabButtonContainer(frame);
    frame:SetTabButtonAlignment("horizontal");
    frame:SetTabButtonSpacing(0);
    frame:SetFirstTabButtonPosition("TOPLEFT", "TOPLEFT", 0, 0);
    frame:SetTabButtonTemplate("NarciCharacterUITabButtonTemplate");

    frame:SetTabFrameContainer(frame);
    frame:SetTabFrameInsets(0, 0, tabButtonHeight, 0);

    if enableBackground then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND");
        frame.Background:SetColorTexture(0.08, 0.08, 0.08, 0.9);
        frame.Background:SetAllPoints(frame);
    end

    if enableDivider then
        frame.Divider = frame:CreateTexture(nil, "OVERLAY", nil, 5);
        frame.Divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -tabButtonHeight);
        frame.Divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -tabButtonHeight);
        frame.Divider:SetHeight(12);
        frame.Divider:SetTexture("Interface/AddOns/Narcissus/Art/NavBar/Shadow-Horizontal");
    end

    return frame ---@type TabSystem
end
