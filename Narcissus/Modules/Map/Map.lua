local _, addon = ...

local TILE_SIZE = 256;
local CANVAS_WIDTH, CANVAS_HEIGHT;

do
    local pixel = NarciAPI.GetPixelByScale(1);
    local scale = pixel;
    CANVAS_WIDTH, CANVAS_HEIGHT = (1004 - 4)*scale, (689 - 24)*scale;
end

local ceil = math.ceil;
local mod = math.fmod;

local MainFrame, Canvas;


local TilePool = {};
TilePool.tiles = {};

function TilePool:Release()
    self.i = 0;
    for i, tile in ipairs(self.tiles) do
        tile:ClearAllPoints();
        tile:SetTexture(nil);
        tile:Hide();
    end
end

function TilePool:Acquire()
    self.i = self.i + 1;
    if not self.tiles[self.i] then
        self.tiles[self.i] = Canvas:CreateTexture(nil, "ARTWORK");
        self.tiles[self.i]:SetSize(TILE_SIZE, TILE_SIZE);
    end
    return self.tiles[self.i];
end

function TilePool:GetCount()
    return self.i;
end

NarciMapMixin = {};

function NarciMapMixin:OnLoad()
    MainFrame = self;
    Canvas = self.Canvas;

    self:SetSize(CANVAS_WIDTH, CANVAS_HEIGHT);
    self.Canvas:SetSize(CANVAS_WIDTH, CANVAS_HEIGHT);


    self.RefreshButton:SetScript("OnClick", function()
        self:SetMapForPlayer();
    end);
end

function NarciMapMixin:SetMap(mapID)
    if not (mapID and C_Map.MapHasArt(mapID)) then return end;

    TilePool:Release();

	local layers = C_Map.GetMapArtLayers(mapID);
	for layerIndex, layerInfo in ipairs(layers) do
        local LAYER_WIDTH = layerInfo.layerWidth;
        local canvasScale = CANVAS_WIDTH/LAYER_WIDTH;
        Canvas:SetScale(canvasScale);

        local TILE_SIZE_WIDTH = layerInfo.tileWidth;
		local TILE_SIZE_HEIGHT = layerInfo.tileHeight;
        local numDetailTilesRows = ceil(layerInfo.layerHeight / TILE_SIZE_HEIGHT);
        local numDetailTilesCols = ceil(layerInfo.layerWidth / TILE_SIZE_WIDTH);
        local textures = C_Map.GetMapArtLayerTextures(mapID, layerIndex);

        local prevRowDetailTile;
        local prevColDetailTile;
        for tileCol = 1, numDetailTilesCols do
            for tileRow = 1, numDetailTilesRows do
                if tileRow == 1 then
                    prevRowDetailTile = nil;
                end
                local detailTile = TilePool:Acquire();
                local textureIndex = (tileRow - 1) * numDetailTilesCols + tileCol;
                detailTile:SetTexture(textures[textureIndex], nil, nil, "TRILINEAR");
                if prevRowDetailTile then
                    detailTile:SetPoint("TOPLEFT", prevRowDetailTile, "BOTTOMLEFT");
                else
                    if prevColDetailTile then
                        detailTile:SetPoint("TOPLEFT", prevColDetailTile, "TOPRIGHT");
                    else
                        detailTile:SetPoint("TOPLEFT", Canvas, "TOPLEFT");
                    end
                end
                detailTile:SetSize(TILE_SIZE, TILE_SIZE);
                detailTile:SetDrawLayer("BACKGROUND", -8 + layerIndex);
                detailTile:Show();
                prevRowDetailTile = detailTile;
                if tileRow == 1 then
                    prevColDetailTile = detailTile;
                end
            end
        end

        if false then
            break
        end
        
        local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
        if exploredMapTextures then
            local subLevel = 0;
            local drawLayer = "ARTWORK";

            for i, exploredTextureInfo in ipairs(exploredMapTextures) do
                local numTexturesWide = ceil(exploredTextureInfo.textureWidth/TILE_SIZE_WIDTH);
                local numTexturesTall = ceil(exploredTextureInfo.textureHeight/TILE_SIZE_HEIGHT);
                local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight;
                for j = 1, numTexturesTall do
                    if ( j < numTexturesTall ) then
                        texturePixelHeight = TILE_SIZE_HEIGHT;
                        textureFileHeight = TILE_SIZE_HEIGHT;
                    else
                        texturePixelHeight = mod(exploredTextureInfo.textureHeight, TILE_SIZE_HEIGHT);
                        if ( texturePixelHeight == 0 ) then
                            texturePixelHeight = TILE_SIZE_HEIGHT;
                        end
                        textureFileHeight = 16;
                        while(textureFileHeight < texturePixelHeight) do
                            textureFileHeight = textureFileHeight * 2;
                        end
                    end
                    for k = 1, numTexturesWide do
                        local texture = TilePool:Acquire();
                        if ( k < numTexturesWide ) then
                            texturePixelWidth = TILE_SIZE_WIDTH;
                            textureFileWidth = TILE_SIZE_WIDTH;
                        else
                            texturePixelWidth = mod(exploredTextureInfo.textureWidth, TILE_SIZE_WIDTH);
                            if ( texturePixelWidth == 0 ) then
                                texturePixelWidth = TILE_SIZE_WIDTH;
                            end
                            textureFileWidth = 16;
                            while(textureFileWidth < texturePixelWidth) do
                                textureFileWidth = textureFileWidth * 2;
                            end
                        end
                        texture:SetSize(texturePixelWidth, texturePixelHeight);
                        texture:SetTexCoord(0, texturePixelWidth/textureFileWidth, 0, texturePixelHeight/textureFileHeight);
                        texture:SetPoint("TOPLEFT", exploredTextureInfo.offsetX + (TILE_SIZE_WIDTH * (k-1)), -(exploredTextureInfo.offsetY + (TILE_SIZE_HEIGHT * (j - 1))));
                        texture:SetTexture(exploredTextureInfo.fileDataIDs[((j - 1) * numTexturesWide) + k], nil, nil, "TRILINEAR");
                        texture:SetDrawLayer(drawLayer, subLevel);
                        texture:Show();
                    end
                end
            end
        end
	end

    print(TilePool:GetCount());
    local w, h = C_Map.GetMapWorldSize(mapID);
end

function NarciMapMixin:SetMapForPlayer()
    local mapID = C_Map.GetBestMapForUnit("player");
    self:SetMap(mapID);
end