local _, addon = ...
local API = addon.API;
local Narci = Narci;

local MsgAlertContainer = addon.MsgAlertContainer;
local TransitionAPI = addon.TransitionAPI;
local SlotButtonOverlayUtil = addon.SlotButtonOverlayUtil;
local TalentTreeDataProvider = addon.TalentTreeDataProvider;
local CameraUtil = addon.CameraUtil;
local UIParentFade = addon.UIParentFade;
local CallbackRegistry = addon.CallbackRegistry;
local SharedBlackScreen = addon.SharedBlackScreen;

Narci.refreshCombatRatings = true;

local SLOT_TABLE = Narci.slotTable;
local SetEquipmentSlotFlag = addon.SetEquipmentSlotFlag;

local AttributeFrames = {};
local ShortAttributeFrames = {};
local L = Narci.L;
local VIGNETTE_ALPHA = 0.5;
local IS_OPENED = false;									--Addon was opened by clicking
local MOG_MODE = false;

local NarciAPI = NarciAPI;

local PlayLetteboxAnimation = NarciAPI_LetterboxAnimation;
local SmartFontType = NarciAPI.SmartFontType;
local FadeFrame = NarciFadeUI.Fade;

local outSine = addon.EasingFunctions.outSine;

local GetToolbarButtonByButtonType = addon.GetToolbarButtonByButtonType;

--local GetCorruptedItemAffix = NarciAPI_GetCorruptedItemAffix;
local C_Item = C_Item;
local After = C_Timer.After;
local ItemLocation = ItemLocation;
local IsPlayerInAlteredForm = TransitionAPI.IsPlayerInAlteredForm;
local InCombatLockdown = InCombatLockdown;
local GetCameraZoom = GetCameraZoom;

local floor = math.floor;
local max = math.max;

local UIParent = _G.UIParent;
local Toolbar = NarciScreenshotToolbar;
local EquipmentFlyoutFrame;
local ItemLevelFrame;
local RadarChart;
local ItemTooltip;

local MiniButton = Narci_MinimapButton;


local EL = CreateFrame("Frame");	--Event Listener
EL:Hide();

EL.EVENTS_DYNAMIC = {"PLAYER_TARGET_CHANGED", "COMBAT_RATING_UPDATE", "PLAYER_MOUNT_DISPLAY_CHANGED",
	"PLAYER_STARTED_MOVING", "PLAYER_REGEN_DISABLED", "UNIT_MAXPOWER", "PLAYER_STARTED_TURNING", "PLAYER_STOPPED_TURNING",
	"BAG_UPDATE_COOLDOWN", "UNIT_STATS", "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "AZERITE_ESSENCE_ACTIVATED", "WEAPON_ENCHANT_CHANGED",
};

if API.IsPlayerDruid() then
	table.insert(EL.EVENTS_DYNAMIC, "UPDATE_SHAPESHIFT_FORM");
end

EL.EVENTS_UNIT = {"UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_PORTRAIT_UPDATE"};


local SlotController = CreateFrame("Frame");

SlotController.slotSequence = {}; -- This will be filled automatically in InitializeSlotButtons
SlotController.tempEnchantSequence = {16, 17};

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

function SlotController:OnUpdate(elapsed)
	self.t = self.t + elapsed;
	if self.t >= 0.05 then
		self.t = 0;
		if self.i <= self.total then
			self.i = self.i + 1;
			self:Refresh(self.currentSequence[self.i], self.forceRefresh);
		else
			self:StopRefresh();
			if MOG_MODE and Toolbar.TransmogListFrame:IsShown() then
				After(0.5, function()
					Toolbar.TransmogListFrame:UpdateTransmogList();
				end);
			end
		end
	end
end

function SlotController:StopRefresh()
	self:SetScript("OnUpdate", nil);
end

function SlotController:LazyRefresh(sequenceName)
	self:StopRefresh();
	if sequenceName == "temp" then
		self.currentSequence = self.tempEnchantSequence;
		self.forceRefresh = true;
	else
		self.currentSequence = self.slotSequence;
		self.forceRefresh = false;
	end
	self.t = 0;
	self.i = 0;
	self.total = #self.currentSequence;
	self:SetScript("OnUpdate", self.OnUpdate);
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
			return true;
		end
	end
	return false;
end


local SlotLayout = {};

SlotLayout.Retail = {
	{"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "MainHandSlot", "SecondaryHandSlot", "ShirtSlot"},
	{"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "TabardSlot"},
};

SlotLayout.Forever = {
	{"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"},
	{"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "ShirtSlot", "TabardSlot"},
};

local function InitializeSlotButtons()
	if not SlotLayout then return; end

	local buttonHeight = 72;
	local gap = 2;
	local container = Narci_Character;

	local layout = addon.IS_FOREVER and SlotLayout.Forever or SlotLayout.Retail;

	local font, _, flag;
	local maxLines = (NarcissusDB.TruncateText and 1) or 2;
	local fontHeight = tonumber(NarcissusDB.FontHeightItemName) or 10;
	local textWidth = tonumber(NarcissusDB.ItemNameWidth) or 200;
	if textWidth >= 200 then
		textWidth = 512;
	end

	local n = 0;

	for k, v in ipairs(layout) do
		local isRight = k == 2;
		local orientation = isRight and "right" or "left";
		local point = isRight and "RIGHT" or "LEFT";
		local relativeTo = isRight and Narci_VirtualLineRight or Narci_VirtualLineLeft;
		local totalHeight = (#v - 1) * (buttonHeight + gap) - gap;
		local fromOffsetY = 0.5 * totalHeight;

		for i, slotName in ipairs(v) do
			local slotButton = CreateFrame("Button", nil, container, "NarciEquipmentSlotButtonTemplate");
			slotButton:SetSlotByName(slotName);
			slotButton:SetOrientation(orientation);
			slotButton:SetPoint(point, relativeTo, "CENTER", 0, fromOffsetY + (1 - i) * (buttonHeight + gap));

			-- Apply font settings
			if not font then
				font, _, flag = slotButton.Name:GetFont();
			end
			slotButton.Name:SetFont(font, fontHeight, flag);
			slotButton.Name:SetMaxLines(maxLines);
			slotButton.ItemLevel:SetMaxLines(maxLines);
			slotButton.Name:SetWidth(textWidth);
			slotButton.ItemLevel:SetWidth(textWidth);

			n = n + 1;
			SlotController.slotSequence[n] = slotButton.slotID;
		end
	end

	SlotLayout = nil;
end


--take out frames from UIParent, so they will still be visible when UI is hidden
local FRAME_TAKEN = false;
local function TakeOutFrames(state)
	if (not state) and (not FRAME_TAKEN) then return end;

	local frameNames = {
		"AzeriteEmpoweredItemUI", "AzeriteEssenceUI", "ItemSocketingFrame",
	};
	local frame;
	if state then
		FRAME_TAKEN = true;
		local scale = UIParent:GetEffectiveScale();
		for _, frameName in pairs(frameNames) do
			frame = _G[frameName];
			if frame then
				frame:SetParent(nil);
				frame:SetScale(scale);
			end
		end
	else
		FRAME_TAKEN = false;
		for _, frameName in pairs(frameNames) do
			frame = _G[frameName];
			if frame then
				frame:SetParent(UIParent);
				frame:SetScale(1);
			end
		end
	end
end
Narci.TakeOutFrames = TakeOutFrames;


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
end

function Narci:HideButtonTooltip()
	DefaultTooltip:HideTooltip();
	ItemTooltip:HideTooltip();

end


--CVar Backup
local ConsoleExec = ConsoleExec;
local GetCVar = C_CVar.GetCVar;
local SetCVar = C_CVar.SetCVar;

ConsoleExec("pitchlimit 88");

local CVarTemp = {};

function CVarTemp:BackUp()
	self.zoomLevel = GetCameraZoom();
	self.dynamicPitch = tonumber(GetCVar("test_cameraDynamicPitch"));
	self.shoulderOffset = GetCVar("test_cameraOverShoulder");
	self.cameraViewBlendStyle = GetCVar("cameraViewBlendStyle");
end

function CVarTemp:BackUpDynamicCam()
	self.DynmicCamShoulderOffsetZoomUpperBound = DynamicCam.db.profile.shoulderOffsetZoom.lowerBound;
	DynamicCam.db.profile.shoulderOffsetZoom.lowerBound = 0;
end

function CVarTemp:RestoreDynamicCam()
	DynamicCam.db.profile.shoulderOffsetZoom.lowerBound = self.DynmicCamShoulderOffsetZoomUpperBound;
end

function CVarTemp.BackUpAndChangeOccludedSilhouette()
	CVarTemp.occludedSilhouettePlayer = GetCVar("occludedSilhouettePlayer");
	SetCVar("occludedSilhouettePlayer", 0);
end
CallbackRegistry:Register("UIParent.OnHide", CVarTemp.BackUpAndChangeOccludedSilhouette);

function CVarTemp.RestoreOccludedSilhouette()
	if CVarTemp.occludedSilhouettePlayer then
		SetCVar("occludedSilhouettePlayer", CVarTemp.occludedSilhouettePlayer);
		CVarTemp.occludedSilhouettePlayer = nil;
	end
end
CallbackRegistry:Register("UIParent.OnShow", CVarTemp.RestoreOccludedSilhouette);

local function GetKeepActionCam()
	return CVarTemp.isDynamicCamLoaded or CVarTemp.isActionCamPlusLoaded or (not CVarTemp.cameraSafeMode)
end

CVarTemp.shoulderOffset = tonumber(GetCVar("test_cameraOverShoulder"));
CVarTemp.dynamicPitch = tonumber(GetCVar("test_cameraDynamicPitch"));		--No CVar directly shows the current state of ActionCam. Check this CVar for the moment. 1~On  2~Off
CVarTemp.zoomLevel = 2;


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


local IntroMotion = {};

function IntroMotion:SetUseCameraTransition(enabled)
	local divisor;
	if enabled then
		--Smooth
		DURATION_TRANSLATION = 0.8;
		divisor = 20;
	else
		--Instant
		DURATION_TRANSLATION = 0.4;
		divisor = 80;
	end

	for k, slot in pairs(AttributeFrames) do
		local delay = (slot:GetID())/divisor;
		if slot.animIn then
			slot.animIn.A2:SetStartDelay(delay);
		end
	end

	for k, slot in pairs(ShortAttributeFrames) do
		local delay = (slot:GetID())/divisor;
		slot.animIn.A2:SetStartDelay(delay);
	end

	RadarChart.animIn.A2:SetStartDelay(9/divisor);
	self.useCameraTransition = enabled;
end

function IntroMotion:InstantZoomIn()
	SetCVar("cameraViewBlendStyle", 2);
	SetView(4);
	CameraUtil:InstantZoomIn();
	self:ShowFrame();
	UIParentFade:HideUIParent();
end

function IntroMotion:Enter()
	if not NarcissusDB.CameraAutoZoomIn then
		After(0.25, function()
			self:ShowFrame();
		end);
		CameraUtil:SmoothShoulderByZoom();
		UIParentFade:FadeOutUIParent();
		return
	end

	SetCVar("test_cameraDynamicPitch", 1);

	if self.useCameraTransition then
		if NarcissusDB.CameraOrbit and not IsPlayerMoving() then
			if NarcissusDB.CameraOrbit then
				CameraUtil:SmoothYaw();
			end
			SetView(2);
		end

		if not IsFlying("player") then
			CameraUtil:SmoothPitch();
		end

		After(0.1, function()
			CameraUtil:ZoomToDefault();
			After(0.7, function()
				self:ShowFrame();
			end)
		end)

		UIParentFade:FadeOutUIParent();
	else
		if not self.hasInitialized then
			if NarcissusDB.CameraOrbit then
				CameraUtil:SmoothYaw();
			end
			SetView(2);
			CameraUtil:SmoothPitch();
			After(0.1, function()
				CameraUtil:ZoomToDefault();
				After(0.7, function()
					self:ShowFrame();
				end)
			end)
			After(1, function()
				if not IsMounted() then
					self.hasInitialized = true;
					ViewProfile:SaveView(4);
				end
			end)
			UIParentFade:FadeOutUIParent();
		else
			self:InstantZoomIn();
		end
	end
end

function IntroMotion:PlayAttributeAnimation()
	if not NarcissusDB.DetailedIlvlInfo then
		RadarChart:UpdateChart(true);
		return
	end
	if not RadarChart:IsShown() then
		return		--Attributes is not the active tab
	end
	local f, anim;
	for i = 1, 20 do
		f = AttributeFrames[i];
		anim = f.animIn;
		if anim and not f.noAnimation then
			anim.A2:SetToAlpha(AttributeFrames[i]:GetAlpha());
			anim:Play();
		end
	end
	RadarChart.animIn:Play();
end

function IntroMotion:ShowFrame()
	if not InCombatLockdown() then
		local GuideLineFrame = Narci_GuideLineFrame;
		local VirtualLineRight = GuideLineFrame.VirtualLineRight;
		VirtualLineRight.AnimFrame:Hide();
		local offsetX = GuideLineFrame.VirtualLineRight.AnimFrame.defaultX or -496;
		VirtualLineRight:SetPoint("RIGHT", offsetX + 120, 0);
		VirtualLineRight.AnimFrame.toX = offsetX;
		VirtualLineRight.AnimFrame:Show();
		GuideLineFrame.VirtualLineLeft.AnimFrame:Show();
		After(0, function()
			FadeFrame(Narci_Character, 0.6, 1);
		end);
		Narci_SnowEffect(true);
	end

	self:PlayAttributeAnimation();
	if MOG_MODE then
		FadeFrame(Narci_Attribute, 0.4, 0)
	else
		FadeFrame(Narci_Attribute, 0.4, 1, 0);
	end
end


local function ExitFunc()
	IS_OPENED = false;
	CameraUtil:SetUseMogOffset(false);
	EL:Hide();

	MoveViewRightStop();
	CameraUtil:RestoreMotionSickness();

	if not GetKeepActionCam() then		--(not CVarTemp.isDynamicCamLoaded and CVarTemp.dynamicPitch == 0) or not Narci.keepActionCam
		SetCVar("test_cameraDynamicPitch", 0);								--Note: "test_cameraDynamicPitch" may cause camera to jitter while reseting the player's view
		CameraUtil:SmoothShoulder(0);
		After(1, function()
			ConsoleExec( "actioncam off" );
			MoveViewRightStop();
		end)
	else
		--Restore the acioncam state
		CameraUtil:SmoothShoulder(CVarTemp.shoulderOffset);
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

	UIParentFade:FadeInUIParent();

	After(0.1, function()
		if not IntroMotion.useCameraTransition then
			SetCVar("cameraViewBlendStyle", 2);
		end

		local cameraSmoothStyle = GetCVar("cameraSmoothStyle");
		if tonumber(cameraSmoothStyle) == 0 and ViewProfile.isEnabled then		--workaround for auto-following
			SetView(5);
		else
			SetView(2);
			CameraUtil:ZoomTo(CVarTemp.zoomLevel);
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
	SetEquipmentSlotFlag("MOG_MODE", MOG_MODE);

	CameraUtil:MakeInactive();

	CallbackRegistry:Trigger("NarcissusCharacterUI.ShownState", false);
end

function Narci:EmergencyStop()
	print("Camera has been reset.");
	UIParentFade:ShowUIParent();
	MoveViewRightStop();
	MoveViewLeftStop();
	ViewProfile:ResetView(5);
	ConsoleExec( "pitchlimit 88");
	CVarTemp.shoulderOffset = 0;
	SetCVar("test_cameraOverShoulder", 0);
	SetCVar("cameraViewBlendStyle", 1);
	ConsoleExec("actioncam off");
	Narci_ModelContainer:HideAndClearModel();
	Narci_ModelSettings:Hide();
	Narci_Character:Hide();
	Narci_Attribute:Hide();
	Narci_Vignette:Hide();
	IS_OPENED = false;
	CameraUtil:SetUseMogOffset(false)
	EL:Hide();
	CameraUtil:MakeInactive();
end

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


-----------------------------------------------------------------------
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
	if not TransitionAPI.Secret_DoesStringExist(self.tooltip) then
		return
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
end


function NarciItemLevelFrameMixin:OnLoad()
	--Declared in Modules\CharacterFrame\ItemLevelFrame.lua
	ItemLevelFrame = self;
	SharedBlackScreen:SetParent(Narci_Character);
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

	ItemLevelFrame:UpdateItemLevel();
end


local function DisplayItemTransmogInfoList(itemTransmogInfoList)
	if MOG_MODE and Narci_Character:IsVisible() then
		for slotID, info in ipairs(itemTransmogInfoList) do
			--print(slotID, info.appearanceID);   --appearanceID, secondaryAppearanceID, illusionID
			if SLOT_TABLE[slotID] then
				SLOT_TABLE[slotID]:SetTransmogSourceID(info.appearanceID, info.secondaryAppearanceID);    --SetAppearance
			end
		end
	end
end
addon.DisplayItemTransmogInfoList = DisplayItemTransmogInfoList;


------------------------------------------------------------------
-----Some of the codes are derivated from EquipmentFlyout.lua-----
------------------------------------------------------------------

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

	local level = SharedBlackScreen:GetBaseFrameLevel() - 1;

	for slotID, slotButton in pairs(SLOT_TABLE) do
		ShowLessItemInfo(slotButton, false);
		slotButton:SetFrameLevel(level -1);
		slotButton.RuneSlot:SetFrameLevel(level);
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
	SharedBlackScreen:TryHide();
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
		--local level = SharedBlackScreen:GetBaseFrameLevel() -1
		--self.parentButton:SetFrameLevel(level - 1);
		--self.parentButton.RuneSlot:SetFrameLevel(level);
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

	SharedBlackScreen:TryShow();
	SharedBlackScreen:RaiseFrameLevel(slotButton);
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
			local _, _, bags, _, slot, bag = TransitionAPI.EquipmentManager_UnpackLocation(location);
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


---------------------------------------------
local function RefreshStats(id, frame)
	frame = frame or "Detailed";
	if frame == "Detailed" then
		if AttributeFrames[id] then
			AttributeFrames[id]:Update();
		end
	elseif frame == "Concise" then
		if ShortAttributeFrames[id] then
			ShortAttributeFrames[id]:Update();
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
		if AttributeFrames[i] then
			AttributeFrames[i]:Update();
		end
		if ShortAttributeFrames[i] then
			ShortAttributeFrames[i]:Update();
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
	RadarChart = Narci_RadarChartFrame;
	local radar = RadarChart;
	AttributeFrames[1] = statFrame.Primary;
	AttributeFrames[2] = statFrame.Stamina;
	AttributeFrames[3] = statFrame.Damage;
	AttributeFrames[4] = statFrame.AttackSpeed;
	AttributeFrames[5] = statFrame.Power;
	AttributeFrames[6] = statFrame.Regen;
	AttributeFrames[7] = statFrame.Health;
	AttributeFrames[8] = statFrame.Armor;
	AttributeFrames[9] = statFrame.Reduction;
	AttributeFrames[10]= statFrame.Dodge;
	AttributeFrames[11]= statFrame.Parry;
	AttributeFrames[12]= statFrame.Block;
	AttributeFrames[13]= radar.Crit;
	AttributeFrames[14]= radar.Haste;
	AttributeFrames[15]= radar.Mastery;
	AttributeFrames[16]= radar.Versatility;
	AttributeFrames[17]= statFrame.Leech;
	AttributeFrames[18]= statFrame.Avoidance;
	AttributeFrames[19]= statFrame.MovementSpeed;
	AttributeFrames[20]= statFrame.Speed;

	local statFrame_Short = Narci_ConciseStatFrame;
	ShortAttributeFrames[1]  = statFrame_Short.Primary;
	ShortAttributeFrames[2]  = statFrame_Short.Stamina;
	ShortAttributeFrames[3]  = statFrame_Short.Health;
	ShortAttributeFrames[4]  = statFrame_Short.Power;
	ShortAttributeFrames[5]  = statFrame_Short.Regen;
	ShortAttributeFrames[6]  = statFrame_Short.Crit;
	ShortAttributeFrames[7]  = statFrame_Short.Haste;
	ShortAttributeFrames[8]  = statFrame_Short.Mastery;
	ShortAttributeFrames[9]  = statFrame_Short.Versatility;
	ShortAttributeFrames[10] = statFrame_Short.Leech;
	ShortAttributeFrames[11] = statFrame_Short.Avoidance;
	ShortAttributeFrames[12] = statFrame_Short.Speed;
end

function Narci_SetPlayerName(self)
	local playerName = UnitName("player");
	local editBox = self.PlayerName or self.MogNameEditBox;
	editBox:SetShadowColor(0, 0, 0);
	editBox:SetShadowOffset(2, -2);
	editBox:SetText(playerName);
	SmartFontType(editBox);
end

local function Narci_Close()
	if Narci.showExitConfirm and not InCombatLockdown() then
		local ExitConfirm = Narci_ExitConfirmationDialog;
		if not ExitConfirm:IsShown() then
			FadeFrame(ExitConfirm, 0.25, 1);

			SetUIVisibility(false);
			MiniButton:Enable();
			UIParent:SetAlpha(1);

			return
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

function Narci_Open()
	if not IS_OPENED then
		if InCombatLockdown() then
			return
		end

		InitializeSlotButtons();

		IS_OPENED = true;
		CVarTemp:BackUp();
		Toolbar:ShowUI("Narcissus");
		ViewProfile:SaveView(5);
		CameraUtil:DisableMotionSickness();
		CameraUtil:UpdateParameters();
		CameraUtil:MakeActive();
		CameraUtil:SetUseMogOffset(false)

		EL:Show();
		IntroMotion:Enter();

		After(0, function()
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
		CallbackRegistry:Trigger("NarcissusCharacterUI.ShownState", true);
	else
		Narci_Close();
	end

	NarciAPI.UpdateSessionTime();
end

function Narci_OpenGroupPhoto()
	if not IS_OPENED then
		if InCombatLockdown() then
			return;
		end

		InitializeSlotButtons();

		IS_OPENED = true;
		CVarTemp:BackUp();
		Toolbar:ShowUI("PhotoMode");
		ViewProfile:SaveView(5);
		CameraUtil:DisableMotionSickness();
		CameraUtil:UpdateParameters();
		CameraUtil:MakeActive();
		SetCVar("test_cameraDynamicPitch", 1);

		EL:Show();

		CameraUtil:SmoothPitch();
		UIParentFade:FadeOutUIParent();

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
		end)

		Narci.isActive = true;
		CallbackRegistry:Trigger("NarcissusCharacterUI.ShownState", true);
		MsgAlertContainer:Display();
		NarciAPI.UpdateSessionTime();
	else
		Narci_Close();
	end
end


------------------------------------------------------
------------------Photo Mode Controller---------------
------------------------------------------------------
function Narci_KeyListener_OnEscapePressed(self)
	if IS_OPENED then
		MiniButton:Click();
		if self then
			if not InCombatLockdown() then
				self:SetPropagateKeyboardInput(false);
			end
		end
	end
end

local function UseXmogLayout()
	CameraUtil:SetUseMogOffset(true);
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
			CameraUtil:SmoothPitch();
			CameraUtil:ZoomToDefault(true);
		else
			CameraUtil:ZoomTo(8);
		end
	end)
end

local function ActivateMogMode()
	Narci_GuideLineFrame.VirtualLineRight.AnimFrame:Hide();

	if MOG_MODE then
		FadeFrame(Narci_Attribute, 0.5, 0)
		FadeFrame(Narci_XmogNameFrame, 0.2, 1, 0)
		CameraUtil:SetUseMogOffset(true);
		NarciPlayerModelFrame1.xmogMode = 2;
		MsgAlertContainer:Display();
		UseXmogLayout();
	else
		Narci_GuideLineFrame.VirtualLineRight.AnimFrame.toX = Narci_GuideLineFrame.VirtualLineRight.AnimFrame.defaultX;
		if Toolbar:IsShown() then
			Narci_GuideLineFrame.VirtualLineRight.AnimFrame:Show();
			FadeFrame(Narci_Attribute, 0.5, 1);
			CameraUtil:SmoothShoulderByZoom();
		end
		FadeFrame(Narci_XmogNameFrame, 0.2, 0);
		ShowAttributeButton();
		CameraUtil:SetUseMogOffset(false);
		MsgAlertContainer:Hide();
		RadarChart:SetValue();
	end
end

local ClassArmorSubclass = {
    MAGE = 1, PRIEST = 1, WARLOCK = 1,    --Cloth
    ROGUE = 2, DRUID = 2, MONK = 2, DEMONHUNTER = 2,    --Leather
    HUNTER = 3, SHAMAN = 3, EVOKER = 3,    --Mail
    WARRIOR = 4, PALADIN = 4, DEATHKNIGHT = 4,    --Plate
};

local function GetArmorTypeByClass(classFile)
	local subclassID = ClassArmorSubclass[classFile];
	if subclassID then
		return (C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, subclassID));
	end
end

local function UpdateXmogName(specOnly)
	local frame = Narci_XmogNameFrame;

	if not specOnly then
		Narci_SetPlayerName(frame);
	end

	local className, englishClass = UnitClass("player");
	local _, _, _, rgbHex = GetClassColor(englishClass);
	local armorType = GetArmorTypeByClass(englishClass);

	if armorType then
		frame.ArmorString:SetText("|cFFFFD100"..armorType.."|r".."  |  ".."|c"..rgbHex..className.."|r");
	else
		frame.ArmorString:SetText("|c"..rgbHex..className.."|r");
	end
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
	SetEquipmentSlotFlag("MOG_MODE", MOG_MODE);

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
				CameraUtil:SmoothPitch();
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
		end

		StatsUpdator:Gradual();
	end

	if MOG_MODE then
		SlotController:RefreshAll();
	else
		SlotController:LazyRefresh();
	end

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


do	--Slash Command
	local function callback(msg)
		if not msg then
			msg = "";
		end

		msg = string.lower(msg);
		if msg == "" then
			MiniButton:Click();
		elseif msg == "minimap" then
			MiniButton:EnableButton();
			print(L["MinimapButton Reenabled"]);
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

	NarciAPI.CreateSlashCommand(callback, "narci", "narcissus");
end


--3D Animation
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


		UpdateXmogName();
		DefaultTooltip = NarciGameTooltip;
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

		elseif C_AddOns.IsAddOnLoaded("ActionCamPlus") then
			CVarTemp.isActionCamPlusLoaded = true;
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
				CameraUtil:UpdateMovementMethodForDynamicCam();
			else
				hooksecurefunc("CameraZoomIn", function(increment)
					if IS_OPENED and (not Narci.groupPhotoMode) then
						CameraUtil:SmoothShoulderByZoom(-increment);
					end
				end)

				hooksecurefunc("CameraZoomOut", function(increment)
					if IS_OPENED and (not Narci.groupPhotoMode) then
						CameraUtil:SmoothShoulderByZoom(-increment);
					end
				end)
			end
		end)

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		local slotID, isItem = ...;
		SlotController:Refresh(slotID);

		if EquipmentFlyoutFrame:IsShown() and EquipmentFlyoutFrame.slotID then
			EquipmentFlyoutFrame:DisplayItemsBySlotID(EquipmentFlyoutFrame.slotID, false);
		end

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
				RadarChart:UpdateChart(true);
			end
		end

		if event == "UNIT_AURA" then
			--11.0 Worgen Two Forms no longer trigger this
			local inAlteredForm = IsPlayerInAlteredForm();
			if self.wasAlteredForm ~= inAlteredForm then
				self.wasAlteredForm = inAlteredForm;
				CameraUtil:OnPlayerFormChanged(0.0);
			end
		end

	elseif event == "PLAYER_TARGET_CHANGED" then
		RefreshStats(8);		--Armor
		RefreshStats(9); 		--Damage Reduction

	elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UNIT_PORTRAIT_UPDATE" then
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

	elseif event == "WEAPON_ENCHANT_CHANGED" then
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
	if (self.t < 0.25 and self.t > 0.03) and NarcissusDB.EnableDoubleTap then
		MiniButton:Click();
	end
end

----------------------------------------------------------------------
function Narci_GuideLineFrame_OnSizing(self, offset)
	local W;
	local W0, H = WorldFrame:GetSize();
	if (W0 and H) and H ~= 0 then
		local ratio = floor(W0 / H * 100 + 0.5) / 100;
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

function Narci_GuideLineFrame_SnapToFinalPosition()
	local animFrames = {
		Narci_GuideLineFrame.VirtualLineLeft.AnimFrame,
		Narci_GuideLineFrame.VirtualLineRight.AnimFrame,
	};

	for _, animFrame in ipairs(animFrames) do
		animFrame:Hide();
		if animFrame.frame then
			animFrame.frame:SetPoint(animFrame.anchorPoint, animFrame.toX, 0);
		end
	end
end


Narci.GetEquipmentSlotByID = function(slotID) return SLOT_TABLE[slotID] end;
Narci.RefreshSlot = function(slotID) SlotController:Refresh(slotID) return SLOT_TABLE[slotID] end;
Narci.RefreshAllSlots = SlotController.RefreshAll;
Narci.RefreshAllStats = StatsUpdator.Instant;


addon.CallbackRegistry:Register("SettingChanged.UseWoWQualityColor", function()
	if Narci_Character:IsVisible() then
		SlotController:RefreshAll(true);
	end
end);


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

		local font, _, flag;

		for id, slotButton in pairs(SLOT_TABLE) do
			if not font then
				font, _, flag = slotButton.Name:GetFont();
			end
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

		IntroMotion:SetUseCameraTransition(state);
	end

	function SettingFunctions.EnableCameraSafeMode(state, db)
		if state == nil then
			state = db["CameraSafeMode"];
		end
		CVarTemp.cameraSafeMode = state;
	end

	function SettingFunctions.EnableMissingEnchantAlert(state, db)
		if state == nil then
			state = db["MissingEnchantAlert"];
		end

		--only enabled when player reach max level
		if not NarciAPI.IsPlayerAtMaxLevel() then
			state = false;
		end

		SetEquipmentSlotFlag("SHOW_MISSING_ENCHANT_ALERT", state);
		SlotButtonOverlayUtil:SetEnabled(state);

		SlotController:ClearCache();
		if Narci_Character and Narci_Character:IsShown() then
			SlotController:LazyRefresh();
		end
	end
end




NarciCharacterUIPlayerNameEditBoxMixin = {};
do
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
end


NarciCharacterUIAliasButtonMixin = {};
do
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
end


UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED");  --Disable EXPERIMENTAL_CVAR_WARNING
