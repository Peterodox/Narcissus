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

function StatTooltipFunc:Spirit()
    local desc;
    local spiritStandingPenalty = 0.75;

    local healthRegenFromSpirit = GetHealthRegenFromSpirit() * spiritStandingPenalty; -- Assume player is standing
    local manaRegenFromSpirit = GetManaRegenFromSpirit();

    local healthRegen = GetHealthRegen();
    local manaRegen = GetManaRegen();

    local _, classFileName = UnitClass("player");
    local classStatText = _G[string.upper(classFileName).."_SPIRIT_TOOLTIP"];
    if classStatText then
        desc = classStatText;
    end

    if classFileName == "WARRIOR" or classFileName == "ROGUE" then
        desc = format(desc, healthRegenFromSpirit * 5, healthRegen * 5);
    else
        desc = format(desc, healthRegenFromSpirit * 5, manaRegenFromSpirit * 5, healthRegen * 5, manaRegen * 5);
    end

    desc = format("%s\n\n%s", desc, SPIRIT_STANDING_WARNING);

    self.tooltip2 = desc;
end
