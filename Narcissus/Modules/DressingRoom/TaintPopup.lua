local _, addon = ...
local L = Narci.L;

local AlertFrame;
local IS_HOOKED = false;


local EventListener = CreateFrame("Frame");

EventListener:RegisterEvent("ADDON_ACTION_FORBIDDEN");

EventListener:SetScript("OnEvent", function(self, event, ...)
    local name, funcName = ...;
    --print(name, funcName)
    if funcName == "CopyToClipboard()" and DressUpFrame and DressUpFrame:IsShown() then
        AlertFrame:ShowFrame();
    end
end);


local function OnCopiedCallBack()
    AlertFrame:Hide();
    StaticPopup1:Hide();

    local r, g, b = NarciAPI.GetColorPresetRGB("green");
    UIErrorsFrame:AddMessage(TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD_NOTICE, r, g, b, 1.0, 0);
end


local GuideLineScripts = {
    OnEnter = function(self)
        self:GetParent().Picture:SetTexCoord(self.texOffset, self.texOffset + 0.5, 0, 1);
        self.Text:SetTextColor(1, 1, 1);
    end,

    OnLeave = function(self)
        self.Text:SetTextColor(0.7, 0.7, 0.7);
    end,
}

NarciDressingRoomTaintAlertFrameMixin = {};

function NarciDressingRoomTaintAlertFrameMixin:OnLoad()
    AlertFrame = self;
    self.Text1:SetText(L["Press Copy"]);
    self.fixedHeight = self.Text1:GetHeight() + 97;

    self.Clipboard.onCopiedCallback = OnCopiedCallBack;

    self.ShowMoreButton:SetButtonText(L["Show Taint Solution"], true);
    self.ShowMoreButton:SetScript("OnClick", function(f)
        f:Hide();
        self:ShowSolution();
    end);

    self.CloseButton:SetScript("OnClick", function()
        self:Hide();
    end);
end

function NarciDressingRoomTaintAlertFrameMixin:ShowFrame()
    self:ClearAllPoints();
    if StaticPopup1:IsShown() then
        self:SetPoint("TOP", StaticPopup1, "BOTTOM", 0, -24);
    else
        self:SetPoint("TOP", UIParent, "TOP", 0, -135);
    end
    self:Show();
    self:UpdateEditBox();
    self:UpdateSize();

    if not IS_HOOKED then
        IS_HOOKED = true;
        DressUpFrame:HookScript("OnHide", function()
            self:Hide();
        end);
    end
end

function NarciDressingRoomTaintAlertFrameMixin:UpdateEditBox()
    self.Clipboard:SetText( NarciAPI.GetOutfitSlashCommand() );
    self.Clipboard:SetFocus();
    self.Clipboard:HighlightText();
    self.Clipboard:SetDefaultCursorPosition(0);
end

function NarciDressingRoomTaintAlertFrameMixin:UpdateSize(extraHeight)
    local height= self.fixedHeight + (extraHeight or 0);
    self:SetHeight(height);
end

function NarciDressingRoomTaintAlertFrameMixin:ShowSolution()
    if not GuideLineScripts.frameHeight then
        local buttons = {};
        local button, fontString, textHeight;
        local buttonWidth = 170;
        local gap = 8;
        local frameHeight = 0;
        for i = 1, 2 do
            button = CreateFrame("Button", nil, self.TutorialFrame);
            button:SetSize(buttonWidth, 24);
            button:SetHitRectInsets(-4, -4, -4, -4);
            buttons[i] = button;
            if i == 1 then
                button:SetPoint("TOPLEFT", self.TutorialFrame, "TOPLEFT", 0, 0);
            else
                button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -gap);
                frameHeight = frameHeight + gap;
            end
            fontString = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
            button.Text = fontString;
            fontString:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
            fontString:SetJustifyH("LEFT");
            fontString:SetJustifyV("TOP");
            fontString:SetSpacing(2);
            fontString:SetTextColor(0.7, 0.7, 0.7);
            fontString:SetWidth(buttonWidth);
            fontString:SetText(Narci.L["Taint Solution Step"..i]);
            textHeight = fontString:GetHeight()
            fontString:SetHeight(textHeight + 2)
            button:SetHeight(textHeight);
            for scriptName, script in pairs(GuideLineScripts) do
                button:SetScript(scriptName, script);
            end
            button.texOffset = (i - 1) * 0.5;
            frameHeight = frameHeight + textHeight;
        end
        frameHeight = math.max(frameHeight, 96);
        GuideLineScripts.frameHeight = frameHeight;
    end

    self.TutorialFrame:Show();
    self:UpdateSize(GuideLineScripts.frameHeight);
end

function NarciDressingRoomTaintAlertFrameMixin:OnHide()
    self:ClearAllPoints();
    self.TutorialFrame:Hide();
    self.ShowMoreButton:Show();
end

--[[
UIErrorsFrame:AddMessage("Test", r, g, b, 1.0, 0);
--]]