local COPPER_PER_SILVER = 100;
local SILVER_PER_GOLD = 100;

local floor = math.floor;
local mod = mod;

local L = Narci.L;
local FormatTime = NarciAPI_FormatTime;

NarciBarberShopStatsMoneyFrameMixin = {};

function NarciBarberShopStatsMoneyFrameMixin:SetLabel(label)
    self.Label:SetText(label)
end

function NarciBarberShopStatsMoneyFrameMixin:SetAmount(rawCopper)
	local gold = floor(rawCopper / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((rawCopper - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
    local copper = mod(rawCopper, COPPER_PER_SILVER);
    self.Gold:SetText(gold);
    self.Silver:SetText(silver);
    self.Copper:SetText(copper);
end


---------------------------------------------------------------------------------
local function GetMapParentMapName(mapID, mapName)
    local parentMapID;
    if mapID == 627 then
        parentMapID = 619;      --Broken Isles
    elseif mapID == 125 then
        parentMapID = 127;      --Crystal Forest
    end
    if parentMapID then
        local info = C_Map.GetMapInfo(parentMapID);
        if info and info.name then
            return mapName..", "..info.name;
        else
            return mapName
        end
    else
        return mapName
    end
end


NarciBarberShopStatsLocationFrameMixin = {};

function NarciBarberShopStatsLocationFrameMixin:SetHeader()
    self.Label:SetText(L["Location"]);
    self.Visit:SetText(L["Visits"]);
    self.Duration:SetText(L["Duration"]);
    local v = 0.5;
    self.Label:SetTextColor(v, v, v);
    self.Visit:SetTextColor(v, v, v);
    self.Duration:SetTextColor(v, v, v);
end

function NarciBarberShopStatsLocationFrameMixin:SetLocation(mapID)
    if mapID then
        if mapID ~= self.mapID then
            self.mapID = mapID;
            local info = C_Map.GetMapInfo(mapID);
            if info and info.name then
                local mapName = info.name;
                mapName = GetMapParentMapName(mapID, mapName)
                self.Label:SetText(mapName);
            else
                self.Label:SetText("#"..mapID);
            end

            local textHeight = self.Label:GetHeight();
            self:SetHeight(8 + textHeight);
        end
    end
end

function NarciBarberShopStatsLocationFrameMixin:StartTimer()
    self.activeOnShow = true;
    self.t = 1;
    self:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= 1 then
            self.t = 0;
            local timestamp = time();
            self.Duration:SetText( FormatTime(self.seconds + timestamp - self.timestamp) );
        end
    end);
end

function NarciBarberShopStatsLocationFrameMixin:StopTimer()
    self:SetScript("OnUpdate", nil);
    self.activeOnShow = false;
end

function NarciBarberShopStatsLocationFrameMixin:SetValue(numVisits, seconds, timestamp)
    self.Visit:SetText(numVisits);
    self.Duration:SetText( FormatTime(seconds) );
    self.seconds = seconds;
    self.timestamp = timestamp;
end

function NarciBarberShopStatsLocationFrameMixin:OnShow()
    if self.activeOnShow then
        self:StartTimer();
    end
end

function NarciBarberShopStatsLocationFrameMixin:OnHide()
    self:SetScript("OnUpdate", nil);
end
