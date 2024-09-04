local FadeFrame = NarciFadeUI.Fade;
local SmartSetName = NarciAPI.SmartSetName;

local MainFrame;

local CloseButtonScripts = {};

CloseButtonScripts.OnEnter = function(self)
    self:SetAlpha(1);
end

CloseButtonScripts.OnLeave = function(self)
    self:SetAlpha(0.5);
    if not MainFrame:IsMouseOver() then
        MainFrame:OnLeave();
    end
end

CloseButtonScripts.OnClick = function(self)
    MainFrame:GetParent():SetDND(true);
end


NarciMsgAlertMixin = {};

function NarciMsgAlertMixin:OnLoad()
    MainFrame = self;

    self.Sender:SetShadowOffset(0, 2);
    self.Sender:SetShadowColor(0, 0, 0, 0.2);
    self.Message:SetShadowOffset(0, 2);
    self.Message:SetShadowColor(0, 0, 0, 0.2);

    --BN character name is protected so we can't detect its language
    self.Sender:SetFont("Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 12);
    self.Message:SetFont("Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 12);

    local CloseButton = self.ExtraFrame.CloseButton;
    for scriptName, func in pairs(CloseButtonScripts) do
        CloseButton:SetScript(scriptName, func);
    end

    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciMsgAlertMixin:OnEnter()
    self:FadeInBorder(true);
    self.ProgressRing:Pause();
end

function NarciMsgAlertMixin:OnLeave()
    if not self:IsMouseOver() then
        self:FadeInBorder(false);
        self.ProgressRing:Resume();
    end
end

function NarciMsgAlertMixin:OnShow()
    NarciScreenshotToolbar:EnableMotion(false);
end

function NarciMsgAlertMixin:OnHide()
    self.ExtraFrame:Hide();
    self.ExtraFrame:SetAlpha(0);
    NarciScreenshotToolbar:EnableMotion(true);
end

function NarciMsgAlertMixin:FadeInBorder(state)
    if state then
        FadeFrame(self.ExtraFrame, 0.2, 1);
    else
        FadeFrame(self.ExtraFrame, 0.25, 0);
    end
end

function NarciMsgAlertMixin:OnMouseDown()

end

function NarciMsgAlertMixin:OnMouseUp()

end

function NarciMsgAlertMixin:OnClick(button)
    if button == "RightButton" then
        self.ExtraFrame.CloseButton:Click();
    else
        SetUIVisibility(true);
    end
end

function NarciMsgAlertMixin:SetMsg(sender, message)
    local MAX_WIDTH = 172;

    self.Message:SetText("");
    self.Message:SetSize(0, 0);

    self.Sender:SetText(sender);
    self.Message:SetText(message);
    --SmartSetName(self.Sender, sender);
    --SmartSetName(self.Message, message);

    local maxWidth = math.max(self.Sender:GetWidth(), self.Message:GetWidth(), 85);
    if maxWidth > MAX_WIDTH then
        maxWidth = MAX_WIDTH;
    end
    self.Message:SetWidth(maxWidth + 2);

    self.ExtraFrame.Center:SetWidth(maxWidth + 32)
    self:SetWidth(maxWidth + 96);
    self:Enable();
    local duration = 6 + 2*(maxWidth - 85)/(MAX_WIDTH - 85);
    self.ProgressRing:SetCooldown(GetTime(), duration);
    if self:IsMouseOver() then
        self.ProgressRing:Pause();
    else
        self.ProgressRing:Resume();
    end
    self:SetAlpha(0);
    self.FlyUp:Stop();
    self.FlyUp:Play();
    FadeFrame(self, 0.2, 1);
    self:SetScale(Narci_Character:GetEffectiveScale());
end

function NarciMsgAlertMixin:OnMsgPlayed()
    self:Disable();
    FadeFrame(self, 0.5, 0);
    FadeFrame(self:GetParent().CornerLight, 1, 0);
end