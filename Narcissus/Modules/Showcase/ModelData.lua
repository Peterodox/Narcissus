local _, addon = ...

local OffsetData = {
    --[modelFileID] = offsetY,
    [917116] = 0.053,   --Orc/Mag'har M Hunched
    [1968587] = 0.08,   --Mag'har Upright
    [949470] = 0.053,   --Orc F

    [1630218] = 0.107,  --Highmountain M
    [1630402] = 0.071,  --Highmountain F

    [940356] = 0.049,   --Gnome F
    [900914] = 0.094,   --Gnome M

    [2564806] = 0.078,  --Mechagnome F
    [2622502] = 0.061,  --Mechagnome M

    [1022598] = 0.02,   --Draenei F
    [1005887] = 0.17,   --Draenei M     --need rework

    [1593999] = 0.02,   --Lightforged F
    [1620605] = 0.017,  --Lightforged M

    [589715] = 0.028,   --Pandaren F
    [535052] = 0.119,   --Pandaren M

    [968705] = 0.152,   --Tauren M

    [997378] = 0.06,    --UD F
    [959310] = 0.070,   --UD M

    [1000764] = 0,      --Human F
    [1011653] = 0,      --Human M

    [307453] = 0,       --Worgen-Wolf F
    [307454] = 0,       --Worgen-Wolf M

    [1890763] = 0.055,  --DarkIron F
    [1890765] = 0,      --DarkIron M

    [950080] = 0.012,   --Dwarf F
    [878772] = 0.049,   --Dwarf M

    [1733758] = 0,      --VE F
    [1734034] = 0,      --VE M

    [1100258] = 0.041,  --BE F

    [921844] = 0,       --NE F
    [974343] = 0,       --NE M

    [1018060] = 0.097,  --Troll F
    [1022938] = 0.066,  --Troll M

    [1886724] = 0,      --KulTiran F
    [1721003] = 0,      --KulTiran M

    [119369] = 0.032,   --Goblin F
    [119376] = 0.025,   --Goblin M

    [1662187] = 0.074,  --Zandalari F
    [1630447] = 0.050,  --Zandalari M

    [1890759] = 0,  --Vulpera F
    [1890761] = 0.074,  --Vulpera M
};


local function GetModelOffsetZ(modelFileID)
    return OffsetData[modelFileID] or 0
end

addon.GetModelOffsetZ = GetModelOffsetZ;