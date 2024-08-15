local _, addon = ...

local L = Narci.L;
local Round = addon.Math.Round;

local MIN_HITRECT_X = 96;
local LINE_SPACING = 4;
local PARAGRAPH_SPACING = 16;
local FONT_HEIGHT = 9;
local STEP_TEXT_OFFSET_X = 12;  --Between number and text
local FRAME_PADDING = 18;
local TEXT_MAX_WIDTH = 240;

local MainFrame;
local Clipboard;

local INSTRUCTIONS = {
    {text = L["FindVisual Guide 1"]},
    {text = L["FindVisual Guide 2"], link = "https://wago.tools/db2/SpellXSpellVisual"},
    {text = L["FindVisual Guide 3"], link = "https://wago.tools/db2/SpellVisualEvent"},
    {text = L["FindVisual Guide 4"]},
};


local GetClipborad;     --TODO: Consider sharing one clipboard across the addon
local SimpleAlertFrame;

do
    local IsControlKeyDown = IsControlKeyDown;

    local function Clipboard_OnCursorChanged(self)
        if self:HasFocus() then
            self:HighlightText();
        end
    end

    local function Clipboard_OnTextChanged(self, userInput)
        if userInput then
            self:ClearFocus();
            self:Hide();
        end
    end

    local function Clipboard_Exit(self)
        self:Hide();
    end

    local function Clipboard_OnEditFocusLost(self)
        self:Hide();
    end

    local function Clipboard_OnEditFocusGained(self)
        SimpleAlertFrame:SetText(L["Press Copy Yellow"]);
    end

    local function Clipboard_OnKeyDown(self, key)
        if key == "C" and IsControlKeyDown() then
            SimpleAlertFrame:SetText(L["Copied"]);
            C_Timer.After(0, function()
                self:Hide();
            end);
        end
    end

    function GetClipborad()
        if not Clipboard then
            Clipboard = CreateFrame("EditBox", nil, UIParent);
            Clipboard:Hide();

            Clipboard:SetAutoFocus(false);
            Clipboard:SetScript("OnEscapePressed", Clipboard_Exit);
            Clipboard:SetScript("OnEnterPressed", Clipboard_Exit);
            Clipboard:SetScript("OnTextChanged", Clipboard_OnTextChanged);
            Clipboard:SetScript("OnCursorChanged", Clipboard_OnCursorChanged);
            Clipboard:SetScript("OnEditFocusGained", Clipboard_OnEditFocusGained);
            Clipboard:SetScript("OnEditFocusLost", Clipboard_OnEditFocusLost);
            Clipboard:SetScript("OnKeyDown", Clipboard_OnKeyDown);

            Clipboard:SetFontObject("NarciDisabledButtonFont");
            Clipboard:SetJustifyH("CENTER");
            Clipboard:SetJustifyV("MIDDLE");
            Clipboard:SetTextColor(1, 1, 1);
            Clipboard:SetHighlightColor(0.05, 0.41, 0.85);
            Clipboard:SetShadowOffset(0, 0);

            local bg = Clipboard:CreateTexture(nil, "BACKGROUND");
            bg:SetAllPoints(true);
            bg:SetColorTexture(0.12, 0.12, 0.12);
            Clipboard.Background = bg;

            SimpleAlertFrame = CreateFrame("Frame", nil, UIParent);
            SimpleAlertFrame.Text = SimpleAlertFrame:CreateFontString(nil, "OVERLAY", "NarciDisabledButtonFont");
            SimpleAlertFrame.Text:SetPoint("CENTER", SimpleAlertFrame, "CENTER", 0, 0);
            SimpleAlertFrame.Text:SetJustifyH("CENTER");
            SimpleAlertFrame.Text:SetJustifyV("MIDDLE");
            SimpleAlertFrame.Background = SimpleAlertFrame:CreateTexture(nil, "BACKGROUND");
            SimpleAlertFrame.Background:SetAllPoints(true);
            SimpleAlertFrame.Background:SetColorTexture(0, 0, 0, 0.8);


            function SimpleAlertFrame:OnUpdate(elapsed)
                self.t = self.t + elapsed;
                if self.t > 1 then
                    self.t = 1;
                    self.alpha = self.alpha - 4*elapsed;

                    if self.alpha <= 0 then
                        self.alpha = 0;
                        self:Hide();
                        self:SetAlpha(0);
                        self:SetScript("OnUpdate", nil);
                        return
                    end

                    self:SetAlpha(self.alpha);
                end
            end

            function SimpleAlertFrame:SetText(text, r, g, b)
                self.Text:SetText(text);
                self.Text:SetTextColor(r or 1, g or 1, b or 1);
                local width = self.Text:GetWidth();
                local height = self.Text:GetHeight();
                self:SetSize(width + 16, height + 16);
                self.alpha = 1;
                self:SetAlpha(1);
                self:Show();
                self.t = 0;
                self:SetScript("OnUpdate", self.OnUpdate);
            end
        end

        return Clipboard
    end
end


local CreateLinkButton;
do
    local function LinkButton_SetLink(self, link)
        self.link = link;
        if link then
            self.Text:SetText("["..link.."]");
            self:SetWidth(Round( math.max(MIN_HITRECT_X, self.Text:GetUnboundedStringWidth()) ));
            self:SetHeight(Round(self.Text:GetHeight() + 2*LINE_SPACING));
            self:Show();
        else
            self:Hide();
        end
    end

    local function LinkButton_OnEnter(self)
        self.Text:SetTextColor(1, 1, 1);
    end

    local function LinkButton_OnLeave(self)
        self.Text:SetTextColor(1, 0.82, 0);
    end

    local function LinkButton_OnClick(self)
        local cb = GetClipborad();
        local parent = self:GetParent();

        SimpleAlertFrame:ClearAllPoints();
        SimpleAlertFrame:SetParent(parent);
        SimpleAlertFrame:SetFrameStrata("TOOLTIP");
        SimpleAlertFrame:SetPoint("BOTTOM", cb, "TOP", 0, -LINE_SPACING);

        cb:ClearAllPoints();
        cb:SetParent(parent);
        cb:SetFrameStrata("TOOLTIP");
        cb:SetPoint("CENTER", self, "CENTER", 0, 0);
        cb:SetWidth(self:GetWidth());
        cb:SetHeight(self:GetHeight());
        cb:SetText(self.link);
        cb:Show();
        cb:SetFocus();
        cb:HighlightText();
    end

    function CreateLinkButton(parent)
        local f = CreateFrame("Button", nil, parent);
        f:SetSize(MIN_HITRECT_X, FONT_HEIGHT + 2*LINE_SPACING);
        f.Text = f:CreateFontString(nil, "OVERLAY", "NarciDisabledButtonFont");
        f.Text:SetPoint("LEFT", f, "LEFT", 0, 0);
        f.Text:SetJustifyH("LEFT");
        f.Text:SetJustifyV("MIDDLE");
        f:SetScript("OnEnter", LinkButton_OnEnter);
        f:SetScript("OnLeave", LinkButton_OnLeave);
        f:SetScript("OnClick", LinkButton_OnClick);
        LinkButton_OnLeave(f);
        f.SetLink = LinkButton_SetLink;
        return f
    end
end


local StepMixin = {};

function StepMixin:SetText(text)
    self.Instruction:SetWidth(TEXT_MAX_WIDTH);
    self.Instruction:SetText(text)
end

function StepMixin:SetIndex(index)
    self.index = index;
    self.IndexText:SetText(index..".");
end

function StepMixin:SetLink(link)
    if link then
        if not self.LinkButton then
            self.LinkButton = CreateLinkButton(self);
        end
        self.LinkButton:ClearAllPoints();
        self.LinkButton:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", STEP_TEXT_OFFSET_X, -LINE_SPACING);
        self.LinkButton:SetLink(link);
    else
        if self.LinkButton then
            self.LinkButton:Hide();
        end
    end
end

function StepMixin:UpdateExtent()
    local textWidth = self.Instruction:GetWrappedWidth();
    local frameHeight = self.Instruction:GetHeight();

    if self.LinkButton and self.LinkButton:IsShown() then
        local linkWidth = self.LinkButton:GetWidth();
        if linkWidth > textWidth then
            textWidth = linkWidth;
            self.Instruction:SetWidth(linkWidth);
            frameHeight = self.Instruction:GetHeight();
        end
        frameHeight = frameHeight + LINE_SPACING + self.LinkButton.Text:GetHeight();
    end
    local frameWidth = Round(STEP_TEXT_OFFSET_X + textWidth);
    frameHeight = Round(frameHeight);
    self:SetSize(frameWidth, frameHeight);

    return frameWidth, frameHeight
end

local function CreateStepFrame(parent)
    local f = CreateFrame("Button", nil, parent);
    f:SetSize(MIN_HITRECT_X, 24);
    Mixin(f, StepMixin);

    f.IndexText = f:CreateFontString(nil, "OVERLAY", "NarciDisabledButtonFont");
    f.IndexText:SetJustifyH("LEFT");
    f.IndexText:SetJustifyV("TOP");
    f.IndexText:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);

    f.Instruction = f:CreateFontString(nil, "OVERLAY", "NarciDisabledButtonFont");
    f.Instruction:SetJustifyH("LEFT");
    f.Instruction:SetJustifyV("TOP");
    f.Instruction:SetPoint("TOPLEFT", f, "TOPLEFT", STEP_TEXT_OFFSET_X, 0);
    f.Instruction:SetSpacing(LINE_SPACING);
    f.Instruction:SetWidth(TEXT_MAX_WIDTH);

    return f
end


local function CreateTutorialFrame(parent)
    if not MainFrame then
        local level = 90;

        local f = CreateFrame("Frame", nil, parent);
        MainFrame = f;
        f:SetSize(128, 128);
        f.Border = CreateFrame("Frame", nil, f, "NarciPhotoModeUIBorderTemplate");
        f.Background = f:CreateTexture(nil, "BACKGROUND");
        f.Background:SetAllPoints(true);
        f.Background:SetColorTexture(0.12, 0.12, 0.12);

        local bt = CreateFrame("Button", nil, f, "Narci_NavigationButton_Template");
        bt:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1);
        bt.Background:SetTexCoord(1, 0, 0, 1);
        bt.Icon:SetTexCoord(0, 0.25, 0.75, 1);
        bt:SetScript("OnClick", function()
            MainFrame:Hide();
        end);

        f:SetFrameStrata("FULLSCREEN_DIALOG");
        f:SetFrameLevel(level);
        f.Border:SetFrameLevel(level + 5);
        bt:SetFrameLevel(level + 3);

        f:EnableMouse(true);
        f:EnableMouseMotion(true);
    end

    return MainFrame
end

local function InitTutorial()
    CreateTutorialFrame(nil);
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    local maxStepWidth = 0;
    local fullHeight = FRAME_PADDING;

    for index, data in ipairs(INSTRUCTIONS) do
        local button = CreateStepFrame(MainFrame);
        button:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", FRAME_PADDING, -fullHeight);
        button:SetIndex(index);
        button:SetText(data.text);
        button:SetLink(data.link);
        local width, height = button:UpdateExtent();
        if width > maxStepWidth then
            maxStepWidth = width;
        end
        fullHeight = fullHeight + height + PARAGRAPH_SPACING;
    end

    fullHeight = fullHeight - PARAGRAPH_SPACING + FRAME_PADDING;
    MainFrame:SetSize(maxStepWidth + 2*FRAME_PADDING, fullHeight);
end

local function ToggleSpellVisualTutorial()
    if MainFrame then
        MainFrame:SetShown(not MainFrame:IsShown());
    else
        InitTutorial();
    end
end
NarciAPI.ToggleSpellVisualTutorial = ToggleSpellVisualTutorial;