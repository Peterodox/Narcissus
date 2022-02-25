if true then return end;

local EL = CreateFrame("Frame");
local events = {"BIND_ENCHANT", "REPLACE_ENCHANT", "ITEM_CHANGED", "SKILL_LINES_CHANGED", "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "CHARACTER_ITEM_FIXUP_NOTIFICATION"}
for _, event in pairs(events) do
    EL:RegisterEvent(event);
end

EL:SetScript("OnEvent", function(self, event, ...)
    print(event);
end);