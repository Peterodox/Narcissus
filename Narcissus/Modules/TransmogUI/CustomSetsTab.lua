-- Modified Tab: Custom Sets
-- Create a outfit pool shared by the same armor type
-- Our outfit string is slightly different than Blizzard's (TransmogUtil.CreateCustomSetSlashCommand)
-- See NarciDB\TransmogDataProvider for details



local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;
local CallbackRegistry = addon.CallbackRegistry;


local OutfitModule = TransmogUIManager:CreateModule("CustomSetsTab");
local CharacterDropdownMixin = {};
local SetsFrame;


local GetCustomSetInfo = C_TransmogCollection.GetCustomSetInfo;
local GetCustomSetItemTransmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList;


local Def = {
    OutfitSource = {
        Default = 0,    --Blizzard, saved on server
        Shared = 1,     --Stored locally
        Alts = 2,       --Access sets on alts, Stored locally, player cannot modify this list on other characters
    },

    MaxSharedSets = 45,     --WoW's maxCustomSets is 25. The UI shows 9 models per page, we'd like remainder of division to be zero

    SetModelWidth = 178,
    SetModelHeight = 218,
    SetModelPaddingX = 27,
    SetModelPaddingY = 19,
};


do  --CharacterDropdown
    function CharacterDropdownMixin:OnClick(button)
        TransmogUIManager:ToggleCustomSetsMenu(self);
    end

    function CharacterDropdownMixin:OnLoad()
        self:SetScript("OnClick", self.OnClick);
        self:SetText(L["OutfitSource Default"]);

        CallbackRegistry:Register("TransmogUI.LoadAltSets", function(characterInfo)
            self:SetText(characterInfo.colorizedName);
        end);

        CallbackRegistry:Register("TransmogUI.LoadDefaultSets", function(characterInfo)
            self:SetText(L["OutfitSource Default"]);
        end);

        CallbackRegistry:Register("TransmogUI.LoadSharedSets", function(characterInfo)
            self:SetText(L["OutfitSource Shared"]);
        end);
    end
end


local ModelLoaderMixin = {};
do
    function ModelLoaderMixin:LoadModels(modelList)
        SetsFrame:SetModelUseNativeForm();
        self:SetScript("OnUpdate", nil);
        self.t = 0;
        self.index = 0;
        self.pendingModel = nil;
        self.modelList = modelList;
        self.toIndex = modelList and #modelList or 0;
        self:LoadNext();
    end

    function ModelLoaderMixin:OnUpdate_LoadNext(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.03 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self.index = self.index + 1;
            if self.index > self.toIndex then
                
            else
                local model = self.modelList[self.index];
                -- For some reason the model loading may fail after UNIT_FORM_CHANGED even IsUnitModelReadyForUI("player") == true
                -- If the model fails to load after 0.1s, we reload it
                self.modelReloadTime = 0.05;
                self.pendingModel = model;
                self:SetScript("OnUpdate", self.OnUpdate_WatchModel);
                model:LoadModel();
            end
        end
    end

    function ModelLoaderMixin:OnUpdate_WatchModel(elapsed)
        self.t = self.t + elapsed;
        if self.t >= self.modelReloadTime then
            self.t = 0;
            self.modelReloadTime = self.modelReloadTime + 0.05;
            if self.pendingModel then
                self.pendingModel:LoadModel();
            end
        end
    end

    function ModelLoaderMixin:LoadNext()
        self.pendingModel = nil;
        if self.index and self.index < self.toIndex then
            self:SetScript("OnUpdate", self.OnUpdate_LoadNext);
        end
    end

    function ModelLoaderMixin:Stop()
        self.index = 0;
        self.toIndex = 0;
        self:SetScript("OnUpdate", nil);
    end
end


local SortFuncs = {};
do
    function SortFuncs.Default(a, b)
        if a.anyUsable ~= b.anyUsable then
            return a.anyUsable
        end

        if a.collected ~= b.collected then
            return a.collected
        end

        return a.name < b.name
    end
end


local SetModelMixin = {};
do
    function SetModelMixin:OnModelLoaded()
        if self:IsShown() then
            self.isModelLoaded = true;
        end

        self:RefreshCameraNew();
        self:RequestLoadSet();

        if self.isModelLoaded then
            SetsFrame.Loader:LoadNext();
        end
    end

    function SetModelMixin:RefreshCameraNew()
        local _, transmogCameraID = C_TransmogSets.GetCameraIDs();
	    self.cameraID = transmogCameraID;
        if self.cameraID then
            Model_ApplyUICamera(self, self.cameraID);
        end
    end

    function SetModelMixin:LoadModel()
        --Notice: equipping some items triggers OnModelLoaded

        self.manualLoading = true;
        self.setEquipped = nil;
        self:SetScript("OnUpdate", nil);

        local blend = false;
        self:SetUnit("player", blend, self.useNativeForm);
        self:SetModelAlpha(0);
    end

    function SetModelMixin:UnloadModel()
        self:ClearModel();
        self.isModelLoaded = false;
        self.setEquipped = false;
    end

    function SetModelMixin:RequestLoadSet()
        if not self.isModelLoaded then
            self:SetScript("OnUpdate", self.OnUpdate_LoadModel)
            return
        end
        self:UpdateSetName();
        self.modelAlpha = 0;
        self.setEquipped = false;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function SetModelMixin:OnUpdate_LoadModel()
        self:SetScript("OnUpdate", nil);
        self:LoadModel();
    end

    function SetModelMixin:GetData()
        local data = self.dataIndex and SetsFrame:GetTransmogData(self.dataIndex);
        return data
    end

    function SetModelMixin:OnUpdate(elapsed)
        if not self.setEquipped then
            self.setEquipped = true;
            local data = self:GetData();
            if data then
                self:Undress();
                for slotID, itemTransmogInfo in ipairs(data.transmogInfoList) do
                    self:SetItemTransmogInfo(itemTransmogInfo, slotID);
                end

                local collected = data.collected and data.anyUsable;
                if collected ~= self.collected then
                    self.collected = collected;
                    local borderAtlas = collected and "transmog-setcard-default" or "transmog-setcard-incomplete";
                    self.Border:SetAtlas(borderAtlas);
                    self.Highlight:SetAtlas(borderAtlas);
                    self.IncompleteOverlay:SetShown(not collected);
                end
            else
                self:UnloadModel();
            end
        end

        if self.manualLoading then
            self.modelAlpha = self.modelAlpha + 5 * elapsed;
            if self.modelAlpha > 1 then
                self.manualLoading = nil;
                self.modelAlpha = 1;
                self:SetScript("OnUpdate", nil);
            end
        else
            self.modelAlpha = 1;
            self:SetScript("OnUpdate", nil);
        end

        self:SetModelAlpha(self.modelAlpha);
    end

    function SetModelMixin:OnMouseDown(button)
        if TransmogUIManager:IsCustomSetsMenuShown() then
            --Block clicks while the menu is shown
            return
        end

        if button == "LeftButton" then
            local data = self:GetData();
            if not data then return end;

            if IsModifiedClick() then
                if IsModifiedClick("CHATLINK") then
                    TransmogUIManager:PostTransmogInChat(data.transmogInfoList);
                    return
                end
            end

            if data.customSetID then
                C_TransmogOutfitInfo.SetOutfitToCustomSet(data.customSetID);
            else
                TransmogUIManager:SetPendingFromTransmogInfoList(data.transmogInfoList);
            end
            PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);

            CallbackRegistry:Trigger("StaticPopup.CloseAll");
        end
    end

    function SetModelMixin:OnMouseUp(button)
        if button == "RightButton" and self:IsMouseMotionFocus() then
            self:ShowContextMenu();
        end
    end

    function SetModelMixin:OnEnter()
        local data = self:GetData();
        if not data then
            GameTooltip:Hide();
            return
        end

        local tooltip = GameTooltip;
        tooltip:SetOwner(self, "ANCHOR_RIGHT");
        tooltip:SetText(data.name, 1, 1, 1, 1, true);

        if not data.collected then
            self:RegisterEvent("MODIFIER_STATE_CHANGED");
            self:SetScript("OnEvent", self.OnEvent);
            local _, missingSlots, allMissing = TransmogUIManager:IsTransmogInfoListCollected(data.transmogInfoList, true);
            local noValidItem = allMissing or not data.anyUsable;
            if noValidItem then
                tooltip:AddLine(L["TransmogSet No Valid Items"], 1, 0.125, 0.125, true);
            else
                TransmogUIManager:Tooltip_AddGreyLine(tooltip, ITEMS_NOT_IN_INVENTORY:format(#missingSlots));
            end

            if (not noValidItem) and NarcissusDB.TransmogUI_ShowMisingItemDetail then
                local slotName;
                for _, slotID in ipairs(missingSlots) do
                    slotName = NarciAPI.GetSlotNameAndTexture(slotID);
                    if slotName then
                        TransmogUIManager:Tooltip_AddGreyLine(tooltip, "- "..slotName);
                    end
                end
            end
        end

        tooltip:Show();
    end

    function SetModelMixin:OnEvent(event, ...)
        if event == "MODIFIER_STATE_CHANGED" then
            if not self:IsMouseMotionFocus() then
                self:UnregisterEvent(event);
                return
            end

            local key, down = ...
            if down == 1 and (key == "LALT" or key =="RALT") then
                NarcissusDB.TransmogUI_ShowMisingItemDetail = not NarcissusDB.TransmogUI_ShowMisingItemDetail;
                self:OnEnter();
            end
        end
    end

    function SetModelMixin:OnLeave()
        GameTooltip:Hide();
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self:SetScript("OnEvent", nil);
    end

    function SetModelMixin:SetBorderState(showPurpleBorder, pending)
        local transmogStateAtlas;

        if showPurpleBorder then
            if pending then
                transmogStateAtlas = "transmog-setcard-transmogrified-pending";
            else
                transmogStateAtlas = "transmog-setcard-transmogrified";
            end
        end

        if transmogStateAtlas then
            self.TransmogStateTexture:SetAtlas(transmogStateAtlas, TextureKitConstants.IgnoreAtlasSize);
            self.TransmogStateTexture:Show();

            if pending then
                self.PendingFrame:Show();
                self.PendingFrame.Anim:Restart();
            else
                self.PendingFrame.Anim:Stop();
                self.PendingFrame:Hide();
            end
        else
            self.TransmogStateTexture:Hide();

            self.PendingFrame.Anim:Stop();
            self.PendingFrame:Hide();
        end
    end

    function SetModelMixin:UpdateSetName()
        local data = self:GetData();
        if data then
            self.Title:SetText(data.name);
            --Similar to border color
            if data.collected then
                self.Title:SetTextColor(0.827, 0.776, 0.620); --1, 0.82, 0
            else
                self.Title:SetTextColor(0.612, 0.627, 0.690);  --0.773, 0.788, 0.855
            end
        else
            self.Title:SetText(nil);
        end
    end

    function SetModelMixin:ShowContextMenu()
        --See TransmogCustomSetModelMixin:OnMouseUp (Interface/AddOns/Blizzard_Transmog/Blizzard_TransmogTemplates.lua)
        --Removed: View in Dressing Room (why)
        --Added: Copy this outfit to shared pool

        local data = self:GetData();
        if not data then return end;

        local customSetID = data.customSetID;

        local Schematic = {
            tag = "NARCISSUS_TRANSMOG_CUSTOM_SETS_MENU",
            objects = {
                {type = "Button", name = TRANSMOG_CUSTOM_SET_RENAME},
                {type = "Divider"},
                {type = "Button", name = TRANSMOG_CUSTOM_SET_REPLACE},
                {type = "Divider"},
                {type = "Button", name = TRANSMOG_CUSTOM_SET_DELETE},
                {type = "Divider"},
                {type = "Spacer"},
            },
        };

        local tinsert = table.insert;

        if customSetID then --Default, Blizzard
            local itemTransmogInfoList = TransmogFrame.WardrobeCollection:GetItemTransmogInfoListCallback();
            local name, _icon = C_TransmogCollection.GetCustomSetInfo(customSetID);

            --Rename
            Schematic.objects[1].OnClick = function()
                local _data = { name = name, customSetID = customSetID, itemTransmogInfoList = itemTransmogInfoList };
                StaticPopup_Show("TRANSMOG_CUSTOM_SET_NAME", nil, nil, _data);
            end

            --Overwrite, Replace with current set
            local hasValidAppearance = TransmogUtil.IsValidItemTransmogInfoList(itemTransmogInfoList);
            if hasValidAppearance then
                Schematic.objects[3].OnClick = function()
                    C_TransmogCollection.ModifyCustomSet(customSetID, itemTransmogInfoList);
                end
            else
                Schematic.objects[3].enabled = false;
            end

            --Delete
            Schematic.objects[5].name = RED_FONT_COLOR:WrapTextInColorCode(TRANSMOG_CUSTOM_SET_DELETE);
            Schematic.objects[5].OnClick = function()
                StaticPopup_Show("CONFIRM_DELETE_TRANSMOG_CUSTOM_SET", name, nil, customSetID);
            end

        elseif OutfitModule:IsOutfitSource("Shared") then
            --Rename
            Schematic.objects[1].OnClick = function()
                local _data = { name = data.name, dataIndex = data.dataIndex };
                StaticPopup_Show("NARCISSUS_TRANSMOG_CUSTOM_SET_NAME", nil, nil, _data);
            end

            --Overwrite
            local itemTransmogInfoList = TransmogFrame.WardrobeCollection:GetItemTransmogInfoListCallback();
            local hasValidAppearance = TransmogUtil.IsValidItemTransmogInfoList(itemTransmogInfoList);
            if hasValidAppearance then
                Schematic.objects[3].OnClick = function()
                    TransmogUIManager:TryOverwriteSharedSet(data.dataIndex, itemTransmogInfoList);
                end
            else
                Schematic.objects[3].enabled = false;
                Schematic.objects[3].tooltip = RED_FONT_COLOR:WrapTextInColorCode(L["TransmogSet No Valid Items"]);
            end

            --Delete
            Schematic.objects[5].name = RED_FONT_COLOR:WrapTextInColorCode(TRANSMOG_CUSTOM_SET_DELETE);
            Schematic.objects[5].tooltip = L["Insturction Delete Without Confirm"];
            Schematic.objects[5].OnClick = function()
                if IsShiftKeyDown() then
                    TransmogUIManager:DeleteSharedSet(data.dataIndex);
                else
                    local _data = { name = data.name, dataIndex = data.dataIndex};
                    StaticPopup_Show("NARCISSUS_TRANSMOG_CUSTOM_SET_DELETE", nil, nil, _data);
                end
            end

        else --Alts
            local disabldTooltip = L["Cannot Delete On Alts"];
            Schematic.objects[1].tooltip = disabldTooltip;
            Schematic.objects[3].tooltip = disabldTooltip;
            Schematic.objects[5].tooltip = disabldTooltip;
            Schematic.objects[1].enabled = false;
            Schematic.objects[3].enabled = false;
            Schematic.objects[5].enabled = false;
        end

        tinsert(Schematic.objects, {
            type = "Button",
            name = TRANSMOG_OUTFIT_POST_IN_CHAT,
            OnClick = function()
                TransmogUIManager:PostTransmogInChat(data.transmogInfoList);
            end,
        });

        tinsert(Schematic.objects, {
            type = "Button",
            name = TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD,
            OnClick = function()
                TransmogUIManager:ShowTransmogClipboard(data.transmogInfoList);
            end,
        });

        if not OutfitModule:IsOutfitSource("Shared") then
            tinsert(Schematic.objects, {type = "Divider"});

            local buttonData = {
                type = "Button",
                name = L["Copy To Shared List"],
                OnClick = function()
                    if TransmogUIManager:TrySaveSharedSet(data.name, data.transmogInfoList) then
                        data.foundSetName = data.name;
                    end
                end,
            };

            if data.foundSetName == nil then
                local foundSetName = TransmogUIManager:IsCustomSetShared(data.transmogInfoList);
                if foundSetName then
                    data.foundSetName = foundSetName;
                else
                    data.foundSetName = false;
                end
            end
            if data.foundSetName then
                buttonData.enabled = false;
                local icon = "Interface/AddOns/Narcissus/Art/BasicShapes/CheckmarkGrey";
                buttonData.name = string.format("|T%s:14:14|t%s", icon, L["Added To Shared List"]);
                buttonData.tooltip = string.format(L["Added To Shared List Alert Format"], data.foundSetName);
            end

            if not TransmogUIManager:CanSaveMoreSharedSet() then
                buttonData.enabled = false;
            end

            tinsert(Schematic.objects, buttonData);
        end

        NarciAPI.TranslateContextMenu(self, Schematic);
    end
end


local CreateSaveButton;
do
    local SaveButtonMixin = {};

    function SaveButtonMixin:OnMouseDown()
        self.mouseDown = true;
        self:UpdateVisual();
    end

    function SaveButtonMixin:OnMouseUp()
        self.mouseDown = false;
        self:UpdateVisual();
    end

    function SaveButtonMixin:OnEnable()
        self:UpdateVisual();
    end

    function SaveButtonMixin:OnDisable()
        self:UpdateVisual();
    end

    function SaveButtonMixin:OnEnter()
        self.Count:Show();
        self:UpdateVisual();
        self:UpdateCount();
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true);
            GameTooltip:Show();
        end
    end

    function SaveButtonMixin:OnLeave()
        GameTooltip:Hide();
        self.Count:Hide();
        self:UpdateVisual();
    end

    function SaveButtonMixin:UpdateCount()
        local currentVal, maxVal;
        if OutfitModule:IsOutfitSource("Shared") then
            currentVal = TransmogUIManager:GetNumSharedSets();
            maxVal = TransmogUIManager:GetNumMaxSharedSets();
        else
            currentVal, maxVal = TransmogUIManager:GetDefaultCustomSetsCount();
        end
        self.Count:SetText(currentVal.."/"..maxVal);
    end

    function SaveButtonMixin:UpdateVisual()
        if self:IsEnabled() then
            if self.mouseDown then
                self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
            else
                self.Icon:SetTexCoord(0, 0.25, 0, 1);
            end
            if self:IsMouseMotionFocus() then
                self.Label:SetTextColor(1, 1, 1);
            else
                self.Label:SetTextColor(1, 0.82, 0);
            end
        else
            self.Icon:SetTexCoord(0.5, 0.75, 0, 1);
            self.Label:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    function SaveButtonMixin:RequestUpdate()
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function SaveButtonMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.03 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:UpdateSaveStatus();
        end
    end

    function SaveButtonMixin:OnClick(button)
        local itemTransmogInfoList = TransmogFrame.WardrobeCollection:GetItemTransmogInfoListCallback();
        local hasValidAppearance = TransmogUtil.IsValidItemTransmogInfoList(itemTransmogInfoList);

        if hasValidAppearance then
            TransmogUIManager:ShowPopup_NewSet(OutfitModule:IsOutfitSource("Shared"), itemTransmogInfoList);
        end
    end

    function SaveButtonMixin:UpdateSaveStatus()
        self.tooltipText = nil;

        local itemTransmogInfoList = TransmogFrame.WardrobeCollection:GetItemTransmogInfoListCallback();
        local hasValidAppearance = TransmogUtil.IsValidItemTransmogInfoList(itemTransmogInfoList);

        if hasValidAppearance then
            self:Enable();
        else
            self:Disable();
            self.tooltipText = TRANSMOG_CUSTOM_SET_NEW_TOOLTIP_DISABLED;
        end
    end


    function CreateSaveButton(parent)
        local f = CreateFrame("Button", nil, parent);
        local texture = "Interface/AddOns/Narcissus/Art/Modules/DressingRoom/SaveButton.png";

        f.Icon = f:CreateTexture(nil, "ARTWORK");
        f.Icon:SetPoint("LEFT", f, "LEFT", 0, 0);
        f.Icon:SetSize(32, 32);
        f.Icon:SetTexture(texture);

        f.Highlight = f:CreateTexture(nil, "HIGHLIGHT");
        f.Highlight:SetPoint("CENTER", f.Icon, "CENTER", 0, 0);
        f.Highlight:SetSize(32, 32);
        f.Highlight:SetTexture(texture);
        f.Highlight:SetTexCoord(0.75, 1, 0, 1);
        f.Highlight:SetBlendMode("ADD");

        f.labelOffsetX = 38;
        f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        f.Label:SetPoint("LEFT", f, "LEFT", f.labelOffsetX, 0);
        f.Label:SetJustifyH("LEFT");
        f.Label:SetText(TRANSMOG_CUSTOM_SET_NEW);

        f.Count = f:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        f.Count:SetPoint("LEFT", f.Label, "RIGHT", 6, 0);
        f.Count:SetJustifyH("LEFT");
        f.Count:SetTextColor(0.5, 0.5, 0.5);
        f.Count:Hide();

        Mixin(f, SaveButtonMixin);

        f:SetScript("OnMouseDown", f.OnMouseDown);
        f:SetScript("OnMouseUp", f.OnMouseUp);
        f:SetScript("OnEnable", f.OnEnable);
        f:SetScript("OnDisable", f.OnDisable);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);

        f:SetSize(192, 32);
        f:SetMotionScriptsWhileDisabled(true);
        f:UpdateVisual();

        return f
    end
end


local SetsFrameMixin = {};
do
    local DynamicEvents = {
	    "TRANSMOG_CUSTOM_SETS_CHANGED",
		"UI_SCALE_CHANGED",
		"DISPLAY_SIZE_CHANGED",
		"VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS",
		"VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH",
    };

    function SetsFrameMixin:OnLoad()
        self.Models = {};
        self.page = 1;
        self.modelsPerPage = 9;
        self.dataList = {};


        local Loader = CreateFrame("Frame", nil, self);
        self.Loader = Loader;
        Mixin(Loader, ModelLoaderMixin);


        --Paging Buttons
        local PagingControls = CreateFrame("Frame", nil, self);    --"PagingControlsHorizontalTemplate" PageText, PrevPageButton, NextPageButton
        PagingControls:SetSize(100, 32);
        PagingControls:SetPoint("BOTTOM", self, "BOTTOM", 15, 3);

        local NextPageButton = CreateFrame("Button", nil, PagingControls, "PagingControlsNextPageButtonTemplate");
        NextPageButton:SetPoint("RIGHT", PagingControls, "RIGHT", 0, 0);
        OutfitModule:AddNewObject(NextPageButton);
        NextPageButton:SetScript("OnClick", function()
            self:OnMouseWheel(-1);
        end);

        local PrevPageButton = CreateFrame("Button", nil, PagingControls, "PagingControlsPrevPageButtonTemplate");
        PrevPageButton:SetPoint("RIGHT", NextPageButton, "LEFT", -5, 0);
        OutfitModule:AddNewObject(NextPageButton);
        PrevPageButton:SetScript("OnClick", function()
            self:OnMouseWheel(1);
        end);

        local PageText = PagingControls:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        PageText:SetSize(0, 32);
        PageText:SetJustifyH("RIGHT");
        PageText:SetPoint("RIGHT", PrevPageButton, "LEFT", -6, 0);

        self.PageText = PageText;
        self.NextPageButton = NextPageButton;
        self.PrevPageButton = PrevPageButton;


        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);
    end

    function SetsFrameMixin:OnShow()
        FrameUtil.RegisterFrameForEvents(self, DynamicEvents);
        local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
        if hasAlternateForm then
            self:RegisterUnitEvent("UNIT_FORM_CHANGED", "player");
        end
        self:SetScript("OnEvent", self.OnEvent);

        if not OutfitModule.outfitSource then
            CallbackRegistry:Trigger("TransmogUI.LoadDefaultSets");
        else
            self:UpdatePage(true);
        end

        self.SaveButton:RequestUpdate();
    end

    function SetsFrameMixin:ClearAllModels()
        self.Loader:Stop();
        for _, model in ipairs(self.Models) do
            model:UnloadModel();
        end
    end

    function SetsFrameMixin:OnHide()
        self:ClearAllModels();
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:SetScript("OnEvent", nil);
        self:UnregisterAllEvents();
    end

    local function CreateTransmogData(name, transmogInfoList, customSetID)
        return {
            customSetID = customSetID,
            name = name,
            transmogInfoList = transmogInfoList,
            collected = TransmogUIManager:IsTransmogInfoListCollected(transmogInfoList),
            anyUsable = TransmogUIManager:IsTransmogInfoListUsable(transmogInfoList),
        };
    end

    function SetsFrameMixin:LoadDefaultSets()
        self:SetScript("OnMouseWheel", nil);
        self:ClearAllModels();

        local customSets = C_TransmogCollection.GetCustomSets() or {};
        local dataList = {};
        local n = 0;
        local name;
        local recentlySavedName = TransmogUIManager.recentlySavedCustomSetFlag;

        for i, customSetID in ipairs(customSets) do
            name = GetCustomSetInfo(customSetID);
            local transmogInfoList = GetCustomSetItemTransmogInfoList(customSetID);
            n = n + 1;
            dataList[n] = CreateTransmogData(name, transmogInfoList, customSetID);
        end

        table.sort(dataList, SortFuncs.Default);

        if recentlySavedName then
            for i, v in ipairs(dataList) do
                if recentlySavedName == v.name then
                    self.page = math.ceil(i/self.modelsPerPage);
                    break
                end
            end
        end

        OutfitModule:SetOutfitSource("Default");
        self:SetDataList(dataList);
    end
    CallbackRegistry:Register("TransmogUI.LoadDefaultSets", function(retainPage)
        TransmogUIManager.selectedCharacterUID = nil;
        if not retainPage then
            SetsFrame.page = 1;
        end
        SetsFrame:LoadDefaultSets();
    end);

    function SetsFrameMixin:LoadSharedSets()
        self:SetScript("OnMouseWheel", nil);
        self:ClearAllModels();

        local dataList = TransmogUIManager:GetSharedSetsDataList();
        OutfitModule:SetOutfitSource("Shared");

        local recentlySavedTimestamp = TransmogUIManager.recentlySavedSharedSetFlag;
        self.page = 1;
        if recentlySavedTimestamp then
            for i, v in ipairs(dataList) do
                if v.timeCreated == recentlySavedTimestamp then
                    self.page = math.ceil(i/self.modelsPerPage);
                    break
                end
            end
        end

        self:SetDataList(dataList);
    end
    CallbackRegistry:Register("TransmogUI.LoadSharedSets", function(retainPage)
        TransmogUIManager.selectedCharacterUID = nil;
        if not retainPage then
            SetsFrame.page = 1;
        end
        SetsFrame:LoadSharedSets();
    end);

    function SetsFrameMixin:LoadAltSets(characterInfo)
        self:SetScript("OnMouseWheel", nil);
        self:ClearAllModels();

        local dataList = {};

        if characterInfo and characterInfo.sets then
            for i, setInfo in ipairs(characterInfo.sets) do
                dataList[i] = CreateTransmogData(setInfo.name, setInfo.transmogInfoList);
            end
        end

        table.sort(dataList, SortFuncs.Default);
        OutfitModule:SetOutfitSource("Alts");
        self.page = 1;
        self:SetDataList(dataList);
    end
    CallbackRegistry:Register("TransmogUI.LoadAltSets", function(characterInfo)
        TransmogUIManager.selectedCharacterUID = characterInfo.uid;
        SetsFrame:LoadAltSets(characterInfo)
    end);

    function TransmogUIManager:GetSelectedCharacterUID()
        return self.selectedCharacterUID
    end

    function SetsFrameMixin:SetDataList(dataList)
        self.dataList = dataList;
        self.maxPage = math.ceil(#dataList/self.modelsPerPage);

        if (not self.page) or (self.page < 1) then
            self.page = 1;
        elseif self.page > self.maxPage then
            self.page = self.maxPage;
        end

        self:UpdatePage(true);
        self:SetScript("OnMouseWheel", self.OnMouseWheel);

        self.SaveButton:RequestUpdate();
        self.SaveButton:UpdateCount();
        CallbackRegistry:Trigger("StaticPopup.CloseAll");
    end

    function SetsFrameMixin:GetTransmogData(dataIndex)
        return self.dataList and self.dataList[dataIndex]
    end

    function SetsFrameMixin:ReloadPage()
        --Update Sets Data
        local retainPage = true;
        if OutfitModule:IsOutfitSource("Default") then
            CallbackRegistry:Trigger("TransmogUI.LoadDefaultSets", retainPage);
        elseif OutfitModule:IsOutfitSource("Shared") then
            CallbackRegistry:Trigger("TransmogUI.LoadSharedSets", retainPage);
        end
    end

    CallbackRegistry:Register("TransmogUI.ReloadSharedSets", function()
        if SetsFrame and SetsFrame:IsVisible() then
            if OutfitModule:IsOutfitSource("Shared") then
                CallbackRegistry:Trigger("TransmogUI.LoadSharedSets", true);
            end
        end
    end);

    function SetsFrameMixin:UpdatePage(fullUpdate)
        local fromIndex = (self.page - 1) * self.modelsPerPage;
        local dataIndex;
        local model;

        if fullUpdate then
            local modelList = {};

            self.Loader:Stop();

            for i = 1, self.modelsPerPage do
                dataIndex = fromIndex + i;
                model = self.Models[i];
                if self.dataList[dataIndex] then
                    if not model then
                        model = CreateFrame("DressUpModel", nil, self, "TransmogSetBaseModelTemplate");
                        self.Models[i] = model;
                        model.index = i;
                        model:Hide();
                        model:SetScript("OnShow", nil);
                        model:SetScript("OnHide", nil);
                        model:SetScript("OnEvent", nil);
                        model:SetScript("OnUpdate", nil);
                        model:SetKeepModelOnHide(true);
                        model:UnregisterAllEvents();

                        Mixin(model, SetModelMixin);
                        model:SetScript("OnModelLoaded", SetModelMixin.OnModelLoaded);
                        model:SetScript("OnMouseDown", SetModelMixin.OnMouseDown);
                        model:SetScript("OnMouseUp", SetModelMixin.OnMouseUp);
                        model:SetScript("OnEnter", SetModelMixin.OnEnter);
                        model:SetScript("OnLeave", SetModelMixin.OnLeave);

                        local col = (i - 1) % 3;
                        local row = math.ceil(i / 3) - 1;
                        model:SetPoint("TOPLEFT", self, "TOPLEFT", col * (Def.SetModelWidth + Def.SetModelPaddingX), -row * (Def.SetModelHeight + Def.SetModelPaddingY));

                        local padding = 8;
                        model.Title = model:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
                        model.Title:SetPoint("TOPLEFT", model, "TOPLEFT", padding, -padding);
                        model.Title:SetPoint("TOPRIGHT", model, "TOPRIGHT", -padding, -padding);
                        model.Title:SetJustifyH("CENTER");
                        model.Title:SetSpacing(2);
                    end
                    model.dataIndex = dataIndex;
                    model:Show();
                    modelList[i] = model;
                else
                    if model then
                        model:Hide();
                    end
                end
            end

            self.Loader:LoadModels(modelList);
        else
            for i = 1, self.modelsPerPage do
                dataIndex = fromIndex + i;
                model = self.Models[i];
                if self.dataList[dataIndex] then
                    if model then
                        model.dataIndex = dataIndex;
                        model:RequestLoadSet();
                        model:Show();
                    end
                else
                    if model then
                        model:Hide();
                    end
                end
            end
        end

        self:TriggerModelsOnEnter();

        self.PageText:SetText(string.format(PAGE_NUMBER_WITH_MAX, self.page, self.maxPage));
        self.PrevPageButton:SetEnabled(self.page > 1);
        self.NextPageButton:SetEnabled(self.page < self.maxPage);

        self:UpdateSelection();
    end

    function SetsFrameMixin:TriggerModelsOnEnter()
        for _, model in ipairs(self.Models) do
            if model:IsMouseMotionFocus() then
                model:OnEnter();
                break
            end
        end
    end
    CallbackRegistry:Register("TransmogUI.SharedSetRenamed", function()
        for _, model in ipairs(SetsFrame.Models) do
            model:UpdateSetName();
        end
        SetsFrame:TriggerModelsOnEnter();
    end);

    function SetsFrameMixin:UpdateSelection()
        local currentItemTransmogInfoList = TransmogFrame.CharacterPreview:GetItemTransmogInfoList();
        local foundModel;

        if currentItemTransmogInfoList then
            for _, model in ipairs(self.Models) do
                model:SetBorderState(false);
                if model:IsShown() and not foundModel then
                    local data = model:GetData();
                    if data and TransmogUIManager:IsCustomSetDressed(currentItemTransmogInfoList, data.transmogInfoList) then
                        foundModel = model;
                    end
                end
            end
        end

        if foundModel then
            foundModel:SetBorderState(true);
        end
    end

    function SetsFrameMixin:OnMouseWheel(delta)
        if delta < 0 and self.page < self.maxPage then
            self.page = self.page + 1;
        elseif delta > 0 and self.page > 1 then
            self.page = self.page - 1;
        else
            return
        end
        self:UpdatePage();
    end

    function SetsFrameMixin:RequestUpdate(flag)
        if not flag then return end;

        if not self.dirtyFlags then
            self.dirtyFlags = {};
        end
        self.dirtyFlags[flag] = true;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function SetsFrameMixin:OnEvent(event, ...)
        if event == "TRANSMOG_CUSTOM_SETS_CHANGED" then
            self:RequestUpdate("All");
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            self:RequestUpdate("Camera");
        elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH" then
            self:RequestUpdate("Selection");
            self.SaveButton:RequestUpdate();
        elseif event == "UNIT_FORM_CHANGED" then
            self:RequestUpdate("Form");
        end
    end

    function SetsFrameMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.05 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);

            if self.dirtyFlags then
                if self.dirtyFlags.All then
                    self.dirtyFlags = nil;
                    self:ReloadPage();
                    return
                end

                if self.dirtyFlags.Camera then
                    self.dirtyFlags.Camera = nil;
                    for _, model in ipairs(self.Models) do
                        if model:IsShown() then
                            model:RefreshCameraNew();
                        end
                    end
                end

                if self.dirtyFlags.Selection then
                    self.dirtyFlags.Selection = nil;
                    self:UpdateSelection();
                end

                if self.dirtyFlags.Form then
                    self.dirtyFlags.Form = nil;
                    if self.dataList then
                        self:ClearAllModels();
                        self:SetDataList(self.dataList);
                    end
                end
            end
        end
    end

    function SetsFrameMixin:SetModelUseNativeForm()
        self.useNativeForm = PlayerUtil.ShouldUseNativeFormInModelScene();
        for _, model in ipairs(self.Models) do
            model.useNativeForm = self.useNativeForm;
        end
    end
end


function OutfitModule:ModifyStockUI()
    --Default TransmogSetBaseModelTemplate has a few performance issues:
    --  All models start loading simultaneously, FPS when changeing pages
    --  Every frame registers the same DYNAMIC_EVENTS


    self.ParentTab.PagedContent:RemoveDataProvider();

    local nop = function()
    end;

    self.ParentTab.RefreshCollectionEntries = nop;

    self.ParentTab:SetScript("OnShow", nil);
    self.ParentTab:SetScript("OnHide", nil);
    self.ParentTab:SetScript("OnEvent", nil);
    self.ParentTab:UnregisterAllEvents();
    self.ParentTab.PagedContent:Hide();
    self.ParentTab.NewCustomSetButton:Hide();
end

function OutfitModule:SetOutfitSource(key)
    self.outfitSource = Def.OutfitSource[key]
end

function OutfitModule:IsOutfitSource(key)
    return OutfitModule.outfitSource == Def.OutfitSource[key]
end
TransmogUIManager.IsOutfitSource = OutfitModule.IsOutfitSource;

function OutfitModule:OnLoad()
    local ParentTab = TransmogFrame.WardrobeCollection.TabContent.CustomSetsFrame;
    self.ParentTab = ParentTab;

    local Container = CreateFrame("Frame", nil, ParentTab);
    self.Container = Container;
    Container:SetAllPoints(true);


    local CharacterDropdown = CreateFrame("DropdownButton", nil, ParentTab, "WowStyle1DropdownTemplate");
    self.CharacterDropdown = CharacterDropdown;
    CharacterDropdown.HandlesGlobalMouseEvent = nil;
    self:AddNewObject(CharacterDropdown);

    CharacterDropdown:SetPoint("TOPRIGHT", ParentTab, "TOPRIGHT", -26, -24);
    CharacterDropdown:SetWidth(186);
    Mixin(CharacterDropdown, CharacterDropdownMixin);
    CharacterDropdown:OnLoad();

    self:ModifyStockUI();


    SetsFrame = CreateFrame("Frame", nil, Container);

    --For sizes, see CustomSetsFrame.PagedContent (Interface/AddOns/Blizzard_Transmog/Blizzard_Transmog.xml)
    SetsFrame:SetPoint("TOPLEFT", Container, "TOPLEFT", 26, -72);
    SetsFrame:SetPoint("BOTTOMRIGHT", Container, "BOTTOMRIGHT", -26, 10);

    SetsFrame.SaveButton = CreateSaveButton(SetsFrame);
    SetsFrame.SaveButton:SetPoint("TOPLEFT", ParentTab, "TOPLEFT", 23, -24);

    Mixin(SetsFrame, SetsFrameMixin);
    SetsFrame:OnLoad();
end




--[[
/dump C_TransmogOutfitInfo.GetOutfitInfo(2);    /dump C_TransmogOutfitInfo.GetOutfitSituation
--]]
