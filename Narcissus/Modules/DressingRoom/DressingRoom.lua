----------------------------------------------------------------------------------------
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 450, 545;       --BLZ dressing room size

----------------------------------------------------------------------------------------
local L = Narci.L;
local After = C_Timer.After;
local C_TransmogCollection = C_TransmogCollection;
local IsFavorite = C_TransmogCollection.GetIsAppearanceFavorite;

local FadeFrame = NarciFadeUI.Fade;
local GetInspectSources = C_TransmogCollection.GetInspectSources or C_TransmogCollection.GetInspectItemTransmogInfoList;        --API changed in 9.1.0

local WIDTH_HEIGHT_RATIO = DEFAULT_WIDTH/DEFAULT_HEIGHT;
local OVERRIDE_HEIGHT = math.floor(GetScreenHeight()*0.8 + 0.5);
local OVERRIDE_WIDTH = math.floor(WIDTH_HEIGHT_RATIO * OVERRIDE_HEIGHT + 0.5);

local slotFrameEnabled = true;            --If DressUp addon is loaded, hide our slot frame
local UseTargetModel = true;                 --Replace your model with target's

local GetActorInfoByUnit = NarciAPI_GetActorInfoByUnit;

--Frames:
local DressingRoomOverlayFrame;
local DressingRoomItemButtons = {};

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
        if (not slotButton.isSlotHidden) and (not slotButton:IsSameSouce(appliedSourceID, secondarySourceID)) then
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

    local GearTextScrollFrame = self.OptionFrame.SharePopup.GearTextContainer.ScrollFrame;
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

    if UseTargetModel then
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
    local Popup = NarciDressingRoomSharePopup;
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
    UseTargetModel = not state;
    self.useTargetModel = not state;
    if not state then   --true
        self.Label:SetText(self.targetModelText);
    else
        self.Label:SetText(self.yourModelText);
    end
    UpdateDressingRoomModelByUnit("target");
end

function Narci_UpdateDressingRoom()
    local frame = DressingRoomOverlayFrame;
    if not frame or not slotFrameEnabled then return end;

    frame.mode = "visual";

    if not frame.pauseUpdate then
        frame.pauseUpdate = true;
        After(0, function()
            if slotFrameEnabled and IsDressUpFrameMaximized() then
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
        

        if slotFrameEnabled then
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
    wipe(self);
    return result;
end

----------------------------------------------------------------------------------------
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
                slotButton:SetHiddenVisual(false);
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
        if not (DressingRoomOverlayFrame and slotFrameEnabled) then return end;
        if not DressingRoomOverlayFrame.pauseUpdate then
            DressingRoomOverlayFrame.pauseUpdate = true;
            DressingRoomOverlayFrame.mode = "visual";
            After(0, function()
                if slotFrameEnabled and IsDressUpFrameMaximized() then
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
end


local initialize = CreateFrame("Frame")
initialize:RegisterEvent("ADDON_LOADED");
initialize:RegisterEvent("PLAYER_ENTERING_WORLD");
initialize:RegisterEvent("UI_SCALE_CHANGED");
initialize:SetScript("OnEvent",function(self,event,...)
    if event == "ADDON_LOADED" then
        local name = ...;
        if name == "Narcissus" then
            self:UnregisterEvent("ADDON_LOADED");
            DressingRoomOverlayFrame_Initialize();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        UseTargetModel = NarcissusDB.DressingRoomUseTargetModel;

        if not DressingRoomOverlayFrame then
            self:UnregisterAllEvents();
            return
        end

        local InspectButton = DressingRoomOverlayFrame.OptionFrame.InspectButton;
        InspectButton:SetScript("OnClick", InspectButton_OnClick);
        if UseTargetModel then   --true
            InspectButton.Label:SetText(L["Use Target Model"]);
            InspectButton.useTargetModel = true;
        else
            InspectButton.Label:SetText(L["Use Your Model"]);
            InspectButton.useTargetModel = false;
        end

        local ShareButton = DressingRoomOverlayFrame.OptionFrame.ShareButton;
        local buttonOffsetX, buttonOffsetY, buttonGap;
        if Adaptor:IsConflictedAddOnLoaded() then                                --DressUp: Hide our dressing room slot frame
            DressingRoomOverlayFrame.SlotFrame:Disable();
            slotFrameEnabled = false;
            buttonOffsetX = 24;
            buttonOffsetY = 48;
            buttonGap = 8;
            function Narci_SetDressUpBackground()

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
            OVERRIDE_HEIGHT = math.floor(GetScreenHeight()*0.8 + 0.5);
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
    self.OptionFrame.SharePopup:SetScale(frameScale);

    if slotFrameEnabled then
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