local NineSliceUtil = {};

NarciAPI.NineSliceUtil = NineSliceUtil;

--Texture order ↓
-- 1 | 2 | 3
-- 4 | 5 | 6
-- 7 | 8 | 9

local ORDER = {1, 3, 7, 9, 2, 4, 6, 8, 5};

local PATH_PREFIX = "Interface\\AddOns\\Narcissus\\Art\\";
local TextureData = {
    rectR6 = {
        file = "Frames\\NineSliceRectR6",
        cornerSize = 4,
        cornerCoord = 0.25,
    },

    shadowR6 = {
        file = "Frames\\NineSliceShadowR6",
        cornerSize = 8,
        cornerCoord = 0.375,
        offsetRatio =  0.6667,
    },

    shadowR12 = {
        file = "Frames\\NineSliceShadowR6",
        cornerSize = 16,
        cornerCoord = 0.375,
        offsetRatio =  0.6667,
    },

    shadowR0 = {
        file = "Frames\\NineSliceShadowR0",
        cornerSize = 8,
        cornerCoord = 0.375,
        offsetRatio =  0.6667,
    },

    shadowLargeR0 = {
        file = "Frames\\NineSliceShadowR0",
        cornerSize = 16,
        cornerCoord = 0.375,
        offsetRatio =  0.6667,
    },

    shadowHugeR0 = {
        file = "Frames\\NineSliceShadowR0",
        cornerSize = 20,
        cornerCoord = 0.375,
        offsetRatio =  0.6667,
    },

    phantom = {
        file = "Frames\\NineSlicePhantom",
        cornerSize = 24,
        cornerCoord = 0.25,
    },

    photoModePopup = {
        file = "Frames\\NineSlicePhotoModePopup",
        cornerSize = 16,
        cornerCoord = 0.25,
    },

    chatBubbleBlack = {
        file = "Frames\\NineSliceChatBubbleBlack",
        cornerSize = 16,
        cornerCoord = 0.25,
    },

    chatBubbleWhite = {
        file = "Frames\\NineSliceChatBubbleWhite",
        cornerSize = 12,
        cornerCoord = 0.25,
    },
};

function NineSliceUtil.SetUp(frame, textureKey, layer, shrink)
    shrink = shrink or 0
    local group, subLevel;
    if layer == "backdrop" then
        if not frame.backdropTextures then
            frame.backdropTextures = {};
        end
        group = frame.backdropTextures;
        subLevel = 0;
    elseif layer == "border" then
        if not frame.borderTextures then
            frame.borderTextures = {};
        end
        group = frame.borderTextures;
        subLevel = -1;
    else
        return
    end

    local file = PATH_PREFIX .. TextureData[textureKey].file;
    local size = TextureData[textureKey].cornerSize;
    local coord = TextureData[textureKey].cornerCoord;
    local offset = size * (TextureData[textureKey].offsetRatio or 0);
    local tex;
    local key;
    for i = 1, 9 do
        key = ORDER[i];
        if not group[key] then
            group[key] = frame:CreateTexture(nil, "BACKGROUND", nil, subLevel);
        end
        tex = group[key];
        tex:SetTexture(file);
        if key == 2 or key == 8 then
            --tex:SetHeight(size);
            if key == 2 then
                tex:SetPoint("TOPLEFT", group[1], "TOPRIGHT", 0, 0);
                tex:SetPoint("BOTTOMRIGHT", group[3], "BOTTOMLEFT", 0, 0);
                tex:SetTexCoord(coord, 1-coord, 0, coord);
            else
                tex:SetPoint("TOPLEFT", group[7], "TOPRIGHT", 0, 0);
                tex:SetPoint("BOTTOMRIGHT", group[9], "BOTTOMLEFT", 0, 0);
                tex:SetTexCoord(coord, 1-coord, 1-coord, 1);
            end
        elseif key == 4 or key == 6 then
            --tex:SetWidth(size);
            if key == 4 then
                tex:SetPoint("TOPLEFT", group[1], "BOTTOMLEFT", 0, 0);
                tex:SetPoint("BOTTOMRIGHT", group[7], "TOPRIGHT", 0, 0);
                tex:SetTexCoord(0, coord, coord, 1-coord);
            else
                tex:SetPoint("TOPLEFT", group[3], "BOTTOMLEFT", 0, 0);
                tex:SetPoint("BOTTOMRIGHT", group[9], "TOPRIGHT", 0, 0);
                tex:SetTexCoord(1-coord, 1, coord, 1-coord);
            end
        elseif key == 5 then
            tex:SetPoint("TOPLEFT", group[1], "BOTTOMRIGHT", 0, 0);
            tex:SetPoint("BOTTOMRIGHT", group[9], "TOPLEFT", 0, 0);
            tex:SetTexCoord(coord, 1-coord, coord, 1-coord);
        else
            tex:SetSize(size, size);
            if key == 1 then
                tex:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset + shrink, offset - shrink);
                tex:SetTexCoord(0, coord, 0, coord);
            elseif key == 3 then
                tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", offset - shrink, offset - shrink);
                tex:SetTexCoord(1-coord, 1, 0, coord);
            elseif key == 7 then
                tex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -offset + shrink, -offset + shrink);
                tex:SetTexCoord(0, coord, 1-coord, 1);
            else
                tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset - shrink, -offset + shrink);
                tex:SetTexCoord(1-coord, 1, 1-coord, 1);
            end
        end
    end
end

function NineSliceUtil.SetBackdropColor(frame, r, g, b)
    if frame.backdropTextures then
        for i = 1, 9 do
            frame.backdropTextures[i]:SetVertexColor(r, g, b);
        end
    end
end

function NineSliceUtil.SetBorderColor(frame, r, g, b)
    if frame.borderTextures then
        for i = 1, 9 do
            frame.borderTextures[i]:SetVertexColor(r, g, b);
        end
    end
end

function NineSliceUtil.SetUpBackdrop(frame, textureKey, shrink, r, g, b)
    NineSliceUtil.SetUp(frame, textureKey, "backdrop", shrink);
    if r and g and b then
        NineSliceUtil.SetBackdropColor(frame, r, g, b);
    end
end

function NineSliceUtil.SetUpBorder(frame, textureKey, shrink, r, g, b)
    NineSliceUtil.SetUp(frame, textureKey, "border", shrink);
    if r and g and b then
        NineSliceUtil.SetBorderColor(frame, r, g, b);
    end
end


----Border Tile----

local TileData = {
    leather = {
        file = "Tiles\\Leather",
        pixel = 64,
        padding = 16,
        minPixel = 32,
    },
};

local function AjustPixel_OnShow(self)
    local scale = self:GetEffectiveScale();
    if scale ~= self.tileScale then
        self.tileScale = scale;
        local px = NarciAPI.GetPixelForWidget(self);
        self.pixelSize = px;
        local size = self.tiles.size * px;
        for i = 1, 4 do
            self.tiles[i]:SetSize(size, size);
        end
        if self.SetPadding then
            local p = self.tiles.padding * px;
            self:SetPadding(p, p, p, p);
        end
        if self.tiles.minPixel then
            local a = self.tiles.minPixel / px;
            self:SetMinResize(a, a);
            self.minSize = a;
        end
        if self.OnPixelChanged then
            self:OnPixelChanged(px);
        end
    end
end

local function AjustTitleVisibility_OnSizeChanged(self, w, h)
    self.tiles[5]:SetShown(h > self.minSize);
    self.tiles[6]:SetShown(h > self.minSize);
    self.tiles[7]:SetShown(w > self.minSize);
    self.tiles[8]:SetShown(w > self.minSize);
end

function NineSliceUtil.TileFrame(frame, tileName)
    local data = TileData[tileName];
    if not data then return end

    local hookscript = false;
    if not frame.tiles then
        frame.tiles = {};
        hookscript = true;
    end

    local tiles = frame.tiles;
    tiles.size = data.pixel;
    tiles.padding = data.padding;
    tiles.minPixel = data.minPixel;

    local file = PATH_PREFIX.. data.file;
    local t;

    for i = 1, 8 do
        if not tiles[i] then
            tiles[i] = frame:CreateTexture(nil, "BORDER");
        end
        t = tiles[i];
        t:SetTexture(file);
        if i <= 4 then
            if i == 1 then  --topleft
                t:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
                t:SetTexCoord(0, 0.5, 0, 0.5);
            elseif i == 2 then  --topright
                t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
                t:SetTexCoord(0.5, 0, 0, 0.5);
            elseif i == 3 then  --bottomleft
                t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
                t:SetTexCoord(0, 0.5, 0.5, 0);
            elseif i == 4 then  --bottomright
                t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
                t:SetTexCoord(0.5, 0, 0.5, 0);
            end
        else
            if i == 5 then  --left
                t:SetPoint("TOPLEFT", tiles[1], "BOTTOMLEFT", 0, 0);
                t:SetPoint("BOTTOMRIGHT", tiles[3], "TOPRIGHT", 0, 0);
                t:SetTexCoord(0, 0.5, 0.5, 1);
            elseif i == 6 then  --right
                t:SetPoint("TOPLEFT", tiles[2], "BOTTOMLEFT", 0, 0);
                t:SetPoint("BOTTOMRIGHT", tiles[4], "TOPRIGHT", 0, 0);
                t:SetTexCoord(0.5, 0, 0.5, 1);
            elseif i == 7 then  --top
                t:SetPoint("TOPLEFT", tiles[1], "TOPRIGHT", 0, 0);
                t:SetPoint("BOTTOMRIGHT", tiles[2], "BOTTOMLEFT", 0, 0);
                t:SetTexCoord(0.5, 1, 0, 0.5);
            elseif i == 8 then  --bottom
                t:SetPoint("TOPLEFT", tiles[3], "TOPRIGHT", 0, 0);
                t:SetPoint("BOTTOMRIGHT", tiles[4], "BOTTOMLEFT", 0, 0);
                t:SetTexCoord(0.5, 1, 0.5, 0);
            end
        end
    end

    AjustPixel_OnShow(frame);

    if hookscript then
        if frame:GetScript("OnShow") then
            frame:HookScript("OnShow", function(f)
                AjustPixel_OnShow(f);
            end);
        else
            frame:SetScript("OnShow", AjustPixel_OnShow);
        end

        if data.minPixel then
            frame:HookScript("OnSizeChanged", function(f, w, h)
                AjustTitleVisibility_OnSizeChanged(f, w, h);
            end);
        end
    end
end