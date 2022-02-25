local _, addon = ...
local SetTextureCurrentClass = addon.SetTextureCurrentClass;


local function CountDown_OnUpdate(self, elapased)
    self.t = self.t + elapased;
    if self.t > 6 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self.Text2.Blink:Stop();
        self.Text2.Blink:Play();
        self.Text2:Show();
    end
end

local function SpinButton_OnUpdate(self, elapased)
    self.t = self.t + elapased;
    if self.t >= 0.125 then
        self.t = 0;
        local sequence = self.sequence + 1;
        if sequence > 16 then
            sequence = 1;
        end
        self.sequence = sequence;
        local row = math.floor( (sequence - 1) * 0.25);
        local col = sequence - row * 4 - 1;
        self.SpinTexture:SetTexCoord(0.25*col, 0.25*(col + 1), 0.25*row, 0.25*(row + 1));
    end
end

local function Close_OnUpdate(self, elapased)
    self.t = self.t + elapased;
    local sat = 1 - self.t * 2;
    if sat < 0 then
        sat = 0;
    end
    if self.t > 0.5 then
        sat = 0;
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self:Hide();
    end
    self.parentActor:SetDesaturation(sat);
    self.panel:SetAlpha(1 - sat);
    self:SetAlpha(sat);
end


NarciShowcaseSplashFrameMixin = {};

function NarciShowcaseSplashFrameMixin:OnLoad()
    local root = self:GetParent();

    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0);
    self:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0);
    self:SetFrameStrata("HIGH");

    local width, height = root:GetSize();
    self.frameHeight = height;
    local rightWidth = width - height * 0.75;
    self.RightArea:SetSize(rightWidth, height);

    local previewWidth = rightWidth * 0.8;
    local prewviewHeight = previewWidth * 0.75;
    self.PreviewFrame:SetSize(previewWidth, prewviewHeight);
    self.LeftModelScene:SetWidth(height * 0.75);
    self.PreviewFrame.Image:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\Splash\\ModelBackground");
    self.SyncButton.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\Splash\\SyncButtonBig", nil, nil, "TRILINEAR");
    self.SpinButton.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\Splash\\SpinButtonBackground");
    self.Text1:SetWidth(previewWidth);
    self.Text2:SetText(Narci.L["Click To Continue"]);

    local function InitModelScene(m)
        m:SetCameraPosition(4, 0, 0);
        m:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0);
        m:SetCameraFieldOfView(0.75);
        m:SetLightDiffuseColor(0.8, 0.8, 0.8);
        m:SetLightAmbientColor(0.6, 0.6, 0.6);
        m:SetLightPosition(1, 0, 1);
        m:SetLightDirection(-1, 0, -1);
        local a = m:CreateActor(nil, "NarciAutoFittingActorTemplate");
        a:SetUseCenterForOrigin(false, false, true);
        a:SetPosition(0, 0, 0);
        return a
    end

    local modelScene = self.PreviewFrame.MicroModelScene;
    modelScene:SetSize(prewviewHeight*0.75, prewviewHeight);
    SetTextureCurrentClass(modelScene.Background);

    local microActor = InitModelScene(modelScene);
    microActor.GroundShadow = modelScene.GroundShadow;
    microActor.yaw = 0;
    self.microActor = microActor;

    local function ModelScene_OnUpdate(f, elapased)
        microActor.yaw = microActor.yaw + elapased * 0.7854;  --8s
        microActor:SetYaw(microActor.yaw);
    end

    modelScene:SetScript("OnUpdate", ModelScene_OnUpdate);

    local leftActor = InitModelScene(self.LeftModelScene);
    leftActor.GroundShadow = self.LeftModelScene.HiddenShadow;
    leftActor:SetUseTransmogSkin(false);
    leftActor:SetParticleOverrideScale(0);
    leftActor:SetModelByUnit("player", true, false);
    self.LeftModelScene:SetFogColor(0.13, 0.13, 0.13);
    self.LeftModelScene:SetFogNear(0);
    self.LeftModelScene:SetFogFar(0.1);

    root.TextFrame.Divider:Hide();
    root.ControlPanel:Hide();

    self:Step1();
end

function NarciShowcaseSplashFrameMixin:ShowNotification(state)
    if state then
        self.t = 0;
        self:SetScript("OnUpdate", CountDown_OnUpdate);
    else
        self:SetScript("OnUpdate", nil);
        self.Text2:Hide();
    end
end


function NarciShowcaseSplashFrameMixin:Step1()
    self.step = 1;
    self:UpdateWidgetVisibility();
    self.LeftModelScene:Show();

    self.Text1:SetText(Narci.L["Showcase Splash 1"]);
    local gap = 12;
    local textHeight = self.Text1:GetHeight();
    local height1 = textHeight + self.PreviewFrame:GetHeight() + gap;
    local offsetY = (height1 - self.frameHeight) * 0.5;
    self.Text1:ClearAllPoints();
    self.Text1:SetPoint("TOP", self.RightArea, "TOP", 0, offsetY);
    self.Text1:SetJustifyH("LEFT");
    self.PreviewFrame:ClearAllPoints();
    self.PreviewFrame:SetPoint("TOP", self.RightArea, "TOP", 0, offsetY - gap - textHeight);
    self.microActor.yaw = 0;
    self.microActor:SetModelByUnit("player");
    self.microActor:UndressSlot(16);
    self.microActor:UndressSlot(17);
    self.Divider:SetHeight(height1 + 32);
    self:FadeInText();
    self.PreviewFrame:SetAlpha(0);
    self.PreviewFrame.FadeIn:Play();
end

function NarciShowcaseSplashFrameMixin:Step2()
    self.step = 2;
    self:UpdateWidgetVisibility();
    self.LeftModelScene:Show();

    self.Text1:SetText(Narci.L["Showcase Splash 2"]);
    self.Text1:SetJustifyH("CENTER");
    local gap = 12;
    local buttonSize = 24;
    local textHeight = self.Text1:GetHeight();
    local height1 = textHeight + gap + buttonSize;
    self.Divider:SetHeight(height1 + 32);
    local offsetY = (height1 - self.frameHeight) * 0.5;
    self.Text1:ClearAllPoints();
    self.Text1:SetPoint("TOP", self.RightArea, "TOP", 0, offsetY);
    self.SyncButton:ClearAllPoints();
    self.SyncButton:SetPoint("TOP", self.Text1, "BOTTOM", 0, -gap);
    self.SyncButton:SetSize(buttonSize, buttonSize);
    self.SyncButton:Show();
    self.SyncButton.AnimRotate:Play();
    self:FadeInText();
end

function NarciShowcaseSplashFrameMixin:Step3()
    self.step = 3;
    self:UpdateWidgetVisibility();
    self.Text1:SetText(Narci.L["Showcase Splash 3"]);
    self.Text1:SetJustifyH("CENTER");
    local gap = 12;
    local buttonSize = 24;
    local textHeight = self.Text1:GetHeight();
    local height1 = textHeight + gap + buttonSize;
    local offsetY = (height1 - self.frameHeight) * 0.5;
    self.Text1:ClearAllPoints();
    self.Text1:SetPoint("TOP", self.RightArea, "TOP", 0, offsetY);
    self.SpinButton:ClearAllPoints();
    self.SpinButton:SetPoint("TOP", self.Text1, "BOTTOM", 0, -gap);
    self.SpinButton:SetSize(buttonSize, buttonSize);
    self.SpinButton:Show();
    self.SpinButton.t = 0;
    self.SpinButton.sequence = 1;
    self.SpinButton.FadeIn:Play();
    self.SpinButton:SetScript("OnUpdate", SpinButton_OnUpdate);

    self.SyncButton:SetSize(16, 16);
    self.SyncButton:ClearAllPoints();
    self.SyncButton.AnimRotate:Play();
    self.SyncButton:SetPoint("CENTER", self, "TOPLEFT", 16, -16);
    self.SyncButton:Show();
    self:GetParent().actor:SetDesaturation(1);
    self.LeftModelScene.FadeOut:Play();
    self:FadeInText();
end

function NarciShowcaseSplashFrameMixin:Step4()
    self.step = 4;
    self:UpdateWidgetVisibility();

    self.Text1:SetText(Narci.L["Showcase Splash 4"]);
    self.Text1:SetJustifyH("CENTER");
    local textHeight = self.Text1:GetHeight();
    local gap = 12;
    local imageHeight = 27;
    local height1 = textHeight + gap + imageHeight;
    local offsetY = (height1 - self.frameHeight) * 0.5;
    self.Text1:ClearAllPoints();
    self.Text1:SetPoint("TOP", self.RightArea, "TOP", 0, offsetY);
    self.ConvertIcon:ClearAllPoints();
    self.ConvertIcon:SetPoint("TOP", self.Text1, "BOTTOM", 0, -gap);
    self.ConvertIcon.FadeIn:Play();
    self:GetParent():SpinActor(true);
    self:FadeInText();
end

function NarciShowcaseSplashFrameMixin:Close()
    self.t = 0;
    local root = self:GetParent();
    self.parentActor = root.actor;
    self.panel = root.ControlPanel;
    self.panel:Show();
    root.TextFrame.Divider:Show();
    self:SetScript("OnUpdate", Close_OnUpdate);
end

function NarciShowcaseSplashFrameMixin:FadeInText()
    self.Text1.FadeIn:Stop();
    self.Text1.FadeIn:Play();
end

function NarciShowcaseSplashFrameMixin:UpdateWidgetVisibility()
    self.PreviewFrame:SetShown(self.step == 1);
    self.SyncButton:SetShown(self.step ~= 1);
    self.SpinButton:SetShown(self.step == 3);
    self.ConvertIcon:SetShown(self.step == 4);
    self:ShowNotification(self.step == 1 or self.step == 4);
end

function NarciShowcaseSplashFrameMixin:OnMouseDown(button)
    if button == "LeftButton" then
        self.step = self.step + 1;
    else
        self.step = self.step - 1;
    end
    if self.step <= 4 then
        if self.step == 1 then
            self:Step1();
        elseif self.step == 2 then
            self:Step2();
        elseif self.step == 3 then
            self:Step3();
        else
            self:Step4();
        end
    else
        self:Close();
    end
end