local FadeFrame = NarciFadeUI.Fade;

local ActiveCharButton, ClassColorOption, MainContainer;

local LEVEL_CLASS_FORMAT = "|cffffffffLevel %d|r %s";

local expansionLogo = {
    --Case-insensitive
    [0] = "Classic",
    [1] = "BC",                     --This one is somehow low-resolution
    [2] = "Woltk",
    [3] = "CC",
    [4] = "MP",
    [5] = "WOD",
    [6] = "Legion",
    [7] = "BattleforAzeroth",
    [8] = "Shadowlands",
    [9] = "Dragonflight",
    [10] = "thewarwithin",
};

local expansionName = {
    [0] = "Classic",
    [1] = "The Burning Crusade",
    [2] = "Wrath of the Lich King",
    [3] = "Cataclysm",
    [4] = "Mists of Pandaria",
    [5] = "Warlords of Draenor",
    [6] = "Legion",
    [7] = "Battle for Azeroth",
    [8] = "Shadowlands",
    [9] = "Dragonflight",
    [10] = "The War Within";
};

local classFiles = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
};

local InteractableWidgetSharedMixin = {}

function InteractableWidgetSharedMixin:ShowArea()
    if not self.Area then
        local tex = self:CreateTexture(nil, "BACKGROUND");
        tex:SetColorTexture(0.5, 0.5, 1, 0.4);
        tex:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        tex:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        self.Area = tex;
    end
    self.Area:Show();
end

function InteractableWidgetSharedMixin:HideArea()
    if self.Area then
        self.Area:Hide();
    end
end

function InteractableWidgetSharedMixin:OnEnter()
    self:ShowArea();
end

function InteractableWidgetSharedMixin:OnLeave()
    self:HideArea();
end



NarciGlueCharSelectCharacterButtonMixin = CreateFromMixins(InteractableWidgetSharedMixin);

function NarciGlueCharSelectCharacterButtonMixin:OnClick()
    self:GetParent().CharacterOptionFrame:SetParentObject(self);
end

function NarciGlueCharSelectCharacterButtonMixin:SetFactionEmblem(factionID)
    factionID = factionID or 0;
    self.factionID = factionID;
    if factionID == 0 then
        self.FactionEmblem:Hide();
    elseif factionID == 1 then
        self.FactionEmblem:SetAtlas("CharacterSelection_Horde_Icon", true);
        self.FactionEmblem:Show();
    elseif factionID == 2 then
        self.FactionEmblem:SetAtlas("CharacterSelection_Alliance_Icon", true);
        self.FactionEmblem:Show();
    end
end

function NarciGlueCharSelectCharacterButtonMixin:SetUp(name, level, className, classFileName, location, faction)
    self:SetName(name);
    self:SetLocation(location);
    self.className = className;
    local colorMixin = C_ClassColor.GetClassColor(classFileName);
    if colorMixin then
        self:SetClassColor( colorMixin:GetRGB() );
    end
    self:SetLevelAndName(level, className);
    local factionID;
    if faction then
        if faction == "Horde" then
            factionID = 1;
        elseif faction == "Alliance" then
            factionID = 2;
        end
    else
        factionID = 0;
    end
    self:SetFactionEmblem(factionID);
    self:Show();
end

function NarciGlueCharSelectCharacterButtonMixin:SetUnit(unit)
    local name = UnitName(unit);
    local level = UnitLevel(unit);
    local className, classFileName = UnitClass(unit);
    local location = GetRealZoneText();
    local englishFaction = UnitFactionGroup(unit);
    self:SetUp(name, level, className, classFileName, location, englishFaction);
end

function NarciGlueCharSelectCharacterButtonMixin:SetName(name)
    if not name or name == "" then
        name = "Player";
    end
    self.CharacterName:SetText(name);
end

function NarciGlueCharSelectCharacterButtonMixin:SetLevel(level)
    level = tonumber(level or 0);
    self.Info:SetText(string.format(LEVEL_CLASS_FORMAT, level, (self.className or "") ));
    self.level = level;
end

function NarciGlueCharSelectCharacterButtonMixin:SetClass(className)
    if not className or className == "" then
        className = UnitClass("player");
    end
    self.className = className;
    self.Info:SetText(string.format(LEVEL_CLASS_FORMAT, (self.level or 0), self.className));
end

function NarciGlueCharSelectCharacterButtonMixin:SetLevelAndName(level, className)
    level = tonumber(level or 0);
    self.level = level;
    self.className = className;
    self.Info:SetText(string.format(LEVEL_CLASS_FORMAT, level, (className or "") ));
end

function NarciGlueCharSelectCharacterButtonMixin:SetClassColor(r, g, b)
    self.Info:SetTextColor(r, g, b);
end

function NarciGlueCharSelectCharacterButtonMixin:SetLocation(location)
    if not location or location == "" then
        location = GetRealZoneText();
    end
    self.Location:SetText(location);
end


NarciStickerExpansionLogoMixin = CreateFromMixins(InteractableWidgetSharedMixin);

function NarciStickerExpansionLogoMixin:OnClick()
    local option = self.OptionFrame;
    if not self.isLoaded then
        --Create Options
        self.isLoaded = true;
        local button;
        local numExpansions = #expansionName;
        local height = 16;
        local width;
        local maxWidth = 0;
        for i = 0, numExpansions, 1 do
            button = CreateFrame("Button", nil, option, "NarciExpansionSelectionButtonTemplate");
            button:SetPoint("TOPLEFT", option, "TOPLEFT", 0, -height * i - height*0.25);
            width = button:Init(i) + 16;
            if width > maxWidth then
                maxWidth = width;
            end
        end
        for k, b in pairs(option.ExpansionButtons) do
            b:SetWidth(maxWidth);
        end
        option:SetHeight(height *(numExpansions + 1.5));
        option:SetWidth(maxWidth);
    end
    option:Toggle();
end

local function SetExpansionLogo(expansionLevel)
    local f = MainContainer.LogoSelect;
    if expansionLogo[expansionLevel] then
        local prefix;
        if expansionLevel == 1 then
            prefix = "Interface\\AddOns\\Narcissus\\Art\\Stickers\\Glues-WoW-%sLogo";
        else
            prefix = "Interface\\GLUES\\COMMON\\Glues-WoW-%sLogo";
        end
        f.ExpansionLogo:SetTexture( string.format(prefix, expansionLogo[expansionLevel]) );
        f.ExpansionLogoMask:SetTexture( string.format(prefix, expansionLogo[expansionLevel]) );

        local buttons = f.OptionFrame.ExpansionButtons;
        if buttons then
            for k, button in pairs(buttons) do
                if button.id == expansionLevel then
                    button:DisableButton();
                else
                    button:EnableButton();
                end
            end
        end
    end
end

NarciExpansionSelectionButtonMixin = {};

function NarciExpansionSelectionButtonMixin:Init(id)
    self.id = id;
    self.Label:SetText(expansionName[id]);
    self:EnableButton();
    self.Background:SetColorTexture(0.8, 0.8, 0.8, 0.85);
    return self.Label:GetWidth();
end

function NarciExpansionSelectionButtonMixin:OnEnter()
    self.Label:SetTextColor(1, 1, 1);
end

function NarciExpansionSelectionButtonMixin:OnLeave()
    self.Label:SetTextColor(0.72, 0.72, 0.72);
end

function NarciExpansionSelectionButtonMixin:EnableButton()
    self:Enable();
    self.Label:SetTextColor(0.72, 0.72, 0.72);
    self.Background:Hide();
end

function NarciExpansionSelectionButtonMixin:DisableButton()
    self:Disable();
    self.Label:SetTextColor(0, 0, 0);
    self.Background:Show();
end

function NarciExpansionSelectionButtonMixin:OnClick()
    SetExpansionLogo(self.id);
end



local function UpdateCharacterName(self, isUserInput)
    if isUserInput then
        if ActiveCharButton then
            ActiveCharButton:SetName(self:GetText());
        end
    end
end

local function CharacterSelect_Init(self)
    self:SetScript("OnShow", nil);

    --Player name
    local unit = "player";
    local name = UnitName(unit);

    local CharacterNameBox = CreateFrame("EditBox", nil, self, "NarciStickerEditableTextTemplate");
    self.CharacterName = CharacterNameBox;
    CharacterNameBox:SetSize(240, 32);
    CharacterNameBox:SetFontObject("SystemFont22_Shadow_Outline");
    CharacterNameBox:SetJustifyH("CENTER");
    CharacterNameBox:SetJustifyV("BOTTOM");
    CharacterNameBox:SetTextColor(1, 0.78, 0);
    CharacterNameBox:SetPoint("BOTTOM", 0, 94);
    CharacterNameBox:SetMaxLetters(16);
    CharacterNameBox:SetText(name);
    CharacterNameBox:SetScript("OnTextChanged", UpdateCharacterName);

    local button;
    button = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
    button:SetPoint("BOTTOMRIGHT", -10, 10);
    button:SetSize(100, 28);
    button:SetText("Back");

    local DeleteButton = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
    DeleteButton:SetPoint("RIGHT", button, "LEFT", -10, 0);
    DeleteButton:SetSize(144, 28);
    DeleteButton:SetText("Delete Character");

    button = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
    button:SetPoint("BOTTOMLEFT", 10, 10);
    button:SetText("Menu");

    local button2 = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
    button2:SetPoint("BOTTOM", button, "TOP", 0, 4);
    button2:SetText("AddOns");

    local button3 = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
    button3:SetPoint("BOTTOM", button2, "TOP", 0, 4);
    button3:SetText("Shop");
    button3:SetButtonAtlas("128-GoldRedButton");
    button3.ButtonText:ClearAllPoints();
    button3.ButtonText:SetPoint("CENTER", button3, "CENTER", 10, 0);
    local logo = button3:CreateTexture(nil, "OVERLAY");
    logo:SetSize(16, 16);
    logo:SetPoint("RIGHT", button3.ButtonText, "LEFT", -3, 0);
    logo:SetAtlas("128-Store-Main");

    ----Character List----
    local cf = self.SelectCharacterFrame;

    --Character Buttons

    if not cf.CharacterButtons then
        button = CreateFrame("Button", nil, cf, "NarciGlueCharSelectCharacterButtonTemplate");
        button:SetPoint("TOP", cf, "TOP", 0, -60);
    end
    local buttons = cf.CharacterButtons;
    button = buttons[1];
    ActiveCharButton = button;
    button:SetUnit("player");

    --Change Realm
    local realmName = GetRealmName();
    local EditBox = CreateFrame("EditBox", nil, cf, "NarciStickerEditableTextTemplate");
    EditBox:SetHeight(24);
    EditBox:SetPoint("TOP", 0, -5);
    EditBox:SetPoint("LEFT", 8, 0);
    EditBox:SetPoint("RIGHT", -8, 0);
    EditBox:SetFontObject("Narci_SystemFont_Shadow_Outline_Large");
    EditBox:SetJustifyH("CENTER");
    EditBox:SetTextColor(0.5, 0.5, 0.5);
    EditBox:SetMaxLetters(20);
    EditBox:SetScript("OnEditFocusLost", function(f)
        f:OnEditFocusLost();
        if f:GetText() then
            f:SetText(realmName);
        end
    end);
    EditBox:SetText(realmName);

    button = CreateFrame("Frame", nil, cf, "NarciGlueButtonSmallTemplate");
    button:SetPoint("TOP", EditBox, "BOTTOM", 0, 2);
    button:SetText("Change Realm");

    --Undelete Button
    local Undelete = CreateFrame("Button", nil, cf);
    Undelete:SetSize(28, 28);
    Undelete:SetPoint("BOTTOMRIGHT", -16, 16);
    Undelete:Disable();
    Undelete:SetDisabledAtlas("128-RedButton-Refresh");

    --"Create" Button
    button = CreateFrame("Frame", nil, cf, "NarciGlueButtonSmallTemplate");
    button:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", 16, 16);
    button:SetPoint("RIGHT", Undelete, "LEFT", -10, 0);
    button:SetText("Create New Character");


    local EnterWorldButton = CreateFrame("Frame", nil, self, "NarciGlueButtonTemplate");
    EnterWorldButton:SetPoint("BOTTOM", 0, 46);
    EnterWorldButton:SetSize(185, 40);
    EnterWorldButton:SetText("Enter World");

    for i = 1, 2 do
        local RotateButton = CreateFrame("Frame", nil, self);
        RotateButton:SetSize(50, 50);
        local Background = RotateButton:CreateTexture(nil, "BACKGROUND");
        Background:SetSize(36, 36);
        Background:SetPoint("CENTER", 0, 0);
        Background:SetAtlas("common-button-square-gray-up");
        local Icon = RotateButton:CreateTexture(nil, "OVERLAY");
        Icon:SetSize(16, 16);
        Icon:SetPoint("CENTER", 0, 0);
        if i == 1 then
            Icon:SetAtlas("common-icon-rotateleft");
            RotateButton:SetPoint("TOP", EnterWorldButton, "BOTTOM", -16, 6);
        else
            Icon:SetAtlas("common-icon-rotateright");
            RotateButton:SetPoint("TOP", EnterWorldButton, "BOTTOM", 16, 6);
        end
    end
end

local function LoginScreen_Init(self)
    self:SetScript("OnShow", nil);

	local version, internalVersion, date, tocVersion = GetBuildInfo();
    local VERSION_TEMPLATE = "Version %s (%s) (Release x64)\n%s";
    local ClientVersion = self:CreateFontString(nil, "OVERLAY", "NarciGlueFontNormalSmall");
    ClientVersion:SetJustifyH("LEFT");
    ClientVersion:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 10, 10);
	ClientVersion:SetText( string.format(VERSION_TEMPLATE, version, internalVersion, date) );

	local year = date:sub(#date - 3, #date);
    local BLIZZ_DISCLAIMER_FORMAT = "Copyright 2004-%s  Blizzard Entertainment. All Rights Reserved.";
    local Disclaimer = self:CreateFontString(nil, "OVERLAY", "NarciGlueFontNormalSmall");
    Disclaimer:SetPoint("BOTTOM", self, "BOTTOM", 0, 10);
	Disclaimer:SetText( string.format(BLIZZ_DISCLAIMER_FORMAT, year) );

    local button, lastButton;

    local leftButtons = {
        "Community Site", "My Account", "Create Account"
    };

    for i = 1, #leftButtons do
        button = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
        if i == 1 then
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 17, 89);
        else
            button:SetPoint("BOTTOM", lastButton, "TOP", 0, 10);
        end
        button:SetSize(138, 28);
        button:SetText(leftButtons[i]);
        lastButton = button;
    end

    local rightButtons = {
        "Quit", "Credits", "Cinematics", "System"
    };

    for i = 1, #rightButtons do
        button = CreateFrame("Frame", nil, self, "NarciGlueButtonSmallTemplate");
        if i == 1 then
            button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 34);
        elseif i == 2 then
            button:SetPoint("BOTTOM", lastButton, "TOP", 0, 87);
        else
            button:SetPoint("BOTTOM", lastButton, "TOP", 0, 10);
        end
        button:SetSize(138, 28);
        button:SetText(rightButtons[i]);
        lastButton = button;
    end

    button = CreateFrame("Frame", nil, self, "NarciGlueEditBoxTemplate");
    button.Label:SetText("Email or Phone");
    button:SetPoint("BOTTOM", self, "BOTTOM", 0, 345);

    button = CreateFrame("Frame", nil, self, "NarciGlueEditBoxTemplate");
    button.Label:SetText("Password");
    button:SetPoint("BOTTOM", self, "BOTTOM", 0, 275);

    button = CreateFrame("Frame", nil, self, "NarciGlueButtonTemplate");
    button:SetText("Log In");
    button:SetSize(200, 30);
    button:SetPoint("BOTTOM", self, "BOTTOM", 0, 180);

    local logo = self:CreateTexture(nil, "OVERLAY");
    logo:SetSize(100, 100);
    logo:SetTexture("Interface\\Glues\\Mainmenu\\Glues-BlizzardLogo");
    logo:SetPoint("BOTTOM", self, "BOTTOM", 0, 8);
end

local function LogoSelect_Init(self)
    self:SetScript("OnShow", nil);
    local expansionLevel = GetExpansionLevel();
    if not expansionLogo[expansionLevel] then
        expansionLevel = 8;
    end
    SetExpansionLogo(expansionLevel);
end

NarciPhotoModeStickerContainerMixin = {};

function NarciPhotoModeStickerContainerMixin:OnLoad()
    MainContainer = self;

    self.CharacterSelectUI:SetScript("OnShow", CharacterSelect_Init);
    self.LoginScreen:SetScript("OnShow", LoginScreen_Init);
    self.LogoSelect:SetScript("OnShow", LogoSelect_Init);

    self.OnLoad = nil;
end

function NarciPhotoModeStickerContainerMixin:ShowOverlay(id)
    self.LoginScreen:SetShown(id == 1);
    self.CharacterSelectUI:SetShown(id == 2);
    self:SetShown(id);
    self.LogoSelect:SetShown(id);
end

function NarciPhotoModeStickerContainerMixin:OnHide()
    self:ShowOverlay();
end

--/run NarciShowCharacterSelectUI()


NarciStickerEditableTextMixin = CreateFromMixins(InteractableWidgetSharedMixin);     --EditBox

function NarciStickerEditableTextMixin:QuitEdit()
    self:ClearFocus();
end

function NarciStickerEditableTextMixin:OnEditFocusGained()

end

function NarciStickerEditableTextMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    self:HideArea();
end

function NarciStickerEditableTextMixin:OnEnterPressed()
    self:QuitEdit();
end

function NarciStickerEditableTextMixin:OnEscapePressed()
    self:QuitEdit();
end

function NarciStickerEditableTextMixin:OnHide()
    self:QuitEdit();
    self:HideArea();
end

function NarciStickerEditableTextMixin:OnEnter()
    self:ShowArea();
end

function NarciStickerEditableTextMixin:OnLeave()
    if not self:HasFocus() then
        self:HideArea();
    end
end


NarciStickerCharacterOptionMixin = CreateFromMixins(NarciAutoCloseFrameMixin);

function NarciStickerCharacterOptionMixin:OnLoad()
    ClassColorOption = self;
    local ColorToggle = self.ColorToggle;
    ColorToggle:SetScript("OnEnter", function(f)
        f.Background:Show();
    end);
    ColorToggle:SetScript("OnLeave", function(f)
        f.Background:Hide();
    end);
    ColorToggle:SetScript("OnClick", function(f)
        self:ToggleColorOption();
    end);

    local FactionSwitch = self.FactionSwitch;
    FactionSwitch:SetScript("OnEnter", function(f)
        f.Background:Show();
    end);
    FactionSwitch:SetScript("OnLeave", function(f)
        f.Background:Hide();
    end);
    FactionSwitch:SetScript("OnClick", function(f, button)
        if not f.id then
            f.id = 0;
        end
        if button == "LeftButton" then
            f.id = f.id + 1;
            if f.id > 2 then
                f.id = 0;
            end
        else
            f.id = f.id - 1;
            if f.id < 0 then
                f.id = 2;
            end
        end

        self:SetFaction(f.id);
    end);
end

function NarciStickerCharacterOptionMixin:SetParentObject(charButton)
    if charButton == self.parentObject then
        self:Hide();
        return
    end
    ActiveCharButton = charButton;
    self.parentObject = charButton;
    self:ClearAllPoints();
    self:SetPoint("TOPRIGHT", charButton, "TOPLEFT", -16, 0);
    
    --Update Text
    self.CharacterName:SetText(charButton.CharacterName:GetText() or "");
    self.Level:SetText(charButton.level);
    self.Class:SetText(charButton.className);
    self.Class:SetTextColor(charButton.Info:GetTextColor());
    self.Location:SetText(charButton.Location:GetText() or "");
    self.ColorToggle.ColorBlock:SetColorTexture(charButton.Info:GetTextColor());
    self:SetFaction(charButton.factionID);
    self:Show();
end

function NarciStickerCharacterOptionMixin:ToggleColorOption()
    if not self.ColorOption then
        local f = CreateFrame("Frame", nil, self.ColorToggle, "NarciAutoCloseFrameTemplate");
        local numButtons = #classFiles;
        local size = 16;
        local numPerRow = 4;
        local row, col = 1, 1;
        f:SetPoint("TOPLEFT", self.ColorToggle, "TOPRIGHT", 4, size);
        local button;
        local colorMixin;
        for i = 1, numButtons do
            button = CreateFrame("Button", nil, f, "NarciStickerColorButtonTemplate");
            col = i  % numPerRow;
            if col == 0 then
                col = numPerRow;
            end
            row = math.ceil(i / numPerRow);
            button:SetPoint("TOPLEFT", f, "TOPLEFT", size * (col - 1), -size * (row - 1));
            colorMixin = C_ClassColor.GetClassColor(classFiles[i]);
            if colorMixin then
                button:SetColor( colorMixin:GetRGB() );
            end
        end
        f:SetSize(size * numPerRow, size * row);
        self.ColorOption = f;
    end

    self.ColorOption:Toggle();
end

function NarciStickerCharacterOptionMixin:SetClassColor(r, g, b)
    if self.parentObject then
        self.parentObject:SetClassColor(r, g, b);
        self.ColorToggle.ColorBlock:SetColorTexture(r, g, b);
        self.Class:SetTextColor(r, g, b);
    end
end

function NarciStickerCharacterOptionMixin:SetFaction(factionID)
    if self.parentObject then
        if not factionID then
            factionID = self.parentObject.factionID;
            if not factionID then
                factionID = 0;
            end
            factionID = factionID + 1;
            if factionID > 1 then
                factionID = 0;
            end
        end
        self.parentObject:SetFactionEmblem(factionID);
        local icon;
        if factionID == 0 then
            icon = 136243;
        elseif factionID == 1 then
            icon = 2565244;
        elseif factionID == 2 then
            icon = 2565243;
        end
        self.FactionSwitch.Icon:SetTexture(icon);
        self.FactionSwitch.id = factionID;
    end
end

NarciStickerColorButtonMixin = {};

function NarciStickerColorButtonMixin:OnEnter()
    self.Background:SetColorTexture(0.50, 0.50, 0.50);
end

function NarciStickerColorButtonMixin:OnLeave()
    self.Background:SetColorTexture(0, 0, 0);
end

function NarciStickerColorButtonMixin:OnClick()
    local buttons = self:GetParent().ColorButtons;
    for k, b in pairs(buttons) do
        if b ~= self then
            b:EnableButton();
        else
            b:DisableButton();
        end
    end
    ClassColorOption:SetClassColor(self.r, self.g, self.b);
end

function NarciStickerColorButtonMixin:DisableButton()
    self:Disable();
    --self.Background:SetColorTexture(0.8, 0.8, 0.8);
    self.Selection:Show();
end

function NarciStickerColorButtonMixin:EnableButton()
    self:Enable();
    --self.Background:SetColorTexture(0, 0, 0);
    self.Selection:Hide();
end

function NarciStickerColorButtonMixin:SetColor(r, g, b)
    self.r, self.g, self.b = r, g, b;
    self.ColorBlock:SetColorTexture(r, g, b);
end




local DROPDOWN_PADDING = 4;

local function Init(self)
    --Create DropDown
    local BUTTON_HEIGHT = 20;

    self.DropDown = CreateFrame("Frame", nil, self);
    local d = self.DropDown;
    d:Hide();
    d:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0);

    NarciAPI.NineSliceUtil.SetUpBackdrop(d, "photoModePopup");

    local StickOptions = {
        {"Login Screen", 1},
        {"Character Select", 2},
    };

    local function OptionButton_OnEnter(f)
        FadeFrame(f.Highlight, 0.2, 1);
        self.rootFrame:OnEnter();
    end

    local function OptionButton_OnLeave(f)
        FadeFrame(f.Highlight, 0.2, 0);
        self.rootFrame:OnLeave();
    end

    local function OptionButton_OnClick(f)
        self:CloseDropDown();
        MainContainer:ShowOverlay(f.id);
        self:UpdateState();
    end

    local numButtons = #StickOptions;
    local button, divider;
    for i = 1, numButtons do
        button = CreateFrame("Button", nil, d);
        button:SetSize(120, BUTTON_HEIGHT);
        button:SetPoint("TOPLEFT", d, "TOPLEFT", DROPDOWN_PADDING, -DROPDOWN_PADDING + (1 - i) * BUTTON_HEIGHT);
        button.Label = button:CreateFontString(nil, "OVERLAY", "NarciPastelBrownFont");
        button.Label:SetPoint("LEFT", button, "LEFT", 8, 0);
        button.Label:SetText(StickOptions[i][1]);
        button.id = StickOptions[i][2];

        button.Highlight = button:CreateTexture(nil, "ARTWORK");
        button.Highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1);
        button.Highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1);
        button.Highlight:SetColorTexture(1, 1, 1, 0.2);
        button.Highlight:Hide();
        button.Highlight:SetAlpha(0);

        button:SetScript("OnEnter", OptionButton_OnEnter);
        button:SetScript("OnLeave", OptionButton_OnLeave);
        button:SetScript("OnClick", OptionButton_OnClick);

        if i ~= numButtons then
            divider = button:CreateTexture(nil, "OVERLAY");
            divider:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\ActorPanel\\DividerH");
            divider:SetHeight(4);
            divider:SetPoint("LEFT", button, "BOTTOMLEFT", 0, 0);
            divider:SetPoint("RIGHT", button, "BOTTOMRIGHT", 0, 0);
        end
    end

    d:SetSize(120 + 2*DROPDOWN_PADDING, BUTTON_HEIGHT * numButtons + 2*DROPDOWN_PADDING);
end

NarciPhotoModeStickerToggleMixin = {};

function NarciPhotoModeStickerToggleMixin:OnLoad()
    self.Icon:SetVertexColor(0.6, 0.6, 0.6);
    self.rootFrame = Narci_ModelSettings;
    Narci_ModelSettings:AddSubFrame(self, "StickerToggle");
    self:ClearAllPoints();
    self:SetPoint("LEFT", Narci_TextOverlay, "RIGHT", 4, 0);
    self.Label:SetText(Narci.L["Photo Mode Frame"]);
end

function NarciPhotoModeStickerToggleMixin:OnEnter()
    FadeFrame(self.Highlight, 0.12, 1);

    if not self.isOn then
        self.Arrow:Show();
        self.Arrow.flyInDown:Play();
    end
end

function NarciPhotoModeStickerToggleMixin:OnLeave()
    if not self.isOn then
        FadeFrame(self.Highlight, 0.25, 0);
    end
    self.Arrow:Hide();
end

function NarciPhotoModeStickerToggleMixin:OnClick(button)
    if Init then
        Init(self);
        Init = nil;
    end

    if button == "RightButton" then
        self:ShowDropDown();
    else
        if self.isOn then
            MainContainer:Hide();
        else
            if self.DropDown:IsShown() then
                self:CloseDropDown();
            else
                self:ShowDropDown();
            end
        end
    end

    self:UpdateState();
end

function NarciPhotoModeStickerToggleMixin:OnShow()
    self:UpdateState();
end

function NarciPhotoModeStickerToggleMixin:OnHide()
    self:CloseDropDown();
    MainContainer:Hide();
end

function NarciPhotoModeStickerToggleMixin:UpdateState()
    self.isOn = MainContainer:IsShown();
    if self.isOn then
        self.Highlight:Show();
        self.Highlight:SetAlpha(1);
        self.Label:SetTextColor(0.88, 0.88, 0.88);
        self.Icon:SetVertexColor(1, 1, 1);
    else
        if not self:IsMouseOver() then
            self.Highlight:Hide();
            self.Highlight:SetAlpha(0);
        end
        self.Label:SetTextColor(0.65, 0.65, 0.65);
        self.Icon:SetVertexColor(0.6, 0.6, 0.6);
    end
end

function NarciPhotoModeStickerToggleMixin:ShowDropDown()
    self.DropDown:Show();
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciPhotoModeStickerToggleMixin:CloseDropDown()
    if self.DropDown then
        self.DropDown:Hide();
    end
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciPhotoModeStickerToggleMixin:OnEvent(event)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not self:IsFocused() then
            self:CloseDropDown();
        end
    end
end

function NarciPhotoModeStickerToggleMixin:IsFocused()
    return self:IsShown() and self:IsMouseOver() or ( self.DropDown and self.DropDown:IsShown() and self.DropDown:IsMouseOver(-DROPDOWN_PADDING, DROPDOWN_PADDING, DROPDOWN_PADDING, -DROPDOWN_PADDING) )
end


NarciPseudoRedButtonMixin = {};

function NarciPseudoRedButtonMixin:SetButtonAtlas(atlasName, atlasNamePostfix)
    atlasName = atlasName or "128-RedButton";
    atlasNamePostfix = atlasNamePostfix or "";    --Disabled, Pressed

    self.Left:SetAtlas(atlasName.."-Left"..atlasNamePostfix, true);
	self.Center:SetAtlas("_"..atlasName.."-Center"..atlasNamePostfix);
	self.Right:SetAtlas(atlasName.."-Right"..atlasNamePostfix, true);
end

function NarciPseudoRedButtonMixin:OnLoad()
    self:SetButtonAtlas(self.atlasName, self.atlasNamePostfix);
    self:UpdateScale();

    if self.fontName then
        self:SetFont(self.fontName);
        self.fontName = nil;
    end

    if self.buttonText then
        self:SetText(self.buttonText);
        self.buttonText = nil;
    end
end

function NarciPseudoRedButtonMixin:SetFont(fontName)
    self.ButtonText:SetFontObject(fontName);
end

function NarciPseudoRedButtonMixin:SetText(text)
    self.ButtonText:SetText(text);
end

function NarciPseudoRedButtonMixin:UpdateScale()
    --This is basically a copy of Blizzard code from SharedUIPanelTemplates.lua

    local atlasName = self.atlasName or "128-RedButton";

    local leftAtlasInfo = C_Texture.GetAtlasInfo(atlasName.."-Left");
    local rightAtlasInfo = C_Texture.GetAtlasInfo(atlasName.."-Right");

    if not (leftAtlasInfo and rightAtlasInfo) then
        return
    end

	local buttonHeight = self:GetHeight();
	local buttonWidth = self:GetWidth();

	local scale = buttonHeight / leftAtlasInfo.height;
	self.Left:SetScale(scale);
	self.Right:SetScale(scale);

	local leftWidth = leftAtlasInfo.width * scale;
	local rightWidth = rightAtlasInfo.width * scale;
	local leftAndRightWidth = leftWidth + rightWidth;

	if leftAndRightWidth > buttonWidth then
		local extraWidth = leftAndRightWidth - buttonWidth;
		local newLeftWidth = leftWidth;
		local newRightWidth = rightWidth;
		if (leftWidth - extraWidth) > rightWidth then
			newLeftWidth = leftWidth - extraWidth;
		elseif (rightWidth - extraWidth) > leftWidth then
			newRightWidth = rightWidth - extraWidth;
		else
			if leftWidth ~= rightWidth then
				local unevenAmount = math.abs(leftWidth - rightWidth);
				extraWidth = extraWidth - unevenAmount;
				newLeftWidth = math.min(leftWidth, rightWidth);
				newRightWidth = newLeftWidth;
			end
			local equallyDividedExtraWidth = extraWidth / 2;
			newLeftWidth = newLeftWidth - equallyDividedExtraWidth;
			newRightWidth = newRightWidth - equallyDividedExtraWidth;
		end
		local leftPercentage = newLeftWidth / leftWidth;
		self.Left:SetTexCoord(0, leftPercentage, 0, 1);
		self.Left:SetWidth(newLeftWidth / scale);
		local rightPercentage = newRightWidth / rightWidth;
		self.Right:SetTexCoord(1 - rightPercentage, 1, 0, 1);
		self.Right:SetWidth(newRightWidth / scale);
	else
		self.Left:SetTexCoord(0, 1, 0, 1);
		self.Left:SetWidth(leftAtlasInfo.width);
		self.Right:SetTexCoord(0, 1, 0, 1);
		self.Right:SetWidth(rightAtlasInfo.width);
	end

    leftAtlasInfo, rightAtlasInfo = nil, nil;
end