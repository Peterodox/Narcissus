local FadeFrame = NarciAPI_FadeFrame;

--------------------------------------
-------------Screen Filter------------
--------------------------------------
local FilterIndex = 1;
local Temperature = {};
Temperature = {
  --[n] = {R, G, B, alpha},
    [1] = {0, 93, 255, 0.08}, --Cooling Filter
    [2] = {243, 152, 0, 1}, --Warming Filter: Orange
}

local ScreenFilter = CreateFrame("Frame", "Narci_ScreenFilter", Narci_Attribute);
ScreenFilter:SetIgnoreParentAlpha(false);
ScreenFilter:SetIgnoreParentScale(true);
ScreenFilter:SetFrameStrata("TOOLTIP")
ScreenFilter:SetScript("OnHide", function(self)
    self:Hide();
    self:SetAlpha(0);
end)
ScreenFilter:Hide();
ScreenFilter:SetAlpha(0);

local ScreenOverlay = ScreenFilter:CreateTexture("ScreenOverlay", "BACKGROUND")
ScreenOverlay:SetAllPoints(UIParent)

local r, g, b, a = Temperature[FilterIndex][1]/255, Temperature[FilterIndex][2]/255, Temperature[FilterIndex][3]/255,Temperature[FilterIndex][4]
ScreenOverlay:SetColorTexture(r, g, b, 0.06)
ScreenOverlay:SetBlendMode("ADD")

--------------------------------------
------------Snow Generator------------
--------------------------------------
local UIScale = UIParent:GetEffectiveScale()
local SnowDensity = 350; --control the maximum number of Snowflakes
local TotalSnow = 1; --Small snowflake + 1  /  Big snowflake + 4
local TotalFakeSnow = 1;
local SnowTexture = {};
SnowTexture = {
    [1] = "Interface/AddOns/Narcissus/Filters/CameraEffect/Snow-Ellipse",
    [2] = "Interface/AddOns/Narcissus/Filters/CameraEffect/Snow-Rectangle",
    [3] = "Interface/AddOns/Narcissus/Filters/CameraEffect/Snow-Triangle",
    [4] = "Interface/AddOns/Narcissus/Filters/CameraEffect/Snow-Round",
}

local SnowyLand = {};
SnowyLand = {
  --[mapID] = {density, x1, y1, x2, y2},

  --Kalimdor
    [83] = {200, -1, -1, 1, 1}, -- Winterspring

  --Eatern Kingdoms
    [25] = {150, 0.38, 0.17, 0.52, 0.42}, -- Hillsbrad Foothills
    [27] = {100, -1, -1, 1, 1}, -- Dun Morogh
    [427] = {100, -1, -1, 1, 1}, -- Dun Morogh

  --Northrend--b
    [114] = {200, 0, 0, 0.37, 0.42}, -- Borean Tundra
    [115] = {200, -1, -1, 1, 1}, -- Dragonblight
    [116] = {100, 0.37, 0.51, 0.83, 1}, -- Grizzly Hill
    [117] = {100, 0.25, 0, 0.75, 0.19}, -- Howling Fjord
    [118] = {200, -1, -1, 1, 1}, -- Icecrown
    [119] = {100, 0.65, 0, 1, 0.43}, -- Sholazar Basin
    [120] = {500, -1, -1, 1, 1}, -- Storm Peaks
    [121] = {50, 0.45, 0, 1, 1}, -- Zul'Drak
    [123] = {100, -1, -1, 1, 1}, -- Wintergrasp

  --Pandaria
    [379] = {100, 0.12, 0.20, 0.61, 0.56}, -- Kun-Lai Summit

  --Broken Isles
    [650] = {100, 0.44, 0.68, 0.64, 1}, -- Highmountain

  --Kul Tiras--
    [942] = {250, 0, 0.80, 0.34, 1}, -- Stormsong Valley
    [895] = {100, 0.34, 0.54, 0.46, 0.16}, -- Trragarde Sound
    [896] = {150, 0.31, 0.48, 0.60, 0.96}, -- Drustvar

    --Test--
    --[971] = {200, -1, -1, 1, 1},
}

--[[
    SnowCounter For Debugging
local number = 0;
local SnowCounter = CreateFrame("Frame","SnowCounter", UIParent)
local Total = SnowCounter:CreateFontString("TotalSnow", "OVERLAY", "GameFontNormal")
Total:SetText(number)
Total:SetPoint("LEFT", "UIParent", "LEFT", 0, 0)
--]]

local ScreenWidth, ScreenHeight = GetScreenWidth(), GetScreenHeight();
ScreenHeight = 1100;

local SnowContainer = CreateFrame("Frame", "SnowContainer", Narci_ScreenFilter)
SnowContainer:SetFrameStrata("BACKGROUND")
SnowContainer:Hide();

local animIn = SnowContainer:CreateAnimationGroup();

local a1 = animIn:CreateAnimation("Alpha");
a1:SetOrder(1)
a1:SetFromAlpha(1);
a1:SetDuration(0);
a1:SetToAlpha(0);

local a11 = animIn:CreateAnimation("Alpha");
a11:SetOrder(2)
a11:SetFromAlpha(0);
a11:SetDuration(2);
a11:SetToAlpha(1);

animIn:SetScript("OnPlay", function(self)
    self:GetParent():Show()
end);	


local animOut = SnowContainer:CreateAnimationGroup();

local a2 = animOut:CreateAnimation("Alpha");
a2:SetFromAlpha(1);
a2:SetDuration(1);
a2:SetToAlpha(0);

animOut:SetScript("OnFinished", function(self)
    self:GetParent():Hide()
end);


local function SnowGenerator()
    local SnowFrame = CreateFrame("Frame", nil, SnowContainer)

    local Snow = SnowFrame:CreateTexture(nil, "BACKGROUND")
    local distribution = random(1,12);
    local depth;
    if distribution <= 10 then
        depth = math.random(4,24);
        SnowFrame:SetFrameLevel(1)
    else
        depth = math.random(24,48);
        if distribution == 12 then
            SnowFrame:SetFrameLevel(7)
        else
            SnowFrame:SetFrameLevel(1)
        end
    end
    
    local texIndex = math.random(4);
    local StartLocation = math.random(ScreenWidth);
    local size = depth;
    local tex = SnowTexture[texIndex];
    local duration = 180/depth
    local SnowAlpha;

    if size >= 24 then
        TotalSnow = TotalSnow + 4;
        SnowAlpha = math.random(20,40)/100
    elseif size >= 8 then
        TotalSnow = TotalSnow + 1;
        SnowAlpha = math.random(60,90)/100
    else
        TotalSnow = TotalSnow + 0.25;
        SnowAlpha = math.random(80,95)/100
    end

    Snow:SetTexture(tex);
    Snow:SetSize(size, size);
    Snow:SetScale(random(75,125)/100, random(50,150)/100)
    Snow:SetPoint("BOTTOMLEFT", "UIParent", "TOPLEFT", StartLocation, 0)

    local ag = Snow:CreateAnimationGroup();
    
	local t1 = ag:CreateAnimation("Translation");
	t1:SetOrder(1);
	t1:SetOffset(random(0,400)*(-1)^random(1,2), -ScreenHeight-200);
    t1:SetDuration(duration);
    
    local r2 = ag:CreateAnimation("Rotation")
    r2:SetOrder(1);
    r2:SetDegrees(270)
    r2:SetDuration(duration);

    local a3 = ag:CreateAnimation("Alpha");
    a3:SetFromAlpha(SnowAlpha);
    a3:SetDuration(0);
    a3:SetToAlpha(SnowAlpha);

    ag:SetScript("OnPlay", function(self)
        self:GetParent():Show();
        self:GetParent():SetAlpha(0.5)
    end);

    ag:SetScript("OnFinished", function(self)
        if TotalSnow < SnowDensity then
            self:GetParent():SetPoint("BOTTOMLEFT", "UIParent", "TOPLEFT", math.random(ScreenWidth), 0)
            self:Play();
        else
            TotalSnow = TotalSnow -2
            self:GetParent():SetAlpha(0)
            --print("Hide")
        end
    end);
	ag:SetScript("OnPause", function(self)
        self:GetParent():Hide();
    end);
    ag:SetScript("OnStop", function(self)
        self:GetParent():Hide();
    end);

    --ag:SetLooping("REPEAT")
    ag:Play();
end

local function FakeCollision()
    TotalFakeSnow = TotalFakeSnow + 1
    local wise = (-1)^math.random(2)
    local FakeCollision = CreateFrame("Frame", "FakeCollision", SnowContainer)

    local Snow2 = FakeCollision:CreateTexture(nil, "BACKGROUND")
    --local distribution = random(1,12);
    local StartLocation, depth;
    local texIndex = math.random(3);
    local tex = SnowTexture[texIndex];
    local StartLocation = math.random((ScreenWidth/4), (ScreenWidth*3/4));
    --depth = 50;
    local size = math.random(20,40);
    Snow2:SetTexture(tex);
    Snow2:SetSize(size, size);
    local startDelay, fallingTime;
    startDelay = math.random(233)/10 + TotalFakeSnow/5
    fallingTime = math.random(6,12)/10
    Snow2:SetRotation(math.random(0, 90)/10);
    --Snow2:SetScale(random(75,125)/100, random(50,150)/100)
    
    Snow2:SetPoint("BOTTOMLEFT", "UIParent", "TOPLEFT", StartLocation, size-40)
    Snow2:SetAlpha(0)

    local ag = Snow2:CreateAnimationGroup()

    local a1 = ag:CreateAnimation("Alpha")
    a1:SetOrder(1);
    a1:SetFromAlpha(0)
    a1:SetToAlpha(random(20,70)/100)
    a1:SetDuration(0);

    local r1 = ag:CreateAnimation("Rotation")
    r1:SetOrder(1);
    r1:SetDegrees(wise*30)
    r1:SetDuration(fallingTime);

    local r2 = ag:CreateAnimation("Rotation")
    r2:SetOrder(2);
    r2:SetDegrees(wise*45)
    r2:SetDuration(0.2);

    local r3 = ag:CreateAnimation("Rotation")
    r3:SetOrder(3);
    r3:SetDegrees(wise*360)
    r3:SetDuration(2);

	local t1 = ag:CreateAnimation("Translation");
	t1:SetOrder(1);
	t1:SetOffset(-wise*5, -187*0.8/UIScale);
    t1:SetDuration(fallingTime);

	local t2 = ag:CreateAnimation("Translation");
	t2:SetOrder(2);
	t2:SetOffset(-wise*10, -4);
    t2:SetDuration(0.2);

	local t3 = ag:CreateAnimation("Translation");
	t3:SetOrder(3);
	t3:SetOffset(-wise*40, -100);
    t3:SetDuration(2);

    a1:SetStartDelay(startDelay)
    r1:SetStartDelay(startDelay)
    t1:SetStartDelay(startDelay)
    
    ag:SetScript("OnFinished", function(self)
        if TotalFakeSnow <= SnowDensity/10 then
            self:GetParent():SetPoint("BOTTOMLEFT", "UIParent", "TOPLEFT", math.random(ScreenWidth/4,ScreenWidth*3/5), 0)
            self:Play();
        else
            TotalFakeSnow = TotalFakeSnow -1
            self:GetParent():SetAlpha(0)
        end
    end);
	ag:SetScript("OnPause", function(self)
        self:GetParent():Hide();
    end);
    ag:SetScript("OnStop", function(self)
        self:GetParent():Hide();
    end);

    ag:Play()
end

local throttle, counter= 0.05, 0


SnowContainer:SetScript("OnUpdate", function(self, elapsed)
    counter = counter + elapsed
    if counter < throttle then
        return
    end
    counter = 0
    if TotalSnow < SnowDensity then
        SnowGenerator();
        if TotalFakeSnow < SnowDensity/10 then
            --print("fake")
            --FakeCollision()
        end
    else
        SnowContainer:SetScript("OnUpdate", function(self, elapsed)
        end)
    end
end);

local mapID = C_Map.GetBestMapForUnit("player");
local Px, Py = 0, 0;

local function GetPlayerPosition(MapID)
    local positionTable;
    positionTable = C_Map.GetPlayerMapPosition(MapID, "player")

    if positionTable ~= nil then
        Px, Py = positionTable:GetXY();
    else
        Px, Py = 0, 0
    end
end

function Narci_SnowEffect(switch)
    mapID = C_Map.GetBestMapForUnit("player");
    --print(mapID)
    if mapID ~= nil then
        GetPlayerPosition(mapID);
    else
        return;
    end
    if switch == true and IsOutdoors() and (not IsSubmerged()) and NarcissusDB.WeatherEffect then
        if SnowyLand[mapID] ~= nil and (Px > SnowyLand[mapID][2] and Px < SnowyLand[mapID][4]) and (Py > SnowyLand[mapID][3] and Py < SnowyLand[mapID][5]) then
            FadeFrame(Narci_ScreenFilter, 2, "IN");
            SnowDensity = SnowyLand[mapID][1]
            animOut:Stop();
            animIn:Play();
        end
    elseif switch == false then
        if ScreenFilter:IsShown() then
            FadeFrame(Narci_ScreenFilter, 1, "OUT");
        end
        animIn:Stop();
        animOut:Play();
    end
end