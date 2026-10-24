local _, addon = ...
local StatSheetAPI = addon.StatSheetAPI; ---@class StatSheetAPI

local Def = {
    IconSize = 16,
    IconTextGap = 4,
};

local DamageClassXTextureIndex = { -- Match ResistanceIcons.tga
    Arcane = 1,
    Fire = 2,
    Frost = 3,
    Nature = 4,
    Shadow = 5,
};

local function ExpectedSpellResistance(casterLevel, resistance)
	return 0.75 * resistance / (casterLevel * 5);
end


local EntryButtonMixin = {};

function EntryButtonMixin:OnEnter()
    if not self.resistanceIndex then return; end

    -- For some reason Blizzard use the third return 
    local _, _, effectiveResistance, bonusResistance = UnitResistance("player", self.resistanceIndex);
    local unitLevel = UnitLevel("player");
    if canaccessallvalues(effectiveResistance, unitLevel) then
        local title = _G["RESISTANCE"..self.resistanceIndex.."_NAME"];
        if not title then return; end

		local tooltip = NarciGameTooltip;
		tooltip:ClearAllPoints();
		tooltip:SetOwner(self, "ANCHOR_NONE");
		tooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4);

        tooltip:SetText(StatSheetAPI.FormatSimpleStat(title, effectiveResistance), 1, 1, 1);

        local typeName = _G["RESISTANCE_TYPE"..self.resistanceIndex];
        if typeName then
            local expectedResist = ExpectedSpellResistance(unitLevel, effectiveResistance);
            tooltip:AddNormalLine(string.format(RESISTANCE_TOOLTIP_SUBTEXT, typeName, unitLevel, math.floor(expectedResist * 100)));
        end

        tooltip:Show();
    end
end

function EntryButtonMixin:OnLeave()
    Narci:HideButtonTooltip();
end

function EntryButtonMixin:UpdateVisual()
    if canaccessvalue(self.effectiveValue) and self.effectiveValue and self.effectiveValue <= 0 then
        self.Value:SetTextColor(0.5, 0.5, 0.5);
        self.Icon:SetVertexColor(0.6, 0.6, 0.6);
    else
        self.Value:SetTextColor(0.92, 0.92, 0.92);
        self.Icon:SetVertexColor(1, 1, 1);
    end
end

function EntryButtonMixin:Refresh()
    if not self.resistanceIndex then return; end
    local _, _, effectiveResistance, bonusResistance = UnitResistance("player", self.resistanceIndex);
    self.Value:SetText(string.format("%.0f", effectiveResistance));
    self.effectiveValue = effectiveResistance;
    self:UpdateVisual();
end

---@param damageClass string Enum.Damageclass
function EntryButtonMixin:SetDamageClass(damageClass)
    self.resistanceIndex = Enum.Damageclass[damageClass];
    local i = DamageClassXTextureIndex[damageClass];
    if i then
        self.Icon:SetTexCoord((i - 1) * 36/256, i * 36/256, 0, 36/64);
    else
        self.Icon:SetTexCoord(0.98, 1, 0.98, 1); -- to the dark nowhere
    end
end


local ResistanceButtonContainer;

function StatSheetAPI.CreateResistanceDisplay(parent)
    local f = ResistanceButtonContainer;

    if not f then
        f = CreateFrame("Frame", nil, parent);
        ResistanceButtonContainer = f;

        local resistances = {"Arcane", "Fire", "Frost", "Nature", "Shadow"};
        local fromOffsetX = 10;
        local buttonWidth = (parent:GetWidth() - fromOffsetX) / #resistances;
        local buttonHeight = 24;
        local buttons = {};
        f.buttons = buttons;

        for i, damageClass in ipairs(resistances) do
            local button = CreateFrame("Frame", nil, f);
            buttons[i] = button;
            button:SetSize(buttonWidth, buttonHeight);
            button.Icon = button:CreateTexture(nil, "ARTWORK");
            button.Icon:SetSize(Def.IconSize, Def.IconSize);
            button.Icon:SetPoint("LEFT", button, "LEFT", 0, 0);
            button.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/CharacterFrame/ResistanceIcons.tga");
            button.Value = button:CreateFontString(nil, "OVERLAY", "NarciFontStatusNumber");
            button.Value:SetPoint("LEFT", button.Icon, "RIGHT", Def.IconTextGap, 0);
            Mixin(button, EntryButtonMixin);
            button:SetScript("OnEnter", button.OnEnter);
            button:SetScript("OnLeave", button.OnLeave);
            button:SetDamageClass(damageClass);
            button:SetPoint("LEFT", f, "LEFT", (i - 1) * buttonWidth + fromOffsetX, 0);
        end
    end

    f:ClearAllPoints();
    f:SetParent(parent);
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);
    f:Show();
end

function StatSheetAPI.RefreshResistanceDisplay()
    if ResistanceButtonContainer and ResistanceButtonContainer.buttons then
        for _, button in ipairs(ResistanceButtonContainer.buttons) do
            button:Refresh();
        end
    end
end

function StatSheetAPI.ReleaseResistanceDisplay()
    if ResistanceButtonContainer then
        ResistanceButtonContainer:Hide();
    end
end
