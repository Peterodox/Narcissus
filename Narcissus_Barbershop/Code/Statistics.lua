local _, addon = ...

local time = time;

local StatManager = {};
addon.StatManager = StatManager;

StatManager.widgets = {};
StatManager.LocationFrames = {};

function StatManager:LoadData()
    if not NarciStatisticsDB_PC then
        NarciStatisticsDB_PC = {};
    end

    if not NarciStatisticsDB_PC.Barbershop then
        NarciStatisticsDB_PC.Barbershop = {};
    end

    if not NarciStatisticsDB_PC.Barbershop.Locations then
        NarciStatisticsDB_PC.Barbershop.Locations = {};   --[mapID] = {visit, time};
    end

    self.DB = NarciStatisticsDB_PC.Barbershop;
end

function StatManager:StartTimer()
    self.startTime = time();
end

function StatManager:StopTimer()
    if self.startTime then
        local stopTime = time();
        local duration = stopTime - self.startTime;
        self.startTime = 0;

        local mapID = self.mapID;
        if mapID and duration < 4800 then   --time broken?
            self.DB.Locations[mapID].time = self.DB.Locations[mapID].time + duration;
        end
    end
end

function StatManager:UpdateLocationFrame()
    local Locations = self.DB.Locations;
    local list = {};
    for mapID, data in pairs(Locations) do
        table.insert(list, {mapID, data.visit, data.time});
    end
    if #list > 0 then
        table.sort(list, function(a, b) return a[1] < b[1] end );
        local timestamp = time();
        local mapID = self.mapID;
        for i = 1, #list do
            local widget = self.LocationFrames[i];
            if not widget then
                widget = CreateFrame("Frame", nil, self.StatFrame, "NarciBarberShopStatsLocationFrameTemplate");
                if i == 1 then
                    widget:SetPoint("TOP", self.widgets.LocationHeader, "BOTTOM", 0, 16*(1 - i));
                else
                    widget:SetPoint("TOP", self.LocationFrames[i - 1], "BOTTOM", 0, 0);
                end
                self.LocationFrames[i] = widget;
            end
            widget:SetLocation(list[i][1]);
            widget:SetValue(list[i][2], list[i][3], timestamp);
            if list[i][1] == mapID then
                widget:StartTimer();
            else
                widget:StopTimer();
            end
        end
    end
end

function StatManager:UpdateLocationFramesHeight()
    local numFrames = #self.LocationFrames;
    if numFrames > 0 then
        local height = self.LocationFrames[1]:GetTop() - self.LocationFrames[numFrames]:GetBottom() + 100;
        self.StatFrame.tabHeight = self.StatFrame.basicHeight + 32;
        if self.StatFrame:IsShown() then
            self.SettingFrame:SelectTab(self.StatFrame);
        end
        return height
    else
        return 0
    end
end

function StatManager:UpdateZone()
    local mapID = C_Map.GetBestMapForUnit("player");
    self.mapID = mapID;
    if mapID then
        --print(C_Map.GetMapInfo(mapID).name);
        if not self.DB.Locations[mapID] then
            self.DB.Locations[mapID] = { visit = 0, time = 0 };
        end
        self.DB.Locations[mapID].visit = self.DB.Locations[mapID].visit + 1;
    end
end

function StatManager:UpdateFrame()
    self:UpdateLocationFrame();
    self:UpdateLocationFramesHeight();
end

function StatManager:OnBarberShopOpen()
    C_Timer.After(0.5, function()
        self:UpdateZone();
        self:StartTimer();
        --self:UpdateMoney();
    end)
end

function StatManager:OnBarberShopClose()
    self:StopTimer();
end

function StatManager:UpdateMoney()
    local moneyLifetime = GetStatistic(1147);
    local copperLifetime;
    if moneyLifetime then
        --"544|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
        local gold = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-GoldIcon") or 0;
        local silver = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-SilverIcon") or 0;
        local copper = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-CopperIcon") or 0;
        local rawCopper = 10000 * gold + 100 * silver + copper;
        self.widgets.CoinsSpentLifetime:SetAmount(rawCopper);
        if not self.DB.CoinSpentBeforeShadowlands then
            self.DB.CoinSpentBeforeShadowlands = rawCopper;
        end

        local diff = rawCopper - self.DB.CoinSpentBeforeShadowlands;
        self.widgets.CoinsSpentSinceShadowlands:SetAmount(diff);
    else
        copperLifetime = 0;
    end
end



---- Barbershop Costs and Locations ----
local COPPER_PER_SILVER = 100;
local SILVER_PER_GOLD = 100;


local L = Narci.L;
local FormatTime = NarciAPI.FormatTime;

NarciBarberShopStatsMoneyFrameMixin = {};

function NarciBarberShopStatsMoneyFrameMixin:SetLabel(label)
    self.Label:SetText(label)
end

function NarciBarberShopStatsMoneyFrameMixin:SetAmount(rawCopper)
	local gold = math.floor(rawCopper / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = math.floor((rawCopper - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
    local copper = math.fmod(rawCopper, COPPER_PER_SILVER);
    self.Gold:SetText(gold);
    self.Silver:SetText(silver);
    self.Copper:SetText(copper);
end


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
    self.Label:SetTextColor(1, 0.82, 0);
end

function NarciBarberShopStatsLocationFrameMixin:StopTimer()
    self:SetScript("OnUpdate", nil);
    self.activeOnShow = false;
    self.Label:SetTextColor(0.8, 0.8, 0.8);
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
