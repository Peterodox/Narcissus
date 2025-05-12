local _, addon = ...

local EXPANDED_BAR_LEFT_OFFSET = 68;    --Constant
local COLLAPSED_BAR_LEFT_OFFSET = -120; --Variable

local IsTrackingPets = C_Minimap.IsTrackingBattlePets;
local SetTrackingPets = addon.TransitionAPI.SetTrackingPets;

local outSine = addon.EasingFunctions.outSine;

local InCombatLockdown = InCombatLockdown;


local MainFrame;
local ToolbarButtons = {};

function ToolbarButtons:DisableButtons()
    for i = 1, #self do
        self[i]:Disable();
    end
end

function ToolbarButtons:EnableButtons()
    for i = 1, #self do
        self[i]:Enable();
    end
end

function ToolbarButtons:SetButtonVisiblity(state)
    if state then
        for i = 1, #self do
            self[i]:Enable();
            self[i]:SetAlpha(1);
        end
    else
        for i = 1, #self do
            self[i]:Disable();
            self[i]:SetAlpha(0);
        end
    end
end

function ToolbarButtons:ResetButtonState()
    for i = 1, #self do
        self[i].isOn = nil;
        self[i]:UpdateIcon();
    end
end

function ToolbarButtons:RunShowButtonCallback()
    for i = 1, #self do
        if self[i].onInitFunc then
            self[i].onInitFunc(self[i]);
        end
    end
end

ToolbarButtons.buttonTypeToButton = {};


local SwitchButtonScripts = {};

function SwitchButtonScripts.OnEnter(self)
    self.Icon:SetTexCoord(0, 0.1875, 0.4375, 0.625);
    MainFrame:OnEnter();
end

function SwitchButtonScripts.OnLeave(self)
    if not MainFrame.expanded then
        self.Icon:SetTexCoord(0, 0.1875, 0.25, 0.4375);
    end
    MainFrame:OnLeave();
end

function SwitchButtonScripts.OnClick(self)
    if MainFrame.expanded then
        MainFrame:Collapse();
    else
        MainFrame:Expand();
    end
end

function SwitchButtonScripts.OnMouseDown(self)
    self.Icon:SetSize(56, 56);
end

function SwitchButtonScripts.OnMouseUp(self)
    self.Icon:SetSize(60, 60);
end




---Set Graphics Settings to Ultra---
local CVAR_GRAPHICS_BACKUP = {};
local CVAR_GRAPHICS_VALUES = {
	["graphicsTextureResolution"] = 2,
	["graphicsTextureFiltering"] = 5,
	["graphicsProjectedTextures"] = 1,

	["graphicsViewDistance"] = 9,
	["graphicsEnvironmentDetail"] = 9,
	["graphicsGroundClutter"] = 9,

	["graphicsShadowQuality"] = 5,
	["graphicsLiquidDetail"] = 3,
	["graphicsComputeEffects"] = 4,
	["graphicsParticleDensity"] = 5,
	["graphicsSSAO"] = 4,
	["graphicsDepthEffects"] = 3,
	--["graphicsLightingQuality"] = 3,
	["lightMode"] = 2,
    ["ffxAntiAliasingMode"] = 2,    --FXAA High
	["MSAAQuality"] = 4,	--4 is invalid. But used for backup
	["shadowrt"] = -1,		--invalid
}

---Hide Names and Bubbles---
local CVAR_UNIT_NAME_BACKUP = {};
local CVAR_UNIT_NAME_VALUES = {			--Unit Name CVars
	["UnitNameOwn"] = 0,
	["UnitNameNonCombatCreatureName"] = 0,
	["UnitNameFriendlyPlayerName"] = 0,
	["UnitNameFriendlyPetName"] = 0,
	["UnitNameFriendlyMinionName"] = 0,
	["UnitNameFriendlyGuardianName"] = 0,
	["UnitNameFriendlySpecialNPCName"] = 0,
	["UnitNameEnemyPlayerName"] = 0,
	["UnitNameEnemyPetName"] = 0,
	["UnitNameEnemyGuardianName"] = 0,
	["UnitNameNPC"] = 0,
	["UnitNameInteractiveNPC"] = 0,
	["UnitNameHostleNPC"] = 0,
	["chatBubbles"] = 0,
	["floatingCombatTextCombatDamage"] = 0,
	["floatingCombatTextCombatHealing"] = 0,

    ["SoftTargetEnemy"] = 1,
    ["SoftTargetInteract"] = 1,
};


local CVAR_CAMERA_BACKUP = {};
local CVAR_CAMERA_VALUES = {
    ["cameraFov"] = 90,
    ["test_cameraOverShoulder"] = 0,
    ["test_cameraDynamicPitch"] = 0,
    ["test_cameraDynamicPitchBaseFovPad"] = 0,
    ["cameraViewBlendStyle"] = 1,
}


local SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar;
local GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar;
local ConsoleExec = ConsoleExec;

local CVarUtil = {};
CVarUtil.groups = {};

function CVarUtil:Backup(originalTable, backupTable)
    for k, v in pairs(originalTable) do
        backupTable[k] = GetCVar(k) or 0;
    end
end

function CVarUtil:Restore(backupTable)
    for k, v in pairs(backupTable) do
        SetCVar(k, v);
    end
end

function CVarUtil:SetValues(cvarTable, value)
    for k, v in pairs(cvarTable) do
        SetCVar(k, value);
    end
end

function CVarUtil:Zero(cvarTable)
    for k, v in pairs(cvarTable) do
        SetCVar(k, 0);
    end
end

function CVarUtil:BackupAll()
    self:Backup(CVAR_GRAPHICS_VALUES, CVAR_GRAPHICS_BACKUP);
    self:Backup(CVAR_UNIT_NAME_VALUES, CVAR_UNIT_NAME_BACKUP);
    self:Backup(CVAR_CAMERA_VALUES, CVAR_CAMERA_BACKUP);
    self:SaveTrackingStatus();
end

function CVarUtil:RestoreAll()
    self:SetHideTextStatus(false);
    self:SetTopQualityStatus(false);
    self:SetCameraStatus(false);
end

function CVarUtil:SaveTrackingStatus()
	self.isTrackingBattlePet = IsTrackingPets();
end

function CVarUtil:SetTrackingStatus(state)
	SetTrackingPets(state);
end

function CVarUtil:RestoreTrackingStatus()
	if self.isTrackingBattlePet then
		self:SetTrackingStatus(true);
	end
end

function CVarUtil:MarkCVarChanged(groupName, state)
    self.groups[groupName] = state;
end

function CVarUtil:IsCVarChanged(groupName)
    return self.groups[groupName]
end


function CVarUtil:SetHideTextStatus(state)
    --causes "Interface action failed" when used in combat programmatically, still functioning, no workaround
    if state then
        if not self:IsCVarChanged("HideTexts") then
            CVarUtil:Backup(CVAR_UNIT_NAME_VALUES, CVAR_UNIT_NAME_BACKUP);
            CVarUtil:Zero(CVAR_UNIT_NAME_BACKUP);
            CVarUtil:SaveTrackingStatus();
            CVarUtil:SetTrackingStatus(false);
            self:MarkCVarChanged("HideTexts", true);
        end
    else
        if self:IsCVarChanged("HideTexts") then
            CVarUtil:RestoreTrackingStatus();
            CVarUtil:Restore(CVAR_UNIT_NAME_BACKUP);
            self:MarkCVarChanged("HideTexts", false)
        end
    end
end

function CVarUtil:SetTopQualityStatus(state)
    if state then
        if not self:IsCVarChanged("TopQuality") then
            CVarUtil:Backup(CVAR_GRAPHICS_VALUES, CVAR_GRAPHICS_BACKUP);
            CVarUtil:Restore(CVAR_GRAPHICS_VALUES);
            self:MarkCVarChanged("TopQuality", true);
        end
    else
        if self:IsCVarChanged("TopQuality") then
            CVarUtil:Restore(CVAR_GRAPHICS_BACKUP);
            self:MarkCVarChanged("TopQuality", false)
        end
    end
end

function CVarUtil:SetCameraStatus(state)
    if state then
        if not self:IsCVarChanged("Camera") then
            CVarUtil:Backup(CVAR_CAMERA_VALUES, CVAR_CAMERA_BACKUP);
            self:MarkCVarChanged("Camera", true);
        end
    else
        if self:IsCVarChanged("Camera") then
            CVarUtil:Restore(CVAR_CAMERA_BACKUP);
            self:MarkCVarChanged("Camera", false)
        end
    end
end


local function MogButton_OnClick(self)
    self.isOn = not self.isOn;
    self:UpdateIcon();
end

local function EmoteButton_OnClick(self)
    local state = not MainFrame.EmoteFrame:IsShown();
    if state then
        MainFrame.EmoteFrame:ClearAllPoints();
        if MainFrame.CameraSettingFrame:IsShown() then
            MainFrame.EmoteFrame:SetPoint("BOTTOMLEFT", MainFrame.CameraSettingFrame, "BOTTOMRIGHT", 0, 0);
        elseif MainFrame.TransmogListFrame:IsShown() then
            MainFrame.EmoteFrame:SetPoint("BOTTOMLEFT", MainFrame.TransmogListFrame, "BOTTOMLEFT", MainFrame.TransmogListFrame.collapsedWidth + 6, 0);
        else
            MainFrame.EmoteFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 4, 6);
        end

        MainFrame.EmoteFrame:ShowUI();
        MainFrame.EmoteFrame.parentButton = self;
        self.isOn = true;
    else
        MainFrame.EmoteFrame:HideUI();
        self.isOn = nil;
    end

    self:UpdateIcon();
end

local function HideTextsButton_OnClick(self)
	self.isOn = not CVarUtil:IsCVarChanged("HideTexts");
	NarcissusDB.HideTextsWithUI = self.isOn;
	CVarUtil:SetHideTextStatus(self.isOn);

    self:UpdateIcon();
end

local function HideTextsButton_OnInit(self)
    if InCombatLockdown() then return end;

    self.isOn = NarcissusDB.HideTextsWithUI;

    if self.isOn then
        CVarUtil:SetHideTextStatus(true);
    end

    self:UpdateIcon();
end

local function TopQualityButton_OnClick(self)
	self.isOn = not CVarUtil:IsCVarChanged("TopQuality");
	CVarUtil:SetTopQualityStatus(self.isOn);

    if self.isOn then
        MainFrame.TopQualityFrame:ClearAllPoints();
        if MainFrame.Switch:IsShown() then
            MainFrame.TopQualityFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 4, -11);
        else
            MainFrame.TopQualityFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 28, -11);
        end
        MainFrame.showTopQualityFrame = true;
        MainFrame.TopQualityFrame:Show();
	else
        MainFrame.showTopQualityFrame = nil;
        MainFrame.TopQualityFrame:Hide();
	end

    self:UpdateIcon();
end

local function CameraButton_OnClick(self)
    local state = not MainFrame.CameraSettingFrame:IsShown();
    if state then
        MainFrame.CameraSettingFrame:ClearAllPoints();
        MainFrame.CameraSettingFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 6);
        MainFrame.CameraSettingFrame:Show();
        self.isOn = true;
    else
        MainFrame.CameraSettingFrame:Hide();
        self.isOn = nil;
    end

    if (not Narci.groupPhotoMode) then
        CVarUtil:SetCameraStatus(self.isOn);
    end

    self:UpdateIcon();
end

local function LocationButton_OnClick(self)
    local state = not MainFrame.PlayerLocationFrame:IsShown();
    MainFrame.PlayerLocationFrame:SetShown(state);
    MainFrame.PlayerLocationFrame.enabled = state;
    if state then
        self.isOn = true;
    else
        self.isOn = nil;
    end
    self:UpdateIcon();
end

local function LocationButton_OnInit(self)
    self.isOn = MainFrame.PlayerLocationFrame.enabled;
    if self.isOn then
        MainFrame.PlayerLocationFrame:Show();
    end
    self:UpdateIcon();
end

local ToolbarButtonInfo = {
    Mog = {
        onClickFunc = MogButton_OnClick,
    },

    Emote = {
        onClickFunc = EmoteButton_OnClick,
    },

    HideTexts = {
        onClickFunc = HideTextsButton_OnClick,
        onInitFunc = HideTextsButton_OnInit,
    },

    TopQuality = {
        onClickFunc = TopQualityButton_OnClick,
    },

    Camera = {
        onClickFunc = CameraButton_OnClick,
    },

    Location = {
        onClickFunc = LocationButton_OnClick,
        onInitFunc = LocationButton_OnInit,
    },
};

local Layouts = {
    Narcissus = {"Mog", "Emote", "HideTexts", "TopQuality",
        showSwitch = true,
    },

    Blizzard = {"Camera", "Emote", "HideTexts", "TopQuality", "Location",
        customScale = 1,
    },

    PhotoMode = {"Mog", "Emote", "HideTexts", "TopQuality", "Camera",
        showSwitch = true,
    },
};


local function OverrideToolbarButtonOnClickFunc(key, newFunc)
    if ToolbarButtonInfo[key] and newFunc then
        ToolbarButtonInfo[key].onClickFunc = newFunc;
    end
end

local function OverrideToolbarButtonOnInitFunc(key, newFunc)
    if ToolbarButtonInfo[key] and newFunc then
        ToolbarButtonInfo[key].onInitFunc = newFunc;
    end
end

local function  GetToolbarButtonByButtonType(buttonKey)
    if buttonKey and ToolbarButtons.buttonTypeToButton[buttonKey] then
        return ToolbarButtons.buttonTypeToButton[buttonKey]
    end
end

addon.OverrideToolbarButtonOnClickFunc = OverrideToolbarButtonOnClickFunc;
addon.OverrideToolbarButtonOnInitFunc = OverrideToolbarButtonOnInitFunc;
addon.GetToolbarButtonByButtonType = GetToolbarButtonByButtonType;


local function MSAASlider_OnValueChanged(self, value, userInput)
    local valueText = "";
    value = tonumber(value);
    if value ~= 0 then
        if value == 1 then
            valueText = "2x";
        elseif value == 2 then
            valueText = "4x";
        elseif value == 3 then
            valueText = "8x";
        end
        valueText = "|cff3fc7eb"..valueText;
    else
        valueText = "|cff808080".."OFF";
    end

    --self:SetLabel("MSAA "..valueText);
    self:SetValueText(valueText);

    if userInput then
        if value ~= 0 then
            ConsoleExec("MSAAQuality "..value..",0");
        else
            ConsoleExec("MSAAQuality 0");
        end
    end
end

local function MSAASlider_GetValue(self)
    local level = tostring(GetCVar("MSAAQuality") or 0);
    local value = tonumber(string.sub(level, 1, 1));
    self.value = nil;

    if not value or value > 3 then
        value = 0;
    end

    self:SetValue(value, false);
end


local function IsValueZero(value)
    return value < 0.0001 and value > -0.0001
end

local function ShoulderSlider_OnValueChanged(self, value, userInput)
    if IsValueZero(value) then
        value = 0;
    end

    --self:SetLabel( string.format("Offset |cff62c497%.1f|r", value) );
    self:SetValueText(string.format("|cff62c497%.1f|r", value));

    if userInput then
        SetCVar("test_cameraOverShoulder", -value);
    end
end

local function ShoulderSlider_GetValue(self)
    local value = tonumber(GetCVar("test_cameraOverShoulder") or 0);
    self:SetValue(-value);
end


local function FoVSlider_OnValueChanged(self, value, userInput)
    --self:SetLabel( string.format("FoV |cff62c497%.1f|r", value) );
    self:SetValueText(string.format("|cff62c497%.1f|r", value));

    if userInput then
        SetCVar("camerafov", value);
    end
end

local function FoVSlider_GetValue(self)
    local value = tonumber(GetCVar("camerafov") or 90);
    self:SetValue(value);
end


local function PitchSlider_OnValueChanged(self, value, userInput)
    if IsValueZero(value) then
        --self:SetLabel("Pitch |cff62c497|r |cff808080OFF|r");
        self:SetValueText("|cff808080OFF|r");
    else
        --self:SetLabel( string.format("Pitch |cff62c497%.1f|r", value) );
        self:SetValueText( string.format("|cff62c497%.1f|r", value) );
    end


    if userInput then
        if IsValueZero(value) then
            SetCVar("test_cameraDynamicPitch", 0);
        else
            SetCVar("test_cameraDynamicPitch", 1);
        end
        SetCVar("test_cameraDynamicPitchBaseFovPad", value);
    end
end

local function PitchSlider_GetValue(self)
    local pitchOn = tonumber(GetCVar("test_cameraDynamicPitch") or 0) >= 1;

    local value;

    if pitchOn then
        value = tonumber(GetCVar("test_cameraDynamicPitchBaseFovPad") or 0);
    else
        value = 0;
    end

    self:SetValue(value);
end


local GetCameraZoom = GetCameraZoom;
local CameraZoomIn = CameraZoomIn;
local CameraZoomOut = CameraZoomOut;

local function ZoomToDistance(value)
    local diff = value - GetCameraZoom();
    if diff > 0 then
        CameraZoomOut(diff);
    elseif diff < 0 then
        CameraZoomIn(-diff);
    end
end

local function ZoomSlider_OnValueChanged(self, value, userInput)
    --self:SetLabel( string.format("Zoom |cff62c497%.1f|r", value) );
    self:SetValueText( string.format("|cff62c497%.1f|r", value) );
    if userInput then
        ZoomToDistance(value);
    end
end

local function ZoomSlider_GetValue(self)
    local value = GetCameraZoom();
    self:SetValue(value);
end

local function ZoomSlider_OnUpdate(self, elapsed)
    if self.isDragging then return end;

    if not self.t then
        self.t = 1;
    end

    self.t = self.t + elapsed;

    if self.t > 0.2 then
        self.t = 0;
    else
        return
    end

    ZoomSlider_GetValue(self);
end


local function PlayCheckSound(self)
	if self.isOn then
		PlaySound(856);     --SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
	else
		PlaySound(857);     --SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
	end
end

local function ToolbarButton_OnEnter(self)
    MainFrame:OnEnter();
    MainFrame.Tooltip:ShowToolbarTooltip(self);
end

local function ToolbarButton_OnLeave(self)
    MainFrame:OnLeave();
    MainFrame.Tooltip:HideTooltip();
end


NarciScreenshotToolbarButtonMixin = {};

function NarciScreenshotToolbarButtonMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);
    ToolbarButton_OnEnter(self);
    --self.Highlight.AnimFlash:Play();
end

function NarciScreenshotToolbarButtonMixin:OnLeave()
    --[[
    if self.isOn then
        self.Icon:SetVertexColor(0.9, 0.9, 0.9);
    else
        self.Icon:SetVertexColor(0.72, 0.72, 0.72);
    end
    --]]
    self.Icon:SetVertexColor(0.9, 0.9, 0.9);
    ToolbarButton_OnLeave(self);
end

function NarciScreenshotToolbarButtonMixin:OnClick(mouseButton)
    if self.onClickFunc then
        self.onClickFunc(self);
    end
    self:UpdateIcon();
    if mouseButton then
        PlayCheckSound(self);
    end
end

function NarciScreenshotToolbarButtonMixin:OnMouseDown()
    self.Icon:SetSize(36, 36);
end

function NarciScreenshotToolbarButtonMixin:OnMouseUp()
    self.Icon:SetSize(40, 40);
end

function NarciScreenshotToolbarButtonMixin:UpdateIcon()
    if self.isOn then
        self.Icon:SetTexCoord(0.5, 1, 0, 1);
    else
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
    end

    if self:IsVisible() and self:IsMouseOver() then
        self.Icon:SetVertexColor(1, 1, 1);
    else
        self.Icon:SetVertexColor(0.9, 0.9, 0.9);
    end
end

function NarciScreenshotToolbarButtonMixin:OnDoubleClick()
    --do nothing
end


local TRANSITION_TIME = 0.5;
local AnimExpand = CreateFrame("Frame");

local function AnimExpand_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    local offsetX;
    local radian;

    if self.t >= self.duration then
        offsetX = self.toX;
        radian = self.toRadian;
        self:SetScript("OnUpdate", nil);
    else
        offsetX = outSine(self.t, self.fromX, self.toX, self.duration);
        radian = outSine(self.t, self.fromRadian, self.toRadian, self.duration);
    end

    MainFrame.BarLeft:SetPoint("LEFT", offsetX, 0);
    MainFrame.Switch.Ring:SetRotation(radian);

    local diff, alpha;
    for i = 1, 4 do
        diff = ToolbarButtons[i].relativeOffset + offsetX - 40;
        if diff > 20 then
            alpha = 1;
        elseif diff > 4 then
            alpha = diff/20;
        else
            alpha = 0;
        end
        ToolbarButtons[i]:SetAlpha(alpha);
    end
end

function AnimExpand:Start(toX, toRadian, snap)
    local _, _, _, fromX = MainFrame.BarLeft:GetPoint();
    local fullOffset = EXPANDED_BAR_LEFT_OFFSET - COLLAPSED_BAR_LEFT_OFFSET;

    local duration;
    if snap then
        duration = 0;
    else
        duration = TRANSITION_TIME * math.abs(fromX - toX)/fullOffset;
        if duration < 0.15 then
            duration = 0.15;
        end
    end

    self.fromRadian = MainFrame.Switch.Ring:GetRotation();
    self.toRadian = toRadian;
    self.fromX = fromX;
    self.toX = toX;
    self.t = 0;
    self.duration = duration;
    self:SetScript("OnUpdate", AnimExpand_OnUpdate);
end

function AnimExpand:Stop()
    self:SetScript("OnUpdate", nil);
end


local function SubFrame_OnEnter(self)
    MainFrame:OnEnter();
end

local function SubFrame_OnLeave(self)
    MainFrame:OnLeave();
end


local function UpdateAnchor()
    if MainFrame.layout == "Narcissus" then
        local scale = MainFrame.defaultScale or 1;
        if scale >= 1 then
            MainFrame:SetPoint("BOTTOMLEFT", 0, -80);
            MainFrame.adaptivePosition = true;
        else
            MainFrame:SetPoint("BOTTOMLEFT", 0, 0);
            MainFrame.adaptivePosition = nil;
        end
    else
        MainFrame.adaptivePosition = nil;
        MainFrame:SetPoint("BOTTOMLEFT", 0, 0);
    end
end

NarciScreenshotToolbarMixin = {};

function NarciScreenshotToolbarMixin:OnLoad()
    MainFrame = self;

    --Expand Panel Switch
    for methodName, method in pairs(SwitchButtonScripts) do
        self.Switch:SetScript(methodName, method);
    end

    self.TopQualityFrame.MSAASlider.onValueChangedFunc = MSAASlider_OnValueChanged;
    self.TopQualityFrame.MSAASlider.onShowCallback = MSAASlider_GetValue;

    self.CameraSettingFrame.ShoulderSlider.onValueChangedFunc = ShoulderSlider_OnValueChanged;
    self.CameraSettingFrame.ShoulderSlider.onShowCallback = ShoulderSlider_GetValue;

    self.CameraSettingFrame.FoVSlider.onValueChangedFunc = FoVSlider_OnValueChanged;
    self.CameraSettingFrame.FoVSlider.onShowCallback = FoVSlider_GetValue;

    self.CameraSettingFrame.ZoomSlider.onValueChangedFunc = ZoomSlider_OnValueChanged;
    self.CameraSettingFrame.ZoomSlider.onShowCallback = ZoomSlider_GetValue;
    self.CameraSettingFrame.ZoomSlider:SetScript("OnUpdate", ZoomSlider_OnUpdate);
    self.CameraSettingFrame.ZoomSlider.alwaysUpdate = true;

    self.CameraSettingFrame.PitchSlider.onValueChangedFunc = PitchSlider_OnValueChanged;
    self.CameraSettingFrame.PitchSlider.onShowCallback = PitchSlider_GetValue;

    self.CameraSettingFrame:SetScript("OnEnter", SubFrame_OnEnter);
    self.CameraSettingFrame:SetScript("OnLeave", SubFrame_OnLeave);

    --self:SetLayout("Narcissus");
    self:SetLayout("Blizzard");

    self:FadeOut(true);
end

function NarciScreenshotToolbarMixin:SetLayout(layoutName)
    if self.layout == layoutName then
        return
    end

    local layout = Layouts[layoutName];
    if layout then
        self.layout = layoutName;
    else
        return
    end

    local BUTTON_SIZE = 40;
    local SIDE_SIZE = 40;
    local GAP = 2;
    local SIDE_OFFSET = -22;
    local FROM_OFFSET = (layout.showSwitch and EXPANDED_BAR_LEFT_OFFSET) or 0;
    local numButtons = #layout;
    local button;
    for i, buttonKey in ipairs(layout) do
        if not ToolbarButtons[i] then
            ToolbarButtons[i] = CreateFrame("Button", nil, self, "NarciScreenshotToolbarButtonTemplate");
            ToolbarButtons[i].relativeOffset = (i - 1) * (BUTTON_SIZE + GAP);
        end

        button = ToolbarButtons[i];
        button:ClearAllPoints();
        local offsetX = FROM_OFFSET + SIDE_SIZE + SIDE_OFFSET + (i-1)*(BUTTON_SIZE + GAP);
        button:SetPoint("LEFT", self.BarLeft, "LEFT", offsetX - FROM_OFFSET, 0);
        button.relativeOffset = offsetX - FROM_OFFSET;
        button:Show();

        if button.type ~= buttonKey then
            button.type = buttonKey;
            button.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\ScreenshotTool\\Icon"..buttonKey);
            button.Icon:SetTexCoord(0, 0.5, 0, 1);
            button:UpdateIcon();
            button.onClickFunc = ToolbarButtonInfo[buttonKey].onClickFunc;
            button.onInitFunc = ToolbarButtonInfo[buttonKey].onInitFunc;
        end

        ToolbarButtons.buttonTypeToButton[buttonKey] = button;
    end

    for i = numButtons + 1, #ToolbarButtons do
        ToolbarButtons[i]:Hide();
        ToolbarButtons[i].type = nil;
        ToolbarButtons[i].onInitFunc = nil;
    end

    local centralWidth = numButtons * (BUTTON_SIZE + GAP) - GAP + 2*SIDE_OFFSET;
    COLLAPSED_BAR_LEFT_OFFSET = -centralWidth + 10;
    self.BarCenter:SetWidth(centralWidth);

    --self.BarLeft:ClearAllPoints();
    --self.BarLeft:SetPoint("LEFT", self, "LEFT", FROM_OFFSET, 0);
    --/run NarciScreenshotToolbar:SetLayout("Narcissus")

    local PADDING_H;

    if layout.showSwitch then
        PADDING_H = 0;
        self.Switch:Show();
        self.BarLeft:SetTexCoord(0.375, 0.5, 0, 0.25);
        self.BarMask:Show();
        if self.expanded then
            self:Expand(true);
        else
            self:Collapse(true);
        end
        self.ExitButton:Show();
        self.PlayerLocationFrame:Hide();

        if self.PreferenceToggle then
            self.PreferenceToggle:Show();
            if self.PreferenceToggle.scriptNotSet then
                self.PreferenceToggle.scriptNotSet = nil;
                self.PreferenceToggle:SetScript("OnEnter", ToolbarButton_OnEnter);
                self.PreferenceToggle:SetScript("OnLeave", ToolbarButton_OnLeave);
            end
        end
    else
        PADDING_H = 16;
        self.Switch:Hide();
        self.BarLeft:SetTexCoord(0.25, 0.375, 0, 0.25);
        self.BarLeft:SetPoint("LEFT", self, "LEFT", PADDING_H, 0);
        self.BarMask:Hide();
        AnimExpand:Stop();
        ToolbarButtons:SetButtonVisiblity(true);
        self.ExitButton:Hide();

        if self.PreferenceToggle then
            self.PreferenceToggle:Hide();
        end
    end

    local fullWidth = centralWidth + 2*SIDE_SIZE + FROM_OFFSET + 2*PADDING_H;
    self:SetWidth(fullWidth);
    self.fullWidth = fullWidth;

    if layout.customScale then
        self:SetScale(layout.customScale);
        self.EmoteFrame.newFontSize = 10;
        self.Tooltip:UseSmallFont(true);
    else
        self:SetScale(self.defaultScale or 1);
        self.EmoteFrame.newFontSize = 12;
        self.Tooltip:UseSmallFont(false);
    end
    UpdateAnchor();

    self.TransmogListFrame:Hide();
    self:StopAnimating();
end

function NarciScreenshotToolbarMixin:Expand(snap)
    self.expanded = true;
    self.Switch.Icon:SetTexCoord(0, 0.1875, 0.4375, 0.625);
    self:SetWidth(self.fullWidth);
    --self.BarLeft:ClearAllPoints();
    --self.BarLeft:SetPoint("LEFT", self, "LEFT", EXPANDED_BAR_LEFT_OFFSET, 0);
    AnimExpand:Start(EXPANDED_BAR_LEFT_OFFSET, 1.25*math.pi, snap);
    ToolbarButtons:EnableButtons();

    if self.showTransmogFrame then
        self.TransmogListFrame:Show();
    end
    if self.showTopQualityFrame then
        self.TopQualityFrame:Show();
    end
end

function NarciScreenshotToolbarMixin:Collapse(snap)
    self.expanded = false;
    self:SetWidth(100);
    --self.BarLeft:ClearAllPoints();
    --self.BarLeft:SetPoint("LEFT", self, "LEFT", COLLAPSED_BAR_LEFT_OFFSET, 0);
    AnimExpand:Start(COLLAPSED_BAR_LEFT_OFFSET, 0, snap);
    ToolbarButtons:DisableButtons();

    self.TransmogListFrame:Hide();
    self.TopQualityFrame:Hide();
end


local AnimFade = CreateFrame("Frame");

local function AnimFadeIn_OnUpdate(self, elapsed)
    self.alpha = self.alpha + elapsed * 4;
    if self.alpha >= 1 then
        self:SetScript("OnUpdate", nil);
        self.alpha = 1;
    end
    MainFrame:SetAlpha(self.alpha);
end

local function AnimFadeOut_OnUpdate(self, elapsed)
    self.alpha = self.alpha - elapsed * 4;
    if self.alpha <= 0 then
        self:SetScript("OnUpdate", nil);
        self.alpha = 0;
    end
    MainFrame:SetAlpha(self.alpha);
end

function AnimFade:FadeTo(toAlpha)
    if self:IsShown() and (toAlpha == self.toAlpha) then
        return
    else
        self.toAlpha = toAlpha;
    end

    self.alpha = MainFrame:GetAlpha();

    if self.alpha == toAlpha then
        return
    else
        if toAlpha > self.alpha then
            self:SetScript("OnUpdate", AnimFadeIn_OnUpdate);
        else
            self:SetScript("OnUpdate", AnimFadeOut_OnUpdate);
        end
    end

    if MainFrame.adaptivePosition then
        MainFrame.FlyDown:Stop();
        MainFrame.FlyUp:Stop();
        if toAlpha == 1 then
            MainFrame.FlyUp:Play();
        elseif toAlpha == 0 then
            MainFrame.EmoteFrame:Hide();
            MainFrame.FlyDown:Play();
        end
    end
end

function AnimFade:Stop()
    self:SetScript("OnUpdate", nil);
end


function NarciScreenshotToolbarMixin:FadeIn()
    AnimFade:FadeTo(1);
    if self.adaptivePosition then
        self:SetPoint("BOTTOMLEFT", 0, 0);
    end
end

function NarciScreenshotToolbarMixin:FadeOut(instant)
    if instant then
        AnimFade:Stop();
        AnimFade.toAlpha = 0;
        self:SetAlpha(0);
    else
        AnimFade:FadeTo(0);
    end

    if self.adaptivePosition then
        self:SetPoint("BOTTOMLEFT", 0, -80);
    end
end

function NarciScreenshotToolbarMixin:OnEnter()
    self:FadeIn();
end

function NarciScreenshotToolbarMixin:OnLeave()
    if not self:IsFocused() then
        self:FadeOut();
    end
end

local function IsFrameFocused(frame)
    return frame and frame:IsShown() and frame:IsMouseOver()
end

function NarciScreenshotToolbarMixin:IsFocused()
    return self:IsMouseOver() or self.EmoteFrame:IsFocused() or self.CameraSettingFrame:IsFocused() or self.TransmogListFrame:IsFocused() or IsFrameFocused(self.PreferenceToggle);
end

function NarciScreenshotToolbarMixin:OnShow()
    self:RegisterEvent("PLAYER_LOGOUT");
    self:RegisterEvent("PLAYER_QUITING");
    self:RegisterEvent("PLAYER_CAMPING");
    self:RegisterEvent("SCREENSHOT_STARTED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function NarciScreenshotToolbarMixin:OnHide()
    self:UnregisterEvent("PLAYER_LOGOUT");
    self:UnregisterEvent("PLAYER_QUITING");
    self:UnregisterEvent("PLAYER_CAMPING");
    self:UnregisterEvent("SCREENSHOT_STARTED");
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:FadeOut(true);
    self:UseLowerLevel(false);
end

function NarciScreenshotToolbarMixin:OnEvent(event, ...)
    if event == "SCREENSHOT_STARTED" then
        self:FadeOut(true);
    elseif event == "PLAYER_REGEN_DISABLED" then
        local toolbarButton = GetToolbarButtonByButtonType("HideTexts");
        if toolbarButton and CVarUtil:IsCVarChanged("HideTexts") then
            CVarUtil:SetHideTextStatus(false);
            toolbarButton.isOn = false;
            toolbarButton:UpdateIcon();
        end
    else
        self:OnExit();
    end
end

function NarciScreenshotToolbarMixin:OnExit()
    CVarUtil:RestoreAll();
    ToolbarButtons:ResetButtonState();

    --Hide Subframes
    self.CameraSettingFrame:Hide();
    self.EmoteFrame:Hide();
    self.TopQualityFrame:Hide();
    self.TransmogListFrame:Hide();
end

function NarciScreenshotToolbarMixin:ShowUI(layoutName)
    if layoutName ~= "Blizzard" then
        CVarUtil:SetCameraStatus(true); --save camera cvars
        self.KeyListener:Show();
    else
        self.KeyListener:Hide();
    end

    self:SetLayout(layoutName);
    self:Show();
    ToolbarButtons:RunShowButtonCallback();
end

function NarciScreenshotToolbarMixin:HideUI()
    self:OnExit();
    self:Hide();

    self.showTransmogFrame = nil;
    self.showTopQualityFrame = nil;
end

function NarciScreenshotToolbarMixin:UseLowerLevel(state)
	local strata;
    local level = 10;
	if state then
		strata = "BACKGROUND";
		self:SetAlpha(0);
        AnimFade.toAlpha = 0;
	else
		strata = "HIGH";
		if self:IsFocused() then
            self:SetAlpha(1);
            AnimFade.toAlpha = 1;
        end
	end
	self:SetFrameStrata(strata);
    self:SetFrameLevel(level);
    self.Switch:SetFrameLevel(level + 4);
	self.MotionBlock:SetFrameStrata("BACKGROUND");
	self.MotionBlock:SetFrameLevel(level + 6);
	self.MotionBlock:SetShown(state);
end

function NarciScreenshotToolbarMixin:SetDefaultScale(scale)
    --set scale to 1 when in screenshot mode (Alt+Z)
    self.defaultScale = scale;
    if self.layout == "Narcissus" then
        self:SetScale(scale);
        if scale >= 1 then
            self.adaptivePosition = true;
        else
            self.adaptivePosition = nil;
        end
    else
        self:SetScale(1);
        self:SetPoint("BOTTOMLEFT", 0, 0);
        self.adaptivePosition = nil;
    end
    UpdateAnchor();
end

function NarciScreenshotToolbarMixin:EnableMotion(state)
    --TO-DO: For PhotoMode DM Alert
end


NarciRayTracingToggleMixin = {};

function NarciRayTracingToggleMixin:SetVisual(level)
	if level and level > 0 then
		self.ButtonText:SetText("RTX ".. level);
        self.ButtonText:SetTextColor(1, 1, 1);
        self.Background:SetTexCoord(0.5, 0.8125, 0.25, 0.375);
	else
		self.ButtonText:SetText("RTX |cff808080OFF|r");
        self.ButtonText:SetTextColor(0.8, 0.8, 0.8);
        self.Background:SetTexCoord(0.5, 0.8125, 0.375, 0.5);
	end
end

function NarciRayTracingToggleMixin:SetLevel(level)
	level = tonumber(level) or 0;
	if level > 3 then
		level = 3;
	end
	self:SetVisual(level);
	SetCVar("shadowrt", level);
end

function NarciRayTracingToggleMixin:Restore()
	if self.oldValue then
		self:SetLevel(self.oldValue);
	end
end

function NarciRayTracingToggleMixin:OnClick()
	self.isOn = not self.isOn;
	if self.isOn then
		self:SetLevel(3);
	else
		self:Restore();
	end
end

function NarciRayTracingToggleMixin:OnShow()
	local level = tonumber(GetCVar("shadowrt"));
	self.oldValue = level;
	self:SetVisual(level);
end

function NarciRayTracingToggleMixin:OnHide()
	self.isOn = false;
end

function NarciRayTracingToggleMixin:OnEnter()
	self.Background:SetVertexColor(1, 1, 1);
end

function NarciRayTracingToggleMixin:OnLeave()
	self.Background:SetVertexColor(0.72, 0.72, 0.72);
end

function NarciRayTracingToggleMixin:OnLoad()
	local validity = true;
	self.isValid = validity;
    self:OnLeave();
	if not validity then
		self:Hide();
		self:Disable();
        self:GetParent():SetWidth(134);
	end
	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end



do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.UseEscapeKeyForExit(state, db)
        if state == nil then
            state = db["UseEscapeButton"];
        end

        if state then
            MainFrame.KeyListener.escapeKey = "ESCAPE";
        else
            MainFrame.KeyListener.escapeKey = "HELLOWORLD";
        end
    end
end
--[[
--Doolly Zoom:
--d = width / (2*math.tan(0.5 * fov))    --fov ~ degree
--fov = 2*math.atan(0.5 * width / d)

local atan = math.atan;
local deg = math.deg;

function GetFoVByZoomDistance(distance, width)
    local fov = deg(2*atan(0.5 * width / distance));

    if fov > 90 then
        fov = 90;
    elseif fov < 50 then
        fov = 50;
    end

    return fov
end

local UpdateFrame = CreateFrame("Frame");

UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    local d = GetCameraZoom();
    if d ~= self.distance then
        self.distance = d;
        local fov = GetFoVByZoomDistance(d, 12);  --4
        print(string.format("%.2f  %.2f", d, fov));
        SetCVar("camerafov", fov);
    end
end);
--]]


