----------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
local _G = _G;
local L = Narci.L;
local After = C_Timer.After;
local C_TransmogCollection = C_TransmogCollection;
local IsFavorite = C_TransmogCollection.GetIsAppearanceFavorite;
local IsHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual;
local GetOutfitInfo = C_TransmogCollection.GetOutfitInfo;
local InCombatLockdown = InCombatLockdown;

local DressUpFrame = DressUpFrame;

local FadeFrame = NarciFadeUI.Fade;
local GetInspectSources = C_TransmogCollection.GetInspectSources or C_TransmogCollection.GetInspectItemTransmogInfoList;        --API changed in 9.1.0

local WIDTH_HEIGHT_RATIO;
do
    local DEFAULT_WIDTH, DEFAULT_HEIGHT = 450, 545;       --BLZ dressing room size
    WIDTH_HEIGHT_RATIO = DEFAULT_WIDTH/DEFAULT_HEIGHT;
end
local HEIGHT_MULTIPLIER = 0.8;  --/dump DressUpFrame:SetAttribute("UIPanelLayout-extraWidth", -500) /dump GetUIPanelWidth(DressUpFrame)
local OVERRIDE_HEIGHT = math.floor(GetScreenHeight()*HEIGHT_MULTIPLIER + 0.5);
local OVERRIDE_WIDTH = math.floor(WIDTH_HEIGHT_RATIO * OVERRIDE_HEIGHT + 0.5);

--print(OVERRIDE_HEIGHT, OVERRIDE_WIDTH)

local SLOT_FRAME_ENABLED = true;              --If DressUp addon is loaded, hide our slot frame
local USE_TARGET_MODEL = true;                --Replace your model with target's

local GetActorInfoByUnit = NarciAPI_GetActorInfoByUnit;


--Frames:
local DressingRoomOverlayFrame;
local DressingRoomItemButtons = {};
local OutfitIconSelect;

local function CreateSlotButton(frame)
    local container = frame.SlotFrame;
    local slotArrangement = {
        [1] = {"HeadSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot"},
        [2] = {"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot"},
        [3] = {"MainHandSlot", "SecondaryHandSlot"},
        [4] = {"ShirtSlot", "TabardSlot"},
    };

    local button, slotID;
    local buttons = {};
    local buttonWidth;
    local offsetY = 12;
    local buttonGap = 4;
    local extrudeX = 16;
    local fullWidth = extrudeX;

    for sectorIndex = 1, #slotArrangement do
        if sectorIndex ~= 1 then
            fullWidth = fullWidth + 12;
        end
        for i = 1, #slotArrangement[sectorIndex] do
            button = CreateFrame("Button", nil, container, "NarciRectangularItemButtonTemplate");
            slotID = button:Init(slotArrangement[sectorIndex][i]);
            buttons[slotID] = button;
            button:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", fullWidth, offsetY);
            if not buttonWidth then
                buttonWidth = math.floor(button:GetWidth() + 0.5);
            end
            fullWidth = fullWidth + buttonWidth + buttonGap;
        end
    end
    DressingRoomItemButtons = buttons;
    fullWidth = fullWidth + extrudeX;
    container:SetWidth(fullWidth);

    slotArrangement = nil;
end


--------------------------------------------------
local DataProvider = {};

DataProvider.isCurrentModelPlayer = false;
DataProvider.inspectedPlayerGUID = {};

function DataProvider:GetActorSlotSourceID(actor, slotID)
    if not self.isLoaded then
        if actor.GetItemTransmogInfo then
            self.isNewAPI = true;
        else
            self.isNewAPI = false;
        end
        self.isLoaded = true;
    end

    if self.isNewAPI then
        local transmogInfo = actor:GetItemTransmogInfo(slotID);
        if transmogInfo then
            if slotID == 16 or slotID == 17 then
                return (transmogInfo.appearanceID or 0), (transmogInfo.illusionID or 0);
            else
                return (transmogInfo.appearanceID or 0), (transmogInfo.secondaryAppearanceID or 0);
            end
        else
            return 0, 0;
        end
    else
        return actor:GetSlotTransmogSources(slotID);
    end
end

function DataProvider:SetInspectedUnit(unit)
    local guid = UnitGUID(unit);
    self.inspectedPlayerGUID[guid] = true;
end

function DataProvider:IsInspectedUnit(guid)
    if self.inspectedPlayerGUID[guid] then
        self.inspectedPlayerGUID[guid] = nil;
        return true
    else
        return false
    end
end

function DataProvider:UnitInQueue()
    local hasUnit = false;
    for guid, monitored in pairs(self.inspectedPlayerGUID) do
        if monitored then
            hasUnit = true;
            break
        end
    end
    return hasUnit
end

-------Create Mogit List-------
local newSet = {items = {}}
-------------------------------
local UnitInfo = {
    raceID = nil,
    genderID = nil,
    classID = nil,
};

--Background Transition Animation--
local function Narci_SetDressUpBackground(unit, instant)
    local _, atlasPostfix = UnitClass(unit or "player");
    local frame = DressUpFrame;
    if ( frame.ModelBackground and frame.ModelBackgroundOverlay and atlasPostfix ) then
        if instant then
            frame.ModelBackground:SetAtlas("dressingroom-background-"..atlasPostfix);
        else
            frame.ModelBackgroundOverlay:SetAtlas("dressingroom-background-"..atlasPostfix);
            frame.ModelBackgroundOverlay:StopAnimating();
            frame.ModelBackgroundOverlay.animIn:Play();
        end
	end
end

local function GetDressingSourceFromActor()
    local slotID;
    local buttons = DressingRoomItemButtons;
    local appliedSourceID;
    local secondarySourceID;    --secondarySourceID or illusionID
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
    if not playerActor then return end;

    for k, slotButton in pairs(buttons) do
        slotID = slotButton.slotID;
        appliedSourceID, secondarySourceID = DataProvider:GetActorSlotSourceID(playerActor, slotID);
        if not slotButton:IsSameSouce(appliedSourceID, secondarySourceID) then
            slotButton:SetItemSource(appliedSourceID, secondarySourceID);
        end
    end
end

local function DressingRoomOverlayFrame_OnLoad(self)
    self:SetParent(DressUpFrame);
    self:GetParent():SetMovable(true);
    self:GetParent():RegisterForDrag("LeftButton");
    self:GetParent():SetScript("OnDragStart", function(self)
        self:StartMoving();
    end);
    self:GetParent():SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
    end);

    self.mode = "visual";

    local GearTextScrollFrame = self.OptionFrame.SharedPopup.GearTextContainer.ScrollFrame;
    local totalHeight = 240;
    local maxScroll = totalHeight;
    GearTextScrollFrame.buttonHeight = 14;
    GearTextScrollFrame.scrollBar:SetRange(maxScroll, true);
    NarciAPI_SmoothScroll_Initialization(GearTextScrollFrame, nil, nil, 2, 0.14);
end


local PrintItemList = NarciDressingRoomAPI.PrintItemList;

local function IsDressUpFrameMaximized()
    return (DressUpFrame.MaximizeMinimizeFrame and not DressUpFrame.MaximizeMinimizeFrame:IsMinimized())
end

local function UpdateDressingRoomExtraWdith()
    --Speculative Fix: Not enough room to display EncounterJournal and DressUpFrame at the same time
    if not InCombatLockdown() then
       --DressUpFrame:SetAttribute("UIPanelLayout-extraWidth", (IsDressUpFrameMaximized() and -100) or 0);   --self.OutfitDetailsPanel
       DressUpFrame:SetAttribute("UIPanelLayout-width", (IsDressUpFrameMaximized() and 450) or 334);    --DressUpModelFrameMixin:ConfigureSize(isMinimized)
    end
end

local function InitializeActor(actor, actorInfo)
    --[[
	actor:SetUseCenterForOrigin(actorInfo.useCenterForOriginX, actorInfo.useCenterForOriginY, actorInfo.useCenterForOriginZ);
	actor:SetPosition(actorInfo.position:GetXYZ());
	actor:SetYaw(actorInfo.yaw);
	actor:SetPitch(actorInfo.pitch);
	actor:SetRoll(actorInfo.roll);
    actor.requestedScale = nil;
    actor:SetAnimation(0, 0, 1.0);
    actor:SetAlpha(1.0);
    actor:SetScale(actorInfo.scale or 1.0);
    --]]

    actor:SetUseCenterForOrigin(actorInfo.useCenterForOriginX, actorInfo.useCenterForOriginY, actorInfo.useCenterForOriginZ);
	actor:SetPosition(actorInfo.position:GetXYZ());
	actor:SetYaw(actorInfo.yaw);
	actor:SetPitch(actorInfo.pitch);
	actor:SetRoll(actorInfo.roll);
	actor.requestedScale = nil;
    actor:SetAlpha(1.0);
    actor:SetRequestedScale(1.0);
	actor:SetNormalizedScaleAggressiveness(actorInfo.normalizeScaleAggressiveness or 0.0);
	actor:MarkScaleDirty();
	actor:UpdateScale();
end

local function UpdateDressingRoomModelByUnit(unit)
    if not DressingRoomOverlayFrame then
        return
    end
    unit = unit or "player";
    local overlay = DressingRoomOverlayFrame;
    if not UnitExists(unit) then
        return
    else
        if UnitIsPlayer(unit) then
            if CanInspect(unit, false) then
                overlay.OptionFrame.InspectButton:Enable();
                if UnitIsUnit(unit, "player") and UnitOnTaxi("player") then
                    --Somehow you won't receive INSPECT_READY when you are on a vehicle
                    overlay.SlotFrame:ShowPlayerTransmog();
                    return
                end
            else
                overlay.OptionFrame.InspectButton:Disable();
            end
        else
            overlay.OptionFrame.InspectButton:Disable();
            return;
        end
    end

    Narci_SetDressUpBackground(unit);
    local ModelScene = DressUpFrame.ModelScene;
    local actor = ModelScene:GetPlayerActor();
    if not actor then return; end;

    --Acquire target's gears
    overlay:RegisterEvent("INSPECT_READY");
    DataProvider:SetInspectedUnit(unit);
    NotifyInspect(unit);

    local _;
    _, _, UnitInfo.raceID = UnitRace(unit);
    UnitInfo.genderID = UnitSex(unit);
    _, _, UnitInfo.classID = UnitClass(unit);

    local modelUnit;
    local updateScale;
    local sheatheWeapons = actor:GetSheathed() or false;

    if USE_TARGET_MODEL then
        modelUnit = unit;
        actor:SetModelByUnit(modelUnit, sheatheWeapons, true);
        updateScale = true;
        DataProvider.isCurrentModelPlayer = false;
    else
        modelUnit = "player";
        if not DataProvider.isCurrentModelPlayer then
            DataProvider.isCurrentModelPlayer = true;
            actor:SetModelByUnit(modelUnit, sheatheWeapons, true);
            updateScale = true;
        end
    end

    if updateScale then
        local modelInfo;
        modelInfo = GetActorInfoByUnit(modelUnit);
        if modelInfo then
            After(0.0,function()
                --InitializeActor(actor, modelInfo)
                actor:ApplyFromModelSceneActorInfo(modelInfo)
            end);
        end
    end

    return true
end

local function RefreshFavoriteState(visualID)
    local buttons = DressingRoomItemButtons;
    local state;
    for slot, button in pairs(buttons) do
        if button.visualID and button.visualID == visualID then
            state = IsFavorite(button.visualID);
            button:UpdateBottomMark();
            local note = button:GetParent().Notification;
            note.fadeOut:Stop();
            note:ClearAllPoints();
            note:SetPoint("TOP", button, "BOTTOM", 0, 0);
            if state then
                note:SetText("|cffffe8a5"..L["Favorited"]);
            else
                note:SetText("|cffcccccc"..L["Unfavorited"]);
            end
            note.fadeOut:Play();

            if slot == 16 then
                local offHandSlot = buttons[17];
                if offHandSlot.visualID and offHandSlot.visualID == visualID then
                    offHandSlot:UpdateBottomMark();
                end
            end

            return
        end
    end
end

local function NarciBridge_MogIt_SaveButton_OnClick(self)
    StaticPopup_Show("MOGIT_WISHLIST_CREATE_SET", nil, nil, newSet);    --Create a new whishlist
    MogIt.view:Show();  --Open a view window
end

local function ShareButton_OnClick(self)
    local Popup = NarciDressingRoomSharedPopup;
    if not Popup:IsShown() then
        Popup:Show();
        PrintItemList();
        Popup.GearTextContainer:SetFocus();
    else
        Popup:Hide();
    end
end

local function InspectButton_OnClick(self)
    local state = NarcissusDB.DressingRoomUseTargetModel;
    NarcissusDB.DressingRoomUseTargetModel = not state;
    USE_TARGET_MODEL = not state;
    self.USE_TARGET_MODEL = not state;
    if not state then   --true
        self.Label:SetText(self.targetModelText);
    else
        self.Label:SetText(self.yourModelText);
    end
    UpdateDressingRoomModelByUnit("target");
end

function Narci_UpdateDressingRoom()
    local frame = DressingRoomOverlayFrame;
    if not frame or not SLOT_FRAME_ENABLED then return end;

    frame.mode = "visual";

    if not frame.pauseUpdate then
        frame.pauseUpdate = true;
        After(0, function()
            if SLOT_FRAME_ENABLED and IsDressUpFrameMaximized() then
                frame.SlotFrame:Show();
                frame.OptionFrame:Show();
                GetDressingSourceFromActor();
                PrintItemList();
            end
            frame.pauseUpdate = nil;
        end)
    end
end

local Narci_UpdateDressingRoom = Narci_UpdateDressingRoom;

local function SetupPlayerForModelScene(modelScene, itemModifiedAppearanceIDs, sheatheWeapons, autoDress, hideWeapons)
	local actor = modelScene:GetPlayerActor();
	if actor then
		sheatheWeapons = (sheatheWeapons == nil) or sheatheWeapons;
		hideWeapons = (hideWeapons == nil) or hideWeapons;
        actor:SetModelByUnit("player", sheatheWeapons, autoDress, hideWeapons);
		if itemModifiedAppearanceIDs then
			for i, itemModifiedAppearanceID in ipairs(itemModifiedAppearanceIDs) do
				actor:TryOn(itemModifiedAppearanceID);
			end
		end
		actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_NONE);
	end
end

local function TransitionToModelSceneID(self, modelSceneID, cameraTransitionType, cameraModificationType, forceEvenIfSame)
	local modelSceneType, cameraIDs, actorIDs = C_ModelInfo.GetModelSceneInfoByID(modelSceneID);
	if not modelSceneType or #cameraIDs == 0 or #actorIDs == 0 then
		return;
	end
	if self.modelSceneID ~= modelSceneID or forceEvenIfSame then
		self.modelSceneID = modelSceneID;
		self.cameraTransitionType = cameraTransitionType;
		self.cameraModificationType = cameraModificationType;
		self.forceEvenIfSame = forceEvenIfSame;
		local actorsToRelease = {};
		for actor in self:EnumerateActiveActors() do
			actorsToRelease[actor] = true;
		end
		local oldTagToActor = self.tagToActor;
		self.tagToActor = {};
		for actorIndex, actorID in ipairs(actorIDs) do
			local actor = self:CreateOrTransitionActorFromScene(oldTagToActor, actorID);    --Taint!
			if actor then
				actorsToRelease[actor] = nil;
			end
		end
		for actor in pairs(actorsToRelease) do
			self.actorPool:Release(actor);
		end
		local oldTagToCamera = self.tagToCamera;
		self.tagToCamera = {};
		self.cameras = {};
		local needsNewCamera = true;
		for cameraIndex, cameraID in ipairs(cameraIDs) do
			local camera = self:CreateOrTransitionCameraFromScene(oldTagToCamera, cameraTransitionType, cameraModificationType, cameraID);
			if camera == self.activeCamera then
				needsNewCamera = false;
			end
		end
		if needsNewCamera then
			self:SetActiveCamera(self.cameras[1]);
		end
		-- HACK: This should come from game data, instead we're caching them incase we Reset()
		self.lightDirX, self.lightDirY, self.lightDirZ = self:GetLightDirection();
	end
	C_ModelInfo.AddActiveModelScene(self, self.modelSceneID);
end

function Narci_ShowDressingRoom()
    local frame = DressUpFrame;
    --derivated from Blizzard DressUpFrames.lua / DressUpFrame_Show
    if ( not frame:IsShown() ) then
        if InCombatLockdown() then
            frame:Show();
            DressingRoomOverlayFrame:ListenEscapeKey(true);
        else
            DressUpFrame_Show(frame);   --!! This one taints !!
        end

        if frame.mode ~= "player" then
            frame.mode = "player";
            frame.ResetButton:SetShown(true);
            frame.MaximizeMinimizeFrame:Maximize(true);
            frame.ModelScene:ClearScene();
            frame.ModelScene:SetViewInsets(0, 0, 0, 0);
            TransitionToModelSceneID(frame.ModelScene, 290, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true);  --Taint
            local sheatheWeapons = false;
            local autoDress = true;
            local itemModifiedAppearanceIDs = nil;
            SetupPlayerForModelScene(frame.ModelScene, itemModifiedAppearanceIDs, sheatheWeapons, autoDress);
            --Narci_UpdateDressingRoom();
        end
        

        if SLOT_FRAME_ENABLED then
            UpdateDressingRoomModelByUnit("player");
        end

        if DressUpFrame.OutfitDetailsPanel then
            DressUpFrame.OutfitDetailsPanel:SetShown(GetCVarBool("showOutfitDetails"));
            --DressUpFrame:SetShownOutfitDetailsPanel(GetCVarBool("showOutfitDetails"));
        end
	end
end


----------------------------------------------------------------------------------------
local Adaptor = {};

function Adaptor:IsBetterWardrobeDressingRoomEnabled()
    local hasBW = IsAddOnLoaded("BetterWardrobe");
    if hasBW then
        local db = BetterWardrobe_Options;
        if db then
            local playerName = UnitName("player");
            local realmName = GetRealmName();   --GetNormalizedRealmName
            local searchKey = playerName .. " - "..realmName;
            local profileKey = "Default";
            if db.profileKeys then
                profileKey = db.profileKeys[searchKey] or profileKey;
            end
            local settings = db.profiles[profileKey];
            if settings then
                return settings.DR_OptionsEnable
            end
        end
    end
end

function Adaptor:IsAddOnDressUpEnabled()
    return IsAddOnLoaded("DressUp");
end

function Adaptor:IsConflictedAddOnLoaded()
    local result = (self:IsBetterWardrobeDressingRoomEnabled() or self:IsAddOnDressUpEnabled());
    Adaptor = nil;
    return result;
end


local function OverrideMaximizeFunc()
    local ReScaleFrame = DressUpFrame.MaximizeMinimizeFrame;

    if ReScaleFrame then
        local function OnMaximize(f)
            f:GetParent():SetSize(OVERRIDE_WIDTH, OVERRIDE_HEIGHT);   --Override DressUpFrame Resize Mixin
            UpdateUIPanelPositions(f);
        end
        ReScaleFrame:SetOnMaximizedCallback(OnMaximize);

        hooksecurefunc(DressUpFrame.MaximizeMinimizeFrame, "Minimize", function(f, isAutomaticAction)
            if isAutomaticAction then
                ReScaleFrame:Maximize(true);
            end
        end)
    end
end

--Feature: Mouseover "WardrobeOutfitButton to preview the outfit
local OutfitPreviewModel;

local function HidePreviewModel()
    if OutfitPreviewModel then
        OutfitPreviewModel:Hide();
    end
end

local function PreviewModel_OnUpdate(f, elapsed)
    f.t = f.t + elapsed;
    if f.t >= 0 and f.outfitID and not f.dressed then
        for i, transmogInfo in ipairs(C_TransmogCollection.GetOutfitItemTransmogInfoList(f.outfitID)) do
            f:SetItemTransmogInfo(transmogInfo);
        end
        f.dressed = true;
    end
    if f.t > 0.25 then
        f:SetModelAlpha(1);
        f:SetScript("OnUpdate", nil);
    elseif f.t > 0.05 then
        f:SetModelAlpha(f.t * 4);
    end
end

local function OutfitDropDownButton_OnEnterCallback(self)
    if self.outfitID then
        if not OutfitPreviewModel then
            OutfitPreviewModel = CreateFrame("DressUpModel", nil, WardrobeOutfitFrame);
            local m = OutfitPreviewModel;
            m:SetSize(129, 186);
            m:SetAutoDress(false);
            m:SetUnit("player");
            m:FreezeAnimation(0, 0, 0);
            local x, y, z = m:TransformCameraSpaceToModelSpace(0, 0, -0.25);    ---0.25
            m:SetPosition(x, y, z);
            m:SetLight(true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);
            --NarciAPI.InitializeModelLight(m);
            m:SetViewTranslation(0, -57);
            m:SetScript("OnHide", function(f)
                f:Hide();
                f.outfitID = nil;
                f:SetScript("OnUpdate", nil);
            end);
            m:SetScript("OnShow", function()
                --m:RefreshUnit();
            end);
        end

        if OutfitPreviewModel.outfitID == self.outfitID then
            return
        end

        OutfitPreviewModel.outfitID = self.outfitID;
        OutfitPreviewModel:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 0);
        OutfitPreviewModel.t = -0.2;
        OutfitPreviewModel.dressed = nil;
        OutfitPreviewModel:Show();
        OutfitPreviewModel:SetScript("OnUpdate", PreviewModel_OnUpdate);
        OutfitPreviewModel:Undress();
        OutfitPreviewModel:SetModelAlpha(0);

        local detailsCameraID, transmogCameraID = C_TransmogSets.GetCameraIDs();
        Model_ApplyUICamera(OutfitPreviewModel, transmogCameraID);
    else
        HidePreviewModel();
    end
end

local OutfitButtonHooked = {};

local function OutfitDropDown_UpdateCallback(self)
    local numButtons = (self.Buttons and #self.Buttons) or 0;
    for i = 1, numButtons do
        if not OutfitButtonHooked[i] then
            OutfitButtonHooked[i] = true;
            self.Buttons[i]:HookScript("OnEnter", OutfitDropDownButton_OnEnterCallback);
        end
    end
    local width = self.dropDown.maxMenuStringWidth or 216;
    self:SetWidth(width + 60)
end



local function DressingRoomOverlayFrame_Initialize()
    if not (NarcissusDB and NarcissusDB.DressingRoom) then return; end;

    local parentFrame = DressUpFrame;
    if not parentFrame then 
        print("Narcissus failed to initialize Advanced Dressing Room");
        return;
    end

    local frame = CreateFrame("Frame", "NarciDressingRoomOverlay", parentFrame, "NarciDressingRoomOverlayTemplate")
    CreateSlotButton(frame)
    DressingRoomOverlayFrame_OnLoad(frame);
    UpdateDressingRoomExtraWdith();

    local texName = parentFrame:GetName() and parentFrame:GetName().."BackgroundOverlay"
    local tex = parentFrame:CreateTexture(texName, "BACKGROUND", "NarciDressingRoomBackgroundTemplate", 2)

    hooksecurefunc("DressUpVisual", Narci_UpdateDressingRoom);

    local function SetDressingRoomMode(mode, link)
        frame.mode = mode;
        frame.SlotFrame:Hide();
        frame.OptionFrame:Hide();
    end

    hooksecurefunc("DressUpMountLink", function(link)
        --[[
        if link then
            local _, _, _, linkType, linkID = strsplit(":|H", link);
            if linkType == "item" or linkType == "spell" then
                link = WOWHEAD_DOMAIN .. linkType .. "=" .. linkID;
            end
        end       
        SetDressingRoomMode("mount", link);
        --]]
        SetDressingRoomMode("mount");
    end)
    
    hooksecurefunc("DressUpBattlePet", function(creatureID)
        --SetDressingRoomMode("battlePet",  WOWHEAD_DOMAIN .. "npc=" .. creatureID);
        SetDressingRoomMode("battlePet");
    end)

    frame.OptionFrame.ShareButton:SetScript("OnClick", ShareButton_OnClick);
    frame.OptionFrame.InspectButton:SetScript("OnClick", InspectButton_OnClick);

    local spinButton = frame.OptionFrame.SpinButton;
    spinButton.Icon:SetTexCoord(0.5, 0.75, 0.5, 0.75);
    spinButton.Label:SetText(L["Turntable"]);
    NarciOutfitShowcase.dressingRoomButton = spinButton;
    spinButton:SetScript("OnClick", function()
        NarciOutfitShowcase:Open();
    end);


    local undressButton = frame.UndressButton;
    local function UB_OnEnter(f)
        f.Shirt:SetVertexColor(1, 1, 1);
        f.Arrow:SetVertexColor(1, 1, 1);
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT", -4, 0);
        GameTooltip_SetTitle(GameTooltip, L["Undress"]);
        GameTooltip:Show();
    end
    local function UB_OnLeave(f)
        f.Shirt:SetVertexColor(0.72, 0.72, 0.72);
        f.Arrow:SetVertexColor(0.72, 0.72, 0.72);
        GameTooltip_Hide();
    end
    local function UB_OnClick(f)
        f.Arrow.AnimDrop:Play();
        local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
        if playerActor then
            NarciDressingRoomAPI.WipeItemList();
            for k, slotButton in pairs(DressingRoomItemButtons) do
                slotButton:HideSlot(false);
                slotButton:Desaturate(true);
            end
            playerActor:Undress();
        end
    end

    local function UB_OnMouseDown(f)
        f.Shirt:SetPoint("CENTER", f, "CENTER", 2, -2);
    end
    local function UB_OnMouseUp(f)
        f.Shirt:SetPoint("CENTER", f, "CENTER", 0, 0);
    end
    undressButton:SetScript("OnEnter", UB_OnEnter);
    undressButton:SetScript("OnLeave", UB_OnLeave);
    undressButton:SetScript("OnClick", UB_OnClick);
    undressButton:SetScript("OnMouseDown", UB_OnMouseDown);
    undressButton:SetScript("OnMouseUp", UB_OnMouseUp);

    undressButton.Shirt:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\UndressButton", nil, nil, "TRILINEAR");
    undressButton.Arrow:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\UndressButton", nil, nil, "TRILINEAR");
    undressButton.Shirt:SetVertexColor(0.72, 0.72, 0.72);
    undressButton.Arrow:SetVertexColor(0.72, 0.72, 0.72);

    if DressUpFrame.ResetButton then
        DressUpFrame.ResetButton:HookScript("OnClick", function(f)
            UpdateDressingRoomModelByUnit("player");
        end)
    end

    DressingRoomOverlayFrame.SlotFrame:SetScript("OnShow", Narci_UpdateDressingRoom);

    --expensive call
    DressUpFrame.ModelScene:HookScript("OnDressModel", function(f, ...)
        if not (DressingRoomOverlayFrame and SLOT_FRAME_ENABLED) then return end;
        if not DressingRoomOverlayFrame.pauseUpdate then
            DressingRoomOverlayFrame.pauseUpdate = true;
            DressingRoomOverlayFrame.mode = "visual";
            After(0, function()
                if SLOT_FRAME_ENABLED and IsDressUpFrameMaximized() then
                    DressingRoomOverlayFrame.SlotFrame:Show();
                    DressingRoomOverlayFrame.OptionFrame:Show();
                    GetDressingSourceFromActor();
                    if NarciDressingRoomGearTextsClipborad:IsVisible() then
                        PrintItemList();
                    end
                end
                DressingRoomOverlayFrame.pauseUpdate = nil;
            end)
        end
    end)


    if NarcissusDB.DressingRoomShowIconSelect then
        OutfitIconSelect.SelectionFrame:Show();
    end

    local OutfitFrame = WardrobeOutfitFrame;
    if OutfitFrame then
        local protected1, protected2 = OutfitFrame:IsProtected();
        if not(protected1 or protected2) then
            if OutfitFrame.Update then
                hooksecurefunc(OutfitFrame, "Update", OutfitDropDown_UpdateCallback);
            end

            if OutfitFrame.StartHideCountDown then
                hooksecurefunc(OutfitFrame, "StartHideCountDown", function()
                    if not OutfitFrame:IsMouseOver(-24, 0, 16, -12) then
                        HidePreviewModel();
                    end
                end);
            end
        end
    end

    --[[
    function OutfitFrame:NewOutfit(name, customIcon)
        local icon;
        local NoTransmogID = Constants.Transmog.NoTransmogID or 0;
        for slotID, itemTransmogInfo in ipairs(self.itemTransmogInfoList) do
            local appearanceID = itemTransmogInfo.appearanceID;
            if appearanceID ~= NoTransmogID then
                icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(appearanceID));
                if icon then
                    break;
                end
            end
        end
        local outfitID = C_TransmogCollection.NewOutfit(name, icon, self.itemTransmogInfoList);
        if outfitID then
            self:SaveLastOutfit(outfitID);
        end
        if ( self.popupDropDown ) then
            self.popupDropDown:SelectOutfit(outfitID);
            self.popupDropDown:OnOutfitSaved(outfitID);
        end
    end
    --]]

    local popupInfo = StaticPopupDialogs["NAME_TRANSMOG_OUTFIT"];
    if popupInfo then
        --!! Override "WardrobeOutfitFrameMixin:NewOutfit(name)" to provide the ability to select icon
        local function SaveNewOutfit(popup)
            local name = popup.editBox:GetText();
            local icon = OutfitIconSelect.selectedIcon;

            if not icon then
                for slotID, itemTransmogInfo in ipairs(OutfitFrame.itemTransmogInfoList) do
                    local appearanceID = itemTransmogInfo.appearanceID;
                    if appearanceID ~= Constants.Transmog.NoTransmogID then
                        icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(appearanceID));
                        if icon then
                            break;
                        end
                    end
                end
            end

            local outfitID = C_TransmogCollection.NewOutfit(name, icon, OutfitFrame.itemTransmogInfoList);
            if outfitID then
                OutfitFrame:SaveLastOutfit(outfitID);
            end
            if ( OutfitFrame.popupDropDown ) then
                OutfitFrame.popupDropDown:SelectOutfit(outfitID);
                OutfitFrame.popupDropDown:OnOutfitSaved(outfitID);
            end
        end

        popupInfo.OnAccept = SaveNewOutfit;

        local ValidPopupNames = {
            NAME_TRANSMOG_OUTFIT = true,
            --BW_NAME_TRANSMOG_OUTFIT = true,     --BetterWardrobe
        };

        local function LocateTransmogPopup()
            local popup;
            for i = 1, 3 do
                popup = _G["StaticPopup"..i];
                if popup and popup:IsShown() and popup.which and ValidPopupNames[popup.which] then
                    return popup
                end
            end
        end

        hooksecurefunc("StaticPopup_Show", function(name)
            if ValidPopupNames[name] then
                --assume it's StaticPopup1
                local popup = LocateTransmogPopup();
                if popup and OutfitFrame.itemTransmogInfoList then
                    local editbox = popup.editBox;
                    editbox:ClearAllPoints();
                    if popup.text then
                        local height = popup.text:GetHeight() or 12;
                        editbox:SetPoint("TOP", 0, -24 - height);
                    else
                        editbox:SetPoint("TOP", 0, -36);
                    end
                    OutfitIconSelect:SetParentFrame(popup, editbox);

                    --Create Optional Icons
                    local _, icon;
                    local NoTransmogID = Constants.Transmog.NoTransmogID or 0;
                    local iconChoices = {};
                    local iconUsed = {};
                    local hiddenIcons = {};

                    --Attemp to find a unique icon that hasn't been used by other outfits, preferably not a hidden transmog's icon
                    local defaultIcon;
                    local oldIcons = {};
                    local outfitIDs = C_TransmogCollection.GetOutfits();
                    if outfitIDs then
                        for i = 1, #outfitIDs do
                            _, icon = GetOutfitInfo(outfitIDs[i]);
                            if icon then
                                oldIcons[icon] = true;
                            end
                        end
                    end

                    for slotID, itemTransmogInfo in ipairs(OutfitFrame.itemTransmogInfoList) do
                        local appearanceID = itemTransmogInfo.appearanceID;
                        if appearanceID ~= NoTransmogID then
                            icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(appearanceID));
                            if icon then
                                if not iconUsed[icon] then
                                    iconUsed[icon] = true;
                                    if IsHiddenVisual(appearanceID) then
                                        --print(string.format("%s is hidden", NarciAPI.GetInventorySlotNameBySlotID(slotID) ));
                                        table.insert(hiddenIcons, icon);
                                    else
                                        table.insert(iconChoices, icon);
                                        if not oldIcons[icon] and not defaultIcon then
                                            defaultIcon = icon;
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for i = 1, #hiddenIcons do
                        table.insert(iconChoices, hiddenIcons[i]);
                    end

                    local extraHeight = OutfitIconSelect:SetupIcons(iconChoices, defaultIcon);
                    if OutfitIconSelect.SelectionFrame:IsShown() then
                        popup:SetHeight(148 + extraHeight);
                    end
                end
            else
                --OutfitIconSelect:Hide();    --TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES, TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES, TRANSMOG_OUTFIT_CHECKING_APPEARANCES
            end
        end)
    end
    
end


local initialize = CreateFrame("Frame")
initialize:RegisterEvent("ADDON_LOADED");
initialize:RegisterEvent("PLAYER_ENTERING_WORLD");
initialize:RegisterEvent("UI_SCALE_CHANGED");
initialize:SetScript("OnEvent",function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        if name == "Narcissus" then
            self:UnregisterEvent("ADDON_LOADED");
            DressingRoomOverlayFrame_Initialize();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        USE_TARGET_MODEL = NarcissusDB.DressingRoomUseTargetModel;

        if not DressingRoomOverlayFrame then
            self:UnregisterAllEvents();
            return
        end

        local InspectButton = DressingRoomOverlayFrame.OptionFrame.InspectButton;
        InspectButton:SetScript("OnClick", InspectButton_OnClick);
        if USE_TARGET_MODEL then   --true
            InspectButton.Label:SetText(L["Use Target Model"]);
            InspectButton.USE_TARGET_MODEL = true;
        else
            InspectButton.Label:SetText(L["Use Your Model"]);
            InspectButton.USE_TARGET_MODEL = false;
        end

        local ShareButton = DressingRoomOverlayFrame.OptionFrame.ShareButton;
        local buttonOffsetX, buttonOffsetY, buttonGap;
        if Adaptor:IsConflictedAddOnLoaded() then                                --DressUp: Hide our dressing room slot frame
            DressingRoomOverlayFrame.SlotFrame:Disable();
            SLOT_FRAME_ENABLED = false;
            buttonOffsetX = 24;
            buttonOffsetY = 48;
            buttonGap = 8;
            function Narci_SetDressUpBackground()
            end

            --send the right buttons to bottom so they won't overlap the OutfitDetailsPanel
            for _, button in pairs(DressingRoomOverlayFrame.OptionFrame.RightButtons) do
                button:SetFrameStrata("LOW");
                button:SetFixedFrameStrata(true);
            end
        else
            buttonOffsetX = 0;
            buttonOffsetY = 96;
            buttonGap = 24;
            OverrideMaximizeFunc();
        end
        ShareButton:ClearAllPoints();
        ShareButton:SetPoint("CENTER", DressingRoomOverlayFrame.OptionFrame, "BOTTOMLEFT", buttonOffsetX, buttonOffsetY);
        DressingRoomOverlayFrame.OptionFrame.GroupController:SetButtonGap(buttonGap);

    elseif event == "UI_SCALE_CHANGED" then
        After(0.5, function()
            OVERRIDE_HEIGHT = math.floor(GetScreenHeight()*HEIGHT_MULTIPLIER + 0.5);
            OVERRIDE_WIDTH = math.floor(WIDTH_HEIGHT_RATIO * OVERRIDE_HEIGHT + 0.5);
            if IsDressUpFrameMaximized() then
                DressUpFrame:SetSize(OVERRIDE_WIDTH, OVERRIDE_HEIGHT)
            end
        end)
    end
end);


NarciDressingRoomOverlayMixin = {};

function NarciDressingRoomOverlayMixin:OnLoad()
    DressingRoomOverlayFrame = self;
    self.updateSize = true;
end

function NarciDressingRoomOverlayMixin:OnShow()
    if self.mode ~= "visual" then return end;

    Narci_SetDressUpBackground("player", true);
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");

    if self.updateSize then
        self.updateSize = nil;
        self:OnSizeChanged();
    end
end

function NarciDressingRoomOverlayMixin:ListenEscapeKey(state)
    if state then
        self:SetScript("OnKeyDown", function(frame, key, down)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false);
                self:SetScript("OnKeyDown", nil);
                DressUpFrame:Hide();
            else
                self:SetPropagateKeyboardInput(true);
            end
        end)
    else
        self:SetScript("OnKeyDown", nil);
    end
end

function NarciDressingRoomOverlayMixin:OnHide()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED");
    self:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED");
    self:UnregisterEvent("INSPECT_READY");
    self:ListenEscapeKey(false);
end

function NarciDressingRoomOverlayMixin:InspectTarget()
    if UpdateDressingRoomModelByUnit("target") then
        self.SlotFrame:FadeOut();
    end
end

function NarciDressingRoomOverlayMixin:OnEvent(event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        self:InspectTarget();
    elseif event == "TRANSMOG_COLLECTION_UPDATED" then
        local collectionIndex, modID, itemAppearanceID, reason = ...
        if reason == "favorite" and itemAppearanceID then
            RefreshFavoriteState(itemAppearanceID);
        end
    elseif event == "INSPECT_READY" then
        if not self.pauseInspect then
            self.pauseInspect = true;
            local guid = ...;
            if DataProvider:IsInspectedUnit(guid) then
                if not DataProvider:UnitInQueue() then
                    self:UnregisterEvent(event);
                end
                After(0, function()
                    self.SlotFrame:SetSources( GetInspectSources() );
                    self.SlotFrame:FadeIn();
                    PrintItemList();
                    ClearInspectPlayer();
                    self.pauseInspect = nil;
                end);
            end
        end
    end
end


function NarciDressingRoomOverlayMixin:OnSizeChanged(width, height)
    --print(width.." x "..height);
    local uiScale = UIParent:GetEffectiveScale();
    local frameScale = math.max(uiScale, 0.75);
    self.OptionFrame.SharedPopup:SetScale(frameScale);

    if SLOT_FRAME_ENABLED then
        self.OptionFrame.GroupController:SetLabelScale(frameScale);
        if IsDressUpFrameMaximized() then
            self.SlotFrame:SetInvisible(false);
            self.OptionFrame:SetScale(frameScale);
            self.UndressButton:Show();
        else
            self.SlotFrame:SetInvisible(true);
            self.OptionFrame:SetScale(0.5);
            self.UndressButton:Hide();
        end
    else
        self.SlotFrame:Hide();
        self.OptionFrame:SetScale(frameScale);
        self.OptionFrame.GroupController:SetLabelScale(frameScale);
        self.UndressButton:Hide();
    end

    UpdateDressingRoomExtraWdith();
end

function NarciDressingRoomOverlayMixin:ShowItemList()
    self.OptionFrame.SharedPopup:Show();
end



local function IconToggle_OnMouseDown(self)
    self.Icon:SetPoint("CENTER", self, "CENTER", 1, -1);
    self.Icon:SetVertexColor(0.6, 0.6, 0.6);
    GameTooltip_Hide();
end

local function IconToggle_OnMouseUp(self)
    self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
    self.Icon:SetVertexColor(1, 1, 1);
end

local function IconToggle_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 2, -2);
    GameTooltip_SetTitle(GameTooltip, COMMUNITIES_CREATE_DIALOG_AVATAR_PICKER_INSTRUCTIONS);
    GameTooltip:Show();
end

local function IconToggle_OnClick(self)
    OutfitIconSelect:ToggleUI();
end

NarciStaticPopupOutfitIconSelectMixin = {};

function NarciStaticPopupOutfitIconSelectMixin:OnLoad()
    OutfitIconSelect = self;

    self.Toggle:SetScript("OnMouseDown", IconToggle_OnMouseDown);
    self.Toggle:SetScript("OnMouseUp", IconToggle_OnMouseUp);
    self.Toggle:SetScript("OnEnter", IconToggle_OnEnter);
    self.Toggle:SetScript("OnLeave", GameTooltip_Hide);
    self.Toggle:SetScript("OnClick", IconToggle_OnClick);

    self.IconHighlight = self.SelectionFrame.IconHighlight;
    self.IconSelection = self.SelectionFrame.IconSelection;
end

function NarciStaticPopupOutfitIconSelectMixin:SetParentFrame(frame, anchor)
    if not frame:IsProtected() then
        self:ClearAllPoints();
        self:SetParent(frame);
        self:SetPoint("TOP", anchor, "BOTTOM", 0, -12);
        self:Show();

        self.Toggle:ClearAllPoints();
        self.Toggle:SetPoint("RIGHT", anchor, "LEFT", -16, 0);

        self.defaultHeight = frame:GetHeight();
        self.parentPopup = frame;
    end
end

function NarciStaticPopupOutfitIconSelectMixin:OnHide()
    self:Hide();
    self:ClearAllPoints();
    self:SetParent(UIParent);
    if self.IconButtons then
        for i, button in pairs(self.IconButtons) do
            button.icon = nil;
        end
    end
end

function NarciStaticPopupOutfitIconSelectMixin:ToggleUI()
    local state = not self.SelectionFrame:IsShown();

    if state then
        self.SelectionFrame:Show();
        if self.parentPopup and self.parentPopup:IsShown() and self.fullHeight then
            self.parentPopup:SetHeight(self.fullHeight);
        end
    else
        self.SelectionFrame:Hide();
        if self.parentPopup and self.parentPopup:IsShown() and self.defaultHeight then
            self.parentPopup:SetHeight(self.defaultHeight);
        end
    end

    NarcissusDB.DressingRoomShowIconSelect = state;
end

local function IconSelectButton_OnEnter(self)
    OutfitIconSelect:HighlightButton(self);
end

local function IconSelectButton_OnLeave(self)
    OutfitIconSelect:HighlightButton();
end

local function IconSelectButton_OnClick(self)
    OutfitIconSelect:SelectButton(self);
end

function NarciStaticPopupOutfitIconSelectMixin:SetupIcons(iconChoices, defaultIcon)
    if not self.IconButtons then
        self.IconButtons = {};
    end

    local BUTTONS_PER_ROW = 9;

    local numIcons = #iconChoices;
    local offsetX;
    if numIcons > BUTTONS_PER_ROW then
        offsetX = 0.5*((24 + 4) * BUTTONS_PER_ROW - 4);
    else
        offsetX = 0.5*((24 + 4) * numIcons - 4);
    end
    local col = 0;
    local row = 0;  --max 9 per row
    local button;
    local fileID;
    local frameLevel = self:GetFrameLevel();

    defaultIcon = defaultIcon or iconChoices[1];
    self.Toggle.Icon:SetTexture(defaultIcon);

    for i = 1, numIcons do
        button = self.IconButtons[i];
        if not button then
            self.IconButtons[i] = CreateFrame("Button", nil, self.SelectionFrame);
            button = self.IconButtons[i];
            button:SetSize(24, 24);
            button:SetScript("OnClick", IconSelectButton_OnClick);
            button:SetScript("OnEnter", IconSelectButton_OnEnter);
            button:SetScript("OnLeave", IconSelectButton_OnLeave);

            button.Texture = button:CreateTexture(nil, "ARTWORK");
            button.Texture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
            button.Texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
        end
        fileID = iconChoices[i];
        button.Texture:SetTexture(fileID);
        button.icon = fileID;
        button:ClearAllPoints();
        col = col + 1;
        if col > 9 then
            col = 1;
            row = row + 1;
        end
        button:SetPoint("TOPLEFT", self, "TOP", -offsetX + (col - 1) * 28, -16 -28 * row);
        button:SetFrameLevel(frameLevel);
        button:Show();
        if fileID == defaultIcon then
            self:SelectButton(button);
        end
    end

    for i = numIcons + 1, #self.IconButtons do
        self.IconButtons[i]:Hide();
    end

    local extraHeight = 24 + row * 28;
    self.fullHeight = 148 + extraHeight;

    return extraHeight
end

function NarciStaticPopupOutfitIconSelectMixin:HighlightButton(button)
    if button then
        self.IconHighlight:ClearAllPoints();
        self.IconHighlight:SetPoint("CENTER", button, "CENTER", 0, 0);
        self.IconHighlight:Show();
    else
        self.IconHighlight:Hide();
    end
end

function NarciStaticPopupOutfitIconSelectMixin:SelectButton(button)
    if button then
        self.IconSelection:ClearAllPoints();
        self.IconSelection:SetPoint("CENTER", button, "CENTER", 0, 0);
        self.IconSelection:Show();
        self.selectedIcon = button.icon;
        self.Toggle.Icon:SetTexture(button.icon);
    end
end

--[[
hooksecurefunc("PanelTemplates_TabResize", function(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
    print(tab:GetName())
    print(padding)
    print(absoluteSize)
    print(minWidth)
    print(maxWidth)
end)

/run A1=DressUpFrame.ModelScene:GetPlayerActor()
/run DressUpFrame.ModelScene:SetLightDirection(- 0.44699833180028 ,  0.72403680806459 , -0.52532198881773)
/dump A1:GetScale();    SetModelByUnit  SetModelByFileID GetModelFileID()
/dump A1:GetModelFileID()   1100258 BE female
/run A1:SetAnimation()  48 CrossBow/Rifle 
/dump A1:SetCustomRace(1,1)
/dump A1.OnModelLoaded
/run A1:TryOn(105951)   105951 Renowned Explorer's Versatile Vest 105950 104948 105946 105945 105949 105947 105944 Cap    105952 Cloak 105959 Tabard  105953 Rucksack     1287 Explorer's Jungle Hopper
/script local a=DressUpFrame.ModelScene:GetPlayerActor();a:Undress();for i=105945,105951 do a:TryOn(i);end;a:TryOn(105953);

Wooly Wendigo
/script local a=DressUpFrame.ModelScene:GetPlayerActor();a:Undress();for i=105954,105958 do a:TryOn(i);end;

/script local a=NarciPlayerModelFrame1;a:Undress();for i=105945,105951 do a:TryOn(i);end;a:TryOn(105953);
/run NarciPlayerModelFrame1:TryOn(66602)
/dump DressUpFrame.ModelScene:GetCameraPosition()
/dump DressUpFrame.ModelScene:GetActiveCamera():GetZoomDistance()
:GetZoomDistance()
local modelSceneType, cameraIDs, actorIDs = C_ModelInfo.GetModelSceneInfoByID(modelSceneID);
playerActor:SetRequestedScale()
/run A1:SetRequestedScale(0.65)
C_ModelInfo.GetModelSceneActorInfoByID(486)
ModelScene:AcquireActor()
/run DressUpFrame.ModelScene:InitializeActor(DressUpFrame.ModelScene:GetPlayerActor(), C_ModelInfo.GetModelSceneActorInfoByID(438))
/run local a = C_ModelInfo.GetModelSceneActorInfoByID(438);print(a.scriptTag)
/run DressUpFrame.ModelScene:CreateActorFromScene(486)
/run DressUpFrame.ModelScene:AcquireAndInitializeActor(C_ModelInfo.GetModelSceneActorInfoByID(486))
/dump DressUpFrame.ModelScene.actorTemplate ModelSceneActorTemplate
ApplyFromModelSceneActorInfo
ReleaseAllActors()

/dump C_TransmogCollection.GetItemInfo(itemID)  171324 118559 Shovel 66602 (return appearanceID, sourceID)
2921871 Gillvanas ModelFileID 93312(DisplayID)  Finduin 2924741/93311 animation 217
A1:SetAnimation(217,1,0.5,0)
9331 Gnome
/run DressingRoomOverlayFrame.SlotFrame:Hide();

function DressUpMountLink(link)
	if( link ) then
		local mountID = 0;

		local _, _, _, linkType, linkID = strsplit(":|H", link);
		if linkType == "item" then
			mountID = C_MountJournal.GetMountFromItem(tonumber(linkID));
		elseif linkType == "spell" then
			mountID = C_MountJournal.GetMountFromSpell(tonumber(linkID));
		end

		if ( mountID ) then
			return DressUpMount(mountID);
		end
	end
	return false
end
local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType = C_PetJournal.GetPetInfoByPetID(petID)
SpeciesID = C_PetJournal.GetPetInfoByIndex()
speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
C_PetJournal.FindPetIDByName()

local creatureDisplayID, _, _, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID);   --93202 Hopper
	local mountActor = frame.ModelScene:GetActorByTag("unwrapped");
	if mountActor then
        mountActor:SetModelByCreatureDisplayID(creatureDisplayID);  --93202
DressUpFrame.ModelScene:AttachPlayerToMount(A2, 91, false, false);       
DressUpFrame.ModelScene:AttachPlayerToMount(mountActor, animID, isSelfMount, disablePlayerMountPreview);   

				local calcMountScale = mountActor:CalculateMountScale(playerActor);
				local inverseScale = 1 / calcMountScale; 
				playerActor:SetRequestedScale( inverseScale );
                mountActor:AttachToMount(playerActor, animID, spellVisualKitID);
                
actorIDs:
[486] = troll-female 0.65   (expected:0.8526)
[487] = undead-female
[488] = lightforgeddraenei-male
[489] = lightforgeddraenei-female
[490] = highmountaintauren-male
[491] = highmountaintauren-female
[492] = zandalaritroll
[495] = magharorc-male
[497] = kultiran-female
[498] = magharorc-female
[499] = darkirondwarf-male
[500] = worgen-female
[501] = draenei-female
[494] = kultiran-male
[438]   player!!!!
[449] = tauren-male
[450] = gnome
[471] = dwarf-male
[472] = undead-male
[473] = pandaren
[474] = worgen-male
[475] = draenei-male
[484] = tauren-female
[483] = orc
[477] = goblin-female
[476] = goblin-male
[485] = troll-male


normalizeScaleAggressiveness
A1:CalculateNormalizedScale(0.65)
/run MountDressingRoom(307256)

--Unlisted APIs:
ModelSceneActor:
SetModelByFileID(fileID [, enableMips])
SetModelByCreatureDisplayID()
SetAnimation(animation[, variation, animSpeed, timeOffsetSecs])
SetSpellVisualKit(spellVisualKitID[, oneShot])


local Test = CreateFrame("Button", "TestButton", DressUpFrame, "SecureActionButtonTemplate");
Test:SetFrameStrata("FULLSCREEN")
Test:SetSize(64, 64);
Test:SetPoint("CENTER", DressUpFrame, "CENTER", 0, 0);
Test.tex = Test:CreateTexture(nil, "ARTWORK");
Test.tex:SetAllPoints(true);
Test.tex:SetColorTexture(1, 0, 0);
Test:SetAttribute("type1", "test")
Test:SetAttribute("_test", function()
    --DressUpVisual("item:2092");
    securecall("DressUpVisual", "item:2092");
end)
--]]