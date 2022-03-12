--[[ includes: (order)

    1.Domination
    2.Class Set

--]]

local function Delay_OnUpdate(self, elapsed)
    self.delay = self.delay + elapsed;
    if self.delay >= 0 then
        self.delay = nil;
        self:SetScript("OnUpdate", nil);
        self:Update();
    end
end

NarciPaperDollWidgetControllerMixin = {};

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