local _, addon = ...
local FadeFrame = NarciFadeUI.Fade;

local GroupController = {};

local MotionHandler = {};

function MotionHandler:Init()
    local fadeTime = 2;
    local f = CreateFrame("Frame");
    f:Hide();
    f.t = 0;
    f:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        if f.t >= fadeTime then
            f.t = 0;
            if not GroupController:IsMouseOverButtons() then
                GroupController:FadeOutButtonTooltip();
                f:Hide();
            end
        end
    end);

    self.executeFrame = f;
end

function MotionHandler:Start()
    if not self.executeFrame then
        self:Init();
    end
    self.executeFrame.t = 0;
    self.executeFrame:Show();
end

function MotionHandler:Stop()
    if self.executeFrame then
        self.executeFrame:Hide();
    end
end


function GroupController:AddButton(button)
    if not self.optionButtons then
        self.optionButtons = {};
    end
    tinsert(self.optionButtons, button);
end

function GroupController:IsMouseOverButtons()
    for _, button in pairs(self.optionButtons) do
        if button:IsMouseOver() then
            return true;
        end
    end
    return false;
end

function GroupController:FadeInButtonTooltip()
    for _, button in pairs(self.optionButtons) do
        button:FadeTooltip(0.15, 1);
    end
end

function GroupController:FadeOutButtonTooltip()
    for _, button in pairs(self.optionButtons) do
        button:FadeTooltip(0.5, 0);
    end
end

function GroupController:SetLabelScale(scale)
    for _, button in pairs(self.optionButtons) do
        button.Label:SetScale(scale);
    end
end

function GroupController:SetButtonGap(gap)
    local button;
    local button1 = self.optionButtons[1];
    if not button1 then return end;
    local height = math.floor(button1:GetHeight() + 0.5);
    for i = 2, #self.optionButtons do
        button = self.optionButtons[i];
        button:ClearAllPoints();
        button:SetPoint("BOTTOM", button1, "BOTTOM", 0, (height + gap) * (i - 1) );
    end
end

NarciDressingRoomOptionButtonMixin = {};

function NarciDressingRoomOptionButtonMixin:OnLoad()
    GroupController:AddButton(self);
    self.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\OptionButton", nil, nil, "TRILINEAR");

    self:SetFrameStrata("HIGH");
    --self:SetFixedFrameStrata(true);

    self.Icon:SetVertexColor(0.6, 0.6 ,0.6);
    self.Label:SetAlpha(0);

    self:GetParent().GroupController = GroupController;

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciDressingRoomOptionButtonMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);
    self.Label:SetTextColor(1, 1, 1);
    GroupController:FadeInButtonTooltip();
    MotionHandler:Stop();
end

function NarciDressingRoomOptionButtonMixin:OnLeave()
    self.Icon:SetVertexColor(0.6, 0.6 ,0.6);
    self.Label:SetTextColor(0.8, 0.8, 0.8);
    MotionHandler:Start();
end

function NarciDressingRoomOptionButtonMixin:OnMouseDown()
    self.Background:SetScale(0.9);
    self.Icon:SetScale(0.9);
end

function NarciDressingRoomOptionButtonMixin:OnMouseUp()
    self.Background:SetScale(1);
    self.Icon:SetScale(1);
end

function NarciDressingRoomOptionButtonMixin:FadeTooltip(t, toAlpha)
    FadeFrame(self.Label, t, toAlpha);
end