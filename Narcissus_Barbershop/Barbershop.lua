local After = C_Timer.After;
local sin = math.sin;
local cos = math.cos;
local pi = math.pi;
local sqrt = math.sqrt;
local abs = math.abs;

local function linear(t, b, e, d)
	return (e - b) * t / d + b
end

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local UIFrameFadeIn = UIFrameFadeIn;
local L = Narci.L;
-----------------------------------------------

local MainFrame, BarbershopModel, MaleButtons, FemaleButtons, WorgenMaleButtons, WorgenFemaleButtons, EditButton, EditBox, DeleteButton, PlusButton, SettingFrame, SettingButton;

--[[
NarciBarberShopModelMixin = {};

local CameraUpdater = CreateFrame("Frame");

function CameraUpdater:ZoomTo(value)
    BarbershopModel:MakeCurrentCameraCustom();
    local currentDistance = BarbershopModel:GetCameraDistance();
    self.zoomDistance = value
    BarbershopModel:SetCameraDistance(value);
end

function NarciBarberShopModelMixin:OnLoad()
    self:SetUnit("player")
    self:SetLight(true, false, -0.707, 0, -0.707, 1, 1, 1, 1, 0.5, 1, 1, 1);
    self:SetCamera(0);
    self:SetPortraitZoom(0.9);
    self:SetAnimation(0, 0);
    self:SetPaused(true);
    self:SetKeepModelOnHide(true);
    
    local ScreenHeight = UIParent:GetHeight();
    self:SetSize(ScreenHeight, ScreenHeight)
    BarbershopModel = self;
    self:SetViewTranslation(0, -80);
    self:SetPosition(-0.5, 0.2, 0);
end

function NarciBarberShopModelMixin:OnShow()
    
end

function NarciBarberShopModelMixin:OnModelLoaded()
    self:SetPaused(true)
end

function NarciBarberShopModelMixin:ZoomTo(value)
    CameraUpdater:ZoomTo(value)
end
--]]


----------------------------------------------------------------------------------------------------
local CAMERA_PROFILES_BY_RACE = {
    --modelX, modelY, modelZ, facing
    bloodelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    voidelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    draenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    lightforgeddraenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    dwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    darkirondwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    gnome = {
        male = {3.23, -0.01, -0.92, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    mechagnome = {
        male = {3.23, -0.05, -0.93, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    goblin = {
        male = {3.24, 0, -1.08, 0.43},
        female = {3.40, -0.03, -1.14, 0.43},
    },

    human = {
        male = {3.38, -0.04, -1.87, 0.35},
        female = {3.51, -0.025, -1.745, 0.43},
    },

    kultiran = {
        male = {3.06, -0.05, -2.32, 0.43},
        female = {3.34, -0.01, -2.21, 0.43},
    },

    nightborne = {
        male = {3.37, 0.01, -2.26, 0.35},
        female = {3.40, 0.05, -2.09, 0.43},
    },

    nightelf = {
        male = {3.26, -0.07, -2.21, 0.43},
        female = {3.38, -0.06, -2.09, 0.43},
    },

    orc = {
        male = {2.79, -0.06, -1.84, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    uprightorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    magharorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    pandaren = {
        male = {3.14, -0.11, -2.11, 0.43},
        female = {3.1, -0.16, -1.95, 0.43},
    },

    tauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    highmountaintauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    troll = {
        male = {2.79, -0.19, -2.01, 0.43},
        female = {3.43, 0.035, -2.19, 0.35},
    },

    scourge = {
        male = {3.37, 0.03, -1.6, 0.43},
        female = {3.39, -0.035, -1.665, 0.43},
    },

    vulpera = {
        male = {3.33, -0.05, -1.09, 0.26},
        female = {3.33, -0.04, -1.09, 0.26},
    },

    worgen = {
        male = {2.41, -0.18, -1.93, 0.43},
        female = {3.06, -0.04, -2.19, 0.52},
    },

    zandalaritroll = {
        male = {3.16, 0.05, -2.55, 0.52},
        female = {3.35, 0.04, -2.51, 0.44},
    },
};


local WORGEN_HUMAN_FORM_ID = 220;   --custom
local MAX_SAVES = 10;
local NUM_ACTIVE_BUTTONS = 0;
local CAMERA_PROFILE;
local ACTIVE_CAMERA_PROFILE;

local ScrollFrameCenterY;
local function UpdateScrollButtonAlpha(buttons)
    local button;
    local alpha;
    local x, y, dy;
    local abs = abs;
    for i = 1, NUM_ACTIVE_BUTTONS do
        button = buttons[i];
        x, y = button:GetCenter();
        dy = abs(y - ScrollFrameCenterY);
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
            end
        end
        button:SetAlpha(alpha);
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
    --local ScrollFrame = MainFrame.activeCategory;
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

local function UpdateScrollRange(ScrollFrame)
    if not ScrollFrame then
        ScrollFrame = MainFrame.activeCategory;
    end

    local range;
    local numButtons = NUM_ACTIVE_BUTTONS;
    if numButtons == 0 then
        range = 0;
    else
        range = (64 + 16) * numButtons -16 - ScrollFrame:GetHeight() + 14;   --the active sex is not neccessarily male, just use the male buttons for height referencing
        if range < 0 then
            range = 0;
        end
    end

    local scrollBar = ScrollFrame.scrollBar;
    scrollBar:SetMinMaxValues(0, range);
    ScrollFrame.range = range;
    scrollBar:SetShown(range ~= 0);

    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
    UpdateScrollBoundMark(ScrollFrame);

    if numButtons >= MAX_SAVES then
        PlusButton:SetCase(3);
    end
end

local function CreateSavedLooksButton(ScrollFrame, sex, isWorgen)
    local button;
    local buttons = {};
    local ScrollChild = ScrollFrame.ScrollChild;
    local buttonHeight = 64;
    local frameHeight = 4 * (buttonHeight + 16) - 2;
    ScrollFrame:SetSize(280, frameHeight);
    ScrollChild:SetSize(280, frameHeight);

    for i = 1, MAX_SAVES do
        button = CreateFrame("Button", nil, ScrollFrame.ClipFrame, "NarciBarberShopSavedLooksTemplate");
        tinsert(buttons, button);
        button:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button.order = i;
        button:Hide();
    end

    local deltaRatio = 1;
    local speedRatio = 0.14;
    local range = buttons[1]:GetTop() - buttons[MAX_SAVES]:GetBottom() - ScrollFrame:GetHeight() + 14;
    local parentScrollFunc;
    local positionFunc = function(endValue, delta, scrollBar, isTop, isBottom)
        ScrollButtonAlphaUpdater:Start();
        ScrollFrame.BoundTop:SetShown(not isTop);
        ScrollFrame.BoundBottom:SetShown(not isBottom);
        ScrollBoundMarkUpdater:Stop();
        ScrollFrame.BoundTop:SetAlpha(0.0);
        ScrollFrame.BoundBottom:SetAlpha(0.0);
        ScrollFrame.BoundTop:StopAnimating();
        ScrollFrame.BoundBottom:StopAnimating();
    end;

    local onScrollFinishedFunc = function()
        ScrollButtonAlphaUpdater:Stop();
        ScrollBoundMarkUpdater:Start();
        ScrollFrame.BoundTop.BoundTopArrow.spring:Play();
        ScrollFrame.BoundBottom.BoundBottomArrow.spring:Play();
    end

    ScrollBoundMarkUpdater.object1 = ScrollFrame.BoundTop;
    ScrollBoundMarkUpdater.object2 = ScrollFrame.BoundBottom;

    NarciAPI_ApplySmoothScrollToScrollFrame(ScrollFrame, deltaRatio, speedRatio, positionFunc, (buttonHeight + 16), range, parentScrollFunc, onScrollFinishedFunc);

    if sex == "male" then
        if isWorgen then
            WorgenMaleButtons = buttons;
        else
            MaleButtons = buttons;
        end
    else
        if isWorgen then
            WorgenFemaleButtons = buttons;
        else
            FemaleButtons = buttons;
        end
    end
end

local function GetOrcCameraProfile(model)
    local fileID = model:GetModelFileID();
    if fileID == 1968587 then
        --Upright
        return CAMERA_PROFILES_BY_RACE.uprightorc.male
    elseif fileID == 917116 then
        --Regular Orc and Maghar: 917116
        return CAMERA_PROFILES_BY_RACE.orc.male
    else
        return ACTIVE_CAMERA_PROFILE
    end
end

local function GetWorgenCameraProfile(model)
    local fileID = model:GetModelFileID();
    if fileID == 307453 then
        return CAMERA_PROFILES_BY_RACE.worgen.female
    elseif fileID == 307454 then
        return CAMERA_PROFILES_BY_RACE.worgen.male
    elseif fileID == 1000764 then
        return CAMERA_PROFILES_BY_RACE.human.female
    else
        return CAMERA_PROFILES_BY_RACE.human.male
    end
end

local function UpdatePortraitCameraGeneric(model, profile)
    if not profile then
        profile = ACTIVE_CAMERA_PROFILE;
    end
    if not profile then return end;

    local modelX, modelY, modelZ, modelFacing = unpack(profile);
    if modelFacing then
        model:MakeCurrentCameraCustom();
        model:SetFacing(modelFacing);
        model:SetPosition(modelX, modelY, modelZ);
        local cameraX, cameraY, cameraZ = model:TransformCameraSpaceToModelSpace(4, 0, 0);
        local targetX, targetY, targetZ = model:TransformCameraSpaceToModelSpace(0, 0, 0);
        model:SetCameraPosition(cameraX, cameraY, cameraZ);
        model:SetCameraTarget(targetX, targetY, targetZ);
        return true
    end
end

local UpdatePortraitCamera = UpdatePortraitCameraGeneric;

local function UpdatePortraitCameraForOrc(model)
    UpdatePortraitCameraGeneric(model, GetOrcCameraProfile(model))
end

local function UpdatePortraitCameraForWorgen(model)
    UpdatePortraitCameraGeneric(model, GetWorgenCameraProfile(model))
end

local IS_PLAYER_WORGEN, IS_HUMAN_FORM = false, false;
local DataProvider = {};
DataProvider.numMales = 0;
DataProvider.numFemales = 0;
DataProvider.numWorgenMales = 0;
DataProvider.numWorgenFemales = 0;
DataProvider.maleButtonOrder = {};
DataProvider.femaleButtonOrder = {};
DataProvider.worgenMaleButtonOrder = {};
DataProvider.worgenFemaleButtonOrder = {};

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
            --print(optionName.."("..optionID.."): "..choiceName.."("..choiceID..")");
            tinsert(selectedOptions, {optionID, choiceID} );
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

function DataProvider:LoadData()
    local _, _, raceID = UnitRace("player");
    self.raceID = raceID or 1;

    if not NarciBarberShopDB then
        NarciBarberShopDB = {};
    end

    local DB = NarciBarberShopDB;

    --wipe(DB) --!!TEST
    
    if not DB.PlayerData then
        DB.PlayerData = {};
    end

    local unitType, realmID, playerID = string.split("-", UnitGUID("player"));
    if not DB.PlayerData[playerID] then
        local playerName = UnitName("player");
        local realmName = GetRealmName();
        DB.PlayerData[playerID] = { SavedLooks = {} , realmID = realmID, playerName = playerName, realmName = realmName};
    end

    if not DB.PlayerData[playerID].SavedLooks[raceID] then
        DB.PlayerData[playerID].SavedLooks[raceID] = {male = {}, female = {}};
    end
    self.savedLooksByRace = DB.PlayerData[playerID].SavedLooks[raceID];

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    local raceName;
    if currentCharacterData then
        raceName = currentCharacterData.raceData.fileName;
    else
        raceName = "human";
    end

    raceName = strlower(raceName);

    CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryMale, "male");
    CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryFemale, "female");
    
    --Worgen in human form
    if raceID == 22 then
        raceID = WORGEN_HUMAN_FORM_ID;
        raceName = "human";
        IS_PLAYER_WORGEN = true;
        if not DB.PlayerData[playerID].SavedLooks[raceID] then
            DB.PlayerData[playerID].SavedLooks[raceID] = { male = {}, female = {} };
        end
        self.savedLooksInHumanForm = DB.PlayerData[playerID].SavedLooks[raceID];
        --MainFrame.SavedLooksFrame.CategoryWorgenMale = CreateFrame("ScrollFrame", nil, MainFrame.SavedLooks, "NarciBarberShopScrollFrameTemplate");
        --MainFrame.SavedLooksFrame.CategoryWorgenFemale = CreateFrame("ScrollFrame", nil, MainFrame.SavedLooks, "NarciBarberShopScrollFrameTemplate");
        CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryWorgenMale, "male", IS_PLAYER_WORGEN);
        CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryWorgenFemale, "female", IS_PLAYER_WORGEN);

        UpdatePortraitCamera = UpdatePortraitCameraForWorgen;
    end

    CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[raceName];

    local sexString;
    local useHiRez = true;
    
    local raceAtlasMale = GetRaceAtlas(raceName, "male", useHiRez);
    local raceAtlasFemale = GetRaceAtlas(raceName, "female", useHiRez);

    if raceName == "orc" or raceName == "magharorc" then
        UpdatePortraitCamera = UpdatePortraitCameraForOrc;
    end

    --NarciDevReferencePortrait:SetAtlas(raceAtlasMale);

    self.raceAtlasMale = raceAtlasMale;
    self.raceAtlasFemale = raceAtlasFemale;

    local maleDB = DB.PlayerData[playerID].SavedLooks[raceID].male;
    local femaleDB = DB.PlayerData[playerID].SavedLooks[raceID].female;
    local numMales =  #maleDB;
    local numFemales = #femaleDB;

    self.numMales = numMales;
    self.numFemales = numFemales;
    
    for i = 1, MAX_SAVES do
        self.maleButtonOrder[i] = i; 
        self.femaleButtonOrder[i] = i; 
        self.worgenMaleButtonOrder[i] = i;
        self.worgenFemaleButtonOrder[i] = i;
    end

    local function SetUpSavedLooksButton(buttonPool, dataSource, atlas)
        for i = 1, #dataSource do
            if i <= 4 then
                buttonPool[i]:Show();
            end
            buttonPool[i]:SetInfo(dataSource[i]);
            buttonPool[i].Portrait:SetAtlas(atlas);
        end
    end

    SetUpSavedLooksButton(MaleButtons, maleDB, raceAtlasMale);
    SetUpSavedLooksButton(FemaleButtons, femaleDB, raceAtlasFemale);

    --Worgen
    if IS_PLAYER_WORGEN then
        raceID = 22;
        maleDB = DB.PlayerData[playerID].SavedLooks[raceID].male;
        femaleDB = DB.PlayerData[playerID].SavedLooks[raceID].female;
        numMales =  #maleDB;
        numFemales = #femaleDB;
        self.numWorgenMales = numMales;
        self.numWorgenFemales = numFemales;
        raceAtlasMale = GetRaceAtlas("worgen", "male", useHiRez);
        raceAtlasFemale = GetRaceAtlas("worgen", "female", useHiRez);
        --NarciDevReferencePortrait:SetAtlas(raceAtlasFemale);
        SetUpSavedLooksButton(WorgenMaleButtons, maleDB, raceAtlasMale);
        SetUpSavedLooksButton(WorgenFemaleButtons, femaleDB, raceAtlasFemale);
    end
end

function DataProvider:GetRandomAppearance()
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
    local isUnique = self:CheckAndSaveLooks(newLooks, nil, checkOnly);
    return isUnique
end

function DataProvider:IsCharacterDataUnique(customizationData)
    local sex = self.currentSex or 0;
    local SavedLooks;
    local newLooks = self:GetCurrentSelection(customizationData);
    
    if IS_PLAYER_WORGEN then
        if IS_HUMAN_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksInHumanForm.male;
            else
                SavedLooks = self.savedLooksInHumanForm.female;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
            else
                SavedLooks = self.savedLooksByRace.female;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
        else
            SavedLooks = self.savedLooksByRace.female;
        end
    end

    local isUnique = true;
    local tempTable = {};
    local numLooks = #SavedLooks;
    local data;
    for i = 1, numLooks do
        wipe(tempTable);
        data = SavedLooks[i].data;
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


function DataProvider:CheckAndSaveLooks(newLooks, generatedDescription, checkOnly)
    if not newLooks then return false end;

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    if not currentCharacterData then return false end;
    
    local sex = currentCharacterData.sex;

    local SavedLooks;

    if IS_PLAYER_WORGEN then
        if IS_HUMAN_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksInHumanForm.male;
            else
                SavedLooks = self.savedLooksInHumanForm.female;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
            else
                SavedLooks = self.savedLooksByRace.female;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
        else
            SavedLooks = self.savedLooksByRace.female;
        end
    end

    local isUnique = true;
    local data;

    local tempTable = {};
    local numLooks = #SavedLooks;
    for i = 1, numLooks do
        wipe(tempTable);
        data = SavedLooks[i].data;
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

    local looksName = "New Look #"..(numLooks);
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
            tinsert(SavedLooks, 1, {name = looksName , description = generatedDescription, data = newLooks, timeCreated = currentTime});
            return SavedLooks[1], numLooks
        end
    end
end

function DataProvider:SaveNewLooks()
    if NUM_ACTIVE_BUTTONS >= MAX_SAVES then
        return
    end
    local generateDescription = true;
    local newLooks, generatedDescription = DataProvider:GetCurrentSelection(nil, generateDescription);
    local data, numLooks = self:CheckAndSaveLooks(newLooks, generatedDescription);
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
        --buttonPool[ orderTable[i] ]:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
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
    local sex = self.currentSex;

    local SavedLooks, OrderTable, ButtonPool, categoryID;
    if IS_PLAYER_WORGEN then
        if IS_HUMAN_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksInHumanForm.male;
                OrderTable = self.maleButtonOrder;
                ButtonPool = MaleButtons;
                categoryID = 1;
            else
                SavedLooks = self.savedLooksInHumanForm.female;
                OrderTable = self.femaleButtonOrder;
                ButtonPool = FemaleButtons;
                categoryID = 2;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
                OrderTable = self.worgenMaleButtonOrder;
                ButtonPool = WorgenMaleButtons;
                categoryID = 3;
            else
                SavedLooks = self.savedLooksByRace.female;
                OrderTable = self.worgenFemaleButtonOrder;
                ButtonPool = WorgenFemaleButtons;
                categoryID = 4;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
            OrderTable = self.maleButtonOrder;
            ButtonPool = MaleButtons;
            categoryID = 1;
        else
            SavedLooks = self.savedLooksByRace.female;
            OrderTable = self.femaleButtonOrder;
            ButtonPool = FemaleButtons;
            categoryID = 2;
        end
    end

    local numLooks = #SavedLooks;
    local position;
    for i = 1, numLooks do
        if SavedLooks[i] == dataSource then
            position = i;
            break
        end
    end
    if position then
        for i = position, numLooks do
            SavedLooks[i] = SavedLooks[i + 1];
        end

        local removedIndex = tremove(OrderTable, position);
        tinsert(OrderTable, removedIndex);

        local removedButton = tremove(ButtonPool, position);
        removedButton.isPortraitLoaded = false;
        tinsert(ButtonPool, removedButton);
        --RepositionButtons(ButtonPool);

        if categoryID == 1 then
            self.numMales = self.numMales - 1;
        elseif categoryID == 2 then
            self.numFemales = self.numFemales - 1;
        elseif categoryID == 3 then
            self.numWorgenMales = self.numWorgenMales - 1;
        elseif categoryID == 4 then
            self.numWorgenFemales = self.numWorgenFemales - 1;
        end
        NUM_ACTIVE_BUTTONS = NUM_ACTIVE_BUTTONS - 1;

        return ButtonPool, removedButton, position
    end
end

function DataProvider:GetButton()
    local currentCharacterData =  C_BarberShop.GetCurrentCharacterData();
    if not currentCharacterData then
        print("Error: No Character Data");
        return
    end
    local sex = currentCharacterData.sex;
    if sex == 0 then
        if IS_PLAYER_WORGEN then
            if IS_HUMAN_FORM then
                self.numMales = self.numMales + 1;
                if self.numMales > MAX_SAVES then
                    self.numMales = MAX_SAVES;
                end
                InsertButtonToTop(MaleButtons, self.numMales);
                return MaleButtons[1], MaleButtons;
            else
                self.numWorgenMales = self.numWorgenMales + 1;
                if self.numWorgenMales > MAX_SAVES then
                    self.numWorgenMales = MAX_SAVES;
                end
                InsertButtonToTop(WorgenMaleButtons, self.numWorgenMales);
                return WorgenMaleButtons[1], WorgenMaleButtons;
            end
        else
            self.numMales = self.numMales + 1;
            if self.numMales > MAX_SAVES then
                self.numMales = MAX_SAVES;
            end
            InsertButtonToTop(MaleButtons, self.numMales);
            return MaleButtons[1], MaleButtons;
        end
    elseif sex == 1 then
        if IS_PLAYER_WORGEN then
            if IS_HUMAN_FORM then
                self.numFemales = self.numFemales + 1;
                if self.numFemales > MAX_SAVES then
                    self.numFemales = MAX_SAVES;
                end
                InsertButtonToTop(FemaleButtons, self.numFemales);
                return FemaleButtons[1], FemaleButtons;
            else
                self.numWorgenFemales = self.numWorgenFemales + 1;
                if self.numWorgenFemales > MAX_SAVES then
                    self.numWorgenFemales = MAX_SAVES;
                end
                local index = self.worgenFemaleButtonOrder[self.numWorgenFemales];
                InsertButtonToTop(WorgenFemaleButtons, self.numWorgenFemales);
                return WorgenFemaleButtons[1], WorgenFemaleButtons;
            end
        else
            self.numFemales = self.numFemales + 1;
            if self.numFemales > MAX_SAVES then
                self.numFemales = MAX_SAVES;
            end
            local index = self.femaleButtonOrder[self.numFemales];
            InsertButtonToTop(FemaleButtons, self.numFemales);
            return FemaleButtons[1], FemaleButtons;
        end
    else
        print("Error: Unknown Gender");
        return
    end
end


local function RandomizeApperance()
    local data = DataProvider:GetRandomAppearance();
    if not data then return end;

    for i = 1, #data do
        local optionID, choiceID = unpack(data[i]);
        C_BarberShop.SetCustomizationChoice(optionID, choiceID);
    end
    BarberShopFrame:UpdateCharCustomizationFrame()
end

local function SetFontStringShadow(fontString)
    fontString:SetShadowColor(0, 0, 0);
    fontString:SetShadowOffset(1, -1);
end

-------------------------------------------------------------
NarciBarberShopSavedLooksMixin = {};


function NarciBarberShopSavedLooksMixin:OnLoad()
    self.Portrait:SetVertexColor(0.5, 0.5, 0.5);
    self.Portrait:SetDesaturation(0.6);
    SetFontStringShadow(self.Description);

    local Model = self.Model;
    Model:SetUnit("player");
    Model:SetKeepModelOnHide(true);
    Model:SetFacing(pi/24);
    Model:SetLight(true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
    Model:SetCamera(0);
    self:SetPortraitZoom(1);
    Model:SetAnimation(0, 0);
    Model:SetPaused(true);
    Model:SetScript("OnModelLoaded", function()
        Model:SetCamera(0);
        Model:SetAnimation(0, 0);
        Model:SetPaused(true);
        self:SetPortraitZoom(0.975);
        self:SetPortraitZoom(1);
    end);
    Model:SetViewTranslation(0, 0);

    --Animation Frame
    --[[
    local animZoom = NarciAPI_CreateAnimationFrame(0.35);
    animZoom:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local zoom = inOutSine(frame.total, frame.fromZoom, frame.toZoom, frame.duration);
        if frame.total >= frame.duration then
            zoom = frame.toZoom;
            frame:Hide();
        end

        self:SetPortraitZoom(zoom);
    end);

    function self:ZoomModel(fromValue, value)
        animZoom:Hide();
        local currentZoom = self:GetPortraitZoom();
        animZoom.fromZoom = currentZoom;
        animZoom.toZoom = value;
        local duration = sqrt( abs( (currentZoom - value)/0.025) ) * 0.35;
        animZoom.duration = duration;
        if duration > 0 then
            animZoom:Show();
        end
    end
    --]]

    self:OnLeave();
end

function NarciBarberShopSavedLooksMixin:SetPortraitZoom(value)
    self.Model:SetPortraitZoom(value);
    self.portraitZoom = value;
end

function NarciBarberShopSavedLooksMixin:GetPortraitZoom(value)
    return self.portraitZoom or 1;
end

function NarciBarberShopSavedLooksMixin:RefreshPortrait(forcedRefresh)
    if (not self.isPortraitLoaded) or (forcedRefresh) then
        self.Model:Show();
        self.Portrait:Hide();
        self.PortraitText:Hide();
        self.isPortraitLoaded = true;
        self.Model:RefreshUnit();
        UpdatePortraitCamera(self.Model);
    end
end

function NarciBarberShopSavedLooksMixin:UpdateText()
    local textHeight = self.Name:GetHeight() + self.Description:GetHeight() + 6;
    self.Reference:SetHeight(textHeight);
end

function NarciBarberShopSavedLooksMixin:SetInfo(dataSource)
    self.dataSource = dataSource;
    self.Name:SetText(dataSource.name);
    self.Description:SetText(dataSource.description);
    self.appearanceData = dataSource.data;
    self:UpdateText()
end

function NarciBarberShopSavedLooksMixin:OnEnter()
    self.Name:SetAlpha(1);
    self.Description:SetAlpha(1);
    UIFrameFadeIn(self.RingHighlight, 0.15, self.RingHighlight:GetAlpha(), 1);
    MainFrame:FadeIn(0.2);
    --self.Model:SetPaused(false);  --Playing character idle animation seems distractive, disabled

    EditButton:SetParentObject(self);
    DeleteButton:SetParentObject(self);
end

function NarciBarberShopSavedLooksMixin:OnLeave()
    if self:IsMouseOver() then
        return
    end
    self.Name:SetAlpha(0.66);
    self.Description:SetAlpha(0.66);
    UIFrameFadeIn(self.RingHighlight, 0.25, self.RingHighlight:GetAlpha(), 0);
    MainFrame:OnLeave();

    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopSavedLooksMixin:OnClick()
    self:UpdateCustomization();
    if not self.isPortraitLoaded then
        After(0.1, function()
            self:RefreshPortrait();
        end)
    end
end

function NarciBarberShopSavedLooksMixin:LoadPortrait()
    self:UpdateCustomization(true);
    if not self.isPortraitLoaded then
        After(0.1, function()
            self:RefreshPortrait();
        end)
    end
end

local SetCustomizationChoice = C_BarberShop.SetCustomizationChoice;
function NarciBarberShopSavedLooksMixin:UpdateCustomization(dontUpdateButton)
    if not self.appearanceData then return end

    local BarberShopFrame = BarberShopFrame;
    for i = 1, #self.appearanceData do
        local optionID, choiceID = unpack(self.appearanceData[i]);
        SetCustomizationChoice(optionID, choiceID);
        --C_BarberShop.PreviewCustomizationChoice(optionID, choiceID);
    end
    if not dontUpdateButton then
        BarberShopFrame:UpdateCharCustomizationFrame();
    end
end


----------------------------------
local DURATION_FADE_OUT = 1.5;

local autoHideTimer = NarciAPI_CreateAnimationFrame(4);
autoHideTimer:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide();
        if not MainFrame:IsMouseOver() then
            MainFrame:FadeOut(DURATION_FADE_OUT);
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

function ScrollToTop(ScrollFrame)
    animScrollFrame:ScrollToTop(ScrollFrame)
    --/run ScrollToTop(Narci_BarbershopFrame.SavedLooksFrame.CategoryFemale)
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

function NarciBarberShopPlusButtonMixin:SetCase(index)
    if index == 1 then
        self.Label:SetText(self.tooltipDefault);
        self:Enable();
    elseif index == 2 then
        self.Label:SetText(self.tooltipSaved);
        self:Disable();
    elseif index == 3 then
        self.Label:SetText(self.tooltipReachMax);
        self:Disable();
    elseif index == 4 then
        self.Label:SetText(self.tooltipShapeShifted);
        self:Disable();
    end
end

function NarciBarberShopPlusButtonMixin:OnEnter()
    self.Label:SetAlpha(1);
    MainFrame:OnEnter();
    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopPlusButtonMixin:OnLeave()
    self.Label:SetAlpha(0.66);
end

function NarciBarberShopPlusButtonMixin:OnClick()
    --Save new Looks

    local data = DataProvider:SaveNewLooks();
    if data then
        local button, buttonPool = DataProvider:GetButton();
        if button then
            animScrollButtons:InsertNewButton(buttonPool, button);
            button:SetInfo(data);
            button:Show();
            EditBox:SetParentObject(button, true);
            After(0.1, function()
                button:RefreshPortrait();
            end)
        end
    end
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
end

function NarciBarberShopEditButtonMixin:OnEnter()
    self:GetParent():OnEnter();
    self.Tooltip:Show();
end

function NarciBarberShopEditButtonMixin:OnLeave()
    MainFrame:OnLeave();
    self:GetParent():OnLeave();
    self.Tooltip:Hide();
end

function NarciBarberShopEditButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
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

    self.Ring:SetDrawLayer("BORDER");
end

function NarciBarberShopDeleteButtonMixin:SetParentObject(object)
    self:SetParent(object);
    self:Show();
    self:OnMouseUp();
end

function NarciBarberShopDeleteButtonMixin:OnClick()

end

function NarciBarberShopDeleteButtonMixin:OnLongClick()
    local ButtonPool, removedButton = DataProvider:DeleteLooks(self:GetParent().dataSource);
    if ButtonPool then
        DataProvider:IsCharacterDataUnique();
        animScrollButtons:RemoveOldButton(ButtonPool, removedButton);
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
    self.Ring:Hide();
end

function NarciBarberShopDeleteButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
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
end

function NarciBarberShopEditBoxMixin:OnHide()
    self:HighlightText(0, 0);
    self:ClearFocus();
    self:Hide();
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
end

----------------------------------
--Main Frame


--Hotkey
local RotateBarberShopCamera = C_BarberShop.RotateCamera;
local CameraRotator = CreateFrame("Frame");
CameraRotator:Hide();
CameraRotator.speed = 0;
CameraRotator.maxSpeed = 2.5;
CameraRotator.direction = 1;    --Counterclockwise
CameraRotator:SetScript("OnUpdate", function(self, elapsed)
    local direction = self.direction;
    local speed = self.speed + 12 * elapsed * direction;
    if direction > 0 then
        if speed > self.maxSpeed then
            speed = self.maxSpeed;
        end
    elseif direction < 0 then
        if speed <= -self.maxSpeed then
            speed = -self.maxSpeed;
        end
    else
        --inertia
        if self.lastDirection > 0 then
            speed = speed - 16 * elapsed;
            if speed <= 0 then
                speed = 0;
                self.lastDirection = 0;
                self:Hide();
            end
        else
            speed = speed + 16 * elapsed;
            if speed >= 0 then
                speed = 0;
                self.lastDirection = 0;
                self:Hide();
            end
        end
    end

    self.speed = speed;
    RotateBarberShopCamera(speed);
end)

local ZoomCamera = C_BarberShop.ZoomCamera;
local CameraZoomer = CreateFrame("Frame");
CameraZoomer:Hide();
CameraZoomer.direction = 1;
CameraZoomer.amountPerSecond = 150;
CameraZoomer:SetScript("OnUpdate", function(self, elapsed)
    ZoomCamera( self.direction * self.amountPerSecond * elapsed );
end)


local function RotateBarberShopCameraLeft()
    CameraRotator:Hide();
    CameraRotator.direction = -1;
    CameraRotator.lastDirection = -1;
    CameraRotator:Show();
end

local function RotateBarberShopCameraRight()
    CameraRotator:Hide();
    CameraRotator.direction = 1;
    CameraRotator.lastDirection = 1;
    CameraRotator:Show();
end

local function StopRotatingCamera()
    CameraRotator.direction = 0;
end

local function ZoomCameraIn()
    CameraZoomer:Hide();
    CameraZoomer.direction = 1;
    CameraZoomer:Show();
end

local function ZoomCameraOut()
    CameraZoomer:Hide();
    CameraZoomer.direction = -1;
    CameraZoomer:Show();
end

local function StopZoomingCamera()
    CameraZoomer:Hide();
end

local HotkeyList = {
    --[key] = {downFunc, upFunc, commandName},
};

local HotkeyManager = {};

HotkeyManager.buttons = {};

HotkeyManager.ignoredKeys = {
	LALT = 1,
	RALT = 2,
	LCTRL = 3,
	RCTRL = 4,
	LSHIFT = 5,
	RSHIFT = 6,
	LMETA = 7,
	RMETA = 8,
	ALT = 9,
	CTRL = 10,
	SHIFT = 11,
    META = 12,
    UNKNOWN = true,
	BUTTON1 = true,
    BUTTON2 = true,
    BUTTON3 = true,
};

HotkeyManager.CommandList = {
    --[name] = {downFunc, upFunc, defaultKey, customKey},
    ["RotateLeft"] = {
        onMouseDownFunc = RotateBarberShopCameraLeft,
        onMouseUpFunc = StopRotatingCamera,
        defaultKey = "A",
        defaultKeyFrench = "Q",
    },

    ["RotateRight"] = {
        onMouseDownFunc = RotateBarberShopCameraRight,
        onMouseUpFunc = StopRotatingCamera,
        defaultKey = "D",
        defaultKeyFrench = "D",
    },

    ["ZoomIn"] = {
        onMouseDownFunc = ZoomCameraIn,
        onMouseUpFunc = StopZoomingCamera,
        defaultKey = "W",
        defaultKeyFrench = "Z",
    },

    ["ZoomOut"] = {
        onMouseDownFunc = ZoomCameraOut,
        onMouseUpFunc = StopZoomingCamera,
        defaultKey = "S",
        defaultKeyFrench = "S",
    },
};

function HotkeyManager:LoadHotkeys()
    --Check French Keyboard
    --GetOSLocale, GetLocale
    local isAZERTY = false;
    local key1, key2 = GetBindingKey("MOVEFORWARD");
    if key1 == "Z" or key2 == "Z" then
        isAZERTY = true;
    end

    ----
    local DB = NarciBarberShopDB;
    if not DB.Hotkeys then
        DB.Hotkeys = {};
    end
    for command, data in pairs(self.CommandList) do
        local key = DB.Hotkeys[command];
        if not key then
            if isAZERTY then
                key = data.defaultKeyFrench;
            else
                key = data.defaultKey;
            end
            DB.Hotkeys[command] = key;
        end
        if key ~= "NONE" then
            HotkeyList[key] = {data.onMouseDownFunc, data.onMouseUpFunc, command};
        end
    end
end

function HotkeyManager:SetHotkey(command, newKey)
    if command and self.CommandList[command] then
        local overriddenCommand;
        --Check conflicted command
        for key, v in pairs(HotkeyList) do
            if v then
                if v[3] == command then
                    HotkeyList[key] = nil;
                elseif key == newKey then
                    overriddenCommand = v[3];
                    HotkeyList[key] = nil;
                    NarciBarberShopDB.Hotkeys[overriddenCommand] = "NONE";
                    --print("Conflict: "..overriddenCommand)
                end 
            end
        end

        local success;
        if newKey then
            if self.ignoredKeys[newKey] then
                success = false;
            else
                HotkeyList[newKey] = {self.CommandList[command].onMouseDownFunc, self.CommandList[command].onMouseUpFunc, command};
                NarciBarberShopDB.Hotkeys[command] = newKey;
                success = true;
            end
        else
            --An empty newKey will unbind the command
            NarciBarberShopDB.Hotkeys[command] = "NONE";
            success = true;
        end

        self:RefreshKeybindingButtons();

        return success
    end
end

function HotkeyManager:GetHotkey(command)
    if command and self.CommandList[command] then
        return NarciBarberShopDB.Hotkeys[command];
    end
end

function HotkeyManager:RefreshKeybindingButtons()
    for i = 1, #self.buttons do
        local key = self:GetHotkey(self.buttons[i].command);
        self.buttons[i]:SetText( key );
    end
end

NarciBarberShopMixin = {};

function NarciBarberShopMixin:OnLoad()
    MainFrame = self;
    
    NarciAPI_CreateFadingFrame(self);
end

function NarciBarberShopMixin:OnKeyDown(key)
    local funcs = HotkeyList[key];
    if funcs and funcs[1] then
        funcs[1]();
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:ToggleNotification(state)
    self.checkUniqueness = state;
end

function NarciBarberShopMixin:ToggleRandomizeAppearanceButton(visible)
    local button = CharCustomizeFrame.RandomizeAppearanceButton;
    if button then
        button:SetShown(visible);
        button:SetScript("OnClick", RandomizeApperance);
    end
end

function NarciBarberShopMixin:OnKeyUp(key)
    local funcs = HotkeyList[key];
    if funcs and funcs[2] then
        funcs[2]();
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:OnShow()
    local _;
    _, ScrollFrameCenterY = self.SavedLooksFrame.CategoryMale:GetCenter();
    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
end

function NarciBarberShopMixin:OnHide()
    ScrollButtonAlphaUpdater:Stop();
    CameraZoomer:Hide();
    CameraRotator:Hide();
end

function NarciBarberShopMixin:OnEnter()
    autoHideTimer:Hide();
    self:FadeIn(0.2);
end

function NarciBarberShopMixin:OnLeave()
    if not self:IsMouseOver() and not IsMouseButtonDown() then
        autoHideTimer:Show();
    end
end

local PortraitLoader = CreateFrame("Frame");
PortraitLoader.t = 0;
PortraitLoader.index = 1;
PortraitLoader:Hide();
PortraitLoader:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.12 then
        self.t = 0;
        local button = self.buttons[self.index];
        if button and button.appearanceData then
            button:LoadPortrait();
            self.index = self.index + 1;
        else
            BarberShopFrame:RegisterEvent("BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE");
            self:Hide();
            local sex = UnitSex("player");
            if self.sex == 0 then
                if self.isWorgen then
                    self.isWorgenMaleLoaded = true;
                else
                    self.isMaleLoaded = true;
                end
                if self.index ~= 1 then
                    if sex == 2 then
                        C_BarberShop.ResetCustomizationChoices();
                    else
                        BarberShopFrame:UpdateCharCustomizationFrame();
                    end
                end
            elseif self.sex == 1 then
                if self.isWorgen then
                    self.isWorgenFemaleLoaded = true;
                else
                    self.isFemaleLoaded = true;
                end
                if self.index ~= 1 then
                    if sex == 3 then
                        C_BarberShop.ResetCustomizationChoices();
                    else
                        BarberShopFrame:UpdateCharCustomizationFrame();
                    end
                end
            end
            self.index = 1;
        end
    end
end)

function PortraitLoader:Load(sex)
    self:Hide();
    self.sex = sex;
    if IS_PLAYER_WORGEN and not IS_HUMAN_FORM then
        self.isWorgen = true;
        if sex == 0 and not self.isWorgenMaleLoaded then
            self.buttons = WorgenMaleButtons;
            After(0, function()
                self:Show();
            end)
            BarberShopFrame:UnregisterEvent("BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE");
            BarberShopFrame:UpdateCharCustomizationFrame();
        elseif sex == 1 and not self.isWorgenFemaleLoaded then
            self.buttons = WorgenFemaleButtons;
            After(0, function()
                self:Show();
            end)
            BarberShopFrame:UnregisterEvent("BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE");
            BarberShopFrame:UpdateCharCustomizationFrame();
        end
    else
        self.isWorgen = false;
        if sex == 0 and not self.isMaleLoaded then
            self.buttons = MaleButtons;
            After(0, function()
                self:Show();
            end)
            BarberShopFrame:UnregisterEvent("BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE");
            BarberShopFrame:UpdateCharCustomizationFrame();
        elseif sex == 1 and not self.isFemaleLoaded then
            self.buttons = FemaleButtons;
            After(0, function()
                self:Show();
            end)
            BarberShopFrame:UnregisterEvent("BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE");
            BarberShopFrame:UpdateCharCustomizationFrame();
        end
    end
end

function NarciBarberShopMixin:ToggleSaves(visible)
    --For Shapeshifter
    if visible then
        self.SavedLooksFrame:Show();
        self:FadeIn(0.2);
    else
        PlusButton:SetCase(4);
        self.SavedLooksFrame:Hide();
        self:SetAlpha(0);
    end
end

function NarciBarberShopMixin:UpdateGenderCategory(sex)
    self:FadeIn(0.2);
    autoHideTimer:Hide();
    autoHideTimer:Show();

    if not sex then
        local currentCharacterData =  C_BarberShop.GetCurrentCharacterData();
        if currentCharacterData then
            sex = currentCharacterData.sex;
        else
            print("Error: No Character Data");
            return
        end
    end
    
    DataProvider.currentSex = sex;

    if IS_PLAYER_WORGEN then
        IS_HUMAN_FORM = C_BarberShop.IsViewingAlteredForm();
        if sex == self.lastSex and IS_HUMAN_FORM == self.lastFrom then
            return
        else
            self.lastSex = sex;
            self.lastFrom = IS_HUMAN_FORM;
        end
    else
        if sex == self.lastSex then
            return
        else
            self.lastSex = sex;
        end
    end

    local activeCategory;
    if sex == 0 then
        if IS_PLAYER_WORGEN then
            if IS_HUMAN_FORM then
                activeCategory = self.SavedLooksFrame.CategoryMale;
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryWorgenMale:Hide();
                self.SavedLooksFrame.CategoryWorgenFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = MaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numMales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE.human.male;
            else
                activeCategory = self.SavedLooksFrame.CategoryWorgenMale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryWorgenFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = WorgenMaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numWorgenMales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE.worgen.male;
            end
        else
            activeCategory = self.SavedLooksFrame.CategoryMale;
            self.SavedLooksFrame.CategoryFemale:Hide();
            ScrollButtonAlphaUpdater.activeButtons = MaleButtons;
            NUM_ACTIVE_BUTTONS = DataProvider.numMales;
            ACTIVE_CAMERA_PROFILE = CAMERA_PROFILE.male;
        end
    else
        if IS_PLAYER_WORGEN then
            if IS_HUMAN_FORM then
                activeCategory = self.SavedLooksFrame.CategoryFemale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryWorgenMale:Hide();
                self.SavedLooksFrame.CategoryWorgenFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = FemaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numFemales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE.human.female;
            else
                activeCategory = self.SavedLooksFrame.CategoryWorgenFemale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryWorgenMale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = WorgenFemaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numWorgenFemales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE.worgen.female;
            end
        else
            activeCategory = self.SavedLooksFrame.CategoryFemale;
            self.SavedLooksFrame.CategoryMale:Hide();
            ScrollButtonAlphaUpdater.activeButtons = FemaleButtons;
            NUM_ACTIVE_BUTTONS = DataProvider.numFemales;
            ACTIVE_CAMERA_PROFILE = CAMERA_PROFILE.female;
        end
    end
    self.activeCategory = activeCategory;


    PortraitLoader:Load(sex);
    activeCategory:Show();
    ScrollBoundMarkUpdater:Hide();
    ScrollBoundMarkUpdater.object1 = activeCategory.BoundTop;
    ScrollBoundMarkUpdater.object2 = activeCategory.BoundBottom;

    UpdateScrollRange(activeCategory);
end

-----------------------------------------------------------------
local function InitializeBarberShopFrame()
    local frame = Narci_BarbershopFrame;
    frame:ClearAllPoints();
    frame:SetParent(BarberShopFrame);
    frame:SetPoint("TOPLEFT", BarberShopFrame, "TOPLEFT", 0, -95);
    frame:ToggleRandomizeAppearanceButton(true);
    frame:Show();

    --Yogg-Salon Mockup
    if false then   --Narci_InteractiveSplash
        local MoneyFrame = CreateFrame("Frame", nil, BarberShopFrame, "NarciBarberShopDiscountMoneyFrameTemplate");
        MoneyFrame:ClearAllPoints();
        local PriceFrame = BarberShopFrame.PriceFrame;
        if not PriceFrame then return end;

        function PriceFrame:SetFakeAmount(rawCopper)
            self.rawCopper = rawCopper;
            
            local gold = floor(rawCopper / (COPPER_PER_SILVER * SILVER_PER_GOLD));
            local silver = floor((rawCopper - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
            local copper = mod(rawCopper, COPPER_PER_SILVER);
            self.GoldDisplay:SetAmount(gold);
            self.SilverDisplay:SetAmount(silver);
            self.CopperDisplay:SetAmount(copper);
            if self.resizeToFit then
                self:UpdateWidth();
            else
                self:UpdateAnchoring();
            end
        end

        local isDiscountEnabled = true;
        MoneyFrame:SetScript("OnEnter", function(self)
            local tooltip = CharCustomizeNoHeaderTooltip;
            if tooltip then
                tooltip:SetOwner(self, "ANCHOR_NONE");
                tooltip:SetPoint("BOTTOM", self, "TOP", 0, 4);
                tooltip:AddLine("|cffec008cYogg Salon|r Special Offer Day", 1, 0.82, 0, true, 0);
                tooltip:AddLine("(Right click to refuse Offer.)", 0.5, 0.5, 0.5, true, 0);
                tooltip:Show();
            end
        end);
        MoneyFrame:SetScript("OnLeave", function(self)
            local tooltip = CharCustomizeNoHeaderTooltip;
            if tooltip then
                tooltip:Hide();
            end
        end);
        MoneyFrame:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                self:Hide();
                isDiscountEnabled = false;
                PriceFrame:SetFakeAmount( 0.999*(PriceFrame.rawCopper or 0) );
            end
        end);


        MoneyFrame:SetFrameLevel(PriceFrame:GetFrameLevel() + 1);
        MoneyFrame:SetPoint("BOTTOM", PriceFrame, "TOP", 0, 4);
        MoneyFrame.RedLine:ClearAllPoints();
        MoneyFrame.RedLine:SetPoint("LEFT", PriceFrame, "LEFT", -2, 0);
        MoneyFrame.RedLine:SetPoint("RIGHT", PriceFrame, "RIGHT", 2, 0);
        hooksecurefunc(PriceFrame, "SetAmount", function(self, rawCopper)
            if isDiscountEnabled then
                MoneyFrame:SetShown(rawCopper ~= 0);
                MoneyFrame:SetAmount(rawCopper);
                self:SetFakeAmount(rawCopper / 0.999);
            end
        end);
    end
    --The WoW default action is automatically closing the BarberShopFrame
    --But here we want to check if the newly applied appearance is unique and notifiy user to save it
    BarberShopFrame:UnregisterEvent("BARBER_SHOP_APPEARANCE_APPLIED");

    SettingFrame:Initialize();
end

--/run TestPlayerModel:SetZoomDistance()
local function RefreshModel()
    After(0.1, function()
        TestPlayerModel:RefreshUnit();
    end)
end

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
        MainFrame:UpdateGenderCategory(sexID);
    end);

    hooksecurefunc(C_BarberShop, "SetViewingShapeshiftForm", function(formID)
        if formID then
            MainFrame:ToggleSaves(false);
        else
            MainFrame:ToggleSaves(true);
        end
    end);

    if IS_PLAYER_WORGEN then
        hooksecurefunc(C_BarberShop, "SetViewingAlteredForm", function(viewingAlteredForm)
            MainFrame:UpdateGenderCategory();
        end);
    end

    --Add looks uniqueness check
    --Constantly monitor this mixin!!
    function BarberShopFrame:UpdateCharCustomizationFrame(alsoReset)
        local customizationCategoryData = C_BarberShop.GetAvailableCustomizations();
        if not customizationCategoryData then
            return;
        end

        DataProvider:IsCharacterDataUnique(customizationCategoryData);

        if alsoReset then
            CharCustomizeFrame:Reset();
        end
        CharCustomizeFrame:SetCustomizations(customizationCategoryData);
        self:UpdatePrice();
    end
end

------------------------------------------------------------------------------
--Statistics
local StatManager = {};
StatManager.widgets = {};
StatManager.LocationFrames = {};

function StatManager:LoadData()
    if not NarciStatisticsDB_PC.Barbershop then
        NarciStatisticsDB_PC.Barbershop = {};
    end

    if not NarciStatisticsDB_PC.Barbershop.Locations then
        NarciStatisticsDB_PC.Barbershop.Locations = {};   --[mapID] = {visit, time};
    end

    self.DB = NarciStatisticsDB_PC.Barbershop;
end

function StatManager:StartTimer()
    self.startTime = time();
end

function StatManager:StopTimer()
    if self.startTime then
        local stopTime = time();
        local duration = stopTime - self.startTime;
        self.startTime = 0;

        local mapID = self.mapID;
        if mapID then
            self.DB.Locations[mapID].time = self.DB.Locations[mapID].time + duration;
        end
    end
end

function StatManager:UpdateLocationFrame()
    local Locations = self.DB.Locations;
    local list = {};
    for mapID, data in pairs(Locations) do
        tinsert(list, {mapID, data.visit, data.time});
    end
    if #list > 0 then
        table.sort(list, function(a, b) return a[1] < b[1] end );
        local timestamp = time();
        local mapID = self.mapID;
        for i = 1, #list do
            local widget = self.LocationFrames[i];
            if not widget then
                widget = CreateFrame("Frame", nil, self.StatFrame, "NarciBarberShopStatsLocationFrameTemplate");
                if i == 1 then
                    widget:SetPoint("TOP", self.widgets.LocationHeader, "BOTTOM", 0, 16*(1 - i));
                else
                    widget:SetPoint("TOP", self.LocationFrames[i - 1], "BOTTOM", 0, 0);
                end
                self.LocationFrames[i] = widget;
            end
            widget:SetLocation(list[i][1]);
            widget:SetValue(list[i][2], list[i][3], timestamp);
            if list[i][1] == mapID then
                widget:StartTimer();
            else
                widget:StopTimer();
            end
        end
    end
end

function StatManager:UpdateLocationFramesHeight()
    local numFrames = #self.LocationFrames;
    if numFrames > 0 then
        local height = self.LocationFrames[1]:GetTop() - self.LocationFrames[numFrames]:GetBottom() + 100;
        self.StatFrame.tabHeight = self.StatFrame.basicHeight + height;
        if self.StatFrame:IsShown() then
            SettingFrame:SelectTab(self.StatFrame);
        end
        return height
    else
        return 0
    end
end

function StatManager:UpdateZone()
    local mapID = C_Map.GetBestMapForUnit("player");
    self.mapID = mapID;
    if mapID then
        --print(C_Map.GetMapInfo(mapID).name);
        if not self.DB.Locations[mapID] then
            self.DB.Locations[mapID] = { visit = 0, time = 0 };
        end
        self.DB.Locations[mapID].visit = self.DB.Locations[mapID].visit + 1;

        self:UpdateLocationFrame();
        self:UpdateLocationFramesHeight();
    end
end

function StatManager:OnBarberShopOpen()
    After(0.1, function()
        self:UpdateZone();
        self:StartTimer();
        self:UpdateMoney();
    end)
end

function StatManager:OnBarberShopClose()
    self:StopTimer();
end

function StatManager:UpdateMoney()
    local moneyLifetime = GetStatistic(1147);
    local copperLifetime;
    if moneyLifetime then
        --"544|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
        local gold = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-GoldIcon") or 0;
        local silver = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-SilverIcon") or 0;
        local copper = string.match(moneyLifetime, "(%d+)|TInterface\\MoneyFrame\\UI%-CopperIcon") or 0;
        local rawCopper = 10000 * gold + 100 * silver + copper;
        self.widgets.CoinsSpentLifetime:SetAmount(rawCopper);
        if not self.DB.CoinSpentBeforeShadowlands then
            self.DB.CoinSpentBeforeShadowlands = rawCopper;
        end
        
        local diff = rawCopper - self.DB.CoinSpentBeforeShadowlands;
        self.widgets.CoinsSpentSinceShadowlands:SetAmount(diff);
    else
        copperLifetime = 0;
    end
end

local EventListener = CreateFrame("Frame");
local events = {"BARBER_SHOP_COST_UPDATE", "BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE", "BARBER_SHOP_RESULT", "BARBER_SHOP_OPEN", "BARBER_SHOP_CLOSE", "BARBER_SHOP_APPEARANCE_APPLIED", "ADDON_LOADED"};    --"UNIT_MODEL_CHANGED"
for i =  1, #events do
    EventListener:RegisterEvent(events[i])
end

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        --Blizzard_CharacterCustomize
        --Blizzard_BarbershopUI
        if name == "Narcissus_Barbershop" then --Narcissus_Barbershop
            self:UnregisterEvent(event);
            if not IsAddOnLoaded("Blizzard_BarbershopUI") then
                print("Narcissus Error: Blizzard_BarbershopUI not loaded!");
                self:UnregisterAllEvents();
                return
            end
            DataProvider:LoadData();
            HotkeyManager:LoadHotkeys();
            StatManager:LoadData();
            HookMixin();
            InitializeBarberShopFrame();
            MainFrame:UpdateGenderCategory();
            StatManager:OnBarberShopOpen();
        end
    elseif event == "BARBER_SHOP_OPEN" then
        MainFrame:UpdateGenderCategory();
        StatManager:OnBarberShopOpen();
    elseif event == "BARBER_SHOP_CLOSE" then
        PortraitLoader:Hide();
        StatManager:OnBarberShopClose();
    elseif event == "BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE" then
        --MainFrame:UpdateGenderCategory();
    elseif event == "BARBER_SHOP_APPEARANCE_APPLIED" then
        if MainFrame.checkUniqueness and DataProvider:IsNewLooksUnique() then
            BarberShopFrame:UpdateCharCustomizationFrame();
        else
            BarberShopFrame:Cancel();
        end
        StatManager:UpdateMoney();
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
    SettingFrame:ScrollToTop();
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
end


NarciBarberShopSettingKeyBindingButtonMixin = {};

function NarciBarberShopSettingKeyBindingButtonMixin:OnLoad()
    tinsert(HotkeyManager.buttons, self);
    self:OnLeave();
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnEnter()
    self.Background:SetVertexColor(1, 1, 1);
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnLeave()
    if not self.isOn then
        self.Background:SetVertexColor(0.6, 0.6, 0.6);
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:Activate()
    self.Background:SetTexCoord(0, 1, 0.5, 1);
    self.ButtonText:SetTextColor(0, 0, 0);
    self:SetScript("OnKeyDown", function(self, key)
        self:Deactivate();
        if HotkeyManager:SetHotkey(self.command, key) then
            self:SetText(key);
        end
    end);
    self:SetPropagateKeyboardInput(false);
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingKeyBindingButtonMixin:Deactivate()
    self.Background:SetTexCoord(0, 1, 0, 0.5);
    self.ButtonText:SetTextColor(1, 0.82, 0);
    self:SetScript("OnKeyDown", nil);
    self.isOn = false;
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnClick(button)
    if button == "RightButton" then
        HotkeyManager:SetHotkey(self.command, nil);
        self:SetText("NONE");
    else
        self.isOn = not self.isOn;
        if self.isOn then
            self:Activate();
        else
            self:Deactivate();
        end
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnEvent()
    if not self:IsMouseOver() then
        self:Deactivate();
    end
end

function NarciBarberShopSettingKeyBindingButtonMixin:OnHide()
    if self.isOn then
        self:Deactivate();
    end
end


local TabData = {
    { name= "General", order = 1, localizedName = GENERAL,
        layout = {
            { name = "ToggleNotification", type = "checkbox", localizedName = L["Save Notify"], defaultState = true, onClickFunc = function(state) MainFrame:ToggleNotification(state) end },
            { name = "ToggleRandomAppearance", type = "checkbox", localizedName = L["Show Randomize Button"], defaultState = false, onClickFunc = function(state) MainFrame:ToggleRandomizeAppearanceButton(state) end }, --RANDOMIZE_APPEARANCE
        },
    },

    { name = "Shortcuts", order = 2, localizedName = NARCI_SHORTCUTS,
        layout = {
            { name = "Camera", type = "header", localizedName = CAMERA_LABEL },
            { name = "RotateLeft", type = "keybinding", localizedName = ROTATE_LEFT},
            { name = "RotateRight", type = "keybinding", localizedName = ROTATE_RIGHT},
            { name = "ZoomIn", type = "keybinding", localizedName = ZOOM_IN},
            { name = "ZoomOut", type = "keybinding", localizedName = ZOOM_OUT},
        },
    },

    { name = "Profiles", order = 3, localizedName = L["Profiles"],
        layout = {
            { name = "Notes", type = "header", localizedName = "Profile management will be availible in the next update.\nAt this moment you cannot access the appearances that were created by your other characters.", anchor = "LEFT" },
        },
    },

    { name = "Statistics", order = 0, localizedName = STATISTICS,
        layout = {
            { name = "Money", type = "header", localizedName = L["Coins Spent"] },
            { name = "CoinsSpentSinceShadowlands", type="money", localizedName = "9.0+", tooltip = "Coins spent since 9.0"},
            { name = "CoinsSpentLifetime", type="money", localizedName = HONOR_LIFETIME, tooltip = "Coins spent during lifetime"},
            { name = "Blank", type="header", localizedName=" ",},
            { name = "LocationHeader", type = "location", localizedName = L["Locations"] },
        },
    },
}


local function CreateTabs(frame)
    local Data;
    for i = 1, #TabData do
        Data = TabData[i];
        local button = CreateFrame("Button", nil, frame, "NarciBarberShopSettingTabButtonTemplate");
        local order = Data.order;
        button.order = order;
        if order ~= 0 then
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12 + 16 *(1 - i));
        else
            button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12);
        end
        button:SetText(Data.name);

        if Data.layout then
            local totalHeight = 8;
            local objects = {};
            local ScrollFrame = frame.ScrollFrame;
            local Tab = CreateFrame("Frame", nil, ScrollFrame);
            button.Tab = Tab;
            if order == 0 then
                StatManager.StatFrame = Tab;
            end
            Tab:SetSize(ScrollFrame:GetSize());
            Tab:SetPoint("TOPLEFT", frame.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            for j = 1, #Data.layout do
                local type = Data.layout[j].type;
                local object;
                if type == "checkbox" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingCheckBoxTemplate");
                    object.onClickFunc = Data.layout[j].onClickFunc;
                    object.Label:SetText(Data.layout[j].localizedName);
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    object:SetHeight(textHeight + 2);
                    totalHeight = totalHeight + textHeight + 12;
                    --Load settings
                    local dbName = Data.layout[j].name;
                    object.name = dbName;
                    if NarciBarberShopDB[dbName] == nil then
                        NarciBarberShopDB[dbName] = Data.layout[j].defaultState;
                    end
                    object:SetChecked(NarciBarberShopDB[dbName]);

                elseif type == "keybinding" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingKeyBindingButtonTemplate");
                    object.Label:SetText(Data.layout[j].localizedName);
                    object.command = Data.layout[j].name;
                    object:SetPoint("TOPRIGHT", Tab, "TOPRIGHT", -60, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 12;
                    object:SetText(HotkeyManager:GetHotkey(object.command));

                elseif type == "header" then
                    object = Tab:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
                    object:SetText(Data.layout[j].localizedName);
                    if Data.layout[j].anchor then
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
                    object:SetLabel(Data.layout[j].localizedName);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 8;

                    StatManager.widgets[Data.layout[j].name] = object;
                elseif type == "location" then
                    object = CreateFrame("Frame", nil, Tab, "NarciBarberShopStatsLocationFrameTemplate");
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    object:SetHeader();
                    totalHeight = totalHeight + 16;
                    StatManager.widgets[Data.layout[j].name] = object;
                    
                end
            end

            Tab.tabHeight = totalHeight;
            Tab.basicHeight = totalHeight;
        end
    end
end

NarciBarberShopSettingsMixin = CreateFromMixins(NarciChamferedFrameMixin);

function NarciBarberShopSettingsMixin:OnLoad()
    SettingFrame = self;
    
    local v = 0.2;
    self:SetBorderColor(v, v, v, 1);
    self:SetBackgroundColor(0, 0, 0, 1);
    self.Divider:SetVertexColor(v, v, v);
    self.ScrollFrame.scrollBar.Background:SetVertexColor(0.5, 0.5, 0.5);

    local frameHeight = math.floor(self.ScrollFrame:GetHeight() + 0.5);
    self.frameHeight = frameHeight;
    
    local deltaRatio = 1;
    local speedRatio = 0.2;
    local positionFunc;
    local buttonHeight = 40;
    local range = 120;

    NarciAPI_ApplySmoothScrollToScrollFrame(self.ScrollFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range);
end

function NarciBarberShopSettingsMixin:Initialize()
    CreateTabs(self);
    TabButtons[1]:Click();
end

function NarciBarberShopSettingsMixin:OnEvent(event)
    if not self:IsMouseOver() and not SettingButton:IsMouseOver() then
        self:Hide();
    end
end

function NarciBarberShopSettingsMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingsMixin:OnHide()
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingsMixin:Toggle()
    self:SetShown(not self:IsShown());
end

function NarciBarberShopSettingsMixin:ScrollToTop()
    self.ScrollFrame.scrollBar:SetValue(0);
end

function NarciBarberShopSettingsMixin:SelectTab(tab)
    --Update Scroll Range
    local frameHeight = math.floor(self.ScrollFrame:GetHeight() + 0.5);
    local range;
    if tab and tab.tabHeight then
        tab:Show();
        range = tab.tabHeight - frameHeight;
        if range < 4 then
            range = 0;
        end
    else
        range = 0;
    end
    
    local scrollBar = self.ScrollFrame.scrollBar;
    scrollBar:SetMinMaxValues(0, range);
    scrollBar:SetShown(range ~= 0);
    self.ScrollFrame.range = range;
end

--Click to open Settings
NarciBarberShopSettingButtonMixin = {};

function NarciBarberShopSettingButtonMixin:OnLoad()
    SettingButton = self;
    self.Label:SetText(SETTINGS);
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
    SettingFrame:Toggle();
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
    if true then return end;
    
    local Model = self.Model;
    Model:SetUnit("player");
    Model:SetKeepModelOnHide(true);
    Model:SetDoBlend(true);
    Model:SetFacing(0);
    Model:SetLight(true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
    Model:SetCamera(0);
    Model:SetPortraitZoom(1);
    Model:SetAnimation(0, 0);
    Model:SetPaused(true);
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
        self.facing = Model:GetFacing() + delta;
        Model:SetFacing(self.facing);
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
        Model:SetCameraPosition( self.cameraDistance*sin(cameraPitch), 0, self.cameraDistance*cos(cameraPitch) + 0.8);
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
        local x, y, z = Model:GetPosition();
        Model:SetPosition(x + delta, y, z);
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
        local x, y, z = Model:GetPosition();
        Model:SetPosition(x, y + delta, z);
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
        local x, y, z = Model:GetPosition();
        Model:SetPosition(x, y, z + delta);
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
        Model:SetCameraPosition( cameraDistance*sin(self.cameraPitch), 0, cameraDistance*cos(self.cameraPitch) + 0.8);
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
        local x, y = Model:GetViewTranslation();
        Model:SetViewTranslation(x + delta, y);
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
        local x, y = Model:GetViewTranslation();
        Model:SetViewTranslation(x, y + delta);
        frame.Value:SetText( round(y + delta) );
    end)

    self.ReloadButton:SetScript("OnClick", function()
        self:LoadProfile();
    end)
end

function NarciDevToolPortraitMixin:OnShow()
    local Model = self.Model;
    Model:MakeCurrentCameraCustom();
    self.cameraDistance = Model:GetCameraDistance();
    self.cameraPitch = pi/2;
    --Model:SetCameraPosition( self.cameraDistance*sin(self.cameraPitch), 0, self.cameraDistance*cos(self.cameraPitch) + 0.8);
    --Model:SetCameraTarget(0, 0, 0.8);
    Model:SetPosition(0, 0, 0);
    self.FacingButton.Value:SetText(Model:GetFacing());
    self.DistanceButton.Value:SetText(self.cameraDistance);
    local x, y = Model:GetViewTranslation();
    self.OffsetXButton.Value:SetText(x);
    self.OffsetYButton.Value:SetText(y);
end

function NarciDevToolPortraitMixin:LoadProfile(race, sex)
    local Model = self.Model;
    Model:RefreshUnit();
    Model:SetAnimation(0, 0);
    Model:SetPaused(true);
    Model:MakeCurrentCameraCustom();
    if not UpdatePortraitCamera(Model) then
        Model:SetFacing(0.52);
        local modelX, modelY, modelZ = 3.4, -0.07, -2.09;
        Model:SetPosition(modelX, modelY, modelZ);
    end
    local cameraX, cameraY, cameraZ = Model:TransformCameraSpaceToModelSpace(4, 0, 0);
    local targetX, targetY, targetZ = Model:TransformCameraSpaceToModelSpace(0, 0, 0);
    Model:SetCameraTarget(targetX, targetY, targetZ);
    Model:SetCameraPosition(cameraX, cameraY, cameraZ);
    local modelFacing = Model:GetFacing();
    local modelPosX, modelPosY, modelPosZ = Model:GetPosition();
    self.ModelXButton.Value:SetText(modelPosX);
    self.ModelYButton.Value:SetText(modelPosY);
    self.ModelZButton.Value:SetText(modelPosZ);
    self.FacingButton.Value:SetText(modelFacing);
end

--[[
    Statistics
    Gold spent at barber shops GetStatistic(1147)
    C_MapExplorationInfo.GetExploredAreaIDsAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"))
    C_Map.GetMapInfoAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"):GetXY())

--]]