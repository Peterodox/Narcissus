local _, addon = ...

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local format = string.format;
local Secret_Multiply = addon.TransitionAPI.Secret_Multiply;
local StatSheetAPI = addon.StatSheetAPI; ---@type StatSheetAPI
local PrimaryStatIndex = StatSheetAPI.PrimaryStatIndex;
local FormatPercent = StatSheetAPI.FormatPercent;


---@class StatSheetLayout
local StatSheetLayout = {
    Detailed = {
        "Primary", "Health",
        "Stamina", "Armor",
        "Damage", "Reduction",
        "AttackSpeed", "Dodge",
        "Power", "Parry",
        "Regen", "Block",

        "Chart",

        "Leech", "Avoidance",
        "MovementSpeed", "Speed",
    };

    Concise = {
        "Primary",
        "Stamina",
        "Health",
        "Power",
        "Regen",

        "Spacer",

        "Crit",
        "Haste",
        "Mastery",
        "Versatility",

        "Spacer",

        "Leech",
        "Avoidance",
        "Speed",
    };
};
addon.StatSheetLayout = StatSheetLayout;


local function IsPlayerTank()
	local spec = C_SpecializationInfo.GetSpecialization();
	local role = spec and GetSpecializationRole(spec);
	return role == "TANK";
end

local function UnitHasMana()
	local powerType = UnitPowerType("player");
	return powerType == 0;
end


---@class StatTooltipFunc
local StatTooltipFunc = {};
addon.StatTooltipFunc = StatTooltipFunc;


local function SetupPrimaryStatExtraTooltip(statToken, tooltip, ...)
    if StatTooltipFunc["ExtraTooltip_"..statToken] then
        StatTooltipFunc["ExtraTooltip_"..statToken](tooltip, ...);
    end
end

local function SetupPrimaryStatTooltip(tooltip, statIndex)
	local unit = "player";
	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"];

	if not canaccessallvalues(effectiveStat, posBuff, negBuff) then return; end

	local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);

	local header = "|cffffffff".. statName .." ";

	if posBuff == 0 and negBuff == 0 then
		header = header..effectiveStatDisplay.."|r";
	else
		header = header..effectiveStatDisplay;
		if posBuff > 0 or negBuff < 0 then
			header = header.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff).."|r";
		end
		if posBuff > 0 then
			header = header.."|r"..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff).."|r";
		end
		if negBuff < 0 then
			header = header..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff).."|r";
		end
		if posBuff > 0 or negBuff < 0 then
			header = header.."|cffffffff"..")".."|r";
		end

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if negBuff < 0 and not (GetPVPGearStatRules and GetPVPGearStatRules()) then
			effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay.."|r";
		end
	end

    tooltip:SetText(header);

	if statIndex == PrimaryStatIndex.Strength then
		SetupPrimaryStatExtraTooltip("Strength", tooltip, statIndex, effectiveStat);
	elseif statIndex == PrimaryStatIndex.Agility then
		SetupPrimaryStatExtraTooltip("Agility", tooltip, statIndex, effectiveStat);
	elseif statIndex == PrimaryStatIndex.Intellect then
		SetupPrimaryStatExtraTooltip("Intellect", tooltip, statIndex, effectiveStat);
	elseif statIndex == PrimaryStatIndex.Stamina then
		SetupPrimaryStatExtraTooltip("Stamina", tooltip, statIndex, effectiveStat);
	elseif statIndex == PrimaryStatIndex.Spirit then
		SetupPrimaryStatExtraTooltip("Spirit", tooltip);
	end

    return true;
end

function StatTooltipFunc.ExtraTooltip_Strength(tooltip, statIndex, effectiveStat)
    local desc = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
    if not desc then return; end -- DEFAULT_STAT1_TOOLTIP doesn't exist on Forever

    local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);

    if HasAPEffectsSpellPower() then
        desc = STAT_TOOLTIP_BONUS_AP_SP;
    end

    desc = format(desc, BreakUpLargeNumbers(attackPower));
    tooltip:AddNormalLine(desc);

    if IsPlayerTank() then
        local increasedParryChance = GetParryChanceFromAttribute();
        if increasedParryChance > 0 then
            tooltip:AddBlankLine();
            tooltip:AddNormalLine(format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance));
        end
    end
end

function StatTooltipFunc.ExtraTooltip_Agility(tooltip, statIndex, effectiveStat)
    local desc = STAT_TOOLTIP_BONUS_AP;
    local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);

    if HasAPEffectsSpellPower() then
        desc = STAT_TOOLTIP_BONUS_AP_SP;
    end

    desc = format(desc, BreakUpLargeNumbers(attackPower));
    tooltip:AddNormalLine(desc);

    if IsPlayerTank() then
        local increasedDodgeChance = GetDodgeChanceFromAttribute();
        if increasedDodgeChance > 0 then
            tooltip:AddBlankLine();
            tooltip:AddNormalLine(format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance));
        end
    end
end

function StatTooltipFunc.ExtraTooltip_Intellect(tooltip, statIndex, effectiveStat)
    local desc = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];

    if HasAPEffectsSpellPower() then
        desc = STAT_NO_BENEFIT_TOOLTIP;
    else
        local result = HasSPEffectsAttackPower();
        if result then
            desc = format(STAT_TOOLTIP_BONUS_AP_SP, math.max(0, effectiveStat));
        else
            desc = format(desc, math.max(0, effectiveStat));
        end
    end

    tooltip:AddNormalLine(desc);
end

function StatTooltipFunc.ExtraTooltip_Stamina(tooltip, statIndex, effectiveStat)
    local desc = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
    local staminaBonusText = Secret_Multiply(effectiveStat, UnitHPPerStamina("player"), GetUnitMaxHealthModifier("player"));

    if staminaBonusText then
        desc = format(desc, BreakUpLargeNumbers(staminaBonusText));
        tooltip:AddNormalLine(desc);
    end
end

for statToken, statIndex in pairs(PrimaryStatIndex) do
    StatTooltipFunc[statToken] = function(tooltip)
        return SetupPrimaryStatTooltip(tooltip, statIndex);
    end
end

function StatTooltipFunc.Primary(tooltip)
    local statIndex = StatSheetAPI.GetPrimaryStatIndex();
    if statIndex then
        return SetupPrimaryStatTooltip(tooltip, statIndex);
    end
end

function StatTooltipFunc.Crit(tooltip)
	local critChance, ratingIndex = StatSheetAPI.GetEffectiveCrit();
	local extraCritChance = GetCombatRatingBonus(ratingIndex);
	local extraCritRating = GetCombatRating(ratingIndex);

    if not (canaccessvalue(extraCritRating) and canaccessvalue(extraCritChance)) then return; end

    local baseDecription, ratingFormat = NarciAPI.SplitTooltipByLineBreak(CR_CRIT_TOOLTIP);

    tooltip:SetText(STAT_CRITICAL_STRIKE .." "..FormatPercent(critChance), 1, 1, 1);

	if GetCritChanceProvidesParryEffect() then
		tooltip:AddNormalLine(format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating)));
	else
		if extraCritChance == 0 then
			tooltip:AddNormalLine(format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance));
		else
            tooltip:AddNormalLine(baseDecription);
            tooltip:AddBlankLine();
			tooltip:AddNormalDoubleLine(format(ratingFormat, BreakUpLargeNumbers(extraCritRating), extraCritChance), math.floor( (extraCritRating / extraCritChance) * 100 + 0.5) / 100 .. " [+1%]");
		end
	end

    return true;
end

function StatTooltipFunc.Haste(tooltip)
	local haste = GetHaste();

    if not canaccessvalue(haste) then return; end

	local hasteFormatString;

	if (haste < 0 and not GetPVPGearStatRules()) then
		hasteFormatString = RED_FONT_COLOR_CODE.."%s".."|r";
	else
		hasteFormatString = "%s";
	end

	local header = "|cffffffff" .. STAT_HASTE .. " " .. format(hasteFormatString, FormatPercent(haste)) .. "|r";
    tooltip:SetText(header);

	local _, class = UnitClass("player");
	local desc = _G["STAT_HASTE_"..class.."_TOOLTIP"];
	if not desc then
		desc = STAT_HASTE_TOOLTIP;
	end

    tooltip:AddNormalLine(desc);
    tooltip:AddBlankLine();

    local ratingIndex = CR_HASTE_MELEE;
	local rating = GetCombatRating(ratingIndex);
	local ratingBonus = GetCombatRatingBonus(ratingIndex);
    local hasteTooltipFormat = strtrim(STAT_HASTE_BASE_TOOLTIP);

	if ratingBonus == 0 then
		tooltip:AddNormalLine(format(hasteTooltipFormat, BreakUpLargeNumbers(rating), ratingBonus));
	else
        tooltip:AddNormalDoubleLine(format(hasteTooltipFormat, BreakUpLargeNumbers(rating), ratingBonus), math.floor( (rating / ratingBonus) * 100 + 0.5) / 100 .. " [+1%]");
	end

    return true;
end

function StatTooltipFunc.Mastery(tooltip)
	local mastery, bonusCoeff = GetMasteryEffect();
	if not canaccessvalue(mastery) then return; end

	local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;

	local header = "|cffffffff"..STAT_MASTERY.." "..FormatPercent(mastery).."|r";
	if masteryBonus > 0 then
		header = header.."|cffffffff".." ("..FormatPercent(mastery - masteryBonus).."|r"..GREEN_FONT_COLOR_CODE.."+"..FormatPercent(masteryBonus).."|r".."|cffffffff"..")".."|r";
	end

	tooltip:SetText(header);

	local masteryRating = GetCombatRating(CR_MASTERY);
	local primaryTalentTree = GetSpecialization();

	if primaryTalentTree then	--dragonflight
		local masterySpell, masterySpell2;
		local spells = C_SpecializationInfo.GetSpecializationMasterySpells(primaryTalentTree);

		if spells then
			masterySpell, masterySpell2 = spells[1], spells[2];
		end

		if tooltip.AddSpellByID then
			if masterySpell then
				tooltip:AddSpellByID(masterySpell);
			end
			if masterySpell2 then
				tooltip:AddBlankLine();
				tooltip:AddSpellByID(masterySpell2);
			end
		else
			if masterySpell then
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell);
				tooltipInfo.append = true;
				tooltip:ProcessInfo(tooltipInfo);
			end
			if masterySpell2 then
				tooltip:AddBlankLine();
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell2);
				tooltipInfo.append = true;
				tooltip:ProcessInfo(tooltipInfo);
			end
		end

		tooltip:AddBlankLine();

		local desc = format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus);
		if masteryBonus ~= 0 then
			tooltip:AddNormalDoubleLine(desc, math.floor( (masteryRating / masteryBonus) * 100 + 0.5) / 100 .. " [+1%]", 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		else
			tooltip:AddNormalLine(desc);
		end
	else
		tooltip:AddNormalLine(format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus));
		tooltip:AddBlankLine();
		tooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true);
	end

	return true;
end

function StatTooltipFunc.Versatility(tooltip)
    local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
    local attackBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
	local versaBonusAttack = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
	local defenseBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN);
	local versaBonusdefense = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);

    if not canaccessallvalues(attackBonus, versaBonusAttack, defenseBonus, versaBonusdefense) then return; end

	local versatilityDamageBonus = attackBonus + versaBonusAttack;
	local versatilityDamageTakenReduction = defenseBonus + versaBonusdefense;

	local header = "|cffffffff" .. format(VERSATILITY_TOOLTIP_FORMAT, STAT_VERSATILITY, versatilityDamageBonus, versatilityDamageTakenReduction) .. "|r";
    tooltip:SetText(header);

	if versatilityDamageBonus == 0 then
		tooltip:AddNormalLine(format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction));
	else
        local ratingFormat1, ratingFormat2 = NarciAPI.SplitTooltipByLineBreak(CR_VERSATILITY_TOOLTIP);
		tooltip:AddNormalLine(format(ratingFormat1, versatilityDamageBonus, versatilityDamageTakenReduction));
        tooltip:AddBlankLine();
		tooltip:AddNormalDoubleLine(format(ratingFormat2, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction) , math.floor( (versatility / versatilityDamageBonus) * 100 + 0.5) / 100 .. " [+1%/0.5%]");
	end

    return true;
end

local function SetupSimplyRatingTooltip(tooltip, ratingIndex, value, statName, description)
    if not canaccessvalue(value) then return; end
	tooltip:SetText("|cffffffff" .. statName .. " " .. FormatPercent(value) .. "|r");
	tooltip:AddNormalLine(format(description, BreakUpLargeNumbers(GetCombatRating(ratingIndex)), GetCombatRatingBonus(ratingIndex)));
    return true;
end

function StatTooltipFunc.Leech(tooltip)
    return SetupSimplyRatingTooltip(tooltip, CR_LIFESTEAL, GetLifesteal(), STAT_LIFESTEAL, CR_LIFESTEAL_TOOLTIP);
end

function StatTooltipFunc.Avoidance(tooltip)
    return SetupSimplyRatingTooltip(tooltip, CR_AVOIDANCE, GetAvoidance(), STAT_AVOIDANCE, CR_AVOIDANCE_TOOLTIP);
end

function StatTooltipFunc.Speed(tooltip)
    return SetupSimplyRatingTooltip(tooltip, CR_SPEED, GetSpeed(), STAT_SPEED, CR_SPEED_TOOLTIP);
end
