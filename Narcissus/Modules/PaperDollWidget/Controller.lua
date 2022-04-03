--[[ includes: (order)

    1.Domination
    2.Class Set

--]]

local WidgetContainer;


local function Delay_OnUpdate(self, elapsed)
    self.delay = self.delay + elapsed;
    if self.delay >= 0 then
        self.delay = nil;
        self:SetScript("OnUpdate", nil);
        self:Update();
    end
end

NarciPaperDollWidgetControllerMixin = {};

function NarciPaperDollWidgetControllerMixin:OnLoad()
    WidgetContainer = self.WidgetContainer;
end

function NarciPaperDollWidgetControllerMixin:Init()
    local parentFrame = PaperDollFrame;

    parentFrame:HookScript("OnShow", function()
        if self.isEnabled then
            self:ListenEvents(true);
            self.WidgetContainer:Show();
            self:Update();
        end
    end);

    parentFrame:HookScript("OnHide", function()
        self:ListenEvents(false);
    end);

    local titleFrame = PaperDollTitlesPane;
    if titleFrame then
        titleFrame:HookScript("OnShow", function()
            self:ListenEvents(false);
            self.WidgetContainer:Hide();
        end);
        titleFrame:HookScript("OnHide", function()
            if self.isEnabled and parentFrame:IsVisible() then
                self:ListenEvents(true);
                self.WidgetContainer:Show();
                self:Update();
            end
        end);
    end

    self.Init = nil;
    NarciPaperDollWidgetControllerMixin.Init = nil;
end

function NarciPaperDollWidgetControllerMixin:Enable()
    if self.Init then
        self:Init();
    end
    local p = PaperDollFrame;
    self.WidgetContainer:ClearAllPoints();
    self.WidgetContainer:SetParent(p);
    self.WidgetContainer:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, 0);
    self.WidgetContainer:Show();
    self.WidgetContainer:SetFrameStrata("HIGH");
    self.isEnabled = true;

    NarcissusDB.PaperDollWidget = true;
end

function NarciPaperDollWidgetControllerMixin:Disable()
    self:ListenEvents(false);
    self.WidgetContainer:ClearAllPoints();
    self.WidgetContainer:SetParent(self);
    self.WidgetContainer:Hide();
    self.isEnabled = false;

    NarcissusDB.PaperDollWidget = false;
end

function NarciPaperDollWidgetControllerMixin:SetEnabled(state)
    if state then
        self:Enable();
    else
        self:Disable();
    end
end

function NarciPaperDollWidgetControllerMixin:AddWidget(newWidget, index)
    if not self.widgets then
        self.widgets = {};
    end
    self.widgets[index] = newWidget;
    newWidget.parent = self.WidgetContainer;
    newWidget:ResetAnchor();
end

function NarciPaperDollWidgetControllerMixin:ListenEvents(state)
    if state then
        self:RegisterEvent("BAG_UPDATE");
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    else
        self:UnregisterEvent("BAG_UPDATE");
        self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    end
end

function NarciPaperDollWidgetControllerMixin:OnEvent(event, ...)
    if not self.delay then
        self:SetScript("OnUpdate", Delay_OnUpdate);
    end
    self.delay = -0.1;
end

function NarciPaperDollWidgetControllerMixin:Update()
    if self.widgets[1]:Update() then
        self.widgets[2]:Hide();
    else
        self.widgets[2]:Update();
    end
end

function NarciPaperDollWidgetControllerMixin:HighlightSlots(slots)
    if slots then
        if type(slots) == "number" then
            slots = { slots };
        end
        if not self.highlights then
            self.highlights = {};
        end
        for i = 1, #slots do
            if not self.highlights[i] then
                self.highlights[i] = CreateFrame("Frame", nil, WidgetContainer, "NarciPaperDollItemHighlightTemplate");
            end
            self.highlights[i]:HighlightSlot(slots[i]);
        end
    end
end

function NarciPaperDollWidgetControllerMixin:ClearHighlights()
    if self.highlights then
        for _, f in pairs(self.highlights) do
            f:Clear();
        end
    end
end


--Highlight PaperDoll button when mouseover indicator--

local COLORS = {
    [1] = {0.25, 0.83, 0.66};    --Progenitor Class Set (turquoise)
};


NarciPaperDollItemHighlightMixin = {};

function NarciPaperDollItemHighlightMixin:OnLoad()
    self:SetColor(1);
    self:SetScript("OnLoad", nil);
end

function NarciPaperDollItemHighlightMixin:SetColor(colorIndex)
    if self.colorIndex ~= colorIndex then
        if COLORS[colorIndex] then
            self.BorderHighlight:SetVertexColor( unpack(COLORS[colorIndex]) );
        end
        self.colorIndex = colorIndex;
    end
end

function NarciPaperDollItemHighlightMixin:HighlightSlot(slotID)
    local slotName = NarciAPI.GetInventorySlotNameBySlotID(slotID);
    if slotName then
        local slotButton = _G["Character"..slotName];
        if slotButton then
            self:ClearAllPoints();
            self:SetParent(slotButton);
            self:SetPoint("TOPLEFT", slotButton, "TOPLEFT", 0, 0);
            self:SetPoint("BOTTOMRIGHT", slotButton, "BOTTOMRIGHT", 0, 0);
            local a = 4 * self:GetSize();
            self.BorderHighlight:SetSize(a, a);
            self:Show();
            self.BorderHighlight.Shine:Play();
            self.active = true;
            return true
        end
    end
    self:Clear();
    return false
end

function NarciPaperDollItemHighlightMixin:Clear()
    self.active = nil;
    self:ClearAllPoints();
    self:SetParent(WidgetContainer);
    self:StopAnimating();
    self:Hide();
end

function NarciPaperDollItemHighlightMixin:OnHide()
    if self.active then
        self:Clear();
    end
end