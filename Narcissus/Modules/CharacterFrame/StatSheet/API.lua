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
---@return number critRating Global like CR_CRIT_MELEE
function StatSheetAPI.GetEffectiveCrit()
	local rating;
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

function StatSheetAPI.GetPrimaryStatIndex()
	local spec = GetSpecialization() or 1;
	local _, _, _, _, _, primaryStat = C_SpecializationInfo.GetSpecializationInfo(spec);
	if type(primaryStat) == "number" then
		return primaryStat;
	end
end
