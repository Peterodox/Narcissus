local _, addon = ...
local SetModelLight = addon.TransitionAPI.SetModelLight;

local PAGE_FORMAT = PAGED_LIST_PAGING_FORMAT or "Page %s / %s"; --PRODUCT_CHOICE_PAGE_NUMBER
local MAX_PETS = (NUM_PET_STABLE_PAGES and NUM_PET_STABLE_SLOTS and NUM_PET_STABLE_PAGES * NUM_PET_STABLE_SLOTS) or 200;
local MAX_ROW = 2;
local MAX_COL = 8;
local SLOT_PER_PAGE = MAX_ROW * MAX_COL;

local format = string.format;
local FadeFrame = NarciFadeUI.Fade;

local GetStablePetInfo = C_StableInfo.GetStablePetInfo;

local MainFrame, PetModel, ModelShadow, Tooltip, SelectionOverlay, PageText, PageControl, DropDownButtons, PetSlots;
local TARGET_MODEL_INDEX;
local ACTOR_CREATED = false;

-----------------------------------------------------
local function SetPetModel(model, index)
    local petInfo = GetStablePetInfo(index);
    if petInfo and petInfo.displayID then
        model:SetDisplayInfo(petInfo.displayID);
    end
end

--UI Animations
local outQuart = addon.EasingFunctions.outQuart;

local animExpand = NarciAPI_CreateAnimationFrame(0.25);
animExpand:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local height = outQuart(self.total, self.fromHeight, self.toHeight, self.duration);
    if self.total >= self.duration then
        height = self.toHeight;
        self:Hide();
    end
    self.object:SetHeight(height);
end);


--Opening/closing animation
local cos = math.cos;
local pi = math.pi;

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local animSizing = NarciAPI_CreateAnimationFrame(0.25);
animSizing.relativeTo = Narci_ActorPanelPopUp.PetStableToggle;
animSizing:SetScript("OnShow", function(self)
    self.startWidth, self.startHeight = MainFrame:GetSize();
end);

local function Sizing_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
    local alpha = self.fromAlpha + self.increment * self.total / self.duration;
    local height = inOutSine(self.total, self.startHeight, self.endHeight, self.duration);
	if self.total >= self.duration then
        alpha = 1;
        height = self.endHeight;
        self:Hide();
    end

    MainFrame:SetHeight(height);
    if alpha > 1 then
        alpha = 1;
    elseif alpha < 0 then
        alpha = 0;
    end
    --[[
    if ModelShadow then
        ModelShadow:SetAlpha(alpha);
        PetModel:SetAlpha(alpha);
    end
    MainFrame.PetSlotFrame:SetAlpha(alpha);
    MainFrame.FilterButton:SetAlpha(alpha);
    PageControl:SetAlpha(alpha);
    --]]
end

animSizing:SetScript("OnUpdate", Sizing_OnUpdate);

local function PlayToggleAnimation(state)
    if animSizing:IsShown() then return end

    if state then
        animSizing.endHeight = 224;
        animSizing.fromAlpha = 0;
        animSizing.increment = 1;
        FadeFrame(MainFrame, 0.25, 1);
    else
        animSizing.endHeight = 64;
        animSizing.fromAlpha = 1;
        animSizing.increment = -1;
        FadeFrame(MainFrame, 0.2, 0);
    end

    animSizing:Show();
end

--Model Animation
local function SycAnimation(m)
    PetModel:SetAnimation(0, 0);
    ModelShadow:SetAnimation(0, 0);
end
-----------------------------------------------------

local AddButtonScripts = {};

function AddButtonScripts.OnClick(f)
    MainFrame:ConfirmPet();
end

function AddButtonScripts.OnEnter(f)
    f.Icon:SetVertexColor(1, 1, 1);
    f.Label:SetTextColor(1, 1, 1);
end

function AddButtonScripts.OnLeave(f)
    f.Icon:SetVertexColor(0.6, 0.6 ,0.6);
    f.Label:SetTextColor(0.8, 0.8, 0.8);
end

function AddButtonScripts.OnMouseDown(f)
    f.Icon:SetSize(28, 28);
    f.Background:SetSize(28, 28);
end

function AddButtonScripts.OnMouseUp(f)
    f.Icon:SetSize(32, 32);
    f.Background:SetSize(32, 32);
end


local function SortFunc(a, b)
    --active pet first (index <=5 ) else: icon then index
    if a[1] > 5 and b[1] > 5 then
        if a[2] == b[2] then
            return a[1] < b[1]
        else
            return a[2] < b[2]
        end
    else
        return a[1] < b[1]
    end
end

local DataProvider = {};

local function DataRetriever_OnUpdate(self, elapsed)
    self.index = self.index + 1;
    local info = GetStablePetInfo(self.index);
    if info then
        DataProvider.numPets = DataProvider.numPets + 1;
        local petTypeIndex = DataProvider:GetPetTypeIndex(info.familyName);
        DataProvider.data[DataProvider.numPets] = {self.index, info.icon, info.name, petTypeIndex};
    end

    if self.index >= MAX_PETS then
        self:Hide();
        DataProvider:OnDataReceived();
    end

    self.t = self.t + elapsed;
    if self.t > 0.08 then
        self.t = 0;
        self.ProgressText:SetText(format(self.progressFormat, self.index));
    end
end

function DataProvider:ClearData()
    self.data = {};
    self.types = {};
    self.typeNames = {};
    self.typeCounts = {};
    self.numTypes = 0;
    self.numPets = 0;
end

function DataProvider:GetPetTypeIndex(petName)
    if not self.types[petName] then
        self.numTypes = self.numTypes + 1;
        self.types[petName] = self.numTypes;
        self.typeNames[self.numTypes] = petName;
        self.typeCounts[self.numTypes] = 1;
        return self.numTypes;
    else
        self.typeCounts[self.numTypes] = self.typeCounts[self.numTypes] + 1;
        return self.types[petName]
    end
end

function DataProvider:GetPetTypeName(petTypeIndex)
    return self.typeNames[petTypeIndex]
end

function DataProvider:GetTypeCount(petTypeIndex)
    return self.typeCounts[petTypeIndex]
end

function DataProvider:GetNumTypes()
    return self.numTypes or 0;
end

function DataProvider:GetNumPets()
    return self.numPets or 0;
end

function DataProvider:GetPetName(petIndex)
    return (self.filteredData[petIndex] and self.filteredData[petIndex][3]) or "Pet"
end

function DataProvider:UpdatePetData()
    self:ClearData();
    if not self.retriever then
        self.retriever = CreateFrame("Frame");
        self.retriever:Hide();
        self.retriever:SetScript("OnUpdate", DataRetriever_OnUpdate);
        self.retriever.progressFormat = "%s/" .. MAX_PETS;
        self.retriever.ProgressText = MainFrame.LoadingIndicator.Progress;
    end
    self.isProcessing = true;
    self.retriever:Hide();
    self.retriever.index = 0;
    self.retriever.t = 0;
    self.retriever:Show();
    SelectionOverlay:Hide();
    MainFrame.LoadingIndicator:SetAlpha(1);
    MainFrame.LoadingIndicator:Show();
    --Instant Process
    --[[
    local petIcon, petName, petLevel, petType, petTalents, petTypeIndex;
    local numPets = 0;
    for i = 1, MAX_PETS do
        petIcon, petName, petLevel, petType, petTalents = GetStablePetInfo(i);
        if petIcon then
            numPets = numPets + 1;
            petTypeIndex = self:GetPetTypeIndex(petName);
            self.data[numPets] = {i, petIcon, petName, petTypeIndex};
        end
    end

    if numPets > 0 then
        table.sort(self.data, SortFunc);
        local numPages = math.ceil(numPets / SLOT_PER_PAGE);
        MainFrame.numPages = numPages;
    else
        MainFrame.numPages = 0;
    end
    self.filteredData = self.data;
    --]]
end

function DataProvider:OnDataReceived()
    if self.numPets > 0 then
        table.sort(self.data, SortFunc);
        local numPages = math.ceil(self.numPets / SLOT_PER_PAGE);
        MainFrame.numPages = numPages;
    else
        MainFrame.numPages = 0;
    end
    self.filteredData = self.data;
    self.isProcessing = nil;
    FadeFrame(MainFrame.LoadingIndicator, 0.12, 0);
    MainFrame:UpdatePetSlots();
end

function DataProvider:GetPetInfoByIndex(index)
    return self.filteredData[index];
end

function DataProvider:SetFilter(petTypeIndex)
    local numData = 0;
    if petTypeIndex then
        self.filteredData = {};
        for i = 1, #self.data do
            if self.data[i][4] == petTypeIndex then
                numData = numData + 1;
                self.filteredData[numData] = self.data[i];
            end
        end
    else
        self.filteredData = self.data;
        numData = #self.data;
    end
    return numData
end

local function SelectFilterDropDownButton(button)
    for k, b in pairs(DropDownButtons) do
        if b == button then
            b.TypeName:SetTextColor(0.92, 0.92, 0.92);
        else
            b.TypeName:SetTextColor(0.65, 0.65, 0.65);
        end
    end
end

local function SetUpFilterOptions()
    local f = MainFrame.FilterDropDown;
    local numTypes = DataProvider:GetNumTypes();
    if MainFrame.rebuiltDropDown then
        MainFrame.rebuiltDropDown = nil;
        local typeInfo = {};
        for i = 1, numTypes do
            typeInfo[i] = {i, DataProvider:GetPetTypeName(i)};
        end
        table.sort(typeInfo, function(a, b) return a[2] > b[2] end);
        if numTypes > 0 then
            if not DropDownButtons then
                DropDownButtons = {};
            end
            local textWidth = 0;
            local maxWidth = 0;
            local buttons = DropDownButtons;
            local button;
            for i = 1, numTypes do
                button = buttons[i];
                if not button then
                    button = CreateFrame("Button", nil, f, "NarciPetTypeDropDownButtonTemplate");
                    button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 16 * (i - 1));
                    buttons[i] = button;
                end
                if typeInfo[i] then
                    textWidth = button:SetUp(typeInfo[i][1], typeInfo[i][2]);
                    if textWidth > maxWidth then
                        maxWidth = textWidth;
                    end
                end
                button:Show();
            end
            for i = numTypes + 1, #buttons do
                buttons[i]:Hide();
            end

            --Adjust DropDown width
            if maxWidth < 96 then
                maxWidth = 96;
            end
            for i = 1, numTypes do
                buttons[i]:SetButtonWidth(maxWidth);
            end
            f:SetSize(maxWidth, numTypes * 16);
            f.height = numTypes * 16;
        end
    end

    if numTypes > 0 then
        MainFrame:ToggleDropDown(not f:IsShown());
    end
end

local FilterButtonScripts = {};

function FilterButtonScripts.OnEnter(f)
    f.Label:SetTextColor(1, 1, 1);
    f.Highlight:Show();
end

function FilterButtonScripts.OnLeave(f)
    if f.hasFilter then
        f.Label:SetTextColor(0.25, 0.78, 0.92);
    else
        f.Label:SetTextColor(0.8, 0.8, 0.8);
    end
    f.Highlight:Hide();
end

function FilterButtonScripts:OnClick(f)
    SetUpFilterOptions();
end

function FilterButtonScripts:OnDoubleClick(f)
    return
end


local PageButtonScripts = {};

function PageButtonScripts.OnEnter(f)
    f.Highlight:Show();
end

function PageButtonScripts.OnLeave(f)
    f.Highlight:Hide();
end

function PageButtonScripts.OnClick(f)
    MainFrame:OnMouseWheel(f.increment);
end

function PageButtonScripts.OnMouseDown(f)
    f.Icon:SetSize(14, 14);
end

function PageButtonScripts.OnMouseUp(f)
    f.Icon:SetSize(16, 16);
end

function PageButtonScripts.OnEnable(f)
    f.Icon:SetVertexColor(1, 1, 1);
    f.Background:SetTexCoord(0.875, 1, 0, 0.125);
end

function PageButtonScripts.OnDisable(f)
    f.Icon:SetVertexColor(0.5, 0.5, 0.5);
    f.Background:SetTexCoord(0.875, 1, 0.125, 0.25);
end


local RemoveFilterScripts = {};
RemoveFilterScripts.OnMouseDown = PageButtonScripts.OnMouseDown;
RemoveFilterScripts.OnMouseUp = PageButtonScripts.OnMouseUp;
RemoveFilterScripts.OnEnter = PageButtonScripts.OnEnter;
RemoveFilterScripts.OnLeave = PageButtonScripts.OnLeave;

function RemoveFilterScripts.OnClick(f)
    local numData = DataProvider:SetFilter(nil);
    MainFrame:ResetPage(numData);
    MainFrame.FilterButton.Label:SetText(FILTER);
    MainFrame.FilterButton.hasFilter = nil;
    f:Hide();
    SelectFilterDropDownButton(nil);
end

local FilterDropDownScripts = {};

function FilterDropDownScripts.OnEvent(f)
    if not (f:IsMouseOver() or (MainFrame.FilterButton:IsMouseOver() and not MainFrame.FilterButton.RemoveFilter:IsMouseOver() ) ) then
        MainFrame:ToggleDropDown(false);
    end
end

function FilterDropDownScripts.OnShow(f)
    f:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function FilterDropDownScripts.OnHide(f)
    f:UnregisterEvent("GLOBAL_MOUSE_DOWN");
end


NarciPetStableMixin = {};

function NarciPetStableMixin:Init()
    local SIZE = 24;
    local row, col = 1, 1;
    local button;
    local container = self;
    PetSlots = {};
    for i = 1, MAX_ROW * MAX_COL do
        button = CreateFrame("Button", nil, self.PetSlotFrame, "NarciPetSlotButtonTemplate");
        PetSlots[i] = button;
        button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0 + SIZE * (col - 1), 0 + SIZE * (2 - row));
        button.index = i;
        col = col + 1;
        if col > MAX_COL then
            col = 1;
            row = row + 1;
        end
    end
    self.numSlots = #PetSlots;

    --Preview Model
    PetModel = CreateFrame("PlayerModel", nil, container);
    ModelShadow = CreateFrame("PlayerModel", nil, container);

    for k, model in pairs( {PetModel, ModelShadow} ) do
        model:SetKeepModelOnHide(true);
        model:SetScript("OnModelLoaded", SycAnimation);
        model:UseModelCenterToTransform(true);
        model:SetFacing(math.pi/6);
        model:SetCamDistanceScale(1.3);
        model:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -16);
        model:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 64);
    end

    SetModelLight(PetModel, true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 172/255, 172/255, 172/255, 1, 0.8, 0.8, 0.8);    
    local a = 0.1;
    ModelShadow:SetFogColor(a, a, a);
    SetModelLight(ModelShadow, false, false);
    ModelShadow:SetViewTranslation(6, 0);

    local backdrop = PetModel:CreateTexture(nil, "BACKGROUND");
    backdrop:SetPoint("TOPLEFT", PetModel, "TOPLEFT", 0, 0);
    backdrop:SetPoint("BOTTOMRIGHT", PetModel, "BOTTOMRIGHT", 0, 0);
    backdrop:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PhotoMode/PetStable/ModelBackground");

    --Add Model Button
    local AddButton = self.AddButton;
    AddButton.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PhotoMode/PetStable/AddButton", nil, nil, "TRILINEAR");
    AddButton.Icon:SetTexCoord(0.5, 1, 0, 1);
    AddButton.Background:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PhotoMode/PetStable/AddButton", nil, nil, "TRILINEAR");
    AddButton.Background:SetTexCoord(0, 0.5, 0, 1);
    local offset = 16;
    AddButton:ClearAllPoints();
    AddButton:SetPoint("CENTER", self, "TOP", offset - 192/2, -offset - 16);
    for methodName, method in pairs(AddButtonScripts) do
        AddButton:SetScript(methodName, method);
    end
    AddButtonScripts.OnLeave(AddButton);

    --Filter Button;
    local FilterButton = self.FilterButton;
    for methodName, method in pairs(FilterButtonScripts) do
        FilterButton:SetScript(methodName, method);
    end
    FilterButtonScripts.OnLeave(FilterButton);

    local RemoveFilter = FilterButton.RemoveFilter;
    for methodName, method in pairs(RemoveFilterScripts) do
        RemoveFilter:SetScript(methodName, method);
    end

    --Page Control
    local LeftButton = PageControl.Left;
    local RightButton = PageControl.Right;
    LeftButton.increment = 1;
    RightButton.increment = -1;
    for methodName, method in pairs(PageButtonScripts) do
        LeftButton:SetScript(methodName, method);
        RightButton:SetScript(methodName, method);
    end

    self.Init = nil;
end

function NarciPetStableMixin:UpdatePetSlots()
    if self.Init then
        self:Init();
    end
    self:UpdatePage();
    self.rebuiltDropDown = true;
    PetSlots[1]:Click();
end

function NarciPetStableMixin:OnEvent(event)
    if event then
        self.requireUpdate = true;
    end
end

function NarciPetStableMixin:OnLoad()
    local _, _, classID = UnitClass("player");
    if classID and classID == 3 then
        MainFrame = self;
        Tooltip = self.Tooltip;
        SelectionOverlay = self.SelectionOverlay;
        PageControl = self.PageControl;
        PageText = PageControl.PageText;
        self:RegisterEvent("PET_STABLE_UPDATE");
        self.requireUpdate = true;
        self.page = 1;
        
        for methodName, method in pairs(FilterDropDownScripts) do
            self.FilterDropDown:SetScript(methodName, method);
        end
        animExpand.object = self.FilterDropDown;
        self.LoadingIndicator.ProgressHeader:SetText(Narci.L["PetStable Loading"]);
        --Update Phantom Popup Layout
        local popup = Narci_ActorPanelPopUp;
        popup.BackdropMiddle:SetHeight(104);   --88
        local npcToggle = popup.BrowserToggle;
        npcToggle:ClearAllPoints();
        npcToggle:SetPoint("CENTER", popup, "CENTER", 0, 8 + 24 * 2);
        npcToggle:SetHitRectInsets(0, 0, 0, 0);
        popup.PetStableToggle:Show();
        self:SetHeight(64);
        self:SetAlpha(0);
    else
        self:Hide();
    end
end

function NarciPetStableMixin:SelectPet(petIndex)
    SetPetModel(PetModel, petIndex);
    SetPetModel(ModelShadow, petIndex);
    PetModel:SetAnimation(0, 0);
    ModelShadow:SetAnimation(0, 0);
    self.selectedPetIndex = petIndex;
end

function NarciPetStableMixin:ConfirmPet()
    local petIndex = self.selectedPetIndex;
    if petIndex then
        ACTOR_CREATED = true;
        NarciPhotoModeAPI.OverrideActorInfo(TARGET_MODEL_INDEX, DataProvider:GetPetName(petIndex), nil, self.petIcon);
        local newActor = self.targetModel;
        C_Timer.After(0, function()
            SetPetModel(newActor, self.selectedPetIndex);
        end);
    end
end

function NarciPetStableMixin:UpdatePage()
    local page = self.page;
    local hasSelection = false;
    if self.numPages > 0 then
        local realIndex;
        local indexOffset = SLOT_PER_PAGE * (page - 1);
        local hasPet;
        for i = 1, self.numSlots do
            realIndex = i + indexOffset;
            PetSlots[i]:Disable();
            hasPet = PetSlots[i]:SetData( DataProvider:GetPetInfoByIndex(realIndex) );
            if not hasSelection and hasPet and realIndex == self.selectedPetIndex then
                hasSelection = true;
                SelectionOverlay:ClearAllPoints();
                SelectionOverlay:SetPoint("CENTER", PetSlots[i], "CENTER", 0, 0);
            end
        end
        PageText:SetText(format(PAGE_FORMAT, self.page, self.numPages));
        PageControl.Right:SetEnabled(self.page < self.numPages);
        PageControl.Left:SetEnabled(self.page > 1);
    else
        for i = 1, self.numSlots do
            PetSlots[i]:DisableSlot();
        end
        PageText:SetText(format(PAGE_FORMAT, 0, 0));
        PageControl.Left:Disable();
        PageControl.Right:Disable();
    end

    if hasSelection then
        SelectionOverlay:Show();
    else
        SelectionOverlay:Hide();
    end
end

function NarciPetStableMixin:ResetPage(numData)
    self.page = 1;
    local numPages = math.ceil(numData / SLOT_PER_PAGE);
    self.numPages = numPages;
    self:UpdatePage();
end

function NarciPetStableMixin:OnMouseWheel(delta)
    if self.numPages and self.numPages > 0 then
        if delta < 0 then
            self.page = self.page + 1;
        else
            self.page = self.page - 1;
        end

        if self.page > self.numPages then
            self.page = self.numPages;
        elseif self.page < 1 then
            self.page = 1;
        else
            self:UpdatePage();
        end
    end
end

function NarciPetStableMixin:ToggleDropDown(state)
    if state then
        FadeFrame(self.FilterDropDown, 0.2, 1);
        animExpand.fromHeight = 8;
        animExpand.toHeight = self.FilterDropDown.height;
    else
        FadeFrame(self.FilterDropDown, 0.25, 0);
        animExpand.fromHeight = self.FilterDropDown.height;
        animExpand.toHeight = 4;
    end
    animExpand:Show();
end

function NarciPetStableMixin:Open(anchorButton)
    local PopUp = Narci_ActorPanelPopUp;
    FadeFrame(PopUp, 0.15, 0);
    self:ClearAllPoints();
    self:SetPoint("TOP", anchorButton, "TOP", 0, 16);
    Narci_ModelSettings:SetPanelAlpha(0.5, true);
    local index = PopUp.Index;
    local isPet = true;
    self.targetModel = NarciPhotoModeAPI.CreateEmptyModelForNPCBrowser(index, isPet);     --Defined in PlayerModel.lua
    self:SetFrameLevel(76);
    TARGET_MODEL_INDEX = index;
    PlayToggleAnimation(true);
end

function NarciPetStableMixin:Close()
    PlayToggleAnimation(false);
    Narci_ModelSettings:SetPanelAlpha(1, true);
    if not ACTOR_CREATED then
        NarciPhotoModeAPI.RemoveActor(TARGET_MODEL_INDEX)
    end
    ACTOR_CREATED = false;
end

function NarciPetStableMixin:OnShow()
    if self.requireUpdate then
        self.requireUpdate = nil;
        DataProvider:UpdatePetData();
    end
end

function NarciPetStableMixin:OnHide()
    self:Hide();
end

function NarciPetStableMixin:IsFocused()
    return self:IsShown() and self:IsMouseOver()
end


NarciPetSlotButtonMixin = {};

function NarciPetSlotButtonMixin:OnEnter()
    self:SetHighlight(true);
    local petType = DataProvider:GetPetTypeName(self.petTypeIndex);
    if self.petName and petType then
        Tooltip:ClearAllPoints();
        if self.petName == petType then
            Tooltip.Name:SetText(self.petName);
        else
            Tooltip.Name:SetText(self.petName.. "  ("..petType..")");
        end
        Tooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0);
        Tooltip:Show();
    end
end

function NarciPetSlotButtonMixin:OnLeave()
    self:SetHighlight(false);
    Tooltip:Hide();
end

function NarciPetSlotButtonMixin:SetHighlight(state)
    if state then
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
    else
        self.Icon:SetVertexColor(0.80, 0.80, 0.80);
        self.Icon:SetDesaturation(0.2);
    end
end

function NarciPetSlotButtonMixin:OnClick()
    MainFrame:SelectPet(self.index);
    SelectionOverlay:ClearAllPoints();
    SelectionOverlay:SetPoint("CENTER", self, "CENTER", 0, 0);
    SelectionOverlay:Show();
    
    local AddButton = MainFrame.AddButton;
    AddButton.Label:SetText(self.petName);
    local textWidth = AddButton.Label:GetWidth();
    if textWidth < 32 then
        textWidth = 32;
    end
    AddButton:SetHitRectInsets(-2, -textWidth - 4, 0, 0);

    MainFrame.petIcon = self.Icon:GetTexture();
end

function NarciPetSlotButtonMixin:SetIcon(texture)
    self.Icon:SetTexture(texture);
    self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    self:SetHighlight(false);
end

function NarciPetSlotButtonMixin:DisableSlot()
    self:Disable();
    self.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/PhotoMode/PetStable/EmptySlot");
    self.Icon:SetTexCoord(0, 1, 0, 1);
    self:SetHighlight(true);
    self.petName = nil;
    self.petTypeIndex = nil;
end

function NarciPetSlotButtonMixin:SetData(data)
    --data = {index, petIcon, petName, petTypeIndex}
    if data then
        self.index = data[1];
        self:SetIcon(data[2]);
        self.petName = data[3];
        self.petTypeIndex = data[4];
        self:Enable();
        return true
    else
        self:DisableSlot();
        return false
    end
end


NarciPetTypeDropDownButtonMixin = {};

function NarciPetTypeDropDownButtonMixin:OnEnter()
    FadeFrame(self.Highlight, 0.12, 1);
end

function NarciPetTypeDropDownButtonMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
end

function NarciPetTypeDropDownButtonMixin:OnClick()
    local numData = DataProvider:SetFilter(self.petTypeIndex);
    MainFrame:ResetPage(numData);
    MainFrame.FilterButton.RemoveFilter:Show();
    MainFrame.FilterButton.Label:SetText(self.TypeName:GetText());
    MainFrame.FilterButton.Label:SetTextColor(0.25, 0.78, 0.92);
    MainFrame.FilterButton.hasFilter = true;
    SelectFilterDropDownButton(self);
end

function NarciPetTypeDropDownButtonMixin:SetButtonWidth(width)
    --Min width 96
    self:SetWidth(width);
    self.BackdropCenter:SetWidth(width - 32);
end

function NarciPetTypeDropDownButtonMixin:SetUp(petTypeIndex, name)
    if name then
        self.TypeName:SetText(name);
    else
        self.TypeName:SetText( DataProvider:GetPetTypeName(petTypeIndex) );
    end
    
    self.Count:SetText( DataProvider:GetTypeCount(petTypeIndex) );
    self.petTypeIndex = petTypeIndex;

    return (self.TypeName:GetWidth() + self.Count:GetWidth() + 24);
end