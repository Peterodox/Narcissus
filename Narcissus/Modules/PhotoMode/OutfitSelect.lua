local _, addon = ...

local TransitionAPI = addon.TransitionAPI;

local CharacterProfile = addon.ProfileAPI;
local TransmogDataProvider = addon.TransmogDataProvider;

local L = Narci.L;

local FadeFrame = NarciFadeUI.Fade;
local GetEquipmentSlotByID = Narci.GetEquipmentSlotByID;
local GetClassColorByClassID = NarciAPI.GetClassColorByClassID;
local SmartSetActorName = NarciAPI.SmartSetActorName;

local C_TransmogCollection = C_TransmogCollection;
local After = C_Timer.After;
local GetCursorPosition = GetCursorPosition;
local UIParent = UIParent;

local BUTTON_PER_PAGE = 8;
local PIXEL = NarciAPI.GetPixelByScale(1);
local IGNORE_NO_OUTFIT_CHARS = true;

local MainFrame, ActivePreviewModel, CharacterList, FilterButton, SimpleTooltip;
local PreviewModels = {};


local function Mixin(object, mixin)
    for k, v in pairs(mixin) do
        object[k] = v;
    end
end


local inOutSine = addon.EasingFunctions.inOutSine
local outQuart = addon.EasingFunctions.outQuart;
local outSine = addon.EasingFunctions.outSine;

local ModelFileIDxUICameraID = {
    --Transmog-Set-Vendor

    [949470] = 1035,   --Orc F
    [917116] = 1036,   --Orc/Mag'har M Hunched
    [1968587] = 1036,  --Mag'har Upright

    [1630402] = 1039,  --Highmountain F
    [1630218] = 1040,  --Highmountain M

    [940356] = 1029,   --Gnome F
    [900914] = 1030,   --Gnome M

    [2564806] = 1029,  --Mechagnome F
    [2622502] = 1030,  --Mechagnome M

    [1022598] = 1025,  --Draenei F
    [1005887] = 1026,  --Draenei M

    [1593999] = 1025,  --Lightforged F
    [1620605] = 1026,  --Lightforged M

    [589715] = 1037,   --Pandaren F
    [535052] = 1038,   --Pandaren M

    [986648] = 1039,   --Tauren F
    [968705] = 1040,   --Tauren M

    [997378] = 1043,   --UD F
    [959310] = 1044,   --UD M

    [1000764] = 1022,  --Human F
    [1011653] = 996,   --Human M

    [307453] = 1045,   --Worgen-Wolf F
    [307454] = 1046,   --Worgen-Wolf M

    [1890763] = 1027,  --DarkIron F
    [1890765] = 1028,  --DarkIron M

    [950080] = 1027,   --Dwarf F
    [878772] = 1028,   --Dwarf M

    [1733758] = 1023,  --VE F
    [1734034] = 1024,  --VE M

    [1100258] = 1023,  --BE F
    [1100087] = 1024,  --BE M

    [921844] = 1033,   --NE F
    [974343] = 1034,   --NE M

    [1018060] = 1041,  --Troll F
    [1022938] = 1042,  --Troll M

    [1886724] = 1387,  --KulTiran F
    [1721003] = 1386,  --KulTiran M

    [119369] = 1031,   --Goblin F
    [119376] = 1032,   --Goblin M

    [1662187] = 1391,  --Zandalari F
    [1630447] = 1390,  --Zandalari M

    [1890759] = 1031,  --Vulpera F
    [1890761] = 1031,  --Vulpera M

    [1810676] = 1112,  --Nightborne F
    [1814471] = 1034,  --Nightborne M

    [4207724] = 1710,  --Dracthyr M/F
    [4395382] = 1024,  --Dracthyr M Visage
    [4220448] = 1023,  --Dracthyr F Visage
};

local function GetUICameraIDByModelFileID(fileID)
    return ModelFileIDxUICameraID[fileID] or 996
end


local function GetPlayerInfoFromNarcissusDB(uid, key)
    return CharacterProfile:GetPlayerInfo(uid, key);
end

local function GetPlayerInfoFromBetterWardrobeDB(profileKey, key)
    return TransmogDataProvider:GetBWCharacterData(profileKey, key);
end

local GetPlayerInfo = GetPlayerInfoFromNarcissusDB;


local OutfitDataProvider = {};
OutfitDataProvider.isCurrentPlayer = true;
OutfitDataProvider.outfitIDs = {};
OutfitDataProvider.originalOutfitData = {
    --the items they worn when an actors is created
    name = L["Models"],
    outfits = {
        --{name = string, outfit = table, id = number},
    },
};
OutfitDataProvider.currentPlayerUID = CharacterProfile:GetCurrentPlayerUID();  --current player
OutfitDataProvider.selectedPlayerUID = nil;    --the alts
OutfitDataProvider.selectedOrderID = nil;

function OutfitDataProvider:OnTransmogOutfitsChanged()
    if self.selectedPlayerUID == self.currentPlayerUID then
        if MainFrame:IsShown() then
            self:SelectProfile(nil, true);
        else
            MainFrame.outfitChanged = true;
        end
    end
    MainFrame:RegisterEvent("PLAYER_LOGOUT");   --update saved outfits when logout
end

function OutfitDataProvider:SelectProfile(playerUID, forceUpdate)
    playerUID = playerUID or self.currentPlayerUID;

    if playerUID == self.selectedPlayerUID and not forceUpdate then
        return
    else
        self.selectedPlayerUID = playerUID;
    end

    self.selectedOrderID = nil;

    if playerUID == "actors" then
        self["GetNameByOrder"] = self["GetNameFromActors"];
        self["GetOutfitByOrder"] = self["GetOutfitFromActors"];
        self.numOutfits = #self.originalOutfitData.outfits;
        SmartSetActorName(MainFrame.ProfileLabel, L["Origin Outfits"]);
    else
        if playerUID == self.currentPlayerUID then
            self["GetNameByOrder"] = self["GetNameFromServer"];
            self["GetOutfitByOrder"] = self["GetOutfitFromServer"];
            self.outfitStrings = nil;
            self.outfitIDs = C_TransmogCollection.GetOutfits() or {};
            self.numOutfits = #self.outfitIDs;
        else
            self["GetNameByOrder"] = self["GetNameFromProfile"];
            self["GetOutfitByOrder"] = self["GetOutfitFromProfile"];
            self.outfitStrings = GetPlayerInfo(playerUID, "outfits");
            self.numOutfits = #self.outfitStrings;
        end
        SmartSetActorName(MainFrame.ProfileLabel, string.format(L["Outfit Owner Format"], GetPlayerInfo(playerUID, "name")));
    end

    MainFrame:UpdateOutfits();
end

function OutfitDataProvider:GetOutfitByOrder(i)
    if self.isCurrentPlayer then
        local outfitID = self.outfitIDs[i];
        if outfitID then
            return C_TransmogCollection.GetOutfitItemTransmogInfoList(outfitID);
        end
    end
end

function OutfitDataProvider:GetNameByOrder(i)
    if self.isCurrentPlayer then
        local outfitID = self.outfitIDs[i];
        if outfitID then
            return C_TransmogCollection.GetOutfitInfo(outfitID);
        end
    else

    end
end

function OutfitDataProvider:GetNumOutfits()
    return self.numOutfits or 0
end

function OutfitDataProvider:GetNameFromServer(i)
    local outfitID = self.outfitIDs[i];
    if outfitID then
        return C_TransmogCollection.GetOutfitInfo(outfitID);
    end
end

function OutfitDataProvider:GetOutfitFromServer(i)
    local outfitID = self.outfitIDs[i];
    if outfitID then
        return C_TransmogCollection.GetOutfitItemTransmogInfoList(outfitID);
    end
end

function OutfitDataProvider:GetNameFromProfile(i)
    if self.outfitStrings[i] then
        return self.outfitStrings[i].n
    end
end

function OutfitDataProvider:GetOutfitFromProfile(i)
    if self.outfitStrings[i] and self.outfitStrings[i].s then
        return TransmogDataProvider:ConvertTransmogStringToList( self.outfitStrings[i].s );
    end
end

function OutfitDataProvider:GetNameFromActors(i)
    return self.originalOutfitData.outfits[i].name
end

function OutfitDataProvider:GetOutfitFromActors(i)
    --return self.originalOutfitData.outfits[i].outfit
    return  TransmogDataProvider:ConvertTransmogStringToList( self.originalOutfitData.outfits[i].outfitString );
end

local DelayTryOn = {
    t = 0,
    orderID = nil,
};

local function HasAnySource(transmogInfo)
    return transmogInfo and transmogInfo.appearanceID ~= 0
end

local function DressModelByOrderID(model, orderID)
    local infoList = OutfitDataProvider:GetOutfitByOrder(orderID);
    local result;
    local valid = true;
    if infoList then
        model:Undress();
        for slotID, transmogInfo in pairs(infoList) do
            result = model:SetItemTransmogInfo(transmogInfo, slotID, slotID ~= 16);       --possibly broken: dressing gnome with BE heritage armor returns 0 (success)
            --print(slotID.." "..result)
            if not HasAnySource(transmogInfo) then
                result = 0;     --consider empty slot as TryOn successful
            end
            valid = valid and (result == 0);
        end
    end
    MainFrame.RightArea.TryOnAlert:SetShown(not valid);
end

local function DelayTryOn_OnUpdate(self, elapsed)
    DelayTryOn.t = DelayTryOn.t + elapsed;
    if DelayTryOn.t >= 0.15 then
        if DelayTryOn.orderID then
            DressModelByOrderID(ActivePreviewModel, DelayTryOn.orderID);
        end
        self:SetScript("OnUpdate", nil);
    end
end

local function AnchorSelectionMarkToButton(self, button)
    --self: the parent frame of the texture
    if button then
        if not self.SelectionMark then
            self.SelectionMark = self:CreateTexture(nil, "OVERLAY");
            self.SelectionMark:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\OutfitSelect\\SelectionMark");
            self.SelectionMark:SetSize(16*PIXEL, 16*PIXEL);
        end
        self.SelectionMark:ClearAllPoints();
        self.SelectionMark:SetPoint("CENTER", button, "LEFT", 7, 0);
        self.SelectionMark:Show();
    else
        if self.SelectionMark then
            self.SelectionMark:Hide();
        end
    end
end

local function PreviewModel_OnModelLoaded(self)
    --print("ModelFileID: "..self:GetModelFileID());
    local cameraID = GetUICameraIDByModelFileID( self:GetModelFileID() )
    --local detailsCameraID, transmogCameraID = C_TransmogSets.GetCameraIDs();
    Model_ApplyUICamera(self, cameraID);
    self:SetAnimation(0);
    self:FreezeAnimation(0, 0, 0);
end

local function HeaderButton_OnEnter(self)
    self.Label:SetTextColor(1, 1, 1);
    self.Icon:SetVertexColor(1, 1, 1);
    self.Label:Show();
end

local function HeaderButton_OnLeave(self)
    self.Label:SetTextColor(0.65, 0.65, 0.65);
    self.Icon:SetVertexColor(0.65, 0.65, 0.65);
    if self.hiddenLabel then
        self.Label:Hide();
    end
end

local function HeaderButton_OnMouseDown(self)
    self.Label:SetPoint("CENTER", 5, -1.6);
end

local function HeaderButton_OnMouseUp(self)
    self.Label:SetPoint("CENTER", 5, -1);
end


--SimpleTooltip: Show this if the outfit name is truncated--

local function SimpleTooltip_OnUpdate(self, elapsed)
    self.x, self.y = GetCursorPosition();
    self.x = self.x + 0;
    self.y = self.y + 8;
    self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", self.x, self.y);
    if self.t then
        self.t = self.t + elapsed;
        if self.t < 0 then
            self:SetAlpha(0);
        elseif self.t < 0.2 then
            self:SetAlpha(self.t * 5);
        else
            self:SetAlpha(1);
            self.t = nil;
        end
    end
end

local function SimpleTooltip_SetText(text)
    SimpleTooltip.Name:SetText(text);
    SimpleTooltip:SetScript("OnUpdate", SimpleTooltip_OnUpdate);
    SimpleTooltip.t = -0.5;
    SimpleTooltip:SetAlpha(0);
    SimpleTooltip:Show();
end

local function SimpleTooltip_OnHide()
    SimpleTooltip:SetScript("OnUpdate", nil);
    SimpleTooltip:Hide();
    SimpleTooltip.x = nil;
    SimpleTooltip.y = nil;
end

NarciPhotoModeOutfitButtonMixin = {};

function NarciPhotoModeOutfitButtonMixin:ShowHighlight()
    FadeFrame(self.Highlight, 0.12, 1);
end

function NarciPhotoModeOutfitButtonMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
    MainFrame.RightArea:SetScript("OnUpdate", nil);

    SimpleTooltip:Hide();
end

function NarciPhotoModeOutfitButtonMixin:HideButton()
    self:Hide();
    self.Highlight:Hide();
    self.Highlight:SetAlpha(0);
    self.orderID = nil;
end

function NarciPhotoModeOutfitButtonMixin:OnEnter()
    self:ShowHighlight();
    DelayTryOn.t = 0;
    DelayTryOn.orderID = self.orderID;
    MainFrame.RightArea:SetScript("OnUpdate", DelayTryOn_OnUpdate);
    if self.Name:IsTruncated() then
        SimpleTooltip_SetText(self.Name:GetText());
    else
        SimpleTooltip:Hide();
    end
end

function NarciPhotoModeOutfitButtonMixin:OnClick()
    local model = Narci.ActiveModel;
    if model and model:IsObjectType("DressUpModel") then
        local infoList = OutfitDataProvider:GetOutfitByOrder(self.orderID);
        if infoList then
            model:Undress();
            if model:GetName() == "NarciPlayerModelFrame1" then
                local slotButton;
                for slotID, transmogInfo in pairs(infoList) do
                    slotButton = GetEquipmentSlotByID(slotID);
                    if slotButton then
                        if transmogInfo then
                            slotButton:SetTransmogSourceID(transmogInfo.appearanceID, transmogInfo.secondaryAppearanceID);
                        else
                            slotButton:SetTransmogSourceID(0);
                        end
                    end
                    --model:SetItemTransmogInfo(transmogInfo, slotID);
                    --[[
                    if slotID == 16 or slotID == 17 then
                        model:TryOn(transmogInfo.appearanceID, (slotID == 16 and "MAINHANDSLOT") or "SECONDARYHANDSLOT", transmogInfo.illusionID);    --ME FIXED?
                    else
                        model:SetItemTransmogInfo(transmogInfo);
                    end
                    --]]
                    model:SetItemTransmogInfo(transmogInfo, slotID, slotID ~= 16)
                end
            else
                for slotID, transmogInfo in pairs(infoList) do
                    --model:SetItemTransmogInfo(transmogInfo, slotID);
                    --[[
                    if slotID == 16 or slotID == 17 then
                        model:TryOn(transmogInfo.appearanceID, (slotID == 16 and "MAINHANDSLOT") or "SECONDARYHANDSLOT", transmogInfo.illusionID);    --ME FIXED?
                    else
                        model:SetItemTransmogInfo(transmogInfo);
                    end
                    --]]
                    model:SetItemTransmogInfo(transmogInfo, slotID, slotID ~= 16)
                end
            end
            Narci_PhotoModeWeaponFrame:SetItemFromActor(model);
            model.customTransmogList = infoList;
        end
    end
    AnchorSelectionMarkToButton(self:GetParent(), self);
    OutfitDataProvider.selectedOrderID = self.orderID;
end


NarciPhotoModeCharacterListButtonMixin = CreateFromMixins(NarciPhotoModeOutfitButtonMixin);

function NarciPhotoModeCharacterListButtonMixin:OnEnter()
    self:ShowHighlight();
end

function NarciPhotoModeCharacterListButtonMixin:SetData(name, classID, numOutfits)
    --self.Name:SetText(name);
    SmartSetActorName(self.Name, name);

    local classColor = classID and GetClassColorByClassID(classID);
    if classColor then
        self.Name:SetTextColor(classColor:GetRGB());
    else
        self.Name:SetTextColor(0.65, 0.65, 0.65);
    end

    if numOutfits and numOutfits > 0 then
        self.Count:SetText(numOutfits);
        self.Count:Show();
    else
        self.Count:Hide();
    end
end

function NarciPhotoModeCharacterListButtonMixin:OnClick()
    AnchorSelectionMarkToButton(self:GetParent(), self);
    OutfitDataProvider:SelectProfile(self.uid);
end


local function ClearAnimationTemps()
    local f = MainFrame;
    f:SetScript("OnUpdate", nil);
    f.t = nil;
    f.toWidth = nil;
    f.fromWidth = nil;
    f.toHeight = nil;
end

local function AnimExpand_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local width = inOutSine(self.t, self.fromWidth, self.toWidth, 0.35);
    if self.t >= 0.35 then
        width = self.toWidth;
        ClearAnimationTemps();
    end
    local listWidth = width - 216;
    if listWidth < 1 then
        listWidth = 1;
    end
    self:SetWidth(width);
    self.CharacterList:SetWidth(listWidth);
end

local function AnimOpen_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local height = outQuart(self.t, 51, 161, 0.25);
    local yaw = outSine(self.t, -0.85, 0, 0.25);
    local alpha = 4 * self.t;
    if self.t >= 0.25 then
        height = 161;
        alpha = 1;
        yaw = 0;
        ClearAnimationTemps();
    end

    self:SetHeight(height);
    self:SetAlpha(alpha);
    ActivePreviewModel:SetFacing(yaw);
end

local function ToggleCharacterList()
    if MainFrame.t then return end;     --still in transition

    local state = not CharacterList:IsShown();
    --CharacterList:SetShown(state);
    --[[
    if state then
        MainFrame:SetWidth(324);
    else
        MainFrame:SetWidth(216);
    end
    --]]
    MainFrame.fromWidth = MainFrame:GetWidth();
    MainFrame.t = 0;
    if state then
        MainFrame.toWidth = 324;
        FadeFrame(CharacterList, 0.25, 1, 0);
    else
        MainFrame.toWidth = 216;
        FadeFrame(CharacterList, 0.25, 0);
    end
    MainFrame:SetScript("OnUpdate", AnimExpand_OnUpdate);
end

local function Shared_OnMouseWheel(self, delta)
    local valid;
    if delta > 0 then
        if self.page > 1 then
            self.page = self.page - 1;
            valid = true;
        end
    elseif delta < 0 then
        if self.page < self.numPages then
            self.page = self.page + 1;
            valid = true;
        end
    end

    if valid then
        self:UpdatePage();
    end
end

local ValidSortMethods = {
    name = 1,
    recent = 2,
};

local function FilterButton_UpdateName(methodID)
    if not methodID then
        local currentMethod = NarcissusDB.OutfitSortMethod;
        methodID = ValidSortMethods[currentMethod];
    end
    if methodID == 1 then
        FilterButton.Label:SetText(L["SortMethod Name"]);
    else
        FilterButton.Label:SetText(L["SortMethod Recent"]);
    end
end

local function FilterButton_OnClick()
    local currentMethod = NarcissusDB.OutfitSortMethod;
    local methodID = ValidSortMethods[currentMethod];
    local newMethod;
    if methodID == 1 then
        newMethod = "recent";
        methodID = 2;
    else
        newMethod= "name";
        methodID = 1;
    end
    CharacterList:Init(newMethod);
    NarcissusDB.OutfitSortMethod = newMethod;
    FilterButton_UpdateName(methodID);
end


local UIDRoster;

local CharacterListMixin = {};

function CharacterListMixin:Init(sortMethod)
    --Get Profiles
    local methodID = ValidSortMethods[sortMethod] or 1;
    if not methodID then
        sortMethod = "name";
    end

    local numCharacters, numIgnored;
    if sortMethod == "BetterWardrobe" then
        UIDRoster, numCharacters, numIgnored = TransmogDataProvider:GetBWCharacters();
    else
        UIDRoster, numCharacters, numIgnored = CharacterProfile:GetRoster(sortMethod, IGNORE_NO_OUTFIT_CHARS and "outfit");
    end   

    table.insert(UIDRoster, 1, "actors");   --the first entry is reserved for actors' original outfits
    numCharacters = numCharacters + 1;

    self.page = 1;
    if not self.PageNodes then
        self.PageNodes = {};
    end
    if not self.Buttons then
        self.Buttons = {};
    end

    local numPages;

    if numCharacters > 0 then
        numPages = math.ceil(numCharacters / BUTTON_PER_PAGE);
    else
        numPages = 0;
    end

    self.numPages = numPages;

    if numPages > 1 then
        for i = 1, numPages do
            if not self.PageNodes[i] then
                self.PageNodes[i] = self:CreateTexture(nil, "OVERLAY");
                local a = 8 * PIXEL;
                self.PageNodes[i]:SetSize(a, a);
                self.PageNodes[i]:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\OutfitSelect\\PageNode");
            end
            self.PageNodes[i]:ClearAllPoints();
            self.PageNodes[i]:SetPoint("TOP", self, "RIGHT", -6, 4 * (numPages - 0.5) + (1 - i) * 8);
            self.PageNodes[i]:Show();
        end
        for i = numPages + 1, #self.PageNodes do
            self.PageNodes[i]:Hide();
        end
    else
        for _, tex in pairs(self.PageNodes) do
            tex:Hide();
        end
    end

    self:UpdatePage();
end

function CharacterListMixin:UpdatePage()
    AnchorSelectionMarkToButton(self.ClipContainer, nil);

    local button;
    local characterData;
    local name, uid, classID, numOutfits;
    local indexOffset = (self.page - 1) * BUTTON_PER_PAGE;
    local anySelection;
    for i = 1, BUTTON_PER_PAGE do
        uid = UIDRoster[i + indexOffset];
        if uid then
            if uid == "actors" then
                characterData = OutfitDataProvider.originalOutfitData;
            else
                characterData = GetPlayerInfo(uid);
            end

            if not self.Buttons[i] then
                self.Buttons[i] = CreateFrame("Button", nil, self.ClipContainer, "NarciPhotoModeCharacterListButtonTemplate");
                --self.Buttons[i]:SetPoint("TOP", self, "TOP", 1, (1 - i) * 16 - 8);
                self.Buttons[i]:SetPoint("BOTTOM", self, "BOTTOM", 1, (1 - i) * 16 + 120);
                self.Buttons[i].Name:SetWidth(64);
            end
            button = self.Buttons[i];
            name = characterData.name;
            classID = characterData.class;
            numOutfits = characterData.numOutfits or (characterData.outfits and #characterData.outfits);
            button:SetData(name, classID, numOutfits);
            button.uid = uid;
            button:Show();
            if not anySelection then
                if uid == OutfitDataProvider.selectedPlayerUID then
                    anySelection = true;
                    AnchorSelectionMarkToButton(self.ClipContainer, button);
                end
            end
        else
            if self.Buttons[i] then
                self.Buttons[i]:HideButton();
            else
                break
            end
        end
    end

    for i = 1, self.numPages do
        if self.PageNodes[i] then
            if i == self.page then
                self.PageNodes[i]:SetVertexColor(1, 1, 1);
            else
                self.PageNodes[i]:SetVertexColor(0.5, 0.5, 0.5);
            end
        end
    end

    --[[
    if self:IsMouseOver(0, 0, 0, -106) then
        for i = 1, BUTTON_PER_PAGE do
            if self.Buttons[i] and self.Buttons[i]:IsShown() then
                if self.Buttons[i]:IsMouseOver() then
                    self.Buttons[i]:OnEnter();
                    break
                end
            else
                break
            end
        end
    end
    --]]
end

local function SetDataSource(source)
    if source == "BetterWardrobe" then
        GetPlayerInfo = GetPlayerInfoFromBetterWardrobeDB;
        CharacterList:Init("BetterWardrobe");
        FilterButton:Hide();
        FilterButton.Label:SetText("BetterWardrobe");
    else
        GetPlayerInfo = GetPlayerInfoFromNarcissusDB;
        CharacterList:Init(NarcissusDB.OutfitSortMethod);
        FilterButton:Show();
        FilterButton_UpdateName();
    end
end

local function DataSourceButton_SetLabelText(self, text)
    self.Label:SetText(text);
    self:SetWidth(math.ceil(self.Label:GetWidth() or 16) + 20);
end

local function DataSourceButton_OnClick(self)
    self.isBW = not self.isBW;
    local name;
    if self.isBW then
        name = "BetterWardrobe";
    else
        name = "Narcissus";
    end
    SetDataSource(name);
    DataSourceButton_SetLabelText(self, name);
end



NarciPhotoModeOutfitSelectMixin = {};

function NarciPhotoModeOutfitSelectMixin:OnLoad()
    MainFrame = self;
    self.parent = self:GetParent();
    self.activeModelIndex = 1;

    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("TRANSMOG_OUTFITS_CHANGED");
end


function NarciPhotoModeOutfitSelectMixin:Init()
    self.Buttons = {};
    self.PageNodes = {};

    self:SetScript("OnMouseWheel", Shared_OnMouseWheel);

    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "shadowR12", 1, 0, 0, 0);

    --[[
    ActivePreviewModel = CreateFrame("DressUpModel", nil, self);
    --ActivePreviewModel:SetKeepModelOnHide(true);

    local m = ActivePreviewModel;
    m:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
    m:SetSize(106, 142); --108, 144
    m:SetAutoDress(true);
    m:SetUnit("player");
    m:SetAnimation(0);
    m:SetViewTranslation(0, 0);
    m:SetModelDrawLayer("ARTWORK");
    m:SetFrameLevel(self:GetFrameLevel())
    local x, y, z = m:TransformCameraSpaceToModelSpace(0, 0, -0.25);
    m:SetPosition(x, y, z);
    m:SetLight(true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);
    m:SetScript("OnShow", function(f)
        f:RefreshUnit();
    end);
    --]]

    SimpleTooltip = self.SimpleTooltip;
    SimpleTooltip:SetScript("OnHide", SimpleTooltip_OnHide);

    local switch = Narci_ModelSettings.BasicPanel.OutfitToggle;
    self:ClearAllPoints();
    self:SetPoint("BOTTOMRIGHT", switch, "TOPLEFT", 214, 4);
    self.parentSwitch = switch;

    --Create Background Textures
    local function TileBackground(frame, fromCoordX, sublevel)
        local tiles = {};
        local t;
        for i = 1, 9 do
            t = frame:CreateTexture(nil, "BACKGROUND", nil, sublevel);
            t:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\OutfitSelect\\Panel");
            tiles[i] = t;
            if i <= 4 then
                t:SetSize(34, 34);
                if i == 1 then
                    t:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
                    t:SetTexCoord(fromCoordX, fromCoordX + 0.125, 0, 0.125);
                elseif i == 2 then
                    t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
                    t:SetTexCoord(fromCoordX + 0.25, fromCoordX + 0.375, 0, 0.125);
                elseif i == 3 then
                    t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
                    t:SetTexCoord(fromCoordX, fromCoordX + 0.125, 0.25, 0.375);
                elseif i == 4 then
                    t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
                    t:SetTexCoord(fromCoordX + 0.25, fromCoordX + 0.375, 0.25, 0.375);
                end
            elseif i == 9 then
                t:SetPoint("TOPLEFT", tiles[1], "BOTTOMRIGHT", 0, 0);
                t:SetPoint("BOTTOMRIGHT", tiles[4], "TOPLEFT", 0, 0);
                t:SetTexCoord(fromCoordX + 0.125, fromCoordX + 0.25, 0.125, 0.25);
            else
                if i == 5 then
                    t:SetPoint("TOPLEFT", tiles[1], "TOPRIGHT", 0, 0);
                    t:SetPoint("BOTTOMRIGHT", tiles[2], "BOTTOMLEFT", 0, 0);
                    t:SetTexCoord(fromCoordX + 0.125, fromCoordX + 0.25, 0, 0.125);
                elseif i == 6 then
                    t:SetPoint("TOPLEFT", tiles[1], "BOTTOMLEFT", 0, 0);
                    t:SetPoint("BOTTOMRIGHT", tiles[3], "TOPRIGHT", 0, 0);
                    t:SetTexCoord(fromCoordX, fromCoordX + 0.125, 0.125, 0.25);
                elseif i == 7 then
                    t:SetPoint("TOPLEFT", tiles[2], "BOTTOMLEFT", 0, 0);
                    t:SetPoint("BOTTOMRIGHT", tiles[4], "TOPRIGHT", 0, 0);
                    t:SetTexCoord(fromCoordX + 0.25, fromCoordX + 0.375, 0.125, 0.25);
                elseif i == 8 then
                    t:SetPoint("TOPLEFT", tiles[3], "TOPRIGHT", 0, 0);
                    t:SetPoint("BOTTOMRIGHT", tiles[4], "BOTTOMLEFT", 0, 0);
                    t:SetTexCoord(fromCoordX + 0.125, fromCoordX + 0.25, 0.25, 0.375);
                end
            end
        end
    end

    TileBackground(self.LeftArea, 0, 1);
    TileBackground(self.RightArea, 0.5, 2);


    local h = self.Header;
    self.ProfileLabel = h.CharacterListToggle.Label;
    h.CharacterListToggle:SetScript("OnClick", ToggleCharacterList);
    h.CharacterListToggle:SetScript("OnEnter", HeaderButton_OnEnter);
    h.CharacterListToggle:SetScript("OnLeave", HeaderButton_OnLeave);
    h.CharacterListToggle:SetScript("OnMouseDown", HeaderButton_OnMouseDown);
    h.CharacterListToggle:SetScript("OnMouseUp", HeaderButton_OnMouseUp);
    HeaderButton_OnLeave(h.CharacterListToggle);

    --header background
    local tiles = {};
    for i = 1, 3 do
        local t = h:CreateTexture(nil, "BACKGROUND", nil, 0);
        t:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\OutfitSelect\\Panel");
        tiles[i] = t;
        if i == 3 then
            t:SetPoint("TOPLEFT", tiles[1], "TOPRIGHT", 0, 0);
            t:SetPoint("BOTTOMRIGHT", tiles[2], "BOTTOMLEFT", 0, 0);
            t:SetTexCoord(0.125, 0.25, 0.5, 0.5625);
        else
            t:SetSize(34, 17);
            if i == 1 then
                t:SetPoint("TOPLEFT", h, "TOPLEFT", 0, 0);
                t:SetTexCoord(0, 0.125, 0.5, 0.5625);
            else
                t:SetPoint("TOPRIGHT", h, "TOPRIGHT", 0, 0);
                t:SetTexCoord(0.25, 0.375, 0.5, 0.5625);
            end
        end
    end

    OutfitDataProvider:SelectProfile();

    CharacterList = self.CharacterList;
    CharacterList:SetScript("OnMouseWheel", Shared_OnMouseWheel);
    Mixin(CharacterList, CharacterListMixin);

    CharacterList:Init(NarcissusDB.OutfitSortMethod);

    FilterButton = self.CharacterList.ClipContainer.FilterButton;
    local fb = FilterButton;
    fb.methodID = 1;
    fb:SetScript("OnClick", FilterButton_OnClick);
    fb:SetScript("OnEnter", HeaderButton_OnEnter);
    fb:SetScript("OnLeave", HeaderButton_OnLeave);
    fb:SetScript("OnMouseDown", HeaderButton_OnMouseDown);
    fb:SetScript("OnMouseUp", HeaderButton_OnMouseUp);
    FilterButton_UpdateName();
    HeaderButton_OnLeave(fb);

    if TransmogDataProvider:IsBWDatabaseValid() then
        --Create a button to select outfit data source (Narcissus, BetterWardrobe)
        local dsb = self.CharacterList.ClipContainer.DataSourceButton;
        dsb:Show();
        dsb:SetScript("OnEnter", HeaderButton_OnEnter);
        dsb:SetScript("OnLeave", HeaderButton_OnLeave);
        dsb:SetScript("OnMouseDown", function(f)
            f.Label:SetPoint("LEFT", 19, -1.6);
        end);
        dsb:SetScript("OnMouseUp", function(f)
            f.Label:SetPoint("LEFT", 19, -1);
        end);
        dsb:SetScript("OnClick", DataSourceButton_OnClick);
        DataSourceButton_SetLabelText(dsb, "Narcissus");

        fb:ClearAllPoints();
        fb:SetPoint("CENTER", CharacterList, "TOP", 46, 8);
        fb:SetSize(16, 16);
        fb.hiddenLabel = true;
        fb.Icon:ClearAllPoints();
        fb.Icon:SetPoint("CENTER", fb, "CENTER", 0, -1);
        fb.Label:Hide();
        fb.Label:ClearAllPoints();
        fb.Label:SetPoint("RIGHT", fb.Icon, "LEFT", 4, 0);
        fb.Label:SetJustifyH("RIGHT");
        fb:SetScript("OnMouseDown", function(f)
            f.Icon:SetPoint("CENTER", 0, -1.6);
        end);
        fb:SetScript("OnMouseUp", function(f)
            f.Icon:SetPoint("CENTER", 0, -1);
        end);
    end

    self:AddPlayerActor("player", _G["NarciPlayerModelFrame1"]);
    if self.activeModelIndex == 1 then
        self:SelectPreviewModel(1);
    end

    self.Init = nil;
end

function NarciPhotoModeOutfitSelectMixin:AddPlayerActor(unit, model)
    if not model.GetItemTransmogInfoList then return end;

    local index = model:GetID();

    if not PreviewModels[index] then
        local m =  CreateFrame("DressUpModel", nil, self);
        PreviewModels[index] = m;
        m:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
        m:SetSize(106, 142); --108, 144
        m:SetAutoDress(true);
        m:SetKeepModelOnHide(true);
        m:SetAnimation(0);
        m:SetViewTranslation(0, 0);
        m:SetModelDrawLayer("ARTWORK");
        m:SetFrameLevel(self:GetFrameLevel());
        m:SetScript("OnModelLoaded", PreviewModel_OnModelLoaded);
        local x, y, z = TransitionAPI.TransformCameraSpaceToModelSpace(m, 0, 0, -0.25);
        TransitionAPI.SetModelPosition(m, x, y, z);
        TransitionAPI.SetModelLight(m, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);
        m:Hide();
    end
    
    TransitionAPI.SetModelByUnit(PreviewModels[index], unit);

    --Add outfit
    After(0.2, function()
        local name = UnitName(unit) or unit;
        name = name.." #"..index;
        local infoList = model:GetItemTransmogInfoList();   --we have to deep copy this table
        local transmogString = TransmogDataProvider:ConvertTransmogListToString(infoList);

        local db = OutfitDataProvider.originalOutfitData.outfits;

        for i = 1, #db do
            if db[i].id == index then
                table.remove(db, i);
                break
            end
        end

        table.insert(db, 1,
            {
                name = name,
                outfit = infoList,
                outfitString = transmogString,
                id = index,
            }
        );

        if CharacterList then
            --Frame hasn't been initialized
            CharacterList:UpdatePage();
            if OutfitDataProvider.selectedPlayerUID == "actors" then
                OutfitDataProvider.numOutfits = #db;
                self:UpdatePage();
            end
        end
    end)
end

function NarciPhotoModeOutfitSelectMixin:ModifyPlayerTransmogInfo(index, mainHandInfo, offHandInfo)
    local db = OutfitDataProvider.originalOutfitData.outfits;
    local outfitData;
    for i = 1, #db do
        if db[i].id == index then
            outfitData = db[i];
            if outfitData.outfit then
                outfitData.outfit[16] = mainHandInfo;
                outfitData.outfit[17] = offHandInfo;
            end
            break
        end
    end
    if outfitData then
        outfitData.outfitString = TransmogDataProvider:ConvertTransmogListToString(outfitData.outfit);
    end
end

function NarciPhotoModeOutfitSelectMixin:SelectPreviewModel(index)
    for i, model in pairs(PreviewModels) do
        if i == index then
            model:Show();
            ActivePreviewModel = model;
        else
            model:Hide();
        end
    end
    self.activeModelIndex = index;
end

function NarciPhotoModeOutfitSelectMixin:UpdateOutfits()
    local numOutfits = OutfitDataProvider:GetNumOutfits();
    local numPages;

    if numOutfits > 0 then
        numPages = math.ceil(numOutfits / BUTTON_PER_PAGE);
        self.NoOutfitText:Hide();
    else
        numPages = 0;
        self.NoOutfitText:Show();
    end

    for _, tex in pairs(self.PageNodes) do
        tex:Hide();
    end

    if numPages > 1 then
        for i = 1, numPages do
            if not self.PageNodes[i] then
                self.PageNodes[i] = self:CreateTexture(nil, "OVERLAY");
                local a = 8 * PIXEL;
                self.PageNodes[i]:SetSize(a, a);
                self.PageNodes[i]:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\OutfitSelect\\PageNode");
            end
            self.PageNodes[i]:ClearAllPoints();
            self.PageNodes[i]:SetPoint("TOP", self.RightArea, "LEFT", -6, 4 * (numPages - 0.5) + (1 - i) * 8);
            self.PageNodes[i]:Show();
        end
    end

    self.outfitChanged = nil;
    self.numPages = numPages;
    self:ResetPage();
end

function NarciPhotoModeOutfitSelectMixin:ResetPage()
    self.page = 1;
    self:UpdatePage();
end

function NarciPhotoModeOutfitSelectMixin:OnShow()
    if self.Init then
        self:Init();
    end
    if self.outfitChanged then
        OutfitDataProvider:OnTransmogOutfitsChanged();
    end
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    self.parentSwitch.Arrow:SetTexCoord(0, 1, 0, 1);
end

function NarciPhotoModeOutfitSelectMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:Hide();
    self.parentSwitch.Arrow:SetTexCoord(0, 1, 1, 0);
    if self.t then
        if self.toWidth then
            local listWidth = self.toWidth - 216;
            if listWidth < 1 then
                listWidth = 1;
            end
            self:SetWidth(self.toWidth);
            self.CharacterList:SetWidth(listWidth);
            ClearAnimationTemps();
        end
    end
end

function NarciPhotoModeOutfitSelectMixin:OnEnter()
    self.parent:OnEnter();
end

function NarciPhotoModeOutfitSelectMixin:UpdatePage()
    AnchorSelectionMarkToButton(self, nil);

    local button;
    local name;
    local indexOffset = (self.page - 1) * BUTTON_PER_PAGE;
    local numOutfits = OutfitDataProvider:GetNumOutfits();
    local orderID;
    local anySelection;
    for i = 1, BUTTON_PER_PAGE do
        orderID = i + indexOffset;
        if orderID <= numOutfits then
            if not self.Buttons[i] then
                self.Buttons[i] = CreateFrame("Button", nil, self, "NarciPhotoModeOutfitButtonTemplate");
                --self.Buttons[i]:SetPoint("TOPRIGHT", self.LeftArea, "TOPRIGHT", -1, (1 - i) * 16 - 8);
                self.Buttons[i]:SetPoint("BOTTOMRIGHT", self.LeftArea, "BOTTOMRIGHT", -1, (1 - i) * 16 + 120);
            end
            button = self.Buttons[i];
            button.orderID = orderID;
            name = OutfitDataProvider:GetNameByOrder(orderID);
            SmartSetActorName(button.Name, name);
            --button.Name:SetText(name);
            button:Show();
            if not anySelection then
                if orderID == OutfitDataProvider.selectedOrderID then
                    anySelection = true;
                    AnchorSelectionMarkToButton(self, button);
                end
            end
        else
            if self.Buttons[i] then
                self.Buttons[i]:HideButton();
            else
                break
            end
        end
    end

    for i = 1, self.numPages do
        if self.PageNodes[i] then
            if i == self.page then
                self.PageNodes[i]:SetVertexColor(1, 1, 1);
            else
                self.PageNodes[i]:SetVertexColor(0.5, 0.5, 0.5);
            end
        end
    end

    if self:IsMouseOver(0, 0, 0, -106) then
        for i = 1, BUTTON_PER_PAGE do
            if self.Buttons[i] and self.Buttons[i]:IsShown() then
                if self.Buttons[i]:IsMouseOver() then
                    self.Buttons[i]:OnEnter();
                    break
                end
            else
                break
            end
        end
    end
end

function NarciPhotoModeOutfitSelectMixin:OnMouseWheel(delta)
    local valid;
    if delta > 0 then
        if self.page > 1 then
            self.page = self.page - 1;
            valid = true;
        end
    elseif delta < 0 then
        if self.page < self.numPages then
            self.page = self.page + 1;
            valid = true;
        end
    end

    if valid then
        self:UpdatePage();
    end
end

function NarciPhotoModeOutfitSelectMixin:OnEvent(event)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not (self:IsMouseOver(8, 0, -4, 4) or self.parentSwitch:IsMouseOver()) then
            self:HideUI();
        end
    elseif event == "TRANSMOG_OUTFITS_CHANGED" then
        OutfitDataProvider:OnTransmogOutfitsChanged();
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        CharacterProfile:SaveOutfits();
    elseif event == "PLAYER_LOGOUT" then
        self:UnregisterEvent(event);
        CharacterProfile:SaveOutfits();
    end
end

function NarciPhotoModeOutfitSelectMixin:ToggleUI()
    if self:IsShown() then
        self:HideUI();
    else
        self:ShowUI();
    end
end

function NarciPhotoModeOutfitSelectMixin:ShowUI()
    self:Show();
    self:SetAlpha(0);
    self.t = 0;
    self:SetScript("OnUpdate", AnimOpen_OnUpdate);
end

function NarciPhotoModeOutfitSelectMixin:HideUI()
    self:Hide();
end


--/script local a={0,84,1};local i=1;local m=Narci.ActiveModel;m:SetScript("OnAnimFinished",function(m)i=i+1;if a[i] then m:SetAnimation(a[i]) else m:SetScript("OnAnimFinished",nil)end end);m:SetAnimation(a[1]);
--/script for k, v in pairs(BW) do if type(v) == "function" then print(k) end end

--[[
BetterWardrobe_SavedSetData.global.sets.[name - server].sources     --Blizzard Outfit
BetterWardrobe_ListData.OutfitDB.char.[name - server].outfits       --SavedExtra (mainHandEnchant, offHandEnchant, offShoulder)

--]]