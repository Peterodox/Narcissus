local _, addon = ...
local currentVersion = 10500;
local lastMajorVersion = 0;
local _, _, _, tocversion = GetBuildInfo();
tocversion = tonumber(tocversion);

local TEST_ALAWYS_SHOW = false;
-----------------------------------------------------------------

local function ApplyPatchFix(self)
    --Apply fix--
    --None
    return;
end

local After = C_Timer.After;
local FadeFrame = NarciAPI_FadeFrame;
local UIFrameFadeIn = UIFrameFadeIn;
local UIFrameFadeOut = UIFrameFadeOut;
local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;
local pi = math.pi;
local sin = math.sin;
local cos = math.cos;
local pow = math.pow;
local L = Narci.L;

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end


--New Splash--
local MainFrame, PreviewFrame;

------------------------------------------------------------------
local playerOffsetX = 0;
local playerOffsetZ = -0.5;
local playerModelInfo;
local PI = math.pi;
local facing = -PI/2.5;
local ModelOffsets = {
    --[raceID] = {Eye male's, female's, male's Z, female's Z}
    [1]  = {1.6, 1.5, -0.58, -0.6},		    -- Human
    [2]  = {1.6, 1.5, -0.54, -0.6},		    -- Orc bow
    [3]  = {1.7, 1.5, -0.3, -0.4},		    -- Dwarf
    [4]  = {1.6, 1.5, -0.67, -0.65},         -- Night Elf
    [5]  = {1.6, 1.5, -0.7, -0.54},		    -- UD **Changed
    [6]  = {1.9, 1.7, -0.6, -0.6},		    -- Tauren
    [7]  = {1.7, 1.7, -0.1, -0.2},		    -- Gnome
    [8]  = {1.6, 1.5, -0.72, -0.6},		    -- Troll  0.9414 too high?  
    [9]  = {1.8, 1.8, -0.32, -0.25},		-- Goblin
    [10] = {1.45, 1.4, -0.58, -0.6},        -- Blood Elf
    [11] = {1.6, 1.5, -0.6, -0.65},		    -- Goat
    [22] = {1.75, 1.5, -0.6, -0.6},         -- Worgen
    [24] = {1.85, 1.7, -0.42, -0.58},		-- Pandaren
    [27] = {1.45, 1.4, -0.72, -0.5},		-- Nightborne
    --[29] = {1, },             -- Void Elf
    --[28] = {490, 491},		-- Highmountain Tauren
    --[30] = {488, 489},		-- Lightforged Draenei
    [31] = {1.6, 1.5, -0.85, -0.76},		    -- Zandalari
    [32] = {1.7, 1.65, -0.7, -0.65},		-- Kul'Tiran
    --[34] = {499, nil},		-- Dark Iron Dwarf
    [35] = {1.7, 1.5, -0.3, -0.2},         -- Vulpera
    --[36] = {495, 498},		-- Mag'har
    --[37] = {929, 931},        -- Mechagnome
}

local AnimationPresets = {
    --Patch 8.3.0 Narcissus 1.0.8
    --[raceID] = {male's, female's}
    --/run SetSplashModelAnimation()
    [1]  = {860, 1240},		    -- Human
    [2]  = {860, 988},		    -- Orc bow
    [3]  = {860, 860},		    -- Dwarf
    [4]  = {860, 52},           -- Night Elf
    [5]  = {944, 860},		    -- UD
    [6]  = {944, 1330},		    -- Tauren
    [7]  = {940, 944},		    -- Gnome
    [8]  = {1330, 860},		    -- Troll
    [9]  = {944, 944},		    -- Goblin
    [10] = {940, 988},          -- Blood Elf
    [11] = {988, 988},		    -- Goat
    [22] = {944, 988},          -- Worgen
    [24] = {732, 1448},		    -- Pandaren
    [27] = {988, 944},  		-- Nightborne
    [31] = {988, 860},		    -- Zandalari
    [32] = {1240, 1330},		-- Kul'Tiran
    [35] = {862, 860},         -- Vulpera 125 4
}

local SplashModelAnimationID = 860;
local function SetModelOffset()
    local unit = "player";
    local _, _, raceID = UnitRace(unit);
    local genderID = UnitSex(unit);
    if genderID and raceID then
        genderID = genderID - 1;
    else
        return
    end
    if raceID == 25 or raceID == 26 then --Pandaren A|H
        raceID = 24;
    elseif raceID == 29 then
        raceID = 10;
    elseif raceID == 37 then
        raceID = 7;
    elseif raceID == 30 then
        raceID = 11;
    elseif raceID == 28 then
        raceID = 6;
    elseif raceID == 34 then
        raceID = 3;
    elseif raceID == 36 then
        raceID = 2;
    elseif raceID == 22 then
        local _, inAlternateForm = HasAlternateForm();
        if not inAlternateForm then
            --Wolf
            raceID = 22;
        else
            raceID = 1;
        end
    end

    --Set offsetX for a few
    if raceID == 11 then
        if genderID == 1 then
            playerOffsetX = 0.2;
        else
            playerOffsetX = -0.06;
        end
    elseif raceID == 2 then
        playerOffsetX = -0.05;
    elseif raceID == 5 then
        if genderID == 1 then
            playerOffsetX = 0;
        else
            playerOffsetX = -0.03;
        end
    elseif raceID == 24 then
        if genderID == 1 then
            playerOffsetX = -0.035;
        end
    elseif raceID == 31 then
        if genderID == 1 then
            playerOffsetX = -0.04;
        end
    elseif raceID == 35 then
        if genderID == 1 then
            playerOffsetX = -0.04;
        else
            playerOffsetX = 0.035;
        end
    elseif raceID == 10 then
        --***Changed
        playerOffsetX = 0.05;
    elseif raceID == 3 then
        if genderID == 1 then
            playerOffsetX = 0.03;
        end
    elseif raceID == 22 then
        if genderID == 1 then
            playerOffsetX = 0.11;
        else
            playerOffsetX = -0.02;
        end
    elseif raceID == 6 then
        if genderID == 1 then
            playerOffsetX = 0.03;
        end
    elseif raceID == 27 then
        if genderID == 1 then
            playerOffsetX = -0.04;
        else
            playerOffsetX = 0.02;
        end
    end
    
    local info = ModelOffsets[raceID];
    if info then
        playerOffsetZ = info[genderID + 2] or playerOffsetZ;
    end

    local animationID = AnimationPresets[raceID][genderID];
    if animationID then
        --defalut 860
        SplashModelAnimationID = animationID;
    end
end


local function SetPlayerModel(model, visualIDs, animationID, fullBody, isReverseSpeed)
    local playerActor = model.narciPlayerActor;
    ------
    playerActor:ClearModel()
    playerActor:SetAlpha(0);
    local camera = model.narciPlayerCamera;
    model:SetActiveCamera(camera);

    --must-do
    playerActor:SetSpellVisualKit(nil)      
    playerActor:SetModelByUnit("player");
    ------

    After(0.0, function()
        playerActor:SetSheathed(true);
        playerActor:SetAlpha(1);
        model:InitializeActor(playerActor, playerModelInfo);   --Re-scale
        local zoom;
        if fullBody then
            playerActor:SetYaw(-3.14/3);
            playerActor:SetPosition(0, 0, 0);
            zoom = 3.8;
        else
            playerActor:SetYaw(facing);
            playerActor:SetPosition(playerOffsetX, 0, playerOffsetZ);
            zoom = NarciAPI_GetCameraZoomDistanceByUnit("player");
        end

        if isReverseSpeed then
            playerActor:SetAnimation(animationID, 0, 0.25, 0);
        else
            playerActor:SetAnimation(animationID, 0, 0.25, 0);
        end
        playerActor:UndressSlot(1); --Remove helm
        playerActor:UndressSlot(17)
        playerActor:UndressSlot(16)
        camera:SetZoomDistance(1);
        camera:SnapAllInterpolatedValues();
        After(0.0, function()
            camera:SetZoomDistance(zoom);
            if visualIDs then
                local _type = type(visualIDs);
                if _type == "number" then
                    playerActor:SetSpellVisualKit(visualIDs);
                elseif _type == "table" then
                    for i = 1, #visualIDs do
                        playerActor:SetSpellVisualKit(visualIDs[i]);
                    end
                end
            else
                playerActor:SetSpellVisualKit(nil);
            end

            --playerActor:SetDesaturation(0.6);
        end)
    end);
end

-------------------------------------------------------------------------------------
--[[
local BarberAssets = {};
BarberAssets.filePath = "Interface/AddOns/Narcissus/Art/Splash/BarberShop/";
BarberAssets.seaLevel = -1;
BarberAssets.defaultFacing = pi;
BarberAssets.Lighting = {
    dirX = -0.0349, dirY = -0.6435, dirZ = -0.7646,
    dirR = 0.8, dirG = 0.65, dirB = 0.6,
    ambR = 0.8, ambG = 0.65, ambB = 0.6,
};
BarberAssets.ActorInfo = {
    {name = "Barber", displayID = 25955, facing = pi*0.05, position = {2.5, 0.7, 0}, animation = {69, 2, 1, 0}, front = true },
    {name = "PoleGround", fileID = 194749, facing = 0, position = {7, 2.4, -0.7}, front = true},
    {name = "PoleWall", fileID = 194750, facing = -pi*0.25, position = {20, -0.3, 1.3},},
    {name = "Bear", displayID = 65503, facing = -pi*0.6, position = {9, -1.2, -0.3}, },
    {name = "Sergeant", displayID = 65663, facing = -pi*0.4, position = {9, -3.5, -0.4},},
    {name = "Orc", displayID = 86330, facing = -pi*0.4, position = {9, -4.4, -0.4},},
    {name = "Gold", fileID = 1455683, facing = 0, position = {6, 1, -0.4}, front = true},
    {name = "Grunt", displayID = 4259, facing = pi*0.5, position = {7, 3, -0.4}, animation = {4, 0, 0.34, 0}, spell = 111290,},
};

function BarberAssets:CreateScene()
    local Container = self.Container;
    Container.Background:SetTexture(self.filePath.."BarberShop");
    Container.BackgroundLeft:SetTexture(self.filePath.."BarberShop");

    local FrontScene = self.FrontScene;

    if self.Lighting then
        local info = self.Lighting;
        if info.dirX then
            Container:SetLightDirection(info.dirX, info.dirY, info.dirZ);
            FrontScene:SetLightDirection(info.dirX, info.dirY, info.dirZ);
        end
        if info.dirR then
            Container:SetLightDiffuseColor(info.dirR, info.dirG, info.dirB);
            FrontScene:SetLightDiffuseColor(info.dirR, info.dirG, info.dirB);
        end
        if info.ambR then
            Container:SetLightAmbientColor(info.ambR, info.ambG, info.ambB);
            FrontScene:SetLightAmbientColor(info.ambR, info.ambG, info.ambB);
        end
    end

    local seaLevel = self.seaLevel or 0;
    local defaultFacing = self.defaultFacing or 0;
    for i = 1, #self.ActorInfo do
        local info = self.ActorInfo[i];
        local actor;
        if info.front then
            actor = FrontScene:CreateActor();
        else
            actor = Container:CreateActor();
        end
        if info.displayID then
            actor:SetModelByCreatureDisplayID(info.displayID);
        elseif info.fileID then
            actor:SetModelByFileID(info.fileID);
        end
        if info.position then
            local x, y, z = unpack(info.position);
            actor:SetPosition(x, y, z + seaLevel);
        else
            actor:SetPosition(0, 0, seaLevel);
        end
        if info.animation then
            actor:SetAnimation(unpack(info.animation));
        else
            actor:SetAnimation(0, 0, 1, 0);
        end
        if info.facing then
            actor:SetYaw(defaultFacing + info.facing);
        end
        if info.spell then
            actor:SetSpellVisualKit(info.spell);
        end

        if info.name == "Grunt" then
            local GroundShadow = Container.GroundShadow;
            local animWalk= NarciAPI_CreateAnimationFrame(18);
            animWalk:SetScript("OnUpdate", function(frame, elapsed)
                frame.total = frame.total + elapsed;
                local offset = linear(frame.total, 6, -6, frame.duration);
                if frame.total > frame.duration then
                    frame:Hide();
                end
                actor:SetPosition(7, offset, -1.4);
                local x, y = Container:Project3DPointTo2D(7, offset, -1.4);
                GroundShadow:SetPoint("CENTER", Container, "BOTTOMLEFT", x, y);
            end);

            function self:PlayWalking()
                animWalk:Hide();
                animWalk:Show();
            end
            function self:StopWalking()
                animWalk:Hide();
                actor:SetPosition(7, 3, -1.4);
            end
        end
    end
end

function BarberAssets:CreateColorStrips()
    local Container = self.Container;
    local NUM_STRIPS = 8;
    local strips = {};
    local stripWidth = Container:GetWidth()/NUM_STRIPS;
    for i = 1, NUM_STRIPS do
        local strip = CreateFrame("Frame", nil, Container, "NarciSplashColorStripTemplate");
        tinsert(strips, strip);
        strip:SetPoint("BOTTOMLEFT", Container, "BOTTOMLEFT", (i - 1)*stripWidth, -60);
        strip:SetWidth(stripWidth);
        strip.Scroll:SetWidth(stripWidth);
        strip.Background:SetColorTexture(0.05, 0.05, 0.05);
        strip.Scroll:SetVertexColor(0.93, 0, 0.55);
        strip.t = (1 - i)/5;
    end

    local animStrip = NarciAPI_CreateAnimationFrame(3);
    animStrip:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        for i = 1, NUM_STRIPS do
            local strip = strips[i];
            strip.t = strip.t + elapsed;
            if strip.t > 0 then
                local height = inOutSine(strip.t, 560, 0, 1);
                if height <= 2 or strip.t > 1 then
                    strip:Hide();
                else
                    strip:SetHeight(height);
                end
            end
        end
        if frame.total >= frame.duration then
            frame:Hide();
        end
    end)

    function self:ResetStrips()
        for i = 1, NUM_STRIPS do
            strips[i]:Show();
            strips[i]:SetHeight(560);
            strips[i].t = (1 - i)/5;
        end
        self:StopWalking();
    end

    function self:PlayStrips()
        animStrip:Hide();
        animStrip:Show();
        self:PlayWalking();
    end
end

function BarberAssets:CreateLogo()
    local Container = self.Container;
    Container.TextBottomRight:SetText(L["Flavored Text"] .."\n|cfff8b0deZa uul og nuq i fssh zz oou iiyoq ez oou 10‰ gul'kafh anagg.|r");

    local LogoFrame = CreateFrame("Frame", "LOGO", Container, "NarciSplashSponsorFrameTemplate");
    LogoFrame:SetPoint("CENTER", Container, "CENTER", 0, 0);
    LogoFrame.Logo:SetTexture( self.filePath.."Logo");
    local Text = LogoFrame.SponsoredBy;
    Text:SetTextColor(0.5, 0.5, 0.5);
    Text:SetAlpha(0);

    local OilActor = Container:GetParent().VFX:CreateActor();
    OilActor:SetModelByFileID(916495);
    OilActor:SetPitch(pi/2);
    OilActor:SetPosition(6, 0, 0);
    OilActor:SetAlpha(0);

    local animText = NarciAPI_CreateAnimationFrame(1.5);
    local animFlyIn = NarciAPI_CreateAnimationFrame(0.5);
    local animLogo = NarciAPI_CreateAnimationFrame(1);

    animText.object = Text;
    animText:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            animFlyIn:Show();
            OilActor:Show();
        end
    end)

    animFlyIn.object = LogoFrame.Logo;
    animFlyIn:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local alpha = frame.total/0.5;
        if alpha > 1 then
            alpha = 1;
        end
        local scale = outQuart(frame.total, 0.5, 1, frame.duration);

        if frame.total >= frame.duration then
            alpha = 1;
            scale = 1;
            frame:Hide();
            After(3, function()
                self:PlayStrips();
                After(0.75, function()
                    animLogo:Show();
                end)
            end);
        end
        frame.object:SetAlpha(alpha);
        frame.object:SetScale(scale);
        OilActor:SetAlpha(alpha);
        Text:SetAlpha(alpha);
    end)


    animLogo:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local x = outSine(frame.total, 0, -300, frame.duration);
        local y = outSine(frame.total, 0, 170, frame.duration);
        local scale = outSine(frame.total, 1, 0.6, frame.duration);
        local alpha = 1 - frame.total/0.5;
        if alpha < 0 then
            alpha = 0;
            Text:Hide();
            OilActor:Hide();
        end
        if scale < 0.6 then
            scale = 0.6;
        end
        if frame.total >= frame.duration then
            x = -300;
            y = 170;
            scale = 0.6;
            alpha = 0;
            frame:Hide();
        end
        Text:SetAlpha(alpha);
        OilActor:SetAlpha(alpha);
        LogoFrame.Logo:SetScale(scale);
        LogoFrame:SetPoint("CENTER", Container, "CENTER", x, y);
    end);

    function self:StartAnimation()
        animFlyIn:Hide();
        animText:Hide();
        animLogo:Hide();
        OilActor:SetAlpha(0);
        Text:SetAlpha(0);
        --Container.Background:SetAlpha(0);
        Container:SetScale(1);
        LogoFrame:SetPoint("CENTER", Container, "CENTER", 0, 0);
        LogoFrame.Logo:SetAlpha(0);
        LogoFrame.Logo:SetScale(1);
        Text:Show();
        self:ResetStrips();
        animText:Show();
    end
end
--]]


local UpdateFrame = CreateFrame("Frame");
UpdateFrame:Hide();
UpdateFrame.t = 0;
UpdateFrame.duration = 0.5;
local function OnUpdateFunc(self, elapsed)
    self.t = self.t + elapsed;
    local modelOffset = inOutSine(self.t, self.startX, self.endX, self.duration);
    local frameOffset = inOutSine(self.t, self.textstartX, self.textendX, self.duration);
    local scale = outSine(self.t, self.startScale, self.endScale, self.duration);
    if self.t >= self.duration then
        modelOffset = self.endX;
        frameOffset = self.textendX;
        scale = self.endScale;
        self:Hide();
    end
    self.welcome:SetPoint("LEFT", modelOffset, 0);
    self.note:SetPoint("LEFT", frameOffset , 0);
    self.preview:SetScale(scale);
end

UpdateFrame:SetScript("OnUpdate", OnUpdateFunc);
UpdateFrame:SetScript("OnHide", function(self)
    self.t = 0;
end);

local function FlyOutModel()
    local f = MainFrame;
    local clip = f.ClipFrame;
    local UpdateFrame = UpdateFrame;
    if not UpdateFrame.frame then
        UpdateFrame.welcome = clip.ItemShop;
        UpdateFrame.note = clip.NoteFrame;
        UpdateFrame.preview = clip.Preview;
    end

    if UpdateFrame:IsShown() then return end;

    if f.IsExpanded then
        --Hide patch note
        UpdateFrame.startX = 180;
        UpdateFrame.endX = 0;
        UpdateFrame.textstartX = 0;
        UpdateFrame.textendX = -100;
        UpdateFrame.startScale = 1;
        UpdateFrame.endScale = 1;
        --FadeFrame(clip.ModelScene, UpdateFrame.duration, "IN");
        --UIFrameFadeIn(clip.AssetContainer, UpdateFrame.duration, 0, 1);
        FadeFrame(clip.ItemShop, UpdateFrame.duration, "IN");
        FadeFrame(clip.NoteFrame, 0.45, "OUT");
        FadeFrame(clip.Preview, 0.25, "OUT");

        if not clip.ItemShop.isPlayed then
            clip.ItemShop:PlayEntrance();
        end
        --button visual
        f.LogoButton:Hide();
        f.LogoButton.Text:SetText(SPLASH_BASE_HEADER);
        f.LogoButton.Text.Bling:Play();
    else
        --Show patch note
        UpdateFrame.startX = 0;
        UpdateFrame.endX = 180;
        UpdateFrame.textstartX = -100;
        UpdateFrame.textendX = 0;
        UpdateFrame.startScale = 1.5;
        UpdateFrame.endScale = 1;
        --FadeFrame(clip.ModelScene, UpdateFrame.duration, "OUT");
        --UIFrameFadeOut(clip.AssetContainer, UpdateFrame.duration, 1, 0);
        FadeFrame(clip.ItemShop, UpdateFrame.duration, "OUT");
        FadeFrame(clip.NoteFrame, 0.35, "IN");
        FadeFrame(clip.Preview, 0.5, "IN");

        --button visual
        FadeFrame(f.LogoButton, 0.2, "Forced_IN");
        local version = NarciAPI.GetAddOnVersionInfo(true);
        f.LogoButton.Text:SetText(string.format("|cff"..NARCI_COLOR_CYAN_DARK.. L["Splash Whats New Format"], version));
        f.LogoButton.Text.Bling:Stop();
    end 
    f.IsExpanded = not f.IsExpanded;
    
    UpdateFrame:Show();
end


local function LogoButton_OnClick(self)
    FlyOutModel();
end

--The text will then be replaced
local PatchNotes = {
    {category = "Photo Mode",
        contents = {
            {name = "Weapon Browser", description = "-", hasPicture = true},
            {name = "Character Select Screen", description = "-", hasPicture = true},
            {name = "Dressing Room", description = "-", hasPicture = true},
            {name = "NPC Brwoser", description = "-", },
        },
    },

    {category = "Character Frame",
        contents = {
            {name = "Shard of Domination", description = "-", hasPicture = true},
            {name = "Soulbinds", description = "-", hasPicture = true},
            {name = "Visuals", description = "-"},
        },
    },
};


local function SetUpSplash(SplashFrame)
    --Model
    --[[
    local ModelScene = SplashFrame.ClipFrame.ModelScene;
    local FrontScene =  ModelScene.FrontScene;
    local actor = NarciAPI_SetupModelScene(ModelScene, nil, 3, "FRONT");
    local actor = NarciAPI_SetupModelScene(FrontScene, nil, 3, "FRONT");
    NarciAPI_SetupModelScene(SplashFrame.ClipFrame.VFX, nil, 3, "FRONT");
    BarberAssets.Container = ModelScene;
    BarberAssets.FrontScene = FrontScene;
    BarberAssets:CreateColorStrips();
    BarberAssets:CreateLogo();
    BarberAssets:CreateScene();
    --]]

    --Create Patch Notes
    local NoteFrame = SplashFrame.ClipFrame.NoteFrame;
    local ScrollChild = NoteFrame.ScrollFrame.ScrollChild;
    ScrollChild:SetSize(NoteFrame:GetSize());

    local data;
    local frameHeight = 0;
    local numText = 0;
    for i = 1, #PatchNotes do
        data = PatchNotes[i];
        local Header = ScrollChild:CreateFontString(nil, "OVERLAY", "NarciSplashHeaderTemplate");
        Header:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 50, -frameHeight);
        Header:SetText(L["Splash Category"..i]);--data.category
        frameHeight = frameHeight + Header:GetHeight() + 12;

        local Arrow = ScrollChild:CreateTexture(nil, "OVERLAY");
        Arrow:SetSize(32, 32);
        Arrow:SetTexture("Interface\\AddOns\\Narcissus\\ART\\Splash\\Pointer-Right");
        Arrow:SetPoint("RIGHT", Header, "LEFT", -4, 2);

        for j = 1, #data.contents do
            local content = data.contents[j];
            local TextFrame = CreateFrame("Frame", nil, ScrollChild, "NarciSplashInteractiveTextFrame");
            TextFrame:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 50, -frameHeight);
            numText = numText + 1;
            local textHeight = TextFrame:SetUpFrame(numText, L["Splash Content"..numText.." Name"], L["Splash Content"..numText.." Description"], content.hasPicture);
            frameHeight = frameHeight + textHeight + 16;
        end
        
        frameHeight = frameHeight + 8;
    end

    local deltaRatio = 1;
    local speedRatio = 0.2;
    local positionFunc = function(endValue, delta, scrollBar, isTop, isBottom)if isBottom then scrollBar.BottomArrow:Hide() end end;
    local buttonHeight = 80;
    local range = frameHeight - NoteFrame.ScrollFrame:GetHeight();

    NarciAPI_ApplySmoothScrollToScrollFrame(NoteFrame.ScrollFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range);
end


NarciInteractveSplashMixin = {};

function NarciInteractveSplashMixin:OnLoad()
    MainFrame = self;
    PreviewFrame = self.ClipFrame.Preview;

    tinsert(UISpecialFrames, self:GetName());
    SetUpSplash(self);
    self.LogoButton:SetScript("OnClick", LogoButton_OnClick);

    --Item Shop
    self.ClipFrame.ItemShop.Header.Logo1:SetScript("OnClick", LogoButton_OnClick);
end

function NarciInteractveSplashMixin:OnShow()
    --BarberAssets:StartAnimation();
end

function NarciInteractveSplashMixin:OnEnter()
    --FadeFrame(self.CloseButton, 0.25, "IN");
    FadeFrame(self.LogoButton.Text, 0.25, "IN");
end

function NarciInteractveSplashMixin:OnLeave()
    if self:IsMouseOver() then return end
    --NarciAPI_FadeFrame(self.CloseButton, 0.25, "OUT");
    if not self.LogoButton.IsExpanded then
        NarciAPI_FadeFrame(self.LogoButton.Text, 0.15, "OUT");
    end
end

function NarciInteractveSplashMixin:OnHide()
    self:SetAlpha(0);
    self:StopAnimating();
end


local function CreateSplashFrame()
    if not Narci_InteractiveSplash then
        local frame = CreateFrame("Frame", "Narci_InteractiveSplash", nil, "NarciInteractiveSplashTemplate");
    end
end

local function ShowSplash()
    FadeFrame(Narci_InteractiveSplash, 0.25, "Forced_IN");
    --Narci_InteractiveSplash.ClipFrame.ItemShop:PlayEntrance();
end


local EventListener = CreateFrame("Frame");
if tocversion > 89999 then
    EventListener:RegisterEvent("ADDON_LOADED");
end

function EventListener:AttempToOpenSplash()
    if (CinematicFrame and CinematicFrame:IsShown()) or (MovieFrame and MovieFrame:IsShown()) then
        self:RegisterEvent("CINEMATIC_STOP");
    elseif (SplashFrame and SplashFrame:IsShown()) then
        return
        --[[
        if not self.splashFrameHooked then
            self.splashFrameHooked = true;
            SplashFrame:HookScript("OnHide", function()
                After(1, function()
                    ShowSplash();
                end)
            end);
        end
        --]]
    else
        ShowSplash();
    end
end

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Narcissus" then
            self:UnregisterEvent(event);
        else
            return
        end

        if currentVersion > NarcissusDB.Version or TEST_ALAWYS_SHOW then
            ApplyPatchFix();
            if NarcissusDB.Version < lastMajorVersion or TEST_ALAWYS_SHOW then
                self:RegisterEvent("GARRISON_UPDATE");
                self:RegisterEvent("LOADING_SCREEN_DISABLED");
                CreateSplashFrame();
            end

            NarcissusDB.Version = currentVersion;
        end

    elseif event == "LOADING_SCREEN_DISABLED" then
        self:UnregisterEvent(event);
        self.loadingScreenOff = true;
        if not self.hasPlayed and self.garrisonUpdated then
            self.hasPlayed = true;
            After(2.5, function()
                self:AttempToOpenSplash();
            end)
        end
    elseif event == "GARRISON_UPDATE" then
        self:UnregisterEvent(event);
        self.garrisonUpdated = true;
        if self.loadingScreenOff and not self.hasPlayed then
            self.hasPlayed = true;
            After(2.5, function()
                self:AttempToOpenSplash();
            end);
        end
    elseif event == "CINEMATIC_STOP" then
        self:UnregisterEvent(event);
        After(2, function()
            ShowSplash();
        end);
    end
end)




local RunDelayedFunction = NarciAPI_RunDelayedFunction;

local function ShowButtonTab(Preview, id)
    --Narcissus 1.0.9
    if true then
        return
    end

    --Narcissus 1.0.8
    if id == 2 then
        Preview.ButtonTab:Show();
    else
        Preview.ButtonTab:Hide();
    end
end


function NarciSplash_PreviewFadeIn_OnFinished(self)
    local Preview = PreviewFrame;    --Preview frame
    Preview.pauseUpdate = nil;
    self:GetParent():SetTexture(Preview.ImageBottom:GetTexture())
    self:GetParent():SetAlpha(1);
    Preview.ImageBottom:SetAlpha(0);
    if Preview:GetParent().NoteFrame:IsMouseOver() then
        local button = GetMouseFocus();
        if button then
            if button.isInteractive and button.hasPicture then
                local id = button.id;
                if id ~= Preview.id then
                    ShowButtonTab(Preview, id);
                    --------
                    Preview.pauseUpdate = true;
                    Preview.ImageBottom:SetTexture("Interface\\AddOns\\Narcissus\\ART\\Splash\\SplashIMG"..id);
                    Preview.ImageBottom:SetAlpha(1);
                    After(0.2, function()
                        Preview.ImageTop.fadeOut:Play();
                        After(0.5, function()
                            Preview.id = id;
                        end)
                    end) 
                end
            end
        end
    end
end

NarciSplashInteractiveTextMixin = {};

function NarciSplashInteractiveTextMixin:SetUpFrame(id, name, description, hasPicture)
    self.isInteractive = true;
    self.id = id;
    self.hasPicture = hasPicture;
    self.Text:SetText("|cffd8d8d8"..name.."|r\n"..description);
    local RGB = NarciAPI.ConvertHexColorToRGB(NARCI_COLOR_CYAN_DARK);
    self.Marker:SetColorTexture(RGB[1], RGB[2], RGB[3]);
    local textHeight = self.Text:GetHeight();
    self:SetHeight(textHeight);
    return textHeight
end

function NarciSplashInteractiveTextMixin:OnEnter()
    UIFrameFadeIn(self.Marker, 0.25, self.Marker:GetAlpha(), 1);
    self.Marker.scaleIn:Play();

    if not self.hasPicture then
        return
    end

    local id = self.id;
    local Preview = PreviewFrame;

    RunDelayedFunction(self, 0.25, function()
        if not Preview.pauseUpdate then
            Preview.pauseUpdate = true;
            Preview.ImageBottom:SetTexture("Interface\\AddOns\\Narcissus\\ART\\Splash\\SplashIMG"..id);
            Preview.ImageBottom:SetAlpha(1);
            After(0, function()
                Preview.ImageTop.fadeOut:Play();
                ShowButtonTab(Preview, id);
                After(0.5, function()
                    Preview.id = id;
                end)
            end)
        end
    end)
end

function NarciSplashInteractiveTextMixin:OnLeave()
    UIFrameFadeOut(self.Marker, 0.25, self.Marker:GetAlpha(), 0);
end



function Narci:ShowSplash()
    CreateSplashFrame();
    ShowSplash();
end



local function SelectionArrow_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local offsetY = inOutSine(self.t, self.fromY, self.toY, self.duration);
    if self.t >= self.duration then
        offsetY = self.toY;
        self:SetScript("OnUpdate", nil);
    end
    self.SelectionMarkLeft:SetPoint("CENTER", self, "LEFT", 0, offsetY);
    self.SelectionMarkRight:SetPoint("CENTER", self, "RIGHT", 0, -offsetY);
end

NarciSplashNavButtonMixin = {};

function NarciSplashNavButtonMixin:OnLoad()
    if self.destination == "changelog" then
        self.Backdrop:SetColorTexture(216/255, 189/255, 90/255);
        self.SelectionMarkLeft:SetVertexColor(4/255, 30/255, 60/255);
        self.SelectionMarkRight:SetVertexColor(4/255, 30/255, 60/255);
        self.Logo:SetTexture("Interface\\AddOns\\Narcissus\\ART\\Logos\\NarcissusLogoFlatMono128");
        self.Logo:SetVertexColor(4/255, 30/255, 60/255);
        local version = NarciAPI.GetAddOnVersionInfo(true);
        self.Title:SetText( string.format(L["Splash Whats New Format"], version) );
        self.Title:SetTextColor(4/255, 30/255, 60/255);
        --self.SelectionMarkLeft:Hide();
    else
        self.Backdrop:SetColorTexture(4/255, 30/255, 60/255);
        self.SelectionMarkLeft:SetVertexColor(216/255, 189/255, 90/255);
        self.SelectionMarkRight:SetVertexColor(216/255, 189/255, 90/255);
        self.Logo:SetTexture("Interface\\AddOns\\Narcissus\\ART\\Splash\\Mawmart\\BrandLogo128");
        self.Title:SetText( L["See Ads"] );
        self.Title:SetTextColor(1, 1, 1);
        --self.SelectionMarkRight:Hide();
    end
    local arrowSize = self.SelectionMarkLeft:GetHeight();
    local selfHeight = self:GetHeight();
    local vanishingOffset = (selfHeight + arrowSize)/2 + 2;
    self.vanishingOffset = vanishingOffset;
    self.SelectionMarkLeft:ClearAllPoints();
    self.SelectionMarkLeft:SetPoint("CENTER", self, "LEFT", 0, vanishingOffset);
    self.SelectionMarkRight:ClearAllPoints();
    self.SelectionMarkRight:SetPoint("CENTER", self, "RIGHT", 0, -vanishingOffset);
end

function NarciSplashNavButtonMixin:OnEnter()
    if not self.isShrinking then
        self.isShrinking = true;
        self.t = 0;
        local _, _, _, _, offsetY = self.SelectionMarkLeft:GetPoint();
        if offsetY ~= 0 then
            self.duration = 0.5 * math.abs( offsetY / self.vanishingOffset );
            self.fromY = offsetY;
            self.toY = 0;
            self:SetScript("OnUpdate", SelectionArrow_OnUpdate);
        end
    end
end

function NarciSplashNavButtonMixin:OnLeave()
    if self:IsMouseOver() then
        return
    end
    self.t = 0;
    self.isShrinking = false;
    self.t = 0;
    local _, _, _, _, offsetY = self.SelectionMarkLeft:GetPoint();
    if offsetY ~= self.vanishingOffset then
        self.duration = 0.5 * math.abs( 1 - offsetY / self.vanishingOffset );
        self.fromY = offsetY;
        self.toY = self.vanishingOffset;
        self:SetScript("OnUpdate", SelectionArrow_OnUpdate);
    end
end

function NarciSplashNavButtonMixin:OnClick()
    local container = self:GetParent();
    FadeFrame(container, 0.25, "OUT");
    container.SeeChangelog:Disable();
    container.SeeSplash:Disable();

    if self.destination == "changelog" then
        FlyOutModel();
    else
        Narci_InteractiveSplash.ClipFrame.ItemShop:PlayEntrance();
    end
end

function NarciSplashNavButtonMixin:OnHide()
    self:SetScript("OnUpdate", nil);
end

--Events Test--
--235326 Icecrown Sky
--/run SetSplashModelAnimation()

--[[
local EventListener = CreateFrame("Frame");
--EventListener:RegisterAllEvents()
--EventListener:RegisterEvent("CVAR_UPDATE")
--EventListener:RegisterEvent("CONSOLE_MESSAGE")
--EventListener:RegisterEvent("CHAT_MSG_SYSTEM")
--EventListener:RegisterEvent("PLAYER_STARTED_LOOKING");
--EventListener:RegisterEvent("PLAYER_LEAVING_WORLD");
--EventListener:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
--EventListener:RegisterEvent("PLAYER_FLAGS_CHANGED")
EventListener:RegisterEvent("UNIT_MODEL_CHANGED")
--EventListener:RegisterEvent("CRITERIA_UPDATE")
EventListener:SetScript("OnEvent",function(self,event,...)
	if event ~= "COMBAT_LOG_EVENT" and event ~= "COMBAT_LOG_EVENT_UNFILTERED" and event ~= "CHAT_MSG_ADDON"
    and event ~= "UNIT_COMBAT" and event ~= "ACTIONBAR_UPDATE_COOLDOWN" and event ~= "UNIT_AURA"

    and event ~= "GUILD_ROSTER_UPDATE" and event ~= "GUILD_TRADESKILL_UPDATE" and event ~= "GUILD_RANKS_UPDATE"
    and event ~= "UPDATE_MOUSEOVER_UNIT" and event ~= "CURSOR_UPDATE"
    and event ~= "NAME_PLATE_UNIT_ADDED" and event ~= "NAME_PLATE_UNIT_REMOVED" and event ~= "NAME_PLATE_CREATED"
    and event ~= "SPELL_UPDATE_COOLDOWN" and event ~= "SPELL_UPDATE_USABLE"
    and event ~= "BN_FRIEND_INFO_CHANGED" and event ~= "FRIENDLIST_UPDATE"
	and event ~= "MODIFIER_STATE_CHANGED" and event ~= "UPDATE_SHAPESHIFT_FORM" and event ~= "SOCIAL_QUEUE_UPDATE" and event ~= "COMPANION_UPDATE" and event ~= "UPDATE_MOUSEOVER_UNIT"
    and event ~= "COMPANION_UPDATE" and event ~= "UPDATE_INVENTORY_DURABILITY" 
    and event ~= "CHAT_MSG_TRADESKILLS" then
		print("Event: |cFFFFD100"..event)
		local name, value, value2, value3, value4, value5 = ...
		print(name)
		--print(value)
        --print(value2)
        --print("\n")
        print(IsFalling())
    end
end)

--To add a player into the scene, select a player in your sight and click + button.
--Click a selected button will temporarily hide its model.
--Drag a button to change the model's layer level.
--You may also change the race and gender by clicking the portrait.
--]]