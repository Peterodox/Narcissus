local _, addon = ...

local MsgAlertContainer = addon.MsgAlertContainer;
local TransitionAPI = addon.TransitionAPI;
local SlotButtonOverlayUtil = addon.SlotButtonOverlayUtil;
local TimerunningUtil = addon.TimerunningUtil;
local TalentTreeDataProvider = addon.TalentTreeDataProvider;

local Narci = Narci;

Narci.refreshCombatRatings = true;

local SLOT_TABLE = {};
Narci.slotTable = SLOT_TABLE;

local STAT_STABLE = {};
local SHORT_STAT_TABLE = {};
local L = Narci.L;
local VIGNETTE_ALPHA = 0.5;
local IS_OPENED = false;									--Addon was opened by clicking
local MOG_MODE = false;
local SHOW_MISSING_ENCHANT_ALERT = true;

local NarciAPI = NarciAPI;
local GetItemEnchantID = NarciAPI.GetItemEnchantID;
local GetItemEnchantText = NarciAPI.GetEnchantTextByItemLink;
local EnchantInfo = Narci.EnchantData;						--Bridge/GearBonus.lua

local PlayLetteboxAnimation = NarciAPI_LetterboxAnimation;
local SmartFontType = NarciAPI.SmartFontType;
local IsItemSocketable = NarciAPI.IsItemSocketable;
local SetBorderTexture = NarciAPI.SetBorderTexture;
local GetBorderArtByItemID = NarciAPI.GetBorderArtByItemID;
local GetVerticalRunicLetters = NarciAPI.GetVerticalRunicLetters;
local FadeFrame = NarciFadeUI.Fade;

local inOutSine = addon.EasingFunctions.inOutSine
local linear = addon.EasingFunctions.linear;
local outSine = addon.EasingFunctions.outSine;

local GetToolbarButtonByButtonType = addon.GetToolbarButtonByButtonType;
local TransmogDataProvider = addon.TransmogDataProvider;
local ConfirmBinding = addon.ConfirmBinding;

--local GetCorruptedItemAffix = NarciAPI_GetCorruptedItemAffix;
local Narci_AlertFrame_Autohide = Narci_AlertFrame_Autohide;
local C_Item = C_Item;
local GetItemInfo = C_Item.GetItemInfo;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local C_LegendaryCrafting = C_LegendaryCrafting;
local C_TransmogCollection = C_TransmogCollection;
local After = C_Timer.After;
local ItemLocation = ItemLocation;
local IsPlayerInAlteredForm = TransitionAPI.IsPlayerInAlteredForm;
local InCombatLockdown = InCombatLockdown;
local GetInventoryItemTexture = GetInventoryItemTexture;
local GetCameraZoom = GetCameraZoom;
local GetSpellInfo = TransitionAPI.GetSpellInfo;

local floor = math.floor;
local max = math.max;

local UIParent = _G.UIParent;
local Toolbar = NarciScreenshotToolbar;
local EquipmentFlyoutFrame;
local ItemLevelFrame;
local RadarChart;
local ItemTooltip;

local MiniButton = Narci_MinimapButton;
local NarciThemeUtil = NarciThemeUtil;


local EL = CreateFrame("Frame");	--Event Listener
EL:Hide();

EL.EVENTS_DYNAMIC = {"PLAYER_TARGET_CHANGED", "COMBAT_RATING_UPDATE", "PLAYER_MOUNT_DISPLAY_CHANGED",
	"PLAYER_STARTED_MOVING", "PLAYER_REGEN_DISABLED", "UNIT_MAXPOWER", "PLAYER_STARTED_TURNING", "PLAYER_STOPPED_TURNING",
	"BAG_UPDATE_COOLDOWN", "UNIT_STATS", "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "AZERITE_ESSENCE_ACTIVATED",
};

EL.EVENTS_UNIT = {"UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_INVENTORY_CHANGED"};


--take out frames from UIParent, so they will still be visible when UI is hidden
local function TakeOutFrames(state)
	local frameNames = {
		"AzeriteEmpoweredItemUI", "AzeriteEssenceUI", "ItemSocketingFrame",
	};
	local frame;
	if state then
		local scale = UIParent:GetEffectiveScale();
		for _, frameName in pairs(frameNames) do
			frame = _G[frameName];
			if frame then
				frame:SetParent(nil);
				frame:SetScale(scale);
			end
		end
	else
		for _, frameName in pairs(frameNames) do
			frame = _G[frameName];
			if frame then
				frame:SetParent(UIParent);
				frame:SetScale(1);
			end
		end
	end
end


local DefaultTooltip;
local ShowDelayedTooltip = NarciAPI_ShowDelayedTooltip;

function Narci_ShowButtonTooltip(self)
	DefaultTooltip:HideTooltip();
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	if not self.tooltipHeadline then
		return
	end

	DefaultTooltip:SetPoint("BOTTOM", self, "TOP", 0, 2);

	DefaultTooltip:SetText(self.tooltipHeadline);

	if self.tooltipLine1 then
		DefaultTooltip:AddLine(self.tooltipLine1, 1, 1, 1, true);
	end

	if self.tooltipSpecial then
		DefaultTooltip:AddLine(" ");
		DefaultTooltip:AddLine(self.tooltipSpecial, 0.25, 0.78, 0.92, true);
	end


	DefaultTooltip:Show();
	DefaultTooltip:FadeIn();

	--ShowDelayedTooltip("BOTTOM", self, "TOP", 0, 2);
end

function Narci:HideButtonTooltip()
	--ShowDelayedTooltip(false);
	DefaultTooltip:HideTooltip();
	ItemTooltip:HideTooltip();
	--DefaultTooltip:SetFrameStrata("TOOLTIP");
end

--------------------------------
local UIPA = CreateFrame("Frame");	--UIParentAlphaAnimation
UIPA:Hide()
UIPA.t = 0;
UIPA.totalTime = 0;
UIPA.frame = UIParent;

UIPA:SetScript("OnShow", function(self)
	self.startAlpha = self.frame:GetAlpha();
end);

UIPA:SetScript("OnUpdate", function(self, elapsed)
	self.t = self.t + elapsed
	self.totalTime = self.totalTime + elapsed;
	if self.t < 0.08 then	--Limit update frequency to mitigate the impact on FPS
		return;
	else
		self.t = 0;
	end

	local alpha = linear(self.totalTime, self.startAlpha, self.endAlpha, 0.5);

	if self.totalTime >= 0.5 then
		alpha = self.endAlpha;
		self:Hide();
	end

	self.frame:SetAlpha(alpha);
end);

UIPA:SetScript("OnHide", function(self)
	self.t = 0;
	self.totalTime = 0;
end);


--------------------------------
-----------CVar Backup----------
--------------------------------
local ConsoleExec = ConsoleExec;
local GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar;
local SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar;

ConsoleExec("pitchlimit 88");

local CVarTemp = {};

function CVarTemp:BackUp()
	self.zoomLevel = GetCameraZoom();
	self.dynamicPitch = tonumber(GetCVar("test_cameraDynamicPitch"));
	self.shoulderOffset = GetCVar("test_cameraOverShoulder");
	self.cameraViewBlendStyle = GetCVar("cameraViewBlendStyle");
end

function CVarTemp:BackUpDynamicCam()
	self.DynmicCamShoulderOffsetZoomUpperBound = DynamicCam.db.profile.shoulderOffsetZoom.lowerBound;	--New
	DynamicCam.db.profile.shoulderOffsetZoom.lowerBound = 0;
end

function CVarTemp:RestoreDynamicCam()
	DynamicCam.db.profile.shoulderOffsetZoom.lowerBound = self.DynmicCamShoulderOffsetZoomUpperBound;
end

local function GetKeepActionCam()
	return CVarTemp.isDynamicCamLoaded or (not CVarTemp.cameraSafeMode)
end

CVarTemp.shoulderOffset = tonumber(GetCVar("test_cameraOverShoulder"));
CVarTemp.dynamicPitch = tonumber(GetCVar("test_cameraDynamicPitch"));		--No CVar directly shows the current state of ActionCam. Check this CVar for the moment. 1~On  2~Off
CVarTemp.zoomLevel = 2;

local ZoomFactor = {};
ZoomFactor.Time = 1.5;			--1.5 outSine
--ZoomFactor.Amplifier = 0.65; 	--0.65
ZoomFactor.toSpeedBasic = 0.004;	--yawmovespeed 180
ZoomFactor.fromSpeedBasic = 1.05;	--yawmovespeed 180
ZoomFactor.toSpeed = 0.005;	--yawmovespeed 180
ZoomFactor.fromSpeed = 1.0;	--yawmovespeed 180 outSine 1.4 
ZoomFactor.SpeedFactor = 180 / tonumber(GetCVar("cameraYawMoveSpeed") or 180);
ZoomFactor.Goal = 2.5; --2.5 with dynamic pitch

local MOG_MODE_OFFSET = 0;
local ZoomValuebyRaceID = {
	--[raceID] = {ZoomValue Bust, factor1, factor2, ZoomValue for XmogMode},
	[0] = {[2] = {2.1, 0.361, -0.1654, 4},},		--Default Value

	[1] = {[2] = {2.1, 0.3283, -0.02, 4},		--1 Human √
		   [3] = {2.0, 0.38, 0.0311, 3.6}},

	[2] = {[2] = {2.4, 0.2667, -0.1233, 5.2},	--2 Orc √
		   [3] = {2.1, 0.3045, -0.0483, 5}},

	[3] = {[2] = {2.0, 0.2667, -0.0267, 3.6},	--3 Dwarf √
		   [3] = {1.8, 0.3533, -0.02, 3.6}},

	[4] = {[2] = {2.1, 0.30, -0.0404, 5},		--4 NE √
		   [3] = {2.1, 0.329, 0.025, 4.6}},

	[5] = {[2] = {2.1, 0.3537, -0.15, 4.2},		--5 UD √
		   [3] = {2.0, 0.3447, 0.03, 3.6}},

	[6] = {[2] = {4.5, 0.2027, -0.18, 5.5},		--6 Tauren Male √
		   [3] = {3.0, 0.2427, -0.1867, 5.5}},

	[7] = {[2] = {2.1, 0.329, 0.0517, 3.2},		--7 Gnome √
		   [3] = {2.1, 0.329, -0.012, 3.1}},

	[8] = {[2] = {2.1, 0.2787, 0.04, 5.2},		--8 Troll √
		   [3] = {2.1, 0.355, -0.1317, 5}},

	[9] = {[2] = {2.1, 0.2787, 0.04, 4.2},		--9 Goblin √
		   [3] = {2.1, 0.3144, -0.054, 4}},

	[10] = {[2] = {2.1, 0.361, -0.1654, 4},		--10 BloodElf Male √
		    [3] = {2.1, 0.3177, 0.0683, 3.8}},

	[11] = {[2] = {2.4, 0.248, -0.02, 5.5},		--11 Goat Male √
			[3] = {2.1, 0.3177, 0, 5}},
			
	[24] = {[2] = {2.5, 0.2233, -0.04, 5.2},		--24 Pandaren Male √
		    [3] = {2.5, 0.2433, 0.04, 5.2}},

	[27] = {[2] = {2.1, 0.3067, -0.02, 5.2},		--27 Nightborne √
		   [3] = {2.1, 0.3347, -0.0563, 4.7}},

	[28] = {[2] = {3.5, 0.2027, -0.18, 5.5},		--28 Tauren Male √
		   [3] = {2.3, 0.2293, 0.0067, 5.5}},

	[29] = {[2] = {2.1, 0.3556, -0.1038, 4.5},		--24 VE √
			[3] = {2.1, 0.3353, -0.02, 3.8}},

	[31] = {[2] = {2.3, 0.2387, -0.04, 5.5},		--32 Zandalari √
		   [3] = {2.1, 0.2733, -0.1243, 5.5}},

	[32] = {[2] = {2.3, 0.2387, 0.04, 5.2},			--32 Kul'Tiran √
		   [3] = {2.1, 0.312, -0.02, 4.7}},

	[35] = {[2] = {2.1, 0.31, -0.03, 3.1},			--35 Vulpera √
		   [3] = {2.1, 0.31, -0.03, 3.1}},

	["Wolf"] = {[2] = {2.6, 0.2266, -0.02, 5},	--22 Worgen Wolf form √
		   	[3] = {2.1, 0.2613, -0.0133, 4.7}},
	
	["Druid"] = {[1] = {3.71, 0.2027, -0.02, 5},		--Cat
				 [5] = {4.8, 0.1707, -0.04, 5},			--Bear
				 [31] = {4.61, 0.1947, -0.02, 5},		--Moonkin
				 [4] = {4.61, 0.1307, -0.04, 5},		--Swim
				 [27] = {4.61, 0.1067, -0.02, 5},		--Fly Swift
				 [29] = {4.61, 0.1067, -0.02, 5},		--Fly
				 [3] = {4.91, 0.184, -0.02, 5},			--Travel Form
				 [36] = {4.2, 0.1707, -0.04, 5},		--Treant
				 [2] = {5.4, 0.1707, -0.04, 5},			--Tree of Life
				},

	["Mounted"] = {[2] = {8, 1.2495, -4, 5.5},
				   [3] = {8, 1.2495, -4, 5.5}},
	
	[52] = {[2] = {2.1, 0.361, -0.1654, 4},		--Dracthyr Visage (Male elf)
		    [3] = {2.0, 0.38, 0.0311, 3.6}},	--Dracthyr Visage (Female human)

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


local _, _, PLAYER_RACE_ID = UnitRace("player")
local PLAYER_GENDER_ID = UnitSex("player")
local _, _, PLAYER_CLASS_ID = UnitClass("player");
local CAM_DISTANCE_INDEX = 1;
local ZOOM_IN_VALUE = ZoomValuebyRaceID[0][1];
local ZOOM_IN_VALUE_MOG = 3.8;
local SHOULDER_FACTOR_1 = ZoomValuebyRaceID[0][2][2];
local SHOULDER_FACTOR_2 = ZoomValuebyRaceID[0][2][3];


local CameraMover = {};
local CameraUtil = {};

function CameraUtil:UpdateParametersDefault()
	local raceKey;
	if IsMounted() then
		raceKey = "Mounted";
	else
		raceKey = self:GetRaceKey();
	end

	ZOOM_IN_VALUE = ZoomValuebyRaceID[raceKey][PLAYER_GENDER_ID][CAM_DISTANCE_INDEX];
	SHOULDER_FACTOR_1 = ZoomValuebyRaceID[raceKey][PLAYER_GENDER_ID][2];
	SHOULDER_FACTOR_2 = ZoomValuebyRaceID[raceKey][PLAYER_GENDER_ID][3];
	ZOOM_IN_VALUE_MOG = ZoomValuebyRaceID[raceKey][PLAYER_GENDER_ID][4];
end

CameraUtil.UpdateParameters = CameraUtil.UpdateParametersDefault;

function CameraUtil:GetRaceKey()
	return PLAYER_RACE_ID
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
				self:UpdateParametersDefault();
				return
			end
		end

		local raceKey = "Druid";
		ZOOM_IN_VALUE = ZoomValuebyRaceID[raceKey][formID][CAM_DISTANCE_INDEX];
		SHOULDER_FACTOR_1 = ZoomValuebyRaceID[raceKey][formID][2];
		SHOULDER_FACTOR_2 = ZoomValuebyRaceID[raceKey][formID][3];
		ZOOM_IN_VALUE_MOG = ZoomValuebyRaceID[raceKey][formID][4];
	else
		self:UpdateParametersDefault();
	end
end


do
	if PLAYER_RACE_ID == 25 or PLAYER_RACE_ID == 26 then	--Pandaren A|H
		PLAYER_RACE_ID = 24;
	elseif PLAYER_RACE_ID == 30 then						--Lightforged
		PLAYER_RACE_ID = 11;
	elseif PLAYER_RACE_ID == 36 then						--Mag'har Orc
		PLAYER_RACE_ID = 2;
	elseif PLAYER_RACE_ID == 34 then						--DarkIron
		PLAYER_RACE_ID = 3;
	elseif PLAYER_RACE_ID == 37 then						--Mechagnome
		PLAYER_RACE_ID = 7;
	elseif PLAYER_RACE_ID == 22 then
		CameraUtil.GetRaceKey = CameraUtil.GetRaceKey_Worgen;
	elseif PLAYER_RACE_ID == 52 or PLAYER_RACE_ID == 70 then	--Dracthyr Horde -> Alliance
		PLAYER_RACE_ID = 52;
		CameraUtil.GetRaceKey = CameraUtil.GetRaceKey_Dracthyr;
	elseif PLAYER_RACE_ID == 84 or PLAYER_RACE_ID == 85 then	--Earthen
		PLAYER_RACE_ID = 3;
	end

	local _, _, playerClassID = UnitClass("player");
	if playerClassID == 11 then
		CameraUtil.UpdateParameters = CameraUtil.UpdateParameters_Druid;
		table.insert(EL.EVENTS_DYNAMIC, "UPDATE_SHAPESHIFT_FORM");
	end

	if (not ZoomValuebyRaceID[PLAYER_RACE_ID]) and (PLAYER_RACE_ID ~= 22 and PLAYER_RACE_ID ~= 52) then
		print(("Narcissus: You are using race %d that doesn't have camera parameters"):format(PLAYER_RACE_ID))
		PLAYER_RACE_ID = 1;
	end
end

for raceKey, data in pairs(ZoomValuebyRaceID) do
	local id = tonumber(raceKey);
	if id and id > 1 and id ~= PLAYER_RACE_ID then
		ZoomValuebyRaceID[raceKey] = nil;
	end
end


function CameraUtil:OnPlayerFormChanged(pauseDuration)
	if not self.frame then
		self.frame = CreateFrame("Frame");
		self.frame:SetScript("OnUpdate", function(f, elapsed)
			f.t = f.t + elapsed;
			if f.t > 0 then
				f:Hide();
				self:UpdateParameters();
				CameraMover:OnCameraChanged();
			end
		end);
	end

	if not self.pauseUpdate then
		--self.pauseUpdate = true;
		pauseDuration = pauseDuration or 0;
		self.frame.t = -pauseDuration;
		self.frame:Show();
	end
end


local function GetShoulderOffsetByZoom(zoom)
	return zoom * SHOULDER_FACTOR_1 + SHOULDER_FACTOR_2 + MOG_MODE_OFFSET
end

local SmoothShoulder = CreateFrame("Frame");
SmoothShoulder.t = 0;
SmoothShoulder.duration = 1;
SmoothShoulder.zoom = 0;
SmoothShoulder:Hide();

SmoothShoulder:SetScript("OnShow", function(self)
	self.fromPoint = GetCVar("test_cameraOverShoulder");
end);

local function SmoothShoulder_OnUpdate_ToValue(self, elapsed)
	self.t = self.t + elapsed;
	local value = outSine(self.t, self.fromPoint, self.toPoint, self.duration);

	if self.t >= self.duration then
		value = self.toPoint;
		self:Hide();
	end

	SetCVar("test_cameraOverShoulder", value);
end

local function SmoothShoulder_OnUpdate_ByZoom(self, elapsed)
	local zoom = GetCameraZoom();

	if zoom ~= self.zoom then
		local value = GetShoulderOffsetByZoom(zoom);
		if value < 0 then
			value = 0;
		end

		SetCVar("test_cameraOverShoulder", value);
	else
		self:Hide();
	end
end


SmoothShoulder:SetScript("OnHide", function(self)
	self.t = 0;
end);

local function SmoothShoulderCVar(toPoint, clampToZero)
	if not toPoint then
		return
	end
	if clampToZero then
		if toPoint < 0 then
			toPoint = 0;
		end
	end
	SmoothShoulder:SetScript("OnUpdate", SmoothShoulder_OnUpdate_ToValue);
	SmoothShoulder.t = 0;
	SmoothShoulder.toPoint = toPoint;
	SmoothShoulder.fromPoint = GetCVar("test_cameraOverShoulder");
	SmoothShoulder:Show();
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
			SmoothShoulderCVar(value, true);
		end
	end
end

local UpdateShoulderCVar = {};
UpdateShoulderCVar.steps = 0;

function UpdateShoulderCVar:Start(increment)
	SmoothShoulder:SetScript("OnUpdate", SmoothShoulder_OnUpdate_UntilStable);
	SmoothShoulder.t = 0;
	SmoothShoulder:Show();
end

local DURATION_TRANSLATION = 0.8;

function Narci_LeftLineAnimFrame_OnUpdate(self, elapsed)
	local toX = self.toX;
	local t = self.TimeSinceLastUpdate + elapsed;
	self.TimeSinceLastUpdate = t;
	local offsetX = outSine(t, toX - 120, toX , DURATION_TRANSLATION);	--outSine
	if t >= DURATION_TRANSLATION then
		offsetX = toX;
		self:Hide();
	end
	if not self.frame then
		self.frame = self:GetParent();
	end
	self.frame:SetPoint(self.anchorPoint, offsetX, 0);
end

function Narci_RightLineAnimFrame_OnUpdate(self, elapsed)
	local toX = self.toX;
	local t = self.TimeSinceLastUpdate + elapsed;
	self.TimeSinceLastUpdate = t;
	local offsetX = outSine(t, self.fromX, toX, DURATION_TRANSLATION);
	if t >= DURATION_TRANSLATION then
		offsetX = toX;
		self:Hide();
	end
	if not self.frame then
		self.frame = self:GetParent();
	end
	self.frame:SetPoint(self.anchorPoint, offsetX, 0);
end


--Views
local ViewProfile = {
	isEnabled = true,
};

function ViewProfile:Disable()
	self.isEnabled = false;
	--print("Dynamic Cam Enabled")
end

function ViewProfile:SaveView(index)
	if self.isEnabled then
		SaveView(index);
	end
end

function ViewProfile:ResetView(index)
	if self.isEnabled then
		ResetView(index);
	end
end


Narci.CameraMover = CameraMover;

function CameraMover:ZoomIn(toPoint)
	local goal = toPoint or ZoomFactor.Goal;
	ZoomFactor.Current = GetCameraZoom();
	if ZoomFactor.Current >= goal then
		CameraZoomIn(ZoomFactor.Current - goal);
	else
		CameraZoomOut(-ZoomFactor.Current + goal);
	end
end

function CameraMover:OnCameraChanged()
	if not self.pauseUpdate then
		self.pauseUpdate = true;
		After(0.0, function()
			--self:ZoomIn(ZOOM_IN_VALUE);
			local zoom = GetCameraZoom();
			if zoom < ZOOM_IN_VALUE then
				self:ZoomIn(ZOOM_IN_VALUE);
			else
				CameraZoomIn(0);
			end
			self.pauseUpdate = nil;
		end);
	end
end

function CameraMover:SetBlend(enable)
	local divisor;
	if enable then
		--Smooth
		DURATION_TRANSLATION = 0.8;
		divisor = 20;
	else
		--Instant
		DURATION_TRANSLATION = 0.4;
		divisor = 80;
	end

	for k, slot in pairs(STAT_STABLE) do
		local delay = (slot:GetID())/divisor;
		if slot.animIn then
			slot.animIn.A2:SetStartDelay(delay);
		end
	end

	for k, slot in pairs(SHORT_STAT_TABLE) do
		local delay = (slot:GetID())/divisor;
		slot.animIn.A2:SetStartDelay(delay);
	end

	RadarChart.animIn.A2:SetStartDelay(9/divisor);
	self.blend = enable;
end

CameraMover.smoothYaw = NarciAPI_CreateAnimationFrame(1.5);
CameraMover.smoothYaw.MoveView = MoveViewRightStart;

CameraMover.smoothYaw:SetScript("OnUpdate", function(frame, elapsed)
	frame.total = frame.total + elapsed;
	local factor = ZoomFactor;
	local speed = inOutSine(frame.total, factor.fromSpeed, factor.toSpeed, 1.5);	--inOutSine
	frame.MoveView(speed);
	
	if frame.total >= 1.5 then
		if not IsPlayerMoving() then
			frame.MoveView(factor.toSpeed);
		else
			MoveViewRightStop();
		end
		frame:Hide();
	end
end);

CameraMover.smoothPitch = NarciAPI_CreateAnimationFrame(1.5);
CameraMover.smoothPitch:SetScript("OnUpdate", function(frame, elapsed)
	frame.total = frame.total + elapsed
	--local x = frame.total;
	--local EndDistance = ZoomFactor.Goal;
	local PL = tostring(outSine(frame.total, 88,  1, frame.duration));	--outSine
	ConsoleExec( "pitchlimit "..PL)
	if frame.total >= frame.duration then
		ConsoleExec( "pitchlimit 1");
		After(0, function()
			ConsoleExec( "pitchlimit 88");
		end)
		frame:Hide();
	end
end);


function CameraMover:InstantZoomIn()
	SetCVar("cameraViewBlendStyle", 2);
	SetView(4);

	ConsoleExec( "pitchlimit 1");
	After(0, function()
		ConsoleExec( "pitchlimit 88");
	end)
	
	local zoom = ZOOM_IN_VALUE or GetCameraZoom();
	local shoulderOffset = GetShoulderOffsetByZoom(zoom);
	SetCVar("test_cameraOverShoulder", shoulderOffset);		--CameraZoomIn(0.0)	--Smooth
	
	self:ZoomIn(ZOOM_IN_VALUE);
	
	self:ShowFrame();
	SetUIVisibility(false);
	if not IsPlayerMoving() and NarcissusDB.CameraOrbit then
		MoveViewRightStart(ZoomFactor.toSpeed);
	end
end

function CameraMover:HideUI()
	NarciAPI.MuteTargetLostSound(true);

	if UIParent:IsShown() then
		UIPA.endAlpha = 0;
		UIPA:Show();
	end

	After(0.5, function()
		SetUIVisibility(false); 		--Same as pressing Alt + Z
		After(0.3, function()
			UIParent:SetAlpha(1);
		end)
	end)
end

function CameraMover:Enter()
	SetCVar("test_cameraDynamicPitch", 1);

	if self.blend then
		if NarcissusDB.CameraOrbit and not IsPlayerMoving() then
			if NarcissusDB.CameraOrbit then
				self.smoothYaw:Show();
			end
			SetView(2);
		end

		if not IsFlying("player") then
			self.smoothPitch:Show();
		end
		
		After(0.1, function()
			self:ZoomIn(ZOOM_IN_VALUE);
			After(0.7, function()
				self:ShowFrame();
			end)
		end)

		self:HideUI();
	else
		if not self.hasInitialized then
			if NarcissusDB.CameraOrbit then
				self.smoothYaw:Show();
			end
			SetView(2);
			self.smoothPitch:Show();
			After(0.1, function()
				self:ZoomIn(ZOOM_IN_VALUE);
				After(0.7, function()
					self:ShowFrame();
				end)
			end)
			After(1, function()
				if not IsMounted() then
					self.hasInitialized = true;
					SaveView(1);
				end
			end)
			self:HideUI();
		else
			self:InstantZoomIn();
		end
	end
end

function CameraMover:Pitch()
	self.smoothPitch:Show();
end

function CameraMover:MakeActive()
	--Reserved for DynamicCam users
end

function CameraMover:MakeInactive()
	--Reserved for DynamicCam users
end

function CameraMover:UpdateMovementMethodForDynamicCam()
	if not self.handler then
		self.handler = CreateFrame("Frame");
	end

	local f = self.handler;
	f:Hide();
	f.t = 0;

	f:SetScript("OnUpdate", function(_, elapsed)
		f.t = f.t + elapsed;
		if f.t >= 0.2 then
			f.currentZoom = GetCameraZoom();
			if f.currentZoom ~= f.lastZoom then
				f.lastZoom = f.currentZoom;
				UpdateShoulderCVar:Start();
			end
		end
	end);

	function self:MakeActive()
		f.lastZoom = -1;
		f:Show();
	end

	function self:MakeInactive()
		f:Hide();
	end
end

------------------------------


------------------------------


local function ExitFunc()
	IS_OPENED = false;
	MOG_MODE_OFFSET = 0;
	EL:Hide();
	CameraMover:MakeInactive();
	MoveViewRightStop();
	if not GetKeepActionCam() then		--(not CVarTemp.isDynamicCamLoaded and CVarTemp.dynamicPitch == 0) or not Narci.keepActionCam
		SetCVar("test_cameraDynamicPitch", 0);								--Note: "test_cameraDynamicPitch" may cause camera to jitter while reseting the player's view
		SmoothShoulderCVar(0);
		After(1, function()
			ConsoleExec( "actioncam off" );
			MoveViewRightStop();
		end)
	else
		--Restore the acioncam state
		SmoothShoulderCVar(CVarTemp.shoulderOffset);
		SetCVar("test_cameraDynamicPitch", CVarTemp.dynamicPitch);
		After(1, function()
			MoveViewRightStop();
		end)
	end

	ConsoleExec("pitchlimit 88");

	FadeFrame(Narci_Vignette, 0.5, 0);
	if Narci_Attribute:IsVisible() then
		Narci_Attribute.animOut:Play();
	end
	UIParent:SetAlpha(0);
	After(0.1, function()
		NarciAPI.MuteTargetLostSound(false);
		UIPA.startAlpha = 0;
		UIPA.endAlpha = 1;
		UIPA:Show();
		SetUIVisibility(true);
		--UIFrameFadeIn(UIParent, 0.5, 0, 1);	--cause frame rate drop
		Minimap:Show();
		local cameraSmoothStyle = GetCVar("cameraSmoothStyle");
		if tonumber(cameraSmoothStyle) == 0 and ViewProfile.isEnabled then		--workaround for auto-following
			SetView(5);
		else
			SetView(2);
			CameraMover:ZoomIn(CVarTemp.zoomLevel);
		end
		SetCVar("cameraViewBlendStyle", CVarTemp.cameraViewBlendStyle);
	end);

	Narci.isActive = false;
	Narci.isAFK = false;

	DefaultTooltip:HideTooltip();
	MsgAlertContainer:Hide();

	UIErrorsFrame:Clear();

	Narci_ModelContainer:HideAndClearModel();
	Narci_ModelSettings:Hide();
	Narci_XmogNameFrame:Hide();
	NarciSettingsFrame:CloseUI();

	MOG_MODE = false;
end

--[[
local function SetDate()
	local CalendarTime = C_Calendar.GetDate();
	local hour = CalendarTime.hour;
	local minute = CalendarTime.minute;
	if minute < 10 then
		minute = "0"..tostring(minute)
	end
	Narci_Vignette.Time:SetText(hour..":"..minute)
	local zoneText = GetMinimapZoneText()
	Narci_Vignette.Location:SetText(zoneText)
end
--]]


function Narci:EmergencyStop()
	print("Camera has been reset.");
	UIParent:SetAlpha(1);
	MoveViewRightStop();
	MoveViewLeftStop();
	ViewProfile:ResetView(5);
	ConsoleExec( "pitchlimit 88");
	CVarTemp.shoulderOffset = 0;
	SetCVar("test_cameraOverShoulder", 0);
	SetCVar("cameraViewBlendStyle", 1);
	ConsoleExec( "actioncam off" );
	CameraMover:MakeInactive();
	Narci_ModelContainer:HideAndClearModel();
	Narci_ModelSettings:Hide();
	Narci_Character:Hide();
	Narci_Attribute:Hide();
	Narci_Vignette:Hide();
	IS_OPENED = false;
	MOG_MODE_OFFSET = 0;
	EL:Hide();
end



---------------End of derivation---------------
---Get Transmog Appearance---
--[[
	==sourceInfo==
	sourceType					TRANSMOG_SOURCE_1 = "Boss Drop";
	invType						TRANSMOG_SOURCE_2 = "Quest";
	visualID					TRANSMOG_SOURCE_3 = "Vendor";
	isCollected					TRANSMOG_SOURCE_4 = "World Drop";
	sourceID					TRANSMOG_SOURCE_5 = "Achievement";
	isHideVisual				TRANSMOG_SOURCE_6 = "Profession";
	itemID
	itemModID					Normal 0, Heroic 1, Mythic 3, LFG 4
	categoryID
	name
	quality	
--]]

local xmogTable = {
	{1, INVTYPE_HEAD}, {3, INVTYPE_SHOULDER}, {15, INVTYPE_CLOAK}, {5, INVTYPE_CHEST}, {4, INVTYPE_BODY}, {19, INVTYPE_TABARD}, {9, INVTYPE_WRIST},		--Left 	**slotID for TABARD is 19
	{10, INVTYPE_HAND}, {6, INVTYPE_WAIST}, {7, INVTYPE_LEGS}, {8, INVTYPE_FEET},																		--Right
	{16, INVTYPE_WEAPONMAINHAND}, {17, INVTYPE_WEAPONOFFHAND},																							--Weapon
};

--[[
local function ShareHyperLink()																	--Send transmog hyperlink to chat
	local delay = 0;																			--Keep message in order
	print(MYMOG_GRADIENT)
	for i=1, #xmogTable do
		local index =  xmogTable[i][1]
		if SLOT_TABLE[index] and SLOT_TABLE[index].hyperlink then			
			After(delay, function()
				SendChatMessage(xmogTable[i][2]..": "..SLOT_TABLE[index].hyperlink, "GUILD")
			end)
			delay = delay + 0.1;
		end
	end
end
--]]

local GetInventoryItemCooldown = GetInventoryItemCooldown;

local function SetItemSocketingFramePosition(self)		--Let ItemSocketingFrame appear on the side of the slot
	if ItemSocketingFrame then
		if self.GemSlot:IsShown() then
			ItemSocketingFrame:Show()
		else
			ItemSocketingFrame:Hide()
			return;
		end
		ItemSocketingFrame:ClearAllPoints();
		if self.isRight then
			ItemSocketingFrame:SetPoint("TOPRIGHT", self, "TOPLEFT", 4, 0);
		else
			ItemSocketingFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", -4, 0);
		end
		DefaultTooltip:HideTooltip();
	end
end

local IsItemEnchantable = {
	[11] = true,
	[12] = true,
	[16] = true,
	[17] = true,
	[5]  = true,

	[8] = true,
	[9] = true,
	[10] = true,
	[15] = true,
};

local function DisplayRuneSlot(equipmentSlot, slotID, itemQuality, itemLink)
	--! RuneSlot.Background is disabled
	if not equipmentSlot.RuneSlot then
		return;
	elseif (itemQuality == 0) or (not itemLink) then
		equipmentSlot.RuneSlot:Hide();
		return;
	end

	if IsItemEnchantable[slotID] then
		equipmentSlot.RuneSlot:Show();
	else
		equipmentSlot.RuneSlot:Hide();
		return;
	end

	local enchantID = GetItemEnchantID(itemLink);
	if enchantID ~= 0 then
		equipmentSlot.RuneSlot.RuneLetter:Show();
		if EnchantInfo[enchantID] then
			equipmentSlot.RuneSlot.RuneLetter:SetText( GetVerticalRunicLetters( EnchantInfo[enchantID][1] ) );
			equipmentSlot.RuneSlot.spellID = EnchantInfo[enchantID][3]
		end
	else
		equipmentSlot.RuneSlot.spellID = nil;
		equipmentSlot.RuneSlot.RuneLetter:Hide();
	end
end

function Narci_RuneButton_OnEnter(self)
	local spellID = self.spellID;
	if (not spellID) then
		return;
	end
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	if self:GetParent().isRight then
		DefaultTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", 8, 8);
	else
		DefaultTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 8);
	end
	DefaultTooltip:SetSpellByID(spellID);
	DefaultTooltip:Show();
	DefaultTooltip:FadeIn();
end

---------------------------------------------------
local USE_DELAY = true;
local function AssignDelay(id, forced)
	if USE_DELAY or forced then
		local time = 0;
		if id == 1 then
			time = 1;
		elseif id == 2 then
			time = 2;
		elseif id == 3 then
			time = 3;
		elseif id == 15 then	--back
			time = 4;
		elseif id == 5 then
			time = 5;
		elseif id == 9 then
			time = 6;
		elseif id == 16 then
			time = 7;
		elseif id == 17 then
			time = 8;
		elseif id == 4 then		--shirt
			time = 9;
		elseif id == 10 then
			time = 10;
		elseif id == 6 then
			time = 11;
		elseif id == 7 then
			time = 12;
		elseif id == 8 then
			time = 13;
		elseif id == 11 then
			time = 14;
		elseif id == 12 then
			time = 15;
		elseif id == 13 then
			time = 16;	
		elseif id == 14 then
			time = 17;	
		elseif id == 19 then
			time = 18;
		end
	
		time = time/20;
		return time;
	else
		return 0;
	end;
end

local function GetTraitsIcon(itemLocation)
    if not itemLocation then return; end
    local TierInfos = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLocation);
	if not TierInfos then return; end
	local powerIDs, icon, _;
	local isRightSpec = true;
	local traitIcons = {};
	local specIndex = GetSpecialization() or 1;
	local specID = GetSpecializationInfo(specIndex);
	local MAX_TIERS = 5;

    for i = 1, MAX_TIERS do
        if (not TierInfos[i]) or (not TierInfos[i].azeritePowerIDs) then         
            return traitIcons;
        end
		powerIDs = TierInfos[i].azeritePowerIDs;
        for k, powerID in pairs(powerIDs) do
			if C_AzeriteEmpoweredItem.IsPowerSelected(itemLocation, powerID) then
				local PowerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
				isRightSpec = isRightSpec and C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(powerID, specID);
				_, _, icon = GetSpellInfo(PowerInfo and PowerInfo.spellID);
                traitIcons[i] = icon;
                break;
            else
                traitIcons[i] = "";
            end
        end
	end

    return traitIcons, isRightSpec;
end

local function GetRuneForgeLegoIcon(itemLocation)
	local componentInfo = C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo(itemLocation);
	if componentInfo and componentInfo.powerID then
		local powerInfo = C_LegendaryCrafting.GetRuneforgePowerInfo(componentInfo.powerID);
		return powerInfo and powerInfo.iconFileID
	end
end


local GetSlotVisualID = NarciAPI.GetSlotVisualID;
local GetGemBorderTexture = NarciAPI.GetGemBorderTexture;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local QueueFrame = NarciAPI.CreateProcessor(nil, 0.5);

-----------------------------------------------------------------------
NarciItemButtonSharedMixin = {};

function NarciItemButtonSharedMixin:RegisterErrorEvent()
	self:RegisterEvent("UI_ERROR_MESSAGE");
end

function NarciItemButtonSharedMixin:UnregisterErrorEvent()
	if self.errorFrame then
		self.errorFrame = nil;
		self:UnregisterEvent("UI_ERROR_MESSAGE");
	end
end

function NarciItemButtonSharedMixin:OnErrorMessage(...)
	self:UnregisterErrorEvent();
	local _, msg = ...
	Narci_AlertFrame_Autohide:AddMessage(msg, true);
end

function NarciItemButtonSharedMixin:AnchorAlertFrame()
	if not self.errorFrame then
		self.errorFrame = true;
		self:RegisterErrorEvent();
		Narci_AlertFrame_Autohide:SetAnchor(self, -12, true);
	end
end

function NarciItemButtonSharedMixin:PlayGamePadAnimation()
	if self.gamepad then
		self.Icon.ScaleUp:Play();
		self.IconMask.ScaleUp:Play();
		self.Border.ScaleUp:Play();
		self.Border.BorderMask.ScaleUp:Play();
	end
end

function NarciItemButtonSharedMixin:ResetAnimation()
	if self.gamepad then
		self.Icon.ScaleUp:Stop();
		self.Border.ScaleUp:Stop();
		self.Border.BorderMask.ScaleUp:Stop();
		self.IconMask.ScaleUp:Stop();
		self.Icon:SetScale(1);
		self.Border:SetScale(1);
		self.IconMask:SetScale(1);
		self.Border.BorderMask:SetScale(1);
		if self.gamepadOverlay then
			self.gamepadOverlay:Hide();
			self.gamepadOverlay = nil;
		end
	end
end

function NarciItemButtonSharedMixin:SetBorderTexture(border, texKey)
	SetBorderTexture(border, texKey, 2);
end

function NarciItemButtonSharedMixin:ShowAlphaChannel()
	self.Icon:SetColorTexture(1, 1, 1);
	self.Border:SetColorTexture(1, 1, 1);
	self.Border.textureKey = -1;
end

-----------------------------------------------------------------------
local ValidForTempEnchant = {
	[16] = true,
	[17] = true,
	[5] = true,
};

local function GetFormattedSourceText(sourceInfo)
	local sourceType = sourceInfo.sourceType;
	local itemQuality = sourceInfo.quality or 1;
	local hex = NarciAPI.GetItemQualityHexColor(itemQuality);
	local difficulty;
	local bonusID;
	local colorizedText, plainText, hyperlink;

	if sourceType == 1 then	--TRANSMOG_SOURCE_BOSS_DROP = 1
		local drops = C_TransmogCollection.GetAppearanceSourceDrops(sourceInfo.sourceID);
		if drops and drops[1] then
			colorizedText = drops[1].encounter.." ".."|cFFFFD100"..drops[1].instance.."|r";
			plainText = drops[1].encounter.." "..drops[1].instance;
			
			if sourceInfo.itemModID == 0 then 
				difficulty = PLAYER_DIFFICULTY1;
				bonusID = 3561;
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:356".."1"..":1476:|h|r";
			elseif sourceInfo.itemModID == 1 then 
				difficulty = PLAYER_DIFFICULTY2;
				bonusID = 3562;
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:356".."2"..":1476:|h|r";
			elseif sourceInfo.itemModID == 3 then 
				difficulty = PLAYER_DIFFICULTY6;
				bonusID = 3563;
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:356".."3"..":1476:|h|r";
			elseif sourceInfo.itemModID == 4 then
				difficulty = PLAYER_DIFFICULTY3;
				bonusID = 3564;
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:356".."4"..":1476:|h|r";
			end

			if difficulty then
				colorizedText = colorizedText.." |CFFf8e694"..difficulty.."|r";
				plainText = plainText.." "..difficulty;
			end
		else
			local sourceText = _G["TRANSMOG_SOURCE_1"];	--Boss Drop
			colorizedText = sourceText;
			plainText = sourceText;
		end
	else
		if sourceType == 2 then --quest
			colorizedText = TRANSMOG_SOURCE_2;
			if sourceInfo.itemModID == 3 then 
				hyperlink= "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:512".."6"..":1562:|h|r";
				bonusID = 5126;
			elseif sourceInfo.itemModID == 2 then 
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:512".."5"..":1562:|h|r";
				bonusID = 5125;
			elseif sourceInfo.itemModID == 1 then 
				hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID.."::::::::120::::2:512".."4"..":1562:|h|r";
				bonusID = 5124;
			end
		elseif sourceType == 3 then --vendor
			colorizedText = TRANSMOG_SOURCE_3;
		elseif sourceType == 4 then --world drop
			colorizedText = TRANSMOG_SOURCE_4;
		elseif sourceType == 5 then --achievement
			colorizedText = TRANSMOG_SOURCE_5;
		elseif sourceType == 6 then	--profession
			colorizedText = TRANSMOG_SOURCE_6;
		else
			if itemQuality == 6 then
				colorizedText = ITEM_QUALITY6_DESC;
			elseif itemQuality == 5 then
				colorizedText = ITEM_QUALITY5_DESC;
			end
		end
		plainText = colorizedText;
	end
	if not hyperlink then
		hyperlink = "|c"..hex.."|Hitem:"..sourceInfo.itemID..":|h|r";
	end

	return colorizedText, plainText, hyperlink;
end

NarciEquipmentSlotMixin = CreateFromMixins{NarciItemButtonSharedMixin};

function NarciEquipmentSlotMixin:SetTransmogSourceID(appliedSourceID, secondarySourceID)
	self.sourceID = appliedSourceID;

	if appliedSourceID and appliedSourceID > 0 then
		self.Icon:SetDesaturated(false);
		self.Name:Show();
		self.ItemLevel:Show();
		self.GradientBackground:Show();
	else
		self.Icon:SetDesaturated(true);
		self.Name:SetText(nil);
		self.ItemLevel:SetText(nil);
		self.GradientBackground:Hide();	
		self:SetBorderTexture(self.Border, 0);
		if self.slotID == 2 then
			self:DisplayDirectionMark(false);
		end
		return
	end

	local itemName, itemIcon, itemQuality, subText;
	local sourceInfo = C_TransmogCollection.GetSourceInfo(appliedSourceID);
	itemName = sourceInfo and sourceInfo.name;

	if not itemName or itemName == "" then
		QueueFrame:Add(self, self.Refresh);
		return
	end

	self.itemID = sourceInfo.itemID;
	self.itemModID = sourceInfo.itemModID;
	itemQuality = sourceInfo.quality or 1;
	itemIcon = C_TransmogCollection.GetSourceIcon(appliedSourceID);

	subText = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID);

	if subText then
		self.sourcePlainText = NarciAPI.RemoveColorString(subText);
		_, _, self.hyperlink = GetFormattedSourceText(sourceInfo);
	else
		subText, self.sourcePlainText, self.hyperlink = GetFormattedSourceText(sourceInfo);
	end

	if self.hyperlink then
		_, self.hyperlink = GetItemInfo(self.hyperlink);																		--original hyperlink cannot be printed (workaround)
	end

	local bonusID;
	if itemQuality == 6 then
		if self.slotID == 16 then
			bonusID = (sourceInfo.itemModID or 0);	--Artifact use itemModID "7V0" + modID - 1
		else
			bonusID = 0;
		end
	end

	self.bonusID = bonusID;


	local bR, bG, bB = GetItemQualityColor(itemQuality);
	local borderTexKey = itemQuality;
	self:SetBorderTexture(self.Border, borderTexKey);

	if self:IsVisible() then
		if itemIcon then
			self.IconOverlay:SetTexture(itemIcon);
			self.Icon.anim:Play();
		end
		self.ItemLevel.anim1:SetScript("OnFinished", function(f)
			self.ItemLevel:SetText(subText);
			self.ItemLevel.anim2:Play();
			f:SetScript("OnFinished", nil);
		end)
		self.Name.anim1:SetScript("OnFinished", function(f)
			self.Name:SetText(itemName);
			self.Name:SetTextColor(bR, bG, bB);
			self.Name.anim2:Play();
			f:SetScript("OnFinished", nil);
			After(0, function()
				self:UpdateGradientSize();
			end)
		end)
		self.ItemLevel.anim1:Play();
		self.Name.anim1:Play();
	else
		self.ItemLevel:SetText(subText);
		self.Name:SetText(itemName);
		self.Name:SetTextColor(bR, bG, bB);
		if itemIcon then
			self.Icon:SetTexture(itemIcon);
		end
		self:UpdateGradientSize();
	end

	if self.slotID == 3 then
		--shoulder
		if secondarySourceID and secondarySourceID > 0 then
			self:DisplayDirectionMark(true, itemQuality);
			SLOT_TABLE[2]:SetTransmogSourceID(secondarySourceID, secondarySourceID);
		else
			self:DisplayDirectionMark(false);
		end
	elseif self.slotID == 2 then
		self:DisplayDirectionMark(appliedSourceID, itemQuality);
	end
end

function NarciEquipmentSlotMixin:Refresh(forceRefresh)
	local _;
	local slotID = self.slotID;
	local itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID);
	--print(slotName..slotID)
	--local texture = CharacterHeadSlot.popoutButton.icon:GetTexture()
	local itemLink;
	local itemIcon, itemName, itemQuality, effectiveLvl, gemName, gemLink, gemID;
	local borderTexKey;
	local isAzeriteEmpoweredItem = false;		--3 Pieces	**likely to be changed in patch 8.2
	local isAzeriteItem = false;				--Heart of Azeroth
	--local isCorruptedItem = false;
	local bR, bG, bB;		--Item Name Color
	if C_Item.DoesItemExist(itemLocation) then
		if MOG_MODE then
			self:UntrackCooldown();
			self:UntrackTempEnchant();
			self:ClearOverlay();
			self:HideVFX();
			self.itemLink = nil;
			self.isSlotHidden = false;	--Undress an item from player model
			self.RuneSlot:Hide();
			self.GradientBackground:Show();
			local appliedSourceID, appliedVisualID, hasSecondaryAppearance = GetSlotVisualID(slotID);
			self.sourceID = appliedSourceID;

			if appliedVisualID > 0 then
				local sourceInfo = C_TransmogCollection.GetSourceInfo(appliedSourceID);
				itemName = sourceInfo and sourceInfo.name;
				if not itemName or itemName == "" then
					QueueFrame:Add(self, self.Refresh);
					return
				end
				self.itemID = sourceInfo.itemID;
				itemQuality = sourceInfo.quality;
				self.itemModID = sourceInfo.itemModID;
				itemIcon = C_TransmogCollection.GetSourceIcon(appliedSourceID);

				effectiveLvl = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID);

				if effectiveLvl then
					self.sourcePlainText = NarciAPI.RemoveColorString(effectiveLvl);
					_, _, self.hyperlink = GetFormattedSourceText(sourceInfo);
				else
					effectiveLvl, self.sourcePlainText, self.hyperlink = GetFormattedSourceText(sourceInfo);
				end

				if self.hyperlink then
					_, self.hyperlink = GetItemInfo(self.hyperlink);																		--original hyperlink cannot be printed (workaround)
				end

				local bonusID;
				if itemQuality == 6 then
					if slotID == 16 then
						bonusID = (sourceInfo.itemModID or 0);	--Artifact use itemModID "7V0" + modID - 1
					else
						bonusID = 0;
					end
				end
				self.bonusID = bonusID;

				if effectiveLvl == nil then
					effectiveLvl = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, self.itemID, self.itemModID) or " ";
				end


			else	--irrelevant slot
				itemName = " ";
				itemQuality = 0;
				itemIcon = GetInventoryItemTexture("player", slotID);
				self.Icon:SetDesaturated(true);
				self.Name:Hide();
				self.ItemLevel:Hide();
				self.GradientBackground:Hide();
				self.bonusID = nil;
			end
			self:DisplayDirectionMark(hasSecondaryAppearance, itemQuality);
	
		else
			self:TrackCooldown();
			self:DisplayDirectionMark(false);
			self.Icon:SetDesaturated(false)
			self.Name:Show();
			self.ItemLevel:Show();
			self.GradientBackground:Show();
			self.sourceID = nil;
			self.hyperlink = nil;
			self.sourcePlainText = nil;
			--[[
			local current, maximum = GetInventoryItemDurability(slotID);
			if current and maximum then
				self.durability = (current / maximum);
			end
			--]]

			itemLink = C_Item.GetItemLink(itemLocation);

			if ValidForTempEnchant[slotID] then
				local hasTempEnchant = NarciTempEnchantIndicatorController:InitFromSlotButton(self);
				if hasTempEnchant ~= self.hasTempEnchant then
					self.hasTempEnchant = hasTempEnchant;
				else
					if itemLink == self.itemLink then
						return
					end
				end
			else
				if itemLink == self.itemLink then
					return
				end
			end

			self.itemLink = itemLink;

			local itemVFX, hideItemIcon;
			local itemID = GetItemInfoInstant(itemLink);
			borderTexKey, itemVFX, bR, bG, bB, hideItemIcon = GetBorderArtByItemID(itemID);

			itemIcon = ((not hideItemIcon) and GetInventoryItemTexture("player", slotID)) or nil;
			itemName = C_Item.GetItemName(itemLocation);
			itemQuality = C_Item.GetItemQuality(itemLocation);
			effectiveLvl = C_Item.GetCurrentItemLevel(itemLocation);
			self.ItemLevelCenter.ItemLevel:SetText(effectiveLvl);

			--Debug
			--if effectiveLvl and effectiveLvl > 1 then
			--	NarciDebug:CalculateAverage(effectiveLvl);
			--end

			if not hideItemIcon then
				if slotID == 13 or slotID == 14 then
					if itemID == 167555 then	--Pocket-Sized Computation Device
						gemName, gemLink = IsItemSocketable(itemLink, 2);
					else
						gemName, gemLink = IsItemSocketable(itemLink);
					end
				else
					gemName, gemLink = IsItemSocketable(itemLink);
				end
			end
			
			self.GemSlot.ItemLevel = effectiveLvl;
			self.gemLink = gemLink;		--Later used in OnEnter func in NarciSocketing.lua
			
			if slotID == 2 then
				isAzeriteItem = C_AzeriteItem.IsAzeriteItem(itemLocation);
				self.isAzeriteItem = isAzeriteItem;
				if isAzeriteItem then
					itemVFX = "Heart";
				end
			elseif slotID == 1 or slotID == 3 or slotID == 5 then
				isAzeriteEmpoweredItem = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation);
			else
				--isCorruptedItem = IsCorruptedItem(itemLink);
			end

			if slotID == 15 then
				--Backslot
				if itemID == 169223 then 	--Ashjra'kamas, Shroud of Resolve Legendary Cloak
					local rank, corruptionResistance = NarciAPI.GetItemRankText(itemLink, "ITEM_MOD_CORRUPTION_RESISTANCE");
					effectiveLvl = effectiveLvl.."  "..rank.."  |cFFFFD100"..corruptionResistance.."|r";
					borderTexKey = "BlackDragon";
					itemVFX = "DragonFire";
				elseif itemID == 210333 then		--Timerunning Thread
					local rank = TimerunningUtil.GetThreadRank();
					if rank > 0 then
						rank = "|cff00ccff"..rank.."|r";
						effectiveLvl = effectiveLvl.."  "..rank;
					end
				end
			end

			if slotID ~= 13 and slotID ~= 14 then
				local isRuneforgeLegendary = C_LegendaryCrafting.IsRuneforgeLegendary(itemLocation);
				if isRuneforgeLegendary then
					itemVFX = "Runeforge";
					borderTexKey = "Runeforge";
					itemIcon = GetRuneForgeLegoIcon(itemLocation) or itemIcon;
				end
			end
	

			local enchantText, isEnchanted = GetItemEnchantText(itemLink, true, self.isRight);	--enchantText (effect texts) may not be available yet
			if enchantText then
				if self.isRight then
					effectiveLvl = enchantText.."  "..effectiveLvl;
				else
					effectiveLvl = effectiveLvl.."  "..enchantText;
				end
				self:ClearOverlay();
			elseif not isEnchanted then
				if SHOW_MISSING_ENCHANT_ALERT and SlotButtonOverlayUtil:IsSlotValidForEnchant(slotID, itemID) then
					SlotButtonOverlayUtil:ShowEnchantAlert(self, slotID, itemID);
					if self.isRight then
						effectiveLvl = effectiveLvl .. "  ".. L["Missing Enchant"];
					else
						effectiveLvl = L["Missing Enchant"].."  "..effectiveLvl;
					end
				end
			end

			--Enchant Frame--
			if itemQuality then	--and not isRuneforgeLegendary
				DisplayRuneSlot(self, slotID, itemQuality, itemLink);
			end

			--Item Visual Effects
			if itemVFX then
				self:ShowVFX(itemVFX);
			else
				self:HideVFX();
			end
		end

		if not itemName or itemName == "" then
			QueueFrame:Add(self, self.Refresh);
			return
		end
	else
		self:UntrackCooldown();
		self:UntrackTempEnchant();
		self:ClearOverlay();
		self:HideVFX();
		self:DisplayDirectionMark(false);
		self.GradientBackground:Hide();
		self.Icon:SetDesaturated(false);
		self.ItemLevelCenter.ItemLevel:SetText("");
		self.itemID = nil;
		self.bonusID = nil;
		self.itemLink = nil;
		self.gemLink = nil;
		itemQuality = 0;
		itemIcon = self.emptyTexture;
		itemName = " " ;
		effectiveLvl = "";
		DisplayRuneSlot(self, slotID, 0);
	end

	self.itemQuality = itemQuality;
	
	if itemQuality and not bR then --itemQuality sometimes return nil. This is a temporary solution
		bR, bG, bB = GetItemQualityColor(itemQuality);
		if not borderTexKey then
			borderTexKey = itemQuality;
		end
	end
	bR = bR or 1;
	bG = bG or 1;
	bB = bB or 1;

	if isAzeriteEmpoweredItem then
		borderTexKey = "Azerite";
		if not MOG_MODE then
			local icons, isRightSpec = GetTraitsIcon(itemLocation);
			for i = 1, #icons do
				effectiveLvl = effectiveLvl.." |T"..icons[i]..":12:12:0:0:64:64:4:60:4:60|t";
			end
		end
	end

	if isAzeriteItem then
		local heartLevel = C_AzeriteItem.GetPowerLevel(itemLocation);
		local xp_Current, xp_Needed =  C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation);
		local GetEssenceInfo = C_AzeriteEssence.GetEssenceInfo;
		local GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence;
		if not C_AzeriteItem.IsAzeriteItemAtMaxLevel() then
			heartLevel = heartLevel .. "  |CFFf8e694" .. floor((xp_Current/xp_Needed)*100 + 0.5) .. "%";
		end
		effectiveLvl = effectiveLvl.."  |cFFFFD100"..heartLevel;
		
		local EssenceID = GetMilestoneEssence(115);
		if EssenceID then
			borderTexKey = "Heart";
			local EssenceInfo = GetEssenceInfo(EssenceID);
			bR, bG, bB = GetItemQualityColor(EssenceInfo.rank + 1);
			itemName = EssenceInfo.name;
			itemIcon = EssenceInfo.icon;
		end

		for i = 116, 119 do
			--116, 117, 119  3 minor slots
			if i ~= 118 then
				EssenceID = GetMilestoneEssence(i);
				if EssenceID then
					local icon = GetEssenceInfo(EssenceID).icon;
					effectiveLvl = effectiveLvl.." |T"..icon..":12:12:0:0:64:64:4:60:4:60|t";
				end
			end
		end
	end

	--[[
	if isCorruptedItem then
		borderTexKey = "NZoth";
		if not MOG_MODE then
			local corruption = GetItemStats(itemLink)["ITEM_MOD_CORRUPTION"];
			if corruption then
				local Affix = GetCorruptedItemAffix(itemLink);
				if Affix then
					if self.isRight then
						effectiveLvl = Affix.."  |cff946dd1"..corruption.."|r  "..effectiveLvl;
					else
						effectiveLvl = effectiveLvl.."  "..Affix.."  |cff946dd1"..corruption.."|r";
					end
				else
					if self.isRight then
						effectiveLvl = "|cff946dd1"..corruption.."|r  "..effectiveLvl;
					else
						effectiveLvl = effectiveLvl.."  |cff946dd1"..corruption.."|r";
					end				
				end
			end
			itemQuality = "NZoth";
		end
	end
	--]]

	--Gem Slot--
	if gemName ~= nil then
		local gemBorder, gemIcon, itemSubClassID;

		--regular gems
		if gemLink then
			gemID, _, _, _, gemIcon, _, itemSubClassID = GetItemInfoInstant(gemLink);
			gemBorder = GetGemBorderTexture(itemSubClassID, gemID);
		else
			gemBorder = GetGemBorderTexture(nil);
		end

		self.GemSlot.GemBorder:SetTexture(gemBorder);
		self.GemSlot.GemIcon:SetTexture(gemIcon);
		self.GemSlot.GemIcon:Show();
		self.GemSlot.sockedGemItemID = gemID;
		if self:IsVisible() then
			self.GemSlot:FadeIn();
		else
			self.GemSlot:ShowSlot();
		end
	else
		if self:IsVisible() then
			self.GemSlot:FadeOut();
		else
			self.GemSlot:HideSlot();
		end
		self.GemSlot.sockedGemItemID = nil;
	end

	--if slotID == 13 then itemName = "The Lion\'s Roar"; end	--Antumbra, Shadow of the Cosmos
	--------------------------------------------------
	if self:IsVisible() then
		self:SetBorderTexture(self.Border, borderTexKey);
		if itemIcon then
			self.IconOverlay:SetTexture(itemIcon);
			self.Icon.anim:Play();
		end
		self.ItemLevel.anim1:SetScript("OnFinished", function(f)
			self.ItemLevel:SetText(effectiveLvl);
			self.ItemLevel.anim2:Play();
			f:SetScript("OnFinished", nil);
		end)
		self.Name.anim1:SetScript("OnFinished", function(f)
			self.Name:SetText(itemName);
			self.Name:SetTextColor(bR, bG, bB);
			self.Name.anim2:Play();
			f:SetScript("OnFinished", nil);
			After(0, function()
				self:UpdateGradientSize();
			end)
		end)
		self.ItemLevel.anim1:Play();
		self.Name.anim1:Play();
	else
		self.ItemLevel:SetText(effectiveLvl);
		self.Name:SetText(itemName);
		self.Name:SetTextColor(bR, bG, bB);
		self:SetBorderTexture(self.Border, borderTexKey);
		if itemIcon then
			self.Icon:SetTexture(itemIcon);
		end
		self:UpdateGradientSize();
	end
	--self.GradientBackground:SetHeight(self.Name:GetHeight() + self.ItemLevel:GetHeight() + 18);
	self.itemNameColor = {bR, bG, bB};

	return true
end

function NarciEquipmentSlotMixin:UpdateGradientSize()
	local text2Width = self.ItemLevel:GetWrappedWidth();
	local extraWidth;
	if self.TempEnchantIndicator then
		extraWidth = 48;
		self.TempEnchantIndicator:ClearAllPoints();
		if self.isRight then
			self.TempEnchantIndicator:SetPoint("TOPRIGHT", self.ItemLevel, "TOPRIGHT", -text2Width - 6, 0);
		else
			local extraOffset;
			if self.ItemLevel:IsTruncated() then
				text2Width = self.ItemLevel:GetWidth();
			end
			self.TempEnchantIndicator:SetPoint("TOPLEFT", self.ItemLevel, "TOPLEFT", text2Width + 6, 0);
		end
	else
		extraWidth = 0;
	end
	self.GradientBackground:SetHeight(self.Name:GetHeight() + self.ItemLevel:GetHeight() + 18);
	self.GradientBackground:SetWidth(max(self.Name:GetWrappedWidth(), text2Width + extraWidth, 48) + 48);
end

function NarciEquipmentSlotMixin:OnLoad()
	local slotName = self.slotName;
	local slotID, textureName = GetInventorySlotInfo(slotName);
	self.emptyTexture = textureName;
	self:SetID(slotID);
	self.slotID = slotID;
	self:SetAttribute("type2", "item");
	self:SetAttribute("item", slotID);
	self:RegisterForDrag("LeftButton");
	self:RegisterForClicks("LeftButtonUp", "RightButtonDown", "RightButtonUp");
	if self:GetParent() then
		if not self:GetParent().slotTable then
			self:GetParent().slotTable = {}
		end
		tinsert(self:GetParent().slotTable, self);
	end
	SLOT_TABLE[slotID] = self;

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

function NarciEquipmentSlotMixin:OnEvent(event, ...)
	if event == "MODIFIER_STATE_CHANGED" then
		local key, state = ...;
		if ( key == "LALT" and self:IsMouseOver() ) then
			local flyout = EquipmentFlyoutFrame;
			if state == 1 then
				if flyout:IsShown() and flyout.slotID == self:GetID() then
					flyout:Hide();
				else
					flyout:SetItemSlot(self, true);
				end
			else
				if not MOG_MODE then
					ItemTooltip:SetFromSlotButton(self, -2, 6);
				end
			end
		end
	elseif event == "UI_ERROR_MESSAGE" then
		self:OnErrorMessage(...);
	end
end

function NarciEquipmentSlotMixin:UntrackCooldown()
	if self.CooldownFrame then
		self.CooldownFrame:Clear();
		self.CooldownFrame = nil;
	end
end

function NarciEquipmentSlotMixin:ClearOverlay()
	if SHOW_MISSING_ENCHANT_ALERT and self.slotOverlay then
		SlotButtonOverlayUtil:ClearOverlay(self);
		self.slotOverlay = nil;
	end
end

function NarciEquipmentSlotMixin:TrackCooldown()
	local start, duration, enable = GetInventoryItemCooldown("player", self:GetID());
	if enable and enable ~= 0 and start > 0 and duration > 0 then
		if not self.CooldownFrame then
			self.CooldownFrame = NarciItemCooldownUtil.AccquireFrame(self);
		end
		self.CooldownFrame:SetCooldown(start, duration);
		return true
	else
		self:UntrackCooldown();
	end
	return false
end

function NarciEquipmentSlotMixin:UntrackTempEnchant()
	if self.TempEnchantIndicator then
		self.TempEnchantIndicator:Hide();
		self.TempEnchantIndicator = nil;
	end
end

function NarciEquipmentSlotMixin:OnEnter(motion, isGamepad)
	self:RegisterEvent("MODIFIER_STATE_CHANGED");

	if isGamepad then
		self:PlayGamePadAnimation();
	else
		FadeFrame(self.Highlight, 0.15, 1);
	end

	if IsAltKeyDown() and not MOG_MODE then
		EquipmentFlyoutFrame:SetItemSlot(self, true);
		return
	end

	if EquipmentFlyoutFrame:IsShown() then
		Narci_Comparison_SetComparison(EquipmentFlyoutFrame.BaseItem, self);
		return;
	end

	if MOG_MODE then
		ItemTooltip:SetTransmogFromSlotButton(self, -2, 6);
	else
		ItemTooltip:SetFromSlotButton(self, -2, 6, isGamepad and 0.4);	--delay 0.4s
	end

	--[[
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");

	if self.isRight then
		DefaultTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", DefaultTooltip.offsetX, DefaultTooltip.offsetY);
	else
		DefaultTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", -DefaultTooltip.offsetX, DefaultTooltip.offsetY);
	end

	if (self.hyperlink) then
		DefaultTooltip:SetHyperlink(self.hyperlink);
		DefaultTooltip:Show();
		return;
	end

	local hasItem, hasCooldown, repairCost = DefaultTooltip:SetPlayerInventoryItem(self:GetID());

	if isGamepad then
		DefaultTooltip:SetAlpha(0);
		if self.isRight then
			ShowDelayedTooltip("TOPRIGHT", self, "TOPLEFT", DefaultTooltip.offsetX, DefaultTooltip.offsetY);
		else
			ShowDelayedTooltip("TOPLEFT", self, "TOPRIGHT", -DefaultTooltip.offsetX, DefaultTooltip.offsetY);
		end
	else
		DefaultTooltip:Show();
	end
	--]]
end

function NarciEquipmentSlotMixin:OnLeave()
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
	self:UnregisterErrorEvent();
	FadeFrame(self.Highlight, 0.25, 0);
	Narci:HideButtonTooltip();
	self:ResetAnimation();
end

function NarciEquipmentSlotMixin:OnHide()
	self.Highlight:Hide();
	self.Highlight:SetAlpha(0);
	self:ResetAnimation();
end

function NarciEquipmentSlotMixin:PreClick(button)

end

function NarciEquipmentSlotMixin:PostClick(button, down)
	if CursorHasItem() and button == "LeftButton" then
		EquipCursorItem(self:GetID());
		return
	end

	ClearCursor();

	if ( IsModifiedClick() ) then
		if IsAltKeyDown() and button == "LeftButton" then
			local action = EquipmentManager_UnequipItemInSlot(self:GetID())
			if action then
				EquipmentManager_RunAction(action)
			end
			return;
		elseif IsShiftKeyDown() and button == "LeftButton" then
			if self.hyperlink then
				if ChatEdit_InsertLink(self.hyperlink) then
					return
				elseif SocialPostFrame and Social_IsShown() then
					Social_InsertLink(self.hyperlink);
					return
				end
			end
		else
			PaperDollItemSlotButton_OnModifiedClick(self, button);
			TakeOutFrames(true);
			SetItemSocketingFramePosition(self);
		end
	else
		if button == "LeftButton" then
			if not MOG_MODE then	--Undress an item from player model while in Xmog Mode
				--EquipmentFlyoutFrame:SetItemSlot(self);
				Narci_EquipmentOption:SetFromSlotButton(self, true)
			end
		elseif button == "RightButton" then
			local useKeyDown = C_CVar.GetCVarBool("ActionButtonUseKeyDown");
			if (useKeyDown and down) or (not useKeyDown and not down) then
				self:AnchorAlertFrame();
			end
		end
	end
end

function NarciEquipmentSlotMixin:OnDragStart()
	local itemLocation = ItemLocation:CreateFromEquipmentSlot(self:GetID())
	if C_Item.DoesItemExist(itemLocation) then
		C_Item.UnlockItem(itemLocation);
		PickupInventoryItem(self:GetID());
	end
end

function NarciEquipmentSlotMixin:OnReceiveDrag()
	PickupInventoryItem(self:GetID());	--In fact, attemp to equip cursor item
end

function NarciEquipmentSlotMixin:DisplayDirectionMark(visible, itemQuality)
	if self.slotID == 2 or self.slotID == 3 then
		if visible then
			if not self.DirectionMark then
				self.DirectionMark = CreateFrame("Frame", nil, self, "NarciTransmogSlotDirectionMarkTemplate");
				self.DirectionMark:SetPoint("RIGHT", self, "LEFT", 9, 0);
				self.DirectionMark:SetDirection(self.slotID - 1);
			end
			FadeFrame(self.DirectionMark, 0.25, 1);
			if itemQuality then
				self.DirectionMark:SetQualityColor(itemQuality);
			end
		else
			if self.DirectionMark then
				self.DirectionMark:Hide();
				self.DirectionMark:SetAlpha(0);
			end
		end
	end
end

function NarciEquipmentSlotMixin:ShowVFX(effectName)
	if effectName then
		if self.VFX then
			self.VFX:SetUpByName(effectName);
		else
			self.VFX = NarciItemVFXContainer:AcquireAndSetModelScene(self, effectName);
		end
	else
		self:HideVFX();
	end
end

function NarciEquipmentSlotMixin:HideVFX()
	if self.VFX then
		self.VFX:Remove();
	end
end

local function SetStatTooltipText(self)
	DefaultTooltip:ClearAllPoints();
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	DefaultTooltip:SetText(self.tooltip);
	if ( self.tooltip2 ) then
		DefaultTooltip:AddLine(self.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
	end
	if ( self.tooltip3 ) then
		DefaultTooltip:AddLine(" ");
		DefaultTooltip:AddLine(self.tooltip3, RAID_CLASS_COLORS["MAGE"].r, RAID_CLASS_COLORS["MAGE"].g, RAID_CLASS_COLORS["MAGE"].b, true);
	end
	if ( self.tooltip4 ) then
		DefaultTooltip:AddLine(" ");
		DefaultTooltip:AddDoubleLine(self.tooltip4[1], self.tooltip4[2], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end
end

function Narci_ShowStatTooltip(self, direction)
	if ( not self.tooltip ) then
		return;
	end
	SetStatTooltipText(self)
	if (not direction) then
		DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0)
	elseif direction=="RIGHT" then
		DefaultTooltip:SetPoint("LEFT",self,"RIGHT", 0, 0)
	elseif direction=="TOP" then
		DefaultTooltip:SetPoint("BOTTOM",self,"TOP", 0, -4)
	elseif direction=="CURSOR" then
		DefaultTooltip:SetOwner(self, "ANCHOR_CURSOR");
	end

	DefaultTooltip:Show();
end

function Narci_ShowStatTooltipDelayed(self)
	if ( not self.tooltip ) then
		return;
	end
	SetStatTooltipText(self);
	DefaultTooltip:SetAlpha(0);
	ShowDelayedTooltip("BOTTOM", self, "TOP", 0, -4);
	--print("Narci_ShowStatTooltipDelayed")
end


function NarciItemLevelFrameMixin:OnLoad()
	--Declared in Modules\CharacterFrame\ItemLevelFrame.lua
	ItemLevelFrame = self;
	self:Init();
end


local function UpdateCharacterInfoFrame(newLevel)
	local level = newLevel or UnitLevel("player");

	local specClassName = TalentTreeDataProvider:GetPlayerSpecClassName(true);	--colorized

	if specClassName then
		local frame = Narci_PlayerInfoFrame;
		local levelNumber = "|cFFFFD100"..level.."|r";
		local titleID = GetCurrentTitle();
		local titleName = GetTitleName(titleID);
		if titleName and titleName ~= "" then
			titleName = strtrim(titleName); --delete the space in Title
			frame.Miscellaneous:SetText(titleName.."  |  "..levelNumber.."  "..specClassName);
		else
			frame.Miscellaneous:SetText("|cFFFFD100Level|r "..levelNumber.."  "..specClassName);
		end
	end

	ItemLevelFrame:UpdateItemLevel(level);
end

local SlotController = {};
SlotController.updateFrame = CreateFrame("Frame");
SlotController.updateFrame:Hide();
SlotController.updateFrame:SetScript("OnUpdate", function(f, elapsed)
	f.t = f.t + elapsed;
	if f.t >= 0.05 then
		f.t = 0;
		if SlotController:Refresh(f.sequence[f.i], f.forceRefresh) then
			f.i = f.i + 1;
		else
			f:Hide();
			if MOG_MODE and Toolbar.TransmogListFrame:IsShown() then
				After(0.5, function()
					Toolbar.TransmogListFrame:UpdateTransmogList();
				end);
			end
		end
	end
end);

SlotController.refreshSequence = {
	1, 2, 3, 15, 5, 9, 16, 17, 4,
	10, 6, 7, 8, 11, 12, 13, 14, 19,
};

SlotController.tempEnchantSequence = {};

for slotID in pairs(ValidForTempEnchant) do
	tinsert(SlotController.tempEnchantSequence, slotID);
end

function SlotController:Refresh(slotID, forceRefresh)
	if SLOT_TABLE[slotID] then
		SLOT_TABLE[slotID]:Refresh(forceRefresh);
		return true;
	end
end

function SlotController:RefreshAll(forceRefresh)
	for slotID, slotButton in pairs(SLOT_TABLE) do
		slotButton:Refresh(forceRefresh);
	end
end

function SlotController:StopRefresh()
	if self.updateFrame then
		self.updateFrame:Hide();
	end
end

function SlotController:LazyRefresh(sequenceName)
	local f = self.updateFrame;
	f:Hide();
	f.t = 0;
	f.i = 1;
	if sequenceName == "temp" then
		f.sequence = self.tempEnchantSequence;
		f.forceRefresh = true;
	else
		f.sequence = self.refreshSequence;
		f.forceRefresh = false;
	end
	f:Show();
end

function SlotController:ClearCache()
	for slotID, slotButton in pairs(SLOT_TABLE) do
		slotButton.itemLink = nil;
	end
end

function SlotController:PlayAnimOut()
	if not InCombatLockdown() and Narci_Character:IsShown() then
		for slotID, slotButton in pairs(SLOT_TABLE) do
			slotButton.animOut:Play();
		end
		Narci_Character.animOut:Play();
	end
end

function SlotController:IsMouseOver()
	for slotID, slotButton in pairs(SLOT_TABLE) do
		if slotButton:IsMouseOver() then
			return true
		end
	end
	return false
end


------------------------------------------------------------------
-----Some of the codes are derivated from EquipmentFlyout.lua-----
------------------------------------------------------------------

NarciEquipmentFlyoutButtonMixin = CreateFromMixins{NarciItemButtonSharedMixin};

function NarciEquipmentFlyoutButtonMixin:OnClick(button, down, isGamepad)
	if button == "LeftButton" then
		local action = EquipmentManager_EquipItemByLocation(self.location, self.slotID)
		if action then
			self:AnchorAlertFrame();
			ConfirmBinding();
			EquipmentManager_RunAction(action);
		end
		self:Disable();
		if isGamepad then
			EquipmentFlyoutFrame.gamepadButton = self;
		end
	end
end

function NarciEquipmentFlyoutButtonMixin:OnLeave()
	FadeFrame(self.Highlight, 0.25, 0);
	Narci:HideButtonTooltip();
	self:ResetAnimation();
end

function NarciEquipmentFlyoutButtonMixin:OnEnter(motion, isGamepad)
	Narci_Comparison_SetComparison(self.itemLocation, self);
	if isGamepad then
		self:PlayGamePadAnimation();
	else
		FadeFrame(self.Highlight, 0.15, 1);
	end
end

function NarciEquipmentFlyoutButtonMixin:OnEvent(event, ...)
	if event == "UI_ERROR_MESSAGE" then
		self:OnErrorMessage(...);
	end
end

function NarciEquipmentFlyoutButtonMixin:SetUp(maxItemLevel)
	self.FlyUp:Stop();
	local itemLocation = self.itemLocation;
	self.hyperlink = C_Item.GetItemLink(itemLocation)
	if ( not itemLocation ) then
		return;
	end

	local itemID = C_Item.GetItemID(itemLocation);
	local itemQuality = C_Item.GetItemQuality(itemLocation);
	local itemLevel = C_Item.GetCurrentItemLevel(itemLocation);
	local itemIcon = C_Item.GetItemIcon(itemLocation);
	local itemLink = C_Item.GetItemLink(itemLocation)

	if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
		itemQuality = "Azerite";	--AzeriteEmpoweredItem
	elseif C_AzeriteItem.IsAzeriteItem(itemLocation) then
		itemQuality = "Heart";
	elseif C_Item.IsCorruptedItem(itemLink) then
		itemQuality = "NZoth";
	elseif C_LegendaryCrafting.IsRuneforgeLegendary(itemLocation) then
		itemQuality = "Runeforge";
		itemIcon = GetRuneForgeLegoIcon(itemLocation) or itemIcon;
	end

	itemQuality = GetBorderArtByItemID(itemID) or itemQuality;

	if maxItemLevel and itemLevel < maxItemLevel and itemQuality ~= "Runeforge" then
		itemQuality = 0;
		self.Icon:SetDesaturated(true);
	else
		self.Icon:SetDesaturated(false);
	end

	self.Icon:SetTexture(itemIcon)
	--self.Border:SetTexture(BorderTexture[itemQuality])
	self:SetBorderTexture(self.Border, itemQuality);
	self.ItemLevelCenter.ItemLevel:SetText(itemLevel);
	self.ItemLevelCenter:Show();

	if itemLink then
		DisplayRuneSlot(self, self.slotID, itemQuality, itemLink);
	end
end

function NarciEquipmentFlyoutButtonMixin:HideButton()
	self:Hide();
	self.location = nil;
	self.hyperlink = nil;
end

local function ShowLessItemInfo(self, bool)
	if bool then
		self.Name:Hide();
		self.ItemLevel:Hide();
		self.ItemLevelCenter:Show();
	else
		self.Name:Show();
		self.ItemLevel:Show();
		self.ItemLevelCenter:Hide();
	end
end

local function ShowAllItemInfo()
	if MOG_MODE then
		return
	end

	local level = Narci_FlyoutBlack:GetFrameLevel() - 1;

	for slotID, slotButton in pairs(SLOT_TABLE) do
		ShowLessItemInfo(slotButton, false);
		slotButton:SetFrameLevel(level -1)
		slotButton.RuneSlot:SetFrameLevel(level)
	end
end

NarciEquipmentFlyoutFrameMixin = {};

function NarciEquipmentFlyoutFrameMixin:OnLoad()
	EquipmentFlyoutFrame = self;
	self.buttons = {};
	self.slotID = -1;
	self.itemSortFunc = function(a,b)
		return tonumber(a.level)> tonumber(b.level)
	end
	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
	self:SetFixedFrameStrata(true);
	self:SetFrameStrata("HIGH");
end

function NarciEquipmentFlyoutFrameMixin:OnHide()
	ShowAllItemInfo();
	self.slotID = -1;
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	self.Arrow:Hide();
	self:StopAnimating();

	if Narci_Character.animOut:IsPlaying() then return; end
	Narci_FlyoutBlack:Out();
end

function NarciEquipmentFlyoutFrameMixin:OnShow()
	self:RegisterEvent("MODIFIER_STATE_CHANGED");
	self:RegisterEvent("GLOBAL_MOUSE_DOWN");
	self.Arrow.anim:Play();
end

function NarciEquipmentFlyoutFrameMixin:OnEvent(event, ...)	--Hide Flyout if Left-Alt is released
	if ( event == "MODIFIER_STATE_CHANGED" ) then
		local key, state = ...;
		if ( key == "LALT" ) then
			local flyout = EquipmentFlyoutFrame;
			if state == 0 and flyout:IsShown() then
				flyout:Hide();
			end
		end
	elseif (event == "GLOBAL_MOUSE_DOWN") then
		if not self:IsMouseOverButtons() then
			self:Hide();
		end
	end
end

function NarciEquipmentFlyoutFrameMixin:SetItemSlot(slotButton, showArrow)
	if MOG_MODE then
		return;
	end

	local slotID = slotButton.slotID;
	if (slotID == -1 or (self:IsShown() and self.parentButton and self.parentButton.slotID == slotID)) and (not IsAltKeyDown()) then
		self:Hide();
		return;
	end

	if self.parentButton then
		local level = Narci_FlyoutBlack:GetFrameLevel() -1
		self.parentButton:SetFrameLevel(level - 1);
		self.parentButton.RuneSlot:SetFrameLevel(level);
		ShowLessItemInfo(self.parentButton, false);
	end

	self.parentButton = slotButton;
	self:DisplayItemsBySlotID(slotID, self.slotID ~= slotID);
	self.slotID = slotID;
	self:SetParent(slotButton);
	self:ClearAllPoints();
	if slotButton.isRight then
		self:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", 0, 0);			--EquipmentFlyout's Position
	else
		self:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", 0, 0);
	end

	--Unequip Arrow
	self.Arrow:ClearAllPoints();
	self.Arrow:SetPoint("TOP", slotButton, "TOP", 0, 8);
	if showArrow then
		self.Arrow:Show();
	end

	Narci_FlyoutBlack:In();
	slotButton:SetFrameLevel(Narci_FlyoutBlack:GetFrameLevel() + 1)
	self:SetFrameLevel(50);

	NarciEquipmentTooltip:HideTooltip();
	ShowLessItemInfo(slotButton, true)

	--Reposition Comparison Tooltip if it reaches the top of the screen--
	local Tooltip = Narci_Comparison;
	Tooltip:ClearAllPoints();
	Tooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 8, 12);
	if slotButton:GetTop() > Tooltip:GetBottom() then
    	Tooltip:ClearAllPoints();
    	Tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 8, -12);
	end
	Narci_Comparison_SetComparison(self.BaseItem, slotButton);
	Narci_ShowComparisonTooltip(Tooltip);
end

function NarciEquipmentFlyoutFrameMixin:CreateItemButton()
	local perRow = 5;	--EQUIPMENTFLYOUT_ITEMS_PER_ROW
	local numButtons = #self.buttons;

	local button = CreateFrame("Button", nil, self.ButtonFrame, "NarciEquipmentFlyoutButtonTemplate");
	button:SetFrameStrata("DIALOG");
	local row = floor(numButtons/perRow);
	local col = numButtons - row * perRow;
	button:SetPoint("TOPLEFT", self, "TOPLEFT", 70*col, -74*row);
	self.buttons[numButtons + 1] = button;
	button.FlyUp.Move:SetStartDelay(numButtons/25);
	button.FlyUp.Fade:SetStartDelay(numButtons/25);
	button.isFlyout = true;
	return button
end

function NarciEquipmentFlyoutFrameMixin:DisplayItemsBySlotID(slotID, playFlyUpAnimation)
	local LoadItemData = C_Item.RequestLoadItemData;	--Cache Item Info
	local id = slotID or self.slotID;
	if not id or id <= 0 then
		return
	end
	self:Show();
	local baseItemLevel;
	local bastItemLocation = ItemLocation:CreateFromEquipmentSlot(id);
	if C_Item.DoesItemExist(bastItemLocation) then
		baseItemLevel = C_Item.GetCurrentItemLevel(bastItemLocation);
	else
		baseItemLevel = 0;
	end
	self.BaseItem = bastItemLocation;
	local buttons = self.buttons;
	
	--Get the items from bags;
	local itemTable = {};
	local sortedItems = {};
	local numItems = 0;
	GetInventoryItemsForSlot(id, itemTable);
	local itemLocation, itemLevel, itemInfo;
	local invLocationPlayer = ITEM_INVENTORY_LOCATION_PLAYER;
	for location, hyperlink in pairs(itemTable) do
		if ( location - id == invLocationPlayer ) then -- Remove the currently equipped item from the list
			itemTable[location] = nil;
		else
			local _, _, bags, _, slot, bag = EquipmentManager_UnpackLocation(location);
			if bags then
				itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot);
				itemLevel = C_Item.GetCurrentItemLevel(itemLocation);
				LoadItemData(itemLocation);
				itemInfo = {level = itemLevel, itemLocation = itemLocation, location = location};
				numItems = numItems + 1;
				sortedItems[numItems] = itemInfo;
			end
		end
	end
	table.sort(sortedItems, self.itemSortFunc);		--Sorted by item level
	local numTotalItems = #sortedItems;
	local buttonWidth, buttonHeight = self.parentButton:GetWidth(), self.parentButton:GetHeight();
	buttonWidth, buttonHeight = floor(buttonWidth + 0.5), floor(buttonHeight + 0.5);
	local borderSize = self.parentButton.Border:GetSize();
	borderSize = floor(borderSize + 0.5);
	self:SetWidth(max(buttonWidth, math.min(numTotalItems, 5)*buttonWidth));
	local numDisplayedItems = math.min(numTotalItems, 20);	--EQUIPMENTFLYOUT_ITEMS_PER_PAGE
	self:SetHeight(max(floor((numDisplayedItems-1)/5 + 1)*buttonHeight, buttonHeight));

	local gamepadButton = self.gamepadButton;
	self.gamepadButton = nil;

	baseItemLevel = baseItemLevel - 14;		--darken button if the item level is lower than the base
	local button;

	for i = 1, numDisplayedItems do
		button = buttons[i];
		if not button then
			button = self:CreateItemButton();
		end
		button.itemLocation = sortedItems[i].itemLocation;
		button.location = sortedItems[i].location;
		button.slotID = id;
		button:SetUp(baseItemLevel);
		button:Show();
		button:SetSize(buttonWidth, buttonHeight);
		button.Border:SetSize(borderSize, borderSize);
		button:Enable();
		if button == gamepadButton then
			Narci_Comparison_SetComparison(gamepadButton.itemLocation, gamepadButton);
			Narci_GamepadOverlayContainer.SlotBorder:UpdateQualityColor(gamepadButton);
		end
	end

	for i = numDisplayedItems + 1, #buttons do
		buttons[i]:HideButton();
	end

	if playFlyUpAnimation then
		for i = 1, numDisplayedItems do
			buttons[i].FlyUp:Play();
		end
	end

	self.numDisplayedItems = numDisplayedItems;		--For gamepad to cycle
end

function NarciEquipmentFlyoutFrameMixin:IsMouseOverButtons()
	for i = 1, #self.buttons do
		if self.buttons[i]:IsShown() and self.buttons[i]:IsMouseOver() then
			return true;
		end
	end
	if self.parentButton:IsMouseOver() then
		return true
	end

	if SlotController:IsMouseOver() then
		return true
	end
	return false
end
-----------------------------------------------------------
------------------------Color Theme------------------------
-----------------------------------------------------------
local ColorUtil = {};
ColorUtil.themeColor = NarciThemeUtil:GetColorTable();

function ColorUtil:UpdateByMapID()
	local mapID = C_Map.GetBestMapForUnit("player");
	--print("mapID:".. mapID)
	if mapID then	--and NarcissusDB.AutoColorTheme
		if mapID == self.mapID then
			self.requireUpdate = false;
		else
			self.mapID = mapID;
			self.requireUpdate = true;
			self.themeColor = NarciThemeUtil:SetColorIndex(mapID);
			RadarChart:UpdateColor();

			Narci_NavBar:SetThemeColor(self.themeColor);
		end
	else
		self.requireUpdate = false;
	end
end

function ColorUtil:SetWidgetColor(frame)
	if not self.requireUpdate then return end;

	local r, g, b = self.themeColor[1], self.themeColor[2], self.themeColor[3];
	local type = frame:GetObjectType();

	if type == "FontString" then
		local sqrt = math.sqrt;
		r, g, b = sqrt(r), sqrt(g), sqrt(b);
		frame:SetTextColor(r, g, b);
	else
		frame:SetColorTexture(r, g, b);
	end
end

---------------------------------------------
NarciRadarChartMixin = {}

function NarciRadarChartMixin:OnLoad()
	RadarChart = self;

	local circleTex = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\RadarChart\\Radar-Vertice";
	local filter = "TRILINEAR";
	local tex;
	local texs = {};
	for i = 1, 4 do
		tex = self:CreateTexture(nil, "OVERLAY", nil, 2);
		tinsert(texs, tex);
		tex:SetSize(12, 12);
		tex:SetTexture(circleTex, nil, nil, filter);
	end

	self.vertices = texs;

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

function NarciRadarChartMixin:OnShow()
	self.MaskedBackground:SetAlpha(0.4);
	self.MaskedBackground2:SetAlpha(0.4);
end

function NarciRadarChartMixin:OnHide()
	self:StopAnimating();
end

function NarciRadarChartMixin:SetVerticeSize(attributeFrame, size)
	local name = attributeFrame.token;
	local vertice;
	if name == "Crit" then
		vertice = self.vertices[1];
	elseif name == "Haste" then
		vertice = self.vertices[2];
	elseif name == "Mastery" then
		vertice = self.vertices[3];
	elseif name == "Versatility" then
		vertice = self.vertices[4];
	end
	vertice:SetSize(size, size);
end

function NarciRadarChartMixin:UpdateColor()
	ColorUtil:SetWidgetColor(self.MaskedBackground)
	ColorUtil:SetWidgetColor(self.MaskedBackground2)
	ColorUtil:SetWidgetColor(self.MaskedLine1)
	ColorUtil:SetWidgetColor(self.MaskedLine2)
	ColorUtil:SetWidgetColor(self.MaskedLine3)
	ColorUtil:SetWidgetColor(self.MaskedLine4)
end

local GetEffectiveCrit = Narci.GetEffectiveCrit;
local GetCombatRating = GetCombatRating;

function NarciRadarChartMixin:SetValue(c, h, m, v, manuallyInPutSum)
	--c, h, m, v: Input manually or use combat ratings
	local deg = math.deg;
	local rad = math.rad;
	local atan2 = math.atan2;
	local sqrt = math.sqrt;
	local Radar = self;

	local chartWidth = 96 / 2;	--In half

	local crit, haste, mastery, versatility;
	if c then
		crit = c;
	else
		local _, rating = GetEffectiveCrit();
		crit = GetCombatRating(rating) or 0;
	end
	if h then
		haste = h;
	else
		haste = GetCombatRating(CR_HASTE_MELEE) or 0;
	end
	if m then
		mastery = m;
	else
		mastery = GetCombatRating(CR_MASTERY) or 0;
	end
	if v then
		versatility = v;
	else
		versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0;
	end

	--		|	p1(x1,y1)	  Line4		p3(x3,y3)
	--		|			*				*
	--		|			 	*		*
	--		|	Line1		 	*		   Line3
	--		|			 	*		*
	--		|			*				*
	--		|	p2(x2,y2)	  Line2		p4(x4,y4)

	local v1, v2, v3, v4, v5, v6 = true, true, true, true, true, true;
	if crit == 0 and haste == 0 and mastery == 0 and versatility == 0 then
		v1, v2, v3, v4, v5, v6 = false, false, false, false, false, false;
	else
		if crit == 0 and haste == 0 then v1 = false; end;
		if haste == 0 and versatility == 0 then v2 = false; end;
		if mastery == 0 and versatility == 0 then v3 = false; end;
		if crit == 0 and mastery == 0 then v4 = false; end;
		crit, haste, mastery = crit + 0.03, haste + 0.02, mastery + 0.01;				--Avoid some mathematical issues
	end
	Radar.MaskedLine1:SetShown(v1);
	Radar.MaskedLine2:SetShown(v2);
	Radar.MaskedLine3:SetShown(v3);
	Radar.MaskedLine4:SetShown(v4);
	Radar.MaskedBackground:SetShown(v5);
	Radar.MaskedBackground2:SetShown(v6);

	--[[
		--4500 9.0 Stats Sum Level 50
		Enchancements on ilvl 445 (Mythic Eternal Palace) Player Lvl 120
		Neck 159 Weapon 25 Back 51 Wrist 28 Hands 37 Waist 36 Legs 50 Feet 37 Ring 89 Trinket 35	Max:696 + 12*7 ~= 800
		Player Lvl 60 iLvl 233(Mythic Castle Nathria):	Back 82 Leg 141 Chest 141 Neck 214 Waist 105 Hand 105 Feet 105 Wrist 79 Ring 226 Shoulder 109  Head 146 Trinket 200 ~=1900
		Player Lvl 60 iLvl 259(Mythic Sanctum of Domination):	Back 90 Leg 165 Chest 165 Neck 268 Waist 124 Hand 130 Feet 124 Wrist 91 Ring 268 Shoulder 124  Head 146 Trinket 200 weapon 162 ~= 2500 (+ 8 sockets)


		ilvl 240 (Mythic Antorus) Player Lvl 110
		Head 87 Shoulder 64 Chest 88 Weapon 152 Back 49 Wrist 49 Hands 64 Waist 64 Legs 87 Feet 63 Ring 165 Trinket 62	Max ~= 1100
		ilvl 149 (Mythic HFC) Player Lvl 100
		Head 48 Shoulder 36 Chest 48 Weapon 24 Back 28 Wrist 27 Hands 36 Waist 36 Legs 48 Feet 35 Ring 27 Trinket 32	Max ~= 510
		Heirlooms Player Lvl 20
		Weapon 4 Back 4 Wrist 4 Hands 6 Waist 6 Legs 8 Feet 6 Ring 5 Trinket 6	 ~= 60
	--]]

	local Sum = manuallyInPutSum or 0;
	local maxNum = max(crit + haste + mastery + versatility, 1);
	if maxNum > 0.95 * Sum then
		Sum = maxNum;
	end

	local d1, d2, d3, d4 = (crit / Sum), (haste / Sum) , (mastery / Sum) , (versatility / Sum);
	local a;
	if (d1 + d4) ~= 0 and (d2 + d3) ~= 0 then
		--a = chartWidth * math.sqrt(0.618/(d1 + d4)/(d2 + d3)/2)* 96;
		a = 1.414 * chartWidth;
	else
		a = 0;
	end

	local x1, x2, x3, x4 = -d1*a, -d2*a, d3*a, d4*a;
	local y1, y2, y3, y4 = d1*a, -d2*a, d3*a, -d4*a;
	local mx1, mx2, mx3, mx4 = (x1 + x2)/2, (x2 + x4)/2, (x3 + x4)/2, (x1 + x3)/2;
	local my1, my2, my3, my4 = (y1 + y2)/2, (y2 + y4)/2, (y3 + y4)/2, (y1 + y3)/2;

	local ma1 = atan2((y1 - y2), (x1 - x2));
	local ma2 = atan2((y2 - y4), (x2 - x4));
	local ma3 = atan2((y4 - y3), (x4 - x3));
	local ma4 = atan2((y3 - y1), (x3 - x1));

	if my1 == 0 then
		my1 = 0.01;
	end
	if my3 == 0 then
		my1 = -0.01;
	end
	if deg(ma1) == 90 then
		ma1 = rad(89);
	end
	if deg(ma3) == -90 then
		ma1 = rad(-89);
	end

	Radar.vertices[1]:SetPoint("CENTER", x1, y1);
	Radar.vertices[2]:SetPoint("CENTER", x2, y2);
	Radar.vertices[3]:SetPoint("CENTER", x3, y3);
	Radar.vertices[4]:SetPoint("CENTER", x4, y4);

	Radar.Mask1:SetRotation(ma1);
	Radar.Mask2:SetRotation(ma2);
	Radar.Mask3:SetRotation(ma3);
	Radar.Mask4:SetRotation(ma4);
		
	local hypo1 = sqrt(2*x1^2 + 2*x2^2);
	local hypo2 = sqrt(2*x2^2 + 2*x4^2);
	local hypo3 = sqrt(2*x4^2 + 2*x3^2);
	local hypo4 = sqrt(2*x3^2 + 2*x1^2);

	if (hypo1 - 4) > 0 then
		Radar.MaskLine1:SetWidth(hypo1 - 4);	--Line length
	else
		Radar.MaskLine1:SetWidth(0.1);
	end

	if (hypo2 - 4) > 0 then
		Radar.MaskLine2:SetWidth(hypo2 - 4);
	else
		Radar.MaskLine2:SetWidth(0.1);
	end

	if (hypo3 - 4) > 0 then
		Radar.MaskLine3:SetWidth(hypo3 - 4);
	else
		Radar.MaskLine3:SetWidth(0.1);
	end

	if (hypo4 - 4) > 0 then
		Radar.MaskLine4:SetWidth(hypo4 - 4);
	else
		Radar.MaskLine4:SetWidth(0.1);
	end

	Radar.MaskLine1:ClearAllPoints();
	Radar.MaskLine1:SetRotation(0);
	Radar.MaskLine1:SetRotation(ma1);
	Radar.MaskLine1:SetPoint("CENTER", Radar, "CENTER", mx1, my1);
	Radar.MaskLine2:ClearAllPoints();
	Radar.MaskLine2:SetRotation(0);
	Radar.MaskLine2:SetRotation(ma2);
	Radar.MaskLine2:SetPoint("CENTER", Radar, "CENTER", mx2, my2);
	Radar.MaskLine3:ClearAllPoints();
	Radar.MaskLine3:SetRotation(0);
	Radar.MaskLine3:SetRotation(ma3);
	Radar.MaskLine3:SetPoint("CENTER", Radar, "CENTER", mx3, my3);
	Radar.MaskLine4:ClearAllPoints();
	Radar.MaskLine4:SetRotation(0);
	Radar.MaskLine4:SetRotation(ma4);
	Radar.MaskLine4:SetPoint("CENTER", Radar, "CENTER", mx4, my4);
	Radar.Mask1:SetPoint("CENTER", mx1, my1);
	Radar.Mask2:SetPoint("CENTER", mx2, my2);
	Radar.Mask3:SetPoint("CENTER", mx3, my3);
	Radar.Mask4:SetPoint("CENTER", mx4, my4);

	Radar.MaskedBackground:SetAlpha(0.4);
	Radar.MaskedBackground2:SetAlpha(0.4);

	Radar.n1, Radar.n2, Radar.n3, Radar.n4 = crit, haste, mastery, versatility;
end

function NarciRadarChartMixin:AnimateValue(c, h, m, v)
	--Update the radar chart using animation
	local Radar = self;
	local UpdateFrame = Radar.UpdateFrame;
	if not UpdateFrame then
		UpdateFrame = CreateFrame("Frame", nil, Radar, "NarciUpdateFrameTemplate");
		Radar.UpdateFrame = UpdateFrame;
		Radar.n1, Radar.n2, Radar.n3, Radar.n4 = 0, 0, 0, 0;
	end

	local s1, s2, s3, s4 = Radar.n1, Radar.n2, Radar.n3, Radar.n4;	--start/end point
	local critChance, critRating = GetEffectiveCrit();
	local e1 = c or GetCombatRating(critRating) or 0;
	local e2 = h or GetCombatRating(CR_HASTE_MELEE) or 0;
	local e3 = m or GetCombatRating(CR_MASTERY) or 0;
	local e4 = v or GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0;

	local duration = 0.2;

	local playerLevel = UnitLevel("player");
	local sum;
	if playerLevel == 50 then
		sum = max(e1 + e2 + e3 + e4 , 800);		--Status Sum for 8.3 Raid
	elseif playerLevel == 60 then
		sum = max(e1 + e2 + e3 + e4 , 2500);	--Status Sum for 9.1 Raid
	else
		--sum = 31 * math.exp( 0.04 * UnitLevel("player")) + 40;
		sum = (e1 + e2 + e3 + e4) * 1.5;
	end

	local function UpdateFunc(frame, elapsed)
		local t = frame.t;
		frame.t = t + elapsed;
		local v1 = outSine(t, s1, e1, duration);
		local v2 = outSine(t, s2, e2, duration);
		local v3 = outSine(t, s3, e3, duration);
		local v4 = outSine(t, s4, e4, duration);
		
		if t >= duration then
			v1, v2, v3, v4 = e1, e2, e3, e4;
			frame:Hide();
		end
		Radar:SetValue(v1, v2, v3, v4, sum);
	end

	UpdateFrame:Hide();
	UpdateFrame:SetScript("OnUpdate", UpdateFunc);
	UpdateFrame:Show();

	if self.Primary:IsShown() then
		self.Primary:Update();
		self.Health:Update();
	end
end

function NarciRadarChartMixin:TogglePrimaryStats(state)
	state = false;
	
	if state then
		self.Primary.Color:SetColorTexture(0.24, 0.24, 0.24, 0.75);
		self.Health.Color:SetColorTexture(0.15, 0.15, 0.15, 0.75);
		FadeFrame(self.Primary, 0.15, 1);
		FadeFrame(self.Health, 0.15, 1);
		self.Primary:Update();
		self.Health:Update();
	else
		FadeFrame(self.Primary, 0.25, 0);
		FadeFrame(self.Health, 0.25, 0);
	end
end

function Narci_AttributeFrame_UpdateBackgroundColor(self)
	local frameID = self:GetID() or 0;
	local themeColor = ColorUtil.themeColor;
	local r, g, b = themeColor[1], themeColor[2], themeColor[3];
	if frameID % 2 == 0 then
		if self.Color then
			self.Color:SetColorTexture(r, g, b, 0.75);
			return;
		elseif self.Color1 and self.Color2 then
			self.Color1:SetColorTexture(r, g, b, 0.75);
			self.Color2:SetColorTexture(r, g, b, 0.75);
		end
	else
		if self.Color then
			self.Color:SetColorTexture(0.1, 0.1, 0.1, 0.75);
			return;
		elseif self.Color1 and self.Color2 then
			self.Color1:SetColorTexture(0.1, 0.1, 0.1, 0.75);
			self.Color2:SetColorTexture(0.1, 0.1, 0.1, 0.75);
		end
	end
end

function Narci_AttributeFrame_OnLoad(self)
	Narci_AttributeFrame_UpdateBackgroundColor(self);
end

local function RefreshStats(id, frame)
	frame = frame or "Detailed";
	if frame == "Detailed" then
		if STAT_STABLE[id] then
			STAT_STABLE[id]:Update();
		end
	elseif frame == "Concise" then
		if SHORT_STAT_TABLE[id] then
			SHORT_STAT_TABLE[id]:Update();
		end
	end
end

local StatsUpdator = CreateFrame("Frame");
StatsUpdator:Hide();
StatsUpdator.t = 0;
StatsUpdator.index = 1;
StatsUpdator:SetScript("OnUpdate", function(self, elapsed)
	self.t = self.t + elapsed;
	if self.t > 0.05 then
		self.t = 0;
		local i = self.index;
		if STAT_STABLE[i] then
			STAT_STABLE[i]:Update();
		end
		if SHORT_STAT_TABLE[i] then
			SHORT_STAT_TABLE[i]:Update();
		end
		if i >= 20 then
			self:Hide();
			self.index = 1;
		else
			self.index = i + 1;
		end
	end
end);

function StatsUpdator:Gradual()
	ItemLevelFrame:AsyncUpdate(0.05);
	self.index = 1;
	self.t = 0;
	self:Show();
end

function StatsUpdator:Instant()
	if not StatsUpdator.pauseUpdate then
		StatsUpdator.pauseUpdate = true;
		After(0, function()
			for i = 1, 20 do
				RefreshStats(i);
			end
			for i = 1, 12 do
				RefreshStats(i, "Concise");
			end
			StatsUpdator.pauseUpdate = nil;
		end);
	end
end

function StatsUpdator:UpdateCooldown()
	for slotID, slotButton in pairs(SLOT_TABLE) do
		slotButton:TrackCooldown();
	end
end


local function PlayAttributeAnimation()
	if not NarcissusDB.DetailedIlvlInfo then
		RadarChart:AnimateValue();
		return
	end
	if not RadarChart:IsShown() then
		return		--Attributes is not the active tab
	end
	local anim;
	for i = 1, 20 do
		anim = STAT_STABLE[i].animIn;
		if anim then
			anim.A2:SetToAlpha(STAT_STABLE[i]:GetAlpha());
			anim:Play();
		end
	end
	RadarChart.animIn:Play();
end

local function ShowAttributeButton(bool)
	if NarcissusDB.DetailedIlvlInfo then
		Narci_DetailedStatFrame:SetShown(true);
		Narci_ConciseStatFrame:SetShown(false);
		RadarChart:SetShown(true);
	else
		Narci_DetailedStatFrame:SetShown(false);
		Narci_ConciseStatFrame:SetShown(true);
		RadarChart:SetShown(false);
	end

	ItemLevelFrame:SetShown(true);
end

local function AssignFrame()
	local statFrame = Narci_DetailedStatFrame;
	local radar = RadarChart;
	STAT_STABLE[1] = statFrame.Primary;
	STAT_STABLE[2] = statFrame.Stamina;
	STAT_STABLE[3] = statFrame.Damage;
	STAT_STABLE[4] = statFrame.AttackSpeed;
	STAT_STABLE[5] = statFrame.Power;
	STAT_STABLE[6] = statFrame.Regen;
	STAT_STABLE[7] = statFrame.Health;
	STAT_STABLE[8] = statFrame.Armor;
	STAT_STABLE[9] = statFrame.Reduction;
	STAT_STABLE[10]= statFrame.Dodge;
	STAT_STABLE[11]= statFrame.Parry;
	STAT_STABLE[12]= statFrame.Block;
	STAT_STABLE[13]= radar.Crit;
	STAT_STABLE[14]= radar.Haste;
	STAT_STABLE[15]= radar.Mastery;
	STAT_STABLE[16]= radar.Versatility;
	STAT_STABLE[17]= statFrame.Leech;
	STAT_STABLE[18]= statFrame.Avoidance;
	STAT_STABLE[19]= statFrame.MovementSpeed;
	STAT_STABLE[20]= statFrame.Speed;

	local statFrame_Short = Narci_ConciseStatFrame;
	SHORT_STAT_TABLE[1]  = statFrame_Short.Primary;
	SHORT_STAT_TABLE[2]  = statFrame_Short.Stamina;
	SHORT_STAT_TABLE[3]  = statFrame_Short.Health;
	SHORT_STAT_TABLE[4]  = statFrame_Short.Power;
	SHORT_STAT_TABLE[5]  = statFrame_Short.Regen;
	SHORT_STAT_TABLE[6]  = statFrame_Short.Crit;
	SHORT_STAT_TABLE[7]  = statFrame_Short.Haste;
	SHORT_STAT_TABLE[8]  = statFrame_Short.Mastery;
	SHORT_STAT_TABLE[9]  = statFrame_Short.Versatility;
	SHORT_STAT_TABLE[10] = statFrame_Short.Leech;
	SHORT_STAT_TABLE[11] = statFrame_Short.Avoidance;
	SHORT_STAT_TABLE[12] = statFrame_Short.Speed;
end

function Narci_SetPlayerName(self)
	local playerName = UnitName("player");
	local editBox = self.PlayerName or self.MogNameEditBox;
	editBox:SetShadowColor(0, 0, 0);
	editBox:SetShadowOffset(2, -2);
	editBox:SetText(playerName);
	SmartFontType(editBox);
end


function Narci_Open()
	if not IS_OPENED then
		if InCombatLockdown() then
			--[[
			--Can't open the default character pane either
			ShowUIPanel(CharacterFrame);
			local subFrame = _G["PaperDollFrame"];
			if not subFrame:IsShown() then
				ToggleCharacter("PaperDollFrame");
			end
			--]]
			return;
		end
		IS_OPENED = true;
		CVarTemp:BackUp();
		Toolbar:ShowUI("Narcissus");
		ViewProfile:SaveView(5);
		CameraUtil:UpdateParameters();
		CameraMover:MakeActive();
		MOG_MODE_OFFSET = 0;

		local speedFactor = 180/(GetCVar("cameraYawMoveSpeed") or 180);
		ZoomFactor.toSpeed = speedFactor * ZoomFactor.toSpeedBasic;
		ZoomFactor.fromSpeed = speedFactor * ZoomFactor.fromSpeedBasic;

		EL:Show();

		After(0, function()
			CameraMover:Enter();
			RadarChart:SetValue(0,0,0,0,1);
			PlayLetteboxAnimation();
			local Vignette = Narci_Vignette;
			Vignette.VignetteLeft:SetAlpha(VIGNETTE_ALPHA);
			Vignette.VignetteRight:SetAlpha(VIGNETTE_ALPHA);
			Vignette.VignetteRightSmall:SetAlpha(0);
			FadeFrame(Vignette, 0.5, 1);
			Vignette.VignetteRight.animIn:Play();
			Vignette.VignetteLeft.animIn:Play();
			SlotButtonOverlayUtil:UpdateData();
			After(0, function()
				SlotController:LazyRefresh();
				StatsUpdator:Gradual();
			end);
		end);

		Narci.refreshCombatRatings = true;
		Narci.isActive = true;
	else
		if Narci.showExitConfirm and not InCombatLockdown() then
			local ExitConfirm = Narci_ExitConfirmationDialog;
			if not ExitConfirm:IsShown() then
				FadeFrame(ExitConfirm, 0.25, 1);

				--"Nullify" ShowUI
				UIParent:SetAlpha(0);
				Minimap:Hide();
				After(0, function()
					SetUIVisibility(false);
					MiniButton:Enable();
					UIParent:SetAlpha(1);
					Minimap:Show()
				end);

				return;
			else
				FadeFrame(ExitConfirm, 0.15, 0);
			end
		end
		SlotController:PlayAnimOut();
		ExitFunc();
		PlayLetteboxAnimation("OUT");
		EquipmentFlyoutFrame:Hide();
		Narci_ModelSettings:Hide();

		Toolbar:HideUI();
		TakeOutFrames(false);

		Narci.showExitConfirm = false;
	end

	NarciAPI.UpdateSessionTime();
end

function Narci_OpenGroupPhoto()
	if not IS_OPENED then
		if InCombatLockdown() then
			return;
		end
		IS_OPENED = true;
		CVarTemp:BackUp();
		Toolbar:ShowUI("PhotoMode");
		ViewProfile:SaveView(5);
		CameraUtil:UpdateParameters();
		CameraMover:MakeActive();
		SetCVar("test_cameraDynamicPitch", 1);

		local speedFactor = 180/(GetCVar("cameraYawMoveSpeed") or 180);
		ZoomFactor.toSpeed = speedFactor*ZoomFactor.toSpeedBasic;
		ZoomFactor.fromSpeed = speedFactor*ZoomFactor.fromSpeedBasic;
		EL:Show();

		CameraMover:Pitch();

		After(0, function()
			Toolbar:Expand(true);
			local toolbarButton = GetToolbarButtonByButtonType("Mog");
			toolbarButton:OnClick();

			SlotController:LazyRefresh();
			local Vignette = Narci_Vignette;
			Vignette.VignetteLeft:SetAlpha(VIGNETTE_ALPHA);
			Vignette.VignetteRight:SetAlpha(VIGNETTE_ALPHA);
			Vignette.VignetteRightSmall:SetAlpha(0);
			FadeFrame(Vignette, 0.8, 1);
			Vignette.VignetteRight.animIn:Play();
			Vignette.VignetteLeft.animIn:Play();

			if UIParent:IsShown() then
				UIPA.endAlpha = 0;
				UIPA:Show();
			end

			After(0, function()
				After(0.5, function()
					SetUIVisibility(false); 		--Same as pressing Alt + Z

					After(0.3, function()
						UIParent:SetAlpha(1);
					end)
				end)
			end)
		end)

		Narci.isActive = true;
		MsgAlertContainer:Display();
	end

	NarciAPI.UpdateSessionTime();
end


------------------------------------------------------
------------------Photo Mode Controller---------------
------------------------------------------------------
function Narci_KeyListener_OnEscapePressed(self)
	if IS_OPENED then
		MiniButton:Click();
		if self then
			self:SetPropagateKeyboardInput(false);
			After(0, function()
				self:SetPropagateKeyboardInput(true);
			end);
		end
	end
end

local function UseXmogLayout()
	MOG_MODE_OFFSET = 0.2;
	NarciPlayerModelFrame1.xmogMode = 2;
	if Narci_Character:IsVisible() then
		FadeFrame(NarciModel_RightGradient, 0.5, 1);
	end

	Narci_ModelContainer:Show();
	Narci_PlayerModelAnimIn:Show();

	Narci_PlayerModelGuideFrame.VignetteRightSmall:Show();
	Narci_GuideLineFrame.VirtualLineRight.AnimFrame.toX = -600;
	Narci_GuideLineFrame.VirtualLineRight.AnimFrame:Show();

	After(0, function()
		if not IsMounted() then
			CameraMover:Pitch();
			CameraMover:ZoomIn(ZOOM_IN_VALUE_MOG);	--ajust by raceID
		else
			CameraMover:ZoomIn(8);	--ajust by raceID
		end
	end)
end


local function ActivateMogMode()
	Narci_GuideLineFrame.VirtualLineRight.AnimFrame:Hide();

	if MOG_MODE then
		FadeFrame(Narci_Attribute, 0.5, 0)
		FadeFrame(Narci_XmogNameFrame, 0.2, 1, 0)
		MOG_MODE_OFFSET = 0.2;
		NarciPlayerModelFrame1.xmogMode = 2;
		MsgAlertContainer:Display();
		UseXmogLayout();
	else
		Narci_GuideLineFrame.VirtualLineRight.AnimFrame.toX = Narci_GuideLineFrame.VirtualLineRight.AnimFrame.defaultX
		if Toolbar:IsShown() then
			Narci_GuideLineFrame.VirtualLineRight.AnimFrame:Show()
			FadeFrame(Narci_Attribute, 0.5, 1)
			local zoom = GetCameraZoom()
			SmoothShoulderCVar(SHOULDER_FACTOR_1*zoom + SHOULDER_FACTOR_2)
		end
		FadeFrame(Narci_XmogNameFrame, 0.2, 0)
		ShowAttributeButton();
		MOG_MODE_OFFSET = 0;
		MsgAlertContainer:Hide();
		RadarChart:SetValue();
	end
end




local function UpdateXmogName(SpecOnly)
	local frame = Narci_XmogNameFrame;

	local currentSpec = GetSpecialization();
	if not currentSpec then
	   return;
	end
	local IsSpellKnown = IsSpellKnown;
	local token = 159243;
	local ArmorType;

	if not SpecOnly then
		Narci_SetPlayerName(frame);
		if IsSpellKnown(76273) or IsSpellKnown(106904) or IsSpellKnown(202782) or IsSpellKnown(76275) then
			--ArmorType = "Leather"
			token = 159300;
		elseif IsSpellKnown(76250) or IsSpellKnown(76272) or IsSpellKnown(366522) then
			--ArmorType = "Mail"
			token = 159371;
		elseif IsSpellKnown(76276) or IsSpellKnown(76277) or IsSpellKnown(76279) then
			--ArmorType = "Cloth"
			token = 159243;
		elseif IsSpellKnown(76271) or IsSpellKnown(76282) or IsSpellKnown(76268) then
			--ArmorType = "Plate"
			token = 159418;
		end
		local _;
		_, _, ArmorType = GetItemInfoInstant(token);
		frame.armorType = ArmorType;
	end
	--Leather 76273		Mail 76250		Cloth 76276	76279	Plate 76271 76282

	ArmorType = frame.armorType or ArmorType or "ArmorType";

	local _, currentSpecName = GetSpecializationInfo(currentSpec);
	currentSpecName = currentSpecName or "";

	local className, englishClass, _ = UnitClass("player");
	local _, _, _, rgbHex = GetClassColor(englishClass);
	frame.ArmorString:SetText("|cFFFFD100"..ArmorType.."|r".."  |  ".."|c"..rgbHex..currentSpecName.." "..className.."|r");
end

local function GetWowHeadDressingRoomURL()
	local slot;
	local ItemList = {};
	for i = 1, #xmogTable do
		slot = xmogTable[i][1];
		if SLOT_TABLE[slot] and SLOT_TABLE[slot].itemID then
			ItemList[slot] = {SLOT_TABLE[slot].itemID, SLOT_TABLE[slot].bonusID};
		end
	end
	return NarciAPI.EncodeItemlist(ItemList);
end

local function CopyTexts(textFormat, includeID)
	local texts = Narci_XmogNameFrame.MogNameEditBox:GetText() or "My Transmog";
	textFormat = textFormat or "text";

	local source;
	if textFormat == "text" then
		texts = texts.."\n"
		for i = 1, #xmogTable do
			local index =  xmogTable[i][1]
			if SLOT_TABLE[index] and SLOT_TABLE[index].Name:GetText() then
				local text = "|cFFFFD100"..xmogTable[i][2]..":|r "..(SLOT_TABLE[index].Name:GetText() or " ");

				if includeID and SLOT_TABLE[index].itemID then
					text = text.." |cFFacacac"..SLOT_TABLE[index].itemID.."|r";
				end
				
				source = SLOT_TABLE[index].ItemLevel:GetText();
				if source and source ~= " " then
					text = text.." ("..source..")"
				end
				if text then
					texts = texts.."\n"..text;
				end
			end
		end

	elseif textFormat == "reddit" then	
		texts = "|cFF959595**|r"..texts.."|cFF959595**\n\n| Slot | Name | Source |".."\n".."|:--|:--|:--|"
		for i=1, #xmogTable do
			local index =  xmogTable[i][1]
			if SLOT_TABLE[index] and SLOT_TABLE[index].Name:GetText() then
				local text = "|cFF959595| |r|cFFFFD100"..xmogTable[i][2].."|r |cFF959595| |r"
				if	includeID and SLOT_TABLE[index].itemID then
					text = text.."|cFF959595[|r"..(SLOT_TABLE[index].Name:GetText() or " ").."|cFF959595](https://www.wowhead.com/item=|r"..SLOT_TABLE[index].itemID..")|r"
				else
					text = text..(SLOT_TABLE[index].Name:GetText() or " ")
				end
				source = SLOT_TABLE[index].ItemLevel:GetText()
				if source then
				text = text.." |cFF959595| |r|cFF40C7EB"..source.."|r |cFF959595| |r"
				else
					text = text.." |cFF959595| |r"
				end
				if text then
					texts = texts.."\n"..text;
				end
			end
		end
		texts = texts.."\n";
	else
		if textFormat == "wowhead" then
			texts = "|cFF959595[table border=2 cellpadding=4]\n[tr][td colspan=3 align=center][b]|r"..texts.."|r|cFF959595[/b][/td][/tr]\n[tr][td align=center]Slot[/td][td align=center]Name[/td][td align=center]Source[/td][/tr]|r"
		elseif textFormat == "nga" then
			texts = "|cFF959595[table]\n[tr][td colspan=3][align=center][b]|r"..texts.."|r|cFF959595[/b][/align][/td][/tr]\n[tr][td][align=center]部位[/align][/td][td][align=center]装备名称[/align][/td][td][align=center]来源[/align][/td][/tr]|r"
		elseif textFormat == "mmo-champion" then
			texts =	"|cFF959595[table=\"width: 640, class: grid\"]\n[tr][td=\"colspan: 3\"][center][b]|r"..texts.."|r|cFF959595[/b][/center][/td][/tr]\n[tr][td][center]Slot[/center][/td][td][center]Name[/center][/td][td][center]Source[/center][/td][/tr]|r"
		end

		for i=1, #xmogTable do
			local index =  xmogTable[i][1]
			if SLOT_TABLE[index] and SLOT_TABLE[index].Name:GetText() then
				local text = "|cFF959595[tr][td]|r".."|cFFFFD100"..xmogTable[i][2].."|r|cFF959595[/td][td]|r"
				if includeID and SLOT_TABLE[index].itemID then
					if textFormat == "wowhead" then
						text = text.."[item="..SLOT_TABLE[index].itemID.."|r|cFF959595][/td]|r"
					elseif textFormat == "nga" then
						text = text.."|cFF959595[url=https://www.wowhead.com/item="..SLOT_TABLE[index].itemID.."]|r"..(SLOT_TABLE[index].Name:GetText() or " ").."|cFF959595[/url][/td]|r"
					elseif textFormat == "mmo-champion" then
						text = text.."|cFF959595[url=https://www.wowdb.com/items/"..SLOT_TABLE[index].itemID.."]|r"..(SLOT_TABLE[index].Name:GetText() or " ").."|cFF959595[/url][/td]|r"
					end
				else
					text = text..(SLOT_TABLE[index].Name:GetText() or " ").."|r|cFF959595[/td]|r"
				end
				source = SLOT_TABLE[index].ItemLevel:GetText()
				if source then
					text = text.."|cFF959595[td]|r|cFF40C7EB"..source.."|r|cFF959595[/td]|r"
				else
					text = text.."|cFF959595[td] [/td]|r"
				end
				if text then
					texts = texts.."\n"..text.."|cFF959595[/tr]|r"
				end
			end
		end
		texts = texts.."\n|cFF959595[/table]|r"


		-----
		if textFormat == "wowhead" then
			texts = GetWowHeadDressingRoomURL();
		end

	end
	return texts;
end



local function Narci_XmogButton_OnClick(self)
	MoveViewRightStop();
	EquipmentFlyoutFrame:Hide();
	MOG_MODE = not MOG_MODE;
	self.isOn = MOG_MODE;

	if self.isOn then
		FadeFrame(Narci_VignetteRightSmall, 0.5, NarcissusDB.VignetteStrength);
		FadeFrame(Narci_VignetteRightLarge, 0.5, 0);
		Narci_SnowEffect(false);
		PlayLetteboxAnimation("OUT");

		Narci_XmogNameFrame.MogNameEditBox:SetText(Narci_PlayerInfoFrame.PlayerName:GetText())

		Toolbar.TransmogListFrame:ShowUI();
		Toolbar.showTransmogFrame = true;
	else
		--Exit Xmog mode
		Toolbar.TransmogListFrame:Hide();
		Toolbar.showTransmogFrame = nil;
		FadeFrame(Narci_VignetteRightSmall, 0.5, 0);
		FadeFrame(Narci_VignetteRightLarge, 0.5, NarcissusDB.VignetteStrength);
		Narci_SnowEffect(true);
		PlayLetteboxAnimation();
		if Narci_ModelContainer:IsVisible() then
			if IS_OPENED then
				CameraMover:Pitch();
			else
				--SmoothShoulderCVar(0);
			end
			Narci_PlayerModelAnimOut:Show()
			After(0.4, function()
				FadeFrame(NarciPlayerModelFrame1, 0.5 , 0);
			end)
		end
		Narci_ModelSettings:Hide();

		if not Narci_ExitConfirmationDialog:IsShown() then
			Narci.showExitConfirm = false;
		end

		if (not InCombatLockdown()) and (not Narci_Character:IsShown()) then
			Narci_Character:Show();
			Narci_Character:SetAlpha(1);
			StatsUpdator:Gradual();
		end
	end

	SlotController:LazyRefresh();
	After(0.1, function()
		ActivateMogMode();
	end)

	self:UpdateIcon();
end

addon.OverrideToolbarButtonOnClickFunc("Mog", Narci_XmogButton_OnClick);
addon.OverrideToolbarButtonOnInitFunc("Mog", function(self)
	if MOG_MODE then
		self.isOn = true;
		self:UpdateIcon();
	end
end);

Toolbar.TransmogListFrame.getItemListFunc = CopyTexts;



function Narci_SetButtonColor(self)
	ColorUtil:SetWidgetColor(self.Color);
	ColorUtil:SetWidgetColor(self.HighlightColor);
end


function CameraMover:ShowFrame()
	local GuideLineFrame = Narci_GuideLineFrame;
	local VirtualLineRight = GuideLineFrame.VirtualLineRight;
	VirtualLineRight.AnimFrame:Hide();
	local offsetX = GuideLineFrame.VirtualLineRight.AnimFrame.defaultX or -496;
	VirtualLineRight:SetPoint("RIGHT", offsetX + 120, 0);
	if MOG_MODE then
		FadeFrame(Narci_Attribute, 0.4, 0)
	else
		VirtualLineRight.AnimFrame.toX = offsetX;
		FadeFrame(Narci_Attribute, 0.4, 1, 0);
	end
	VirtualLineRight.AnimFrame:Show();
	GuideLineFrame.VirtualLineLeft.AnimFrame:Show();
	PlayAttributeAnimation();
	After(0, function()
		FadeFrame(Narci_Character, 0.6, 1);
	end)

	Narci_SnowEffect(true);
end


------Photo Mode Toolbar------
do
	local IsInteractingWithDialogNPC = addon.IsInteractingWithDialogNPC;	--Prevent clash with DialogUI

	hooksecurefunc("SetUIVisibility", function(state)
		if IS_OPENED then		--when Narcissus hide the UI
			if state then
				MsgAlertContainer:SetDND(true);
				Toolbar:UseLowerLevel(true);
			else
				local bar = Toolbar;
				Toolbar.ExitButton:Show();
				if not bar:IsShown() then
					bar:Show();
				end
				MsgAlertContainer:SetDND(false);
				bar:UseLowerLevel(false);
			end
		else						--when user hide the UI manually
			if state then
				--When player closes the full-screen world map, SetUIVisibility(true) fires twice, and WorldMapFrame:IsShown() returns true and false.
				--Thus, use this VisibilityTracker instead to check if WorldMapFrame has been closed recently.
				--WorldMapFrame.VisibilityTracker.state
				MsgAlertContainer:Hide();
				if Narci_Character:IsShown() then return end;
				if not Toolbar:IsShown() then return end;

				if not GetKeepActionCam() then
					After(0.6, function()
						ConsoleExec( "actioncam off" );
					end)
				end
				Toolbar:HideUI();
			else
				if IsInteractingWithDialogNPC() then return end;

				local bar = Toolbar;
				if not bar:IsShown() then
					CVarTemp.shoulderOffset = GetCVar("test_cameraOverShoulder");
				end
				bar:ShowUI("Blizzard");
				bar:FadeOut(true);
			end
		end
	end)
end

--[[
do  --UIParent OnShow/OnHide
	local IsInteractingWithDialogNPC = addon.IsInteractingWithDialogNPC;	--Prevent clash with DialogUI

	local frame = CreateFrame("Frame", nil, UIParent);

	local function UIParent_OnShow()
		if IS_OPENED then		--when Narcissus hide the UI
			MsgAlertContainer:SetDND(true);
			Toolbar:UseLowerLevel(true);
		else
			MsgAlertContainer:Hide();
			if Narci_Character:IsShown() then return end;
			if not Toolbar:IsShown() then return end;

			if not GetKeepActionCam() then
				After(0.6, function()
					ConsoleExec( "actioncam off" );
				end)
			end
			Toolbar:HideUI();
		end
	end

	local function UIParent_OnHide()
		if IS_OPENED then		--when Narcissus hide the UI
			local bar = Toolbar;
			Toolbar.ExitButton:Show();
			if not bar:IsShown() then
				bar:Show();
			end
			MsgAlertContainer:SetDND(false);
			bar:UseLowerLevel(false);
		else
			if IsInteractingWithDialogNPC() then return end;

			local bar = Toolbar;
			if not bar:IsShown() then
				CVarTemp.shoulderOffset = GetCVar("test_cameraOverShoulder");
			end
			bar:ShowUI("Blizzard");
			bar:FadeOut(true);
		end
	end

    frame:SetScript("OnShow", UIParent_OnShow);
    frame:SetScript("OnHide", UIParent_OnHide);
end
--]]

do
	--Slash Command
	local commandName = "narci";
	local commandAlias = "narcissus";

	local function callback(msg)
		if not msg then
			msg = "";
		end

		msg = string.lower(msg);
		if msg == "" then
			MiniButton:Click();
		elseif msg == "minimap" then
			MiniButton:EnableButton();
			print("Minimap button has been re-enabled.");
		elseif msg == "itemlist" then
			DressUpFrame_Show(DressUpFrame);
			if NarciDressingRoomOverlay then
				NarciDressingRoomOverlay:ShowItemList();
			end
		elseif msg == "resetposition" then
			MiniButton:ResetPosition();
		elseif string.find(msg, "/outfit") then
			Narci:LoadOutfitSlashCommand(msg);
			--/narci /outfit v1 50109,182541,0,77345,182521,2633,0,181613,182527,79067,182538,84323,80378,-1,0,77903,0
		else
			local color = "|cff40C7EB";
			print(" ");
			print(color.."Show Minimap Button:|r /narci minimap");
			print(color.."Reset Minimap Button Position:|r /narci resetposition");
			print(color.."Copy Item List:|r /narci itemlist");
		end
	end

	--RegisterNewSlashCommand(callback, commandName, commandAlias);

	---- Alternative method to avoid slash command taint

	if ChatEdit_HandleChatType then
		local VALID_COMMANDS = {
			["/NARCI"] = true,
			["/NARCISSUS"] = true,
		};

		local c, m;

		hooksecurefunc("ChatEdit_HandleChatType", function(editBox, msg, command, send)
			c = command;	--Auto capitalized by the game
			m = msg;
			if send == 1 then
				if c then
					if c == "/NARCISSUSGAMEPAD" then
						Narci_Open();
					elseif VALID_COMMANDS[c] then
						callback(m);
					end
				end

				c = nil;
				m = nil;
			end
		end);
	end

	--local f = CreateFrame("Frame");
	--f:RegisterEvent("EXECUTE_CHAT_LINE");
	--f:SetScript("OnEvent", function(self, event, line)
	--	print(line)
	--end)
end

----------------
--3D Animation--
local function InitializeAnimationContainer(frame, SequenceInfo, TargetFrame)
	frame.OppoDirection = false;
	frame.t = 0
	frame.totalTime = 0;
	frame.Index = 1;
	frame.Pending = false;
	frame.IsPlaying = false;
	frame.SequenceInfo = SequenceInfo;
	frame.Target = TargetFrame
end

local function AnimationContainer_OnHide(self)
	self.totalTime = 0;
	self.TimeSinceLastUpdate = 0;
	self.OppoDirection = not self.OppoDirection
	if self.Index <= 0 then
		self.Index = 0;
	end
end

local PlayAnimationSequence = NarciAPI_PlayAnimationSequence;



local ASC2 = CreateFrame("Frame", "AnimationSequenceContainer_Heart");
ASC2.Delay = 5;
ASC2.IsPlaying = false;
ASC2:Hide();

local function Generic_AnimationSequence_OnUpdate(self, elapsed)
	if self.Pending then
		return;
	end

	self.totalTime = self.totalTime + elapsed;
	if (not self.OppoDirection and self.totalTime < self.Delay) and (not self.IsPlaying) then
		return;
	elseif not self.IsPlaying then
		if not self.OppoDirection then		--box closing
			FadeFrame(Narci_HeartofAzeroth_AnimFrame, 0.25, 1)
			After(0.3, function()
				Narci_HeartofAzeroth_AnimFrame.Background:SetAlpha(1);
				Narci_HeartofAzeroth_AnimFrame.Quote:SetAlpha(1);
				Narci_HeartofAzeroth_AnimFrame.SN:SetAlpha(1);
			end)
		end
		self.IsPlaying = true;
	end
	
	self.t = self.t + elapsed;

	if self.t >= 0.01666 then
		self.t = 0;
		if self.OppoDirection then
			self.Index = self.Index - 1;
		else
			self.Index = self.Index + 1;
		end

		if not PlayAnimationSequence(self.Index, self.SequenceInfo, self.Target) then
			self:Hide()
			self.IsPlaying = false;
			if not self.OppoDirection then
				Narci_HeartofAzeroth_AnimFrame.Background:SetAlpha(0);
				Narci_HeartofAzeroth_AnimFrame.Quote:SetAlpha(0);
				Narci_HeartofAzeroth_AnimFrame.SN:SetAlpha(0);
				FadeFrame(Narci_HeartofAzeroth_AnimFrame, 0.25, 0)
			end
			return;
		end
	end
end

ASC2:SetScript("OnUpdate", Generic_AnimationSequence_OnUpdate);
ASC2:SetScript("OnHide", AnimationContainer_OnHide);



local RACE_PORTRAIT_CAMERA = {	--For 3D Portait on the top-left
  --[RaceID] = {[GenderID] = {offsetX, offsetY, distance, angle, CameraIndex, {animation} }}
	[1]  = {[2] = {10, -10, 0.75, false, 0},	--Human Male √
		    [3] = {12, -10, 0.71, false, 1, 2},	-- 	    Female	 √
		},

	[2]  = {[2] = {12, -16, 1.3, 1.1, 0},	--Orcs Male  √
		    [3] = {18, -16, 0.72, 1.1, 0, 1},	-- 	    Female	 √
		},

	[3]  = {[2] = {14, -20, 0.88, 0.9, 1},	--Dwarf Male
		    [3] = {2, -12, 0.75, false, 0},	-- 	    Female	 √
		},	

	[4]  = {[2] = {16, -5, 1, 1.5, 0},		--NE	Male
		    [3] = {8, -10, 0.75, false, 0},	-- 	    Female
		},	

	[5]  = {[2] = {16, -6, 0.6, 0.8, 1},	--UD 	Male
		    [3] = {10, -6, 0.68, 1.0, 1, 3},	-- 	    Female
		},

	[6]  = {[2] = {24, -15, 3, 0.6, 1},		--Tauren Male	√
		    [3] = {24, -8, 1.8, false, 1},	-- 	     Female
		},	

	[7]  = {[2] = {10, -14, 1, 0.5, 1},			--Gnome Male
		    [3] = {14, -14, 0.8, 0.55, 0},	-- 	    Female
		},

	[8]  = {[2] = {16, -4, 1.15, 1.3, 0},	--Troll Male √
		    [3] = {18, -10, 0.75, 1.3, 0},	-- 	    Female	 √
		},

	[9] = {[2] = {8, 0, 0.8, 0.6, 0},		--Goblin Male 	 √
			[3] = {20, -14, 0.85, 0.8, 0},	-- 	    Female 	 √
		},	

	[10] = {[2] = {8, -5, 0.75, 1.2, 0},		--	BE Male
			[3] = {0, -4, 0.53, 1.1, 0},	-- 	    Female
		},

	[11] = {[2] = {15, -12, 1, 1.4, 0},		--	Goat Male
			[3] = {10, -10, 0.66, 1.4, 0},	-- 	    Female
		},	

	[22]  = {[2] = {10, -10, 0.75, false, 0},	--Worgen Male Human Form
		    [3] = {12, -12, 0.72, 1.1, 1},		--Female	 √
		},

	[24]  = {[2] = {14, 0, 1.1, 1.15, 0},		--Pandaren Male		√
		    [3] = {12, 4, 1.0, 1.1, 0},			--Female	 
		},

	[27]  = {[2] = {24, -10, 0.72, false, 0},	--Highborne Male		√
		    [3] = {16, -4, 0.70, false, 0},			--Female	 
		},

	[28]  = {[2] = {24, -15, 2.4, 0.6, 0},		--Tauren Male	√
		    [3] = {4, -10, 0.62, false, 0},	-- 	     Female
		},	

	[128]  = {[2] = {18, -18, 1.4, 0.85, 0},	--Worgen Male Wolf Form
		    [3] = {18, -15, 1.1, 1.25, 0},		--Female	 √
		},

	[31]  = {[2] = {4, 0, 1.2, 1.6, 0},		--Zandalari Male √
		    [3] = {18, -12, 0.95, 1.6, 0},		-- 	    Female	 √
		},

	[32]  = {[2] = {10, -16, 1.25, 1.15, 1},	--Kul'tiran Male	√
		    [3] = {12, -10, 0.9, 1.5, 0},			--Female	 
		},

	[36]  = {[2] = {14, -10, 1.2, 1.2, 0, 2},		--Mag'har Male
		    [3] = {20, -20, 0.75, false, 0, 1},		-- 	    Female	 √
		},

	[35]  = {[2] = {18, -8, 0.7, false, 1, 2},		--Vulpera Male
		    [3] = {18, -8, 0.7, false, 1, 2},	-- 	    Female 	 √
		},

    [52] = {[2] = {18, -18, 1.4, false, 1},		--Dracthyr
        	[3] = {18, -18, 1.4, false, 1},
	},

	[520] = {[2] = {8, -5, 0.75, 1.2, 0},		--Dracthyr Visage Male
			[3] = {12, -10, 0.71, false, 1, 2},	-- 	    Female	 √
	},
}

function Narci_PortraitPieces_OnLoad(self)
	if true then

		return
	end

	local unit = "player";
	local a1, a2, a3;
	local ModelPieces = self.Pieces;
	local _, _, raceID = UnitRace(unit);
	local GenderID = UnitSex(unit);

	--print("raceID: "..raceID)

	if raceID == 34 then	 --DarkIron
		raceID = 3;
	elseif raceID == 29 then --VE
		raceID = 10
	elseif raceID == 28 then --Highmountain
		raceID = 6
	elseif raceID == 30 then --LightForged
		raceID = 11
	elseif raceID == 25 or raceID == 26 then --Pandaren A|H
		raceID = 24
	elseif raceID == 37 then				--Mechagnome
		raceID = 7;
	elseif raceID == 22 then --Worgen
		local inHumanForm = IsPlayerInAlteredForm();
		if not inHumanForm	then
			raceID = 128;
		end
	elseif raceID == 52 or raceID == 70 then
		local inVisageForm = IsPlayerInAlteredForm();
		if not inVisageForm	then
			raceID = 52;
		else
			raceID = 520;
		end
	end

	local model;
	if RACE_PORTRAIT_CAMERA[raceID] and RACE_PORTRAIT_CAMERA[raceID][GenderID] then
		if Narci_FigureModelReference then
			Narci_FigureModelReference:SetPoint("CENTER", RACE_PORTRAIT_CAMERA[raceID][GenderID][1], RACE_PORTRAIT_CAMERA[raceID][GenderID][2])
		end

		for i = 1, #ModelPieces do
			model = ModelPieces[i];
			TransitionAPI.SetModelByUnit(model, "player");
			model:SetCamera(1);
			model:MakeCurrentCameraCustom();
			if RACE_PORTRAIT_CAMERA[raceID][GenderID][3] then
				model:SetCameraDistance(RACE_PORTRAIT_CAMERA[raceID][GenderID][3])
			end
			if RACE_PORTRAIT_CAMERA[raceID][GenderID][4] then
				a1, a2, a3 = model:GetCameraPosition();
				model:SetCameraPosition(a1, a2, RACE_PORTRAIT_CAMERA[raceID][GenderID][4])
			end
			if RACE_PORTRAIT_CAMERA[raceID][GenderID][6] then
				model:SetAnimation(2, RACE_PORTRAIT_CAMERA[raceID][GenderID][6])
			end
		end
	else
		for i = 1, #ModelPieces do
			model = ModelPieces[i];
			model:SetCamera(1);
			model:MakeCurrentCameraCustom();
			a1, a2, a3 = model:GetCameraPosition();
			model:SetCameraPosition(a1, a2, 1.1);
		end
	end

	for i = 1, #ModelPieces do
		model = ModelPieces[i];
		model:SetFacing(-math.pi/24)	--Front pi/6
		model:SetAnimation(804, 1);
		TransitionAPI.SetModelLight(model, true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 0.7, 0.5, 0.8, 1, 0.8, 0.8, 0.8)
		model:UndressSlot(1);
		model:UndressSlot(3);
		model:UndressSlot(15);		--Remove the cloak
		model:UndressSlot(16);
		model:UndressSlot(17);
	end
end

--Static Events
EL:RegisterEvent("PLAYER_ENTERING_WORLD");
EL:RegisterUnitEvent("UNIT_NAME_UPDATE", "player");
EL:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE");
EL:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
EL:RegisterEvent("PLAYER_LEVEL_CHANGED");

--These events might become deprecated in future expansions
EL:RegisterEvent("COVENANT_CHOSEN");

EL:SetScript("OnEvent",function(self, event, ...)
	--print(event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent(event);

		After(2, function()
			StatsUpdator:Instant();
			RadarChart:SetValue(0,0,0,0,1);
			UpdateXmogName();
		end)

		local AnimSequenceInfo = Narci.AnimSequenceInfo;
		InitializeAnimationContainer(ASC2, AnimSequenceInfo["Heart"], Narci_HeartofAzeroth_AnimFrame.Sequence)
		local HeartSerialNumber = strsub(UnitGUID("player"), 8, 15);
		Narci_HeartofAzeroth_AnimFrame.SN:SetText("No."..HeartSerialNumber);
		Narci_HeartofAzeroth_AnimFrame.Quote:SetText(L["Heart Azerite Quote"]);

		UpdateXmogName();
		SetCVar("CameraKeepCharacterCentered", 0);
		--CameraMover:SetBlend(NarcissusDB.CameraTransition);	--Load in Settings.lua
		DefaultTooltip = NarciGameTooltip;	--Created in Module\GameTooltip.lua
		if not ItemTooltip then
			ItemTooltip = DefaultTooltip;
		end
		DefaultTooltip:SetParent(Narci_Character);
		DefaultTooltip:SetFrameStrata("TOOLTIP");
		DefaultTooltip.offsetX = 4;
		DefaultTooltip.offsetY = -16;
		DefaultTooltip:SetIgnoreParentAlpha(true);
	
		if C_AddOns.IsAddOnLoaded("DynamicCam") then
			CVarTemp.isDynamicCamLoaded = true;
			
			--Check validity
			if not (DynamicCam.BlockShoulderOffsetZoom and DynamicCam.AllowShoulderOffsetZoom) then return end;
			hooksecurefunc("Narci_Open", function()
				if IS_OPENED then
					DynamicCam:BlockShoulderOffsetZoom();
				else
					DynamicCam:AllowShoulderOffsetZoom();
				end
			end)
			hooksecurefunc("Narci_OpenGroupPhoto", function()
				DynamicCam:BlockShoulderOffsetZoom();
			end)

			ViewProfile:Disable();

		else
			if NarcissusDB.CameraSafeMode then
				local temp = GetCVar("test_cameraOverShoulder");
				if tonumber(temp) ~= 0 then
					--SetCVar("test_cameraOverShoulder", 0);
					ConsoleExec( "actioncam off" );
					NarciAPI.PrintPresetMessage("camera");
				end
			end
		end

		After(1.7, function()
			UpdateCharacterInfoFrame();
			
			if CVarTemp.isDynamicCamLoaded then
				CameraMover:UpdateMovementMethodForDynamicCam();
			else
				hooksecurefunc("CameraZoomIn", function(increment)
					if IS_OPENED and (not Narci.groupPhotoMode) then
						UpdateShoulderCVar:Start(-increment);
					end
				end)
				
				hooksecurefunc("CameraZoomOut", function(increment)
					if IS_OPENED and (not Narci.groupPhotoMode) then
						UpdateShoulderCVar:Start(increment);
					end
				end)
			end
		end)

		if TimerunningUtil.IsTimerunningMode() then
			Narci.deferGemManager = true;
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		local slotID, isItem = ...;
		USE_DELAY = false;
		SlotController:Refresh(slotID);

		if EquipmentFlyoutFrame:IsShown() and EquipmentFlyoutFrame.slotID then
			EquipmentFlyoutFrame:DisplayItemsBySlotID(EquipmentFlyoutFrame.slotID, false);
		end

		USE_DELAY = true;
		ItemLevelFrame:AsyncUpdate();
		local slot = SLOT_TABLE[slotID];
		if slot and slot:IsMouseOver() then
			slot:Disable();
			After(0, function()
				slot:Enable();
			end);
		end

	elseif event == "AZERITE_ESSENCE_ACTIVATED" then
		local neckSlotID = 2;
		SlotController:Refresh(neckSlotID);		--Heart of Azeroth

	elseif event == "PLAYER_AVG_ITEM_LEVEL_UPDATE" then
        if not self.pendingItemLevel then
            self.pendingItemLevel = true;
            After(0.1, function()    -- only want 1 update per 0.1s
				ItemLevelFrame:UpdateItemLevel();
				self.pendingItemLevel = nil;
            end)
		end

	elseif event == "COVENANT_CHOSEN" then
		local covenantID = ...;
		ItemLevelFrame:AsyncUpdate();
		MiniButton:SetBackground(covenantID);

	elseif event == "COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED" then
		local newRenownLevel = ...;
		ItemLevelFrame:UpdateRenownLevel(newRenownLevel);

	elseif event == "UNIT_NAME_UPDATE" then
		local unit = ...;
		if unit == "player" then
			UpdateCharacterInfoFrame();
		end

	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
		UpdateCharacterInfoFrame();
		UpdateXmogName(true);
		SlotButtonOverlayUtil:UpdateData();

	elseif event == "PLAYER_LEVEL_CHANGED" then
		local oldLevel, newLevel = ...;
		UpdateCharacterInfoFrame(newLevel)

	elseif ( event == "COMBAT_RATING_UPDATE" or
			 event == "UNIT_MAXPOWER" or
			 event == "UNIT_STATS" or
			 event == "UNIT_DAMAGE" or event == "UNIT_ATTACK_SPEED" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA"
			) and Narci.refreshCombatRatings then
		-- don't refresh stats when equipment set manager is activated
		StatsUpdator:Instant();
		if event == "COMBAT_RATING_UPDATE" then
			if Narci_Character:IsShown() then
				RadarChart:AnimateValue();
			end
		end

		if event == "UNIT_AURA" then
			local inAlteredForm = IsPlayerInAlteredForm();
			if self.wasAlteredForm ~= inAlteredForm then
				self.wasAlteredForm = inAlteredForm;
				CameraUtil:OnPlayerFormChanged(0.0);
			end
		end

	elseif event == "PLAYER_TARGET_CHANGED" then
		RefreshStats(8);		--Armor
		RefreshStats(9); 		--Damage Reduction

	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		CameraUtil:OnPlayerFormChanged(0.1);

	elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
		CameraUtil:OnPlayerFormChanged(0.0);

	elseif event == "PLAYER_REGEN_DISABLED" then
		if Narci.isAFK and Narci.isActive then
			--exit when entering combat during AFK mode
			MiniButton:Click();
			Narci:PlayVoice("DANGER");
		end

	elseif event == "PLAYER_STARTED_MOVING" then
		self:UnregisterEvent(event);
		MoveViewRightStop();
		if Narci.isAFK and Narci.isActive then
			--exit when entering combat during AFK mode
			MiniButton:Click();
		end

	elseif event == "PLAYER_STARTED_TURNING" and not MOG_MODE then
		NarciAR.Turning.radian = GetPlayerFacing();
		NarciAR.Turning:Show();

	elseif event == "PLAYER_STOPPED_TURNING" and not MOG_MODE then
		NarciAR.Turning:Hide();

	elseif event == "BAG_UPDATE_COOLDOWN" then
		StatsUpdator:UpdateCooldown();
		
	elseif event == "BAG_UPDATE" then
		local newTime = GetTime();
		if self.lastTime then
			if newTime > self.lastTime + 0.2 then
				self.lastTime = newTime;
			else
				return
			end
		else
			self.lastTime = newTime;
		end
		ItemLevelFrame:AsyncUpdate(0.1);

	elseif event == "UNIT_INVENTORY_CHANGED" then
		SlotController:LazyRefresh("temp");
	end
end)


function EL:ToggleDynamicEvents(state)
	if state then
		for _, event in ipairs(self.EVENTS_DYNAMIC) do
			self:RegisterUnitEvent(event);
		end
		for _, event in ipairs(self.EVENTS_UNIT) do
			self:RegisterUnitEvent(event, "player");
		end
	else
		for _, event in ipairs(self.EVENTS_DYNAMIC) do
			self:UnregisterEvent(event);
		end
		for _, event in ipairs(self.EVENTS_UNIT) do
			self:UnregisterEvent(event);
		end
	end
end

EL:SetScript("OnShow",function(self)
	self:ToggleDynamicEvents(true);
	if NarciAR then
		NarciAR:Show();
	end
end)

EL:SetScript("OnHide",function(self)
	self:ToggleDynamicEvents(false);
	if NarciAR then
		NarciAR:Hide();
	end
end)


----------------------------------------------------------------------
--Double-click PaperDoll Button to open Narcissus
NarciPaperDollDoubleClickTriggerMixin = {};

local function Narci_DoubleClickTrigger_OnUpdate(self, elapsed)
	self.t = self.t + elapsed;
	if self.t > 0.25 then
		self:SetScript("OnUpdate", nil);
	end
end

function NarciPaperDollDoubleClickTriggerMixin:OnLoad()
	self.t = 0;

	AssignFrame();
	AssignFrame = nil;

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

function NarciPaperDollDoubleClickTriggerMixin:OnShow()
	self.t = 0;
	self:SetScript("OnUpdate", Narci_DoubleClickTrigger_OnUpdate);
end


function NarciPaperDollDoubleClickTriggerMixin:OnHide()
	if (self.t < 0.25) and NarcissusDB.EnableDoubleTap then
		MiniButton:Click();
	end
end

----------------------------------------------------------------------
function Narci_GuideLineFrame_OnSizing(self, offset)
	local W;
	local W0, H = WorldFrame:GetSize();
	if (W0 and H) and H ~= 0 then
		local ratio = floor(W0 / H * 100 + 0.5)/100 ;
		if ratio == 1.78 then
			return
		end
		self:ClearAllPoints();
		self:SetPoint("TOP", UIParent, "TOP", 0, 0);
		self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0);
		offset = offset or 0;
		W = math.min(H / 9 * 16, W0);
		W = floor(W + 0.5);
		--print("Original: "..W0.." Calculated: "..W);
		self:SetWidth(W - offset);
	else
		W = self:GetWidth();
	end

	local C = W*0.618;

	self.VirtualLineRight:SetPoint("RIGHT", C - W +32, 0);
	self.VirtualLineRight.defaultX = C - W +32;

	local AnimFrame = self.VirtualLineRight.AnimFrame;
	AnimFrame.OppoDirection = false;
	AnimFrame.TimeSinceLastUpdate = 0;

	AnimFrame.anchorPoint, AnimFrame.relativeTo, AnimFrame.relativePoint, AnimFrame.toX, AnimFrame.toY = AnimFrame:GetParent():GetPoint();
	AnimFrame.defaultX = AnimFrame.toX;
end



NarciFlyoutOverlayMixin = {};

function NarciFlyoutOverlayMixin:In()
	--FadeFrame(self, 0.2, 1);
	self:Init();
	self.animFrame.toAlpha = 1;
	self.animFrame:Show();
	self:Show();
end

function NarciFlyoutOverlayMixin:Out()
	--FadeFrame(self, 0.2, 0);
	self:Init();
	self.animFrame.toAlpha = 0;
	self.animFrame:Show();
	self:Show();
end

function NarciFlyoutOverlayMixin:OnHide()
	self:SetAlpha(0);
	self:Hide();
end

function NarciFlyoutOverlayMixin:Init()
	if not self.animFrame then
		self.animFrame = CreateFrame("Frame", nil, self);
		self.animFrame:SetScript("OnUpdate", function(f, elapsed)
			f.t = f.t + elapsed;
			local alpha;
			if f.t < 0.25 then
				alpha = outSine(f.t, f.fromAlpha, f.toAlpha, 0.25);
			else
				alpha = f.toAlpha;
				if alpha <= 0 then
					self:Hide();
				end
				f:Hide();
			end
			self:SetAlpha(alpha);
		end);
	end
	self.animFrame.t = 0;
	self.animFrame.fromAlpha = self:GetAlpha();
end

function NarciFlyoutOverlayMixin:RaiseFrameLevel(widget)
	local selfLevel = self:GetFrameLevel();
	if self.lastWidget then
		self.lastWidget:SetFrameLevel(selfLevel - 1);
		self.lastWidget = nil;
	end
	local widgetLevel = widget:GetFrameLevel();
	if widgetLevel <= selfLevel then
		widget:SetFrameLevel(selfLevel + 1);
		self.lastWidget = widget;
	end
end



Narci.GetEquipmentSlotByID = function(slotID) return SLOT_TABLE[slotID] end;
Narci.RefreshSlot = function(slotID) SlotController:Refresh(slotID) return SLOT_TABLE[slotID] end;
Narci.RefreshAllSlots = SlotController.RefreshAll;
Narci.RefreshAllStats = StatsUpdator.Instant;


function Narci:SetItemTooltipStyle(id)

end

function Narci:CloseCharacterUI()
	if IS_OPENED then
		Narci_Open();
	end
end

do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.SetItemTooltipStyle(id, db)
        if id == nil then
            id = db["ItemTooltipStyle"];
        end
        if id == 2 then
            ItemTooltip = NarciGameTooltip;
        else
            ItemTooltip = NarciEquipmentTooltip;
        end
		NarciEquipmentTooltip:SetParent(Narci_Character);
    end


	function SettingFunctions.SetVignetteStrength(alpha, db)
		if alpha == nil then
			alpha = db["VignetteStrength"];
		end
		alpha = tonumber(alpha) or 0.5;
		VIGNETTE_ALPHA = alpha;
		Narci_Vignette.VignetteLeft:SetAlpha(alpha);
		Narci_Vignette.VignetteRight:SetAlpha(alpha);
		Narci_Vignette.VignetteRightSmall:SetAlpha(alpha);
		Narci_PlayerModelGuideFrame.VignetteRightSmall:SetAlpha(alpha);
	end


	function SettingFunctions.SetUltraWideFrameOffset(offset, db)
		--A positive offset expands the reference frame.
		if not offset then
			offset = db["BaseLineOffset"];
			offset = tonumber(offset) or 0
		end
		Narci_GuideLineFrame_OnSizing(Narci_GuideLineFrame, -offset);
	end

	function SettingFunctions.ShowDetailedStats(state, db)
		if state == nil then
			state = db["DetailedIlvlInfo"];
		end

		if Narci_Attribute:IsVisible() then
			if state then
				FadeFrame(Narci_DetailedStatFrame, 0.5, 1);
				FadeFrame(RadarChart, 0.5, 1);
				FadeFrame(Narci_ConciseStatFrame, 0.5, 0);
			else
				FadeFrame(Narci_DetailedStatFrame, 0.5, 0);
				FadeFrame(RadarChart, 0.5, 0);
				FadeFrame(Narci_ConciseStatFrame, 0.5, 1);
			end
		else
			if state then
				FadeFrame(Narci_DetailedStatFrame, 0, 1);
				FadeFrame(RadarChart, 0, 1);
				FadeFrame(Narci_ConciseStatFrame, 0, 0);
			else
				FadeFrame(Narci_DetailedStatFrame, 0, 0);
				FadeFrame(RadarChart, 0, 0);
				FadeFrame(Narci_ConciseStatFrame, 0, 1);
			end
		end
		Narci_ItemLevelFrame:ToggleExtraInfo(state);
		Narci_ItemLevelFrame.showExtraInfo = state;
		Narci_NavBar:SetMaximizedMode(state);
	end

	function SettingFunctions.SetCharacterUIScale(scale, db)
		if not scale then
			scale = db["GlobalScale"];
		end
		scale = tonumber(scale) or 1;
	
		NarciScreenshotToolbar:SetDefaultScale(scale);
		Narci_Character:SetScale(scale);
		Narci_Attribute:SetScale(scale);
		NarciTooltip:SetScale(scale);
	end

	function SettingFunctions.SetItemNameTextHeight(height, db)
		if not height then
			height = db["FontHeightItemName"];
		end
		height = tonumber(height) or 10;

		local font, _, flag = SLOT_TABLE[1].Name:GetFont();

		for id, slotButton in pairs(SLOT_TABLE) do
			slotButton.Name:SetFont(font, height, flag);
			slotButton:UpdateGradientSize();
		end
	end

	function SettingFunctions.SetItemNameTextWidth(width, db)
		if not width then
			width = db["ItemNameWidth"];
		end
		width = tonumber(width) or 200;

		if width >= 200 then
			width = 512;
		end

		for id, slotButton in pairs(SLOT_TABLE) do
			slotButton.Name:SetWidth(width);
			slotButton.ItemLevel:SetWidth(width);
			slotButton:UpdateGradientSize();
		end
	end

	function SettingFunctions.SetItemNameTruncated(state, db)
		if state == nil then
			state = db["TruncateText"];
		end

		local maxLines;
		if state then
			maxLines = 1;
		else
			maxLines = 2;
		end
		
		for id, slotButton in pairs(SLOT_TABLE) do
			slotButton.Name:SetMaxLines(maxLines);
			slotButton.ItemLevel:SetMaxLines(maxLines);
			slotButton.Name:SetWidth(slotButton.Name:GetWidth()+1)
			slotButton.Name:SetWidth(slotButton.Name:GetWidth()-1)
			slotButton.ItemLevel:SetWidth(slotButton.Name:GetWidth()+1)
			slotButton.ItemLevel:SetWidth(slotButton.Name:GetWidth()-1)
			slotButton:UpdateGradientSize();
		end
	end

	function SettingFunctions.UseCameraTransition(state, db)
		if state == nil then
			state = db["CameraTransition"];
		end

		CameraMover:SetBlend(state);
	end

	function SettingFunctions.EnableCameraSafeMode(state, db)
		if state == nil then
			state = db["CameraSafeMode"];
		end
		CVarTemp.cameraSafeMode = state;
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

	function SettingFunctions.EnableMissingEnchantAlert(state, db)
		if state == nil then
			state = db["MissingEnchantAlert"];
		end

		--only enabled when player reach max level
		if not NarciAPI.IsPlayerAtMaxLevel() then
			state = false;
		end

		SHOW_MISSING_ENCHANT_ALERT = state;
		SlotButtonOverlayUtil:SetEnabled(state);

		SlotController:ClearCache();
		if Narci_Character and Narci_Character:IsShown() then
			SlotController:LazyRefresh();
		end
	end
end




NarciCharacterUIPlayerNameEditBoxMixin = {};

function NarciCharacterUIPlayerNameEditBoxMixin:OnLoad()

end

function NarciCharacterUIPlayerNameEditBoxMixin:OnShow()
	self:UpdateSize();
end

function NarciCharacterUIPlayerNameEditBoxMixin:OnTextChanged()
	SmartFontType(self)
	self:UpdateSize();
end

function NarciCharacterUIPlayerNameEditBoxMixin:UpdateSize()
	local numLetters = self:GetNumLetters();
	local width = max(numLetters*16, 160);
	self:SetWidth(width);
end

function NarciCharacterUIPlayerNameEditBoxMixin:SaveAndExit()
	self:ClearFocus();
	local text = strtrim(self:GetText());
	self:SetText(text);
	NarcissusDB_PC.PlayerAlias = text;
end

function NarciCharacterUIPlayerNameEditBoxMixin:OnEscapePressed()
	self:SaveAndExit();
end

function NarciCharacterUIPlayerNameEditBoxMixin:OnEnterPressed()
	self:SaveAndExit();
end


NarciCharacterUIAliasButtonMixin = {};

function NarciCharacterUIAliasButtonMixin:OnLoad()
	local keepInvisibleFrame = true;
	NarciFadeUI.CreateFadeObject(self, keepInvisibleFrame);
end

function NarciCharacterUIAliasButtonMixin:OnEnter()
	self.Label:SetTextColor(0, 0, 0);
	self.Label:SetShadowColor(1, 1, 1);
	self.Highlight:Show();
end

function NarciCharacterUIAliasButtonMixin:OnLeave()
	self.Label:SetTextColor(0.25, 0.78, 0.92);
	self.Label:SetShadowColor(0, 0, 0);
	self.Highlight:Hide();
end

function NarciCharacterUIAliasButtonMixin:OnClick()
	NarcissusDB_PC.UseAlias = not NarcissusDB_PC.UseAlias;
	self:UpdateNames(true);
end

function NarciCharacterUIAliasButtonMixin:OnShow()
	self:SetScript("OnShow", nil);
	self:UpdateNames();
end

function NarciCharacterUIAliasButtonMixin:OnHide()
	self:OnLeave();
end

function NarciCharacterUIAliasButtonMixin:UpdateSize()
	self:SetWidth(self.Label:GetWidth() + 12);
end

function NarciCharacterUIAliasButtonMixin:UpdateNames(onClick)
	local editBox = self:GetParent();

	if NarcissusDB_PC.UseAlias then
		self.Label:SetText(L["Use Player Name"]);
		editBox:Enable();
		editBox:SetText(NarcissusDB_PC.PlayerAlias or UnitName("player"));
		if onClick then
			editBox:SetFocus();
			editBox:HighlightText();
		end
	else
		self.Label:SetText(L["Use Alias"]);
		local text = strtrim(editBox:GetText());
		editBox:SetText(text);
		NarcissusDB_PC.PlayerAlias = text;
		editBox:Disable();
		editBox:HighlightText(0,0)
		editBox:SetText(UnitName("player"));
	end

	self:UpdateSize();
	editBox:UpdateSize();
end


UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED");  --Disable EXPERIMENTAL_CVAR_WARNING