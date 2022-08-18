local _, addon = ...

local DECIMAL = "%.1f";
local THRESHHOLD_ACTIVE = 0.04;
local THRESHHOLD_DORMANT = 0.2;
local THRESHHOLD_TRAILS = 2;
local NUM_TRAILS = 6;
local format = string.format;

local UIFrameFadeIn = UIFrameFadeIn;
local UIFrameFadeOut = UIFrameFadeOut;
local After = C_Timer.After;
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition;
local GetBestMapForUnit = C_Map.GetBestMapForUnit;
local GetMapInfo = C_Map.GetMapInfo;
local GetMapArtLayerTextures = C_Map.GetMapArtLayerTextures;
local GetExploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures;
local IsIndoors = IsIndoors;
local GetPlayerFacing = GetPlayerFacing;

local PositionFrame;
local MapFrame;
local positionTable;

local upper = string.upper;
local max = math.max;
local min = math.min;
local ceil = math.ceil;
local sqrt = math.sqrt;

local outSine = addon.EasingFunctions.outSine;
local inOutSine = addon.EasingFunctions.inOutSine;


local ScaleAnim1 = NarciAPI_CreateAnimationFrame(0.35);
ScaleAnim1:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local scale = outSine(self.total, self.fromScale, self.toScale, self.duration);
    if self.total >= self.duration then
        self:Hide()
        scale = self.toScale;
    end
    self.frame:SetZoomLevel(scale);
end)

local function SmoothScaleFast(frame, fromScale, toScale)
    frame.finalZoomLevel = toScale;
    ScaleAnim1:Hide();
    ScaleAnim1.frame = frame;
    ScaleAnim1.total = 0;
    ScaleAnim1.fromScale = fromScale;
    ScaleAnim1.toScale = toScale;
    ScaleAnim1:Show();
end

local ScaleAnim2 = NarciAPI_CreateAnimationFrame(1);
ScaleAnim2:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local scale = inOutSine(self.total, self.fromScale, self.toScale, self.duration);
    if self.total >= self.duration then
        self:Hide()
        scale = self.toScale;
    end
    self.frame:SetZoomLevel(scale);
end)

local function SmoothScaleSlow(frame, fromScale, toScale)
    frame.finalZoomLevel = toScale;
    ScaleAnim2:Hide();
    ScaleAnim2.frame = frame;
    ScaleAnim2.total = 0;
    ScaleAnim2.fromScale = fromScale;
    ScaleAnim2.toScale = toScale;
    ScaleAnim2:Show();
end

--Get coordinates when pressing ALT+Z
NarciPlayerPositionFrameMixin = {};

function NarciPlayerPositionFrameMixin:OnLoad()
    PositionFrame = self;
    
    self.t = 0;
    self.gate = THRESHHOLD_DORMANT;
end

function NarciPlayerPositionFrameMixin:OnShow()

end

function NarciPlayerPositionFrameMixin:OnHide()
    self.t = 0;
end

function NarciPlayerPositionFrameMixin:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.gate then
        self.t = 0;
        self:GetPlayerPosition();
    end
end

function NarciPlayerPositionFrameMixin:UpdateText(object, str)
    UIFrameFadeOut(object, 0.15, object:GetAlpha(), 0);
    UIFrameFadeOut(self.MapFrame.MapTextFrame.MinimapNameHighlight, 0.15, self.MapFrame.MapTextFrame.MinimapNameHighlight:GetAlpha(), 0);
    if str then
        After(0.15, function()
            object:SetText(str);
            UIFrameFadeIn(object, 0.15, 0, 1);
            UIFrameFadeIn(self.MapFrame.MapTextFrame.MinimapNameHighlight, 0.15, 0, 1);
        end)
    end
end

function NarciPlayerPositionFrameMixin:GetPlayerPosition()
    local mapID = GetBestMapForUnit("player");
    if mapID then
        positionTable = GetPlayerMapPosition(mapID, "player");
        if not positionTable then return end;
        local x = positionTable.x or 0;
        local y = positionTable.y or 0;
        self.MapFrame.MapTextFrame.Coordinates:SetText( format(DECIMAL, 100 * x) .." , ".. format(DECIMAL, 100 * y) );

        local mapInfo = GetMapInfo(mapID);
        local zoneName = GetMinimapZoneText();

        if zoneName ~= self.zoneName then
            self.zoneName = zoneName;
            if zoneName == self.mapName then
                zoneName = nil;
            end
            self:UpdateText(self.MapFrame.MapTextFrame.MinimapName, zoneName);
        end
        if mapID ~= self.mapID and mapInfo then
            local mapName = mapInfo.name;
            self.mapID = mapID;
            self.mapName = mapName;
            self.MapFrame.MapTextFrame.MapName:SetText(upper(mapName));

            MapFrame:SetCurrentMap();
        end
    end
end

function NarciPlayerPositionFrameMixin:OnEvent(event)

end


local ZOOM_PER_LEVEL = 0.75;
local ZOOM_LEVEL_MAX = 1;

local function GetScaleByZoomLevel(level)
    return math.pow(ZOOM_PER_LEVEL, level)
end

local ZOOM_LEVEL_MIN = GetScaleByZoomLevel(5);

local DataProvider;
NarciWorldMapMixin = {};

function NarciWorldMapMixin:OnLoad()
    MapFrame = self;
    self.Canvas = self.ClipContainer.Canvas;
    self.Pin = self.Canvas.Pin;

    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "shadowLargeR0", 1);

    local Pin = self.Pin;
    Pin:SetTexture("Interface/AddOns/Narcissus/Art/Modules/ScreenshotTool/Map/Pin", nil, nil, "TRILINEAR");
    Pin:SetDrawLayer("OVERLAY", 4);

    self.numTileAlongX = 4;
    self.numTileAlongY = 3;
    self.Canvas:SetSize(256 * 4, 256 * 3);

    self.zoomLevel = 1;
    self.finalZoomLevel = 1;

    --Data Provider
    DataProvider = CreateFrame("Frame", nil, self);
    DataProvider:Hide();
    self.DataProvider = DataProvider;
    DataProvider.t = THRESHHOLD_TRAILS;
    DataProvider:SetScript("OnUpdate", function(DataProvider, elapsed)
        self:UpdateMapAndPinOffset();

        --Create Trails
        --[[
        DataProvider.t = DataProvider.t + elapsed;
        if DataProvider.t >= THRESHHOLD_TRAILS then
            DataProvider.t = 0;
            self:SetNewTrail();
        end
        --]]
    end)

    DataProvider:SetScript("OnShow", function()
        --print("ON")
        PositionFrame.gate = THRESHHOLD_ACTIVE;
    end)

    DataProvider:SetScript("OnHide", function()
        --print("OFF")
        PositionFrame.gate = THRESHHOLD_DORMANT;
    end)

    --Trails
    self:CreateTrailPool(NUM_TRAILS);
end

function NarciWorldMapMixin:UpdateOffsetRange()
    self.maxOffsetX = self.layerWidth - 64 /self.zoomLevel;
    self.maxOffsetY = self.layerHeight - 64 /self.zoomLevel;
    self:UpdateMapAndPinOffset();
end

function NarciWorldMapMixin:SetZoomLevel(zoomLevel)
    self.Canvas:SetScale(zoomLevel);
    self.zoomLevel = zoomLevel;
    local normalizedSize;
    if zoomLevel < 1 then
        normalizedSize = 28* 1/sqrt(zoomLevel);
    else
        normalizedSize = 28* 1/zoomLevel;
    end
    self.Canvas.Pin:SetSize(normalizedSize, normalizedSize);
    self:UpdateOffsetRange();
end

function NarciWorldMapMixin:FindBestZoomLevelForIndoors()
    if IsIndoors() then
        self.isIndoors = true;
        self:UpdateScale(ZOOM_LEVEL_MAX);
    else
        self:UpdateScale(GetScaleByZoomLevel(4));
    end
end

function NarciWorldMapMixin:FindBestZoomLevelForMap(mapWidth)
    local zoomLevel;
    if mapWidth and mapWidth > 1500 then
        self.isLastMapLarge = true;
        zoomLevel = GetScaleByZoomLevel(5);
        self:SetZoomLevel(zoomLevel);
        self.finalZoomLevel = zoomLevel;
    else
        if self.isLastMapLarge then
            zoomLevel = GetScaleByZoomLevel(4);
            self.isLastMapLarge = nil;
            self:SetZoomLevel(zoomLevel);
            self.finalZoomLevel = zoomLevel;
        end
    end
end

function NarciWorldMapMixin:UpdateScale(newZoomLevel)
    if newZoomLevel > ZOOM_LEVEL_MAX then
        newZoomLevel = ZOOM_LEVEL_MAX;
    elseif newZoomLevel < ZOOM_LEVEL_MIN then
        newZoomLevel = ZOOM_LEVEL_MIN;
    end

    SmoothScaleSlow(self, self.zoomLevel, newZoomLevel);
end

function NarciWorldMapMixin:OnMouseWheel(delta)
    local newZoomLevel;
    if delta > 0 then
        newZoomLevel = min(self.finalZoomLevel / ZOOM_PER_LEVEL, ZOOM_LEVEL_MAX);
    else
        newZoomLevel = max(self.finalZoomLevel * ZOOM_PER_LEVEL, ZOOM_LEVEL_MIN);
    end

    SmoothScaleFast(self, self.zoomLevel, newZoomLevel);
    print(delta)
end

function NarciWorldMapMixin:AcquireBaseTextures()
    local a, b = self.numTileAlongX, self.numTileAlongY;
    local tex;
    if not self.baseTexs then
        self.baseTexs = {}
    end
    local texs = self.baseTexs;

    for i = 1, (a * b) do
        tex = texs[i];
        if not tex then
            tex = self.Canvas:CreateTexture(nil, "ARTWORK");
            tex:SetSize(self.tileSizeX, self.tileSizeY);
            tinsert(texs, tex);
        end
        if i == 1 then
            tex:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", 0, 0);
        elseif i % a == 1 then
            tex:SetPoint("TOPLEFT", texs[i - a], "BOTTOMLEFT", 0, 0);
        else
            tex:SetPoint("TOPLEFT", texs[i - 1], "TOPRIGHT", 0, 0);
        end
    end

    return texs
end


function NarciWorldMapMixin:AcquireTexureByIndex(index)
    if not self.overlayTexs then
        self.overlayTexs = {};
    end

    if self.overlayTexs[index] then
        return self.overlayTexs[index]
    else
        local tex = self.Canvas:CreateTexture(nil, "ARTWORK", 2);
        self.overlayTexs[index] = tex;
        return tex
    end
end

function NarciWorldMapMixin:HideUnusedTexture(childFrame, fromIndex)
    local texs = childFrame.texs;
    if texs then
        for i = fromIndex, #texs do
            texs[i]:SetAlpha(0);
        end
    end
end

function NarciWorldMapMixin:GetTexturePool(childFrame)
    return childFrame.texs
end

function NarciWorldMapMixin:GetNumTextures()
    local childFrame = self.OverlayFrame
    if childFrame.texs then
        return #childFrame.texs
    else
        return 0
    end
end

function NarciWorldMapMixin:CreateTrailPool(numTrails)
    if not self.trails then
        self.trails = {};
    end
    local trails = self.trails;
    local trail;
    for i = 1, numTrails do
        trail = trails[i];
        if not trail then
            trail = self:CreateTexture(nil, "OVERLAY", nil, 2);
            tinsert(trails, trail);
            trail:SetSize(18, 18);
            trail:SetTexture("Interface/AddOns/Narcissus/Art/Modules/ScreenshotTool/Map/Trail", nil, nil, "TRILINEAR");
        end
    end
    self.numTrails = numTrails;
    self.nextTrailIndex = 1;
end

function NarciWorldMapMixin:UpdateTrailSize()

end

function NarciWorldMapMixin:AcquireTrailTexture()
    local index = self.nextTrailIndex;
    local tex = self.trails[index];
    if index + 1 > self.numTrails then
        self.nextTrailIndex = 1;
    else
        self.nextTrailIndex = index + 1;
    end
    UIFrameFadeOut(tex, 0.5, 1, 0);
    return tex
end

function NarciWorldMapMixin:SetOffset(x, y)
    local minOffset = 64/self.zoomLevel;
    
    if x >= self.maxOffsetX then
        x = self.maxOffsetX
    end

    if x <= minOffset then
        x = minOffset;
    end

    if y >= self.maxOffsetY then
        y = self.maxOffsetY;
    end

    if y <= minOffset then
        y = minOffset;
    end

    self.Canvas:ClearAllPoints();
    self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", minOffset - x, y - minOffset);     --Tile Size / 2
end

function NarciWorldMapMixin:UpdateMapAndPinOffset()
    if not self.mapID or not positionTable then
        DataProvider:Hide();
        return
    end

    self.offsetX = (positionTable.x or 0) * self.layerWidth;
    self.offsetY = (positionTable.y or 0) * self.layerHeight;

    if self.isMoving or true then
        self:SetOffset(self.offsetX, self.offsetY);
    end
    self.Canvas.Pin:ClearAllPoints();
    self.Canvas.Pin:SetPoint("CENTER", self.Canvas, "TOPLEFT", self.offsetX, - self.offsetY);
    self.Canvas.Pin:SetRotation(GetPlayerFacing() or 0);
end

function NarciWorldMapMixin:SetNewTrail()
    local trail = self:AcquireTrailTexture();
    local x, y = self.offsetX or 0, self.offsetY or 0;
    y = -y;
    
    After(0.5, function()
        trail:ClearAllPoints();
        trail:SetPoint("CENTER", self, "TOPLEFT", x, y);
        trail:SetRotation(GetPlayerFacing() or 0);
        UIFrameFadeIn(trail, 0.5, 0, 1);
    end)
end

function NarciWorldMapMixin:SetCurrentMap(forceUpdate)
    local unit = "player";
    local mapID = GetBestMapForUnit(unit);
    if not mapID then return end
    positionTable = GetPlayerMapPosition(mapID, unit);
    if not positionTable then return end;
    local playerX = positionTable.x or 0;
    local playerY = positionTable.y or 0;

    if mapID ~= self.mapID or forceUpdate then
        self.mapID = mapID;
        
        local layers = C_Map.GetMapArtLayers(mapID);
        local layerInfo = layers[1];
        local layerWidth, layerHeight = layerInfo.layerWidth, layerInfo.layerHeight;
        local tileSizeX, tileSizeY = layerInfo.tileWidth, layerInfo.tileHeight;
        self.tileSizeX = tileSizeX;
        self.tileSizeY = tileSizeY;
        self.numTileAlongX = ceil(layerWidth / tileSizeX);
        self.numTileAlongY = ceil(layerHeight / tileSizeY);
        self.layerWidth = layerWidth;
        self.layerHeight = layerHeight;

        self:FindBestZoomLevelForMap(layerWidth);
        self:UpdateOffsetRange();

        local textures = GetMapArtLayerTextures(mapID, 1);    --LAYER_INDEX
        if not textures then return end
        local baseTextures = self:AcquireBaseTextures();
        local numPiece = #textures;
        local tex;
        for i = 1, numPiece do
            tex = baseTextures[i];
            tex:SetTexture( textures[i], nil, nil, "TRILINEAR");
            tex:SetAlpha(1);
            tex:SetDrawLayer("BORDER", 1);
        end
        --self:HideUnusedTexture(self.BaseFrame, numPiece + 1);
        

        --Overlay: Explored Area
        self.layerWidth, self.layerHeight = layerWidth, layerHeight;
        local exploredMapTextures = GetExploredMapTextures(mapID);
        local left, right, top, bottom;
        local overlayOffsetX, overlayOffsetY = 0, 0;

        if exploredMapTextures then
            local texIndex = 1;
            local textureWidth, textureHeight;
            local fileDataIDs;
            local tex, lastTex, lastRowTex;
            local numTex, numTexX, numTexY;
            for _, artInfo in pairs(exploredMapTextures) do
                textureWidth = artInfo.textureWidth;
                textureHeight = artInfo.textureHeight;
                if textureWidth and textureWidth ~= 0 then
                    numTexX = ceil(textureWidth / 256);
                    numTexY = ceil(textureHeight / 256);

                    overlayOffsetX = artInfo.offsetX;
                    overlayOffsetY = artInfo.offsetY;
                    fileDataIDs = artInfo.fileDataIDs;
                    numTex = #fileDataIDs;
                    --print(_, textureWidth, textureHeight)
                    for i = 1, numTex do
                        tex = self:AcquireTexureByIndex(texIndex);
                        tex:ClearAllPoints();
                        tex:SetTexture(fileDataIDs[i], nil, nil, "TRILINEAR");
                        tex:SetAlpha(1);
                        if i == 1 then
                            tex:SetWidth(256);
                            tex:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", overlayOffsetX, -overlayOffsetY);
                            lastRowTex = tex;
                        elseif i % numTexX == 1 then
                            tex:SetWidth(256);
                            tex:SetPoint("TOPLEFT", lastRowTex, "BOTTOMLEFT", 0, 0);
                            lastRowTex = tex;
                        else
                            if (i % numTexX == 0) then
                                tex:SetWidth(mod(textureWidth, 256));
                            else
                                tex:SetWidth(256);
                                tex:SetPoint("TOPLEFT", lastTex, "TOPRIGHT", 0, 0);
                            end
                        end

                        tex:SetDrawLayer("ARTWORK", 1);
                        lastTex = tex;
                        texIndex = texIndex + 1;
                    end
                end
            end

            --self:HideUnusedTexture(OverlayFrame, texIndex);
        else
            --self:HideUnusedTexture(OverlayFrame, 1);
        end

        self:FindBestZoomLevelForIndoors();
    end


    --1002, 668
    --Pin
    local offsetX = playerX * self.layerWidth;
    local offsetY = playerY * self.layerHeight;

    self:SetOffset(offsetX, offsetY);

    local pin = self.Canvas.Pin;
    pin:ClearAllPoints();
    pin:SetPoint("CENTER", self.Canvas, "TOPLEFT", offsetX, -offsetY);

    local degree = GetPlayerFacing();
    if degree then
        pin:SetRotation(degree)
    end
end

function NarciWorldMapMixin:OnShow()
    self:RegisterEvent("PLAYER_STARTED_MOVING");
    self:RegisterEvent("PLAYER_STOPPED_MOVING");
    self:RegisterEvent("PLAYER_STARTED_TURNING");
    self:RegisterEvent("PLAYER_STOPPED_TURNING");
    --
    self:RegisterEvent("MAP_EXPLORATION_UPDATED");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("ZONE_CHANGED_INDOORS");
    self:RegisterEvent("ZONE_CHANGED");
    --
    self:RegisterEvent("MINIMAP_UPDATE_ZOOM");
    
    -----------------------
    self:SetCurrentMap();
    self.isMoving = IsPlayerMoving();
    self.isTuring = IsMouselooking();
    if self.isMoving or self.isTuring then
        self.DataProvider:Show();
    end
end

function NarciWorldMapMixin:OnHide()
    self:UnregisterEvent("PLAYER_STARTED_MOVING");
    self:UnregisterEvent("PLAYER_STOPPED_MOVING");
    self:UnregisterEvent("PLAYER_STARTED_TURNING");
    self:UnregisterEvent("PLAYER_STOPPED_TURNING");
    --
    self:UnregisterEvent("MAP_EXPLORATION_UPDATED");
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
    self:UnregisterEvent("ZONE_CHANGED_INDOORS");
    self:UnregisterEvent("ZONE_CHANGED");
    --
    self:UnregisterEvent("MINIMAP_UPDATE_ZOOM");
end

local function StopDataProvider(a, b)
    if not (a or b) then
        DataProvider:Hide();
    end
end

function NarciWorldMapMixin:OnEvent(event)
    if event == "PLAYER_STARTED_TURNING" then
        self.isTuring = true;
        self.DataProvider:Show();
    elseif event == "PLAYER_STOPPED_TURNING" then
        self.isTuring = nil;
        if not self.isMoving then
            After(0.1, function()
                StopDataProvider(self.isMoving, self.isTuring);
            end)
        end
    elseif event == "PLAYER_STARTED_MOVING" then
        self.isMoving = true;
        self.DataProvider:Show();
    elseif event == "PLAYER_STOPPED_MOVING" then
        self.isMoving = nil;
        if not self.isTuring then
            After(0.1, function()
                StopDataProvider(self.isMoving, self.isTuring);
            end)
        end
    elseif event == "MAP_EXPLORATION_UPDATED" then
        After(0.05, function()
            self:SetCurrentMap(true);
        end)
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
        After(0.05, function()
            self:SetCurrentMap();
        end)
    elseif event == "ZONE_CHANGED" then
        local newMapID = GetBestMapForUnit("player");
        if newMapID ~= self.mapID then
            self:SetCurrentMap();
        end
    elseif event == "MINIMAP_UPDATE_ZOOM" then
        if self.isIndoors then
            if not IsIndoors() then
                self.isIndoors = nil;
                self:FindBestZoomLevelForIndoors();
            end
        else
            if IsIndoors() then
                self.isIndoors = true;
                self:FindBestZoomLevelForIndoors();
            end
        end
    end
end

function NarciWorldMapMixin:OnUpdate()

end

--[[
84 Stormwind
1165 Dazar'alor
/run Narci_MapFrame:Show();
/dump Narci_WorldMapFrame:GetNumTextures();
/run Narci_WorldMapFrame:SetCurrentMap()
/dump C_MapExplorationInfo.GetExploredMapTextures(118)
/run Narci_PlayerPositionFrame.Map.Overlay:SetTexture()

function MapCanvasMixin:RefreshDetailLayers()
	if not self.areDetailLayersDirty then return end;
	self.detailLayerPool:ReleaseAll();

	local layers = C_Map.GetMapArtLayers(self.mapID);
	for layerIndex, layerInfo in ipairs(layers) do
		local detailLayer = self.detailLayerPool:Acquire();
		detailLayer:SetAllPoints(self:GetCanvas());
		detailLayer:SetMapAndLayer(self.mapID, layerIndex);
		detailLayer:SetGlobalAlpha(self:GetGlobalAlpha());
		detailLayer:Show();
	end

	self:AdjustDetailLayerAlpha();

	self.areDetailLayersDirty = false;
end

    if exploredMapTextures then
        local textureWidth, textureHeight;
        for texIndex, artInfo in pairs(exploredMapTextures) do
            textureWidth = artInfo.textureWidth;
            textureHeight = artInfo.textureHeight;
            if textureWidth and textureWidth ~= 0 then
                left = artInfo.offsetX or 0;
                top = artInfo.offsetY or 0;
                right = left + textureWidth;
                bottom = top + textureHeight;
                left, right = left/layerWidth, right/layerWidth;
                top, bottom = top/layerHeight, bottom/layerHeight;
                --print(format(self.coordinatesFormat, texIndex, left, right, top, bottom))
                if left <= playerX and right >= playerX and top <= playerY and bottom >= playerY then
                    overlayTexture = artInfo.fileDataIDs[1];
                    overlayOffsetX = artInfo.offsetX;
                    overlayOffsetY = artInfo.offsetY;

                    local tex = self.OverlayFrame.tex1
                    tex:SetTexture(overlayTexture);
                    tex:ClearAllPoints();
                    tex:SetPoint("TOPLEFT", self.OverlayFrame, "TOPLEFT", overlayOffsetX, -overlayOffsetY);

                    local tex2 = self.OverlayFrame.tex2
                    tex2:SetTexture(artInfo.fileDataIDs[2]);
                    print(textureHeight)
                    tex2:SetWidth(textureWidth -256);
                    --tex2:SetTexCoord(0, textureWidth/256 -1, 0, textureHeight/256)
                    tex2:ClearAllPoints();
                    tex2:SetPoint("TOPLEFT", tex, "TOPRIGHT", 0, 0);

                    break
                end
            end
        end
    end
TestFrame:AddUnit("player", "Interface/AddOns/Narcissus/Art/Modules/ScreenshotTool/Map/Pin", 16, 16, 1, 1, 1, 1, 10, true)
--]]

