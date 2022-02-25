local FadeFrame = NarciFadeUI.Fade;

local activeCharButton, ClassColorOption;

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
};

local classFiles = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER",
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
        local numExpansions = 8;
        local height = 16;
        local width;
        local maxWidth = 0;
        for i = 0, numExpansions, 1 do
            button = CreateFrame("Button", nil, option, "NarciExpansionSelectionButtonTemplate");
            button:SetPoint("TOPLEFT", option, "TOPLEFT", 0, -height * i);
            width = button:Init(i) + 16;
            if width > maxWidth then
                maxWidth = width;
            end
        end
        for k, b in pairs(option.ExpansionButtons) do
            b:SetWidth(maxWidth);
        end
        option:SetHeight(height *(numExpansions + 1));
        option:SetWidth(maxWidth);
    end
    option:Toggle();
end

local function SetExpansionLogo(expansionLevel)
    local f = NarciPhotoModeStickerContainer.CharacterSelectUI.LogoFrame;
    if expansionLogo[expansionLevel] then
        local prefix;
        if expansionLevel == 1 then
            prefix = "Interface\\AddOns\\Narcissus\\ART\\Stickers\\Glues-WoW-%sLogo";
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


function NarciStickerContainer_Init(self)
    self:SetScript("OnShow", nil);

    local f = self.CharacterSelectUI;

    local expansionLevel = GetExpansionLevel();
    if not expansionLogo[expansionLevel] then
        expansionLevel = 8;
    end
    SetExpansionLogo(expansionLevel);

    --Player name
    local unit = "player";
    local name = UnitName(unit);

    f.CharacterName:SetText(name);

    --Character List
    local cf = f.SelectCharacterFrame;
    local realmName = GetRealmName();
    cf.RealmName:SetText(realmName);

    --Character Buttons
    local button;
    if not cf.CharacterButtons then
        button = CreateFrame("Button", nil, cf, "NarciGlueCharSelectCharacterButtonTemplate");
        button:SetPoint("TOP", cf, "TOP", 0, -60);
    end
    local buttons = cf.CharacterButtons;
    button = buttons[1];
    activeCharButton = button;
    button:SetUnit("player");
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
    activeCharButton = charButton;
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
        f:SetPoint("TOPLEFT", self.ColorToggle, "TOPRIGHT", 4, 0);
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




----Temp----
function NarciSitcker_UpdateCharacterName(self, isUserInput)
    if isUserInput then
        if activeCharButton then
            activeCharButton:SetName(self:GetText());
        end
    end
end


NarciPhotoModeStickerToggleMixin = {};

function NarciPhotoModeStickerToggleMixin:OnLoad()
    self.object = NarciPhotoModeStickerContainer;
    self.Icon:SetVertexColor(0.6, 0.6, 0.6);
end

function NarciPhotoModeStickerToggleMixin:OnEnter()
    FadeFrame(self.Highlight, 0.12, 1);
end

function NarciPhotoModeStickerToggleMixin:OnLeave()
    if not self.isOn then
        FadeFrame(self.Highlight, 0.25, 0);
    end
end

function NarciPhotoModeStickerToggleMixin:OnClick()
    self.object:SetShown(not self.object:IsShown());
    self:UpdateState();
end

function NarciPhotoModeStickerToggleMixin:OnShow()
    self:UpdateState();
end

function NarciPhotoModeStickerToggleMixin:OnHide()
    self.object:Hide();
end

function NarciPhotoModeStickerToggleMixin:UpdateState()
    self.isOn = self.object:IsShown();
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