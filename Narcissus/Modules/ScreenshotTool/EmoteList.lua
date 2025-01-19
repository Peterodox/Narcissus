local _, addon = ...

local DoEmote = DoEmote;
local TakeScreenshot = Screenshot;

local EmoteTokenList = {
	{"Talk", EMOTE94_CMD1},	{"TALKEX", EMOTE95_CMD1}, {"TALKQ", EMOTE96_CMD2}, {"Flee", YELL},
	{"Kiss", EMOTE59_CMD1}, {"Salute", EMOTE79_CMD1}, {"Bye", EMOTE102_CMD1}, {"Bow", EMOTE17_CMD1},
	{"Dance", EMOTE35_CMD1}, {"Read", EMOTE453_CMD2}, {"Train", EMOTE155_CMD1}, {"Chicken", EMOTE22_CMD1},
	{"Clap", EMOTE24_CMD1}, {"Cheer", EMOTE21_CMD1}, {"Cackle", EMOTE61_CMD1},
	{"Nod", EMOTE68_CMD1}, {"Doubt", EMOTE67_CMD1}, {"Point", EMOTE73_CMD1},
	{"Rude", EMOTE78_CMD1}, {"Flex", EMOTE42_CMD1}, {"ROAR", EMOTE76_CMD1},
	{"Cower", EMOTE29_CMD1}, {"Beg", EMOTE8_CMD1}, {"Cry", EMOTE32_CMD1},
	{"Laydown", EMOTE62_CMD1}, {"Stand", EMOTE143_CMD1}, {"Sit", EMOTE87_CMD1}, {"Kneel", EMOTE60_CMD1},
    {"Shy", EMOTE85_CMD1},
}

local NUM_ROWS = 7;


local MainFrame;
local EmoteFrame;
local EmoteButtons;


local function EmoteFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 1 then
        self:SetScript("OnUpdate", nil);
        self.inCooldown = nil;
        if self.autocapture then
            TakeScreenshot();
        end
    end
end

local function EmoteButton_OnClick(self)
    if not EmoteFrame.inCooldown then
        EmoteFrame.inCooldown = true;
        EmoteFrame.t = 0;
        EmoteFrame:SetScript("OnUpdate", EmoteFrame_OnUpdate);
        DoEmote(self.token, "none");
    end
end

local function EmoteButton_OnEnter(self)
    self.ButtonText:SetTextColor(1, 1, 1);
    MainFrame:OnEnter();
end

local function EmoteButton_OnLeave(self)
    self.ButtonText:SetTextColor(0.67, 0.67, 0.67);
    MainFrame:OnLeave();
end


local function AutoCaptureButton_AdjustSize(self)
    local width = self.ButtonText:GetWidth() + 32;
    if width < 80 then
        width = 80;
    end
    self:SetWidth(width);
end

local function AutoCaptureButton_UpdateVisual(self, isMouseOver)
    if EmoteFrame.autocapture then
        if isMouseOver then
            self.Background:SetColorTexture(0.541, 0.459, 0.176);
            self.BackgroundLeft:SetVertexColor(0.541, 0.459, 0.176);
        else
            self.Background:SetColorTexture(0.435, 0.360, 0.07);
            self.BackgroundLeft:SetVertexColor(0.435, 0.360, 0.07);
        end
    else
        if isMouseOver then
            self.Background:SetColorTexture(0.2, 0.2, 0.2);
            self.BackgroundLeft:SetVertexColor(0.2, 0.2, 0.2);
        else
            self.Background:SetColorTexture(0.12, 0.12, 0.12);
            self.BackgroundLeft:SetVertexColor(0.12, 0.12, 0.12);
        end
    end
end

local function AutoCaptureButton_OnClick(self)
    EmoteFrame.autocapture = not EmoteFrame.autocapture;
    AutoCaptureButton_UpdateVisual(self, true);
end

local function AutoCaptureButton_OnEnter(self)
    self.ButtonText:SetTextColor(1, 1, 1);
    AutoCaptureButton_UpdateVisual(self, true);
    MainFrame:OnEnter();
end

local function AutoCaptureButton_OnLeave(self)
    if EmoteFrame.autocapture then
        self.ButtonText:SetTextColor(0.8, 0.8, 0.8);
    else
        self.ButtonText:SetTextColor(0.67, 0.67, 0.67);
    end

    AutoCaptureButton_UpdateVisual(self, false);
    MainFrame:OnLeave();
end

NarciDoEmoteFrameMixin = {};

function NarciDoEmoteFrameMixin:OnLoad()
    EmoteFrame = self;
    MainFrame = self:GetParent();
end

function NarciDoEmoteFrameMixin:Init()
    --Sort by name
    local function SortByName(a, b)
        if a[2] and b[2] then
            return a[2] < b[2]
        else
            return a[1] < b[1]
        end
    end

    table.sort(EmoteTokenList, SortByName);

    local trim = string.trim;

    --Auto Capture Button
    local ac = self.AutoCaptureToggle;
    local bt = ac.ButtonText;
    bt:ClearAllPoints();
    bt:SetPoint("LEFT", ac, "LEFT", 24, 0);
    bt:SetText(Narci.L["Auto Capture"]);
    AutoCaptureButton_AdjustSize(ac);
    AutoCaptureButton_OnLeave(ac);
    ac:SetScript("OnClick", AutoCaptureButton_OnClick);
    ac:SetScript("OnEnter", AutoCaptureButton_OnEnter);
    ac:SetScript("OnLeave", AutoCaptureButton_OnLeave);


    local numEmotes = #EmoteTokenList;
    local X_MAX = 4;
    local Y_MAX = math.ceil(numEmotes / X_MAX);

    NUM_ROWS = Y_MAX;

    local BUTTON_WIDTH = 60;
    local BUTTON_HEIGHT = 24;
    local TEXT_PADDING2 = 12;
    local OFFSET_Y = BUTTON_HEIGHT + 2;


    --Create Backdrop
    local bg;
    local anchorTo;

    self.bgs = {};

    for i = 1, Y_MAX do
        if i == 1 then
            anchorTo = self;
        else
            anchorTo = bg;
        end

        bg = self:CreateTexture(nil, "BACKGROUND");
        bg:SetHeight(BUTTON_HEIGHT);

        if i == 1 then
            bg:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 0, -OFFSET_Y);
            bg:SetPoint("TOPRIGHT", anchorTo, "TOPRIGHT", 0, -OFFSET_Y);
        else
            bg:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, 0);
            bg:SetPoint("TOPRIGHT", anchorTo, "BOTTOMRIGHT", 0, 0);
        end

        if i % 2 == 1 then
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.9);
        else
            bg:SetColorTexture(0.12, 0.12, 0.12, 0.9);
        end

        self.bgs[i] = bg;
    end


    --Create Buttons
    if not EmoteButtons then
        EmoteButtons = {}
    end

    local row = 1;
    local col = 1;
    local maxColWidth = BUTTON_WIDTH;
    local button, text, textWidth;
    local totalWidth = 0;

    local LanguageDetector = NarciAPI.LanguageDetector;

    for i, info in ipairs(EmoteTokenList) do
        if not EmoteButtons[i] then
            EmoteButtons[i] = CreateFrame("Button", nil, self, "NarciEmoteButtonTemplate");
        end
        button = EmoteButtons[i];
        --button:SetPoint("TOPLEFT", self, "TOPLEFT", totalWidth, BUTTON_HEIGHT * (1 - row) - OFFSET_Y);   --from top to bottom then left to right
        button:SetPoint("LEFT", self.bgs[row], "LEFT", totalWidth, 0);
        button:SetWidth(BUTTON_WIDTH);
        button.token = info[1];

        if info[2] then
            text = trim(info[2],"/");       --remove the slash
            if LanguageDetector(text) == "RM" then
                text = string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2);     --upper initial
            end
            button.ButtonText:SetText(text);

            textWidth = button.ButtonText:GetWidth() + TEXT_PADDING2;
            if textWidth > maxColWidth then
                maxColWidth = math.ceil(textWidth);
            end
 
            button:SetScript("OnClick", EmoteButton_OnClick);
            button:SetScript("OnEnter", EmoteButton_OnEnter);
            button:SetScript("OnLeave", EmoteButton_OnLeave);
            button.ButtonText:SetTextColor(0.67, 0.67, 0.67);
        else
            button:Hide();
            print("Narissus: Emote "..info[2].." does not exist");
        end

        row = row + 1;
        if row > Y_MAX or i == numEmotes then
            row = 1;
            col = col + 1;
            totalWidth = totalWidth + maxColWidth;
            if maxColWidth > BUTTON_WIDTH then
                maxColWidth = BUTTON_WIDTH;
                for j = i - 1, i - Y_MAX do
                    EmoteButtons[j]:SetWidth(maxColWidth);
                end
            end
        end
    end


    self:SetSize(totalWidth, (Y_MAX + 1) * BUTTON_HEIGHT + 2);

    EmoteTokenList = nil;
    self.Init = nil;
    NarciDoEmoteFrameMixin.Init = nil;
end

function NarciDoEmoteFrameMixin:UseSmallerFont(state)
    local buttonHeight, fontObject;

    if state and not self.isSmallFont then
        self.isSmallFont = true;
        buttonHeight = 20;
        fontObject = "NarciFontNormal10Outline";
    elseif (not state) and self.isSmallFont then
        self.isSmallFont = nil;
        buttonHeight = 24;
        fontObject = "NarciFontMedium12";
    end

    if buttonHeight then
        fontObject = _G[fontObject];
        if not fontObject then return end;

        for _, button in ipairs(EmoteButtons) do
            button:SetHeight(buttonHeight);
            button.ButtonText:SetFontObject(fontObject);
        end

        self.AutoCaptureToggle:SetHeight(buttonHeight);
        self.AutoCaptureToggle.BackgroundLeft:SetSize(buttonHeight, buttonHeight);
        self.AutoCaptureToggle.ButtonText:SetFontObject(fontObject);
        AutoCaptureButton_AdjustSize(self.AutoCaptureToggle);
    
        for _, bg in ipairs(self.bgs) do
            bg:SetHeight(buttonHeight);
        end

        local offsetY = buttonHeight + 2;   --Auto Capture button height plus gap
        self.bgs[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY);
        self.bgs[1]:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -offsetY);

        self:SetHeight( NUM_ROWS * buttonHeight + offsetY);
    end
end

function NarciDoEmoteFrameMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciDoEmoteFrameMixin:OnEvent(event)
    if not (self:IsMouseOverButtons() or (self.parentButton and self.parentButton:IsMouseOver()) ) then
        self:Hide();
    end
end

function NarciDoEmoteFrameMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:SetScript("OnUpdate", nil);
    self.inCooldown = nil;

    if self.parentButton then
        self.parentButton.isOn = nil;
        self.parentButton:UpdateIcon();
    end
end

function NarciDoEmoteFrameMixin:IsMouseOverButtons()
    return self:IsVisible() and (self:IsMouseOver() or self.AutoCaptureToggle:IsMouseOver());
end

function NarciDoEmoteFrameMixin:IsFocused()
    return self:IsVisible() and (self:IsMouseOver(6, -6, -6, 6) or self.AutoCaptureToggle:IsMouseOver());
end

function NarciDoEmoteFrameMixin:OnEnter()
    MainFrame:OnEnter();
end

function NarciDoEmoteFrameMixin:OnLeave()
    MainFrame:OnLeave();
end

function NarciDoEmoteFrameMixin:ShowUI()
    if self.Init then
        self:Init();
    end

    if self.newFontSize then
        if self.newFontSize == 10 then
            self:UseSmallerFont(true);
        else
            self:UseSmallerFont(false);
        end
        self.newFontSize = nil;
    end

    self.FlyUp:Stop();
    self.FlyUp:Play();
    self:Show();
end

function NarciDoEmoteFrameMixin:HideUI()
    self.FlyUp:Stop();
    self:Hide();
end