local _, addon = ...

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local format = string.format;
local Secret_Multiply = addon.TransitionAPI.Secret_Multiply;
local StatSheetAPI = addon.StatSheetAPI; ---@type StatSheetAPI
local PrimaryStatIndex = StatSheetAPI.PrimaryStatIndex;


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

	if not canaccessvalue(posBuff) then return; end

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

    if IsPlayerTank() then
        local increasedParryChance = GetParryChanceFromAttribute();
        if increasedParryChance > 0 then
            desc = format("%s\n\n%s", desc, format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance));
        end
    end

    tooltip:AddNormalLine(desc);
end

function StatTooltipFunc.ExtraTooltip_Agility(tooltip, statIndex, effectiveStat)
    local desc = STAT_TOOLTIP_BONUS_AP;
    local attackPower = GetAttackPowerForStat(statIndex, effectiveStat);

    if HasAPEffectsSpellPower() then
        desc = STAT_TOOLTIP_BONUS_AP_SP;
    end

    desc = format(desc, BreakUpLargeNumbers(attackPower));
    if IsPlayerTank() then
        local increasedDodgeChance = GetDodgeChanceFromAttribute();
        if increasedDodgeChance > 0 then
            desc = format("%s\n\n%s", desc, format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance));
        end
    end

    tooltip:AddNormalLine(desc);
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

function StatTooltipFunc.Crit(tooltip)
	local critChance, rating = StatSheetAPI.GetEffectiveCrit();
	local extraCritChance = GetCombatRatingBonus(rating);
	local extraCritRating = GetCombatRating(rating);

    local NARCI_CRIT_TOOLTIP, NARCI_CRIT_TOOLTIP_FORMAT = NarciAPI.SplitTooltipByLineBreak(CR_CRIT_TOOLTIP);

	if GetCritChanceProvidesParryEffect() then
		tooltip:AddNormalLine(format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating)));
	else
		if extraCritChance == 0 then
			tooltip:AddNormalLine(format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance));
		else
            tooltip:AddNormalLine(NARCI_CRIT_TOOLTIP);
			tooltip:AddNormalDoubleLine(format(NARCI_CRIT_TOOLTIP_FORMAT, BreakUpLargeNumbers(extraCritRating), extraCritChance), floor( (extraCritRating / extraCritChance) * 100 + 0.5) / 100 .. " [+1%]");
		end
	end

    return true;
end
