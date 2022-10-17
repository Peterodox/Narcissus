local _, addon = ...

local outQuart = addon.EasingFunctions.outQuart;
local LoadingBarUtil = addon.TalentTreeLoadingBarUtil;
local SetSpecialization = SetSpecialization;
local InCombatLockdown = InCombatLockdown;

local SpecFrame;
local SpecButtons;


local function SpecButton_OnEnter(self)
    if not self.selected then
        self.Name:SetTextColor(0.8, 0.8, 0.8);
        self.Icon:SetAlpha(0.5);
    end
end

local function SpecButton_OnLeave(self)
    if not self.selected then
        self.Name:SetTextColor(0.5, 0.5, 0.5);
        self.Icon:SetAlpha(0.25);
    end
end

local function SpecButton_OnClick(self)
    if LoadingBarUtil:IsBarVisible() then
        return
    end

    if self.selected then
        SpecFrame:CloseFrame();
    else
        if not InCombatLockdown() then
            LoadingBarUtil:SetFromSpecButton(self);
            SetSpecialization(self.specIndex, false);
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
            SpecFrame.activeButton = self;
        end
    elseif self.selected or self.selected == nil then
        self.selected = false;
        self.Icon:SetDesaturated(true);
        self.Icon:SetAlpha(0.25);
        self.Name:SetTextColor(0.5, 0.5, 0.5);
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
    end
    if alpha > 1 then
        alpha = 1
    end
    self:SetAlpha(alpha);
    self.ButtonContainer:SetWidth(width);
end

NarciTalentTreeSpecSelectMixin = {};

function NarciTalentTreeSpecSelectMixin:OnLoad()
    SpecFrame = self;
end

function NarciTalentTreeSpecSelectMixin:Init()
    --/run NarciMiniTalentTree.SpecSelect:ShowFrame()
    SpecButtons = {};

    local px = NarciAPI.GetPixelForWidget(self, 1);
    local FONT_HEIGHT = 16 * px;
    local BUTTON_HEIGHT = 56 * px;
    local BUTTON_WIDTH = 216 * px;
    local PX2 = 2 * px;

    local height = self:GetHeight();
    local heightPixel = height/px;
    self.ButtonContainer.Background:SetTexCoord(0, 216/256, 0, heightPixel/512);
    self:SetWidth(BUTTON_WIDTH);
    self.fullWidth = BUTTON_WIDTH;


    local font = self.InComatAlert:GetFont();

    local numSpec = GetNumSpecializations();

    local b;
    local specID, name, description, icon;

    for i = 1, numSpec do
        SpecButtons[i] = CreateFrame("Button", nil, self.ButtonContainer, "NarciTalentTreeSpecButtonTemplate");
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

function NarciTalentTreeSpecSelectMixin:ShowFrame()
    if not self:IsShown() then
        if self.Init then
            self:Init();
        end
        self.t = 0;
        self.d = 0.5;
        self:SetScript("OnUpdate", ShowFrame_OnUpdate);
        self:Show();
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");

        if self.activeButton then
            self.activeButton.Underline.AnimIn:Stop();
            self.activeButton.Underline.AnimIn:Play();
        end

        self:GetParent().MotionBlocker:Show();
    end
    self.isClosing = nil;
end

function NarciTalentTreeSpecSelectMixin:CloseFrame(instant)
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

function NarciTalentTreeSpecSelectMixin:SetSelectedSpec(specID)
    self.currentSpecID = specID;

    if SpecButtons then
        for i, b in ipairs(SpecButtons) do
            SpecButton_SetSelected(b, specID == b.specID);
        end
    end
end

function NarciTalentTreeSpecSelectMixin:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not (self:IsMouseOver() or LoadingBarUtil:IsBarVisible())  then
            self:CloseFrame();
        end
    end
end

function NarciTalentTreeSpecSelectMixin:OnSpecChangeSucceeded()
    self:CloseFrame(true);
end

function NarciTalentTreeSpecSelectMixin:OnMouseDown()

end