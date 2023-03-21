---- Extra Features For PerksProgramFrame

local _, addon = ...
local DataProvider = addon.PerksProgramDataProvider;

local L = Narci.L;

local BlizzardFrame;
local PerksProgramUITooltip;
local ExtraDetailFrame;    --1.Display the items of an ensemble on ProductDetailsContainerFrame   2.Toggle individual item's visibility.
local SheatheToggle;
local AnimationButton, AnimationDropDown;

local SELECTED_DATA;


local function SetButtonFontColor(fontString, colorIndex)
    if colorIndex == 1 then
        fontString:SetTextColor(0.5, 0.5, 0.5);
    elseif colorIndex == 2 then
        fontString:SetTextColor(1, 1, 1);
    elseif colorIndex == 3 then
        fontString:SetTextColor(1, 0.82, 0);
    end
end

local function OnProductSelectedAfterModel(f, data)
    --Enum.PerksVendorCategoryType
    SELECTED_DATA = data;

    local categoryID = data.perksVendorCategoryID;
    local showExtraDetail;
    local showSheatheToggle = true;

    if categoryID == 8 then
        if data.transmogSetID then
            ExtraDetailFrame:Show();
            local sourceIDs = C_TransmogSets.GetAllSourceIDs(data.transmogSetID);
            ExtraDetailFrame:DisplayEnsembleSources(sourceIDs);
            showExtraDetail = true;
        end
    elseif categoryID == 3 then
        if data.speciesID then
            ExtraDetailFrame:DisplayPetInfo(data.speciesID);
            showExtraDetail = true;
        end
        showSheatheToggle = false;
    elseif categoryID == 2 then
        --mount
        showSheatheToggle = false;
    end

    if not showExtraDetail then
        ExtraDetailFrame:HideFrame();
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
        return string.format("|T%s:%d:%d:0:0:128:256:102:63:129:168|t", "Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petTypeID], size, size);
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
            icon = string.format(typeIconFomart, icon, "Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[typeID]);
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
    local owner = f:GetOwner();
    if not owner then return end;

    if owner.perksVendorItemID then
        --PerksProgramProductButtonTemplate

        --[[
        local categoryID;
        if owner.GetElementData then
           local data = owner.GetElementData();
           categoryID = data and data.perksVendorCategoryID;
           if categoryID then
                --Enum.PerksVendorCategoryType
                if categoryID == 3 then --pet
                    if data.speciesID then
                        SetupPetTooltip(f, data.speciesID);
                    end
                end
            end
        end
        --]]

        if not owner.purchased then
            --Show "unavailable" for historical items
            local seconds = C_PerksProgram.GetTimeRemaining(owner.perksVendorItemID);
            if seconds and seconds <= 0 then
                f:AddLine(L["Perks Program Item Unavailable"], 0.6, 0.6, 0.6, true);
                f:Show();
            end
        end

        --Show month name for returning items
        local displayMonthName = DataProvider:GetCurrentDisplayMonthName();
        f:AddLine(" ");
        f:AddLine(string.format(L["Perks Program Item Added In Format"], displayMonthName), 1, 0.82, 0, true);
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

local function Initialize()
    if not PerksProgramFrame then return end;

    BlizzardFrame = PerksProgramFrame;

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
        SheatheToggle.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PerksProgram\\SheatheIconYellow");

        local function SheatheToggle_SetIcon(b, sheathed)
            if sheathed then
                b.Icon:SetTexCoord(0, 0.5, 0, 1);
            else
                b.Icon:SetTexCoord(0.5, 1, 0, 1);
            end
        end
    
        SheatheToggle_SetIcon(SheatheToggle, true);

        local function SheatheToggle_OnClick(b)
            local playerActor = BlizzardFrame.ModelSceneContainerFrame.playerActor;
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
            local playerActor = BlizzardFrame.ModelSceneContainerFrame.playerActor;
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
        AnimationButton.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PerksProgram\\AnimationIcon");

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
    EventRegistry:RegisterCallback("PerksProgramModel.OnProductSelectedAfterModel", OnProductSelectedAfterModel, self);
end

function NarciPerksProgramItemDetailExtraFrameMixin:OnEvent(event, ...)
    if event == "PERKS_PROGRAM_OPEN" then
        self:UnregisterEvent(event);
        Initialize();
    elseif event == "PERKS_PROGRAM_CLOSE" then
        SELECTED_DATA = nil;
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:ReleaseButtons()
    if self.buttons then
        for i, button in pairs(self.buttons) do
            button:ClearData();
        end
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:AcquireButton(i)
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
    end
end

local function CalculateInitialOffset(buttonSize, gap, numButtons, maxButtonPerRow)
    local spanX = (buttonSize + gap) * (math.min(numButtons, maxButtonPerRow)) - gap;
    return -0.5*spanX;
end
function NarciPerksProgramItemDetailExtraFrameMixin:DisplayEnsembleSources(sourceIDs)
    self:ReleaseButtons();
    local numItems = (sourceIDs and #sourceIDs) or 0;

    if numItems > 1 then
        local buttonSize = 32;
        local buttonGap = 4;
        local maxButtonPerRow = 8;
        local col, row = 0, 0;

        local buttonUnit = buttonSize + buttonGap;
        local fromOffsetX = CalculateInitialOffset(buttonSize, buttonGap, numItems, maxButtonPerRow);

        local button;

        for i = 1, numItems do
            col = col + 1;
            if col > maxButtonPerRow then
                col = 1;
                row = row + 1;
                fromOffsetX = CalculateInitialOffset(buttonSize, buttonGap, numItems - row*maxButtonPerRow, maxButtonPerRow);
            end
            button = self:AcquireButton(i);
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self.HeaderText, "BOTTOM", fromOffsetX + (col - 1) * buttonUnit, -8 -row*buttonUnit);
            button:SetTransmogSource(sourceIDs[i]);
        end

        self:SetEnsembleHeaderText();
        self:SetHeight(14 + 8 + buttonUnit * (row +1) - buttonGap);
        self:Show();
    else
        self:HideFrame();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:DisplayPetInfo(speciesID)
    self:ReleaseButtons();

    if speciesID then
        local _, _, petType, _, _, _, _, canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
        local petAbilityLevelInfo = petType and C_PetJournal.GetPetAbilityListTable(speciesID);
        if (canBattle) and (not petAbilityLevelInfo) then self:Hide(); return; end;

        local numItems = #petAbilityLevelInfo;

        local buttonSize = 32;
        local buttonGap = 8;
        local verticalGap = 4;
        local maxButtonPerRow = 3;
        local col, row = 0, 0;

        local buttonUnit = buttonSize + buttonGap;
        local fromOffsetX = CalculateInitialOffset(buttonSize, buttonGap, numItems, maxButtonPerRow);

        local button;

        for i = 1, numItems do
            col = col + 1;
            if col > maxButtonPerRow then
                col = 1;
                row = row + 1;
                fromOffsetX = CalculateInitialOffset(buttonSize, buttonGap, numItems - row*maxButtonPerRow, maxButtonPerRow);
            end
            button = self:AcquireButton(i);
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self.HeaderText, "BOTTOM", fromOffsetX + (col - 1) * buttonUnit, -8 -row*(buttonSize + verticalGap));
            button:SetPetAbilityInfo(petAbilityLevelInfo[i]);
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
        self:HideFrame();
    end
end

function NarciPerksProgramItemDetailExtraFrameMixin:SetEnsembleHeaderText(slotName)
    if slotName then
        self.HeaderText:SetText(slotName);
        self.HeaderText:SetTextColor(1, 1, 1);
    else
        self.HeaderText:SetText("Includes:");
        self.HeaderText:SetTextColor(0.5, 0.5, 0.5);
    end
end

--Transmog Item Source
local function TransmogItemButton_OnEnter(self)
    if self.transmogSourceID then
        local itemID = C_TransmogCollection.GetSourceItemID(self.transmogSourceID);
        local slotName;
        if itemID then
            local _, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(itemID);
            slotName = itemEquipLoc and _G[itemEquipLoc];
        end
        ExtraDetailFrame:SetEnsembleHeaderText(slotName);
    end
end

local function TransmogItemButton_OnLeave(self)
    ExtraDetailFrame:SetEnsembleHeaderText();
end

local function TransmogItemButton_OnClick(self)
    local playerActor = BlizzardFrame.ModelSceneContainerFrame.playerActor;
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

function NarciPerksProgramItemDetailButtonMixin:OnClick()
    if self.onClickFunc then
        self.onClickFunc(self);
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
end

function NarciPerksProgramItemDetailButtonMixin:SetPetAbilityInfo(abilityInfo)
    if self.type ~= "pet" then
        self.onEnterFunc = PetAbilityButton_OnEnter;
        self.onLeaveFunc = nil;
        self.onClickFunc = nil;
        self.type = "pet";
    end

    if abilityInfo.abilityID then
        self.petAbilityID = abilityInfo.abilityID;
        local name, icon, typeID = C_PetJournal.GetPetAbilityInfo(abilityInfo.abilityID);
        self.Icon:SetTexture(icon);
        self.petAbilityLevel = abilityInfo.level;
        self:Show();
    end

    self.hideItem = nil;
    self:UpdateVisual();
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
        self.RedEye:Show();
    else
        self.Icon:SetDesaturated(false);
        self.Icon:SetVertexColor(1, 1, 1);
        self.RedEye:Hide();
    end
end

function PerksProgramTryOnItems()
    --local items = {190904, 190905, 190906, 190907};
    local items = {190161, 190163, 190193, 190160, 190158, 190159, 190156, 190162, 190157}
    local actor = BlizzardFrame.ModelSceneContainerFrame.playerActor;
    actor:Undress();
    for _, itemID in pairs(items) do
        actor:TryOn("item:"..itemID);
    end

    local button = GetMouseFocus();
    local name = GetSpellInfo(368307);
    button.ContentsContainer.Label:SetText(name);

    local f = BlizzardFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame.DetailsFrame;
    f.ProductNameText:SetText(name);
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
    135,    --Fly
    548,    --Mount Flight Idle
};

local ANIMATIONS_PLAYER_DEFAULT = {
    0,
    4,  --Walk
    5,  --Run
};

local ANIMATIONS_PLAYER_MELEE_1H = {
    0, 4, 5,
    26,
};

local ANIMATIONS_PLAYER_MELEE_2H = {
    0, 4, 5,
    27, 28,
};

local ANIMATIONS_PLAYER_SHIELD = {
    0, 4, 5,
    26, 1078,
};

local ANIMATIONS_PLAYER_BOW = {
    0, 4, 5,
    29, 109,
};

local ANIMATIONS_PLAYER_CROSSBOW = {
    0, 4, 5,
    836, 842,
};

local ANIMATIONS_PLAYER_GUN = {
    0, 4, 5,
    48, 110,
};

local ANIMATIONS_PLAYER_CASTER = {
    0, 4, 5,
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
        
        if defaultAnimationID then
            for i = 1, #self.animationIDs do
                if self.animationIDs[i] == defaultAnimationID then
                    defaultOption = false;
                    break
                end
            end
        end

        if defaultOption then
            numButtons = numButtons + 1;
        end

        self.numButtons = numButtons;

        local button;

        local maxNumberWidth = 0;
        local maxNameWidth = 0;
        local numberWidth, nameWidth;

        for i = 1, numButtons do
            if not self.buttons[i] then
                self.buttons[i] = CreateFrame("Button", nil, self, "NarciPerksProgramDropDownButtonTemplate");
                self.buttons[i].id = i;
            end
            button = self.buttons[i];
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -paddingV + (1-i)*buttonHeight);

            if defaultOption and i == numButtons then
                if self.defaultAnimationKitID then
                    numberWidth, nameWidth = button:SetAnimationOption("Default", self.defaultAnimationKitID, true);
                else
                    numberWidth, nameWidth = button:SetAnimationOption("Default", defaultAnimationID);
                end
            else
                numberWidth, nameWidth = button:SetAnimationOption(self.getNameFunc(self.animationIDs[i]), self.animationIDs[i]);
            end

            if numberWidth > maxNumberWidth then
                maxNumberWidth = numberWidth;
            end
            if nameWidth > maxNameWidth then
                maxNameWidth = nameWidth;
            end
            button:SetButtonFontColor(1);
        end

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
        self:SetHeight(paddingV*2 + numButtons*buttonHeight);

        if defaultOption then
            self:SelectButton(self.buttons[numButtons]);
        else
            self:SelectButtonByAnimID(defaultAnimationID);
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
    actor:SetAnimationBlendOperation(2);  --LE_MODEL_BLEND_OPERATION_ANIM

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
    self.selectedButtonID = button.id;
    self:HighlightButton();

    if click then
        AnimationDropDown_PlayAnimation(self.actor, button);
    end
end

function NarciPerksProgramAnimationDropDownMixin:SelectButtonByID(id, click)
    if self.buttons then
        for i, b in ipairs(self.buttons) do
            if i == id then
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
    self.selectedButtonID = id;
end

function NarciPerksProgramAnimationDropDownMixin:SelectButtonByAnimID(animID, click)
    if self.buttons then
        for i, b in ipairs(self.buttons) do
            if b.animationID == animID then
                b.isSelected = true;
                b:SetButtonFontColor(3);
                self.selectedButtonID = b.id;
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
    if not self.selectedButtonID then
        self.selectedButtonID = 0;
    end
    if not self.numButtons then
        self.numButtons = 1;
    end
    if delta < 0 then
        self.selectedButtonID = self.selectedButtonID + 1;
        if self.selectedButtonID > self.numButtons then
            self.selectedButtonID = 1;
        end
    else
        self.selectedButtonID = self.selectedButtonID - 1;
        if self.selectedButtonID < 1 then
            self.selectedButtonID = self.numButtons;
        end
    end
    self:SelectButtonByID(self.selectedButtonID, true);
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
end

function NarciPerksProgramDropDownButtonMixin:OnLeave()
    AnimationDropDown:HighlightButton();
    if not self.isSelected then
        self:SetButtonFontColor(1);
    end
end

function NarciPerksProgramDropDownButtonMixin:SetButtonFontColor(colorIndex)
    SetButtonFontColor(self.OptionName, colorIndex);
    SetButtonFontColor(self.OptionNumber, colorIndex);
end

function NarciPerksProgramDropDownButtonMixin:SetAnimationOption(name, id, isAnimKit)
    self.OptionName:SetText(name);
    self.OptionNumber:SetWidth(0);

    local nameWidth = self.OptionName:GetWrappedWidth()
    local numberWidth;

    if id and not isAnimKit then
        self.OptionNumber:SetText(id);
        self.OptionNumber:Show();
        numberWidth = self.OptionNumber:GetWrappedWidth();
    else
        self.OptionNumber:Hide();
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

function NarciPerksProgramDropDownButtonMixin:SetElementSizes(numberWidth, buttonWidth)
    if numberWidth > 0 then
        self.OptionNumber:SetWidth(numberWidth);
    end
    self:SetWidth(buttonWidth);
end

function NarciPerksProgramDropDownButtonMixin:OnClick()
    AnimationDropDown:SelectButton(self, true);
end



--[[
if false then
    local f = CreateFrame("Frame");
    f:RegisterEvent("PERKS_PROGRAM_OPEN");
    f:RegisterEvent("PERKS_PROGRAM_DATA_REFRESH");

    f:SetScript("OnEvent", function(self, event, ...)
        print(event, ...)
        if event == "PERKS_PROGRAM_OPEN" then
            C_Timer.After(0, function()
                PerksProgramFrame:SetPropagateKeyboardInput(true);
                --PerksProgramFrame:SetToplevel(false);
                --PerksProgramFrame:SetFrameStrata("LOW");
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