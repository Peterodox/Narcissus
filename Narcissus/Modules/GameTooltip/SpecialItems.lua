local _, addon = ...
local TimerunningUtil = addon.TimerunningUtil;

local SETUP_FUNC = {
    --[itemID] = setupFunc
};

local function TimerunnersAdvantage(tooltip)
    local rank = TimerunningUtil.GetThreadRank();
    if rank < 0 then return end;

    tooltip:AddBlankLine();
    tooltip:AddLine(string.format(Narci.L["Format Rank"], rank));

    local stats = TimerunningUtil.GetStatsBonus();
    if stats then
        for i, leftText in ipairs(stats) do
            tooltip:AddColoredText(leftText, 2);
        end
    end
end
SETUP_FUNC[210333] = TimerunnersAdvantage;


local function SetupSpecialItemTooltip(tooltip, itemID, slotID)
    if SETUP_FUNC[itemID] then
        SETUP_FUNC[itemID](tooltip);
    end
end
addon.SetupSpecialItemTooltip = SetupSpecialItemTooltip;