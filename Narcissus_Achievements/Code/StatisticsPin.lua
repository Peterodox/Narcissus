local MAX_PINS = 20;

local _, addon = ...

local p = {};
addon.PinUtil = p;

local isPinned = {};
local db;


function p:Load()
    if not NarciAchievementOptions.pinnedStatistics then
        NarciAchievementOptions.pinnedStatistics = {};
    end
    db = NarciAchievementOptions.pinnedStatistics;
    for _, id in pairs(db) do
        isPinned[id] = true;
    end
end

function p:Pin(statID)
    if not db then
        self:Load();
    end
    if self:IsVacant() and (not isPinned[statID]) then
        tinsert(db, 1, statID);
        isPinned[statID] = true;
        return true;
    else
        return false;
    end
end

function p:IsPinned(statID)
    return isPinned[statID]
end

function p:Unpin(statID)
    if db and isPinned[statID] then
        for i = 1, #db do
            if db[i] == statID then
                isPinned[statID] = nil;
                table.remove(db, i);
                return true;
            end
        end
    end
end

function p:Toggle(statID)
    -- 0-Unpinned  1-Pinned  2-Capped
    if statID then
        if isPinned[statID] then
            self:Unpin(statID);
            return 0
        else
            if self:IsVacant() then
                self:Pin(statID);
                return 1
            else
                return 2
            end
        end
    else
        return 0
    end
end

function p:GetTotal()
    if db then
        return #db, MAX_PINS;
    else
        return 0, MAX_PINS;
    end
end

function p:IsVacant()
    return self:GetTotal() < MAX_PINS
end

function p:GetList()
    if db then
        return db;
    else
        return {};
    end
end

function p:GetID(index)
    if db then
        return db[index]
    end
end

function p:GetSummaryText()
    local total = self:GetTotal();
    return string.format("%d/%d", total, MAX_PINS);    --Narci.L["Pinned Entry Format"]
end