local match = string.match;

local IsEquippableItem = IsEquippableItem;

local function ShortenHyperLink(hyperlink)
    return match(hyperlink, "item:([%-?%d:]+)")
end


--Generic Loot Tracker
local PLAYER_GUID = UnitGUID("player");

local EventListener = CreateFrame("Frame");
local staticEvents = {
    "LOOT_OPENED",
}

EventListener:RegisterEvent("CHAT_MSG_LOOT");
EventListener:SetScript("OnEvent", function(self, event, ...)
    local payloads = {...};
    local guid = payloads[12];
    if not guid or guid ~= PLAYER_GUID then return end;

    local text = payloads[1];
    local itemID = match(text, "item:(%d+):");
    if itemID then
        itemID = tonumber(itemID);
        if IsEquippableItem(itemID) then
            local link = match(text, "|c.+|h");
            if link then
                print(link);
            end
        end
    end
end);


local GreatVault = {};

function GreatVault:Enable()
    hooksecurefunc(C_WeeklyRewards, "ClaimReward", function(id)
        self:OnRewardClaimed();
    end);
    self.Enable = nil;
end

function GreatVault:OnRewardClaimed()
    local f = WeeklyRewardsFrame;
    if f and f.confirmSelectionFrame then
        local itemDBID = f.confirmSelectionFrame.itemDBID;
        if itemDBID then
            local itemHyperlink = C_WeeklyRewards.GetItemHyperlink(itemDBID);
            print(itemHyperlink);
        end
    end
end





--Activation
GreatVault:Enable();