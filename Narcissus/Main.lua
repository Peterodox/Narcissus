local _, addon = ...

local MsgAlertContainer = addon.MsgAlertContainer;
local TransitionAPI = addon.TransitionAPI;
local SlotButtonOverlayUtil = addon.SlotButtonOverlayUtil;
local TimerunningUtil = addon.TimerunningUtil;
local TalentTreeDataProvider = addon.TalentTreeDataProvider;
local CameraUtil = addon.CameraUtil;
local UIParentFade = addon.UIParentFade;
local CallbackRegistry = addon.CallbackRegistry;
local API = addon.API;


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

if API.IsPlayerDruid() then
	table.insert(EL.EVENTS_DYNAMIC, "UPDATE_SHAPESHIFT_FORM");
end

EL.EVENTS_UNIT = {"UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_INVENTORY_CHANGED", "UNIT_PORTRAIT_UPDATE"};


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
		table.insert(self:GetParent().slotTable, self);
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
				Narci_EquipmentOption:SetFromSlotButton(self, true);
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
	table.insert(SlotController.tempEnchantSequence, slotID);
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
		table.insert(texs, tex);
		tex:SetSize(12, 12);
		tex:SetTexture(circleTex, nil, nil, filter);
	end

	self.vertices = texs;

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;

	self.deg = math.deg;
	self.rad = math.rad;
	self.atan2 = math.atan2;
	self.sqrt = math.sqrt;
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
	ColorUtil:SetWidgetColor(self.MaskedBackground);
	ColorUtil:SetWidgetColor(self.MaskedBackground2);
	ColorUtil:SetWidgetColor(self.MaskedLine1);
	ColorUtil:SetWidgetColor(self.MaskedLine2);
	ColorUtil:SetWidgetColor(self.MaskedLine3);
	ColorUtil:SetWidgetColor(self.MaskedLine4);
end

local GetEffectiveCrit = Narci.GetEffectiveCrit;
local GetCombatRating = GetCombatRating;

function NarciRadarChartMixin:SetValue(c, h, m, v, manuallyInPutSum)
	--c, h, m, v: Input manually or use combat ratings

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

	local ma1 = self.atan2((y1 - y2), (x1 - x2));
	local ma2 = self.atan2((y2 - y4), (x2 - x4));
	local ma3 = self.atan2((y4 - y3), (x4 - x3));
	local ma4 = self.atan2((y3 - y1), (x3 - x1));

	if my1 == 0 then
		my1 = 0.01;
	end
	if my3 == 0 then
		my1 = -0.01;
	end
	if self.deg(ma1) == 90 then
		ma1 = self.rad(89);
	end
	if self.deg(ma3) == -90 then
		ma1 = self.rad(-89);
	end

	Radar.vertices[1]:SetPoint("CENTER", x1, y1);
	Radar.vertices[2]:SetPoint("CENTER", x2, y2);
	Radar.vertices[3]:SetPoint("CENTER", x3, y3);
	Radar.vertices[4]:SetPoint("CENTER", x4, y4);

	Radar.Mask1:SetRotation(ma1);
	Radar.Mask2:SetRotation(ma2);
	Radar.Mask3:SetRotation(ma3);
	Radar.Mask4:SetRotation(ma4);

	local hypo1 = self.sqrt(2*x1^2 + 2*x2^2);
	local hypo2 = self.sqrt(2*x2^2 + 2*x4^2);
	local hypo3 = self.sqrt(2*x4^2 + 2*x3^2);
	local hypo4 = self.sqrt(2*x3^2 + 2*x1^2);

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
	local sum = e1 + e2 + e3 + e4;
	local bestSum;

	if playerLevel == 50 then
		bestSum = max(sum, 800);		--Status Sum for 8.3 Raid
	elseif playerLevel == 60 then
		bestSum = max(sum, 2500);		--Status Sum for 9.1 Raid
	elseif playerLevel == 80 then
		local cap = 27000;
		if sum < 0.4*cap then
			bestSum = 1.5 * sum;
		else
			bestSum = max(sum, cap);
		end
	else
		--sum = 31 * math.exp( 0.04 * UnitLevel("player")) + 40;
		bestSum = 1.5 * sum;
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
		Radar:SetValue(v1, v2, v3, v4, bestSum);
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
			return
		end
		IS_OPENED = true;
		CVarTemp:BackUp();
		Toolbar:ShowUI("Narcissus");
		ViewProfile:SaveView(5);
		CameraUtil:DisableMotionSickness();
		CameraUtil:UpdateParameters();
		CameraUtil:MakeActive();
		CameraUtil:SetUseMogOffset(false)

		EL:Show();

		After(0, function()
			IntroMotion:Enter();
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
		if Narci.showExitConfirm and not InCombatLockdown() then
			local ExitConfirm = Narci_ExitConfirmationDialog;
			if not ExitConfirm:IsShown() then
				FadeFrame(ExitConfirm, 0.25, 1);

				After(0, function()
					SetUIVisibility(false);
					MiniButton:Enable();
					UIParent:SetAlpha(1);
				end);

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
		CameraUtil:DisableMotionSickness();
		CameraUtil:UpdateParameters();
		CameraUtil:MakeActive();
		SetCVar("test_cameraDynamicPitch", 1);

		EL:Show();

		CameraUtil:SmoothPitch();

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

			UIParentFade:FadeOutUIParent();
		end)

		Narci.isActive = true;
		CallbackRegistry:Trigger("NarcissusCharacterUI.ShownState", true);
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


do
	--Slash Command
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

	--local commandName = "narci";
	--local commandAlias = "narcissus";
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

		if TimerunningUtil.IsTimerunningMode() then
			Narci.deferGemManager = true;
		end
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
				RadarChart:AnimateValue();
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