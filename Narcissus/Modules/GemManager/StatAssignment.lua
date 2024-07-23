local _, addon = ...

local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;

local MainFrame;



local CreateStatButton;
do
    local CreateFrame = CreateFrame;
    local Mixin = Mixin;

    local StatButtonMixin = {};

    function StatButtonMixin:SetData()

    end

    function StatButtonMixin:SetName(name)
        self.Name:SetText(name);
    end

    function StatButtonMixin:SetCount(count)
        self.amount = count;
        self.Count:SetText(count);
        if count > 0 then
            self.Count:SetTextColor(1, 0.82, 0);
            self.MinusButton:Show();
            self.showMinusButton = true;
        else
            self.Count:SetTextColor(0.5, 0.5, 0.5);
            self.MinusButton:Hide();
            self.showMinusButton = false;
        end
    end

    function StatButtonMixin:SetPlusButtonVisibility(showPlusButton)
        self.PlusButton:SetShown(showPlusButton);
        self.showPlusButton = showPlusButton;
    end

    function StatButtonMixin:SetValue(value)
        if self.valueFormat then
            value = string.format(self.valueFormat, value);
        end
        self.Value:SetText(value);
    end

    function StatButtonMixin:OnEnter()
        MainFrame:ShowStatAssignmentDetail(self);
    end

    function StatButtonMixin:OnLeave()
        if not self:IsMouseOver() then
            MainFrame:ShowStatAssignmentDetail(nil);
        end
    end

    function CreateStatButton(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerStatAssignmentTemplate");
        f:SetHeight(24);

        Mixin(f, StatButtonMixin);
        f.Count:SetTextColor(1, 0.82, 0);
        f.Name:SetTextColor(0.88, 0.88, 0.88);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);

        f:SetCount(0);

        AtlasUtil:SetAtlas(f.MinusButton, "gemma-stats-minus");
        AtlasUtil:SetAtlas(f.PlusButton, "gemma-stats-plus");

        f.MinusButton:SetVertexColor(0.5, 0.5, 0.5);
        f.PlusButton:SetVertexColor(0.5, 0.5, 0.5);

        return f
    end
end

function NarciGemManagerMixin:AcquireStatButton()
    if not self.statButtons then
        self.statButtons = {};
        self.numStatButtons = 0;
        MainFrame = self;
    end

    local index = self.numStatButtons + 1;
    self.numStatButtons = index;

    if not self.statButtons[index] then
        local button = CreateStatButton(self.SlotFrame);
        button.index = index;
        self.statButtons[index] = button;

        AtlasUtil:SetAtlas(button.Background, "gemma-stats-bg");
        if index % 2 == 1 then
            button.Background:SetVertexColor(0.08, 0.08, 0.08, 0.9);
        else
            button.Background:SetVertexColor(38/255, 31/255, 28/255, 0.9);
        end
    end

    self.statButtons[index]:Show();

    return self.statButtons[index]
end

function NarciGemManagerMixin:ReleaseStatButtons()
    if self.statButtons and self.numStatButtons ~= 0 then
        for _, button in pairs(self.statButtons) do
            button:Hide();
            button:ClearAllPoints();
        end
        self.numStatButtons = 0;
    end
end