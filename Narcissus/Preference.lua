local L = Narci.L;

--NARCI_NEW_ENTRY_PREFIX..
local TabNames = { 
    L["Interface"], L["Shortcuts"], NARCI_NEW_ENTRY_PREFIX..L["Item Tooltip"], L["Themes"], L["Effects"], L["Camera"], L["Transmog"],
    L["Photo Mode"], L["NPC"], NARCI_NEW_ENTRY_PREFIX..EXPANSION_NAME8, L["Extensions"],
};  --Credits and About will be inserted later

local FadeFrame = NarciFadeUI.Fade;

local COLOR_BAD = "|cffee3224";      --238 50 36

local BIND_ACTION = "CLICK Narci_MinimapButton:LeftButton";
_G["BINDING_NAME_"..BIND_ACTION] = "Open Narcissus Character Panel";

local Narci_LetterboxAnimation = NarciAPI_LetterboxAnimation;
local floor = math.floor;

local MainFrame, CreatureTab;
local Settings, CreatureSettings;

local textLanguage = GetLocale();
if textLanguage == "enGB" then
    textLanguage = "enUS";
end

local function ShowChildButtons(parentButton, state)
    if parentButton.childButtons then
        if state then
            for i = 1, #parentButton.childButtons do
                FadeFrame(parentButton.childButtons[i], 0.2, 1, 0);
            end
        else
            for i = 1, #parentButton.childButtons do
                parentButton.childButtons[i]:Hide();
            end
        end
    end
end

--Interface
local function SetFrameScale(scale)
	local scale = tonumber(scale) or 1;

	Narci_PhotoModeToolbar:SetScale(scale);
	Narci_Character:SetScale(scale);
	Narci_Attribute:SetScale(scale);
    NarciTooltip:SetCustomScale(scale);
	if Settings then
		Settings.GlobalScale = scale;
	end
end

local function SetLetterboxEffectAlert()
    local selectedRatio = Settings.LetterboxRatio;
    local uiScale = Settings.GlobalScale;
    local recommendedScale;
    uiScale = floor(uiScale*10 + 0.5)/10;
    if selectedRatio == 2 then
        recommendedScale = 0.8;
    elseif selectedRatio == 2.35 then
        recommendedScale = 0.7;
    else
        recommendedScale = 0.7;
    end

    if Narci_LetterboxToggle then
        if uiScale > recommendedScale then
            Narci_LetterboxToggle.Description:SetText(string.format(L["Letterbox Alert2"], recommendedScale, uiScale));
            if Settings.LetterboxEffect then
                Narci_LetterboxToggle.Description:Show();
            end
        else
            Narci_LetterboxToggle.Description:Hide();
        end
    end
end

local function GlobalScaleSlider_OnValueChanged(self, value)
    value = floor(value*10 +0.5)/10;
    self.KeyLabel:SetText(string.format("%.1f", value));
    SetFrameScale(value);
    SetLetterboxEffectAlert();
end


local function SetItemNameTextSize(self, height)
    local slotTable = Narci_Character.slotTable;
    if not (slotTable and Settings) then
        return;
    end

    height = tonumber(height) or 10;
    self.KeyLabel:SetText(height);

    local font, _, flag = slotTable[1].Name:GetFont();

    Settings.FontHeightItemName = height;
    local slot;
    for i=1, #slotTable do
        slot = slotTable[i];
		if slot then
            slot.Name:SetFont(font, height, flag);
            slot:UpdateGradientSize();
		end
    end
end

local function SetItemNameTextWidth(width)
    local slotTable = Narci_Character.slotTable;
    if not (slotTable and Settings) then
        return;
    end

    local Width = tonumber(width) or 200;
    Settings.ItemNameWidth = Width;

    if Width == 200 then
        Width = 512;
    end
    
    local slot;
    for i = 1, #slotTable do
        slot = slotTable[i];
        if slot then
            slot.Name:SetWidth(Width);
            slot.ItemLevel:SetWidth(Width);
            slot:UpdateGradientSize();
        end
    end
end

local function ItemNameWidthSlider_OnValueChanged(self, value)
    local _, maxValue = self:GetMinMaxValues();
    if value < maxValue then
        self.KeyLabel:SetText(value);
        SetItemNameTextWidth(value);
    else
        self.KeyLabel:SetText(UNLIMITED);
        SetItemNameTextWidth(200);
    end
end

local function SetItemNameTextTruncated(self, state)
    local slotTable = Narci_Character.slotTable;
    if (not slotTable) then
        return;
    end

    local State = state or false;
    local MaxLines =2;
    if State then
        MaxLines = 1;
    end
    
    local slot;
    for i=1, #slotTable do
        slot = slotTable[i];
        if slot then
            slot.Name:SetMaxLines(MaxLines);
            slot.ItemLevel:SetMaxLines(MaxLines);
            slot.Name:SetWidth(slot.Name:GetWidth()+1)
            slot.Name:SetWidth(slot.Name:GetWidth()-1)
            slot.ItemLevel:SetWidth(slot.Name:GetWidth()+1)
            slot.ItemLevel:SetWidth(slot.Name:GetWidth()-1)
            slot:UpdateGradientSize();
        end
    end
end

local function ShowDetailedIlvlInfo(self, state)
	if state then
        FadeFrame(Narci_DetailedStatFrame, 0.5, 1);
        FadeFrame(Narci_RadarChartFrame, 0.5, 1);
		FadeFrame(Narci_ConciseStatFrame, 0.5, 0);
	else
        FadeFrame(Narci_DetailedStatFrame, 0.5, 0);
        FadeFrame(Narci_RadarChartFrame, 0.5, 0);
		FadeFrame(Narci_ConciseStatFrame, 0.5, 1);
	end
    Narci_ItemLevelFrame:ToggleExtraInfo(state);
    Narci_ItemLevelFrame.showExtraInfo = state;
    Narci_NavBar:SetMaximizedMode(state);
end


--Shortcuts

local function MinimapButtonSwitch_SetState(self, state)
    Narci_MinimapButton:SetShown(state);
    if state then
        Narci_MinimapButton:PlayBling();
    end
    ShowChildButtons(self, state);
end

local function MinimapButtonSwitch_OnShow(self)
    local state = Settings.ShowMinimapButton;
    ShowChildButtons(self, state);
end

local function ModulePanelSwitch_SetState(self, state)
    Narci_MinimapButton.showPanelOnMouseOver = state;
end

local function MinimapButtonParentSwitch_SetState(self, state)
    local MinimapButton = Narci_MinimapButton;
    if state then
        MinimapButton:ClearAllPoints();
        MinimapButton:SetParent(Narci_MinimapButtonContainer);
        MinimapButton:SetFrameLevel(62);
        MinimapButton:SetFrameStrata("MEDIUM");
        MinimapButton:InitPosition();
    else
        MinimapButton:SetParent(Minimap);
        MinimapButton:SetFrameStrata("MEDIUM");
        MinimapButton:SetFrameLevel(62);
    end
end

local function FadeOutSwitch_SetState(self, state)
    local button = Narci_MinimapButton;
    local alpha;
    if state then
        alpha = 0.25;
    else
        alpha = 1;
    end
    button.endAlpha = alpha;
    button:SetAlpha(alpha);
end

local function DoubleTapSwitch_SetState(self)
    local state = Settings.EnableDoubleTap;
    self.Tick:SetShown(state);
end

function Narci_DoubleTapSwitch_OnClick(self)
    Settings.EnableDoubleTap = not Settings.EnableDoubleTap;
    DoubleTapSwitch_SetState(self);
end

local function DoubleTapSwitch_OnShow(self)
    local HotKey1, HotKey2 = GetBindingKey("TOGGLECHARACTER0");
    local Text1 = L["Double Tap"];
    if HotKey1 then
        Text2 = "|cFFFFD100("..HotKey1..")|r";
        if HotKey2 then
            Text2 = Text2 .. "|cffffffff or |cFFFFD100("..HotKey2..")|r";
        end
        Text1 = Text1.." "..Text2;
    else
        Text1 = Text1.." |cff636363("..NOT_APPLICABLE..")";
    end
    self.Label:SetText(Text1);
end


local function SetUseEcapeButtonForExit(self, state)
    if state then
        Narci_PhotoModeToolbar.KeyListener.EscapeKey = "ESCAPE";
        self.Description:SetText(L["Use Escape Button Description1"]);
    else
        Narci_PhotoModeToolbar.KeyListener.EscapeKey = "HELLOWORLD";
        self.Description:SetText(L["Use Escape Button Description2"]);
    end
end


--Themes
local function BorderThemeButton_OnClick(self, theme)
    NarciAPI.SetBorderTheme(theme);
    if theme == "Bright" then
        self:GetParent().Preview:SetTexCoord(0.5, 1, 0, 1);
        if Settings.BorderTheme ~= "Bright" then
            Settings.BorderTheme = "Bright";
        else
            return;
        end
    elseif theme == "Dark" then
        self:GetParent().Preview:SetTexCoord(0, 0.5, 0, 1);
        if Settings.BorderTheme ~= "Dark" then
            Settings.BorderTheme = "Dark";
        else
            return;
        end
    end
    Narci_SetActiveBorderTexture();
end

local function TooltipThemeButton_OnClick(self, theme)
    if theme == "Bright" then
        self:GetParent().Preview2:SetTexCoord(0, 1, 0.5, 1);
        if Settings.TooltipTheme ~= "Bright" or not self.isInitialized then
            self.isInitialized = true;
            Settings.TooltipTheme = "Bright";
        else
            return;
        end
        NarciTooltip:SetColorTheme(1);
    elseif theme == "Dark" then
        self:GetParent().Preview2:SetTexCoord(0, 1, 0, 0.5);
        if Settings.TooltipTheme ~= "Dark" or not self.isInitialized then
            self.isInitialized = true;
            Settings.TooltipTheme = "Dark";
        else
            return;
        end
        NarciTooltip:SetColorTheme(0);
    end
end


--Effects
local function VignetteStrengthSlider_OnValueChanged(self, value)
    value = floor( value * 10 + 0.5) / 10;
    Settings[self.dbKey] = value;
    self.KeyLabel:SetText(string.format("%.1f", value));
    Narci:UpdateVignetteStrength();
end

local function WeatherSwitch_SetState(self, state)
    if state then
        Narci_SnowEffect(true);
    else
        Narci_SnowEffect(false);
    end
end

function Narci_WeatherEffectSwitch_OnClick(self)
	Settings.WeatherEffect = not Settings.WeatherEffect;
    WeatherSwitch_SetState(self);
    if Settings.WeatherEffect then
        Narci_SnowEffect(true);
    else
        Narci_SnowEffect(false);
    end
end

local function LetterboxEffectSwitch_OnShow()
    if Settings.LetterboxEffect then
        Narci_LetterboxRatioSlider:Show();
        Narci_LetterboxRatioSlider:SetAlpha(1);
    else
        Narci_LetterboxRatioSlider:Hide();
    end
end

local function LetterboxEffectSwitch_SetState(self, state)
    if state then
        if Narci_LetterboxRatioSlider then
            FadeFrame(Narci_LetterboxRatioSlider, 0.25, 1, 0);
        end
        if self:IsVisible() then
            Narci_LetterboxAnimation();
        end
    else
        if Narci_LetterboxRatioSlider then
            Narci_LetterboxRatioSlider:SetShown(state);
        end
        if self:IsVisible() then
            Narci_LetterboxAnimation("OUT");
        end
        self.Description:Hide();
    end
    SetLetterboxEffectAlert();
end

local function LetterboxRatioSlider_OnValueChanged(self, value)
    local effectiveValue;
    if value > 2.34 then
        effectiveValue = 2.35;
    elseif value > 1.9 then
        effectiveValue = 2;
    else
        effectiveValue = 2.35;
    end

    Settings.LetterboxRatio = effectiveValue;
    self.KeyLabel:Hide();
    self.KeyLabel2:Show();
    self.KeyLabel2:SetText(effectiveValue.." : 1");
    
    SetLetterboxEffectAlert();
    if not Narci_ScreenMask_Initialize() then
        Narci_LetterboxToggle.Description:SetText(L["Letterbox Alert1"]);
        Narci_LetterboxToggle:Show();
    end
end

local function SmoothMusicVolume(state)
    local frame = Narci_MusicInOut;
    frame:Hide()
    frame.state = state;
    frame:Show()
end

local function FadeMusicSwitch_SetState(self, state)
    if self:IsVisible() then
        SmoothMusicVolume(state);
    end
end


--Camera
local function CameraTransitionSwitch_SetState(self, state)
    Narci.CameraMover:SetBlend(state);
    if state then
        self.Description:SetText(L["Camera Transition Description On"]);
    else
        self.Description:SetText(L["Camera Transition Description Off"]);
    end
end

local function CameraOrbitSwitch_SetState(self, state)
    if state then
        self.Description:SetText(L["Orbit Camera Description On"]);
    else
        self.Description:SetText(L["Orbit Camera Description Off"]);
    end

    if self:IsVisible() then
        if Settings.CameraOrbit then
            MoveViewRightStart(0.005*180/GetCVar("cameraYawMoveSpeed"));
        else
            MoveViewRightStop();
            MoveViewLeftStop();
        end
    end
end


local function CameraSafeSwitch_SetState(self, state)
    local state = Settings.CameraSafeMode;
    if IsAddOnLoaded("DynamicCam") then
        state = false;
    end
    Narci.keepActionCam = not state;
end

local function CameraSafeSwitch_OnShow(self)
    if IsAddOnLoaded("DynamicCam") then
        self.Description:SetText(L["Camera Safe Mode Description"].."\n".. L["Camera Safe Mode Description Extra"]);
        self.Tick:Hide();
        self:Disable();
    else
        self.Description:SetText(L["Camera Safe Mode Description"]);
    end
    self:SetScript("OnShow", nil);
end

local function BustShotSwitch_SetState(self, state)
    Narci:InitializeCameraFactors();
    if state then
        self:GetParent().Preview:SetTexCoord(0, 0.5, 0, 0.75);
    else
        self:GetParent().Preview:SetTexCoord(0.5, 1, 0, 0.75);
    end
end


--Transmog
local function LayoutButtonButton_SetState(self, id)
    if id == 1 then
        self:GetParent().Preview:SetTexCoord(0, 0.4443359375, 0, 0.5);
    elseif id == 2 then
        self:GetParent().Preview:SetTexCoord(0, 0.4443359375, 0.5, 1);
    elseif id == 3 then
        self:GetParent().Preview:SetTexCoord(0.5556640625, 1, 0, 0.5);
    end
end

local function AlwaysShowModelSwitch_SetState(self, state)
    local xmogButton = Narci_AlwaysShowModelButton;
    if xmogButton then
        xmogButton.IsOn = state;
        xmogButton.Tick:SetShown(state);
    end
end

local function EntranceVisualSwitch_SetState(self, state)
    Narci:SetUseEntranceVisual();
end


--Photo Mode
local function SceenshotQualitySlider_OnValueChanged(self, value, userInput)
    value = floor(value * 10 + 0.5) / 10;
    self.KeyLabel:SetText(value);
    if userInput then
        SetCVar("screenshotQuality", value);
    end
end

local function ModelPanelScaleSlider_OnValueChanged(self, value, userInput)
    value = floor(value * 10 + 0.5) / 10;
    self.KeyLabel:SetText(string.format("%.1f", value));
    Narci_ModelSettings:SetScale(value);
    Settings.ModelPanelScale = value;
end

local function InteractiveAreaSlider_OnLoad(self)
    local function OnValueChanged(self, value)
        self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)
        if value ~= self.oldValue then
            self.oldValue = value;
            value = floor(value);
            Narci:ShrinkModelHitRect(value);
            Settings.ShrinkArea = value;
            if value > 0 then
                value = -value;
            end
            self.KeyLabel:SetText(value);

            local frame = Narci_ModelInteractiveArea;
            frame.InOut:Stop();
            frame.InOut:Play();
            frame:Show();
        end
    end

    local W = floor( (WorldFrame:GetWidth()) *(1/3 - 1/8) + 0.5);
    self:SetMinMaxValues(0, W);
    self:SetValueStep(W/8);
    self.Label:SetText(L["Interactive Area"]);
    self:SetScript("OnValueChanged", OnValueChanged);
    NarciAPI_SliderWithSteps_OnLoad(self);
    self:SetValue(Settings.ShrinkArea);
    Narci_ModelInteractiveArea:Hide();
end


--Soulbinds & Conduits
local function ConduitTooltipSwitch_SetState(self, state)
    NarciAPI.EnableConduitTooltip(state);
end

local function PaperDollWidget_SetState(self, state)
    NarciPaperDollWidgetController:SetEnabled(state);
end


--Equipment UI Tooltip Style
local function ItemTooltipStyleStyleChanged(self, value)
    Narci:SetItemTooltipStyle(value);
end
local function ItemTooltipStyleButton_OnEnter(self)
    NarciEquipmentTooltip:HideTooltip();
    NarciGameTooltip:Hide();
    local link = "|Hitem:71086:6226:173127::::::60:577:::3:6660:7575:7696|r";   --77949
    if self.optionValue == 1 then
        --NarciEquipmentTooltip:SetFromSlotButton(self:GetParent().VirtualItemButton);
        NarciEquipmentTooltip:SetItemLinkAndAnchor(link, self:GetParent().VirtualItemButton)
    elseif self.optionValue == 2 then
        --NarciGameTooltip:SetFromSlotButton(self:GetParent().VirtualItemButton);
        NarciGameTooltip:SetItemLinkAndAnchor(link, self:GetParent().VirtualItemButton);
    end
end

local function ItemTooltipStyleButton_OnLeave(self)
    NarciEquipmentTooltip:HideTooltip();
    NarciGameTooltip:Hide();
end

local function ItemTooltipAdditionalInfo_SetState(self, state)
    Narci:ShowAdditionalInfoOnTooltip(state);
end


--Minimap Button Style
local MinimapTextureData = {
    [1] = {"Minimap\\LOGO-Cyan", "Narcissus"},
    [2] = {"Minimap\\LOGO-Thick", "AzeriteUI"},
    [3] = {"Preference\\MBT-Hollow", "SexyMap"},
};

NarciMinimapTextureOptionMixin = {};

function NarciMinimapTextureOptionMixin:OnLoad()
    self.styleID = self:GetID();
    if MinimapTextureData[self.styleID] then
        self.HighlightTexture:SetTexture("Interface\\AddOns\\Narcissus\\ART\\".. MinimapTextureData[self.styleID][1]);
        self.NormalTexture:SetTexture("Interface\\AddOns\\Narcissus\\ART\\".. MinimapTextureData[self.styleID][1]);
        self.ButtonName:SetText(MinimapTextureData[self.styleID][2]);
    else
        self.ButtonName:SetText("Unknown");
    end
    if self.styleID == 1 then
        self:SetSelection(true);
    end
end

function NarciMinimapTextureOptionMixin:OnEnter()
    self:StopAnimating();
    self.AnimIn:Play();
    self.AnimIn.Bounce1:SetDuration(0.2);
    self.AnimIn.Bounce2:SetDuration(0.2);
    self.AnimIn.Hold1:SetDuration(20);
    self.AnimIn.Hold2:SetDuration(20);
    --self.HighlightTexture:Show();
    FadeFrame(self.HighlightTexture, 0.2, 1);
    if not self.isSelected then
        self.ButtonName:SetTextColor(0.72, 0.72, 0.72);
    end
end

function NarciMinimapTextureOptionMixin:OnLeave()
    self.AnimIn.Bounce1:SetDuration(0);
    self.AnimIn.Bounce2:SetDuration(0);
    self.AnimIn.Hold1:SetDuration(0);
    self.AnimIn.Hold2:SetDuration(0);
    --self.HighlightTexture:Hide();
    FadeFrame(self.HighlightTexture, 0.2, 0);
    if self.isSelected then
        self.ButtonName:SetTextColor(0.72, 0.72, 0.72);
    else
        self.ButtonName:SetTextColor(0.42, 0.42, 0.42);
    end
end

function NarciMinimapTextureOptionMixin:OnClick()
    local buttons = self:GetParent().MinimapTextureOptions;
    for _, button in pairs(buttons) do
        button:SetSelection(false);
    end
    self:SetSelection(true);
    NarcissusDB.MinimapIconStyle = self.styleID;
    Narci_MinimapButton:SetBackground();
end

function NarciMinimapTextureOptionMixin:SetSelection(state)
    self.isSelected = state;
    if state then
        self.ButtonName:SetTextColor(0.72, 0.72, 0.72);
        local Tick = self:GetParent().Tick;
        Tick:ClearAllPoints();
        Tick:SetPoint("TOP", self, "BOTTOM", 0, -12);
        Tick:Show();
    else
        self.ButtonName:SetTextColor(0.42, 0.42, 0.42);
    end
end

function NarciMinimapTextureOptionMixin:Init()
    self:SetSelection(self.styleID and self.styleID == NarcissusDB.MinimapIconStyle);
    self:SetScript("OnShow", nil);
end

local Structure = {
    {Category = "Interface", localizedName = L["Interface"], layout = {
        { name = "UIScale", type = "header", localizedName = UI_SCALE, },
        { name = "GlobalScale", type = "slider", localizedName = ALL, minValue = 0.7, maxValue = 1, valueStep = 0.1, valueFunc = GlobalScaleSlider_OnValueChanged},
        { name = "ItemNames", type = "header", localizedName = ITEM_NAMES, },
        { name = "FontHeightItemName", type = "slider", localizedName = FONT_SIZE, minValue = 10, maxValue = 12, valueStep = 1, valueFunc = SetItemNameTextSize},
        { name = "ItemNameWidth", type = "slider", localizedName = L["Text Width"], minValue = 100, maxValue = 200, valueStep = 20, valueFunc = ItemNameWidthSlider_OnValueChanged},
        { name = "TruncateText", type = "checkbox", localizedName = L["Truncate Text"], valueFunc = SetItemNameTextTruncated},
        { name = "StatSheet", type = "header", localizedName = L["Stat Sheet"], },
        { name = "DetailedIlvlInfo", type = "checkbox", localizedName = L["Show Detailed Stats"], valueFunc = ShowDetailedIlvlInfo},
    }},

    {Category = "Shortcuts", localizedName = L["Shortcuts"], layout = {
        { name = "MinimapButton", type = "header", localizedName = L["Minimap Button"], },
        { name = "ShowMinimapButton", type = "checkbox", localizedName = ENABLE, valueFunc = MinimapButtonSwitch_SetState, onShowFunc = MinimapButtonSwitch_OnShow, parentButton = true, },
        { name = "ShowModulePanelOnMouseOver", type = "checkbox", localizedName = L["Show Module Panel Gesture"], valueFunc = ModulePanelSwitch_SetState, childButton = true,},
        { name = "IndependentMinimapButton", type = "checkbox", localizedName = L["Independent Minimap Button"], valueFunc = MinimapButtonParentSwitch_SetState, childButton = true, },
        { name = "FadeButton", type = "checkbox", localizedName = L["Fade Out"], description = L["Fade Out Description"], valueFunc = FadeOutSwitch_SetState, childButton = true, },
        { name = "Space", type = "space", height = -16},
        { name = "HotkeyHeader", type = "header", localizedName = L["Hotkey"], },
        { name = "EnableDoubleTap", type = "checkbox", localizedName = L["Double Tap"], description = L["Double Tap Description"], onShowFunc = DoubleTapSwitch_OnShow},
        { name = "HotkeyButton", type = "keybinding", localizedName = KEY_BINDING, externalAction = BIND_ACTION},
        { name = "UseEscapeButton", type = "checkbox", localizedName = L["Use Escape Button"], description = L["Use Escape Button Description1"], valueFunc = SetUseEcapeButtonForExit},
    }},

    {Category = "ItemTooltip", localizedName = L["Item Tooltip"], layout = {
        { name = "Style", type = "header", localizedName = L["Style"], },
        { name = "ItemTooltipStyle", type = "radio", localizedName = L["Tooltip Style 1"], valueFunc = ItemTooltipStyleStyleChanged, optionValue = 1, groupIndex = 1, onEnterFunc = ItemTooltipStyleButton_OnEnter, onLeaveFunc = ItemTooltipStyleButton_OnLeave},
        { name = "ItemTooltipStyle", type = "radio", localizedName = L["Tooltip Style 2"], valueFunc = ItemTooltipStyleStyleChanged, optionValue = 2, groupIndex = 1, onEnterFunc = ItemTooltipStyleButton_OnEnter, onLeaveFunc = ItemTooltipStyleButton_OnLeave},
        { name = "AdditionalInfo", type = "header", localizedName = L["Addtional Info"], },
        { name = "ShowItemID", type = "checkbox", localizedName = L["Item ID"], valueFunc = ItemTooltipAdditionalInfo_SetState},
    }},

    {Category = "Themes", localizedName = L["Themes"], layout = {
        --{ name = "BorderThemeHeader", type = "header", localizedName = L["Border Theme Header"], },
        --{ name = "BorderTheme", type = "radio", localizedName = L["Border Theme Bright"], valueFunc = BorderThemeButton_OnClick, optionValue = "Bright", groupIndex = 1 },
        --{ name = "BorderTheme", type = "radio", localizedName = L["Border Theme Dark"], valueFunc = BorderThemeButton_OnClick, optionValue = "Dark", groupIndex = 1 },
        --{ name = "Space", type = "space", height = 64},
        { name = "BorderThemeHeader", type = "header", localizedName = L["Minimap Button"], },
        { name = "Space", type = "space", height = 108},
        { name = "TooltipThemeHeader", type = "header", localizedName = L["Tooltip Color"], },
        { name = "TooltipTheme", type = "radio", localizedName = L["Border Theme Bright"], valueFunc = TooltipThemeButton_OnClick, optionValue = "Bright", groupIndex = 2 },
        { name = "TooltipTheme", type = "radio", localizedName = L["Border Theme Dark"], valueFunc = TooltipThemeButton_OnClick, optionValue = "Dark", groupIndex = 2 },
    }},

    {Category = "Effects", localizedName = L["Effects"], layout = {
        { name = "FilterHeader", type = "header", localizedName = L["Image Filter"], },
        { name = "VignetteStrength", type = "slider", localizedName = L["Vignette Strength"], minValue = 0, maxValue = 1, valueStep = 0.1, valueFunc = VignetteStrengthSlider_OnValueChanged },
        { name = "FilterDescription", type = "subheader", localizedName = L["Image Filter Description"], },
        { name = "WeatherEffect", type = "checkbox", localizedName = L["Weather Effect"], valueFunc = WeatherSwitch_SetState },
        { name = "LetterboxEffect", type = "checkbox", localizedName = L["Letterbox"], description = " ", globalName = "Narci_LetterboxToggle", valueFunc = LetterboxEffectSwitch_SetState, onShowFunc = LetterboxEffectSwitch_OnShow },
        { name = "LetterboxRatio", type = "slider", localizedName = L["Letterbox Ratio"], globalName = "Narci_LetterboxRatioSlider", offsetX = 80, offsetY = 40, width = 40, minValue = 2.0, maxValue = 2.350, valueStep = 2, valueFunc = LetterboxRatioSlider_OnValueChanged },
        { name = "SoundHeader", type = "header", localizedName = SOUND },
        { name = "FadeMusic", type = "checkbox", localizedName = L["Fade Music"], valueFunc = FadeMusicSwitch_SetState },
    }},

    {Category = "Camera", localizedName = L["Camera"], layout = {
        { name = "CameraMovementHeader", type = "header", localizedName = L["Camera Movement"], },
        { name = "CameraTransition", type = "checkbox", localizedName = L["Camera Transition"], description = L["Camera Transition Description Off"], valueFunc = CameraTransitionSwitch_SetState },
        { name = "CameraOrbit", type = "checkbox", localizedName = L["Orbit Camera"], description = L["Orbit Camera Description On"], valueFunc = CameraOrbitSwitch_SetState },
        { name = "CameraSafeMode", type = "checkbox", localizedName = L["Camera Safe Mode"], description = "\n\n", valueFunc = CameraSafeSwitch_SetState, onShowFunc = CameraSafeSwitch_OnShow, },
        { name = "UseBustShot", type = "checkbox", localizedName = L["Use Bust Shot"], valueFunc = BustShotSwitch_SetState },
    }},

    {Category = "Transmog", localizedName = L["Transmog"], layout = {
        { name = "CameraMovementHeader", type = "header", localizedName = L["Default Layout"], },
        { name = "DefaultLayout", type = "radio", localizedName = L["Transmog Layout1"], valueFunc = LayoutButtonButton_SetState, optionValue = 1, groupIndex = 1 },
        { name = "DefaultLayout", type = "radio", localizedName = L["Transmog Layout2"], valueFunc = LayoutButtonButton_SetState, optionValue = 2, groupIndex = 1 },
        { name = "DefaultLayout", type = "radio", localizedName = L["Transmog Layout3"], valueFunc = LayoutButtonButton_SetState, optionValue = 3, groupIndex = 1 },
        { name = "ModelHeader", type = "header", localizedName = L["3D Model"], },
        { name = "AlwaysShowModel", type = "checkbox", localizedName = L["Always Show Model"], globalName = "Narci_AlwaysShowModelToggle", valueFunc = AlwaysShowModelSwitch_SetState },
        { name = "UseEntranceVisual", type = "checkbox", localizedName = L["Entrance Visual"], description = L["Entrance Visual Description"], valueFunc = EntranceVisualSwitch_SetState },
    }},

    {Category = "PhotoMode", localizedName = L["Photo Mode"], layout = {
        { name = "CameraMovementHeader", type = "header", localizedName = L["General"], },
        { name = "screenshotQuality", type = "slider", localizedName = L["Sceenshot Quality"], isCVar = true, minValue = 1, maxValue = 10, valueStep = 1, valueFunc = SceenshotQualitySlider_OnValueChanged },
        { name = "QualityDescription", type = "subheader", localizedName = L["Screenshot Quality Description"], },
        { name = "Space", type = "space", height = 32},
        { name = "ModelPanelScale", type = "slider", localizedName = L["Panel Scale"], minValue = 0.8, maxValue = 1, valueStep = 0.10, valueFunc = ModelPanelScaleSlider_OnValueChanged },
        { name = "ShrinkArea", type = "slider", localizedName = L["Interactive Area"], onLoadFunc = InteractiveAreaSlider_OnLoad },
    }},

    {Category = "Soulbinds", localizedName = EXPANSION_NAME8, layout = {
        { name = "BlizzardUI", type = "header", localizedName = L["Blizzard UI"], },
        { name = "ConduitTooltip", type = "checkbox", localizedName = L["Conduit Tooltip"], valueFunc = ConduitTooltipSwitch_SetState},
        { name = "Space", type = "space", height = 96},
        { name = "PaperDollWidget", type = "checkbox", localizedName = NARCI_NEW_ENTRY_PREFIX..L["Paperdoll Widget"], valueFunc = PaperDollWidget_SetState},
    }},
};

local function CreateSettingFrame(tabContainer)
    local PADDING_LEFT = 16;
    local PADDING_CHECKBOX = 34;
    local PADDING_SLIDER = 112;
    for i = 1, #Structure do
        local tab = tabContainer["Tab"..i];
        if not tab then return end;

        local category = Structure[i];
        local layout = category.layout;
        local tabHeight = 0;
        local parentButton;
        for j = 1, #layout do
            local data = layout[j];
            local type = data.type;
            local widget;
            --print(data.name)
            local globalName = data.globalName;
            if type == "header" then
                tabHeight = tabHeight + 16;
                widget = tab:CreateFontString(globalName, "OVERLAY", "NarciPrefFontGrey9");
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_LEFT, -tabHeight);
                widget:SetText(data.localizedName);
                tabHeight = tabHeight + 24;

            elseif type == "subheader" then
                widget = tab:CreateFontString(globalName, "OVERLAY", "NarciPrefFontGreyThin9");
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_CHECKBOX, -tabHeight);
                widget:SetText(data.localizedName);
                widget:SetWidth(280);
                tabHeight = tabHeight + 24;

            elseif type == "slider" then
                widget = CreateFrame("Slider", globalName, tab, "NarciPreferenceHorizontalSliderTemplate");
                local offsetY = (data.offsetY or 0);
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_SLIDER + (data.offsetX or 0), -tabHeight + offsetY);
                if data.width then
                    widget:SetWidth(data.width);
                end
                if data.onLoadFunc then
                    data.onLoadFunc(widget);
                else
                    widget:SetUp(data.localizedName, data.minValue, data.maxValue, data.valueStep, data.name, data.valueFunc, data.isCVar);
                end
                tabHeight = tabHeight + 36 - offsetY;

            elseif type == "checkbox" then
                widget = CreateFrame("Button", globalName, tab, "NarciPreferenceCheckBoxTemplate");
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_CHECKBOX, -tabHeight);
                if data.parentButton then
                    parentButton = widget;
                    widget.childButtons = {};
                elseif data.childButton then
                    widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_CHECKBOX + 18, -tabHeight);
                    if parentButton then
                        tinsert(parentButton.childButtons, widget);
                    end
                end
                if data.onShowFunc then
                    widget:SetScript("OnShow", data.onShowFunc);
                end
                local extraHeight = widget:SetUp(data.localizedName, data.description, data.name, data.valueFunc);
                tabHeight = tabHeight + extraHeight + 24;

            elseif type == "radio" then
                widget = CreateFrame("Button", globalName, tab, "NarciPreferenceRadioButtonTemplate");
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", PADDING_CHECKBOX, -tabHeight);
                local extraHeight = widget:SetUp(data.localizedName, data.description, data.name, data.optionValue, data.valueFunc, data.groupIndex, data.onEnterFunc, data.onLeaveFunc);
                tabHeight = tabHeight + extraHeight + 24;

            elseif type == "keybinding" then
                widget = CreateFrame("Button", globalName, tab, "NarciBindingButtonTemplate");
                tabHeight = tabHeight + 6;
                widget:SetPoint("TOPLEFT", tab, "TOPLEFT", 168, -tabHeight);
                widget.Label:SetText(data.localizedName);
                if data.externalAction then
                    widget:SetBindingActionExternal(data.externalAction);
                elseif data.internalAction then
                    widget:SetBindingActionInternal(data.internalAction);
                end
                tabHeight = tabHeight + 36;

            elseif type == "space" then
                tabHeight = tabHeight + (data.height or 0);
            end
        end
    end

    Structure = nil;
end



--GetBindingText("U", "KEY_")
--command name = GetBindingAction("U")
--GetBindingName(GetBindingAction("U"))


NarciPreferenceSliderMixin = {};


function NarciPreferenceSliderMixin:SetUp(labelText, minValue, maxValue, valueStep, dbKey, valueFunc, isCVar)
    self.Label:SetText(labelText);
    self.valueFunc = valueFunc;
    self.dbKey = dbKey;
    if minValue and maxValue and valueStep then
        self:SetMinMaxValues(minValue, maxValue);
        self:SetValueStep(valueStep);
        NarciAPI_SliderWithSteps_OnLoad(self);  --Draw Markers
        --OptimizeBorderThickness(self);
    end
    if valueFunc then
        if isCVar then
            self:SetValue(GetCVar(dbKey) or 0);
            self:SetScript("OnShow", function()
                self:SetValue(GetCVar(dbKey) or 0);
            end)
        else
            self:SetValue(Settings[dbKey]);
        end
    end
end

function NarciPreferenceSliderMixin:OnValueChanged(value, userInput)
    self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0);
    if value ~= self.oldValue then
        self.oldValue = value;
        if self.valueFunc then
            --Change setting value in this function
            self.valueFunc(self, value, userInput);
        end
    end
end

NarciPreferenceCheckBoxMixin = {};

function NarciPreferenceCheckBoxMixin:SetUp(labelText, description, dbKey, valueFunc, onEnterFunc, onLeaveFunc)
    self.Label:SetText(labelText);
    self.valueFunc = valueFunc;
    self.dbKey = dbKey;
    local state =  Settings[dbKey];
    self.Tick:SetShown(state);
    local textWidth = math.max(floor(self.Label:GetWidth() + 0.5) + 16, 80);
    local textHeight = floor(self.Label:GetHeight() + 0.5);
    self:SetSize(textWidth, textHeight);

    local extraHeight = 0;
    if description then
        self.Description = self:CreateFontString(nil, "OVERLAY", "NarciPreferenceDescriptionTemplate");
        self.Description:SetText(description);
        extraHeight = extraHeight + self.Description:GetHeight() + 8;
    end
    if valueFunc then
        valueFunc(self, state);
    end
    if onEnterFunc then
        self:SetScript("OnEnter", onEnterFunc);
    end
    if onLeaveFunc then
        self:SetScript("OnLeave", onLeaveFunc);
    end
    return extraHeight
end

function NarciPreferenceCheckBoxMixin:OnClick()
    local state = not Settings[self.dbKey];
    Settings[self.dbKey] = state;
    self.Tick:SetShown(state);
    if self.valueFunc then
        self.valueFunc(self, state);
    end
end

NarciPreferenceRadioButtonMixin = {};

function NarciPreferenceRadioButtonMixin:SetUp(labelText, description, dbKey, optionValue, valueFunc, groupIndex, onEnterFunc, onLeaveFunc)
    self.Label:SetText(labelText);
    self.valueFunc = valueFunc;
    self.dbKey = dbKey;
    self.optionValue = optionValue;
    local textWidth = math.max(floor(self.Label:GetWidth() + 0.5) + 16, 80);
    local textHeight = floor(self.Label:GetHeight() + 0.5);
    self:SetSize(textWidth, textHeight);

    if groupIndex then
        self.groupIndex = groupIndex;
        local parent = self:GetParent();
        if not parent.buttonGroups then
            parent.buttonGroups = {};
        end
        if not parent.buttonGroups[groupIndex] then
            parent.buttonGroups[groupIndex] = {};
        end
        tinsert(parent.buttonGroups[groupIndex], self);
    end

    local extraHeight = textHeight - 14;
    if description then
        self.Description = self:CreateFontString(nil, "OVERLAY", "NarciPreferenceDescriptionTemplate");
        self.Description:SetText(description);
        extraHeight = extraHeight + self.Description:GetHeight();
    end

    if valueFunc then
        if optionValue == Settings[dbKey] then
            self:Click();
        end
    end

    if onEnterFunc then
        self:SetScript("OnEnter", onEnterFunc);
    end

    if onLeaveFunc then
        self:SetScript("OnLeave", onLeaveFunc);
    end

    return extraHeight
end

function NarciPreferenceRadioButtonMixin:OnClick()
    if self.valueFunc then
        self.valueFunc(self, self.optionValue);
    end
    Settings[self.dbKey] = self.optionValue;
    local buttonGroup = self:GetParent().buttonGroups[self.groupIndex];
    for i = 1, #buttonGroup do
        buttonGroup[i].Tick:Hide();
    end
    self.Tick:Show();
end



local function UnToggleElvUIAFK()
    local E, L, V, P, G = unpack(ElvUI);
    E.db.general.afk = false;
    --local AFK = E:GetModule('AFK')
    --AFK:Toggle()
end

local function AFKScreenSwitch_SetState(self)
    local state = Settings.AFKScreen;
    self.Tick:SetShown(state);
    if state then
        if IsAddOnLoaded("ElvUI") then
            self.Description:SetText(L["AFK Screen Description"].." "..L["AFK Screen Description Extra"]);
            UnToggleElvUIAFK();
        else
            self.Description:SetText(L["AFK Screen Description"]);
        end

        FadeFrame(self:GetParent().AutoStand, 0.25, 1, 0);
        self:GetParent().Gemma:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -90);
    else
        self.Description:SetText(L["AFK Screen Description"]);

        self:GetParent().AutoStand:Hide();
        self:GetParent().Gemma:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -50);
    end
end

function Narci_AFKScreenSwitch_OnClick(self)
    Settings.AFKScreen = not Settings.AFKScreen;
    AFKScreenSwitch_SetState(self);
end

local function AFKAutoStand_SetState(self)
    self.Tick:SetShown(Settings.AFKAutoStand);
end

function Narci_AFKAutoStand_OnClick(self)
    Settings.AFKAutoStand = not Settings.AFKAutoStand;
    AFKAutoStand_SetState(self);
end

local function GemManagerSwitch_SetState(self)
    local state = Settings.GemManager;
    self.Tick:SetShown(state);
end

function Narci_GemManagerSwitch_OnClick(self)
    Settings.GemManager = not Settings.GemManager;
    GemManagerSwitch_SetState(self);
end

local function DressingRoomSwitch_SetState(self)
    local state = Settings.DressingRoom;
    self.Tick:SetShown(state);
end

function Narci_DressingRoomSwitch_OnClick(self)
    Settings.DressingRoom = not Settings.DressingRoom;
    DressingRoomSwitch_SetState(self);
    self.Description:SetText(L["Dressing Room Description"].."\n"..NARCI_REQUIRE_RELOAD);
end

local function RestoreClickFunc()
    local button = Narci_MinimapButton;
    button:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp");
    button:RegisterForDrag("LeftButton");
    button:SetScript("OnClick", Narci_MinimapButton_OnClick)
    button:SetScript("OnDragStart", function()  Narci_MinimapButton_DraggingFrame:Show();   end)
    button:SetScript("OnDragStop", function()   Narci_MinimapButton_DraggingFrame:Hide();   end)
    button:SetFrameStrata("MEDIUM");
    button:SetFrameLevel(61);
    button:SetMovable(true);
    button:EnableMouse(true);
end


local function LoadOnDemandSwitch_SetState(self)
    if self:IsEnabled() then
        local state = CreatureSettings.LoadOnDemand;
        if state then
            self.Description:SetText(self.enabledText);
        else
            self.Description:SetText(self.disabledText);
        end
        self.Tick:SetShown(state);
    else
        self.Description:SetText(self.lockedText);
        self.Tick:SetShown(false);
    end
end

local function LoadOnDemandSwitch_OnClick(self)
    CreatureSettings.LoadOnDemand = not CreatureSettings.LoadOnDemand;
    LoadOnDemandSwitch_SetState(self)
end

local function LoadOnDemandSwitch_OnLoad(self)
    self.Label:SetText(L["Load on Demand"]);
    self.lockedText = L["Load on Demand Description Disabled"];
    self.enabledText = L["Load on Demand Description On"];
    self.disabledText = L["Load on Demand Description Off"];

    self:SetScript("OnDisable", LoadOnDemandSwitch_SetState);
    self:SetScript("OnEnable", LoadOnDemandSwitch_SetState);
    self:SetScript("OnClick", LoadOnDemandSwitch_OnClick);
    LoadOnDemandSwitch_SetState(self);
end

local function LockDatabaseToggle()
    Narci_LoadOnDemandSwitch:SetEnabled(not ( CreatureSettings.SearchRelatives or CreatureSettings.TranslateName ));
end

local function IsCreatureDatabaseLoaded(needReload, language)
    language = language or "enUS";
    if NarciCreatureInfo and NarciCreatureInfo.isLanguageLoaded[language] then
        return true
    else
        if needReload then
            Narci_LoadOnDemandNotes:Show();
        end
        return false
    end
end

local function TranslatorSwitch_SetState(self)
    local state = CreatureSettings.TranslateName;
    self.Tick:SetShown(state);

    if state then
        FadeFrame(CreatureTab.OnTooltip, 0.25, 1, 0);
        FadeFrame(CreatureTab.OnNamePlate, 0.25, 1, 0);
        FadeFrame(CreatureTab.SelectLanguage, 0.25, 1, 0);
        self.Description:SetText(self.enabledText);
    else
        CreatureTab.OnTooltip:Hide();
        CreatureTab.OnNamePlate:Hide();
        CreatureTab.SelectLanguage:Hide();
        self.Description:SetText(self.disabledText);
        if NarciCreatureInfo then
            NarciCreatureInfo.ShowNarciUnitFrames(false);
        end
    end

    CreatureTab.Jaina:SetShown(state);
    CreatureTab.Preview:SetShown(state);

    LockDatabaseToggle();
end

local function IsRequiredLangugesLoaded()
    local useNamePlate = CreatureSettings.ShowTranslatedNameOnNamePlate;
    local allLoaded = true;

    if useNamePlate then
        local language = CreatureSettings.NamePlateLanguage;
        allLoaded = IsCreatureDatabaseLoaded(true, language);
    else
        local Languages = CreatureSettings.Languages;
        for language, state in pairs(Languages) do
            if state then
                allLoaded = allLoaded and IsCreatureDatabaseLoaded(true, language);
            end
        end
    end

    return allLoaded
end

function Narci_TranslatorSwitch_OnClick(self)
    CreatureSettings.TranslateName = not CreatureSettings.TranslateName;
    TranslatorSwitch_SetState(self);

    if IsCreatureDatabaseLoaded(CreatureSettings.TranslateName, textLanguage) then
        if not CreatureSettings.TranslateName then
            NarciCreatureInfo.DiasbleTranslator();
        else
            NarciCreatureInfo.UpdateEnabledLanguages();
        end
    end

    IsRequiredLangugesLoaded();
end

function Narci_SelectLanguage_OnClick(self)
    FadeFrame(CreatureTab.LanguageOptions, 0.25, 1, 0);
end

local function FindRelativesSwitch_SetState(self)
    local state = CreatureSettings.SearchRelatives;
    self.Tick:SetShown(state);
    self.KeyBinding:SetShown(state);
    LockDatabaseToggle();
end

function Narci_FindRelativesSwitch_OnClick(self)
    CreatureSettings.SearchRelatives = not CreatureSettings.SearchRelatives;
    local state = CreatureSettings.SearchRelatives;
    LockDatabaseToggle();
    self.Tick:SetShown(state);
    if state then
        FadeFrame(self.KeyBinding, 0.25, 1, 0);
    else
        self.KeyBinding:Hide();
    end
    if IsCreatureDatabaseLoaded(state, "enUS") then
        NarciCreatureInfo.SetIsCreatureTooltipEnabled();
    end
end

local UpdateLanguageOptionButtons;    --function

local function UpdateSelectedLanguage()
    local button = CreatureTab.SelectLanguage;
    local enabledLanguages;
    local numEnabled = 0;

    local useNamePlate = CreatureSettings.ShowTranslatedNameOnNamePlate;
    if useNamePlate then
        enabledLanguages = CreatureSettings.NamePlateLanguage;
        if enabledLanguages then
            numEnabled = 1;
        end
    else
        local Languages = CreatureSettings.Languages;
        local SortedLanguages = {};
        for language, state in pairs(Languages) do
            if state then
                numEnabled = numEnabled + 1;
                tinsert(SortedLanguages, language)
            end
        end
        
        table.sort(SortedLanguages, function(a, b) return a < b end);

        for _, language in pairs(SortedLanguages) do
            if enabledLanguages then
                enabledLanguages = enabledLanguages..", "..language;
            else
                enabledLanguages = language;
            end
        end
    end

    if numEnabled == 0 then
        button.Description:SetText(button.singular);
        enabledLanguages = COLOR_BAD.. "None";
    elseif numEnabled == 1 then
        button.Description:SetText(button.singular);
    else
        button.Description:SetText(button.plural);
    end

    button.Label:SetText(enabledLanguages);

    
    --Preview
    local Preview = button:GetParent().Preview;
    local relativeTo = button:GetParent().Jaina;
    if useNamePlate then
        Preview:SetTexCoord(0, 0.5, 0.5, 1);
        Preview:SetPoint("CENTER", relativeTo, "CENTER", 4, 94);
    else
        Preview:SetTexCoord(0, 0.5, 0, 0.5);
        Preview:SetPoint("CENTER", relativeTo, "CENTER", 4, -10);
    end
end

local function TranslationPositionButton_SetState()
    local useNamePlate = CreatureSettings.ShowTranslatedNameOnNamePlate;
    CreatureTab.OnTooltip.Tick:SetShown(not useNamePlate);
    CreatureTab.OnNamePlate.Tick:SetShown(useNamePlate);
    CreatureTab.OnNamePlate.OffsetSetting:SetShown(useNamePlate);
end

function Narci_TranslationPositionButton_OnClick(self)
    self:GetParent().OnTooltip.Tick:Hide();
    self:GetParent().OnNamePlate.Tick:Hide();
    self.Tick:Show();

    local id = self:GetID();
    local useNamePlate = (id == 2)
    
    CreatureSettings.ShowTranslatedNameOnNamePlate = useNamePlate;
    if useNamePlate then
        FadeFrame(self.OffsetSetting, 0.25, 1, 0);
    else
        self:GetParent().OnNamePlate.OffsetSetting:Hide();
    end


    if IsRequiredLangugesLoaded() then
        NarciCreatureInfo.UpdateEnabledLanguages();
    end

    UpdateSelectedLanguage();
    UpdateLanguageOptionButtons();
end


-------------------------------------------------------------
----------------Preference scrollBar Animation---------------
-------------------------------------------------------------
local function BuildTabNames()
    --For Ultra Wide Monitor--
    local ScreenRatio, maxOffset;
    local W0, H = WorldFrame:GetSize();
    --W0 = 1792
    if (W0 and H) and H ~= 0 and (W0 / H) > (16.01 / 9) then     --No resizing option on 16:9 or lower
        local W = H / 9 * 16;
        maxOffset = floor( (W0 - W)/2 + 0.5);
        tinsert(TabNames, L["Ultra-wide"]);
        ScreenRatio = floor((W0 / H) * 9 + 0.25);
    end
    tinsert(TabNames, L["Credits"]);
    tinsert(TabNames, L["About"]);

    return ScreenRatio, maxOffset;
end

--/run local W, H = WorldFrame:GetSize(); print(floor((W / H) * 9 + 0.25)..":9")
local ScreenRatio, MaxOffset = BuildTabNames();
local TotalTab = #TabNames;
local TabHeight = 1;
local TotalHeight = 0;
local MaxScroll = 0;
local floor = floor;
local SelectedColorAlpha = 0.6;
local currentTab = 1;
local function UpdateTabBackgroundColor(self)
    local buttons = Narci_Preference.TabButtonFrame.buttons;
    local scrollBarValue = self:GetValue();
    local currentValue = TotalTab - (TotalHeight - scrollBarValue)/TabHeight + 1;
    currentTab = floor(currentValue + 0.5)
    --print(currentTab);
    if buttons[currentTab] then
        buttons[currentTab].SelectedColor:SetAlpha(SelectedColorAlpha);
    end

    if currentValue >= currentTab then
        if buttons[currentTab + 1] then
            buttons[currentTab + 1].SelectedColor:SetAlpha(2*SelectedColorAlpha*(currentValue - currentTab));
        end
        if buttons[currentTab - 1] then
            buttons[currentTab - 1].SelectedColor:SetAlpha(0);
        end
    elseif currentValue < currentTab then
        if buttons[currentTab - 1] then
            buttons[currentTab - 1].SelectedColor:SetAlpha(2*SelectedColorAlpha*(currentTab - currentValue));
        end
        if buttons[currentTab + 1] then
            buttons[currentTab + 1].SelectedColor:SetAlpha(0);
        end
    end       

    --Play heart animation for credit list
    if currentTab == (TotalTab - 1) then
        Narci_CreditList.Timer:Play();
    end
end

local function ScrollBar_OnValueChanged(self, value)
    self:GetParent():SetVerticalScroll(value)
    UpdateTabBackgroundColor(self)
end

function Narci_Preference_ScrollFrame_OnLoad(self)
    TabHeight = self:GetHeight();
    TotalHeight = floor(TotalTab * TabHeight + 0.5);
    MaxScroll = floor((TotalTab - 1) * TabHeight + 0.5);

    --NarciAPI_SmoothScroll_Initialization(self, nil, nil, 1, 0.2);
    NarciAPI_ApplySmoothScrollToScrollFrame(self, 1, 0.2, nil, TabHeight, MaxScroll);
    self.scrollBar:SetScript("OnValueChanged", ScrollBar_OnValueChanged);
end

local function TabButton_OnClick(self)
    MainFrame:ScrollToTab(self:GetID());
    local buttons = self:GetParent().buttons;
    for i=1, #buttons do
        buttons[i].SelectedColor:SetAlpha(0);
    end
    self.SelectedColor:SetAlpha(SelectedColorAlpha);
end

local function BuildTabButtonList(self, buttonTemplate, buttonNameTable, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
	local button, buttonHeight, buttons, numButtons;

	local parentName = self:GetName();
	local buttonName = parentName and (parentName .. "Button") or nil;

	initialPoint = initialPoint or "TOPLEFT";
    initialRelative = initialRelative or "TOPLEFT";
    initialOffsetX = initialOffsetX or 0;
    initialOffsetY = initialOffsetY or 0;
	point = point or "TOPLEFT";
	relativePoint = relativePoint or "BOTTOMLEFT";
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;

	if ( self.buttons ) then
		buttons = self.buttons;
		buttonHeight = buttons[1]:GetHeight();
	else
        button = CreateFrame("BUTTON", buttonName and (buttonName .. 1) or nil, self, buttonTemplate);
        button:SetScript("OnClick", TabButton_OnClick);
		buttonHeight = button:GetHeight();
        button:SetPoint(initialPoint, self, initialRelative, initialOffsetX, initialOffsetY);
        button:SetID(0);
        buttons = {}
        button.Name:SetText(buttonNameTable[1])
		tinsert(buttons, button);
	end

	local numButtons = #buttonNameTable;

	for i = 2, numButtons do
        button = CreateFrame("BUTTON", buttonName and (buttonName .. i) or nil, self, buttonTemplate);
        button:SetScript("OnClick", TabButton_OnClick);
        button:SetID(i-1);
        button.Name:SetText(buttonNameTable[i])
        if i == numButtons then         --About Tab
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", initialOffsetX, -initialOffsetY);
        elseif i == numButtons - 1 then --Credit Tab
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", initialOffsetX, -initialOffsetY + buttonHeight);
            button.HighlightColor:SetColorTexture(0.6666, 0, 0.549);
            button.SelectedColor:SetColorTexture(0.6666, 0, 0.549);
        else                            --Regular Tab
            button:SetPoint(point, buttons[i-1], relativePoint, offsetX, offsetY);
        end
		tinsert(buttons, button);
	end

    self.buttons = buttons;
    buttons[1]:Click();

    wipe(buttonNameTable);  --Reclaim space
end

local function LanguageOption_OnClick(self)
    local language = self.keyValue;
    local state;

    if self:GetParent().singleChoice then
        if language == CreatureSettings.NamePlateLanguage then
            CreatureSettings.NamePlateLanguage = nil;
            state = false;
        else
            CreatureSettings.NamePlateLanguage = language;
            state = true;
        end
        UpdateLanguageOptionButtons();
    else
        CreatureSettings.Languages[language] = not CreatureSettings.Languages[language];
        state = CreatureSettings.Languages[language];   
        self.Tick:SetShown(state);
    end

    if IsCreatureDatabaseLoaded(state, language) then
        NarciCreatureInfo.EnableLanguage(language, state);
    end

    UpdateSelectedLanguage();
end

local function CreateLanguageOptions(parent, anchor)
    local MAX_ROW = 6;
    local OFFSET_START = 22.5; --22.5
    local OFFSET_X = 150; --170
    local OFFSET_Y = 16;
    local LANGUAGES = {
        {"enUS", LFG_LIST_LANGUAGE_ENUS},
        {"frFR", LFG_LIST_LANGUAGE_FRFR},
        {"deDE", LFG_LIST_LANGUAGE_DEDE},
        {"itIT", LFG_LIST_LANGUAGE_ITIT},
        {"koKR", LFG_LIST_LANGUAGE_KOKR},
        {"ptBR", LFG_LIST_LANGUAGE_PTBR},
        {"ruRU", LFG_LIST_LANGUAGE_RURU},
        {"esES", ESES},
        {"esMX", ESMX},
        {"zhCN", ZHCN},
        {"zhTW", ZHTW},
    };

    local button;
    local buttons = {};
    local numButton = 0;
    local numRow = 0;
    local numColumn = 0;

    local LanguageOptions = CreateFrame("Frame", "Narci_LanguageOptions", parent, "NarciFrameTemplate");
    parent.LanguageOptions = LanguageOptions;
    LanguageOptions:SetSize(64, 64);
    LanguageOptions:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0);
    LanguageOptions:SetHeaderText("Language");
    LanguageOptions:SetRelativeFrameLevel(3);
    LanguageOptions:HideWhenParentIsHidden(true);

    local languageInfo;
    for i = 1, #LANGUAGES do
        button = CreateFrame("Button", nil, LanguageOptions, "NarciCheckBoxTemplate");
        numButton = numButton + 1;
        tinsert(buttons, button);
        if numButton == 1 then
            numRow = numRow + 1;
            numColumn = numColumn + 1;
            button:SetPoint("TOPLEFT", LanguageOptions, "TOPLEFT", OFFSET_START, -18);
        elseif numButton % MAX_ROW == 1 then
            button:SetPoint("LEFT", buttons[numButton - MAX_ROW], "LEFT", OFFSET_X, 0);
        else
            button:SetPoint("TOP", buttons[numButton - 1], "BOTTOM", 0, - OFFSET_Y);
        end
        
        languageInfo = LANGUAGES[i];
        button.keyValue = languageInfo[1];
        button.Label:SetText(languageInfo[2]);
        button:SetScript("OnClick", LanguageOption_OnClick);

        if languageInfo[1] == textLanguage then
            button.ignore = true;
            button:Disable();
            button.Tick:Show();
            button.Label:SetTextColor(0.42, 0.42, 0.42);
        end
    end

    local width = floor((button.Label:GetRight() - buttons[1]:GetLeft())/0.72 );
    LanguageOptions:SetSizeAndAnchor(width, 200, "TOPLEFT", anchor, "BOTTOMLEFT", 0, 80);
    
    function UpdateLanguageOptionButtons()
        local button;
        if CreatureSettings.ShowTranslatedNameOnNamePlate then
            --Single-choice
            LanguageOptions.singleChoice = true;

            local nameplateLanguage = CreatureSettings.NamePlateLanguage;
            for i = 1, #buttons do
                button = buttons[i];
                if not button.ignore then
                    button.Tick:SetShown( button.keyValue == nameplateLanguage );
                end
            end
        else
            --Multiple-choice
            LanguageOptions.singleChoice = nil;

            for i = 1, #buttons do
                button = buttons[i];
                if not button.ignore then
                    button.Tick:SetShown( CreatureSettings.Languages[button.keyValue] );
                end
            end
        end
    end
end

local function OffsetSetting_OnShow(self)
    self.number = tonumber(CreatureSettings.NamePlateNameOffset);
    self.Value:SetText(self.number);
end

local function OffsetSetting_OnClick(self)
    self.Value:Hide();
    self.Border:SetColorTexture(0.9, 0.9, 0.9);
    local EditBox = self.EditBox;
    EditBox:SetText(self.number);
    EditBox:Show();
    EditBox:HighlightText();
    EditBox:SetFocus();
end

local function OffsetSetting_EditBox_Confirm(self)
    local offset = self:GetNumber();
    self:GetParent().number = offset;
    CreatureSettings.NamePlateNameOffset = offset;
    NarciCreatureInfo.SetNamePlateNameOffset(offset);
    self:ClearFocus();
end

local function OffsetSetting_EditBox_OnHide(self)
    local Parent = self:GetParent();
    Parent.Value:SetText(Parent.number);
    Parent.Value:Show();
    Parent.Border:SetColorTexture(0, 0, 0);
end



--local ColorTable = Narci_ColorTable;

--[[
function Narci_SetTabButtonColorTheme(self)
    local ColorIndex = Narci_GlobalColorIndex;
	local R, G, B = ColorTable[ColorIndex][1], ColorTable[ColorIndex][2], ColorTable[ColorIndex][3];
	local r, g, b = R/255, G/255 ,B/255;
	self.HighlightColor:SetColorTexture(r, g, b);
	self.SelectedColor:SetColorTexture(r, g, b);
end
--]]








-----------------
-----Credits-----
-----------------
local function SetCreditList()
    local ACIVE_COLOR = "|cffd9ccb4";
    local ACTIVE_PATRONS = {"Elexys", "Solanya", "Erik Shafer", "Pierre-Yves Bertolus", "Celierra&Darvian", "Alex Boehm", "Terradon", "Brian Haberer", "Albator S.", "Lars Norberg", "Miroslav Kovac", };
    local FORMER_PATRONS = {"Miroslav Kovac", "Knightlord", "Andrew Phoenix", "Ellypse", "Nantangitan", "Blastflight ", "Valnoressa", "Nimrodan", "Brux", "Karl", "Webb", "Acein", "Christian Williamson", "Tzutzu",
    "Anthony Cordeiro", "Nina Recchia", "heiteo", "Psyloken", "Jesse Blick", "Victor Torres", };
    local RawList = {};
    for i = 1, #ACTIVE_PATRONS do
        tinsert(RawList, ACIVE_COLOR.. ACTIVE_PATRONS[i] .."|r");
    end
    for i = 1, #FORMER_PATRONS do
        tinsert(RawList, FORMER_PATRONS[i]);
    end

    local LeftList, MidList, RightList = {}, {}, {};
    local mod = mod;
    local index;
    for i = 1, #RawList do
        index = mod(i, 3);
        if index == 1 then
            tinsert(LeftList, RawList[i]);
        elseif index == 2 then
            tinsert(MidList, RawList[i]);
        else
            tinsert(RightList, RawList[i]);
        end
    end

    local LEFT, MID, RIGHT;
    for i = 1, #LeftList do
        if i == 1 then
            LEFT = LeftList[i];
            if MidList[i] then
                MID = MidList[i];
            end
            if RightList[i] then
                RIGHT = RightList[i];
            end
        else
            LEFT = LEFT.."\n"..LeftList[i];
            if MidList[i] then
                MID =  MID.."\n"..MidList[i];
                if RightList[i] then
                    RIGHT =  RIGHT.."\n"..RightList[i];
                end
            end
        end
    end

    local CreditList = Narci_CreditList;
    CreditList.PatronListLeft:SetText(LEFT);
    CreditList.PatronListMid:SetText(MID);
    CreditList.PatronListRight:SetText(RIGHT);

    CreditList.ExtraList:SetText(L["Credit List Extra"]);
end

local function Narci_InsertHeart()
    local Pref = Narci_Preference;
    local frame = Pref.LoveContainer;
    if not frame:IsMouseOver() then return; end;

    --Start at cursor position
	local px, py = GetCursorPosition();
    local scale = Pref:GetEffectiveScale();
    px, py = px / scale, py / scale;

    local d = math.max(py - Pref:GetBottom() + 16, 0); --distance
    local depth = math.random(1, 8);
    local scale = 0.25 + 0.25 * depth;
    local size = 32 * scale;
    local alpha = 1.35 - 0.15 * depth;
    local v = 20 + 10 * depth;
    local t= d / v;
    local tex = frame.ReusedTexture;
    if tex then
        --print("Reuse heart "..t);
    else
        tex = frame:CreateTexture(nil, "BACKGROUND", "NarciPinkHeartTemplate");
        --print("Inset a new heart "..t);
    end

    tex.animIn.Translation:SetOffset(0, -d);
    tex.animIn.Translation:SetDuration(t);
    tex:ClearAllPoints();
    tex:SetPoint("CENTER", nil, "BOTTOMLEFT" , px, py);

    tex:SetSize(size, size);
    tex:SetAlpha(alpha);
    tex.animIn:Play();
end

function Narci_CreditList_OnFinished(self)
    if currentTab == (TotalTab - 1) then
        Narci_InsertHeart();
        self:Play();
    end
end

----------------------------------------------------
local function ResetMinimap_OnEnter(self)
    self.Label:SetTextColor(0.88, 0.88, 0.88);
    self.Icon:SetVertexColor(0.88, 0.88, 0.88);
end

local function ResetMinimap_OnLeave(self)
    self.Label:SetTextColor(0.24, 0.78, 0.92);
    self.Icon:SetVertexColor(0.66, 0.66, 0.66);
end

local function ResetMinimap_OnClick(self)
    self.AnimRotate:Play();
    Narci_MinimapButton:ResetPosition();
end

----------------------------------------------------
NarciPreferenceMixin = CreateFromMixins(NarciChamferedFrameMixin);

function NarciPreferenceMixin:OnLoad()
    MainFrame = self;
    local v = 0.2;
    self:SetBorderColor(v, v, v);
    self:SetBackgroundColor(0.07, 0.07, 0.08, 0.95);
    self:SetOffset(10);

    --Create Settings
    local Tabs = self.ScrollFrame.scrollChild;
    local tab;

    Tabs.ExtensionTab.Cate1:SetText(L["Extensions"]);

    --Ultra-wide Optimization
    if ScreenRatio then
        local function MoveBaselineSlider_OnLoad(slider)
            slider:GetParent().Cate1:SetText(L["Ultra-wide Optimization"]);
            slider.Label:SetText(L["Baseline Offset"]);
            slider.Description:SetText(string.format(L["Ultra-wide Tooltip"], ScreenRatio));
            slider:SetMinMaxValues(0, MaxOffset);
            slider:SetValueStep(MaxOffset/8);   --Disabled
            NarciAPI_SliderWithSteps_OnLoad(slider);
        end

        local function OnValueChanged(slider, value)
            slider.VirtualThumb:SetPoint("CENTER", slider.Thumb, "CENTER", 0, 0)
            if value ~= slider.oldValue then
                slider.oldValue = value;
                value = floor(value)
                slider.KeyLabel:SetText(value);
                Narci:SetReferenceFrameOffset(value);
                Settings.BaseLineOffset = value;
            end
        end
        MoveBaselineSlider_OnLoad(Narci_MoveBaselineSlider);
        Narci_MoveBaselineSlider:SetScript("OnValueChanged", OnValueChanged)
    else
        Tabs.CreditTab:ClearAllPoints();
        Tabs.CreditTab:SetPoint("TOPLEFT", Tabs.ExtensionTab, "BOTTOMLEFT", 0, 0);
        Tabs.CreditTab:SetPoint("TOPRIGHT", Tabs.ExtensionTab, "BOTTOMRIGHT", 0, 0);
        Tabs.UltraWideSettings:Hide();
    end

    --Creature Database Tab
    CreatureTab = Tabs.CreatureTab;
    tab = CreatureTab;
    tab.Cate1:SetText(L["Database"]);
    tab.Cate2:SetText(L["Creature Tooltip"]);

    local OffsetSetting = tab.OnNamePlate.OffsetSetting;
    OffsetSetting.Label:SetText(L["Y Offset"]);
    OffsetSetting:SetScript("OnShow", OffsetSetting_OnShow);
    OffsetSetting:SetScript("OnClick", OffsetSetting_OnClick);
    local EditBox = OffsetSetting.EditBox;
    EditBox:SetScript("OnHide", OffsetSetting_EditBox_OnHide);
    EditBox:SetScript("OnEnterPressed", OffsetSetting_EditBox_Confirm);
    EditBox:SetScript("OnSpacePressed", OffsetSetting_EditBox_Confirm);

    CreateLanguageOptions(tab, tab.Translator);

    --"Reset" Button
    local resetButton = Tabs.Tab2.ResetButton;
    resetButton:SetScript("OnEnter", ResetMinimap_OnEnter);
    resetButton:SetScript("OnLeave", ResetMinimap_OnLeave);
    resetButton:SetScript("OnClick", ResetMinimap_OnClick);
    ResetMinimap_OnLeave(resetButton);
    resetButton:SetWidth( (resetButton.Label:GetWidth() or 20) + 48 );

    --Build Tab Buttons
    BuildTabButtonList(self.TabButtonFrame, "Narci_TabButtonTemplate", TabNames, 0, -12);
end

function NarciPreferenceMixin:OnShow()
    Narci_PreferenceButton:LockHighlight();
end

function NarciPreferenceMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
    Narci_PreferenceButton:UnlockHighlight();
end

function NarciPreferenceMixin:OnMouseWheel()

end

function NarciPreferenceMixin:ScrollToTab(index)
    self.ScrollFrame.scrollBar:SetValue(index * TabHeight);
end

function NarciPreferenceMixin:ResetAnchor()
    if self.anchorTo ~= "narcissus" then
        self.anchorTo = "narcissus";
        self:ClearAllPoints();
        self:SetParent(Narci_Vignette);
        self:SetScale(1);
        self:SetFrameStrata("DIALOG");
        self:SetPoint("CENTER", Narci_VirtualLineCenter, "CENTER", 0, 0);
        self.CloseButton:Show();
        self:SetBorderColor(0.2, 0.2, 0.2);
        self:SetBackgroundColor(0.07, 0.07, 0.08, 0.95);
    end
end

function NarciPreferenceMixin:AnchorToInterfaceOptions()
    if self.anchorTo ~= "blizzard" then
        self.anchorTo = "blizzard";
        self:ClearAllPoints();
        local Panel = Narci_InterfaceOptionsPanel;
        local Container = InterfaceOptionsFramePanelContainer;
        local containerWidth = Container:GetWidth();
        local uiScale = Container:GetEffectiveScale();
        if containerWidth and uiScale then
            self:SetScale(uiScale * containerWidth / 500);
        end
        self:SetParent(Container);
        self:SetPoint("BOTTOMLEFT", Container, "BOTTOMLEFT", 2, 2);
        self.CloseButton:Hide();
        self:SetBorderColor(0, 0, 0, 0);
        self:SetBackgroundColor(0, 0, 0, 0);
    end
    self:Show();
    self:SetAlpha(1);
end

function NarciPreferenceMixin:Toggle()
    local state = not self:IsShown();
    if state then
        FadeFrame(Narci_Preference, 0.15, 1);
    else
        FadeFrame(Narci_Preference, 0.2, 0);
    end
end


function Narci_PreferenceButton_OnClick(self)
    MainFrame:ResetAnchor();
    MainFrame:Toggle();
end

----------------------------------------------------
local function InitializePreference()
    Settings, CreatureSettings = NarcissusDB, NarciCreatureOptions;

    local ScrollFrame = Narci_Preference.ScrollFrame;
    CreateSettingFrame(ScrollFrame.scrollChild);

    UpdateLanguageOptionButtons();

    --Using Old Method --Will be changed in the future
    AFKScreenSwitch_SetState(Narci_AFKScreenSwitch);
    AFKAutoStand_SetState(Narci_AFKAutoStandSwitch);
    GemManagerSwitch_SetState(Narci_GemManagerSwitch);
    DressingRoomSwitch_SetState(Narci_DressingRoomSwitch);
    TranslatorSwitch_SetState(Narci_TranslateNameSwitch);
    FindRelativesSwitch_SetState(Narci_FindRelativesSwitch);
    TranslationPositionButton_SetState();
    UpdateSelectedLanguage();
    LoadOnDemandSwitch_OnLoad(Narci_LoadOnDemandSwitch);
    --Ultra-wide
    Narci_MoveBaselineSlider:SetValue(Settings.BaseLineOffset);


    --Create UI on Interface Options Panel (ESC-Interface)
    local Panel = Narci_InterfaceOptionsPanel;
    Panel.name = "Narcissus";
    Panel.Header:SetText(L["Preferences"]);
    Panel.Description:SetText(L["Interface Options Tab Description"]);

    InterfaceOptions_AddCategory(Panel);
    
    
    Panel:HookScript("OnShow", function(self)
        if self:IsVisible() then
            MainFrame:AnchorToInterfaceOptions();
        end
    end);
    
    Panel:HookScript("OnHide", function(self)
        MainFrame:Hide();
    end)
end

local Initialize = CreateFrame("Frame");
Initialize:RegisterEvent("PLAYER_ENTERING_WORLD");
Initialize:SetScript("OnEvent",function(self,event,...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        InitializePreference();
        SetCreditList();
    end
end)