-- Modified Tab: Custom Sets
-- Create a outfit pool shared by the same armor type
-- Our outfit string is slightly different than Blizzard's (TransmogUtil.CreateCustomSetSlashCommand)
-- See NarciDB\TransmogDataProvider for details



local _, addon = ...
local TransmogUIManager = addon.TransmogUIManager;
local TransmogDataProvider = addon.TransmogDataProvider;


local OutfitModule = TransmogUIManager:CreateModule("OutfitPool");
local CharacterDropdownMixin = {};


local GetCustomSetInfo = C_TransmogCollection.GetCustomSetInfo;
local GetCustomSetItemTransmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList;


local Def = {
    OutfitSource = {
        Default = 0,
        Narcissus = 1,
    },

    SetModelWidth = 178,
    SetModelHeight = 218,
    SetModelPaddingX = 27,
    SetModelPaddingY = 19,
};


do  --CharacterDropdown
    function CharacterDropdownMixin:OnClick(button)

    end

    function CharacterDropdownMixin:OnLoad()
        self:SetScript("OnClick", self.OnClick);
        self:SetText("Current Character");
    end
end


local ModelLoaderMixin = {};
do
    function ModelLoaderMixin:LoadModels(modelList)
        self:SetScript("OnUpdate", nil);

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
                self.modelList[self.index]:LoadModel();
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
        local _, transmogCameraID = C_TransmogSets.GetCameraIDs();
	    self.cameraID = transmogCameraID;
        if self.cameraID then
            Model_ApplyUICamera(self, self.cameraID);
        end

        self:RequestLoadSet();

        OutfitModule.SetsFrame.Loader:LoadNext();
    end

    function SetModelMixin:LoadModel()
        local blend = false;
        self:SetUnit("player", blend, PlayerUtil.ShouldUseNativeFormInModelScene());
    end

    function SetModelMixin:RequestLoadSet()
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function SetModelMixin:GetData()
        local data = self.dataIndex and OutfitModule.SetsFrame:GetTransmogData(self.dataIndex);
        return data
    end

    function SetModelMixin:OnUpdate()
        self:SetScript("OnUpdate", nil);
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

    function SetModelMixin:OnMouseDown(button)
        if button == "LeftButton" then
            local data = self:GetData();
            if data then
                if data.customSetID then
		            C_TransmogOutfitInfo.SetOutfitToCustomSet(data.customSetID);
                else
                    TransmogUIManager:SetPendingFromTransmogInfoList(data.transmogInfoList);
                end
                PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);
            end
        end
    end

    function SetModelMixin:OnMouseUp(button)
        if button == "RightButton" and self:IsMouseMotionFocus() then
            
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
            tooltip:AddLine(ITEMS_NOT_IN_INVENTORY:format(#missingSlots), 0.5, 0.5, 0.5, true);
            if NarcissusDB.TransmogUI_ShowMisingItemDetail then
                local slotName;
                for _, slotID in ipairs(missingSlots) do
                    slotName = NarciAPI.GetSlotNameAndTexture(slotID);
                    if slotName then
                        tooltip:AddLine("- "..slotName, 0.5, 0.5, 0.5);
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
end


local SetsFrameMixin = {};
do
    function SetsFrameMixin:OnLoad()
        self.Models = {};
        self.outfitSource = Def.OutfitSource.Default;
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
        local PrevPageButton = CreateFrame("Button", nil, PagingControls, "PagingControlsPrevPageButtonTemplate");
        PrevPageButton:SetPoint("RIGHT", NextPageButton, "LEFT", -5, 0);
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
    end

    function SetsFrameMixin:OnHide()
        for _, model in ipairs(self.Models) do
            model:ClearModel();
        end
    end

    function SetsFrameMixin:LoadDefaultSets()
        self:SetScript("OnMouseWheel", nil);

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
        self.dataList = dataList;

        self.page = 1;
        self.maxPage = math.ceil(#dataList/self.modelsPerPage);
        self:UpdatePage(true);

        self:SetScript("OnMouseWheel", self.OnMouseWheel);
    end

    function SetsFrameMixin:GetTransmogData(dataIndex)
        return self.dataList and self.dataList[dataIndex]
    end

    function SetsFrameMixin:UpdatePage(fullUpdate)
        local fromIndex = (self.page - 1) * self.modelsPerPage;
        local dataIndex;
        local model;

        if fullUpdate then
            local isDefaultMode = self.outfitSource == Def.OutfitSource.Default;
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


    self:ModifyStockUI();

    --C_EncodingUtil
end