local _, addon = ...

local format = string.format;


local StatSheetAPI = {}; ---@class StatSheetAPI
addon.StatSheetAPI = StatSheetAPI;


StatSheetAPI.PrimaryStatIndex = {
	Strength = LE_UNIT_STAT_STRENGTH or 1,
	Agility = LE_UNIT_STAT_AGILITY or 2,
	Stamina = LE_UNIT_STAT_STAMINA or 3,
	Intellect = LE_UNIT_STAT_INTELLECT or 4,
	Spirit = LE_UNIT_STAT_SPIRIT or 5,
};

---Format a number like 67 into 67.00%
function StatSheetAPI.FormatPercent(value)
	return format("%.2f%%", value);
end

function StatSheetAPI.FormatStatBonus(name, base, posBuff, negBuff)
	posBuff = posBuff or 0;
	negBuff = negBuff or 0;

	local effectiveText = BreakUpLargeNumbers(math.max(0, base + posBuff + negBuff));
	local text = format("%s %s", name, effectiveText);

	if posBuff > 0 or negBuff < 0 then
		text = text .. format(" (%s", base);
		if posBuff > 0 then
			text =  text .. format("|cnGREEN_FONT_COLOR:+%s|r", posBuff);
		end
		if negBuff < 0 then
			text =  text .. format("|cnRED_FONT_COLOR:%s|r", negBuff);
		end
		text = text..")";
	end

	return text;
end

---For Retail where there is only one meaningful crit chance
---@return number critChance Like 5%
---@return number ratingIndex Global like CR_CRIT_MELEE
function StatSheetAPI.GetEffectiveCrit()
	local ratingIndex;
	local spellCrit, rangedCrit, meleeCrit;
	local critChance;

	-- Start at 2 to skip physical damage
	local holySchool = 2;
	local minCrit = GetSpellCritChance(holySchool);

	for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
		spellCrit = GetSpellCritChance(i);
		if not (canaccessvalue(minCrit) and canaccessvalue(spellCrit)) then
			return minCrit, CR_CRIT_MELEE;
		end
		minCrit = math.min(minCrit, spellCrit);
	end

	spellCrit = minCrit;
	rangedCrit = GetRangedCritChance();
	meleeCrit = GetCritChance();

	if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
		critChance = spellCrit;
		ratingIndex = CR_CRIT_SPELL;
	elseif rangedCrit >= meleeCrit then
		critChance = rangedCrit;
		ratingIndex = CR_CRIT_RANGED;
	else
		critChance = meleeCrit;
		ratingIndex = CR_CRIT_MELEE;
	end

	return critChance, ratingIndex;
end

function StatSheetAPI.GetPrimaryStatIndex()
	local spec = GetSpecialization() or 1;
	local _, _, _, _, _, primaryStat = C_SpecializationInfo.GetSpecializationInfo(spec);
	if type(primaryStat) == "number" then
		return primaryStat;
	end
end

---Return localized power and the value after BreakUpLargeNumbers: Mana, 10,000
---@param unit string? Default to "player"
---@return string? powerName Localized name: Mana
---@return string? displayedValue After BreakUpLargeNumbers
---@return string? powerToken "MANA"
function StatSheetAPI.GetDisplayedPower(unit)
	if not unit then unit = "player"; end

	local powerType, powerToken = UnitPowerType(unit);
	local powerName = powerToken and _G[powerToken];
	if powerName then
		local power = UnitPowerMax(unit);
		return powerName, BreakUpLargeNumbers(power), powerToken;
	end
end

---Return player regen name, rate, tooltip: Mana Regen, 1,000/s, "Mana regen every second"
---@return string? regenName Mana Regen
---@return string? regenRateText 1,000/s
---@return string? regenTooltip "Mana regen every second"
function StatSheetAPI.GetDisplayedComatRegen()
	local powerType, powerToken = UnitPowerType("player");
	local regenRate = GetPowerRegen();
	local regenName, regenRateText, regenTooltip;

	if powerToken == "ENERGY" then
		regenName = STAT_ENERGY_REGEN;
		regenTooltip = STAT_ENERGY_REGEN_TOOLTIP;
	elseif powerToken == "RUNES" then
		regenName = STAT_RUNE_REGEN;
		regenTooltip = STAT_RUNE_REGEN_TOOLTIP;
	elseif powerToken == "FOCUS" then
		regenName = STAT_FOCUS_REGEN;
		regenTooltip = STAT_FOCUS_REGEN_TOOLTIP;
	elseif powerToken == "MANA" then
		regenName = MANA_REGEN;
		--regenTooltip = MANA_REGEN_TOOLTIP; --On Retail, Mana doesn't follow the 5-second rule
		regenRate = GetManaRegen();
	else
		local _, class = UnitClass("player");
		if class == "DEATHKNIGHT" then
			regenName = STAT_RUNE_REGEN;
			regenTooltip = STAT_RUNE_REGEN_TOOLTIP;
			local _, runeDuration = GetRuneCooldown(1);
			regenRateText = format(STAT_RUNE_REGEN_FORMAT, runeDuration);
		else
			-- Fun fact: Regen can be negative for Warrior
			return;
		end
	end

	if not regenRateText then
		if powerToken == "MANA" then
			regenRateText = format("%.0f/s", regenRate);
		else
			regenRateText = format("%.2f/s", regenRate);
		end
	end

	return regenName, regenRateText, regenTooltip;
end

---Return the armorReduction, armorReductionAgainstTarget, effectiveArmor. Convert decimal to percentage. Secret check included.
---@return number? armorReduction
---@return number? armorReductionAgainstTarget
---@return number? effectiveArmor
function StatSheetAPI.GetArmorReduction()
	local _, effectiveArmor = UnitArmor("player");
	local level = UnitEffectiveLevel("player");
	if canaccessallvalues(effectiveArmor, level) then
		local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, level) or 0;
		local armorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(effectiveArmor) or 0;
		if armorReductionAgainstTarget > 0 then
			return 100 * armorReduction, 100 * armorReductionAgainstTarget, effectiveArmor;
		else
			return 100 * armorReduction, nil, effectiveArmor;
		end
	end
end

---Return mainhandMinDamage, mainhandMaxDamage, offhandMinDamage, offhandMaxDamage, posBuff, negBuff, percent
---@param useRangedWeapon boolean? Only use true/false on games where Ranged slot exist
local function GetAppropriateDamage(useRangedWeapon)
	if useRangedWeapon == nil then
		useRangedWeapon = IsRangedWeapon();
	end

	if useRangedWeapon then
		local attackTime, minDamage, maxDamage, posBuff, negBuff, percent = UnitRangedDamage("player");
		return minDamage, maxDamage, 0, 0, posBuff, negBuff, percent;
	else
		return UnitDamage("player");
	end
end

---Return damage text for StatButton: 1234 - 2345
---@param useRangedWeapon boolean? Specify ranged or melee weapons
function StatSheetAPI.GetDisplayedDamage(useRangedWeapon)
	local minDamage, maxDamage = GetAppropriateDamage(useRangedWeapon);
	if canaccessallvalues(minDamage, maxDamage) then
		minDamage = math.max(math.floor(minDamage), 1);
		maxDamage = math.max(math.ceil(maxDamage), 1);
	end
	return format("%.0f - %.0f", minDamage, maxDamage);
end

---Return mainhandDamage, offhandDamage. Format: 1,234 - 2,345 x108%
---Offhand can have damage without weapon, but we don't show that on the tooltip
---@param useRangedWeapon boolean? Specify ranged or melee weapons
---@return string?  mainhandDamage
---@return string? offhandDamage
function StatSheetAPI.GetDamageTooltip(useRangedWeapon)
	local mainhandMinDamage, mainhandMaxDamage, offhandMinDamage, offhandMaxDamage, posBuff, negBuff, percent = GetAppropriateDamage(useRangedWeapon);
	if not canaccessallvalues(mainhandMinDamage, offhandMinDamage, posBuff, percent) then return; end
	if (not percent) or percent == 0 then return; end;

	local colorPos = "|cff20ff20";
	local colorNeg = "|cffff2020";
	local mainhandDamage, offhandDamage;

	for i = 1, (C_PaperDollInfo.OffhandHasWeapon() and 2 or 1) do -- Main/Off hand
		local minDamage = i == 1 and mainhandMinDamage or offhandMinDamage;
		local maxDamage = i == 1 and mainhandMaxDamage or offhandMaxDamage;
		local baseMinDamage = (minDamage / percent) - posBuff - negBuff;
		local baseMaxDamage = (maxDamage / percent) - posBuff - negBuff;
		local baseDamage = (baseMinDamage + baseMaxDamage) * 0.5;
		local fullDamage = (baseDamage + posBuff + negBuff) * percent;
		local totalBonus = fullDamage - baseDamage;
		local damageTooltip = BreakUpLargeNumbers(math.max(math.floor(baseMinDamage), 1)).." - "..BreakUpLargeNumbers(math.max(math.ceil(baseMaxDamage), 1));

		if totalBonus > -0.1 and totalBonus < 0.1 then
			-- Considered as Zero Bonus
		else
			if posBuff > 0 then
				damageTooltip = format("%s %s+%.0f|r", damageTooltip, colorPos, posBuff);
			end
			if negBuff < 0 then
				damageTooltip = format("%s %s%.0f|r", damageTooltip, colorNeg, negBuff);
			end
			if percent > 1 then
				damageTooltip = format("%s %sx%.0f%%|r", damageTooltip, colorPos, 100 * percent);
			elseif percent < 1 then
				damageTooltip = format("%s %sx%.0f%%|r", damageTooltip, colorNeg, 100 * percent);
			end
		end

		if i == 1 then
			mainhandDamage = damageTooltip;
		else
			offhandDamage = damageTooltip;
		end
	end

	return mainhandDamage, offhandDamage;
end

---Return mainhandSpeed, offhandSpeed. If merged == true, connect the two if the speeds are different.
---@param merged boolean? If true, merge the Main/Off hand speeds into one string
function StatSheetAPI.GetDisplayedAttackSpeed(merged)
	local mainhandSpeed, offhandSpeed = UnitAttackSpeed("player");
	if canaccessallvalues(mainhandSpeed, offhandSpeed) then
		mainhandSpeed = math.floor(100 * mainhandSpeed + 0.5) / 100;
		if offhandSpeed then
			offhandSpeed = math.floor(100 * offhandSpeed + 0.5) / 100;
		end
		if merged then
			if offhandSpeed and offhandSpeed ~= mainhandSpeed then
				return format("%.2f / %.2f", mainhandSpeed, offhandSpeed);
			end
		else
			if offhandSpeed then
				return format("%.2f", mainhandSpeed), format("%.2f", offhandSpeed);
			end
		end
	end
	return format("%.2f", mainhandSpeed);
end

---@return string? formattedText
function StatSheetAPI.GetDisplayedRangedAttackSpeed()
	local _, _, rangedSpeed = UnitAttackSpeed("player");
	if rangedSpeed then
		if canaccessallvalues(rangedSpeed) then
			rangedSpeed = math.floor(100 * rangedSpeed + 0.5) / 100;
		end
		return format("%.2f", rangedSpeed);
	end
end

---@return number? effectiveDefenseSkill
---@return number? baseDefenseSkill
---@return number? defenseModifier
---@return number? maxDefense
function StatSheetAPI.GetEffectiveDefenseSkill()
	local baseDefenseSkill, defenseModifier = UnitDefenseSkill("player");
	local playerLevel = UnitLevel("player");
	if canaccessallvalues(baseDefenseSkill, defenseModifier, playerLevel) then
		local SKILL_RANKS_PER_SKILL_LEVEL = 5;
		local effectiveDefenseSkill = math.max(0, baseDefenseSkill + defenseModifier);
		local maxDefense = playerLevel * SKILL_RANKS_PER_SKILL_LEVEL;
		return effectiveDefenseSkill, baseDefenseSkill, defenseModifier, maxDefense
	end
end

local function FormatDPS(minDamage, maxDamage, speed)
	if not canaccessallvalues(minDamage, maxDamage, speed) then return; end

	minDamage = minDamage or 0;
	maxDamage = maxDamage or 0;
	speed = speed or 1;

	return format("%.1f", (minDamage + maxDamage) / (2 * speed));
end

---@return string? mainhandDPS
---@return string? offhandDPS
---@return string? rangedDPS
function StatSheetAPI.GetDisplayedDPS()
	local mainhandMinDamage, mainhandMaxDamage, offhandMinDamage, offhandMaxDamage = GetAppropriateDamage(false);
	local rangedMinDamage, rangedMaxDamage = GetAppropriateDamage(true);
	local mainhandSpeed, offhandSpeed, rangedSpeed = UnitAttackSpeed("player");
	return FormatDPS(mainhandMinDamage, mainhandMaxDamage, mainhandSpeed),
		FormatDPS(offhandMinDamage, offhandMaxDamage, offhandSpeed),
		FormatDPS(rangedMinDamage, rangedMaxDamage, rangedSpeed);
end
