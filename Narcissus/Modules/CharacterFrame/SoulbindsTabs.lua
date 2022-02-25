local tabButtons = {};

NarciSoulbindsTabButtonMixin = {};

function NarciSoulbindsTabButtonMixin:OnLoad()
    tinsert(tabButtons, self);
    if self.tabIndex == 1 then
        self.ButtonText:SetText("Selected");
        self:SetSelection(true);
    elseif self.tabIndex == 2 then
        self.ButtonText:SetText("Collected");
        self:SetSelection(false);
    end
end

function NarciSoulbindsTabButtonMixin:OnEnter()
    if not self.isSelected then
        self.ButtonText:SetTextColor(0.66, 0.66, 0.66);
    end
end

function NarciSoulbindsTabButtonMixin:OnLeave()
    if not self.isSelected then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciSoulbindsTabButtonMixin:SetSelection(state)
    if state then
        self.isSelected = true;
        if self.tabIndex == 1 then
            self.ButtonText:SetTextColor(0.188, 0.506, 0.8);
        elseif self.tabIndex == 2 then
            self.ButtonText:SetTextColor(0.659, 0.325, 0.325);
        end
    else
        self.isSelected = nil;
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciSoulbindsTabButtonMixin:OnClick()
    if not self.isSelected then
        for i = 1, #tabButtons do
            tabButtons[i]:SetSelection(false);
        end
        self:SetSelection(true);
        self:GetParent():GetParent():SelectTab(self.tabIndex);
    end
end
