local _, addon = ...

local DataProvider = addon.DragonridingRaceDataProvider;
local TourPOI = DataProvider.TourPOI;

local WorldMapFrame = WorldMapFrame;

local ENABLE_MAP_PIN = false;

local WorldMapWidget;

local function AreaPOIPin_OnMouseOver(event, self, tooltipShown, poiID, name)
    print(tooltipShown, poiID, name)
    if not (tooltipShown and poiID and TourPOI[poiID]) then return end;

    local mapID = self:GetMap():GetMapID();
    GameTooltip:AddDoubleLine("MapID", mapID);

    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID);
    if poiInfo then
        local x, y = poiInfo.position:GetXY();
        GameTooltip:AddDoubleLine("X Coord.", x);
        GameTooltip:AddDoubleLine("Y Coord.", y);

        if false then
            local point = {
                uiMapID = mapID,
                position = poiInfo.position:Clone();
            };
            C_Map.SetUserWaypoint(point);

            local posVector = C_Map.GetUserWaypointPositionForMap(12);
            if posVector then
                GameTooltip:AddLine("World Map Position:");
                x, y = posVector:GetXY();
                GameTooltip:AddDoubleLine("X Coord.", x);
                GameTooltip:AddDoubleLine("Y Coord.", y);
                print(x, y)
            end
        end
    end


    GameTooltip:Show();
end

--EventRegistry:RegisterCallback("AreaPOIPin.MouseOver", AreaPOIPin_OnMouseOver, {});


local PIN_TEMPLATE_NAME = "NarciWorldMapPinTemplate";
local PinUtil = {};

function PinUtil:GetPinPool()
    if not self.pool then
        local wm = WorldMapFrame;
        if wm and wm.pinPools and wm.pinPools[PIN_TEMPLATE_NAME] then
            self.pool = wm.pinPools[PIN_TEMPLATE_NAME];
        else
            local pool = {};
            self.pool = pool;

            function pool:EnumerateActive()
                return pairs({})
            end
        end
    end

    return self.pool
end

function PinUtil:HighlightPinByPOIID(poiID)
    local anyMatch;

    for pin in self:GetPinPool():EnumerateActive() do
        if pin.poiID == poiID then
            pin:Focus();
            anyMatch = true;
        else
            pin:Unfocus();
        end
    end

    if anyMatch then

    end
end

function PinUtil:ResetPinVisual()
    for pin in self:GetPinPool():EnumerateActive() do
        pin:ResetVisual();
    end
end



local NarciWorldMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function NarciWorldMapDataProviderMixin:GetPinTemplate()
	return "NarciWorldMapPinTemplate";
end

function NarciWorldMapDataProviderMixin:OnShow()
	--self:RegisterEvent("AREA_POIS_UPDATED");
end

function NarciWorldMapDataProviderMixin:OnHide()
	--self:UnregisterEvent("AREA_POIS_UPDATED");
end

function NarciWorldMapDataProviderMixin:OnEvent(event, ...)
	if event == "AREA_POIS_UPDATED" then

	end
end

function NarciWorldMapDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate(self:GetPinTemplate());
end

function NarciWorldMapDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();
	local mapID = self:GetMap():GetMapID();

    if DataProvider:ShouldShowWorldMapWidget(mapID) then
        DataProvider:SetCurrentContinent(mapID);
        WorldMapWidget:Refresh(mapID);
        if ENABLE_MAP_PIN then
            NarciWorldMapDataProviderMixin:ShowAllPins();
        end
    else
        WorldMapWidget:Hide();
    end
end

function NarciWorldMapDataProviderMixin:ShowMapPinByPOIID(poiID)
    local x, y = TourPOI[poiID].cx, TourPOI[poiID].cy;

    local template = "NarciWorldMapPinTemplate";
    local uiMapID = TourPOI[poiID].mapID;

    local courseName = DataProvider:GetPOIName(poiID);
    local mapName = DataProvider:GetMapName(uiMapID);

    local poiInfo = {
        atlasName = "racing",
        name = mapName,
        description = courseName,
        poiID = poiID,
        isAlawysOnFlightmap = false,
        shouldGlow = false,
        isPrimaryMapForPOI = true,
        position = CreateVector2D(x, y)
    };

    --[[
    local dataProvider;
    for dp in pairs(WorldMapFrame.dataProviders) do
        if dp.GetPinTemplate and dp:GetPinTemplate() == template then
            dataProvider = dp;
        end
    end
    --]]

    poiInfo.dataProvider = NarciWorldMapDataProviderMixin;

    local pin = WorldMapFrame:AcquirePin(template, poiInfo);
end

function NarciWorldMapDataProviderMixin:ShowAllPins()
    self:RemoveAllData();
    for i, poiID in ipairs( DataProvider:GetPOIsForCurrentContinent() ) do
        self:ShowMapPinByPOIID(poiID);
    end
end


local PIN_SIZE_NORMAL = 18;
local PIN_SIZE_FOCUSED = 24;

NarciWorldMapPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_AREA_POI");    --PIN_FRAME_LEVEL_WORLD_QUEST, PIN_FRAME_LEVEL_VIGNETTE

function NarciWorldMapPinMixin:SetTexture(poiInfo)

end

function NarciWorldMapPinMixin:OnMouseLeave()
    BaseMapPoiPinMixin.OnMouseLeave(self);
    --self:Unfocus();
end

function NarciWorldMapPinMixin:OnMouseEnter()
    BaseMapPoiPinMixin.OnMouseEnter(self);
    --self:Focus();

    if WorldMapWidget then
        WorldMapWidget:HoverListButtonByPOI(self.poiID);
    end
end

function NarciWorldMapPinMixin:Focus()
    self.GlowTexture:Show();
    self.AnimGlow:Stop();
    self.AnimGlow:Play();
    self.Texture:SetSize(PIN_SIZE_FOCUSED, PIN_SIZE_FOCUSED);
    self:SetAlpha(1);
end

function NarciWorldMapPinMixin:Unfocus()
    self.GlowTexture:Hide();
    self.AnimGlow:Stop();
    self.Texture:SetSize(PIN_SIZE_NORMAL, PIN_SIZE_NORMAL);
    self:SetAlpha(0.5);
end

function NarciWorldMapPinMixin:ResetVisual()
    self.GlowTexture:Hide();
    self.AnimGlow:Stop();
    self.Texture:SetSize(PIN_SIZE_NORMAL, PIN_SIZE_NORMAL);
    self:SetAlpha(1);
end

function NarciWorldMapPinMixin:OnAcquired(poiInfo)
	self.name = poiInfo.name;
	self.description = poiInfo.description;
	self.widgetSetID = poiInfo.widgetSetID;
	self.textureKit = poiInfo.uiTextureKit;
    self.poiID = poiInfo.poiID;

	self:SetPosition(poiInfo.position:GetXY());

    self:SetSize(24, 24);
    self.Texture:SetSize(PIN_SIZE_NORMAL, PIN_SIZE_NORMAL);

    if DataProvider:IsCourseGold(self.poiID) then
        self.Texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\MapPin-RacingFlag");
    else
        self.Texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\MapPin-RacingFlag-RedDot");
    end

    self.HighlightTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\MapPin-RacingFlag");
    self.GlowTexture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\MapPin-RacingFlag-Glow");
end


local MapController = {};
local inOutSine = addon.EasingFunctions.inOutSine;

function MapController:SetMapPan(x, y)
    local scrollContainer = WorldMapFrame.ScrollContainer;
    local scale = scrollContainer.targetScale;
    scrollContainer.targetScrollX = x;
    scrollContainer.targetScrollY = y;
    scrollContainer.currentScrollX = x;
    scrollContainer.currentScrollY = y;

    scrollContainer:SetNormalizedHorizontalScroll(x);
    scrollContainer:SetNormalizedVerticalScroll(y);
end

function MapController:GetProcessor()
    if not self.p then
        self.p = CreateFrame("Frame", nil, WorldMapFrame);
        self.p:Hide();
        self.p.t = -1;

        self.p:SetScript("OnHide", function()
            self.p:Hide();
        end);

        self.p:SetScript("OnUpdate", function(p, elapsed)
            p.t = p.t + elapsed;

            if p.t < 0 then
                return
            end


            local x = inOutSine(p.t, p.fromX, p.toX, p.d);
            local y = inOutSine(p.t, p.fromY, p.toY, p.d);
        
            if p.t >= p.d then
                p:Hide();
                x = p.toX;
                y = p.toY;
            end
        
            self:SetMapPan(x, y);
        end);
    end

    return self.p
end

function MapController:SmoothPanTo(x, y, useDelay)
    local p = self:GetProcessor();
    local x0, y0 = WorldMapFrame.ScrollContainer.targetScrollX, WorldMapFrame.ScrollContainer.targetScrollY;
    local mapWidth, mapHeight = WorldMapFrame.ScrollContainer.Child:GetSize();
    local distance = math.sqrt( (mapWidth*(x-x0))^2 + (mapHeight*(y - y0))^2 );

    if distance <= 2 then
        p:Hide();
        return
    end

    local duration = distance / 600;

    if duration > 1 then
        duration = 1;
    elseif duration < 0.4 then
        duration = 0.4;
    end

    p.t = (useDelay and -0.08) or 0;
    p.fromX, p.fromY = x0, y0;
    p.toX, p.toY = x, y;
    p.d = duration;
    p:Show();
end

function MapController:StopPanQueue()
    local p = self:GetProcessor();
    if p.t < 0 then
        p:Hide();
    end
end

local function Clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

function MapController:SmoothPanToPOI(poiID, useDelay)
    --Attemp to center 
    local scrollContainer = WorldMapFrame.ScrollContainer;
    --scrollContainer:SetZoomTarget(2);

    local x, y = DataProvider:GetPOIContinentPosition(poiID);

    local childScale = scrollContainer.Child:GetScale();
    local childWidth = scrollContainer.Child:GetWidth();

    local offsetX = 100 / (childScale * childWidth);
    x = x - offsetX;

    x = Clamp(x, scrollContainer.scrollXExtentsMin, scrollContainer.scrollXExtentsMax);
	y = Clamp(y, scrollContainer.scrollYExtentsMin, scrollContainer.scrollYExtentsMax);

    --scrollContainer:SetPanTarget(x, y);
    MapController:SmoothPanTo(x, y, useDelay);
end


NarciWorldMapDragonridingRaceListButtonMixin = {};

function NarciWorldMapDragonridingRaceListButtonMixin:SetBlackText(state)
    if state then
        self.ButtonText:SetTextColor(0, 0, 0);
        self.ButtonText:SetShadowColor(1, 1, 1, 0);
    else
        self.ButtonText:SetTextColor(0.80, 0.80, 0.80);
        self.ButtonText:SetShadowColor(0, 0, 0, 1);
    end
end

function NarciWorldMapDragonridingRaceListButtonMixin:OnEnter()
    WorldMapWidget:HighlightButton(self);
    self:SetBlackText(true);

    WorldMapWidget:ShowRecordsForPOI(self.poiID);
    PinUtil:HighlightPinByPOIID(self.poiID);
    MapController:SmoothPanToPOI(self.poiID, true);
end

function NarciWorldMapDragonridingRaceListButtonMixin:OnLeave()
    WorldMapWidget:HighlightButton();
    self:SetBlackText(false);

    WorldMapWidget:ShowTournamentInfo();
    PinUtil:ResetPinVisual();
    MapController:StopPanQueue();
end

function NarciWorldMapDragonridingRaceListButtonMixin:OnClick(button)
    if button == "RightButton" then
        WorldMapWidget:HideScoreboard();
        return
    end

    if IsModifierKeyDown() then
        --So it can be triggered by both Shift or Ctrl Click --IsModifiedClick("QUESTWATCHTOGGLE")
        C_Map.SetUserWaypoint( DataProvider:GetPOIWaypoint(self.poiID) );
        C_SuperTrack.SetSuperTrackedUserWaypoint(true);
    end
end

function NarciWorldMapDragonridingRaceListButtonMixin:SetDataByPOI(poiID)
    if DataProvider:IsCourseGold(poiID) then
        self.RedDot:Hide();
    else
        self.RedDot:Show();
    end

    if poiID == self.poiID then
        return
    end

    self.poiID = poiID;
    self.ButtonText:SetWidth(160);
    self.ButtonText:SetText(DataProvider:GetPOIName(poiID));
    if self.ButtonText:IsTruncated() then
        self.ButtonText:SetWidth(150);
    end
end


local function SimpleIconButton_OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
end

local function SimpleIconButton_OnLeave(self)
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
end


NarciWorldMapDragonridingRaceUIMixin = {};

function NarciWorldMapDragonridingRaceUIMixin:OnLoad()
    WorldMapWidget = self;

    NarciWorldMapDragonridingRaceUI = self;

    local blurredTexture = self.BackgroundFrame.BlurredMap:CreateTexture(nil, "BACKGROUND", nil, -1);
    self.blurredTexture = blurredTexture;
    blurredTexture:Hide();

    local relativeTo = WorldMapFrame.ScrollContainer.Child;
    blurredTexture:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, 0);
    blurredTexture:SetPoint("BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", 0, 0);

    --Setup Scoreboard Toggle
    self.ToggleButton:SetScript("OnEnter", function(f)
        f.Icon:SetTexCoord(0.5, 0.875, 0, 0.375);
    end);

    self.ToggleButton:SetScript("OnLeave", function(f)
        f.Icon:SetTexCoord(0, 0.375, 0, 0.375);
    end);

    self.ToggleButton:SetScript("OnClick", function(f)
        self:ShowScoreboard();
    end);


    local button1 = self.ListFrame.CloseButton;
    SimpleIconButton_OnLeave(button1);
    button1:SetScript("OnEnter", SimpleIconButton_OnEnter);
    button1:SetScript("OnLeave", SimpleIconButton_OnLeave);
    button1:SetScript("OnClick", function()
        self:HideScoreboard();
    end);


    --Pin Toggle
    local button2 = self.ListFrame.PinToggle;
    SimpleIconButton_OnLeave(button2);
    button2:SetScript("OnEnter", SimpleIconButton_OnEnter);
    button2:SetScript("OnLeave", SimpleIconButton_OnLeave);
    button2:SetScript("OnClick", function()
        self:EnableMapPin(not ENABLE_MAP_PIN);
    end);

    self:EnableMapPin(NarcissusDB.DragonridingTourWorldMapPin);
end

function NarciWorldMapDragonridingRaceUIMixin:EnableMapPin(state)
    if state == nil then
        state = true;
    end

    if state then
        self.ListFrame.PinToggle.Icon:SetTexCoord(0.5, 1, 0, 1);
    else
        self.ListFrame.PinToggle.Icon:SetTexCoord(0, 0.5, 0, 1);
    end

    ENABLE_MAP_PIN = state;
    NarcissusDB.DragonridingTourWorldMapPin = state;

    if self:IsVisible() then
        NarciWorldMapDataProviderMixin:RefreshAllData();
    end
end

function NarciWorldMapDragonridingRaceUIMixin:ShowScoreboard()
    self.ToggleButton:Hide();
    self:Refresh();
    self:EnableMouse(true);
end

function NarciWorldMapDragonridingRaceUIMixin:HideScoreboard()
    self.ToggleButton:Show();
    self:Refresh();
    self:EnableMouse(false);
end

function NarciWorldMapDragonridingRaceUIMixin:Refresh(mapID)
    if not mapID then
        mapID = WorldMapFrame:GetMapID();
    end

    if mapID then
        local poiList = DataProvider:GetPOIsForContinent(mapID);
        if poiList and #poiList > 0 then
            if self.ToggleButton:IsShown() then
                self.blurredTexture:Hide();
                self.BackgroundFrame:Hide();
                self.ListFrame:Hide();
            else
                DataProvider:UpdateAllRecords();

                local padding = 4;
                local footerHeight = 28;
                local headerHeight = 48;

                if not self.listButtons then
                    self.listButtons = {};
                end

                local button;
                local poiID;
                local total = #poiList;
                for i = 1, total do
                    button = self.listButtons[i];
                    if not button then
                        button = CreateFrame("Button", nil, self.ListFrame, "NarciWorldMapDragonridingRaceListButtonTemplate");
                        button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, (i - 1)*20 + padding + footerHeight);
                        self.listButtons[i] = button;
                    end
                    poiID = poiList[total - i + 1];
                    button:SetDataByPOI(poiID);
                    button:Show();
                end

                for i = total + 1, #self.listButtons do
                    self.listButtons[i]:Hide();
                end

                self:SetHeight(total * 20 + padding * 2 + headerHeight + footerHeight);
                self.blurredTexture:Show();
                self.BackgroundFrame:Show();
                self.ListFrame:Show();
            end

            self:Show();
            return
        end
    end

    self:Hide();
    self.blurredTexture:Hide();
end

function NarciWorldMapDragonridingRaceUIMixin:OnEnter()

end

function NarciWorldMapDragonridingRaceUIMixin:OnLeave()

end

function NarciWorldMapDragonridingRaceUIMixin:HighlightButton(button)
    if self.lastButton then
        self.lastButton:SetBlackText(false);
        self.lastButton = nil;
    end
    self.lastButton = button;

    self.ListFrame.ButtonHighlight:ClearAllPoints();
    if button then
        self.ListFrame.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
        self.ListFrame.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
        self.ListFrame.ButtonHighlight:Show();
    else
        self.ListFrame.ButtonHighlight:Hide();
    end
end

function NarciWorldMapDragonridingRaceUIMixin:ShowRecordsForPOI(poiID)
    if poiID then
        local t1, t2;

        for i = 1, 3 do
            t1, t2 = DataProvider:GetAndCacheRecord(poiID, i);
            self.ListFrame.RecordFrame.TimeDisplays[i]:SetRecord(t1, t2);
        end
    else
        for i = 1, 3 do
            self.ListFrame.RecordFrame.TimeDisplays[i]:SetRecord();
        end
    end

    self.ListFrame.RecordFrame:Show();
    self.ListFrame.TournamentInfo:Hide();
end

function NarciWorldMapDragonridingRaceUIMixin:ShowTournamentInfo()
    self.ListFrame.RecordFrame:Hide();
    self.ListFrame.TournamentInfo:Show();

    local seconds = DataProvider:GetTournamentRemainingSeconds();
    self.ListFrame.TournamentInfo.DurationDisplay:SetCountdown(seconds);
end


function NarciWorldMapDragonridingRaceUIMixin:HoverListButtonByPOI(poiID)
    if self:IsVisible() then
        if self.listButtons then
            for i, button in ipairs(self.listButtons) do
                if button.poiID == poiID then
                    self:HighlightButton(button);
                    button:SetBlackText(true);
                else
                    button:SetBlackText(false);
                end
            end
        end
        WorldMapWidget:ShowRecordsForPOI(poiID);
    end
end

function NarciWorldMapDragonridingRaceUIMixin:OnMouseDown(button)
    if button == "RightButton" then
        self:HideScoreboard();
    end
end

function NarciWorldMapDragonridingRaceUIMixin:OnShow()
    --one-time
    local trpButton = TRP3_WorldMapButton;
    if trpButton then
        local height = trpButton:GetHeight();
        self.ToggleButton:ClearAllPoints();
        self.ToggleButton:SetPoint("BOTTOMLEFT", self:GetParent(), "BOTTOMLEFT", 8, height + 24);
        self.ToggleButton.Shade:Hide();

        self:SetFrameStrata("FULLSCREEN_DIALOG");
        self:SetFixedFrameStrata(true);
        self:SetFrameLevel(20);
    end

    self:SetScript("OnShow", nil);
end


NarciDragonridingRaceTimeDisplayMixin = {};

function NarciDragonridingRaceTimeDisplayMixin:OnLoad()
    local font = "Interface\\AddOns\\Narcissus\\Font\\OpenSans-SemiBold.ttf";
    local style = "";   --OUTLINE;

    self.LeftNum:SetFont(font, 18, style);
    self.RightNum:SetFont(font, 12, style);
    self.Label:SetFont(font, 12, style);

    self.LeftNum:SetTextColor(1, 1, 1);
    self.RightNum:SetTextColor(1, 1, 1);
    self.Label:SetTextColor(1, 1, 1);

    self.LeftNum:SetShadowOffset(2, -2);
    self.RightNum:SetShadowOffset(1, -1);
    self.Label:SetShadowOffset(1, -1);

    self:SetHorizontalGap(-3);
end

function NarciDragonridingRaceTimeDisplayMixin:Layout()
    local width = self.RightNum:GetWidth() + self.LeftNum:GetWidth() + self.hGap;
    self:SetWidth(width);
end

function NarciDragonridingRaceTimeDisplayMixin:SetRecord(record, standard)
    local diff;
    local grey;

    if (not record) or (record == 0) then
        self.LeftNum:SetText("--\"");
        self.RightNum:SetText("--");
        grey = true;
        if standard then
            diff = string.format("|cffdd4e4e%.3f|r", standard);
        end
    else
        local n1 = math.floor(record);
        local n2 = 1000*(record - n1);

        if standard then
            diff = record - standard;
            if diff <= 0 then   --green
                if diff < 0 then
                    diff = -diff;
                end
                diff = string.format("|cff80ce94-%.3f|r", diff);
                grey = false;
            else    --red untimed
                diff = string.format("|cffdd4e4e+%.3f|r", diff);
                grey = true;
            end
            
        else
            grey = false;
        end

        if n2 == 0 then
            n2 = "000";
        elseif n2 < 9 then
            n2 = string.format("00%.0f", n2)
        elseif n2 < 100 then
            n2 = string.format("0%.0f", n2)
        else
            n2 = string.format("%.0f", n2)
        end

        self.LeftNum:SetText(n1.."\"");
        self.RightNum:SetText(n2);
    end

    if grey then
        self.LeftNum:SetTextColor(0.67, 0.67, 0.67);
        self.RightNum:SetTextColor(0.67, 0.67, 0.67);
    else
        self.LeftNum:SetTextColor(1, 1, 1);
        self.RightNum:SetTextColor(1, 1, 1);
    end

    if not diff then
        diff = "|cffaaaaaan/a|r";
    end

    self.Label:SetText(diff);

    self:Layout();
end


function NarciDragonridingRaceTimeDisplayMixin:SetCountdown(seconds, labelText)
    if labelText then
        self.Label:SetText(labelText);
    end

    if seconds then
        local value, unit, fallbackUnit;
        local redText = seconds < 172800;

        if seconds > 86400 then
            value = math.floor(seconds / 86400 + 0.5);
            fallbackUnit = "DAYS";
            if value > 1 then
                unit = Narci.L["Day Plural"];
            else
                unit = Narci.L["Day Singular"];
            end
        else
            value = math.floor(seconds / 3600);
            if value > 1 then
                unit = Narci.L["Hour Plural"];
            else
                unit = Narci.L["Hour Singular"];
            end
            fallbackUnit = "HOURS";
        end

        if unit then
            unit = string.upper(unit);
        else
            unit = fallbackUnit;
        end

        self.LeftNum:SetText(value);
        self.RightNum:SetText(unit);

        if redText then
            self.LeftNum:SetTextColor(1, 0.502, 0.251);  --The Color of Limited Time Set --0.94, 0.302, 0.302
            self.RightNum:SetTextColor(1, 0.502, 0.251);
        else
            self.LeftNum:SetTextColor(0.8, 0.8, 0.8);
            self.RightNum:SetTextColor(0.8, 0.8, 0.8);
        end

        self:Layout();
    end
end

function NarciDragonridingRaceTimeDisplayMixin:SetHorizontalGap(gap)
    self.RightNum:SetPoint("BOTTOMLEFT", self.LeftNum, "BOTTOMRIGHT", gap, 0);
    self.hGap = gap;
end


do
    local function CheckActiveTournament()
        --Must be used after game loading process
        local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();
        C_Calendar.SetAbsMonth(currentCalendarTime.month, currentCalendarTime.year);
        C_Calendar.OpenCalendar();


        C_Timer.After(2, function()
            local tourLocalizedName, remainingSeconds, tourLabel = DataProvider:GetActiveTournamentInfo();
            local enable = (tourLocalizedName ~= nil);
            if enable then
                local overlay = CreateFrame("Frame", nil, WorldMapFrame, "NarciWorldMapDragonridingRaceUITemplate");
                overlay:SetPoint("BOTTOMLEFT", WorldMapFrame:GetCanvasContainer(), "BOTTOMLEFT", 0, 1);

                local durationDisplay = overlay.ListFrame.TournamentInfo.DurationDisplay;
                local icon = "|TInterface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\ClockIcon:0:0:0:1:32:32:0:32:0:32:172:172:172|t";
                durationDisplay.Label:SetText(icon.." "..tourLocalizedName);
                durationDisplay.Label:SetTextColor(0.67, 0.67, 0.67);
                durationDisplay:SetHorizontalGap(4);
                overlay:ShowTournamentInfo();

                WorldMapFrame:AddDataProvider(NarciWorldMapDataProviderMixin);
                WorldMapWidget.blurredTexture:SetTexture(string.format("Interface\\AddOns\\Narcissus\\Art\\Modules\\DragonridingRaces\\BlurredMap-%s", tourLabel), nil, nil, "TRILINEAR"); --Resize to 768x512 then Gaussian radius 3
            end
        end);
    end

    addon.AddLoadingCompleteCallback(CheckActiveTournament);
end


--[[
local function GetMapPinDataProviderByTemplateName(template)
    for dp in pairs(WorldMapFrame.dataProviders) do
        if dp.GetPinTemplate and dp:GetPinTemplate() == template then
            return dp
        end
    end
end

local function VignettePinDataProvider_Callback()
    print("Update Pin")
end

local function HookVignetteDataProvider()
    local dp = GetMapPinDataProviderByTemplateName("VignettePinTemplate");
    if dp then
        hooksecurefunc(dp, "RefreshAllData", VignettePinDataProvider_Callback);
    end
end

local function VignettePin_OnMouseEnter(self)
    local id = self.GetVignetteID and self:GetVignetteID();
    if id then
        if GameTooltip:IsVisible() then
            GameTooltip:AddDoubleLine("VignetteID", id);
            GameTooltip:Show();
        end
    end
end

local HOOKED_VIGNETTE_PINS = {};

local function PinPool_OnAcquire()
    for pin in WorldMapFrame.pinPools["VignettePinTemplate"]:EnumerateActive() do
        if not (HOOKED_VIGNETTE_PINS[pin]) then
            HOOKED_VIGNETTE_PINS[pin] = true;
            if pin.OnMouseEnter then
                hooksecurefunc(pin, "OnMouseEnter", VignettePin_OnMouseEnter);
            end
        end
    end
end

local function HookMapPinPoolByTemplate(pinTemplate)
    local f = WorldMapFrame;
    if f and f.pinPools then
        if f.pinPools[pinTemplate] then
            hooksecurefunc(f.pinPools[pinTemplate], "Acquire", PinPool_OnAcquire);
            print("Success")
            return
        end
    end
end

local function InitializeVignettePinPool()
    local pinTemplate = "VignettePinTemplate";
    local vignetteGUID = "Vignette-0-0-0-0-0-0000000000";
    local vignetteInfo = {};
    local frameIndex = 1;

    HookMapPinPoolByTemplate(pinTemplate);
end
--]]