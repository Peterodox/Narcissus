local _, addon = ...

-- 12.1.0 client doesn't recognize [AllowLoadGameType camelot] so this file is still loaded.
if not addon.IS_FOREVER then return; end

local format = string.format;
local StatSheetAPI = addon.StatSheetAPI; ---@class StatSheetAPI
local FormatPercent = StatSheetAPI.FormatPercent;


---@class StatSheetLayout
local StatSheetLayout = {
    Detailed = {}, -- No Detailed view for Forever

    Concise = {
        "Health",
        "Power",
        "MovementSpeed",

        "Spacer",

        "Strength",
        "Agility",
        "Stamina",
        "Intellect",
        "Spirit",

        "Spacer",

        "StatTab",
    },
};
addon.StatSheetLayout = StatSheetLayout;


StatSheetAPI.StatTabInfo = {
    {
        key = "Melee",
        name = PLAYERSTAT_MELEE_COMBAT,
        layout = {"Damage", "AttackSpeed", "Regen", "Crit"},
    },

    {
        key = "Ranged",
        name = PLAYERSTAT_RANGED_COMBAT,
        layout = {"Damage", "AttackSpeed", "Regen", "Crit"},
    },

    {
        key = "Spell",
        name = PLAYERSTAT_SPELL_COMBAT,
        layout = {"Damage", "AttackSpeed", "Regen", "Crit"},
    },

    {
        key = "Defense",
        name = STAT_CATEGORY_DEFENSE,
        layout = {"Defense", "Dodge", "Block", "Parry", "Armor"},
    },
};


local StatTooltipFunc = addon.StatTooltipFunc; ---@class StatTooltipFunc

local CLASS_FILE_NAME;

local function InitPlayerClass()
    if not CLASS_FILE_NAME then
        _, CLASS_FILE_NAME = UnitClass("player");
        CLASS_FILE_NAME = string.upper(CLASS_FILE_NAME);
    end
end

---@param statToken string
local function GetClassSpecificTooltip(statToken)
    InitPlayerClass();

    local classStatText = _G[CLASS_FILE_NAME.."_"..string.upper(statToken).."_TOOLTIP"];
    if not classStatText then
		classStatText = _G["DEFAULT".."_"..string.upper(statToken).."_".."TOOLTIP"];
	end

    return classStatText;
end

function StatTooltipFunc.ExtraTooltip_Strength(tooltip, statIndex, effectiveStat)
    local BLOCK_VALUE_PER_STRENGTH = 20;
    local classStatText = GetClassSpecificTooltip("Strength");
    classStatText = format(classStatText, GetAttackPowerForStat(statIndex, effectiveStat), math.floor(effectiveStat / BLOCK_VALUE_PER_STRENGTH));
    tooltip:AddNormalLine(classStatText, false);
end

function StatTooltipFunc.ExtraTooltip_Agility(tooltip, statIndex, effectiveStat)
    local ARMOR_PER_AGILITY = 2;
    local classStatText = GetClassSpecificTooltip("Agility");

    local increasedDodgeChance = GetDodgeChanceFromAttribute() * 100.0;
    local increasedArmor = effectiveStat * ARMOR_PER_AGILITY;
    local increasedMeleeCritChance = GetCritChanceFromStat(statIndex, effectiveStat) * 100.0;
    local increasedRangedCritChance = increasedMeleeCritChance;
    local increasedAttackPower = GetAttackPowerForStat(statIndex, effectiveStat);
    local increasedRangedAttackPower = GetRangedAttackPowerForStat(statIndex, effectiveStat);

    if CLASS_FILE_NAME == "ROGUE" then
        classStatText = format(classStatText, increasedMeleeCritChance, increasedAttackPower, increasedRangedAttackPower, increasedArmor, increasedDodgeChance);
    elseif CLASS_FILE_NAME == "HUNTER" then
        classStatText = format(classStatText, increasedRangedCritChance, increasedAttackPower, increasedRangedAttackPower, increasedArmor, increasedDodgeChance);
    elseif CLASS_FILE_NAME == "DRUID" then
        local catFormAgility = effectiveStat;
        classStatText = format(classStatText, increasedMeleeCritChance, catFormAgility, increasedArmor, increasedDodgeChance);
    elseif CLASS_FILE_NAME == "WARRIOR" then
        classStatText = format(classStatText, increasedRangedCritChance, increasedRangedAttackPower, increasedArmor, increasedDodgeChance);
    else
        classStatText = format(classStatText, increasedMeleeCritChance, increasedArmor, increasedDodgeChance);
    end

    tooltip:AddNormalLine(classStatText, false);
end

function StatTooltipFunc.ExtraTooltip_Stamina(tooltip, statIndex, effectiveStat)
    local staminaBreak = STAMINA_BREAK or 10;

    local bonus = math.min(staminaBreak, effectiveStat);
    local perStaminaBonus = (math.max(staminaBreak, effectiveStat) - staminaBreak) * UnitHPPerStamina("player");
    bonus = bonus + perStaminaBonus;

    local classStatText = GetClassSpecificTooltip("Stamina");
    classStatText = format(classStatText, tostring(bonus));
    tooltip:AddNormalLine(classStatText);
end

function StatTooltipFunc.ExtraTooltip_Intellect(tooltip, statIndex, effectiveStat)
    local intellectBreak = INTELLECT_BREAK or 20;
    local manaPerIntellect = MANA_PER_INTELLECT or 15;

    local classStatText = GetClassSpecificTooltip("Intellect");
    local spellCrit = GetSpellCritChanceFromStat(statIndex, effectiveStat) * 100.0;

    if CLASS_FILE_NAME == "WARRIOR" or CLASS_FILE_NAME == "ROGUE" then
        classStatText = format(classStatText, spellCrit);
    else
        local manaBonus = math.min(intellectBreak, effectiveStat);
        manaBonus = manaBonus + (math.max(intellectBreak, effectiveStat) - intellectBreak) * manaPerIntellect;

        classStatText = format(classStatText, tostring(manaBonus), spellCrit);
    end

    tooltip:AddNormalLine(classStatText, false);
end

function StatTooltipFunc.ExtraTooltip_Spirit(tooltip)
    local spiritStandingPenalty = 0.75;

    local healthRegenFromSpirit = GetHealthRegenFromSpirit() * spiritStandingPenalty; -- Assume player is standing
    local manaRegenFromSpirit = GetManaRegenFromSpirit();

    local healthRegen = GetHealthRegen();
    local manaRegen = GetManaRegen();

    local classStatText = GetClassSpecificTooltip("Spirit");

    if CLASS_FILE_NAME == "WARRIOR" or CLASS_FILE_NAME == "ROGUE" then
        classStatText = format(classStatText, healthRegenFromSpirit * 5, healthRegen * 5);
    else
        classStatText = format(classStatText, healthRegenFromSpirit * 5, manaRegenFromSpirit * 5, healthRegen * 5, manaRegen * 5);
    end

    tooltip:AddNormalLine(classStatText);
    tooltip:AddBlankLine();
    tooltip:AddNormalLine(SPIRIT_STANDING_WARNING);
end

function StatTooltipFunc.Crit(tooltip)
    local critChance = StatSheetAPI.GetEffectiveCrit();

	local meleeCrit = GetCritChance();
    local rangedCrit = GetRangedCritChance();
    local spellCrit = GetSpellCritChance();

    if not (canaccessvalue(meleeCrit)) then return; end

    tooltip:SetText(STAT_CRITICAL_STRIKE .." "..FormatPercent(critChance), 1, 1, 1);

    tooltip:AddNormalLine(format(STAT_CRIT_MELEE, meleeCrit));

    InitPlayerClass();
	local isRangedClass = CLASS_FILE_NAME == "WARRIOR" or CLASS_FILE_NAME == "HUNTER" or CLASS_FILE_NAME == "ROGUE";

	if isRangedClass then
        tooltip:AddNormalLine(format(STAT_CRIT_RANGED, rangedCrit));
	end

    tooltip:AddNormalLine(format(STAT_CRIT_SPELL, spellCrit));

	local critBonusTooltip = _G["STAT_" .. CLASS_FILE_NAME .. "_CRIT_BONUS"] or STAT_CRIT_BONUS;
    if critBonusTooltip then
        tooltip:AddBlankLine();
        tooltip:AddNormalLine(format(critBonusTooltip)); -- Clear the % in the tooltip
    end

    return true;
end

function StatTooltipFunc.Defense(tooltip)
    local effectiveDefenseSkill, baseDefenseSkill, defenseModifier, maxDefense = StatSheetAPI.GetEffectiveDefenseSkill();
    if effectiveDefenseSkill then
        local posBuff = 0;
        local negBuff = 0;
        if defenseModifier > 0 then
            posBuff = defenseModifier;
        elseif defenseModifier < 0 then
            negBuff = defenseModifier;
        end

        local header = StatSheetAPI.FormatStatBonus(DEFENSE, baseDefenseSkill, posBuff, negBuff);
        tooltip:SetText(header, 1, 1, 1);

        local STAT_PER_DEFENSE = 0.04;
        local effectiveDefense = math.max(effectiveDefenseSkill - maxDefense, 0);

        tooltip:AddNormalLine(format(DEFAULT_STATDEFENSE_TOOLTIP, effectiveDefense * STAT_PER_DEFENSE, effectiveDefense * STAT_PER_DEFENSE));

        return true;
    end
end

function StatTooltipFunc.Dodge(tooltip)
    local dodgeChance = GetDodgeChance();
    tooltip:SetText(format("%s %.2f%%", DODGE_CHANCE, dodgeChance), 1, 1, 1);
    tooltip:AddNormalLine(format(CR_DODGE_BASE_STAT_TOOLTIP, dodgeChance));
    return true;
end

function StatTooltipFunc.Block(tooltip)
	local chance = GetBlockChance();
	tooltip:SetText(format("%s %s", BLOCK_CHANCE, FormatPercent(chance)), 1, 1, 1);
	local shieldBlockArmor = GetShieldBlock();
	tooltip:AddNormalLine(format(STAT_BLOCK_VALUE_FLAT_TOOLTIP, chance, shieldBlockArmor));
	return true;
end
