local NineSliceUtil = {};

NarciAPI.NineSliceUtil = NineSliceUtil;

local AddPixelPerfectTexture = NarciAPI.AddPixelPerfectTexture; --(frame, texture, pixelWidth, pixelHeight)

local function DisableSharpening(texture)
    texture:SetTexelSnappingBias(0);
    texture:SetSnapToPixelGrid(false);
end
NarciAPI.DisableSharpening = DisableSharpening;

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

    settingsBackground = {
        file = "SettingsFrame\\FrameBackground",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    settingsBorder = {
        file = "SettingsFrame\\FrameBorder",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    blackChamfer8 = {
        file = "Frames\\NineSliceChamfer8",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    classTalentTrait = {
        file = "Modules\\TalentTree\\TraitTooltipNineSlice",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    classTalentTraitTransparent = {
        file = "Modules\\TalentTree\\TraitTooltipStrokeOnlyNineSlice",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    brownBorder = {
        file = "Modules\\BagItemSearchSuggest\\BorderNineSlice",
        cornerSize = 24,
        cornerCoord = 0.25,
    },

    whiteBorder = {
        file = "Modules\\BagItemSearchSuggest\\BorderNineSlice",
        cornerSize = 24,
        cornerCoord = 0.25,
    },

    genericChamferedBorder = {
        file = "Frames\\GenericChamferedBorder",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    genericChamferedBackground = {
        file = "Frames\\GenericChamferedBackground",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = true,
        useCenterForAlignment = true,
    },

    ChamferedBevelBorderThick = {
        file = "Frames\\ChamferedBevelBorderThick",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = false,
        useCenterForAlignment = true,
    },

    dispersiveShadow = {
        file = "Frames\\NineSliceShadowR32",
        cornerSize = 32,
        cornerCoord = 0.25,
        pixelPerfect = false,
        useCenterForAlignment = true,
    },

    blizzardTooltipBorder = {
        file = "Frames\\NineSliceBlizzardTooltipBorder",
        cornerSize = 24,
        cornerCoord = 0.25,
        disableSharpening = true;
        useCenterForAlignment = true,
    },

    focus = {
        file = "Frames\\NineSliceFocus",
        cornerSize = 12,
        cornerCoord = 0.25,
        disableSharpening = true;
        useCenterForAlignment = true,
    },

    photoModeUIBorder = {
        file = "Frames\\NineSlicePhotoModeGreyBorder",
        cornerSize = 16,
        cornerCoord = 0.25,
        useCenterForAlignment = true,
        disableSharpening = true;
    },
};

function NineSliceUtil.SetUp(frame, textureKey, layer, shrink, customLayerSubLevel)
    shrink = shrink or 0;
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

    if customLayerSubLevel then
        subLevel = customLayerSubLevel;
    end


    local file, size, coord, pixelMode, useCenterForAlignment, offset, disableSharpening;

    if textureKey then
        local data = TextureData[textureKey];
        file = PATH_PREFIX .. data.file;
        size = data.cornerSize;
        coord = data.cornerCoord;
        pixelMode = data.pixelPerfect;
        useCenterForAlignment = data.useCenterForAlignment;
        offset = size * (data.offsetRatio or 0);
        disableSharpening = data.disableSharpening;
    else
        size = 16;
        coord = 1;
        pixelMode = false;
        useCenterForAlignment = false;
        offset = 0;
        disableSharpening = true;
    end

    local tex, key;
    local isNewTexture;

    for i = 1, 9 do
        key = ORDER[i];
        if not group[key] then
            group[key] = frame:CreateTexture(nil, "BACKGROUND", nil, subLevel);
            isNewTexture = true;
        else
            isNewTexture = false;
        end
        tex = group[key];
        tex:SetTexture(file, nil, nil, "LINEAR"); --NEAREST LINEAR
        if disableSharpening then
            DisableSharpening(tex)
        end
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

            if useCenterForAlignment then
                if key == 1 then
                    tex:SetPoint("CENTER", frame, "TOPLEFT", shrink, -shrink);
                    tex:SetTexCoord(0, coord, 0, coord);
                elseif key == 3 then
                    tex:SetPoint("CENTER", frame, "TOPRIGHT", -shrink, -shrink);
                    tex:SetTexCoord(1-coord, 1, 0, coord);
                elseif key == 7 then
                    tex:SetPoint("CENTER", frame, "BOTTOMLEFT", shrink, shrink);
                    tex:SetTexCoord(0, coord, 1-coord, 1);
                elseif key == 9 then
                    tex:SetPoint("CENTER", frame, "BOTTOMRIGHT", -shrink, shrink);
                    tex:SetTexCoord(1-coord, 1, 1-coord, 1);
                end
            else
                if key == 1 then
                    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset + shrink, offset - shrink);
                    tex:SetTexCoord(0, coord, 0, coord);
                elseif key == 3 then
                    tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", offset - shrink, offset - shrink);
                    tex:SetTexCoord(1-coord, 1, 0, coord);
                elseif key == 7 then
                    tex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -offset + shrink, -offset + shrink);
                    tex:SetTexCoord(0, coord, 1-coord, 1);
                elseif key == 9 then
                    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset - shrink, -offset + shrink);
                    tex:SetTexCoord(1-coord, 1, 1-coord, 1);
                end
            end

            if pixelMode and isNewTexture then
                AddPixelPerfectTexture(frame, tex, size, size);
            end
        end
    end

    if frame.pixelDriver then
        frame.pixelDriver.scale = 0;    --reset scale so it can update on next OnShow
    end
end

function NineSliceUtil.SetBackdropColor(frame, r, g, b, a)
    if frame and frame.backdropTextures then
        a = a or 1;
        for i = 1, 9 do
            frame.backdropTextures[i]:SetVertexColor(r, g, b);
            frame.backdropTextures[i]:SetAlpha(a);
        end
    end
end

function NineSliceUtil.SetBorderColor(frame, r, g, b, a)
    if frame and frame.borderTextures then
        a = a or 1;
        for i = 1, 9 do
            frame.borderTextures[i]:SetVertexColor(r, g, b);
            frame.borderTextures[i]:SetAlpha(a);
        end
    end
end

function NineSliceUtil.SetUpBackdrop(frame, textureKey, shrink, r, g, b, a, customLayerSubLevel)
    NineSliceUtil.SetUp(frame, textureKey, "backdrop", shrink, customLayerSubLevel);
    if r and g and b then
        NineSliceUtil.SetBackdropColor(frame, r, g, b, a);
    end
end

function NineSliceUtil.SetUpBorder(frame, textureKey, shrink, r, g, b, a, customLayerSubLevel)
    NineSliceUtil.SetUp(frame, textureKey, "border", shrink, customLayerSubLevel);
    if r and g and b then
        NineSliceUtil.SetBorderColor(frame, r, g, b, a);
    end
end

function NineSliceUtil.SetUpOverlay(frame, textureKey, shrink, r, g, b, a, customLayerSubLevel)
    local container = frame.NineSliceOverlay;

    if not container then
        container = CreateFrame("Frame", nil, frame);
        container:SetAllPoints(true);
        frame.NineSliceOverlay = container;
    end

    NineSliceUtil.SetUp(container, textureKey, "border", shrink, customLayerSubLevel);
    if r and g and b then
        NineSliceUtil.SetBorderColor(container, r, g, b, a);
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

function NineSliceUtil.CreateNineSlice(frame)
    local textureKey = nil;
    local layer = "backdrop";
    NineSliceUtil.SetUp(frame, textureKey, layer);
end