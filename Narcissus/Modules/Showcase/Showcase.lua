local _, addon = ...

local L = Narci.L;
local TransmogDataProvider = addon.TransmogDataProvider;    --defined in Modules/DressingRoom/SlotFrame
local GetModelOffsetZ = addon.GetModelOffsetZ;
local UseCurrentClassBackground = addon.UseCurrentClassBackground;
local UseCurrentRaceBackground = addon.UseCurrentRaceBackground;
local UseModelBackgroundImage = addon.UseModelBackgroundImage;
local IsPlayerInAlteredForm = addon.TransitionAPI.IsPlayerInAlteredForm;
local MixScripts = addon.PrivateAPI.MixScripts;

local FadeFrame = NarciFadeUI.Fade;
local GetAnimationName = NarciAnimationInfo.GetOfficialName;
local IsSlotValidForTransmog = NarciAPI.IsSlotValidForTransmog;

local IsShiftKeyDown = IsShiftKeyDown;
local GetCursorPosition = GetCursorPosition;
local GetCursorDelta = GetCursorDelta;
local IsHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual;
local GetPhysicalScreenSize = GetPhysicalScreenSize;


local ROTATION_PERIOD = 1/8;

local PIXEL = 1;
local PI = math.pi;
local PI2 = math.pi * 2;

local ASPECT = 3/4;
local FOV_VERTICAL = 0.6;
local FOV_DIAGONAL = FOV_VERTICAL * math.sqrt(1 + ASPECT^2);
local TAN_FOV_V = math.tan(FOV_VERTICAL/2);
local TAN_FOV_H;

local function ConvertHorizontalFoV(fovV, aspect)
    local fov_H = 2*math.atan(math.tan(fovV/2) * aspect);
    return math.tan(fov_H/2);
end

TAN_FOV_H = ConvertHorizontalFoV(FOV_VERTICAL, ASPECT);

local IMAGE_WIDTH = 800;
local IMAGE_HEIGHT = 600;
local MODEL_WIDTH_RATIO = 0.75; --width:height = 3:4

local ACTOR_IS_MOUNT = false;
local LOOP_ANIMATION = false;
local SHOW_ITEM_NAME = true;
local NUM_DOUBLE_LINE_OBJECT = 0;
local MAX_DOUBLE_LINE_OBJECT = 4;
local MAX_FONTSTRING_WIDTH = 318;
local ITEM_TEXT_FONT = "Interface/AddOns/Narcissus/Font/NotoSansCJKsc-Regular.otf";
local FONT_WEIGHT = 16;
local FONT_EFFECT = "OUTLINE";
local ITEM_TEXT_HEIGHT = PIXEL * FONT_WEIGHT;

local PA_SPACING_WEIGHT = 12;   --weight * pixel
local PA_SPACING = 12;

local DEFAULT_CAM_DISTANCE = 4;
local MIN_CAM_DISTANCE = 1;
local MAX_CAM_DISTANCE = 12;

local LAST_IMAGE_SIZE_WITH_TEXT;
local LAST_IMAGE_SIZE_NO_TEXT;

local PRINT_ORDERS = {
    1, 3, 15, 5, 4, 19, 9, 10, 6, 7, 8, 16, 17,
};

local ANIMATION_ID = 0;
local VARIATION_ID = 1;
local MAX_ANIMATION_ID = (NarciConstants and NarciConstants.Animation.MaxAnimationID) or 1499;

local min = math.min;
local max = math.max;

local DB;
local MainFrame, ModelScene, ControlPanel, FadeOptionFrame, UtilityModel, Tooltip, DropDownPanel, TabSelection, SheatheButton, GroundShadow;
local ActiveActor, PlayerActor, MountActor;
local IDFrame, VariationButton, AnimationSlider, MountToggle, LoopToggle;


local function GetScreenAspectText(width, height)
    local ratio = math.floor(100*width/height)/100;
    if ratio == 1 then
        ratio = "1:1";
    elseif ratio == 0.75 then
        ratio = "3:4";
    elseif ratio == 1.33 then
        ratio = "4:3";
    elseif ratio == 1.77 then
        ratio = "16:9";
    elseif ratio == 1.6 then
        ratio = "16:10";
    elseif ratio == 0.5625 then
        ratio = "9:16";
    else
        ratio = "custom";
    end
    return ratio
end

local DropDownOptions = {
    imageSizeWithText = {
        {" ", {1024, 768}},
        {" ", {800, 600}},
        method = "SetImageSize",
    };

    imageSizeNoText = {
        {" ", {1080, 1080}},
        {" ", {600, 800}},
        {" ", {600, 600}},
        method = "SetImageSize",
    };

    rotationPeriod = {
        {"4 s", 4},
        {"6 s", 6},
        {"8 s", 8},
        method = "SetRotationPeriod",
    };

    fontSize = {
        {"15", 15},
        {"16", 16},
        {"18", 18},
        {"20", 20},
        method = "SetFontWeight",
    };
};

for i = 1, #DropDownOptions.imageSizeWithText do
    local v = DropDownOptions.imageSizeWithText[i];
    local width, height = v[2][1], v[2][2];
    DropDownOptions.imageSizeWithText[i][1] = string.format("%s x %s (%s)", width, height, GetScreenAspectText(width, height));
end

for i = 1, #DropDownOptions.imageSizeNoText do
    local v = DropDownOptions.imageSizeNoText[i];
    local width, height = v[2][1], v[2][2];
    DropDownOptions.imageSizeNoText[i][1] = string.format("%s x %s (%s)", width, height, GetScreenAspectText(width, height));
end

DropDownOptions.imageSizeValid = DropDownOptions.imageSizeWithText;


local FadeFramecripts = {};
do
    local function FadeOptionFrame_OnUpdate(self, elapsed)
        if self.toAlpha > self.alpha then
            self.alpha = self.alpha + elapsed * 4;
            if self.alpha >= self.toAlpha then
                self.alpha = self.toAlpha;
                self:SetScript("OnUpdate", nil);
            end
        elseif self.toAlpha < self.alpha then
            self.alpha = self.alpha - elapsed * 4;
            if self.alpha <= self.toAlpha then
                self.alpha = self.toAlpha;
                self:SetScript("OnUpdate", nil);
            end
        else
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    function FadeFramecripts.OnEnter(self)
        self.toAlpha = 1;
        if self.alpha == 1 then
            self:SetScript("OnUpdate", nil);
        else
            self:SetScript("OnUpdate", FadeOptionFrame_OnUpdate);
        end
    end

    function FadeFramecripts.OnLeave(self)
        if not self:IsMouseOver() or (MainFrame.BackdropSelect:HasFocus()) then
            self.toAlpha = 0;
            self:SetScript("OnUpdate", FadeOptionFrame_OnUpdate);
        end
    end

    function FadeFramecripts.OnHide(self)
        self:SetScript("OnUpdate", nil);
        self.alpha = 0;
        self:SetAlpha(0);
    end
end


local SyncButtonScripts = {};
do
    function SyncButtonScripts.OnClick(self)
        self.AnimRotate:Play();
        MainFrame:SyncModel();
    end

    function SyncButtonScripts.OnEnter(self)
        FadeFramecripts.OnEnter(FadeOptionFrame);
        FadeFrame(self.Icon, 0.15, 1);
        FadeFrame(self.Label, 0.15, 1);
    end

    function SyncButtonScripts.OnLeave(self)
        FadeFramecripts.OnLeave(FadeOptionFrame);
        if not self.AnimRotate:IsPlaying() then
            FadeFrame(self.Icon, 0.25, 0.5);
        end
        FadeFrame(self.Label, 0.25, 0);
    end
end

local function SyncButton_OnAnimFinished(self)
    local button = self:GetParent();
    if not button:IsMouseOver() then
        FadeFrame(button.Icon, 0.5, 0.5);
    end
end


local ItemNameToggleScripts = {};
do
    ItemNameToggleScripts.OnEnter = SyncButtonScripts.OnEnter;

    function ItemNameToggleScripts.OnLeave(self)
        FadeFrame(self.Icon, 0.25, 0.5);
        FadeFrame(self.Label, 0.25, 0);
        FadeFramecripts.OnLeave(FadeOptionFrame);
    end

    function ItemNameToggleScripts.OnClick(self)
        local state = not DB.ShowItemName;
        DB.ShowItemName = state;
        MainFrame:ShowItemText(state);
    end
end


local TopLevelButtonScripts = {};
do
    TopLevelButtonScripts.OnEnter = SyncButtonScripts.OnEnter;
    TopLevelButtonScripts.OnLeave = ItemNameToggleScripts.OnLeave;

    function TopLevelButtonScripts.SetState(state)
        local self = FadeOptionFrame.TopLevelButton;
        if state then
            self.Label:SetText(L["Lower Level"]);
            self.Icon:SetTexCoord(0.5, 1, 0, 1);
            MainFrame:SetFrameStrata("DIALOG");
        else
            self.Label:SetText(L["Raise Level"]);
            self.Icon:SetTexCoord(0, 0.5, 0, 1);
            MainFrame:SetFrameStrata("MEDIUM");
        end
    end

    function TopLevelButtonScripts.OnClick(self)
        DB.BringToFront = not DB.BringToFront;
        TopLevelButtonScripts.SetState(DB.BringToFront)
    end
end


local CloseButtonScripts = {};
do
    function CloseButtonScripts.OnEnter(self)
        self.Icon:SetVertexColor(0.84, 0.08, 0.15);
    end

    function CloseButtonScripts.OnLeave(self)
        self.Icon:SetVertexColor(0.4, 0.4, 0.4);
    end

    function CloseButtonScripts.OnClick(self)
        MainFrame:Close();
    end
end


local function LoadSettings()
    NarciTurntableOptions = NarciTurntableOptions or {};
    DB = NarciTurntableOptions;

    local defaultValues = {
        ["ShowItemName"] = true,
        ["FontSize"] = 16,
        ["ImageWidth"] = 800,
        ["ImageHeight"] = 600,
        ["NoTextImageWidth"] = 600,
        ["NoTextImageHeight"] = 800,
        ["Period"] = 6,
        ["BackgroundType"] = 1,
        ["BackgroundImageType"] = 1,
        ["ShowSplash"] = true,
        --["BackgroundImageID"]
        --["CustomFileName"]
    };

    if not DB.ImageHeight then
        local w, h = GetPhysicalScreenSize();
        if h > 1438 then
            DB.ImageWidth = 1024;
            DB.ImageHeight = 768;
        end
    end

    for k, v in pairs(defaultValues) do
        if (DB[k] == nil) or (type(DB[k]) ~= type(v)) then
            DB[k] = v;
        end
    end

    SHOW_ITEM_NAME = DB.ShowItemName;
    LAST_IMAGE_SIZE_WITH_TEXT = {DB.ImageWidth, DB.ImageHeight};
    LAST_IMAGE_SIZE_NO_TEXT = {DB.NoTextImageWidth, DB.NoTextImageHeight};

    MainFrame:ShowItemText(SHOW_ITEM_NAME);
    MainFrame:SetFontWeight(DB.FontSize);
    MainFrame:SetRotationPeriod(DB.Period, true);

    local tab = MainFrame.ControlPanel.BackgroundTab;
    local id = DB.BackgroundType;
    if tab.Nodes[id] then
        tab.Nodes[id]:Click();
    else
        tab.Nodes[1]:Click();
    end

    if DB.ShowSplash then
        MainFrame.createSplash = true;
        --/run NarciTurntableOptions.ShowSplash = true
    end

    TopLevelButtonScripts.SetState(DB.BringToFront);
end


local function SetUpDropDown(parentButton, menuName)
    local p = DropDownPanel;
    p:ClearAllPoints();
    if p.parentButton then
        p.parentButton:SetFocus(false);
        if p.parentButton == parentButton then
            p:Hide();
            return
        end
    end
    p.parentButton = parentButton;
    p.Check:ClearAllPoints();
    p.Check:Hide();
    if parentButton and menuName then
        parentButton:SetFocus(true);
        local selectedText = parentButton.ValueText:GetText();
        local width = parentButton:GetWidth();
        local data = DropDownOptions[menuName];
        p.method = data.method;
        local numData = #data;
        for i = 1, numData do
            if not p.buttons then
                p.buttons = {};
            end
            if not p.buttons[i] then
                p.buttons[i] = CreateFrame("Button", nil, p, "NarciShowcaseDropDownButtonTemplate");
                p.buttons[i]:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -16 + 14*(1-i));
            end
            p.buttons[i]:SetWidth(width);
            p.buttons[i]:SetValueText(data[i][1])
            if selectedText == data[i][1] then
                p.Check:SetPoint("LEFT", p.buttons[i], "LEFT", 3, 0.6);
                p.Check:Show();
            end
            p.buttons[i].value = data[i][2];
            p.buttons[i]:Show();
        end
        for i = numData + 1, #p.buttons do
            p.buttons[i]:Hide();
        end
        p:SetPoint("TOPLEFT", parentButton, "TOPLEFT", 0, 0);
        p:SetPoint("TOPRIGHT", parentButton, "TOPRIGHT", 0, 0);
        p:SetHeight(numData * 14 + 4 + 14);
        p:Show();
    else
        p:Hide();
    end
end


local ItemTexts = {
    objects = {},
    numUsed = 0,
};

function ItemTexts:Release()
    for i = 1, #self.objects do
        self.objects[i]:Hide();
    end
    self.numUsed = 0;
end

function ItemTexts:Acquire()
    local i = self.numUsed + 1;
    self.numUsed = i;
    if not self.objects[i] then
        self.objects[i] = MainFrame.TextFrame:CreateFontString(nil, "OVERLAY", "NarciShowcaseFontStringTemplate");
        if i == 1 then
            self.objects[i]:SetPoint("TOPLEFT", MainFrame.TextFrame, "TOPLEFT", 0, 0);
        else
            self.objects[i]:SetPoint("TOPLEFT", self.objects[i - 1], "BOTTOMLEFT", 0, -PA_SPACING);
        end
        self.objects[i]:SetFont(ITEM_TEXT_FONT, ITEM_TEXT_HEIGHT, FONT_EFFECT);
        self.objects[i]:SetSpacing(2 * PIXEL);
        self.objects[i]:SetWidth(MAX_FONTSTRING_WIDTH);
        self.objects[i]:SetTextColor(0.8, 0.8, 0.8);
    end
    self.objects[i]:Show();
    return self.objects[i]
end



local SourceCacher = CreateFrame("Frame");

local function SourceCacher_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 1 then
        self.t = 0;
        self:ProcessQueue();
        self:SetScript("OnUpdate", nil);
    end
end

function SourceCacher:AddToQueue(fontString, sourceID)
    if not self.queue then
        self.queue = {};
    end
    table.insert(self.queue, {fontString, sourceID});
    self.t = 0;
    self:SetScript("OnUpdate", SourceCacher_OnUpdate);
end

function SourceCacher:ProcessQueue()
    local complete = true;
    for i = 1, #self.queue do
        if not self.queue[i] then
            return complete
        end
        complete = self.queue[i][1]:SetItemTextBySourceID(self.queue[i][2]);
    end
end

function SourceCacher:Stop()
    self:SetScript("OnUpdate", nil);
    if self.queue then
        self.queue = {};
    end
end


NarciShowcaseSheatheButtonMixin = {};

function NarciShowcaseSheatheButtonMixin:OnLoad()
    SheatheButton = self;
    self.labelText = WEAPON or "weapon";
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    self:SetPropagateKeyboardInput(true);
end

function NarciShowcaseSheatheButtonMixin:OnEnter()
    FadeFramecripts.OnEnter(FadeOptionFrame);
    FadeFrame(self.Icon, 0.15, 1);
    FadeFrame(self.Label, 0.15, 1);
end

function NarciShowcaseSheatheButtonMixin:OnLeave()
    FadeFramecripts.OnLeave(FadeOptionFrame);
    FadeFrame(self.Icon, 0.25, 0.5);
    FadeFrame(self.Label, 0.25, 0);
end

function NarciShowcaseSheatheButtonMixin:OnClick()
    ModelScene.actor:SheatheWeapon( not  ModelScene.actor:GetSheathed() );
end

local function SheatheButton_OnKeyDown(self, key)
    if key == self.hotkey then
        self:SetPropagateKeyboardInput(true);
        self:Click();
    elseif key == "ESCAPE" then
        if DressUpFrame:IsVisible() then
            self:SetPropagateKeyboardInput(true);
        else
            self:SetPropagateKeyboardInput(false);
            MainFrame:Close();
        end
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciShowcaseSheatheButtonMixin:OnShow()
    local hotkey = GetBindingKey("TOGGLESHEATH");
    self.hotkey = hotkey;
    if hotkey then
        self.Label:SetText("|cffffd100("..hotkey..")|r "..self.labelText);
    else
        self.Label:SetText(self.labelText);
    end
    self:SetScript("OnKeyDown", SheatheButton_OnKeyDown);
end

function NarciShowcaseSheatheButtonMixin:OnHide()
    self:SetScript("OnKeyDown", nil);
end

function NarciShowcaseSheatheButtonMixin:UpdateIcon()
    local sheathed = ModelScene.actor and ModelScene.actor:GetSheathed();
    if sheathed then
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
    else
        self.Icon:SetTexCoord(0.5, 1, 0, 1);
    end
end



local function SetUpSphereTexture(variationID)
    if variationID == 1 then
        VariationButton.Icon:SetTexCoord(0, 0.5, 0, 0.5);
    elseif variationID == 2 then
        VariationButton.Icon:SetTexCoord(0.5, 1, 0, 0.5);
    elseif variationID == 3 then
        VariationButton.Icon:SetTexCoord(0, 0.5, 0.5, 1);
    else
        VariationButton.Icon:SetTexCoord(0.5, 1, 0.5, 1);
    end
end

local VariationButtonScripts = {};

function VariationButtonScripts.OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
end

function VariationButtonScripts.OnLeave(self)
    self.Icon:SetVertexColor(0.67, 0.67, 0.67);
end

function VariationButtonScripts.OnClick(self, button)
    if button == "LeftButton" then
        VARIATION_ID = VARIATION_ID + 1;
        if VARIATION_ID > 4 then
            VARIATION_ID = 1;
        end
    else
        VARIATION_ID = VARIATION_ID - 1;
        if VARIATION_ID < 1 then
            VARIATION_ID = 4;
        end
    end
    SetUpSphereTexture(VARIATION_ID);
    ActiveActor:TryAnimation(ANIMATION_ID);
end


local function ArrowButton_OnEnter(self)
    self.Icon:SetVertexColor(0.9, 0.9, 0.9);
    IDFrame.EditBox.AnimationName:Show();
end

local function ArrowButton_OnLeave(self)
    self.Icon:SetVertexColor(0.5, 0.5, 0.5);
    IDFrame.EditBox.AnimationName:Hide();
end

local function TryNextID(direction)
    local animationID = ANIMATION_ID;
    if direction > 0 then
        if animationID >= MAX_ANIMATION_ID then
            return
        end
        animationID = animationID + 1;
        while (not UtilityModel:HasAnimation(animationID)) and (animationID < MAX_ANIMATION_ID) do
            animationID = animationID + 1;
        end
    else
        if animationID <= 0 then
            return
        end
        animationID = animationID - 1;
        while (not UtilityModel:HasAnimation(animationID)) and (animationID > 0) do
            animationID = animationID - 1;
        end
    end
    IDFrame.EditBox:SetText(animationID, true);
    IDFrame.EditBox.AnimationName:Show();
    ActiveActor:TryAnimation(animationID);
    ANIMATION_ID = animationID;
end

local function ArrowButton_OnClick(self)
    TryNextID(self.delta);
end


local EditBoxScripts = {};

function EditBoxScripts.OnEscapePressed(self)
    self:ClearFocus();
end

function EditBoxScripts.OnEnterPressed(self)
    self:ClearFocus();
end

function EditBoxScripts.OnTabPressed(self)
    self:ClearFocus();
end

function EditBoxScripts.OnEditFocusGained(self)
    self:HighlightText();
end

function EditBoxScripts.OnEditFocusLost(self)
    self:HighlightText(0, 0);
    self:SetText(self:GetNumber());
    if not self:IsMouseOver() then
        self.Highlight:Hide();
        self.AnimationName:Hide();
    end
end

function EditBoxScripts.OnTextChanged(self, userInput)
    local id = self:GetNumber();
    if id <= 0 then
        id = 0;
        self:SetText(id);
    elseif id > MAX_ANIMATION_ID then
        id = MAX_ANIMATION_ID;
        self:SetText(id);
    end
    ANIMATION_ID = id;
    self.AnimationName:SetText(GetAnimationName(id))
    if userInput then
        ActiveActor:TryAnimation(id);
    end
end

function EditBoxScripts.OnEnter(self)
    self.Highlight:Show();
    self.AnimationName:Show();
end
function EditBoxScripts.OnLeave(self)
    if not self:HasFocus() then
        self.Highlight:Hide();
        self.AnimationName:Hide();
    end
end

function EditBoxScripts.OnMouseWheel(self, delta)
    TryNextID(-delta);
end


NarciShowcaseModelSceneMixin = {};

local function ConvertCursorToFrameCoord(cursorX, cursorY, frameCenterX, frameCenterY, frameHalfWidth, frameHalfHeight)
    local ratioH = (cursorX - frameCenterX)/frameHalfWidth;
    if ratioH > 1 then
        ratioH = 1;
    elseif ratioH < -1 then
        ratioH = -1;
    end
    local ratioV = (cursorY - frameCenterY)/frameHalfHeight;
    if ratioV > 1 then
        ratioV = 1;
    elseif ratioV < -1 then
        ratioV = -1;
    end
    return ratioH, ratioV
end

local function GetCameraPlaneIntersection(camX, camY, camZ, forwardX, forwardY, forwardZ)
    local scalar = -camX / forwardX;
	return camX + scalar*forwardX, camY + scalar*forwardY, camZ + scalar*forwardZ
end

local function PlaceMountAtGroundCenter()
    --We don't want Mount to use its Z center for origin so we need to place it manually
    local x, y, z = ModelScene:GetVisualGroundCenter();
    local scale = MountActor:GetScale();
    MountActor:SetPosition(0, 0, z/scale);
    MountActor:UpdateMountShadow();
end

function NarciShowcaseModelSceneMixin:OnEnter()
    FadeFramecripts.OnEnter(FadeOptionFrame);
end

function NarciShowcaseModelSceneMixin:OnLeave()
    FadeFramecripts.OnLeave(FadeOptionFrame);
end

function NarciShowcaseModelSceneMixin:OnMouseDown(button)
    if button == "LeftButton" then
        MainFrame:SpinActor(false);
        self.leftButtonDown = true;
    elseif button == "RightButton" then
        MainFrame:SpinActor(false);
        self:ShowGuideLines(true);
        self.rightButtonDown = true;
    elseif button == "MiddleButton" then
        self:ResetView(true);
    end
    self:StartUpdating();
end

function NarciShowcaseModelSceneMixin:OnMouseUp(button)
    if button == "LeftButton" then
        self.leftButtonDown = nil;
    elseif button == "RightButton" then
        self.rightButtonDown = nil;
        self:ShowGuideLines(false);
        --[[
        local x, y, z = self.actor:GetPosition();
        local fileID = self.actor:GetModelFileID();
        print(string.format("file: %s  offsetY: %s", fileID, z));
        --]]
    end
end

function NarciShowcaseModelSceneMixin:OnHide()
    self:SetScript("OnUpdate", nil);
    self.leftButtonDown = nil;
    self.rightButtonDown = nil;
    self.zooming = nil;
end

function NarciShowcaseModelSceneMixin:OnMouseWheel(delta)
    local camX, camY, camZ = self:GetCameraPosition();
    local shiftDown = IsShiftKeyDown();
    local toX;
    if delta > 0 then
        if camX > MIN_CAM_DISTANCE then
            if shiftDown then
                toX = camX - 0.6;
            else
                toX = camX - 0.2;
            end
            if toX < MIN_CAM_DISTANCE then
                toX = MIN_CAM_DISTANCE;
            end
        else
            return
        end
    else
        if camX < MAX_CAM_DISTANCE then
            if shiftDown then
                toX = camX + 0.6;
            else
                toX = camX + 0.2;
            end
            if toX > MAX_CAM_DISTANCE then
                toX = MAX_CAM_DISTANCE;
            end
        else
            return
        end
    end

    self.fromCamX = camX;
    self.toCamX = toX;
    self.zooming = true;
    self:StartUpdating();
end

function NarciShowcaseModelSceneMixin:ShowGuideLines(state)
    self.GuideLineFrame:SetShown(state);
    if state then
        if self.updateLines then
            if not self.GuideLineFrame.lines then
                self.GuideLineFrame.lines = {};
                local f = self.GuideLineFrame;
                f.verticalLine = f:CreateTexture(nil, "OVERLAY");
                f.verticalLine:SetPoint("TOP", self, "TOP", 0, 0);
                f.verticalLine:SetPoint("BOTTOM", self, "BOTTOM", 0, 0);
                f.verticalLine:SetWidth(PIXEL * 2);
                f.verticalLine:SetColorTexture(1, 1, 1, 0.8);

                f.horizontalLine = f:CreateTexture(nil, "OVERLAY");
                f.horizontalLine:SetPoint("LEFT", self, "LEFT", 0, 0);
                f.horizontalLine:SetPoint("RIGHT", self, "RIGHT", 0, 0);
                f.horizontalLine:SetHeight(PIXEL * 2);
                f.horizontalLine:SetColorTexture(0.6, 0.6, 0.6, 0.5);

                f.actorLine = f:CreateTexture(nil, "OVERLAY");
                f.actorLine:SetHeight(4);
                f.actorLine:SetWidth(PIXEL * 2);
                f.actorLine:SetColorTexture(0.8, 0.2, 0.2, 0.8);
            end
            self.GuideLineFrame.actorLine:SetHeight(self:GetHeight() + 1);
            local lines = self.GuideLineFrame.lines;
            local lineDistance = 100 * PIXEL;
            local width = self:GetWidth();
            local height = self:GetHeight();
            local numLinesH = math.floor(width * 0.5 / lineDistance);
            local numLinesV = math.floor(height * 0.5 / lineDistance);
            local n = 0;
            for i = 1, numLinesH do
                n = n + 1;
                if not lines[n] then
                    lines[n] = self.GuideLineFrame:CreateTexture(nil, "ARTWORK");
                    lines[n]:SetColorTexture(0.6, 0.6, 0.6, 0.5);
                end
                lines[n]:ClearAllPoints();
                lines[n]:SetPoint("CENTER", self, "CENTER", lineDistance * i, 0);
                lines[n]:SetSize(PIXEL * 2, height);
                lines[n]:Show();
            end

            for i = 1, numLinesH do
                n = n + 1;
                if not lines[n] then
                    lines[n] = self.GuideLineFrame:CreateTexture(nil, "ARTWORK");
                    lines[n]:SetColorTexture(0.6, 0.6, 0.6, 0.5);
                end
                lines[n]:ClearAllPoints();
                lines[n]:SetPoint("CENTER", self, "CENTER", lineDistance * (-i), 0);
                lines[n]:SetSize(PIXEL * 2, height);
                lines[n]:Show();
            end

            for i = 1, numLinesV do
                n = n + 1;
                if not lines[n] then
                    lines[n] = self.GuideLineFrame:CreateTexture(nil, "ARTWORK");
                    lines[n]:SetColorTexture(0.6, 0.6, 0.6, 0.5);
                end
                lines[n]:ClearAllPoints();
                lines[n]:SetPoint("CENTER", self, "CENTER", 0, lineDistance * i);
                lines[n]:SetSize(width, PIXEL * 2);
                lines[n]:Show();
            end

            for i = 1, numLinesV do
                n = n + 1;
                if not lines[n] then
                    lines[n] = self.GuideLineFrame:CreateTexture(nil, "ARTWORK");
                    lines[n]:SetColorTexture(0.6, 0.6, 0.6, 0.5);
                end
                lines[n]:ClearAllPoints();
                lines[n]:SetPoint("CENTER", self, "CENTER", 0, lineDistance * (-i));
                lines[n]:SetSize(width, PIXEL * 2);
                lines[n]:Show();
            end

            for i = n + 1, #self.GuideLineFrame.lines do
                lines[i]:Hide();
            end

            self.updateLines = nil;
        end
    else

    end
end

function NarciShowcaseModelSceneMixin:ResetView(forceReset)
    if not ACTOR_IS_MOUNT or forceReset then
        self:SetCameraPosition(DEFAULT_CAM_DISTANCE, 0, 0);
        self.actor:SetPosition(0, 0, self.actor.defaultY or 0);
        self.actor:SetScale(1);
        if self.actor:IsLoaded() then
            self.actor:AdjustAlignment();
            if ACTOR_IS_MOUNT then
                PlaceMountAtGroundCenter();
            end
        end
    end
    self.zooming = nil;
end

local function ModelScene_OnUpdate(self, elapsed)
    local hasAction;

    if self.leftButtonDown then
        hasAction = true;
        local deltaX, deltaY = GetCursorDelta();
        if deltaX ~= 0 then
            local yaw;
            if ACTOR_IS_MOUNT then
                yaw = MountActor:GetYaw();
                MountActor:SetYaw(yaw + deltaX * 0.02); --0.026 when size is 800x600
            else
                yaw = self.actor:GetYaw();
                self.actor:SetYaw(yaw + deltaX * 0.02);
            end
        end
    end

    if self.rightButtonDown then
        hasAction = true;
        local px, py, pz = self:GetProjectedCursor3DPosition();
        local scale = self.actor.scale;
        local y = py - self.from3DY + self.fromActorY;
        local z = pz - self.from3DZ + self.fromActorZ;
        if ACTOR_IS_MOUNT then
            MountActor:SetPosition(0, y/scale, z/scale);
        else
            self.actor:SetPosition(0, y/scale, z/scale);
        end
        local centerX = self:Project3DPointTo2D(0, y, z);
        self.GuideLineFrame.actorLine:SetPoint("BOTTOM", self, "BOTTOMLEFT", centerX, 0);
    end

    if self.zooming then
        local diff = self.toCamX - self.fromCamX;
        if diff > 0.01 or diff < -0.01 then
            hasAction = true;
            self.fromCamX = self.fromCamX + elapsed*10*diff;
            self:SetCameraPosition(self.fromCamX, 0, 0)
        end
    end

    if not hasAction then
        self:SetScript("OnUpdate", nil);
    end

    self.actor:UpdateGroundShadow();
    if ACTOR_IS_MOUNT then
        MountActor:UpdateMountShadow();
    end
end

function NarciShowcaseModelSceneMixin:GetProjectedCursor3DPosition()
    local cursorX, cursorY = GetCursorPosition();
    local ratioH, ratioV = ConvertCursorToFrameCoord(cursorX, cursorY, self.frameCenterX, self.frameCenterY, self.frameHalfWidth, self.frameHalfHeight);
    local camX, camY, camZ = self:GetCameraPosition();
    local fx, fy, fz = self:GetCameraForward();
    local rx, ry, rz = self:GetCameraRight();
    local ux, uy, uz = self:GetCameraUp();
    local forwardOffset = 1;
    local rightOffset = -ratioH * TAN_FOV_H;
    local upOffset = ratioV * TAN_FOV_V;
    local rayFX, rayFY, rayFZ = forwardOffset*fx + rightOffset*rx + upOffset*ux, forwardOffset*fy + rightOffset*ry + upOffset*uy, forwardOffset*fz + rightOffset*rz + upOffset*uz;
    local px, py, pz = GetCameraPlaneIntersection(camX, camY, camZ, rayFX, rayFY, rayFZ);
    return px, py, pz
end

function NarciShowcaseModelSceneMixin:GetVisualGroundCenter()
    local ratioH = 0;
    local ratioV = -0.8;
    local camX, camY, camZ = self:GetCameraPosition();
    local fx, fy, fz = self:GetCameraForward();
    local rx, ry, rz = self:GetCameraRight();
    local ux, uy, uz = self:GetCameraUp();
    local forwardOffset = 1;
    local rightOffset = -ratioH * TAN_FOV_H;
    local upOffset = ratioV * TAN_FOV_V;
    local rayFX, rayFY, rayFZ = forwardOffset*fx + rightOffset*rx + upOffset*ux, forwardOffset*fy + rightOffset*ry + upOffset*uy, forwardOffset*fz + rightOffset*rz + upOffset*uz;
    local px, py, pz = GetCameraPlaneIntersection(camX, camY, camZ, rayFX, rayFY, rayFZ);
    return px, py, pz
end

function NarciShowcaseModelSceneMixin:StartUpdating()
    self.fromCursorX, self.fromCursorY = GetCursorPosition();
    self.frameCenterX, self.frameCenterY = self:GetCenter();
    local w, h = self:GetSize();
    self.frameHalfWidth, self.frameHalfHeight = 0.5*w, 0.5*h;
    self.fromActorX, self.fromActorY, self.fromActorZ = self.actor:GetPosition();
    local scale = self.actor:GetScale();
    self.fromActorX = self.fromActorX * scale;
    self.fromActorY = self.fromActorY * scale;
    self.fromActorZ = self.fromActorZ * scale;
    self.from3DX, self.from3DY, self.from3DZ = self:GetProjectedCursor3DPosition();

    self:SetScript("OnUpdate", ModelScene_OnUpdate);
end


NarciShowcaseSpinButtonMixin = {};

local function SetUpSpinTexture(self, sequence)
    local row = math.floor( (sequence - 1) * 0.25);
    local col = sequence - row * 4 - 1;
    self.SpinTexture:SetTexCoord(0.25*col, 0.25*(col + 1), 0.25*row, 0.25*(row + 1));
    self.sequence = sequence;
end

local function SpinButton_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.125 then
        self.t = 0;
        self.sequence = self.sequence + 1;
        if self.sequence > 16 then
            self.sequence = 1;
        end
        SetUpSpinTexture(self, self.sequence);
    end
end

function NarciShowcaseSpinButtonMixin:OnLoad()
    self.minTextWidth = 24;
    self.Background:SetAlpha(0.5);
    SetUpSpinTexture(self, 1);
    self:SetLabelText(L["Spin"]);
end

function NarciShowcaseSpinButtonMixin:OnEnter()
    self.t = 0.0625;
    self:SetScript("OnUpdate", SpinButton_OnUpdate);
    FadeFrame(self.Background, 0.2, 1);
end

function NarciShowcaseSpinButtonMixin:OnLeave()
    self:SetScript("OnUpdate", nil);
    FadeFrame(self.Background, 0.2, 0.5);
end

function NarciShowcaseSpinButtonMixin:OnHide()
    self:SetScript("OnUpdate", nil);
    SetUpSpinTexture(self, 1);
    self.AnimPushed:Stop();
end

function NarciShowcaseSpinButtonMixin:SetLabelText(text)
    self.Label:SetText(text);
    self:SetWidth( math.max(self.Label:GetWrappedWidth(), self.minTextWidth) + 28);
end

function NarciShowcaseSpinButtonMixin:OnMouseDown(button)
    if button == "LeftButton" then
        self.AnimPushed:Stop();
        self.AnimPushed.Hold:SetDuration(20);
        self.AnimPushed:Play();
    end
end

function NarciShowcaseSpinButtonMixin:OnMouseUp(button)
    if button == "LeftButton" then
        self.AnimPushed.Hold:SetDuration(0);
    end
end

function NarciShowcaseSpinButtonMixin:OnShow()
    self:Enable();
    self:EnableMouse(true);
end

function NarciShowcaseSpinButtonMixin:OnClick()
    MainFrame:SpinActor(true);
end

function NarciShowcaseSpinButtonMixin:FadeIn()
    self:Enable();
    self:EnableMouse(true);
    FadeFrame(self, 0.25, 1);
end

function NarciShowcaseSpinButtonMixin:FadeOut()
    self:Disable();
    self:EnableMouse(false);
    FadeFrame(self, 0.25, 0);
end


local function AnimationSlider_OnValueChangedFunc(self, value)
    ModelScene.actor:PauseAtFrame(value);
end

local function AnimationSlider_OnMouseDownFunc(self)
    LOOP_ANIMATION = false;
    LoopToggle:UpdateVisual();
end

local function SetUpTooltipText(infobutton, customText, offsetX)
    Tooltip:Hide();
    Tooltip.AnimIn:Stop();
    if infobutton then
        Tooltip:ClearAllPoints();
        Tooltip:SetPoint("TOPLEFT", infobutton, "TOPRIGHT", 2 + (offsetX or 0), 3);
        if customText then
            Tooltip.Text:SetText(customText);
        else
            Tooltip.Text:SetText(L[infobutton.tooltipKey]);
        end
        local width = Tooltip.Text:GetWrappedWidth();
        Tooltip:SetSize(width + 12, Tooltip.Text:GetHeight() + 12);
        Tooltip.AnimIn:Play();
        Tooltip:Show();
        Tooltip:SetFrameStrata("TOOLTIP");
    end
end


local DropDownPanelScripts = {};

function DropDownPanelScripts.OnShow(self)
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function DropDownPanelScripts.OnHide(self)
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    if self.parentButton then
        self.parentButton:SetFocus(false);
        self.parentButton = nil;
    end
end

function DropDownPanelScripts.OnEvent(self)
    if not (self:IsMouseOver() or (self.parentButton and self.parentButton:IsMouseOver())) then
        self:Hide();
    end
end


local OBSInfoScripts = {};

function OBSInfoScripts.OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
    local w, h = GetPhysicalScreenSize();
    w = (w - IMAGE_WIDTH)*0.5;
    h = (h - IMAGE_HEIGHT)*0.5;
    local tooltipText = string.format("OBS Settings:\nVideo Resolution: %sx%s\nCrop Filter: X:%s, Y:%s", IMAGE_WIDTH, IMAGE_HEIGHT, w, h);
    SetUpTooltipText(self, tooltipText, 8);
end

function OBSInfoScripts.OnLeave(self)
    self.Icon:SetVertexColor(0.5, 0.5, 0.5);
    SetUpTooltipText();
end


local OutlineToggleScripts = {};

OutlineToggleScripts.OnLeave = OBSInfoScripts.OnLeave;

function OutlineToggleScripts.OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
    local tooltipText = (self.state and L["Outline Hide"]) or L["Outline Show"];
    SetUpTooltipText(self, tooltipText, 8);
end

function OutlineToggleScripts.OnClick(self)
    local state = not MainFrame.OutlineFrame:IsShown();
    MainFrame.OutlineFrame:SetShown(state);
    if state then
        --self.Label:SetText(L["Outline Hide"]);
        self.Icon:SetTexCoord(0.5, 1, 0, 1);
    else
        --self.Label:SetText(L["Outline Show"]);
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
    end
    self.state = state;
    SetUpTooltipText();
end


---------------------Background Options---------------------

local function BGNode_OnClick(self)
    if self.id == 2 then
        --Image
        MainFrame.ModelScene.Backdrop:Show();
        MainFrame.ModelScene.BackdropPreview:Hide();
        MainFrame.ModelScene.Vignetting:Show();
        MainFrame.TextFrame.Divider:Hide();
        GroundShadow:Show();
        local typeID = DB.BackgroundImageType;
        if typeID and self.SubFrame.Nodes[typeID] then
            self.SubFrame.Nodes[typeID]:Click();
        else
            self.SubFrame.Nodes[1]:Click();
        end
    elseif self.id == 3 then
        --Transparent
        MainFrame.ModelScene.Backdrop:Hide();
        MainFrame.ModelScene.BackdropPreview:Hide();
        MainFrame.ModelScene.Vignetting:Show();
        MainFrame.TextFrame.Divider:Hide();
        GroundShadow:Show();
    else
        --Color
        MainFrame.ModelScene.Backdrop:Show();
        MainFrame.ModelScene.BackdropPreview:Hide();
        MainFrame.ModelScene.Vignetting:Hide();
        MainFrame.TextFrame.Divider:Show();
        if not self.SubFrame.selectedID then
            self.SubFrame.selectedID = 1;
        end
        self.SubFrame.Nodes[self.SubFrame.selectedID]:Click();
    end
    DB.BackgroundType = self.id;
end

local function BGNode_OnSelected(self, state)
    if state then
        self.Label:SetTextColor(0.8, 0.8, 0.8);
    else
        self.Label:SetTextColor(0.5, 0.5, 0.5);
    end
    if self.SubFrame then
        self.SubFrame:SetShown(state);
    end
end


local function ColorNode_OnClick(self)
    if self.id == 1 then
        GroundShadow:Show();
        MainFrame.TextFrame.Divider:Show();
        ModelScene.Backdrop:SetColorTexture(0.1, 0.1, 0.1);
    else
        GroundShadow:Hide();
        MainFrame.TextFrame.Divider:Hide();
        if self.id == 2 then
            ModelScene.Backdrop:SetColorTexture(1, 0, 0);
        elseif self.id == 3 then
            ModelScene.Backdrop:SetColorTexture(0, 1, 0);
        elseif self.id == 4 then
            ModelScene.Backdrop:SetColorTexture(0, 0, 1);
        end
    end
    self:GetParent().selectedID = self.id;
end

local function ColorNode_OnSelected(self, state)
    self.HighlightTexture:SetVertexColor(1, 1, 1, 0.5);
    self:UnlockHighlight();
end


local function UseCustomBackground(fileName)
    if fileName then
        ModelScene.Backdrop:SetTexture("Interface\\AddOns\\"..fileName);
    else
        ModelScene.Backdrop:SetColorTexture(0.1, 0.1, 0.1);
    end
end

local FileNameEditBoxScripts = {};

function FileNameEditBoxScripts.OnEscapePressed(self)
    self:ClearFocus();
end

function FileNameEditBoxScripts.OnEnterPressed(self)
    self:ClearFocus();
end

function FileNameEditBoxScripts.OnTabPressed(self)
    self:ClearFocus();
end

function FileNameEditBoxScripts.OnEditFocusGained(self)

end

function FileNameEditBoxScripts.OnEditFocusLost(self)
    self:HighlightText(0, 0);
    SetUpTooltipText();
    if not self:IsMouseOver() then
        self:GetParent():OnLeave();
    end
end

function FileNameEditBoxScripts.OnTextChanged(self, userInput)
    if userInput then
        local fileName = self:GetText();
        fileName = string.gsub(fileName, "(%..+)", "");     --remove file suffix
        if fileName and fileName ~= "" then
            UseCustomBackground(fileName);
            DB.CustomFileName = fileName;
        end
    end
end

function FileNameEditBoxScripts.OnEnter(self)
    SetUpTooltipText(self, L["File Tooltip"], 8);
    self:GetParent():OnEnter();
end
function FileNameEditBoxScripts.OnLeave(self)
    if not self:HasFocus() then
        SetUpTooltipText();
        self:GetParent():OnLeave();
    end
end

local function CreateBackgroundOptions(tab)
    local function CreateLink(parent, direction)
        local tex = parent:CreateTexture(nil, "BACKGROUND");
        tex:SetSize(6, 6);
        tex:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\NodeButton", nil, nil, "TRILINEAR");
        tex:SetVertexColor(0.25, 0.25, 0.25);
        if direction == "h" then
            tex:SetTexCoord(0, 0.25, 0.9375, 1);   --horizontal line
        else
            tex:SetTexCoord(0.25, 0.3125, 0.75, 1);   --vertical line
        end
        return tex
    end

    local function CreateSubFrame(parent)
        local f = CreateFrame("Frame", nil, parent);
        f:Hide();
        f:SetSize(14, 14);
        f:SetPoint("LEFT", parent, "LEFT", 70, 0);
        parent.SubFrame = f;
        return f
    end

    local function CreateLabel(parent, text)
        local label = parent:CreateFontString(nil, "OVERLAY", "NarciFontUniversal9");
        label:SetPoint("LEFT", parent, "RIGHT", 2, 0);
        label:SetJustifyH("LEFT");
        label:SetJustifyV("MIDDLE");
        label:SetText(text);
        parent.Label = label;
        local width = label:GetWidth();
        if width < 14 then
            width = 14;
        elseif width > 62 then
            width = 62;
        end
        parent:SetHitRectInsets(0, -width - 10, -2, -2);
        return label
    end

    local link = CreateLink(tab, "v");
    local distance = 20;
    local button;
    local labelNames = {COLOR, L["Picture"], NONE};

    for i = 1, 3 do
        button = CreateFrame("Button", nil, tab, "NarciShowcaseSharedNodeTemplate");
        button.id = i;
        button.onClickFunc = BGNode_OnClick;
        button.onSelectedFunc = nil;
        button:SetPoint("TOPLEFT", tab, "TOPLEFT", 16, -16 + distance*(1 - i));
        CreateLabel(button, labelNames[i]);
        button.onClickFunc = BGNode_OnClick;
        button.onSelectedFunc = BGNode_OnSelected;
        button.Border:SetTexCoord(0.5, 1, 0.5, 1);

        if i == 1 then
            link:SetPoint("TOP", button, "CENTER", 0, 0);
        elseif i == 3 then
            link:SetPoint("BOTTOM", button, "CENTER", 0, 0);
        end
    end

    --Colors
    local subFrame = CreateSubFrame(tab.Nodes[1]);
    link = CreateLink(subFrame, "h");
    for i = 1, 4 do
        button = CreateFrame("Button", nil, subFrame, "NarciShowcaseSharedNodeTemplate");
        button.id = i;
        button:SetPoint("LEFT", subFrame, "LEFT", 24 * (i - 1), 0);
        button.ColorTexture = button:CreateTexture(nil, "OVERLAY");
        button.ColorTexture:SetSize(16, 16);
        button.ColorTexture:SetPoint("CENTER", button, "CENTER", 0, 0);
        button.ColorTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\NodeButton", nil, nil, "TRILINEAR");
        button.ColorTexture:SetTexCoord(0.75, 1, 0, 0.25);
        button.onSelectedFunc = ColorNode_OnSelected;
        button.onClickFunc = ColorNode_OnClick;
        if i == 2 then
            button.ColorTexture:SetVertexColor(1, 0, 0);
        elseif i == 3 then
            button.ColorTexture:SetVertexColor(0, 1, 0);
        elseif i == 4 then
            button.ColorTexture:SetVertexColor(0, 0, 1);
            link:SetPoint("RIGHT", button, "CENTER", 0, 0);
        else
            if i == 1 then
                link:SetPoint("LEFT", button, "CENTER", 0, 0);
            end
            button.ColorTexture:SetVertexColor(0.2, 0.2, 0.2);
        end
    end

    --Image
    subFrame = CreateSubFrame(tab.Nodes[2]);
    for i = 1, 4 do
        button = CreateFrame("Button", nil, subFrame, "NarciShowcaseSharedNodeTemplate");
        button.id = i;
        button.onSelectedFunc = BGNode_OnSelected;
        if i == 1 then
            button:SetPoint("TOPLEFT", tab, "TOPLEFT", 86, -16);
            CreateLabel(button, CLASS);
            button.onClickFunc = function(self)
                UseCurrentClassBackground();
                DB.BackgroundImageType = self.id;
            end
        elseif i == 2 then
            button:SetPoint("TOPLEFT", tab, "TOPLEFT", 156, -16);
            CreateLabel(button, RACE);
            button.onClickFunc = function(self)
                UseCurrentRaceBackground();
                DB.BackgroundImageType = self.id;
            end
        elseif i == 3 then
            button:SetPoint("TOPLEFT", tab, "TOPLEFT", 86, -36);
            CreateLabel(button, L["Preset"]);
            button.onClickFunc = function(self)
                UseModelBackgroundImage();
                DB.BackgroundImageType = self.id;
            end
            local f = CreateFrame("Frame", nil, button, "NarciShowcaseThreeSliceFrameTemplate");
            button.SubFrame = f;
            f:SetPoint("LEFT", button.Label, "RIGHT", 4, 0);
            f:SetPoint("RIGHT", tab, "RIGHT", -16, 0);
            f:SetHeight(14);
            f:SetFrameLevel(button:GetFrameLevel() + 2);
            f.Arrow = f:CreateTexture(nil, "OVERLAY");
            f.Arrow:SetSize(14, 14);
            f.Arrow:SetPoint("RIGHT", f, "RIGHT", 0, 0);
            f.Arrow:SetTexture("Interface/AddOns/Narcissus/Art/Modules/Showcase/NewWindowMark");
            f.ValueText = f:CreateFontString(nil, "OVERLAY", "NarciFontUniversal9");
            f.ValueText:SetPoint("LEFT", f, "LEFT", 4, 0);
            f.ValueText:SetPoint("RIGHT", f, "RIGHT", -14, 0);
            f.ValueText:SetHeight(14);
            f.ValueText:SetMaxLines(1);
            f.ValueText:SetTextColor(0.9, 0.9, 0.9);
            f.ValueText:SetText("Select");
            f.ValueText:SetJustifyH("LEFT");
            f:OnLeave();
            f:SetScript("OnMouseDown", function()
                MainFrame.BackdropSelect:Toggle();
            end);
            MainFrame.BackdropSelect.swtich = f;
        elseif i == 4 then
            button:SetPoint("TOPLEFT", tab, "TOPLEFT", 86, -56);
            CreateLabel(button, L["File"]);
            button.onClickFunc = function(self)
                UseCustomBackground(DB.CustomFileName);
                self.SubFrame.EditBox:SetText(DB.CustomFileName or "");
                DB.BackgroundImageType = self.id;
            end
            local f = tab.EditFrame;
            button.SubFrame = f;
            f:SetParent(button);
            f:ClearAllPoints();
            f:SetPoint("LEFT", button.Label, "RIGHT", 4, 0);
            f:SetPoint("RIGHT", tab, "RIGHT", -16, 0);
            f.EditBox:SetJustifyH("LEFT");
            MixScripts(f.EditBox, FileNameEditBoxScripts);
        end
    end
end

--/script local a = DressUpFrame.ModelScene:GetPlayerActor();if a then a:TryOn(78416) end

------------------------------------------------------------


NarciOutfitShowcaseMixin = {};

function NarciOutfitShowcaseMixin:OnLoad()
    MainFrame = self;

    --if UISpecialFrames then
    --    table.insert(UISpecialFrames, self:GetName());
    --end
end

function NarciOutfitShowcaseMixin:OnShow()
    if self.Init then
        self:Init();
        self:RegisterEvent("DISPLAY_SIZE_CHANGED");
    end
    if self.pixelChanged then
        self:OnDisplaySizeChanged();
    end
    self:SyncModel();
    self.cvarMSAA = GetCVar("MSAAQuality");

    if self.createSplash then
        self.createSplash = nil;
        local f = CreateFrame("Frame", nil, self, "NarciShowcaseSplashFrameTemplate");
        f:SetScript("OnHide", function()
            DB.ShowSplash = false;
        end);
    end
end

function NarciOutfitShowcaseMixin:Init()
    self.Init = nil;
    NarciOutfitShowcaseMixin.Init = nil;

    ModelScene = self.ModelScene;
    ControlPanel = self.ControlPanel;
    UtilityModel = self.ModelScene.UtilityModel;
    Tooltip = self.Tooltip;
    TabSelection = self.ControlPanel.NavBar.TabSelection;
    TabSelection.x = 0;

    GroundShadow = self.ModelScene.GroundShadow;

    NarciAPI.NineSliceUtil.SetUpBackdrop(Tooltip, "rectR6");
    NarciAPI.NineSliceUtil.SetBackdropColor(Tooltip, 0.1, 0.1, 0.1);
    NarciAPI.NineSliceUtil.SetUpBorder(Tooltip, "shadowR6");
    NarciAPI.NineSliceUtil.SetBorderColor(Tooltip, 0.5, 0.5, 0.5);

    DropDownPanel = self.ControlPanel.DropDownPanel;
    DropDownPanel.Check:SetVertexColor(0.66, 0.66, 0.66);
    NarciAPI.NineSliceUtil.SetUpBackdrop(DropDownPanel, "rectR6");
    NarciAPI.NineSliceUtil.SetBackdropColor(DropDownPanel, 0.1, 0.1, 0.1);
    NarciAPI.NineSliceUtil.SetUpBorder(DropDownPanel, "shadowR6");
    NarciAPI.NineSliceUtil.SetBorderColor(DropDownPanel, 0.5, 0.5, 0.5);

    MixScripts(DropDownPanel, DropDownPanelScripts);

    PlayerActor = ModelScene:CreateActor(nil, "NarciAutoFittingActorTemplate");
    PlayerActor:SetUseCenterForOrigin(false, false, true);
    PlayerActor:SetPosition(0, 0, 0);
    ActiveActor = PlayerActor;
    ModelScene.actor = PlayerActor;
    self.actor = PlayerActor;
    ModelScene:SetCameraPosition(DEFAULT_CAM_DISTANCE, 0, 0);
    ModelScene:SetCameraOrientationByYawPitchRoll(PI, 0, 0);
    ModelScene:SetCameraFieldOfView(FOV_DIAGONAL);

    ModelScene:SetLightDiffuseColor(0.8, 0.8, 0.8);
    ModelScene:SetLightAmbientColor(0.6, 0.6, 0.6);
    ModelScene:SetLightPosition(1, 0, 1);
    ModelScene:SetLightDirection(-1, 0, -1);

    ModelScene.GuideLineFrame.Mouse:SetTexture("Interface/AddOns/Narcissus/Art/Keyboard/Mouse", nil, nil, "TRILINEAR");
    ModelScene.GuideLineFrame.Mouse:SetTexCoord(0.5, 0.75, 0, 1);
    ModelScene.GuideLineFrame.MouseLabel:SetText("Reset camera");
    --ModelScene:SetPaused(true, true);

    FadeOptionFrame = self.FadeOptionFrame;
    FadeOptionFrame.alpha = 0;
    FadeOptionFrame:SetAlpha(0);
    MixScripts(FadeOptionFrame, FadeFramecripts);

    MixScripts(FadeOptionFrame.SyncButton, SyncButtonScripts);
    FadeOptionFrame.SyncButton.AnimRotate:SetScript("OnFinished", SyncButton_OnAnimFinished);
    FadeOptionFrame.SyncButton.Label:SetText(L["Sync"]);
    FadeOptionFrame.SyncButton.Icon:SetVertexColor(0.8, 0.8, 0.8);

    MixScripts(FadeOptionFrame.TopLevelButton, TopLevelButtonScripts);
    FadeOptionFrame.TopLevelButton.Label:SetText(L["Raise Level"]);

    MixScripts(FadeOptionFrame.ItemNameToggle, ItemNameToggleScripts);

    MixScripts(FadeOptionFrame.CloseButton, CloseButtonScripts);
    CloseButtonScripts.OnLeave(FadeOptionFrame.CloseButton);

    --Animation Tab
    VariationButton = self.ControlPanel.AnimationTab.VariationButton;
    VariationButton.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/Showcase/VariationSphere", nil, nil, "TRILINEAR");
    VariationButton.Label:SetText(L["Animation Variation"]);
    MixScripts(VariationButton, VariationButtonScripts);
    VariationButtonScripts.OnLeave(VariationButton);
    SetUpSphereTexture(1);

    IDFrame = self.ControlPanel.AnimationTab.IDFrame;
    IDFrame.Label:SetText("ID");
    IDFrame.ArrowLeft:SetScript("OnEnter", ArrowButton_OnEnter);
    IDFrame.ArrowLeft:SetScript("OnLeave", ArrowButton_OnLeave);
    IDFrame.ArrowLeft:SetScript("OnClick", ArrowButton_OnClick);
    IDFrame.ArrowLeft.delta = -1;
    ArrowButton_OnLeave(IDFrame.ArrowLeft);
    IDFrame.ArrowRight:SetScript("OnEnter", ArrowButton_OnEnter);
    IDFrame.ArrowRight:SetScript("OnLeave", ArrowButton_OnLeave);
    IDFrame.ArrowRight:SetScript("OnClick", ArrowButton_OnClick);
    IDFrame.ArrowRight.delta = 1;
    ArrowButton_OnLeave(IDFrame.ArrowRight);

    MixScripts(IDFrame.EditBox, EditBoxScripts);
    IDFrame.EditBox:SetText(0);

    AnimationSlider = self.ControlPanel.AnimationTab.AnimationSlider;
    AnimationSlider.onValueChangedFunc = AnimationSlider_OnValueChangedFunc;
    AnimationSlider.onMouseDownFunc = AnimationSlider_OnMouseDownFunc;

    --Image Settings
    local widget = self.ControlPanel.LayoutTab.ImageSize;
    widget.Label:SetText(L["Image Size"]);
    widget.ValueText:SetText("800 x 600 (4:3)");

    widget = ControlPanel.LayoutTab.RotationPeriod;
    widget.Label:SetText(L["Rotation Period"]);
    widget.ValueText:SetText("4");

    widget = ControlPanel.LayoutTab.FontSize;
    widget.Label:SetText(L["Font Size"]);
    widget.ValueText:SetText("16");

    widget = self.ControlPanel.LayoutTab.OBSInfo;
    --widget.Icon:SetVertexColor(0.5, 0.5, 0.5);
    MixScripts(widget, OBSInfoScripts);
    MixScripts(self.ControlPanel.LayoutTab.OutlineToggle, OutlineToggleScripts);

    self.playerGUID = UnitGUID("player");

    --Create Navigation Buttons
    local bar = ControlPanel.NavBar;
    local navButton;
    local navButtonNames = {
        "Animation", "Image", "Quality", "Background",
    };
    for i = 1, #navButtonNames do
        navButton = CreateFrame("Button", nil, bar, "NarciShowcaseNavButtonTemplate");
        if i == 1 then
            navButton:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 4, 0);
        else
            navButton:SetPoint("BOTTOMLEFT", bar.NavButtons[i - 1], "BOTTOMRIGHT", 0, 0);
        end
        navButton:SetButtonText(L["Turntable Tab "..navButtonNames[i]]);
        navButton.id = i;
    end
    bar.NavButtons[2]:Click();


    local fps = NarciFramerateIndicator;
    fps:ClearAllPoints();
    fps:SetParent(self.ControlPanel.QualityTab);
    fps:SetPoint("TOPRIGHT", self.ControlPanel.QualityTab, "TOPRIGHT", -7, -48);
    fps:Show();

    --Backdrop Tab
    CreateBackgroundOptions(self.ControlPanel.BackgroundTab);

    --Load User Settings
    LoadSettings();

    --DEBUG Create drop-shadow
    --NarciAPI.NineSliceUtil.SetUpBorder(self.DropShadow, "shadowR0");

    self.ModelScene.BackdropPreview:SetTexture("Interface/AddOns/Narcissus/Art/Modules/Showcase/BackdropThumbnails", nil, nil, "NEAREST");
    MountToggle:UpdateIcon();
end

function NarciOutfitShowcaseMixin:UpdateWidgetSize()
    local h = 14;
    IDFrame:SetSize(4*h, h);
    IDFrame.ArrowLeft:SetSize(h, h);
    IDFrame.ArrowRight:SetSize(h, h);
    IDFrame.EditBox:SetSize(2*h, h);
    VariationButton:SetSize(h, h);
end

function NarciOutfitShowcaseMixin:UpdateTextSize()
    local multiplier = IMAGE_HEIGHT/600;
    if multiplier < 1 then
        multiplier = 1;
    end
    ITEM_TEXT_HEIGHT = PIXEL * FONT_WEIGHT * multiplier;
    PA_SPACING = PA_SPACING_WEIGHT * PIXEL * multiplier;
    local spacing = 2 * PIXEL;
    local offsetY = -PA_SPACING;
    local object;
    for i = 1, #ItemTexts.objects do
        object = ItemTexts.objects[i];
        object:SetFont(ITEM_TEXT_FONT, ITEM_TEXT_HEIGHT, FONT_EFFECT);
        object:SetSpacing(spacing);
        object:SetWidth(MAX_FONTSTRING_WIDTH);
        if i > 1 then
            object:SetPoint("TOPLEFT", ItemTexts.objects[i - 1], "BOTTOMLEFT", 0, offsetY);
        end
    end
end

function NarciOutfitShowcaseMixin:UpdateSize(resetCamera)
    local _, screenHeight = GetPhysicalScreenSize();
    local pixel = (768/screenHeight);
    PIXEL = pixel;
    local frameWidth = pixel*IMAGE_WIDTH;
    local frameHeight = pixel*IMAGE_HEIGHT;
    local modelWidth = frameHeight * MODEL_WIDTH_RATIO;
    MAX_FONTSTRING_WIDTH = frameWidth - modelWidth - (32 *2*PIXEL);
    --local modelWidth = pixel * 600;
    --local frameHeight = modelWidth *4/3;
    --local frameWidth = frameHeight*4/3;

    self:SetSize(frameWidth, frameHeight);
    self.ModelScene:SetSize(modelWidth, frameHeight);
    self.ModelScene.BackdropPreview:SetSize(frameHeight, frameHeight);
    self.BackdropSelect:SetFrameWidth(frameHeight * 4/3 - modelWidth);
    self.TextFrame.Divider:SetWidth(16 * pixel);
    self:UpdateTextSize();
    self.ModelScene.updateLines = true;
    self.pixelChanged = nil;

    local w, h = self.ModelScene:GetSize();
    local aspect = 0.5*w/h;
    self.ModelScene.Backdrop:SetTexCoord(0.5 - aspect, 0.5 + aspect, 0, 1);
    self.BackdropSelect.aspect = w/h;

    self.OutlineFrame.LeftLine:SetSize(2*pixel, frameHeight + 4*pixel);
    self.OutlineFrame.RightLine:SetSize(2*pixel, frameHeight + 4*pixel);
    self.OutlineFrame.TopLine:SetSize(frameWidth + 4*pixel, 2*pixel);
    self.OutlineFrame.BottomLine:SetSize(frameWidth + 4*pixel, 2*pixel);

    --self.ControlPanel:SetPoint("TOP", self, "BOTTOM", 0, -12*pixel);

    if resetCamera then
        self.ModelScene:ResetView();
    end
end

function NarciOutfitShowcaseMixin:UpdateMountActor(resetModel)
    local mountID;

    if MountJournal and MountJournal:IsVisible() and MountJournal.selectedMountID then
        mountID = MountJournal.selectedMountID;
    elseif IsMounted() then
        local UnitBuff = C_UnitAuras.GetBuffDataByIndex;
        local GetMountFromSpell = C_MountJournal.GetMountFromSpell;
        local i = 1;
        local spellID = 0;
        local auraData;
        while spellID do
            auraData = UnitBuff("player", i, "HELPFUL");
            spellID = auraData and auraData.spellId;
            if spellID then
                if auraData.duration == 0 then
                    mountID = GetMountFromSpell(spellID);
                    if mountID then
                        break
                    else
                        i = i + 1;
                    end
                else
                    i = i + 1;
                end
            else
                break
            end
        end
    else
        mountID = self.mountID;
    end

    if mountID == self.mountID and not resetModel then
        return
    end

    if mountID and mountID ~= 0 then
        local creatureDisplayID, _, _, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID);

        if not MountActor then
            MountActor = ModelScene:CreateActor(nil, "NarciAutoFittingActorTemplate");
            MountActor.actorType = "mount";
            MountActor:SetUseCenterForOrigin(false, false, false);
            MountActor:SetPosition(0, 0, 0);
            --MountActor:SetParticleOverrideScale(0);
        end

        if resetModel then
            MountActor:ClearModel();
        end

        MountActor:Show();
        MountActor:SetYaw(0);

        local showCustomization = true;
        MountActor:SetModelByCreatureDisplayID(creatureDisplayID, showCustomization);
        MountActor.creatureName = C_MountJournal.GetMountInfoByID(mountID);

        if (isSelfMount) then
            MountActor:SetAnimationBlendOperation(0);   --LE_MODEL_BLEND_OPERATION_NONE
            MountActor:SetAnimation(618);
        else
            MountActor:SetAnimationBlendOperation(1);    --LE_MODEL_BLEND_OPERATION_ANIM
            MountActor:SetAnimation(0);
        end

        ANIMATION_ID = 0;
        IDFrame.EditBox:SetText(0);

        local calcMountScale = MountActor:CalculateMountScale(PlayerActor);
        local inverseScale = 1 / calcMountScale;
        PlayerActor:SetScale( inverseScale );
        PlayerActor:SheatheWeapon(true);
        PlayerActor:SetYaw(0);
        PlayerActor:SetUseCenterForOrigin(false, false, false);

        if self.mountOnly then
            PlayerActor:ClearModel();
        else
            MountActor:AttachToMount(PlayerActor, animID, spellVisualKitID);    --fun fact: a new player model is generated and attached to the mount
        end

        ACTOR_IS_MOUNT = true;
        ModelScene.actor = MountActor;
        ActiveActor = MountActor;
        self.mountID = mountID;
    end
end

function NarciOutfitShowcaseMixin:SyncModel()
    --retrieve the outfit data from dressing room
    --/run NarciOutfitShowcase:SyncModel()
    local sheatheWeapons = PlayerActor:GetSheathed();
    local useNativeForm = not IsPlayerInAlteredForm();
    PlayerActor:SetScale(1);
    PlayerActor:SetModelByUnit("player", sheatheWeapons, nil, nil, useNativeForm);  --autoDress, hideWeapons
    PlayerActor.bowData = nil;

    local sourceActor;
    if WardrobeTransmogFrame and WardrobeTransmogFrame:IsVisible() and WardrobeTransmogFrame.ModelScene then
        sourceActor = WardrobeTransmogFrame.ModelScene:GetPlayerActor();
        self:UnregisterEvent("INSPECT_READY");
    elseif DressUpFrame:IsShown() then
        sourceActor = DressUpFrame.ModelScene:GetPlayerActor();
        self:UnregisterEvent("INSPECT_READY");
    else
        sourceActor = PlayerActor;
        self:RegisterEvent("INSPECT_READY");
        NotifyInspect("player");  --it seems they fixed the artifact issue
    end
    local transmogInfoList = sourceActor and sourceActor:GetItemTransmogInfoList();
    if transmogInfoList then
        PlayerActor:Undress();
        for slotID, info in pairs(transmogInfoList) do
            if slotID == 16 or slotID == 17 then
                local transmogInfo = PlayerActor:GetItemTransmogInfo(slotID);
                if not (transmogInfo and transmogInfo:IsEqual(info)) then
                    PlayerActor:SetItemTransmogInfo(info, slotID);
                end
            else
                PlayerActor:SetItemTransmogInfo(info, slotID);
            end
        end
    else
        return
    end
    PlayerActor:SheatheWeapon(sheatheWeapons);

    if self.mountMode then
        self:UpdateMountActor(true);
    end

    self:UpdateItemText(transmogInfoList);
end

local function IsValidTransmogInfo(slotID, info)
    if IsSlotValidForTransmog(slotID) then
        return (info.appearanceID > 0) and ((slotID ~= 5 and slotID ~= 19) or ( not IsHiddenVisual(info.appearanceID) ));  --skip hidden tabard/shirt
    end
end

function NarciOutfitShowcaseMixin:UpdateItemText(transmogInfoList)
    ItemTexts:Release();
    SourceCacher:Stop();
    NUM_DOUBLE_LINE_OBJECT = 0;
    local slotID, fontString;
    for i = 1, #PRINT_ORDERS do
        slotID = PRINT_ORDERS[i];
        if IsValidTransmogInfo(slotID, transmogInfoList[slotID]) then
            fontString = ItemTexts:Acquire();
            fontString:SetItemTextBySlotInfo(slotID, transmogInfoList[slotID]);
        end
    end

    --[[
    if self.mountMode and ACTOR_IS_MOUNT then
        if MountActor.creatureName then
            fontString = ItemTexts:Acquire();
            fontString:SetItemText(MountActor.creatureName);
        end
    end
    --]]

    self:UpdateAlignment();
end

function NarciOutfitShowcaseMixin:RearangeControlPanel()
    --Make ControlPanel fade if it goes out of the screen
    if self.ControlPanel:GetTop() + 4 > self:GetBottom() then
        if self.extruding then return end
        self.extruding = true;
        local function ControlPanel_OnUpdate(f, elapsed)
            f.t = f.t + elapsed;
            if f.t > 1 then
                f.t = 0;
                if f:IsMouseOver() or (DropDownPanel:IsShown() and DropDownPanel:IsMouseOver()) then
                    if f:GetAlpha() < 1 then
                        f.delta = 4;
                    else
                        f.delta = nil;
                    end
                else
                    if f:GetAlpha() > 0 then
                        f.delta = -2;
                    else
                        f.delta = nil;
                    end
                end
                if f.delta then
                    f.alpha = f:GetAlpha();
                end
            end
            if f.delta then
                f.alpha = f.alpha + f.delta * elapsed;
                if f.alpha >= 1 then
                    f.alpha = 1;
                    f.delta = nil;
                elseif f.alpha <= 0 then
                    f.alpha = 0;
                    f.delta = nil;
                end
                f:SetAlpha(f.alpha);
            end
        end
        self.ControlPanel.t = 0;
        self.ControlPanel:SetScript("OnEnter", function(f)
            f.t = 2;
        end);
        self.ControlPanel:SetScript("OnLeave", function(f)
            f.t = 0;
        end);
        self.ControlPanel:SetScript("OnUpdate", ControlPanel_OnUpdate);
    else
        if self.extruding then
            self.extruding = nil;
            self.ControlPanel:SetScript("OnEnter", nil);
            self.ControlPanel:SetScript("OnLeave", nil);
            self.ControlPanel:SetScript("OnUpdate", nil);
            self.ControlPanel:SetAlpha(1);
        end
    end
end

function NarciOutfitShowcaseMixin:OnDisplaySizeChanged(resetCamera)
    --Screen resolution / Main frame size changed
    self:UpdateSize(resetCamera);
    self:UpdateAlignment();
    PlayerActor:UpdateGroundShadow();
    self:RearangeControlPanel();
end

function NarciOutfitShowcaseMixin:OnEvent(event, ...)
    if event == "INSPECT_READY" then
        local guid = ...;
        if guid == self.playerGUID then
            self:UpdateItemText( C_TransmogCollection.GetInspectItemTransmogInfoList() );   --fix for paired weapons
            self:UnregisterEvent(event);
        end
    elseif event == "DISPLAY_SIZE_CHANGED" then
        if self:IsShown() then
            C_Timer.After(0, function()
                self:OnDisplaySizeChanged();
            end);
        else
            self.pixelChanged = true;
        end
    elseif event == "PLAYER_LOGOUT" then
        self:OnHide();
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        self:UpdateMountActor();
    end
end

function NarciOutfitShowcaseMixin:UpdateAlignment()
    local offsetY = -PA_SPACING;
    local maxWidth = 0;
    local width;
    local numObjects = #ItemTexts.objects;
    if numObjects == 0 then
        return
    end
    local object, firstObject, lastObject;
    for i = 1, numObjects do
        object = ItemTexts.objects[i];
        if object:IsShown() then
            width = object:GetWrappedWidth();
            if width > maxWidth then
                maxWidth = width;
            end
            object:ClearAllPoints();
            if firstObject then
                object:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, offsetY);
            else
                object:SetPoint("TOPLEFT", self.TextFrame, "TOPLEFT", 0, 0);
                firstObject = object;
            end
            lastObject = object;
        end
    end

    if not firstObject then return end

    local textHeight = firstObject:GetTop() - lastObject:GetBottom();
    local frameWidth, frameHeight = self.TextFrame:GetSize();
    firstObject:ClearAllPoints();
    firstObject:SetPoint("TOPLEFT", self.TextFrame, "TOPLEFT", (frameWidth-maxWidth)*0.5, (textHeight - frameHeight)*0.5);
    self.TextFrame.Divider:SetHeight(textHeight + 64*PIXEL);
end

function NarciOutfitShowcaseMixin:SetModelFromTarget()
    local unit = "target";
    if UnitIsPlayer(unit) then
        PlayerActor:SetModelByUnit(unit);
    end
end

function NarciOutfitShowcaseMixin:GetPixelSize()
    return PIXEL, IMAGE_HEIGHT/600;
end

local function Turntable_OnUpdate(self, elapsed)
    self.yaw = self.yaw + elapsed * PI2 * ROTATION_PERIOD;
    ActiveActor:SetYaw(self.yaw);
end

function NarciOutfitShowcaseMixin:SpinActor(state)
    state = state and self:IsVisible();
    if state then
        self.yaw = ActiveActor:GetYaw();
        self:SetScript("OnUpdate", Turntable_OnUpdate);
        FadeOptionFrame.SpinButton:FadeOut();
    else
        self:SetScript("OnUpdate", nil);
        self.yaw = nil;
        FadeOptionFrame.SpinButton:FadeIn();
    end
    self.isSpinning = state;
end

function NarciOutfitShowcaseMixin:OnHide()
    SetUpTooltipText();
    if self.cvarChanged and self.cvarMSAA then
        SetCVar("MSAAQuality", self.cvarMSAA);
        self.cvarMSAA = nil;
    end
    self:Hide();
    self:SpinActor(false);
    PlayerActor:SetYaw(0);
    self:UnregisterEvent("PLAYER_LOGOUT");
    self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    if self.dressingRoomButton then
        self.dressingRoomButton.Icon:SetTexCoord(0.5, 0.75, 0.5, 0.75);
    end
end

function NarciOutfitShowcaseMixin:MarkCVarChanged()
    self.cvarChanged = true;
    self:RegisterEvent("PLAYER_LOGOUT");
end

function NarciOutfitShowcaseMixin:Close()
    self:Hide();
end

function NarciOutfitShowcaseMixin:Open()
    self:Show();
    self:Raise();
    if self.dressingRoomButton then
        self.dressingRoomButton.Icon:SetTexCoord(0.75, 1, 0.5, 0.75);
    end
end

function NarciOutfitShowcaseMixin:SetImageSize(sizes)
    local width, height = sizes[1], sizes[2];
    if width * height < 10000 then
        return
    end

    local ratio = math.floor(100*width/height)/100;

    local resetCamera;
    if ratio ~= self.lastRatio then
        self.lastRatio = ratio;
        resetCamera = true;
    end

    MODEL_WIDTH_RATIO = ratio;
    if ratio > 1 then
        MODEL_WIDTH_RATIO = 0.75;
    end
    if ratio == 1 then
        ratio = "1:1";
    elseif ratio == 0.75 then
        ratio = "3:4";
    elseif ratio == 1.33 then
        ratio = "4:3";
    elseif ratio == "1.77" then
        ratio = "16:9";
        MODEL_WIDTH_RATIO = 1;
    else
        ratio = "custom";
    end

    IMAGE_WIDTH = width;
    IMAGE_HEIGHT = height;
    self:OnDisplaySizeChanged(resetCamera);
    self.ControlPanel.LayoutTab.ImageSize.ValueText:SetText( string.format("%d x %d (%s)", width, height, GetScreenAspectText(width, height)) );

    if SHOW_ITEM_NAME then
        LAST_IMAGE_SIZE_WITH_TEXT = sizes;
        DB.ImageWidth = width;
        DB.ImageHeight = height;
    else
        LAST_IMAGE_SIZE_NO_TEXT = sizes;
        DB.NoTextImageWidth = width;
        DB.NoTextImageHeight = height;
    end

    TAN_FOV_H = ConvertHorizontalFoV(FOV_VERTICAL, height/width);
end

function NarciOutfitShowcaseMixin:SetFontWeight(weight)
    FONT_WEIGHT = weight;
    self:UpdateTextSize();
    self:UpdateAlignment();
    self.ControlPanel.LayoutTab.FontSize.ValueText:SetText(weight);

    DB.FontSize = weight;
end

function NarciOutfitShowcaseMixin:SetRotationPeriod(seconds, pause)
    if seconds > 2 then
        ROTATION_PERIOD = 1/seconds;
        self:SpinActor(not pause);
        self.ControlPanel.LayoutTab.RotationPeriod.ValueText:SetText(string.format("%d s", seconds));
        DB.Period = seconds;
    else
        ROTATION_PERIOD = 2;
    end
end

function NarciOutfitShowcaseMixin:ShowItemText(state)
    self.TextFrame:SetShown(state);
    SHOW_ITEM_NAME = state;
    local b = FadeOptionFrame.ItemNameToggle;
    if state then
        self:SetImageSize(LAST_IMAGE_SIZE_WITH_TEXT or {800, 600});
        b.Icon:SetTexCoord(0.5, 1, 0, 1);
        b.Label:SetText(L["Item Name Hide"]);
        DropDownOptions.imageSizeValid = DropDownOptions.imageSizeWithText;
    else
        self:SetImageSize(LAST_IMAGE_SIZE_NO_TEXT or {450, 600});
        b.Icon:SetTexCoord(0, 0.5, 0, 1);
        b.Label:SetText(L["Item Name Show"]);
        DropDownOptions.imageSizeValid = DropDownOptions.imageSizeNoText;
    end
    DB.ShowItemName = state;
end

function NarciOutfitShowcaseMixin:ShowTab(id)
    self.ControlPanel.AnimationTab:SetShown(id == 1);
    self.ControlPanel.LayoutTab:SetShown(id == 2);
    self.ControlPanel.QualityTab:SetShown(id == 3);
    self.ControlPanel.BackgroundTab:SetShown(id == 4);
end

function NarciOutfitShowcaseMixin:SetMountMode(state, mountOnly)
    self.mountMode = state;
    if state then
        self.mountOnly = mountOnly;
        self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
        self:UpdateMountActor();
    else
        self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
        self.mountID = nil;
        self.mountOnly = nil;
        if ACTOR_IS_MOUNT then
            ACTOR_IS_MOUNT = false;
            PlayerActor:SetUseCenterForOrigin(false, false, true);
            PlayerActor:ResetAnimation();
            MountActor:Hide();
            MountActor:ClearModel();
            ModelScene.actor = PlayerActor;
            ActiveActor = PlayerActor;
        end
        ANIMATION_ID = 0;
        IDFrame.EditBox:SetText(0);
    end

    MainFrame:SyncModel();
    MountToggle:UpdateIcon();

    if LOOP_ANIMATION then
        ActiveActor:TryAnimation(ANIMATION_ID);
    end
end


NarciAutoFittingActorMixin = {};

function NarciAutoFittingActorMixin:OnLoad()
    self.parentScene = self:GetParent();
    self.scale = 1;
    self.feetZ = -0.5;
    self.leftX = 0.5;
    self.rightX = 0.5;
end

function NarciAutoFittingActorMixin:TryAnimation(animationID)
    self:SetPaused(false);
    self.t = 0;
    self.isPlaying = true;
    self:SetAnimation(animationID, VARIATION_ID, 1);
    AnimationSlider:SetCeiling();
    if animationID ~= self.animationID then
        self.animationID = animationID;
        self.parentScene:ResetView();
    end
end

function NarciAutoFittingActorMixin:OnAnimFinished()
    self:SetPaused(true);
    self.isPlaying = false;

    if self.t then
        --print("Duration: "..self.t);
        AnimationSlider:SetCeiling(self.t * 1000);
    end

    if LOOP_ANIMATION then
        self:TryAnimation(self.animationID);    --loop animation
    end
end

function NarciAutoFittingActorMixin:OnUpdate(elapsed)
    if self.isPlaying then
        self.t = self.t + elapsed;
        AnimationSlider:SetValue(1000 * self.t);
    end
end

function NarciAutoFittingActorMixin:PauseAtFrame(millisecond)
    self.isPlaying = false;
    self.f = millisecond*0.001;
    self:SetAnimation(ANIMATION_ID, VARIATION_ID, 1, self.f);
    self:SetPaused(true);
end

function NarciAutoFittingActorMixin:ResetAnimation()
    self.isPlaying = false;
    self:SetAnimation(ANIMATION_ID, VARIATION_ID, 1, self.f or 0);
    self:SetPaused(true);
end

function NarciAutoFittingActorMixin:UpdateGroundShadow()
    local x, y, z = self:GetPosition();
    x, y, z = x*self.scale, y*self.scale, z*self.scale;
    local feetX, feetY = self.parentScene:Project3DPointTo2D(x, y, z + self.feetZ);

    GroundShadow:ClearAllPoints();
    GroundShadow:SetPoint("CENTER", self.parentScene, "BOTTOMLEFT", feetX, feetY);
    local leftX = self.parentScene:Project3DPointTo2D(x, y + self.leftX, z + self.feetZ);
    local rightX = self.parentScene:Project3DPointTo2D(x, y + self.rightX, z + self.feetZ);
    if not (leftX and rightX) then
        return
    end
    local width = leftX - rightX + 25;
    if width < 0 then
        width = -width;
    end
    GroundShadow:SetSize(width, 0.5*width);
end

function NarciAutoFittingActorMixin:UpdateMountShadow()
    local x, y, z = self:GetPosition();
    x, y, z = x*self.scale, y*self.scale, z*self.scale;
    local feetX, feetY = self.parentScene:Project3DPointTo2D(x, y, z);

    GroundShadow:ClearAllPoints();
    GroundShadow:SetPoint("CENTER", self.parentScene, "BOTTOMLEFT", feetX, feetY);
    local leftX = self.parentScene:Project3DPointTo2D(x, y - self.averageSpan, 0);
    local rightX = self.parentScene:Project3DPointTo2D(x, y + self.averageSpan, 0);
    if not (leftX and rightX) then
        return
    end
    local width = leftX - rightX;
    if width < 0 then
        width = -width;
    end
    GroundShadow:SetSize(width, 0.5*width);
end

function NarciAutoFittingActorMixin:AdjustAlignment()
    local a, b, c, d, e, f = self:GetActiveBoundingBox();

    local scene = self.parentScene;
    local w, h = scene:GetSize();

    local depth, width, height = d - a, e - b, f - c;
    --print(depth, width, height)
    self.width = width;

    self.averageSpan = (depth + width) * 0.2;   --used to calculate shadow size
    if self.averageSpan > 0.8 then
        self.averageSpan = 0.8;
    end

    d = depth*0.5;
    a = -d;
    e = width*0.5;
    b = -e;
    f = height*0.5;
    c = -f;

    a,d = 0, 0;
    local x1, y1 = scene:Project3DPointTo2D(a, b, c);
    local x2, y2 = scene:Project3DPointTo2D(a, b, f);
    local x3, y3 = scene:Project3DPointTo2D(a, e, c);
    local x4, y4 = scene:Project3DPointTo2D(a, e, f);
    local x5, y5 = scene:Project3DPointTo2D(d, b, c);
    local x6, y6 = scene:Project3DPointTo2D(d, b, f);
    local x7, y7 = scene:Project3DPointTo2D(d, e, c);
    local x8, y8 = scene:Project3DPointTo2D(d, e, f);

    local minX = min(x1, x2, x3, x4, x5, x6, x7, x8);
    local maxX = max(x1, x2, x3, x4, x5, x6, x7, x8);
    local minY = min(y1, y2, y3, y4, y5, y6, y7, y8);
    local maxY = max(y1, y2, y3, y4, y5, y6, y7, y8);

    local spanX = maxX - minX;
    local spanY = maxY - minY;

    local scale = min(0.8*h/spanY, 0.8*w/spanX);
    self:SetScale(scale);
    self.scale = scale;

    a, b, c, d, e, f = a*scale, b*scale, c*scale, d*scale, e*scale, f*scale
    self.feetZ = c;
    self.leftX = e;
    self.rightX = b;
    x1, y1 = scene:Project3DPointTo2D(a, b, c);
    x2, y2 = scene:Project3DPointTo2D(a, b, f);
    x3, y3 = scene:Project3DPointTo2D(a, e, c);
    x4, y4 = scene:Project3DPointTo2D(a, e, f);
    x5, y5 = scene:Project3DPointTo2D(d, b, c);
    x6, y6 = scene:Project3DPointTo2D(d, b, f);
    x7, y7 = scene:Project3DPointTo2D(d, e, c);
    x8, y8 = scene:Project3DPointTo2D(d, e, f);

    minX = min(x1, x2, x3, x4, x5, x6, x7, x8);
    maxX = max(x1, x2, x3, x4, x5, x6, x7, x8);
    minY = min(y1, y2, y3, y4, y5, y6, y7, y8);
    maxY = max(y1, y2, y3, y4, y5, y6, y7, y8);

    
    --[[
    local centerX = (maxX + minX)*0.5;
    local centerY = (maxY + minY)*0.5;
    scene.P1:ClearAllPoints();
    scene.P2:ClearAllPoints();
    scene.P3:ClearAllPoints();
    scene.P4:ClearAllPoints();
    scene.P1:SetPoint("CENTER", scene, "BOTTOMLEFT", minX, minY);
    scene.P2:SetPoint("CENTER", scene, "BOTTOMLEFT", maxX, minY);
    scene.P3:SetPoint("CENTER", scene, "BOTTOMLEFT", minX, maxY);
    scene.P4:SetPoint("CENTER", scene, "BOTTOMLEFT", maxX, maxY);
    local x, y = scene:Project3DPointTo2D(0, 0, 0);
    --]]
    

    self:UpdateGroundShadow();
end

function NarciAutoFittingActorMixin:OnModelLoaded()
    local fileID = self:GetModelFileID();
    if fileID then
        UtilityModel:SetModel(fileID);
    end
    self.defaultY = GetModelOffsetZ(fileID);
    self:SetPosition(0, 0, self.defaultY);
    self:AdjustAlignment();
    self:SetPaused(true);
    AnimationSlider:Reset();

    if self.actorType == "mount" then
        PlaceMountAtGroundCenter();
    end
end


function NarciAutoFittingActorMixin:SheatheWeapon(state)
    self:SetSheathed(state);
    if self.bowData then
        if state then
            self:SetItemTransmogInfo(self.bowData, 16);
        else
            self:SetItemTransmogInfo(self.bowData, 17); --swtich bow to the left hand
            self:UndressSlot(16);
        end
    end
    SheatheButton:UpdateIcon();
end

--/run NarciOutfitShowcase:SetModelFromTarget()


NarciShowcaseItemTextMixin = {};    --advanced formating

function NarciShowcaseItemTextMixin:SetItemText(text)
    self:SetMaxLines(2);
    self:SetText(text);
    if true then return end
    local width0 = self:GetUnboundedStringWidth();
    local width1 = self:GetWrappedWidth();
    local diff = width0 - width1;
    if diff < 0.25*width1 then
        self:SetMaxLines(1);
    else
        if NUM_DOUBLE_LINE_OBJECT <= MAX_DOUBLE_LINE_OBJECT then
            self:SetMaxLines(2);
            NUM_DOUBLE_LINE_OBJECT = NUM_DOUBLE_LINE_OBJECT + 1;
        else
            self:SetMaxLines(1);
        end
    end
end

function NarciShowcaseItemTextMixin:SetItemTextBySourceID(sourceID)
    self:SetItemText(TransmogDataProvider:GetSourceName(sourceID));
end

function NarciShowcaseItemTextMixin:SetItemTextBySlotInfo(slotID, transmogInfo)
    local sourceID = transmogInfo.appearanceID;
    if IsHiddenVisual(sourceID) then
        self:SetTextColor(0.5, 0.5, 0.5);
    else
        self:SetTextColor(0.8, 0.8, 0.8);
    end
    local name = TransmogDataProvider:GetSourceName(sourceID);
    if not name or name == "" then
        SourceCacher:AddToQueue(self, sourceID);
    end
    if slotID == 3 then
        --Shoulders
        local secondID = transmogInfo.secondaryAppearanceID;
        if secondID and secondID > 0 and secondID ~= sourceID then
            self:SetText("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\ShoulderMark:12:12:0:0:64:64:0:32:0:64|t "..name);
            name = TransmogDataProvider:GetSourceName(transmogInfo.secondaryAppearanceID);
            local fontString = ItemTexts:Acquire();
            if name and name ~= "" then
                fontString:SetText("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\ShoulderMark:12:12:0:0:64:64:32:64:0:64|t "..name);
            else
                SourceCacher:AddToQueue(fontString, secondID);
            end
            if IsHiddenVisual(secondID) then
                fontString:SetTextColor(0.5, 0.5, 0.5);
            else
                fontString:SetTextColor(0.8, 0.8, 0.8);
            end
        else
            self:SetText(name);
        end
    else
        if slotID == 16 or slotID == 17 then
            if TransmogDataProvider:IsLegionArtifactBySourceID(sourceID) then
                local artifactAppearanceSetName = TransmogDataProvider:GetArtifactAppearanceSetName(sourceID);
                if artifactAppearanceSetName and name ~= artifactAppearanceSetName then
                    name = name .. " ("..artifactAppearanceSetName..")";
                end
            end
            self:SetItemText(name);

            if TransmogDataProvider:IsSourceBow(sourceID) then
                ModelScene.actor.bowData = transmogInfo;
                ModelScene.actor:UndressSlot(16);
                ModelScene.actor:SetItemTransmogInfo(transmogInfo, 17);
            else
                local currentInfo = PlayerActor:GetItemTransmogInfo(slotID);
                if not (currentInfo and currentInfo:IsEqual(transmogInfo)) then
                    PlayerActor:SetItemTransmogInfo(transmogInfo, slotID);
                end
            end

            --Weapons
            sourceID = transmogInfo.illusionID;
            if sourceID > 0 and sourceID ~= 5360 then    --0 ~ Constants.Transmog.NoTransmogID / 5360 ~ Hide Weapon Enchant
                name = TransmogDataProvider:GetIllusionName(transmogInfo.illusionID);
                local fontString = ItemTexts:Acquire();
                if name and name ~= "" then
                    --fontString:SetText("|cff808080└|r "..name);
                    fontString:SetText("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\SubTextMark:12:12:0:0:64:64:0:64:0:64|t"..name);
                else
                    SourceCacher:AddToQueue(fontString, sourceID);
                end
            end
        else
            self:SetItemText(name);
        end
    end
end


NarciOutfitInfoButtonMixin = {};

function NarciOutfitInfoButtonMixin:OnLoad()
    self.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/Showcase/InfoButton", nil, nil, "LINEAR");
    self.Icon:SetTexCoord(0, 0.5, 0, 1);
    self:SetColor(0.3, 0.3, 0.3);
end

function NarciOutfitInfoButtonMixin:OnEnter()
    self:SetColor(0.5, 0.5, 0.5);
    SetUpTooltipText(self, nil, 8);
    SetCursor("Interface/CURSOR/UnableQuestTurnIn.blp");
end

function NarciOutfitInfoButtonMixin:OnLeave()
    self:SetColor(0.3, 0.3, 0.3);
    SetUpTooltipText();
    ResetCursor();
end

function NarciOutfitInfoButtonMixin:SetColor(r, g, b)
    self.Icon:SetVertexColor(r, g, b);
end


NarciShowcaseThreeSliceFrameMixin = {};

function NarciShowcaseThreeSliceFrameMixin:OnLoad()
    self:SetBackdropColor(0.25, 0.25, 0.25);
end

function NarciShowcaseThreeSliceFrameMixin:SetBackdropColor(r, g, b)
    self.BackdropLeft:SetVertexColor(r, g, b);
    self.BackdropRight:SetVertexColor(r, g, b);
    self.BackdropCenter:SetVertexColor(r, g, b);
end

function NarciShowcaseThreeSliceFrameMixin:OnEnter()
    self:SetBackdropColor(0.35, 0.35, 0.35);
    if self.Arrow then
        self.Arrow:SetVertexColor(0.9, 0.9, 0.9);
    end
end

function NarciShowcaseThreeSliceFrameMixin:OnLeave()
    self:SetBackdropColor(0.25, 0.25, 0.25);
    if self.Arrow then
        self.Arrow:SetVertexColor(0.5, 0.5, 0.5);
    end
end


NarciShowcaseDropDownFrameMixin = CreateFromMixins(NarciShowcaseThreeSliceFrameMixin);

function NarciShowcaseDropDownFrameMixin:OnLoad()
    self:SetBackdropColor(0.25, 0.25, 0.25);
    self.Arrow:SetVertexColor(0.5, 0.5, 0.5);
    if self.InfoButton then
        self.Label:ClearAllPoints();
        self.Label:SetPoint("RIGHT", self, "LEFT", -20, 0);
    end
end

function NarciShowcaseDropDownFrameMixin:SetFocus(state)
    self.isFocused = state;
    self:UpdateArrow();
    if state then
        self:SetFrameLevel(8);
    else
        self:SetFrameLevel(4);
    end
end

function NarciShowcaseDropDownFrameMixin:IsFocused()
    return self.isFocused
end

function NarciShowcaseDropDownFrameMixin:OnHide()
    self.isFocused = nil;
    self:SetBackdropColor(0.25, 0.25, 0.25);
    self.Arrow:SetVertexColor(0.5, 0.5, 0.5);
end

function NarciShowcaseDropDownFrameMixin:UpdateArrow()
    if self.isFocused then
        self.Arrow:SetTexCoord(0, 1, 1, 0);
    else
        self.Arrow:SetTexCoord(0, 1, 0, 1);
    end
end

function NarciShowcaseDropDownFrameMixin:OnMouseDown(button)
    if button == "LeftButton" then
        SetUpDropDown(self, self.menuName);
    end
end

NarciShowcaseDropDownButtonMixin = {};

function NarciShowcaseDropDownButtonMixin:OnMouseDown(button)
    if button == "LeftButton" then
        self.ButtonText:SetPoint("LEFT", self, "LEFT", 14, -0.6);
    end
end

function NarciShowcaseDropDownButtonMixin:OnMouseUp()
    self.ButtonText:SetPoint("LEFT", self, "LEFT", 14, 0);
end

function NarciShowcaseDropDownButtonMixin:OnClick(button)
    if button == "LeftButton" then
        local method = self:GetParent().method;
        MainFrame[method](MainFrame, self.value);
        SetUpDropDown();
    end
end

function NarciShowcaseDropDownButtonMixin:OnEnter()
    self.ButtonText:SetTextColor(0.9, 0.9, 0.9);
end

function NarciShowcaseDropDownButtonMixin:OnLeave()
    self.ButtonText:SetTextColor(0.67, 0.67, 0.67);
end

function NarciShowcaseDropDownButtonMixin:OnHide()
    self:OnMouseUp();
end


function NarciShowcaseDropDownButtonMixin:SetValueText(text)
    self.ButtonText:SetText(text);
end


local function TabSelection_OnUpdate(self, elapsed)
    local complete;
    local diff = self.toX - self.x;
    local delta = elapsed * 16 * diff;
    if diff >= 0 and (diff < 1 or (self.x + delta >= self.toX)) then
        self.x = self.toX;
        complete = true;
    elseif diff <= 0 and (diff > -1 or (self.x + delta <= self.toX)) then
        self.x = self.toX;
        complete = true;
    else
        self.x = self.x + delta;
    end

    diff = self.toWidth - self.width;
    delta = elapsed * 16 * diff;
    if diff >= 0 and (diff < 1 or (self.width + delta >= self.toWidth)) then
        self.width = self.toWidth;
        complete = complete and true;
    elseif diff <= 0 and (diff > -1 or (self.width + delta <= self.toWidth)) then
        self.width = self.toWidth;
        complete = complete and true;
    else
        self.width = self.width + delta;
        complete = false;
    end

    if complete then
        self:SetScript("OnUpdate", nil);
    end

    self:SetPoint("BOTTOM", ControlPanel.NavBar, "BOTTOMLEFT", self.x, 0);
    self.Center:SetWidth(self.width);
end


NarciShowcaseNavButtonMixin = {};

function NarciShowcaseNavButtonMixin:OnEnter()
    if not self.selected then
        self.ButtonText:SetTextColor(0.9, 0.9, 0.9);
    end
end

function NarciShowcaseNavButtonMixin:OnLeave()
    if not self.selected then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciShowcaseNavButtonMixin:OnMouseDown()
    if not self.selected then
        self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, -0.6);
    end
end

function NarciShowcaseNavButtonMixin:OnMouseUp()
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciShowcaseNavButtonMixin:OnClick()
    if self.selected then return end;

    for _, button in pairs( self:GetParent().NavButtons ) do
        button:SetSelection( button == self );
    end
    MainFrame:ShowTab(self.id);

    local leftX = self:GetParent():GetLeft();
    local buttonX = self:GetCenter();
    TabSelection.width = TabSelection.Center:GetWidth();
    TabSelection.toWidth = self.ButtonText:GetWidth();
    TabSelection.toX = buttonX - leftX;
    TabSelection:SetScript("OnUpdate", TabSelection_OnUpdate);
end

function NarciShowcaseNavButtonMixin:SetSelection(state)
    self.selected = state;
    if state then
        self.ButtonText:SetTextColor(0.188, 0.506, 0.8);
    else
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciShowcaseNavButtonMixin:SetButtonText(text)
    self.ButtonText:SetText(text);
    self:SetWidth( math.max(self.ButtonText:GetWidth() + 8, 48) );
end


NarciShowcaseMountToggleMixin = {};

function NarciShowcaseMountToggleMixin:OnLoad()
    MountToggle = self;
end

function NarciShowcaseMountToggleMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);
    local tooltipText = (MainFrame.mountMode and L["Hide Mount"] or L["Show Mount"]);
    SetUpTooltipText(self, tooltipText, 8);
end

function NarciShowcaseMountToggleMixin:OnLeave()
    if not self.isOn then
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    end
    SetUpTooltipText();
end

function NarciShowcaseMountToggleMixin:OnClick(button)
    MainFrame:SetMountMode(not MainFrame.mountMode, button == "RightButton");
    SetUpTooltipText();
end

function NarciShowcaseMountToggleMixin:UpdateIcon()
    if MainFrame.mountMode then
        if MainFrame.mountOnly then
            self.Icon:SetTexCoord(0.5, 1, 0.5, 1);
        else
            self.Icon:SetTexCoord(0.5, 1, 0, 0.5);
        end
        self.isOn = true;
    else
        self.Icon:SetTexCoord(0, 0.5, 0, 0.5);
        self.isOn = nil;
    end
end

NarciShowcaseLoopToggleMixin = {};

function NarciShowcaseLoopToggleMixin:OnLoad()
    LoopToggle = self;

    local _, _, raceID = UnitRace("player");
    local sex = UnitSex("player");
    self.isKultiran = (sex == 2 and raceID == 32) or nil;
end

function NarciShowcaseLoopToggleMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);
    if self.isKultiran then
        SetUpTooltipText(self, L["Loop Animation Alert Kultiran"], 8);
    else
        SetUpTooltipText(self, L["Loop Animation On"], 8);
    end
end

function NarciShowcaseLoopToggleMixin:OnLeave()
    if not LOOP_ANIMATION then
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    end
    SetUpTooltipText();
end

function NarciShowcaseLoopToggleMixin:OnClick()
    LOOP_ANIMATION = not LOOP_ANIMATION;

    if LOOP_ANIMATION then
        ActiveActor:TryAnimation(ANIMATION_ID);
    else
        ActiveActor:OnAnimFinished();
    end

    self:UpdateVisual();
    SetUpTooltipText();
end

function NarciShowcaseLoopToggleMixin:UpdateVisual()
    if LOOP_ANIMATION then
        self.Icon:SetTexCoord(0.5, 1, 0, 1);
    else
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
    end
end


--/script local m=MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped");if m then m:SetAnimation(97) end;