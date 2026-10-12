local _, addon = ...

-- 12.1.0 client doesn't recognize [AllowLoadGameType camelot] so this file is still loaded.
if not addon.IS_FOREVER then return; end

local format = string.format;


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
        "Strength",
        "Agility",
        "Stamina",
        "Intellect",
        "Spirit",

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


local StatTooltipFunc = addon.StatTooltipFunc; ---@class StatTooltipFunc

local CLASS_FILE_NAME;

---@param statToken string
local function GetClassSpecificTooltip(statToken)
    if not CLASS_FILE_NAME then
        _, CLASS_FILE_NAME = UnitClass("player");
        CLASS_FILE_NAME = string.upper(CLASS_FILE_NAME);
    end

    local classStatText = _G[CLASS_FILE_NAME.."_"..string.upper(statToken).."_TOOLTIP"];
    if not classStatText then
		classStatText = _G["DEFAULT".."_"..string.upper(statToken).."_".."TOOLTIP"];
	end

    return classStatText;
end

function StatTooltipFunc:Strength(statIndex, effectiveStat)
    local BLOCK_VALUE_PER_STRENGTH = 20;
    local classStatText = GetClassSpecificTooltip("Strength");
    self.tooltip2 = format(classStatText, GetAttackPowerForStat(statIndex, effectiveStat), math.floor(effectiveStat / BLOCK_VALUE_PER_STRENGTH));
end

function StatTooltipFunc:Agility(statIndex, effectiveStat)
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

    self.tooltip2 = classStatText;
end

function StatTooltipFunc:Stamina(statIndex, effectiveStat)
    local staminaBreak = STAMINA_BREAK or 10;

    local bonus = math.min(staminaBreak, effectiveStat);
    local perStaminaBonus = (math.max(staminaBreak, effectiveStat) - staminaBreak) * UnitHPPerStamina("player");
    bonus = bonus + perStaminaBonus;

    local classStatText = GetClassSpecificTooltip("Stamina");
    self.tooltip2 = format(classStatText, tostring(bonus));
end

function StatTooltipFunc:Intellect(statIndex, effectiveStat)
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

    self.tooltip2 = classStatText;
end

function StatTooltipFunc:Spirit()
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

    self.tooltip2 = format("%s\n\n%s", classStatText, SPIRIT_STANDING_WARNING);
end
