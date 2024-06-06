local _, addon = ...

local GetItemSpell = C_Item.GetItemSpell;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local GetSpellBaseCooldown = GetSpellBaseCooldown;


local SpellSetupFuncs = {};

local function Setup_RubyWhelpShell(tooltip)
    --Show whelp training progress
    local info, value;
    local anyPadding = false;

    for i = 2148, 2153 do
        info = C_CurrencyInfo.GetCurrencyInfo(i);
        if info then
            value = info.quantity;
            if value and value > 0 then
                if anyPadding then
                    tooltip:AddDoubleLine(info.name, value, 1, 0.82, 0);
                else
                    anyPadding = true;
                    tooltip:AddDoubleLine(info.name, value, 1, 0.82, 0, -12);
                end
            end
        end
    end
end
SpellSetupFuncs[389843] = Setup_RubyWhelpShell;


local function Setup_FindItemAura(spellIDs, tooltip, spellFrame)
    local GetInfo = C_UnitAuras.GetPlayerAuraBySpellID;
    local auraInfo, auraInstanceID;

    for _, id in ipairs(spellIDs) do
        auraInfo = GetInfo(id);
        if auraInfo then
            spellFrame.Icon:SetTexture(auraInfo.icon);
            auraInstanceID = auraInfo.auraInstanceID;
            tooltip:AddLine(auraInfo.name, 1, 1, 1, -12);
            break
        end
    end

    if auraInstanceID then
        local info = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", auraInstanceID);
        if info and info.lines and info.lines[2] and info.lines[2].leftText then
            tooltip:AddLine(info.lines[2].leftText, 1, 0.82, 0);
        end
    end
end

local function Setup_PrimalRitualShell(tooltip, spellFrame)
    local spellIDs = {390835, 390655, 390899, 390869};    --Fire (Damage), Stone (Aborb), Wind (Mastery), Sea (Heal)
    Setup_FindItemAura(spellIDs, tooltip, spellFrame);
end

SpellSetupFuncs[390643] = Setup_PrimalRitualShell;


local function Setup_OminousChromaticEssence(tooltip, spellFrame)
    local spellIDs = {402221, 401516, 401518, 401519, 401521};    --Fire (Damage), Stone (Aborb), Wind (Mastery), Sea (Heal)
    Setup_FindItemAura(spellIDs, tooltip, spellFrame);
end

SpellSetupFuncs[401515] = Setup_OminousChromaticEssence;


NarciEquipmentSpellFrameMixin = {};

function NarciEquipmentSpellFrameMixin:SetFrameWidth(width)
    self:SetWidth(width);
    self.SpellEffect:SetWidth(width);
    self.SpellName:SetWidth(width - 34);
end


function NarciEquipmentSpellFrameMixin:SetSpellEffect(link, effectText, isActive, cooldownText)
    local spellName, spellID = GetItemSpell(link);

    self.spellID = spellID;
    self:SetSpellInactive(not isActive and ITEM_LEGACY_INACTIVE_EFFECTS);

    if spellID then
        if not spellName then
            self:GetParent():QueryData();
            return
        end
        local _, _, icon, _, minRange, maxRange = GetSpellInfo(spellID);
        local cd = GetSpellBaseCooldown(spellID);
        self.Icon:SetTexture(icon);
        self.SpellName:SetText(spellName);
        if cd and cd > 0 then
            self.SpellCooldown:SetText( SecondsToTime(cd / 1000) );
            self.CooldownIcon:Show();
        elseif cooldownText then
            self.SpellCooldown:SetText(cooldownText);
            self.CooldownIcon:Show();
        else
            self.SpellCooldown:SetText(nil);
            self.CooldownIcon:Hide();
        end
        if maxRange and maxRange > 0 then
            maxRange = (maxRange <= 5 and MELEE_RANGE) or string.format(SPELL_RANGE, maxRange);
        else
            maxRange = " ";
        end
        self.SpellRange:SetText(maxRange);
        self.SpellEffect:SetText(effectText);
    elseif effectText then
        --it seems impossible to obatin the spellID from item if that one is a legacy item
        self.spellID = 0;
        self.SpellName:SetText(self:GetParent().itemName);
        self.Icon:SetTexture(self:GetParent().itemIcon);
        self.SpellRange:SetText(" ");
        self.SpellEffect:SetText(effectText);
        if cooldownText then
            self.SpellCooldown:SetText(cooldownText);
            self.CooldownIcon:Show();
        else
            self.SpellCooldown:SetText(nil);
            self.CooldownIcon:Hide();
        end
    else
        self:Hide();
        return
    end

    local frameHeight = self:GetTop() - (self.SpellEffect:GetBottom() or 0) + (self.bottomPadding or 0);
    local frameWidth = math.max(34 + self.SpellName:GetWrappedWidth(), self.SpellEffect:GetWrappedWidth());

    local tooltip = self:GetParent();

    tooltip:EvaluateMaxWidth(frameWidth);
    self:SetHeight(frameHeight);
    self:Show();
    tooltip:InsertFrame(self);

    if spellID and SpellSetupFuncs[spellID] then
        SpellSetupFuncs[spellID](tooltip, self);
    end
end

function NarciEquipmentSpellFrameMixin:Clear()
    if self.spellID then
        self:Hide();
        self.Icon:SetTexture(nil);
        self.SpellName:SetText(nil);
        self.SpellCooldown:SetText(nil);
        self.SpellRange:SetText(nil);
        self.SpellEffect:SetText(nil);
        self.spellID = nil;
    end
end

function NarciEquipmentSpellFrameMixin:SetCooldownTextColor(r, g, b)
    self.CooldownIcon:SetVertexColor(r, g, b);
    self.SpellCooldown:SetTextColor(r, g, b);
    self.SpellName:SetTextColor(r, g, b);
end

function NarciEquipmentSpellFrameMixin:SetSpellInactive(requirementText)
    if requirementText then
        if self.isActive then
            self.isActive = nil;
            self.Icon:ClearAllPoints();
            self.Icon:SetPoint("LEFT", self, "LEFT", 1, 0);
            self.Icon:SetPoint("TOP", self.InactiveAlert, "BOTTOM", 0, -5);
            self.SpellName:ClearAllPoints();
            self.SpellName:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", 31, -1);
            self:SetCooldownTextColor(0.5, 0.5, 0.5);
            self.SpellEffect:SetTextColor(0.5, 0.5, 0.5);
            self.Icon:SetDesaturation(1);
            self.InactiveAlert:Show();
            self.RedBackground:Show();
            self.bottomPadding = 6;
        end
        self.InactiveAlert:SetText(requirementText);
    else
        if not self.isActive then
            self.isActive = true;
            self.Icon:ClearAllPoints();
            self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1);
            self.SpellName:ClearAllPoints();
            self.SpellName:SetPoint("TOPLEFT", self, "TOPLEFT", 32, 0);
            self:SetCooldownTextColor(0.8863, 0.8863, 0.8863);
            self.SpellEffect:SetTextColor(1, 0.82, 0);
            self.Icon:SetDesaturation(0);
            self.InactiveAlert:Hide();
            self.RedBackground:Hide();
            self.bottomPadding = 0;
        end
        self.InactiveAlert:SetText(nil);
    end
end