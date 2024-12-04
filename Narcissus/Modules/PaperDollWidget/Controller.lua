--[[ includes: (order)

    1. Domination (Deprecated)
    2. Class Set
    3. Remix Gem
--]]

local _, addon = ...
local IsModuleEnabled = addon.IsModuleEnabled;
local Controller, WidgetContainer;


local function Delay_OnUpdate(self, elapsed)
    self.delay = self.delay + elapsed;
    if self.delay >= 0 then
        self.delay = nil;
        self:SetScript("OnUpdate", nil);
        self:UpdateWidgets();
    end
end

NarciPaperDollWidgetControllerMixin = {};

function NarciPaperDollWidgetControllerMixin:OnLoad()
    Controller = self;
    WidgetContainer = self.WidgetContainer;
end

function NarciPaperDollWidgetControllerMixin:Init()
    local parentFrame = PaperDollFrame;

    parentFrame:HookScript("OnShow", function()
        if self.isEnabled then
            self:ListenEvents(true);
            WidgetContainer:Show();
            self:UpdateWidgets();
        end
    end);

    parentFrame:HookScript("OnHide", function()
        self:ListenEvents(false);
    end);

    local titleFrame = PaperDollFrame.TitleManagerPane;
    if titleFrame then
        titleFrame:HookScript("OnShow", function()
            self:ListenEvents(false);
            WidgetContainer:Hide();
        end);
        titleFrame:HookScript("OnHide", function()
            if self.isEnabled and parentFrame:IsVisible() then
                self:ListenEvents(true);
                WidgetContainer:Show();
                self:UpdateWidgets();
            end
        end);
    end

    self.Init = nil;
    NarciPaperDollWidgetControllerMixin.Init = nil;
end

local function UpdateParent()
    if GwDressingRoomGear then
        local parent = GwDressingRoomGear;
        WidgetContainer:SetParent(parent);
        parent:HookScript("OnShow", function()
            if Controller.isEnabled then
                Controller:ListenEvents(true);
                WidgetContainer:Show();
                Controller:UpdateWidgets();
            end
        end);
    
        parent:HookScript("OnHide", function()
            Controller:ListenEvents(false);
        end);
    end
end

local function UpdatePosition_OnShow()
    --adjustment for serveral addons/WA
    if CharacterStatsPaneilvl then
        --Chonky Character Sheet    wago.io/bRl2gJIgz
        WidgetContainer:ClearAllPoints();
        WidgetContainer:SetPoint("CENTER", CharacterStatsPaneilvl, "RIGHT", 22, 0);     --anchor changed after swapping items, IDK why
    elseif C_AddOns.IsAddOnLoaded("DejaCharacterStats") then
        WidgetContainer:ClearAllPoints();
        WidgetContainer:SetPoint("CENTER", PaperDollFrame, "TOPRIGHT", -1, -84);
    elseif GwDressingRoomGear then   --GW2 UI
        WidgetContainer:SetParent(GwDressingRoomGear);
        WidgetContainer:ClearAllPoints();
        WidgetContainer:SetPoint("CENTER", GwDressingRoomGear, "TOPRIGHT", 12, -60);
    elseif CharacterFrame and CharacterStatsPane and CharacterStatsPane.ItemLevelFrame then
        --A universal approach to align to the ItemLevelFrame center    (DejaCharStats)
        local anchor = CharacterStatsPane.ItemLevelFrame;
        local _, anchorY = anchor:GetCenter();
        if anchorY then
            local y0 = CharacterFrame:GetTop();
            WidgetContainer:ClearAllPoints();
            WidgetContainer:SetPoint("CENTER", PaperDollFrame, "TOPRIGHT", -1, anchorY - y0);
        end
    end

    Controller:ResetWidgetPosition();
    WidgetContainer:SetScript("OnShow", nil);
end

function NarciPaperDollWidgetControllerMixin:Enable()
    if self.Init then
        self:Init();
    end

    local parent = PaperDollFrame;
    WidgetContainer:ClearAllPoints();
    WidgetContainer:SetParent(parent);
    WidgetContainer:SetPoint("CENTER", parent, "TOPRIGHT", -1, -119);
    WidgetContainer:Show();
    WidgetContainer:SetFrameStrata("HIGH");
    WidgetContainer:SetScript("OnShow", UpdatePosition_OnShow);

    self.isEnabled = true;
    NarcissusDB.PaperDollWidget = true;


    UpdateParent();
end


function NarciPaperDollWidgetControllerMixin:Disable()
    self:ListenEvents(false);
    WidgetContainer:ClearAllPoints();
    WidgetContainer:SetParent(self);
    WidgetContainer:Hide();
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

function NarciPaperDollWidgetControllerMixin:UpdateIfEnabled()
    if self.isEnabled and self:IsVisible() then
        self:UpdateWidgets();
    end
end

function NarciPaperDollWidgetControllerMixin:AddWidget(newWidget, index, dbKey)
    if not self.widgets then
        self.widgets = {};
    end

    if self.widgets[index] then
        print(string.format("Narcissus: Widget #%s %s already exisit!", index, dbKey or "Unnamed"));
    else
        self.widgets[index] = newWidget;
    end

    newWidget.parent = WidgetContainer;
    newWidget.dbKey = dbKey;
    newWidget:ResetAnchor();
end

function NarciPaperDollWidgetControllerMixin:RemoveWidget(removedWidget)
    for index, widget in pairs(self.widgets) do
        if widget == removedWidget then
            self.widgets[index] = nil;
            widget:Hide();
            widget:ClearAllPoints();
            widget:SetParent(nil);
            break
        end
    end
end

function NarciPaperDollWidgetControllerMixin:ResetWidgetPosition()
    if self.widgets then
        for _, widget in pairs(self.widgets) do
            widget:ResetAnchor();
        end
    end
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

function NarciPaperDollWidgetControllerMixin:UpdateWidgets()
    local isShown;

    for _, widget in pairs(self.widgets) do
        if IsModuleEnabled(widget.dbKey) then
            isShown = widget:Update();
        else
            widget:Hide();
        end
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
    [2] = {0.94, 0.6, 0};    --Yellow Ember
};


NarciPaperDollItemHighlightMixin = {};

function NarciPaperDollItemHighlightMixin:OnLoad()
    self:SetColor(2);
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


do
    function addon.SettingFunctions.EnablePaperDollWidget(state, db)
        if state == nil then
            state = db["PaperDollWidget"];
        end
        Controller:SetEnabled(state);
    end
end


do
    --ChonkyCharacterSheet supports this widget in our addon that we no longer use
    local widgetName = "NarciCharacterFrameDominationIndicator";
    if not _G[widgetName] then
        local f = CreateFrame("Frame", widgetName, UIParent);
        f:SetSize(4, 4);
        f:Hide();
    end
end