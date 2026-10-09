local _, addon = ...


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
