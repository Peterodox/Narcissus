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

local function ShowChildren(self, state)
    if self.children then
        for i = 1, #self.children do
            self.children[i]:SetShown(state);
        end
    end
end

local Structure = {
    [1] = {
        name = L["Use Achievement Panel"],
        type = "checkbox",
        key = "UseAsDefault",
        data = {
            default = false,
            onClickfunc = function(self)
                local state = not AchievementDB.UseAsDefault;
                AchievementDB.UseAsDefault = state;
                self.Tick:SetShown(state);
                Narci.UpdateAchievementSettings();     --defined in Narcissus\Modules\Achievement\Modules.lua
                if state then
                    self.Description:SetText(L["Use Achievement Panel Description"]);
                else
                    self.Description:SetText(NARCI_REQUIRE_RELOAD);
                end
                ShowChildren(self, state);
            end,

            description = L["Use Achievement Panel Description"],
        },
    },

    [2] = {
        name = "Replace Toasts",
        type = "checkbox",
        isChild = true,
        parentKey = "UseAsDefault",
        key = "ReplaceToast",
        data = {
            default = true,
            onClickfunc = function(self)
                local state = not AchievementDB.ReplaceToast;
                AchievementDB.ReplaceToast = state;
                self.Tick:SetShown(state);
                Narci.UpdateAchievementSettings();
            end,
            description = "Reskin the default achievement toasts.",

            onEnterfunc = function(self)
                if not self.preview then
                    self.preview = self:CreateTexture(nil, "OVERLAY", nil, 4);
                    self.preview:SetSize(128, 32);
                    self.preview:SetTexture("Interface\\AddOns\\Narcissus_Achievements\\Art\\Classic\\PlayerToastStylePreview");
                    self.preview:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 12, 2);

                    --Create a delay fade-in anim
                    local ag = self.preview:CreateAnimationGroup();
                    local a1 = ag:CreateAnimation("ALPHA");
                    a1:SetOrder(1);
                    a1:SetFromAlpha(0);
                    a1:SetToAlpha(0);
                    a1:SetDuration(0.2);
                    local a2 = ag:CreateAnimation("ALPHA");
                    a2:SetOrder(2);
                    a2:SetFromAlpha(0);
                    a2:SetToAlpha(1);
                    a2:SetDuration(0.25);
                    self.previewFadeIn = ag;
                end
                self.preview:Show();
                self.previewFadeIn:Play();
            end,

            onLeavefunc = function(self)
                if self.preview then
                    self.preview:Hide();
                    self.previewFadeIn:Stop();
                end
            end
        },
    },

    [3] = {
        name = UI_SCALE,
        type = "slider",
        key = "Scale",
        data = { minValue = 1, maxValue = 1.25, step = 0.05, default = 1, decimal = 0.01,
            func = function(value) Narci_AchievementFrame:SetScale(value); AchievementDB.Scale = value; end,
        },
    },

    [4] = {
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

    [5] = {
        name = L["Hotkey"],
        type = "keybind",
        data = {

        },
    },

    [6] = {
        name = L["Show Unearned Mark"],
        type = "checkbox",
        key = "ShowRedMark",
        data = {
            default = false,
            onClickfunc = function(self)
                local state = not AchievementDB.ShowRedMark;
                AchievementDB.ShowRedMark = state;
                self.Tick:SetShown(state);
                Narci_AchievementFrame:ShowRedMark(state);
            end,

            description = L["Show Unearned Mark Description"],
        },
    },
};

local function CreateWidget(parent, widgetData, offset, widgetIndex)
    local type = widgetData.type;
    local data = widgetData.data;
    local object;
    local height;

    local PADDING_X = 16;

    if type == "slider" then
        object = CreateFrame("Slider", nil, parent, "NarciLineSliderTemplate");
        widgetObjects[widgetIndex] = object;
        if data.minValue and data.maxValue then
            object:SetWidth(120);
            object:SetMinMaxValues(data.minValue, data.maxValue);
            object:SetObeyStepOnDrag(true);
            object:SetValueStep(data.step);
            NarciAPI_SliderWithSteps_OnLoad(object);
            object.func = data.func;
            object.decimal = data.decimal;

            local defaultValue = AchievementDB[widgetData.key] or data.default;
            object:SetValue(defaultValue);
            object.Label:SetText(widgetData.name);
        end
        local padding = 24;
        object:SetPoint("TOP", parent, "TOP", 0, offset - padding);
        height = 2 * padding;

    elseif type == "radio" then
        local info;
        local choices = {};
        local numButtons = #data;
        local header = parent:CreateFontString(nil, "OVERLAY", "NarciPrefFontGrey9");
        header:SetText(widgetData.name);
        local padding = 8;
        header:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset - padding);
        local defaultValue = AchievementDB[widgetData.key] or data.default;

        widgetObjects[widgetIndex] = {
            [1] = header,
        };

        for i = 1, numButtons do
            info = data[i];
            object = CreateFrame("Button", nil, parent, "NarciRadioButtonTemplate");
            choices[i] = object;
            widgetObjects[widgetIndex][i + 1] = object;
            object:Initialize(info.groupIndx, info.name);
            object:SetScript("OnClick", info.func);
            if i == 1 then
                object:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset -24);
            else
                object:SetPoint("TOPLEFT", choices[i - 1], "BOTTOMLEFT", 0, -4);
                if i == numButtons then
                    object:UpdateGroupHitBox();
                end
            end
            if i == defaultValue then
                object:Select();
            end
        end
        height = header:GetTop() - object:GetBottom() + padding;

    elseif type == "checkbox" then
        object = CreateFrame("Button", nil, parent, "NarciCheckBoxTemplate");
        widgetObjects[widgetIndex] = object;
        object:SetScript("OnClick", data.onClickfunc);
        object:SetScript("OnEnter", data.onEnterfunc);
        object:SetScript("OnLeave", data.onLeavefunc);
        object:SetScript("OnShow", data.onShowFunc);
        object.Label:SetText(widgetData.name);
        local padding;
        if widgetData.isChild then
            padding = 8;
            object:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X + 16, offset - padding);
            object:SetShown(AchievementDB[widgetData.parentKey]);
        else
            padding = 24;
            object:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_X, offset - padding);
        end

        local defaultValue = AchievementDB[widgetData.key];
        object.Tick:SetShown(defaultValue);
        object.IsOn = defaultValue;

        if data.description then
            object.Description = object:CreateFontString(nil, "ARTWORK", "NarciPreferenceDescriptionTemplate");
            --object.Description:SetPoint("TOPLEFT", object.Label, "BOTTOMLEFT", 0, -4);    --Already defined in the template
            object.Description:SetSize(0, 0);
            object.Description:SetPoint("RIGHT", parent, "RIGHT", -24, 0);
            object.Description:SetText(data.description);
            height = object:GetTop() - object.Description:GetBottom();
        else
            height = object:GetTop() - object.Label:GetBottom();
        end

        height = height + padding

    elseif type == "keybind" then
        local padding = 24;
        object = CreateFrame("Button", nil, parent, "NarciBindingButtonTemplate");
        widgetObjects[widgetIndex] = object;
        object:SetSize(78, 18);
        object.Label:SetText(widgetData.name);
        object:SetPoint("TOP", parent, "TOP", 0, offset - padding);
        height = padding + 18;
        object:SetBindingActionExternal(BIND_ACTION);
    end

    --debug --draw area
    --[[
    local background = object:CreateTexture(nil, "BACKGROUND");
    background:SetPoint("TOPLEFT", object, "TOPLEFT", -4, 4);
    background:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 4, -4);
    background:SetColorTexture(1, 0, 0, 0.5);
    --]]

    return -height, object, widgetData.isChild
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

local function AddChildWidget(parent, child)
    if parent then
        if not parent.children then
            parent.children = {};
        end
        tinsert(parent.children, child);
    end
end

local function CreateSettings(frame)
    local fromOffsetY = 0;
    local offset = 0;
    local isChild, object, parentObject;
    for i = 1, #Structure do
        offset, object, isChild = CreateWidget(frame, Structure[i], fromOffsetY, i);
        fromOffsetY = offset + fromOffsetY;
        if isChild then
            AddChildWidget(parentObject, object);
        else
            parentObject = object;
        end
    end
    frame:SetHeight(24 -fromOffsetY);
    Structure = nil;
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