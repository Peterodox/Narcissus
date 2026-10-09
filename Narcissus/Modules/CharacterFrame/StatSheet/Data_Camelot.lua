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

---@param statToken string
local function GetClassSpecificTooltip(statToken)
    local _, classFileName = UnitClass("player");
    local classStatText = _G[string.upper(classFileName).."_"..string.upper(statToken).."_TOOLTIP"];
    if not classStatText then
		classStatText = _G["DEFAULT".."_"..string.upper(statToken).."_".."TOOLTIP"];
	end
    return classStatText;
end

function StatTooltipFunc:Stamina(statIndex, effectiveStat)
    local staminaBreak = STAMINA_BREAK or 10;

    local bonus = math.min(staminaBreak, effectiveStat);
    local perStaminaBonus = (math.max(staminaBreak, effectiveStat) - staminaBreak) * UnitHPPerStamina("player");
    bonus = bonus + perStaminaBonus;

    local classStatText = GetClassSpecificTooltip("Stamina");
    self.tooltip2 = string.format(classStatText, tostring(bonus));
end

function StatTooltipFunc:Spirit()
    local spiritStandingPenalty = 0.75;

    local healthRegenFromSpirit = GetHealthRegenFromSpirit() * spiritStandingPenalty; -- Assume player is standing
    local manaRegenFromSpirit = GetManaRegenFromSpirit();

    local healthRegen = GetHealthRegen();
    local manaRegen = GetManaRegen();

    local classStatText = GetClassSpecificTooltip("Spirit");
    local _, classFileName = UnitClass("player");

    if classFileName == "WARRIOR" or classFileName == "ROGUE" then
        classStatText = format(classStatText, healthRegenFromSpirit * 5, healthRegen * 5);
    else
        classStatText = format(classStatText, healthRegenFromSpirit * 5, manaRegenFromSpirit * 5, healthRegen * 5, manaRegen * 5);
    end

    self.tooltip2 = format("%s\n\n%s", classStatText, SPIRIT_STANDING_WARNING);
end
