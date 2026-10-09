local _, addon = ...

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local format = string.format;
local Secret_Multiply = addon.TransitionAPI.Secret_Multiply;


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
	local spec = GetSpecialization();
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

---@param statIndex number
---@param effectiveStat number
function StatTooltipFunc:Strength(statIndex, effectiveStat)
    local desc = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
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

    self.tooltip2 = desc;
end

---@param statIndex number
---@param effectiveStat number
function StatTooltipFunc:Agility(statIndex, effectiveStat)
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

    self.tooltip2 = desc;
end

---@param statIndex number
---@param effectiveStat number
function StatTooltipFunc:Intellect(statIndex, effectiveStat)
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

    self.tooltip2 = desc;
end

---@param statIndex number
---@param effectiveStat number
function StatTooltipFunc:Stamina(statIndex, effectiveStat)
    local desc = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
    local staminaBonusText = Secret_Multiply(effectiveStat, UnitHPPerStamina("player"), GetUnitMaxHealthModifier("player"));

    if staminaBonusText then
        desc = format(desc, BreakUpLargeNumbers(staminaBonusText));
    else
        desc = nil;
    end

    self.tooltip2 = desc;
end
