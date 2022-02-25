local BIND_ACTION = "CLICK Narci_Achievement_MinimapButton:LeftButton";
_G["BINDING_NAME_CLICK ".."Narci_Achievement_MinimapButton:LeftButton"] = "Open Narcissus Achievement Panel";

--local FadeFrame = NarciAPI_FadeFrame;
local Color_Good = "|cff7cc576";     --124 197 118
local Color_Good_r = 124/255;
local Color_Good_g = 197/255;
local Color_Good_b = 118/255;
local Color_Bad = "|cffee3224";      --238 50 36
local Color_Bad_r = 238/255;
local Color_Bad_g = 50/255;
local Color_Bad_b = 36/255;
local Color_Alert = "|cfffced00";    --252 237 0
local Color_Alert_r = 252/255;
local Color_Alert_g = 237/255;
local Color_Alert_b = 0;

local L = Narci.L;
local AchievementDB;
local SettingsFrame;

local widgetObjects = {};
local function ShowOrHideWidgetGroup(parentIndex, widgetIndex, visible)
    if widgetObjects[parentIndex] and widgetObjects[parentIndex][widgetIndex] then
        local widgetGroup = widgetObjects[parentIndex][widgetIndex];
        for i = 1, #widgetGroup do
            widgetGroup[i]:SetShown(visible);
        end
    end
end

local WidgetStructure = {
    [1] = {
        name = "Narcissus Achievement",
        widgets = {
            [1] = {
                name = L["Use Achievement Panel"],
                type = "checkbox",
                key = "UseAsDefault",
                data = {
                    default = false,
                    func = function(self)
                        local state = not AchievementDB.UseAsDefault;
                        AchievementDB.UseAsDefault = state;
                        self.Tick:SetShown(state);
                        Narci.RedirectPrimaryAchievementFrame();     --defined in Narcissus\ModulesAchievement\Loader.lua
                        if state then
                            self.Description:SetText(L["Use Achievement Panel Description"]);
                        else
                            self.Description:SetText(NARCI_REQUIRE_RELOAD);
                        end
                    end,

                    description = L["Use Achievement Panel Description"],
                },
            },

            [2] = {
                name = UI_SCALE,
                type = "slider",
                key = "Scale",
                data = { minValue = 1, maxValue = 1.25, step = 0.05, default = 1, decimal = 0.01,
                    func = function(value) Narci_AchievementFrame:SetScale(value); AchievementDB.Scale = value; end,
                },
            },

            [3] = {
                name = L["Themes"],
                type = "radio",
                key = "Theme",
                data = {
                    default = 1,
                    [1] = {name = "Dark Wood", func = function(self) NarciAchievement_SelectTheme(1) self:UpdateVisual() end, groupIndx = 1, },
                    [2] = {name = "Classic", func = function(self) NarciAchievement_SelectTheme(2) self:UpdateVisual() end, groupIndx = 1, },
                    [3] = {name = "Flat", func = function(self) NarciAchievement_SelectTheme(3) self:UpdateVisual() end, groupIndx = 1, },
                },
            },

            [4] = {
                name = L["Hotkey"],
                type = "keybind",
                data = {
                    
                },
            },

            [5] = {
                name = L["Show Unearned Mark"],
                type = "checkbox",
                key = "ShowRedMark",
                data = {
                    default = false,
                    func = function(self)
                        local state = not AchievementDB.ShowRedMark;
                        AchievementDB.ShowRedMark = state;
                        self.Tick:SetShown(state);
                        Narci_AchievementFrame:ShowRedMark(state);
                    end,

                    description = L["Show Unearned Mark Description"],
                },
            },
        },
    },
}

local function ClearAllBinding()
    local key1, key2 = GetBindingKey(BIND_ACTION);
    if key1 then
        SetBinding(key1, nil, 1)
    end
    if key2 then
        SetBinding(key2, nil, 1)
    end
    SaveBindings(1);
end

local function ShouldConfirmKey(self)
    local key = self.key;
    if not key then
        return;
    end
    if key == "SHIFT" or key=="ALT" or key=="CTRL" then
        self.key = nil;
        self.Value:SetText(NOT_BOUND);
        self.Description:SetText(Color_Bad..NARCI_INVALID_KEY);
        self.Highlight:SetColorTexture(Color_Bad_r, Color_Bad_g, Color_Bad_b);
        return false;
    else
        self.key = key;
        local action = GetBindingAction(key);
        if action and action ~= "" and action ~= BIND_ACTION then
            self.Description:SetText(Color_Alert..NARCI_OVERRIDE.." "..GetBindingName(action).." ?");
            self.Highlight:SetColorTexture(Color_Alert_r, Color_Alert_g, Color_Alert_b);
            return true;
        else
            ClearAllBinding();
            if SetBinding(key, BIND_ACTION, 1) then
                self.Description:SetText(Color_Good..KEY_BOUND);
                self.Highlight:SetColorTexture(Color_Good_r, Color_Good_g, Color_Good_b);
                self.ConfirmButton:Hide();
                SaveBindings(1);    --account wide
            else
                self.Description:SetText(Color_Bad..ERROR_CAPS);
                self.Highlight:SetColorTexture(Color_Bad_r, Color_Bad_g, Color_Bad_b);
            end
            return false;
        end
    end
end

local function ResetBindVisual(self)
    self.Border:SetColorTexture(0, 0, 0);
    self.Value:SetTextColor(1, 1, 1);
    self.Value:SetShadowColor(0, 0, 0);
    self.Value:SetShadowOffset(0.6, -0.6);
    self:SetPropagateKeyboardInput(true)
    self:SetScript("OnKeyDown", nil); 
    self:SetScript("OnKeyUp", nil);
    self.IsOn = false;
end

local BindingAlertTimer;
local function ExitKeyBinding(self)
    C_Timer.After(0.05, function()
        ResetBindVisual(self)
    end)
    local shouldConfirm = ShouldConfirmKey(self);
    UIFrameFadeIn(self.Highlight, 0.2, 0, 1);
    UIFrameFadeIn(self.Description, 0.2, 0, 1);
    
    if not shouldConfirm then
        BindingAlertTimer = C_Timer.NewTimer(4, function()
            UIFrameFadeOut(self.Highlight, 0.5, self.Highlight:GetAlpha(), 0);
            UIFrameFadeOut(self.Description, 0.5, self.Description:GetAlpha(), 0);
            self.Value:SetText(GetBindingKey(BIND_ACTION) or NOT_BOUND); 
        end)
    else
        self.ConfirmButton:Show();
        BindingAlertTimer = C_Timer.NewTimer(6, function()
            UIFrameFadeOut(self.Highlight, 0.5, self.Highlight:GetAlpha(), 0);
            UIFrameFadeOut(self.Description, 0.5, self.Description:GetAlpha(), 0);
            self.Value:SetText(GetBindingKey(BIND_ACTION) or NOT_BOUND)
            self.ConfirmButton:Hide();
        end)       
    end
end

local function KeybindingButton_OnKeydown(self, key)
    if key == "ESCAPE" or key == "SPACE" or key == "ENTER"then
        ExitKeyBinding(self);
        return;
    end

    local KeyText;
    if CreateKeyChordStringUsingMetaKeyState then   --Shadowlands
        KeyText = CreateKeyChordStringUsingMetaKeyState(key);
    else
        KeyText = CreateKeyChordString(key);
    end

    self.Value:SetText(KeyText);
    self.key = KeyText;
    if not IsKeyPressIgnoredForBinding(key) then
        ExitKeyBinding(self);
    end
end

local function KeybindingButton_OnClick(self, button)
    if BindingAlertTimer then
        BindingAlertTimer:Cancel();
    end
    if button == "RightButton" then
        ClearAllBinding();
        self.Value:SetText(NOT_BOUND);
        self.key = nil;
        self.Description:SetText(Color_Alert.."Hotkey disabled");
        self.Highlight:SetColorTexture(Color_Alert_r, Color_Alert_g, Color_Alert_b);
        ResetBindVisual(self)
        UIFrameFadeIn(self.Highlight, 0.2, 0, 1);
        UIFrameFadeIn(self.Description, 0.2, 0, 1);

        BindingAlertTimer = C_Timer.NewTimer(2, function()
            UIFrameFadeOut(self.Highlight, 0.5, self.Highlight:GetAlpha(), 0);
            UIFrameFadeOut(self.Description, 0.5, self.Description:GetAlpha(), 0);
        end)
        return;
    end
    self.IsOn = not self.IsOn;
    if self.IsOn then
        self.Border:SetColorTexture(0.9, 0.9, 0.9);
        self.Value:SetTextColor(0, 0, 0);
        self.Value:SetShadowColor(1, 1, 1);
        self.Value:SetShadowOffset(0.6, -0.6);
        self:SetPropagateKeyboardInput(false);
        self:SetScript("OnKeyDown", KeybindingButton_OnKeydown);
        self:SetScript("OnKeyUp", function(self)
            ExitKeyBinding(self)
        end);
    else
        ExitKeyBinding(self)
    end
end

local function KeybindingButton_OnShow(self)
    self.Value:SetText(GetBindingKey(BIND_ACTION) or NOT_BOUND);
    self.action = BIND_ACTION;
end


local function CreateWidget(parent, widgetData, offset, parentIndex, widgetIndex)
    if parentIndex and widgetIndex then
        if not widgetObjects[parentIndex] then
            widgetObjects[parentIndex] = {};
        end
        if not widgetObjects[parentIndex][widgetIndex] then
            widgetObjects[parentIndex][widgetIndex] = {};
        end
    end
    local widgetGroup = widgetObjects[parentIndex][widgetIndex];

    local type = widgetData.type;
    local data = widgetData.data;
    local element;
    local height;

    local PADDING_X = 1;

    if type == "slider" then
        element = CreateFrame("Slider", nil, parent, "NarciLineSliderTemplate");
        tinsert(widgetGroup, element);
        if data.minValue and data.maxValue then
            element:SetWidth(120);
            element:SetMinMaxValues(data.minValue, data.maxValue);
            element:SetObeyStepOnDrag(true);
            element:SetValueStep(data.step);
            NarciAPI_SliderWithSteps_OnLoad(element);
            element.func = data.func;
            element.decimal = data.decimal;

            local defaultValue = AchievementDB[widgetData.key] or data.default;
            element:SetValue(defaultValue);
            element.Label:SetText(widgetData.name);
        end
        element:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, offset - 8);
        height = 46;

    elseif type == "radio" then
        local info;
        local elements = {};
        local numButtons = #data;
        local header = parent:CreateFontString(nil, "OVERLAY", "NarciPrefFontGrey9");
        tinsert(widgetGroup, header);
        header:SetText(widgetData.name);
        header:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset);
        local defaultValue = AchievementDB[widgetData.key] or data.default;

        for i = 1, numButtons do
            info = data[i];
            element = CreateFrame("Button", nil, parent, "NarciRadioButtonTemplate");
            tinsert(widgetGroup, element);
            tinsert(elements, element);
            element:Initialize(info.groupIndx, info.name);
            element:SetScript("OnClick", info.func);
            if i == 1 then
                element:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset -20);
            else
                element:SetPoint("TOPLEFT", elements[i - 1], "BOTTOMLEFT", 0, -4);
                if i == numButtons then
                    element:UpdateGroupHitBox();
                end
            end
            if i == defaultValue then
                element:Select();
            end
        end
        
        height = numButtons * 24 + (numButtons - 1) * 4 + 24;

    elseif type == "checkbox" then
        element = CreateFrame("Button", nil, parent, "NarciCheckBoxTemplate");
        tinsert(widgetGroup, element);
        element:SetScript("OnClick", data.func);
        element:SetScript("OnShow", data.onShowFunc);
        element.Label:SetText(widgetData.name);
        element:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset);

        local defaultValue = AchievementDB[widgetData.key];
        element.Tick:SetShown(defaultValue);
        element.IsOn = defaultValue;

        height = 30;

        if data.description then
            element.Description = element:CreateFontString(nil, "OVERLAY", "NarciPreferenceDescriptionTemplate");
            element.Description:SetWidth(200);
            element.Description:SetText(data.description);
            height = height + element.Description:GetHeight() + 8;
        end
        

    elseif type == "keybind" then
        element = CreateFrame("Button", nil, parent, "NarciBindingButtonTemplate");
        tinsert(widgetGroup, element);
        element:SetSize(78, 18);
        element.Label:SetText(widgetData.name);
        element:SetPoint("TOPLEFT", parent, "TOPLEFT", 80, offset);
        height = 48;

        element:SetScript("OnClick", KeybindingButton_OnClick);
        element:SetScript("OnShow", KeybindingButton_OnShow);
    end

    return -height
end

local function AnchorToUIParent()
    local parent = SettingsFrame:GetParent();
    local x = parent:GetRight();
    local y = parent:GetTop();
    SettingsFrame:ClearAllPoints();
    local uiScale = UIParent:GetEffectiveScale() * parent:GetScale();
    SettingsFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", uiScale * x + 8, uiScale * y - 4);
end

local function SettingsFrame_OnShow(self)
    AnchorToUIParent();
    if self.linkedTabButton then
        self.linkedTabButton:Select();
    end
end

local function SettingsFrame_OnHide(self)
    self:Hide();
    if self.linkedTabButton then
        self.linkedTabButton:Deselect();
    end
end

local function CreateSettings(frame)
    local sectors = {};
    local sector;
    local widgets;
    local startOffset = -24;
    for i = 1, #WidgetStructure do
        sector = CreateFrame("Frame", nil, frame);
        tinsert(sectors, sector);
        if i == 1 then
            sector:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12);
            sector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12);
        else
            sector:SetPoint("TOPLEFT", sectors[i - 1], "BOTTOMLEFT", 0, -36);
            sector:SetPoint("TOPRIGHT", sectors[i - 1], "BOTTOMRIGHT", 0, -36);
        end

        local header = sector:CreateFontString(nil, "OVERLAY", "NarciPrefFontGrey9");
        header:SetText(WidgetStructure[i].name);
        header:SetJustifyH("LEFT");
        header:SetJustifyV("TOP");
        header:SetPoint("TOPLEFT", sector, "TOPLEFT", 0, 0);
        header:SetPoint("TOPRIGHT", sector, "TOPRIGHT", 0, 0);

        widgets = WidgetStructure[i].widgets;

        for j = 1, #widgets do
            startOffset = startOffset + CreateWidget(sector, widgets[j], startOffset, i, j);
        end
        sector:SetHeight(-startOffset);
    end
    frame:SetHeight(4 -startOffset);

    wipe(WidgetStructure);
    WidgetStructure = nil;
end

local function LoadSettings(self)
    CreateSettings(self);
    local v = 0.2;
    self:SetBorderColor(v, v, v);
    self:SetBackgroundColor(0.07, 0.07, 0.08, 0.95);
    self:SetOffset(10);
    self:HideWhenParentIsHidden(true);
    self:SetScript("OnShow", SettingsFrame_OnShow);
    self:SetScript("OnHide", SettingsFrame_OnHide);
    self.AnchorToUIParent = AnchorToUIParent;

    CreateWidget = nil;
    CreateSettings = nil;
    LoadSettings = nil;
end

local initialize = CreateFrame("Frame");
initialize:RegisterEvent("ADDON_LOADED");
initialize:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        if name == "Narcissus_Achievements" then
            self:UnregisterEvent(event);
            AchievementDB = NarciAchievementOptions;
            SettingsFrame = Narci_AchievementSettings;
            C_Timer.After(0, function()
                LoadSettings(SettingsFrame);
            end)
            initialize = nil;
        end
    end
end)