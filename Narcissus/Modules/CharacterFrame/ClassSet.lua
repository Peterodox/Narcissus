local THEME_KEY = "ClassSetTheme_DF_1";     --Former: ClassTheme,
local TEXTURE_PATH = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\Progenitor\\";

local GetInventoryItemID = GetInventoryItemID;
local GetSpellDescription = GetSpellDescription;
local FadeFrame = NarciFadeUI.Fade;
local strtrim = strtrim;

local PIXEL = NarciAPI.GetScreenPixelSize();

local PDWC = NarciPaperDollWidgetController;

local PaperDollIndicator, SplashFrame;

local isClassItem = {};

do
    local classSetItems = {
        --https://wow.tools/dbc/?dbc=itemset&build=10.0.2.46801#page=1
        200405, 200407, 200408, 200409, 200410,     --DK
        200342, 200344, 200345, 200346, 200347,     --DH
        200351, 200353, 200354, 200355, 200356,     --Druid
        200387, 200389, 200390, 200391, 200392,     --Hunter
        200378, 200380, 200381, 200382, 200383,     --Evoker
        200315, 200317, 200318, 200319, 200320,     --Mage
        200360, 200362, 200363, 200364, 200365,     --Monk
        200414, 200416, 200417, 200418, 200419,     --Paladin
        200326, 200327, 200328, 200324, 200329,     --Priest
        200369, 200371, 200372, 200373, 200374,     --Rogue
        200396, 200398, 200399, 200400, 200401,     --Shaman
        200335, 200336, 200337, 200333, 200338,     --Warlock
        200423, 200425, 200426, 200427, 200428,     --Warrior
    };

    for _, itemID in pairs(classSetItems) do
        isClassItem[itemID] = true;
    end
end

local candidateSlots = {
    [1] = true,   --Head
    [3] = true,   --Shoulder
    [5] = true,   --Chest
    [7] = true,   --Legs
    [10] = true,  --Hands
};

local clssSetSpells = {
    --[classID] = { [specIndex] = {spell1, spell2} },

    [1] = {    --Warrior
        {393705, 393706},   --Arms 71
        {393708, 393709},   --Fury 72
        {393710, 393711},   --Protection 73
    },

    [2] = {    --Paladin
        {393670, 393672},   --Holy 65
        {393673, 393674},   --Protection 66
        {393675, 393677},   --Retribution 70
    },

    [3] = {    --Hunter
        {393646, 393647},   --BM 253
        {393648, 393649},   --Marksmanship 254
        {393650, 393652},   --Survival 255
    },

    [4] = {    --Rogue
        {393724, 393725},   --Ass 259
        {393727, 393728},   --Outlaw 260
        {393729, 393730},   --Sub 261
    },

    [5] = {    --Priest
        {393679, 393681},   --Discipline 256
        {393682, 393683},   --Holy 257
        {393684, 393685},   --Shadow 258
    },

    [6] = {    --DK
        {393621, 393622},   --Blood 250
        {393623, 393624},   --Frost 251
        {393626, 393627},   --Unholy 252
    },

    [7] = {    --Shaman
        {393688, 393690},   --Elemental 262
        {393691, 393693},   --Enhancement 263
        {393695, 393697},   --Restoration 264
    },

    [8] = {    --Mage
        {393653, 393654},   --Arcane 62
        {393655, 393656},   --Fire 63
        {393657, 393658},   --Frost 64
    },

    [9] = {    --Warlock
        {393698, 393699},   --Affliction 265
        {393701, 393702},   --Demonology 266
        {393703, 393704},   --Destruction 267
    },

    [10] = {    --Monk
        {393659, 393660},   --Brewmaster 268
        {393661, 393663},   --Mistweaver 270
        {393666, 393668},   --Windwalker 269
    },

    [11] = {    --Druid
        {393632, 393633},   --Balance 102
        {393635, 393636},   --Feral 103
        {393637, 393638},   --Guardian 104
        {393639, 393641},   --Restoration 105
    },

    [12] = {    --DH
        {393628, 393629},   --Havoc 577
        {393630, 393631},   --Vengeance 581
    },

    [13] = {    --Evoker
        {393642, 393643},   --Devastation 1467
        {393644, 393645},   --Preservation 1468
    },
};


local function IsItemClassSet(itemID)
    return (itemID and isClassItem[itemID])
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
            if IsItemClassSet(itemID) then
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

NarciAPI.IsItemClassSet = IsItemClassSet;
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


NarciClassSetTooltipMixin = {};

function NarciClassSetTooltipMixin:OnShow()
    if self.Init then
        self:Init();
    end
    self:DisplayBonus();
    self:ListenKey(true);
end

function NarciClassSetTooltipMixin:ListenKey(state)
    if state then
        self:SetScript("OnKeyDown", OnTabPressed);
    else
        self:SetScript("OnKeyDown", nil);
    end
end

function NarciClassSetTooltipMixin:OnEvent(event, ...)
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

function NarciClassSetTooltipMixin:Init()
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
    NarciClassSetTooltipMixin.Init = nil;
end

function NarciClassSetTooltipMixin:DisplayBonus(specIndex)
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

function NarciClassSetTooltipMixin:UpdateSize()
    self:SetHeight((self.Effect1:GetHeight() or 12) + (self.Effect2:GetHeight() or 12) + self.fixedHeight);
end

function NarciClassSetTooltipMixin:CycleSpec(delta)
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

function NarciClassSetTooltipMixin:UpdatePixel(scale)
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

function NarciClassSetTooltipMixin:FadeIn(isNarcissusUI)
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

function NarciClassSetTooltipMixin:FadeOut()
    self:ListenKey(false);
    FadeFrame(self, 0.2, 0);
end

function NarciClassSetTooltipMixin:OnHide()
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

NarciClassSetIndicatorMixin = {};

function NarciClassSetIndicatorMixin:OnLoad()
    PaperDollIndicator = self;

    self.numOwned = 0;
    PDWC:AddWidget(self, 2);
end

function NarciClassSetIndicatorMixin:ResetAnchor()
    self:ClearAllPoints();
    self:SetParent(self.parent);
    self:SetPoint("CENTER", self.parent, "CENTER", 0, 0);
end

function NarciClassSetIndicatorMixin:OnShow()
    if not NarcissusDB[THEME_KEY] then
        self.Splash:ShowSplash();
        self:SetTheme(2, true);
    else
        self:SetTheme(NarcissusDB[THEME_KEY]);
    end
    self:SetScript("OnShow", nil);
end

function NarciClassSetIndicatorMixin:OnEnter()
    self.t = -0.2;
    self:SetScript("OnUpdate", DelayedTooltip_OnUpdate);
    self.Highlight:Show();
    self.Highlight.Shine:Play();
end

function NarciClassSetIndicatorMixin:OnLeave()
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    local f = NarciClassSetTooltip;
    f:Hide();
    PDWC:ClearHighlights();
end

function NarciClassSetIndicatorMixin:ShowTooltip()
    local f = NarciClassSetTooltip;
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

function NarciClassSetIndicatorMixin:OnMouseDown(button)
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

function NarciClassSetIndicatorMixin:SetCount(numOwned)
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

function NarciClassSetIndicatorMixin:OnHide()
    if self.t then
        self:SetScript("OnUpdate", nil);
        self.t = nil;
    end
end

function NarciClassSetIndicatorMixin:Update()
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
    texture:SetTexture(TEXTURE_PATH..name, nil, nil, "LINEAR");
    return themeID
end

function NarciClassSetIndicatorMixin:SetTheme(themeID, save)
    self.themeID = SetTextureByThemeID(self.Background, themeID);
    if save then
        NarcissusDB[THEME_KEY] = self.themeID;
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
        if not NarcissusDB[THEME_KEY] then
            NarcissusDB[THEME_KEY] = 1;
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
            if not NarcissusDB[THEME_KEY] then
                NarcissusDB[THEME_KEY] = 1;
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
        NarcissusDB[THEME_KEY] = f.id;
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
        mask:SetTexture(TEXTURE_PATH.."PaperDollBaseMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
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