local _, addon = ...

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
	return string.format("%.2f%%", value);
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

	return critChance, ratingIndex
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
			regenRateText = string.format(STAT_RUNE_REGEN_FORMAT, runeDuration);
		end
	end

	if not regenRateText then
		regenRateText = string.format("%.2f/s", BreakUpLargeNumbers(regenRate));
	end

	return regenName, regenRateText, regenTooltip;
end
