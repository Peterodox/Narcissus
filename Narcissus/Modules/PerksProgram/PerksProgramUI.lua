---- Extra Features For PerksProgramFrame

local _, addon = ...
local DataProvider = addon.PerksProgramDataProvider;
local TransmogDataProvider = addon.TransmogDataProvider;

local L = Narci.L;
local NarciAPI = NarciAPI;

local BlizzardFrame;
local PerksProgramUITooltip;
local ExtraDetailFrame;    --1.Display the items of an ensemble on ProductDetailsContainerFrame   2.Toggle individual item's visibility.
local SheatheToggle;
local AnimationButton, AnimationDropDown;

local SELECTED_DATA;

local C_Item = C_Item;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local C_PerksProgram = C_PerksProgram;
local C_TransmogCollection = C_TransmogCollection;
local EventRegistry = EventRegistry;
local hooksecurefunc = hooksecurefunc;
local After = C_Timer.After;


-- User Settings --
local CHANGE_POSE = false;   --Change the default model's animation and yaw
local DEV_MODE = false;
-------------------
local CURRENCY_MARKUP = " |T4696085:0:0:0:0:64:64:6:58:6:58|t";

local STAND_ANIMATION = 804;    --Stand Character Create
local MOUNT_SPECIAL_ANIM_KIT = 1371;    --See https://www.townlong-yak.com/framexml/live/Blizzard_PerksProgram/Blizzard_PerksProgramModel.lua
local MODEL_SETUPS = {
    INVTYPE_RANGED = {yaw = -1.52, animation = STAND_ANIMATION, sheathed = false},
    INVTYPE_2HWEAPON = {yaw = 0.00, animation = STAND_ANIMATION, sheathed = false},
    INVTYPE_WEAPON = {yaw = -2.10, animation = STAND_ANIMATION, sheathed = false},
    INVTYPE_RANGEDRIGHT = {yaw = -1.83, animation = STAND_ANIMATION, sheathed = false},
    STAFF =  {yaw = 2.13, animation = STAND_ANIMATION, sheathed = true},
};

local function GetPlayerActor()
    return BlizzardFrame.ModelSceneContainerFrame.playerActor
end

local function SetupModelByItemID(actor, itemID)
    if itemID then
        local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemID);
        local key = itemEquipLoc;

        if classID == 2 and subclassID == 10 then
            key = "STAFF";
        end

        local data = key and MODEL_SETUPS[key];

        if data then
            if data.yaw then
                actor:SetYaw(data.yaw);
            end

            if data.sheathed ~= nil then
                actor:SetSheathed(data.sheathed);
            end
        end

        local animationID = (data and data.animation) or STAND_ANIMATION;
        actor:StopAnimationKit();
        actor:SetAnimationBlendOperation(0);  --LE_MODEL_BLEND_OPERATION_ANIM
        actor:SetAnimation(animationID);

        local sheathed = actor:GetSheathed();   --Re-sheathe so the actor can grip the weapon
        actor:SetSheathed(not sheathed);
        actor:SetSheathed(sheathed);
    end
end

local function GetColorizedItemNameFromSource(sourceID, itemID)
    if not itemID then
        itemID = C_TransmogCollection.GetSourceItemID(sourceID);
    end

    if itemID then
        local itemName, itemLink, itemQuality = C_Item.GetItemInfo(itemID);
        if itemName and itemName ~= "" then
            local hex = NarciAPI.GetItemQualityHexColor(itemQuality);
            return "|cff"..hex..itemName.."|r", true
        else
            return itemID, false
        end
    end
end

local function SetButtonFontColor(fontString, colorIndex)
    if colorIndex == 1 then
        fontString:SetTextColor(0.5, 0.5, 0.5);
    elseif colorIndex == 2 then
        fontString:SetTextColor(1, 1, 1);
    elseif colorIndex == 3 then
        fontString:SetTextColor(1, 0.82, 0);
    end
end

local function GetSelectedMountTypeName()
    local data = SELECTED_DATA;
    if not (data and data.mountID and data.mountID ~= 0) then return end;
    local mountTypeID = select(5, C_MountJournal.GetMountInfoExtraByID(data.mountID));
    local mountTypeName;
    if mountTypeID == 230 then --ground
        mountTypeName = MOUNT_JOURNAL_FILTER_GROUND or "Ground";
    elseif mountTypeID == 248 then  --flying
        mountTypeName = MOUNT_JOURNAL_FILTER_FLYING or "Flying";
    end
    return mountTypeName
end

local function UpdateProductModelAnimation(data, userInput)
    local categoryID = data.perksVendorCategoryID;
    if categoryID == 1 then --Transmog
        if CHANGE_POSE then
            local actor = PerksProgramFrame.ModelSceneContainerFrame.playerActor;
            if actor then
                SetupModelByItemID(actor, data.itemID);
            end
            if userInput then
                actor:SetAnimation(0);
                AnimationDropDown:SelectAnimationByIndex(1);
            end
        end
    elseif categoryID == 2 then --Mount
        local actor = PerksProgramFrame.ModelSceneContainerFrame.MainModelScene:GetActorByTag("mount");
        if actor then
            if not CHANGE_POSE then
                actor:PlayAnimationKit(MOUNT_SPECIAL_ANIM_KIT);
                if userInput then
                    AnimationDropDown:SelectAnimationByIndex(AnimationDropDown.maxIndex);
                end
            elseif userInput then
                actor:SetAnimation(0);
                AnimationDropDown:SelectAnimationByIndex(1);
            end
        end
    elseif categoryID == 3 then --Pet

    end
end

local function OnProductSelectedAfterModel(f, data)
    --Enum.PerksVendorCategoryType
    SELECTED_DATA = data;

    local categoryID = data.perksVendorCategoryID;
    local showExtraDetail;
    local showSheatheToggle = true;

    UpdateProductModelAnimation(data);

    if categoryID == 8 then     --TransmogSet
        --[[    --Showing child items has become a base feature
        if data.transmogSetID then
            ExtraDetailFrame:Show();
            local sourceIDs = C_TransmogSets.GetAllSourceIDs(data.transmogSetID);
            ExtraDetailFrame:DisplayEnsembleSources(sourceIDs);
            showExtraDetail = true;
        end
        --]]
    elseif categoryID == 3 then     --Pet
        if data.speciesID then
            ExtraDetailFrame:DisplayPetInfo(data.speciesID);
            showExtraDetail = true;
        end
        showSheatheToggle = false;
    elseif categoryID == 2 then     --Mounts
        --Mount: Add mountType (Ground, Flying, etc.) to CategoryText
        --Now implemented by Blizzard
        --[[
        showSheatheToggle = false;
        local mountTypeName = GetSelectedMountTypeName();
        if mountTypeName then
            local defaultDetailsFrame = ExtraDetailFrame.parentFrame;   --PerksProgramDetailsFrameTemplate
            if defaultDetailsFrame and defaultDetailsFrame.CategoryText then
                After(0, function() --DetailsFrame also use EventRegistry for updating data, so we need to set a delay
                    mountTypeName = GetSelectedMountTypeName();
                    if mountTypeName then
                        defaultDetailsFrame.CategoryText:SetText((PERKS_VENDOR_CATEGORY_MOUNT or "Mount").." - "..mountTypeName);
                    end
                end);
            end
        end
        --]]

    elseif categoryID == 1 then     --Transmog
        local sourceID = data.itemModifiedAppearanceID;
        local ownerSetInfo = TransmogDataProvider:GetOwnerSetInfo(sourceID);
        if ownerSetInfo then
            ExtraDetailFrame:Show();
            ExtraDetailFrame:DisplayHiddenTransmogSet(ownerSetInfo, sourceID);
            showExtraDetail = true;
        end
    end

    if not showExtraDetail then
        ExtraDetailFrame:Hide();
    end

    if ExtraDetailFrame.parentFrame then
        ExtraDetailFrame.parentFrame:Layout();
    end

    if SheatheToggle then
        SheatheToggle:SetState(categoryID);
    end

    AnimationDropDown:UpdateOptions();
end

local function GetPetTypeTexture(petTypeID, size)
    size = size or 16;

    if petTypeID and PET_TYPE_SUFFIX and PET_TYPE_SUFFIX[petTypeID] then
        return string.format("|T%s:%d:%d:0:0:128:256:102:63:129:168|t", "Interface/PetBattles/PetIcon-"..PET_TYPE_SUFFIX[petTypeID], size, size);
    else
        return "";
    end
end

local function SetupPetTooltip(tooltip, speciesID)
    local petAbilityLevelInfo = C_PetJournal.GetPetAbilityListTable(speciesID);
    if petAbilityLevelInfo and #petAbilityLevelInfo > 0 then
        tooltip:AddLine(" ");
        local name, icon, typeID;
        local typeIconFomart = "|T%s:24:24|t|T%s:16:16:-4:0:128:256:102:63:129:168|t";
        for _, info in ipairs(petAbilityLevelInfo) do
            name, icon, typeID = C_PetJournal.GetPetAbilityInfo(info.abilityID);
            icon = string.format(typeIconFomart, icon, "Interface/PetBattles/PetIcon-"..PET_TYPE_SUFFIX[typeID]);
            tooltip:AddLine(icon.." "..name, 1, 1, 1, true);
        end
        tooltip:Show();
    end

    --_G["BATTLE_PET_NAME_"..typeID]
end

local PET_ABILITY_INFO;

local function InitPetAbilityInfo()
    if not PET_ABILITY_INFO then
        PET_ABILITY_INFO = SharedPetBattleAbilityTooltip_GetInfoTable();

        function PET_ABILITY_INFO:GetPetType()
            return self.petType
        end

        function PET_ABILITY_INFO:GetAbilityID()
            return self.abilityID;
        end

        function PET_ABILITY_INFO:IsInBattle()
            return false;
        end

        function PET_ABILITY_INFO:GetHealth(target)
            self:EnsureTarget(target);
            return self.maxHealth;
        end

        function PET_ABILITY_INFO:GetMaxHealth(target)
            self:EnsureTarget(target);
            return self.maxHealth;
        end

        function PET_ABILITY_INFO:GetAttackStat(target)
            self:EnsureTarget(target);
            return self.power;
        end

        function PET_ABILITY_INFO:GetSpeedStat(target)
            self:EnsureTarget(target);
            return self.speed;
        end

        function PET_ABILITY_INFO:EnsureTarget(target)
        end
    end
end

local function SetupPetAbilityTooltip(owner, abilityID, level)
    InitPetAbilityInfo();

    local id, name, icon, maxCooldown, unparsedDescription, numTurns, petType, noStrongWeakHints = C_PetBattles.GetAbilityInfoByID(abilityID);

    local tooltip = PerksProgramUITooltip;
    tooltip:Hide();
    tooltip:SetOwner(owner, "ANCHOR_NONE");
    tooltip:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", -2, -4);

    local petTypeIcon = GetPetTypeTexture(petType, 24);
    tooltip:SetText(petTypeIcon.." "..name);
	
    if level then
        tooltip:AddLine(string.format(ITEM_MIN_LEVEL, level), 0.6, 0.6, 0.6, true);
    end

	if numTurns and numTurns > 1 then
        tooltip:AddLine(string.format(BATTLE_PET_ABILITY_MULTIROUND, numTurns), 1, 1, 1, true);
	end

    if maxCooldown and maxCooldown > 0 then
        tooltip:AddLine(string.format(PET_BATTLE_TURN_COOLDOWN, maxCooldown), 1, 1, 1, true);
	end

    if unparsedDescription then
        PET_ABILITY_INFO.abilityID = abilityID;
        PET_ABILITY_INFO.speciesID = 1;
        PET_ABILITY_INFO.petID = nil;
        PET_ABILITY_INFO.petType = petType;
        PET_ABILITY_INFO.power = 0;
        PET_ABILITY_INFO.speed = 0;
        PET_ABILITY_INFO.maxHealth = 100;
        local description = SharedPetAbilityTooltip_ParseText(PET_ABILITY_INFO, unparsedDescription);
        tooltip:AddLine(description, 1, 0.82, 0, true);
    end

    tooltip:Show();
    SharedTooltip_SetBackdropStyle(tooltip, GAME_TOOLTIP_BACKDROP_STYLE_DEFAULT_DARK);
end

local function PerksProgramTooltip_ProcessInfo(f, info)
    --SharedTooltip_SetBackdropStyle(f, GAME_TOOLTIP_BACKDROP_STYLE_DEFAULT_DARK);
    local owner = f:GetOwner();     --ScrollViewButton
    if not owner then return end;

    local viid = owner.perksVendorItemID;
    if (not viid) and owner.GetElementData then
        local data = owner:GetElementData();
        viid = data and data.perksVendorItemID;
    end

    if viid then
        local sourceID = DataProvider:GetVendorItemTransmogSourceID(viid);
        if sourceID and TransmogDataProvider:IsSoucePartOfTransmogSet(sourceID) then
            f:AddLine(" ");
            f:AddLine(string.format(L["Format Item Belongs To Set"], TransmogDataProvider:GetOwnerSetName(sourceID)), 1, 0.82, 0, true);
        end
        
        --[[
        if not owner.purchased then
            --Show "unavailable" for historical items
            local seconds = C_PerksProgram.GetTimeRemaining(viid);
            if seconds and seconds <= 0 then
                f:AddLine(L["Perks Program Item Unavailable"], 0.6, 0.6, 0.6, true);
                f:Show();
            end
        end

        --Show month name for returning items
        local displayMonthName, isNewItem = DataProvider:GetVendorItemAddedMonthName(viid);
        if (not isNewItem) and displayMonthName then
            f:AddLine(" ");
            f:AddLine(string.format(L["Perks Program Item Added In Format"], displayMonthName), 1, 0.82, 0, true);
        end
        --]]
    end
end

local function PerksProgramCurrencyFrame_OnEnter(f)
    --PerksProgramCurrencyFrame
    --Constants.CurrencyConsts.CURRENCY_ID_PERKS_PROGRAM_DISPLAY_INFO
    local unclaimedPoints, unearnedPoints = DataProvider:GetAvailableCurrency();    --Sometimes returns a large negative value for some reason

    if unclaimedPoints > 0 or unearnedPoints > 0 then
        local numLines = PerksProgramUITooltip:NumLines();
        local fontString, stringText;

        for i = 4, numLines do
            fontString = _G["PerksProgramTooltipTextLeft"..i];
            if fontString then
                stringText = fontString:GetText();
                if stringText ~= "" then
                    if (stringText == _G.PERKS_PROGRAM_UNCOLLECTED_TENDER) and unclaimedPoints > 0  then
                        fontString:SetText(string.format(L["Perks Program Unclaimed Tender Format"], unclaimedPoints));
                    elseif (stringText == _G.PERKS_PROGRAM_ACTIVITIES_UNEARNED) and unearnedPoints > 0 then
                        fontString:SetText(string.format(L["Perks Program Unearned Tender Format"], unearnedPoints));
                    end
                end
            end
        end

        PerksProgramUITooltip:Show();
    end
end

local function CreateDevTool(owner)
    local f = CreateFrame("Frame", nil, owner);
    f:SetSize(16, 16);
    f:SetPoint("TOP", owner, "TOP", 0, -16);

    local line1 = f:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med3_Outline");
    line1:SetJustifyH("CENTER");
    line1:SetPoint("TOP", f, "TOP", 0, 0);
    line1:SetTextColor(1, 0.82, 0);

    local line2 = f:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med3_Outline");
    line2:SetJustifyH("CENTER");
    line2:SetPoint("TOP", f, "TOP", 0, -20);
    line2:SetTextColor(1, 0.82, 0);

    local function OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.2 then
            self.t = 0;
            local actorYaw = 0;
            local cameraYaw = 0;
            local effectiveYaw = 0;

            if self.actor then
                actorYaw = self.actor:GetYaw();
            end

            if self.camera then
                cameraYaw = self.camera:GetYaw();
            end

            if self.baseCameraYaw then
                local delta = cameraYaw - self.baseCameraYaw;
                effectiveYaw = actorYaw - delta;
            end

            line2:SetText(string.format("Actor: |cffffffff%.2f|r   Camera: |cffffffff%.2f|r   Effective: |cffffffff%.2f|r", actorYaw, cameraYaw, effectiveYaw));
        end
    end

    f.t = 0;
    f:SetScript("OnUpdate", OnUpdate);

    local function Callback(_, data)
        f.actor = GetPlayerActor();
        local DEFAULT_CAMERA_TAG = "primary";
        f.camera = BlizzardFrame.ModelSceneContainerFrame.PlayerModelScene:GetCameraByTag(DEFAULT_CAMERA_TAG);
        f.baseCameraYaw = f.camera:GetYaw();

        local itemID = data.itemID;
        local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemID);
        itemEquipLoc = itemEquipLoc or "NOT_Equippable";
        line1:SetText(string.format("ItemID: |cffffffff%s|r   EquipLoc: |cffffffff%s|r   Class: |cffffffff%s/%s|r", itemID, itemEquipLoc, classID, subclassID));
    end

    EventRegistry:RegisterCallback("PerksProgramModel.OnProductSelectedAfterModel", Callback, f);
end

local function Initialize()
    if not PerksProgramFrame then return end;

    BlizzardFrame = PerksProgramFrame;

    CHANGE_POSE = NarcissusDB.TradingPostChangePost;

    if DEV_MODE then
        CreateDevTool(BlizzardFrame);
    end

    --Insert ExtraDetailFrame
    if BlizzardFrame.ProductsFrame and BlizzardFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame and BlizzardFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame.DetailsFrame then
        ExtraDetailFrame.parentFrame = BlizzardFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame.DetailsFrame;
        ExtraDetailFrame:SetParent(ExtraDetailFrame.parentFrame);
    end

    --Skin Tooltip
    PerksProgramUITooltip = BlizzardFrame.PerksProgramTooltip;
    if PerksProgramUITooltip and PerksProgramUITooltip.ProcessInfo then
        --PerksProgramUITooltip.layoutType = "TooltipDefaultDarkLayout";
        hooksecurefunc(PerksProgramUITooltip, "ProcessInfo", PerksProgramTooltip_ProcessInfo);

        if BlizzardFrame.ProductsFrame.PerksProgramCurrencyFrame then
            BlizzardFrame.ProductsFrame.PerksProgramCurrencyFrame:HookScript("OnEnter", PerksProgramCurrencyFrame_OnEnter);
        end
    end

    if BlizzardFrame.TimeLeftListFormatter then
        --Hide TimeRemaining when browsing history items
        function BlizzardFrame.TimeLeftListFormatter:FormatZero()
            return ""
        end
    end

    --Change the rotation speed
    if BlizzardFrame.FooterFrame and BlizzardFrame.FooterFrame.RotateButtonContainer then
        local period = 4;
        local f = BlizzardFrame.FooterFrame.RotateButtonContainer;
        local increment = math.floor(1000* 2*math.pi/period/60)/1000;

        if f.RotateLeftButton then
            f.RotateLeftButton.rotationIncrement = increment;
        else
            return
        end

        if f.RotateRightButton then
            f.RotateRightButton.rotationIncrement = increment;
        else
            return
        end

        f.RotateLeftButton:ClearAllPoints();
        f.RotateRightButton:ClearAllPoints();
        f.RotateRightButton:SetPoint("RIGHT", f, "CENTER", -8, 0);
        f.RotateLeftButton:SetPoint("RIGHT", f.RotateRightButton, "LEFT", -4, 0);

        SheatheToggle = CreateFrame("Button", nil, f, "NarciPerksProgramSquareButtonTemplate");
        SheatheToggle:SetPoint("LEFT", f, "CENTER", 8, 0);
        SheatheToggle.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PerksProgram/SheatheIconYellow");

        local function SheatheToggle_SetIcon(b, sheathed)
            if sheathed then
                b.Icon:SetTexCoord(0, 0.5, 0, 1);
            else
                b.Icon:SetTexCoord(0.5, 1, 0, 1);
            end
        end
    
        SheatheToggle_SetIcon(SheatheToggle, true);

        local function SheatheToggle_OnClick(b)
            local playerActor = GetPlayerActor();
            if not playerActor then return end;
            local sheathed = not playerActor:GetSheathed();
            playerActor:SetSheathed(sheathed);
            SheatheToggle_SetIcon(b, sheathed);
        end

        local function SheatheToggle_OnKeyDown(b, key, down)
            if b:IsEnabled() then
                if b.hotkey == key then
                    SheatheToggle_OnClick(b);
                    b:SetPropagateKeyboardInput(false);
                    return
                end
            end
            b:SetPropagateKeyboardInput(true);
        end

        local function SheatheToggle_OnShow(b)
            local hotkey = GetBindingKey("TOGGLESHEATH");
            b.hotkey = hotkey;
            if hotkey then
                b.tooltipText = BINDING_NAME_TOGGLESHEATH.." |cffffd100("..hotkey..")|r";
                b:SetScript("OnKeyDown", SheatheToggle_OnKeyDown);
            else
                b.tooltipText = BINDING_NAME_TOGGLESHEATH;
                b:SetScript("OnKeyDown", nil);
            end
        end

        local function SheatheToggle_OnHide(b)
            b:SetScript("OnKeyDown", nil);
        end

        SheatheToggle:SetScript("OnShow", SheatheToggle_OnShow);
        SheatheToggle:SetScript("OnHide", SheatheToggle_OnHide);

        function SheatheToggle:SetState(perksVendorCategoryID)
            local enable = perksVendorCategoryID and (perksVendorCategoryID ~= 2) and (perksVendorCategoryID ~= 3);
            local playerActor = GetPlayerActor();
            enable = enable and (playerActor and playerActor:IsShown());
            local sheathed = playerActor and playerActor:GetSheathed();
            SheatheToggle_SetIcon(self, sheathed);
            if enable then
                self:Enable();
            else
                self:Disable();
            end
        end

        SheatheToggle.onClickFunc = SheatheToggle_OnClick;
        SheatheToggle:SetState(SELECTED_DATA and SELECTED_DATA.perksVendorCategoryID);

        SheatheToggle_OnShow(SheatheToggle);

        AnimationButton = CreateFrame("Button", nil, f, "NarciPerksProgramSquareButtonTemplate");
        AnimationButton:SetPoint("LEFT", SheatheToggle, "RIGHT", 4, 0);
        AnimationButton.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PerksProgram/AnimationIcon");

        AnimationDropDown:SetParentButton(AnimationButton);
        AnimationDropDown:UpdateOptions();

        local function AnimationButton_OnClick(b)
            if AnimationDropDown:IsShown() then
                AnimationDropDown:Hide();
            else
                AnimationDropDown:ShowFrame();
            end
        end

        AnimationButton.onClickFunc = AnimationButton_OnClick;

        
        local function SkinSmallButton(button, checkTexture, disabledCheckTexture)
            button:SetSize(48, 48);
            button:SetNormalAtlas("perks-button-up");
            button:SetPushedAtlas("perks-button-down");
            button:SetHighlightAtlas("perks-button-up");

            local pushedTex = button:GetPushedTexture();
            pushedTex:SetPoint("CENTER", button, "CENTER", 1, -1);

            local tex1 = button:GetCheckedTexture();    --Texture, not fileID
            if tex1 then
                tex1:ClearAllPoints();
                tex1:SetPoint("CENTER", button, "CENTER", 0, 0);
                tex1:SetSize(24, 24);
                tex1:SetAtlas(checkTexture);
            end

            local tex2 = button:GetDisabledCheckedTexture();
            if tex2 then
                tex2:ClearAllPoints();
                tex2:SetPoint("CENTER", button, "CENTER", 0, 0);
                tex2:SetSize(24, 24);
                tex2:SetAtlas(disabledCheckTexture);
            end

            button.Text:Hide();
        end

        local PlayerToggle = BlizzardFrame.FooterFrame.TogglePlayerPreview;
        --[[
        if PlayerToggle then
            SkinSmallButton(PlayerToggle, "common-icon-checkmark-yellow", "common-icon-checkmark");
            PlayerToggle:ClearAllPoints();
            PlayerToggle:SetPoint("RIGHT", f.RotateLeftButton, "LEFT", -32, 0);
        end
        --]]
    end
end



NarciPerksProgramItemDetailExtraFrameMixin = {};

function NarciPerksProgramItemDetailExtraFrameMixin:OnLoad()
    ExtraDetailFrame = self;

    if not DataProvider:DoesPerksProgramExist() then return end;

    self:RegisterEvent("PERKS_PROGRAM_OPEN");
    self:RegisterEvent("PERKS_PROGRAM_CLOSE");
    self:SetEnsembleHeaderText();

    EventRegistry:RegisterCallback("PerksProgramModel.OnProductSelectedAfterModel", OnProductSelectedAfterModel, ExtraDetailFrame);
    EventRegistry:RegisterCallback("PerksProgramFrame.OnShow", self.LoadUserSettings, self);
end

function NarciPerksProgramItemDetailExtraFrameMixin:Init()
    self.Init = nil;

    if BlizzardFrame.ConfirmPurchase and BlizzardFrame.GetSelectedProduct then
        hooksecurefunc("StaticPopup_Show", function(which)
            if which == "PERKS_PROGRAM_CONFIRM_PURCHASE" then
                self:TryShowPurchaseAlert();
            end
        end)

        if StaticPopup1 then
            StaticPopup1:HookScript("OnHide", function()
                self:HidePurchaseAlert();
            end);
        end
    end

    if BlizzardFrame.ToggleHideArmorSetting then
        hooksecurefunc(BlizzardFrame, "ToggleHideArmorSetting", function(_, playerArmorSetting)
            DataProvider:SaveUserData("hidePlayerArmorSetting", playerArmorSetting);
        end)
    end

    local att = self.AutoTryOnToggle;
    self.autoDisplayTransmogSet = DataProvider:GetTimeLimitedData("autoDisplayTransmogSet");

    local function att_UpdateVisual()
        if self.autoDisplayTransmogSet then
            att.Checkbox:SetTexCoord(0, 0.5, 0, 1);
        else
            att.Checkbox:SetTexCoord(0.5, 1, 0, 1);
        end
    end

    do
        local function OnClick()
            self:ToggleAutoDisplayTransmogSet();
            att_UpdateVisual();
        end

        local function OnEnter()
            att.ButtonText:SetTextColor(1, 1, 1);
        end

        local function OnLeave()
            att.ButtonText:SetTextColor(0.67, 0.67, 0.67);
        end

        att:SetScript("OnClick", OnClick);
        att:SetScript("OnEnter", OnEnter);
        att:SetScript("OnLeave", OnLeave);

        OnLeave();
        att_UpdateVisual();
    end

    att.ButtonText:SetText(L["Auto Try On All Items"]);

    local buttonWidth = att:GetWidth();
    local checkboxSize = 40;
    local textWidth = att.ButtonText:GetWrappedWidth();
    local visualCompensation = -8;
    local gap = -2;
    local offsetX = 0.5*(buttonWidth - checkboxSize - textWidth + visualCompensation);
    att.Checkbox:ClearAllPoints();
    att.Checkbox:SetPoint("LEFT", att, "LEFT", offsetX, 0);
    att.ButtonText:ClearAllPoints();
    att.ButtonText:SetPoint("LEFT", att.Checkbox, "RIGHT", gap, 0);

    do
        local HeaderMouseoverFrame = self.HeaderMouseoverFrame;

        local function FitToText(f)
            local width = self.HeaderText:GetWrappedWidth();
            f:SetWidth(width + 16);
        end

        local function OnEnter(f)
            if self.sourceIDs then
                local n = 0;
                local itemCosts = {};
                local totalCosts = 0;
                local price, purchased;
                local name, loaded;
                local allLoaded = true;

                for _, sourceID in ipairs(self.sourceIDs) do
                    name, loaded = GetColorizedItemNameFromSource(sourceID);
                    if name then
                        allLoaded = allLoaded and loaded;
                        price, purchased = DataProvider:GetVendorItemPriceBySourceID(sourceID);
                        if purchased then
                            n = n + 1;
                            itemCosts[n] = {name, 0};
                        elseif price and price > 0 then
                            n = n + 1;
                            itemCosts[n] = {name, price};
                            totalCosts = totalCosts + price;
                        end
                    end
                end

                if n > 0 then
                    local tooltip = PerksProgramUITooltip;
                    tooltip:Hide();
                    tooltip:SetOwner(self, "ANCHOR_NONE");
                    tooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", -8, 0);

                    if totalCosts > 0 then
                        tooltip:AddDoubleLine(L["Full Set Cost"], totalCosts..CURRENCY_MARKUP, 1, 0.82, 0, 1, 1, 1);
                    else
                        tooltip:AddDoubleLine(L["Full Set Cost"], "|A:perks-owned-small:0:0|a", 1, 0.82, 0, 1, 1, 1);
                    end

                    for _, data in ipairs(itemCosts) do
                        if data[2] > 0 then
                            tooltip:AddDoubleLine(data[1], data[2]..CURRENCY_MARKUP, 1, 1, 1, 1, 1, 1);  --interface/icons/tradingpostcurrency.blp
                        else
                            tooltip:AddDoubleLine(data[1], "|A:perks-owned-small:0:0|a", 1, 1, 1, 1, 1, 1);
                        end
                    end

                    tooltip:Show();

                    if not allLoaded then
                        After(0.2, function()
                            if f:IsVisible() and f:IsMouseOver() then
                                OnEnter(f);
                            end
                        end);
                    end
                end
            end

        end

        local function OnLeave(f)
            PerksProgramUITooltip:Hide();
        end

        HeaderMouseoverFrame.FitToText = FitToText;

        HeaderMouseoverFrame:SetScript("OnEnter", OnEnter);
        HeaderMouseoverFrame:SetScript("OnLeave", OnLeave);
    end

    do  --Fixed Mount Speical, Attack Animation Checkboxes status not saved issue
        --NOTE: We instead disable the two checkboxes because we already have equivalents (animation dropdown)

        local ff = BlizzardFrame.FooterFrame;
        local mc = BlizzardFrame.ModelSceneContainerFrame;

        if BlizzardFrame.SetMountSpecialPreviewOnClick then
            BlizzardFrame:SetMountSpecialPreviewOnClick(false);
        end

        if BlizzardFrame.PlayerSetAttackAnimationOnClick then
            BlizzardFrame:PlayerSetAttackAnimationOnClick(false);
        end

        if mc and ff.ToggleHideArmor and ff.TogglePlayerPreview then
            local function HideCheckboxes()
                ff.ToggleHideArmor:SetPoint("LEFT", ff.RotateButtonContainer, "LEFT", -18, 0);
                ff.TogglePlayerPreview:SetPoint("LEFT", ff.RotateButtonContainer, "LEFT", -18, 0);

                if ff.ToggleMountSpecial then
                    ff.ToggleMountSpecial:Hide();
                end

                if ff.ToggleAttackAnimation then
                    ff.ToggleAttackAnimation:Hide();
                end
            end

            After(0, function()
                EventRegistry:UnregisterCallback("PerksProgram.OnMountSpecialPreviewSet", PerksProgramFrame.ModelSceneContainerFrame);
                EventRegistry:UnregisterCallback("PerksProgram.OnPlayerAttackAnimationSet", PerksProgramFrame.ModelSceneContainerFrame);
                HideCheckboxes();
            end);
        end

        --This method may not be secure:
        C_PerksProgram.IsMountSpecialAnimToggleEnabled = function() return false end;
        C_PerksProgram.IsAttackAnimToggleEnabled = function() return false end;

        --[[    --The actual fix

        if (mc and mc.OnMountSpecialPreviewSet and mc.OnPlayerAttackAnimationSet)
        and (BlizzardFrame.SetMountSpecialPreviewOnClick and BlizzardFrame.PlayerSetAttackAnimationOnClick)
        and (ff and ff.OnProductSelected and ff.ToggleMountSpecial and ff.ToggleAttackAnimation) then
            ff.ToggleMountSpecial:HookScript("OnClick", function(f)
                local isChecked = f:GetChecked();
                DataProvider:SaveUserData("mountSpecialAnimPlaying", isChecked);
            end);

            ff.ToggleAttackAnimation:HookScript("OnClick", function(f)
                local isChecked = f:GetChecked();
                DataProvider:SaveUserData("attackAnimationPlaying", isChecked);
            end);

            local EventSolver = CreateFrame("Frame", nil, BlizzardFrame);
            EventSolver:Hide();
            EventSolver:SetScript("OnHide", function()
                EventSolver.t = 0;
                EventSolver:Hide();
            end);
            EventSolver:SetScript("OnShow", function()
                EventSolver.t = 0;
            end);

            EventSolver:SetScript("OnUpdate", function(f, elapsed)
                f.t = f.t + elapsed;
                if f.t > 0 then
                    f:Hide();

                    if ff.ToggleMountSpecial:IsShown() then
                        local isChecked = DataProvider:GetUserData("mountSpecialAnimPlaying");
                        --BlizzardFrame:SetMountSpecialPreviewOnClick(isChecked);
                        ff.ToggleMountSpecial:SetChecked(isChecked);
                        mc:OnMountSpecialPreviewSet(isChecked);
                    end

                    if ff.ToggleAttackAnimation:IsShown() then
                        local isChecked = DataProvider:GetUserData("attackAnimationPlaying");
                        --BlizzardFrame:PlayerSetAttackAnimationOnClick(isChecked);
                        ff.ToggleAttackAnimation:SetChecked(isChecked);
                        mc:OnPlayerAttackAnimationSet(isChecked);
                    end
                end
            end);

            function EventSolver:Start()
                EventSolver.t = 0;
                EventSolver:Show();
            end

            After(0, function()
                EventRegistry:UnregisterCallback("PerksProgram.OnMountSpecialPreviewSet", PerksProgramFrame.ModelSceneContainerFrame);
                EventRegistry:UnregisterCallback("PerksProgram.OnPlayerAttackAnimationSet", PerksProgramFrame.ModelSceneContainerFrame);

                EventRegistry:RegisterCallback("PerksProgramModel.OnProductSelectedAfterModel", function()
                    EventSolver:Start();
                end);

                EventRegistry:RegisterCallback("PerksProgram.OnMountSpecialPreviewSet", function()
                    EventSolver:Start();
                end);

                EventRegistry:RegisterCallback("PerksProgram.OnPlayerAttackAnimationSet", function()
                    EventSolver:Start();
                end);

                EventSolver:Start();
            end)
        end
        --]]
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:OnEvent(event, ...)
    if event == "PERKS_PROGRAM_OPEN" then   --Alawys ON
        self:UnregisterEvent(event);
        Initialize();
        self:Init();
        self:LoadUserSettings();
    elseif event == "PERKS_PROGRAM_CLOSE" then  --Alawys ON
        SELECTED_DATA = nil;
        TransmogDataProvider:ClearTransmogSetCache();
        self:SaveUserSettings();
    elseif event == "PERKS_PROGRAM_PURCHASE_SUCCESS" or event == "PERKS_PROGRAM_REFUND_SUCCESS" then    --Dynamic
        self:UpdateItemButtons();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:ReleaseButtons()
    if self.buttons then
        for i, button in pairs(self.buttons) do
            button:ClearData();
        end
    end

    self.Pointer:Hide();
    self.Pointer:ClearAllPoints();
    self.HeaderMouseoverFrame:Hide();
end

function NarciPerksProgramItemDetailExtraFrameMixin:PointAtButton(button)
    if button then
        self.Pointer:ClearAllPoints();
        self.Pointer:SetPoint("TOP", button, "BOTTOM", 0, 0);
        self.Pointer:Show();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:AcquireSmallButton(i)
    if not self.buttons then
        self.buttons = {};
    end
    if not self.buttons[i] then
        self.buttons[i] = CreateFrame("Button", nil, self, "NarciPerksProgramItemDetailButtonTemplate");
    end
    return self.buttons[i];
end

function NarciPerksProgramItemDetailExtraFrameMixin:HideFrame()
    if self:IsShown() then
        self:Hide();
        self:ReleaseButtons();
        self.HeaderText:SetText("");
        self.sourceIDs = nil;
        self.viewedSourceID = nil;
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:CalculateInitialOffset(buttonSize, gap, numButtons, maxButtonPerRow)
    local spanX = (buttonSize + gap) * (math.min(numButtons, maxButtonPerRow)) - gap;
    return -0.5*spanX;
end

function NarciPerksProgramItemDetailExtraFrameMixin:DisplayPetInfo(speciesID)
    self:ReleaseButtons();
    self.AutoTryOnToggle:Hide();

    if speciesID then
        local _, _, petType, _, _, _, _, canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
        local abilities, levels = C_PetJournal.GetPetAbilityList(speciesID);
        if (canBattle) and (not abilities) then self:Hide(); return; end;

        local numItems = #abilities;

        local buttonSize = 32;
        local buttonGap = 8;
        local verticalGap = 4;
        local maxButtonPerRow = 3;
        local col, row = 0, 0;

        local buttonUnit = buttonSize + buttonGap;
        local fromOffsetX = self:CalculateInitialOffset(buttonSize, buttonGap, numItems, maxButtonPerRow);

        local button;

        for i = 1, numItems do
            col = col + 1;
            if col > maxButtonPerRow then
                col = 1;
                row = row + 1;
                fromOffsetX = self:CalculateInitialOffset(buttonSize, buttonGap, numItems - row*maxButtonPerRow, maxButtonPerRow);
            end
            button = self:AcquireSmallButton(i);
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self.HeaderText, "BOTTOM", fromOffsetX + (col - 1) * buttonUnit, -8 -row*(buttonSize + verticalGap));
            button:SetPetAbilityInfo(abilities[i], levels[i]);
        end

        local petTypeName = _G["BATTLE_PET_NAME_"..petType] or "Unknown Type";
        local petTypeIcon = GetPetTypeTexture(petType, 16);
        petTypeName = petTypeIcon.." "..petTypeName;

        if canBattle then
            self.HeaderText:SetText(petTypeName);
        else
            self.HeaderText:SetText(petTypeName.."\n".. BATTLE_PET_CANNOT_BATTLE);
        end

        local headerHeight = math.floor(self.HeaderText:GetHeight() + 0.5);

        if numItems > 0 then
            self:SetHeight(headerHeight + 8 + (buttonSize + verticalGap) * (row +1) - verticalGap);
        else
            self:SetHeight(headerHeight);
        end
        self:Show();
    else
        self:Hide();
    end

    self:UnregisterEvent("PERKS_PROGRAM_PURCHASE_SUCCESS");
    self:UnregisterEvent("PERKS_PROGRAM_REFUND_SUCCESS");
end

function NarciPerksProgramItemDetailExtraFrameMixin:SetEnsembleHeaderText(slotName)
    if slotName then
        self.HeaderText:SetText(slotName);
        self.HeaderText:SetTextColor(1, 1, 1);
    else
        self.HeaderText:SetText(self.defaultHeaderText);
        if self.defaultHeaderColor == 1 then
            self.HeaderText:SetTextColor(1, 0.82, 0);
        else
            self.HeaderText:SetTextColor(0.5, 0.5, 0.5);
        end
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:DisplayEnsembleSources(sourceIDs, hiddenTransmogSetMode, viewedSourceID)
    self:ReleaseButtons();

    local extraHeight = 0;

    if hiddenTransmogSetMode then
        self.AutoTryOnToggle:Show();
        extraHeight = 24 + 16;
        self.HeaderMouseoverFrame:Show();
    else
        self.AutoTryOnToggle:Hide();
        self.HeaderMouseoverFrame:Hide();
    end

    local numItems = (sourceIDs and #sourceIDs) or 0;

    if numItems > 1 then
        local buttonSize = 32;
        local buttonGap = 4;
        local maxButtonPerRow = 8;
        local col, row = 0, 0;

        local buttonUnit = buttonSize + buttonGap;
        local fromOffsetX = self:CalculateInitialOffset(buttonSize, buttonGap, numItems, maxButtonPerRow);
        local fromOffsetY = -22;

        local showItemName = hiddenTransmogSetMode == true;

        local button;
        local sourceID;

        for i = 1, numItems do
            sourceID = sourceIDs[i];
            col = col + 1;
            if col > maxButtonPerRow then
                col = 1;
                row = row + 1;
                fromOffsetX = self:CalculateInitialOffset(buttonSize, buttonGap, numItems - row*maxButtonPerRow, maxButtonPerRow);
            end
            button = self:AcquireSmallButton(i);
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self, "TOP", fromOffsetX + (col - 1) * buttonUnit, fromOffsetY -row*buttonUnit);
            button:SetTransmogSource(sourceID);
            button.showItemName = showItemName;

            if sourceID == viewedSourceID then
                self:PointAtButton(button);
            end
        end

        self.defaultHeaderText = L["Include Header"];
        self.defaultHeaderColor = 0;
        self:SetEnsembleHeaderText();
        self:SetHeight(14 + 8 + buttonUnit * (row +1) - buttonGap + extraHeight);
        self:Show();
        self.numActiveButtons = numItems;
        self:RegisterEvent("PERKS_PROGRAM_PURCHASE_SUCCESS");
        self:RegisterEvent("PERKS_PROGRAM_REFUND_SUCCESS");
    else
        self:HideFrame();
        self.numActiveButtons = 0;
    end

    self.sourceIDs = sourceIDs;
    self.viewedSourceID = viewedSourceID;
end

function NarciPerksProgramItemDetailExtraFrameMixin:DisplayHiddenTransmogSet(setInfo, viewedSourceID)
    local sourceIDs = setInfo.sources;
    self:DisplayEnsembleSources(sourceIDs, true, viewedSourceID);
    self.defaultHeaderText = setInfo.name;
    self.defaultHeaderColor = 1;
    self:SetEnsembleHeaderText();
    self.HeaderMouseoverFrame:FitToText();

    if self.autoDisplayTransmogSet then
        local playerActor = GetPlayerActor();
        if not playerActor then return end;
        for _, sourceID in ipairs(sourceIDs) do
            playerActor:TryOn(sourceID);
        end
    else

    end

    self:UpdateItemVisibility();
end

function NarciPerksProgramItemDetailExtraFrameMixin:UpdateItemVisibility()
    local button;
    local hideItem = not self.autoDisplayTransmogSet;

    for i = 1, self.numActiveButtons do
        button = self.buttons[i];
        if button.transmogSourceID == self.viewedSourceID then
            button.hideItem = false;
        else
            button.hideItem = hideItem;
        end
        button:UpdateVisual();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:UpdateItemButtons()
    After(0.5, function()
        local button;
        for i = 1, self.numActiveButtons do
            button = self.buttons[i];
            if button.transmogSourceID then
                button.GreenCheck:SetShown(C_TransmogCollection.PlayerKnowsSource(button.transmogSourceID));
            end
        end
    end);
end

function NarciPerksProgramItemDetailExtraFrameMixin:ToggleAutoDisplayTransmogSet()
    self.autoDisplayTransmogSet = not self.autoDisplayTransmogSet;
    DataProvider:SetTimeLimitedData("autoDisplayTransmogSet", self.autoDisplayTransmogSet);

    if self.autoDisplayTransmogSet then
        if self.sourceIDs then
            local playerActor = GetPlayerActor();
            if not playerActor then return end;
            for _, sourceID in ipairs(self.sourceIDs) do
                playerActor:TryOn(sourceID);
            end
        end
    else
        if self.viewedSourceID then
            local playerActor = GetPlayerActor();
            if not playerActor then return end;
            playerActor:Undress();
            playerActor:TryOn(self.viewedSourceID);
        end
    end

    self:UpdateItemVisibility();
end

function NarciPerksProgramItemDetailExtraFrameMixin:OnHide()
    self:HideFrame();
    self:UnregisterEvent("PERKS_PROGRAM_PURCHASE_SUCCESS");
    self:UnregisterEvent("PERKS_PROGRAM_REFUND_SUCCESS");
end

function NarciPerksProgramItemDetailExtraFrameMixin:TryShowPurchaseAlert()
    if (self:IsVisible() and self.viewedSourceID and self.autoDisplayTransmogSet) then

    else
        return
    end


    local product = BlizzardFrame:GetSelectedProduct();
    local sourceID = product and product.itemModifiedAppearanceID;
    if sourceID == 0 then return end;

    local f = self.PurchaseAlertFrame;
    if not f then
        f = CreateFrame("Frame", nil, self);
        self.PurchaseAlertFrame = f;

        local scale = 2;
        local padding = 4;
        local modelWidth = 78 * scale;
        local modelHeight = 104 * scale;
        f:SetSize(modelWidth + 2*padding, modelHeight + 2*padding);
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

        NarciAPI.NineSliceUtil.SetUpBorder(f, "genericChamferedBorder", nil, 0.25, 0.25, 0.25, 1, 7);
        NarciAPI.NineSliceUtil.SetUpBackdrop(f, "genericChamferedBackground", nil, 0, 0, 0, 0.9, -8);

        f.Model = CreateFrame("DressUpModel", nil, f);
        f.Model:SetSize(modelWidth, modelHeight);
        f.Model:SetPoint("CENTER", 0, 0);
        f.Model:SetAutoDress(false);
        f.Model:SetDoBlend(false);
        NarciAPI.TransitionAPI.SetModelLight( f.Model, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);

        f.Model:SetScript("OnModelLoaded", function(m)
            if m.cameraID then
                Model_ApplyUICamera(f.Model, m.cameraID);
            end

            if m.sourceID then
                m:TryOn(m.sourceID);
            end
        end)

        f.Title = f:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med2_Outline");
        f.Title:SetTextColor(1, 0.82, 0);
        f.Title:SetJustifyH("CENTER");
        f.Title:SetText(L["You Will Receive One Item"]);
        f.Title:SetPoint("BOTTOM", f, "TOP", 0, 12);

        f:SetFrameStrata("FULLSCREEN_DIALOG");
    end

    local itemID = C_TransmogCollection.GetSourceItemID(sourceID);
    if not itemID then return end;

    local Model = f.Model;
    Model.cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(sourceID);
    Model:ClearModel();

    f:Show();

    if NarciAPI.IsHoldableItem(itemID) then
        Model.sourceID = nil;
        Model:SetItem(itemID, sourceID);
    else
        Model.sourceID = sourceID;
        Model:SetUseTransmogChoices(true);
        Model:SetUseTransmogSkin(true);
        Model:Undress();
        NarciAPI.TransitionAPI.SetModelByUnit(Model, "player");
        Model:FreezeAnimation(0, 0, 0);
        Model:TryOn(sourceID);  --Model must be visible first
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:HidePurchaseAlert()
    if self.PurchaseAlertFrame and self.PurchaseAlertFrame:IsShown() then
        self.PurchaseAlertFrame:Hide();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:SaveUserSettings()
    --Save the status
end

function NarciPerksProgramItemDetailExtraFrameMixin:LoadUserSettings()
    if not BlizzardFrame then return end;

    if DataProvider:GetUserData("hidePlayerArmorSetting") and not BlizzardFrame.hidePlayerArmorSetting then
        BlizzardFrame.hidePlayerArmorSetting = true;
        EventRegistry:TriggerEvent("PerksProgram.OnPlayerHideArmorToggled");
    end
end

--Transmog Item Source
local function TransmogItemButton_OnEnter(self)
    if self.transmogSourceID then
        local itemID = C_TransmogCollection.GetSourceItemID(self.transmogSourceID);
        local slotName;
        if itemID then
            local _, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(itemID);

            if classID == 4 then        --Armor
                if subclassID == 6 then
                    slotName = itemSubType;
                else
                    slotName = itemEquipLoc and _G[itemEquipLoc];
                end
            elseif classID == 2 then    --Weapon Type
                slotName = itemSubType;
            end

            if self.showItemName then
                local itemName, isLoaded = GetColorizedItemNameFromSource(self.transmogSourceID, itemID)
                if isLoaded then
                    slotName = string.format("%s - %s", slotName, itemName);
                else
                    After(0.2, function()
                        if self:IsMouseOver() and self:IsVisible() then
                            TransmogItemButton_OnEnter(self);
                        end
                    end);
                end
            end
        end
        ExtraDetailFrame:SetEnsembleHeaderText(slotName);
    end
end

local function TransmogItemButton_OnLeave(self)
    ExtraDetailFrame:SetEnsembleHeaderText();
end

local function SelectProductBySourceID(itemModifiedAppearanceID)
    local f = BlizzardFrame.ProductsFrame;

    local frozenProductItemInfo = f.FrozenProductContainer:GetItemInfo();
    if frozenProductItemInfo and frozenProductItemInfo.itemModifiedAppearanceID == itemModifiedAppearanceID then
        f.FrozenProductContainer:SetSelected(true);
        return true
    end

    local scrollContainer = f.ProductsScrollBoxContainer;
    local scrollBox = scrollContainer.ScrollBox;
    local index, foundElementData = scrollBox:FindByPredicate(function(elementData)
        return elementData.itemModifiedAppearanceID == itemModifiedAppearanceID
    end);
    if foundElementData then
        scrollContainer.selectionBehavior:SelectElementData(foundElementData);
        scrollBox:ScrollToElementDataIndex(index);
        return true
    end

    return false
end

local function TransmogItemButton_OnClick(self, button)
    if button == "LeftButton" then
        local playerActor = GetPlayerActor();
        if not playerActor then return end;

        self.hideItem = not self.hideItem;

        local sourceInfo = C_TransmogCollection.GetSourceInfo(self.transmogSourceID);
        if not sourceInfo then return end;

        local slotID = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
        if self.hideItem then
            playerActor:UndressSlot(slotID);
        else
            playerActor:TryOn(self.transmogSourceID);
        end
        self:UpdateVisual();
    elseif button == "RightButton" then
        if self.transmogSourceID then
            if SelectProductBySourceID(self.transmogSourceID) then
                
            end
        end
    end
end

--Pet Ability
local function PetAbilityButton_OnEnter(self)
    SetupPetAbilityTooltip(self, self.petAbilityID, self.petAbilityLevel);
end

NarciPerksProgramItemDetailButtonMixin = {};

function NarciPerksProgramItemDetailButtonMixin:OnEnter()
    self.Highlight:Show();
    if self.onEnterFunc then
        self.onEnterFunc(self);
    end
end

function NarciPerksProgramItemDetailButtonMixin:OnLeave()
    self.Highlight:Hide();
    PerksProgramUITooltip:Hide();

    if self.onLeaveFunc then
        self.onLeaveFunc(self);
    end
end

function NarciPerksProgramItemDetailButtonMixin:OnClick(button)
    if self.onClickFunc then
        self.onClickFunc(self, button);
    end
end

function NarciPerksProgramItemDetailButtonMixin:SetTransmogSource(sourceID)
    if self.type ~= "transmog" then
        self.onEnterFunc = TransmogItemButton_OnEnter;
        self.onLeaveFunc = TransmogItemButton_OnLeave;
        self.onClickFunc = TransmogItemButton_OnClick;
        self.type = "transmog";
    end

    local icon = C_TransmogCollection.GetSourceIcon(sourceID);
    self.Icon:SetTexture(icon);
    self:Show();
    self.transmogSourceID = sourceID;
    self.hideItem = nil;
    self:UpdateVisual();

    self.GreenCheck:SetShown(C_TransmogCollection.PlayerKnowsSource(sourceID));
end

function NarciPerksProgramItemDetailButtonMixin:SetPetAbilityInfo(abilityID, level)
    if self.type ~= "pet" then
        self.onEnterFunc = PetAbilityButton_OnEnter;
        self.onLeaveFunc = nil;
        self.onClickFunc = nil;
        self.type = "pet";
    end

    self.petAbilityID = abilityID;

    if abilityID then
        local name, icon, typeID = C_PetJournal.GetPetAbilityInfo(abilityID);
        self.Icon:SetTexture(icon);
        self.petAbilityLevel = level;
        self:Show();
    end

    self.hideItem = nil;
    self:UpdateVisual();
    self.GreenCheck:Hide();
end

function NarciPerksProgramItemDetailButtonMixin:ClearData()
    self.Icon:SetTexture(nil);
    self.transmogSourceID = nil;
    self.petAbilityID = nil;
    self.petAbilityLevel = nil;
    self.hideItem = nil;
    self:Hide();
end

function NarciPerksProgramItemDetailButtonMixin:UpdateVisual()
    if self.hideItem then
        self.Icon:SetDesaturated(true);
        self.Icon:SetVertexColor(0.72, 0.72, 0.72);
        self.RedEye:Hide(); --Always Hidden
    else
        self.Icon:SetDesaturated(false);
        self.Icon:SetVertexColor(1, 1, 1);
        self.RedEye:Hide();
    end
end


--Small Button (etc. Rotate Left/Right);
NarciPerksProgramSquareButtonMixin = {};

function NarciPerksProgramSquareButtonMixin:OnLoad()

end

function NarciPerksProgramSquareButtonMixin:OnEnter()
    if self:IsEnabled() and self.tooltipText then
        PerksProgramUITooltip:Hide();
        PerksProgramUITooltip:SetOwner(self, "ANCHOR_NONE");
        PerksProgramUITooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 2, 2);
        PerksProgramUITooltip:SetText(self.tooltipText, 1, 1, 1, true);
        PerksProgramUITooltip:Show();
    end
end

function NarciPerksProgramSquareButtonMixin:OnLeave()
    PerksProgramUITooltip:Hide();
end

function NarciPerksProgramSquareButtonMixin:OnClick()
    if self.onClickFunc then
        self.onClickFunc(self);
    end
end

function NarciPerksProgramSquareButtonMixin:OnMouseDown()
	if self:IsEnabled() then
		self.Icon:SetPoint("CENTER", self.PushedTexture);
	end
end

function NarciPerksProgramSquareButtonMixin:OnMouseUp()
	self.Icon:SetPoint("CENTER");
end

function NarciPerksProgramSquareButtonMixin:OnDisable()
    self.NormalTexture:SetDesaturated(true);
    self.Icon:SetDesaturated(true);
    self.NormalTexture:SetVertexColor(0.72, 0.72, 0.72);
    self.Icon:SetVertexColor(0.72, 0.72, 0.72);
end

function NarciPerksProgramSquareButtonMixin:OnEnable()
    self.NormalTexture:SetDesaturated(false);
    self.Icon:SetDesaturated(false);
    self.NormalTexture:SetVertexColor(1, 1, 1);
    self.Icon:SetVertexColor(1, 1, 1);
end

local ANIMATIONS_MOUNT = {
    0,      --Stand
    4,      --Walk
    5,      --Run
    13,     --Walk Backwards
    94,     --Mount Special
    548,    --Mount Flight Idle
};

local ANIMATIONS_PLAYER_DEFAULT = {
    STAND_ANIMATION,
    4,  --Walk
    5,  --Run
};

local ANIMATIONS_PLAYER_MELEE_1H = {
    STAND_ANIMATION, 4, 5,
    26,
};

local ANIMATIONS_PLAYER_MELEE_2H = {
    STAND_ANIMATION, 4, 5,
    27, 28,
};

local ANIMATIONS_PLAYER_SHIELD = {
    STAND_ANIMATION, 4, 5,
    26, 1078,
};

local ANIMATIONS_PLAYER_BOW = {
    STAND_ANIMATION, 4, 5,
    29, 109,
};

local ANIMATIONS_PLAYER_CROSSBOW = {
    STAND_ANIMATION, 4, 5,
    836, 842,
};

local ANIMATIONS_PLAYER_GUN = {
    STAND_ANIMATION, 4, 5,
    48, 110,
};

local ANIMATIONS_PLAYER_CASTER = {
    STAND_ANIMATION, 4, 5,
    51, 52,
};

--[[
local ANIMATIONS_PLAYER = {
    0,      --Stand
    26,     --Ready 1H
    27,     --Ready 2H
    28,     --Ready 2HL
    29,     --Ready Bow
    48,     --Ready Rifle
    51,     --Ready Spell Directed
    52,     --Ready Spell Omni
    836,    --Ready Crossbow
    --1026,   --Ready Glv

    --678,    --Monk Offense Ready
    --698,    --Monk Cast

    --860,    --Shaman
    --896,    --Mage
    --918,    --Warlock
    --940,    --Druid
    --988,    --Priest

    1078,   --Artifact Shield
};
--]]

do
    local tinsert = table.insert;
    local _, _, classID = UnitClass("player");

    if classID == 5 then        --Priest
        tinsert(ANIMATIONS_PLAYER_CASTER, 988);
    elseif classID == 7 then    --Shaman
        tinsert(ANIMATIONS_PLAYER_CASTER, 860);
    elseif classID == 8 then    --Mage
        tinsert(ANIMATIONS_PLAYER_CASTER, 896);
    elseif classID == 9 then    --Warlock
        tinsert(ANIMATIONS_PLAYER_CASTER, 918);
    elseif classID == 10 then   --Monk
        tinsert(ANIMATIONS_PLAYER_MELEE_1H, 678);
        tinsert(ANIMATIONS_PLAYER_MELEE_2H, 678);
        tinsert(ANIMATIONS_PLAYER_CASTER, 698);
    elseif classID == 11 then   --Druid
        tinsert(ANIMATIONS_PLAYER_CASTER, 940);
    elseif classID == 12 then   --DH
        tinsert(ANIMATIONS_PLAYER_MELEE_1H, 1026);
    end
end

NarciPerksProgramAnimationDropDownMixin = {};

function NarciPerksProgramAnimationDropDownMixin:OnLoad()
    AnimationDropDown = self;
    self.requireUpdate = true;
    self.animationIDs = ANIMATIONS_PLAYER_DEFAULT;
end

function NarciPerksProgramAnimationDropDownMixin:ShowFrame()
    self:Build();
    self:Show();
end

function NarciPerksProgramAnimationDropDownMixin:UpdateOptions()
    local enableDropdown = true;

    if SELECTED_DATA then
        self.requireUpdate = true;

        local categoryID = SELECTED_DATA.perksVendorCategoryID;
        self.categoryID = categoryID;
        self.perksVendorItemID = SELECTED_DATA.perksVendorItemID;
        self.itemID = SELECTED_DATA.itemID;

        if categoryID then
            if categoryID == 3 then --pet
                enableDropdown = false;
                self.actor = PerksProgramFrame.ModelSceneContainerFrame.MainModelScene:GetActorByTag("pet");
            elseif categoryID == 2 then
                self.mode = "mount";
                self.actor = PerksProgramFrame.ModelSceneContainerFrame.MainModelScene:GetActorByTag("mount");
            else
                self.mode = "player";
                self.actor = PerksProgramFrame.ModelSceneContainerFrame.playerActor;
            end
        else
            enableDropdown = false;
        end

        local displayData = SELECTED_DATA.displayData;
        if displayData then
            self.defaultAnimationKitID = displayData.animationKitID;
            if displayData.animationKitID then
                self.defaultAnimationID = nil;
            else
                self.defaultAnimationID = displayData.animation;
            end
        else
            self.defaultAnimationKitID = nil;
            self.defaultAnimationID = nil;
        end
    end

    if self.parentButton then
        if enableDropdown then
            self.parentButton:Enable();
        else
            self.parentButton:Disable();
        end
    end
end

local function GetBestAnimationsForItem(mode, itemID)
    if mode == "mount" then
        return ANIMATIONS_MOUNT
    else
        if itemID then
            local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemID);
            if classID == 4 then
                if subclassID == 6 then
                    return ANIMATIONS_PLAYER_SHIELD
                else
                    return ANIMATIONS_PLAYER_DEFAULT
                end
            elseif classID == 2 then
                if subclassID == 2 then
                    return ANIMATIONS_PLAYER_BOW
                elseif subclassID == 3 then
                    return ANIMATIONS_PLAYER_GUN
                elseif subclassID == 18 then
                    return ANIMATIONS_PLAYER_CROSSBOW
                else
                    if itemEquipLoc == "INVTYPE_2HWEAPON" then
                        return ANIMATIONS_PLAYER_MELEE_2H
                    else
                        return ANIMATIONS_PLAYER_MELEE_1H
                    end
                end
            else
                return ANIMATIONS_PLAYER_DEFAULT
            end
        else
            return ANIMATIONS_PLAYER_DEFAULT
        end
    end
end


function NarciPerksProgramAnimationDropDownMixin:Build()
    if not self.isLoaded then
        self.isLoaded = true;
        NarciAPI.NineSliceUtil.SetUpBorder(self.BackgroundFrame, "genericChamferedBorder", nil, 0.25, 0.25, 0.25, 1, 7);
        NarciAPI.NineSliceUtil.SetUpBackdrop(self.BackgroundFrame, "genericChamferedBackground", nil, 0, 0, 0, 0.9, -8);

        self.buttons = {};
        self.getNameFunc = NarciAnimationInfo.GetOfficialName;
    end

    if self.requireUpdate then
        self.requireUpdate = nil;

        self.animationIDs = GetBestAnimationsForItem(self.mode, self.itemID);

        local paddingV = 8;
        local buttonHeight = 24;
        local numButtons = #self.animationIDs;

        local defaultAnimationID = self.defaultAnimationID;
        local defaultOption = defaultAnimationID or self.defaultAnimationKitID;

        if self.mode == "mount" then
            self.defaultAnimationKitID = MOUNT_SPECIAL_ANIM_KIT;
            defaultOption = MOUNT_SPECIAL_ANIM_KIT;
            defaultAnimationID = nil;
        end

        if defaultAnimationID then
            for i = 1, #self.animationIDs do
                if self.animationIDs[i] == defaultAnimationID then
                    defaultOption = nil;
                    break
                end
            end
        end

        if defaultOption then   --Add a "Default" button if the default animation isn't on our animation list
            numButtons = numButtons + 1;
        end

        local button;

        local maxNumberWidth = 0;
        local maxNameWidth = 0;
        local numberWidth, nameWidth;

        numButtons = numButtons + 1;    --We use the first button as a checkbox/toggle

        local offsetY = paddingV;

        local animationButtonIndex = 0;
        self.indexedButtons = {};

        for i = 1, numButtons do
            if not self.buttons[i] then
                self.buttons[i] = CreateFrame("Button", nil, self, "NarciPerksProgramDropDownButtonTemplate");
            end
            button = self.buttons[i];

            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY);

            if i == 1 then  --Modify Default Pose
                numberWidth, nameWidth = button:SetModelSetupToggle();
                local dividerHeight = 12;
                offsetY = offsetY + buttonHeight;
                if not self.Divider then
                    self.Divider = self:CreateTexture(nil, "OVERLAY");
                    self.Divider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(offsetY + 0.5*dividerHeight));
                    self.Divider:SetPoint("RIGHT", self, "RIGHT", 0, 0);
                    self.Divider:SetColorTexture(0.2, 0.2, 0.2);
                end
                local pixel = NarciAPI.GetPixelForWidget(self, 1);
                self.Divider:SetHeight(pixel);
                offsetY = offsetY + dividerHeight;
            else
                animationButtonIndex = animationButtonIndex + 1;
                self.indexedButtons[animationButtonIndex] = button;
                button.index = animationButtonIndex;
                if defaultOption and i == numButtons then
                    if self.defaultAnimationKitID then
                        numberWidth, nameWidth = button:SetAnimationOption(L["Default Animation"], self.defaultAnimationKitID, true);
                    else
                        numberWidth, nameWidth = button:SetAnimationOption(L["Default Animation"], defaultAnimationID);
                    end
                else
                    numberWidth, nameWidth = button:SetAnimationOption(self.getNameFunc(self.animationIDs[i-1]), self.animationIDs[i-1]);
                end
                offsetY = offsetY + buttonHeight;
            end

            if numberWidth > maxNumberWidth then
                maxNumberWidth = numberWidth;
            end
            if nameWidth > maxNameWidth then
                maxNameWidth = nameWidth;
            end
            button:SetButtonFontColor(1);
        end

        self.maxIndex = animationButtonIndex;

        maxNumberWidth = math.floor(maxNumberWidth + 0.5);
        local buttonWidth =  math.floor(12 + maxNumberWidth + 12 + maxNameWidth + 12 + 0.5);
        if buttonWidth < 192 then
            buttonWidth = 192;
        end

        for i = 1, numButtons do
            self.buttons[i]:SetElementSizes(maxNumberWidth, buttonWidth);
            self.buttons[i]:Show();
        end

        for i = numButtons + 1, #self.buttons do
            self.buttons[i]:Hide();
        end

        self:SetWidth(buttonWidth);
        self:SetHeight(offsetY + paddingV);

        if CHANGE_POSE then
            self:SelectAnimationByIndex(1);
        else
            if defaultOption then
                self:SelectButton(self.buttons[numButtons]);
            else
                self:SelectButtonByAnimID(defaultAnimationID);
            end
        end
    end
end

function NarciPerksProgramAnimationDropDownMixin:SetParentButton(button)
    self.parentButton = button;
    self:ClearAllPoints();
    self:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 4, 4);
    self:SetParent(button);
end

local function AnimationButton_OnMouseWheel(self, delta)
    AnimationDropDown:OnMouseWheel(delta);
end

function NarciPerksProgramAnimationDropDownMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    if self.parentButton then
        self.parentButton:SetScript("OnMouseWheel", AnimationButton_OnMouseWheel);
    end
end

function NarciPerksProgramAnimationDropDownMixin:OnHide()
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    if self.parentButton then
        self.parentButton:SetScript("OnMouseWheel", nil);
    end
end

function NarciPerksProgramAnimationDropDownMixin:OnEvent()
    if not (self:IsMouseOver() or (self.parentButton and self.parentButton:IsMouseOver()) ) then
        self:Hide();
    end
end

function NarciPerksProgramAnimationDropDownMixin:HighlightButton(button)
    self.ButtonHighlight:ClearAllPoints();
    if button then
        self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0);
        self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
        self.ButtonHighlight:Show();
    else
        self.ButtonHighlight:Hide();
    end
end

local function AnimationDropDown_PlayAnimation(actor, button)
    if not actor then return end;

    actor:StopAnimationKit();
    actor:SetAnimationBlendOperation(1);  --LE_MODEL_BLEND_OPERATION_ANIM

    if button.animationKitID then
        actor:PlayAnimationKit(button.animationKitID, true);
    elseif button.animationID then
        actor:SetAnimation(button.animationID);
    end
end

function NarciPerksProgramAnimationDropDownMixin:SelectButton(button, click)
    if self.buttons then
        for i, b in ipairs(self.buttons) do
            if b == button then
                b.isSelected = true;
                b:SetButtonFontColor(3);
            elseif b.isSelected then
                b.isSelected = nil;
                b:SetButtonFontColor(1);
            end
        end
    end
    self.selectedButtonIndex = button.index;
    self:HighlightButton();

    if click then
        AnimationDropDown_PlayAnimation(self.actor, button);
    end
end

function NarciPerksProgramAnimationDropDownMixin:SelectAnimationByIndex(index, click)
    if self.indexedButtons then
        for i, b in ipairs(self.indexedButtons) do
            if i == index then
                b.isSelected = true;
                b:SetButtonFontColor(3);
                if click then
                    AnimationDropDown_PlayAnimation(self.actor, b);
                end
            elseif b.isSelected then
                b.isSelected = nil;
                b:SetButtonFontColor(1);
            end
        end
    end
    self.selectedButtonIndex = index;
end

function NarciPerksProgramAnimationDropDownMixin:SelectButtonByAnimID(animID, click)
    if self.buttons then
        for i, b in ipairs(self.buttons) do
            if b.animationID == animID then
                b.isSelected = true;
                b:SetButtonFontColor(3);
                self.selectedButtonIndex = b.index;
                if click then
                    AnimationDropDown_PlayAnimation(self.actor, b);
                end
            elseif b.isSelected then
                b.isSelected = nil;
                b:SetButtonFontColor(1);
            end
        end
    end
end

function NarciPerksProgramAnimationDropDownMixin:OnMouseWheel(delta)
    if not self.selectedButtonIndex then
        self.selectedButtonIndex = 0;
    end
    if not self.maxIndex then
        self.maxIndex = 1;
    end
    if delta < 0 then
        self.selectedButtonIndex = self.selectedButtonIndex + 1;
        if self.selectedButtonIndex > self.maxIndex then
            self.selectedButtonIndex = 1;
        end
    else
        self.selectedButtonIndex = self.selectedButtonIndex - 1;
        if self.selectedButtonIndex < 1 then
            self.selectedButtonIndex = self.maxIndex;
        end
    end
    self:SelectAnimationByIndex(self.selectedButtonIndex, true);
end


NarciPerksProgramDropDownButtonMixin = {};

function NarciPerksProgramDropDownButtonMixin:OnMouseDown()
    self.OptionNumber:SetPoint("LEFT", self, "LEFT", 13, 0);
end

function NarciPerksProgramDropDownButtonMixin:OnMouseUp()
    self.OptionNumber:SetPoint("LEFT", self, "LEFT", 12, 0);
end

function NarciPerksProgramDropDownButtonMixin:OnEnter()
    if not self.isSelected then
        AnimationDropDown:HighlightButton(self);
        self:SetButtonFontColor(2);
    else
        AnimationDropDown:HighlightButton();
    end

    if self.tooltip then
        local tooltip = PerksProgramUITooltip;
        tooltip:SetOwner(self, "ANCHOR_RIGHT");
        tooltip:SetText(self.OptionName:GetText(), 1, 1, 1);
        tooltip:AddLine(self.tooltip, 1, 0.82, 0, true);
        tooltip:Show();
    end
end

function NarciPerksProgramDropDownButtonMixin:OnLeave()
    AnimationDropDown:HighlightButton();
    PerksProgramUITooltip:Hide();
    if not self.isSelected then
        self:SetButtonFontColor(1);
    end
end

function NarciPerksProgramDropDownButtonMixin:SetButtonFontColor(colorIndex)
    SetButtonFontColor(self.OptionName, colorIndex);
    SetButtonFontColor(self.OptionNumber, colorIndex);
end

function NarciPerksProgramDropDownButtonMixin:SetAnimationOption(name, id, isAnimKit)
    self.onClickFunc = self.OnClick_Animation;
    self.OptionName:SetText(name);
    self.OptionNumber:SetWidth(0);

    local nameWidth = self.OptionName:GetWrappedWidth()
    local numberWidth;

    if id and not isAnimKit then
        self.OptionNumber:SetText(id);
        self.OptionNumber:Show();
        numberWidth = self.OptionNumber:GetWrappedWidth();
    else
        self.OptionNumber:SetText("--");
        self.OptionNumber:Show();
        numberWidth = 0;
    end

    if isAnimKit then
        self.animationKitID = id;
        self.animationID = nil;
    else
        self.animationKitID = nil;
        self.animationID = id;
    end


    return numberWidth, nameWidth;
end

local function UpdateModelSetupCheckbox(dropdownButton)
    if dropdownButton.Checkbox then
        if CHANGE_POSE then
            dropdownButton.Checkbox:SetTexCoord(0, 0.5, 0, 1);
        else
            dropdownButton.Checkbox:SetTexCoord(0.5, 1, 0, 1);
        end
    end
end

function NarciPerksProgramDropDownButtonMixin:SetModelSetupToggle()
    self.onClickFunc = self.OnClick_ModelSetupToggle;
    self.OptionName:SetText(L["Modify Default Pose"]);
    self.OptionNumber:Hide();

    local numberWidth = 0;
    local nameWidth = self.OptionName:GetWrappedWidth()

    if not self.Checkbox then
        self.Checkbox = self:CreateTexture(nil, "OVERLAY");
        self.Checkbox:SetPoint("LEFT", self, "LEFT", 6, 0);
        self.Checkbox:SetSize(40, 40);
        self.Checkbox:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PerksProgram/TwoStateCheckbox");
    end

    UpdateModelSetupCheckbox(self);

    self.tooltip = L["Modify Default Pose Tooltip"];

    return numberWidth, nameWidth
end

function NarciPerksProgramDropDownButtonMixin:SetElementSizes(numberWidth, buttonWidth)
    if numberWidth > 0 then
        self.OptionNumber:SetWidth(numberWidth);
    end
    self:SetWidth(buttonWidth);
end

function NarciPerksProgramDropDownButtonMixin:OnClick()
    if self.onClickFunc then
        self.onClickFunc(self);
    end
end

function NarciPerksProgramDropDownButtonMixin:OnClick_Animation()
    AnimationDropDown:SelectButton(self, true);
end

function NarciPerksProgramDropDownButtonMixin:OnClick_ModelSetupToggle()
    CHANGE_POSE = not CHANGE_POSE;
    UpdateModelSetupCheckbox(self);
    NarcissusDB.TradingPostChangePost = CHANGE_POSE;

    if SELECTED_DATA then
        UpdateProductModelAnimation(SELECTED_DATA, true);
    end
end

--[[
if true then
    local f = CreateFrame("Frame");
    f:RegisterEvent("PERKS_PROGRAM_OPEN");
    f:RegisterEvent("PERKS_PROGRAM_DATA_REFRESH");

    f:SetScript("OnEvent", function(self, event, ...)
        print(event, ...)
        if event == "PERKS_PROGRAM_OPEN" then
            After(0.5, function()
                PerksProgramFrame:SetPropagateKeyboardInput(true);
                --PerksProgramFrame:SetToplevel(false);
                --PerksProgramFrame:SetFrameStrata("LOW");
                SetUIVisibility(true)
            end);
        end
    end);
end


function InjectVendorItemIDs()
    LoadAddOn("Blizzard_PerksProgram")
    ShowUIPanel(PerksProgramFrame);
    PerksProgramFrame:SetPropagateKeyboardInput(true);
    BlizzardFrame.vendorItemIDs = DataProvider:GetCurrentMonthItems();
    BlizzardFrame.ProductsFrame:UpdateProducts();
    print("Injected")
end
--]]