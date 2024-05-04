local _, addon = ...
local Gemma = addon.Gemma;

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";

local Atlas = {};
local AtlasUtil = {};
Gemma.AtlasUtil = AtlasUtil;

function AtlasUtil:SetAtlas(texture, name)
    local a = name and Atlas[name];

    if a then
        texture:SetTexture(a[1]);
        texture:SetSize(a[2], a[3]);
        texture:SetTexCoord(a[4], a[5], a[6], a[7]);
    else
        texture:SetTexture(nil);
    end
end

local AtlasInfo = {
    --file, textureWidth, textureHeight, {[atlasName] = {width, height, 4pixelCoords}, ...}

    {PATH.."TimerunningPandaria.png", 1024, 1024, {
        ["remix-ui-bg"] = {338, 424, 616, 1024, 0, 512},
        ["remix-ui-divider"] = {338, 16, 0, 408, 256, 280},
        ["remix-ui-tinker-bg"] = {290, 290, 0, 144, 96, 240},
        ["remix-ui-tooltip-bg"] = {204, 86, 0, 204, 282, 368},

        ["remix-listbutton-highlight"] = {256, 64, 292, 548, 282, 346},

        ["remix-hexagon-yellow"] = {48, 48, 0, 96, 0, 96},
        ["remix-hexagon-green"] = {48, 48, 96, 192, 0, 96},
        ["remix-hexagon-darkyellow"] = {48, 48, 192, 288, 0, 96},
        ["remix-hexagon-grey"] = {48, 48, 288, 384, 0, 96},
        ["remix-hexagon-highlight"] = {48, 48, 384, 480, 0, 96},

        ["remix-bigsquare-yellow"] = {72, 72, 0, 144, 368, 512},
        ["remix-bigsquare-green"] = {72, 72, 144, 288, 368, 512},
        ["remix-bigsquare-grey"] = {72, 72, 288, 432, 368, 512},
        ["remix-bigsquare-highlight"] = {72, 72, 432, 576, 368, 512},
        ["remix-bigsquare-shadow"] = {144, 144, 0, 144, 512, 656},

        ["gemlist-return"] = {20, 20, 328, 360, 100, 132},
        ["gemlist-prev"] = {14, 14, 292, 324, 100, 132},
        ["gemlist-next"] = {14, 14, 324, 292, 100, 132},
    }},
};

do
    local file, width, height;
    local w, h;

    for _, v in pairs(AtlasInfo) do
        file = v[1];
        width, height = v[2], v[3];
        for name, data in pairs(v[4]) do
            w, h = data[1], data[2];
            Atlas[name] = {file, w, h, data[3]/width, data[4]/width, data[5]/height, data[6]/height};
        end
    end

    AtlasInfo = {};
end