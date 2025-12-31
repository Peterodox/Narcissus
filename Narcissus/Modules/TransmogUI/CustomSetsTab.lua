-- Modified Tab: Custom Sets
-- Create a outfit pool shared by the same armor type
-- Our outfit string is slightly different than Blizzard's (TransmogUtil.CreateCustomSetSlashCommand)
-- See NarciDB\TransmogDataProvider for details



local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;
local TransmogDataProvider = addon.TransmogDataProvider;


local OutfitModule = TransmogUIManager:CreateModule("CustomSetsTab");
local CharacterDropdownMixin = {};


local GetCustomSetInfo = C_TransmogCollection.GetCustomSetInfo;
local GetCustomSetItemTransmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList;
--C_TransmogCollection.GetNumMaxCustomSets


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
    end
end


local ModelLoaderMixin = {};
do
    function ModelLoaderMixin:LoadModels(modelList)
        self:SetScript("OnUpdate", nil);
        self.useNativeForm = PlayerUtil.ShouldUseNativeFormInModelScene();
        self.t = 0;
        self.index = 0;
        self.modelList = modelList;
        self.toIndex = modelList and #modelList or 0;
        self:LoadNext();
    end

    function ModelLoaderMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.03 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self.index = self.index + 1;
            if self.index > self.toIndex then
                
            else
                local model = self.modelList[self.index];
                model.useNativeForm = self.useNativeForm;
                model:LoadModel();
            end
        end
    end

    function ModelLoaderMixin:LoadNext()
        if self.index and self.index < self.toIndex then
            self:SetScript("OnUpdate", self.OnUpdate);
        end
    end

    function ModelLoaderMixin:Stop()
        self.index = 0;
        self.toIndex = 0;
        self:SetScript("OnUpdate", nil);
    end
end


local SortFunc = {};
do
    function SortFunc.Default(a, b)
        if a.collected ~= b.collected then
            return a.collected;
        end

        return a.name < b.name;
    end
end


local SetModelMixin = {};
do
    function SetModelMixin:OnModelLoaded()
        self:RefreshCameraNew();
        self:RequestLoadSet();

        OutfitModule.SetsFrame.Loader:LoadNext();
    end

    function SetModelMixin:RefreshCameraNew()
        local _, transmogCameraID = C_TransmogSets.GetCameraIDs();
	    self.cameraID = transmogCameraID;
        if self.cameraID then
            Model_ApplyUICamera(self, self.cameraID);
        end
    end

    function SetModelMixin:LoadModel()
        --Notice: equipping sets triggers OnModelLoaded
        self.manualLoading = true;
        self.setEquipped = nil;
        self:SetScript("OnUpdate", nil);

        local blend = false;
        self:SetUnit("player", blend, self.useNativeForm);
        self:SetModelAlpha(0);
    end

    function SetModelMixin:RequestLoadSet()
        self.modelAlpha = 0;
        self.setEquipped = false;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function SetModelMixin:GetData()
        local data = self.dataIndex and OutfitModule.SetsFrame:GetTransmogData(self.dataIndex);
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

                local collected = data.collected;
                if collected ~= self.collected then
                    self.collected = collected;
                    local borderAtlas = collected and "transmog-setcard-default" or "transmog-setcard-incomplete";
                    self.Border:SetAtlas(borderAtlas);
                    self.Highlight:SetAtlas(borderAtlas);
                    self.IncompleteOverlay:SetShown(not collected);
                end
            else
                self:ClearModel();
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
        if button == "LeftButton" then
            local data = self:GetData();
            if not data then return end;

            if IsModifiedClick() then
                if IsModifiedClick("CHATLINK") then
                    TransmogUIManager:PostTransmogInChat(data.transmogInfoList)
                    return
                end
            end

            if data.customSetID then
                C_TransmogOutfitInfo.SetOutfitToCustomSet(data.customSetID);
            else
                TransmogUIManager:SetPendingFromTransmogInfoList(data.transmogInfoList);
            end
            PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);
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
        tooltip:SetText(data.name, 1, 0.82, 0, 1, true);

        if not data.collected then
            self:RegisterEvent("MODIFIER_STATE_CHANGED");
            self:SetScript("OnEvent", self.OnEvent);
            local _, missingSlots = TransmogUIManager:IsTransmogInfoListCollected(data.transmogInfoList, true);
            TransmogUIManager:Tooltip_AddColoredLine(tooltip, ITEMS_NOT_IN_INVENTORY:format(#missingSlots));
            if NarcissusDB.TransmogUI_ShowMisingItemDetail then
                local slotName;
                for _, slotID in ipairs(missingSlots) do
                    slotName = NarciAPI.GetSlotNameAndTexture(slotID);
                    if slotName then
                        TransmogUIManager:Tooltip_AddColoredLine(tooltip, "- "..slotName);
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

    function SetModelMixin:ShowContextMenu()
        --See TransmogCustomSetModelMixin:OnMouseUp (Interface/AddOns/Blizzard_Transmog/Blizzard_TransmogTemplates.lua)
        --Removed: View in Dressing Room (why)
        --Added: Copy this outfit to shared pool

        local data = self:GetData();
        if not data then return end;

        local customSetID = data.customSetID;
        local Schematic = {
            tag = "NARCISSUS_TRANSMOG_CUSTOM_SETS_MENU",
            objects = {},
        };

        if customSetID then
            local itemTransmogInfoList = TransmogFrame.WardrobeCollection:GetItemTransmogInfoListCallback();
            local name, _icon = C_TransmogCollection.GetCustomSetInfo(customSetID);

            --Rename
            table.insert(Schematic.objects, {
                type = "Button",
                name = TRANSMOG_CUSTOM_SET_RENAME,
                OnClick = function()
                    local data = { name = name, customSetID = customSetID, itemTransmogInfoList = itemTransmogInfoList };
                    StaticPopup_Show("TRANSMOG_CUSTOM_SET_NAME", nil, nil, data);
                end,
            });

            --Overwrite, Replace with current set
            local hasValidAppearance = TransmogUtil.IsValidItemTransmogInfoList(itemTransmogInfoList);
            if hasValidAppearance then
                table.insert(Schematic.objects, {type = "Divider"});

                table.insert(Schematic.objects, {
                    type = "Button",
                    name = TRANSMOG_CUSTOM_SET_REPLACE,
                    OnClick = function()
                        C_TransmogCollection.ModifyCustomSet(customSetID, itemTransmogInfoList);
                    end,
                });
            end

            table.insert(Schematic.objects, {type = "Divider"});

            --Delete
            table.insert(Schematic.objects, {
                type = "Button",
                name = RED_FONT_COLOR:WrapTextInColorCode(TRANSMOG_CUSTOM_SET_DELETE),
                OnClick = function()
                    StaticPopup_Show("CONFIRM_DELETE_TRANSMOG_CUSTOM_SET", name, nil, customSetID);
                end,
            });
        else
            if OutfitModule:GetOutfitSource() == Def.OutfitSource.Shared then
                --Rename
                table.insert(Schematic.objects, {
                    type = "Button",
                    name = TRANSMOG_CUSTOM_SET_RENAME,
                    OnClick = function()
                        --TryRename
                    end,
                });
            else
                --Rename
                table.insert(Schematic.objects, {
                    type = "Button",
                    name = TRANSMOG_CUSTOM_SET_RENAME,
                    enabled = false,
                    tooltip = RED_FONT_COLOR:WrapTextInColorCode(L["Cannot Delete On Alts"]),
                });

                table.insert(Schematic.objects, {type = "Divider"});

                --Delete
                table.insert(Schematic.objects, {
                    type = "Button",
                    name = TRANSMOG_CUSTOM_SET_DELETE,
                    enabled = false,
                    tooltip = RED_FONT_COLOR:WrapTextInColorCode(L["Cannot Delete On Alts"]),
                });
            end
        end

        NarciAPI.TranslateContextMenu(self, Schematic);
    end
end


local Shared
do
    
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

        local PrevPageButton = CreateFrame("Button", nil, PagingControls, "PagingControlsPrevPageButtonTemplate");
        PrevPageButton:SetPoint("RIGHT", NextPageButton, "LEFT", -5, 0);
        OutfitModule:AddNewObject(NextPageButton);

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
        self:LoadDefaultSets();
        FrameUtil.RegisterFrameForEvents(self, DynamicEvents);
        local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
        if hasAlternateForm then
            self:RegisterUnitEvent("UNIT_FORM_CHANGED", "player");
        end
        self:SetScript("OnEvent", self.OnEvent);
    end

    function SetsFrameMixin:ClearAllModels()
        self.Loader:Stop();
        for _, model in ipairs(self.Models) do
            model:ClearModel();
        end
    end

    function SetsFrameMixin:OnHide()
        self:ClearAllModels();
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:SetScript("OnEvent", nil);
        self:UnregisterAllEvents();
    end

    function SetsFrameMixin:LoadDefaultSets()
        self:SetScript("OnMouseWheel", nil);
        self:ClearAllModels();

        local customSets = C_TransmogCollection.GetCustomSets() or {};
        local dataList = {};
        local name;

        for i, customSetID in ipairs(customSets) do
            name = GetCustomSetInfo(customSetID);
            local transmogInfoList = GetCustomSetItemTransmogInfoList(customSetID);

            dataList[i] = {
                customSetID = customSetID,
                name = name,
                transmogInfoList = transmogInfoList,
                collected = TransmogUIManager:IsTransmogInfoListCollected(transmogInfoList),
            };
        end

        table.sort(dataList, SortFunc.Default);

        OutfitModule:SetOutfitSource(Def.OutfitSource.Default);
        self:SetDataList(dataList);
    end

    function SetsFrameMixin:SetDataList(dataList)
        self.dataList = dataList;
        self.maxPage = math.ceil(#dataList/self.modelsPerPage);

        if not self.page then
            self.page = 1;
        elseif self.page > self.maxPage then
            self.page = self.maxPage;
        end

        self:UpdatePage(true);
        self:SetScript("OnMouseWheel", self.OnMouseWheel);
    end

    function SetsFrameMixin:GetTransmogData(dataIndex)
        return self.dataList and self.dataList[dataIndex]
    end

    function SetsFrameMixin:ReloadPage()
        --Update Sets Data
        if OutfitModule:GetOutfitSource() == Def.OutfitSource.Default then
            self:LoadDefaultSets();
        end
    end

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
                        model:Hide();
                        model:SetScript("OnShow", nil);
                        model:SetScript("OnHide", nil);
                        model:SetScript("OnEvent", nil);
                        model:SetScript("OnUpdate", nil);
                        model:SetKeepModelOnHide(true);
                        model:UnregisterAllEvents();
                        model:ClearModel();

                        Mixin(model, SetModelMixin);
                        model:SetScript("OnModelLoaded", SetModelMixin.OnModelLoaded);
                        model:SetScript("OnMouseDown", SetModelMixin.OnMouseDown);
                        model:SetScript("OnMouseUp", SetModelMixin.OnMouseUp);
                        model:SetScript("OnEnter", SetModelMixin.OnEnter);
                        model:SetScript("OnLeave", SetModelMixin.OnLeave);

                        local col = (i - 1) % 3;
                        local row = math.ceil(i / 3) - 1;
                        model:SetPoint("TOPLEFT", self, "TOPLEFT", col * (Def.SetModelWidth + Def.SetModelPaddingX), -row * (Def.SetModelHeight + Def.SetModelPaddingY));
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

        for _, model in ipairs(self.Models) do
            if model:IsMouseMotionFocus() then
                model:OnEnter();
                break
            end
        end

        self.PageText:SetText(string.format(PAGE_NUMBER_WITH_MAX, self.page, self.maxPage));
        self.PrevPageButton:SetEnabled(self.page > 1);
        self.NextPageButton:SetEnabled(self.page < self.maxPage);
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
        print(event, ...)
        if event == "TRANSMOG_CUSTOM_SETS_CHANGED" or event == "UNIT_FORM_CHANGED" then
            self:RequestUpdate("All");
        elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            self:RequestUpdate("Camera");
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
            end
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


    if not self.SetsFrame then
        local f = CreateFrame("Frame", nil, self.Container);
        self.SetsFrame = f;

        --For sizes, see CustomSetsFrame.PagedContent (Interface/AddOns/Blizzard_Transmog/Blizzard_Transmog.xml)
        f:SetPoint("TOPLEFT", self.Container, "TOPLEFT", 26, -72);
        f:SetPoint("BOTTOMRIGHT", self.Container, "BOTTOMRIGHT", -26, 10);

        Mixin(f, SetsFrameMixin);
        f:OnLoad();
    end
end

function OutfitModule:SetOutfitSource(outfitSource)
    self.outfitSource = outfitSource;
end

function OutfitModule:GetOutfitSource()
    return self.outfitSource
end

function OutfitModule:OnLoad()
    local ParentTab = TransmogFrame.WardrobeCollection.TabContent.CustomSetsFrame;
    self.ParentTab = ParentTab;

    local Container = CreateFrame("Frame", nil, ParentTab);
    self.Container = Container;
    Container:SetAllPoints(true);


    local CharacterDropdown = CreateFrame("DropdownButton", nil, ParentTab, "WowStyle1DropdownTemplate");
    self.CharacterDropdown = CharacterDropdown;
    self:AddNewObject(CharacterDropdown);

    CharacterDropdown:SetPoint("TOPRIGHT", ParentTab, "TOPRIGHT", -28, -24);
    CharacterDropdown:SetWidth(184);
    Mixin(CharacterDropdown, CharacterDropdownMixin);
    CharacterDropdown:OnLoad();

    self:SetOutfitSource(Def.OutfitSource.Default);
    self:ModifyStockUI();

    --C_EncodingUtil
end



--[[
/dump C_TransmogOutfitInfo.GetOutfitInfo(2);    GetOutfitSituation

--]]