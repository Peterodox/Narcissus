local _, addon = ...
local NarciAPI = NarciAPI;


local max = math.max;
local min = math.min;
local floor = math.floor;
local strsub = strsub;
local unpack = unpack;


local colors = {
    green = {r = 124, g = 197, b = 118},
    red = {r = 255, g = 80, b = 80},
};

local function GetColorPresetRGB(name)
    if colors[name] then
        return colors[name].r/255, colors[name].g/255, colors[name].b/255
    end
end


Narci_FontColor = {
    ["Brown"] = {0.85098, 0.80392, 0.70588, "|cffd9cdb4"},
    ["DarkGrey"] = {0.42, 0.42, 0.42, "|cff6b6b6b"},
    ["LightGrey"] = {0.72, 0.72, 0.72, "|cffb8b8b8"},
    ["White"] = {0.88, 0.88, 0.88, "|cffe0e0e0"},
    ["Good"] = {0.4862, 0.7725, 0.4627, "|cff7cc576"},
    ["Bad"] = {1, 0.3137, 0.3137, 0.3137, "|cffff5050"},
    ["Corrupt"] = {0.584, 0.428, 0.82, "|cff946dd1"},
};

local CustomQualityColors= {
	[0] = "9d9d9d",	--Poor
	[1] = "ffffff",	--Common
	[2] = "1eff00",	--Uncommon
	[3] = "699eff",	--Rare 0070dd 699eff
	[4] = "b953ff",	--Epic a335ee
	[5] = "ff8000",	--Legend
	[6] = "e6cc80",	--Artifact
	[7] = "00ccff",	--Heirloom
	[8] = "00ccff",
	[9] = "ffffff",
};


local function ConvertHexColorToRGB(hexColor, includeHex)
    local r = tonumber(strsub(hexColor, 1, 2), 16) / 255;
    local g = tonumber(strsub(hexColor, 3, 4), 16) / 255;
    local b = tonumber(strsub(hexColor, 5, 6), 16) / 255;
    if includeHex then
        return {r, g, b, hexColor};
    else
        return {r, g, b};
    end
end

local function RGB2HSV(r, g, b)
	local Cmax = max(r, g, b);
	local Cmin = min(r, g, b);
	local dif = Cmax - Cmin;
	local Hue = 0;
	local Brightness = floor(100*(Cmax / 255) + 0.5)/100;
	local Stauration = 0;
	if Cmax ~= 0 then Stauration = floor(100*(dif / Cmax)+0.5)/100; end;

	if dif ~= 0 then
		if r == Cmax and g >= b then
			Hue = (g - b) / dif + 0;
		elseif r == Cmax and g < b then
			Hue = (g - b) / dif + 6;
		elseif g == Cmax then
			Hue = (b - r) / dif + 2;
		elseif b == Cmax then
			Hue = (r - g) / dif + 4;
		end
	end

	return floor(60*Hue + 0.5), Stauration, Brightness
end

local function RGBRatio2HSV(r, g, b)
	return RGB2HSV(255 * r, 255 * g, 255 * b)
end

local function HSV2RGB(h, s, v)
	local Cmax = 255 * v;
	local Cmin = Cmax * (1 - s);
	local i = floor(h / 60);
	local dif = h % 60;
	local Cmid = (Cmax - Cmin) * dif / 60;
	local r, g, b;

	if i == 0 or i == 6 then
		r, g, b = Cmax, Cmin + Cmid, Cmin;
	elseif i == 1 then
		r, g, b = Cmax - Cmid, Cmax, Cmin;
	elseif i == 2 then
		r, g, b = Cmin, Cmax, Cmin + Cmid;
	elseif i == 3 then
		r, g, b = Cmin, Cmax - Cmid, Cmax;
	elseif i == 4 then
		r, g, b = Cmin + Cmid, Cmin, Cmax;
	else
		r, g, b = Cmax, Cmin, Cmax - Cmid;
	end

	r, g, b = floor(r + 0.5)/255, floor(g + 0.5)/255, floor(b + 0.5)/255;
	return r, g, b
end

for index, hex in pairs(CustomQualityColors) do
	CustomQualityColors[index] = ConvertHexColorToRGB(hex, true);
end

local function GetCustomQualityColor(itemQuality)
    if (not itemQuality) or (not CustomQualityColors[itemQuality]) then
        itemQuality = 1;
    end
    return CustomQualityColors[itemQuality][1], CustomQualityColors[itemQuality][2], CustomQualityColors[itemQuality][3];
end

local function GetCustomQualityColorByItemID(itemID)
    local itemQuality = C_Item.GetItemQualityByID(itemID);
    return GetCustomQualityColor(itemQuality);
end

local function GetCustomQualityHexColor(itemQuality)
    if (not itemQuality) or (not CustomQualityColors[itemQuality]) then
        itemQuality = 1;
    end
    return CustomQualityColors[itemQuality][4]
end


local function GetItemQualityColorTable()
    local newTable = {};
    for k, v in pairs(CustomQualityColors) do
        newTable[k] = v;
    end
    return newTable;
end


do  --Map Color Theme
    local MapColors = {
        --[0] = { 35,  96, 147},	--default Blue  0.1372, 0.3765, 0.5765
        [0] = {78,  78,  78},   --Default Black
        [1] = {121,  31,  35},	--Orgrimmar
        [2] = { 49, 176, 107},	--Zuldazar
        [3] = {187, 161, 134},	--Vol'dun
        [4] = { 89, 140, 123},	--Tiragarde Sound
        [5] = {127, 164, 114},	--Stormsong
        [6] = {156, 165, 153},	--Drustvar
        [7] = { 42,  63,  79},	--Halls of Shadow


        --[UiMapID] = {r, g, b}
        --Shadowlands
        [1970] = {137, 218, 247},   --Zereth Mortis
        [1670] = {76, 86, 109},     --Oribos

        [1533] = {197, 185, 172},	--Bastion
        [1707] = {193, 199, 210},   --Elysian Hold
        [1708] = {168, 188, 232},   --Sanctum of Binding

        [1701] = {57, 66, 154},     --Heart of the Forest
        [1565] = {57, 66, 154},     --Ardenweald
        
        [1536] = {25, 97, 85},      --Maldraxxus
        [1698] = {25, 97, 85},      --Seat of the Primus

        [1525] = {48, 96, 153},      --Revendreth

        [1911] = {53, 80, 115},     --Torghast Entrance
        [1912] = {53, 80, 115},     --Runecrafter

        --Major City--
        [84]  = {129, 144, 155},	--Stormwind City
        
        [85]  = {121,  52,  55},	--Orgrimmar
        [86]  = {121,  31,  35},	--Orgrimmar - Cleft of Shadow
        [463] = {163,  99,  89},	--Echo Isles
        
        [87]  = {102,  64,  58},	--Ironforge
        [27]  = {151, 198, 213},	--Dun Morogh
        [469] = {151, 198, 213},	--New Tinkertown
        
        [88]  = {115, 140, 113},	--Thunder Bluff
        
        [89]  = {121,  31,  35},	--Darnassus	R.I.P.
        
        [90]  = { 42,  63,  79},	--Undercity

        [110] = {172,  58,  54},    --Silvermoon City

        [202]  = {78,  78,  78},    --Gilneas City
        [217]  = {78,  78,  78},    --Ruins of Gilneas
        [627] = {102,  58,  64},	--Dalaran  	Broken Isles
        [111] = {88,  108,  91},	--Shattrath City

        -- TBC --
        [107] = {181,  151, 93},	--Nagrand Outland
        [109] = {96,   48, 108},	--Netherstorm
        [102] = {61,   77, 162},	--Zangarmash
        [105] = {123, 104,  80},	--Blade's Edge Mountains

        -- MOP --
        [378] = {120, 107,  81},	--The Wandering Isle
        [371] = { 95, 132,  78},    --The Jade Forrest
        [379] = { 90, 119, 156},    --Kun-Lai Summit

        -- LEG --
        [641] = { 70, 128, 116},    --Val'sharah

        -- BFA --
        [81]  = { 98,  84,  77},    --Silithus
        [1473]= {168, 136,  90},    --Chamber of Heart
        [1163]= { 89, 140, 123},	--Dazar'alor - The Great Seal
        [1164]= { 89, 140, 123},	--Dazar'alor - Hall of Chroniclers
        [1165]= { 89, 140, 123},	--Dazar'alor
        [862] = { 89, 140, 123},	--Zuldazar
        [864] = {187, 161, 134},	--Vol'dun
        [863] = {113, 173, 183},	--Nazmir
        [895] = { 89, 140, 123},	--Tiragarde Sound
        [1161]= { 89, 140, 123},	--Boralus
        [942] = {127, 164, 114},	--Stormsong
        [896] = {156, 165, 153},	--Drustvar
        
        [1462] = {16, 156, 192},    --Mechagon
        [1355] = {41,  74, 127},    --Nazjatar

        [249]  = {180,149, 121},    --Uldum Normal
        [1527] = {180,149, 121},    --Uldum Assault
        [390]  = {150, 117, 94},    --Eternal Blossoms Normal
        [1530] = {150, 117, 94},    --Eternal Blossoms Assault  --{105, 71, 156}
        ["NZ"] = {105, 71, 156},    --During Assault: N'Zoth Purple Skybox

        [1580] = {105, 71, 156},    --Ny'alotha - Vision of Destiny
        [1581] = {105, 71, 156},    --Ny'alotha - Annex of Prophecy
        [1582] = {105, 71, 156},    --Ny'alotha - Ny'alotha
        [1590] = {105, 71, 156},    --Ny'alotha - The Hive
        [1591] = {105, 71, 156},    --Ny'alotha - Terrace of Desolation
        [1592] = {105, 71, 156},    --Ny'alotha - The Ritual Chamber
        [1593] = {105, 71, 156},    --Ny'alotha - Twilight Landing
        [1594] = {105, 71, 156},    --Ny'alotha - Maw of Gor'ma
        [1595] = {105, 71, 156},    --Ny'alotha - Warren of Decay
        [1596] = {105, 71, 156},    --Ny'alotha - Chamber of Rebirth
        [1597] = {105, 71, 156},    --Ny'alotha - Locus of Infinite Truths

        --Allied Race Starting Zone--
        [124]  = {87,  56, 132},    --DK
        [1186] = {117,  26, 22},    --Dark Iron
        [971]  = {65, 57, 124},     --Void Elf

        --Class Hall
        [625] = { 42,  63,  79},	--Dalaran, Broken Isles  Halls of Shadow
        [626] = { 42,  63,  79},	--Hall of Shadow
        [715] = {149, 180, 146},    --Emerald Dreamway
        [747] = { 70, 128, 116},    --The Dreamgrove

        --Frequently Visited
        [198]  = {78,  78,  78},    --Hyjal
    };

    local UIColorThemeUtil = {};
    addon.UIColorThemeUtil = UIColorThemeUtil;
    UIColorThemeUtil.colorIndex = 0;

    function UIColorThemeUtil:GetColorTable()
        local r, g, b = unpack(MapColors[self.colorIndex]);
        return {r/255, g/255, b/255}
    end

    function UIColorThemeUtil:GetActiveColor()
        local r, g, b = unpack(MapColors[self.colorIndex]);
        return r/255, g/255, b/255
    end

    function UIColorThemeUtil:GetColorIndex()
        return self.colorIndex
    end

    function UIColorThemeUtil:SetColorIndex(index)
        if index and MapColors[index] then
            self.colorIndex = index
        else
            self.colorIndex = 0;
        end
        self.r, self.g, self.b = self:GetActiveColor();
    end

    function UIColorThemeUtil:UpdateByMapID()
        local mapID = C_Map.GetBestMapForUnit("player");
        if mapID then	--and NarcissusDB.AutoColorTheme
            if not MapColors[mapID] then
                mapID = 0;
            end

            if mapID == self.mapID then
                self.requireUpdate = false;
            else
                self.mapID = mapID;
                self.requireUpdate = true;
                self.themeColor = self:SetColorIndex(mapID);
                --RadarChart:UpdateColor();
                --Narci_NavBar:SetThemeColor(self.themeColor);
            end
        else
            self.requireUpdate = false;
        end
    end

    function UIColorThemeUtil:SetWidgetColor(frame)
        if not self.requireUpdate then return end;

        if not self.r then
            self:UpdateByMapID()
        end

        local r, g, b = self.r, self.g, self.b;
        local type = frame:GetObjectType();

        if type == "FontString" then
            local sqrt = math.sqrt;
            r, g, b = sqrt(r), sqrt(g), sqrt(b);
            frame:SetTextColor(r, g, b);
        else
            frame:SetColorTexture(r, g, b);
        end
    end
end


do --Globals
    NarciAPI.GetItemQualityColor = GetCustomQualityColor;
    NarciAPI.GetItemQualityColorByItemID = GetCustomQualityColorByItemID;
    NarciAPI.GetItemQualityHexColor = GetCustomQualityHexColor;
    NarciAPI.GetColorPresetRGB = GetColorPresetRGB;
    NarciAPI.ConvertHexColorToRGB = ConvertHexColorToRGB;
    NarciAPI.RGB2HSV = RGB2HSV;
    NarciAPI.RGBRatio2HSV = RGBRatio2HSV;
    NarciAPI.HSV2RGB = HSV2RGB;
    NarciAPI.GetItemQualityColorTable = GetItemQualityColorTable;
end