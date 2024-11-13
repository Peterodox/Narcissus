local _, addon = ...
local SettingFunctions = addon.SettingFunctions;

local CameraUtil = CreateFrame("Frame");
addon.CameraUtil = CameraUtil;


local GetCVar = C_CVar.GetCVar;
local GetCVarBool = C_CVar.GetCVarBool;
local SetCVar = C_CVar.SetCVar;
local After = C_Timer.After;


local MS_1 = "CameraKeepCharacterCentered";
local MS_2 = "CameraReduceUnexpectedMovement";


local CVar_Backup = {};

local function BackupCVar(cvar)
    if CVar_Backup[cvar] == nil then
        CVar_Backup[cvar] = GetCVar(cvar);
    end
end

local function RestoreCVar(cvar)
    if CVar_Backup[cvar] ~= nil then
        SetCVar(cvar, CVar_Backup[cvar]);
        CVar_Backup[cvar] = nil;
        return true
    end
end

local function GetShoulderOffsetByZoom(zoom)
    return 0
end

do  --Move Smooth Yaw/Pitch/Shoulder
    local inOutSine = addon.EasingFunctions.inOutSine;
    local outSine = addon.EasingFunctions.outSine;

    local GetCameraZoom = GetCameraZoom;
    local MoveViewRightStop = MoveViewRightStop;
    local MoveViewRightStart = MoveViewRightStart;
    local IsPlayerMoving = IsPlayerMoving;
    local ConsoleExec = ConsoleExec;

    local ANGLE_SMOOTH_DURATION = 1.5;
    local SHOULDER_SMOOTH_DURATION = 1.0;

    local function CreateProcessFrame(onUpdateFunc)
        local f = CreateFrame("Frame");
        f:Hide();
        f:SetScript("OnUpdate", onUpdateFunc);
        return f
    end

    do  --Yaw
        local YAW_SPEED_END = 0.004;
        local YAW_SPEED_START = 1.05;

        CameraUtil.Yaw = CreateProcessFrame(function(self, elapsed)
            self.t = self.t + elapsed;
            self.speed = inOutSine(self.t, self.fromSpeed, self.toSpeed, ANGLE_SMOOTH_DURATION);	--inOutSine
            MoveViewRightStart(self.speed);
            if self.t >= 1.5 then
                self:Hide();
                self.t = 0;
                if IsPlayerMoving() then
                    MoveViewRightStop();

                else
                    MoveViewRightStart(self.toSpeed);
                end
            end
        end);

        function CameraUtil:SmoothYaw()
            --Rotate from player back to front
            local a = 180/(GetCVar("cameraYawMoveSpeed") or 180);
            self.Yaw.toSpeed = a * YAW_SPEED_END;
            self.Yaw.fromSpeed = a * YAW_SPEED_START;
            self.Yaw.t = 0;
            self.Yaw:Show();
        end

        function CameraUtil:GetOrbitYawSpeed()
            local a = 180/(GetCVar("cameraYawMoveSpeed") or 180);
            return a * YAW_SPEED_END
        end
    end

    do  --Pitch
        CameraUtil.Pitch = CreateProcessFrame(function(self, elapsed)
            self.t = self.t + elapsed
            local pl = tostring(outSine(self.t, 88,  1, ANGLE_SMOOTH_DURATION));
            ConsoleExec("pitchlimit "..pl);
            if self.t >= ANGLE_SMOOTH_DURATION then
                self:Hide();
                self.t = 0;
                ConsoleExec( "pitchlimit 1");
                After(0, function()
                    ConsoleExec( "pitchlimit 88");
                end)
            end
        end);

        function CameraUtil:SmoothPitch()
            self.Pitch.t = 0;
            self.Pitch:Show();
        end
    end

    do  --Shoulder
        CameraUtil.Shoulder = CreateProcessFrame(nil);   --Use different onUpdate situationally

        local function SmoothShoulder_OnUpdate_ToValue(self, elapsed)
            self.t = self.t + elapsed;
            local value = outSine(self.t, self.fromPoint, self.toPoint, SHOULDER_SMOOTH_DURATION);
            if self.t >= SHOULDER_SMOOTH_DURATION then
                value = self.toPoint;
                self:Hide();
            end
            SetCVar("test_cameraOverShoulder", value);
        end

        local function SmoothShoulder_OnUpdate_UntilStable(self, elapsed)
            self.t = self.t + elapsed;

            if self.t >= 0.1 then
                local zoom = GetCameraZoom();
                if zoom ~= self.zoom then
                    self.zoom = zoom;
                    self.t = 0;
                else
                    local value = GetShoulderOffsetByZoom(zoom);
                    if value < 0 then
                        value = 0;
                    end
                    CameraUtil:SmoothShoulder(value, true);
                end
            end
        end

        CameraUtil.Shoulder:SetScript("OnShow", function(self)
            self.fromPoint = GetCVar("test_cameraOverShoulder");
        end);

        function CameraUtil:SmoothShoulder(toPoint, clampToZero)
            if not toPoint then
                return
            end
            if clampToZero then
                if toPoint < 0 then
                    toPoint = 0;
                end
            end
            self.Shoulder:SetScript("OnUpdate", SmoothShoulder_OnUpdate_ToValue);
            self.Shoulder.t = 0;
            self.Shoulder.toPoint = toPoint;
            self.Shoulder.fromPoint = GetCVar("test_cameraOverShoulder");
            self.Shoulder:Show();
        end


        function CameraUtil:SmoothShoulderByZoom(increment)
            self.Shoulder:SetScript("OnUpdate", SmoothShoulder_OnUpdate_UntilStable);
            self.Shoulder.t = 0;
            self.Shoulder:Show();
        end
    end

    do  --Zoom
        function CameraUtil:ZoomTo(goal)
            local current = GetCameraZoom();
            if current >= goal then
                CameraZoomIn(current - goal);   --Calling global because other addons may change it
            else
                CameraZoomOut(goal -current);
            end
        end

        function CameraUtil:OnCameraChanged()
            if not self.cameraChanging then
                self.cameraChanging = true;
                After(0, function()
                    local current = GetCameraZoom();
                    local goal = self:GetDefaultZoomGoal();
                    if current < goal then          --We only zoom out in this situation
                        self:ZoomTo(goal);
                    else
                        CameraZoomIn(0);            --Incur shoulder update
                    end
                    self.cameraChanging = nil;
                end);
            end
        end

        function CameraUtil:ZoomToDefault(mogMode)
            local zoom = self:GetDefaultZoomGoal(mogMode) or GetCameraZoom();
            self:ZoomTo(zoom);
        end

        function CameraUtil:InstantZoomIn()
            --SetCVar("cameraViewBlendStyle", 2);
            --SetView(4);
            ConsoleExec( "pitchlimit 1");
            After(0, function()
                ConsoleExec( "pitchlimit 88");
            end)

            local zoom = self:GetDefaultZoomGoal() or GetCameraZoom();
            local shoulderOffset = GetShoulderOffsetByZoom(zoom);
            SetCVar("test_cameraOverShoulder", shoulderOffset);		--CameraZoomIn(0.0)	--Smooth
            self:ZoomTo(zoom);

            if not IsPlayerMoving() and NarcissusDB.CameraOrbit then
                MoveViewRightStart(self:GetOrbitYawSpeed());
            end
        end
    end
end


do  --Motion Sickness Locks Shoulder Offset
    local EXIT_EVENTS = {
        "PLAYER_LOGOUT",
        "PLAYER_QUITING",
        "PLAYER_CAMPING",
    };

    function CameraUtil:DisableMotionSickness()
        BackupCVar(MS_1);
        BackupCVar(MS_2);

        SetCVar(MS_1, 0);
        SetCVar(MS_2, 0);

        for _, event in ipairs(EXIT_EVENTS) do
            self:RegisterEvent(event);
        end
    end

    function CameraUtil:RestoreMotionSickness()
        RestoreCVar(MS_1);
        RestoreCVar(MS_2);

        for _, event in ipairs(EXIT_EVENTS) do
            self:UnregisterEvent(event);
        end
    end

    function CameraUtil:OnEvent(event, ...)
        self:RestoreMotionSickness();
    end
    CameraUtil:SetScript("OnEvent", CameraUtil.OnEvent);
end


do  --Camera Parameters
    local IsMounted = IsMounted;
    local GetShapeshiftFormID = GetShapeshiftFormID;
    local IsPlayerInAlteredForm = addon.TransitionAPI.IsPlayerInAlteredForm;

    local CAM_DISTANCE_INDEX = 1;
    local DEFAULT_ZOOM_GOAL = 2.1;
    local DEFAULT_ZOOM_MOG = 3.8;
    local EXTRA_SHOULDER_OFFSET = 0;     --During Mog Mode: +0.2 compensation due equipment layout change

    local CameraData = {
        --[raceID] = {bustZoom, factor1, factor2, fullbodyZoom},
        [0] = {[2] = {2.1, 0.361, -0.1654, 4},
            [3] = {2.1, 0.361, -0.1654, 4}},		        --Default Value

        [1] = {[2] = {2.1, 0.3283, -0.02, 4},		        --1 Human
            [3] = {2.0, 0.38, 0.0311, 3.6}},

        [2] = {[2] = {2.4, 0.2667, -0.1233, 5.2},	        --2 Orc
            [3] = {2.1, 0.3045, -0.0483, 5}},

        [3] = {[2] = {2.0, 0.2667, -0.0267, 3.6},	        --3 Dwarf
            [3] = {1.8, 0.3533, -0.02, 3.6}},

        [4] = {[2] = {2.1, 0.30, -0.0404, 5},		        --4 NE
            [3] = {2.1, 0.329, 0.025, 4.6}},

        [5] = {[2] = {2.1, 0.3537, -0.15, 4.2},		        --5 UD
            [3] = {2.0, 0.3447, 0.03, 3.6}},

        [6] = {[2] = {4.5, 0.2027, -0.18, 5.5},		        --6 Tauren
            [3] = {3.0, 0.2427, -0.1867, 5.5}},

        [7] = {[2] = {2.1, 0.329, 0.0517, 3.2},		        --7 Gnome
            [3] = {2.1, 0.329, -0.012, 3.1}},

        [8] = {[2] = {2.1, 0.2787, 0.04, 5.2},		        --8 Troll
            [3] = {2.1, 0.355, -0.1317, 5}},

        [9] = {[2] = {2.1, 0.2787, 0.04, 4.2},		        --9 Goblin
            [3] = {2.1, 0.3144, -0.054, 4}},

        [10] = {[2] = {2.1, 0.361, -0.1654, 4},		        --10 BloodElf
                [3] = {2.1, 0.3177, 0.0683, 3.8}},

        [11] = {[2] = {2.4, 0.248, -0.02, 5.5},		        --11 Goat
                [3] = {2.1, 0.3177, 0, 5}},

        [24] = {[2] = {2.5, 0.2233, -0.04, 5.2},		    --24 Pandaren
                [3] = {2.5, 0.2433, 0.04, 5.2}},

        [27] = {[2] = {2.1, 0.3067, -0.02, 5.2},		    --27 Nightborne
            [3] = {2.1, 0.3347, -0.0563, 4.7}},

        [28] = {[2] = {3.5, 0.2027, -0.18, 5.5},		    --28 Tauren
            [3] = {2.3, 0.2293, 0.0067, 5.5}},

        [29] = {[2] = {2.1, 0.3556, -0.1038, 4.5},		    --24 VE
                [3] = {2.1, 0.3353, -0.02, 3.8}},

        [31] = {[2] = {2.3, 0.2387, -0.04, 5.5},		    --32 Zandalari
            [3] = {2.1, 0.2733, -0.1243, 5.5}},

        [32] = {[2] = {2.3, 0.2387, 0.04, 5.2},			    --32 Kul'Tiran
            [3] = {2.1, 0.312, -0.02, 4.7}},

        [35] = {[2] = {2.1, 0.31, -0.03, 3.1},			    --35 Vulpera
            [3] = {2.1, 0.31, -0.03, 3.1}},

        ["Wolf"] = {[2] = {2.6, 0.2266, -0.02, 5},	        --22 Worgen Wolf form
                [3] = {2.1, 0.2613, -0.0133, 4.7}},

        ["Druid"] = {[1] = {3.71, 0.2027, -0.02, 5},		--Cat
                    [5] = {4.8, 0.1707, -0.04, 5},			--Bear
                    [31] = {4.61, 0.1947, -0.02, 5},		--Moonkin
                    [4] = {4.61, 0.1307, -0.04, 5},		    --Swim
                    [27] = {4.61, 0.1067, -0.02, 5},		--Fly Swift
                    [29] = {4.61, 0.1067, -0.02, 5},		--Fly
                    [3] = {4.91, 0.184, -0.02, 5},			--Travel Form
                    [36] = {4.2, 0.1707, -0.04, 5},		    --Treant
                    [2] = {5.4, 0.1707, -0.04, 5},			--Tree of Life
                    },

        ["Mounted"] = {[2] = {8, 1.2495, -4, 5.5},
                    [3] = {8, 1.2495, -4, 5.5}},

        [52] = {[2] = {2.1, 0.361, -0.1654, 4},		        --Dracthyr Visage (Male elf)
                [3] = {2.0, 0.38, 0.0311, 3.6}},	        --Dracthyr Visage (Female human)

        ["Dracthyr"] = {[2] = {2.6, 0.1704, 0.0749, 5},		--Dracthyr Dragon Form
                        [3] = {2.6, 0.1704, 0.0749, 5}},

        --1 	Human 32 Kultiran
        --2 	Orc
        --3 	Dwarf
        --4 	Night Elf
        --5 	Undead
        --6 	Tauren
        --7 	Gnome
        --8 	Troll
        --9 	Goblin
        --10 	Blood Elf
        --11 	Draenei
        --/run NarciScreenshotToolbar:ShowUI("Blizzard")
    };


    local SHOULDER_PARA_1 = CameraData[0][2][2];
    local SHOULDER_PARA_2 = CameraData[0][2][3];

    function GetShoulderOffsetByZoom(zoom)
        return zoom * SHOULDER_PARA_1 + SHOULDER_PARA_2 + EXTRA_SHOULDER_OFFSET
    end

    local _, _, RACE = UnitRace("player");
    local SEX = UnitSex("player");

    function CameraUtil:GetRaceKey()
        return RACE
    end

    function CameraUtil:GetRaceKey_Worgen()
        local raceKey;
        local inAlternateForm = IsPlayerInAlteredForm();
        if inAlternateForm then
            --Human
            raceKey = 1;
        else
            raceKey = "Wolf";
        end
        return raceKey
    end

    function CameraUtil:GetRaceKey_Dracthyr()
        local raceKey;
        local inAlternateForm = IsPlayerInAlteredForm();
        if inAlternateForm then
            --Visage
            raceKey = 52;
        else
            raceKey = "Dracthyr";
        end
        return raceKey
    end

    function CameraUtil:UpdateParameters_Druid()
        local formID = GetShapeshiftFormID();

        if formID then
            if formID == 31 then
                local _, glyphID = GetCurrentGlyphNameForSpell(24858);		--Moonkin form with Glyph of Stars use regular configuration
                if glyphID and glyphID == 114301 then
                    self:UpdateParameters_Default();
                    return
                end
            end

            local raceKey = "Druid";
            DEFAULT_ZOOM_GOAL = CameraData[raceKey][formID][CAM_DISTANCE_INDEX];
            SHOULDER_PARA_1 = CameraData[raceKey][formID][2];
            SHOULDER_PARA_2 = CameraData[raceKey][formID][3];
            DEFAULT_ZOOM_MOG = CameraData[raceKey][formID][4];
        else
            self:UpdateParameters_Default();
        end
    end

    function CameraUtil:UpdateParameters_Default()
        local raceKey;
        if IsMounted() then
            raceKey = "Mounted";
        else
            raceKey = self:GetRaceKey();
        end
        DEFAULT_ZOOM_GOAL = CameraData[raceKey][SEX][CAM_DISTANCE_INDEX];
        SHOULDER_PARA_1 = CameraData[raceKey][SEX][2];
        SHOULDER_PARA_2 = CameraData[raceKey][SEX][3];
        DEFAULT_ZOOM_MOG = CameraData[raceKey][SEX][4];
    end
    CameraUtil.UpdateParameters = CameraUtil.UpdateParameters_Default;

    do  --Remove Irrelevant Data
        if RACE == 25 or RACE == 26 then            --Pandaren A|H
            RACE = 24;
        elseif RACE == 30 then						--Lightforged
            RACE = 11;
        elseif RACE == 36 then						--Mag'har Orc
            RACE = 2;
        elseif RACE == 34 then						--DarkIron
            RACE = 3;
        elseif RACE == 37 then						--Mechagnome
            RACE = 7;
        elseif RACE == 22 then
            CameraUtil.GetRaceKey = CameraUtil.GetRaceKey_Worgen;
        elseif RACE == 52 or RACE == 70 then	    --Dracthyr Horde -> Alliance
            RACE = 52;
            CameraUtil.GetRaceKey = CameraUtil.GetRaceKey_Dracthyr;
        elseif RACE == 84 or RACE == 85 then	    --Earthen
            RACE = 3;
        end

        local _, _, playerClassID = UnitClass("player");
        if playerClassID == 11 then
            CameraUtil.UpdateParameters = CameraUtil.UpdateParameters_Druid;
        end

        if (not CameraData[RACE]) and (RACE ~= 22 and RACE ~= 52) then
            print(("Narcissus: You are using race %d that doesn't have camera parameters"):format(RACE))
            RACE = 1;
        end

        for raceKey, data in pairs(CameraData) do
            local id = tonumber(raceKey);
            if id and id > 1 and id ~= RACE then
                CameraData[raceKey] = nil;
            end
        end
    end

    function CameraUtil:OnPlayerFormChanged(pauseDuration)
        if not self.f1 then
            self.f1 = CreateFrame("Frame");
            self.f1:SetScript("OnUpdate", function(f, elapsed)
                f.t = f.t + elapsed;
                if f.t > 0 then
                    f:Hide();
                    self:UpdateParameters();
                    self:OnCameraChanged();
                end
            end);
        end
        pauseDuration = pauseDuration or 0;
        self.f1.t = -pauseDuration;
        self.f1:Show();
    end

    function CameraUtil:GetDefaultZoomGoal(mogMode)
        return (mogMode and DEFAULT_ZOOM_MOG) or DEFAULT_ZOOM_GOAL
    end

    function CameraUtil:SetUseMogOffset(mogMode)
        if mogMode then
            EXTRA_SHOULDER_OFFSET = 0.2;
        else
            EXTRA_SHOULDER_OFFSET = 0;
        end
    end



	function SettingFunctions.SetDefaultZoomClose(state, db)
		if state == nil then
			state = db["UseBustShot"];
		end
		if state then
			CAM_DISTANCE_INDEX = 1;
		else
			CAM_DISTANCE_INDEX = 4;
		end
	end
end


do  --Compatibility: Dymaic Cam
    function CameraUtil:MakeActive()
        --Reserved for DynamicCam users
    end

    function CameraUtil:MakeInactive()
        --Reserved for DynamicCam users
    end

    function CameraUtil:UpdateMovementMethodForDynamicCam()
        if not self.dcHandler then
            self.dcHandler = CreateFrame("Frame");
        end

        local f = self.dcHandler;
        f:Hide();
        f.t = 0;

        f:SetScript("OnUpdate", function(_, elapsed)
            f.t = f.t + elapsed;
            if f.t >= 0.2 then
                f.currentZoom = GetCameraZoom();
                if f.currentZoom ~= f.lastZoom then
                    f.lastZoom = f.currentZoom;
                    CameraUtil:SmoothShoulderByZoom();
                end
            end
        end);

        local oldShoulderOffset;

        local function ReApplySettings()
            local dc = DynamicCam;

            local curSituation = dc.db.profile.situations[dc.currentSituationID]

            dc.virtualCameraZoom = nil
            dc.easeShoulderOffsetInProgress = false;

            if curSituation then
                local cvar = "test_cameraOverShoulder";
                local value = curSituation.situationSettings.cvars[cvar];

                if value then
                    SetCVar(cvar, oldShoulderOffset or value);
                end
            end

            oldShoulderOffset = nil
        end

        function self:MakeActive()
            f.lastZoom = -1;
            f:Show();
            oldShoulderOffset = GetCVar("test_cameraOverShoulder");
        end


        function self:MakeInactive()
            f:Hide();
            ReApplySettings();
        end
    end
end