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
};

function NineSliceUtil.SetUp(frame, textureKey, layer)
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
                tex:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset);
                tex:SetTexCoord(0, coord, 0, coord);
            elseif key == 3 then
                tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", offset, offset);
                tex:SetTexCoord(1-coord, 1, 0, coord);
            elseif key == 7 then
                tex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -offset, -offset);
                tex:SetTexCoord(0, coord, 1-coord, 1);
            else
                tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset);
                tex:SetTexCoord(1-coord, 1, 1-coord, 1);
            end
        end
    end
end

function NineSliceUtil.SetUpBackdrop(frame, textureKey)
    NineSliceUtil.SetUp(frame, textureKey, "backdrop");
end

function NineSliceUtil.SetUpBorder(frame, textureKey)
    NineSliceUtil.SetUp(frame, textureKey, "border");
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