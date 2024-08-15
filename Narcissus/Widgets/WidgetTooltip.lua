-- Widget Tooltip for:
---- Screenshot Toolbar
---- Photo Mode UI

local L = Narci.L;


local PATH_PREFIX = "Interface\\AddOns\\Narcissus\\Guide\\IMG\\";

local TEXT_PADDING = 12;
local TOOLTIP_MAX_WIDTH = 256;
local TEXT_MAX_WIDTH = TOOLTIP_MAX_WIDTH - 2*TEXT_PADDING;

local TOOLTIP_IMAGES = {
    HideTexts = true,
    TopQuality = true,
};

local TOOLTIP_BG_ART = {
    HideTexts = 2,
    TopQuality = 3,
};

local TOOLTIP_BG_COLORS = {
    Mog = {48, 25, 71},
    Emote = {71, 55, 25},
    HideTexts = {72, 32, 25},
    TopQuality = {25, 60, 71},
    Camera = {37, 60, 53},
    Preferences = {51, 51, 51},
};
TOOLTIP_BG_COLORS.Location = TOOLTIP_BG_COLORS.HideTexts;

local TOOLTIP_HEADER_COLORS = {
    Mog = {172, 115, 238},
    Emote = {224, 194, 56},
    HideTexts = {204, 82,82},
    TopQuality = {96, 182, 216},
    Camera = {129, 202, 165},
};
TOOLTIP_HEADER_COLORS.Location = TOOLTIP_HEADER_COLORS.HideTexts;

local function GetColorByButtonType(buttonType, tbl)
    if tbl[buttonType] then
        return tbl[buttonType][1]/255, tbl[buttonType][2]/255, tbl[buttonType][3]/255
    else
        return 0, 0, 0
    end
end


NarciGenericWidgetTooltipMixin = {};

function NarciGenericWidgetTooltipMixin:OnLoad()
    self:SetClampRectInsets(-6, 6, 6, -6);
end

function NarciGenericWidgetTooltipMixin:Init()
    local shrink = 2;
    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "shadowHugeR0", shrink);

    self:UpdateTextSize();
    self.Init = nil;
end

function NarciGenericWidgetTooltipMixin:UpdateTextSize()
    TEXT_MAX_WIDTH = TOOLTIP_MAX_WIDTH - 2*TEXT_PADDING;
    self.Image:SetSize(TOOLTIP_MAX_WIDTH, TOOLTIP_MAX_WIDTH*0.5);
    self.Header:SetWidth(TEXT_MAX_WIDTH);
    self.TextLine1:SetWidth(TEXT_MAX_WIDTH);
end

local function ShowToolbarTooltip_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.alpha = self.alpha + 2*self.t;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    if self.t > -0.2 and not self.ready then
        self.ready = true;
        self:SetupToolbarTooltip();
    end
end

function NarciGenericWidgetTooltipMixin:ShowToolbarTooltip(toolbarButton)
    self.t = -0.8;
    self.alpha = 0;
    self:SetAlpha(0);
    self:SetScript("OnUpdate", ShowToolbarTooltip_OnUpdate);
    self:ClearAllPoints();
    self:SetPoint("BOTTOM", toolbarButton, "TOP", 0, 12);
    self.Tail:ClearAllPoints();
    self.Tail:SetPoint("CENTER", toolbarButton, "TOP", 0, 12.5);

    self.buttonType = toolbarButton.type;
    self.ready = nil;
    self:Show();
end

local function ShowWidgetTooltip_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.alpha = self.alpha + 2*self.t;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    if self.t > -0.2 and not self.ready then
        self.ready = true;
        local b = self.parentButton;
        if b then
            local image = (b.tooltipImage and PATH_PREFIX..b.tooltipImage) or nil;
            self:SetupTooltip(b.tooltipHeader, b.tooltipDescription, image);
        end
    end
end

function NarciGenericWidgetTooltipMixin:ShowButtonTooltip(widget)
    self.parentButton = widget;
    self.t = -0.8;
    self.alpha = 0;
    self:SetAlpha(0);
    self:SetScript("OnUpdate", ShowWidgetTooltip_OnUpdate);
    self:ClearAllPoints();
    self:SetPoint("BOTTOM", widget, "TOP", 0, 8);
    self.Tail:ClearAllPoints();
    self.Tail:SetPoint("CENTER", widget, "TOP", 0, 8.5);

    self.buttonType = nil;
    self.ready = nil;
    self:Show();
    self:SetFrameStrata("TOOLTIP");

    self.Tail:SetVertexColor(0.120, 0.120, 0.120);
    self.Background:SetColorTexture(0.120, 0.120, 0.120);
end

function NarciGenericWidgetTooltipMixin:HideTooltip()
    self:ClearAllPoints();
    self:Hide();
end

function NarciGenericWidgetTooltipMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
    self:SetScript("OnUpdate", nil);
end


function NarciGenericWidgetTooltipMixin:OnShow()
    if self.Init then
        self:Init();
    end
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciGenericWidgetTooltipMixin:OnEvent(event, ...)
    --GLOBAL_MOUSE_DOWN
    self:HideTooltip();
end

local PENDING_TEXT;

local function ShowNewText_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.alpha = self.alpha + 2*self.t;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    if self.t > -0.2 and not self.ready then
        self.ready = true;
        local b = self.parentButton;
        if self.owner and PENDING_TEXT then
            local header, description, image;
            if type(PENDING_TEXT) == "table" then
                header = PENDING_TEXT[1];
                description = PENDING_TEXT[2];
                image = PENDING_TEXT[3];
            else
                description = PENDING_TEXT;
            end
            self:SetupTooltip(header, description, image);
        end
    end
end

function NarciGenericWidgetTooltipMixin:NewText(owner, texts, offsetX, offsetY, useDelay)
    self:HideTooltip();

    PENDING_TEXT = texts;
    self.owner = owner;

    if owner and texts then
        self.ready = nil;
        if useDelay then
            self.t = -0.8;
        else
            self.t = 0;
        end
        self.alpha = 0;
        self:SetAlpha(0);
        self:SetScript("OnUpdate", ShowNewText_OnUpdate);
        self:Show();
        self:SetFrameStrata("TOOLTIP");
        offsetX = offsetX or 0;
        offsetY = 8 + (offsetY or 0);
        self:SetPoint("BOTTOM", owner, "TOP", offsetX, offsetY);
        self.Tail:SetPoint("CENTER", owner, "TOP", offsetX, offsetY + 0.5);
        self.Tail:SetVertexColor(0.120, 0.120, 0.120);
        self.Background:SetColorTexture(0.120, 0.120, 0.120);
    end
end

function NarciGenericWidgetTooltipMixin:SetupTooltip(headerText, description, imageFile)
    self.Header:ClearAllPoints();
    self.TextLine1:ClearAllPoints();

    if headerText then
        self.Header:SetText(headerText);
        self.Header:Show();
        if imageFile then
            self.Header:SetPoint("TOPLEFT", self.Image, "BOTTOMLEFT", TEXT_PADDING, -TEXT_PADDING);
        else
            self.Header:SetPoint("TOPLEFT", self, "TOPLEFT", TEXT_PADDING, -TEXT_PADDING);
        end

        self.TextLine1:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -4);
    else
        self.Header:SetText(nil);
        self.Header:Hide();
        if not description then
            self:HideTooltip();
            return
        end

        self.TextLine1:SetPoint("TOPLEFT", self, "TOPLEFT", TEXT_PADDING, -TEXT_PADDING);
    end

    self.TextLine1:SetText(description or "");

    local textMinHeight;
    local i = TOOLTIP_BG_ART[self.buttonType];

    if i then
        textMinHeight = 80;
        self.BackgroundArt:SetTexCoord(0.25*i, 0.25*(i+1), 0, 1);
        self.BackgroundArt:Show();
    else
        textMinHeight = 0;
        self.BackgroundArt:Hide();
    end

    local textHeight, imageHeight;

    if imageFile then
        self.Image:SetTexture(imageFile);
        self.Image:Show();

        self.Background:SetPoint("TOPLEFT", self.Image, "BOTTOMLEFT", 0, 0);
        self:SetWidth(TOOLTIP_MAX_WIDTH);
        textHeight = self.Header:GetHeight() + self.TextLine1:GetHeight() + 4;
        imageHeight = TOOLTIP_MAX_WIDTH * 0.5;
    else
        self.Image:Hide();
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        self:SetWidth(math.min(self.TextLine1:GetWrappedWidth() or TEXT_MAX_WIDTH, TEXT_MAX_WIDTH) + 2*TEXT_PADDING);
        if headerText then
            textHeight = self.Header:GetHeight() + self.TextLine1:GetHeight() + 4;
        else
            textHeight = self.TextLine1:GetHeight();
        end
        imageHeight = 0;
    end

    self:SetHeight(imageHeight + math.max(textMinHeight, textHeight + 2*TEXT_PADDING));
end

function NarciGenericWidgetTooltipMixin:SetupToolbarTooltip()
    if self.buttonType then
        local headerText = L["Toolbar "..self.buttonType.." Button"];
        local description = L["Toolbar "..self.buttonType.." Button Tooltip"];
        local imageFile = TOOLTIP_IMAGES[self.buttonType] and (PATH_PREFIX..self.buttonType);

        self:SetupTooltip(headerText, description, imageFile);

        local r, g, b = GetColorByButtonType(self.buttonType, TOOLTIP_BG_COLORS);
        self.Tail:SetVertexColor(r, g, b);
        self.Background:SetColorTexture(r, g, b);

        r, g, b = GetColorByButtonType(self.buttonType, TOOLTIP_HEADER_COLORS);
        self.Header:SetTextColor(r, g, b);
        self.TextLine1:SetTextColor(0.8, 0.8, 0.8);
        self:SetFrameStrata("TOOLTIP");
    else
        self:HideTooltip();
    end
end

function NarciGenericWidgetTooltipMixin:UseSmallFont(state)
    if state then
        if (self.smallFont == nil) or (not self.smallFont) then
            self.smallFont = true;
            self.TextLine1:SetFontObject("NarciFontThin9");
            self.TextLine1:SetShadowColor(0, 0, 0);
            self.TextLine1:SetShadowOffset(1, -1);
            TOOLTIP_MAX_WIDTH = 256;
            self:UpdateTextSize();
        end
    else
        if self.smallFont then
            self.smallFont = false;
            self.TextLine1:SetFontObject("NarciFontThin12");
            self.TextLine1:SetShadowColor(0, 0, 0);
            self.TextLine1:SetShadowOffset(1, -1);
            TOOLTIP_MAX_WIDTH = 300;
            self:UpdateTextSize();
        end
    end
end