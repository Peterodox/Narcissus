local _, addon = ...
local TransmogSetFrame = addon.DressingRoomSystem.TransmogSetFrame;
local TransitionAPI = addon.TransitionAPI;
local CopyTable = addon.CopyTable;

local _G = _G;
local L = Narci.L;
local After = C_Timer.After;
local C_TransmogCollection = C_TransmogCollection;
local IsFavorite = C_TransmogCollection.GetIsAppearanceFavorite;
local IsHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual;
local GetOutfitInfo = C_TransmogCollection.GetOutfitInfo;
local InCombatLockdown = InCombatLockdown;
local UnitRace = UnitRace;

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

--Interface/SharedXML/ModelSceneCameras/CameraBaseMixin.lua
local CAMERA_TRANSITION_TYPE_IMMEDIATE = 1;
local CAMERA_MODIFICATION_TYPE_DISCARD = 1;
local DRESSING_ROOM_SCENE_ID = 596;

local SLOT_FRAME_SUPPORTED = true;              --If DressUp addon is loaded, hide our slot frame
local USE_TARGET_MODEL = true;                  --Replace your model with target's

local GetActorInfoByFileID = addon.GetActorInfoByFileID;


--Frames:
local DressingRoomOverlayFrame;
local DressingRoomItemButtons = {};
local OutfitIconSelect;
local AlteredFormButton;
local OLD_PLAYER_ACTOR;

local function CreateSlotButton(frame)
    local SlotFrame = frame.SlotFrame;

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
    local groupGap = 12;
    local extrudeX = 16;
    local fullWidth = extrudeX;

    for sectorIndex = 1, #slotArrangement do
        if sectorIndex ~= 1 then
            fullWidth = fullWidth + groupGap;
        end
        for i = 1, #slotArrangement[sectorIndex] do
            button = CreateFrame("Button", nil, SlotFrame.SlotContainer, "NarciDressingRoomItemButtonTemplate");
            slotID = button:Init(slotArrangement[sectorIndex][i]);
            buttons[slotID] = button;
            button:SetPoint("BOTTOMLEFT", SlotFrame, "BOTTOMLEFT", fullWidth, offsetY);
            if not buttonWidth then
                buttonWidth = math.floor(button:GetWidth() + 0.5);
            end
            fullWidth = fullWidth + buttonWidth + buttonGap;
        end
    end

    DressingRoomItemButtons = buttons;
    fullWidth = fullWidth + extrudeX;
    SlotFrame:SetWidth(fullWidth);

    if SlotFrame.SlotToggle then
        SlotFrame.SlotToggle:SetPoint("LEFT", button, "RIGHT", groupGap, 0);
    end

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


local function UpdateDressingRoomModelByUnit(unit, transmogInfoList)
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
    OLD_PLAYER_ACTOR = actor;

    --Acquire target's gears
    local autoDress = not transmogInfoList;
    if autoDress then
        overlay:RegisterEvent("INSPECT_READY");
        DataProvider:SetInspectedUnit(unit);
        NotifyInspect(unit);
    end


    local modelUnit = (USE_TARGET_MODEL and unit) or "player";
    local _, raceFile = UnitRace(modelUnit);

    local updateScale;
    local sheatheWeapons = actor:GetSheathed() or false;
    local nativeForm;
    if (raceFile == "Dracthyr" or raceFile == "Worgen") then
        AlteredFormButton.enabled = true;
        nativeForm = C_UnitAuras.WantsAlteredForm(modelUnit);
        if modelUnit == "player" then
            if AlteredFormButton.reverse then
                nativeForm = not nativeForm;
            end
            AlteredFormButton:Update();
            AlteredFormButton:Show();
        else
            AlteredFormButton:Hide();
        end
    else
        nativeForm = nil;
        AlteredFormButton:Hide();
    end

    if USE_TARGET_MODEL then
        actor:SetModelByUnit(modelUnit, sheatheWeapons, autoDress, false, nativeForm);
        updateScale = true;
        DataProvider.isCurrentModelPlayer = false;
    else
        DataProvider.isCurrentModelPlayer = true;
        actor:SetModelByUnit(modelUnit, sheatheWeapons, autoDress, false, nativeForm);
        updateScale = true;
    end


    if updateScale then
        After(0.0,function()
            local modelInfo = GetActorInfoByFileID(actor:GetModelFileID());
            if modelInfo then
                actor:ApplyFromModelSceneActorInfo(modelInfo);
            end

            if transmogInfoList then
                for slotID, transmogInfo in ipairs(transmogInfoList) do
                    actor:SetItemTransmogInfo(transmogInfo, slotID);
                end
            end
        end);
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
            local note = button:GetParent():GetParent().Notification;
            note.fadeOut:Stop();
            note:ClearAllPoints();
            note:SetPoint("TOP", button, "BOTTOM", 0, 0);
            if state then
                note:SetText("|cffffe8a5"..L["Favorited"]);
            else
                note:SetText("|cffcccccc"..L["Unfavorited"]);
            end
            note:Show();
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
    DressingRoomOverlayFrame.SlotFrame:SetManuallyChanged(false);

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

local function IsDressUpFramePlayerMode()
    return DressUpFrame and DressUpFrame.mode == "player"
end

function Narci_UpdateDressingRoom()
    local frame = DressingRoomOverlayFrame;
    if not frame or not SLOT_FRAME_SUPPORTED then return end;


    frame.mode = "visual";

    if not frame.pauseUpdate then
        frame.pauseUpdate = true;
        After(0, function()
            DressingRoomOverlayFrame:UpdateUI();
            if SLOT_FRAME_SUPPORTED and IsDressUpFrameMaximized() then
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
            TransitionToModelSceneID(frame.ModelScene, DRESSING_ROOM_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true);  --Taint
            local sheatheWeapons = false;
            local autoDress = true;
            local itemModifiedAppearanceIDs = nil;
            SetupPlayerForModelScene(frame.ModelScene, itemModifiedAppearanceIDs, sheatheWeapons, autoDress);
            --Narci_UpdateDressingRoom();
        end
        

        if SLOT_FRAME_SUPPORTED then
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
    local hasBW = C_AddOns.IsAddOnLoaded("BetterWardrobe");
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
    return C_AddOns.IsAddOnLoaded("DressUp");
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
local OutfitPreview = CreateFrame("Frame");
do
    OutfitPreview:Hide();

    function OutfitPreview:SetOwner(OutfitDropdown)
        self:SetParent(OutfitDropdown);
        self:Show();

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);

        self.GetMouseFocus = TransitionAPI.GetMouseFocus;
        self.StripHyperlinks = StripHyperlinks;

        Menu.ModifyMenu("MENU_WARDROBE_OUTFITS", function(owner, rootDescription, contextData)
            rootDescription:AddMenuAcquiredCallback(function()
                self.t = 0;
                self:LoadSavedOutfits();
                local parent = owner:GetParent();
                local parentName = parent and parent:GetName();

                if parentName == "DressUpFrame" or parentName == "WardrobeTransmogFrame" then
                    self.parent = _G[parentName];
                    self:SetParent(self.parent);
                    self:SetScript("OnUpdate", self.OnUpdate);
                    self:Show();
                else
                    self:SetScript("OnUpdate", nil);
                    self:HideModel();
                end
            end)

            rootDescription:AddMenuReleasedCallback(function()
                self:SetScript("OnUpdate", nil);
                self:HideModel();
            end)
        end)
    end

    function OutfitPreview:LoadSavedOutfits()
        local outfits = C_TransmogCollection.GetOutfits();
        local name, icon;
        self.NameToID = {};
        for index, outfitID in ipairs(outfits) do
            name, icon = C_TransmogCollection.GetOutfitInfo(outfitID);
            self.NameToID[name] = outfitID;
        end
    end

    function OutfitPreview:GetOutfitIDByName(name)
        return (name and self.NameToID and self.NameToID[name]) or nil
    end

    function OutfitPreview:OnShow()

    end

    function OutfitPreview:OnHide()
        self:Hide();
        self:SetScript("OnUpdate", nil);
        self.NameToID = nil;
    end

    function OutfitPreview:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.2 then
            self.t = 0;
            self.found = false;
            if self.parent:IsMouseOver() then
                local obj = self.GetMouseFocus();
                OBJ = obj
                if obj and obj.fontString and obj.fontString.GetText then
                    local text = obj.fontString:GetText();
                    if text then
                        text = self.StripHyperlinks(text);
                        local outfitID = self:GetOutfitIDByName(text);
                        if outfitID then
                            self.found = true;
                            self:SetOutfit(outfitID, obj);
                        end
                    end
                end
            end

            if not self.found then
                self:HideModel();
            end
        end
    end

    function OutfitPreview:Init()
        if not self.Model then
            self.Model = CreateFrame("DressUpModel", nil, self);
            self.Model:SetSize(129, 186);
            self.Model:SetAutoDress(false);
            self.Model:SetFrameStrata("HIGH");
            TransitionAPI.SetModelByUnit(self.Model, "player");
            self.Model:FreezeAnimation(0, 0, 0);
            local x, y, z = TransitionAPI.TransformCameraSpaceToModelSpace(self.Model, 0, 0, -0.25);    ---0.25
            TransitionAPI.SetModelPosition(self.Model, x, y, z);
            TransitionAPI.SetModelLight(self.Model, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);
            self.Model:SetViewTranslation(0, -57);
            self.Model:SetScript("OnHide", function(f)
                f:Hide();
                self.outfitID = nil;
                f:SetScript("OnUpdate", nil);
            end);
            self.Model:SetScript("OnShow", function()
                --m:RefreshUnit();
            end);

            local bg = self.Model:CreateTexture(nil, "BACKGROUND");
            bg:SetAllPoints(true);
            --bg:SetColorTexture(0, 0, 0, 0.8)
        end
    end

    function OutfitPreview:HideModel()
        if self.Model then
            self.Model:Hide();
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

    function OutfitPreview:SetOutfit(outfitID, anchorTo)
        if outfitID then
            self:Init();
            if outfitID == self.outfitID then
                return
            else
                self.outfitID = outfitID;
            end

            TransitionAPI.SetModelByUnit(self.Model, "player");
            self.Model:SetPoint("BOTTOMLEFT", anchorTo, "BOTTOMRIGHT", 8, 0);
            self.Model.t = -0.2;
            self.Model.dressed = nil;
            self.Model.outfitID = outfitID;
            self.Model:Show();
            self.Model:SetScript("OnUpdate", PreviewModel_OnUpdate);
            self.Model:Undress();
            self.Model:SetModelAlpha(0);

            local detailsCameraID, transmogCameraID = C_TransmogSets.GetCameraIDs();
            Model_ApplyUICamera(self.Model, transmogCameraID);
        else
            self:Hide();
        end
    end
end


NarciDressingRoomOverlayMixin = {};

function NarciDressingRoomOverlayMixin:OnLoad()
    DressingRoomOverlayFrame = self;
    self.sizeChanged = true;
end

function NarciDressingRoomOverlayMixin:OnShow()
    if self.mode ~= "visual" then return end;

    Narci_SetDressUpBackground("player", true);
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");

    if self.sizeChanged then
        self:UpdateLayout();
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
    AlteredFormButton.reverse = nil;
end

function NarciDressingRoomOverlayMixin:InspectTarget()
    if UpdateDressingRoomModelByUnit("target") then
        self.SlotFrame:FadeOut();
    end
end

function NarciDressingRoomOverlayMixin:OnEvent(event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        if IsDressUpFramePlayerMode() and not self.SlotFrame:IsManuallyChanged() then
            self:InspectTarget();
        end
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

function NarciDressingRoomOverlayMixin:UpdateLayout()
    local uiScale = UIParent:GetEffectiveScale();
    local frameScale = math.max(uiScale, 0.75);
    self.OptionFrame.SharedPopup:SetScale(frameScale);

    if SLOT_FRAME_SUPPORTED then
        self.OptionFrame.GroupController:SetLabelScale(frameScale);
        if IsDressUpFrameMaximized() then
            self.SlotFrame:SetShouldShowSlot(true);
            self.OptionFrame:SetScale(frameScale);
            self.UndressButton:Show();
            AlteredFormButton:SetScale(1);
        else
            self.SlotFrame:SetShouldShowSlot(false);
            self.OptionFrame:SetScale(0.5);
            self.UndressButton:Hide();
            AlteredFormButton:SetScale(0.75);
        end
    else
        self.SlotFrame:Hide();
        self.SlotFrame:SetShouldShowSlot(false);
        self.OptionFrame:SetScale(frameScale);
        self.OptionFrame.GroupController:SetLabelScale(frameScale);
        self.UndressButton:Hide();
    end

    UpdateDressingRoomExtraWdith();
    self.sizeChanged = nil;
end

function NarciDressingRoomOverlayMixin:OnSizeChanged(width, height)
    if self:IsVisible() then
        self:UpdateLayout();
    else
        self.sizeChanged = true;
    end
end

function NarciDressingRoomOverlayMixin:ShowItemList()
    self.OptionFrame.SharedPopup:Show();
end

function NarciDressingRoomOverlayMixin:SetMode(mode)
    self.mode = mode;
    self:UpdateUI();
end

function NarciDressingRoomOverlayMixin:UpdateUI()
    local isViewingAppearance = IsDressUpFramePlayerMode();
    if isViewingAppearance then
        self:UpdateLayout();
        self.OptionFrame:Show();
        if AlteredFormButton.enabled then
            AlteredFormButton:Show();
        end
    else
        self.SlotFrame:Hide();
        self.OptionFrame:Hide();
        self.UndressButton:Hide();
        AlteredFormButton:Hide();
    end
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
    OutfitIconSelect:SelectButton(self, true);
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

function NarciStaticPopupOutfitIconSelectMixin:SelectButton(button, fromClicks)
    if button then
        self.IconSelection:ClearAllPoints();
        self.IconSelection:SetPoint("CENTER", button, "CENTER", 0, 0);
        self.IconSelection:Show();
        self.selectedIcon = button.icon;
        self.Toggle.Icon:SetTexture(button.icon);
        if fromClicks then
            self:OverrideStaticPopupOnAccept();
        end
    end
end

function NarciStaticPopupOutfitIconSelectMixin:OverrideStaticPopupOnAccept()
    if self.popupInfoChanged then return end;

    if not (self.parentPopup and self.parentPopup:IsShown()) then return end;
    self.popupInfoChanged = true;

    local popupInfo = StaticPopupDialogs["NAME_TRANSMOG_OUTFIT"];
    if popupInfo then
        local function SaveNewOutfit(popup)
            local name = popup.EditBox:GetText();
            local icon = self.selectedIcon;

            if not icon then
                local noTransmogID = Constants.Transmog.NoTransmogID;
                for slotID, itemTransmogInfo in ipairs(WardrobeOutfitManager.itemTransmogInfoList) do
                    local appearanceID = itemTransmogInfo.appearanceID;
                    if appearanceID ~= noTransmogID then
                        icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(appearanceID));
                        if icon then
                            break;
                        end
                    end
                end
            end

            local outfitID = C_TransmogCollection.NewOutfit(name, icon, WardrobeOutfitManager.itemTransmogInfoList);
            if outfitID then
                WardrobeOutfitManager:SaveLastOutfit(outfitID);
            end
            if WardrobeOutfitManager.dropdown then
                WardrobeOutfitManager.dropdown:NewOutfit(outfitID);
            end
        end

        popupInfo.OnAccept = SaveNewOutfit;
    end
end



NarciDressingRoomAlteredFormButtonMixin = {};

function NarciDressingRoomAlteredFormButtonMixin:OnLoad()
    AlteredFormButton = self;
    self:Init();
end

function NarciDressingRoomAlteredFormButtonMixin:FadeIn()
    self:SetScript("OnUpdate", nil);
    FadeFrame(self, 0.2, 1);
end

local function FormButtonFadeOutDelay(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self:SetScript("OnUpdate", nil);
        FadeFrame(self, 0.5, 0.25);
    end
end

function NarciDressingRoomAlteredFormButtonMixin:FadeOut(delay)
    self.t = (delay and -delay) or 0;
    self:SetScript("OnUpdate", FormButtonFadeOutDelay);
end

function NarciDressingRoomAlteredFormButtonMixin:ShowTooltip()
    local tooltip = GameTooltip;
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("LEFT", self, "RIGHT", 4, 0);
    if self.isTrueForm then
        GameTooltip_SetTitle(tooltip, self.trueFormTooltip, NORMAL_FONT_COLOR);
    else
        GameTooltip_SetTitle(tooltip, self.alteredFormTooltip, NORMAL_FONT_COLOR);
    end
    tooltip:Show();
end

function NarciDressingRoomAlteredFormButtonMixin:OnEnter()
    --FadeFrame(self.InnerHighlight, 0.12, 1);
    self:FadeIn();
    self:ShowTooltip();
end

function NarciDressingRoomAlteredFormButtonMixin:OnLeave()
    --FadeFrame(self.InnerHighlight, 0.2, 0);
    self:FadeOut(2);
    GameTooltip_Hide();
end

function NarciDressingRoomAlteredFormButtonMixin:OnClick()
    self.reverse = not self.reverse;
    local actor = OLD_PLAYER_ACTOR or DressUpFrame.ModelScene:GetPlayerActor();
    local transmogInfoList;
    if actor then
        local tempInfoList = actor:GetItemTransmogInfoList();
        transmogInfoList = CopyTable(tempInfoList);     --the original infolist will be wiped when players swtich form
    end
    DressUpFrame.ModelScene:ClearScene();
    DressUpFrame.ModelScene:SetViewInsets(0, 0, 0, 0);
    TransitionToModelSceneID(DressUpFrame.ModelScene, DRESSING_ROOM_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true);  --Taint
    UpdateDressingRoomModelByUnit("player", transmogInfoList);
    self:ShowTooltip();
end

function NarciDressingRoomAlteredFormButtonMixin:OnDoubleClick()
    --prevent accidental double-click
end

function NarciDressingRoomAlteredFormButtonMixin:OnMouseDown()
    self.Portrait:SetPoint("BOTTOM", 0, -1);
end

function NarciDressingRoomAlteredFormButtonMixin:OnMouseUp()
    self.Portrait:SetPoint("BOTTOM", 0, 0);
end

function NarciDressingRoomAlteredFormButtonMixin:Update()

end

function NarciDressingRoomAlteredFormButtonMixin:UpdateShapeshifter()
    local isTrueForm = C_UnitAuras.WantsAlteredForm("player");
    if self.reverse then
        isTrueForm = not isTrueForm;
    end
    self.isTrueForm = isTrueForm;

    if UnitSex("player") == 3 then
        if isTrueForm then
            self.Portrait:SetTexCoord(0.5, 0.75, 0.375, 1);
        else
            self.Portrait:SetTexCoord(0, 0.25, 0.375, 1);
        end
    else
        if isTrueForm then
            self.Portrait:SetTexCoord(0.75, 1, 0.375, 1);
        else
            self.Portrait:SetTexCoord(0.25, 0.5, 0.375, 1);
        end
    end

    if not self:IsMouseOver() then
        self:FadeIn();
        self:FadeOut(4);
    end
end


function NarciDressingRoomAlteredFormButtonMixin:Init()
    local _, raceFile = UnitRace("player");
    if raceFile == "Dracthyr" then
        self.Update = self.UpdateShapeshifter;
        self.Portrait:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\FormButton-Dracthyr");
        self.trueFormTooltip = L["Switch Form To Visage"];
        self.alteredFormTooltip = L["Switch Form To Dracthyr"];
    elseif raceFile == "Worgen" then
        self.Update = self.UpdateShapeshifter;
        self:SetHeight(34);
        self.Portrait:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\FormButton-Worgen");
        self.trueFormTooltip = L["Switch Form To Human"];
        self.alteredFormTooltip = L["Switch Form To Worgen"];
    else
        self:Hide();
    end
end


local SetSelectionModule = {};
do  --Transmog Set Selection
    function SetSelectionModule.DressUpFrame_Show(frame, itemModifiedAppearanceIDs, forcePlayerRefresh, fromLink, equipPlayerItem)
        if frame == DressUpFrame then
            SetSelectionModule.fromLink = fromLink;
            if not (fromLink and frame:IsShown()) then
                TransmogSetFrame:Hide();
                return
            end
        else
            return
        end

        local setID = C_Item.GetItemLearnTransmogSet(fromLink);
        local setItems = setID and C_Transmog.GetAllSetAppearancesByID(setID);

        if not setItems then
            TransmogSetFrame:Hide();
            return
        end

        local set = C_TransmogSets.GetSetInfo(setID);
        local setName = set and set.name;
        if setName == "" then
            setName = nil;
        end

        TransmogSetFrame:SetItemSet(setName, setItems, fromLink);
        DressUpFrame.OutfitDetailsPanel:Hide();

        if not (SetSelectionModule.autoRemoveNonSetItem or equipPlayerItem) then return end;

        local slotID, usedSlots;

        for _, setItem in ipairs(setItems) do
            if setItem.invSlot then
                --slotID = C_Item.GetItemInventoryTypeByID(setItem.itemID);
                slotID = setItem.invSlot + 1;
                if slotID then
                    if not usedSlots then
                        usedSlots = {};
                    end
                    usedSlots[slotID] = true;
                else

                end
            end
        end

        if usedSlots then
            C_Timer.After(0, function()
                if frame:IsShown() then
                    local actor = frame.ModelScene:GetPlayerActor();
                    if actor then
                        for slotID = 1, 19 do
                            if not usedSlots[slotID] then
                                if equipPlayerItem then
                                    actor:DressPlayerSlot(slotID);
                                else
                                    actor:UndressSlot(slotID);
                                end
                            end
                        end
                    end
                end
            end)
        end
    end

    function NarciDressingRoomAPI.EnableAutoRemoveNonSetItems(state, userInput)
        state = state == true;
        SetSelectionModule.autoRemoveNonSetItem = state;
        if userInput and DressUpFrame:IsShown() then
            if SetSelectionModule.fromLink then
                local equipPlayerItem = not state;
                SetSelectionModule.DressUpFrame_Show(DressUpFrame, nil, nil, SetSelectionModule.fromLink, equipPlayerItem);
            end
        end
        NarcissusDB.DressingRoomAutoRemoveNonSetItem = state;
    end
end


local function DressingRoomOverlayFrame_Initialize()
    if not (NarcissusDB and NarcissusDB.DressingRoom) then return false; end;

    local parentFrame = DressUpFrame;
    if not parentFrame then 
        print("Narcissus failed to EL Advanced Dressing Room");
        return;
    end

    if not NarcissusDB.KeepDressingRoomOriginalLight then
        DressUpFrame.ModelScene:SetLightDiffuseColor(0.78, 0.78, 0.78);
    end

    local frame = CreateFrame("Frame", "NarciDressingRoomOverlay", parentFrame, "NarciDressingRoomOverlayTemplate")
    CreateSlotButton(frame)
    DressingRoomOverlayFrame_OnLoad(frame);
    UpdateDressingRoomExtraWdith();

    hooksecurefunc("DressUpVisual", Narci_UpdateDressingRoom);

    local function SetDressingRoomNonPlayerMode(mode, link)
        DressingRoomOverlayFrame:SetMode(mode);
        TransmogSetFrame:Hide();
    end

    hooksecurefunc("DressUpMountLink", function(link)
        --[[
        if link then
            local _, _, _, linkType, linkID = strsplit(":|H", link);
            if linkType == "item" or linkType == "spell" then
                link = WOWHEAD_DOMAIN .. linkType .. "=" .. linkID;
            end
        end       
        --]]
        SetDressingRoomNonPlayerMode("mount");
    end)

    hooksecurefunc("DressUpBattlePet", function(creatureID)
        SetDressingRoomNonPlayerMode("battlePet");
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
            TransmogSetFrame:Hide();
        end)
    end

    DressingRoomOverlayFrame.SlotFrame:SetScript("OnShow", Narci_UpdateDressingRoom);

    --expensive call
    DressUpFrame.ModelScene:HookScript("OnDressModel", function(f, ...)
        if not (DressingRoomOverlayFrame) then return end;

        if SLOT_FRAME_SUPPORTED then
            if not DressingRoomOverlayFrame.pauseUpdate then
                DressingRoomOverlayFrame.pauseUpdate = true;
                DressingRoomOverlayFrame.mode = "visual";
                After(0, function()
                    DressingRoomOverlayFrame:UpdateUI();
                    if SLOT_FRAME_SUPPORTED and IsDressUpFrameMaximized() then
                        GetDressingSourceFromActor();
                        if NarciDressingRoomGearTextsClipborad:IsVisible() then
                            PrintItemList();
                        end
                    end
                    DressingRoomOverlayFrame.pauseUpdate = nil;
                end)
            end
        else
            if not DressingRoomOverlayFrame.pauseUpdate then
                DressingRoomOverlayFrame.pauseUpdate = true;
                DressingRoomOverlayFrame.mode = "visual";
                After(0, function()
                    GetDressingSourceFromActor();
                    if NarciDressingRoomGearTextsClipborad:IsVisible() then
                        PrintItemList();
                    end
                    DressingRoomOverlayFrame.pauseUpdate = nil;
                end)
            end
        end
    end)


    if NarcissusDB.DressingRoomShowIconSelect then
        OutfitIconSelect.SelectionFrame:Show();
    end


    if DressUpFrame.OutfitDropdown then     --See "WardrobeOutfitDropdownTemplate"
        if Menu and Menu.ModifyMenu then
            OutfitPreview:SetOwner(DressUpFrame.OutfitDropdown);
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
                if popup and WardrobeOutfitManager and WardrobeOutfitManager.itemTransmogInfoList then
                    local tinsert = table.insert;
                    local EditBox = popup.EditBox;
                    EditBox:ClearAllPoints();
                    if popup.Text then
                        local height = popup.Text:GetHeight() or 12;
                        EditBox:SetPoint("TOP", 0, -24 - height);
                    else
                        EditBox:SetPoint("TOP", 0, -36);
                    end
                    OutfitIconSelect:SetParentFrame(popup, EditBox);

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

                    for slotID, itemTransmogInfo in ipairs(WardrobeOutfitManager.itemTransmogInfoList) do
                        local appearanceID = itemTransmogInfo.appearanceID;
                        if appearanceID ~= NoTransmogID then
                            icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(appearanceID));
                            if icon then
                                if not iconUsed[icon] then
                                    iconUsed[icon] = true;
                                    if IsHiddenVisual(appearanceID) then
                                        --print(string.format("%s is hidden", NarciAPI.GetInventorySlotNameBySlotID(slotID) ));
                                        tinsert(hiddenIcons, icon);
                                    else
                                        tinsert(iconChoices, icon);
                                        if not oldIcons[icon] and not defaultIcon then
                                            defaultIcon = icon;
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for i = 1, #hiddenIcons do
                        tinsert(iconChoices, hiddenIcons[i]);
                    end

                    local extraHeight = OutfitIconSelect:SetupIcons(iconChoices, defaultIcon);
                    if OutfitIconSelect.SelectionFrame:IsShown() then
                        popup:SetHeight(148 + extraHeight);
                    end

                    popup.ButtonContainer.Button1:ClearAllPoints();
                    popup.ButtonContainer.Button1:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 16);
                    popup.ButtonContainer.Button2:ClearAllPoints();
                    popup.ButtonContainer.Button2:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 16);
                end
            else
                --OutfitIconSelect:Hide();    --TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES, TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES, TRANSMOG_OUTFIT_CHECKING_APPEARANCES
            end
        end)
    end

    hooksecurefunc("DressUpFrame_Show", SetSelectionModule.DressUpFrame_Show);




    return true
end


local EL = CreateFrame("Frame")
EL:RegisterEvent("ADDON_LOADED");
EL:RegisterEvent("PLAYER_ENTERING_WORLD");
EL:SetScript("OnEvent",function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        if name == "Narcissus" then
            self:UnregisterEvent("ADDON_LOADED");
            self.enabled = DressingRoomOverlayFrame_Initialize();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        USE_TARGET_MODEL = NarcissusDB.DressingRoomUseTargetModel;

        if not (DressingRoomOverlayFrame and self.enabled) then
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
            SLOT_FRAME_SUPPORTED = false;
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

        self:SetScript("OnEvent", self.OnEvent);
        self:RegisterEvent("UI_SCALE_CHANGED");
        self:OnEvent("UI_SCALE_CHANGED");

        DressUpFrame.transmogSetDressUpEnabled = false;     --Disable WoW's SetSelectionPanel
        NarciDressingRoomAPI.EnableAutoRemoveNonSetItems(NarcissusDB.DressingRoomAutoRemoveNonSetItem);
        TransmogSetFrame:ClearAllPoints();
        TransmogSetFrame:SetParent(DressUpFrame);
        TransmogSetFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", -1, -32);
        local baseFrameLevel = DressUpFrame.NineSlice:GetFrameLevel();
        TransmogSetFrame:SetFrameLevel(baseFrameLevel + 1);
        DressUpFrame.OutfitDetailsPanel:SetFrameLevel(baseFrameLevel + 5);
    end
end);

function EL:OnEvent(event, ...)
    if event == "UI_SCALE_CHANGED" then
        self:RequestUpdateFrameSize();
    end
end

function EL:UpdateFrameSize()
    OVERRIDE_HEIGHT = math.floor(GetScreenHeight() * HEIGHT_MULTIPLIER + 0.5);
    OVERRIDE_WIDTH = math.floor(WIDTH_HEIGHT_RATIO * OVERRIDE_HEIGHT + 0.5);
    if IsDressUpFrameMaximized() then
        DressUpFrame:SetSize(OVERRIDE_WIDTH, OVERRIDE_HEIGHT)
    end
end

function EL:RequestUpdateFrameSize()
    self.t = 0;
    self:SetScript("OnUpdate", function(_, elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.5 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            self:UpdateFrameSize();
        end
    end);
end