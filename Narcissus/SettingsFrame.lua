local _, addon = ...
local SettingFunctions = addon.SettingFunctions;
local inOutSine = addon.EasingFunctions.inOutSine;
local FadeFrame = NarciFadeUI.Fade;

local DEFAULT_FRAME_WIDTH = 720;    --800 640
local DEFAULT_FRAME_HEIGHT = 405;   --450 360
local DEFAULT_LEFT_WIDTH = DEFAULT_FRAME_WIDTH - DEFAULT_FRAME_HEIGHT*4/3;
local SHRIKNED_LEFT_WIDTH = (640 - 360 * 4/3);
local MAX_SCROLLFRAME_WIDTH = 394;

local PADDING_H = 18;
local PADDING_V = 12;
local CATE_LEVEL_OFFSET = 8;
local BUTTON_LEVEL_OFFSET = 12;
local CATE_OFFSET = 64;
local WIDGET_GAP = 16;

local IS_DRAGONFLIGHT = addon.IsDragonflight();

local L = Narci.L;
local BIND_ACTION_NARCISSUS = "CLICK Narci_MinimapButton:LeftButton";
_G["BINDING_NAME_"..BIND_ACTION_NARCISSUS] = L["Binding Name Open Narcissus"];


local CategoryButtons;
local CategoryOffsets;
local CategoryTabs;
local OptionButtons;
local AllObjects;
local WidgetGroups;
local MainFrame;
local AlertMessageFrame;
local Clipboard;
local DB;
local CURRENT_CATE_ID;
local RENDER_RANGE = DEFAULT_FRAME_HEIGHT;
local NUM_CATE = 0;

local GAMEPAD_ENABLED = false;      --Determine if we need to enable game pad surrpot
local SCROLL_LOCKED = false;        --Lock scroll if user is assigning a hotkey


local math = math;
local tinsert = table.insert;
local GetCursorPosition = GetCursorPosition;
local SliderUpdator = CreateFrame("Frame");

local CreditList = {};

local function SetTextColorByID(fontString, id)
    if id == 3 then
        fontString:SetTextColor(0.92, 0.92, 0.92);
    elseif id == 2 then
        fontString:SetTextColor(0.67, 0.67, 0.67);
    elseif id == 1 then
        fontString:SetTextColor(0.40, 0.40, 0.40);
    end
end

local function SetTextureColorByID(texture, id)
    if id == 3 then
        texture:SetVertexColor(0.92, 0.92, 0.92);
    elseif id == 2 then
        texture:SetVertexColor(0.67, 0.67, 0.67);
    elseif id == 1 then
        texture:SetVertexColor(0.40, 0.40, 0.40);
    end
end

local function Round0(value)
    return math.floor(value + 0.5)
end

local function Round1(value)
    return math.floor(value * 10 + 0.5) * 0.1
end

local function Round2(value)
    return math.floor(value * 100 + 0.5) * 0.01
end

local function OnClick_Checkbox(self)
    if self.key then
        local state = not DB[self.key];
        DB[self.key] = state;
        self:UpdateState();
        if self.onValueChangedFunc then
            self.onValueChangedFunc(self, state);
        end
    end
end

local function OnClick_Radio(self)
    if self.key then
        DB[self.key] = self.id;
        self:UpdateRadioButtons();
        if self.onValueChangedFunc then
            self.onValueChangedFunc(self, self.id);
        end
    end
end


local ULTRAWIDE_MAX_OFFSET;
local ULTRAWIDE_STEP;
local IS_ULTRAWIDE;
local MAX_MODEL_SHRINKAGE = 100;

local function IsUsingUltraWideMonitor()
    return IS_ULTRAWIDE
end

do
    --Decides if it shows options for extra-wide monitor
    local W0, H = WorldFrame:GetSize();
    if (W0 and H) and H ~= 0 and (W0 / H) > (16.01 / 9) then     --No resizing option on 16:9 or lower
        IS_ULTRAWIDE = true;
        local SLICE = 4;
        local W = H / 9 * 16;
        ULTRAWIDE_MAX_OFFSET = ((W0 - W)/2);
        ULTRAWIDE_STEP = math.floor(ULTRAWIDE_MAX_OFFSET / SLICE);
        ULTRAWIDE_MAX_OFFSET = SLICE * ULTRAWIDE_STEP;
    end

    local function IsUsingUltraWideMonitor()
        return IS_ULTRAWIDE
    end

    --Calculate max model interactable area skrinkage
    MAX_MODEL_SHRINKAGE = Round0( (1/3 - 1/8) *W0 );
end

local SettingsButtonMixin = {};

function SettingsButtonMixin:UpdateState_Checkbox()
    self:SetState(self.key and DB[self.key]);
end

function SettingsButtonMixin:UpdateState_Radio()
    self:SetState(self.key and DB[self.key] == self.id);
end


NarciSettingsSharedButtonMixin = {};

function NarciSettingsSharedButtonMixin:OnClick()
    self:UpdateState();
end

function NarciSettingsSharedButtonMixin:OnEnter()
    SetTextColorByID(self.Label, 3);
    SetTextureColorByID(self.Border, 3);
    if self.onEnterFunc then
        self.onEnterFunc(self);
    end
end

function NarciSettingsSharedButtonMixin:OnLeave()
    SetTextColorByID(self.Label, 2);
    SetTextureColorByID(self.Border, 2);
    if self.onLeaveFunc then
        self.onLeaveFunc(self);
    end
end

function NarciSettingsSharedButtonMixin:SetState(state)
    if state then
        self.Selection:Show();
        self.Border:SetTexCoord(0, 0.25, 0, 1);
        self.selected = true;
    else
        self.Selection:Hide();
        self.Border:SetTexCoord(0.25, 0.5, 0, 1);
        self.selected = nil;
    end

    if self.children then
        for i = 1, #self.children do
            self.children[i]:SetShown(state);
        end
    end
end


function NarciSettingsSharedButtonMixin:SetButtonType(buttonType, keepOnClickScript)
    if buttonType == "radio" then
        self["UpdateState"] = SettingsButtonMixin["UpdateState_Radio"];
        if not keepOnClickScript then
            self:SetScript("OnClick", OnClick_Radio);
        end
        self.Background:SetTexCoord(0.5, 1, 0, 1);
        self.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Radio");
        self.Selection:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Radio");
        self.Highlight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Radio");
    else
        self["UpdateState"] = SettingsButtonMixin["UpdateState_Checkbox"];
        if not keepOnClickScript then
            self:SetScript("OnClick", OnClick_Checkbox);
        end
        self.Background:SetTexCoord(0, 0.5, 0, 1);
        self.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Checkbox");
        self.Selection:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Checkbox");
        self.Highlight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Checkbox");
    end
    self.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\ButtonBackground");
    self:OnLeave();
end

function NarciSettingsSharedButtonMixin:SetLabelText(text)
    self.Label:SetText(text);
    local textWidth = self.Label:GetWrappedWidth();
    if textWidth then
        if textWidth > 138 then
            self:SetWidth(textWidth + 22);
        else
            self:SetWidth(160);
        end
    end
end

function NarciSettingsSharedButtonMixin:UpdateRadioButtons()
    local groupID = self.groupID;
    local buttons = WidgetGroups[groupID];

    if buttons then
        for i, b in ipairs(buttons) do
            b:SetState(b == self);
        end
    end
end


---- Close Button ----
local function CloseButton_OnEnter(self)
    SetTextureColorByID(self.Cross, 3);
end

local function CloseButton_OnLeave(self)
    SetTextureColorByID(self.Cross, 1);
end

local function CloseButton_OnMouseDown(self)
    self.Cross:SetScale(0.8);
    self.Texture:SetTexCoord(0.375, 0.75, 0, 0.75);
end

local function CloseButton_OnMouseUp(self)
    self.Cross:SetScale(1);
    self.Texture:SetTexCoord(0, 0.375, 0, 0.75);
end

local function CloseButton_OnClick(self)
    MainFrame:CloseUI();
end


---- Category Button ----
local function UpdateRenderArea(topOffset)
    local bottomOffset = topOffset + RENDER_RANGE;
    local tabTop, tabBottom;

    for i = 1, NUM_CATE do
        tabTop = CategoryOffsets[i] - CATE_OFFSET;
        tabBottom = (CategoryOffsets[i + 1] or tabTop) + RENDER_RANGE;

        if (tabTop < topOffset and tabBottom > topOffset) or
            (tabTop < bottomOffset and tabBottom > bottomOffset) or
            (tabTop > topOffset and tabBottom < bottomOffset) then
            CategoryTabs[i]:Show();
        else
            CategoryTabs[i]:Hide();
        end
    end
end

local function SetCategory(id)
    --category button visual
    for i, b in ipairs(CategoryButtons) do
        if i == id then
            b.selected = true;
            SetTextColorByID(b.ButtonText, 3);
        else
            if b.selected then
                b.selected = nil;
                SetTextColorByID(b.ButtonText, 1);
            end
        end
    end
end

local CREDIT_TAB_ID = 10;

local function FindCurrentCategory(offset)
    offset = offset + 135;   --is height/3 a proper position?
    local matchID;

    for i = NUM_CATE, 1, -1 do
        if offset >= CategoryOffsets[i] then
            matchID = i;
            break
        end
    end

    if matchID ~= CURRENT_CATE_ID then
        CURRENT_CATE_ID = matchID;
        SetCategory(matchID);
        CreditList:OnFocused(matchID == CREDIT_TAB_ID);
    end

    UpdateRenderArea(offset);
end


local function CategoryButton_SetLabel(self, text)
    self.ButtonText:SetText(text);
    local numLines = self.ButtonText:GetNumLines();
    if numLines > 1 then
        self:SetHeight(40);
        if self.ButtonText:IsTruncated() then
            self.ButtonText:SetFontObject("NarciFontMedium12");
        end
        return 40;
    else
        return 24;
    end
end

local function SetScrollByCategoryID(id, smoothScroll)
    SetCategory(id);
    if smoothScroll then
        MainFrame.ScrollFrame:ScrollToOffset(CategoryOffsets[id]);
    else
        MainFrame.ScrollFrame:SetOffset(CategoryOffsets[id]);
    end
    UpdateRenderArea(CategoryOffsets[id]);
end

local function CategoryButton_OnClick(self)
    SetScrollByCategoryID(self.id, true);
end

local function CategoryButton_OnEnter(self)
    SetTextColorByID(self.ButtonText, 3);
end

local function CategoryButton_OnLeave(self)
    if not self.selected then
        SetTextColorByID(self.ButtonText, 1);
    end
end


---- Feature Preview Pictures ----
local FeaturePreview = {
    --textureKey[same as DB key] = {fileName, imageWidth, imageWidth, effectiveWidth, effectiveHeight}
    PaperDollWidget = {"Preview-PaperDollWidget.png", 512, 256, 250, 185},
    ConduitTooltip = {"Preview-ConduitTooltip.png", 512, 256, 256, 188},
    NameTranslationPosition1 = {"Preview-TranslationOnTooltip.png", 256, 256, 149, 193},
    NameTranslationPosition2 = {"Preview-TranslationOnNameplate.png", 256, 256, 149, 193},
};

function FeaturePreview.FadeIn_OnUpdate(f, elapsed)
    f.t = f.t + elapsed;
    if f.t > -0.1 and f.pendingKey then
        FeaturePreview:SetupPreview(f.pendingKey);
        f.pendingKey = nil;
        FeaturePreview.animIn:Stop();
        FeaturePreview.animIn:Play();
    end
    if f.t >= 0 then
        if f.t < 0.25 then
            f:SetAlpha(4 * f.t);
        else
            f:SetAlpha(1);
            f:SetScript("OnUpdate", nil);
        end
    end
end

function FeaturePreview.FadeOut_OnUpdate(f, elapsed)
    f.t = f.t + elapsed;
    local alpha = f.fromAlpha - 5*f.t;
    if alpha > 0 then
        f:SetAlpha(alpha);
    else
        f:SetAlpha(0);
        f:SetScript("OnUpdate", nil);
        f:Hide();
    end
end

function FeaturePreview:SetupPreview(previewKey)
    if self[previewKey] and self.anchorTo then
        self.texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\".. self[previewKey][1]);
        local w0, h0 = self[previewKey][2], self[previewKey][3];
        local w1, h1 = self[previewKey][4], self[previewKey][5];
        self.frame:SetSize(w1 * 0.75, h1 * 0.75);
        self.texture:SetTexCoord(1-(w1/w0), 1, 0, h1/h0); --textures are aligned to top-right in the image(tga)

        self.frame:ClearAllPoints();
        local offsetY = self.anchorTo:GetTop() - MainFrame.ScrollFrame:GetTop();
        self.frame:SetPoint("TOPRIGHT", MainFrame.ScrollFrame, "TOPRIGHT", -PADDING_H, offsetY);
        if self.frame:GetBottom() < MainFrame.ScrollFrame:GetBottom() + PADDING_H then
            self.frame:ClearAllPoints();
            self.frame:SetPoint("BOTTOMRIGHT", MainFrame.ScrollFrame, "BOTTOMRIGHT", -PADDING_H, PADDING_H);
        end
    end
end

function FeaturePreview.ShowPreview(anchorTo)
    if not anchorTo.previewKey then return end;

    local self = FeaturePreview;
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, MainFrame.ScrollFrame.ScrollChild);
        self.frame:SetSize(16, 16);
        self.texture = self.frame:CreateTexture(nil, "OVERLAY");
        self.texture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0);
        self.texture:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0);
        self.frame:SetScript("OnHide", function(f)
            f:Hide();
            f:ClearAllPoints();
            f:SetScript("OnUpdate", nil);
        end);

        self.animIn = self.frame:CreateAnimationGroup();
        local ag = self.animIn;
        --[[
        local path = ag:CreateAnimation("Path");
        path:SetDuration(0.5);
        path:SetStartDelay(0.08);
        local p1 = path:CreateControlPoint(nil, nil, 1);
        p1:SetOffset(0, -8);
        local p2 = path:CreateControlPoint(nil, nil, 2);
        p2:SetOffset(0, 0);
        --]]

        local tran1 = ag:CreateAnimation("translation");
        tran1:SetDuration(0);
        tran1:SetOrder(1);
        tran1:SetOffset(0, -8);
        local tran2 = ag:CreateAnimation("translation");
        tran2:SetSmoothing("OUT");
        tran2:SetDuration(0.25);
        tran2:SetOrder(1);
        tran2:SetStartDelay(0.08);
        tran2:SetOffset(0, 8);
        self.tran1 = tran1;
        self.tran2 = tran2;
    end

    local deltaX, deltaY = GetCursorDelta();
    local d = math.sqrt(deltaX*deltaX + deltaY*deltaY);
    if d == 0 then
        self.tran1:SetOffset(0, 0);
        self.tran2:SetOffset(0, 0);
    else
        self.tran1:SetOffset(-deltaX, -deltaY);
        self.tran2:SetOffset(deltaX, deltaY);
    end

    self.texture:SetTexture(nil);
    self.anchorTo = anchorTo;
    self.frame.pendingKey = anchorTo.previewKey;
    self.frame:SetAlpha(0);
    self.frame.t = -0.2;
    self.frame:SetScript("OnUpdate", self.FadeIn_OnUpdate);
    self.frame:Show();
end

function FeaturePreview.HidePreview()
    local self = FeaturePreview;
    if self.frame then
        self.frame.fromAlpha = self.frame:GetAlpha();
        if self.frame.fromAlpha > 0 then
            self.frame.t = 0;
            self.frame:SetScript("OnUpdate", self.FadeOut_OnUpdate);
            self.frame:Show();
        else
            self.frame:Hide();
        end
    end
end


---- Options ----
local function AFKToggle_OnValueChanged(self, state)
    SettingFunctions.UseAFKScreen(state);
end


local function ItemTooltipStyle_OnValueChanged(self, styleID)
    SettingFunctions.SetItemTooltipStyle(styleID)
end

local function ItemTooltipShowItemID_OnValueChanged(self, state)
    SettingFunctions.ShowItemIDOnTooltip(state);
end


local function ValueFormat_LetterboxRatio(value)
    return Round2(value) ..":1"
end

local function DoubleTap_Setup(self)
    local hotkey1, hotkey2 = GetBindingKey("TOGGLECHARACTER0");
    local labelText = L["Double Tap"];
    if hotkey1 then
        labelText = labelText.." |cffffd100("..hotkey1..")|r";
        if hotkey2 then
            labelText = labelText .. "|cffffffff or |cffffd100("..hotkey2..")|r";
        end
    else
        labelText = labelText.." |cff636363("..(NOT_APPLICABLE or "N/A")..")";
    end
    self:SetLabelText(labelText);
end

local function DoubleTap_OnValueChanged(self, state)

end

local function UseEscapeKey_OnValueChanged(self, state)
    SettingFunctions.UseEscapeKeyForExit(state);
end


local function ItemTooltipStyle_OnEnter(self)
    self.slotID = 16;
    NarciEquipmentTooltip:HideTooltip();
    NarciGameTooltip:Hide();
    local link = "|Hitem:71086:6226:173127::::::60:577:::3:6660:7575:7696|r";   --77949
    if self.id == 1 then
        if Narci_Character:IsShown() then
            NarciEquipmentTooltip:SetParent(Narci_Character);
        else
            NarciEquipmentTooltip:SetParent(UIParent);
        end
        NarciEquipmentTooltip:SetItemLinkAndAnchor(link, self);
        NarciEquipmentTooltip:ShowHotkey(false);
    elseif self.id == 2 then
        if Narci_Character:IsShown() then
            NarciGameTooltip:SetParent(Narci_Character);
        else
            NarciGameTooltip:SetParent(UIParent);
        end
        NarciGameTooltip:SetItemLinkAndAnchor(link, self);
    end
end

local function ItemTooltipStyle_OnLeave(self)
    NarciEquipmentTooltip:HideTooltip();
    NarciEquipmentTooltip:SetParent(Narci_Character);
    NarciEquipmentTooltip:ShowHotkey(true);
    NarciGameTooltip:Hide();
    NarciGameTooltip:SetParent(Narci_Character);
end


local function VignetteStrength_OnValueChanged(self, value)
    SettingFunctions.SetVignetteStrength(value);
end

local function WeatherEffectToggle_OnValueChanged(self, state)
    Narci_SnowEffect(state);
end

local function Letterbox_IsCompatible()
	local scale = UIParent:GetEffectiveScale();
	local w, h = GetScreenWidth()*scale, GetScreenHeight()*scale;
    local ratio = 2;
	local croppedHeight = w/ratio;	--2.35/2/1.8
	local maskHeight = math.floor((h - croppedHeight)/2 - 0.5);
    return maskHeight > 0
end

local function LetterboxToggle_OnValueChanged(self, state)
    SettingFunctions.UpdateLetterboxSize();
    if state then
        NarciAPI_LetterboxAnimation("IN");
    else
        NarciAPI_LetterboxAnimation("OUT");
    end
end

local function LetterboxRatio_OnValueChanged(self, value)
    SettingFunctions.UpdateLetterboxSize(value);
end

local function UltraWideOffset_OnValueChanged(self, value)
    SettingFunctions.SetUltraWideFrameOffset(value);
end

local function ShowMisingEnchantAlert_OnValueChanged(self, state)
    SettingFunctions.EnableMissingEnchantAlert(state);
end

local function ShowMisingEnchantAlert_IsValid()
    return NarciAPI.IsPlayerAtMaxLevel();
end

local function ShowDetailedStats_OnValueChanged(self, state)
    SettingFunctions.ShowDetailedStats(state);
end

local function CharacterUIScale_OnValueChanged(self, scale)
    SettingFunctions.SetCharacterUIScale(scale);
end

local function ItemNameHeight_OnValueChanged(self, height)
    SettingFunctions.SetItemNameTextHeight(height);
end

local function ItemNameWidth_OnValueChanged(self, width)
    SettingFunctions.SetItemNameTextWidth(width);
end

local function TruncateTextToggle_OnValueChanged(self, state)
    SettingFunctions.SetItemNameTruncated(state);
end

local function ShowMinimapModulePanel_OnValueChanged(self, state)
    SettingFunctions.ShowMinimapModulePanel(state);
end

local function IndependentMinimapButtonToggle_OnValueChanged(self, state)
    Narci_MinimapButton:SetIndependent(state);
end


local function ResetMinimapPosition_Setup(self)
    self.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\ResetButton");
    self.Border:SetTexCoord(0, 1, 0, 1);
    self.Selection:Hide();
    self.Selection:SetTexture(nil);
    self.Highlight:SetTexture(nil);
    self.Background:Hide();
    self.Background:SetTexture(nil);

    local animRotate = self.Border:CreateAnimationGroup();
    local r1 = animRotate:CreateAnimation("Rotation");
    r1:SetDuration(1);
    r1:SetOrder(1);
    r1:SetDegrees(360);
    r1:SetSmoothing("IN_OUT");

    function self:UpdateState()
        return
    end

    self.onEnterFunc = function()
        self.Border:SetVertexColor(1, 1, 1);
    end
    self.onLeaveFunc = function()
        SetTextureColorByID(self.Border, 2);
    end
    self.onLeaveFunc();

    self:SetScript("OnClick", function()
        Narci_MinimapButton:ResetPosition();
        animRotate:Play();
    end);
end


local function ScreenshotQuality_GetValue()
    local value = C_CVar.GetCVar("screenshotQuality");
    return tonumber(value)
end

local function ScreenshotQuality_OnValueChanged(self, value)
    C_CVar.SetCVar("screenshotQuality", value);
end

local function ModelPanelScale_OnValueChanged(self, value)
    SettingFunctions.SetModelPanelScale(value);
end

local function LoopAnimation_OnValueChanged(self, value)
    SettingFunctions.SetModelLoopAnimation(value);
end

local function SpeedyScreenshotAlert_OnValueChanged(self, value)
    SettingFunctions.SpeedyScreenshotAlert(value);
end

local function GetOppositeValue(value)
    value = Round0(value);
    if value > 0 then
        return -value
    else
        return value
    end
end

local function ModelHitRectShrinkage_OnValueChanged(self, value)
    SettingFunctions.SetModelHitRectShrinkage(value);
end


local function CameraTransition_SetupDescription(self)
    if DB[self.key] then
        if self.description then
            self.description:SetText(L["Camera Transition Description On"])
        end
    else
        if self.description then
            self.description:SetText(L["Camera Transition Description Off"])
        end
    end
end

local function CameraTransition_OnValueChanged(self, state)
    SettingFunctions.UseCameraTransition(state);
    CameraTransition_SetupDescription(self);
end

local function CameraOrbitToggle_SetupDescription(self)
    if DB[self.key] then
        if self.description then
            self.description:SetText(L["Orbit Camera Description On"])
        end
    else
        if self.description then
            self.description:SetText(L["Orbit Camera Description Off"])
        end
    end
end

local function CameraOrbitToggle_OnValueChanged(self, state)
    if Narci_Character:IsVisible() then
        MoveViewRightStop();
        if state then
            local speed = tonumber(GetCVar("cameraYawMoveSpeed")) or 180;
            MoveViewRightStart(0.005*180/speed);
        end
    end

    CameraOrbitToggle_SetupDescription(self);
end

local function CameraSafeToggle_IsValid()
    if C_AddOns.IsAddOnLoaded("DynamicCam") then
        return false
    else
        return true
    end
end

local function CameraSafeToggle_OnValueChanged(self, state)
    SettingFunctions.EnableCameraSafeMode(state);
end

local function CameraUseBustShot_OnValueChanged(self, value)
    SettingFunctions.SetDefaultZoomClose(value);
end


local function GemManagerToggle_OnValueChanged(self, state)
    if (not state) and Narci_EquipmentOption then
        Narci_EquipmentOption:CloseUI();
    end
end

local function DressingRoomToggle_OnValueChanged(self, state)
    if (state and not NarciDressingRoomOverlay) or (not state and NarciDressingRoomOverlay) then
        AlertMessageFrame:ShowRequiresReload();
    end
end

local function LFRWingDetails_OnValueChanged(self, state)
    SettingFunctions.EnableGossipFrameSoloQueueLFRDetails(state);
end

local function PaperDollWidgetToggle_OnValueChanged(self, state)
    SettingFunctions.EnablePaperDollWidget(state);
end

local function PaperDollWidget_Update()
    local f = NarciPaperDollWidgetController;
    if f  then
        f:UpdateIfEnabled();
    end
end

local function ConduitTooltipToggle_OnValueChanged(self, state)
    SettingFunctions.EnableConduitTooltip(state);
end


-- dropping hearts when creadit list is focused
local LoveGenerator = {};

function LoveGenerator.HeartAnimationOnStop(animGroup)
    local tex = animGroup:GetParent();
    tex:Hide();
    tinsert(LoveGenerator.recyledTextures, tex);
end

function LoveGenerator:GetHeart()
    if not self.textures then
        self.textures = {};
    end
    if not self.recyledTextures then
        self.recyledTextures = {};
    end

    if #self.recyledTextures > 0 then
        return table.remove(self.recyledTextures, #self.recyledTextures)
    else
        local tex = MainFrame.HeartContainer:CreateTexture(nil, "OVERLAY", "NarciPinkHeartTemplate", 2);
        tex.FlyDown:SetScript("OnFinished", LoveGenerator.HeartAnimationOnStop);
        tex.FlyDown:SetScript("OnStop", LoveGenerator.HeartAnimationOnStop);
        self.textures[ #self.textures + 1 ] = tex;
        return tex
    end
end

function LoveGenerator:CreateHeartAtCursorPosition()
    if MainFrame.HeartContainer:IsMouseOver() then
        local heart = self:GetHeart();

        local px, py = GetCursorPosition();
        local scale = MainFrame:GetEffectiveScale();
        px, py = px / scale, py / scale;
    
        local d = math.max(py - MainFrame:GetBottom() + 16, 0); --distance
        local depth = math.random(1, 8);
        local scale = 0.25 + 0.25 * depth;
        local size = 32 * scale;
        local alpha = 1.35 - 0.15 * depth;
        local v = 20 + 10 * depth;
        local t= d / v;

        if alpha > 0.67 then
            alpha = 0.67;
        end

        heart.FlyDown.Translation:SetOffset(0, -d);
        heart.FlyDown.Translation:SetDuration(t);
        heart:ClearAllPoints();
        heart:SetPoint("CENTER", UIParent, "BOTTOMLEFT" , px, py);
    
        heart:SetSize(size, size);
        heart:SetAlpha(alpha);
        heart.FlyDown:Play();
        heart:Show();
    end
end

function LoveGenerator:StopAnimation()
    if self.textures then
        for _, tex in ipairs(self.textures) do
            tex.FlyDown:Stop();
        end
    end
end



function CreditList:CreateList(parent, anchorTo, fromOffsetY)
    local active = {"Albator S.", "Lala.Marie", "Erik Shafer", "Celierra&Darvian", "Pierre-Yves Bertolus", "Terradon", "Miroslav Kovac", "Ryan Zerbin", "Helene Rigo", "Kit M", "Rui", "Elrathir"};
    local inactive = {"Alex Boehm", "Solanya", "Elexys", "Ben Ashley", "Knightlord", "Brian Haberer", "Andrew Phoenix", "Nantangitan", "Blastflight", "Lars Norberg", "Valnoressa", "Nimrodan", "Brux",
        "Karl", "Webb", "acein", "Christian Williamson", "Tzutzu", "Anthony Cordeiro", "Nina Recchia", "heiteo", "Psyloken", "Jesse Blick", "Victor Torres", "Nisutec", "Tezenari", "Gina", "Markus Magnitz"};
    local special = {"Marlamin | WoW.tools", "Keyboardturner | Avid Bug Finder(Generator)", "Meorawr | Wondrous Wisdomball", "Ghost | Real Person", "Hubbotu | Translator - Russian", "Romanv | Translator - Spanish", "Onizenos | Translator - Portuguese"};

    local aciveColor = "|cff914270";

    local numTotal = #active;
    local mergedList = active;
    local totalHeight;

    for i = 1, #active do
        active[i] = aciveColor ..active[i].."|r";
    end

    for i = 1, #inactive do
        numTotal = numTotal + 1;
        mergedList[numTotal] = inactive[i];
    end

    local upper = string.upper;
    local gsub = string.gsub;

    table.sort(mergedList, function(a, b)
        return upper( gsub(a, aciveColor, "") ) < upper( gsub(b, aciveColor, "") )
    end);


    local header = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    header:SetPoint("TOP", anchorTo, "TOP", 0, fromOffsetY);
    header:SetText(string.upper("Patrons"));
    SetTextColorByID(header, 1);

    totalHeight = header:GetHeight() + 12;
    fromOffsetY = fromOffsetY - totalHeight;

    local numRow = math.ceil(numTotal/3);

    local sidePadding = PADDING_H + BUTTON_LEVEL_OFFSET;
    self.sidePadding = sidePadding;
    self.anchorTo = anchorTo;
    self.parent = parent;

    local colWidth = (MainFrame.ScrollFrame:GetWidth() - sidePadding*2) / 3;
    local text;
    local fontString;
    local height;

    local i = 0;
    local maxHeight = 0;
    local totalTextWidth = 0;
    local width = 0;

    local fontStrings = {};

    for col = 1, 3 do
        fontString = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        fontString:SetWidth(colWidth);
        fontString:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 0, fromOffsetY);
        fontString:SetJustifyH("LEFT");
        fontString:SetJustifyV("TOP");
        fontString:SetSpacing(8);
        fontStrings[col] = fontString;
        SetTextColorByID(fontString, 1);

        text = nil;
        for row = 1, numRow do
            i = i + 1;
            if mergedList[i] then
                if text then
                    text = text .. "\n" .. mergedList[i];
                else
                    text = mergedList[i];
                end
            end
        end

        fontString:SetText(text);
        height = fontString:GetHeight();
        width = fontString:GetWrappedWidth();
        totalTextWidth = totalTextWidth + width;

        if height > maxHeight then
            maxHeight = height;
        end
    end

    self.totalTextWidth = totalTextWidth;
    self.fontStrings = fontStrings;
    self.offsetY = fromOffsetY;

    fromOffsetY = fromOffsetY - maxHeight - 48;

    local header2 = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    header2:SetPoint("TOP", anchorTo, "TOP", 0, fromOffsetY);
    header2:SetText(string.upper("special thanks"));
    SetTextColorByID(header2, 1);


    text = nil;
    for i = 1, #special do
        if i == 1 then
            text = special[i];
        else
            text = text .. "\n" .. special[i];
        end
    end

    fromOffsetY = fromOffsetY - header2:GetHeight() - 12;

    fontString = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    fontString:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", sidePadding, fromOffsetY);
    fontString:SetJustifyH("LEFT");
    fontString:SetJustifyV("TOP");
    fontString:SetSpacing(8);
    fontString:SetText(text);
    SetTextColorByID(fontString, 1);

    self.specialNames = fontString;
    self.specialNamesOffsetY = fromOffsetY;

    totalHeight = Round0(header:GetTop() - fontString:GetBottom() + 36);

    self:UpdateAlignment();

    active = nil;
    inactive = nil;

    return totalHeight
end

function CreditList:UpdateAlignment()
    if self.fontStrings then
        local offsetX = self.sidePadding;
        local parentWidth = MainFrame.ScrollFrame:GetWidth();

        local gap = (parentWidth - self.sidePadding*2 - self.totalTextWidth) * 0.5;
        for col = 1, 3 do
            self.fontStrings[col]:ClearAllPoints();
            self.fontStrings[col]:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", offsetX, self.offsetY);
            offsetX = offsetX + self.fontStrings[col]:GetWrappedWidth() + gap;
        end

        local specialNameWidth = self.specialNames:GetWrappedWidth();
        offsetX = (parentWidth - specialNameWidth) * 0.5;
        self.specialNames:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", offsetX, self.specialNamesOffsetY);
    end
end

function CreditList.TimerOnUpdate(f, elapsed)
    f.t = f.t + elapsed;
    if f.t > 3 then
        f.t = 0;
        LoveGenerator:CreateHeartAtCursorPosition();
    end
end

function CreditList:OnFocused(state)
    if state then
        if not self.focused then
            self.focused = true;
            self.parent.t = 0;
            self.parent:SetScript("OnUpdate", CreditList.TimerOnUpdate);
            FadeFrame(MainFrame.HeartContainer, 0.5, 1);
        end
    else
        if self.focused then
            self.focused = nil;
            self.parent:SetScript("OnUpdate", nil);
            FadeFrame(MainFrame.HeartContainer, 0.5, 0);
        end
    end
end

function CreditList:StopAnimation()
    if self.focused then
        LoveGenerator:StopAnimation();
    end
end


local AboutTab = {};

function AboutTab:CreateTab(parent, anchorTo, fromOffsetY)
    self.anchorTo = anchorTo;

    local sidePadding = PADDING_H + BUTTON_LEVEL_OFFSET;
    self.sidePadding = sidePadding;

    --Version Info
    local fontString = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    fontString:SetJustifyH("LEFT");
    fontString:SetJustifyV("TOP");
    SetTextColorByID(fontString, 1);
    fontString:SetSpacing(8);
    fontString:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", sidePadding, fromOffsetY);

    local version, releaseDate, timeDiff = NarciAPI.GetAddOnVersionInfo();
    local text = L["Version Colon"]..version.."\n"..L["Date Colon"]..releaseDate;
    if timeDiff then
        text = text .." ("..timeDiff..")";
    end
    text = text .. "\n"..L["Developer Colon"].."Peterodox";

    fontString:SetText(text);

    local textHeight = Round0(fontString:GetHeight());
    fromOffsetY = fromOffsetY - textHeight - 2*WIDGET_GAP;


    --Project Websites
    local projectHeader = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    projectHeader:SetJustifyH("LEFT");
    projectHeader:SetJustifyV("TOP");
    SetTextColorByID(projectHeader, 1);
    projectHeader:SetText(L["Project Page"]);
    projectHeader:SetPoint("TOP", anchorTo, "TOP", 0, fromOffsetY);
    self.projectHeader = projectHeader;

    --Animation after successfully copying link
    local animFadeIn = projectHeader:CreateAnimationGroup();
    local fadeIn1 = animFadeIn:CreateAnimation("Alpha");
    fadeIn1:SetOrder(1);
    fadeIn1:SetFromAlpha(0);
    fadeIn1:SetToAlpha(1);
    fadeIn1:SetDuration(0.25);

    local animSuccess = projectHeader:CreateAnimationGroup();
    projectHeader.animSuccess = animSuccess;
    local fadeOut1 = animSuccess:CreateAnimation("Alpha");
    fadeOut1:SetOrder(1);
    fadeOut1:SetFromAlpha(1);
    fadeOut1:SetToAlpha(0);
    fadeOut1:SetDuration(0.25);
    fadeOut1:SetStartDelay(1);
    fadeOut1:SetScript("OnFinished", function()
        projectHeader:SetText(L["Project Page"]);
        animFadeIn:Play();
    end);
    

    fromOffsetY = fromOffsetY - 24;

    local addonPages = {
        {"Curseforge", "https://wow.curseforge.com/projects/narcissus"};
        {"Wago", "https://addons.wago.io/addons/narcissus"},
    };

    local numWebsiteButton = #addonPages;
    local textWidth;
    self.websiteButtons = {};
    self.websiteButtonFromOffsetY = fromOffsetY;

    for i = 1, numWebsiteButton do
        self.websiteButtons[i] = CreateFrame("Button", nil, parent, "NarciSettingsClipboardButtonTemplate");
        self.websiteButtons[i]:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", sidePadding, fromOffsetY);
        self.websiteButtons[i].ButtonText:SetText(addonPages[i][1]);
        self.websiteButtons[i].link = addonPages[i][2];
        self.websiteButtons[i].Logo:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Website-"..addonPages[i][1]);
        textWidth = self.websiteButtons[i].ButtonText:GetWrappedWidth();
        self.websiteButtons[i].ButtonText:SetWidth(textWidth + 2);
        self.websiteButtons[i].id = i;
    end

    fromOffsetY = fromOffsetY - 48 - 2*WIDGET_GAP;

    --Other Notes & Social Media
    local notes = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
    notes:SetJustifyH("LEFT");
    notes:SetJustifyV("TOP");
    notes:SetSpacing(4);
    notes:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", sidePadding, fromOffsetY);
    notes:SetPoint("RIGHT", anchorTo, "RIGHT", -sidePadding, 0);
    notes:SetText(L["AboutTab Developer Note"]);
    SetTextColorByID(notes, 1);

    local platLogo, platName;
    for i = 1, 2 do
        platLogo = parent:CreateTexture(nil, "OVERLAY");
        platLogo:SetSize(24, 24);
        platLogo:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\PlatformLogo");
        if i == 1 then
            platLogo:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -24 + 4)
            platLogo:SetTexCoord(0, 0.5, 0, 1);
        else
            platLogo:SetPoint("LEFT", platName, "RIGHT", 24, 0);
            platLogo:SetTexCoord(0.5, 1, 0, 1);
        end
        platName = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        platName:SetJustifyH("LEFT");
        platName:SetJustifyV("MIDDLE");
        platName:SetText("Peterodox");
        platName:SetPoint("LEFT", platLogo, "RIGHT", 2, 0);
        SetTextColorByID(platName, 1);
        SetTextureColorByID(platLogo, 2);
    end
end

function AboutTab:UpdateWebsiteButtons(selectedButtonID)
    if self.websiteButtons then
        local parentWidth = MainFrame.ScrollFrame:GetWidth();
        local numWebsiteButton = #self.websiteButtons;
        local websiteButtonGap = BUTTON_LEVEL_OFFSET;

        if selectedButtonID then
            --make the selected one maximized and minimize other ones
            self.projectHeader:StopAnimating();
            self.projectHeader:SetText(L["Press Copy Yellow"]);

            local fromOffsetX = self.sidePadding;
            local minimizedWidth = 36.0;
            local maximizedWidth = Round0( parentWidth - 2*self.sidePadding -  (numWebsiteButton - 1) * (minimizedWidth + websiteButtonGap) )
            for i, button in ipairs(self.websiteButtons) do
                button:ClearAllPoints();
                button:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", fromOffsetX, self.websiteButtonFromOffsetY);
                if button.id == selectedButtonID then
                    button:SetLogoOnlyMode(false);
                    button.ButtonText:Hide();
                    button:SetWidth(maximizedWidth);
                    fromOffsetX = fromOffsetX + maximizedWidth + websiteButtonGap;
                else
                    button:SetLogoOnlyMode(true);
                    button:SetWidth(minimizedWidth);
                    button.isActive = nil;
                    if not button:IsMouseOver() then
                        button:OnLeave();
                    end
                    fromOffsetX = fromOffsetX + minimizedWidth + websiteButtonGap;
                end

            end
        else
            --equal width
            if not self.projectHeader.animSuccess:IsPlaying() then
                self.projectHeader:SetText(L["Project Page"]);
            end

            local websiteButtonWidth = Round0( (parentWidth - 2*self.sidePadding - (numWebsiteButton - 1)*websiteButtonGap) / numWebsiteButton );
            for i, button in ipairs(self.websiteButtons) do
                button:ClearAllPoints();
                button:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", self.sidePadding + (i - 1)*(websiteButtonWidth + websiteButtonGap), self.websiteButtonFromOffsetY);
                button:SetWidth(websiteButtonWidth);
                button.maximizedWidth = websiteButtonWidth;
                button:SetLogoOnlyMode(false);
                button.Logo:Show();
                button.isActive = nil;
                if button:IsMouseOver() then
                    button:OnEnter();
                else
                    button:OnLeave();
                end
            end
        end
    end
end


---- Minimap Button Skin ----
local MinimapButtonSkin = {};

function MinimapButtonSkin.OnEnter(self)
    self.AnimIn:Stop();
    self.AnimDelay:Stop();
    self.AnimDelay:Play();
    SetTextColorByID(self.SkinName, 3);
end

function MinimapButtonSkin.OnDelayFinished(self)
    local button = self:GetParent();
    button.AnimIn:Play();
    button.AnimIn.Bounce1:SetDuration(0.2);
    button.AnimIn.Bounce2:SetDuration(0.2);
    button.AnimIn.Hold1:SetDuration(20);
    button.AnimIn.Hold2:SetDuration(20);
    FadeFrame(button.HighlightTexture, 0.2, 1);
end

function MinimapButtonSkin.OnLeave(self)
    self.AnimDelay:Stop();
    self.AnimIn.Bounce1:SetDuration(0);
    self.AnimIn.Bounce2:SetDuration(0);
    self.AnimIn.Hold1:SetDuration(0);
    self.AnimIn.Hold2:SetDuration(0);
    FadeFrame(self.HighlightTexture, 0.2, 0);
    SetTextColorByID(self.SkinName, 2);
end

function MinimapButtonSkin.OnClick(self)
    NarcissusDB.MinimapIconStyle = self.skinID;
    Narci_MinimapButton:SetBackground();
    MinimapButtonSkin:UpdateState();
end

function MinimapButtonSkin.CreateOptions(parentLabel, parent, anchorTo, fromOffsetY)
    local data = {
        {"Minimap\\LOGO-Cyan", "Dark"},
        {"Minimap\\LOGO-Thick", "AzeriteUI"},
        {"Minimap\\LOGO-Hollow", "SexyMap"},
        {"Minimap\\LOGO-Dragonflight", "Dragonflight"},
    };

    local buttonWidth = 64;
    local buttonHeight = 64;
    local buttonPerRow = 4;
    local gap = 0;

    local self = MinimapButtonSkin;

    self.buttonWidth = buttonWidth;
    self.buttonHeight = buttonHeight;
    self.buttonPerRow = buttonPerRow;
    self.gap = gap;
    self.fromOffsetY = fromOffsetY + 24;
    self.buttons = {};
    self.anchorTo = anchorTo;
    self.container = CreateFrame("Frame", nil, parent);
    --self.container:Hide();
    --self.container:SetAlpha(0);

    local col, row = 1, 1;
    local b;

    for i = 1, #data do
        self.buttons[i] = CreateFrame("Button", nil, self.container, "NarciMinimapSkinOptionTemplate");
        b = self.buttons[i];
        if col > buttonPerRow then
            col = 1;
            row = row + 1;
        end
        b:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", PADDING_H + (i - 1) * (buttonWidth + gap), fromOffsetY - (row - 1)*(buttonHeight + gap));
        b:SetScript("OnEnter", self.OnEnter);
        b:SetScript("OnLeave", self.OnLeave);
        b:SetScript("OnClick", self.OnClick);
        b.AnimDelay:SetScript("OnFinished", self.OnDelayFinished)
        b.skinID = i;
        b.NormalTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\"..data[i][1]);
        b.HighlightTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\"..data[i][1]);
        b.SkinName:SetText(data[i][2]);
        SetTextColorByID(b.SkinName, 2);
        col = col + 1;
    end

    MinimapButtonSkin:UpdateAlignment();

    tinsert(OptionButtons, MinimapButtonSkin);

    local newHeight = row * (buttonHeight + gap) - gap;
    local newObj = self.container;

    newObj.UpdateState = function()
        MinimapButtonSkin:UpdateState();
    end

    return newHeight, newObj
end

function MinimapButtonSkin:UpdateAlignment()
    if not self.buttonWidth then return end;
    local parentWidth = MainFrame.ScrollFrame:GetWidth();
    --local gap = (parentWidth - 2 * PADDING_H)/self.buttonPerRow;
    local gap = (parentWidth - 2 * 30 - (self.buttonWidth*self.buttonPerRow))/(self.buttonPerRow - 1);
    if gap > 48 then
        gap = 48;
    end

    local fromOffsetX = 0.5*(parentWidth - (self.buttonPerRow * (self.buttonWidth + gap) - gap) );
    local col, row = 1, 0;

    for i, b in ipairs(self.buttons) do
        if col > self.buttonPerRow then
            col = 1;
            row = row + 1;
        end
        b:ClearAllPoints();
        b:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", fromOffsetX + (i - 1) * (self.buttonWidth + gap), self.fromOffsetY - row*(self.buttonHeight + gap));
    end
end

function MinimapButtonSkin:UpdateState()
    local skinID = NarcissusDB.MinimapIconStyle;
    if not skinID then
        skinID = 0;
    end
    for i, b in ipairs(self.buttons) do
        b.Selection:SetShown(i == skinID);
    end
end

local function UseAddonCompartment_OnValueChanged(self, state)
    NarciAPI.AddToAddonCompartment(state);      --Defined in MinimapButton.lua
end

local function MinimapButtonToggle_OnValueChanged(self, state)
    SettingFunctions.ShowMinimapButton(state);
    if state then
        Narci_MinimapButton:PlayBling();
    end
end

local function MinimapButtonFadeOut_OnValueChanged(self, state)
    SettingFunctions.FadeOutMinimapButton(state);
end

local function Minimap_HandledByLeatrix()
    return not NarciAPI.IsLeatrixMinimapEnabled()
end

--[[
local function MinimapButtonLibDBIcon_OnValueChanged(self, state)
    if not Narci_MinimapButton:HasLibDBIcon() then return end

    NarcissusDB.UseLibDBIcon = state;
    Narci_MinimapButton:ResolveVisibility();
end
--]]


local LanguageSelector = {};

function LanguageSelector:CreateFrame()
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, MainFrame.ScrollFrame);
        local f = self.frame;
        f:Hide();
        f:SetSize(400, 300);
        local frameLevel = 10;
        f:SetPoint("CENTER", MainFrame.ScrollFrame, "CENTER", 0, 0);
        f:SetFrameLevel(frameLevel);
        f.BorderFrame = CreateFrame("Frame", nil, f);
        f.BorderFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
        f.BorderFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0);
        f.BorderFrame:SetFrameLevel(frameLevel + 6);
        f.BackgroundFrame = CreateFrame("Frame", nil, f);
        f.BackgroundFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
        f.BackgroundFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
        f.BackgroundFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0);
        f.BackgroundFrame:SetFrameLevel(frameLevel - 2);
        NarciAPI.NineSliceUtil.SetUp(f.BorderFrame, "settingsBorder", "backdrop");
        NarciAPI.NineSliceUtil.SetUp(f.BackgroundFrame, "settingsBackground", "backdrop");

        self.header = f:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        self.header:SetJustifyH("CENTER");
        self.header:SetPoint("TOP", f, "TOP", 0, -PADDING_V);
        SetTextColorByID(self.header, 1);

        f:SetScript("OnShow", function()
            f:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end);

        f:SetScript("OnHide", function()
            f:UnregisterEvent("GLOBAL_MOUSE_DOWN");
            f:Hide();
        end);

        f:SetScript("OnEvent", function()
            if not f:IsMouseOver() then
                f:Hide();
            end
        end);

        f:SetScript("OnMouseWheel", function()
            f:Hide();
        end)

        f:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                f:Hide();
            end
        end)

        local gameLocale = GetLocale();
    
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

        local MIN_LABEL_WIDTH = 74;
        local MAX_ROW = math.ceil(#LANGUAGES / 2);
        local row = 0;
        local col = 0;
        local offsetX = PADDING_H + BUTTON_LEVEL_OFFSET;
        local offsetY = -24 - WIDGET_GAP;

        self.choiceButtons = {};

        local maxLabelThisCol = MIN_LABEL_WIDTH;
        local labelWidth, buttonWidth;
        local lastColButtonIndex;
        local choiceButton;
    
        for i, languageData in ipairs(LANGUAGES) do
            row = row + 1;
            if row > MAX_ROW then
                col = col + 1;
                row = 1;
                buttonWidth = Round0(maxLabelThisCol + 22);
                for j = i-1, i-MAX_ROW, -1 do
                    self.choiceButtons[j]:SetWidth(buttonWidth);
                end
                offsetX = offsetX + buttonWidth + 24 + 0.5*WIDGET_GAP;
                maxLabelThisCol = MIN_LABEL_WIDTH;
                lastColButtonIndex = i;
            end
            self.choiceButtons[i] = CreateFrame("Button", nil, f, "NarciSettingsSharedButtonTemplate");
            choiceButton = self.choiceButtons[i];
            choiceButton:SetPoint("TOPLEFT", f, "TOPLEFT", offsetX, offsetY - (row - 1) * (24 + 0.5*WIDGET_GAP));
            choiceButton.locale = languageData[1];
            choiceButton.Label:SetText(languageData[2]);
            choiceButton:SetScript("OnClick", self.ChoiceButton_OnClick);

            labelWidth = choiceButton.Label:GetWrappedWidth();
            if labelWidth > maxLabelThisCol then
                maxLabelThisCol = labelWidth;
            end

            if languageData[1] == gameLocale then
                choiceButton:Disable();
                choiceButton.alwaysOn = true;
            end
        end

        buttonWidth = Round0(maxLabelThisCol + 22);
        for j = lastColButtonIndex, #self.choiceButtons do
            self.choiceButtons[j]:SetWidth(buttonWidth);
        end
        local frameWidth = math.max( (offsetX + buttonWidth + PADDING_H + BUTTON_LEVEL_OFFSET), Round0(self.header:GetWrappedWidth() + 2*PADDING_H) );
        local frameHeight = 36 + WIDGET_GAP + MAX_ROW * (24 + 0.5*WIDGET_GAP);
        f:SetSize(frameWidth, frameHeight);
    end
end

function LanguageSelector:ShowSelector()
    self:CreateFrame();

    local isSingleChoice = DB.NameTranslationPosition == 2;

    if isSingleChoice ~= self.isSingleChoice then
        self.isSingleChoice = isSingleChoice;
        local buttonType;
        if isSingleChoice then
            self.header:SetText(L["Select Language Single"]);
            buttonType = "radio";
        else
            self.header:SetText(L["Select Language Multiple"]);
            buttonType = "checkbox";
        end

        for i, button in ipairs(self.choiceButtons) do
            button:SetButtonType(buttonType, true);
            if button.alwaysOn then
                SetTextColorByID(button.Label, 1);
                SetTextureColorByID(button.Selection, 1);
                SetTextureColorByID(button.Border, 1);
                button.Selection:Hide();
            end
        end
    end

    self.frame:Show();
    self:UpdateSelection();
end

function LanguageSelector:ToggleSelector()
    if self.frame then
        self.frame:SetShown(not self.frame:IsShown());
    end
end

function LanguageSelector:UpdateSelection()
    local languageText;
    local isSingleChoice = DB.NameTranslationPosition == 2;

    if self.choiceButtons then
        if isSingleChoice then
            local locale = DB.NamePlateLanguage;
            for i, button in ipairs(self.choiceButtons) do
                if button.alwaysOn then
                    button:SetState(false);
                else
                    button:SetState(button.locale == locale);
                end
            end
            languageText = locale;
        else
            local count = 0;
            local isSelected;
            for i, button in ipairs(self.choiceButtons) do
                if not button.alwaysOn then
                    isSelected = DB.TooltipLanguages[button.locale];
                    button:SetState(isSelected);
                    if isSelected then
                        count = count + 1;
                        if count <= 3 then
                            if languageText then
                                languageText = languageText..", "..button.locale;
                            else
                                languageText = button.locale;
                            end
                        end
                    end
                end
            end
            if count > 3 then
                languageText = languageText..", +"..(count - 3);
            end
        end
    else

        if isSingleChoice then
            local locale = DB.NamePlateLanguage;
            if locale then
                languageText = locale;
            end
        else
            local count = 0;
            for locale, state in pairs(DB.TooltipLanguages) do
                if state then
                    count = count + 1;
                    if count <= 3 then
                        if languageText then
                            languageText = languageText..", "..locale;
                        else
                            languageText = locale;
                        end
                    end
                    if count > 3 then
                        languageText = languageText..", +"..(count - 3);
                    end
                end
            end
        end
    end

    if self.toggle then
        if languageText then
            self.toggle.Label:SetText(languageText);
        else
            self.toggle.Label:SetText(NONE);
        end
    end
end

function LanguageSelector.SetupToggle(f)
    LanguageSelector.toggle = f;

    f:SetScript("OnClick", function ()
        LanguageSelector:ShowSelector();
    end)

    function f:UpdateState()
        LanguageSelector:UpdateSelection();
    end

    f.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\OpenNewWindowButton");
    f.Border:SetTexCoord(0, 1, 0, 1);
    f.Selection:Hide();
    f.Selection:SetTexture(nil);
    f.Highlight:SetTexture(nil);
    f.Background:Hide();
    f.Background:SetTexture(nil);
end

function LanguageSelector:IsCreatureDatabaseLoaded(locale)
    locale = locale or "enUS";
    if NarciCreatureInfo and NarciCreatureInfo.isLanguageLoaded[locale] then
        return true
    else
        return false
    end
end

function LanguageSelector:AreRequiredDatabaseLoaded()
    local allLoaded = true;

    if DB.TranslateName then
        if DB.NameTranslationPosition == 2 then
            local locale = DB.NamePlateLanguage;
            allLoaded = self:IsCreatureDatabaseLoaded(locale);
        else
            local locales = DB.TooltipLanguages;
            for locale, state in pairs(locales) do
                if state then
                    allLoaded = allLoaded and self:IsCreatureDatabaseLoaded(locale);
                    if not allLoaded then
                        break
                    end
                end
            end
        end
    end

    if not allLoaded then
        return false
    end

    if DB.SearchRelatives then
        allLoaded = self:IsCreatureDatabaseLoaded("enUS");
    end

    return allLoaded
end


local function UpdateNPCSettings()
    if NarciCreatureInfo then
        NarciCreatureInfo.UpdateNPCSettings();
    end
end

local function CheckReloadRequirement()
    local allLoaded = LanguageSelector:AreRequiredDatabaseLoaded();
    if allLoaded then
        --AlertMessageFrame:Hide();
    else
        AlertMessageFrame:ShowRequiresReload();
    end
end


function LanguageSelector.ChoiceButton_OnClick(f)
    if LanguageSelector.isSingleChoice then
        DB.NamePlateLanguage = f.locale;
    else
        DB.TooltipLanguages[f.locale] = not DB.TooltipLanguages[f.locale];
    end
    LanguageSelector:UpdateSelection();
    CheckReloadRequirement();
end

local function TranslateNameToggle_OnValueChanged(self, state)
    UpdateNPCSettings();
    if state then
        CheckReloadRequirement();
    end
end

local function NameTranslationPosition_OnValueChanged(self, index)
    LanguageSelector:UpdateSelection();
    UpdateNPCSettings();
    CheckReloadRequirement();
end

local function NameTranslationPosition_Setup(lastRadioButton)
    local groupID = lastRadioButton.groupID;
    local buttons = WidgetGroups[groupID];
    if buttons then
        for i, button in ipairs(buttons) do
            if i == 2 then
                local f = CreateFrame("Frame", nil, button, "NarciSettingsSliderTemplate");
                local labelWidth = Round0(button.Label:GetWrappedWidth());
                f:SetPoint("TOPLEFT", button, "TOPLEFT", labelWidth, 0);
                f.Label:SetText(L["Offset Y"]);
                SetTextColorByID(f.Label, 2);
                local slider = f.Slider;
                SetTextColorByID(slider.ValueText, 2);
                slider.key = "NamePlateNameOffset";
                slider.valueFormatFunc = Round0;
                slider.convertionFunc = Round0;
                slider:SetMinMaxValues(-20, 20);
                slider:SetObeyStepOnDrag(false);
                slider.onValueChangedFunc = function(self, value)
                    if NarciCreatureInfo then
                        NarciCreatureInfo.SetNamePlateNameOffset(value);
                    end
                end;
                slider.getValueFunc = function()
                    return tonumber(DB.NamePlateNameOffset) or 0
                end;
                slider:SetSliderWidth(96, true);
                slider:SetValue( slider.getValueFunc() );
                f.Label:ClearAllPoints();
                f.Label:SetPoint("BOTTOM", slider, "TOP", 0, 2);
                f.Label:SetJustifyH("CENTER");

                button.children = {};
                button.children[1] = f;
            end
        end
    end
end

local function SearchRelativesToggle_OnValueChanged(self, state)
    if state then
        CheckReloadRequirement();
    end
    UpdateNPCSettings();
end



local function UpdateAlignment()
    MinimapButtonSkin:UpdateAlignment();
    CreditList:UpdateAlignment();
    AboutTab:UpdateWebsiteButtons();
end

local function AddObjectAsChild(childObject, isTextObject)
    local parentObj;
    local i;

    if isTextObject then
        i = #AllObjects;
    else
        i = #AllObjects;
    end
    parentObj = AllObjects[i];

    while parentObj and parentObj.isChild do
        i = i - 1;
        parentObj = AllObjects[i];
    end

    if parentObj then
        if not parentObj.children then
            parentObj.children = {};
        end
        tinsert(parentObj.children, childObject);
        childObject.isChild = true;
        --print(childObject.widgetType, childObject.key, parentObj.key)
    end
end

local function CreateWidget(parent, anchorTo, offsetX, offsetY, widgetData)
    if widgetData.validityCheckFunc then
        if not widgetData.validityCheckFunc() then
            return nil, 0
        end
    end

    local height;
    local widgetType = widgetData.type;
    local obj;


    local isTextObject;
    if widgetType == "header" or widgetType == "subheader" then
        height = 12;
        isTextObject = true;
    else
        height = 24;
    end

    if widgetData.extraTopPadding then
        local extraOffset = WIDGET_GAP * widgetData.extraTopPadding;
        offsetY = offsetY - extraOffset;
        height = height + extraOffset;
    end

    if widgetData.isNew then
        if widgetData.text then
            widgetData.text = NARCI_NEW_ENTRY_PREFIX..widgetData.text.."|r"
        end
    end

    if isTextObject then
        obj = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        obj.widgetType = widgetType;

        if widgetData.alignToCenter then
            obj:SetPoint("TOP", anchorTo, "TOP", 0, offsetY);
            obj:SetJustifyH("CENTER");
        else
            obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * BUTTON_LEVEL_OFFSET) or 0), offsetY);
            obj:SetJustifyH("LEFT");
        end

        obj:SetJustifyV("TOP");
        SetTextColorByID(obj, 1);
        height = height + WIDGET_GAP;

        if widgetType == "header" then
            obj:SetText(string.upper(widgetData.text));
        else
            obj:SetText(widgetData.text);
        end
    
    elseif widgetType == "radio" then
        local numButtons = #widgetData.texts;

        local preview;
        local sectorHeight;

        local groupID = #WidgetGroups + 1;
        WidgetGroups[groupID] = {};

        for i = 1, numButtons do
            obj = CreateFrame("Button", nil, parent, "NarciSettingsSharedButtonTemplate");
            tinsert(OptionButtons, obj);
            obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * BUTTON_LEVEL_OFFSET) or 0), offsetY + (1 - i) * (24 + 0.5*WIDGET_GAP));
            obj:SetButtonType("radio");
            obj.groupID = groupID;
            obj.id = i;
            obj.key = widgetData.key;
            obj.widgetType = widgetType;
            obj:SetLabelText(widgetData.texts[i]);

            if widgetData.previewImage and not preview then
                preview = obj:CreateTexture(nil, "ARTWORK");
                preview:SetSize(widgetData.previewWidth, widgetData.previewHeight);
                preview:SetPoint("TOPRIGHT", anchorTo, "TOPRIGHT", -24, offsetY + (widgetData.previewOffsetY or 0));
                preview:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\"..widgetData.previewImage);
                sectorHeight = widgetData.previewHeight - (widgetData.previewOffsetY or 0);
            end
            obj.preview = preview;
            SetTextColorByID(obj.Label, 2);
            WidgetGroups[groupID][i] = obj;
            obj.onValueChangedFunc = widgetData.onValueChangedFunc;
            if widgetData.isChild then
                AddObjectAsChild(obj);
            end
            obj.onEnterFunc = widgetData.onEnterFunc;
            obj.onLeaveFunc = widgetData.onLeaveFunc;

            if widgetData.showFeaturePreview then
                obj.previewKey = widgetData.key..i;
            end
        end

        height = (24 + 0.5*WIDGET_GAP) * numButtons;
        if sectorHeight and height < sectorHeight then
            height = sectorHeight;
        end
        height = height + WIDGET_GAP;

    elseif widgetType == "checkbox" then
        obj = CreateFrame("Button", nil, parent, "NarciSettingsSharedButtonTemplate");
        tinsert(OptionButtons, obj);
        obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * BUTTON_LEVEL_OFFSET) or 0), offsetY);
        obj:SetButtonType("checkbox");
        obj.key = widgetData.key;
        obj.widgetType = widgetType;
        obj:SetLabelText(widgetData.text);
        SetTextColorByID(obj.Label, 2);
        obj.onValueChangedFunc = widgetData.onValueChangedFunc;

        if widgetData.description then
            local desc = obj:CreateFontString(nil, "OVERLAY", "NarciFontThin13");
            obj.description = desc;
            SetTextColorByID(desc, 1);
            desc:SetSpacing(4);
            desc:SetJustifyH("LEFT");
            desc:SetJustifyV("TOP");
            desc:SetPoint("TOPLEFT", obj.Label, "BOTTOMLEFT", 0, -6);
            desc:SetWidth(300);
            desc:SetText(widgetData.description);

            local extraHeight = obj:GetBottom() - desc:GetBottom();
            extraHeight = Round0(extraHeight);
            height = height + extraHeight;
        end

        height = height + WIDGET_GAP;

        if widgetData.showFeaturePreview then
            obj.previewKey = widgetData.key;
        end

    elseif widgetType == "slider" then
        obj = CreateFrame("Frame", nil, parent, "NarciSettingsSliderTemplate");
        local slider = obj.Slider;
        tinsert(OptionButtons, slider);
        obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * BUTTON_LEVEL_OFFSET) or 0), offsetY);
        SetTextColorByID(obj.Label, 2);
        SetTextColorByID(slider.ValueText, 2);
        obj.Label:SetText(widgetData.text);
        obj.widgetType = widgetType;
        slider.key = widgetData.key;
        slider.valueFormatFunc = widgetData.valueFormatFunc;
        slider.convertionFunc = widgetData.convertionFunc;
        slider:SetMinMaxValues(widgetData.minValue, widgetData.maxValue);

        if widgetData.valueStep then
            slider:SetValueStep(widgetData.valueStep);
            slider:SetObeyStepOnDrag(true);
        else
            slider:SetObeyStepOnDrag(false);
        end

        slider.onValueChangedFunc = widgetData.onValueChangedFunc;
        slider.getValueFunc = widgetData.getValueFunc;
    
        if widgetData.sliderWidth then
            slider:SetSliderWidth(widgetData.sliderWidth, true);
        end

        height = height + WIDGET_GAP;

        --local left = MainFrame.ScrollFrame:GetLeft();
        --local right = slider:GetRight() + PADDING_H;
        --print(left - right);
    elseif widgetType == "keybinding" then
        obj = CreateFrame("Button", nil, parent, "NarciSettingsKeybindingButtonTemplate");
        tinsert(OptionButtons, obj);
        obj:SetPoint("TOP", anchorTo, "TOP", (widgetData.level and widgetData.level * BUTTON_LEVEL_OFFSET) or 0, offsetY);
        obj.Label:SetText(widgetData.text);
        obj.widgetType = widgetType;
        if widgetData.externalAction then
            obj:SetExternalAction(widgetData.externalAction);
        else
            obj:SetInternalAction(widgetData.internalAction);
        end
        height = 24 + WIDGET_GAP;
    end

    if widgetType ~= "radio" then
        obj.onEnterFunc = widgetData.onEnterFunc;
        obj.onLeaveFunc = widgetData.onLeaveFunc;
        if widgetData.isChild then
            AddObjectAsChild(obj, isTextObject);
        end
    end

    tinsert(AllObjects, obj);

    if widgetData.setupFunc then
        local extraHeight, newObject = widgetData.setupFunc(obj, parent, anchorTo, offsetY - height);
        if extraHeight then
            height = height + extraHeight;
        end
        if newObject and widgetData.isChild then
            if not newObject.UpdateState then
                newObject.UpdateState = function() end;
            end
            AddObjectAsChild(newObject);
            tinsert(AllObjects, newObject);
        end
    end

    return obj, Round0(height)
end


local Categories = {
    --{ CategoryName }
    {name = L["Character Panel"], level = 0, key = "characterPanel",
        widgets = {
            {type = "header", level = 0, text = L["Character Panel"]},
            {type = "slider", level = 1, key = "GlobalScale", text = UI_SCALE, onValueChangedFunc = CharacterUIScale_OnValueChanged, minValue = 0.7, maxValue = 1, valueStep = 0.1, },
            {type = "slider", level = 1, key = "BaseLineOffset", text = L["Baseline Offset"], validityCheckFunc = IsUsingUltraWideMonitor, onValueChangedFunc = UltraWideOffset_OnValueChanged, minValue = 0, maxValue = ULTRAWIDE_MAX_OFFSET, valueStep = ULTRAWIDE_STEP, },
            {type = "checkbox", level = 1, key = "MissingEnchantAlert", text = L["Missing Enchant Alert"], onValueChangedFunc = ShowMisingEnchantAlert_OnValueChanged, validityCheckFunc = ShowMisingEnchantAlert_IsValid, isNew = false},
            {type = "checkbox", level = 1, key = "DetailedIlvlInfo", text = L["Show Detailed Stats"], onValueChangedFunc = ShowDetailedStats_OnValueChanged},
            {type = "checkbox", level = 1, key = "AFKScreen", text = L["AFK Screen Description"], onValueChangedFunc = AFKToggle_OnValueChanged, },
                {type = "checkbox", level = 3, key = "AKFScreenDelay", text = L["AFK Screen Delay"], onValueChangedFunc = nil, isChild = true},
            {type = "subheader", level = 1, text = L["Item Names"], extraTopPadding = 1},
            {type = "slider", level = 1, key = "FontHeightItemName", text = FONT_SIZE, onValueChangedFunc = ItemNameHeight_OnValueChanged, minValue = 10, maxValue = 12, valueStep = 1, },
            {type = "slider", level = 1, key = "ItemNameWidth", text = L["Text Width"], onValueChangedFunc = ItemNameWidth_OnValueChanged, minValue = 100, maxValue = 200, valueStep = 20, },
            {type = "checkbox", level = 1, key = "TruncateText", text = L["Truncate Text"], onValueChangedFunc = TruncateTextToggle_OnValueChanged},
        },
    },

    {name = L["Hotkey"], level = 1, key = "hotkey",
        widgets = {
            {type = "header", level = 0, text = L["Hotkey"]},
            {type = "keybinding", level = 1, text = L["Open Narcissus"], externalAction = BIND_ACTION_NARCISSUS},
            {type = "checkbox", level = 1, key = "EnableDoubleTap", extraTopPadding = 1, text = L["Double Tap"], description = L["Double Tap Description"], onValueChangedFunc = DoubleTap_OnValueChanged, setupFunc = DoubleTap_Setup},
            {type = "checkbox", level = 1, key = "UseEscapeButton", text = L["Use Escape Button"], description = L["Use Escape Button Description"], onValueChangedFunc = UseEscapeKey_OnValueChanged},
        },
    },

    {name = L["Item Tooltip"], level = 1, key = "itemTooltip",
        widgets = {
            {type = "header", level = 0, text = L["Item Tooltip"]},
            {type = "subheader", level = 1, text= L["Style"]},
            {type = "radio", level = 1, key = "ItemTooltipStyle", texts = {L["Tooltip Style 1"], L["Tooltip Style 2"]}, onValueChangedFunc = ItemTooltipStyle_OnValueChanged, onEnterFunc = ItemTooltipStyle_OnEnter, onLeaveFunc = ItemTooltipStyle_OnLeave},
            {type = "subheader", level = 1, text = L["Addtional Info"], extraTopPadding = 0},
            {type = "checkbox", level = 1, key = "ShowItemID", text = L["Item ID"], onValueChangedFunc = ItemTooltipShowItemID_OnValueChanged},
        },
    },

    {name = L["Screen Effects"], level = 1, key = "screenEffects",
        widgets = {
            {type = "header", level = 0, text = L["Screen Effects"]},
            {type = "slider", level = 1, key = "VignetteStrength", text =  L["Vignette Strength"], valueFormatFunc = Round1, convertionFunc = Round1, onValueChangedFunc = VignetteStrength_OnValueChanged, minValue = 0, maxValue = 1, valueStep = nil, },
            {type = "checkbox", level = 1, key = "WeatherEffect", text = L["Weather Effect"], onValueChangedFunc = WeatherEffectToggle_OnValueChanged},
            {type = "checkbox", level = 1, key = "LetterboxEffect", text = L["Letterbox"], validityCheckFunc = Letterbox_IsCompatible, onValueChangedFunc = LetterboxToggle_OnValueChanged},
                {type = "slider", level = 3, key = "LetterboxRatio", text = L["Letterbox Ratio"], validityCheckFunc = Letterbox_IsCompatible, isChild = true, onValueChangedFunc = LetterboxRatio_OnValueChanged, minValue = 2, maxValue = 2.35, valueStep = 0.35, sliderWidth = 64, valueFormatFunc = ValueFormat_LetterboxRatio, },
        },
    },

    {name = L["Camera"], level = 1, key = "camera",
        widgets = {
            {type = "header", level = 0, text = L["Camera"]},
            {type = "checkbox", level = 1, key = "CameraTransition", text = L["Camera Transition"], onValueChangedFunc = CameraTransition_OnValueChanged, description = L["Camera Transition Description Off"], setupFunc = CameraTransition_SetupDescription},
            {type = "checkbox", level = 1, key = "CameraOrbit", text = L["Orbit Camera"], onValueChangedFunc = CameraOrbitToggle_OnValueChanged, description = L["Orbit Camera Description On"], setupFunc = CameraOrbitToggle_SetupDescription},
            {type = "checkbox", level = 1, key = "CameraSafeMode", text = L["Camera Safe Mode"], onValueChangedFunc = CameraSafeToggle_OnValueChanged, description = L["Camera Safe Mode Description"], validityCheckFunc = CameraSafeToggle_IsValid},
            {type = "checkbox", level = 1, key = "UseBustShot", text = L["Use Bust Shot"], onValueChangedFunc = CameraUseBustShot_OnValueChanged},
        },
    },

    {name = L["Minimap Button"], level = 0, key = "minimapButton",
        widgets = {
            {type = "header", level = 0, text = L["Minimap Button"]},
            {type = "checkbox", level = 1, key = "UseAddonCompartment", text = L["Add To AddOn Compartment"], onValueChangedFunc = UseAddonCompartment_OnValueChanged},
            {type = "checkbox", level = 1, key = "ShowMinimapButton", text = L["Show Minimap Button"], onValueChangedFunc = MinimapButtonToggle_OnValueChanged},
                {type = "checkbox", level = 3, customButtonScript = true, text = RESET_POSITION or "Reset Position", isChild = true, setupFunc = ResetMinimapPosition_Setup, validityCheckFunc = Minimap_HandledByLeatrix},
                {type = "checkbox", level = 3, key = "ShowModulePanelOnMouseOver", text = L["Show Module Panel Gesture"], isChild = true, onValueChangedFunc = ShowMinimapModulePanel_OnValueChanged, validityCheckFunc = Minimap_HandledByLeatrix},
                {type = "checkbox", level = 3, key = "IndependentMinimapButton", text = L["Independent Minimap Button"], isChild = true, onValueChangedFunc = IndependentMinimapButtonToggle_OnValueChanged, validityCheckFunc = Minimap_HandledByLeatrix},
                {type = "checkbox", level = 3, key = "FadeButton", text = L["Fade Out Description"], isChild = true, onValueChangedFunc = MinimapButtonFadeOut_OnValueChanged, validityCheckFunc = Minimap_HandledByLeatrix},
                {type = "subheader", level = 3, text = L["Style"], extraTopPadding = 1, isChild = true, setupFunc = MinimapButtonSkin.CreateOptions, validityCheckFunc = Minimap_HandledByLeatrix},
                --{type = "checkbox", level = 3, extraTopPadding = 2, key = "UseLibDBIcon", text = L["MinimapButton LibDBIcon"], description = L["MinimapButton LibDBIcon Desc"], isChild = true, onValueChangedFunc = MinimapButtonLibDBIcon_OnValueChanged, validityCheckFunc = function() return Narci_MinimapButton:HasLibDBIcon() end},
        },
    },

    {name = L["Photo Mode"], level = 0, key = "photoMode",
        widgets = {
            {type = "header", level = 0, text = L["Photo Mode"]},
            {type = "checkbox", level = 1, key = "LoopAnimation", text = L["Loop Animation"], onValueChangedFunc = LoopAnimation_OnValueChanged},
            {type = "slider", level = 1, key = "screenshotQuality", text = L["Sceenshot Quality"], onValueChangedFunc = ScreenshotQuality_OnValueChanged, minValue = 3, maxValue = 10, getValueFunc = ScreenshotQuality_GetValue, valueFormatFunc = Round0, convertionFunc = Round0},
            {type = "subheader", level = 1, text = L["Screenshot Quality Description"]},
            {type = "slider", level = 1, key = "ModelPanelScale", text = L["Panel Scale"], onValueChangedFunc = ModelPanelScale_OnValueChanged, minValue = 0.8, maxValue = 1, valueStep = 0.1, extraTopPadding = 1, valueFormatFunc = Round1},
            {type = "slider", level = 1, key = "ShrinkArea", text = L["Interactive Area"], onValueChangedFunc = ModelHitRectShrinkage_OnValueChanged, minValue = 0, maxValue = MAX_MODEL_SHRINKAGE, valueFormatFunc = GetOppositeValue, convertionFunc = Round0},
            {type = "checkbox", level = 1, key = "SpeedyScreenshotAlert", text = L["Speedy Screenshot Alert"], onValueChangedFunc = SpeedyScreenshotAlert_OnValueChanged},
        },
    },

    {name = "NPC", level = 0,  key = "npc",
        widgets = {
            {type = "header", level = 0, text = L["Creature Tooltip"]},
            {type = "checkbox", level = 1, key = "SearchRelatives", text = L["Find Relatives"], onValueChangedFunc = SearchRelativesToggle_OnValueChanged, },
            {type = "checkbox", level = 1, key = "TranslateName", text = L["Translate Names"], onValueChangedFunc = TranslateNameToggle_OnValueChanged, },
                {type = "subheader", level = 3, text = L["Translate Names Description"], extraTopPadding = 0, isChild = true},
                {type = "radio", level = 3, key = "NameTranslationPosition", texts = {L["Tooltip"], L["Name Plate"]}, isChild = true, onValueChangedFunc = NameTranslationPosition_OnValueChanged, showFeaturePreview = true, onEnterFunc = FeaturePreview.ShowPreview, onLeaveFunc = FeaturePreview.HidePreview, setupFunc = NameTranslationPosition_Setup},
                {type = "subheader", level = 3, text = L["Translate Names Languages"], extraTopPadding = 0, isChild = true},
                {type = "checkbox", level = 3, text = "Select Languages", isChild = true, setupFunc = LanguageSelector.SetupToggle},
        },
    },

    {name = L["Extensions"], level = 0, key = "extensions",
        widgets = {
            {type = "header", level = 0, text = L["Extensions"]},
            {type = "checkbox", level = 1, key = "GemManager", text = L["Gem List"], onValueChangedFunc = GemManagerToggle_OnValueChanged, description = L["Gemma Description"]},
            {type = "checkbox", level = 1, key = "DressingRoom", text = L["Dressing Room"], onValueChangedFunc = DressingRoomToggle_OnValueChanged, description = L["Dressing Room Description"]},
            {type = "checkbox", level = 1, key = "SoloQueueLFRDetails", text = L["LFR Wing Details"], onValueChangedFunc = LFRWingDetails_OnValueChanged, description = L["LFR Wing Details Description"]},
            {type = "subheader", level = 1, text = L["Expansion Features"], extraTopPadding = 1},
            {type = "checkbox", level = 1, key = "PaperDollWidget", text = L["Paperdoll Widget"], onValueChangedFunc = PaperDollWidgetToggle_OnValueChanged, showFeaturePreview = true, onEnterFunc = FeaturePreview.ShowPreview, onLeaveFunc = FeaturePreview.HidePreview},
                {type = "checkbox", level = 2, key = "PaperDollWidget_ClassSet", text = L["Class Set Indicator"], isChild = true, onValueChangedFunc = PaperDollWidget_Update},
                {type = "checkbox", level = 2, key = "PaperDollWidget_Remix", text = L["Remix Gem Manager"], isChild = true, onValueChangedFunc = PaperDollWidget_Update},
            --{type = "checkbox", level = 1, key = "ConduitTooltip", text = L["Conduit Tooltip"], onValueChangedFunc = ConduitTooltipToggle_OnValueChanged, showFeaturePreview = true, onEnterFunc = FeaturePreview.ShowPreview, onLeaveFunc = FeaturePreview.HidePreview},
        },
    },



    {name = L["Credits"], level = 0, key = "credits", isBottom = true},
    {name = L["About"], level = 0, key = "about",  isBottom = true,
        widgets = {
            {type = "header", level = 0, text = L["About"]},
        },
    },
};

local function InsertCategory(newCategory)
    tinsert(Categories, #Categories -1, newCategory);
end

if IS_DRAGONFLIGHT then
    local function ShowTreeCase1(self, state)
        SettingFunctions.ShowMiniTalentTreeForPaperDoll(state);
    end

    local function ShowTreeCase2(self, state)
        SettingFunctions.ShowMiniTalentTreeForInspection(state);
    end

    local function ShowTreeCase3(self, state)
        SettingFunctions.ShowMiniTalentTreeForEquipmentManager(state);
    end

    local function TalentTreeSetPosition(self, id)
        SettingFunctions.SetTalentTreePosition(id);
    end

    local function TalentTreeUseClassBackground(self, state)
        SettingFunctions.SetUseClassBackground(state);
    end

    local function TalentTreeUseBiggerUI(self, state)
        SettingFunctions.SetUseBiggerUI(state);
    end

    local talentCategory = {name = TALENTS or "Talents", level = 1, key = "talents",
        widgets = {
            {type = "header", level = 0, text = L["Mini Talent Tree"]},
            {type = "subheader", level = 1, text = L["Show Talent Tree When"]},
            {type = "checkbox", level = 1, key = "TalentTreeForPaperDoll",text = L["Show Talent Tree Paperdoll"], onValueChangedFunc = ShowTreeCase1},
            {type = "checkbox", level = 1, key = "TalentTreeForInspection", text = L["Show Talent Tree Inspection"],  onValueChangedFunc = ShowTreeCase2},
            {type = "checkbox", level = 1, key = "TalentTreeForEquipmentManager", text = L["Show Talent Tree Equipment Manager"],  onValueChangedFunc = ShowTreeCase3},

            {type = "subheader", level = 1, text = L["Place UI"], extraTopPadding = 1},
            {type = "radio", level = 1, key = "TalentTreeAnchor", texts = {L["Place Talent UI Right"], L["Place Talent UI Bottom"]},  onValueChangedFunc = TalentTreeSetPosition},

            {type = "subheader", level = 1, text = L["Appearance"], extraTopPadding = 1},
            {type = "checkbox", level = 1, key = "TalentTreeUseClassBackground", text = L["Use Class Background"],  onValueChangedFunc = TalentTreeUseClassBackground},
            {type = "checkbox", level = 1, key = "TalentTreeBiggerUI", text = L["Use Bigger UI"],  onValueChangedFunc = TalentTreeUseBiggerUI},
        }
    };

    InsertCategory(talentCategory);

    
    local function NarciBagItemFilter_LoadAddOn()
        if not NarciBagItemFilterSettings then
            C_AddOns.LoadAddOn("Narcissus_BagFilter");
        end
    end

    local function ItemSearchToggle_OnValueChanged(self, state)
        if state then
            NarciBagItemFilter_LoadAddOn();
        end

        if NarciBagItemFilterSettings then
            NarciBagItemFilterSettings.SetEnableSearchSuggestion(state);
        end
    end
    
    local function ItemSearchDirectionButton_OnValueChanged(self, id)
        NarciBagItemFilterSettings.SetItemSearchPopupDirection(id);
        if id == 1 then
            self.preview:SetTexCoord(0, 0.5, 0, 0.8125);
        else
            self.preview:SetTexCoord(0.5, 1, 0, 0.8125);
        end
    end
    
    local function ItemSearchDirection_Setup(radioButton)
        if radioButton.preview then
            if DB and DB.SearchSuggestDirection == 2 then
                radioButton.preview:SetTexCoord(0.5, 1, 0, 0.8125);
            else
                radioButton.preview:SetTexCoord(0, 0.5, 0, 0.8125);
            end
        end
    end

    local function AutoFilterMail_OnValueChanged(self, state)
        NarciBagItemFilterSettings.AutoFilterMail(state);
    end
    
    local function AutoFilterAuction_OnValueChanged(self, state)
        NarciBagItemFilterSettings.AutoFilterAuction(state);
    end
    
    local function AutoFilterGem_OnValueChanged(self, state)
        NarciBagItemFilterSettings.AutoFilterGem(state);
    end

    local function IsBagItemFilterAddOnLoaded()
        --return NarciBagItemFilterSettings ~= nil
        return true     --changed this module to load-on-demand, so we need to keep its settings visible
    end

    local bagCategory = {name = L["Bag Item Filter"], level = 1, key = "bagitemfilter", validityCheckFunc = IsBagItemFilterAddOnLoaded,
    widgets = {
        {type = "header", level = 0, text = L["Bag Item Filter"]},
        {type = "checkbox", level = 1, key = "SearchSuggestEnable", text = L["Bag Item Filter Enable"], onValueChangedFunc = ItemSearchToggle_OnValueChanged},
        {type = "subheader", level = 3, text = L["Place Window"], extraTopPadding = 1, isChild = true},
        {type = "radio", level = 3, key = "SearchSuggestDirection", texts = {L["Below Search Box"], L["Above Search Box"]}, onValueChangedFunc = ItemSearchDirectionButton_OnValueChanged, setupFunc = ItemSearchDirection_Setup,
            previewImage = "Preview-PopupPosition.png", previewWidth = 200, previewHeight = 162, previewOffsetY = 28, isChild = true
        },
        {type = "subheader", level = 3, text = L["Auto Filter Case"], extraTopPadding = 1, isChild = true},
        {type = "checkbox", level = 3, key = "AutoFilterMail", text = L["Send Mails"], onValueChangedFunc = AutoFilterMail_OnValueChanged, isChild = true},
        {type = "checkbox", level = 3, key = "AutoFilterAuction", text = L["Create Auctions"], onValueChangedFunc = AutoFilterAuction_OnValueChanged, isChild = true},
        {type = "checkbox", level = 3, key = "AutoFilterGem", text = L["Socket Items"], onValueChangedFunc = AutoFilterGem_OnValueChanged, isChild = true},
    }};

    InsertCategory(bagCategory);


    local function AutoDisplayQuestItemToggle_OnValueChanged(self, state)
        SettingFunctions.SetAutoDisplayQuestItem(state);
    end

    local function QuestCardStyleButton_OnValueChanged(self, id)
        if id == 2 then
            self.preview:SetTexCoord(0, 1, 0.375, 0.75);
        else
            self.preview:SetTexCoord(0, 1, 0, 0.375);
        end

        NarciQuestItemDisplay:SetTheme(id);
    end
    
    local function QuestCardStyle_Setup(radioButton)
        if radioButton.preview then
            if DB and DB.QuestCardTheme == 2 then
                radioButton.preview:SetTexCoord(0, 1, 0.375, 0.75);
            else
                radioButton.preview:SetTexCoord(0, 1, 0, 0.375);
            end
        end
    end

    local function QuestCardPositionButton_Setup(f)
        f:SetScript("OnClick", function ()
            NarciQuestItemDisplay:ChangePosition()
        end)

        function f:UpdateState()
            return
        end

        f.Border:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\FourWayArrow");
        f.Border:SetTexCoord(0, 1, 0, 1);
        f.Selection:Hide();
        f.Selection:SetTexture(nil);
        f.Highlight:SetTexture(nil);
        f.Background:Hide();
        f.Background:SetTexture(nil);
    end

    local questCategory = {name = TRANSMOG_SOURCE_2 or "Quest", level = 1, key = "quest",
    widgets = {
        {type = "header", level = 0, text = TRANSMOG_SOURCE_2 or "Quest"},
        {type = "checkbox", level = 1, key = "AutoDisplayQuestItem", text = L["Auto Display Quest Item"], onValueChangedFunc = AutoDisplayQuestItemToggle_OnValueChanged},
        {type = "subheader", level = 3, text = L["Appearance"], extraTopPadding = 1, isChild = true},
        {type = "radio", level = 3, key = "QuestCardTheme", texts = {L["Border Theme Bright"], L["Border Theme Dark"]}, onValueChangedFunc = QuestCardStyleButton_OnValueChanged, setupFunc = QuestCardStyle_Setup,
            previewImage = "Preview-QuestCardTheme.png", previewWidth = 200, previewHeight = 75, previewOffsetY = 10, isChild = true
        },
        {type = "checkbox", level = 3, text = L["Change Position"], isChild = true, setupFunc = QuestCardPositionButton_Setup},
    }};

    InsertCategory(questCategory);
end


local function SetupFrame()
    if CategoryButtons then return end;

    DB = NarcissusDB;

    local f = MainFrame;
    local texPath = "Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\";

    f.CategoryFrame:SetWidth(DEFAULT_LEFT_WIDTH);
    f.ScrollFrame.ScrollChild:SetWidth(DEFAULT_FRAME_WIDTH - DEFAULT_LEFT_WIDTH);

    f.Divider = f.OverlayFrame:CreateTexture(nil, "OVERLAY", nil, 1);
    f.Divider:SetPoint("TOP", f.CategoryFrame, "TOPRIGHT", 0, -1);
    f.Divider:SetPoint("BOTTOM", f.CategoryFrame, "BOTTOMRIGHT", 0, 1);
    f.Divider:SetWidth(32);
    f.Divider:SetTexture(texPath.."DividerVertical");

    NarciAPI.NineSliceUtil.SetUp(f.BorderFrame, "settingsBorder", "backdrop");
    NarciAPI.NineSliceUtil.SetUp(f.BackgroundFrame, "settingsBackground", "backdrop");
    NarciAPI.AddPixelPerfectTexture(f.BorderFrame, f.Divider, 32);

    local cateButtonHeight = 24;
    local numCate = #Categories;
    local bottomIndex = 0;
    local p = 0;    --numEffectiveCate
    local frameHeight = Round0(f.ScrollFrame:GetHeight());

    CategoryButtons = {};
    CategoryOffsets = {};
    CategoryTabs = {};
    OptionButtons = {};
    AllObjects = {};
    WidgetGroups = {};

    local obj;
    local height;
    local totalScrollHeight = PADDING_H;

    local cateHeight, totalCateHeight = 0, 0;

    for i, cateData in ipairs(Categories) do
        if (not cateData.validityCheckFunc) or (cateData.validityCheckFunc and cateData.validityCheckFunc()) then
            p = p + 1;
            obj = CreateFrame("Button", nil, f.CategoryFrame, "NarciSettingsCategoryButtonTemplate");
            CategoryButtons[p] = obj;
            CategoryOffsets[p] = totalScrollHeight - PADDING_H;
    
            obj.id = p;
            obj.level = cateData.level;
            obj.key = cateData.key;
    
            obj:SetScript("OnClick", CategoryButton_OnClick);
            obj:SetScript("OnEnter", CategoryButton_OnEnter);
            obj:SetScript("OnLeave", CategoryButton_OnLeave);
    
            obj:SetWidth(DEFAULT_LEFT_WIDTH);
            obj:SetHitRectInsets(0, 8, 0, 0);
            obj.ButtonText:SetPoint("LEFT", obj, "LEFT", PADDING_H + CATE_LEVEL_OFFSET*cateData.level, 0);
    
            SetTextColorByID(obj.ButtonText, 1);
    
            CategoryTabs[p] = CreateFrame("Frame", nil, f.ScrollFrame.ScrollChild);
    
            if cateData.isBottom then
                bottomIndex = bottomIndex + 1;
                obj:SetPoint("BOTTOMLEFT", f.CategoryFrame, "BOTTOMLEFT", 0, PADDING_V + (2 - bottomIndex) * cateButtonHeight);
                if cateData.key == "about" then
                    --About Tab
                else
                    --Credit List
                    totalScrollHeight = math.ceil(totalScrollHeight/frameHeight) * frameHeight;
                    totalScrollHeight = totalScrollHeight + WIDGET_GAP;
                    CategoryOffsets[p] = totalScrollHeight - PADDING_H;
    
                    height = CreditList:CreateList(CategoryTabs[p], f.ScrollFrame.ScrollChild, -totalScrollHeight);
                    totalScrollHeight = totalScrollHeight + height;
                end
            else
                obj:SetPoint("TOPLEFT", f.CategoryFrame, "TOPLEFT", 0, -PADDING_V -totalCateHeight);
            end
    
            cateHeight = CategoryButton_SetLabel(obj, cateData.name);
            totalCateHeight = totalCateHeight + cateHeight;
    
            if cateData.widgets then
                for j = 1, #cateData.widgets do
                    obj, height = CreateWidget(CategoryTabs[p], f.ScrollFrame.ScrollChild, PADDING_H, -totalScrollHeight, cateData.widgets[j]);
                    totalScrollHeight =  totalScrollHeight + height;
                    if obj then
                        obj.categoryID = p;
                    end
                end
            end
    
            if i == numCate then
                --About List
                AboutTab:CreateTab(CategoryTabs[p], f.ScrollFrame.ScrollChild, -totalScrollHeight);
            end
    
            totalScrollHeight = totalScrollHeight + CATE_OFFSET;
        end
    end

    CREDIT_TAB_ID = p - 1;

    --Close Button;
    local CloseButton = CreateFrame("Button", nil, f.OverlayFrame);
    f.CloseButton = CloseButton;
    CloseButton:SetSize(36, 36);
    CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0);

    CloseButton.Texture = CloseButton:CreateTexture(nil, "BACKGROUND");
    CloseButton.Texture:SetSize(36, 36);
    CloseButton.Texture:SetPoint("CENTER", CloseButton, "CENTER", 0, 0);
    CloseButton.Texture:SetTexture(texPath.."CloseButton");
    CloseButton.Texture:SetTexCoord(0, 0.375, 0, 0.75);

    CloseButton.Cross = CloseButton:CreateTexture(nil, "OVERLAY");
    CloseButton.Cross:SetSize(18, 18);
    CloseButton.Cross:SetPoint("CENTER", CloseButton, "CENTER", 0, 0);
    CloseButton.Cross:SetTexture(texPath.."CloseButton");
    CloseButton.Cross:SetTexCoord(0.8125, 1, 0, 0.375);

    CloseButton:SetScript("OnEnter", CloseButton_OnEnter);
    CloseButton:SetScript("OnLeave", CloseButton_OnLeave);
    CloseButton:SetScript("OnMouseDown", CloseButton_OnMouseDown);
    CloseButton:SetScript("OnMouseUp", CloseButton_OnMouseUp);
    CloseButton:SetScript("OnClick", CloseButton_OnClick);
    CloseButton_OnLeave(CloseButton);


    for _, button in pairs(OptionButtons) do
        button:UpdateState();
    end

    local enableSwipe = true;
    local useReachLimitAnimation = true;
    NarciAPI.CreateSmoothScroll(f.ScrollFrame, enableSwipe, useReachLimitAnimation);
    NUM_CATE = #CategoryOffsets;
    local scrollRange = CategoryOffsets[ NUM_CATE ];
    f.ScrollFrame:SetScrollRange(scrollRange);
    f.ScrollFrame:SetStepSize(80);
    f.ScrollFrame:SetSpeedMultiplier(0.2);
    f.ScrollFrame:SetOnValueChangedFunc(FindCurrentCategory);

    if not AlertMessageFrame then
        AlertMessageFrame = CreateFrame("Frame", nil, f, "NarciSettingsAlertFrameTemplate");
    end
    AlertMessageFrame:Hide();

    CategoryButtons[1]:Click();

    --Pixel perfect?
    local _, screenHeight = GetPhysicalScreenSize();
    local scale = 768/screenHeight;
    MainFrame:SetScale(scale / 0.75);
    MainFrame:RegisterEvent("UI_SCALE_CHANGED");

    Categories = nil;

    C_TooltipInfo.GetHyperlink("|Hitem:71086:6226:173127::::::60:577:::3:6660:7575:7696|r");    --Cache
end


NarciSettingsFrameMixin = {};

function NarciSettingsFrameMixin:OnLoad()
    MainFrame = self;

    local panel = NarciInterfaceOptionsPanel;
    panel:HookScript("OnShow", function(f)
        if f:IsVisible() then
            MainFrame:ShowUI("blizzard");
        end
    end);
    panel:HookScript("OnHide", function(f)
        MainFrame:CloseUI();
    end);

    if IS_DRAGONFLIGHT and SettingsPanel then
        self.Background = CreateFrame("Frame", nil, SettingsPanel);
        self.Background:SetFrameStrata("LOW");
        self.Background:SetFixedFrameStrata(true);
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        local realTexture = self.Background:CreateTexture(nil, "BACKGROUND")
        realTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -58, 14);  --30
        realTexture:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 32, -4);    --8
        realTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\DispersiveBackground");
        --realTexture:SetColorTexture(1, 0.05, 0.05, 0.8);

        --local category = securecallfunction(Settings.RegisterCanvasLayoutCategory, panel, "Narcissus");
        --securecallfunction(Settings.RegisterAddOnCategory, category);
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Narcissus");
        Settings.RegisterAddOnCategory(category);

    elseif InterfaceOptions_AddCategory then
        self.Background = self:CreateTexture(nil, "BACKGROUND", nil, -1);
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        self.Background:SetColorTexture(0.05, 0.05, 0.05, 0.8);

        --Create UI on Interface Options Panel (ESC-Interface)
        panel.name = "Narcissus";
        panel.Header:SetText("Narcissus");
        InterfaceOptions_AddCategory(panel);
    end

    self.Background:Hide();
end



function NarciSettingsFrameMixin:ShowUI(mode, alignToCenter, navigateTo)
    SetupFrame();

    mode = mode or "default";
    --if mode ~= self.mode then
        self.mode = mode;
        if mode == "blizzard" then
            self:AnchorToInterfaceOptions();
        else
            self:AnchorToDefault(alignToCenter);
        end
    --end

    CreditList:StopAnimation();

    if mode == "blizzard" then
        self.FlyIn:Stop();
        self.Background:Show();
    else
        self.FlyIn:Play();
        self:SetFrameStrata("DIALOG");
        self.Background:Hide();
    end

    RENDER_RANGE = Round0(self.ScrollFrame:GetHeight() + 4 + CATE_OFFSET);

    self:Show();

    if navigateTo then
        C_Timer.After(0, function()
            self:NavigateToCategory(navigateTo);
        end)
    end
end

function NarciSettingsFrameMixin:CloseUI()
    self:Hide();
end

function NarciSettingsFrameMixin:ToggleUI()
    if self:IsShown() then
        self:CloseUI();
    else
        self:ShowUI();
    end
end

function NarciSettingsFrameMixin:OnHide()
    self.FlyIn:Stop();
    SliderUpdator:Stop();
    SCROLL_LOCKED = false;
    self:Hide();
    self.Background:Hide();
end

function NarciSettingsFrameMixin:OnEvent(event, ...)
    if event == "UI_SCALE_CHANGED" then
        self.mode = nil;    --to recalculate scale
    end
end

function NarciSettingsFrameMixin:NavigateToCategory(categoryKey)
    for i, b in ipairs(CategoryButtons) do
        if b.key == categoryKey then
            SetScrollByCategoryID(b.id, false);
            return
        end
    end
end


local CollapsibleCategory = {
    onUpdate = function(self, elapsed)
        self.t = self.t + elapsed;
        local w = inOutSine(self.t, self.fromW, self.toW, self.d);
        if self.t >= self.d then
            w = self.toW;
            self:SetScript("OnUpdate", nil);
        end
        self.frame:SetWidth(w);
    end
};

function CollapsibleCategory:Init()
    if not self.f then
        self.f = CreateFrame("Frame", nil, MainFrame);
        self.f.frame = MainFrame.CategoryFrame;
    end
    self.f.fromW = self.f.frame:GetWidth();
    self.f.t = 0;
    self.f.d = 0.5;
end

function CollapsibleCategory:Collapse()
    self:Init();
    self.f.toW = self.collapsedWidth;
    self.f:SetScript("OnUpdate", self.onUpdate);
end

function CollapsibleCategory:Expand()
    self:Init();
    self.f.toW = SHRIKNED_LEFT_WIDTH;
    self.f:SetScript("OnUpdate", self.onUpdate);
end

function CollapsibleCategory:SetCollapsedWidth(width)
    self.collapsedWidth = width;
end



local function MouseoverTracker_OnUpdate(self, elapsed)
    self.t1 = self.t1 + elapsed;
    if self.t1 > 0.1 then
        self.t1 = 0;
    else
        return
    end

    if self.CategoryFrame:IsMouseOver() then
        if not self.cursorInCategoryFrame then
            self.cursorInCategoryFrame = true;
            CollapsibleCategory:Expand();
        end
    else
        if self.cursorInCategoryFrame then
            self.cursorInCategoryFrame = nil;
            CollapsibleCategory:Collapse();
        end
    end
end

function NarciSettingsFrameMixin:AnchorToInterfaceOptions()
    local container = NarciInterfaceOptionsPanel;
    if not container then return end;

    self:ClearAllPoints();
    self:SetParent(container);

    local padding = 4;
    self:SetPoint("TOPRIGHT", container, "TOPRIGHT", -padding, -padding);

    local containerScale = container:GetEffectiveScale();
    local containerHeight = container:GetHeight();
    local containerWidth = container:GetWidth();
    local scale = self:GetScale();
    local effectiveSettingsFrameWidth = (MAX_SCROLLFRAME_WIDTH + SHRIKNED_LEFT_WIDTH) * scale;
    local exceed = effectiveSettingsFrameWidth - containerWidth * containerScale;

    if exceed > 0 then
        local collapsedCateWidth = SHRIKNED_LEFT_WIDTH - exceed/containerScale;
        if collapsedCateWidth < 36 then
            collapsedCateWidth = 36;
        end
        CollapsibleCategory:SetCollapsedWidth(collapsedCateWidth);
        self.CategoryFrame:SetWidth(collapsedCateWidth);
        self.t1 = 0;
        self:SetScript("OnUpdate", MouseoverTracker_OnUpdate);
    else
        self.CategoryFrame:SetWidth(SHRIKNED_LEFT_WIDTH);
        self:SetScript("OnUpdate", nil);
    end


    self:SetSize( (containerWidth-2*padding) *containerScale/scale, (containerHeight - 2*padding) *containerScale/scale);

    local scrollFrameWidth = self.ScrollFrame:GetWidth();
    self.ScrollFrame.ScrollChild:SetWidth(scrollFrameWidth);
    self.CloseButton:Hide();
    self.BackgroundFrame:Hide();
    self.BorderFrame:Hide();

    if self.Background then
        self.Background:Show();
    end

    UpdateAlignment();
end

function NarciSettingsFrameMixin:AnchorToDefault(alignToCenter)
    self:ClearAllPoints();
    self:SetParent(nil);
    local x, y = Narci_VirtualLineCenter:GetCenter();
    local scale = self:GetEffectiveScale();
    if alignToCenter then
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    else
        self:SetPoint("CENTER", UIParent, "LEFT", x/scale, 0);
    end

    self:SetSize(DEFAULT_FRAME_WIDTH, DEFAULT_FRAME_HEIGHT);
    self.CategoryFrame:SetWidth(DEFAULT_LEFT_WIDTH);
    self.ScrollFrame.ScrollChild:SetWidth(DEFAULT_FRAME_WIDTH - DEFAULT_LEFT_WIDTH);
    self.CloseButton:Show();
    self.BackgroundFrame:Show();
    self.BorderFrame:Show();

    if self.Background then
        self.Background:Hide();
    end

    UpdateAlignment();
end


---- Slider ----
function SliderUpdator:Stop()
    self:SetScript("OnUpdate", nil);
    self.cursorX = nil;
    self.ratio = nil;
    self.slider = nil;
    self.left = nil;
    self.t = nil;
    self.delay = nil;
    self.cursorScale = nil;
    self.reciprocal = nil;
end

local function SliderUpdator_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self.t = self.delay;
    else
        return
    end

    local cursorX = GetCursorPosition();
    cursorX = cursorX * self.cursorScale - self.cursorOffset;
    if cursorX ~= self.cursorX then
        self.cursorX = cursorX;
        self.ratio = (self.cursorX - self.left) * self.reciprocal;
        self.slider:SetValueByRatio(self.ratio, true);
    end
end


function SliderUpdator:Start(slider)
    self:SetScript("OnUpdate", nil);
    self.left = slider:GetEffectiveLeft();
    if not self.left then
        return
    end
    self.width = slider:GetEffectiveWidth();
    self.reciprocal = 1/self.width;
    self.cursorX = GetCursorPosition();
    self.t = 1;
    self.slider = slider;
    local scale = slider:GetEffectiveScale();
    self.cursorScale = 1 / scale;
    if slider.Thumb:IsMouseOver(0, 0, -2, 2) then
        local centerX = slider.Thumb:GetCenter();
        local cursorX = GetCursorPosition();
        self.cursorOffset = cursorX/scale - centerX;
    else
        self.cursorOffset = 0;
    end
    if slider.obeyStep then
        self.delay = -0.1;
    else
        self.delay = -0.016;
    end
    self:SetScript("OnUpdate", SliderUpdator_OnUpdate);
end


NarciSettingsFrameSliderMixin = {};


function NarciSettingsFrameSliderMixin:OnLoad()
    self.BarTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
    self.Thumb:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
    self.Selection:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
    self.Highlight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
    self.BackgroundLeft:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\SliderBackground");
    self.BackgroundCenter:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\SliderBackground");
    self.BackgroundRight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\SliderBackground");

    self.valueOffsetRatio = 1;
    self:SetSideOffset(4); --half of thumb size
    self:SetMinMaxValues(0, 1);
    self:SetValue(0);


    SetTextureColorByID(self.Thumb, 2);
end

function NarciSettingsFrameSliderMixin:SetValue(value, userInput)
    if self.maxVal and value > self.maxVal then
        value = self.maxVal;
    elseif self.minVal and value < self.minVal then
        value = self.minVal;
    end

    self.value = value;
    self.Thumb:SetPoint("CENTER", self.Bar, "LEFT", self.sideOffset + self.valueOffsetRatio * (value - self.minVal), 0);

    if self.valueFormatFunc then
        self.ValueText:SetText(self.valueFormatFunc(value));
    else
        self.ValueText:SetText(Round1(value));
    end

    if userInput and self.onValueChangedFunc then
        if self.convertionFunc then
            value = self.convertionFunc(value);
        end
        if value ~= self.lastValue then
            self.lastValue = value;
            if self.key then
                DB[self.key] = value;
            end
            self.onValueChangedFunc(self, value);
        end
    end
end

function NarciSettingsFrameSliderMixin:SetValueByRatio(ratio, userInput)
    if ratio < 0 then
        self:SetValue(self.minVal, userInput);
    elseif ratio > 1 then
        self:SetValue(self.maxVal, userInput);
    else
        if self.obeyStep then
            local rawValue = ratio * self.range;
            local rawStep = math.floor(rawValue / self.valueStep);
            local prev = rawStep * self.valueStep;
            local next = prev + self.valueStep;
            if rawValue > (next + prev) * 0.5 then
                rawValue = next;
            else
                rawValue = prev;
            end
            self:SetValue(self.minVal + rawValue, userInput);
        else
            self:SetValue(self.minVal + ratio * self.range, userInput);
        end
    end
end

function NarciSettingsFrameSliderMixin:SetValueStep(valueStep)
    self.valueStep = valueStep;
end

function NarciSettingsFrameSliderMixin:SetMinMaxValues(minVal, maxVal)
    self.minVal = minVal;
    self.maxVal = maxVal;
    self.range = maxVal - minVal;
end

function NarciSettingsFrameSliderMixin:GetRange()
    return self.range or 0
end

function NarciSettingsFrameSliderMixin:SetSideOffset(offset)
    self.sideOffset = offset;
end

function NarciSettingsFrameSliderMixin:GetEffectiveLeft()
    return self:GetLeft() + self.sideOffset;
end

function NarciSettingsFrameSliderMixin:GetEffectiveWidth()
    return self:GetWidth() - 2 * self.sideOffset;
end

function NarciSettingsFrameSliderMixin:SetObeyStepOnDrag(state)
    if not self.nodes then
        self.nodes = {};
    end

    if state and self.valueStep and self.valueStep > 0 then
        local numSteps = Round0( (self.maxVal - self.minVal) / self.valueStep + 1);
        if numSteps < 2 then
            self:SetObeyStepOnDrag(false);
            return
        end

        self.obeyStep = true;
        self.ratioStep = 0.5/numSteps;

        for i = 1, numSteps do
            if not self.nodes[i] then
                self.nodes[i] = self:CreateTexture(nil, "ARTWORK");
                self.nodes[i]:SetSize(24, 24);
                self.nodes[i]:SetPoint("CENTER", self.Bar, "LEFT", 0, 0);
                self.nodes[i]:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
                SetTextureColorByID(self.nodes[i], 1);
            end
            self.nodes[i]:SetTexCoord(0.125, 0.1875, 0, 0.5);
            self.nodes[i]:Show();
        end

        for i = numSteps + 1, #self.nodes do
            self.nodes[i]:Hide();
        end

        self.numSteps = numSteps;
        --self.Bar:SetVertexColor(0.25, 0.25, 0.25);
        SetTextureColorByID(self.BarTexture, 1);
    else
        self.obeyStep = nil;
        self.numSteps = 2;
        for i = 1, 2 do
            if not self.nodes[i] then
                self.nodes[i] = self:CreateTexture(nil, "ARTWORK");
                self.nodes[i]:SetSize(24, 24);
                self.nodes[i]:SetPoint("CENTER", self.Bar, "LEFT", 0, 0);
                self.nodes[i]:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Slider");
                SetTextureColorByID(self.nodes[i], 1);
            end
            if i == 1 then
                self.nodes[i]:SetTexCoord(0.25, 0.3125, 0, 0.5);
            else
                self.nodes[i]:SetTexCoord(0.3125, 0.375, 0, 0.5);
            end
            self.nodes[i]:Hide();
        end

        for i = 3, #self.nodes do
            self.nodes[i]:Hide();
        end

        SetTextureColorByID(self.BarTexture, 1);
    end

    self:OnSizeChanged();
end

function NarciSettingsFrameSliderMixin:OnSizeChanged()
    local width = self:GetWidth();
    if width and self.numSteps then
        if self.numSteps > 2 then
            local effectiveWidth = width - self.sideOffset * 2;
            local gap = effectiveWidth / (self.numSteps - 1);
            for i = 1, self.numSteps do
                self.nodes[i]:ClearAllPoints();
                self.nodes[i]:SetPoint("CENTER", self.Bar, "LEFT", self.sideOffset + (i - 1) * gap, 0);
            end
        else
            self.nodes[1]:ClearAllPoints();
            self.nodes[1]:SetPoint("CENTER", self.Bar, "LEFT", self.sideOffset, 0);
            self.nodes[2]:ClearAllPoints();
            self.nodes[2]:SetPoint("CENTER", self.Bar, "RIGHT", -self.sideOffset, 0);
        end
        width = width - 4;
        local pixelScale = 0.75;
        local pixelWidth = width / pixelScale;
        if pixelWidth > 512 then
            pixelWidth = 512;
        end
        local coord = (pixelWidth / 512) * 0.5;
        if self.obeyStep then
            self.BarTexture:SetTexCoord(0.5 - coord, 0.5 + coord, 0.75, 1);
        else
            self.BarTexture:SetTexCoord(0.5 - coord, 0.5 + coord, 0.5, 0.75);
        end
        self.valueOffsetRatio = self:GetEffectiveWidth() / self:GetRange();
    end
end

function NarciSettingsFrameSliderMixin:OnMouseDown()
    SliderUpdator:Start(self);
    self.isDragging = true;
end

function NarciSettingsFrameSliderMixin:OnMouseUp()
    SliderUpdator:Stop();
    self.isDragging = nil;
    if not self:IsFocused() then
        self:HighlightFrame(false);
    end
end

function NarciSettingsFrameSliderMixin:IsFocused()
    return (self:IsVisible() and self:IsMouseOver(0, 0, -12, 12))
end

function NarciSettingsFrameSliderMixin:SetSliderWidth(width, adjustOffsetByLabelWidth)
    self:SetWidth(width);
    if adjustOffsetByLabelWidth then
        local labelWidth = self:GetParent().Label:GetWrappedWidth();
        if labelWidth then
            self:SetPoint("LEFT", self:GetParent(), "LEFT", labelWidth + 64, 0);
        end
    end
    --local offsetX = 120 - 192 + width + 16;
    --self:SetPoint("LEFT", self:GetParent(), "LEFT", offsetX, 0);
    self:OnSizeChanged();
end

function NarciSettingsFrameSliderMixin:OnEnter()
    self:HighlightFrame(true);
end

function NarciSettingsFrameSliderMixin:OnLeave()
    if not self.isDragging then
        self:HighlightFrame(false);
    end
end

function NarciSettingsFrameSliderMixin:HighlightFrame(state)
    if state then
        SetTextColorByID(self:GetParent().Label, 3);
        SetTextColorByID(self.ValueText, 3);
        SetTextureColorByID(self.BarTexture, 2);
        self.Highlight:Show();
    else
        SetTextColorByID(self:GetParent().Label, 2);
        SetTextColorByID(self.ValueText, 2);
        SetTextureColorByID(self.BarTexture, 1);
        self.Highlight:Hide();
    end
end

function NarciSettingsFrameSliderMixin:UpdateState()
    if self.key and DB[self.key] then
        if self.convertionFunc then
            self:SetValue( self.convertionFunc(DB[self.key]) );
        else
            self:SetValue(DB[self.key]);
        end
    elseif self.getValueFunc then
        self:SetValue( self.getValueFunc() );
    else
        if self.minVal then
            self:SetValue(self.minVal);
        end
    end
end


---- Keybindings ----

local function KeybingdingButton_OnEvent(self, event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not self:IsFocused() then
            self:StopListening();
        end
    end
end

NarciSettingsKeybindingButton = {};

function NarciSettingsKeybindingButton:OnLoad()
    self.Left:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Keybinding");
    self.Center:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Keybinding");
    self.Right:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\Keybinding");

    self.BGLeft:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\KeybindingBackground");
    self.BGCenter:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\KeybindingBackground");
    self.BGRight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\KeybindingBackground");

    self.TextBackground:SetColorTexture(0.92, 0.92, 0.92);
    self:OnLeave();
end

function NarciSettingsKeybindingButton:OnEnter()
    self:HighlightFrame(true);
    SetTextColorByID(self.Label, 3);
end

function NarciSettingsKeybindingButton:OnLeave()
    if not self.active then
        self:HighlightFrame(false);
    end
    SetTextColorByID(self.Label, 1);
end

function NarciSettingsKeybindingButton:UpdateState()
    local key;
    if self.actionName then
        key = GetBindingKey(self.actionName);
    end
    if key then
        self:SetText(key);
        SetTextColorByID(self.ButtonText, 3);
    else
        self:SetText(NOT_BOUND);
        SetTextColorByID(self.ButtonText, 1);
    end
end

function NarciSettingsKeybindingButton:SetExternalAction(actionName)
    --Processesd by WoWUI, globally
    self.actionName = actionName;
end

function NarciSettingsKeybindingButton:SetInternalAction(actionName)
    --Used and processed by Narcissus
    self.actionName = actionName;
end

function NarciSettingsKeybindingButton:HighlightFrame(state)
    if state then
        SetTextureColorByID(self.Left, 2);
        SetTextureColorByID(self.Center, 2);
        SetTextureColorByID(self.Right, 2);
    else
        SetTextureColorByID(self.Left, 1);
        SetTextureColorByID(self.Center, 1);
        SetTextureColorByID(self.Right, 1);
    end
end

function NarciSettingsKeybindingButton:OnClick(mouseButton)
    if mouseButton == "RightButton" then
        self:ClearBinding();
    else
        if self.active then
            self:StopListening();
        else
            self:StartListening();
        end
    end
end

local RESERVED_KEYS = {
    ESCAPE = true,
    BACKSPACE = true,
    SPACE = true,
    ENTER = true,
    TAB = true,
};

local function ClearBindingKey(actionName)
    local key1, key2 = GetBindingKey(actionName);
    if key1 then
        SetBinding(key1, nil, 1);
    end
    if key2 then
        SetBinding(key2, nil, 1);
    end
    SaveBindings(1);
end

local function ExternalAction_OnKeydown(self, key)
    if key == "ESCAPE" then
        self:StopListening();
        return
    end

    if RESERVED_KEYS[key] then
        self:ExitAndShowInvalidKey(key);
        return
    end

    local keyString = CreateKeyChordStringUsingMetaKeyState(key);
    self.newKey = keyString;
    --self.ButtonText:SetText(keyString);
    self:AnimateSetText(keyString);

    if not IsKeyPressIgnoredForBinding(key) then
        self:AttemptToBind();
    end
end

local function ExternalAction_OnKeyUp(self, key)
    self:AttemptToBind();
end


function NarciSettingsKeybindingButton:StartListening()
    self.active = true;

    self.ButtonText:SetTextColor(0, 0, 0);
    self.ButtonText:SetShadowColor(1, 1, 1);
    self.ButtonText:SetShadowOffset(0, 0);
    self.ButtonText.AnimInput:Stop();

    self.TextBackground.AnimFadeOut:Stop();
    self.TextBackground:SetColorTexture(0.92, 0.92, 0.92);
    self.TextBackground:Show();

    self:SetScript("OnEvent", KeybingdingButton_OnEvent);
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");

    SCROLL_LOCKED = true;
    MainFrame.ScrollFrame:LockScroll(true);
    MainFrame.ScrollFrame:ScrollToWidget(self, 24);

    self:SetScript("OnKeyDown", ExternalAction_OnKeydown);
    self:SetScript("OnKeyUp", ExternalAction_OnKeyUp);
    self:SetPropagateKeyboardInput(false);
    if GAMEPAD_ENABLED then
 
    end
end

function NarciSettingsKeybindingButton:StopListening()
    self.active = nil;
    self:SetScript("OnKeyDown", nil);
    self:SetScript("OnKeyUp", nil);
    if GAMEPAD_ENABLED then
        self:SetScript("OnGamePadButtonDown", nil);
        self:SetScript("OnGamePadButtonUp", nil);
    end

    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");

    if not self:IsFocused() then
        self:HighlightFrame(false);
    end

    if not self.TextBackground.AnimFadeOut:IsPlaying() then
        self.TextBackground:Hide();
    end

    self.ButtonText:SetShadowColor(0, 0, 0);
    self.ButtonText:SetShadowOffset(1, -1);
    self:UpdateState();

    SCROLL_LOCKED = false;
    MainFrame.ScrollFrame:LockScroll(false);

    AlertMessageFrame:Hide();
end

function NarciSettingsKeybindingButton:AnimateSetText(text)
    self.ButtonText.AnimInput:Stop();
    local width1 = self.ButtonText:GetWrappedWidth();
    self.ButtonText:SetText(text);
    local width2 = self.ButtonText:GetWrappedWidth();
    local diff = 0.5*(width2 - width1);
    if diff > 10 or diff <-10 then
        diff = 0;
    end
    self.ButtonText.AnimInput.X1:SetOffset(diff, 0);
    self.ButtonText.AnimInput.X2:SetOffset(-diff, 0);
    self.ButtonText.AnimInput:Play();
end

function NarciSettingsKeybindingButton:ClearBinding()
    ClearBindingKey(self.actionName);
    self:StopListening();
end

function NarciSettingsKeybindingButton:OnHide()
    if self.active then
        self:StopListening();
    end
end

function NarciSettingsKeybindingButton:OnShow()
    self:UpdateState();
end

function NarciSettingsKeybindingButton:IsFocused()
    return (self:IsMouseOver() and self:IsVisible()) or (AlertMessageFrame:IsVisible() and AlertMessageFrame:IsMouseOver());
end

function NarciSettingsKeybindingButton:ExitAndShowInvalidKey(key)
    self:StopListening();
    AlertMessageFrame:ShowInvalidKey(self, key);
end

function NarciSettingsKeybindingButton:AttemptToBind(override)
    self:SetScript("OnKeyDown", nil);
    self:SetScript("OnKeyUp", nil);
    if GAMEPAD_ENABLED then
        self:SetScript("OnGamePadButtonDown", nil);
        self:SetScript("OnGamePadButtonUp", nil);
    end

    if not self.newKey then
        self:StopListening();
        return
    end

    if IsKeyPressIgnoredForBinding(self.newKey) then
        self:ExitAndShowInvalidKey(self.newKey);
        return
    end

    local action = GetBindingAction(self.newKey);
    if (action and action ~= "" and action ~= self.actionName) and not override then
        AlertMessageFrame:ShowOverwriteConfirmation(self, action);
        return
    else
        ClearBindingKey(self.actionName);
        if SetBinding(self.newKey, self.actionName, 1) then
            --Successful
            self.TextBackground.AnimFadeOut:Stop();
            self.TextBackground:SetColorTexture(0.35, 0.61, 0.38);  --green
            self.TextBackground.AnimFadeOut:Play();
            self:StopListening();
            SaveBindings(1);    --account wide
            return true
        else
            self:StopListening();
            return
        end
    end
end


local ClipboardUtil = {};
ClipboardUtil.scripts = {};

function ClipboardUtil:CreateClipboard()
    Clipboard = CreateFrame("EditBox", nil, MainFrame);
    Clipboard:SetFontObject("NarciFontMedium13");
    Clipboard:SetShadowOffset(0, 0);
    Clipboard:SetTextInsets(6, 6, 0, 0);
    Clipboard:SetAutoFocus(false);
    Clipboard:SetHighlightColor(0, 0.35, 0.75);
    Clipboard:SetJustifyH("CENTER");
    Clipboard:SetPropagateKeyboardInput(false);
    for name, method in pairs(self.scripts) do
        Clipboard:SetScript(name, method);
    end
    SetTextColorByID(Clipboard, 3);
end

function ClipboardUtil:SetupFromWebsiteButton(websiteButton)
    if not Clipboard then
        self:CreateClipboard();
    end

    Clipboard:ClearAllPoints();
    Clipboard:SetParent(websiteButton);
    Clipboard:SetPoint("TOPLEFT", websiteButton, "TOPLEFT", 0, 0);
    Clipboard:SetPoint("BOTTOMRIGHT", websiteButton, "BOTTOMRIGHT", 0, 0);
    Clipboard:Show();
    Clipboard:SetText(websiteButton.link);
    Clipboard:SetCursorPosition(0);
    Clipboard:SetFocus();
end

function ClipboardUtil.scripts.OnKeyDown(self, key)
    local keys = CreateKeyChordStringUsingMetaKeyState(key);
    if keys == "CTRL-C" or key == "COMMAND-C" then
        AboutTab.projectHeader.animSuccess:Play();
        AboutTab.projectHeader:SetText(L["Copied"]);
        self:Hide();
    end
end

function ClipboardUtil.scripts.OnEditFocusLost(self)
    if self:IsShown() then
        self:HighlightText(0, 0);
        if IsMouseButtonDown() then
            for _, button in ipairs(AboutTab.websiteButtons) do
                if button:IsMouseOver() then
                    return
                end
            end
        end
        self:Hide();
    end
end

function ClipboardUtil.scripts.OnEditFocusGained(self)
    self:HighlightText();
end

function ClipboardUtil.scripts.OnHide(f)
    AboutTab:UpdateWebsiteButtons();
    f:Hide();
end

function ClipboardUtil.scripts.OnEscapePressed(self)
    self:Hide();
end

function ClipboardUtil.scripts.OnEnterPressed(self)
    self:Hide();
end

function ClipboardUtil.scripts.OnTextChanged(self, userInput)
    if userInput then
        self:Hide();
    end
end

function ClipboardUtil.scripts.OnCursorChanged(self)
    self:HighlightText();
end



NarciSettingsClipboardButtonMixin = {};

function NarciSettingsClipboardButtonMixin:OnLoad()
    self.Left:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\EditBox");
    self.Center:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\EditBox");
    self.Right:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SettingsFrame\\EditBox");

    self:HighlightFrame(false);
end

function NarciSettingsClipboardButtonMixin:OnClick()
    if self.isActive then
        self.isActive = nil;
        AboutTab:UpdateWebsiteButtons();
    else
        self:PlaceClipboard();
    end
end

function NarciSettingsClipboardButtonMixin:OnEnter()
    self:HighlightFrame(true);
end

function NarciSettingsClipboardButtonMixin:OnLeave()
    self:HighlightFrame(false);
end

function NarciSettingsClipboardButtonMixin:HighlightFrame(state)
    if self.isActive then return end;

    if state then
        SetTextureColorByID(self.Left, 2);
        SetTextureColorByID(self.Center, 2);
        SetTextureColorByID(self.Right, 2);
        SetTextureColorByID(self.Logo, 3);
        SetTextColorByID(self.ButtonText, 3);
    else
        SetTextureColorByID(self.Left, 1);
        SetTextureColorByID(self.Center, 1);
        SetTextureColorByID(self.Right, 1);
        SetTextureColorByID(self.Logo, 2);
        SetTextColorByID(self.ButtonText, 2);
    end
end

function NarciSettingsClipboardButtonMixin:OnMouseDown()
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 16, -0.8);
    if self.logoMode then
        self.Logo:SetPoint("CENTER", self, "CENTER", 0, -0.8);
    end
end

function NarciSettingsClipboardButtonMixin:OnMouseUp()
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 16, 0);
    if self.logoMode then
        self.Logo:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    if Clipboard and Clipboard:IsShown() then
        Clipboard:SetFocus();
    end
end

function NarciSettingsClipboardButtonMixin:SetLogoOnlyMode(state)
    self.Logo:ClearAllPoints();
    if state then
        self.ButtonText:Hide();
        self.Logo:SetPoint("CENTER", self, "CENTER", 0, 0);
    else
        self.ButtonText:Show();
        self.Logo:SetPoint("RIGHT", self.ButtonText, "LEFT", -4, 0);
    end
    self.Logo:Show();
    self.logoMode = state;
end

function NarciSettingsClipboardButtonMixin:PlaceClipboard()
    AboutTab:UpdateWebsiteButtons(self.id);

    self.Logo:Hide();
    self.ButtonText:Hide();
    self.Left:SetVertexColor(0, 0.5, 0.83);
    self.Center:SetVertexColor(0, 0.5, 0.83);
    self.Right:SetVertexColor(0, 0.5, 0.83);
    self.isActive = true;

    ClipboardUtil:SetupFromWebsiteButton(self);
end


NarciSettingsAlertMessageFrameMixin = {};

function NarciSettingsAlertMessageFrameMixin:ShowInvalidKey(keybindingButton, key)
    self:AnchorToButton(keybindingButton);
    self.YesButton:Hide();
    self.NoButton:Hide();
    SetTextColorByID(self.Message, 3);
    self.Stroke:SetColorTexture(0.75, 0.06, 0);
    self.Background:SetColorTexture(0.35, 0.11, 0.11);
    self:SetAlertMessage(key.." is invalid");
    self:StopAnimating();
    self.AnimFadeIn:Play();
    self:Show();
end

function NarciSettingsAlertMessageFrameMixin:ShowOverwriteConfirmation(keybindingButton, conflictedAction)
    self:AnchorToButton(keybindingButton);
    local actionName = GetBindingName(conflictedAction);
    SetTextColorByID(self.Message, 3);
    self.Stroke:SetColorTexture(0.4, 0.4, 0.4);
    self.Background:SetColorTexture(0.08, 0.08, 0.08);
    self.YesButton:Show();
    self.NoButton:Show();
    self.NoButton.Countdown:SetCooldown(GetTime(), 8);
    self:SetAlertMessage("Override "..actionName.." ?");
    self:StopAnimating();
    self.AnimShake:Play();
    self:Show();

    self.parentButton = keybindingButton;
    keybindingButton.TextBackground:SetColorTexture(1, 0.82, 0);
end

function NarciSettingsAlertMessageFrameMixin:ShowRequiresReload()
    self:StopAnimating();
    self.YesButton:Hide();
    self.NoButton:Hide();
    self:ClearAllPoints();
    self:SetParent(MainFrame.ScrollFrame);
    self:SetPoint("TOP", MainFrame.ScrollFrame, "TOP", 0, -8);
    self:SetAlertMessage(REQUIRES_RELOAD or "Requires Reload");
    self.Message:SetTextColor(1, 0.93, 0);
    self.Stroke:SetColorTexture(0.4, 0.4, 0.4);
    self.Background:SetColorTexture(0.08, 0.08, 0.08);
    self.AnimFadeIn:Play();
    self:Show();
end

function NarciSettingsAlertMessageFrameMixin:AnchorToButton(keybindingButton)
    self:ClearAllPoints()
    --self:SetPoint("BOTTOM", keybindingButton, "TOP", 0, 4);
    self:SetPoint("TOP", keybindingButton, "BOTTOM", 0, -8);
    self:SetParent(keybindingButton);
end

function NarciSettingsAlertMessageFrameMixin:SetAlertMessage(msg)
    self.Message:SetText(msg);
    local width = self.Message:GetWrappedWidth();
    local height = self.Message:GetHeight();

    if self.YesButton:IsShown() then
        self:SetSize(Round0(width + 32), Round0(height + 16 + 32 + 2));
    else
        self:SetSize(Round0(width + 20), Round0(height + 20));
    end

    --Update alignment
    if self:GetBottom() < MainFrame.ScrollFrame:GetBottom() then
        self:ClearAllPoints();
        self:SetPoint("BOTTOM", self:GetParent(), "TOP", 0, 8);
    end
end

function NarciSettingsAlertMessageFrameMixin:OnHide()
    self:Hide();
    self.NoButton.Countdown:Clear();
end

local function AlertFrameButton_OnEnter(self)
    self.Texture:SetVertexColor(1, 1, 1);
    if self.Countdown then
        self.Countdown:Pause();
    end
end

local function AlertFrameButton_OnLeave(self)
    self.Texture:SetVertexColor(0.67, 0.67, 0.67);
    if self.Countdown then
        self.Countdown:Resume();
    end
end

local function AlertFrameButton_OnMouseDown(self)
    self.Texture:SetScale(0.8);
end

local function AlertFrameButton_OnMouseUp(self)
    self.Texture:SetScale(1);
end

local function AlertFrameButton_Yes_OnClick(self)
    self:GetParent():Hide();
    self:GetParent().parentButton:AttemptToBind(true);
end

local function Countdown_OnFinished()
    AlertMessageFrame:Hide();
    local keybindingButton = AlertMessageFrame:GetParent();
    if keybindingButton and keybindingButton.StopListening then
        keybindingButton:StopListening();
    end
end

local function AlertFrameButton_No_OnClick(self)
    Countdown_OnFinished();
end

function NarciSettingsAlertMessageFrameMixin:OnLoad()
    AlertMessageFrame = self;

    self.YesButton:SetScript("OnEnter", AlertFrameButton_OnEnter);
    self.YesButton:SetScript("OnLeave", AlertFrameButton_OnLeave);
    self.YesButton:SetScript("OnMouseDown", AlertFrameButton_OnMouseDown);
    self.YesButton:SetScript("OnMouseUp", AlertFrameButton_OnMouseUp);
    self.YesButton:SetScript("OnClick", AlertFrameButton_Yes_OnClick);

    self.NoButton:SetScript("OnEnter", AlertFrameButton_OnEnter);
    self.NoButton:SetScript("OnLeave", AlertFrameButton_OnLeave);
    self.NoButton:SetScript("OnMouseDown", AlertFrameButton_OnMouseDown);
    self.NoButton:SetScript("OnMouseUp", AlertFrameButton_OnMouseUp);
    self.NoButton:SetScript("OnClick", AlertFrameButton_No_OnClick);
    self.NoButton.Countdown:SetScript("OnCooldownDone", Countdown_OnFinished);

    self.Stroke:SetColorTexture(0.4, 0.4, 0.4);
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "LINEAR");
end

function NarciSettingsAlertMessageFrameMixin:OnShow()
    local a = NarciAPI.GetPixelForWidget(self, 2);
    self.Exclusion:ClearAllPoints();
    self.Exclusion:SetPoint("TOPLEFT", self, "TOPLEFT", a, -a);
    self.Exclusion:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -a, a);
end


local function GetSettingsButtonByDBKey(dbKey)
    for id, button in ipairs(OptionButtons) do
        if button.key == dbKey then
            return button
        end
    end
end
NarciAPI.GetSettingsButtonByDBKey = GetSettingsButtonByDBKey;


function Narci_PreferenceButton_OnClick(self)
    MainFrame:ToggleUI();
end


function NarciAPI.ToggleSettings()
    if SettingsPanel and SettingsPanel:IsVisible() then return end;  --Player is viewing Options

    if MainFrame:IsShown() then
        MainFrame:CloseUI();
    else
        MainFrame:ShowUI(nil, true);
    end
end