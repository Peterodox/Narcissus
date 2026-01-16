-- Similar to UIErrorsFrame, with additions:
-- Use drop shadow to increase legibility. Because sometimes there is another frame below like TransmogFrame
-- Color Presets

local _, addon = ...


local MainFrame;

local Def = {
    FadeDelay = 1,
    MaxTextWidth = 512,
};


local MessageFrameMixin = {};
do
    function MessageFrameMixin:AddMessage(text, r, g, b)
        if not r then
            r, g, b = 1, 0.82, 0;
        end
        self.Text:SetText(text);
        self.Text:SetTextColor(r, g, b);
        local textWidth = self.Text:GetWrappedWidth();
        local textHeight = self.Text:GetHeight();
        local offset = 48;
        self.Background:SetSize(textWidth + 1.2*offset, textHeight + offset);
        self:FadeIn();
    end

    function MessageFrameMixin:AddMessageGreen(text)
        self:AddMessage(text, 124/255, 197/255, 118/255);
    end

    function MessageFrameMixin:AddMessageRed(text)
        self:AddMessage(text, 1, 0.125, 0.125);
    end

    function MessageFrameMixin:FadeIn()
        self.alpha = self:GetAlpha();
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
        self:Show();
    end

    function MessageFrameMixin:FadeOut()
        self.alpha = self:GetAlpha();
        if self.alpha < 0.99 then
            self.t = 0;
        else
            self.t = -Def.FadeDelay;
        end
        self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
    end

    function MessageFrameMixin:OnUpdate_FadeIn(elapsed)
        self.alpha = self.alpha + 8 * elapsed;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetAlpha(self.alpha);
            self:SetScript("OnUpdate", nil);
            self:FadeOut();
        end
        self:SetAlpha(self.alpha);
    end

    function MessageFrameMixin:OnUpdate_FadeOut(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0 then
            self.alpha = self.alpha - 2 * elapsed;
            if self.alpha <= 0 then
                self.alpha = 0;
                self.t = 0;
                self:SetScript("OnUpdate", nil);
                self:Hide();
            end
            self:SetAlpha(self.alpha);
        end
    end
end

local function DisplayTopMessage(text, colorKey)
    if not MainFrame then
        MainFrame = CreateFrame("Frame", nil, UIParent);
        MainFrame:SetFrameStrata("DIALOG");
        MainFrame:SetAlpha(0);
        MainFrame:Hide();
        MainFrame:SetFrameLevel(128);
        MainFrame:SetToplevel(true);
        MainFrame:SetSize(Def.MaxTextWidth, 60);
        MainFrame:SetPoint("TOP", UIParent, "TOP", 0, -144);

        Mixin(MainFrame, MessageFrameMixin);

        local Text = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
        MainFrame.Text = Text;
        Text:SetPoint("TOP", MainFrame, "TOP", 0, 0);
        Text:SetWidth(Def.MaxTextWidth);
        Text:SetJustifyH("CENTER");
        Text:SetSpacing(2);

        local Background = MainFrame:CreateTexture(nil, "OVERLAY", nil, -1);
        MainFrame.Background = Background;
        Background:SetTexture("Interface/AddOns/Narcissus/Art/Frames/NameplateTextShadow");
        Background:SetTextureSliceMargins(40, 24, 40, 24);
        Background:SetTextureSliceMode(0);
        Background:SetSize(128, 32);
        Background:SetPoint("CENTER", Text, "CENTER", 0, 0);
        Background:SetAlpha(0.6);
    end

    if colorKey and MainFrame["AddMessage"..colorKey] then
        MainFrame["AddMessage"..colorKey](MainFrame, text);
    else
        MainFrame:AddMessage(text);
    end
end
addon.DisplayTopMessage = DisplayTopMessage;