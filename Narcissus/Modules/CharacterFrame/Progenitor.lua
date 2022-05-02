local GetInventoryItemID = GetInventoryItemID;
local GetSpellDescription = GetSpellDescription;
local FadeFrame = NarciFadeUI.Fade;
local strtrim = strtrim;

local PIXEL = NarciAPI.GetScreenPixelSize();

local PDWC = NarciPaperDollWidgetController;

local PaperDollIndicator, SplashFrame;

local isProgenitorItem = {};

do
    local classSetItems = {
        188868, 188867, 188866, 188864, 188863,     --DK        188870, 188873, 188865, 188869,
        188892, 188894, 188896, 188893, 188898,     --DH        188900, 188897, 188899, 188895,
        188847, 188853, 188851, 188848, 188849,     --Druid     188854, 188871, 188852, 188850,
        188859, 188861, 188860, 188856, 188858,     --Hunter    188872, 188857, 188862, 188855,
        188844, 188845, 188839, 188842, 188843,     --Mage      188838, 188840, 188846, 188841,
        188916, 188911, 188910, 188914, 188912,     --Monk      188915, 188917, 188918, 188913,
        188933, 188931, 188932, 188929, 188928,     --Paladin   188935, 188930, 188936, 188934,
        188880, 188879, 188881, 188875, 188878,     --Priest    188882, 188877, 188876, 188874,
        188901, 188902, 188903, 188905, 188907,     --Rogue     188909, 188908, 188906, 188904,
        188923, 188925, 188924, 188920, 188922,     --Shaman    188927, 188926, 188921, 188919,
        188889, 188890, 188884, 188888, 188887,     --Warlock   188883, 188885, 188886, 188891,
        188942, 188941, 188940, 188938, 188937,     --Warrior   188939, 188945, 188944, 188943,

        --187378, 186475, 185905, 186739, 186738, 172254     --Test
    };

    for _, itemID in pairs(classSetItems) do
        isProgenitorItem[itemID] = true;
    end
end

local candidateSlots = {
    [1] = "Head",
    [3] = "Shoulder",
    [5] = "Chest",
    [7] = "Legs",
    [10] = "Hands",
};

local clssSetSpells = {
    --[classID] = { [specIndex] = {spell1, spell2} },

    [1] = {    --Warrior
        {364553, 363913},   --Arms
        {364554, 363738},   --Fury
        {364002, 364639},   --Protection
    },

    [2] = {    --Paladin
        {364468, 363674},   --Holy
        {364304, 363675},   --Protection
        {363677, 364370},   --Retribution
    },

    [3] = {    --Hunter
        {364492, 363665},   --BM
        {364491, 363666},   --Marksmanship
        {364490, 363667},   --Survival
    },

    [4] = {    --Rogue
        {364667, 363591},   --Ass
        {364555, 363592},   --Outlaw
        {364557, 363949},   --Sub
    },

    [5] = {    --Priest
        {364428, 363494},   --Discipline
        {364427, 363492},   --Holy
        {364424, 363469},   --Shadow
    },

    [6] = {    --DK
        {364399, 363590},   --Blood
        {364383, 363411},   --Frost
        {364392, 363560},   --Unholy
    },

    [7] = {    --Shaman
        {364472, 363671},   --Elemental
        {364473, 363668},   --Enhancement
        {364470, 363672},   --Restoration
    },

    [8] = {    --Mage
        {364539, 363682},   --Arcane
        {364476, 363500},   --Fire
        {363535, 364544},   --Frost
    },

    [9] = {    --Warlock
        {364437, 363953},   --Affliction
        {364436, 363951},   --Demonology
        {364433, 363950},   --Destruction
    },

    [10] = {    --Monk
        {364415, 366792},   --Brewmaster
        {364417, 363733},   --Mistweaver
        {364418, 363734},   --Windwalker
    },

    [11] = {    --Druid
        {364423, 363497},   --Balance
        {364416, 363498},   --Feral
        {364362, 363496},   --Guardian
        {364365, 363495},   --Restoration
    },

    [12] = {    --DH
        {364438, 363736},   --Havoc
        {364454, 363737},   --Vengeance
    },
};


local function IsItemProgenitorSet(itemID)
    return (itemID and isProgenitorItem[itemID])
end

local NUM_OWNED = 0;
local OWNED_SLOTS;

local function GetEquippedSet(recount)
    if recount then
        local itemID;
        local numValid = 0;
        OWNED_SLOTS = {};
        for slotID in pairs(candidateSlots) do
            itemID = GetInventoryItemID("player", slotID);
            if IsItemProgenitorSet(itemID) then
                numValid = numValid + 1;
                OWNED_SLOTS[numValid] = slotID;
                if numValid >= 5 then
                    break
                end
            end
        end
        NUM_OWNED = numValid;
    end
    return NUM_OWNED, OWNED_SLOTS
end

NarciAPI.IsItemProgenitorSet = IsItemProgenitorSet;
NarciAPI.GetNumClassSetItems = GetEquippedSet;



local TOOLTIP_PADDING = 32;

local function FormatText(text)
    if text then
        return strtrim(text)
    end
end

local function SetBonusText(fontString, text, isActive)
    fontString:SetText(text);
    if isActive then
        fontString:SetTextColor(0.855, 0.843, 0.69);
    else
        fontString:SetTextColor(0.5, 0.5, 0.5);
    end
end

local function SetCountIcon(icon, required, owned)
    local left, top;
    if required == 2 then
        top = 0;
        if owned == 1 then
            left = 0;
        else
            left = 0.5;
        end
    elseif required == 4 then
        if owned == 1 then
            left = 0;
            top = 0.5;
        elseif owned == 2 then
            left = 0.5;
            top = 0.5;
        elseif owned == 3 then
            left = 0;
            top = 0.75;
        else
            left = 0.5;
            top = 0.75;
        end
    end
    icon:SetTexCoord(left, left + 0.5, top, top + 0.25);
end

local function OnTabPressed(self, key)
    if key == "TAB" then
        self:SetPropagateKeyboardInput(false);
        if IsShiftKeyDown() then
            self:CycleSpec(-1);
        else
            self:CycleSpec(1);
        end
    else
        self:SetPropagateKeyboardInput(true);
    end
end


NarciProgenitorTooltipMixin = {};

function NarciProgenitorTooltipMixin:OnShow()
    if self.Init then
        self:Init();
    end
    self:DisplayBonus();
    self:ListenKey(true);
end

function NarciProgenitorTooltipMixin:ListenKey(state)
    if state then
        self:SetScript("OnKeyDown", OnTabPressed);
    else
        self:SetScript("OnKeyDown", nil);
    end
end

function NarciProgenitorTooltipMixin:OnEvent(event, ...)
    if event == "SPELL_DATA_LOAD_RESULT" then
        local spellID, success = ...
        if spellID == self.spell1 then
            self.spell1 = nil;
            self:DisplayBonus(self.specIndex);
        elseif spellID == self.spell2 then
            self.spell2 = nil;
            self:DisplayBonus(self.specIndex);
        end
        if not (self.spell1 or self.spell2) then
            self:UnregisterEvent(event);
        end
    end
end

function NarciProgenitorTooltipMixin:Init()
    local _, _, classID = UnitClass("player");
    self.specSpells = clssSetSpells[classID];
    local numSpecs = #self.specSpells   --GetNumSpecializations();

    local padding = TOOLTIP_PADDING;
    local width = math.floor(self:GetWidth() + 0.5);
    local markSize = 16;
    local textOffsetX = markSize + 8 + padding;
    local textWidth = width - textOffsetX - padding;
    self.Count1:SetSize(markSize, markSize);
    self.Count2:SetSize(markSize, markSize);
    self.Effect1:ClearAllPoints();
    self.Effect1:SetPoint("TOPLEFT", self, "TOPLEFT", textOffsetX, -padding);
    self.Effect1:SetWidth(textWidth);
    self.Effect2:ClearAllPoints();
    self.Effect2:SetPoint("TOPLEFT", self.Effect1, "BOTTOMLEFT", 0, -0.5 * padding);
    self.Effect2:SetWidth(textWidth);
    self.Divider:ClearAllPoints();
    self.Divider:SetPoint("RIGHT", self.Effect2, "BOTTOMRIGHT", 0, -0.55 * padding);
    self.Divider:SetWidth(width - 2 * padding);

    --Create Spec Icons
    local iconSize = 24;
    local gap = iconSize * 1;
    self.SpecIcons = {};
    self.numSpecs = numSpecs;
    local offsetX = (width - numSpecs * iconSize - gap * (numSpecs - 1)  - (iconSize + gap)) * 0.5;
    local _, icon;
    for i = 1, numSpecs do
        self.SpecIcons[i] = self:CreateTexture(nil, "OVERLAY");
        self.SpecIcons[i]:SetSize(iconSize, iconSize);
        self.SpecIcons[i]:SetPoint("CENTER", self.Divider, "LEFT", offsetX + (i - 1) * (iconSize + gap), -1.35 * iconSize);
        _, _, _, icon = GetSpecializationInfo(i);
        self.SpecIcons[i]:SetTexture(icon or 134400);
        self.SpecIcons[i]:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    end

    self.CycleNote:ClearAllPoints();
    self.CycleNote:SetPoint("TOP", self.Divider, "CENTER", 0, -2*iconSize - 0.5 * padding + 2);
    self.CycleNote:SetWidth(textWidth);
    self.CycleNote:SetText(Narci.L["Cycle Spec"]);

    self.fixedHeight = (2 + 0.5 + 0.75 + 0.5) * padding + 2 * iconSize + 2;

    NarciAPI.NineSliceUtil.SetUpBorder(self, "shadowLargeR0");

    self.Init = nil;
    NarciProgenitorTooltipMixin.Init = nil;
end

function NarciProgenitorTooltipMixin:DisplayBonus(specIndex)
    local numOwned = GetEquippedSet();     --debug

    --Spec
    specIndex = specIndex or GetSpecialization();
    self.specIndex = specIndex;
    self.Selection:Hide();
    self.Selection:ClearAllPoints();

    for i = 1, #self.SpecIcons do
        if i == specIndex then
            self.SpecIcons[i]:SetSize(24, 24);
            self.SpecIcons[i]:SetVertexColor(1, 1, 1);
            self.SpecIcons[i]:SetDesaturation(0);
            self.Selection:SetPoint("CENTER", self.SpecIcons[i], "CENTER", 0, 0);
            self.Selection:Show();
        else
            self.SpecIcons[i]:SetSize(20, 20);
            self.SpecIcons[i]:SetVertexColor(0.6, 0.6, 0.6);
            self.SpecIcons[i]:SetDesaturation(0.2);
        end
    end

    --Set Bonus
    local spell1, spell2, text1, text2;
    if self.specSpells[specIndex] then
        spell1, spell2 =  unpack(self.specSpells[specIndex]);
        text1 = FormatText(GetSpellDescription(spell1));
        text2 = FormatText(GetSpellDescription(spell2));
    else
        text1 = "Bonus #1";
        text2 = "Bonus #2";
    end

    local fullyLoaded;
    if text1 and text1 ~= "" then
        fullyLoaded = true;
        self.spell1 = nil;
    else
        self.spell1 = spell1;
        C_Spell.RequestLoadSpellData(spell1);
    end
    if text2 and text2 ~= "" then
        fullyLoaded = fullyLoaded and true;
        self.spell2 = nil;
    else
        self.spell2 = spell2;
        C_Spell.RequestLoadSpellData(spell2);
    end
    if fullyLoaded then
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    else
        self:RegisterEvent("SPELL_DATA_LOAD_RESULT");
        return
    end

    SetBonusText(self.Effect1, text1, numOwned >= 2);
    SetBonusText(self.Effect2, text2, numOwned >= 4);
    SetCountIcon(self.Count1, 2, numOwned);
    SetCountIcon(self.Count2, 4, numOwned);

    self:UpdateSize();
end

function NarciProgenitorTooltipMixin:UpdateSize()
    self:SetHeight((self.Effect1:GetHeight() or 12) + (self.Effect2:GetHeight() or 12) + self.fixedHeight);
end

function NarciProgenitorTooltipMixin:CycleSpec(delta)
    if delta > 0 then
        self.specIndex = self.specIndex + 1;
        if self.specIndex > self.numSpecs then
            self.specIndex = 1;
        end
    else
        self.specIndex = self.specIndex - 1;
        if self.specIndex < 1 then
            self.specIndex = self.numSpecs;
        end
    end
    self:DisplayBonus(self.specIndex);
end

function NarciProgenitorTooltipMixin:UpdatePixel(scale)
    local px = PIXEL / scale;
    self.Divider:SetHeight(16 * px);
    local a = 64 * px;
    self.Decor1:SetSize(a, a);
    self.Decor3:SetSize(a, a);
    self.Decor7:SetSize(a, a);
    self.Decor9:SetSize(a, a);

    self.Selection:SetSize(24 + 8*px, 24 + 8*px);
    self.Exclusion:SetSize(24 + 4*px, 24 + 4*px);
end

function NarciProgenitorTooltipMixin:FadeIn(isNarcissusUI)
    if isNarcissusUI then
        self.Background:SetAlpha(1);
    else
        self.Background:SetAlpha(0.95);
    end
    local scale = self:GetParent():GetEffectiveScale();
    if scale < 0.7 then
        scale = 0.7;
    end
    if scale ~= self.scale then
        self.scale = scale;
        self:SetScale(scale);
        self:UpdatePixel(scale);
    end
    self:OnShow();
    FadeFrame(self, 0.2, 1);
end

function NarciProgenitorTooltipMixin:FadeOut()
    self:ListenKey(false);
    FadeFrame(self, 0.2, 0);
end

function NarciProgenitorTooltipMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
end



local function DelayedTooltip_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self:SetScript("OnUpdate", nil);
        self:ShowTooltip();
        self.t = nil;
    end
end

NarciProgenitorSetIndicatorMixin = {};

function NarciProgenitorSetIndicatorMixin:OnLoad()
    PaperDollIndicator = self;

    self.numOwned = 0;
    PDWC:AddWidget(self, 2);
end

function NarciProgenitorSetIndicatorMixin:ResetAnchor()
    self:ClearAllPoints();
    self:SetParent(self.parent);
    self:SetPoint("CENTER", self.parent, "CENTER", 0, 0);
end

function NarciProgenitorSetIndicatorMixin:OnShow()
    if not NarcissusDB.ProgenitorTheme then
        self.Splash:ShowSplash();
    else
        self:SetTheme(NarcissusDB.ProgenitorTheme);
    end
    self:SetScript("OnShow", nil);
end

function NarciProgenitorSetIndicatorMixin:OnEnter()
    self.t = -0.2;
    self:SetScript("OnUpdate", DelayedTooltip_OnUpdate);
    self.Highlight:Show();
    self.Highlight.Shine:Play();
end

function NarciProgenitorSetIndicatorMixin:OnLeave()
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    local f = NarciProgenitorTooltip;
    f:Hide();
    PDWC:ClearHighlights();
end

function NarciProgenitorSetIndicatorMixin:ShowTooltip()
    local f = NarciProgenitorTooltip;
    f:ClearAllPoints();
    f:SetParent(self);
    f:SetFrameStrata("HIGH");
    f:SetFrameLevel(self:GetFrameLevel() - 1);
    if self.Splash:IsShown() then
        f:SetPoint("TOPLEFT", self.Splash, "BOTTOMLEFT", 0, -8);
    else
        f:SetPoint("TOPLEFT", self, "CENTER", 0, 0);
    end
    f:FadeIn();
    PDWC:HighlightSlots(OWNED_SLOTS);
end

function NarciProgenitorSetIndicatorMixin:OnMouseDown(button)
    --Debug
    --[[
    if button == "RightButton" then
        if not self.themeID then
            self.themeID = 1;
        end
        self.themeID = self.themeID + 1;
        if self.themeID > 3 then
            self.themeID = 1;
        end
        self:SetTheme(self.themeID);
    elseif button == "MiddleButton" then
        SplashFrame:ShowStep((SplashFrame.step == 1 and 2) or 1);
    else
        self.numOwned = self.numOwned + 1;
        if self.numOwned > 5 then
            self.numOwned = 1;
        end
        self:SetCount(self.numOwned);
    end
    --]]
    self.themeID = self.themeID + 1;
    if self.themeID > 3 then
        self.themeID = 1;
    end
    self:SetTheme(self.themeID, true);
end

function NarciProgenitorSetIndicatorMixin:SetCount(numOwned)
    numOwned = numOwned or 0;
    if numOwned > 0 then
        self:Show(0);
    else
        self:Hide();
        return false
    end
    local left;
    if numOwned == 1 then
        left = 0;
    elseif numOwned == 2 then
        left = 0.25;
    elseif numOwned == 3 then
        left = 0.5;
    else
        left = 0.75;
    end
    self.Background:SetTexCoord(left, left + 0.25, 0, 1);
    self.Redundancy:SetShown(numOwned > 4);
    self.numOwned = numOwned;
    return true
end

function NarciProgenitorSetIndicatorMixin:OnHide()
    if self.t then
        self:SetScript("OnUpdate", nil);
        self.t = nil;
    end
end

function NarciProgenitorSetIndicatorMixin:Update()
    local numOwned = GetEquippedSet(true);
    return self:SetCount(numOwned);
end

local function SetTextureByThemeID(texture, themeID)
    local name;
    if themeID == 1 then
        name = "PaperDollBase-Cool";
    elseif themeID == 2 then
        name ="PaperDollBase";
    else
        themeID = 3;
        name = "PaperDollBase-Warm"
    end
    texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\Progenitor\\"..name, nil, nil, "LINEAR");
    return themeID
end

function NarciProgenitorSetIndicatorMixin:SetTheme(themeID, save)
    self.themeID = SetTextureByThemeID(self.Background, themeID);
    if save then
        NarcissusDB.ProgenitorTheme = self.themeID;
    end
end



--Splash--
local function Resizing_OnUpdate(self, elapsed)
    local diff = self.toHeight - self.height;
    local delta = elapsed * 12 * diff;
    if diff >= 0 and (diff < 1 or (self.height + delta >= self.toHeight)) then
        self.height = self.toHeight;
        self:SetScript("OnUpdate", nil);
    elseif diff <= 0 and (diff > -1 or (self.height + delta <= self.toHeight)) then
        self.height = self.toHeight;
        self:SetScript("OnUpdate", nil);
    else
        self.height = self.height + delta;
    end
    self:SetHeight(self.height);
end

NarciClassSetIndicatorSplash = {};

function NarciClassSetIndicatorSplash:OnLoad()
    SplashFrame = self;
end

function NarciClassSetIndicatorSplash:Init()
    local function CountDown_OnCooldownDone(f)
        self:FadeOut();
        if not NarcissusDB.ProgenitorTheme then
            NarcissusDB.ProgenitorTheme = 1;
        end
    end

    local function ChooseButton_OnEnter(f)
        f.Texture:SetVertexColor(1, 1, 1);
        if f.CountDown then
            local duration = f.CountDown:GetCooldownDuration();
            if not duration or duration == 0 then
                SplashFrame:StartCountDown(true, 6);
            end
            f.CountDown:Pause();
        else
            self:StartCountDown(false);
        end
    end

    local function ChooseButton_OnLeave(f)
        f.Texture:SetVertexColor(0.6, 0.6, 0.6);
        if f.CountDown then
            f.CountDown:Resume();
        else
            self:StartCountDown(true, 6);
        end
    end

    local function ChooseButton_OnClick(f)
        if f.CountDown then
            PDWC:SetEnabled(true);
            if not NarcissusDB.ProgenitorTheme then
                NarcissusDB.ProgenitorTheme = 1;
            end
            self:ShowStep(2);
        else
            PDWC:SetEnabled(false);
        end
    end

    self.Step1.YesButton.CountDown:SetScript("OnCooldownDone", CountDown_OnCooldownDone);
    self.Step1.YesButton:SetScript("OnEnter", ChooseButton_OnEnter);
    self.Step1.NoButton:SetScript("OnEnter", ChooseButton_OnEnter);
    self.Step1.YesButton:SetScript("OnLeave", ChooseButton_OnLeave);
    self.Step1.NoButton:SetScript("OnLeave", ChooseButton_OnLeave);
    self.Step1.YesButton:SetScript("OnClick", ChooseButton_OnClick);
    self.Step1.NoButton:SetScript("OnClick", ChooseButton_OnClick);
    self.Step1.Header:SetText(Narci.L["Paperdoll Splash 1"]);
    self.Step2.Header:SetText(Narci.L["Paperdoll Splash 2"]);

    --Create Theme Options--
    local function Theme_OnEnter(f)
        PaperDollIndicator:SetTheme(f.id);
        local name;
        if f.id == 1 then
            name = "Silver";
        elseif f.id == 2 then
            name = "Gold";
        elseif f.id == 3 then
            name = "Scrambled Eggs with Tomatoes";
        end
        self.Step2.ThemeName:SetText(name);
        f.Texture:SetVertexColor(1, 1, 1);
    end

    local function Theme_OnClick(f)
        PaperDollIndicator:SetTheme(f.id, true);
        NarcissusDB.ProgenitorTheme = f.id;
        self:ShowStep(3);
    end

    local function Theme_OnLeave(f)
        f.Texture:SetVertexColor(0.6, 0.6, 0.6);
    end

    local button, tex, mask;
    local size = 48;
    local gap = 12;
    local iconScale = PaperDollFrame:GetEffectiveScale();
    for i = 1, 3 do
        button = CreateFrame("Button", nil, self.Step2);
        button:SetSize(48, 48);
        button:SetPoint("CENTER", self.Step2, "CENTER", (i - 2) * (size + gap), 0);
        button:SetIgnoreParentScale(true);
        button:SetScale(iconScale);
        button.id = i;
        button:SetScript("OnEnter", Theme_OnEnter);
        button:SetScript("OnLeave", Theme_OnLeave);
        button:SetScript("OnClick", Theme_OnClick);
        tex = button:CreateTexture(nil, "OVERLAY");
        button.Texture = tex;
        tex:SetAllPoints(true);
        tex:SetTexCoord(0.75, 1, 0, 1);
        tex:SetVertexColor(0.6, 0.6, 0.6);
        SetTextureByThemeID(tex, i);
        mask = button:CreateMaskTexture(nil, "OVERLAY");
        mask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\Progenitor\\PaperDollBaseMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
        mask:SetAllPoints(true);
        tex:AddMaskTexture(mask);
    end

    self.Init = nil;
end

function NarciClassSetIndicatorSplash:ShowSplash()
    if self.Init then
        self:Init();
    end
    self:Show();
    self:SetFrameStrata("LOW");
end

function NarciClassSetIndicatorSplash:StartCountDown(state, duration)
    if state then
        self.Step1.YesButton.CountDown:SetCooldown(GetTime(), duration or 10);
    else
        self.Step1.YesButton.CountDown:Clear();
    end
end

function NarciClassSetIndicatorSplash:ShowStep(step)
    self.Step1:SetShown(step == 1);
    self.Step2:SetShown(step == 2);
    self.height = self:GetHeight();
    if step == 1 then
        self.toHeight = 64;
        FadeFrame(self.Step1, 0.2, 1, 0);
    elseif step == 2 then
        self.toHeight = 120;
        FadeFrame(self.Step2, 0.2, 1, 0);
    elseif step == 3 then
        self:FadeOut();
        self.Shrink:Play();
    end
    self:SetScript("OnUpdate", Resizing_OnUpdate);
    self.step = step;
end

function NarciClassSetIndicatorSplash:OnShow()
    local scale = self:GetParent():GetEffectiveScale();
    if scale < 0.7 then
        self:SetScale(0.7 / scale);
    end
    self:StartCountDown(true, 10);
end

function NarciClassSetIndicatorSplash:FadeOut()
    FadeFrame(self, 0.5, 0);
end