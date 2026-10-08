local _, addon = ...

local DIGITS = "%.2f";

local Narci = Narci;
local L = Narci.L;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local GetPrimaryStats = NarciAPI.GetPrimaryStats;
local SplitTooltipByLineBreak = NarciAPI.SplitTooltipByLineBreak;
local TransitionAPI = addon.TransitionAPI;

local format = string.format;
local floor = math.floor;
local ceil = math.ceil;
local max = math.max;
local min = math.min;

local DefaultTooltip = NarciGameTooltip;	--Created in NarciAPI.lua

local C_PaperDollInfo = C_PaperDollInfo;
local UnitStat = UnitStat;
local GetCombatRating = GetCombatRating;
local GetCombatRatingBonus = GetCombatRatingBonus;
local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7;
local GetSpecialization = C_SpecializationInfo.GetSpecialization;
local GetUnitSpeed = GetUnitSpeed;
local canaccessvalue = canaccessvalue;


local NARCI_CRIT_TOOLTIP, NARCI_CRIT_TOOLTIP_FORMAT = SplitTooltipByLineBreak(CR_CRIT_TOOLTIP);
local _, NARCI_HASTE_TOOLTIP_FORMAT = SplitTooltipByLineBreak(STAT_HASTE_BASE_TOOLTIP);
local NARCI_VERSATILITY_TOOLTIP_FORMAT_1, NARCI_VERSATILITY_TOOLTIP_FORMAT_2 = SplitTooltipByLineBreak(CR_VERSATILITY_TOOLTIP);
local N_SLASH_A = NOT_APPLICABLE;


local function FormatPercent(value)
	return format("%.2f%%", value);
end

local function GetPrimaryStatsValue()
	local _, strength = UnitStat("player", 1);
	local _, agility = UnitStat("player", 2);
	local _, intellect = UnitStat("player", 4);
	if strength > agility and strength > intellect then
		return strength;
	elseif	agility > strength and agility > intellect then
		return agility;
	elseif	intellect > agility and	intellect >	strength then
		return intellect;
	end
end

local function GetEffectiveCrit()
	local rating;
	local spellCrit, rangedCrit, meleeCrit;
	local critChance;

	-- Start at 2 to skip physical damage
	local holySchool = 2;
	local minCrit = GetSpellCritChance(holySchool);
	local spellCritTable = {};
	spellCritTable[holySchool] = minCrit;

	for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
		spellCrit = GetSpellCritChance(i);
		if not (canaccessvalue(minCrit) and canaccessvalue(spellCrit)) then
			return minCrit, CR_CRIT_MELEE;
		end
		minCrit = min(minCrit, spellCrit);
		spellCritTable[i] = spellCrit;
	end

	spellCrit = minCrit;
	rangedCrit = GetRangedCritChance();
	meleeCrit = GetCritChance();

	if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
		critChance = spellCrit;
		rating = CR_CRIT_SPELL;
	elseif rangedCrit >= meleeCrit then
		critChance = rangedCrit;
		rating = CR_CRIT_RANGED;
	else
		critChance = meleeCrit;
		rating = CR_CRIT_MELEE;
	end

	return critChance, rating
end

Narci.GetEffectiveCrit = GetEffectiveCrit;

local function ClearTooltipIfSecret(self, statName, value1)
	if not canaccessvalue(value1) then
		self.tooltip = statName;
		self.tooltip2 = nil;
		return true;
	end
end

------------------------------------------------------------------
----The following codes are derivated from PapaerDollFrame.lua----
------------------------------------------------------------------
---@class StatUpdateFunc
local UpdateFunc = {};
addon.StatUpdateFunc = UpdateFunc;

function UpdateFunc:Primary()
	local unit = "player";
	local primaryStatsName, primaryStatsValue = GetPrimaryStats();
	self:SetLabelAndValue(primaryStatsName, primaryStatsValue);

	local spec = GetSpecialization();
	if not spec then return; end

	local role = GetSpecializationRole(spec);
	local _, _, _, _, _, primaryStat = C_SpecializationInfo.GetSpecializationInfo(spec);
	if type(tonumber(primaryStat)) ~= "number" then return; end		--sometimes changing zones cause Lua error

	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, primaryStat);

	if ClearTooltipIfSecret(self, primaryStatsName, posBuff) then
		return;
	end

	local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);

	-- Set the tooltip text
	local statName = _G["SPELL_STAT"..primaryStat.."_NAME"];
	local tooltipText = "|cffffffff".. statName .." ";

	if posBuff == 0 and negBuff == 0 then
		self.tooltip = tooltipText..effectiveStatDisplay.."|r";
	else
		tooltipText = tooltipText..effectiveStatDisplay;
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff).."|r";
		end
		if posBuff > 0 then
			tooltipText = tooltipText.."|r"..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff).."|r";
		end
		if negBuff < 0 then
			tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff).."|r";
		end
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.."|cffffffff"..")".."|r";
		end
		self.tooltip = tooltipText;

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if negBuff < 0 and not GetPVPGearStatRules() then
			effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay.."|r";
		end
	end

	self.tooltip2 = _G["DEFAULT_STAT"..primaryStat.."_TOOLTIP"];

	if primaryStat == LE_UNIT_STAT_AGILITY then
		local attackPower = GetAttackPowerForStat(primaryStat, effectiveStat);
		local tooltip = STAT_TOOLTIP_BONUS_AP;
		if HasAPEffectsSpellPower() then
			tooltip = STAT_TOOLTIP_BONUS_AP_SP;
		end
		if (not primaryStat or primaryStat == LE_UNIT_STAT_AGILITY) then
			self.tooltip2 = format(tooltip, BreakUpLargeNumbers(attackPower));
			if role == "TANK" then
				local increasedDodgeChance = GetDodgeChanceFromAttribute();
				if increasedDodgeChance > 0 then
					self.tooltip2 = self.tooltip2.."|n|n"..format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance);
				end
			end
		else
			self.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end

	elseif primaryStat == LE_UNIT_STAT_STRENGTH then
		local attackPower = GetAttackPowerForStat(primaryStat,effectiveStat);
		if HasAPEffectsSpellPower() then
			self.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP;
		end
		if (not primaryStat or primaryStat == LE_UNIT_STAT_STRENGTH) then
			self.tooltip2 = format(self.tooltip2, BreakUpLargeNumbers(attackPower));
			if role == "TANK" then
				local increasedParryChance = GetParryChanceFromAttribute();
				if increasedParryChance > 0 then
					self.tooltip2 = self.tooltip2.."|n|n"..format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance);
				end
			end
		else
			self.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end

	elseif primaryStat == LE_UNIT_STAT_INTELLECT then
		if TransitionAPI.UnitHasMana("player") then
			if HasAPEffectsSpellPower() then
				self.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
			else
				local result, druid = HasSPEffectsAttackPower();
				if result and druid then
					self.tooltip2 = format(STAT_TOOLTIP_SP_AP_DRUID, max(0, effectiveStat), max(0, effectiveStat));
				elseif result then
					self.tooltip2 = format(STAT_TOOLTIP_BONUS_AP_SP, max(0, effectiveStat));
				elseif (not primaryStat or primaryStat == LE_UNIT_STAT_INTELLECT) then
					self.tooltip2 = format(self.tooltip2, max(0, effectiveStat));
				else
					self.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
				end
			end
		else
			self.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end
	end
end

function UpdateFunc:Stamina()
	local statIndex = LE_UNIT_STAT_STAMINA;
	local stat, effectiveStat, posBuff, negBuff = UnitStat("player", statIndex);

	local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
	local tooltipText = "|cffffffff".. statName .." ";

	self:SetLabelAndValue(statName, effectiveStat);

	if ClearTooltipIfSecret(self, statName, posBuff) then
		return;
	end

	if posBuff == 0 and negBuff == 0 then
		self.tooltip = tooltipText..effectiveStatDisplay.."|r";
	else
		tooltipText = tooltipText..effectiveStatDisplay;
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff).."|r";
		end
		if posBuff > 0 then
			tooltipText = tooltipText.."|r"..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff).."|r";
		end
		if negBuff < 0 then
			tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff).."|r";
		end
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.."|cffffffff"..")".."|r";
		end
		self.tooltip = tooltipText;

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if negBuff < 0 and not GetPVPGearStatRules() then
			effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay.."|r";
		end
	end

	local staminaBonusText = TransitionAPI.Secret_Multiply(effectiveStat, UnitHPPerStamina("player"), GetUnitMaxHealthModifier("player"));
	if staminaBonusText then
		local textFormat = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
		self.tooltip2 = format(textFormat, BreakUpLargeNumbers(staminaBonusText));
	else
		self.tooltip2 = nil;
	end
end

local function GetAppropriateDamage(unit)
	if IsRangedWeapon() then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	else
		return UnitDamage(unit);
	end
end

local function CharacterDamageFrame_OnEnter(self)
	-- Main hand weapon
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	if self.unit == "pet" then
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND_PET, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	else
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2F", self.attackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.damage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	-- Check for offhand weapon
	if self.offhandAttackSpeed then
		DefaultTooltip:AddLine("\n");
		DefaultTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2F", self.offhandAttackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.offhandDamage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	end

	DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0);
	DefaultTooltip:Show();
end

function UpdateFunc:Damage()
	local unit = "player";

	local speed, offhandSpeed = UnitAttackSpeed(unit);
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage(unit);

	if ClearTooltipIfSecret(self, DAMAGE, minDamage) then
		self:SetLabelAndValue(DAMAGE, format("%.0f", minDamage));
		self:SetScript("OnEnter", nil);
		return;
	end

	-- remove decimal points for display values
	local displayMin = max(floor(minDamage),1);
	local displayMinLarge = displayMin	--BreakUpLargeNumbers(displayMin);
	local displayMax = max(ceil(maxDamage),1);
	local displayMaxLarge = displayMax	--BreakUpLargeNumbers(displayMax);

	-- calculate base damage
	if percent == 0 then return; end;
	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	-- set tooltip text with base damage
	local damageTooltip = BreakUpLargeNumbers(max(floor(minDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxDamage),1));

	local colorPos = "|cffffffff";
	local colorNeg = "|cffffffff";

	-- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
	end

	local value;
	if totalBonus == 0  then
		if displayMin < 100 and displayMax < 100 then
			value = displayMinLarge.." - "..displayMaxLarge;
		else
			value = displayMinLarge.." - "..displayMaxLarge;
		end
	else
		-- set bonus color and display
		local color;
		if totalBonus > 0  then
			color = colorPos;
		else
			color = colorNeg;
		end
		if displayMin < 100 and displayMax < 100 then
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		else
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		end
		if physicalBonusPos > 0 then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if physicalBonusNeg < 0 then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if percent > 1 then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent * 100 + 0.5).."%|r";
		elseif percent < 1 then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent * 100 + 0.5).."%|r";
		end

	end

	self:SetLabelAndValue(DAMAGE, value);
	self.damage = damageTooltip;
	self.attackSpeed = speed;
	self.unit = unit;

	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and minOffHandDamage and maxOffHandDamage ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		--local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent; -- We don't have space to show offhand damage :(
		local offhandDamageTooltip = BreakUpLargeNumbers(max(floor(minOffHandDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxOffHandDamage),1));
		if physicalBonusPos > 0 then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if physicalBonusNeg < 0 then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if percent > 1 then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent * 100 + 0.5).."%|r";
		elseif percent < 1 then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent * 100 + 0.5).."%|r";
		end
		self.offhandDamage = offhandDamageTooltip;
		self.offhandAttackSpeed = offhandSpeed;
	else
		self.offhandAttackSpeed = nil;
	end

	self:SetScript("OnEnter", CharacterDamageFrame_OnEnter);
end

function UpdateFunc:AttackSpeed()
	local meleeHaste = GetMeleeHaste();
	local speed, offhandSpeed = UnitAttackSpeed("player");

	if ClearTooltipIfSecret(self, ATTACK_SPEED, speed) then
		self:SetLabelAndValue(ATTACK_SPEED, format("%.2f", speed));
		return;
	end

	local displaySpeed = floor(100 * speed + 0.5) / 100;
	if offhandSpeed then
		offhandSpeed = floor(100 * offhandSpeed + 0.5) / 100;
	end
	if offhandSpeed then
		if displaySpeed ~= offhandSpeed then
			displaySpeed =  displaySpeed.." / ".. offhandSpeed;
		else
			displaySpeed =  displaySpeed;
		end
	else
		displaySpeed =  displaySpeed;
	end

	self:SetLabelAndValue(ATTACK_SPEED, displaySpeed);
	self.tooltip = "|cffffffff".. ATTACK_SPEED .." "..displaySpeed.."|r";
	self.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, format(DIGITS, meleeHaste));
end

local function ArmorOrReduction_OnEnter(self)
	local _, effectiveArmor = UnitArmor("player");
	local armorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(effectiveArmor);
	if canaccessvalue(armorReductionAgainstTarget) and armorReductionAgainstTarget then
		self.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, 100 * armorReductionAgainstTarget);
	else
		self.tooltip3 = nil;
	end
	self:ShowTooltip();
end

function UpdateFunc:Armor()
	local unit = "player";

	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);
	self:SetLabelAndValue(STAT_ARMOR, effectiveArmor);

	if ClearTooltipIfSecret(self, STAT_ARMOR, effectiveArmor) then
		return;
	end

    local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit));

	self.tooltip = "|cffffffff".. ARMOR .." "..BreakUpLargeNumbers(effectiveArmor).."|r";
	self.tooltip2 = format(STAT_ARMOR_TOOLTIP, 100 * armorReduction);

	self:SetScript("OnEnter", ArmorOrReduction_OnEnter);
end

function UpdateFunc:Reduction()
	local unit = "player"
	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);

	if ClearTooltipIfSecret(self, COMBAT_TEXT_SHOW_RESISTANCES_TEXT, effectiveArmor) then
		self:SetLabelAndValue(L["Damage Reduction Percentage"], N_SLASH_A, true);
		return;
	end

	local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit)) or 0;
	armorReduction = 100 * armorReduction;

	local armorReductionText = FormatPercent(armorReduction);
	self:SetLabelAndValue(L["Damage Reduction Percentage"], armorReductionText);

	self.tooltip = "|cffffffff"..COMBAT_TEXT_SHOW_RESISTANCES_TEXT.." "..armorReductionText.."|r";
	self.tooltip2 = format(STAT_ARMOR_TOOLTIP, armorReduction);

	self:SetScript("OnEnter", ArmorOrReduction_OnEnter);
end

function UpdateFunc:Dodge()
	local chance = GetDodgeChance();
	local chanceText = format("%.2F", chance).."%"
	self:SetLabelAndValue(STAT_DODGE, chanceText);
	self.tooltip = "|cffffffff".. DODGE_CHANCE .." "..format("%.2F", chance).."%".."|r";
	self.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
end

function UpdateFunc:Parry()
	local chance = GetParryChance();
	local chanceText = format("%.2F", chance).."%"
	self:SetLabelAndValue(STAT_PARRY, chanceText);
	self.tooltip = "|cffffffff".. PARRY_CHANCE .." "..format("%.2F", chance).."%".."|r";
	self.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
end

function UpdateFunc:Block()
	local unit = "player";

	local chance = GetBlockChance();
	local chanceText = format("%.2F", chance).."%";

	if ClearTooltipIfSecret(self, STAT_BLOCK, chance) then
		self:SetLabelAndValue(STAT_BLOCK, chanceText);
		return;
	end

	local spec = GetSpecialization();
	if not spec then return; end

	--local role = GetSpecializationRole(spec);
	if chance ~= 0 and C_PaperDollInfo.OffhandHasShield() then		--role == "TANK"
		self:SetLabelAndValue(STAT_BLOCK, chanceText);
	else
		self:SetLabelAndValue(STAT_BLOCK, N_SLASH_A, true);
	end

	self.tooltip = "|cffffffff".. BLOCK_CHANCE .." "..format("%.2F", chance).."%".."|r";

	local shieldBlockArmor = GetShieldBlock();
	local blockArmorReduction = C_PaperDollInfo.GetArmorEffectiveness(shieldBlockArmor, UnitEffectiveLevel(unit));
	local blockArmorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(shieldBlockArmor);

	self.tooltip2 = format(CR_BLOCK_TOOLTIP, blockArmorReduction * 100);
	if (blockArmorReductionAgainstTarget) then
		self.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget * 100);
	else
		self.tooltip3 = nil;
	end
end

function UpdateFunc:Health()
	local unit = "player";
	local health = UnitHealthMax(unit);
	local healthText = BreakUpLargeNumbers(health);
	self:SetLabelAndValue(HEALTH, healthText);
	self.tooltip = "|cffffffff".. HEALTH .." "..healthText.."|r";
	if (unit == "player") then
		self.tooltip2 = STAT_HEALTH_TOOLTIP;
	elseif (unit == "pet") then
		self.tooltip2 = STAT_HEALTH_PET_TOOLTIP;
	end
end

function UpdateFunc:Power()
	local unit = "player";
	local powerType, powerToken = UnitPowerType(unit);
	local power = UnitPowerMax(unit);
	local powerText = BreakUpLargeNumbers(power);
	local powerName = _G[powerToken];
	if powerToken and powerName then
		self:SetLabelAndValue(powerName, powerText);
		self.tooltip = "|cffffffff".. powerName .." "..powerText.."|r";
		self.tooltip2 = _G["STAT_"..powerToken.."_TOOLTIP"];
	else
		self:SetLabelAndValue(L["Combat Resources"], N_SLASH_A, true);
	end
end

function UpdateFunc:Regen()
	local powerType, powerToken = UnitPowerType("player");
	local regenRate = GetPowerRegen();
	local regenRateText = BreakUpLargeNumbers(regenRate);
	local regenRatePerSec = format("%.2f", regenRate).."/s";
	local labelText;
	if powerToken == "ENERGY" then
		labelText = STAT_ENERGY_REGEN;
		self.tooltip2 = STAT_ENERGY_REGEN_TOOLTIP;
	elseif powerToken == "RUNES" then
		labelText = STAT_RUNE_REGEN;
		self.tooltip2 = STAT_RUNE_REGEN_TOOLTIP;
	elseif powerToken == "FOCUS" then
		labelText = STAT_FOCUS_REGEN;
		self.tooltip2 = STAT_FOCUS_REGEN_TOOLTIP;
	elseif powerToken == "MANA" then
		labelText = MANA_REGEN;
		regenRate = GetManaRegen();
	else
		local _, class = UnitClass("player");
		if (class ~= "DEATHKNIGHT") then
			self:SetLabelAndValue(MANA_REGEN_COMBAT, N_SLASH_A, true);		--MANA_REGEN_ABBR
			return;
		end
		local _;
		_, regenRate = GetRuneCooldown(1);
		regenRateText = (format(STAT_RUNE_REGEN_FORMAT, regenRate));
		self:SetLabelAndValue(STAT_RUNE_REGEN, regenRateText);
		return;
	end

	if labelText and canaccessvalue(regenRatePerSec) then
		self.tooltip = "|cffffffff".. labelText .." "..regenRatePerSec.."|r";
	else
		self.tooltip = nil;
	end

	self:SetLabelAndValue(labelText, regenRatePerSec);
end

function UpdateFunc:Crit()
	local critChance, rating = GetEffectiveCrit();
	local extraCritChance = GetCombatRatingBonus(rating);
	local extraCritRating = GetCombatRating(rating);

	self:SetLabelAndValue(NARCI_CRITICAL_STRIKE, FormatPercent(critChance)); --COMBAT_RATING_NAME10
	self:SetValueRating(extraCritRating);

	if ClearTooltipIfSecret(self, STAT_CRITICAL_STRIKE, critChance) then
		return;
	end

	self.tooltip = "|cffffffff".. STAT_CRITICAL_STRIKE .." "..FormatPercent(critChance).."|r";

	self.tooltip4 = nil;
	if GetCritChanceProvidesParryEffect() then
		self.tooltip2 = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
	else
		if extraCritChance == 0 then
			self.tooltip2 = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance);
		else
			self.tooltip2 = NARCI_CRIT_TOOLTIP;
			self.tooltip4 = {format(NARCI_CRIT_TOOLTIP_FORMAT, BreakUpLargeNumbers(extraCritRating), extraCritChance), floor( (extraCritRating / extraCritChance) * 100 + 0.5) / 100 .. " [+1%]"}
		end
	end
end

function UpdateFunc:Haste()
	local unit = "player";
	local haste = GetHaste();
	local rating = CR_HASTE_MELEE;
	local hasteFormatString;

	self:SetLabelAndValue(STAT_HASTE, FormatPercent(haste));
	self:SetValueRating(GetCombatRating(rating));

	if ClearTooltipIfSecret(self, STAT_HASTE, haste) then
		return;
	end

	if (haste < 0 and not GetPVPGearStatRules()) then
		hasteFormatString = RED_FONT_COLOR_CODE.."%s".."|r";
	else
		hasteFormatString = "%s";
	end

	self.tooltip = "|cffffffff" .. STAT_HASTE .. " " .. format(hasteFormatString, FormatPercent(haste)) .. "|r";

	local _, class = UnitClass(unit);
	self.tooltip2 = _G["STAT_HASTE_"..class.."_TOOLTIP"];
	if (not self.tooltip2) then
		self.tooltip2 = STAT_HASTE_TOOLTIP;
	end

	local Rating = GetCombatRating(rating);
	local RatingBonus = GetCombatRatingBonus(rating);
	if RatingBonus == 0 then
		self.tooltip2 = self.tooltip2 .. format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(Rating), RatingBonus);
		self.tooltip4 = nil;
	else
		self.tooltip4 = {format(NARCI_HASTE_TOOLTIP_FORMAT, BreakUpLargeNumbers(Rating), RatingBonus), floor( (Rating / RatingBonus) * 100 + 0.5) / 100 .. " [+1%]"};
	end
end

local function MasteryFrame_OnEnter(self)
	local mastery, bonusCoeff = GetMasteryEffect();
	if not canaccessvalue(mastery) then
		DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
		DefaultTooltip:SetText(STAT_MASTERY);
		DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0)
		DefaultTooltip:Show();
		return;
	end

    local RadarChart = self:GetParent();
    if RadarChart.SetVerticeSize then
        RadarChart.SetVerticeSize(RadarChart, self, 15);
    end

	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");

	local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;

	local title = "|cffffffff"..STAT_MASTERY.." "..FormatPercent(mastery).."|r";
	if (masteryBonus > 0) then
		title = title.."|cffffffff".." ("..format("%.2F%%", mastery-masteryBonus).."|r"..GREEN_FONT_COLOR_CODE.."+"..FormatPercent(masteryBonus).."|r".."|cffffffff"..")".."|r";
	end
	DefaultTooltip:SetText(title);

	local masteryRating = GetCombatRating(CR_MASTERY);
	local primaryTalentTree = GetSpecialization();
	if primaryTalentTree then	--dragonflight
		local masterySpell, masterySpell2;
		local spells = C_SpecializationInfo.GetSpecializationMasterySpells(primaryTalentTree);
		if spells then
			masterySpell, masterySpell2 = spells[1], spells[2];
		end
		if DefaultTooltip.AddSpellByID then
			if masterySpell then
				DefaultTooltip:AddSpellByID(masterySpell);
			end
			if masterySpell2 then
				DefaultTooltip:AddLine(" ");
				DefaultTooltip:AddSpellByID(masterySpell2);
			end
		else
			if masterySpell then
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell);
				tooltipInfo.append = true;
				DefaultTooltip:ProcessInfo(tooltipInfo);
			end
			if masterySpell2 then
				DefaultTooltip:AddLine(" ");
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell2);
				tooltipInfo.append = true;
				DefaultTooltip:ProcessInfo(tooltipInfo);
			end
		end
		DefaultTooltip:AddLine(" ");
		local tooltip = format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus);
		if masteryBonus ~= 0 then
			DefaultTooltip:AddDoubleLine(tooltip ,floor( (masteryRating / masteryBonus) * 100 + 0.5) / 100 .. " [+1%]", 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		else
			DefaultTooltip:AddLine(tooltip, 1.00, 0.82, 0.00, true);
		end
	else
		DefaultTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus), 1.00, 0.82, 0.00, true);
		DefaultTooltip:AddLine(" ");
		DefaultTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true);
	end
	DefaultTooltip:SetPoint("TOPRIGHT", self,"TOPLEFT", -4, 0)
	DefaultTooltip:Show();
end

function UpdateFunc:Mastery()
	self:SetScript("OnEnter", MasteryFrame_OnEnter);

	local mastery = GetMasteryEffect();
	self:SetLabelAndValue(STAT_MASTERY, FormatPercent(mastery));
	self:SetValueRating(GetCombatRating(CR_MASTERY));
end

function UpdateFunc:Versatility()
	local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
	local attackBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
	local versaBonusAttack = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
	local defenseBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN);
	local versaBonusdefense = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);

	self:SetValueRating(versatility);

	if ClearTooltipIfSecret(self, STAT_VERSATILITY, attackBonus) then
		self:SetLabelAndValue(STAT_VERSATILITY, FormatPercent(attackBonus));
		return;
	end

	local versatilityDamageBonus = attackBonus + versaBonusAttack;
	local versatilityDamageTakenReduction = defenseBonus + versaBonusdefense;
	self.tooltip = "|cffffffff" .. format(VERSATILITY_TOOLTIP_FORMAT, STAT_VERSATILITY, versatilityDamageBonus, versatilityDamageTakenReduction) .. "|r";

	if versatilityDamageBonus == 0 then
		self.tooltip2 = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction);
		self.tooltip4 = nil;
	else
		self.tooltip2 = format(NARCI_VERSATILITY_TOOLTIP_FORMAT_1, versatilityDamageBonus, versatilityDamageTakenReduction);
		self.tooltip4 = {format(NARCI_VERSATILITY_TOOLTIP_FORMAT_2, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction) , floor( (versatility / versatilityDamageBonus) * 100 + 0.5) / 100 .. " [+1%/0.5%]"};
	end

	local percentageText = format(DIGITS, versatilityDamageBonus).."%";
	self:SetLabelAndValue(STAT_VERSATILITY, percentageText);
end

function UpdateFunc:Leech()
	local lifesteal = GetLifesteal();

	self.tooltip = "|cffffffff" .. STAT_LIFESTEAL .. " " .. FormatPercent(lifesteal) .. "|r";
	self.tooltip2 = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)), GetCombatRatingBonus(CR_LIFESTEAL));

	local PercentageText = format(DIGITS, lifesteal).."%";
	self:SetLabelAndValue(STAT_LIFESTEAL, PercentageText, canaccessvalue(lifesteal) and lifesteal == 0);
end

function UpdateFunc:Avoidance()
	local avoidance = GetAvoidance();

	self.tooltip = "|cffffffff" .. STAT_AVOIDANCE .. " " .. FormatPercent(avoidance) .. "|r";
	self.tooltip2 = format(CR_AVOIDANCE_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE)), GetCombatRatingBonus(CR_AVOIDANCE));

	local PercentageText = format(DIGITS, avoidance).."%";
	self:SetLabelAndValue(STAT_AVOIDANCE, PercentageText, canaccessvalue(avoidance) and avoidance == 0);
end

function UpdateFunc:Speed()
	local speed = GetSpeed();

	self.tooltip = "|cffffffff" .. STAT_SPEED .. " " .. FormatPercent(speed) .. "|r";
	self.tooltip2 = format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED));

	local PercentageText = format(DIGITS, speed).."%";
	self:SetLabelAndValue(STAT_SPEED, PercentageText, canaccessvalue(speed) and speed == 0);
end

local function MovementSpeed_OnUpdate(self, elapsed)
	self.t = self.t + elapsed;
	if self.t > 0.1 then
		self.t = 0;
	else
		return;
	end

	local unit = self.unit;
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit);

	if not canaccessvalue(runSpeed) then
		self.Value:SetText(N_SLASH_A);
		return;
	end

	runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100;
	flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100;
	swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100;

	-- Determine whether to display running, flying, or swimming speed
	local speed = runSpeed;
	local swimming = IsSwimming(unit);
	if swimming then
		speed = swimSpeed;
	elseif IsFlying(unit) then
		speed = flightSpeed;
	end

	-- Hack so that your speed doesn't appear to change when jumping out of the water
	if IsFalling(unit) then
		if self.wasSwimming then
			speed = swimSpeed;
		end
	else
		self.wasSwimming = swimming;
	end

	local valueText = format("%d%%", speed + 0.5);
	self.Value:SetText(valueText);

	self.speed = speed;
	self.runSpeed = runSpeed;
	self.flightSpeed = flightSpeed;
	self.swimSpeed = swimSpeed;
end

local function MovementSpeed_OnEnter(self)
	if not (self.speed and canaccessvalue(self.speed)) then
		DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
		DefaultTooltip:SetText(format(STAT_MOVEMENT_SPEED));
		DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0)
		DefaultTooltip:Show();
		return;
	end

	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	DefaultTooltip:SetText("|cffffffff".. STAT_MOVEMENT_SPEED .." "..format("%d%%", self.speed+0.5).."|r");

	DefaultTooltip:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, self.runSpeed+0.5));
	if self.unit ~= "pet" then
		DefaultTooltip:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, self.flightSpeed+0.5));
	end
	DefaultTooltip:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, self.swimSpeed+0.5));
	DefaultTooltip:AddLine(" ");
	DefaultTooltip:AddLine(format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED)));

	DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0)
	DefaultTooltip:Show();

	self.UpdateTooltip = MovementSpeed_OnEnter;
end

function UpdateFunc:MovementSpeed()
	local unit = "player";

	self.wasSwimming = nil;
	self.unit = unit;
	self.t = 0;
	self.Label:SetText(L["Movement Speed"]);		--STAT_MOVEMENT_SPEED
	MovementSpeed_OnUpdate(self, 1);
	self:SetScript("OnEnter", MovementSpeed_OnEnter);
	self:SetScript("OnUpdate", MovementSpeed_OnUpdate);
end
