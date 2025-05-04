local UPDATE_PORTRAIT_DELAY = 0.2;


local _, addon = ...

local API = addon.API;
local StatManager = addon.StatManager;
local HotkeyManager = addon.HotkeyManager;
local GetPortraitCameraInfoByModelFileID = API.GetPortraitCameraInfoByModelFileID;
local FormatPlayerName = API.FormatPlayerName;

local FadeFrame = NarciFadeUI.Fade;
local TransitionAPI = NarciAPI.TransitionAPI;

local C_BarberShop = C_BarberShop;
local SetCustomizationChoice = C_BarberShop.SetCustomizationChoice;
--C_BarberShop.SetViewingChrModel(chrModelID)   New API for Dragon Customization

local After = C_Timer.After;
local sin = math.sin;
local cos = math.cos;
local pi = math.pi;
local sqrt = math.sqrt;
local abs = math.abs;
local tremove = table.remove;
local tinsert = table.insert;
local unpack = unpack;
local wipe = wipe;
local tostring = tostring;

local IsMouseButtonDown = IsMouseButtonDown;
local GetMouseFocus = NarciAPI.TransitionAPI.GetMouseFocus;
local PlaySound = PlaySound;
local CreateFrame = CreateFrame;

local function IsWidgetFocused(widget1, widget2)
    local focus = GetMouseFocus();
    if widget2 then
        return focus == widget1 or focus == widget2
    elseif widget1 then
        return focus == widget1
    end
end

local function linear(t, b, e, d)
	return (e - b) * t / d + b
end

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end


local L = Narci.L;
-----------------------------------------------

local MainFrame, ScrollModelFrame, EditButton, EditBox, DeleteButton, PlusButton, SettingFrame, SettingButton, LoadingFrame, SavedLookButtons, WidgetTooltip;
local BarberShopUI; --Blizzard BarberShopUI


local HAS_ALTERNATE_FORM = false;
local IN_ALTERNATE_FORM = false;    --For worgen, human form is the alternate form
local IS_SAVE_SUPPORTED = true;     --Disable saves for non-Moonkin Shapeshifts

local RACE_WITH_ALTERNATE_FORM = {
    [22] = "human",       --worgen
    [52] = "bloodelf",    --dracthyr
    [70] = "bloodelf",    --dracthyr
};


local function UpdatePortraitCamera(model)
    local fileID = model:GetModelFileID();
    local cameraInfo = GetPortraitCameraInfoByModelFileID(fileID);
    if cameraInfo then
        local modelX, modelY, modelZ, modelYaw = unpack(cameraInfo);
        model:MakeCurrentCameraCustom();
        model:SetFacing(modelYaw);
        model:SetPosition(modelX, modelY, modelZ);
        local cameraX, cameraY, cameraZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 4, 0, 0);
        local targetX, targetY, targetZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 0, 0, 0);
        TransitionAPI.SetCameraPosition(model, cameraX, cameraY, cameraZ);
        TransitionAPI.SetCameraTarget(model, targetX, targetY, targetZ);

        return true
    else
        return false
    end
end


local ModelPool = {};
ModelPool.pools = {};

function ModelPool:Init()
    local f = CreateFrame("Frame", nil, MainFrame);
    f:SetSize(8, 8);
    f:SetPoint("TOP", MainFrame, "BOTTOM", 0, -8);
    f:Hide();
    self.container = f;
end

local function PortaitModel_OnModelLoaded(self)
    self:SetCamera(0);
    self:SetAnimation(0, 0);
    self:SetPaused(true);
    self:SetPortraitZoom(0.975);
    self:SetPortraitZoom(1);
    self.isModelLoaded = true;
    self:SetIgnoreParentAlpha(true);
    LoadingFrame:LoadNextPortrait(self.parentButton.order);
    UpdatePortraitCamera(self);
end

function ModelPool.SetupModel(model)
    model:SetSize(56, 56);
    model:SetUnit("player");
    model:SetKeepModelOnHide(true);
    model:SetFacing(pi/24);
    model:SetCamera(0);
    model:SetPortraitZoom(1);
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    model:SetScript("OnModelLoaded", PortaitModel_OnModelLoaded);
    model:SetViewTranslation(0, 0);
    TransitionAPI.SetModelLight(model, true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
end

function ModelPool:SetActiveModelPool(poolID)
    self:ReleaseModels();
    if not self.pools[poolID] then
        self.pools[poolID] = {};
    end
    self.activeModelPool = self.pools[poolID];
end

function ModelPool:AcquireModel(identifier)
    if not self.activeModelPool[identifier] then
        self.activeModelPool[identifier] = CreateFrame("PlayerModel", nil, self.container);
        self.SetupModel( self.activeModelPool[identifier] );
    end
    return self.activeModelPool[identifier]
end

function ModelPool:ReleaseModels()
    if self.activeModelPool then
        for _, model in pairs(self.activeModelPool) do
            model:Hide();
            model:ClearAllPoints();
            model:SetParent(self.container);
            model:SetPoint("TOP", self.container, "TOP", 0, 0);
        end
    end
end

function ModelPool:AssignModelToButton(savedLookButton, identifier)
    local model = self:AcquireModel(identifier);
    model:ClearAllPoints();
    model:SetPoint("CENTER", savedLookButton.Border, "CENTER", 0, 0);
    model:SetParent(savedLookButton);
    model:SetFrameLevel(savedLookButton:GetFrameLevel());
    model:Show();
    model.parentButton = savedLookButton;
    savedLookButton.Model = model;
end

function ModelPool:WipeAllModels()
    for poolID, modelPool in pairs(self.pools) do
        for identifier, model in pairs(modelPool) do
            model:ClearModel();
            model:Hide();
            model:ClearAllPoints();
            model:SetParent(self.container);
            model:SetPoint("TOP", self.container, "TOP", 0, 0);
            model.isModelLoaded = nil;
        end
    end
end


local ALTERNATE_FORM_SAVED_ID = "alternateForm";   --OLD:220 (number)
local MAX_SAVES = 20;
local NUM_ACTIVE_BUTTONS = 0;
local SCROLLFRAME_CENTER_Y;

local function UpdateScrollButtonAlpha(buttons)
    local button;
    local alpha;
    local x, y, dy;

    for i = 1, NUM_ACTIVE_BUTTONS do
        button = buttons[i];
        x, y = button:GetCenter();
        dy = abs(y - SCROLLFRAME_CENTER_Y);
        if dy < 128 then
            alpha = 1;
            button:Show();
        else
            alpha = 1 - (dy - 128)/64;
            if alpha < 0 then
                alpha = 0;
                button:Hide();
            else
                button:Show();
                if alpha > 1 then
                    alpha = 1;
                end
            end
        end
        button:SetButtonAlpha(alpha);
    end
end

local ScrollButtonAlphaUpdater = CreateFrame("Frame");
ScrollButtonAlphaUpdater:Hide();
ScrollButtonAlphaUpdater.t = 0;
ScrollButtonAlphaUpdater.duration = 1/60;
ScrollButtonAlphaUpdater:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.duration then
        self.t = 0;
        UpdateScrollButtonAlpha(self.activeButtons);
    end
end);

function ScrollButtonAlphaUpdater:Start()
    self:Show();
end

function ScrollButtonAlphaUpdater:Stop()
    self:Hide();
end

function ScrollButtonAlphaUpdater:Refresh()
    UpdateScrollButtonAlpha(self.activeButtons);
end

function ScrollButtonAlphaUpdater:SetActiveButtonAlpha(alpha)
    for i = 1, NUM_ACTIVE_BUTTONS do
        self.activeButtons[i]:SetButtonAlpha(alpha);
    end
end

local ScrollBoundMarkUpdater = CreateFrame("Frame");
ScrollBoundMarkUpdater:Hide();
ScrollBoundMarkUpdater.t = 0;
ScrollBoundMarkUpdater.duration = 0.2;
ScrollBoundMarkUpdater.lastAlpha = 0;
ScrollBoundMarkUpdater:SetScript("OnUpdate", function(self, elapsed)
    local alpha = self.lastAlpha + 2 * elapsed;
    self.lastAlpha = alpha;
    if alpha >= self.toAlpha then
        alpha = self.toAlpha;
        self:Hide();
    end
    self.object1:SetAlpha(alpha);
    self.object2:SetAlpha(alpha);
end);

function ScrollBoundMarkUpdater:Start()
    self.lastAlpha = 0; --self.object1:GetAlpha();
    self.toAlpha = 0.5;
    self:Show();
end

function ScrollBoundMarkUpdater:Stop()
    self:Hide();
end

local function UpdateScrollBoundMark(ScrollFrame)
    local scrollValue = ScrollFrame.scrollBar:GetValue();
    local a, b = ScrollFrame.scrollBar:GetMinMaxValues();
    local isTop = scrollValue <= 0.1;
    local isBottom = scrollValue + 0.1 >= b;
    local numButtons = NUM_ACTIVE_BUTTONS or 0;
    ScrollFrame.BoundTop:SetShown(not isTop);
    ScrollFrame.BoundBottom:SetShown(not isBottom);
    
    ScrollFrame.BoundTop:SetAlpha(0);
    ScrollFrame.BoundBottom:SetAlpha(0);
    
    ScrollBoundMarkUpdater:Start();
end

local function UpdateScrollRange(initialOffset)
    local scrollFrame = ScrollModelFrame;

    local range;
    local numButtons = NUM_ACTIVE_BUTTONS;

    if numButtons == 0 then
        range = 0;
    else
        range = (64 + 16) * numButtons -16 - scrollFrame:GetHeight() + 14;   --the active sex is not neccessarily male, just use the male buttons for height referencing
        if range < 0 then
            range = 0;
        end
    end

    local scrollBar = scrollFrame.scrollBar;
    scrollBar:SetMinMaxValues(0, range);
    scrollFrame.range = range;
    scrollBar:SetShown(range ~= 0);

    ScrollModelFrame:SnapToOffset(initialOffset or 0);

    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
    UpdateScrollBoundMark(scrollFrame);

    if numButtons >= MAX_SAVES then
        PlusButton:SetCase(3);
    end
    PlusButton.numSaves = numButtons;
end

local function CreateSavedLooksButton(scrollFrame, sex, isAlternateForm)
    local button;
    local buttons = {};
    local scrollChild = scrollFrame.ScrollChild;
    local buttonHeight = 64;
    local frameHeight = 4 * (buttonHeight + 16) - 2;
    scrollFrame:SetSize(280, frameHeight);
    scrollChild:SetSize(280, frameHeight);

    for i = 1, MAX_SAVES do
        button = CreateFrame("Button", nil, scrollFrame.ClipFrame, "NarciBarberShopSavedLooksTemplate");
        tinsert(buttons, button);
        button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button.order = i;
        button:Hide();
    end

    local deltaRatio = 1;
    local speedRatio = 0.14;
    local range = buttons[1]:GetTop() - buttons[MAX_SAVES]:GetBottom() - scrollFrame:GetHeight() + 14;
    local parentScrollFunc;
    local positionFunc = function(endValue, delta, scrollBar, isTop, isBottom)
        ScrollButtonAlphaUpdater:Start();
        scrollFrame.BoundTop:SetShown(not isTop);
        scrollFrame.BoundBottom:SetShown(not isBottom);
        ScrollBoundMarkUpdater:Stop();
        scrollFrame.BoundTop:SetAlpha(0.0);
        scrollFrame.BoundBottom:SetAlpha(0.0);
        scrollFrame.BoundTop:StopAnimating();
        scrollFrame.BoundBottom:StopAnimating();
    end;

    local onScrollFinishedFunc = function()
        ScrollButtonAlphaUpdater:Stop();
        ScrollBoundMarkUpdater:Start();
        scrollFrame.BoundTop.BoundTopArrow.spring:Play();
        scrollFrame.BoundBottom.BoundBottomArrow.spring:Play();
    end

    ScrollBoundMarkUpdater.object1 = scrollFrame.BoundTop;
    ScrollBoundMarkUpdater.object2 = scrollFrame.BoundBottom;

    NarciAPI_ApplySmoothScrollToScrollFrame(scrollFrame, deltaRatio, speedRatio, positionFunc, (buttonHeight + 16), range, parentScrollFunc, onScrollFinishedFunc);

    SavedLookButtons = buttons;
    ScrollButtonAlphaUpdater.activeButtons = buttons;
end


local DataProvider = {};
DataProvider.maleButtonOrder = {};
DataProvider.femaleButtonOrder = {};
DataProvider.alternateMaleButtonOrder = {};
DataProvider.alternateFemaleButtonOrder = {};

function DataProvider:GetCurrentSelection(customizationData, generateDescription)
    customizationData = customizationData or C_BarberShop.GetAvailableCustomizations();
    if not customizationData then
        return
    end
    local numCatetroy = #customizationData;
    local options, optionName, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local selectedOptions = {};
    local description = "";
    local addComma = false;

    local total = 0;

    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            optionName = options[j].name;
            optionID = options[j].id;
            cuurentChoiceIndex = options[j].currentChoiceIndex or 1;
            choice = options[j].choices[cuurentChoiceIndex];
            choiceName = choice.name or "";
            choiceID = choice.id;
            tinsert(selectedOptions, {optionID, choiceID} );
            total = total + 1;
            if generateDescription then
                if choiceName ~= "" and choiceName ~= "None" then
                    if addComma then
                        description = description..", ";
                    else
                        addComma = true;
                    end
                    description = description.. choiceName.." "..optionName;
                end
            end
        end
    end

    return selectedOptions, description
end

--sex 0 - Male 1- Female C_BarberShop.SetSelectedSex;

local RaceAtlas = {};

RaceAtlas.fixedRaceAtlasNames = {
    ["highmountaintauren"] = "highmountain",
    ["lightforgeddraenei"] = "lightforged",
    ["scourge"] = "undead",
    ["zandalaritroll"] = "zandalari",
};

RaceAtlas.alternateFormAtlasNames = {
    ["dracthyr"] = "dracthyrvisage",    --visage
    ["worgen"] = "human",
};

RaceAtlas.fixedModelAtlasNames = {
    --chrModelID
    [124] = "dragonriding-barbershop-icon-protodrake",
    [129] = "dragonriding-barbershop-icon-pterrodax",
    [123] = "dragonriding-barbershop-icon-drake",
    [126] = "dragonriding-barbershop-icon-wyvernspirit",
    --10.1.0
    [125] = "dragonriding-barbershop-icon-slitherdrake",
    --10.2.0
    [149] = "dragonriding-barbershop-icon-netherwingdrake",
    [188] = "dragonriding-barbershop-icon-faeriedragon",
    --11.1.5
    [202] = "dragonriding-barbershop-icon-delvesairship",
    [206] = "dragonriding-barbershop-icon-delvesairshipgoblin",
    [212] = "chihuahua-barbershop-icon",
};

function RaceAtlas:GetAtlas(raceName, gender, alternateForm)
    if self.fixedModelAtlasNames[raceName] then
        return self.fixedModelAtlasNames[raceName]
    end

    if alternateForm and self.alternateFormAtlasNames[raceName] then
        raceName = self.alternateFormAtlasNames[raceName];
    end

    if (self.fixedRaceAtlasNames[raceName]) then
        raceName = self.fixedRaceAtlasNames[raceName];
    end

    if not raceName then
        raceName = "human";
    end

    gender = gender or "none";

    local formatingString = "raceicon128-%s-%s";    --"raceicon-%s-%s"
    return formatingString:format(raceName, gender);
end

--[[
local f = CreateFrame("Frame");
f:SetSize(96, 96);
f:SetPoint("CENTER", 0, 0);
local tex = f:CreateTexture(nil, "OVERLAY");
tex:SetAllPoints(true);
tex:SetAtlas( RaceAtlas:GetAtlas("dracthyr", "male", true, true) )
--]]


local function SetUpSavedLooksButton(dataSource, atlas)
    local numActiveButtons = #dataSource;
    local numVisibleButtons = math.min(4, numActiveButtons);
    for i, button in ipairs(SavedLookButtons) do
        if i <= numVisibleButtons then
            button:Show();
        else
            button:Hide();
        end
        button:SetInfo(dataSource[i]);
        button.Portrait:SetAtlas(atlas);
        if button:IsPortraitLoaded() then
            button.Portrait:Hide();
        else
            button.Portrait:Show();
        end
    end
end

function DataProvider:SetActiveDatabase(key1, key2)
    --key1: race, key2: sex

    if not key1 then
        key1 = self.raceID;
    end

    if not self.activeAppearanceDB[key1] then
        self.activeAppearanceDB[key1] = {};
    end

    if key2 then
        if not self.activeAppearanceDB[key1][key2] then
            self.activeAppearanceDB[key1][key2] = {};
        end
        self.activeDB = self.activeAppearanceDB[key1][key2];
    else
        self.activeDB = self.activeAppearanceDB[key1];
    end

    self.dbKey1 = key1;
    self.dbKey2 = key2;

    return self.activeDB
end

function DataProvider:GetActiveDatabase()
    return self.activeDB
end

function DataProvider:GetActiveNumSaves()
    if self.activeDB then
        return #self.activeDB;
    else
        return 0
    end
end

local function GetRaceFileName(characterData)
    local fileName;
    if characterData then
        if characterData.raceData then
            fileName = characterData.raceData.fileName;
        else
            fileName = characterData.fileName;
        end
    end
    return fileName or "human";
end

function DataProvider:LoadData()
    if not NarciBarberShopDB then
        NarciBarberShopDB = {};
    end

    local DB = NarciBarberShopDB;

    --wipe(DB) --!!TEST

    if not DB.PlayerData then
        DB.PlayerData = {};
    end
    self.allPlayerData = DB.PlayerData;

    if not DB.SharedSavedLooks then
        DB.SharedSavedLooks = {};
    end

    local unitType, realmID, playerID = string.split("-", UnitGUID("player"));

    if not DB.PlayerData[playerID] then
        DB.PlayerData[playerID] = {
            SavedLooks = {},
            realmID = realmID,
            playerName = UnitName("player"),
            realmName = GetRealmName(),
            usePublicProfile = nil,
        };
    end

    local playerDB = DB.PlayerData[playerID];
    self.currentPlayerDB = playerDB;
    self.currentPlayerID = playerID;

    local _, classID = UnitClassBase("player");
    playerDB.classID = classID;

    self.sharedAppearanceDB = DB.SharedSavedLooks;
    self.playerAppearanceDB = DB.PlayerData[playerID].SavedLooks;

    local activeAppearanceDB;

    if playerDB.usePublicProfile then
        activeAppearanceDB = self.sharedAppearanceDB;
    else
        activeAppearanceDB = self.playerAppearanceDB;
    end

    self.activeAppearanceDB = activeAppearanceDB;

    local raceID = API.GetPlayerRaceID();
    self.raceID = raceID or 1;

    if not activeAppearanceDB[raceID] then
        activeAppearanceDB[raceID] = {male = {}, female = {}};
    end

    self.savedLooksByRace = activeAppearanceDB[raceID];

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    local raceName = GetRaceFileName(currentCharacterData);
    raceName = string.lower(raceName);

    CreateSavedLooksButton(ScrollModelFrame, "male");

    --Migrate Old Saves
    if activeAppearanceDB[220] then
        local function CopyTable(tbl)
            local copy = {};
            for k, v in pairs(tbl) do
                if type(v) == "table" then
                    copy[k] = CopyTable(v);
                else
                    copy[k] = v;
                end
            end
            return copy;
        end
        activeAppearanceDB[ALTERNATE_FORM_SAVED_ID] = CopyTable(activeAppearanceDB[220]);
        activeAppearanceDB[220] = nil;
    end


    --Worgen in human form. Dracthyr in visage form.
    if RACE_WITH_ALTERNATE_FORM[raceID] then
        HAS_ALTERNATE_FORM = true;
        local id = ALTERNATE_FORM_SAVED_ID;

        if not activeAppearanceDB[id] then
            activeAppearanceDB[id] = { male = {}, female = {} };
        end
        self.savedLooksInAlternateForm = activeAppearanceDB[id];
    end

    for i = 1, MAX_SAVES do
        self.maleButtonOrder[i] = i;
        self.femaleButtonOrder[i] = i;
        self.alternateMaleButtonOrder[i] = i;
        self.alternateFemaleButtonOrder[i] = i;
    end
end

function DataProvider:GetRandomAppearance()    --Unused
    local customizationData = C_BarberShop.GetAvailableCustomizations();
    if not customizationData then    --Not at the Barber
        return
    end

    local random = math.random;
    local selectedOptions = {};

    local option, options, optionName, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local numCatetroy = #customizationData;
    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            option = options[j];
            optionName = option.name;
            optionID = option.id;
            local numChoices = #option.choices;
            choice = option.choices[ random(numChoices) ]
            choiceID = choice.id;
            tinsert(selectedOptions, {optionID, choiceID} );
        end
    end

    return selectedOptions
end

function DataProvider:IsNewLooksUnique()
    local newLooks, generatedDescription = DataProvider:GetCurrentSelection();
    if not newLooks then
        return
    end
    local checkOnly = true;
    local isUnique = self:CheckAndSaveLooks(newLooks, nil, nil, checkOnly);
    return isUnique
end

function DataProvider:IsCharacterDataUnique(customizationData)
    local newLooks = self:GetCurrentSelection(customizationData);
    local savedLooks = self:GetActiveDatabase();

    local isUnique = true;
    local tempTable = {};
    local numLooks = #savedLooks;
    local data;
    local matchID;
    local profileName;

    for i = 1, numLooks do
        wipe(tempTable);
        data = savedLooks[i].data;
        local numData = #data;
        for j = 1, numData do
            tempTable[ data[j][1] ] = data[j][2];
        end

        local numSame = 0;
        for j = 1, #newLooks do
            if tempTable[ newLooks[j][1] ] == newLooks[j][2] then
                numSame = numSame + 1;
            end
        end

        if numSame == numData then
            isUnique = false;
            matchID = i;
            profileName = savedLooks[i].name;
            break
        end
    end

    if IS_SAVE_SUPPORTED then
        if isUnique then
            if numLooks < MAX_SAVES then
                PlusButton:SetCase(1);
            else
                PlusButton:SetCase(3);
            end
        else
            PlusButton:SetCase(2);
        end
    end

    PlusButton.numSaves = numLooks;

    if SavedLookButtons then
        for i, portraitButton in ipairs(SavedLookButtons) do
            portraitButton:SetSelection(i == matchID);
        end
    end

    API.SetActiveAppearanceName(profileName);
end


function DataProvider:CheckAndSaveLooks(newLooks, generatedDescription, customName, checkOnly)
    if not newLooks then return false end;

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    if not currentCharacterData then return false end;

    local targetDB = self:GetActiveDatabase();

    local isUnique = true;
    local data;

    local tempTable = {};
    local numLooks = #targetDB;
    for i = 1, numLooks do
        wipe(tempTable);
        data = targetDB[i].data;
        local numData = #data;
        for j = 1, numData do
            tempTable[ data[j][1] ] = data[j][2];
        end

        local numSame = 0;
        for j = 1, #newLooks do
            if tempTable[ newLooks[j][1] ] == newLooks[j][2] then
                numSame = numSame + 1;
            end
        end

        if numSame == numData then
            isUnique = false;
            break
        end
    end

    wipe(tempTable);
    numLooks = numLooks + 1;

    if numLooks > MAX_SAVES then
        return false
    end

    local looksName = customName or ("New Look #"..(numLooks));
    if isUnique then
        if checkOnly then
            return true;
        else
            if numLooks < MAX_SAVES then
                PlusButton:SetCase(2);
            else
                PlusButton:SetCase(3);
            end
            local currentTime = time();
            tinsert(targetDB, 1, {name = looksName , description = generatedDescription, data = newLooks, timeCreated = currentTime});
            return targetDB[1], numLooks
        end
    else
        PlusButton:SetCase(2);
    end
    PlusButton.numSaves = numLooks;
end

function DataProvider:SaveNewLooks(customName)
    if NUM_ACTIVE_BUTTONS >= MAX_SAVES then
        return
    end
    local generateDescription = true;
    local newLooks, generatedDescription = DataProvider:GetCurrentSelection(nil, generateDescription);
    local data, numLooks = self:CheckAndSaveLooks(newLooks, generatedDescription, customName);
    if data then
        NUM_ACTIVE_BUTTONS = numLooks;
        if numLooks >= 4 then
            ScrollBoundMarkUpdater:Start();
        end

        return data
    else

    end
end

local function RepositionButtons(buttonPool)
    local _, relativeTo = buttonPool[1]:GetPoint();
    local buttonHeight = 64;
    local button;
    for i = 1, MAX_SAVES do
        button = buttonPool[i];
        button:ClearAllPoints();
        button:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button.order = i;
    end
end

local function InsertButtonToTop(buttonPool, position)
    local removedButton = tremove(buttonPool, position);
    if removedButton then
        for i = #buttonPool, 1, -1  do
            buttonPool[i + 1] = buttonPool[i];
        end
        buttonPool[1] = removedButton;
        --RepositionButtons(buttonPool);
    end
end

function DataProvider:DeleteLooks(dataSource)
    if not dataSource then return end;

    local savedLooks = self:GetActiveDatabase();
    local numLooks = #savedLooks;
    local position;
    for i = 1, numLooks do
        if savedLooks[i] == dataSource then
            position = i;
            break
        end
    end
    if position then
        for i = position, numLooks do
            savedLooks[i] = savedLooks[i + 1];
        end

        local removedButton = tremove(SavedLookButtons, position);
        removedButton:RemovePortrait();
        removedButton.appearanceData = nil;
        tinsert(SavedLookButtons, removedButton);
        NUM_ACTIVE_BUTTONS = NUM_ACTIVE_BUTTONS - 1;

        local buttonPool = SavedLookButtons;
        return buttonPool, removedButton, position
    end
end

function DataProvider:GetButton()
    local numSaves = self:GetActiveNumSaves();
    local numNewSaves = numSaves + 1;
    if numNewSaves > MAX_SAVES then
        numNewSaves = MAX_SAVES;
    end
    InsertButtonToTop(SavedLookButtons, numNewSaves);
    return SavedLookButtons[1]
end

function DataProvider:IsUsingPublicProfile()
    return self.currentPlayerDB and self.currentPlayerDB.usePublicProfile
end

function DataProvider:SetUsePublicProfile(state)
    if self.currentPlayerDB then
        self.currentPlayerDB.usePublicProfile = state or false;

        if state then
            self.activeAppearanceDB = self.sharedAppearanceDB;
        else
            self.activeAppearanceDB = self.playerAppearanceDB;
        end
    end
end

function DataProvider:GetAppearanceByPlayerID(playerID)
    if self.dbKey1 and self.allPlayerData[playerID] then
        local looks = self.allPlayerData[playerID].SavedLooks;

        if looks[self.dbKey1] and self.dbKey2 then
            return looks[self.dbKey1][self.dbKey2];
        else
            return looks[self.dbKey1]
        end
    end
end

function DataProvider:GetAppearanceFromSharedDB()
    if self.dbKey1 then
        local tbl = self.sharedAppearanceDB;
        if tbl[self.dbKey1] and self.dbKey2 then
            return tbl[self.dbKey1][self.dbKey2];
        else
            return tbl[self.dbKey1]
        end
    end
end


function DataProvider:GetCharacterList()
    if not self.dbKey1 then return {} end;

    local tbl = {};
    local n = 0;
    local numLooks;
    local looks;

    for playerID, playerData in pairs(self.allPlayerData) do
        looks = self:GetAppearanceByPlayerID(playerID);
        numLooks = looks and #looks or 0;
        if numLooks > 0 then
            n = n + 1;
            tbl[n] = {
                playerID = playerID,
                playerName = playerData.playerName,
                realmName = playerData.realmName,
                numLooks = numLooks,
                classID = playerData.classID,
            };
        end
    end

    local function SortFunc(a, b)
        --Realm Name
        if a.realmName ~= b.realmName then
            return a.realmName < b.realmName
        end

        if a.playerName ~= b.playerName then
            return a.playerName < b.playerName
        end

        return a.playerID < b.playerID;
    end

    table.sort(tbl, SortFunc);

    return tbl
end

function DataProvider:GetNumLooksInSharedDB()
    local db = self:GetAppearanceFromSharedDB();
    local numSaves = db and #db or 0;
    return numSaves
end

function DataProvider:IsPublicProfileFull()
    return self:GetNumLooksInSharedDB() >= MAX_SAVES
end


local function SetFontStringShadow(fontString)
    fontString:SetShadowColor(0, 0, 0);
    fontString:SetShadowOffset(1, -1);
end

-------------------------------------------------------------

local CustomizationUtil = {};
CustomizationUtil.f = CreateFrame("Frame");

function CustomizationUtil.repeater_OnUpdate(f, elapsed)
    --Dracthyr Notes:
    --some options are only valid when certain options are selected
    --so we need to apply the same appearance profile again to ensure everything we need is selected
    --Arbitrarily use a 2-frame delay

    f.t = f.t + elapsed;

    if f.t > 0.033 then
        f:SetScript("OnUpdate", nil);
        for i = 1, #CustomizationUtil.appearanceData do
            local optionID, choiceID = unpack(CustomizationUtil.appearanceData[i]);
            SetCustomizationChoice(optionID, choiceID);
        end
        BarberShopUI:UpdateCharCustomizationFrame();
    end
end

function CustomizationUtil:UseCustomization(appearanceData)
    --appearanceData consisted of formated optionID-choiceID pairs
    if not appearanceData then return end;

    self.f:SetScript("OnUpdate", nil);
    self.appearanceData = appearanceData;

    local optionID, choiceID;
    for i = 1, #appearanceData do
        optionID, choiceID = unpack(appearanceData[i]);
        SetCustomizationChoice(optionID, choiceID);
    end

    self.f.t = 0;
    self.f:SetScript("OnUpdate", self.repeater_OnUpdate);
end

function CustomizationUtil:ApplyCustomizationCategoryData(customizationCategoryData, firstCall)
    --customizationCategoryData is the raw payload from C_BarberShop.GetAvailableCustomizations()
    local optionID, cuurentChoiceIndex, choice, choiceID;
    for i, data in ipairs(customizationCategoryData) do
        for j, option in ipairs(data.options) do
            optionID = option.id;
            cuurentChoiceIndex = option.currentChoiceIndex or 1;
            choice = option.choices[cuurentChoiceIndex];
            choiceID = choice.id;
            SetCustomizationChoice(optionID, choiceID);
        end
    end

    if firstCall then
        After(0.033, function()
            self:ApplyCustomizationCategoryData(customizationCategoryData);
            DataProvider:IsCharacterDataUnique();
        end);
    end
end


NarciBarberShopSavedLooksMixin = {};


function NarciBarberShopSavedLooksMixin:OnLoad()
    self.Portrait:SetVertexColor(0.5, 0.5, 0.5);
    self.Portrait:SetDesaturation(0.6);
    SetFontStringShadow(self.Description);
    self:OnLeave();
end


function NarciBarberShopSavedLooksMixin:RefreshPortrait(forcedRefresh)
    if (not self:IsPortraitLoaded()) or (forcedRefresh) then
        self.Model:Show();
        self.Portrait:Hide();
        self.PortraitText:Hide();
        self.isPortraitLoaded = true;
        self.Model:SetUnit("player");
    end
end

function NarciBarberShopSavedLooksMixin:UpdateText()
    local textHeight = self.Name:GetHeight() + self.Description:GetHeight() + 6;
    self.Reference:SetHeight(textHeight);
end

function NarciBarberShopSavedLooksMixin:SetInfo(dataSource)
    self.dataSource = dataSource;
    if dataSource then
        ModelPool:AssignModelToButton(self, tostring(dataSource.timeCreated));
        self.Name:SetText(dataSource.name);
        self.Description:SetText(dataSource.description);
        self.appearanceData = dataSource.data;
        self:UpdateText();
    end
end

function NarciBarberShopSavedLooksMixin:OnEnter()
    self.Name:SetAlpha(1);
    self.Description:SetAlpha(1);
    FadeFrame(self.BorderHighlight, 0.15, 1);
    MainFrame:FadeIn(0.2);
    --self.Model:SetPaused(false);  --Playing character idle animation seems distractive, disabled

    EditButton:SetParentObject(self);
    DeleteButton:SetParentObject(self);
end

function NarciBarberShopSavedLooksMixin:OnLeave()
    if self:IsMouseOver() and IsWidgetFocused(self) then
        return
    end
    self.Name:SetAlpha(0.66);
    self.Description:SetAlpha(0.66);
    FadeFrame(self.BorderHighlight, 0.25, 0);
    MainFrame:OnLeave();

    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopSavedLooksMixin:OnClick()
    --self:UseCustomization();
    CustomizationUtil:UseCustomization(self.appearanceData);

    if not self:IsPortraitLoaded() then
        After(UPDATE_PORTRAIT_DELAY, function()
            self:RefreshPortrait();
        end)
    end

    PlaySound(856); --SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
end

function NarciBarberShopSavedLooksMixin:RemovePortrait()
    if self.Model then
        self.Model.isModelLoaded = nil;
        self.Model:ClearModel();
    end
end

function NarciBarberShopSavedLooksMixin:IsPortraitLoaded()
    if self.Model then
        return self.Model.isModelLoaded
    end
end

function NarciBarberShopSavedLooksMixin:GetPortraitModel()
    return self.Model
end

function NarciBarberShopSavedLooksMixin:LoadPortrait()
    self:UseCustomization(true);
    if not self:IsPortraitLoaded() then
        After(UPDATE_PORTRAIT_DELAY, function()
            self:RefreshPortrait();
        end)
    end
end

function NarciBarberShopSavedLooksMixin:UseCustomization(dontUpdateButton)
    if not self.appearanceData then return end

    for i = 1, #self.appearanceData do
        local optionID, choiceID = unpack(self.appearanceData[i]);
        SetCustomizationChoice(optionID, choiceID);
        --C_BarberShop.PreviewCustomizationChoice(optionID, choiceID);
    end

    if not dontUpdateButton then
        --determine if it should update the option buttons on the right side of the screen
        BarberShopUI:UpdateCharCustomizationFrame();
    end
end

function NarciBarberShopSavedLooksMixin:SetSelection(state)
    if state then
        if not self.isSelected then
            self.isSelected = true;
            self.Border:SetTexCoord(0.5, 1, 0, 1);
        end
    else
        if self.isSelected then
            self.isSelected = nil;
            self.Border:SetTexCoord(0, 0.5, 0, 1);
        end
    end
end

if true then
    function NarciBarberShopSavedLooksMixin:SetButtonAlpha(alpha)
        --Dragonflight Beta: Model no longer inherts parent alpha.
        --Probably a driver issue that only took place in beta but still
        self:SetAlpha(alpha);
        if self.Model then
            self.Model:SetModelAlpha(alpha); --SetAlpha caused the model to flicker
        end
        self.buttonAlpha = alpha;
    end
else
    function NarciBarberShopSavedLooksMixin:SetButtonAlpha(alpha)
        self:SetAlpha(alpha);
    end
end


----------------------------------
local DURATION_FADE_OUT = 1.5;

local autoHideTimer = NarciAPI_CreateAnimationFrame(4);
autoHideTimer:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self.total = 0;
        if MainFrame:IsVisible() then
            if not MainFrame:IsMouseOver() then
                self:Hide();
                MainFrame:FadeOut(DURATION_FADE_OUT);
            end
        else
            self:Hide();
        end
    end
end)

local animScrollFrame = NarciAPI_CreateAnimationFrame(0.25);
animScrollFrame:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local offsetY = linear(self.total, self.fromY, 0, self.duration);
    if self.total >= self.duration then
        self:Hide();
        offsetY = 0;
        ScrollButtonAlphaUpdater:Stop();
        if self.onFinishedFunc then
            self.onFinishedFunc();
            self.onFinishedFunc = nil;
        end
    end
    self.parentScrollBar:SetValue(offsetY);
end);

function animScrollFrame:ScrollToTop(ScrollFrame)
    self:Hide();
    local value = ScrollFrame:GetVerticalScroll();
    if value == 0 then
        return
    end
    self.parentScrollBar = ScrollFrame.scrollBar;
    self.fromY = value;
    local duration = sqrt( value/ 400) * 0.25;
    self.duration = duration;
    ScrollButtonAlphaUpdater:Start();
    self:Show();
end


local animScrollButtons = NarciAPI_CreateAnimationFrame(0.4);

animScrollButtons:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local offsetY = outSine(self.total, self.fromY, self.toY, self.duration);

    if self.newButton then
        local alpha = self.total/0.35;
        if alpha > 1 then
            alpha = 1;
        end
        local offsetX = inOutSine(self.total, -32, 0, self.duration);
        self.newButton:Show();
        self.newButton:SetAlpha(alpha);
        if self.total >= self.duration then
            offsetX = 0;
            offsetY = self.toY;
        end
        self.newButton:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", offsetX, -8);
    end

    if self.oldButton then
        local alpha = 1 - self.total/0.35;
        
        if alpha < 0 then
            alpha = 0;
            self.oldButton:Hide();
        end
        local offsetX = outSine(self.total, 0, -120, self.duration);
        self.oldButton:SetAlpha(alpha);
        if self.total >= self.duration then
            offsetX = -64;
        end
        self.oldButton:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", offsetX, self.oldButtonPosY);
    end

    if self.forthButton then
        local alpha = self.fromAlpha - self.total/0.25;
        if alpha < 0 then
            alpha = 0;
        end
        self.forthButton:SetAlpha(alpha);
        if alpha == 0 then
            self.forthButton:Hide();
        end
    end

    if self.total >= self.duration then
        offsetY = self.toY;
        self:Hide();
        MainFrame.ScrollBlocker:Hide();
        RepositionButtons(self.buttonPool);
        UpdateScrollRange();
        ScrollButtonAlphaUpdater:Stop();
    end

    for i = self.buttonIndex, self.numButtons do
        self.buttonPool[i]:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", 0, -8 + 80*(1 - i) + offsetY);
    end
end)

function animScrollButtons:InsertNewButton(buttonPool, newButton)
    self:Hide();
    local _, ScrollChild = buttonPool[1]:GetPoint();
    self.relativeTo = ScrollChild;
    self.buttonPool = buttonPool;
    self.numButtons = #buttonPool;
    self.buttonIndex = 2;
    self.newButton = newButton;
    self.forthButton = buttonPool[5];
    self.oldButton = nil;
    self.fromAlpha = self.forthButton:GetAlpha();
    self.fromY = 80;
    self.toY = 0;

    local ScrollFrame = ScrollChild:GetParent();
    if ScrollFrame:GetVerticalScroll() > 0.1 then
        --ScrollFrame.scrollBar:SetValue(0);
        animScrollFrame.onFinishedFunc = function()
            self:Show();
            EditBox:SetParentObject(newButton, true);
        end
        animScrollFrame:ScrollToTop(ScrollFrame);
    else
        self:Show();
    end
    MainFrame.ScrollBlocker:Show();
end

function animScrollButtons:RemoveOldButton(buttonPool, button)
    self:Hide();
    self.forthButton = nil;
    self.newButton = nil;
    self.oldButton = button;
    local _, ScrollChild, _, _, posY = button:GetPoint();
    self.oldButtonPosY = posY;
    self.buttonIndex = button.order;
    self.relativeTo = ScrollChild;
    self.buttonPool = buttonPool;
    self.numButtons = #buttonPool - 1;
    self.fromY = -80;
    self.toY = 0;
    self:Show();
    ScrollButtonAlphaUpdater:Start();
    MainFrame.ScrollBlocker:Show();
end


--Click to save new looks
NarciBarberShopPlusButtonMixin = {};

function NarciBarberShopPlusButtonMixin:OnLoad()
    PlusButton = self;
    self:OnLeave();
    self.tooltipDefault = L["Save New Look"];
    self.tooltipReachMax = L["No Available Slot"];
    self.tooltipSaved = L["Look Saved"];
    self.tooltipShapeShifted = L["Cannot Save Forms"];
    self:SetCase(1);
end

function NarciBarberShopPlusButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self.Background:SetTexCoord(0.25, 0.5, 0, 1);
    end
end

function NarciBarberShopPlusButtonMixin:OnMouseUp()
    if self:IsEnabled() then
        self.Background:SetTexCoord(0, 0.25, 0, 1);
    end
end

function NarciBarberShopPlusButtonMixin:OnEnable()
    self.Background:SetTexCoord(0, 0.25, 0, 1);
    self.Label:SetTextColor(1, 1, 1);
    self.Label:SetAlpha(0.66);
end

function NarciBarberShopPlusButtonMixin:OnDisable()
    self.Background:SetTexCoord(0.5, 0.75, 0, 1);
    self.Label:SetTextColor(0.5, 0.5, 0.5);
end

function NarciBarberShopPlusButtonMixin:SetCase(caseID)
    if caseID == 1 then
        --Can be added
        self.Label:SetText(self.tooltipDefault);
        self:Enable();
    elseif caseID == 2 then
        --Already saved
        self.Label:SetText(self.tooltipSaved);
        self:Disable();
    elseif caseID == 3 then
        --Cannot save more
        self.Label:SetText(self.tooltipReachMax);
        self:Disable();
    elseif caseID == 4 then
        --Cannot add shapes
        self.Label:SetText(self.tooltipShapeShifted);
        self:Disable();
    end

    self.caseID = caseID;
end

function NarciBarberShopPlusButtonMixin:GetCase()
    return self.caseID
end

function NarciBarberShopPlusButtonMixin:OnEnter()
    self.Label:SetAlpha(1);
    MainFrame:OnEnter();
    EditButton:Hide();
    DeleteButton:Hide();

    local labelWidth = self.Label:GetWrappedWidth();
    self.Count:SetPoint("LEFT", self.Label, "LEFT", labelWidth + 8, 0);

    if IS_SAVE_SUPPORTED then
        if self.numSaves then
            self.Count:SetText(self.numSaves.." / "..MAX_SAVES);
            self.Count:Show();
        else
            self.Count:Hide();
        end
    end
end

function NarciBarberShopPlusButtonMixin:OnLeave()
    self.Label:SetAlpha(0.66);
    self.Count:Hide();
end

local function SaveCurrentAppearance(customName)
    if not PlusButton:IsEnabled() then return end;

    local data = DataProvider:SaveNewLooks(customName);
    if data then
        local button = DataProvider:GetButton();
        if button then
            animScrollButtons:InsertNewButton(SavedLookButtons, button);
            button:SetInfo(data);
            button:Show();
            button.Portrait:Show();
            EditBox:SetParentObject(button, true);
            After(UPDATE_PORTRAIT_DELAY, function()
                button:RefreshPortrait(true);
                button:SetSelection(true);
            end);
        end
        MainFrame:FadeIn(0.2);
        return true
    end
end


API.SaveCurrentAppearance = SaveCurrentAppearance;

function NarciBarberShopPlusButtonMixin:OnClick()
    --Save new Looks
    SaveCurrentAppearance();
    PlaySound(856);
end

function NarciBarberShopPlusButtonMixin:Glow()
    self.GlowTexture.AnimGlow:Play();
    self.GlowTexture:Show();
    PlaySound(23404)
end


NarciBarberShopEditButtonMixin = {};

function NarciBarberShopEditButtonMixin:OnLoad()
    EditButton = self;
    self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    self.Ring:SetVertexColor(0.8, 0.8, 0.8);
    self.Tooltip:SetText(L["Edit Name"]);
    SetFontStringShadow(self.Tooltip);
end

function NarciBarberShopEditButtonMixin:SetParentObject(object)
    self:ClearAllPoints();
    self:SetParent(object);
    self:SetPoint("BOTTOMRIGHT", object, "RIGHT", 0, 0);
    self:Show();
end

function NarciBarberShopEditButtonMixin:EditName()
    EditBox:SetParentObject(self:GetParent());
end

function NarciBarberShopEditButtonMixin:OnClick()
    self:EditName();
    PlaySound(856);
end

function NarciBarberShopEditButtonMixin:OnEnter()
    self:GetParent():OnEnter();
    self.Tooltip:Show();
    self.Ring:Show();
end

function NarciBarberShopEditButtonMixin:OnLeave()
    MainFrame:OnLeave();
    self:GetParent():OnLeave();
    self.Tooltip:Hide();
end

function NarciBarberShopEditButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
    self.Tooltip:Hide();
    self:UnlockHighlight();
    self.Ring:Hide();
end

function NarciBarberShopEditButtonMixin:OnMouseDown()
    self.Icon:SetSize(16, 16);
end

function NarciBarberShopEditButtonMixin:OnMouseUp()
    self.Icon:SetSize(20, 20);
end


NarciBarberShopDeleteButtonMixin = {};

function NarciBarberShopDeleteButtonMixin:OnLoad()
    DeleteButton = self;
    self.Icon:SetTexCoord(0, 0.25, 0, 1);
    self.Ring:SetTexCoord(0.25, 0.5, 0, 1);
    self.Ring:SetVertexColor(0.85, 0, 0);
    self.SemiCircleRight:SetVertexColor(0.85, 0, 0);
    self.SemiCircleLeft:SetVertexColor(0.85, 0, 0);
    self.Tooltip:SetText(L["Delete Look"]);
    self.Tooltip:SetTextColor(1, 0.31, 0.31);
    SetFontStringShadow(self.Tooltip);

    --self.Ring:SetDrawLayer("BORDER");
end

function NarciBarberShopDeleteButtonMixin:SetParentObject(object)
    self:SetParent(object);
    self:Show();
    self:OnMouseUp();
end

function NarciBarberShopDeleteButtonMixin:OnClick()
    PlaySound(856);
end

function NarciBarberShopDeleteButtonMixin:OnLongClick()
    local buttonPool, removedButton = DataProvider:DeleteLooks(self:GetParent().dataSource);
    if buttonPool then
        DataProvider:IsCharacterDataUnique();
        animScrollButtons:RemoveOldButton(buttonPool, removedButton);
    end
end

function NarciBarberShopDeleteButtonMixin:OnEnter()
    self:GetParent():OnEnter();
    self.Tooltip:Show();
    self.Ring:Show();
end

function NarciBarberShopDeleteButtonMixin:OnLeave()
    MainFrame:OnLeave();
    self:GetParent():OnLeave();
    self.Tooltip:Hide();
end

function NarciBarberShopDeleteButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
    self.Tooltip:Hide();
    self.Ring:Hide();
    self:UnlockHighlight();
end

function NarciBarberShopDeleteButtonMixin:OnMouseDown()
    self.Icon:SetSize(14, 14);
    self:LockHighlight();
    self.SemiCircleLeft:Show();
    self.SemiCircleRight:Show();
    self.SemiCircleLeft.rotation:Play();
    self.SemiCircleRight.rotation:Play();
    self.Ring:SetVertexColor(0.25, 0, 0);
end

function NarciBarberShopDeleteButtonMixin:OnMouseUp()
    self.Icon:SetSize(20, 20);
    self:UnlockHighlight();
    self.SemiCircleRight:Hide();
    self.SemiCircleLeft:Hide();
    self:StopAnimating();
    self.Ring:SetVertexColor(0.85, 0, 0);
end


NarciBarberShopEditBoxMixin = {};

function NarciBarberShopEditBoxMixin:OnLoad()
    EditBox = self;
end

function NarciBarberShopEditBoxMixin:SetParentObject(object, alsoHighlightText)
    if self.parentObject then
        self.parentObject.Name:Show();
        self.parentObject:OnLeave();
    end
    self:ClearAllPoints();
    self:SetParent(object);
    self:SetPoint("LEFT", object.Name, "LEFT", 0, 0);
    self:SetText(object.Name:GetText());
    self:Show();
    self.parentObject = object;
    object.Name:Hide();
    if alsoHighlightText then
        After(0, function()
            self:HighlightText();
        end)
    end
end

function NarciBarberShopEditBoxMixin:OnEscapePressed()
    self.exitByPressingEscape = true;
    self:DiscardChanges();
end

function NarciBarberShopEditBoxMixin:OnEnterPressed()
    self:ConfirmChanges();
end

function NarciBarberShopEditBoxMixin:OnTextChanged()
    local remainingLetters = 36 - self:GetNumLetters(true);
    self.LetterCount:SetText(remainingLetters);
    if remainingLetters == 0 then
        self.LetterCount:SetTextColor(0.85, 0, 0);
    elseif remainingLetters <= 12 then
        self.LetterCount:SetTextColor(0.96, 0.64, 0.13);
    else
        self.LetterCount:SetTextColor(0.66, 0.66, 0.66);
    end
end

function NarciBarberShopEditBoxMixin:DiscardChanges()
    self:Hide();
end

function NarciBarberShopEditBoxMixin:ConfirmChanges()
    local text = strtrim(self:GetText() or "");
    if text ~= "" then
        self.parentObject.Name:SetText(text);
        self.parentObject:UpdateText();
        self.parentObject.dataSource.name = text;
    end
    self:Hide();
end

function NarciBarberShopEditBoxMixin:OnShow()
    self:SetFocus();
    self:SetCursorPosition(100);
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopEditBoxMixin:OnHide()
    self:HighlightText(0, 0);
    self:ClearFocus();
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    if self.parentObject then
        self.parentObject.Name:Show();
        self.parentObject:OnLeave();
    end
end

function NarciBarberShopEditBoxMixin:OnEditFocusGained()
    autoHideTimer:Hide();
end

function NarciBarberShopEditBoxMixin:OnEditFocusLost()
    if self.exitByPressingEscape then
        self.exitByPressingEscape = nil;
        self:Hide();
    else
        self:ConfirmChanges();
    end
    autoHideTimer:Show();
end

function NarciBarberShopEditBoxMixin:OnEvent()
    if not self:IsMouseMotionFocus() then
        self:Hide();
    end
end

----------------------------------

NarciBarberShopMixin = {};

function NarciBarberShopMixin:OnLoad()
    MainFrame = self;
    WidgetTooltip = self.WidgetTooltip;
    ScrollModelFrame = self.SavedLooksFrame.ScrollModelFrame;
    ScrollBoundMarkUpdater.object1 = ScrollModelFrame.BoundTop;
    ScrollBoundMarkUpdater.object2 = ScrollModelFrame.BoundBottom;
    self.fadeController = CreateFrame("Frame", nil, self);
end

local function FadeController_OnUpdate(self, elapsed)
    self.alpha = self.alpha + self.fadeSpeed*elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    elseif self.alpha <= 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
    end
    MainFrame:SetFrameAlpha(self.alpha);
end

function NarciBarberShopMixin:SetFrameAlpha(alpha)
    --temp fix for "Model Widgets Not Inherit Parent's Alpha"
    self:SetAlpha(alpha);
    ScrollButtonAlphaUpdater:SetActiveButtonAlpha(alpha);
end

function NarciBarberShopMixin:FadeIn(fullDuration)
    local alpha = self:GetAlpha();
    if alpha == 1 then
        self.fadeController:SetScript("OnUpdate", nil);
        return
    end
    self.fadeController.fadeSpeed = 1/fullDuration;
    self.fadeController.alpha = alpha;
    self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
end

function NarciBarberShopMixin:FadeOut(fullDuration)
    local alpha = self:GetAlpha();
    if alpha == 0 then
        self.fadeController:SetScript("OnUpdate", nil);
        return
    end
    self.fadeController.fadeSpeed = -1/fullDuration;
    self.fadeController.alpha = alpha;
    self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
    EditBox:Hide();
end

function NarciBarberShopMixin:OnKeyDown(key)
    if HotkeyManager:RunCommandByKeyState(key, true) then
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:ToggleNotification(state)
    self.checkUniqueness = state;
end

function NarciBarberShopMixin:ToggleRandomizeAppearanceButton(visible)
    --Deprecated
    --"Random" button is enabled by Blizzard
    local button = CharCustomizeFrame.RandomizeAppearanceButton;
    if button then
        button:SetShown(visible);
    end
end

function NarciBarberShopMixin:OnKeyUp(key)
    if HotkeyManager:RunCommandByKeyState(key, false) then
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:OnShow()
    local _;
    _, SCROLLFRAME_CENTER_Y = ScrollModelFrame:GetCenter();
    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
end

function NarciBarberShopMixin:OnHide()
    ScrollButtonAlphaUpdater:Stop();
    HotkeyManager:StopMovingCamera();
    autoHideTimer:Hide();
end

function NarciBarberShopMixin:OnEnter()
    self:FadeIn(0.2);
end

function NarciBarberShopMixin:OnLeave()
    if not self:IsMouseOver() and not IsMouseButtonDown() then
        autoHideTimer:Show();
    end
end

function NarciBarberShopMixin:ToggleSaves(savable)
    --For Shapeshifter
    if savable then
        self.SavedLooksFrame:Show();
        self:FadeIn(0.2);
    else
        PlusButton:SetCase(4);
        self.SavedLooksFrame:Hide();
        self:SetAlpha(0);
    end

    IS_SAVE_SUPPORTED = savable;
end

local SCROLL_OFFSETS = {};  --Used to preserve the scroll offset of the old category

function NarciBarberShopMixin:UpdateCategory(sex, raceName)
    self.currentCategorySex = sex;
    self.currentCategoryRaceName = raceName;

    self:FadeIn(0.2);
    autoHideTimer:Hide();
    autoHideTimer:Show();

    local modelPoolID;
    local databaseKey, sexKey;

    local chrModelID = C_BarberShop.GetViewingChrModel();

    if chrModelID then
        --Dragonriding / Druid Forms
        modelPoolID = chrModelID;
        raceName = chrModelID;
        databaseKey = "chrModel"..chrModelID;
    else
        if not (sex and raceName) then
            local currentCharacterData =  C_BarberShop.GetCurrentCharacterData();
            if currentCharacterData then
                sex = currentCharacterData.sex;
                raceName = GetRaceFileName(currentCharacterData);
            else
                print("Error: No Character Data");
                return
            end
        end
        raceName = string.lower(raceName);

        if HAS_ALTERNATE_FORM then
            IN_ALTERNATE_FORM = C_BarberShop.IsViewingAlteredForm();
        else
            IN_ALTERNATE_FORM = false;
        end
        if sex == 0 then
            sexKey = "male";
            if HAS_ALTERNATE_FORM then
                if IN_ALTERNATE_FORM then   --alternate male
                    databaseKey = ALTERNATE_FORM_SAVED_ID;
                    modelPoolID = 3;
                else    --male
                    modelPoolID = 1;
                end
            else    --male
                modelPoolID = 1;
            end
        else
            sexKey = "female";
            if HAS_ALTERNATE_FORM then
                if IN_ALTERNATE_FORM then   --alternate female
                    databaseKey = ALTERNATE_FORM_SAVED_ID;
                    modelPoolID = 4;
                else    --female
                    modelPoolID = 2;
                end
            else    --female
                modelPoolID = 2;
            end
        end
    end

    if self.modelPoolID then
        SCROLL_OFFSETS[self.modelPoolID] = ScrollModelFrame:GetEndPosition();   --save current offset
    end
    self.modelPoolID = modelPoolID;

    ScrollBoundMarkUpdater:Hide();

    ModelPool:SetActiveModelPool(modelPoolID);

    local data = DataProvider:SetActiveDatabase(databaseKey, sexKey);
    NUM_ACTIVE_BUTTONS = #data;
    local raceTex = RaceAtlas:GetAtlas(raceName, sexKey, IN_ALTERNATE_FORM);
    SetUpSavedLooksButton(data, raceTex);
    UpdateScrollRange( SCROLL_OFFSETS[modelPoolID] );
    LoadingFrame:LoadPortraits();
end

function NarciBarberShopMixin:OnBarberShopOpen()
    self.initialCustomizationData = C_BarberShop.GetAvailableCustomizations();

    local isDragonriding;

    if self.initialCustomizationData then
        for _, categoryData in ipairs(self.initialCustomizationData) do
            if categoryData.chrModelID then
                isDragonriding = API.IsDragonridingChrModel(categoryData.chrModelID);
                break
            end
        end
    end
    self.isDragonriding = isDragonriding;

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    local sex, raceName;
    if currentCharacterData then
        sex = currentCharacterData.sex;
        self.initialIconAtlas = currentCharacterData.raceData and currentCharacterData.raceData.createScreenIconAtlas;
        raceName = GetRaceFileName(currentCharacterData);
    end

    IS_SAVE_SUPPORTED = true;   --Reset druid form flag
    self:UpdateCategory(sex, raceName);
    StatManager:OnBarberShopOpen();
end

function NarciBarberShopMixin:OnBarberShopClose()
    self.initialIconAtlas = nil;
    self.initialCustomizationData = nil;
    self.fadeController:SetScript("OnUpdate", nil);
    StatManager:OnBarberShopClose();
end

function NarciBarberShopMixin:ResetCustomizationInternally()
    if self.isDragonriding then
        C_BarberShop.ResetCustomizationChoices();
    else
        if self.initialCustomizationData then
            CustomizationUtil:ApplyCustomizationCategoryData(self.initialCustomizationData, true);
        end
    end
end

function NarciBarberShopMixin:IsCharacterCategoryChanged()
    --true if player is viewing a different category - i.g. was type1 but currently viewing type2
    local chrModelID = C_BarberShop.GetViewingChrModel();
    if chrModelID and chrModelID ~= 0 then
        return false
    end

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    if currentCharacterData then
        if currentCharacterData.raceData then
            return self.initialIconAtlas ~= currentCharacterData.raceData.createScreenIconAtlas;
        else
            return true
        end
    else
        return true
    end
end

function NarciBarberShopMixin:OnViewingModelChanged(chrModelID)
    local effectiveChrModelID = C_BarberShop.GetViewingChrModel();
    self:UpdateCategory();
    --print("chrModelID", effectiveChrModelID)
end

function NarciBarberShopMixin:ReloadData()
    for k, v in pairs(SCROLL_OFFSETS) do
        SCROLL_OFFSETS[k] = 0;
    end

    ModelPool:WipeAllModels();

    for _, presetButton in pairs(SavedLookButtons) do
        presetButton.appearanceData = nil;
    end

    self:UpdateCategory(self.currentCategorySex, self.currentCategoryRaceName);

    After(0.1, function()
        DataProvider:IsCharacterDataUnique();
    end);
end

-----------------------------------------------------------------
local function InitializeBarberShopFrame()
    local frame = Narci_BarbershopFrame;
    frame:ClearAllPoints();
    frame:SetParent(BarberShopUI);
    frame:SetPoint("TOPLEFT", BarberShopUI, "TOPLEFT", 0, -95);
    frame:Show();

    --The WoW default action is automatically closing the BarberShopUI
    --But here we want to check if the newly applied appearance is unique and notifiy user to save it
    BarberShopUI:UnregisterEvent("BARBER_SHOP_APPEARANCE_APPLIED");

    ModelPool:Init();
end

--/run TestPlayerModel:SetZoomDistance()


local function HookMixin()
    --[[
    hooksecurefunc(CharCustomizeFrame, "SetCustomizationChoice", function(self, optionID, choiceID)
        print("Set ",optionID, choiceID)
    end)
    hooksecurefunc(CharCustomizeFrame, "PreviewCustomizationChoice", function(self, optionID, choiceID)
        print("Preview ", optionID, choiceID)
    end)
    --]]

    hooksecurefunc(C_BarberShop, "SetSelectedSex", function(sexID)
        MainFrame:UpdateCategory(sexID);
    end);

    hooksecurefunc(C_BarberShop, "SetViewingShapeshiftForm", function(formID)
        MainFrame:UpdateCategory();
        if API.IsFormSavable(formID) then
            MainFrame:ToggleSaves(true);
        else
            MainFrame:ToggleSaves(false);
        end
    end);

    if HAS_ALTERNATE_FORM then
        hooksecurefunc(C_BarberShop, "SetViewingAlteredForm", function(viewingAlteredForm)
            MainFrame:UpdateCategory();
        end);
    end

    if C_BarberShop.SetViewingChrModel then
        hooksecurefunc(C_BarberShop, "SetViewingChrModel", function(chrModelID)
            MainFrame:OnViewingModelChanged();
        end);
    end

    --Override the default method to:
    --1. Add looks uniqueness check
    --Constantly monitor this mixin!!

    if true then
        function BarberShopUI:UpdateCharCustomizationFrame(alsoReset)
            local customizationCategoryData = C_BarberShop.GetAvailableCustomizations();
            if not customizationCategoryData then
                return;
            end

            DataProvider:IsCharacterDataUnique(customizationCategoryData);

            if alsoReset then
                CharCustomizeFrame:Reset();
            end

            CharCustomizeFrame:SetCustomizations(customizationCategoryData);

            if self.UpdatePrice then
                --TransitionAPI *barbershop is free in Dragonflight
                self:UpdatePrice();
            end

            if self.UpdateButtons then
                self:UpdateButtons();
            end
            --ExportEditBox.profileString = nil; --It'll be updated when that editbox becomes visible
        end
    end
end



local EventListener = CreateFrame("Frame");
local events = {"BARBER_SHOP_COST_UPDATE", "BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE", "BARBER_SHOP_RESULT", "BARBER_SHOP_OPEN", "BARBER_SHOP_CLOSE", "BARBER_SHOP_APPEARANCE_APPLIED", "ADDON_LOADED"};    --"UNIT_MODEL_CHANGED"
for i = 1, #events do
    EventListener:RegisterEvent(events[i])
end


EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        --Blizzard_CharacterCustomize
        --Blizzard_BarbershopUI
        if name == "Narcissus_Barbershop" then --Narcissus_Barbershop
            self:UnregisterEvent(event);
            if not (BarberShopFrame) then
                print("Narcissus Error: Blizzard_BarbershopUI not loaded!");
                self:UnregisterAllEvents();
                return
            end
            BarberShopUI = BarberShopFrame;
            DataProvider:LoadData();
            HotkeyManager:LoadHotkeys();
            StatManager:LoadData();
            HookMixin();
            InitializeBarberShopFrame();
            MainFrame:UpdateCategory();
            MainFrame:OnBarberShopOpen();

            if false then
                C_Timer.After(0.5 , function()
                    BarberShopUI:SetPropagateKeyboardInput(true);    --DEBUG
                end)
            end
        end
    elseif event == "BARBER_SHOP_OPEN" then
        MainFrame:OnBarberShopOpen();

    elseif event == "BARBER_SHOP_CLOSE" then
        MainFrame:OnBarberShopClose();

    elseif event == "BARBER_SHOP_RESULT" then
        if BarberShopUI.UpdateButtons then
            BarberShopUI:UpdateButtons();
        end
    elseif event == "BARBER_SHOP_APPEARANCE_APPLIED" then
        if MainFrame.checkUniqueness and DataProvider:IsNewLooksUnique() then
            BarberShopUI:UpdateCharCustomizationFrame();
            PlusButton:Glow();
        else
            BarberShopUI:Cancel();
        end
        --StatManager:UpdateMoney();
    end
end)





-------------------------------------------------------
--Settings
local TabButtons = {};

NarciBarberShopSettingTabButtonMixin = {};

function NarciBarberShopSettingTabButtonMixin:OnLoad()
    tinsert(TabButtons, self);
end

function NarciBarberShopSettingTabButtonMixin:OnEnter()
    if not self.isSelected then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSettingTabButtonMixin:OnLeave()
    if not self.isSelected then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciBarberShopSettingTabButtonMixin:SetSelection(isSelected)
    self.isSelected = isSelected;
    SettingFrame.ScrollFrame:SetOffset(0);
    if isSelected then
        self.ButtonText:SetTextColor(1, 0.82, 0);
        SettingFrame:SelectTab(self.Tab);
    else
        self:OnLeave();
        if self.Tab then
            self.Tab:Hide();
        end
    end
end

function NarciBarberShopSettingTabButtonMixin:OnClick()
    if self.isSelected then return end;
    
    for i = 1, #TabButtons do
        TabButtons[i]:SetSelection( TabButtons[i] == self );
    end

    PlaySound(856);
end


NarciBarberShopSettingCheckBoxMixin = {};

function NarciBarberShopSettingCheckBoxMixin:OnLoad()
    self.Box:SetVertexColor(0.8, 0.8, 0.8);
    self.Highlight:SetVertexColor(0.5, 0.5, 1);
end

function NarciBarberShopSettingCheckBoxMixin:SetChecked(state)
    self.isOn = state;
    self.Check:SetShown(state);
    if self.onClickFunc then
        self.onClickFunc(self.isOn);
    end
end

function NarciBarberShopSettingCheckBoxMixin:OnClick()
    self.isOn = not self.isOn;
    self:SetChecked(self.isOn);
    if self.name then
        NarciBarberShopDB[self.name] = self.isOn;
    end

    if self.isOn then
        PlaySound(856);
    else
        PlaySound(857); --SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end
end


local DiffUtil = {};

function DiffUtil:GenerateAppearanceUID(selectedOptions)
    --selectedOptions = { {option1ID, choice1ID}, }

    local choices = {};
    local n = 0;

    for _, data in ipairs(selectedOptions) do
        n = n + 1;
        choices[n] = data[2];
    end

    table.sort(choices);

    local uid;
    local lastValue;

    for k, v in ipairs(choices) do
        if k == 1 then
            uid = v;
        else
            uid = uid .. (v - lastValue);
        end
        lastValue = v;
    end

    return uid
end

function DiffUtil:UpdateTable()
    local tbl = {};
    local sharedAppearance = DataProvider:GetAppearanceFromSharedDB();
    local uid;

    if sharedAppearance then
        local n = 0;

        for _, dataSource in pairs(sharedAppearance) do
            n = n + 1;
            uid = self:GenerateAppearanceUID(dataSource.data);
            tbl[uid] = true;
        end
    end

    self.lookupTable = tbl;
end

function DiffUtil:IsSavedAppearance(selectedOptions)
    local uid = self:GenerateAppearanceUID(selectedOptions);
    return self.lookupTable[uid] or false
end


local function SharedTab_Update()

end

local function ShareTab_Setup(tab)
    tab:SetScript("OnShow", API.ShowAppearanceList);
    tab:SetScript("OnHide", API.HideAppearanceList);

    local box1OffsetY = -25;
    local box2OffsetY = -96;

    tab.ExportEditBox:ClearAllPoints();
    tab.ImportEditBox:ClearAllPoints();

    if API.IsPlayerMultiForm() then
        tab.ExportEditBox.Header:ClearAllPoints();
        tab.ExportEditBox.Header:SetPoint("TOP", tab, "TOP", 0, -8);


        local PlayerFormLabel = tab:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        PlayerFormLabel:Hide();
        PlayerFormLabel:SetTextColor(0.5, 0.5, 0.5);
        tab.ExportEditBox.HiddenObject = PlayerFormLabel;

        --Form Switch Button
        local switchButtonSize = 20;
        local buttonGap = 6;
        local textureFile = "Interface/AddOns/Narcissus/Art/Modules/BarberShop/FormSwitch.tga";

        local FormSwitchButtonMixin = {};

        function FormSwitchButtonMixin:OnEnter()
            if self.selected then
                self.Border:SetVertexColor(1, 1, 1);
            else
                self.Border:SetVertexColor(API.GetColorByKey("focused"));
            end
        end

        function FormSwitchButtonMixin:OnLeave()
            if self.selected then
                self.Border:SetVertexColor(1, 1, 1);
            else
                self.Border:SetVertexColor(API.GetColorByKey("grey"));
            end
        end

        function FormSwitchButtonMixin:OnClick()
            --C_BarberShop.SetViewingAlteredForm(self.isAlteredForm);
            local resetCategory = false;
            CharCustomizeFrame:SetViewingAlteredForm(self.isAlteredForm, resetCategory);
            After(0.1, function()
                if tab:IsVisible() then
                    SharedTab_Update();
                end
            end);
        end

        function FormSwitchButtonMixin:SetSelected(selected)
            self.selected = selected;
            if selected then
                self.Border:SetTexCoord(0.25, 0.5, 0, 0.25);
                PlayerFormLabel:ClearAllPoints();
                if self.isAlteredForm then
                    PlayerFormLabel:SetPoint("LEFT", self, "RIGHT", buttonGap, 0);
                else
                    PlayerFormLabel:SetPoint("RIGHT", self, "LEFT", -buttonGap, 0);
                end
            else
                self.Border:SetTexCoord(0, 0.25, 0, 0.25);
            end
            if self:IsMouseMotionFocus() then
                self:OnEnter();
            else
                self:OnLeave();
            end
        end

        local FormButtons = {};

        for i = 1, 2 do
            local button = CreateFrame("Button", nil, tab);
            Mixin(button, FormSwitchButtonMixin);
            button:SetSize(switchButtonSize, switchButtonSize);

            button.Border = button:CreateTexture(nil, "OVERLAY");
            button.Border:SetSize(32, 32);
            button.Border:SetPoint("CENTER", button, "CENTER", 0, 0);
            button.Border:SetTexture(textureFile);

            button.RaceIcon = button:CreateTexture(nil, "ARTWORK");
            button.RaceIcon:SetAllPoints(true);

            local mask = button:CreateMaskTexture(nil, "ARTWORK");
            mask:SetAllPoints(true);
            mask:SetTexture("Interface/AddOns/Narcissus/Art/BasicShapes/Circle", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
            button.RaceIcon:AddMaskTexture(mask);

            button:SetScript("OnEnter", button.OnEnter);
            button:SetScript("OnLeave", button.OnLeave);
            button:SetScript("OnClick", button.OnClick);

            if i == 1 then
                button:SetPoint("TOPRIGHT", tab, "TOP", -0.5*buttonGap, box1OffsetY);
                button.isAlteredForm = false;
                button:SetSelected(true);
            else
                button:SetPoint("TOPLEFT", tab, "TOP", 0.5*buttonGap, box1OffsetY);
                button.isAlteredForm = true;
                button:SetSelected(false);
            end

            table.insert(FormButtons, button);
        end


        function SharedTab_Update()
            API.ShowAppearanceList();
            tab.ExportEditBox:UpdateContent();

            local raceID, sex, _, raceName = API.GetCurrentCharacterRaceSex();     --Defined in ImportExport.lua
            if API.IsMultiFormRace(raceID) then
                local extraOffsetY = switchButtonSize + buttonGap + 2;
                tab.ExportEditBox:SetPoint("TOP", tab, "TOP", 0, box1OffsetY - extraOffsetY);
                tab.ImportEditBox:SetPoint("TOP", tab, "TOP", 0, box2OffsetY - extraOffsetY);

                local viewingAlteredForm = C_BarberShop.IsViewingAlteredForm();

                for i = 1, 2 do
                    local button = FormButtons[i];
                    if button then
                        button:Show();
                        button:SetSelected(viewingAlteredForm == button.isAlteredForm);
                        button.RaceIcon:SetAtlas(API.GetRaceIcon(raceID, sex, button.isAlteredForm), false);
                    end
                end

                PlayerFormLabel:SetText(CHARACTER_FORM:format(raceName));
            else
                tab.ExportEditBox:SetPoint("TOP", tab, "TOP", 0, box1OffsetY);
                tab.ImportEditBox:SetPoint("TOP", tab, "TOP", 0, box2OffsetY);
                for i = 1, 2 do
                    local button = FormButtons[i];
                    if button then
                        button:Hide();
                    end
                end
            end
        end

        tab:SetScript("OnShow", SharedTab_Update);
    else
        tab.ExportEditBox:SetPoint("TOP", tab, "TOP", 0, box1OffsetY);
        tab.ImportEditBox:SetPoint("TOP", tab, "TOP", 0, box2OffsetY);
    end
end


local ProfilePresetButton_Setup;
do
    local ProfilePresetButtonMixin = {};

    function ProfilePresetButton_Setup(button)
        Mixin(button, ProfilePresetButtonMixin);

        local names = {"OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnClick"};
        for _, methodName in ipairs(names) do
            button:SetScript(methodName, ProfilePresetButtonMixin[methodName]);
        end
    end

    function ProfilePresetButtonMixin:OnEnter()
        self:SetFocus(true);
    end

    function ProfilePresetButtonMixin:OnLeave()
        if not self:IsMouseOver() then
            self:SetFocus(false);
        end
    end

    function ProfilePresetButtonMixin:OnMouseDown()
        self.Reference:SetPoint("LEFT", self, "LEFT", 0, -1);
    end

    function ProfilePresetButtonMixin:OnMouseUp()
        self.Reference:SetPoint("LEFT", self, "LEFT", 0, 0);
    end

    function ProfilePresetButtonMixin:HighlightButton()
        --Override
    end

    function ProfilePresetButtonMixin:ShowCopyButton()
        --Override
    end

    function ProfilePresetButtonMixin:SetFocus(focused)
        if focused then
            self.HighlightButton(self);
            self.ShowCopyButton(self);
        else
            self.HighlightButton(nil);
            self.ShowCopyButton(nil);
        end
    end

    function ProfilePresetButtonMixin:OnClick(button)
        CustomizationUtil:UseCustomization(self.dataSource.data);
    end
end


local function ProfileTab_Setup(tab)
    local widgetHeight = 20;
    local padding = 8;
    local tabWidth = tab:GetWidth();


    local subframe = CreateFrame("Frame", nil, tab);
    local LookList = CreateFrame("Frame", nil, subframe);
    local IntroFrame;

    local function IntroFrame_Show()
        if not IntroFrame then
            IntroFrame = CreateFrame("Frame", nil, tab);
            IntroFrame:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -padding - 40);
            IntroFrame:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, padding);

            local Instruction = IntroFrame:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
            Instruction:SetWidth(tabWidth*0.8);
            Instruction:SetJustifyH("CENTER");
            Instruction:SetJustifyV("TOP");
            Instruction:SetPoint("TOP", tab, "TOP", 0, 0);
            Instruction:SetTextColor(0.8, 0.8, 0.8);
            Instruction:SetText(L["Profile Migration Tooltip"]);

            local OkButton = CreateFrame("Button", nil, IntroFrame, "NarciBarberShopStrokeButtonTemplate");
            OkButton.onClickFunc = function()
                IntroFrame:Hide();
                NarciBarberShopDB.Intro_PublicProfile = true;
                subframe:Show();
            end
            OkButton:SetPoint("TOP", Instruction, "BOTTOM", 0, -12);
            OkButton:SetButtonText(L["Profile Migration Okay"]);

            local contentHeight = Instruction:GetHeight() + 12 + widgetHeight;
            local frameHeight = IntroFrame:GetHeight();
            local offsetY = 0.5 * (frameHeight - contentHeight);
            Instruction:ClearAllPoints();
            Instruction:SetPoint("TOP", IntroFrame, "TOP", 0, -offsetY);
        end

        subframe:Hide();
        IntroFrame:Show();
    end

    --Select Profile: Private/Public
    local frame1Data = {
        label = L["Profile"],

        tooltip = L["Profile Type Tooltip"],

        choices = {
            {text = L["Private Profile"]},
            {text = L["Public Profile"]},
        },

        getChoice = function()
            if DataProvider:IsUsingPublicProfile() then
                return 2
            else
                return 1
            end
        end,

        onSelectChoice = function(choice)
            if IntroFrame then
                IntroFrame:Hide();
            end

            if choice == 1 then
                DataProvider:SetUsePublicProfile(false);
                subframe:Hide();
            elseif choice == 2 then
                DataProvider:SetUsePublicProfile(true);

                if not NarciBarberShopDB.Intro_PublicProfile then
                    IntroFrame_Show();
                else
                    subframe:Show();
                end
            end

            MainFrame:ReloadData();
        end
    };

    local totalHeight = padding;
    local choiceFrame = addon.CreateChoiceFrame(tab);
    choiceFrame:SetPoint("TOPLEFT", tab, "TOPLEFT", padding, -totalHeight);
    choiceFrame:SetFrameWidth(tabWidth - 2*padding);
    choiceFrame:SetData(frame1Data);
    totalHeight = totalHeight + widgetHeight;


    do  --Save Looks List
        local BUTTON_TEXT_OFFSET = 6;
        local BUTTON_WIDTH = (tabWidth - 2*padding) / 2;
        local BUTTON_HEIGHT = 20;
        local FORMAT_PAGE = PAGE_NUMBER_WITH_MAX or "Page %d/%d";

        LookList:SetSize(tabWidth - 2 * padding, 6 * BUTTON_HEIGHT);

        LookList.buttons = {};

        local ButtonHighlight = LookList:CreateTexture(nil, "BORDER");
        ButtonHighlight:SetColorTexture(0.2, 0.2, 0.2);
        ButtonHighlight:Hide();

        local function HighlightButton(button)
            ButtonHighlight:ClearAllPoints();
            if button then
                ButtonHighlight:Show();
                ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
                ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
            else
                ButtonHighlight:Hide();
            end
        end


        local PageText = LookList:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        PageText:SetHeight(BUTTON_HEIGHT);
        PageText:SetJustifyH("CENTER");
        PageText:SetJustifyV("MIDDLE");
        PageText:SetPoint("BOTTOM", LookList, "BOTTOM", 0, 0);
        PageText:SetTextColor(0.5, 0.5, 0.5);

        local CountText = LookList:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        CountText:SetHeight(BUTTON_HEIGHT);
        CountText:SetJustifyH("RIGHT");
        CountText:SetJustifyV("MIDDLE");
        CountText:SetPoint("BOTTOMRIGHT", LookList, "TOPRIGHT", -BUTTON_TEXT_OFFSET, 0.5 * widgetHeight);
        CountText:SetTextColor(0.5, 0.5, 0.5);

        local CopyButton = CreateFrame("Button", nil, LookList);
        CopyButton:Hide();
        CopyButton:SetSize(30, BUTTON_HEIGHT);
        CopyButton.Icon = CopyButton:CreateTexture(nil, "OVERLAY");
        CopyButton.Icon:SetTexture("Interface/AddOns/Narcissus/Art/Modules/BarberShop/CopyButton");
        CopyButton.Icon:SetSize(12, 12);
        CopyButton.Icon:SetPoint("CENTER", CopyButton, "CENTER", 0, 0);

        CopyButton.BlackLine = CopyButton:CreateTexture(nil, "OVERLAY");
        CopyButton.BlackLine:SetPoint("TOPLEFT", CopyButton, "TOPLEFT", 0, 0);
        CopyButton.BlackLine:SetSize(2*addon.pixel, widgetHeight);
        CopyButton.BlackLine:SetColorTexture(0, 0, 0);

        local function CopyButton_OnEnter(self)
            HighlightButton(self:GetParent());
            self.Icon:SetAlpha(1);

            WidgetTooltip:Hide();
            WidgetTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 2, 2);
            WidgetTooltip:SetTooltipText(L["Profile Migration CopyButton Tooltip"]);
        end

        local function CopyButton_OnLeave(self)
            HighlightButton(nil);
            self.Icon:SetAlpha(0.6);
            self:Hide();
            WidgetTooltip:Hide();
        end
        CopyButton_OnLeave(CopyButton);

        local function CopyButton_OnClick(self)
            if DataProvider:IsPublicProfileFull() then
                return
            end

            if not self.isProcessing then
                self.isProcessing = true;
                CustomizationUtil:UseCustomization(self:GetParent().dataSource.data)
                self:Disable();
                After(0.1, function()
                    self.isProcessing = nil;
                    self:Enable();
                    SaveCurrentAppearance();
                    LookList:UpdateList();
                end)
            end
        end

        CopyButton:SetScript("OnEnter", CopyButton_OnEnter);
        CopyButton:SetScript("OnLeave", CopyButton_OnLeave);
        CopyButton:SetScript("OnClick", CopyButton_OnClick);

        function CopyButton:UpdateState()
            if DataProvider:IsPublicProfileFull() then
                if not self.RedTexture then
                    self.RedTexture = self:CreateTexture(nil, "ARTWORK");
                    self.RedTexture:SetAllPoints(true);
                    local r, g, b = API.GetColorByKey("red");
                    self.RedTexture:SetColorTexture(r, g, b, 0.6);
                end
                self.RedTexture:Show();
                self.isFull = true;
                CountText:SetTextColor(0.9333, 0.1961, 0.1412);
            else
                if self.RedTexture then
                    self.RedTexture:Hide();
                end
                self.isFull = nil;
                CountText:SetTextColor(0.5, 0.5, 0.5);
            end
        end

        local function ShowCopyButton(owner)
            CopyButton:ClearAllPoints();
            if owner and (not owner.isSaved) then
                CopyButton:SetPoint("RIGHT", owner, "RIGHT", 0, 0);
                CopyButton:SetParent(owner);
                CopyButton:Show();
            else
                CopyButton:Hide();
            end
        end

        local function CreateLookButton(parent)
            local button = CreateFrame("Button", nil, parent);
            local leftOffset = BUTTON_TEXT_OFFSET + 12;
            button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT);

            button.Reference = CreateFrame("Frame", nil, button);
            button.Reference:SetSize(BUTTON_HEIGHT, BUTTON_HEIGHT);
            button.Reference:SetPoint("LEFT", button, "LEFT", 0, 0);

            button.LeftText = button:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
            button.LeftText:SetPoint("LEFT", button.Reference, "LEFT", leftOffset, 0);
            button.LeftText:SetJustifyH("LEFT");
            button.LeftText:SetTextColor(0.8, 0.8, 0.8);
            button.LeftText:SetWidth(BUTTON_WIDTH -leftOffset -34);

            button.Check = button:CreateTexture(nil, "OVERLAY");
            button.Check:SetPoint("LEFT", button.Reference, "LEFT", BUTTON_TEXT_OFFSET, 0);
            button.Check:SetSize(8, 8);
            button.Check:SetTexture("Interface/AddOns/Narcissus/Art/Modules/BarberShop/GreenCheck");

            ProfilePresetButton_Setup(button);
            button.HighlightButton = HighlightButton;
            button.ShowCopyButton = ShowCopyButton;

            return button
        end

        function LookList:SetDataByPlayerID(playerID)
            if playerID ~= self.playerID then
                self.page = 1;
            end
            self.playerID = playerID;
            self:UpdateList();
        end

        function LookList:UpdateList()
            local list = DataProvider:GetAppearanceByPlayerID(self.playerID);
            self.list = list;
            self.numPages = math.ceil( (list and #list)/10 or 0);

            PageText:ClearAllPoints();

            if self.numPages > 0 then
                PageText:SetPoint("BOTTOM", LookList, "BOTTOM", 0, 0);
                PageText:SetHeight(BUTTON_HEIGHT);
            else
                PageText:SetPoint("CENTER", LookList, "CENTER", 0, 0);
                PageText:SetHeight(96);
                PageText:SetText(L["No Saves"]);
            end

            self.isSaved = {};
            DiffUtil:UpdateTable();
            for i, dataSource in ipairs(list) do
                self.isSaved[i] = DiffUtil:IsSavedAppearance(dataSource.data);
            end

            CountText:SetText(DataProvider:GetNumLooksInSharedDB().." / "..MAX_SAVES);

            CopyButton:UpdateState()

            self:SetPage(self.page);
        end

        function LookList:SetPage(page)
            self.page = page;

            if self.numPages > 0 then
                PageText:SetText(FORMAT_PAGE:format(page, self.numPages));
            else
                for i = 1, 10 do
                    if self.buttons[i] then
                        self.buttons[i]:Hide();
                    end
                end
                return
            end

            local button;

            local fromIndex = 10 * (page - 1);
            local total = 0;
            local dataSource, dataIndex;

            for i = 1, 10 do
                dataIndex = fromIndex + i;
                dataSource = self.list[dataIndex];
                if dataSource then
                    total = total + 1;
                    button = self.buttons[i];

                    if not button then
                        button = CreateLookButton(self);
                        self.buttons[i] = button;
                        local col = (i > 5 and 2) or 1;
                        local row = i - (col - 1) * 5;
                        button:SetPoint("TOPLEFT", self, "TOPLEFT", (col - 1) * BUTTON_WIDTH, (1 - row) * BUTTON_HEIGHT);
                    end

                    button.isSaved = self.isSaved[dataIndex]
                    button.LeftText:SetText(dataSource.name);
                    button.Check:SetShown(button.isSaved);
                    button.dataSource = dataSource;

                    button:Show();
                end
            end

            for i = total + 1, 10 do
                if self.buttons[i] then
                    self.buttons[i]:Hide();
                end
            end
        end

        function LookList:SetPageByDelta(delta)
            if delta < 0 then
                if self.page < self.numPages then
                    self.page = self.page + 1;
                else
                    return
                end
            else
                if self.page > 1 then
                    self.page = self.page - 1;
                else
                    return
                end
            end

            self:SetPage(self.page);
        end

        LookList:SetScript("OnMouseWheel", function(self, delta)
            LookList:SetPageByDelta(delta);
        end);

        LookList:SetScript("OnShow", function(self)
            LookList:UpdateList();
        end);

        LookList:SetDataByPlayerID(DataProvider.currentPlayerID);
    end

    do  --Dropdown: Character Select
        local _, classID = UnitClassBase("player");
        local playerName = UnitName("player");
        local realmName = GetRealmName();

        local DropdownDataProvider = {};

        function DropdownDataProvider:GetList()
            return DataProvider:GetCharacterList()
        end

        function DropdownDataProvider:SelectData(data)
            LookList:SetDataByPlayerID(data.playerID);
            return true
        end

        function DropdownDataProvider:SetData(button, data)
            button.LeftText:SetText(FormatPlayerName(data.playerName, data.realmName, data.classID));
            if button.RightText then
                button.RightText:SetText(data.numLooks);
            end
            button.data = data;
            button:Show();
        end

        local frame2Data = {
            text = FormatPlayerName(playerName, realmName, classID),
            dataProvider = DropdownDataProvider,
        };

        totalHeight = totalHeight + widgetHeight;
        local dropdown = addon.CreateDropdownFrame(subframe);
        dropdown:SetFrameLevel(tab:GetFrameLevel() + 5);
        dropdown:SetPoint("TOPLEFT", tab, "TOPLEFT", padding, -totalHeight);
        dropdown:SetWidth(0.6*(tabWidth - 2*padding));
        dropdown:SetData(frame2Data);

        totalHeight = totalHeight + widgetHeight;
    end

    totalHeight = totalHeight + 0.5*widgetHeight;
    LookList:SetPoint("TOPLEFT", tab, "TOPLEFT", padding, -totalHeight);

    if DataProvider:IsUsingPublicProfile() then
        if not NarciBarberShopDB.Intro_PublicProfile then
            IntroFrame_Show();
        else
            subframe:Show();
        end
    else
        subframe:Hide();
    end
end

local TabData = {
    { name= "General", order = 1, localizedName = GENERAL,
        layout = {
            { name = "ToggleNotification", type = "checkbox", localizedName = L["Save Notify"], defaultState = true,
                onClickFunc = function(state) MainFrame:ToggleNotification(state) end,
                tooltip = L["Save Notify Tooltip"];
            },
            --{ name = "ToggleRandomAppearance", type = "checkbox", localizedName = L["Show Randomize Button"], defaultState = false, onClickFunc = function(state) MainFrame:ToggleRandomizeAppearanceButton(state) end }, --RANDOMIZE_APPEARANCE
        },
    },

    { name = "Shortcuts", order = 2, localizedName = L["Hotkey"],
        layout = {
            { name = "Camera", type = "header", localizedName = CAMERA_LABEL},
            { name = "RotateLeft", type = "keybinding", localizedName = ROTATE_LEFT},
            { name = "RotateRight", type = "keybinding", localizedName = ROTATE_RIGHT},
            { name = "ZoomIn", type = "keybinding", localizedName = ZOOM_IN},
            { name = "ZoomOut", type = "keybinding", localizedName = ZOOM_OUT},
        },
    },

    { name = "Share", order = 3, localizedName = L["Share"],
        manuallyCreated = true,
        setupFunc = ShareTab_Setup,
    },

    { name = "Profile", order = 4, localizedName = L["Profile"],
        manuallyCreated = true,
        setupFunc = ProfileTab_Setup,
    },

    { name = "Statistics", order = 0, localizedName = STATISTICS,
        layout = {
            --Barbershop service is free now. Remove money stats
            --{ name = "Money", type = "header", localizedName = L["Coins Spent"] },
            --{ name = "CoinsSpentSinceShadowlands", type="money", localizedName = "9.0+", tooltip = "Coins spent since 9.0"},
            --{ name = "CoinsSpentLifetime", type="money", localizedName = HONOR_LIFETIME, tooltip = "Coins spent during lifetime"},
            --{ name = "Blank", type="header", localizedName=" ",},
            { name = "LocationHeader", type = "location", localizedName = L["Locations"] },
        },
    },
};


local function CreateTabs(frame)
    local sidePadding = 8;
    local tabWidth, tabHeight = 312, 200;
    local ScrollFrame = frame.ScrollFrame;

    for i, data in ipairs(TabData) do
        local button = CreateFrame("Button", nil, frame, "NarciBarberShopSettingTabButtonTemplate");
        local order = data.order;
        button.order = order;

        if order ~= 0 then
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", sidePadding, -sidePadding + 16 *(1 - i));
        else
            button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", sidePadding, sidePadding);
        end
        button:SetText(data.localizedName);

        if data.layout then
            local totalHeight = 8;
            local Tab = CreateFrame("Frame", nil, ScrollFrame);
            button.Tab = Tab;
            if order == 0 then
                StatManager.StatFrame = Tab;
            end
            Tab:SetSize(tabWidth, tabHeight);
            Tab:SetPoint("TOPLEFT", frame.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            for j, objectData in ipairs(data.layout) do
                local type = objectData.type;
                local object;
                if type == "checkbox" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingCheckBoxTemplate");
                    object.onClickFunc = objectData.onClickFunc;
                    object.Label:SetText(objectData.localizedName);
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    object:SetHeight(textHeight + 2);
                    totalHeight = totalHeight + textHeight + 12;
                    --Load settings
                    local dbName = objectData.name;
                    object.name = dbName;
                    if NarciBarberShopDB[dbName] == nil then
                        NarciBarberShopDB[dbName] = objectData.defaultState;
                    end
                    object:SetChecked(NarciBarberShopDB[dbName]);
                    if objectData.tooltip then
                        local infoButton = CreateFrame("Frame", nil, object, "NarciBarberShopInfoButtonTemplate");
                        infoButton:SetPoint("LEFT", object, "RIGHT", 12, 0);
                        infoButton.tooltipText = objectData.tooltip;
                        objectData.tooltip = nil;
                    end
                elseif type == "keybinding" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingKeyBindingButtonTemplate");
                    object.Label:SetText(objectData.localizedName);
                    object.command = objectData.name;
                    object:SetPoint("TOPRIGHT", Tab, "TOPRIGHT", -60, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 12;
                    object:SetText(HotkeyManager:GetHotkey(object.command));

                elseif type == "header" then
                    object = Tab:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
                    object:SetText(objectData.localizedName);
                    if objectData.anchor then
                        object:SetJustifyH("LEFT");
                    else
                        object:SetJustifyH("CENTER");
                    end
                    object:SetSpacing(2);
                    object:SetJustifyV("TOP");
                    object:SetPoint("TOP", Tab, "TOP", 0, -totalHeight);
                    object:SetTextColor(0.5, 0.5, 0.5);
                    object:SetWidth(270);
                    totalHeight = totalHeight + 16;

                elseif type == "money" then
                    object = CreateFrame("Frame", nil, Tab, "NarciBarberShopStatsMoneyFrameTemplate");
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    object:SetLabel(objectData.localizedName);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 8;

                    StatManager.widgets[objectData.name] = object;
                elseif type == "location" then
                    object = CreateFrame("Frame", nil, Tab, "NarciBarberShopStatsLocationFrameTemplate");
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    object:SetHeader();
                    totalHeight = totalHeight + 16;
                    StatManager.widgets[objectData.name] = object;
                end
            end

            Tab.tabHeight = totalHeight;
            Tab.basicHeight = totalHeight;

        elseif data.manuallyCreated then
            local Tab = frame[data.name.."Tab"];

            if not Tab then
                Tab = CreateFrame("Frame", nil, ScrollFrame);
                button.Tab = Tab;
                Tab:SetSize(tabWidth, tabHeight);
                Tab:SetPoint("TOPLEFT", ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            end

            button.Tab = Tab;
            Tab:ClearAllPoints();
            Tab:SetPoint("TOPLEFT", ScrollFrame, "TOPLEFT", 0, 0);

            if data.setupFunc then
                data.setupFunc(Tab);
            end
        end
    end

    TabData = nil;
end

NarciBarberShopSettingsMixin = CreateFromMixins(NarciChamferedFrameMixin);

function NarciBarberShopSettingsMixin:OnLoad()
    self:CreateBackground();

    SettingFrame = self;
    StatManager.SettingFrame = self;

    local v = 0.2;
    self:SetBorderColor(v, v, v, 1);
    self:SetBackgroundColor(0, 0, 0, 1);
    self.Divider:SetVertexColor(v, v, v);
    self:SetBorderOffset(0);

    self.ScrollFrame.ScrollBar.Background:SetVertexColor(0.5, 0.5, 0.5);

    NarciAPI.CreateSmoothScroll(self.ScrollFrame);
    self.ScrollFrame:SetStepSize(40);

    self:SetScript("OnMouseWheel", function()
    end);
end

function API.GetSettingsFrame()
    return SettingFrame
end

function NarciBarberShopSettingsMixin:AddChildFrame(child)
    if not self.childFrames then
        self.childFrames = {};
    end

    for i, f in ipairs(self.childFrames) do
        if f == child then
            return
        end
    end

    table.insert(self.childFrames, child);
end

function NarciBarberShopSettingsMixin:Init()
    self.Init = nil;

    _G.NarciBarberShopWidgetTooltip = WidgetTooltip;

    local tooltipPadding = 8;
    WidgetTooltip.Text:SetPoint("TOPLEFT", WidgetTooltip, "TOPLEFT", tooltipPadding, -tooltipPadding);

    function WidgetTooltip:SetTooltipText(tooltipText, r, g, b)
        self:Hide();
        if tooltipText then
            self.Text:SetText(tooltipText);
            self.Text:SetTextColor(r or 1, g or 1, b or 1);
            local width = self.Text:GetWrappedWidth();
            self:SetSize(width + 2*tooltipPadding, self.Text:GetHeight() + 2*tooltipPadding);
            self.AnimIn:Play();
            self:Show();
            self:SetFrameStrata("TOOLTIP");
        end
    end

    NarciAPI.NineSliceUtil.SetUpBackdrop(WidgetTooltip, "rectR6");
    NarciAPI.NineSliceUtil.SetBackdropColor(WidgetTooltip, 0.0, 0.0, 0.0);
    NarciAPI.NineSliceUtil.SetUpBorder(WidgetTooltip, "shadowR6");
    NarciAPI.NineSliceUtil.SetBorderColor(WidgetTooltip, 0.5, 0.5, 0.5);

    CreateTabs(self);
    TabButtons[3]:Click();  --Open Share (import/export)
end

function NarciBarberShopSettingsMixin:IsFocused()
    if self:IsMouseOver(0, 0, 0, 16) then
        return true
    elseif self.childFrames then
        for i, f in ipairs(self.childFrames) do
            if f:IsVisible() and f:IsMouseOver() then
                return true
            end
        end
        return false
    end
end

function NarciBarberShopSettingsMixin:OnEvent(event)
    --GLOBAL_MOUSE_DOWN
    if not self:IsFocused() and not SettingButton:IsMouseOver() then
        self:Hide();
    end
end

function NarciBarberShopSettingsMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    StatManager:UpdateFrame();
end

function NarciBarberShopSettingsMixin:OnHide()
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");

    autoHideTimer:Show();
end

function NarciBarberShopSettingsMixin:Toggle()
    self:SetShown(not self:IsShown());
end

function NarciBarberShopSettingsMixin:SelectTab(tab)
    --Update Scroll Range
    local frameHeight = math.floor(self.ScrollFrame:GetHeight() + 0.5);
    local range;
    if tab then
        tab:Show();
        if tab.tabHeight then
            range = tab.tabHeight - frameHeight;
            if range < 4 then
                range = 0;
            end
        else
            range = 0;
        end
        self.ScrollFrame:SetScrollRange(range);
    end
end

--Click to open Settings
NarciBarberShopSettingButtonMixin = {};

function NarciBarberShopSettingButtonMixin:OnLoad()
    SettingButton = self;
    self.Label:SetText(L["Settings And Share"]);
end

function NarciBarberShopSettingButtonMixin:OnMouseDown()
    self.Background:SetTexCoord(0.25, 0.5, 0, 1);
end

function NarciBarberShopSettingButtonMixin:OnMouseUp()
    self.Background:SetTexCoord(0, 0.25, 0, 1);
end

function NarciBarberShopSettingButtonMixin:OnEnter()
    self.Label:Show();
    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopSettingButtonMixin:OnLeave()
    self.Label:Hide();
end

function NarciBarberShopSettingButtonMixin:OnClick()
    if SettingFrame.Init then
        SettingFrame:Init();
    end
    SettingFrame:Toggle();
    PlaySound(856);
end

-----------------------------------------------
--Dev Tool
local function round(number, digit)
    digit = digit or 0;
    local fold = 10^digit;
    return math.floor((number * fold + 0.5))/fold
end

NarciDevToolPortraitMixin = {};

function NarciDevToolPortraitMixin:OnLoad()
    if false then return end;
    
    local model = self.Model;
    model:SetUnit("player");
    model:SetKeepModelOnHide(true);
    model:SetDoBlend(true);
    model:SetFacing(0);
    TransitionAPI.SetModelLight(model, true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
    model:SetCamera(0);
    model:SetPortraitZoom(1);
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    self.facing = 0;
    self.cameraDistance = 1;
    self.cameraPitch = pi/2;
    self.translationX, self.translationY = 0, 0;

    self.FacingButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        self.facing = model:GetFacing() + delta;
        model:SetFacing(self.facing);
        frame.Value:SetText( round(self.facing, 2) );
    end)

    --[[
    self.CameraPitchButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        local cameraPitch = self.cameraPitch + delta;
        self.cameraPitch = cameraPitch;
        TransitionAPI.SetCameraPosition(model, self.cameraDistance*sin(cameraPitch), 0, self.cameraDistance*cos(cameraPitch) + 0.8);
        frame.Value:SetText(cameraPitch);
    end)
    --]]



    self.ModelXButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x + delta, y, z);
        frame.Value:SetText( round(x + delta, 2) );
    end)

    self.ModelYButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x, y + delta, z);
        frame.Value:SetText( round(y + delta, 2) );
    end)

    self.ModelZButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x, y, z + delta);
        frame.Value:SetText( round(z + delta, 2) );
    end)

    self.DistanceButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local cameraDistance = self.cameraDistance + delta;
        self.cameraDistance = cameraDistance;
        TransitionAPI.SetCameraPosition(model, cameraDistance*sin(self.cameraPitch), 0, cameraDistance*cos(self.cameraPitch) + 0.8);
        frame.Value:SetText( round(cameraDistance, 4) );
    end)

    self.OffsetXButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local x, y = model:GetViewTranslation();
        model:SetViewTranslation(x + delta, y);
        frame.Value:SetText( round(x + delta) );
    end)

    self.OffsetYButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local x, y = model:GetViewTranslation();
        model:SetViewTranslation(x, y + delta);
        frame.Value:SetText( round(y + delta) );
    end)

    self.ReloadButton:SetScript("OnClick", function()
        self:LoadProfile();
    end)

    self.Model:SetScript("OnModelLoaded", function(self)
        print("ModelFileID:", self:GetModelFileID())
    end);
end

function NarciDevToolPortraitMixin:OnShow()
    local model = self.Model;
    model:MakeCurrentCameraCustom();
    self.cameraDistance = model:GetCameraDistance();
    self.cameraPitch = pi/2;
    model:SetPosition(0, 0, 0);
    self.FacingButton.Value:SetText(model:GetFacing());
    self.DistanceButton.Value:SetText(self.cameraDistance);
    local x, y = model:GetViewTranslation();
    self.OffsetXButton.Value:SetText(x);
    self.OffsetYButton.Value:SetText(y);
end

function NarciDevToolPortraitMixin:LoadProfile(race, sex)
    local model = self.Model;
    model:RefreshUnit();
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    model:MakeCurrentCameraCustom();
    UpdatePortraitCamera(model);
    local cameraX, cameraY, cameraZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 4, 0, 0);
    local targetX, targetY, targetZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 0, 0, 0);
    TransitionAPI.SetCameraTarget(model, targetX, targetY, targetZ);
    TransitionAPI.SetCameraPosition(model, cameraX, cameraY, cameraZ);
    local modelFacing = model:GetFacing();
    local modelPosX, modelPosY, modelPosZ = model:GetPosition();
    self.ModelXButton.Value:SetText(modelPosX);
    self.ModelYButton.Value:SetText(modelPosY);
    self.ModelZButton.Value:SetText(modelPosZ);
    self.FacingButton.Value:SetText(modelFacing);
    --/dump NarciDevToolPortraitFrame.Model:GetModelFileID()
end

--[[
    Statistics
    Gold spent at barber shops GetStatistic(1147)
    C_MapExplorationInfo.GetExploredAreaIDsAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"))
    C_Map.GetMapInfoAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"):GetXY())
New Look #10: Q.0.52k.i.5.c.1h.6.7.g.1.a.4.p.2.5.7.9.2.7.4.2.8.2g1.2.nD.J.9.B.16.7.7.c.f.w.3.5.4.5.C
Dracthyr Male: Q.0.52E.3.d.1i.4.9.g.3.6.3.j.9.6.3.3.8.3.4.8.1.6.1Th.g.mw.1.3.nV.p.9.J.19.3.b.1.O.1.8.5.C.aQ
Dracthyr Male: Q.0.52E.3.d.1i.4.9.g.3.6.3.j.9.6.3.3.8.3.4.8.1.6.1Th.h.P.lG.1.3.nV.p.9.J.19.3.b.1.O.1.8.5.C.aQ
--]]

local PORTRAIT_LOAD_DELAY = 0.1;
NarciBarberShopLoadingFrameMixin = {};

local function LoadingFrame_UpdatePortraitDelay(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > PORTRAIT_LOAD_DELAY then
        --self:SetScript("OnUpdate", nil);
        self.t = 0;
        self.button:RefreshPortrait(true);
    end
end

local function LoadingFrame_InitiateLoadingDelay(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.2 then
        self.t = 0;
        self:LoadNextPortrait(self.current);
    end
end

function NarciBarberShopLoadingFrameMixin:OnLoad()
    LoadingFrame = self;

    self.Name:SetText(Narci.L["Loading Portraits"] .."...");
    self.Name:SetTextColor(1, 1, 1);
    self.Progress:SetTextColor(0.67, 0.67, 0.67);
end

function NarciBarberShopLoadingFrameMixin:LoadPortraits()
    local model;

    if self.isLoading then
        --player select another category before previous portraits loading complete
        if self.models then
            for i, model in ipairs(self.models) do
                model.isModelLoaded = false;
                model:ClearModel();
            end
            self.models = nil;
        end

        if self.button then
            model = self.button:GetPortraitModel();
            if model then
                model.isModelLoaded = false;
                model:ClearModel();
            end
        end
    end

    local fromID;
    local total = 0;
    local models = {};
    if SavedLookButtons then
        for i, presetButton in ipairs(SavedLookButtons) do
            model = presetButton:GetPortraitModel();
            if model then
                tinsert(models, model);
            end
            if (not presetButton:IsPortraitLoaded()) and presetButton.appearanceData then
                total = total + 1;
                if not fromID then
                    fromID = i;
                end
            end
        end
    end
    self.models = models;

    if total == 0 then
        self:Hide();
        self:SetScript("OnUpdate", nil);
        return
    else
        self.total = total;
    end

    MainFrame.initialCustomizationData = C_BarberShop.GetAvailableCustomizations();

    self.Name:SetText(Narci.L["Loading Portraits"] .."...");
    self.current = fromID - 1;
    self.Ring.AnimSpin:Play();
    self.t = 0;
    self:SetScript("OnUpdate", LoadingFrame_InitiateLoadingDelay);

    FadeFrame(self, 0.25, 1, 0);
end

function NarciBarberShopLoadingFrameMixin:OnHide()
    self:SetScript("OnUpdate", nil);
end

function NarciBarberShopLoadingFrameMixin:LoadNextPortrait(buttonID)
    if buttonID and buttonID ~= self.current then
        return
    end

    self.current = self.current + 1;
    if self.current > self.total then
        --complete
        if self.isLoading then
            self:OnLoadingComplete();
        end
    else
        local button = SavedLookButtons[self.current];
        if button then
            button:UseCustomization(true);
            self.t = 0;
            self.button = button;
            self:SetScript("OnUpdate", LoadingFrame_UpdatePortraitDelay);
            self.isLoading = true;
            self.Progress:SetText(self.current .. " / " ..self.total);
        else
            self:OnLoadingComplete();
        end
    end
end

function NarciBarberShopLoadingFrameMixin:OnLoadingComplete()
    --self:StopAnimating();
    self:SetScript("OnUpdate", nil);
    self.isLoading = false;
    self.button = nil;

    FadeFrame(self, 0.5, 0);
    MainFrame:ResetCustomizationInternally();

    --if MainFrame:IsCharacterCategoryChanged() then

    --else

    --end
end