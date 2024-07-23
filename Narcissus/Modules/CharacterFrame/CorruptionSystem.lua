--Narcissus Corruption Module for CharacterStatsPane
--Create a bar that shows: current corruption value and thresholds

local FILLED_BAR_HEIGHT = 75;

--Though contents will be localized\overwritten after login, I save these in case there's a bandwidth congestion caused by intalling too much addons.
local CorruptionEffectInfo = {
    [1] = {["name"] = "Grasping Tendrils", ["description"] = "Taking damage has a chance to reduce your movement speed for 5 sec. The magnitude of the snare increases with further Corruption."},
    [2] = {["name"] = "Eye of Corruption", ["description"] = "Your spells and abilities have a chance to summon an Eye of Corruption for 8 sec. The Eye inflicts increasing Shadow damage to you every 2 sec while you remain in range."},
    [3] = {["name"] = "Grand Delusions", ["description"] = "Taking damage has a chance to summon a Thing From Beyond, which pursues you for 8 sec. Its speed increases with further Corruption."},
    [4] = {["name"] = "Cascading Disaster", ["description"] = "If you are struck by the Thing From Beyond, you will be immediately afflicted by Grasping Tendrils and Eye of Corruption."},
    [5] = {["name"] = "Inevitable Doom", ["description"] = "All damage taken is magnified and healing received is reduced, increasing with further Corruption."},
};


local _, addon = ...
local OLD_CURRUPTION_LEVEL;

local L = Narci.L;
local FadeFrame = NarciAPI_FadeFrame;
local GetCorruptionResistance = GetCorruptionResistance;
local GetCorruption = GetCorruption;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local pi = math.pi;
local cos = math.cos;
local max = math.max;
local min = math.min;
local floor = math.floor;
local CR_VERSATILITY_DAMAGE_TAKEN = CR_VERSATILITY_DAMAGE_TAKEN;

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local AnimFrame = CreateFrame("Frame");
AnimFrame.t = 0;
AnimFrame.duration = 1;
AnimFrame:Hide();

local function UpdateDuration(self)
    self.duration = max(math.abs(self.endHeight - self.startHeight) / 92, 0.4);
end

local function OnShowFunc(self)
    self.t = 0;
    UpdateDuration(self);
end

local function CallBackFunc(self)
    self:Hide();
end

local function OnUpdateFunc(self, elapse)
    self.t = self.t + elapse;
    local height = inOutSine(self.t, self.startHeight, self.endHeight, self.duration);
    if self.t >= self.duration then
        height = self.endHeight;
        CallBackFunc(self);
    end
    self.Bar:SetHeight(height);
end

AnimFrame:SetScript("OnShow", OnShowFunc);
AnimFrame:SetScript("OnUpdate", OnUpdateFunc);

local function SetBarTexts(corruptionLevel, totalCorruption)
    local frame = Narci_CorruptionBar;
    local Ceiling, Floor;
    
    if corruptionLevel == 0 then
        Ceiling = GetCorruptionResistance() or 0;
        Floor = 0;
    elseif corruptionLevel == 1 then
        Ceiling = 20;
        Floor = 1;
    elseif corruptionLevel == 5 then
        Ceiling = 0;
        Floor = 80;
    else
        Ceiling = 20 * corruptionLevel;
        Floor = Ceiling - 20;      
    end

    local COLOR;
    if corruptionLevel < 1 then
        --When corruption level is 0, show total curruption and resistance
        COLOR = "|cffa59bb5";   --Purple
    elseif corruptionLevel < 2 then
        COLOR = "|cffdbbc34";   --Yellow
    elseif corruptionLevel < 4 then
        COLOR = "|cfff26522";   --Orange
    else
        COLOR = "|cffee3224";   --red
    end

    --Avoid text overlapping
    local diff = (Ceiling - totalCorruption)/(Ceiling - Floor);
    local offsetY = 0;
    if diff <= 0 or diff >= 1 then
        offsetY = 0;
    elseif diff <= 0.05 then
        offsetY = -7;
    elseif diff <= 0.1 then
        offsetY = -6;
    elseif diff >= 0.95 then
        offsetY = 7;
    elseif diff >= 0.9 then
        offsetY = 6;
    else
        offsetY = 0;
    end
    frame.Current:SetPoint("LEFT", frame.Fluid, "TOP", 7, offsetY);
    --

    local Current = totalCorruption.." "..COLOR..corruptionLevel .."|r";

    if Floor == 0 then
        Floor = "";
    end

    if Ceiling == 0 then
        Ceiling = "";
    end

    frame.Current:SetText(Current);
    frame.Ceiling:SetText(Ceiling);
    frame.Floor:SetText(Floor);
end

local function SmoothHeight(height, newCorruptionLevel, totalCorruption)
    if not AnimFrame.Bar then
        AnimFrame.Bar = Narci_CorruptionBar.Fluid;
    end

    AnimFrame:Hide();
    AnimFrame.startHeight = AnimFrame.Bar:GetHeight();

    if newCorruptionLevel > OLD_CURRUPTION_LEVEL then
        AnimFrame.endHeight = FILLED_BAR_HEIGHT;
        function CallBackFunc(self)
            OLD_CURRUPTION_LEVEL = newCorruptionLevel;
            AnimFrame.t = 0;
            AnimFrame.startHeight = 0;
            AnimFrame.endHeight = height;
            if newCorruptionLevel > 0 then
                AnimFrame.Bar:SetTexCoord(0.9375, 1, 0, 1);
            end
            UpdateDuration(self);
            SetBarTexts(newCorruptionLevel, totalCorruption);
            function CallBackFunc(self)
                self:Hide();
            end
        end
    elseif newCorruptionLevel < OLD_CURRUPTION_LEVEL then
        AnimFrame.endHeight = 0.01;
        function CallBackFunc(self)
            OLD_CURRUPTION_LEVEL = newCorruptionLevel;
            AnimFrame.t = 0;
            AnimFrame.startHeight = FILLED_BAR_HEIGHT;
            AnimFrame.endHeight = height;
            if newCorruptionLevel == 0 then
                AnimFrame.Bar:SetTexCoord(0.875, 0.9375, 0, 1);
            end
            UpdateDuration(self);
            SetBarTexts(newCorruptionLevel, totalCorruption);
            function CallBackFunc(self)
                self:Hide();
            end
        end
    else 
        AnimFrame.endHeight = height;
        function CallBackFunc(self)
            OLD_CURRUPTION_LEVEL = newCorruptionLevel;
            self:Hide();
        end
        SetBarTexts(newCorruptionLevel, totalCorruption);
    end
    AnimFrame.newCorruptionLevel = newCorruptionLevel;
    AnimFrame:Show();
end

function Narci_SetCorruptionBar(self, smooth)
	local corruption = GetCorruption();
	local corruptionResistance = GetCorruptionResistance();
    local totalCorruption = max(corruption - corruptionResistance, 0);

    local Ceiling, Floor, corruptionLevel;
    local barHeight;

	if corruption > 0 then
		if totalCorruption < 1 then
            Ceiling = corruptionResistance;
            Floor = 0;
			corruptionLevel = 0;
		elseif totalCorruption < 20 then
            Ceiling = 20;
            Floor = 1;
			corruptionLevel = 1;
		elseif totalCorruption < 40 then
            Ceiling = 40;
            Floor = 20;
			corruptionLevel = 2;
		elseif totalCorruption < 60 then
            Ceiling = 60;
            Floor = 40;
			corruptionLevel = 3;
        elseif totalCorruption < 80 then
            Ceiling = 80;
            Floor = 60;
            corruptionLevel = 4;
        else
            Ceiling = 80;
            Floor = 80;
            corruptionLevel = 5;    
        end

        if corruptionLevel == 5 then
            barHeight = FILLED_BAR_HEIGHT;
        elseif corruptionLevel == 0 then
            barHeight = max(FILLED_BAR_HEIGHT * corruption / Ceiling, 0.01);
            totalCorruption = corruption;
        else
            barHeight = max(FILLED_BAR_HEIGHT * (totalCorruption - Floor) / (Ceiling - Floor), 0.01);
        end

        if totalCorruption > 80 then
            --No cap when exceeding 80 corruption
            Ceiling = "";
        end
    else
        corruptionLevel = 0;
        Ceiling = "";
        Floor = "";
        barHeight = 0.01;
    end

    if smooth then
        SmoothHeight(barHeight, corruptionLevel, totalCorruption);
    else
        self.Fluid:SetHeight(barHeight);
        SetBarTexts(corruptionLevel, totalCorruption);
        OLD_CURRUPTION_LEVEL = corruptionLevel;
        if corruptionLevel == 0 then
            self.Fluid:SetTexCoord(0.875, 0.9375, 0, 1);
        else
            self.Fluid:SetTexCoord(0.9375, 1, 0, 1);
        end
    end
end

function Narci_CorruptionBar_OnEvent(self)
    if not self.IsRefreshing then
        self.IsRefreshing = true;
        C_Timer.After(0, function()
            Narci_SetCorruptionBar(self, true);
            self.IsRefreshing = nil;
        end)
    end
end

local format = string.format;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local function SetTooltipText(entry, text1, text2)
    local str;
    if text2 then
        str = format(entry.format, BreakUpLargeNumbers(text1), text2);
    else
        str = format(entry.format, text1);
    end
    entry.Effect:SetText(str);
end

local SetUpModel = NarciAPI_SetupModelScene;
local eyeOffset = 1.5;
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
    [4]  = {1.6, 1.5, -0.8, -0.65},         -- Night Elf
    [5]  = {1.6, 1.5, -0.54, -0.5},		    -- UD   0.9585 seems small
    [6]  = {1.9, 1.7, -0.6, -0.6},		    -- Tauren
    [7]  = {1.7, 1.7, -0.1, -0.2},		    -- Gnome
    [8]  = {1.6, 1.5, -0.58, -0.6},		    -- Troll  0.9414 too high?  
    [9]  = {1.8, 1.8, -0.32, -0.25},		-- Goblin
    [10] = {1.45, 1.4, -0.58, -0.6},        -- Blood Elf
    [11] = {1.6, 1.5, -0.6, -0.6},		    -- Goat
    [22] = {1.75, 1.5, -0.6, -0.6},         -- Worgen
    [24] = {1.85, 1.7, -0.42, -0.58},		-- Pandaren
    [27] = {1.45, 1.4, -0.72, -0.6},		-- Nightborne
    --[29] = {1, },             -- Void Elf
    --[28] = {490, 491},		-- Highmountain Tauren
    --[30] = {488, 489},		-- Lightforged Draenei
    [31] = {1.6, 1.5, -0.85, -0.8},		    -- Zandalari
    [32] = {1.7, 1.65, -0.6, -0.65},		-- Kul'Tiran
    --[34] = {499, nil},		-- Dark Iron Dwarf
    [35] = {1.7, 1.5, -0.3, -0.25},         -- Vulpera
    --[36] = {495, 498},		-- Mag'har
    --[37] = {929, 931},        -- Mechagnome
}

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
        end
    elseif raceID == 2 then
        playerOffsetX = -0.04;
    elseif raceID == 5 then
        if genderID == 1 then
            playerOffsetX = -0.05;
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
        playerOffsetX = -0.04;
    elseif raceID == 27 then
        if genderID == 2 then
            playerOffsetX = -0.06;
        end
    end
    
    local info = ModelOffsets[raceID];
    if info then
        eyeOffset = info[genderID] or eyeOffset;
        playerOffsetZ = info[genderID + 2] or playerOffsetZ;
    end
end

local playerSpeed = 1;    --Alter animation when corruption changes
local chasingSpeed = 0.25;
local ringScale = 0.32;     --
local ringOffset = -1.65;   --
local function CalculateAnimation(corruption)
    --Calculate running speed
    playerSpeed = max( (100 - corruption - 10) / 100, 0.1);
    chasingSpeed = max( (corruption - 15) / 100, 0.25);
    ringScale = 0.18 + max( (corruption - 20) / 200 , 0);
    ringOffset = min(-1.8 + ringScale , 0.5)
end

local function SetPlayerModel(model, visualIDs, animationID, fullBody, isReverseSpeed)
    local playerActor = model.narciPlayerActor;
    playerActor:ClearModel()
    playerActor:SetAlpha(0);
    local camera = model.narciPlayerCamera;
    model:SetActiveCamera(camera);

    --must-do
    playerActor:SetSpellVisualKit(nil)      
    playerActor:SetModelByUnit("player");
    ------

    C_Timer.After(0.0, function()
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
            playerActor:SetAnimation(animationID, 0, chasingSpeed, 0);
        else
            playerActor:SetAnimation(animationID, 0, playerSpeed, 0);
        end
        --playerActor:SetDesaturation(0);
        camera:SetZoomDistance(1.5);
        camera:SnapAllInterpolatedValues();
        C_Timer.After(0.0, function()
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
        end)
    end);
end

local function SetPreview(index)
    local model = Narci_CorruptionTooltip.ModelScene;
    if index == model.previewIndex then
        return
    else
        model.previewIndex = index;
    end

    if index == 1 then
        SetModelOffset();
        local effect1 = model.narciEffectActor1;
        if effect1 then
            effect1:Hide();
        end

        local effect2 = model.narciEffectActor2;
        if effect2 then
            effect2:Hide();
        end
        local actor = model.narciPlayerActor;
        if actor then
            actor:Hide();
        end
        
        local animationID;
        if playerSpeed > 0.6 then
            animationID = 5;
        else
            animationID = 4;
        end
        SetPlayerModel(model, {121838, 123875}, animationID, true, false);    --123874 Red 123875 Purple residue

    elseif index == 2 then
        SetUpModel(model, 3004122, 3, "FRONT", 1, true);
        SetUpModel(model, 943454, nil, {PI/12, PI}, 2);
        
        local effect1 = model.narciEffectActor1;
        effect1:SetPosition(0, 0, -1.65);
        effect1:SetRequestedScale(1);
        effect1:Show();
        E1 = effect1;
        local effect2 = model.narciEffectActor2;
        effect2:SetRequestedScale(ringScale);
        effect2:SetAnimation(158, 0, 0.5);
        effect2:SetPosition(0, 0, ringOffset);
        effect2:SetAlpha(1);
        effect2:Show();
        local actor = model.narciPlayerActor;
        if actor then
            actor:Hide();
        end
        
    elseif index == 3 then
        SetModelOffset();

        local effect1 = model.narciEffectActor1;
        if effect1 then
            effect1:SetAlpha(0);
            C_Timer.After(0, function()
                effect1:SetModelByFileID(611777);   --Fixate Eye
                effect1:SetPosition(0, 0, eyeOffset);
                effect1:SetRequestedScale(0.8);
                effect1:Show();
                effect1:SetAlpha(1);
            end)
        end

        local effect2 = model.narciEffectActor2;
        if effect2 then
            effect2:Hide();
        end

        local animationID;
        if chasingSpeed > 0.75 then
            animationID = 5;
        else
            animationID = 4;
        end
        SetPlayerModel(model, 111381, animationID, false, true);  --Ghost 111381
    
    elseif index == 4 then
        SetModelOffset();
        local effect1 = model.narciEffectActor1;
        if effect1 then
            effect1:Hide();
        end

        local effect2 = model.narciEffectActor2;
        if effect2 then
            effect2:Hide();
        end
        local actor = model.narciPlayerActor;
        if actor then
            actor:Hide();
        end
        SetPlayerModel(model, 78248, 4, false, false);
    elseif index == 5 then
        SetModelOffset();
        local effect1 = model.narciEffectActor1;
        if effect1 then
            effect1:Hide();
        end

        local effect2 = model.narciEffectActor2;
        if effect2 then
            effect2:Hide();
        end
        local actor = model.narciPlayerActor;
        if actor then
            actor:Hide();
        end
        SetPlayerModel(model, 123874, 4, false, false);
    end
end

local UIFrameFadeOut = UIFrameFadeOut;
local UIFrameFadeIn = UIFrameFadeIn;
local RunDelayedFunction = NarciAPI_RunDelayedFunction;
local function EntryButton_OnEnter(self)
    self.Pointer:Show();
    RunDelayedFunction(self, 0.2, function()
        UIFrameFadeOut(self.Effect, 0.15, self.Effect:GetAlpha(), 0); 
        UIFrameFadeOut(self.Name, 0.15, self.Name:GetAlpha(), 0);
        C_Timer.After(0.12, function()
            if self:IsMouseOver() then
                UIFrameFadeIn(self.Description, 0.15, 0, 1);
                if not self:IsEnabled() then
                    return
                end
                SetPreview(self.id);
            end
        end)
    end);
end

local function EntryButton_OnLeave(self)
    self.Pointer:Hide();
    local finalAlpha;
    if self:IsEnabled() then
        finalAlpha = 1;
    else
        finalAlpha = 0.4;
    end
    UIFrameFadeOut(self.Effect, 0.2, self.Effect:GetAlpha(), finalAlpha);
    UIFrameFadeOut(self.Name, 0.2, self.Name:GetAlpha(), 1);
    UIFrameFadeOut(self.Description, 0.2, self.Description:GetAlpha(), 0);
end

local function UpdateBarHeight(bar, effectiveCorruption)
    local totalHeight = bar:GetHeight();
    local tabHeight = totalHeight/5;
    local height;
    if effectiveCorruption == 1 then
        height = tabHeight;
    elseif effectiveCorruption == 0 then
        height = 0;
    else
        height = tabHeight + 0.8*totalHeight* (min( effectiveCorruption / 80, 1));
    end
    bar.FluidFrame:SetHeight(height);
end

local IsSpellKnown = IsSpellKnown;
local function GetMagicReduction()
    --Calculate passive reduction
    local r;
    if IsSpellKnown(203513) then
        r = 0.15;   --Demonic Wards Vengeance
    elseif IsSpellKnown(278386) then
        r = 0.1;    --Demonic Wards Havoc
    elseif IsSpellKnown(255668) or IsSpellKnown(59221) or IsSpellKnown(20579) then
        r = 0.01;   --1% Shadow DMG Racial VE, UD, Draenei  --Highmountain omitted
    else
        r = 0;
    end
    return (1-r)
end

local function GetConstantReduction()
    local r;
    if IsSpellKnown(255659) then
        r = UnitHealthMax("player") * 0.0003;   --Highmountain Tauren Racial Rugged Tenacity
    else
        r = 0;
    end
    return r
end

local function UpdateCorruptionTooltip()
    local corruption = GetCorruption();
    local corruptionResistance = GetCorruptionResistance();
    local corruption = max(corruption - corruptionResistance, 0);
    local frame = Narci_CorruptionTooltip;
    local slowBy, damageModifier, radius, delusionDamage, percentageHP;
    local entry;
    local level = 1;

    local HP = UnitHealthMax("player");
    local magicReduction = GetMagicReduction();
    local eyeDamage = (0.5*corruption + 15) * (HP/1000) * magicReduction;
    local delusionDamage = 0.35 * HP * magicReduction;

    if corruption >= 1 then
        level = 1;
        frame.Entry1:Enable();
        slowBy = min(corruption + 10, 99);
        damageModifier = max(corruption - 75, 0);
        radius = max(floor(10 * corruption / 4)/10, 5);
        if corruption >= 20 then
            level = 2;
            frame.Entry2:Enable();
            if corruption >= 40 then
                level = 3;
                frame.Entry3:Enable();
                if corruption >= 60 then
                    level = 4;
                    frame.Entry4:Enable();
                    if corruption >= 80 then
                        level = 5;
                        frame.Entry5:Enable();
                    else
                        frame.Entry5:Disable();
                    end
                else
                    frame.Entry4:Disable();
                    frame.Entry5:Disable();
                end
            else
                frame.Entry3:Disable();
                frame.Entry4:Disable();
                frame.Entry5:Disable();
            end
        else
            frame.Entry2:Disable();
            frame.Entry3:Disable();
            frame.Entry4:Disable();
            frame.Entry5:Disable();
        end
    else
        slowBy = 0;
        damageModifier = 0;
        radius = 5;
        for i = 1, 5 do
            entry = frame["Entry"..i];
            entry:Disable();
        end
    end

    CalculateAnimation(corruption);
    SetPreview(level);

    local reduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
    local constantReduction = GetConstantReduction();   --Reduction as constant instead of percentage

    eyeDamage = floor(eyeDamage * (1 + damageModifier / 100) * (1 - reduction/100) + 0.5 - constantReduction);
    delusionDamage = floor(delusionDamage * (1 + damageModifier / 100) * (1 - reduction/100) + 0.5 - constantReduction);  --change me when they fix the bug
    percentageHP = floor(10000 * delusionDamage / HP + 0.5) / 100;

    SetTooltipText(frame.Entry1, slowBy);
    SetTooltipText(frame.Entry2, eyeDamage, radius);
    SetTooltipText(frame.Entry3, delusionDamage, percentageHP);
    SetTooltipText(frame.Entry5, damageModifier);

    UpdateBarHeight(frame.CorruptionBar, corruption);

    local COLOR;    --for corruption value
    if level < 1 then
        --When corruption level is 0, show total curruption and resistance
        COLOR = "|cffa59bb5";   --Purple
    elseif level < 2 then
        COLOR = "|cffdbbc34";   --Yellow
    elseif level < 4 then
        COLOR = "|cfff26522";   --Orange
    else
        COLOR = "|cffee3224";   --red
    end

    frame.CorruptionBar.OverlayFrame.CorruptionValue:SetText(COLOR..corruption);
end

local function CorruptionTooltip_OnEvent(self)
    if not self.IsRefreshing then
        self.IsRefreshing = true;
        C_Timer.After(0, function()
            UpdateCorruptionTooltip(self, true);
            self.IsRefreshing = nil;
        end)
    end
end

local function CorruptionTooltip_OnShow(self)
    local bar = Narci_CorruptionBar;
    if bar:IsShown() then 
        UIFrameFadeOut(bar, 0.25, 0 ,0);
    end
    self:RegisterEvent("COMBAT_RATING_UPDATE");
    UpdateCorruptionTooltip();
end

local function CorruptionTooltip_OnHide(self)
    self:UnregisterEvent("COMBAT_RATING_UPDATE");
    local bar = Narci_CorruptionBar;
    if bar:IsShown() then
        UIFrameFadeIn(bar, 0.25, bar:GetAlpha() ,1);
    end
    self.ModelScene.previewIndex = -1;
    self:Hide();
    self:SetAlpha(0);
end

local function ShowOrHideModel()
    local state = NarcissusDB.CorruptionTooltipModel;
    local tooltip = Narci_CorruptionTooltip;
    local button = tooltip.ModelToggle;
    local model = tooltip.ModelScene;
    
    if state then
        button.tex1:SetTexCoord(0, 0.5, 0, 1);
        button.tex2:SetTexCoord(0.5, 1, 0, 1);
        button.tex3:SetTexCoord(0.5, 1, 0, 1);
        model:Show();
        tooltip:SetWidth(tooltip.expandedWidth);
        tooltip.CloseButton:Show();
    else
        button.tex1:SetTexCoord(0.5, 0, 0, 1);
        button.tex2:SetTexCoord(1, 0.5, 0, 1);
        button.tex3:SetTexCoord(1, 0.5, 0, 1);
        model:Hide();
        tooltip:SetWidth(tooltip.basicWidth);
        tooltip.CloseButton:Hide();     
    end

end

local function ModelToggle_OnClick(self)
    NarcissusDB.CorruptionTooltipModel = not NarcissusDB.CorruptionTooltipModel;
    ShowOrHideModel();
end

local function InitializeCorruptionTooltip()
    --Set up the constant: Spell name, icon
    local NUM_TAB = 5;
    local TAB_HEIGHT = 72;
    local BAR_WIDTH = 6;
    local frame = Narci_CorruptionTooltip;
    local entry;
    local icons = {537022, 3004126, 1391768, 1119888, 575534};
    local text;

    --Set Scripts
    frame:SetScript("OnEvent", CorruptionTooltip_OnEvent);
    frame:SetScript("OnShow", CorruptionTooltip_OnShow);
    frame:SetScript("OnHide", CorruptionTooltip_OnHide);
    frame.ModelToggle:SetScript("OnClick", ModelToggle_OnClick);

    --Sizing
    local basicWidth, basicHeight = frame.Entry1:GetSize();
    local totalHeight = basicHeight * NUM_TAB;
    local modelWidth = totalHeight * 3/4;
    local entryWidth = basicWidth;

    for i = 1, NUM_TAB do
        entry = frame["Entry"..i];
        entry.id = i;
        entry:SetHeight(TAB_HEIGHT);
        entry.Name:SetText(CorruptionEffectInfo[i].name);
        text = CorruptionEffectInfo[i].description;
        entry.Description:SetText(CorruptionEffectInfo[i].description);
        entry.format = L["Corruption Effect Format"..i];
        entry.Icon:SetTexture(icons[i]);
        entry.IconHighlight:SetTexture(icons[i]);
        entry:SetScript("OnEnter", EntryButton_OnEnter);
        entry:SetScript("OnLeave", EntryButton_OnLeave);
        entry:SetScript("OnClick", function(self)
            SetPreview(self.id);

            for p = 1, NUM_TAB do
                if p ~= i then
                    entry = frame["Entry"..p];
                    entry.Pointer:Hide();
                    entry.IsOn = false;
                end
            end
            self.Pointer:Show();
            self.IsOn = true;
        end);

        if i <= 3 then
            entry:Enable();
        end
    end
    SetTooltipText(frame.Entry4, "");

    local parentFrame = CharacterStatsPane.ItemLevelFrame.Corruption;
    C_Timer.After(0, function()
        for i = 1, NUM_TAB do
            entry = frame["Entry"..i];
            while entry.Description:IsTruncated() do
                entryWidth = frame.Entry1:GetWidth() + 10;
                frame.Entry1:SetWidth(entryWidth);
            end
        end

        local model = frame.ModelScene;
        model:SetWidth(modelWidth);
        local totalWidth = modelWidth + entryWidth + BAR_WIDTH;
        frame:SetSize(totalWidth, totalHeight);
        frame.basicWidth = entryWidth + BAR_WIDTH;
        frame.expandedWidth = totalWidth;
        local camera, playerActor;
        SetModelOffset();
        model:TransitionToModelSceneID(290, 1, 1, true);
        SetupPlayerForModelScene(model, nil, true, true);   --3 sheathWeapon
        playerActor = model:GetPlayerActor();
        playerActor:SetModelByUnit("player")
        model.narciPlayerActor = playerActor;
        camera = model:GetActiveCamera();
        camera.minZoomDistance = 1.5;
        model.narciPlayerCamera = camera;

        SetPreview(2);

        model.previewIndex = -1;
        if parentFrame then
            frame:ClearAllPoints();
            frame:SetParent(parentFrame);
            frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", -10, 12);
        else
            frame:Hide();
        end

        ShowOrHideModel();
        UpdateCorruptionTooltip();
    end)
end

--------------------------------------------------------------------------------------------------------
--Automatically toggle character pane when clicking upgrade item (Corrupting Core, Horrific Core)
--Show Highlight for backslot
local GetContainerItemID = GetContainerItemID;
local GetInventoryItemID = GetInventoryItemID;
local BlizzardCorruptionWidget_OnEnterFunction;
local BlizzardCorruptionWidget_OnLeaveFunction;

local function NewOnEnter(self)
    local frame = Narci_CorruptionTooltip;
    frame:ClearAllPoints();
    frame.ModelScene.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 1, 1, 1, 1, 0.1);
    frame:SetScale(1);
    frame:SetParent(CharacterFrame);
    frame:SetHitRectInsets(0, -32, -32, -24);
    frame:SetPoint("TOPLEFT", self, "TOPRIGHT", -10, 12);
    FadeFrame(frame, 0.2, "IN");

    --Original
	self.tooltipShowing = true;
    self.Eye:SetAtlas("Nzoth-charactersheet-icon-glow", true);
    PaperDollFrame_UpdateCorruptedItemGlows(true);
	PlaySound(SOUNDKIT.NZOTH_EYE_SQUISH);
end

local function NewOnLeave(self)
    local frame = Narci_CorruptionTooltip;
    if not frame:IsMouseOver(0, 0, -6, 0) then
        FadeFrame(frame, 0.2, "OUT");
    end
    --Original
	self.tooltipShowing = false;
	self.Eye:SetAtlas("Nzoth-charactersheet-icon", true);
    PaperDollFrame_UpdateCorruptedItemGlows(false);
end


local function ShowItemlevelAndCorruptionInfo(frame)
	if ( not frame.tooltip ) then
		return;
	end
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
	GameTooltip:SetText(frame.tooltip);
	if ( frame.tooltip2 ) then
		GameTooltip:AddLine(frame.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    local corruption = GetCorruption();
    if corruption > 0 then
        local corruptionResistance = GetCorruptionResistance();
        local totalCorruption = math.max(corruption - corruptionResistance, 0); 
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddColoredDoubleLine(GameTooltip, CORRUPTION_TOOLTIP_LINE, corruption, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR, false);
        GameTooltip_AddColoredDoubleLine(GameTooltip, CORRUPTION_RESISTANCE_TOOLTIP_LINE, corruptionResistance, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR, false);
        GameTooltip_AddColoredDoubleLine(GameTooltip, TOTAL_CORRUPTION_TOOLTIP_LINE, totalCorruption, CORRUPTION_COLOR, CORRUPTION_COLOR, false);
    end
end

--Preferences Corruption Tooltip Toggle--
local function ItemLevelFrame_OnEnter(self)
    ShowItemlevelAndCorruptionInfo(self);
	GameTooltip:Show();
end

local function ItemLevelFrame_withCorruptionTooltips_OnEnter(self)
    ShowItemlevelAndCorruptionInfo(self)
    CorruptionTooltips:SummaryHook(self);
	GameTooltip:Show();
end

function Narci:SetUseCorruptionTooltip()
    local ItemLevelFrame = CharacterStatsPane.ItemLevelFrame;
    local BlizzardCorruptionWidget = ItemLevelFrame.Corruption;
    if not BlizzardCorruptionWidget then return end

    local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
    local state = NarcissusDB.CorruptionTooltip;

    if state then
        GameTooltip_Hide();
        if IsAddOnLoaded("CorruptionTooltips") then
            ItemLevelFrame.onEnterFunc = ItemLevelFrame_withCorruptionTooltips_OnEnter;
        else
            ItemLevelFrame.onEnterFunc = ItemLevelFrame_OnEnter;
        end
        BlizzardCorruptionWidget:SetScript("OnEnter", NewOnEnter);
        BlizzardCorruptionWidget:SetScript("OnLeave", NewOnLeave);
    else
        ItemLevelFrame.onEnterFunc = nil;
        Narci_CorruptionTooltip:Hide();
        BlizzardCorruptionWidget:SetScript("OnLeave", CharacterFrameCorruption_OnLeave);

        if IsAddOnLoaded("CorruptionTooltips") then
            BlizzardCorruptionWidget:SetScript("OnEnter", function(self)
                CharacterFrameCorruption_OnEnter(self)
                CorruptionTooltips:SummaryHook(self);
            end)
        else
            BlizzardCorruptionWidget:SetScript("OnEnter", CharacterFrameCorruption_OnEnter);
        end
    end

    --Fix Compatible Issue with DejaCharacterStats
    if not NarcissusDB.CorruptionBar then return end

    if IsAddOnLoaded("DejaCharacterStats") then
        local Bar = Narci_CorruptionBar;
        BlizzardCorruptionWidget:SetScript("OnHide", function(self)
            Bar:SetAlpha(0);
        end)
        BlizzardCorruptionWidget:SetScript("OnShow", function(self)
            Bar:SetAlpha(1);
        end)

        Bar:ClearAllPoints();
        Bar:SetParent(CharacterFrame);
        Bar:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -4, -48);

        if BlizzardCorruptionWidget:IsVisible() then
            Bar:SetAlpha(1);
        else
            Bar:SetAlpha(0);
        end
    end
end

local function CorruptionTooltipSwitch_OnClick()
    NarcissusDB.CorruptionTooltip = not NarcissusDB.CorruptionTooltip;
    Narci:SetUseCorruptionTooltip()
end


local function GetCorruptionDescription(corruptionSpells)
    local spellID, name, description;
    local IsSpellCached = C_Spell.IsSpellDataCached;
    for i = 1, #corruptionSpells do
        spellID = corruptionSpells[i];
        if IsSpellCached(spellID) and not CorruptionEffectInfo[i].isLocalized then
            CorruptionEffectInfo[i].isLocalized = true;

            name = GetSpellInfo(spellID);
            if name and name ~= "" then
                CorruptionEffectInfo[i].name = name;
            end
            
            description = GetSpellDescription(spellID);
            if description and description ~= "" then
                description = string.gsub(description, "\n.+", "");
                CorruptionEffectInfo[i].description = description;
            end
        else
            corruptionSpells.iteration = corruptionSpells.iteration + 1;
            if corruptionSpells.iteration <= 8 then
                C_Spell.RequestLoadSpellData(spellID);
                C_Timer.After(0.2, function()
                    GetCorruptionDescription(corruptionSpells);
                end)
                return
            else
                InitializeCorruptionTooltip();
            end
        end
    end
    InitializeCorruptionTooltip();
    C_Timer.After(0.2, function()
        SetPreview(2);
    end);
end

local Initialize = CreateFrame("Frame");
Initialize:RegisterEvent("PLAYER_ENTERING_WORLD");
Initialize:SetScript("OnEvent", function(self, event, ...)
    self:UnregisterEvent(self);
    local level = UnitLevel("player");
    if level == 120 then
        hooksecurefunc("UseContainerItem", function(bag, slot)
            if bag and slot then
                local id = GetContainerItemID(bag, slot);
                if id == 171335 or id == 171354 or id == 171355 or id == 175062 then
                    id = GetInventoryItemID("player", 15);       --Legendary Cloak
                    if id and id == 169223 then
                        ShowUIPanel(CharacterFrame);
                        local subFrame = _G["PaperDollFrame"];
                        if not subFrame:IsShown() then
                            ToggleCharacter("PaperDollFrame");
                        end
                        Narci_CloakHighlight.Bling:Play();
                    end
                end
            end
        end)
    end
    
    SetModelOffset();
    playerModelInfo = NarciAPI_GetActorInfoByUnit("player");

    local BlizzardCorruptionWidget = CharacterStatsPane.ItemLevelFrame.Corruption;
    if BlizzardCorruptionWidget then
        BlizzardCorruptionWidget_OnEnterFunction = BlizzardCorruptionWidget:GetScript("OnEnter");
        BlizzardCorruptionWidget_OnLeaveFunction = BlizzardCorruptionWidget:GetScript("OnLeave");   --Just in case they get changed in the future
    end

    Narci:SetUseCorruptionTooltip();


    --Cache Negative Corruption Effect Info
    local corruptionSpells = {
        315176,    --Grasping Tendrils
        315154,    --Eye of Corruption
        315184,    --Grand Delusions
        315857,    --Cascading Disaster
        315179,    --Inevitable Doom
    }
    
    for k, v in pairs(corruptionSpells) do
        GetSpellInfo(v);
        GetSpellDescription(v);
    end
    corruptionSpells.iteration = 0;

    C_Timer.After(0.5, function()
        GetCorruptionDescription(corruptionSpells);
    end)
end)
