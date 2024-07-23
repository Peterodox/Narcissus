local _, addon = ...

local outQuart = addon.EasingFunctions.outQuart;
local LoadingBarUtil = addon.TalentTreeLoadingBarUtil;
local DataProvider = addon.TalentTreeDataProvider;
local GetPixelForWidget = NarciAPI.GetPixelForWidget;
local SetSpecialization = SetSpecialization;


local FONT_PIXEL_SIZE = 16;
local BUTTON_PIXEL_HEIGHT = 56;
local TAB_PIXEL_WIDTH = 216;

do
    local function ChangePixelSize(sizeInfo)
        FONT_PIXEL_SIZE = sizeInfo.fontHeight;
        BUTTON_PIXEL_HEIGHT = sizeInfo.specButtonHeight;
        TAB_PIXEL_WIDTH = sizeInfo.specTabWidth;
    end
    addon.TalentTreeTextureUtil:AddSizeChangedCallback(ChangePixelSize);
end

local SideFrame, Clipboard;
local SpecButtons = {};

local UnitCastingInfo = UnitCastingInfo;
local function IsCasting()
    return UnitCastingInfo("player");
end

local ActionValidityCheck = {};
ActionValidityCheck.IsFlying = IsFlying;
ActionValidityCheck.IsPlayerMoving = IsPlayerMoving;
ActionValidityCheck.InCombatLockdown = InCombatLockdown;
ActionValidityCheck.IsCasting = IsCasting;    --return ~= nil

function ActionValidityCheck:IsValid()
    return not(self.IsPlayerMoving() or self.IsFlying() or self.InCombatLockdown() or self.IsCasting())
end

local function SpecTab_OnEvent(self, event, ...)
    if ActionValidityCheck:IsValid() then
        SideFrame:LockAction(false);
    else
        SideFrame:LockAction(true);
    end
end

local function SpecTab_OnShow(self)
    if ActionValidityCheck:IsValid() then
        SideFrame:LockAction(false, true);
    else
        SideFrame:LockAction(true, true);
    end
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    self:RegisterEvent("PLAYER_STARTED_MOVING");
    self:RegisterEvent("PLAYER_STOPPED_MOVING");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:SetScript("OnEvent", SpecTab_OnEvent);
end

local function SpecTab_OnHide(self)
    self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
    self:UnregisterEvent("PLAYER_STARTED_MOVING");
    self:UnregisterEvent("PLAYER_STOPPED_MOVING");
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    self:SetScript("OnEvent", nil);
end

local function SpecButton_OnEnter(self)
    if not self.selected then
        self.Name:SetTextColor(0.92, 0.92, 0.92);
        self.Icon:SetAlpha(0.67);
    end
end

local function SpecButton_OnLeave(self)
    if not self.selected then
        self.Name:SetTextColor(0.67, 0.67, 0.67);
        self.Icon:SetAlpha(0.25);
    end
end

local function SpecButton_OnClick(self, button)
    if LoadingBarUtil:IsBarVisible() then
        return
    end

    if self.selected or button ~= "LeftButton" then
        SideFrame:CloseFrame();
    else
        SideFrame.SpecTab.t = 2;
        if ActionValidityCheck:IsValid() then
            LoadingBarUtil:SetFromSpecButton(self);
            if ClassTalentHelper and ClassTalentHelper.SwitchToSpecializationByIndex then
                ClassTalentHelper.SwitchToSpecializationByIndex(self.specIndex);
            else
                SetSpecialization(self.specIndex, false);
            end
        end
    end
end

local function SpecButton_SetSelected(self, state)
    if state then
        if not self.selected then
            self.selected = true;
            self.Icon:SetDesaturated(false);
            self.Icon:SetAlpha(0.75);
            self.Name:SetTextColor(1, 0.82, 0);
            self.Underline:Show();
            SideFrame.activeButton = self;
        end
    elseif self.selected or self.selected == nil then
        self.selected = false;
        self.Icon:SetDesaturated(true);
        SpecButton_OnLeave(self);
        self.Underline:Hide();
    end
end

local function ShowFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local width = outQuart(self.t, 16, self.fullWidth, self.d);
    local alpha = self.t * 5;
    if self.t > self.d then
        width = self.fullWidth;
        self:SetScript("OnUpdate", nil);
        self:OnTabExpaned();
    end
    if alpha > 1 then
        alpha = 1
    end
    if self.t > 0.2 and self.buttonLocked then
        self.buttonLocked = nil;
        if not self.actionLocked then
            self:LockSpecButtons(false);
        end
    end
    self:SetAlpha(alpha);
    self.ClipFrame:SetWidth(width);
end

NarciTalentTreeSideTabMixin = {};

function NarciTalentTreeSideTabMixin:OnLoad()
    SideFrame = self;
    Clipboard = self.InspectTab.Clipboard;
    self:SetMode("class");
    self.SpecTab:SetScript("OnShow", SpecTab_OnShow);
    self.SpecTab:SetScript("OnHide", SpecTab_OnHide);
end

function NarciTalentTreeSideTabMixin:Init()
    --/run NarciMiniTalentTree.SideTab:ShowFrame()

    local px = GetPixelForWidget(self, 1);
    local FONT_HEIGHT = FONT_PIXEL_SIZE * px;
    local BUTTON_HEIGHT = BUTTON_PIXEL_HEIGHT * px;
    local BUTTON_WIDTH = TAB_PIXEL_WIDTH * px;
    local PX2 = 2 * px;

    local height = self:GetHeight();
    local heightPixel = height/px;
    self.ClipFrame.Background:SetTexCoord(0, TAB_PIXEL_WIDTH/256, 0, heightPixel/512);
    self:SetWidth(BUTTON_WIDTH);
    self.fullWidth = BUTTON_WIDTH;


    local font = self.InspectTab.DividerText:GetFont();

    local numSpec = GetNumSpecializations();

    local b;
    local specID, name, description, icon;

    for i = 1, numSpec do
        SpecButtons[i] = CreateFrame("Button", nil, self.SpecTab, "NarciTalentTreeSpecButtonTemplate");
        b = SpecButtons[i];
        specID, name, description, icon = GetSpecializationInfo(i);
        b.specIndex = i;
        b.specID = specID;
        b.Name:SetFont(font, FONT_HEIGHT, "");
        b.Name:SetText(name);
        b.Icon:SetTexture(icon);
        b.Icon:SetSize(BUTTON_HEIGHT, BUTTON_HEIGHT);
        b:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT);
        b.Divider:SetHeight(PX2);
        b.Underline:SetHeight(PX2);
        b.Underline:SetWidth(b.Name:GetWrappedWidth());
        b.Underline:SetPoint("TOPLEFT", b.Name, "BOTTOMLEFT", 0, -PX2);
        b.Underline:SetColorTexture(0.72, 0.6, 0);

        b:SetScript("OnEnter", SpecButton_OnEnter);
        b:SetScript("OnLeave", SpecButton_OnLeave);
        b:SetScript("OnClick", SpecButton_OnClick);

        b:SetPoint("TOPLEFT", self, "TOPLEFT", 0, (1 - i) * (BUTTON_HEIGHT + PX2));
    end

    self.Init = nil;


    if self.currentSpecID then
        self:SetSelectedSpec(self.currentSpecID)
    end
end

function NarciTalentTreeSideTabMixin:UpdatePixel(px)
    local font = self.InspectTab.DividerText:GetFont();
    local FONT_HEIGHT = FONT_PIXEL_SIZE * px;
    local BUTTON_HEIGHT = BUTTON_PIXEL_HEIGHT * px;
    local BUTTON_WIDTH = TAB_PIXEL_WIDTH * px;
    local PX2 = 2 * px;

    local height = self:GetHeight();
    local heightPixel = height/px;
    self.ClipFrame.Background:SetTexCoord(0, TAB_PIXEL_WIDTH/256, 0, heightPixel/512);
    self:SetWidth(BUTTON_WIDTH);
    self.fullWidth = BUTTON_WIDTH;

    for i, b in ipairs(SpecButtons) do
        b.Name:SetFont(font, FONT_HEIGHT, "");
        b.Icon:SetSize(BUTTON_HEIGHT, BUTTON_HEIGHT);
        b:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT);
        b.Divider:SetHeight(PX2);
        b.Underline:SetWidth(b.Name:GetWrappedWidth());
        b.Underline:SetHeight(PX2);
        b.Underline:SetPoint("TOPLEFT", b.Name, "BOTTOMLEFT", 0, -PX2);
        b:SetPoint("TOPLEFT", self, "TOPLEFT", 0, (1 - i) * (BUTTON_HEIGHT + PX2));
    end

    local offsetX = 20*px;
    Clipboard:SetPoint("TOPLEFT", self, "TOPLEFT", offsetX, Clipboard.defaultOffsetY * px);
    Clipboard:UpdatePixel(px);
    self.InspectTab.LoadoutNameEditBox:SetPoint("TOPLEFT", self, "TOPLEFT", offsetX, self.InspectTab.LoadoutNameEditBox.defaultOffsetY * px);
    self.InspectTab.LoadoutNameEditBox:UpdatePixel(px);

    self.InspectTab.DividerText:SetFont(font, 14*px, "");
    self.InspectTab.DividerText:SetPoint("CENTER", self, "TOP", 0, px*((Clipboard.defaultOffsetY + self.InspectTab.LoadoutNameEditBox.defaultOffsetY)*0.5 - 2));
    self.InspectTab.DividerLeft:SetHeight(px);
    self.InspectTab.DividerRight:SetHeight(px);
    local lineWidth = (TAB_PIXEL_WIDTH - 20 - 20*2)*px*0.5;
    self.InspectTab.DividerLeft:SetPoint("RIGHT", self.InspectTab.DividerText, "LEFT", -4*px, 0);
    self.InspectTab.DividerRight:SetPoint("LEFT", self.InspectTab.DividerText, "RIGHT", 4*px, 0);
    self.InspectTab.DividerLeft:SetWidth(lineWidth);
    self.InspectTab.DividerRight:SetWidth(lineWidth);
end

function NarciTalentTreeSideTabMixin:LockSpecButtons(state)
    --prevent clicking to fast and initiate spec change by mistake
    if state then
        for i, b in ipairs(SpecButtons) do
            b:Disable();
        end
    else
        for i, b in ipairs(SpecButtons) do
            b:Enable();
        end
    end
end

function NarciTalentTreeSideTabMixin:ShowFrame()
    if not self:IsShown() then
        if self.Init then
            self:Init();
        end
        self.t = 0;
        self.d = 0.35;
        self.buttonLocked = true;
        self:SetScript("OnUpdate", ShowFrame_OnUpdate);
        self:Show();
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        self:LockSpecButtons(true);

        if self.activeButton then
            self.activeButton.Underline.AnimIn:Stop();
            self.activeButton.Underline.AnimIn:Play();
        end

        self:GetParent().MotionBlocker:Show();

        if self.mode ~= "inspect" then
            self:TakeClipboard(false);
        end
    end
    self.isClosing = nil;
end

function NarciTalentTreeSideTabMixin:CloseFrame(instant)
    if instant then
        self:Hide();
    else
        if not self.isClosing then
            self.isClosing = true;
        end
        self:Hide();
    end
    self:GetParent().MotionBlocker:Hide();
end

function NarciTalentTreeSideTabMixin:SetSelectedSpec(specID)
    self.currentSpecID = specID;

    if SpecButtons then
        for i, b in ipairs(SpecButtons) do
            SpecButton_SetSelected(b, specID == b.specID);
        end
    end
end

function NarciTalentTreeSideTabMixin:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not (self:IsMouseOver() or LoadingBarUtil:IsBarVisible())  then
            self:CloseFrame();
        end
    end
end

function NarciTalentTreeSideTabMixin:OnSpecChangeSucceeded()
    self:CloseFrame(true);
end

function NarciTalentTreeSideTabMixin:OnMouseDown()

end

function NarciTalentTreeSideTabMixin:SetMode(mode, canDirectlyImport)
    --(class) show specialization / (inspect) show export editboxes
    self.mode = mode;

    local isSpecMode = mode ~= "inspect";
    self.SpecTab:SetShown(isSpecMode);
    self.InspectTab:SetShown(not isSpecMode);

    if mode == "inspect" then
        self:TakeClipboard(false);
        self.InspectTab.LoadoutNameEditBox:SetShown(canDirectlyImport);
        self.InspectTab.DividerLeft:SetShown(canDirectlyImport);
        self.InspectTab.DividerRight:SetShown(canDirectlyImport);
        self.InspectTab.DividerText:Show();
        Clipboard:SetText("");
        Clipboard:ShowLoadingIndicator(true);
        if canDirectlyImport then
            self.InspectTab.LoadoutNameEditBox:ResetState();
            if DataProvider:CanCreateNewConfig() then
                self.InspectTab.DividerText:SetText("OR");
                self.InspectTab.DividerLeft:Show();
                self.InspectTab.DividerRight:Show();
            else
                self.InspectTab.DividerText:SetText(string.upper( Narci.L["No Save Slot Red"] ));
                self.InspectTab.DividerLeft:Hide();
                self.InspectTab.DividerRight:Hide();
                self.InspectTab.LoadoutNameEditBox:Hide();
            end
        else
            self.InspectTab.DividerText:Hide();
            self.InspectTab.DividerLeft:Hide();
            self.InspectTab.DividerRight:Hide();
        end
        self.InspectTab.LoadoutNameEditBox.SaveButton:Hide();
    end
    Clipboard.copiedText = nil;
end

local function SpecTabFade_OnUpdate(self, elapsed)
    self.alpha = self.alpha + self.delta * elapsed;
    if self.alpha >= 1 then
        self:SetScript("OnUpdate", nil);
        self.alpha = 1;
    elseif self.alpha <= 0.5 then
        self:SetScript("OnUpdate", nil);
        self.alpha = 0.5;
    end
    self:SetAlpha(self.alpha);
end

function NarciTalentTreeSideTabMixin:LockAction(state, noFading)
    --forbid spec change while in combat, moving, casting, flying
    self.actionLocked = state;

    self:LockSpecButtons(state);
    if state then
        self.SpecTab.delta = -2;
    else
        self.SpecTab.delta = 2;
    end

    if noFading then
        if state then
            self.SpecTab:SetAlpha(0.5);
        else
            self.SpecTab:SetAlpha(1);
        end
        self.SpecTab:SetScript("OnUpdate", nil);
    else
        self.SpecTab.alpha = self.SpecTab:GetAlpha();
        self.SpecTab:SetScript("OnUpdate", SpecTabFade_OnUpdate);
    end

end

local function UpdateClipboard()
    local exportString = DataProvider:GetLoadoutExportString();
    Clipboard:SetText(exportString);
    Clipboard.copiedText = exportString;
    Clipboard:ShowLoadingIndicator(false);
end

function NarciTalentTreeSideTabMixin:OnTabExpaned()
    if self.mode == "inspect" then
        if not Clipboard.copiedText then
            UpdateClipboard();
        end
        Clipboard:SetFocus();
    end
end

function NarciTalentTreeSideTabMixin:TakeClipboard(state)
    if state == Clipboard.isTaken then return end;
    Clipboard.isTaken = state;

    local px = GetPixelForWidget(self, 1);
    Clipboard:ClearAllPoints();

    local offsetX = 20*px;
    if state then
        Clipboard:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offsetX, 84 * px);
        Clipboard:SetParent(self);
        UpdateClipboard();
        Clipboard:SetFocus();
    else
        Clipboard:SetPoint("TOPLEFT", self, "TOPLEFT", offsetX, Clipboard.defaultOffsetY * px);
        Clipboard:SetParent(self.InspectTab);
        local toggle = self:GetParent().ShareToggle;
        if toggle then
            toggle:Show();
        end
    end
    Clipboard:Show();
end