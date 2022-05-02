--/run Narci.ActiveModel:SetDisplayInfo(C_MountJournal.GetMountAllCreatureDisplayInfoByID(GetMouseFocus().mountID)[1].creatureDisplayID)
--/run Narci.ActiveModel:TryOn(C_TransmogCollection.GetAppearanceSources(GetMouseFocus().visualInfo.visualID)[1].sourceID)
local Narci = Narci;
local L = Narci.L;
local pi = math.pi;
local sin = math.sin;
local cos = math.cos;
local atan2 = math.atan2;
local sqrt = math.sqrt;
local tooltip = NarciTooltip;
local FadeFrame = NarciFadeUI.Fade;
local FadeIn = NarciFadeUI.FadeIn;
local After = C_Timer.After;
local SmartSetActorName = NarciAPI.SmartSetActorName;
local NarciAnimationInfo = NarciAnimationInfo;
local NarciSpellVisualBrowser = NarciSpellVisualBrowser;
local GetCursorPosition = GetCursorPosition;
local IsAltKeyDown = IsAltKeyDown;
local Screenshot = Screenshot;	--This is an API: screen capture
local IsMouseButtonDown = IsMouseButtonDown;

local _G = _G;
local VIRTUAL_ACTOR = L["Virtual Actor"];
local SettingFrame, BasicPanel;
local FullSceenChromaKey, FullScreenAlphaChannel;
local PrimaryPlayerModel, ActorPanel;	--PrimaryPlayerModel
local AnimationIDEditBox;
local OutfitToggle;
-----------------------------------
local defaultZ = -0.275;
local defaultY = 0.4;
local startY = 2.5;
local endFacing = -3.14/8;
local maxAnimationID = NarciConstants.Animation.MaxAnimationID or 1499;	--Auto-updated

local NUM_MAX_ACTORS = 8;
local IndexButtonPosition = {
	1, 2, 3, 4, 5, 6, 7, 8
};

local HIT_RECT_OFFSET = 0;

local function HighlightButton(button, bool)
	if bool then
		button:LockHighlight();
		button.Label:SetTextColor(0.88, 0.88, 0.88);
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		button:UnlockHighlight();
		button.Label:SetTextColor(0.65, 0.65, 0.65);
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
end


local LINK_SCALE = false;
local LINK_LIGHT = true;
local GLOBAL_CAMERA_PITCH = pi/2;

local ModelSettings = {
	["Generic"] = { panMaxLeft = -4, panMaxRight = 3, panMaxTop = 1.2, panMaxBottom = -1.6, panValue = 40 },
}

local TranslateValue_Male = {
	--[raceID] = {ZoomValue(1.Bust 2.FullBody), defaultY, defaultZ},
	[0] = {[1] = {0.05, 0.4, -0.275},		--Default Value
				[2] = {0.05, 0.4, -0.275}},

	[1] = {[1] = {0, 0.95, -0.36},
				[2] = {-0.3, 1.21, -0.09}},		--1 Human √

	[2] = {[1] = {-0.1, 1.33, -0.65},
				[2] = {-0.5, 1.67, -0.34}},		--2 Orc √	-0.1 -0.5

	[3] = {[1] = {0.05, 0.633, -0.06},
				[2] = {-0.4, 0.93, 0.16}},		--3 Dwarf √

	[4] = {[1] = {0.1, 0.98, -0.68},
				[2] = {-0.2, 1.33, -0.25}},		--4 NE √

	[5] = {[1] = {0.1, 0.83, -0.31},
				[2] = {-0.3, 1.21, -0.05}},		--5 UD √

	[6] = {[1] = {-0.1, 1.4, -1},
				[2] = {-0.4, 1.87, -0.58}},		--6 Tauren Male √

	[7] = {[1] = {0.05, 0.485, 0.22},
				[2] = {-0.6, 0.78, 0.332}},		--7 Gnome √

	[8] = {[1] = {-0.2, 1, -0.58},
				[2] = {-0.6, 1.33, -0.3}},		--8 Troll √

	[9] = {[1] = {0, 0.54, 0.12},
				[2] = {-0.5, 0.82, 0.26}},		--9 Goblin √

	[10] = {[1] = {0.2, 0.86, -0.5},
				[2] = {-0.3, 1.3, -0.09}},		--10 BloodElf Male √

	[11] = {[1] = {-0.1, 1.28, -0.72},
				[2] = {-0.5, 1.73, -0.39}},		--11 Goat Male √
			
	[22] = {[1] = {-0.1, 0.92, -0.58},
				[2] = {-0.55, 1.44, -0.26}},	--22 Worgen Wolf form √

	[24] = {[1] = {0, 1.07, -0.62},
				[2] = {-0.3, 1.54, -0.31}},		--24 Pandaren Male √

	[27] = {[1] = {0.1, 0.46, -0.35},
				[2] = {-0.3, 1.41, -0.32}},		--27 Nightborne

	[28] = {[1] = {0.05, 0, -0.09},
				[2] = {-0.6, 0.3, -0.175}},		--28 Tauren Male √

	[31] = {[1] = {0.1, 0.61, -0.4},
				[2] = {-0.3, 1.71, -0.48}},		--31 Zandalari

	[32] = {[1] = {0.1, 0.97, -0.8},
				[2] = {-0.4, 1.48, -0.36}},		--32 Kul'Tiran √

	[36] = {[1] = {0, 1.17, -0.55},
				[2] = {-0.3, 1.52, -0.28}},		--36 Mag'har

	[35] = {[1] = {0.3, 0.73, 0.111},
				[2] = {0, 0.95, 0.2375}},		--35 Vulpera √
}

local TranslateValue_Female = {
	--[raceID] = {ZoomValue, defaultY, defaultZ},
	[0] = {[1] = {0.05, 0.4, -0.275},		    --Default Value
				[2] = {0.05, 0.4, -0.275}},

	[1] = {[1] = {0.1, 0.77, -0.355},
				[2] = {-0.3, 1.18, 0}},		    --1 Human √

	[2] = {[1] = {0.1, 0.88, -0.46},
				[2] = {-0.3, 1.29, -0.138}},	--2 Orc √

	[3] = {[1] = {0.0, 0.71, -0.04},
				[2] = {-0.3, 0.93, 0.167}},		--3 Dwarf √

	[4] = {[1] = {0.2, 0.28, -0.28},
				[2] = {-0.3, 1.28, -0.22}},		--4 NE √

	[5] = {[1] = {0.2, 0.708, -0.332},
				[2] = {-0.3, 1.06, -0.00}},		--5 UD

	[6] = {[1] = {0.1, 1.121, -0.91},
				[2] = {-0.4, 1.7, -0.416}},		--6 Tauren Female √

	[7] = {[1] = {0.05, 0.56, 0.27},
				[2] = {-0.4, 0.73, 0.37}},		--7 Gnome √

	[8] = {[1] = {0.1, 0.89, -0.73},
				[2] = {-0.4, 1.38, -0.23}},		--8 Troll √

	[9] = {[1] = {0, 0.60, 0.07},
				[2] = {-0.5, 0.85, 0.236}},		--9 Goblin √

	[10] = {[1] = {0.2, 0.71, -0.38},
				[2] = {-0.3, 1.2, 0}},		    --10 BloodElf Female √

	[11] = {[1] = {0.2, 0.8, -0.73},
				[2] = {-0.3, 1.33, -0.23}},		--11 Goat Female √

	[22] = {[1] = {-0.1, 0.955, -0.773},
				[2] = {-0.6, 1.455, -0.27}},	--22 Worgen Wolf form √

	[24] = {[1] = {-0.1, 1, -0.54},
				[2] = {-0.5, 1.37, -0.15}},		--24 Pandaren Female √

	[27] = {[1] = {0.1, 0.45, -0.35},
				[2] = {-0.3, 1.33, -0.19}},		--27 Nightborne

	[31] = {[1] = {0.2, 0.5, -0.454},
				[2] = {-0.4, 1.73, -0.427}},	--31 Zandalari

	[32] = {[1] = {0.1, 0.88, -0.75},
				[2] = {-0.5, 1.37, -0.24}},	    --32 Kul'Tiran √

	[36] = {[1] = {0.1, 0.88, -0.46},
				[2] = {-0.3, 1.29, -0.138}},	--2 Orc √

	[35] = {[1] = {0.3, 0.73, 0.111},
				[2] = {-0.6, 0.98, 0.25}},		--35 Vulpera √
}

TranslateValue_Female[36] = TranslateValue_Female[2];

local function ReAssignRaceID(raceID, custom)
	if raceID == 30 then	--Lightforged
		raceID = 11;
	elseif raceID == 36 then	--Mag'har Orc
		--raceID = 2;
	elseif raceID == 34 then	--DarkIron
		raceID = 3;
	elseif raceID == 22 then	--Worgen
		local _, inAlternateForm = HasAlternateForm();
		if inAlternateForm and not custom then		--Human form is Worgen's alternate form
			raceID = 1;
		end
	elseif raceID == 25 or raceID == 26 then --Pandaren A|H
		raceID = 24;
	elseif raceID == 28 then	--Hightmountain
		raceID = 6;
	elseif raceID == 29 then
		raceID = 10;
	elseif raceID == 37 then				--Mechagnome
		raceID = 7;
	end

	return raceID;
end

local TranslateValue;

local function AssignModelPositionTable(race, gender)
	local _, _, XraceID = UnitRace("player")
	XraceID = race or XraceID;
	XraceID = ReAssignRaceID(XraceID);
	local XgenderID = gender or UnitSex("player");		--2 Male	3 Female
	if XgenderID == 2 then
		TranslateValue = TranslateValue_Male[XraceID];
	else
		TranslateValue = TranslateValue_Female[XraceID];
	end
end
-----------------------------------

local function outSine(t, b, c, d)
	return c * sin(t / d * (pi / 2)) + b
end
local function outQuad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end
-----------------------------------
local ACTIVE_MODEL_INDEX = 1;
local ModelFrames = {};
local playerInfo = {};

local function SetGenderIcon(genderID)
	local button = Narci_GenderButton;
	if genderID == 3 then
		--female
		button.Icon:SetTexCoord(0.5, 1, 0, 0.5);
		button.Icon2:SetTexCoord(0.5, 1, 0, 0.5);
		button.Highlight:SetTexCoord(0.5, 1, 0.5, 1);
	elseif genderID == 2 then
		button.Icon:SetTexCoord(0, 0.5, 0, 0.5);
		button.Icon2:SetTexCoord(0, 0.5, 0, 0.5);
		button.Highlight:SetTexCoord(0, 0.5, 0.5, 1);
	end
end

local function GetUnitRaceIDAndSex(unit)
	unit = unit or "player";
	local _, _, raceID = UnitRace(unit);
	local gender = UnitSex(unit);
	return raceID or 1, gender
end

local function InitializePlayerInfo(index, unit)
	local unit = unit or "player";
	local name = UnitName(unit);
	local _, className = UnitClass(unit);
	local race, gender =  GetUnitRaceIDAndSex(unit);
	playerInfo[index] = playerInfo[index] or {};
	playerInfo[index].raceID_Original, playerInfo[index].gender_Original = race, gender;
	playerInfo[index].raceID = playerInfo[index].raceID_Original;
	playerInfo[index].gender = playerInfo[index].gender_Original;
	playerInfo[index].name = name;
	playerInfo[index].class = className;
	SetGenderIcon(playerInfo[index].gender_Original);
	local r, g, b = GetClassColor(className);
	local fontstring = ActorPanel.ExtraPanel.buttons[index].Label;	--name tooltip
	SmartSetActorName(fontstring, name);
	fontstring:SetTextColor(r, g, b);
	
	return race, gender;
end

local function RestorePlayerInfo(index)
	if not playerInfo[index] then return; end;
	playerInfo[index].raceID = playerInfo[index].raceID_Original;
	playerInfo[index].gender = playerInfo[index].gender_Original;
	SetGenderIcon(playerInfo[index].gender_Original);
end

local function UpdateActorName(index)
	local str = ActorPanel.ActorButton.ActorName;

	local className = playerInfo[index].class;
	local r, g, b = GetClassColor(className);
	if className == "DEATHKNIGHT" or className == "DEMONHUNTER" or className == "SHAMAN" then
		r, g, b = r + 0.05, g + 0.05, b + 0.05;
	end

	SmartSetActorName(str, playerInfo[index].name or "Unnamed");
	str:SetTextColor(r, g, b);
end

local function ResetModelPosition(model)
	model:SetPosition(0, 0, 0);
end


local function UpdateGroundShadowOption()
	local button = Narci_GroundShadowToggle;
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local shadowFrame = model.GroundShadow;
	local state = shadowFrame:IsShown();
	HighlightButton(button, state);

	Narci_GroundShadowOption:ReAnchor(model, shadowFrame.Option);
end

-------------------------
--Model Control Buttons--
-------------------------

local function DisablePlayButton()
	local playButton = NarciModelControl_PlayAnimationButton;
	local animationSlider = NarciModelControl_AnimationSlider;
	playButton.isOn = false;
	playButton.Highlight:Hide();
	animationSlider:Show();

	local pauseButton = NarciModelControl_PauseAnimationButton;
	pauseButton.isOn = true;
	pauseButton.Highlight:Show();
end

local function DisablePauseButton()
	local pauseButton = NarciModelControl_PauseAnimationButton;
	local animationSlider = NarciModelControl_AnimationSlider;
	pauseButton.isOn = false;
	pauseButton.Highlight:Hide();
	if animationSlider:IsShown() then
		animationSlider.animOut:Play();
	end

	local playButton = NarciModelControl_PlayAnimationButton;
	playButton.isOn = true;
	playButton.Highlight:Show();
end

local function Narci_CharacterModelFrame_OnShow(self)
	if self.xmogMode == 2 then
		--NarciModel_RightGradient:Show();
	else
		NarciModel_RightGradient:Hide();
	end

	if not SettingFrame:IsShown() then
		SettingFrame:Show();
		After(1, function()
			SettingFrame:FadeIn(0.5);
		end);
	end
end

function Narci_CharcaterModelFrame_OnHide(self)
	if ( self.panning ) then
		self.panning = false;
	end
	self.mouseDown = false;
end

local function rotateTexture(tex, Degree)
	local ag = tex.ag;
	if not ag then
		ag = tex:CreateAnimationGroup();
	end
	local a1 = ag.a1;
	if not a1 then
		a1 = ag:CreateAnimation("Rotation");
		ag.a1 = a1;
	end
	ag:Stop();
	a1:SetRadians(Degree);
	a1:SetOrigin("CENTER",0 ,0);
	a1:SetOrder(1);
	a1:SetDuration(0);
	local a2 = ag.a2;
	if not a2 then
		a2 = ag:CreateAnimation("Rotation");
		ag.a2 = a2;
	end
	a2:SetRadians(0);
	a2:SetOrigin("CENTER",0 ,0); 
	a2:SetOrder(2);
	a2:SetDuration(1);
	ag:Play();
	ag:Pause();

	tex.ag = ag;
end

local RGB2HSV = NarciAPI.RGB2HSV;
local RGBRatio2HSV = NarciAPI.RGBRatio2HSV;
local HSV2RGB = NarciAPI.HSV2RGB;

local LightControl = {};
LightControl.ambientMode = false;
LightControl.angleZ = pi/4;
LightControl.angleXY = -3*pi/4;

function LightControl:SetLightWidgetFromActiveModel()
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local _, _, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB = model:GetLight();
	local hypotenuse = sqrt(dirX*dirX + dirY*dirY);

	local angleZ = -atan2(dirZ, hypotenuse);
	local angleXY = - pi - atan2(dirX, dirY);
	
	local r = self.radius;
	local button1 = self.parentButton1;
	local button2 = self.parentButton2;
	local x1, y1 = r*cos(angleZ), r*sin(angleZ);
	local x2, y2 = r*cos(angleXY), r*sin(angleXY);

	button1:SetPoint("CENTER", x1, y1);
	button1.Tex:SetRotation(angleZ);
	button1.Highlight:SetRotation(angleZ);
	BasicPanel.LeftView.LightColor:SetRotation(angleZ);

	button2:SetPoint("CENTER", x2, y2);
	button2.Tex:SetRotation(angleXY);
	button2.Highlight:SetRotation(angleXY);
	BasicPanel.TopView.LightColor:SetRotation(angleXY);

	local h, s, v;
	
	if self.ambientMode then
		h, s, v = RGBRatio2HSV(ambR, ambG, ambB);
	else
		h, s, v = RGBRatio2HSV(dirR, dirG, dirB);
	end

	NarciModelControl_HueSlider:SetValue(h);
	NarciModelControl_SaturationSlider:SetValue(s);
	NarciModelControl_BrightnessSlider:SetValue(v);

	BasicPanel.TopView.AmbientColor:SetColorTexture(ambR, ambG, ambB, 0.6);
	BasicPanel.LeftView.AmbientColor:SetColorTexture(ambR, ambG, ambB, 0.6);
	BasicPanel.TopView.LightColor:SetVertexColor(dirR, dirG, dirB, 0.6);
	BasicPanel.LeftView.LightColor:SetVertexColor(dirR, dirG, dirB, 0.6);
end

function LightControl:UpdateModel()
	local phi = pi/2-(self.angleZ);
	local rX = sin(phi)*sin(self.angleXY);
	local rY = -sin(phi)*cos(self.angleXY);
	local rZ = -cos(phi);
	--print(rX, rY, rZ);

	local _, _, _, _, _, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB = ModelFrames[ACTIVE_MODEL_INDEX]:GetLight();

	--Override Target
	--[[
	local model = TestFrame.WeaponModel;
	model:SetLight(true, false, rX, rY, rZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB);
	if true then return end;
	--]]
	
	if LINK_LIGHT then
		for i = 1, #ModelFrames do
			ModelFrames[i]:SetLight(true, false, rX, rY, rZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB);
		end
	else
		ModelFrames[ACTIVE_MODEL_INDEX]:SetLight(true, false, rX, rY, rZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB);
		--[[
		local ModelScene = Narci_InteractiveSplash.ClipFrame.ModelScene;
		ModelScene:SetLightDirection(rX, rY, rZ);
		ModelScene:SetLightDiffuseColor(dirR, dirG, dirB);
		ModelScene:SetLightAmbientColor(ambR, ambG, ambB);
		print(dirR, dirG, dirB, ambR, ambG, ambB);
		--]]
	end
end

function LightControl:SetDirection(radian, heightRatio)
	local r = self.radius;
	local button1 = self.parentButton1;
	local button2 = self.parentButton2;

	if not r then return end

	local x2, y2 = r*cos(radian), r*sin(radian);
	button2:SetPoint("CENTER", x2, y2);
	button2.Tex:SetRotation(radian);
	button2.Highlight:SetRotation(radian);
	BasicPanel.TopView.LightColor:SetRotation(radian);

	self.angleXY = radian;

	--[[
	local angleZ = heightRatio * 1.5708;	--pi/2
	if angleZ >= 1.309 then
		angleZ = 1.309		--90 - 15
	elseif angleZ <= 0.2618 then
		angleZ = 0.2618;	--15
	end

	local x1, y1 = r*cos(angleZ), r*sin(angleZ);
	button1:SetPoint("CENTER", x1, y1);
	button1.Tex:SetRotation(angleZ);
	button1.Highlight:SetRotation(angleZ);
	rotateTexture(self.BeamMask1, angleZ);
	self.angleZ = angleZ;
	--]]


	self:UpdateModel();
end

function LightButton_UpdateFrame_OnLoad(self)
	local r = self:GetParent():GetWidth()/2 - 4;
	self.r = r;
	LightControl.radius = r;

	local button = self:GetParent().Thumb;
	local radian = self.radian;
	local x, y = self.r*math.cos(radian), self.r*math.sin(radian);
	button:SetPoint("CENTER", x, y);
	button.Tex:SetRotation(radian);
	button.Highlight:SetRotation(radian);
	self:GetParent().LightColor:SetRotation(radian);

	if self.limit then
		LightControl.parentButton1 = button;
		--LightControl.BeamMask1 = self:GetParent().BeamMask;
	else
		LightControl.parentButton2 = button;
		--LightControl.BeamMask2 = self:GetParent().BeamMask;
	end
end

function LightButton_UpdateFrame_OnUpdate(self)
	local button = self:GetParent().Thumb;
	local radian;

	local mx, my = self:GetParent():GetCenter();
	local px, py = GetCursorPosition();

	--Adjust for mousedown start offset
	px, py = (px + self.dx) / self.scale, (py + self.dy) / self.scale;
	radian = atan2(py - my, px - mx);
	
	if self.limit then
		if radian >= pi/2 then
			radian = pi/2 - 0.001;
		elseif radian <= -pi/2 then
			radian = -pi/2 + 0.001;
		end
		LightControl.angleZ = radian;
	else
		LightControl.angleXY = radian;
		local FaceLeft = self:GetParent():GetParent().LeftView.FaceLeft;
		local FaceRight = self:GetParent():GetParent().LeftView.FaceRight;
		if FaceLeft and FaceRight then
			local degree2 = math.deg(radian);
			if degree2 > 0 then
				FaceLeft:SetAlpha(1);
				FaceRight:SetAlpha(0);
			elseif degree2 <= 0 and degree2 >= -180 then
				FaceLeft:SetAlpha(0);
				FaceRight:SetAlpha(1);
			end
		end
	end

	--Not sure why MaskTexture can only get rotated after mouse-up event.
	self:GetParent().LightColor:SetRotation(radian);

	local r = self.r;
	local x, y = r*cos(radian), r*sin(radian);
	button:SetPoint("CENTER", x, y);
	button.Tex:SetRotation(radian);
	button.Highlight:SetRotation(radian);

	LightControl:UpdateModel();
end


----------------------------------------------------------------------
--Fix Weapon Missing Issue
local WeaponUpdator = {};
WeaponUpdator.GetInspectTransmogInfo = C_TransmogCollection.GetInspectSources or C_TransmogCollection.GetInspectItemTransmogInfoList;	--API changed in 9.1.0

function WeaponUpdator:GetPlayerWeapons(model)
	model = model or PrimaryPlayerModel;
	if not model or not model.TryOn then return end;

	local transmogLocation = CreateFromMixins(TransmogLocationMixin);
	local transmogType = 0;
	local modification = 0;
	local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID;
	for slotID = 16, 17 do
		transmogLocation:Set(slotID, transmogType, modification);
		baseSourceID, baseVisualID, appliedSourceID, appliedVisualID = C_Transmog.GetSlotVisualInfo(transmogLocation);
		if appliedSourceID == 0 then
			model:UndressSlot(slotID);
		else
			if slotID == 16 then
				model:TryOn(appliedSourceID, "MAINHANDSLOT");
			else
				model:TryOn(appliedSourceID, "SECONDARYHANDSLOT");
			end
		end

		--print(slotID..": "..appliedSourceID)
	end
end

function WeaponUpdator:GetTargetWeapons(unit)
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	if false and UnitIsUnit(unit, "player") then
		WeaponUpdator:GetPlayerWeapons(model);
	else
		if model and CanInspect(unit) then
			self:SetListener(true, unit);
			NotifyInspect(unit);
		end
	end
end

function WeaponUpdator:SetListener(state, unit)
	if state then
		if not self.queue then
			self.queue = {};
		end

		if not self.eventListener then
			self.eventListener = CreateFrame("Frame");
			self.eventListener:SetScript("OnEvent", function(f, event, inspecteeGUID)
				if not self.pauseUpdate then
					self.pauseUpdate = true;
					self:ProcessInspect(inspecteeGUID);
				end
			end);
		end
		local guid = UnitGUID(unit);
		self.queue[guid] = ModelFrames[ACTIVE_MODEL_INDEX];
		self.eventListener:RegisterEvent("INSPECT_READY");
	else
		if self.eventListener then
			wipe(self.queue);
			self.eventListener:UnregisterEvent("INSPECT_READY");
			ClearInspectPlayer();
		end
	end
end

function WeaponUpdator:ProcessInspect(inspecteeGUID)
	local model = self.queue[inspecteeGUID];
	if model then
		local transmogInfoList, mainHandEnchant, offHandEnchant = self.GetInspectTransmogInfo();
		if not model.equippedWeapons then
			model.equippedWeapons = {};
		end

		if model.SetItemTransmogInfo then
			local hand = 0;
			local transmogInfo;
			local mainHandInfo, offHandInfo;
			for slotID = 16, 17 do
				hand = hand + 1;
				transmogInfo = transmogInfoList[slotID];
				if transmogInfo then
					--[[
					local currentInfo = model:GetItemTransmogInfo(slotID);
					if not transmogInfo:IsEqual(currentInfo) then
						model:SetItemTransmogInfo(transmogInfo, slotID, slotID ~= 16);
					end
					--]]
					model.equippedWeapons[hand] = transmogInfo.appearanceID;

					local currentInfo = model:GetItemTransmogInfo(slotID);
					if not transmogInfo:IsEqual(currentInfo) then
						model:TryOn(transmogInfo.appearanceID, (slotID == 16 and "MAINHANDSLOT") or "SECONDARYHANDSLOT", transmogInfo.illusionID);    --ME FIXED?
						--NarciPhotoModeOutfitSelect:ModifyPlayerTransmogInfo(model:GetID(), slotID, transmogInfo);
					end
					if slotID == 16 then
						mainHandInfo = transmogInfo;
					else
						offHandInfo = transmogInfo;
					end
					--print(slotID.. " " ..transmogInfo.appearanceID)
				else
					model.equippedWeapons[hand] = nil;
				end
				NarciPhotoModeOutfitSelect:ModifyPlayerTransmogInfo(model:GetID(), mainHandInfo, offHandInfo);
			end
		elseif model.TryOn then
			if transmogInfoList[16] then
				model:TryOn(transmogInfoList[16], "MAINHANDSLOT", mainHandEnchant);
				model.equippedWeapons[1] = transmogInfoList[16];
			end
			if transmogInfoList[17] then
				model:TryOn(transmogInfoList[17], "SECONDARYHANDSLOT", offHandEnchant);
				model.equippedWeapons[1] = transmogInfoList[17];
			end
		end

		self.queue[inspecteeGUID] = nil;
		After(0, function()
			self.pauseUpdate = nil;
			self:SetListener(false);
		end)
		--[[
		for guid, m in pairs(self.queue) do
			if m then
				print("in queue: "..guid)
				break
			end
		end

		After(0, function()
			self:SetListener(false);
		end);
		--]]
	end
end

----------------------------------------------------------------------
local PMAI = CreateFrame("Frame", "Narci_PlayerModelAnimIn");
PMAI:Hide();
PMAI.t = 0
PMAI.faceTime = 0;
PMAI.trigger = true;
PMAI.init = true;
PMAI.useAlternateEntrance = true;		--Enable entrance visual

function Narci:SetUseEntranceVisual()
	local state = NarcissusDB.UseEntranceVisual;
	if type(state) ~= "boolean" then
		state = true;
	end
	PMAI.useAlternateEntrance = state;
end

local function PlayerModelAnimIn_Update_Style1(self, elapsed)
	local ModelFrame = PrimaryPlayerModel;
	self.t = self.t + elapsed;
	local turnTime = 0.36;
	local t = 1;
	local offset = outQuad(self.t, startY, defaultY - startY, t);

	if self.t > turnTime then
		self.faceTime= self.faceTime + elapsed;
		local radian = outSine(self.faceTime, -pi/2, endFacing + pi/2, 0.8); --0.11 NE
		ModelFrame:SetFacing(radian);
		ModelFrame.rotation = radian;
	end

	ModelFrame:SetPosition(0, offset, ModelFrame.posZ);
	ModelFrame.posY = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end

	if self.t <=0.8 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:PlayAnimation(804);
		ModelFrame:MakeCurrentCameraCustom();
	end
end

local function InitializeModel(model)
	model:SetLight(true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 204/255, 204/255, 204/255, 1, 0.8, 0.8, 0.8);
	local zoomLevel = -0.5;
	model:MakeCurrentCameraCustom();
	model:SetPortraitZoom(zoomLevel)
	model:SetPosition(0, 0, defaultZ);
	model:PlayAnimation(0, 0);
	After(0, function()
		model:ResetCameraPosition();
	end)
end

local _, _, classID = UnitClass("player");
local EntranceAnimation = Narci.ClassEntranceVisuals[classID];
PMAI:SetScript("OnShow", function(self)		--PlayerModelAnimIn
	local model = PrimaryPlayerModel;
	model:RefreshUnit();
	model.isItemLoaded = false;
	model.isPlayer = true;
	model.hasRaceChanged = false;
	local ZoomMode = 2;
	--if NarcissusDB.ShowFullBody then
	--	ZoomMode = 2;	--Full body
	--else
	--	ZoomMode = 1;
	--end
	AssignModelPositionTable();
	local zoomLevel = TranslateValue[ZoomMode][1] or 0.05;
	defaultY = TranslateValue[ZoomMode][2] or 0.4;
	defaultZ = TranslateValue[ZoomMode][3] or -0.275;
	model:SetPortraitZoom(zoomLevel);
	model.zoomLevel = zoomLevel;

	if (not self.useAlternateEntrance) or not EntranceAnimation then
		model:SetPosition(0, startY, defaultZ);
		model.posZ = defaultZ;
		model:SetFacing(-pi/2);
		model:FreezeAnimation(4,1);
		model:SetAnimation(4);
		self:SetScript("OnUpdate", PlayerModelAnimIn_Update_Style1);
	else
		local soundID = EntranceAnimation[6];
		if soundID then
			PlaySound(soundID, "SFX");
		end
		local animStart = EntranceAnimation[4];	--38
		local startY = EntranceAnimation[1] or defaultY;
		local startZ = EntranceAnimation[2] or defaultZ;
		local startFacing = EntranceAnimation[3] or endFacing;
		self.defaultY = defaultY;
		self.defaultZ = defaultZ;
		self.startY = startY;
		self.startZ = startZ;
		model:SetPosition(0, startY, startZ);
		model.posY = startY;
		model.posZ = startZ;
		model:SetFacing(startFacing);
		model.rotation = startFacing;
		model:FreezeAnimation(animStart,1);
		model:SetAnimation(animStart);
		self:SetScript("OnUpdate", EntranceAnimation[5]);
	end
	model:Show();
	model:SetAlpha(1);
	model:SetModelAlpha(1);
	model.isVirtual = false;
	model:ResetCameraPosition();
	FadeIn(Narci_ModelContainer, 0.6);

	if self.init then	--Initialize settings
		self.init = nil;
		BasicPanel.ColorPresets.Color1:Click();
		model:SetSheathed(true);
		model:SetKeepModelOnHide(true);
	end

	WeaponUpdator:GetTargetWeapons("player");
	model:SetActive(true);
end);

PMAI:SetScript("OnUpdate", PlayerModelAnimIn_Update_Style1);
PMAI:SetScript("OnHide", function(self)
	self.t = 0;
	self.faceTime = 0;
	self.trigger = true;
end);

local PMAO = CreateFrame("Frame","Narci_PlayerModelAnimOut");
PMAO:Hide();
PMAO.t = 0
PMAO.faceTime = 0;
PMAO.trigger = true;
PMAO.Facing = 0;
PMAO.PosY = 0;
PMAO.PosZ = 0;

local function PlayerModelAnimOut_Update(self, elapsed)
	local ModelFrame = PrimaryPlayerModel;
	self.t = self.t + elapsed;
	local turnTime = 0.3;
	local t = 1;

	local radian = outSine(self.t, self.Facing, pi/2 - self.Facing, turnTime); --0.11 NE
	if self.t < turnTime then
		ModelFrame:SetFacing(radian);
		ModelFrame.rotation = radian;
	end

	if self.t > 0.2 then
		self.faceTime= self.faceTime + elapsed;
		local offset = PMAO.PosY + 1.15*self.faceTime/t;
		ModelFrame:SetPosition(0, offset, self.PosZ);
		ModelFrame.posY, ModelFrame.posZ = offset, PMAO.PosZ;
	end

	if self.t >= t then
		ModelFrame:SetUnit("player");
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0.1 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:SetAnimation(4);
	end
end

local function HideAllModels()
	local _G = _G;
	local player;
	local npc = _G["NarciNPCModelFrame"..1];
	if npc then
		npc:Hide();
	end
	for i = 2, NUM_MAX_ACTORS do
		player = _G["NarciPlayerModelFrame"..i];
		npc = _G["NarciNPCModelFrame"..i];
		if player then
			player:Hide();
			player.customTransmogList = nil;
		end
		if npc then
			npc:Hide();
		end
	end
end

PMAO:SetScript("OnShow", function(self)
	GLOBAL_CAMERA_PITCH = pi/2;
	self.Facing = PrimaryPlayerModel:GetFacing();
	local _;
	_, self.PosY, self.PosZ = PrimaryPlayerModel:GetPosition();
	FadeFrame(SettingFrame, 0.4, 0)
	HideAllModels();
end)

PMAO:SetScript("OnUpdate", PlayerModelAnimOut_Update);
PMAO:SetScript("OnHide", function(self)
	self.t = 0;
	self.faceTime = 0;
	self.trigger = true;
	InitializePlayerInfo(1);	--Reset Actor#1 portrait and name
	PrimaryPlayerModel:SetUnit("player");
end);


----------------------------------------------------------------
function Narci_Xmog_UseCompactMode(state)
	local frame = PrimaryPlayerModel;
	if state then
		FadeFrame(frame.GuideFrame, 0.5, 1);
		Narci_PlayerModelGuideFrame.VignetteRightSmall:Show();
		UIFrameFadeOut(NarciModel_RightGradient, 0.5, NarciModel_RightGradient:GetAlpha(), 0)
	else
		FadeFrame(frame.GuideFrame, 0.5, 0);
		if PrimaryPlayerModel.xmogMode == 2 and Narci_Character:IsShown() then
			FadeFrame(NarciModel_RightGradient, 0.5, 1)
		end
	end
end


local Smooth_Zoom = CreateFrame("Frame");
Smooth_Zoom.t = 0;
Smooth_Zoom.duration = 0.2;
Smooth_Zoom:Hide();

local function UpdateCameraPosition(model)
	--Spherical Coordinates since 1.0.7
	model:SetCameraPosition(model.cameraDistance*sin(model.cameraPitch), 0, model.cameraDistance*cos(model.cameraPitch) + 0.8);
end

local function UpdateCameraPitch(model, pitch)
	model.cameraPitch = pitch;
	UpdateCameraPosition(model);
end

local function UpdateGlobalCameraPitch(pitch)
	local model;
	for i = 1, #ModelFrames do
		model = ModelFrames[i];
		if model and not model.isVirtual then
			model.cameraPitch = pitch;
			UpdateCameraPosition(model);
		end
	end
	GLOBAL_CAMERA_PITCH = pitch;
end

local function Smooth_Zoom_Update(self, elapsed)
	self.t = self.t + elapsed
	local EndPoint = self.EndPoint;
	local StartPoint = self.StartPoint;
	local Value = outSine(self.t, StartPoint, EndPoint - StartPoint, self.duration) --0.11 NE
	if LINK_SCALE then
		for i = 1, #ModelFrames do
			--ModelFrames[i]:SetCameraDistance(Value);
			ModelFrames[i].cameraDistance = Value;
			UpdateCameraPosition(ModelFrames[i]);
		end
	else
		--ModelFrames[ACTIVE_MODEL_INDEX]:SetCameraDistance(Value);
		--print(Value)
		ModelFrames[ACTIVE_MODEL_INDEX].cameraDistance = Value;
		UpdateCameraPosition(ModelFrames[ACTIVE_MODEL_INDEX]);
	end

	if self.t >= self.duration then
		self:Hide();
	end
end


Smooth_Zoom:SetScript("OnShow", function(self)
	self.StartPoint = ModelFrames[ACTIVE_MODEL_INDEX].cameraDistance;
end);
Smooth_Zoom:SetScript("OnUpdate", Smooth_Zoom_Update);
Smooth_Zoom:SetScript("OnHide", function(self)
	self.t = 0
end);

local function SmoothZoomModel(EndPoint)
	Smooth_Zoom:Hide();
	Smooth_Zoom.EndPoint = EndPoint;
	Smooth_Zoom:Show();
end

local function Narci_ShowChromaKey(state)
	local frame = FullSceenChromaKey;

	if state then
		FadeFrame(frame, 0.25, 1);
		Narci_Character:SetShown(false);
	else
		FadeFrame(frame, 0.5, 0);
		if Narci_SlotLayerButton.isOn then
			Narci_Character:SetShown(true);
		end
	end
end


--- Show Alpha Channel ---

local function ShowTextAlphaChannel(state, doNotShowModel)
	--Text Mask
    local slotTable = Narci_Character.slotTable;
    if not (slotTable) then
        return;
    end

	local theme = NarcissusDB.BorderTheme;
	local borderMask;
	local shadowAlpha = false;
	local runeAlpha = 1;
	if theme == "Bright" then
		borderMask = "Interface/AddOns/Narcissus/Art/Masks/HexagonThin-Mask";
	elseif theme == "Dark" then
		borderMask = "Interface/AddOns/Narcissus/Art/Masks/HexagonThick-Mask";
		shadowAlpha = true;
		runeAlpha = 0;
	end

	local slot, sourcePlainText, tempText;
	if state then
		for i=1, #slotTable do
			slot = slotTable[i];
			if slot then
				--slotTable[i].Name:SetFont(font, Height);
				if slot.RuneSlot then
					--slot.RuneSlot.AlphaChannelRune:Show();
					--slot.RuneSlot.Background:SetAlpha(runeAlpha);
				end
				slot.GradientBackground:SetColorTexture(1, 1, 1);
				slot.Name:SetTextColor(1, 1, 1);
				slot.Name:SetShadowColor(1, 1, 1);
				tempText = slot.Name:GetText();
				slot.Name:SetText(" ");		--IDK why shadow color won't be updated until the text got
				slot.Name:SetText(tempText);
				sourcePlainText = slot.sourcePlainText;
				if sourcePlainText then
					slot.ItemLevel:SetText(" ");
					slot.ItemLevel:SetText(sourcePlainText);
				end
				slot.ItemLevel:SetTextColor(1, 1, 1);
				slot.ItemLevel:SetShadowColor(1, 1, 1);
				slot:ShowAlphaChannel();
			end
		end
		Narci_ModelContainer:Hide();
		Narci_XmogNameFrame:Hide();
		Narci_Character:SetAlpha(1);
		Narci_Character:Show();
	else
		for i=1, #slotTable do
			slot = slotTable[i];
			if slot then
				--slotTable[i].Name:SetFont(font, Height);
				if slot.RuneSlot then
					--slot.RuneSlot.AlphaChannelRune:Hide();
					--slot.RuneSlot.Background:SetAlpha(runeAlpha);
				end
				slot.GradientBackground:SetColorTexture(0, 0, 0);
				slot.Name:SetShadowColor(0, 0, 0);
				slot.ItemLevel:SetShadowColor(0, 0, 0);
				slot:Refresh();
			end
		end

		if not doNotShowModel then
			Narci_ModelContainer:Show();
			Narci_ModelContainer:SetAlpha(1);
			Narci_XmogNameFrame:Show();
			Narci_XmogNameFrame:SetAlpha(1);
		end
	end
end

local hasBackup = false;
local LayerButtonStates = {};
local function UnhighlightAllLayerButtons()
	local buttons = BasicPanel.LayerButtons;
	if not hasBackup then
		wipe(LayerButtonStates);
	end

	for i=1, #buttons do
		if not hasBackup then
			tinsert(LayerButtonStates, buttons[i].isOn);
		end
		buttons[i].isOn = false;
		buttons[i]:UnlockHighlight();
		buttons[i].Label:SetTextColor(0.65, 0.65, 0.65) --
		buttons[i].AlphaButton.isOn = false;
		buttons[i].AlphaButton:UnlockHighlight();
	end
	hasBackup = true;
end

local function RestoreAllLayerButtons()
	local buttons = BasicPanel.LayerButtons;
	for i=1, #buttons do
		local state = LayerButtonStates[i];
		buttons[i].isOn = state
		buttons[i].AlphaButton.isOn = false;
		buttons[i].AlphaButton:UnlockHighlight();
		--print(i..": "..tostring(state))
		HighlightButton(buttons[i], state);
	end
	hasBackup = false;
end

local function ExitAlphaMode()
	local buttons = BasicPanel.AlphaButtons;
	for i= 1, #buttons do
		if buttons[i].isOn then
			buttons[i]:Click()
			return true;
		end
	end
	return false;
end

local function LayerButton_OnClick(self)
	if ExitAlphaMode() then
		return;
	end

	self.isOn = not self.isOn;
	HighlightButton(self, self.isOn);
end

local function SlotLayerButton_OnClick(self)
	LayerButton_OnClick(self);
	--Narci_Character:SetShown(self.isOn);
	if self.isOn then
		if PrimaryPlayerModel.xmogMode == 2 then
			FadeFrame(NarciModel_RightGradient, 0.25, 1);
		end
		FadeFrame(Narci_Character, 0.25, 1);
	else
		FadeFrame(NarciModel_RightGradient, 0.25, 0);
		FadeFrame(Narci_Character, 0.25, 0);
	end
end

local function PlayerModelLayerButton_OnClick(self)
	LayerButton_OnClick(self);
	local model = Narci_ModelContainer;
	model:SetShown(self.isOn);
end

local function ChangeHighlight(self)
	self.isOn = not self.isOn;
	if self.isOn then
		UnhighlightAllLayerButtons();
		self.isOn = true;
		self:LockHighlight();
		self:GetParent().Label:SetTextColor(0.88, 0.88, 0.88)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		RestoreAllLayerButtons();
		self:UnlockHighlight();
		self.isOn = false;
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end	
end

local function SetTextAlphaLayerButtonVisual(self)
	if Narci_PlayerModelLayerButton.AlphaButton.isOn then
		Narci_PlayerModelLayerButton.AlphaButton:Click();
	end
	ChangeHighlight(self);

	if self.isOn then
		FadeFrame(FullScreenAlphaChannel, 0.5, 1);
	else
		FadeFrame(FullScreenAlphaChannel, 0.5, 0);
		local SlotLayerButton = self:GetParent();
		SlotLayerButton.isOn = true;
		SlotLayerButton:LockHighlight();
		SlotLayerButton.Label:SetTextColor(0.88, 0.88, 0.88);
	end
end

local function TextAlphaLayerButton_OnClick(self)
	SetTextAlphaLayerButtonVisual(self);
	ShowTextAlphaChannel(self.isOn);
end


local function TextAlphaLayerButton_OnHide(self)
	if self.isOn then
		SetTextAlphaLayerButtonVisual(self);
		ShowTextAlphaChannel(false, true);
	end
end

local function ModelAlphaLayerButton_OnClick(self)
	if Narci_SlotLayerButton.AlphaButton.isOn then
		Narci_SlotLayerButton.AlphaButton:Click();
	end
	ChangeHighlight(self);
	Narci_ShowChromaKey(self.isOn);
	local parent = self:GetParent();
	if self.isOn then
		parent.ButtonFrame:Show();
		if not parent.lastSelectedButton then
			parent.ButtonFrame.buttons[4]:Click();	--Model Mask
		else
			parent.lastSelectedButton:Click();
		end
	else
		parent.ButtonFrame:Hide();
	end
end

local function ModelAlphaLayerButton_OnHide(self)
	if self.isOn then
		self.isOn = false;
		self:UnlockHighlight();
		self:GetParent().Label:SetTextColor(0.65, 0.65, 0.65);
	end
end

local function SlotLayerButton_OnShow(self)
	local isShown = Narci_Character:IsShown()
	self.isOn = isShown;
	HighlightButton(self, isShown);
end

local function LightsOut(state)
	local model;
	if state then
		for i = 1, #ModelFrames do
			model = ModelFrames[i];
			if model then
				model:SetFogColor(1, 1, 1);
			end
		end
	else
		for i = 1, #ModelFrames do
			model = ModelFrames[i];
			if model then
				model:ClearFog()
			end
		end
	end
end

function Narci_LayerButton_OnLoad(self)
	self.isOn = true;
	self:LockHighlight();
	local ID = self:GetID();
	local AlphaButton = self.AlphaButton;
	AlphaButton.isOn = false;
	if ID == 1 then
		--Equipment Slots Visibility
		self.Label:SetText(NARCI_EQUIPMENTSLOTS);
		self.Icon:SetTexCoord(0.5, 0.703125, 0.703125, 0.890625);
		self:SetScript("OnClick", SlotLayerButton_OnClick);
		self:SetScript("OnShow", SlotLayerButton_OnShow);
		self.tooltip = L["Toggle Equipment Slots"];

		--Use white font to replace item texts
		AlphaButton:SetScript("OnClick", TextAlphaLayerButton_OnClick);
		AlphaButton:SetScript("OnHide", TextAlphaLayerButton_OnHide);
		AlphaButton.tooltip = L["Toggle Text Mask"];
	elseif ID == 2 then
		--3D Model Visibility
		self.Label:SetText(L["3D Model"]);
		self:SetScript("OnClick", PlayerModelLayerButton_OnClick);
		self:SetScript("OnShow", function(f)
			HighlightButton(f, true);
			f.isOn = Narci_ModelContainer:IsShown();
		end)
		self.tooltip = L["Toggle 3D Model"];

		--Show chroma key (mask, green/blue screen)
		AlphaButton:SetScript("OnClick", ModelAlphaLayerButton_OnClick);
		AlphaButton:SetScript("OnHide", ModelAlphaLayerButton_OnHide);
		AlphaButton.tooltip = L["Toggle Model Mask"];

		--Create Chromakey Buttons
		local ButtonFrame = self.ButtonFrame;
		local buttons = {};

		local function SelectButton(button)
			button.Border:SetTexCoord(0.5, 1, 0, 1);
			for i = 1, 4 do
				if button ~= buttons[i] then
					buttons[i].Border:SetTexCoord(0, 0.5, 0, 1);
				end
			end
			self.lastSelectedButton = button;
		end

		local function ChromakeyButton_OnClick(button)
			SelectButton(button);
			Narci_ModelContainer.ChromaKey:SetColorTexture(button.r, button.g, button.b);
			LightsOut(false);
		end

		local function LightsOutButton_OnClick(button)
			SelectButton(button);
			Narci_ModelContainer.ChromaKey:SetColorTexture(0, 0, 0);
			button.isOn = true;
			LightsOut(true);
		end

		for i = 1, 4 do
			local button = CreateFrame("Button", nil, ButtonFrame, "Narci_RoundButtonTemplate");
			tinsert(buttons, button);
			local r, g, b;
			if i == 1 then
				button:SetPoint("RIGHT", self, "RIGHT", -10, 0);
				r, g, b = 0, 177/255, 64/255;	--Green
			else
				button:SetPoint("RIGHT", buttons[i - 1], "LEFT", 0, 0);
				if i == 2 then
					r, g, b = 0, 71/255, 187/255;	--Blue
				elseif i == 3 then
					r, g, b = 0, 0 ,0;
				elseif i == 4 then
					r, g, b = 1, 1 ,1;
				end
			end
			button.r, button.g, button.b = r, g, b;
			if i == 3 then
				r, g, b = 0.12, 0.12, 0.12;
			end
			button.Color:SetColorTexture(r, g, b);

			if i == 4 then
				button:SetScript("OnClick", LightsOutButton_OnClick);
				button:SetScript("OnHide", function(button)
					if button.isOn then
						LightsOut(false);
					end
				end);
			else
				button:SetScript("OnClick", ChromakeyButton_OnClick);
			end
		end
		ButtonFrame.buttons = buttons;

	end
	
	local Settings = self:GetParent();
	if not Settings.LayerButtons then
		Settings.LayerButtons = {};
	end
	tinsert(Settings.LayerButtons, self);

	if not Settings.AlphaButtons then
		Settings.AlphaButtons = {};
	end
	tinsert(Settings.AlphaButtons, AlphaButton);
end

function Narci_BackgroundColorButton_OnClick(self)
	Narci_ModelContainer.ChromaKey:SetColorTexture(self.r, self.g, self.b);
	self.Border:Show();
	self.Border:SetTexCoord(0.5, 1, 0, 1);
	local parent = self:GetParent();
	parent.Blue.Border:SetTexCoord(0, 0.5, 0, 1);
	parent.Black.Border:SetTexCoord(0, 0.5, 0, 1);
	local WhiteButton = parent.White;
	if WhiteButton.isOn then
		WhiteButton:Click();
	end
	parent.lastSelectedButton = self;
end

local AutoCloseTimer = C_Timer.NewTimer(0, function()	end)

function Narci_AnimationOption_MainTabButton_OnClick(self)
	AutoCloseTimer:Cancel()
	self.isOn = not self.isOn;
	if self.isOn then
		--self.Background:SetTexCoord(0, 0.376953125, 0.6328125, 0.52734375);
		self.Arrow:SetTexCoord(0, 1, 0, 1);
		self:GetParent().OtherTab:Show();
	else
		--self.Background:SetTexCoord(0, 0.376953125, 0.2109375, 0.31640625);
		self.Arrow:SetTexCoord(0, 1, 1, 0);
		self:GetParent().OtherTab:Hide();
	end
	AutoCloseTimer = C_Timer.NewTimer(5, function()
		if Narci_AnimationOptionFrame_Tab1.isOn then
			Narci_AnimationOptionFrame_Tab1:Click();
		end
	end)
end

local animationIDPresets = {
	--from right to left
	[1] = {110, 48, 109, 29, ["name"] = NARCI_RANGED_WEAPON,},
	[2] = {962, 1242, 1240, 1076, ["name"] = "Melee Animation",},	--NARCI_MELEE_WEAPON
	[3] = {124, 51, 874, 940, ["name"] = NARCI_SPELLCASTING,},
}

function Narci_AnimationOptionFrame_OnLoad(self)
	local _, _, classID = UnitClass("player");
	local ID;
	if classID == 5 or classID == 8 or classID == 9 or classID == 11 then	--spellcasting
		ID = 3;
	elseif classID == 3 then												--hunter
		ID = 1;
	else
		ID = 2;
	end
	self.tab1:SetID(ID);
	self.tab1.Label:SetText(animationIDPresets[ID]["name"]);

	local maxTab = 3;
	local otherIDs = {};

	for i=1, maxTab do
		if i ~= ID then
			tinsert(otherIDs, i)
		end
	end

	self.OtherTab.tab2:SetID(otherIDs[1]);
	self.OtherTab.tab2.Label:SetText(animationIDPresets[otherIDs[1]]["name"]);
	self.OtherTab.tab3:SetID(otherIDs[2]);
	self.OtherTab.tab3.Label:SetText(animationIDPresets[otherIDs[2]]["name"]);

	local buttons = self.buttons;
	for i=1, #buttons do
		buttons[i].ID = (animationIDPresets[ID][i]);
	end

	NarciPhotoModeBar_OnLoad(self);
end

function Narci_AnimationOption_OtherTabButton_OnClick(self)
	local ID = self:GetID();
	local tab1 = self:GetParent():GetParent().tab1;
	local activeID = tab1:GetID();
	local buttons = self:GetParent():GetParent().buttons;
	local animationID;
	for i=1, #buttons do
		buttons[i].ID = (animationIDPresets[ID][i]);
		buttons[i].animOut:Play();
	end

	self:SetID(activeID);
	self.Label:SetText(animationIDPresets[activeID]["name"]);
	tab1:SetID(ID);
	tab1.Label:SetText(animationIDPresets[ID]["name"]);
	tab1:Click();
end

function Narci_AnimationPresetButton_OnClick(self, button)
	local id = self.ID;
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	model:PlayAnimation(id);
	if button == "RightButton" then
		AnimationIDEditBox:SetAnimationID(id);
	end

	local buttons = self:GetParent().buttons;
	for i=1, #buttons do
		buttons[i].Highlight:Hide();
		buttons[i].isOn = false;
	end
	self.isOn = true;
	self.Highlight:Show();
end

function Narci_Model_DarknessSlider_OnValueChanged(self, value, isUserInput)
    self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)
    if value ~= self.oldValue then
		self.oldValue = value
		Narci_BackgroundDarkness:Show();
		Narci_BackgroundDarkness:SetAlpha(value);
    end
end

function Narci_Model_VignetteSlider_OnValueChanged(self, value, isUserInput)
    self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)
    if value ~= self.oldValue then
		self.oldValue = value
		Narci_VignetteLeft:SetAlpha(value);
		Narci_VignetteRightLarge:SetAlpha(value);
		Narci_VignetteRightSmall:SetAlpha(value);
		Narci_PlayerModelGuideFrame.VignetteRightSmall:SetAlpha(value);
    end
end

function Narci_Model_UseCompactMode_OnClick(self)
	self.isOn = not self.isOn;
	if self.isOn then
		HighlightButton(self, true);
		if not Narci_HidePlayerButton.isOn then
			Narci_HidePlayerButton:Click();
		end
	else
		HighlightButton(self, false);
		if Narci_HidePlayerButton.isOn then
			Narci_HidePlayerButton:Click();
		end
	end
	Narci_Xmog_UseCompactMode(self.isOn);
end

function Narci_Model_HidePlayer_OnClick(self)
	self.isOn = not self.isOn;
	ConsoleExec("showPlayer");
	HighlightButton(self, self.isOn);
end

function Narci_ModelShadow_SizeSlider_OnValueChanged(self, value, isUserInput)
    self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)
    if value ~= self.oldValue then
		self.oldValue = value;
		if not self.shadows then
			self.shadows = self:GetParent():GetParent().ShadowTextures;
		end
		self.shadows:SetScale(value);
    end
end

function Narci_ModelShadow_AlphaSlider_OnValueChanged(self, value, isUserInput)
    self.VirtualThumb:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)
    if value ~= self.oldValue then
		self.oldValue = value;
		if not self.shadow1 then
			self.shadow1 = self:GetParent():GetParent().ShadowTextures.Shadow;
		end
		if not self.shadow2 then
			self.shadow2 = self:GetParent():GetParent().ShadowTextures.RadialShadow;
		end
		self.shadow1:SetAlpha(value);
		self.shadow2:SetAlpha(value);
    end
end




-------------------------
---- Custom Lighting ----
-------------------------
local LightData = {};

function LightData:SetAmbientMode(state)
	self.ambientMode = state;
end

function LightData:SetLightDirection(dirX, dirY, dirZ)
	self.dirX, self.dirY, self.dirZ = dirX, dirY, dirZ;
end

function LightData:GetLightDirection()
	return self.dirX, self.dirY, self.dirZ;
end

function LightData:SetAmbientColor(r, g, b)
	self.ambR, self.ambG, self.ambB = r, g, b;
end

function LightData:GetAmbientColor()
	return self.ambR, self.ambG, self.ambB;
end

function LightData:SetDiffuseColor(r, g, b)
	self.dirR, self.dirG, self.dirB = r, g, b;
end

function LightData:GetDiffuseColor()
	return self.dirR, self.dirG, self.dirB;
end

function LightData:Set(dirX, dirY, dirZ, dirR, dirG, dirB, ambR, ambG, ambB)
	self:SetLightDirection(dirX, dirY, dirZ);
	self:SetDiffuseColor(dirR, dirG, dirB);
	self:SetAmbientColor(ambR, ambG, ambB);
end

local XdirX, XdirY, XdirZ, XdirR, XdirG, XdirB;

local function SetLightViewerColor(r, g, b)
	if LightControl.ambientMode then
		BasicPanel.TopView.AmbientColor:SetColorTexture(r, g, b, 0.6);
		BasicPanel.LeftView.AmbientColor:SetColorTexture(r, g, b, 0.6);
	else
		BasicPanel.TopView.LightColor:SetVertexColor(r, g, b, 0.6);
		BasicPanel.LeftView.LightColor:SetVertexColor(r, g, b, 0.6);
	end
end

local function ShowHighlightBorder(border)
	border:SetTexCoord(0.5, 1, 0, 1);
end

local function HideHighlightBorder(border)
	border:SetTexCoord(0, 0.5, 0, 1);
end

function Narci_LightColorButton_OnClick(self)
	--Change Light Color--
	local H, S, V = RGB2HSV(self.r, self.g, self.b);
	local ColorSliders = BasicPanel.ColorSliders;
	if H then ColorSliders.HueSlider:SetValue(H, true); end
	if S then ColorSliders.SaturationSlider:SetValue(S, true); end
	if V then ColorSliders.BrightnessSlider:SetValue(V, true); end

	SetLightViewerColor(self.r/255, self.g/255, self.b/255);

	local ColorButtons = self:GetParent().Colors;
	for i=1, #ColorButtons do
		HideHighlightBorder(ColorButtons[i].Border);
	end
	ShowHighlightBorder(self.Border);
end

function Narci_LightColorButton_OnLoad(self)
	local r, g, b = 0, 0, 0;
	local id = self:GetID();

	if id == 1 then
		r, g, b = 204, 204, 204;
	elseif id == 2 then
		r, g, b = 0.65*255, 0.45*255, 0.7*255; --
	elseif id == 3 then
		r, g, b = 140, 70, 70
	elseif id == 4 then
		r, g, b = 220, 173, 83; --
	elseif id == 5 then
		r, g, b = 80, 186, 141;
	elseif id == 6 then
		r, g, b = 0, 174, 239;
	elseif id == 7 then
		r, g, b = 40, 124, 186; --
 	elseif id == 8 then
		r, g, b = 70, 61, 220;
	end

	self.r = r;
	self.g = g;
	self.b = b;

	self.Color:SetColorTexture(r / 255, g / 255, b / 255, 1);

	if not self:GetParent().Colors then
		self:GetParent().Colors = {};
	end
	tinsert(self:GetParent().Colors, self)
end




---------------------------
---------------------------
---------------------------
local LayersToBeCaptured = -1;
local Temps = {
	Alpha1 = 1,
	Alpha2 = 1,
	Vignette = 0,
	Brightness = 0,
	HidePlayer = false,
};

local function PauseAllModel(bool)
	for i = 1, #ModelFrames do
		ModelFrames[i]:SetPaused(bool);
	end
end

local function StartAutoCapture()
	local model = Narci_ModelContainer;
	local r1, g1, b1 = 0, 177/255, 64/255;
	local r2, g2, b2 = 0, 71/255, 187/255;

	if LayersToBeCaptured == 6 then
		PauseAllModel(true);
		Temps.TextOverlayVisibility = NarciTextOverlayContainer:IsShown();
		NarciTextOverlayContainer:Hide();
		Temps.HidePlayer = Narci_HidePlayerButton.isOn;
		if not Temps.HidePlayer then
			Narci_HidePlayerButton:Click();
		end
		Temps.Vignette = Narci_Model_VignetteSlider:GetValue();
		Temps.Brightness = Narci_Model_DarknessSlider:GetValue();
		Narci_Model_VignetteSlider:SetValue(0);
		Narci_Model_DarknessSlider:SetValue(0);
		Narci_Character:Hide();
		model:Hide();
	elseif LayersToBeCaptured == 5 then
		model:Show();
		FullSceenChromaKey:SetColorTexture(0, 0, 0);
		FullSceenChromaKey:Show();
		FullSceenChromaKey:SetAlpha(1);
		LightsOut(true);
	elseif LayersToBeCaptured == 4 then
		LightsOut(false);
		model:Show();
		FullSceenChromaKey:SetColorTexture(r1, g1, b1);
		FullSceenChromaKey:Show();
		FullSceenChromaKey:SetAlpha(1);
	elseif LayersToBeCaptured == 3 then
		model:Show();
		FullSceenChromaKey:SetColorTexture(r2, g2, b2);
		FullSceenChromaKey:Show();
		FullSceenChromaKey:SetAlpha(1);
	elseif LayersToBeCaptured == 2 then
		model:Hide();
		FullSceenChromaKey:Hide();
		FullSceenChromaKey:SetAlpha(0);
		ShowTextAlphaChannel(true);
		FullScreenAlphaChannel:SetAlpha(1);
		FullScreenAlphaChannel:Show();
	elseif LayersToBeCaptured == 1 then
		ShowTextAlphaChannel(false);
		FullScreenAlphaChannel:SetAlpha(1);
		FullScreenAlphaChannel:Show();
		model:Hide();
	elseif LayersToBeCaptured == 0 then
		Narci_Model_VignetteSlider:SetValue(Temps.Vignette);
		Narci_Model_DarknessSlider:SetValue(Temps.Brightness);
		if Temps.TextOverlayVisibility then
			 NarciTextOverlayContainer:Show();
		end
		model:Show();
		FullScreenAlphaChannel:SetAlpha(0);
		FullScreenAlphaChannel:Hide();
		if not Temps.HidePlayer then
			Narci_HidePlayerButton:Click();
		end
		LayersToBeCaptured = -1;
		Narci_Model_CaptureButton.Value:SetText(0);
		Narci_Model_CaptureButton:Enable();
		local button = Narci_SlotLayerButton;
		button:LockHighlight();
		button.Label:SetTextColor(0.8, 0.8, 0.8);
		button.isOn = true;
		PauseAllModel(false);
		return;
	else
		LayersToBeCaptured = -1;
		Narci_Model_CaptureButton.Value:SetText(0);
		Narci_Model_CaptureButton:Enable();
		PauseAllModel(false);
		return;
	end
	After(1, function()
		Screenshot();
	end)
	Narci_Model_CaptureButton.Value:SetText(LayersToBeCaptured);
	LayersToBeCaptured = LayersToBeCaptured - 1;
end

local NUM_CAPTURE = 6;
function Narci_Model_CaptureButton_OnClick(self)
	self:Disable()
	PauseAllModel(true);
	tooltip:Hide();
	Narci_Character:Hide();
	Narci_VignetteLeft:SetAlpha(0);
	Narci_VignetteRightSmall:SetAlpha(0);
	LayersToBeCaptured = NUM_CAPTURE;
	Screenshot();
end

function Narci_Model_CaptureButton_OnEnter(self)
	if LayersToBeCaptured == -1 then
		Narci_Model_CaptureButton.Value:SetText(NUM_CAPTURE);
		tooltip:ShowTooltip(self);
	end
end

function Narci_Model_CaptureButton_OnLeave(self)
	if LayersToBeCaptured == -1 then
		Narci_Model_CaptureButton.Value:SetText(0);
		tooltip:FadeOut();
	end
end


--[[
-----------------
-------API-------
-----------------

SetShadowEffect(0~1)	--Transparent



function SM(path)
	path = tostring(path)
	path = gsub(path, "%/", "\\".."\\")
	print(path)
	PrimaryPlayerModel:SetModel(path)
end

function EQ(id)
	local _, itemLink = GetItemInfo(id)
	PrimaryPlayerModel:TryOn(itemLink)
end

function SV(id)
	PrimaryPlayerModel:ApplySpellVisualKit(id, false)
end
--]]




-----------------------------------------------------------------------------

NarciAnimationIDEditboxMixin = {};

function NarciAnimationIDEditboxMixin:OnLoad()
	self.isOn = false;
	self:SetAnimationID(0);
	self.Highlight:SetAlpha(0);
	self.FavoriteButton = self:GetParent().FavoriteButton;
	self:SetHighlightColor(0, 0, 0);
	AnimationIDEditBox = self;
	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

function NarciAnimationIDEditboxMixin:OnMouseWheel(delta)
	local id = self:GetNumber();
	if id > maxAnimationID then
		id = maxAnimationID;
	end
	local model = ModelFrames[ACTIVE_MODEL_INDEX];

	if delta < 0 and id < maxAnimationID then
		id = id + 1;
		while (not model:HasAnimation(id)) and id < maxAnimationID do
			id = id + 1;
		end
	elseif delta > 0 and id > 0 then
		id = id - 1;
		while (not model:HasAnimation(id)) and id > 0 do
			id = id - 1;
		end
	end

	self.isOn = true;

	model:PlayAnimation(id);

	if not self.hasWheeled then
		self.hasWheeled = true;
		DisablePauseButton();
		self.MouseButton:FadeOut();
	end

	self:SetAnimationID(id);
end

function NarciAnimationIDEditboxMixin:SetAnimationID(id)
	self:SetNumber(id);
	self.IDFrame.Label:SetText( NarciAnimationInfo.GetOfficialName(id) );
end

function NarciAnimationIDEditboxMixin:OnEnterPressed()
	self.Highlight:SetAlpha(0);
	
	if not self:GetText() then
		self:ClearFocus();
		return;
	else
		self:ClearFocus();
	end

	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local id = math.min(self:GetNumber(), maxAnimationID);
	model.animationID = id;

	if model.isPaused then
		NarciModelControl_AnimationSlider:SetValue(0, true);
	else
		model:PlayAnimation(id);
	end
end

function NarciAnimationIDEditboxMixin:OnEditFocusLost()
	self:HighlightText(0,0);
	self.Highlight:SetAlpha(0);
	local ID = tonumber(self:GetText());
	if not ID then
		self:SetText(self.oldID);
	elseif ID > maxAnimationID then
		self:SetText(maxAnimationID);
	end
	self.Timer:Stop();
end

function NarciAnimationIDEditboxMixin:OnEditFocusGained()
	self.oldID = self:GetNumber();
	self:HighlightText();
end

function NarciAnimationIDEditboxMixin:OnEnter()
	self.Timer:Stop();
	FadeFrame(self.Highlight, 0.2, 1);
	self.IDFrame:Show();
	self.MouseButton:ShowTooltip();
end

function NarciAnimationIDEditboxMixin:OnLeave()
	if not self:HasFocus() then
		FadeFrame(self.Highlight, 0.2, 0);
	else
		self.Timer:Play();
	end
	self.hasWheeled = nil;
	self.IDFrame:Hide();
	self.MouseButton:FadeOut();
end

function NarciAnimationIDEditboxMixin:OnTextChanged()
	self.Timer:Stop();
	local id = self:GetNumber();
	self.IDFrame.Label:SetText( NarciAnimationInfo.GetOfficialName(id) );
	self.FavoriteButton:UpdateStatus(id);
end

function NarciAnimationIDEditboxMixin:OnEscapePressed()
	self:ClearFocus();
end

function NarciAnimationIDEditboxMixin:OnSpacePressed()
	self:HighlightText();
end

function NarciAnimationIDEditboxMixin:OnHide()
	self:ClearFocus();
end


NarciAnimationVariationSphereMixin = {};

function NarciAnimationVariationSphereMixin:SetVisual(variationID)
	local left = variationID * 0.25;
	self.Icon:SetTexCoord(left, left + 0.25, 0, 1);
	self.variationID = variationID;
end

function NarciAnimationVariationSphereMixin:OnLoad()
	self.maxVariations = 3;	-- 0, 1, 2, 3
	self.Icon:SetSize(12, 12);
	self.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Widgets/ModelAnimation/VariationSphere", nil, nil, "TRILINEAR");
	self:SetVisual(0);
	self.tooltip = L["Animation Variation"];
end

function NarciAnimationVariationSphereMixin:OnEnter()
	self.Icon:SetSize(14, 14);
	NarciTooltip:ShowTooltip(self, 0, nil, 1);
end

function NarciAnimationVariationSphereMixin:OnLeave()
	self.Icon:SetSize(12, 12);
	NarciTooltip:FadeOut();
end

function NarciAnimationVariationSphereMixin:OnClick(button)
	local newVariationID;

	if button == "LeftButton" then
		if self.variationID < self.maxVariations then
			newVariationID = self.variationID + 1;
		else
			newVariationID = 0;
		end
	else
		if self.variationID > 0 then
			newVariationID = self.variationID - 1;
		else
			newVariationID = self.maxVariations;
		end
	end

	self:SetVisual(newVariationID);

	---Update Model Animation
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local animationID = AnimationIDEditBox:GetNumber();
	if model.isPaused then
		model.variationID = newVariationID;
		NarciModelControl_AnimationSlider:SetValue(model.freezedFrame or 0, true);
	else
		model:PlayAnimation(animationID, newVariationID);
	end
end

function NarciAnimationVariationSphereMixin:OnMouseDown()

end


NarciFavoriteStarMixin = {};

function NarciFavoriteStarMixin:OnLoad()
	self.Icon:SetSize(16, 16);
	self.Star:SetSize(16, 16);
	self.Star:SetTexCoord(0.25, 0.5, 0, 1);
	local file = "Interface/AddOns/Narcissus/Art/Widgets/SpellVisualBrowser/Favorites.tga";
	self.Icon:SetTexture(file, nil, nil, "LINEAR");	--TRILINEAR
	self.Star:SetTexture(file, nil, nil, "LINEAR");

	local isFavorite = false;
	self:SetVisual(isFavorite);

	local HollowStar = self:GetParent().ExpandButton.Star;
	--HollowStar:ClearAllPoints();
	--HollowStar:SetPoint("CENTER", self.Star, "CENTER", 0, 0);

	self.flyOut1 = self.Star.flyOut;
	self.flyOut2 = HollowStar.flyOut;
end

function NarciFavoriteStarMixin:OnEnter()
	self:SetAlpha(1);
	if self.isFavorite then
		NarciTooltip:NewText(L["Favorites Remove"], nil, nil, 1);
	else
		NarciTooltip:NewText(L["Favorites Add"], nil, nil, 1);
	end
end

function NarciFavoriteStarMixin:OnLeave()
	if not self.isFavorite then
		self:SetAlpha(0.6);
	end
	NarciTooltip:FadeOut();
end

function NarciFavoriteStarMixin:OnMouseDown()
	self.Icon:SetSize(14, 14);
end

function NarciFavoriteStarMixin:OnMouseUp()
	self.Icon:SetSize(16, 16);
end

function NarciFavoriteStarMixin:PlayStarAnimation()
	self.flyOut1:Stop();
	self.flyOut2:Stop();
	self.flyOut1:Play();
	self.flyOut2:Play();
end

function NarciFavoriteStarMixin:SetVisual(isFavorite)
	self.isFavorite = isFavorite;
	if isFavorite then
		self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
		self:SetAlpha(1);
	else
		self.Icon:SetTexCoord(0, 0.25, 0, 1);
		self:SetAlpha(0.6);
	end
end

function NarciFavoriteStarMixin:UpdateStatus(id)
	local isFavorite = NarciAnimationInfo.IsFavorite(id);
	self:SetVisual(isFavorite);
end

function NarciFavoriteStarMixin:OnClick()
	local isFavorite = not self.isFavorite;
	self:SetVisual(isFavorite);

	local id = AnimationIDEditBox:GetNumber();
	if isFavorite then
		NarciAnimationInfo.AddFavorite(id);
		self:PlayStarAnimation();
	else
		NarciAnimationInfo.RemoveFavorite(id);
	end
	Narci_AnimationBrowser:RefreshFavorite(id);
end

function NarciFavoriteStarMixin:OnDoubleClick()

end
-----------------------------------------------------------------------------

function NarciModelControl_PlayAnimationButton_OnClick(self, button)
	AnimationIDEditBox:ClearFocus();
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local id = AnimationIDEditBox:GetNumber();
	model:PlayAnimation(id);
	if button == "LeftButton" then
		model:SetPaused(false);
	else
		PauseAllModel(false);
	end
	DisablePauseButton();
end

function NarciModelControl_PauseAnimationButton_OnClick(self, button)
	AnimationIDEditBox:ClearFocus();
	local model = ModelFrames[ACTIVE_MODEL_INDEX]
	local id = AnimationIDEditBox:GetNumber();
	model:Freeze(id, nil, model.freezedFrame or 0);
	if button == "RightButton" then
		PauseAllModel(true);
	end
	DisablePlayButton();
end

local xR, xG, xB = 1, 0, 0;		--Spot Light: red, green, blue, stauration
local xHUE = 0;
local xSAT = 0;					--Spot Light: stauration
local xBRT = 1;					--Spot Light: brightness 100%

local aHue, aSAT, aBRT = 0, 0, 0.8;
local sHue, sSAT, sBRT = 0, 0, 0.8;

local function PlayLightBling(index)
	if index == 1 then
		BasicPanel.LeftView.LightColor.Bling:Play();
		BasicPanel.TopView.LightColor.Bling:Play();
	else
		BasicPanel.LeftView.AmbientColor.Bling:Play();
		BasicPanel.TopView.AmbientColor.Bling:Play();
	end
end

function NarciModelControl_LightSwitch_OnClick(self)
	local isAmbientMode = not LightControl.ambientMode;
	LightControl.ambientMode = isAmbientMode;

	local ColorSliders = BasicPanel.ColorSliders;
	local BAK1 = ColorSliders.HueSlider:GetValue();
	local BAK2 = ColorSliders.SaturationSlider:GetValue();
	local BAK3 = ColorSliders.BrightnessSlider:GetValue();

	if isAmbientMode then
		sHue = BAK1;
		sSAT = BAK2;
		sBRT = BAK3;
		ColorSliders.HueSlider:SetValue(aHue)
		ColorSliders.SaturationSlider:SetValue(aSAT);
		ColorSliders.BrightnessSlider:SetValue(aBRT);
		PlayLightBling(2)
		self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
	else
		aHue = BAK1;
		aSAT = BAK2;
		aBRT = BAK3;
		ColorSliders.HueSlider:SetValue(sHue)
		ColorSliders.SaturationSlider:SetValue(sSAT);
		ColorSliders.BrightnessSlider:SetValue(sBRT);
		PlayLightBling(1)
		self.Icon:SetTexCoord(0, 0.25, 0, 1);
	end
end

local CPSA = CreateFrame("Frame");	--Color Pane Switch Animation
CPSA:Hide();
CPSA.t = 0
CPSA.duration = 0.15;
local function ColorPaneSwitchAnim_Update(self, elapsed)
	self.t = self.t + elapsed
	local height = outSine(self.t, self.StartHeight, self.EndHeight - self.StartHeight, self.duration);

	NarciModelControl_BrightnessSlider:SetHeight(height)
	if self.t > self.duration then
		self:Hide();
	end
end

CPSA:SetScript("OnUpdate", ColorPaneSwitchAnim_Update);
CPSA:SetScript("OnHide", function(self)
	self.t = 0;
end);
CPSA:SetScript("OnShow", function(self)
	self.StartHeight = NarciModelControl_BrightnessSlider:GetHeight();
	self.EndHeight = self.EndHeight or 12;
end);

function NarciModelControl_ColorPaneSwitch_OnClick(self)
	--local defaultHeight = 278;
	self.ShowSlider = not self.ShowSlider;
	local state = self:GetParent().ColorPresets:IsShown();
	local Colors = self:GetParent().ColorPresets;
	local Sliders = self:GetParent().ColorSliders;
	if not self.ShowSlider then
		--Presets
		self.tooltip = L["Show Color Sliders"];
		FadeFrame(Sliders, 0.1, 0);
		FadeFrame(Colors, 0.1, 1);
		self.Icon:SetTexCoord(0, 0.25, 0.25, 0.5);
		self:GetParent():SetHitRectInsets(-60, -60, -60, -60);
		CPSA:Hide();
		CPSA.EndHeight = 0.001;
		CPSA:Show();
	else
		--Sliders
		self.tooltip = L["Show Color Presets"];
		local ExtraHeight = 12;
		FadeFrame(Sliders, 0.1, 1);
		FadeFrame(Colors, 0.1, 0);
		self.Icon:SetTexCoord(0.75, 1, 0, 0.25);
		self:GetParent().padding = ExtraHeight + 40;
		CPSA:Hide();
		CPSA.EndHeight = ExtraHeight;
		CPSA:Show();
	end
end


function LightControl:Initialize(newModel)
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB = model:GetLight();
	newModel:SetLight(true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
end

function LightControl:UpdateLight()
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local r, g, b = HSV2RGB(xHUE, xSAT, xBRT);
	local _;
	if self.linkLight then
		if self.ambientMode then
			_, _, XdirX, XdirY, XdirZ, _, _, _, _, _, XdirR, XdirG, XdirB = model:GetLight();
			for i = 1, #ModelFrames do
				ModelFrames[i]:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r, g, b, 1, XdirR, XdirG, XdirB);
			end
		else
			local r0, g0, b0;
			_, _, XdirX, XdirY, XdirZ, _, r0, g0, b0, _, XdirR, XdirG, XdirB = model:GetLight();
			for i = 1, #ModelFrames do
				ModelFrames[i]:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r0, g0, b0, 1, r, g, b);
			end
		end
	else
		if self.ambientMode then
			_, _, XdirX, XdirY, XdirZ, _, _, _, _, _, XdirR, XdirG, XdirB = model:GetLight();
			model:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r, g, b, 1, XdirR, XdirG, XdirB);
		else
			local r0, g0, b0;
			_, _, XdirX, XdirY, XdirZ, _, r0, g0, b0, _, XdirR, XdirG, XdirB = model:GetLight();
			model:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r0, g0, b0, 1, r, g, b);
		end
	end
	SetLightViewerColor(r, g, b);
end

local function InitializeModelLight(newModel)
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local r, g, b = HSV2RGB(xHUE, xSAT, xBRT);
	local _;
	if LINK_LIGHT then
		newModel:SetLight(model:GetLight());
		--[[
		if LightControl.ambientMode then
			_, _, XdirX, XdirY, XdirZ, _, _, _, _, _, XdirR, XdirG, XdirB = model:GetLight();
			newModel:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r, g, b, 1, XdirR, XdirG, XdirB);
		else
			local r0, g0, b0;
			_, _, XdirX, XdirY, XdirZ, _, r0, g0, b0, _, XdirR, XdirG, XdirB = model:GetLight();
			newModel:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r0, g0, b0, 1, r, g, b);
		end
		--]]
	end
end

local function SetModelLightColor()
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local r, g, b = HSV2RGB(xHUE, xSAT, xBRT);
	local _;
	if LINK_LIGHT then
		if LightControl.ambientMode then
			_, _, XdirX, XdirY, XdirZ, _, _, _, _, _, XdirR, XdirG, XdirB = model:GetLight();
			for i = 1, #ModelFrames do
				ModelFrames[i]:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r, g, b, 1, XdirR, XdirG, XdirB);
			end
		else
			local r0, g0, b0;
			_, _, XdirX, XdirY, XdirZ, _, r0, g0, b0, _, XdirR, XdirG, XdirB = model:GetLight();
			for i = 1, #ModelFrames do
				ModelFrames[i]:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r0, g0, b0, 1, r, g, b);
			end
		end
	else
		if LightControl.ambientMode then
			_, _, XdirX, XdirY, XdirZ, _, _, _, _, _, XdirR, XdirG, XdirB = model:GetLight();
			model:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r, g, b, 1, XdirR, XdirG, XdirB);
		else
			local r0, g0, b0;
			_, _, XdirX, XdirY, XdirZ, _, r0, g0, b0, _, XdirR, XdirG, XdirB = model:GetLight();
			model:SetLight(true, false, XdirX, XdirY, XdirZ, 1, r0, g0, b0, 1, r, g, b);
		end
	end
	SetLightViewerColor(r, g, b);
end

function NarciModelControl_HueSlider_OnValueChanged(self, value, isUserInput)
	if value ~= self.oldValue then
		self.oldValue = value;
		xHUE = value;
		
		value = value/60;
		if value <= 1 then
			xR, xG, xB = 1, value, 0;
		elseif value > 1 and value <= 2 then
			xR, xG, xB = 2 - value, 1, 0;
		elseif value > 2 and value <= 3 then
			xR, xG, xB = 0, 1, value - 2;
		elseif value > 3 and value <= 4 then
			xR, xG, xB = 0, 4 - value, 1;
		elseif value > 4 and value <= 5 then
			xR, xG, xB = value - 4, 0, 1;
		else
			xR, xG, xB = 1, 0, 6 - value;
		end
		

		NarciModelControl_SaturationSlider.Color:SetGradient("HORIZONTAL", 1, 1, 1, xR, xG, xB);
		NarciModelControl_BrightnessSlider.Color:SetGradient("HORIZONTAL", 0, 0, 0, xR + (1-xSAT), xG + (1-xSAT), xB + (1-xSAT));

		if isUserInput then
			SetModelLightColor();
			if self:GetParent():IsShown() then
				self.Thumb:SetTexCoord(0.96875, 1, 0, 0.0625);
			end;
		end
    end
end

function NarciModelControl_SaturationSlider_OnValueChanged(self, value, isUserInput)
	if value ~= self.oldValue then
		self.oldValue = value;
		xSAT = value;

		NarciModelControl_BrightnessSlider.Color:SetGradient("HORIZONTAL", 0, 0, 0, xR + (1-xSAT), xG + (1-xSAT), xB + (1-xSAT));

		if isUserInput then
			SetModelLightColor();
			if self:GetParent():IsShown() then
				self.Thumb:SetTexCoord(0.96875, 1, 0.0625, 0);
			end
		end
	end
end

function NarciModelControl_BrightnessSlider_OnValueChanged(self, value, isUserInput)
	if value ~= self.oldValue then
		self.oldValue = value;
		xBRT = value;

		if isUserInput then
			SetModelLightColor();
			if self:GetParent():IsShown() then
				self.Thumb:SetTexCoord(0.96875, 1, 0.0625, 0.125);
			end
		end
	end
end

------------------------------------------------------------
------------------------Actor Panel-------------------------
--Race/gender change, Active Model, Synchronize light/size--
------------------------------------------------------------
local RaceList = {
	1, 3, 4, 7, 11, 22,
	29, 30, 34, 32, 37, 24,
	2, 5, 6, 8, 10, 9,
	27, 28, 36, 31, 35, 24,
};

local function SwitchPortrait(index, unit, fromBrowser)
	local Portraits = ActorPanel.ActorButton;
	local portrait = Portraits["Portrait"..index];
	for i = 1, NUM_MAX_ACTORS do
		Portraits["Portrait"..i]:Hide();
	end
	if unit then
		SetPortraitTexture(portrait, unit);
		portrait:SetTexCoord(0, 1, 0, 1);
	elseif fromBrowser then
		portrait:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\ActorPanel\\Dummy.blp");
		portrait:SetTexCoord(0, 1, 0, 1);
	end
	portrait:Show();
end

local function ModelIndexButton_ResetReposition()
	--Reset Model Index Buttons' position--
	IndexButtonPosition = {
		1, 2, 3, 4, 5, 6, 7, 8,
	};
	local buttons = ActorPanel.ExtraPanel.buttons;
	local relativeTo = ActorPanel.ExtraPanel.ReferenceFrame;
	local offset;
	for i = 1, #buttons do
		local button = buttons[i];
		button.order = i;
		offset = (button.order - 1) * 24;	--button width = 24
		buttons[i]:ClearAllPoints();
		buttons[i]:SetPoint("LEFT", relativeTo, "LEFT", offset, 0);
	end
end

local function ResetIndexButton()
	local buttons = ActorPanel.ExtraPanel.buttons;
	local button = buttons[1];
	button.hasModel = true;
	button.isModelHidden = false;
	button.order = 1;
	button.isOn = true;
	button.ID:Show();
	button.Icon:Hide();
	button.Icon:SetTexCoord(0, 0.25, 0, 1);
	button:SetModelType("player");
	button:SetSelection(true);
	for i = 2, #buttons do
		button = buttons[i];
		button.ID:Hide();
		button.Icon:SetTexCoord(0, 0.25, 0, 1);
		button.Icon:Show();
		button.Border:SetTexCoord(0.875, 1, 0, 0.5)
		button:Hide();
		button.hasModel = false;
		button.isModelHidden = false;
		button.isOn = false;
		button.Highlight:Hide();
		button.order = i;
		button:SetSelection(false);
	end

	buttons[2]:Show();
	SwitchPortrait(1);
	UpdateActorName(1);
	ModelIndexButton_ResetReposition();
end

local function ExitGroupPhoto()
	ACTIVE_MODEL_INDEX = 1;
	local model = PrimaryPlayerModel;
	Narci.ActiveModel = model;
	--model:SetActive(true);
	model.GroundShadow:Hide();
	local panel = ActorPanel;
	panel.ExpandButton:Show();
	panel.ExpandButton:SetAlpha(1);
	panel.ExtraPanel:Hide();
	panel.ActorButton.ActorName:SetWidth(96);

	local NameFrame = panel.NameFrame;
	NameFrame.NameBackground:SetPoint("LEFT", -96, 0);
	NameFrame.HiddenFrames:Hide();

	local SlotLayerButton = Narci_SlotLayerButton;
	SlotLayerButton.isOn = true;
	HighlightButton(SlotLayerButton, true);

	ModelFrames[1] = PrimaryPlayerModel;
end

local function ShowIndexButtonLabel(self, bool)
	self.Label:SetShown(bool);
	self.Status:SetShown(bool);
	self.LabelColor:SetShown(bool);
end

local function ShakeModel(model)
	local facing = model:GetFacing();
	model:SetRotation(facing + 0.07);
	After(0.15, function()
		model:SetRotation(facing);
	end)
end

local function SetModelActive(index)
	ACTIVE_MODEL_INDEX = index or 1;
	for i = 1, #ModelFrames do
		if i ~= ACTIVE_MODEL_INDEX and ModelFrames[i] then
			ModelFrames[i]:SetActive(false);
		end
	end

	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	if not model then return; end;
	Narci.ActiveModel = model;
	model:SetActive(true);
	model:MakeCurrentCameraCustom();
	local shadowFrame = model.GroundShadow;
	shadowFrame:EnableMouse(true);
	shadowFrame.Option:SetAlpha(1);
	shadowFrame.Option:Show();
	AnimationIDEditBox:SetAnimationID(model.animationID or 0);
	NarciModelControl_AnimationVariationButton:SetVisual(model.variationID or 0);

	--Update Virtual Toggle Status
	local VirtualToggle = Narci_VirtualActorToggle;
	if model:GetModelAlpha() == 1 then
		VirtualToggle.isOn = false;
		VirtualToggle.Icon:Hide();
	else
		VirtualToggle.isOn = true;
		VirtualToggle.Icon:Show();
	end
	
	--Load Spell Visual History
	NarciSpellVisualBrowser:LoadHistory();

	--Update Play/Pause Button
	if model.isPaused then
		DisablePlayButton();
		NarciModelControl_AnimationSlider:SetValue(model.freezedFrame or 0, true)
	else
		DisablePauseButton();
	end

	LightControl:SetLightWidgetFromActiveModel();

	if model:IsObjectType("DressUpModel") then
		OutfitToggle:EnableButton();
		NarciPhotoModeOutfitSelect:SelectPreviewModel(model.buttonIndex);
	else
		OutfitToggle:DisableButton();
	end
end

function Narci_ModelIndexButton_OnClick(self, button)
	--Functionality
	local unit = "target";
	local ID = self:GetID();
	local playBling = true;
	local model = ModelFrames[ID];
	local buttons = self:GetParent().buttons;
	ACTIVE_MODEL_INDEX = ID;

	if not self.hasModel then
		if UnitExists(unit) then
			local isPlayer = UnitIsPlayer(unit);
			local alternateMode = IsAltKeyDown();
			if isPlayer and not alternateMode then
				model = _G["NarciPlayerModelFrame"..ID];
			else
				model = _G["NarciNPCModelFrame"..ID];
			end
		
			if not model then
				if isPlayer and not alternateMode then
					model = CreateFrame("DressUpModel", "NarciPlayerModelFrame"..ID, Narci_ModelContainer, "Narci_CharacterModelFrame_Template");
				else
					model = CreateFrame("CinematicModel", "NarciNPCModelFrame"..ID, Narci_ModelContainer, "Narci_NPCModelFrame_Template");
				end
				model:SetID(ID);
				NarciModelControl_AnimationSlider:ResetValueVisual();
			end
			model.buttonIndex = ID;
			model.isPlayer = isPlayer;
			model.isVirtual = false;
			ModelFrames[ID] = model;
			SwitchPortrait(ID, unit);
			model.isModelLoaded = false;
			model:SetUnit(unit);
			model.race, model.gender = InitializePlayerInfo(ID, unit);
			ResetModelPosition(model);
			InitializeModelLight(model);
			
			self.hasModel = true;
			playBling = false;

			if buttons[ID + 1] then
				buttons[ID + 1]:Show();
			end

			if isPlayer then
				self:SetModelType("player");
				NarciPhotoModeOutfitSelect:AddPlayerActor(unit, model);
			else
				self:SetModelType("npc");
			end
			--Fix Weapons
			WeaponUpdator:GetTargetWeapons(unit);
		else
			local PopUp = self:GetParent().PopUp;
			PopUp.AddTarget.Text.animError:Play();
			Narci:PlayVoice("ERROR");
			return;
		end
	end
	model:SetFrameLevel(14 - self.order);

	--Visual
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	for i = 1, #buttons do
		buttons[i]:SetSelection(i == ID);
	end

	SwitchPortrait(ID);
	UpdateActorName(ID);
	SetGenderIcon(playerInfo[ID].gender);

	if model then
		if button == "LeftButton" then
			--Left click to activate model
			if not self.isModelHidden then
				if playBling then
					--give some visual feedback to tell which model has just been activated
					ShakeModel(model);
				end
				local state = true;
				model:EnableMouse(state);
				model:EnableMouseWheel(state);
				model:Show();
				self.ID:Show();
				self.Icon:Hide();
			end
		elseif button == "RightButton" then
			--Right click to hide model
			local state;
			if not self.isModelHidden then
				state = false;
				self.ID:Hide();
				self.Icon:SetTexCoord(0.5, 0.75, 0, 1);
				self.isModelHidden = true;
				self.Status:SetText(NARCI_GROUP_PHOTO_STATUS_HIDDEN);
				self:SetModelType("hidden");
			else
				state = true;
				self.Icon:SetTexCoord(0.5, 0.75, 0, 1);
				self.isModelHidden = false;
				self.Status:SetText("");
				self:UpdateBorderTexture();
			end
			model:SetShown(state);
			model:EnableMouse(state);
			model:EnableMouseWheel(state);
			self.ID:SetShown(state);
			self.Icon:SetShown(not state);
		end
	end

	SetModelActive(ID);
	UpdateGroundShadowOption();
	self.isOn = true;

	--PopUp Frame
	local PopUp = self:GetParent().PopUp;
	FadeFrame(PopUp, 0.15, 0);
end

----------------------------------------------------------------------
NarciGenericModelMixin = {};

function NarciGenericModelMixin:SetWidgetType()
	if self:GetObjectType() == "DressUpModel" then
		self.widgetType = 1;
	else
		self.widgetType = 2;
	end
end

function NarciGenericModelMixin:OnLoad()
	self.isModelLoaded = false;
	--[[
	if UnitExists("target") and UnitIsPlayer("target") then
		self:SetUnit("target");
	else
		self:SetUnit("player");
	end
	--]]
	self:SetKeepModelOnHide(true);
	self.cameraPitch = pi/2;
	self.t = 0;
	self.cameraDistance = self:GetCameraDistance();

	self.rotation = 0.61;
	self:SetRotation(self.rotation);

	local W = self:GetWidth()
	self:SetHitRectInsets(2*W/3 + HIT_RECT_OFFSET, 0, 0, 32.0);

	--AddNewModelFrame(self);

	self.AppliedVisuals = {};
	self.variationID = 0;
	self.animationID = 0;

	self:SetWidgetType();
end

function NarciGenericModelMixin:Freeze(animationID, variationID, animationFrame)
	if variationID then
		self.variationID = variationID;
	else
		variationID = self.variationID or 0;
	end
	self:FreezeAnimation(animationID, variationID, animationFrame);
	self.animationID = animationID;
	self.isPaused = true;
	self.freezedFrame = animationFrame or 0;
end

function NarciGenericModelMixin:PlayAnimation(animationID, variationID)
	if variationID then
		self.variationID = variationID;
	else
		variationID = self.variationID or 0;
	end
	self:SetAnimation(animationID, variationID);
	self.animationID = animationID;
	self.isPaused = nil;
end

function NarciGenericModelMixin:UpdateVirtualModel()
	if self.isVirtual then
		After(0, function()
			self:SetModelAlpha(0);
		end)
	end
end

function NarciGenericModelMixin:ResetCameraPosition()
	local d = self:GetCameraDistance();
	local radian = GLOBAL_CAMERA_PITCH;
	self:MakeCurrentCameraCustom();
	self:SetCameraPosition(d*sin(radian), 0, d*cos(radian) + 0.8);
	self:SetCameraTarget(0, 0, 0.8);
	self.cameraDistance = d;
	self.cameraPitch = radian;
end

function NarciGenericModelMixin:StartPanning()
	self.isAltDown = IsAltKeyDown();
	self.panning = true;
	local posX, posY, posZ = self:GetPosition();
	self.posX = posX;
	self.posY = posY;
	self.posZ = posZ;
	local cursorX, cursorY = GetCursorPosition();
	self.cursorX = cursorX;
	self.cursorY = cursorY;
	self.zoomCursorStartX, self.zoomCursorStartY = GetCursorPosition();
end

function NarciGenericModelMixin:OnUpdate()
	-- Mouse drag rotation
	if (self.mouseDown) then
		if ( self.rotationCursorStart ) then
			local x, y = GetCursorPosition();
			local diffX = (x - self.rotationCursorStart) * 0.01;	--MODELFRAME_DRAG_ROTATION_CONSTANT
			local diffY = (y - self.cameraPitchCursorStart) * 0.02;
			self.rotationCursorStart, self.cameraPitchCursorStart = GetCursorPosition();

			if not IsAltKeyDown() then
				--Rotate Character
				self.rotation = self.rotation + diffX;
				if ( self.rotation < 0 ) then
					self.rotation = self.rotation + (2 * pi);
				end
				if ( self.rotation > (2 * pi) ) then
					self.rotation = self.rotation - (2 * pi);
				end
				self:SetRotation(self.rotation, false);
			else
				--Rotate Camera (pitch)
				self.cameraPitch = self.cameraPitch + diffY;
				if ( self.cameraPitch <= (0 + 0.01)) then
					self.cameraPitch = 0.01;
				end
				if ( self.cameraPitch >= ( pi - 0.01)) then
					self.cameraPitch = pi - 0.01;
				end
				if self.isVirtual then
					UpdateCameraPitch(self, self.cameraPitch);
				else
					UpdateGlobalCameraPitch(self.cameraPitch);
				end
			end
		end
	elseif ( self.panning ) then
		local isAltDown = IsAltKeyDown();
		if isAltDown ~= self.isAltDown then
			--Reset cursor positions
			self:StartPanning();
		end
		local modelScale = self:GetModelScale();
		local cursorX, cursorY = GetCursorPosition();
		local scale = UIParent:GetEffectiveScale();
		local diff = (cursorX - self.zoomCursorStartX) + (cursorY - self.zoomCursorStartY);
		self.zoomCursorStartX, self.zoomCursorStartY = GetCursorPosition();
		if not isAltDown then
			local settings = ModelSettings["Generic"];
			local zoom = sqrt(sqrt(self.cameraDistance));
			local transformationRatio = 0.00002*settings.panValue * 2 ^ (zoom * 2) * scale / modelScale;
			local dx = (cursorX - self.cursorX) * transformationRatio;
			local dy = (cursorY - self.cursorY) * transformationRatio;
			local posY = self.posY + dx;
			local posZ = self.posZ + dy;
			self:SetPosition(self.posX, posY, posZ);
			--print("Y: "..posY.." Z: "..posZ.." Dis: "..self.cameraDistance)
		else
			if LINK_SCALE then
				for i = 1, #ModelFrames do
					--ModelFrames[i]:SetCameraDistance(Value);
					ModelFrames[i].cameraDistance = self.cameraDistance - diff * 0.01;
					UpdateCameraPosition(ModelFrames[i]);
				end
			else
				self.cameraDistance = self.cameraDistance - diff * 0.01;
				UpdateCameraPosition(self);
			end
		end
	end
end

function NarciGenericModelMixin:OnMouseWheel(delta)
	if not self:HasCustomCamera() then return; end
	SmoothZoomModel(self.cameraDistance - delta * 0.25);
end

function NarciGenericModelMixin:OnMouseUp(button)
	if ( button == "RightButton" and self.panning ) then
		self.panning = false;
	elseif ( self.mouseDown ) then
		if ( not button or button == "LeftButton" ) then
			self.mouseDown = false;
		end
	end
end

function NarciGenericModelMixin:OnMouseDown(button)
	if ( button == "RightButton" and not self.mouseDown ) then
		self:StartPanning();
	else
		if ( not button or button == "LeftButton" ) then
			self.mouseDown = true;
			self.rotationCursorStart, self.cameraPitchCursorStart = GetCursorPosition();
		end
	end
end

function NarciGenericModelMixin:OnHide()
	if ( self.panning ) then
		self.panning = false;
	end
	self.mouseDown = false;
end

local function RedressPlayerAfterLoading(model)
	if model:IsObjectType("DressUpModel") and model.customTransmogList then
		After(0, function()
			model:Undress();
			local mainHandInfo, offHandInfo;	--a workaround cuz there seems to be a delay before weapons being loaded
			for slotID, transmogInfo in pairs(model.customTransmogList) do
				if slotID == 16 then
					mainHandInfo = transmogInfo;
				elseif slotID == 17 then
					offHandInfo = transmogInfo;
				else
					model:SetItemTransmogInfo(transmogInfo, slotID);
				end
				After(0.1, function()
					model:UndressSlot(16);
					model:UndressSlot(17);
					model:SetItemTransmogInfo(mainHandInfo, 16);
					model:SetItemTransmogInfo(offHandInfo, 17);
				end);
			end
		end);
	end
end

function NarciGenericModelMixin:OnModelLoaded()
	InitializeModel(self);
	self:UpdateVirtualModel();
	self.isModelLoaded = true;
	self.isAnimationCached = nil;
	self.animationList = {};
	RedressPlayerAfterLoading(self);
end

function NarciGenericModelMixin:OnAnimFinished()
	--Disabled because unsheathing weapon will stop animation from playing
	--[[
	if self.animationID then
		local id = self.animationID;
		if id ~= 0 and id ~= 804 and id ~= 808 then
			self:SetAnimation(self.animationID, self.variationID);
		end
	end
	--]]
end

local inventoryTypeSlot = {
	--Mainhand~1 Offhand~2
	INVTYPE_SHIELD = 2,
	INVTYPE_RANGED = 2,			--Bow
	INVTYPE_RANGEDRIGHT = 1,	--Crossbow/Gun
	INVTYPE_2HWEAPON = 1,
	INVTYPE_WEAPONMAINHAND = 1,
	INVTYPE_WEAPONOFFHAND = 2,
	INVTYPE_THROWN = 1,
	INVTYPE_RELIC = 2,
};

local function RedirectInventorySlot(itemID, widgetType)
	local _, _, _, itemEquipLoc, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID);
	if itemClassID == 4 and itemSubClassID == 6 then	--shield ~ always offhand
		return 2
	elseif widgetType == 2 then	--CinematicModel
		return inventoryTypeSlot[itemEquipLoc]
	end
end



function NarciGenericModelMixin:EquipWeapon(itemID, sourceID, hand)
	--item: "item:123456"(string) or sourceID(number)
	--print(string.format("item: %s  source: %s", itemID, sourceID));
	if not self.equippedWeapons then
		self.equippedWeapons = {};
	end
	self.holdWeapon = true;

	--redirect hand
	hand = RedirectInventorySlot(itemID, self.widgetType) or hand;
	local slotID;
	local itemTryOnResult;
	if hand and hand == 2 then
		--offhand
		slotID = 17;
		if self.SetItemTransmogInfo then
			if sourceID and sourceID ~= 0 then
				itemTryOnResult = self:EquipItemBySourceID(sourceID, 17);
			else
				self:UndressSlot(17);
			end
			self.equippedWeapons[2] = sourceID;

		elseif self.TryOn then
			if sourceID and sourceID ~= 0 then
				itemTryOnResult = self:TryOn(sourceID, "SECONDARYHANDSLOT");
			else
				self:UndressSlot(17);
			end
			self.equippedWeapons[2] = sourceID;

		elseif self.EquipItem then
			local noMainHand = not self.equippedWeapons[1];
			if noMainHand then
				self:EquipItem(itemID);
				self:EquipItem(itemID);
				self:EquipItem(111532);	--Remove mainhand
			else
				self:EquipItem(130105);	--Invisible Holdable
				self:EquipItem(itemID);
			end

			self.equippedWeapons[2] = itemID;
			itemTryOnResult = 0;
		end

	else
		--mainhand
		slotID = 16;
		if self.SetItemTransmogInfo then
			if sourceID and sourceID ~= 0 then
				itemTryOnResult = self:EquipItemBySourceID(sourceID, 16);
			else
				self:UndressSlot(16);
			end
			self.equippedWeapons[1] = sourceID;

		elseif self.TryOn then
			if sourceID and sourceID ~= 0 then
				itemTryOnResult = self:TryOn(sourceID, "MAINHANDSLOT");
			else
				self:UndressSlot(16);
			end
			self.equippedWeapons[1] = sourceID;

		elseif self.EquipItem then
			--self:UnequipItems();	--Doesn't work
			self:EquipItem(111532);	--Invisible Mainhand
			self:EquipItem(itemID);
			self.equippedWeapons[1] = itemID;
			itemTryOnResult = 0;
		end
	end

	if self.customTransmogList and sourceID then
		self.customTransmogList[slotID] = ItemUtil.CreateItemTransmogInfo(sourceID);
	end

	return (itemTryOnResult == 0), hand, self.widgetType	--ItemTryOnReason.Success ~ 0
end

function NarciGenericModelMixin:ReEquipWeapons()
	if self.equippedWeapons then
		if self.SetItemTransmogInfo then
			local weaponID = self.equippedWeapons[1];
			if weaponID then
				self:EquipItemBySourceID(weaponID, 16);
			end
			weaponID = self.equippedWeapons[2];
			if weaponID then
				self:EquipItemBySourceID(weaponID, 17);
			end

		elseif self.TryOn then
			local weaponID = self.equippedWeapons[1];
			if weaponID then
				self:TryOn(weaponID, "MAINHANDSLOT");
			end
			weaponID = self.equippedWeapons[2];
			if weaponID then
				self:TryOn(weaponID, "SECONDARYHANDSLOT");
			end

		else
			--CinematicModel
			if self.holdWeapon then
				local itemID = self.equippedWeapons[1];
				if itemID then
					self:EquipItem(itemID);
				end
				itemID = self.equippedWeapons[2];
				if itemID then
					self:EquipItem(itemID);
				end
			end
		end
	end
end

function NarciGenericModelMixin:SetActive(state)
	if state then
		self:SetScript("OnUpdate", self.OnUpdate);
		if self.isItemLoaded then
			Narci_PhotoModeWeaponFrame:SetItemFromActor(self);
		else
			After(0.5, function()
				Narci_PhotoModeWeaponFrame:SetItemFromActor(self);
			end);
		end
		Narci_WeaponBrowser:ChangeActiveModelType(self.widgetType);
	else
		self:SetScript("OnUpdate", nil);
		self.GroundShadow.Option:Hide();
	end
	self.GroundShadow:EnableMouse(state);
	self:EnableMouse(state);
	self:EnableMouseWheel(state);
end

function NarciGenericModelMixin:EquipItemBySourceID(sourceID, slotID)
	if sourceID and sourceID ~= 0 and self.SetItemTransmogInfo then
		local itemTransmogInfoMixin = CreateFromMixins(ItemTransmogInfoMixin);
		itemTransmogInfoMixin:Init(sourceID);
		local result = self:SetItemTransmogInfo(itemTransmogInfoMixin, slotID);
		return result
	end
end

--------------------------------------------------------------------------------
NarciMainModelMixin = CreateFromMixins(NarciGenericModelMixin);

function NarciMainModelMixin:OnLoad()
	self.isVirtual = false;
	self.isModelLoaded = false;
	self:SetUnit("player");
	self.mouseDown = false;
	self.panning = false;
	self.cameraPitch = pi/2;
	self:SetLight(true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.8, 0.8, 0.8, 1, 0.8, 0.8, 0.8);
	self.t = 0;
	self.buttonIndex = 1;

	local defaultRotation = 0.61;
	self:SetRotation(defaultRotation);
	self.rotation = defaultRotation;

	local r, g, b = 0, 177/255, 64/255;
	FullSceenChromaKey = Narci_ChromaKey;
	FullSceenChromaKey:SetColorTexture(r, g, b);
	FullScreenAlphaChannel = Narci_FullScreenAlphaChannel;

	local W = self:GetWidth();
	self:SetHitRectInsets(2*W/3 + HIT_RECT_OFFSET, 0, 0, 32.0);

	ModelFrames[1] = self;
	PrimaryPlayerModel = self;
	Narci.ActiveModel = self;

	self.AppliedVisuals = {};
	self.animationID = 0;
	self.variationID = 0;

	self:SetWidgetType();
end

function NarciMainModelMixin:OnMouseUpModified(button)
	self:OnMouseUp(button);
	self.GuideLineCenter:Hide();
end

function NarciMainModelMixin:OnMouseDownModified(button)
	self:OnMouseDown(button)

	if self.GuideFrame:IsVisible() then
		self.GuideLineCenter:Show();
	end
end

function NarciMainModelMixin:OnModelLoaded()
	self:MakeCurrentCameraCustom();
	self.isModelLoaded = true;
	self.isAnimationCached = nil;
	self.animationList = {};
	RedressPlayerAfterLoading(self);
end

----------------------------------------------------------------------
NarciPhotoModeAPI = {};

local function CreateEmptyModelForNPCBrowser(actorIndex, isPet)
	local ID = actorIndex;
	local buttons = ActorPanel.ExtraPanel.buttons;
	local IndexButton = buttons[ID];
	if not ID or not IndexButton then return; end;

	local model = _G["NarciNPCModelFrame"..ID];
	if not model then
		model = CreateFrame("CinematicModel", "NarciNPCModelFrame"..ID, Narci_ModelContainer, "Narci_NPCModelFrame_Template");
		model:SetID(ID);
	end
	model:SetModel(124640);
	model.isLoaded = false;
	model.isPlayer = false;
	ModelFrames[ID] = model;

	model.buttonIndex = ID;
	model:SetShown(true);
	model:EnableMouse(true);
	model:EnableMouseWheel(true);
	model:SetFrameLevel(14 - IndexButton.order);
	ResetModelPosition(model);
	InitializeModelLight(model);

	model.race, model.gender = InitializePlayerInfo(ID, "player");

	UpdateActorName(ID);
	SetGenderIcon(playerInfo[ID].gender);

	IndexButton.hasModel = true;
	IndexButton.ID:Show();
	IndexButton.Icon:Hide();
	IndexButton.Label:SetText(" ");

	if isPet then
		IndexButton:SetModelType("pet");
	else
		IndexButton:SetModelType("npc");
	end

	model:SetModelAlpha(1);
	model.isVirtual = false;

	for i= 1, #buttons do
		buttons[i]:SetSelection(i == ID);
	end

	if buttons[ID + 1] then
		buttons[ID + 1]:Show();
	end

	SwitchPortrait(ID, nil, true)
	SetModelActive(ID);
	UpdateGroundShadowOption();

	return model
end

NarciPhotoModeAPI.CreateEmptyModelForNPCBrowser = CreateEmptyModelForNPCBrowser;

local function OverrideActorInfo(actorIndex, name, hasWeapon, portraitFile)
	if not playerInfo[actorIndex] then
		playerInfo[actorIndex] = {};
		local info = playerInfo[actorIndex];
		info.raceID_Original = 1;
		info.raceID = 1;
		info.gender_Original = 2;
		info.gender = 2;
		info.class = "PRIEST";
	end
	playerInfo[actorIndex].name = name;
	--ActorPanel.ExtraPanel.buttons[actorIndex].Label:SetText(name);
	--ActorPanel.ActorButton.ActorName:SetText(name);
	SmartSetActorName(ActorPanel.ExtraPanel.buttons[actorIndex].Label, name);
	SmartSetActorName(ActorPanel.ActorButton.ActorName, name);
	

	--Weapon

	--Portrait
	if portraitFile then
		local Portraits = ActorPanel.ActorButton;
		local Portrait = Portraits["Portrait"..actorIndex];
		Portrait:SetTexture(portraitFile);
		if type(portraitFile) ~= "number" then
			Portrait:SetTexCoord(0.734, 0.472, 0, 0.52);
		end
	end
end

NarciPhotoModeAPI.OverrideActorInfo = OverrideActorInfo;

local function CreateAndSelectNewActor(actorIndex, unit, isVirtual)
	local ID = actorIndex;
	local buttons = ActorPanel.ExtraPanel.buttons;
	local IndexButton = buttons[ID];
	if not ID or not IndexButton then return; end;

	local model;
	local inputType = type(unit);
	local alternateMode = IsAltKeyDown();
	if inputType == "string" then
		--Create from unit (player/target/party)
		if UnitExists(unit) then
			if alternateMode then
				model = _G["NarciNPCModelFrame"..ID];
			else
				model = _G["NarciPlayerModelFrame"..ID];
			end
		end

		if not model then
			if alternateMode and not isVirtual then
				model = CreateFrame("CinematicModel", "NarciNPCModelFrame"..ID, Narci_ModelContainer, "Narci_NPCModelFrame_Template");
			else
				model = CreateFrame("DressUpModel", "NarciPlayerModelFrame"..ID, Narci_ModelContainer, "Narci_CharacterModelFrame_Template");
			end
			model:SetID(ID);
			NarciModelControl_AnimationSlider:ResetValueVisual();
		end
		model.isModelLoaded = false;
		model:SetUnit(unit);
		model.isPlayer = true;
		NarciPhotoModeOutfitSelect:AddPlayerActor(unit, model);

	elseif inputType == "number" then
		--Create from displayID
		model = _G["NarciNPCModelFrame"..ID];
		if not model then
			model = CreateFrame("CinematicModel", "NarciNPCModelFrame"..ID, Narci_ModelContainer, "Narci_NPCModelFrame_Template");
			model:SetID(ID);
		end
		alternateMode = true;
		model.isModelLoaded = false;
		model:SetDisplayInfo(unit);
		model.isPlayer = false;
		unit = "player";
	else
		return;
	end

	ModelFrames[ID] = model;

	model.buttonIndex = ID;
	model:SetShown(true);
	model:SetFrameLevel(14 - IndexButton.order);
	ResetModelPosition(model);
	InitializeModelLight(model);

	SwitchPortrait(ID, unit);	--Use diffrent portrait for virtual actor?
	model.race, model.gender = InitializePlayerInfo(ID, unit);
	UpdateActorName(ID);
	SetGenderIcon(playerInfo[ID].gender);

	--Update index button

	IndexButton.hasModel = true;
	IndexButton.ID:Show();
	IndexButton.Icon:Hide();

	if isVirtual then
		IndexButton:SetModelType("virtual");
		model:SetModelAlpha(0)
		model.isVirtual = true;

		playerInfo[ID].name = "|cff0081a9"..VIRTUAL_ACTOR;
		IndexButton.Label:SetText(VIRTUAL_ACTOR);
		IndexButton.Label:SetTextColor(0, 0.505, 0.663);
	else
		if model.isPlayer then
			IndexButton:SetModelType("player");
		else
			IndexButton:SetModelType("npc");
		end
		model:SetModelAlpha(1)
		model.isVirtual = false;
	end

	for i= 1, #buttons do
		buttons[i]:SetSelection(i == ID);
	end

	if buttons[ID + 1] then
		buttons[ID + 1]:Show();
	end

	SetModelActive(ID);
	UpdateGroundShadowOption();

	model.creatureID = nil;

	WeaponUpdator:GetTargetWeapons(unit);
end

function Narci_ModelIndexButton_AddSelf(self)
	local PopUp = self:GetParent();
	local index = PopUp.Index;
	CreateAndSelectNewActor(index, "player", false);
	FadeFrame(PopUp, 0.15, 0);
end

function Narci_ModelIndexButton_AddVirtual(self)
	local PopUp = self:GetParent();
	local index = PopUp.Index;
	CreateAndSelectNewActor(index, "player", true);
	FadeFrame(PopUp, 0.15, 0);
end


local function ModelIndexButton_ShowSelfLabelAndHideOthers(self)
	local buttons = self:GetParent().buttons;
	local button;
	for i = 1, #buttons do
		button = buttons[i];
		ShowIndexButtonLabel(button, false);
	end
	ShowIndexButtonLabel(self, true);
end

local function CopyTable(table)
	if not table then return; end;
	local newTable = {};
	for k, v in pairs(table) do
		newTable[k] = v;
	end
	return newTable;
end

local function UpdateButtonOrder(button, newOrder)
	local buttons = ActorPanel.ExtraPanel.buttons;
	local buttonID = button:GetID();
	local orderTable = {};
	for i = 1, #IndexButtonPosition do
		if IndexButtonPosition[i] == buttonID then
			IndexButtonPosition[i] = false;
		end
	end
	local a = 1;
	for i = 1, #IndexButtonPosition do
		if IndexButtonPosition[i] then
			if a == newOrder then
				a = a + 1;
			end
			orderTable[a] = IndexButtonPosition[i];
			a = a + 1;
		end
	end
	orderTable[newOrder] = buttonID;

	--[[
	local str = "";
	for i = 1, 5 do
		if orderTable[i] then
			str = str..orderTable[i].." ";
		else
			return;
		end
	end
	print(str);
	--]]
	
	return orderTable;
end

function Narci_ModelIndexButton_AnimFrame_OnUpdate(self, elapsed)
	self.t = self.t + elapsed;
	local value = outSine(self.t, self.StartX, self.EndX - self.StartX, self.duration) --0.11 NE
	
	self:GetParent():SetPoint("LEFT", self.relativeTo, "LEFT", value, 0);
	if self.t >= self.duration then
		self:Hide();
	end
end

local function AssignOrder(orderTable)
	--Replace Index Button (transition animation)--
	if not orderTable then return; end;
	local buttons = ActorPanel.ExtraPanel.buttons;
	local button, buttonID, model;
	local offset;
	for i = 1, #orderTable do
		buttonID = orderTable[i];
		button = buttons[buttonID];
		button.order = i;
		model = ModelFrames[buttonID];
		if model then
			model:SetFrameLevel(14 - i);
			--print( (model:GetName()).. " Level ".. (14-i) )
		end
		offset = 24*(i - 1);
		button.AnimFrame:Hide();
		button.AnimFrame.EndX = 24*(i - 1);
		button.AnimFrame:Show();
	end
end

-------------------------------------------------------
function Narci_VirtualActorToggle_OnClick(self)
	self.isOn = not self.isOn;
	local IndexButton = ActorPanel.ExtraPanel.buttons[ACTIVE_MODEL_INDEX];
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	if self.isOn then
		self.Icon:Show();
		IndexButton:SetModelType("virtual");
		model:SetModelAlpha(0)
		model.isVirtual = true;
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		self.Icon:Hide();
		model:SetModelAlpha(1)
		model.isVirtual = false;
		IndexButton:UpdateBorderTexture();
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
end

-------------------------------------------------------
function Narci_ExtraPanel_OnLoad(self)
	local buttons = {};
	for i = 1, NUM_MAX_ACTORS do
		local button = CreateFrame("Button", nil, self, "Narci_ModelIndexButton_Template");
		button:SetID(i);
		if i == 1 then
			button:SetPoint("LEFT", self.ReferenceFrame, "LEFT", 0, 0);
		else
			button:SetPoint("LEFT", buttons[i - 1], "RIGHT", 0, 0);
		end
		button:RegisterForDrag("LeftButton");
		button:SetModelType("player");
		button.order = self:GetID();
		button.isOn = false;
		button.lockHighlight = false;
		button.ID:SetText(i);
		button.AnimFrame.relativeTo = self.ReferenceFrame;
		tinsert(buttons, button);
	end
	self.buttons = buttons;
end

NarciIndexRepositionFrameMixin = {};

function NarciIndexRepositionFrameMixin:OnLoad()
	self.orderTable = {};
	self.ref = self:GetParent().ReferenceFrame;
end

function NarciIndexRepositionFrameMixin:OnShow()
	self.x0 = self:GetParent().ReferenceFrame:GetLeft();
	self.order = nil;
	self.xmin = self.x0 + 0.1 + 12;
	self.xmax = self.x0 + (NUM_MAX_ACTORS - 1) * 24 + 12; -- Index Button Width numMaxButton - 1
	self.scale = self:GetEffectiveScale() or 1;
end

function NarciIndexRepositionFrameMixin:OnUpdate(elapsed)
	--drag an index button to replace model's framelevel--
	local xpos, _ = GetCursorPosition();
	xpos = xpos / self.scale;
	local buttons = self:GetParent().buttons;
	local ofsx, order;
	if xpos <= self.xmin then
		ofsx = 0 + 12;
	elseif xpos >= self.xmax then
		ofsx = (NUM_MAX_ACTORS - 1) * 24 + 12;
	else
		ofsx = (xpos - self.x0);
	end

	local button = buttons[self.ActiveButton];
	for i = 1, NUM_MAX_ACTORS do
		if ofsx > 24*(i - 1) and ofsx <= 24*i then
			if self.order ~= i then
				self.order = i;
				self.orderTable = UpdateButtonOrder(button, self.order);
				AssignOrder(self.orderTable);
			end
			break;
		end
	end

	--print(ofsx);
	button:ClearAllPoints();
	button:SetPoint("CENTER", self.ref, "LEFT", ofsx, 0);
end

function NarciIndexRepositionFrameMixin:OnHide()
	IndexButtonPosition = CopyTable(self.orderTable) or IndexButtonPosition;
	AssignOrder(IndexButtonPosition);
end


local function RemoveActor(actorIndex)
	local ID, model;
	if actorIndex then
		ID = actorIndex;
		model = _G["NarciNPCModelFrame"..ID];
	else
		ID = ACTIVE_MODEL_INDEX;
		model = ModelFrames[ID];
	end

	local buttons = ActorPanel.ExtraPanel.buttons;
	local button = buttons[ID];

	if model then
		model.isModelLoaded = false;
		model.isItemLoaded = false;
		model:ClearModel();
		model.isVirtual = false;
		model:Hide();

		model.creatureID = nil;
		model.creatureName = nil;
		model.equippedWeapons = nil;
		model.isAnimationCached = nil;
		model.animationList = {};
		model.customTransmogList = nil;
		model.GroundShadow:Hide();
		model.freezedFrame = 0;
		wipe(model.AppliedVisuals);
	end

	button:SetModelType("empty");
	button.hasModel = false;
	button.isModelHidden = false;
	button.isOn = false;
	button.Icon:SetTexCoord(0, 0.25, 0, 1);
	button.Icon:Show();
	button.ID:Hide();
	button.Highlight:Hide();

	for i = ID - 1, 1, -1 do
		if buttons[i].hasModel then
			buttons[i]:Click();
			return;
		end
	end
	for i = ID + 1, #buttons do
		if buttons[i].hasModel then
			buttons[i]:Click();
			return;
		end
	end
end

NarciPhotoModeAPI.RemoveActor = RemoveActor;

function Narci_DeleteModelButton_OnClick()
	RemoveActor();
end

local function CustomModelPosition(model, raceID, genderID)
	model:MakeCurrentCameraCustom();
	raceID = ReAssignRaceID(raceID, true);

	local data;
	if genderID == 2 then
		data = TranslateValue_Male[raceID][2];
	else
		data = TranslateValue_Female[raceID][2];
	end

	model:SetPosition(0, data[2], data[3]);
	model:SetPortraitZoom(data[1]);
	model:MakeCurrentCameraCustom();
	After(0, function()
		model:ResetCameraPosition();
	end)
end

function Narci_GenderButton_OnLoad(self)
	self.tooltip = Narci.L["Sex Change Tooltip"];
	local _, genderID = GetUnitRaceIDAndSex("player");
	SetGenderIcon(genderID);
end

local function RestoreModelAfterRaceChange(model)
	if model.isPaused then
		model:Freeze(model.animationID or 804);
	else
		model:PlayAnimation(model.animationID or 804);
	end

	After(0, function()
		local visualID;
		local AppliedVisuals = model.AppliedVisuals;
		for i = 1, #AppliedVisuals do
			visualID = AppliedVisuals[i];
			if visualID then
				model:ApplySpellVisualKit(visualID, false);
			end
		end
		if model.isVirtual then
			model:SetModelAlpha(0);
		else
			model:SetModelAlpha(1);
		end

		model.hasRaceChanged = true;
		--Weapons Gone
		--It seems that after race change, the model can no longer get dressed or undressed
		--[[
		local WeaponInfo = ActorPanel;
		if WeaponInfo.MainHandSource then
			model:TryOn(WeaponInfo.MainHandSource, "MAINHANDSLOT", WeaponInfo.MainHandEnchant);
		end
		if WeaponInfo.OffHandSource then
			model:TryOn(WeaponInfo.OffHandSource, "SECONDARYHANDSLOT", WeaponInfo.OffHandEnchant);
		end
		--]]
	end)
end

function Narci_GenderButton_OnClick(self)
	local index = ACTIVE_MODEL_INDEX;
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local genderID = playerInfo[index].gender or 2;
	local raceID = playerInfo[index].raceID;
	local _, _, dirX, dirY, dirZ, _, ambR, ambG, ambB, _, dirR, dirG, dirB = model:GetLight();
	model:SetBarberShopAlternateForm();
	if genderID == 2 then
		model:SetCustomRace(raceID, 1);
		genderID = 3;
	elseif genderID == 3 then
		model:SetCustomRace(raceID, 0);
		genderID = 2;
	end
	playerInfo[index].gender = genderID;
	SetGenderIcon(playerInfo[index].gender);
	model:SetModelAlpha(0);
	After(0, function()
		CustomModelPosition(model, raceID, genderID);
		After(0, function()
			RestoreModelAfterRaceChange(model);
			model:SetLight(true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
		end)	
	end);
end

local AutoCloseTimer2 = C_Timer.NewTimer(0, function()	end);

local function AutoCloseRaceOption(time)
	AutoCloseTimer2:Cancel();
	AutoCloseTimer2 = C_Timer.NewTimer(time, function()
		if NarciModelControl_ActorButton.isOn then
			NarciModelControl_ActorButton:Click();
		end
	end)
end

function Narci_RaceOptionButton_OnEnter(self)
	self.Highlight:Show();
	AutoCloseTimer2:Cancel();
end

function Narci_RaceOptionButton_OnLeave(self)
	self.Highlight:Hide();
	AutoCloseRaceOption(2);
end

function Narci_RaceOptionButton_OnClick(self)
	AutoCloseTimer2:Cancel();
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local genderID = playerInfo[ACTIVE_MODEL_INDEX].gender;
	local raceID = self:GetID() or 1;
	playerInfo[ACTIVE_MODEL_INDEX].raceID = raceID;
	local _, _, dirX, dirY, dirZ, _, ambR, ambG, ambB, _, dirR, dirG, dirB = model:GetLight();
	model:SetBarberShopAlternateForm();
	if genderID == 2 then
		model:SetCustomRace(raceID, 0);
	else
		model:SetCustomRace(raceID, 1);
	end
	AutoCloseRaceOption(4);
	
	model:SetModelAlpha(0);
	After(0, function()
		CustomModelPosition(model, raceID, genderID);
		After(0, function()
			RestoreModelAfterRaceChange(model);
			model:SetLight(true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
		end)	
	end);
end

function Narci_LinkLightButton_OnClick(self)
	self.isOn = not self.isOn;
	LINK_LIGHT = self.isOn;
	HighlightButton(self, self.isOn);
	self.ClipFrame.LinkButton:Click();
	--self.LinkButton.FadeOut:Play();
end

function Narci_LinkScaleButton_OnClick(self)
	self.isOn = not self.isOn;
	LINK_SCALE = self.isOn;
	HighlightButton(self, self.isOn);
	self.ClipFrame.LinkButton:Click();
	--self.LinkButton.FadeOut:Play();
end

function Narci_ActorButton_OnClick(self)
	self.isOn = not self.isOn;
	if self.isOn then
		self:LockHighlight();
		AutoCloseRaceOption(4);
		FadeFrame(Narci_RaceOptionFrame, 0.2, 1);
	else
		self:UnlockHighlight();
		FadeFrame(Narci_RaceOptionFrame, 0.2, 0);
	end

	NarciTooltip:JustHide();
end

local function HideGroundShadowControl()
	local model;
	for i = 1, #ModelFrames do
		model = ModelFrames[i];
		if model then
			model.GroundShadow.Option:Hide();
		end
	end
end

function Narci_GroundShadowToggle_ResetButton_OnClick(self)
	local frame = ModelFrames[ACTIVE_MODEL_INDEX].GroundShadow;
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0 ,0);
	frame:SetUserPlaced(false);
	frame.Option.SizeSlider:SetValue(1);
	frame.Option.AlphaSlider:SetValue(1);
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
end

function Narci_GroundShadowToggle_OnHide(self)
	HideGroundShadowControl();
	self.isOn = false;
	HighlightButton(self, false);
end

function Narci_GroundShadowToggle_OnClick(self)
	local frame = ModelFrames[ACTIVE_MODEL_INDEX].GroundShadow;
	local state = not frame:IsShown();
	frame:SetShown(state);
	self.isOn = state;
	UpdateGroundShadowOption();
end

local function CreateRaceButtonList(self, buttonTemplate, buttonNameTable, numRow)
	local button, buttonWidth, buttonHeight;
	local buttons, columnWidth = {}, {};
	local parentName = self:GetName();
	local buttonName = parentName and (parentName .. "Button") or nil;
	local minWidth, maxWidth = 80, 0;
	local GetRaceInfo = C_CreatureInfo.GetRaceInfo;
	local _, _, playerRaceID = UnitRace("player");
	playerRaceID = playerRaceID or -1;
	local column = 1;

	local insetFrame = self.Inset;
	local initialPoint = "TOPLEFT";
    local initialRelative = "TOPLEFT";
    local initialOffsetX = 0;
    local initialOffsetY = 0;
	local point = "TOPLEFT";
	local relativePoint = "BOTTOMLEFT";
	local offsetX = 0;
	local offsetY = 0;

	local numButtons = #buttonNameTable;
	local totalHeight = 0;
	numRow = numRow or numButtons;
	
	local value;
	for i = 1, numButtons do
		button = CreateFrame("BUTTON", buttonName and (buttonName .. i) or nil, self, buttonTemplate);
		value = buttonNameTable[i]
		
		if value ~= -1 then
			button:SetID(value);
			button.Name:SetText(GetRaceInfo(value).raceName);
			if value == playerRaceID then
				button.Name:SetTextColor(0.25, 0.78, 0.92);
				--highlight the original race
			end
		else
			--Create placeholder
			button.Name:SetText("");
			button:Disable();
		end

		if i == 1 then
			button:SetPoint(initialPoint, insetFrame, initialRelative, initialOffsetX, initialOffsetY);
			buttonHeight = button:GetHeight();
			totalHeight = buttonHeight * numRow;
		else
			if i % numRow == 1 then
				button:SetPoint(point, buttons[i- numRow], "TOPRIGHT", offsetX, offsetY);
				column = column + 1;
				maxWidth = 0;
				--Create divider
				local tex;
				if column == 3 then
				tex = self:CreateTexture(nil, "OVERLAY", nil, 1);
				tex:SetSize(0.5, 0);
				tex:SetColorTexture(1, 1, 1, 0.15);
				tex:SetPoint("TOP", button, "TOPLEFT", 0, -2);
				tex:SetPoint("BOTTOM", insetFrame, "BOTTOM", 0, 2);
				end

				if (column - 1) % 2 == 1 then
					tex = self:CreateTexture(nil, "ARTWORK", nil, 1);
					tex:SetSize(totalHeight + 22, totalHeight + 22);
					tex:SetPoint("TOPRIGHT", button, "TOPRIGHT", 5, 12);
					--tex:SetWidth(totalHeight - 10);
					tex:SetTexture("Interface/AddOns/Narcissus/Art/Widgets/LightSetup/FactionEmblems.tga")
					tex:SetAlpha(0.15);
					if column == 2 then
						tex:SetTexCoord(0, 0.5, 0, 1);
					elseif column == 4 then
						tex:SetTexCoord(0.5, 1, 0, 1);
					end
				end
			else
				button:SetPoint(point, buttons[i- 1], relativePoint, offsetX, offsetY);
				button:SetPoint("TOPRIGHT", buttons[i- 1], "TOPRIGHT", 0, 0);
			end
		end

		if column < 3 then
			--Alliance blue
			button.Background:SetColorTexture(10/255, 40/255, 120/255, 0.2);
		else
			--Horde red
			button.Background:SetColorTexture(120/255, 27/255, 27/255, 0.2);
		end

		buttonWidth = button.Name:GetWidth();
		if buttonWidth > maxWidth then
			maxWidth = buttonWidth;
		end

		columnWidth[column] = math.max(minWidth, math.floor(maxWidth + 0.5 + 16));

		tinsert(buttons, button);
	end

	local totalWidth = 0;
	for i = 1, column do
		--Resize Button
		buttons[(i-1)*numRow + 1]:SetWidth(columnWidth[i]);
		totalWidth = totalWidth + columnWidth[i];
	end

	self:SetSize(totalWidth + 10, numRow*buttonHeight + 10)
	self.buttons = buttons;
end

local function CacheModel()
	local model = PrimaryPlayerModel;
	model:SetUnit("player");
	WeaponUpdator:GetPlayerWeapons("player");
	model:SetAlpha(0);
	model:Show();
	model:SetPosition(0, -1000, -2200)
	model:EnableMouse(false)
	model:EnableMouseWheel(false)
	After(0.5, function()
		model:Hide();
		model:EnableMouse(true);
		model:EnableMouseWheel(true);
		model:SetScript("OnShow", Narci_CharacterModelFrame_OnShow);
	end)
end


---------------------------------------------------------------------------
--Expand Animation

local FRAME_GAP = 0.0166;	--60FPS

local AnimationInfo = {
	frames = 26,
	cX = 0.4296875,
	cY = 0.056640625,
	colum = 2,
	row = 17,
};

local function AnimationSequence_OnUpdate(self, elapsed)
	self.t = self.t + elapsed;
	if self.t >= FRAME_GAP then
		self:SetAlpha(1);
		self.i = self.i + math.floor(self.t / FRAME_GAP);
		self.t = 0;

		local alpha = 0;

		if self.i >= AnimationInfo.frames then
			self.i = AnimationInfo.frames;
			self.isPlaying = nil;
			alpha = 1;
		elseif self.i >= 20 then
			alpha = (self.i - 20) / 6;
		end

		self:SetSubFrameAlpha(alpha);

		local col = math.ceil(self.i / AnimationInfo.row);
		local row =  self.i + (1 - col) * AnimationInfo.row;

		local left, right = (col -1) * AnimationInfo.cX, col * AnimationInfo.cX;
		local top, bottom = (row -1) * AnimationInfo.cY, row * AnimationInfo.cY;
		self.SequenceTexture:SetTexCoord(left, right, top, bottom);

		if not self.isPlaying then
			self:StopAnimation();
		end
	end
end


local ExpandAnim =  CreateFrame("Frame");		--name frame moves to the right
ExpandAnim:Hide();
ExpandAnim.t = 0;
ExpandAnim:SetScript("OnShow", function(self)
	self.d = 0.5;
	self.t = 0;
	self.tex = ActorPanel.NameFrame.NameBackground;
end)
ExpandAnim:SetScript("OnUpdate", function(self, elapsed)
	self.t = self.t + elapsed;
	local offset = outSine(self.t, -96, 95, self.d);

	if self.t >= self.d then
		offset = -1;
		self:Hide();
	end

	self.tex:SetPoint("LEFT", offset, 0);
end)


NarciPhotoModeExtraPanelMixin = {};

function NarciPhotoModeExtraPanelMixin:StopAnimation()
	self:SetScript("OnUpdate", nil);
end

function NarciPhotoModeExtraPanelMixin:ShowFrame()
	self.i = 0;
	self.t = FRAME_GAP;
	self.isPlaying = true;
	self:SetScript("OnUpdate", AnimationSequence_OnUpdate);
	self:Show();
	self:SetAlpha(0);
	self:SetSubFrameAlpha(0);
end

function NarciPhotoModeExtraPanelMixin:SetSubFrameAlpha(alpha)
	self.buttons[1]:SetAlpha(alpha);
	self.buttons[2]:SetAlpha(alpha);
	self.ArtFrame:SetAlpha(alpha);
end

function Narci_GroupPhotoToggle_OnClick(self)
	ResetIndexButton();
	--SetModelActive(1);

	local ExtraPanel = ActorPanel.ExtraPanel;
	ActorPanel.ActorButton.ActorName:SetWidth(120);
	FadeIn(ActorPanel.NameFrame.HiddenFrames, 0.5);

	ExpandAnim:Show();
	ExtraPanel:ShowFrame();
	After(0, function()
		self:Hide();
	end)

	if Narci_SlotLayerButton.isOn then
		Narci_SlotLayerButton:Click();
	end

	Narci.showExitConfirm = true;

	Narci_NPCBrowser:Init();
end


----------------------------------------------------

NarciShadowRotationMixin = {};

function NarciShadowRotationMixin:OnLoad()
	local parent = self:GetParent();
	local GroundShadowContainer = parent:GetParent().ShadowTextures;
	local shadow = GroundShadowContainer.RadialShadow;
	local shadowMask = GroundShadowContainer.RadialShadowMask;
	local defaultRadian = 0;
	local defaultRadius = 72;
	local rMin, rMax = 40, 120;
	local scaleMin, scaleMax = 0.25, 1.25;

	self.lastRadiant = 0;

	local function FlipShadowMask(direction)
		if direction >= 0 then
			shadowMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\GroundShadowRadial-Mask-Up");
		else
			shadowMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\GroundShadowRadial-Mask-Down");
		end
	end
	
	function self:UpdatePosition(radian, r, initialized)
		local dR = r / rMax / 2;
		self.Shaft:SetTexCoord(0.5 - dR, 0.5 + dR, 0, 1);

		local d = 2 * r;
		self.Shaft:SetSize(d, 6);
		self.RingMask1:SetSize(d - 1, d - 1);
		self.RingMask2:SetSize(d + 1, d + 1);

		self.Shaft:SetRotation(radian);
		self.DashedLine:SetRotation(radian);
		shadow:SetRotation(radian);
		local scale = 0.0125 * r - 0.25;
		--shadow:SetScale(0.0125 * r - 0.25);
		shadow:SetWidth(800* scale + 0.5);

		self:SetPoint("CENTER", parent, "CENTER", r * cos(radian), r * sin(radian));

		if radian > 0 and self.lastRadiant < 0 then
			FlipShadowMask(1);
		elseif radian < 0 and self.lastRadiant > 0 then
			FlipShadowMask(-1);
		end
		self.lastRadiant = radian;

		--Update Light Control Button
		if (not initialized) and (GroundShadowContainer.controlLights) then
			LightControl:SetDirection(pi + radian, 1 - 2*dR);
		end
	end

	local UpdateFrame = CreateFrame("Frame", nil, self);
	self.UpdateFrame = UpdateFrame;
	UpdateFrame:Hide();
	
	UpdateFrame:SetScript("OnHide", function(frame)
		frame:Hide();
	end)
	
	UpdateFrame:SetScript("OnUpdate", function()
		local px, py = GetCursorPosition();
		local dx = (px + self.dx) / self.scale - self.cx;
		local dy = (py + self.dy) / self.scale - self.cy;
		local radian = atan2(dy, dx);

		local r = sqrt(dx*dx + dy*dy);
		if r >= rMax then
			r = rMax;
		elseif r <= rMin then
			r = rMin;
		end

		self:UpdatePosition(radian, r);
	end)

	self.Shaft:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\ShadowShaft", nil, nil, "TRILINEAR");
	self.DashedLine:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\ShadowDashedLine", nil, nil, "TRILINEAR");
	self.DashedLine:SetWidth(2 * rMax);
	local texOffset = ( 512 - 2 * rMax )/2/512
	self.DashedLine:SetTexCoord(texOffset, 1 - texOffset, 0, 1);

	--Initialization
	self:UpdatePosition(defaultRadian, defaultRadius, true);
end

function NarciShadowRotationMixin:OnEnter()
	
end

function NarciShadowRotationMixin:OnLeave()
	
end

function NarciShadowRotationMixin:OnMouseDown()
	local tx, ty = self:GetCenter();				--Thumb center
	local cx, cy = self:GetParent():GetCenter();	--parent center
	local px, py = GetCursorPosition();
	local scale = self:GetEffectiveScale();
	self.dx, self.dy = tx * scale - px, ty * scale - py;
	self.cx, self.cy = cx, cy;
	self.scale = scale;

	self.UpdateFrame:Show();
	self:LockHighlight();
end

function NarciShadowRotationMixin:OnMouseUp()
	self.UpdateFrame:Hide();
	self:UnlockHighlight();
end

----------------------------------------------------
NarciActorPanelPopUpMixin = {};

function NarciActorPanelPopUpMixin:OnShow()
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("MODIFIER_STATE_CHANGED");
	

	if UnitExists("target") then
		self.AddTarget.isTypeLocked = not UnitIsPlayer("target");
	end
	self:OnModifierChanged();
end

function NarciActorPanelPopUpMixin:OnHide()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
	self:Hide();
	self:SetAlpha(0);
end

function NarciActorPanelPopUpMixin:OnLeave()
	if not self:IsMouseOver() then
		FadeFrame(self, 0.15, 0);
	end
end

function NarciActorPanelPopUpMixin:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then	--fire when target's changed
		local TargetText = self.AddTarget.Text;
		if UnitExists("target") then
			local name = UnitName("target");
			local _, className = UnitClass("target");
			local r, g, b = GetClassColor(className);
			TargetText:SetTextColor(r, g, b);
			SmartSetActorName(TargetText, name);

			local isTargetNPC = not UnitIsPlayer("target");
			self.AddTarget.isTypeLocked = isTargetNPC;
			if self.AddTarget:IsMouseOver() then
				self:UpdateWidgetTpe(isTargetNPC);
			end
		else
			TargetText:SetTextColor(1, 0.3137, 0.3137);		--Pastel Red
			TargetText:SetText(ERR_GENERIC_NO_TARGET);
			self.AddTarget.isTypeLocked = nil;
		end
	elseif event == "MODIFIER_STATE_CHANGED" then
		local key, down = ...;
		self:OnModifierChanged();
	end
end

function NarciActorPanelPopUpMixin:OnModifierChanged()
	if IsAltKeyDown() then
		self:SetWidgetType(2);
		self.Header.HotkeyAlt:SetHighlight(true);
	else
		self:SetWidgetType(1)
		self.Header.HotkeyAlt:SetHighlight(false);
	end
end

function NarciActorPanelPopUpMixin:SetWidgetType(index)
	if self.isTypeLocked then
		self.Header.WidgetType:SetText("CinematicModel");
	else
		if index == 1 then
			self.Header.WidgetType:SetText("DressUpModel");
		else
			self.Header.WidgetType:SetText("CinematicModel");
		end
	end
	self:UpdateLockVisual();
end

function NarciActorPanelPopUpMixin:UpdateWidgetTpe(lockType)
	self.isTypeLocked = lockType;
	if lockType then
		self.Header.WidgetType:SetText("CinematicModel");
	else
		if IsAltKeyDown() then
			self.Header.WidgetType:SetText("CinematicModel");
		else
			self.Header.WidgetType:SetText("DressUpModel");
		end
	end
	self:UpdateLockVisual();
end

function NarciActorPanelPopUpMixin:UpdateLockVisual()
	local state = self.isTypeLocked;
	self.Header.LockIcon:SetShown(state);
	self.Header.LeftText:SetShown(not state);
	if state then
		self.Header.WidgetType:SetTextColor(0.4, 0.4, 0.4);
	else
		self.Header.WidgetType:SetTextColor(0.65, 0.65, 0.65);
	end
end


----------------------------------------------------
NarciModelIndexButtonMixin = {};

function NarciModelIndexButtonMixin:OnDoubleClick()
	return;
end

function NarciModelIndexButtonMixin:OnEnter()
	self.Highlight:Show();
	if self:GetParent().UpdateFrame:IsShown() then return; end;
	if self.hasModel then
		if self.isModelHidden then
			self.Status:SetText(NARCI_GROUP_PHOTO_STATUS_HIDDEN);
		else
			self.Status:SetText(nil);
		end
		ShowIndexButtonLabel(self, true);
	else
		if not IsMouseButtonDown() then
			local PopUp = self:GetParent().PopUp;
			local TargetText = PopUp.AddTarget.Text;
			if UnitExists("target") then
				local name = UnitName("target");
				local _, className = UnitClass("target");
				local r, g, b = GetClassColor(className);
				TargetText:SetTextColor(r, g, b);
				SmartSetActorName(TargetText, name);
			else
				TargetText:SetTextColor(1, 0.3137, 0.3137);	--Pastel Red
				TargetText:SetText(ERR_GENERIC_NO_TARGET);
			end
			PopUp.parent = self;
			PopUp.Index = self:GetID();
			PopUp:SetPoint("CENTER", self, "CENTER", 0, 16);
			FadeFrame(PopUp, 0.15, 1);
		end
	end
end

function NarciModelIndexButtonMixin:OnLeave()
	if not (self.isOn or self.lockHighlight) then
		self.Highlight:Hide();
	end
	if not self:GetParent().UpdateFrame:IsShown() then
		self.Label:Hide();
		self.LabelColor:Hide();
		self.Status:Hide();
	end
	NarciTooltip:FadeOut();
	local PopUp = self:GetParent().PopUp;
	if not PopUp:IsMouseOver() then
		FadeFrame(PopUp, 0.15, 0);
	end
end

function NarciModelIndexButtonMixin:OnMouseDown()
	self.ID:SetPoint("CENTER", 0.5, -0.5);
	self.Icon:SetPoint("CENTER", 0.5, -0.5);
end

function NarciModelIndexButtonMixin:OnMouseUp()
	self.ID:SetPoint("CENTER", 0, 0);
	self.Icon:SetPoint("CENTER", 0, 0);
end

function NarciModelIndexButtonMixin:OnDragStart()
	if not self.hasModel then return; end;
	self:GetFrameLevel(60);
	self:GetParent().ArtFrame.Label:SetText(L["Move To Font"]);
	self.lockHighlight = true;
	local UpdateFrame = self:GetParent().UpdateFrame;
	UpdateFrame.ActiveButton = self:GetID();
	UpdateFrame:Show();
	ModelIndexButton_ShowSelfLabelAndHideOthers(self);
end

function NarciModelIndexButtonMixin:OnDragStop()
	self:SetFrameLevel(21);
	self:GetParent().ArtFrame.Label:SetText(L["Actor Index"]);
	self:GetParent().UpdateFrame:Hide();
	self.ID:SetPoint("CENTER", 0, 0);
	self.Icon:SetPoint("CENTER", 0, 0);
	if not self.hasModel then return; end;
	local _, _, _, offset = self:GetPoint();
	offset = tonumber(offset) - 12;
	local AnimFrame = self.AnimFrame;
	AnimFrame.StartX = offset;
	AnimFrame.duration = math.max(0.05, math.abs(offset - AnimFrame.EndX) / 65);
	--print("Anim Duration(s) = "..AnimFrame.duration)
	self.lockHighlight = false;
	if not self.isOn then
		self.Highlight:Hide();
	end

	if not self:IsMouseOver() then
		ShowIndexButtonLabel(self, false);
	end
end

function NarciModelIndexButtonMixin:SetModelType(modelType)
	local texOffset = 0;
	if modelType == "player" then
		texOffset = 0;
	elseif modelType == "npc" then
		texOffset = 1;
	elseif modelType == "pet" then
		texOffset = 3;
	elseif modelType == "empty" then
		texOffset = 7;
	else
		if modelType == "hidden" then
			texOffset = 6;
		elseif modelType == "virtual" then
			texOffset = 2;
		end
		self.Border:SetTexCoord(0.125 * texOffset, 0.125 + 0.125 * texOffset, 0, 0.5);
		self.Selection:SetTexCoord(0.125 * texOffset, 0.125 + 0.125 * texOffset, 0.5, 1);
		return
	end
	self.texOffset = texOffset;
	self:UpdateBorderTexture();
end

function NarciModelIndexButtonMixin:UpdateBorderTexture()
	self.Border:SetTexCoord(0.125 * self.texOffset, 0.125 + 0.125 * self.texOffset, 0, 0.5);
	self.Selection:SetTexCoord(0.125 * self.texOffset, 0.125 + 0.125 * self.texOffset, 0.5, 1);
end

function NarciModelIndexButtonMixin:SetSelection(state)
	if state then
		self.Highlight:Show();
		self.Selection:Show();
		self.isOn = true;
		self.ID:SetShadowColor(1, 1, 1);
		self.ID:SetTextColor(0, 0, 0);
	else
		self.Highlight:Hide();
		self.Selection:Hide();
		self.isOn = false;
		self.ID:SetShadowColor(0, 0, 0);
		self.ID:SetTextColor(0.25, 0.78, 0.92);
	end
end

----------------------------------------------------
NarciModelSettingsMixin = {};

function NarciModelSettingsMixin:OnLoad()
	SettingFrame = self;
	BasicPanel = self.BasicPanel;
	self:RegisterForDrag("LeftButton");
	NarciAPI_CreateFadingFrame(self);
end

function NarciModelSettingsMixin:OnEnter()
	if IsMouseButtonDown() then return end;

	HideGroundShadowControl();
	Narci_PhotoModeToolbar:SetAlpha(0);
	self:FadeIn(0.15);
end

local function IsFrameFocused(frame)
	return frame and frame:IsFocused();
end

function NarciModelSettingsMixin:OnLeave()
	if self:IsMouseOver(24, -24, -36, 24) or Narci_SpellVisualBrowser:IsMouseOver(0, 0, 0, 0) or IsFrameFocused(self.TextOverlayMenu) or
	IsFrameFocused(self.NPCBrowser) or IsFrameFocused(self.PetStable) or IsFrameFocused(self.StickerToggle)
	or IsMouseButtonDown() then return end;

	self:FadeOut(0.2);
end

function NarciModelSettingsMixin:OnHide()
	self:SetAlpha(0);
	ResetIndexButton();
	ExitGroupPhoto();
	RestorePlayerInfo(1);
	self:ClearAllPoints();
	self:SetPoint("CENTER", Narci_VirtualLineRightCenter, "CENTER", 0 , 0);
	self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0 , 4);
	self:SetUserPlaced(false);
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    self:SetPanelAlpha(1, false);

	FullSceenChromaKey:Hide();
	FullSceenChromaKey:SetAlpha(0);
	Narci_BackgroundDarkness:Hide();
	Narci_BackgroundDarkness:SetAlpha(0);
	NarciTextOverlayContainer:HideAllWidgets();
	Narci_ColorPicker:Hide();
	WeaponUpdator:SetListener(false);

	NarciPhotoModeOutfitSelect:AddPlayerActor("player", PrimaryPlayerModel);
	NarciPhotoModeOutfitSelect:SelectPreviewModel(1);
	OutfitToggle:EnableButton();
	PrimaryPlayerModel.customTransmogList = nil;
end



function NarciModelSettingsMixin:OnDragStart()
	self:StartMoving();
end

function NarciModelSettingsMixin:OnDragStop()
	self:StopMovingOrSizing();
end

function NarciModelSettingsMixin:SetPanelAlpha(value, smoothing)
    local SpellVisualBrowser = self.SpellPanel;
    local fromAlpha = self.BasicPanel:GetAlpha();
	local UIFrameFadeIn = UIFrameFadeIn;
    if smoothing then
        local fadeDuation;
        if value == 1 then
            fadeDuation = 0.2;
        else
            fadeDuation = 0.5;
        end
        if SpellVisualBrowser.isActive then
            UIFrameFadeIn(SpellVisualBrowser, fadeDuation, fromAlpha, value);
        end
        UIFrameFadeIn(self.ActorPanel, fadeDuation, fromAlpha, value);
        UIFrameFadeIn(self.BasicPanel, fadeDuation, fromAlpha, value);
    else
        if SpellVisualBrowser.isActive then
            SpellVisualBrowser:SetAlpha(value);
        end
        self.ActorPanel:SetAlpha(value);
        self.BasicPanel:SetAlpha(value);
    end
end

function NarciModelSettingsMixin:AddSubFrame(frame, key)
	frame:SetParent(self.ActorPanel.NameFrame.HiddenFrames);
	frame:Show();
	if key and not self[key] then
		self[key] = frame;
	end
end



NarciOutfitToggleMixin = {};

function NarciOutfitToggleMixin:OnLoad()
	OutfitToggle = self;
	self.Label:SetText(L["Outfit"]);
	NarciPhotoModeBar_OnLoad(self);
end

function NarciOutfitToggleMixin:OnClick()
    NarciPhotoModeOutfitSelect:ToggleUI();
end

function NarciOutfitToggleMixin:OnEnter()
    FadeFrame(self.Highlight, 0.2, 1);
end

function NarciOutfitToggleMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
end

function NarciOutfitToggleMixin:DisableButton()
    self:Disable();
	self.Label:SetTextColor(0.42, 0.42, 0.42);
	self.Arrow:SetVertexColor(0.5, 0.5, 0.5);
    --self:SetAlpha(0.5);
end

function NarciOutfitToggleMixin:EnableButton()
    self:Enable();
	self.Label:SetTextColor(0.25, 0.78, 0.92);
	self.Arrow:SetVertexColor(1, 1, 1);
    --self:SetAlpha(1);
end

----------------------------------------------------
local function InitializeScripts()
	local CaptureButton = Narci_Model_CaptureButton;
	CaptureButton.tooltip = {L["Save Layers"], L["Save Layers Tooltip"]};
	CaptureButton.guideIndex = 6;
end

local ScreenshotListener = CreateFrame("Frame");
ScreenshotListener:RegisterEvent("SCREENSHOT_STARTED")
ScreenshotListener:RegisterEvent("SCREENSHOT_SUCCEEDED")
ScreenshotListener:RegisterEvent("PLAYER_ENTERING_WORLD");
ScreenshotListener:SetScript("OnEvent",function(self,event,...)
	if event == "SCREENSHOT_STARTED" then
		Temps.Alpha1 = Narci_PhotoModeToolbar:GetAlpha();
		Temps.Alpha2 = SettingFrame:GetAlpha();
		Narci_PhotoModeToolbar:SetAlpha(0);
		SettingFrame:SetAlpha(0);
	elseif event == "SCREENSHOT_SUCCEEDED" then
		Narci_PhotoModeToolbar:SetAlpha(Temps.Alpha1);
		SettingFrame:SetAlpha(Temps.Alpha2);
		if LayersToBeCaptured >= 0 then
			After(1.5, function()
				StartAutoCapture();
			end)
		end
		NarciAPI.UpdateScreenshotsCounter();

	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent(event);
		ActorPanel = Narci_ActorPanel;
		ModelIndexButton_ResetReposition();
		InitializePlayerInfo(1);
		UpdateActorName(1);
		CreateRaceButtonList(Narci_RaceOptionFrame, "Narci_RaceOptionButton_Template", RaceList, 6);
		InitializeScripts();
		After(1, function()
			CacheModel();
		end)

		NarciModelControl_AnimationSlider.onValueChangedFunc = function(value)
			local id = AnimationIDEditBox:GetNumber();
			local model = ModelFrames[ACTIVE_MODEL_INDEX];
			model:Freeze(id, model.variationID or 0, value);
		end
	end
end)

----------------------------------------------------
function Narci:EquipmentItemByItemID(modelIndex, itemID, itemModID)
	local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemID, itemModID);
	local name = GetItemInfo(itemID) or "";
	After(0.1, function()
		name = GetItemInfo(itemID) or "";
		print(name.." | ".."AppearanceID: "..appearanceID.."  ".." SourceID"..sourceID);
	end)
	
	local model = ModelFrames[modelIndex];
	if model then
		model:TryOn(sourceID);
	else
		print("Can't find model #"..modelIndex);
	end
end

function Narci:ShrinkModelHitRect(offsetX)
	HIT_RECT_OFFSET = offsetX;
	local W0 = WorldFrame:GetWidth();
	local newWidth = 2/3*W0 + offsetX;
	local _G = _G;
	local model;
	for i = 1, NUM_MAX_ACTORS do
		model = _G["NarciPlayerModelFrame"..i];
		if model then
			model:SetHitRectInsets(newWidth, 0 ,0 , 32.0);
		end
		model = _G["NarciNPCModelFrame"..i];
		if model then
			model:SetHitRectInsets(newWidth, 0 ,0 , 32.0);
		end
	end
	Narci_ModelInteractiveArea:SetWidth(W0 - newWidth);
end

function Narci:GetActiveActor()
	return ModelFrames[ACTIVE_MODEL_INDEX]
end


function NarciPhotoModeAPI:SetMaxAnimationID(value)
	if value > maxAnimationID then
		maxAnimationID = value;
	end
end




--[[
function PrintIcon(id)
	print("|T"..id..":18:18:0:0:64:64:4:60:4:60|t")
end

**Peter Odox**

| Slot | Name | Source |
|:--|:--|:--|
| Head | [Netherstorm Eyepatch](https://www.wowhead.com/item=29979) | Quest | 
| Shoulder | [Lightdrinker Shoulders](https://www.wowhead.com/item=119702) |   | 
| Back | [Loa Exultant's Shroud](https://www.wowhead.com/item=165512) | Conclave of the Chosen Battle of Dazar'alor Mythic | 
| Chest | [Vest of the Dashing Scoundrel](https://www.wowhead.com/item=152160) | Eonar the Life-Binder Antorus, the Burning Throne Raid Finder | 
| Shirt | [Blue Lumberjack Shirt](https://www.wowhead.com/item=41249) | Profession | 
| Wrist | [Codemaster's Cuffs](https://www.wowhead.com/item=63660) | Quest | 
| Hands | [Honorable Combatant's Leather Gauntlets](https://www.wowhead.com/item=161949) | Profession | 
| Waist | [Hound-Jowl Waistband](https://www.wowhead.com/item=159341) | Soulbound Goliath Waycrest Manor Heroic | 
| Legs | [Pants of the Dashing Scoundrel](https://www.wowhead.com/item=152164) | Imonar the Soulhunter Antorus, the Burning Throne Raid Finder | 
| Feet | [Honorable Combatant's Leather Treads](https://www.wowhead.com/item=161948) | Profession | 
| Main Hand | [Dreadblades](https://www.wowhead.com/item=128872) | Artifact | 
| Off Hand | [Dreadblades](https://www.wowhead.com/item=134552) | Artifact | 



https://www.wowhead.com/dressing-room#sazm0zJ89cRszNz9m8RZY8zVy8OP48zgJ8WqC8zLJ8PdT8zmw87oSxB8zT48SIf8zLA8Pdx8zmw8Sxl8zT48CiZ808CiY87cf
https://www.wowhead.com/dressing-room#sm0m0zJ89mVm0V9m8RZY8zVy8OP48zgJ8WqC8zLO8PdT8zmi87oURd8zT48SIf808Pdx8zmi8URb8zT48CiZ808CiY87cw

Model FileID
Calia Menethil 2997555
Jaina Proudmoore No Weapon 1717164
Derek Proudmoore 2831231

Dogs
320622

Patch	SpellVisualKit max ID
8.2.0	119100
8.2.5	120270


/run PrimaryPlayerModel:SetLight(true, false, -pi/4, pi/4, 0, 1, 1, 1, 1, 500, 10, 10, 10);



function SetModelID(fileID)
	local m = NarciNPCModelFrame2;
	local a, b, c = m:GetPosition();
	local x, y, z = m:GetCameraPosition();

	m:SetModel(fileID);
	After(1, function()
		m:MakeCurrentCameraCustom();
		m:SetPosition(a, b, c);
		m:SetCameraPosition(x, y, z);
		m:SetCameraTarget(0, 0, 0.8);
	end);
end


/script local m=Narci.ActiveModel;local v=m.variationID;v=(v<15 and v+1)or(0);m.variationID=v;m:PlayAnimation(m.animationID);print(v);
--]]