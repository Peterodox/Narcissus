local _, addon = ...

local outQuart = addon.EasingFunctions.outQuart;


local EXPANDED_WIDTH, EXPANDED_HEIGHT = 256, 156;
local COLLAPSED_WIDTH, COLLAPSED_HEIGHT = 60, 24;

local Toolbar, MainFrame;


local function SharedOnMouseMotionCallback(frame, mouseEnter)
    if mouseEnter then
        Toolbar:OnEnter();
    else
        Toolbar:OnLeave();
    end
end

NarciScreenshotToolbarTransmogListMixin = {};

function NarciScreenshotToolbarTransmogListMixin:OnShow()
    if self.Init then
        self:Init();
    end
end

function NarciScreenshotToolbarTransmogListMixin:OnHide()
    self:SetScript("OnUpdate", nil);
    self:SetSize(COLLAPSED_WIDTH, COLLAPSED_HEIGHT);
end

function NarciScreenshotToolbarTransmogListMixin:OnEvent()
    if not self:IsFocused() then
        self:Collapse();
    end
end

function NarciScreenshotToolbarTransmogListMixin:SetFormat(token)
    self.textFormat = token;
end

function NarciScreenshotToolbarTransmogListMixin:GetFormat()
    return self.textFormat
end

function NarciScreenshotToolbarTransmogListMixin:UpdateTransmogList(forceUpdateWhenHidden)
    if self.getItemListFunc and (self.Subframe:IsShown() or forceUpdateWhenHidden) then
        self.Subframe.TextContainer:SetText(self.getItemListFunc(self:GetFormat(), self.includeItemID));
    end
end

function NarciScreenshotToolbarTransmogListMixin:IsFocused()
    return self:IsVisible() and self:IsMouseOver()
end

function NarciScreenshotToolbarTransmogListMixin:OnEnter()
    SharedOnMouseMotionCallback(self, true);
end

function NarciScreenshotToolbarTransmogListMixin:OnLeave()
    SharedOnMouseMotionCallback(self, false);
end


local function TokenButton_OnClick(self)
    MainFrame:SetFormat(self.token);
    for i, button in ipairs(MainFrame.tokens) do
        if button == self then
            button.Icon:SetSize(20, 20);
            button.Icon:SetDesaturation(0);
        else
            button.Icon:SetSize(16, 16);
            button.Icon:SetDesaturation(1);
        end
    end
    MainFrame:UpdateTransmogList(true);
end

local function TokenButton_OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
    SharedOnMouseMotionCallback(self, true);
end

local function TokenButton_OnLeave(self)
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    SharedOnMouseMotionCallback(self, false);
end

local function TokenButton_Create(parent, id)
    local button = CreateFrame("Button", nil, parent);
    button:SetSize(20, 20);
    button.Icon = button:CreateTexture();
    
    if id == 1 then
        button.Icon:SetSize(20, 20);
        button.Icon:SetDesaturation(0);
    else
        button.Icon:SetSize(16, 16);
        button.Icon:SetDesaturation(1);
    end

    button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0);
    button.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Logos\\TextFormatTokens");
    button.Icon:SetTexCoord((id - 1)*0.125, id*0.125, 0, 1);
    button:SetScript("OnClick", TokenButton_OnClick);
    button:SetScript("OnEnter", TokenButton_OnEnter);
    button:SetScript("OnLeave", TokenButton_OnLeave);
    button.Icon:SetVertexColor(0.8, 0.8, 0.8);
    button:SetHitRectInsets(-2, -2, -2, -2);

    return button
end

local function ItemIDButton_OnClick(self)
    MainFrame.includeItemID = not MainFrame.includeItemID;
    self.Tick:SetShown(MainFrame.includeItemID);
    MainFrame:UpdateTransmogList(true);
end

local function ItemIDButton_OnEnter(self)
    MainFrame.Subframe.ItemIDLabel:SetTextColor(1, 1, 1);
    SharedOnMouseMotionCallback(self, true);
end

local function ItemIDButton_OnLeave(self)
    MainFrame.Subframe.ItemIDLabel:SetTextColor(0.72, 0.72, 0.72);
    SharedOnMouseMotionCallback(self, false);
end


local function ExpandButton_OnEnter(self)
    self.ButtonText:SetTextColor(1, 1, 1);
    SharedOnMouseMotionCallback(self, true);
end

local function ExpandButton_OnLeave(self)
    self.ButtonText:SetTextColor(0.78, 0.33, 1);
    SharedOnMouseMotionCallback(self, false);
end

function NarciScreenshotToolbarTransmogListMixin:OnLoad()
    Toolbar = self:GetParent();
end

function NarciScreenshotToolbarTransmogListMixin:Init()
    MainFrame = self;

    --Create Token Buttons
    local textFormats = {
        "text", "reddit", "wowhead", "nga", "mmochampion",
    };

    self.tokens = {};
    for i, token in ipairs(textFormats) do
        self.tokens[i] = TokenButton_Create(self.Subframe, i);
        self.tokens[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 14 + 22*(i - 1), -14);
        self.tokens[i].token = token;
    end

    self.Subframe.ItemIDToggle:SetScript("OnClick", ItemIDButton_OnClick);
    self.Subframe.ItemIDToggle:SetScript("OnEnter", ItemIDButton_OnEnter);
    self.Subframe.ItemIDToggle:SetScript("OnLeave", ItemIDButton_OnLeave);

    local eb = self.ExpandButton;
    eb.ButtonText:SetText(Narci.L["Copy Texts"]);

    local buttonWidth = math.floor((eb.ButtonText:GetWidth() or 120) + 0.5) + 26;
    self.collapsedWidth = buttonWidth;
    COLLAPSED_WIDTH = buttonWidth;

    eb:SetWidth(buttonWidth);
    eb:SetScript("OnClick", function()
        self:Expand();
    end);
    eb:SetScript("OnEnter", ExpandButton_OnEnter);
    eb:SetScript("OnLeave", ExpandButton_OnLeave);
    ExpandButton_OnLeave(eb);

    self.Subframe.TextContainer.onMouseMotion = SharedOnMouseMotionCallback;

    self:Collapse(true);
    self.Init = nil;
end

local function Expand_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    local w = outQuart(self.t, self.fromW, self.toW, 0.35);
    local h = outQuart(self.t, self.fromH, self.toH, 0.35);

    local delta;

    if self.lastW then
        delta = w - self.lastW;
        self.lastW = w;
        if delta < 0.2 and delta > -0.2 then
            delta = 0;
        end
    else
        self.lastW = w;
    end

    if self.t >= 0.35 or (delta and delta == 0) then
        self:SetScript("OnUpdate", nil);
        w, h = self.toW, self.toH;
    end

    self:SetSize(w, h);
end


function NarciScreenshotToolbarTransmogListMixin:Expand(instant)
    self.Subframe:Show();
    self.ExpandButton:Hide();
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    self.lastW = nil;

    if instant then
        self:SetScript("OnUpdate", nil);
        self:SetSize(EXPANDED_WIDTH, EXPANDED_HEIGHT);
    else
        self.t = 0;
        self.fromW, self.fromH = self:GetSize();
        self.toW, self.toH = EXPANDED_WIDTH, EXPANDED_HEIGHT;
        self:SetScript("OnUpdate", Expand_OnUpdate);
        self.Subframe.FadeIn:Play();
    end

    self:UpdateTransmogList(true);
end

function NarciScreenshotToolbarTransmogListMixin:Collapse(instant)
    self.Subframe:Hide();
    self.ExpandButton:Show();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self.lastW = nil;

    if instant then
        self:SetScript("OnUpdate", nil);
        self:SetSize(COLLAPSED_WIDTH, COLLAPSED_HEIGHT);
    else
        self.t = 0;
        self.fromW, self.fromH = self:GetSize();
        self.toW, self.toH = COLLAPSED_WIDTH, COLLAPSED_HEIGHT;
        self:SetScript("OnUpdate", Expand_OnUpdate);
    end
end

function NarciScreenshotToolbarTransmogListMixin:ShowUI()
    self:Collapse(true);
    self:Show();
end

function NarciScreenshotToolbarTransmogListMixin:OnMouseDown(button)
    if button == "RightButton" then
        self:Collapse();
    end
end