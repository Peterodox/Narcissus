local _, addon = ...
local EaseFunc = addon.EasingFunctions.outQuart;

local Scene = {};
local StoryboardUtil = {};
addon.StoryboardUtil = StoryboardUtil;

local CAMERA_TRANSITION_D = 1.5;

local function Camera_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= CAMERA_TRANSITION_D then
        self:SetScript("OnUpdate", nil);
    end

    self.cx = EaseFunc(self.t, self.fromCamX, self.toCamX, CAMERA_TRANSITION_D);
    self.cy = EaseFunc(self.t, self.fromCamY, self.toCamY, CAMERA_TRANSITION_D);
    self.cz = EaseFunc(self.t, self.fromCamZ, self.toCamZ, CAMERA_TRANSITION_D);

    self.yaw = EaseFunc(self.t, self.fromYaw, self.toYaw, CAMERA_TRANSITION_D);
    self.pitch = EaseFunc(self.t, self.fromPitch, self.toPitch, CAMERA_TRANSITION_D);

    self:SetCameraPosition(self.cx, self.cy, self.cz);
    self:SetCameraOrientationByYawPitchRoll(self.yaw, self.pitch, 0);
end

function StoryboardUtil.SetScene(storyboard, sceneName)
    sceneName = "LoammNiffen";

    if not Scene[sceneName] then
        return
    end

    if sceneName == storyboard.sceneName then
        return
    end
    storyboard.sceneName = sceneName;

    local data = Scene[sceneName];

    storyboard.DescriptionFrame.Text:SetText(data.text);

    local modelScene = storyboard.ModelScene;

    if storyboard.actors then
        for i, actor in ipairs(storyboard.actors) do
            actor:ClearModel();
        end
    else
        storyboard.actors = {};
    end

    local camInfo = data.fromCamera;
    modelScene:SetCameraFieldOfView(camInfo[1]);
    --modelScene:SetCameraPosition(camInfo[2], camInfo[3], camInfo[4]);
    --modelScene:SetCameraOrientationByAxisVectors(camInfo[5], camInfo[6], camInfo[7],  camInfo[8], camInfo[9], camInfo[10],  camInfo[11], camInfo[12], camInfo[13]);

    --Camera Transition
    modelScene.fromCamX, modelScene.fromCamY, modelScene.fromCamZ = camInfo[2], camInfo[3], camInfo[4];
    modelScene.fromYaw, modelScene.fromPitch = camInfo[5], camInfo[6];
    modelScene.toCamX, modelScene.toCamY, modelScene.toCamZ = camInfo[2], camInfo[3], camInfo[4];

    camInfo = data.toCamera;
    modelScene.toCamX, modelScene.toCamY, modelScene.toCamZ = camInfo[2], camInfo[3], camInfo[4];
    modelScene.toYaw, modelScene.toPitch = camInfo[5], camInfo[6];

    modelScene.t = 0;
    modelScene:SetScript("OnUpdate", Camera_OnUpdate);

    local actor;

    for i, modelInfo in ipairs(data.models) do
        if not storyboard.actors[i] then
            storyboard.actors[i] = modelScene:CreateActor();
        end
        actor = storyboard.actors[i];

        if type(modelInfo[1]) == "number" then
            actor:SetModelByFileID(modelInfo[1]);
        else
            local modelType, id = string.split(":", modelInfo[1]);
            id = tonumber(id);
            if modelType == "displayID" then
                actor:SetModelByCreatureDisplayID(id);
                actor:SetAnimationBlendOperation(0);
                actor:SetAnimation(97);
            end
        end

        actor:SetUseCenterForOrigin(true, true, true);
        actor:SetScale(modelInfo[2]);
        actor:SetPosition(modelInfo[3], modelInfo[4], modelInfo[5]);
        actor:SetYaw(modelInfo[6]);
        actor:SetPitch(modelInfo[7]);
        actor:SetRoll(modelInfo[8]);
        if modelInfo[9] then
            actor:SetSpellVisualKit(modelInfo[9]);
        end
    end

    
    --Use this model as light source
    if modelScene.lights then
        for i, light in ipairs(storyboard.lights) do
            light:ClearModel();
        end
    else
        storyboard.lights = {};
    end

    local light;
    for i = 1, 2 do
        if not storyboard.lights[i] then
            storyboard.lights[i] = modelScene:CreateActor();
        end
        light = storyboard.lights[i];
        light:SetModelByFileID(343630);
        light:SetPosition(0, 1000, -1000);
        light:SetAlpha(1);
    end

    modelScene:SetLightType(1);

    --[[
    --Debug
    local CAM_YAW = 0;
    local CAM_PITCH = 0;

    if false and not StoryboardUtil.sliders then
        StoryboardUtil.sliders = true;

        local function CameraYaw_OnValueChanged(f, value, userInput)
            print(value)
            f.ValueText:SetText(math.floor(math.deg(value) + 0.5));
            CAM_YAW = value;
            modelScene:SetCameraOrientationByYawPitchRoll(CAM_YAW, CAM_PITCH, 0);
        end
        local function CameraPitch_OnValueChanged(f, value, userInput)
            print(value)
            f.ValueText:SetText(math.floor(math.deg(value) + 0.5));
            CAM_PITCH = value;
            modelScene:SetCameraOrientationByYawPitchRoll(CAM_YAW, CAM_PITCH, 0);
        end

        local sliderYaw = CreateFrame("Frame", nil, nil, "NarciScreenshotToolbarSliderTemplate");
        sliderYaw:SetWidth(150);
        sliderYaw:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
        sliderYaw:SetLabel("Yaw");
        sliderYaw:SetMinMaxValues(0, 2*math.pi);
        sliderYaw:SetValue(0);
        sliderYaw:OnLoad();
        sliderYaw.onValueChangedFunc = CameraYaw_OnValueChanged;
        sliderYaw:Init();

        local sliderPitch = CreateFrame("Frame", nil, nil, "NarciScreenshotToolbarSliderTemplate");
        sliderPitch:SetWidth(150);
        sliderPitch:SetPoint("CENTER", UIParent, "CENTER", 0, -80);
        sliderPitch:SetLabel("Pitch");
        sliderPitch:SetMinMaxValues(math.rad(-88), math.rad(88));
        sliderPitch:OnLoad();
        sliderPitch.onValueChangedFunc = CameraPitch_OnValueChanged;
        sliderPitch:Init();
        sliderPitch:SetValue(0);
    end
    --]]
end

function StoryboardUtil.CreateAndSetScene(sceneName)
    if not StoryboardUtil.cards then
        StoryboardUtil.cards = {};
    end

    local newCard;

    for i, card in ipairs(StoryboardUtil.cards) do
        if card.sceneName == sceneName then
            return
        end

        if not card:IsShown() then
            newCard = card;
        end
    end

    if not newCard then
        newCard = CreateFrame("Frame", nil, UIParent, "NarciStoryboardTemplate");
        table.insert(StoryboardUtil.cards, newCard);
    end

    newCard:ResetPosition();
    newCard:Show();
    StoryboardUtil.SetScene(newCard, sceneName);
end

do
    --Serves as an easter egg for now
    local TRIGGER_QUEST_ID = 72920;     --The Endless Burning Sky.  Extinguish the fires consuming Loamm and rescue 5 Loamm villagers.

    local function SetupSotryboardTrigger()
        local achievementID = 17739;
        local isValid = C_AchievementInfo.IsValidAchievement(achievementID);
        if not isValid then return end;

        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(TRIGGER_QUEST_ID);
        if not isCompleted then
            isCompleted = select(4, GetAchievementInfo(achievementID));
        end

        if isCompleted then return end;

        local EventListener = CreateFrame("Frame");
        EventListener:RegisterEvent("QUEST_TURNED_IN");
        EventListener:SetScript("OnEvent", function(self, event, questID)
            if questID == TRIGGER_QUEST_ID then
                self:UnregisterEvent(event);
                self:SetScript("OnEvent", nil);

                C_Timer.After(4, function()
                    StoryboardUtil.CreateAndSetScene("LoammNiffen");
                end);
            end
        end);
    end

    addon.AddInitializationCallback(SetupSotryboardTrigger);
end


local QuestItemTracker = CreateFrame("Frame");

local match = string.match;
local select = select;
local tonumber = tonumber;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local find = string.find;
local LOOT_ITEM_SELF = string.gsub(LOOT_ITEM_SELF or "You receive loot: %s", "%%s", "");
local QuestItemDB = {};
local PLAYER_GUID = "";

local function QuestItemTracker_OnEvent(self, event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid)
    local itemID = match(text, "item:(%d+)", 1);
    if itemID then
        itemID = tonumber(itemID);
        --print(event, itemID)
        local classID = select(6, GetItemInfoInstant(itemID));
        if classID == 12 then
            if guid == PLAYER_GUID then    --find(text, LOOT_ITEM_SELF)
                if not QuestItemDB[itemID] then
                    QuestItemDB[itemID]= true;
                    NarciQuestItemDisplay:SetItem(itemID);
                end
            end
        end
    end
end

function QuestItemTracker:EnableTracker()
    --[[
    local playerName = UnitNameUnmodified("player");
    local _, realmName = UnitFullName("player");

    if realmName then
        TRACKED_PLAYER_NAME = playerName.."-"..realmName;
    end
    --]]

    self:RegisterEvent("CHAT_MSG_LOOT");   --QUEST_LOOT_RECEIVED
    self:SetScript("OnEvent", QuestItemTracker_OnEvent);
end

function QuestItemTracker:DisableTracker()
    self:UnregisterEvent("CHAT_MSG_LOOT");
    self:SetScript("OnEvent", nil);
end


do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.SetAutoDisplayQuestItem(state, db)
        if state == nil then
            state = db["AutoDisplayQuestItem"];
        end

        if DialogueUI_DB and DialogueUI_DB.QuestItemDisplay then
            state = false;
        end

        if state then
            QuestItemTracker:EnableTracker()
        else
            QuestItemTracker:DisableTracker();
        end
    end

    function SettingFunctions.SetQuestItemDisplayTheme(id, db)
        if id == nil then
            id = db["QuestCardTheme"];
        end
        NarciQuestItemDisplay:SetTheme(id);
    end

    local function LoadDatabase()
        if not NarciStatisticsDB.QuestItems then
            NarciStatisticsDB.QuestItems = {};
        end

        QuestItemDB = NarciStatisticsDB.QuestItems;
        NarciQuestItemDisplay:UseSavedPosition();

        PLAYER_GUID = UnitGUID("player");
    end

    addon.AddInitializationCallback(LoadDatabase);
end

---- Scene Data ----
Scene.LoammNiffen = {
    text = "\"Honey, where is my Onyxia Scale Cloak?\"",

    --camera = {fov, x, y, z, 3 AxisVectors}
    --  OR --
    --camera = {fov, x, y, z, yaw, pitch, roll}

    fromCamera = {0.87266463041306, 2.6849436759949, -3.5322875976562, 4.6396870613098, 2.191, 0.8569, 0},
    toCamera = {0.87266463041306, 2.7117350101471, -4.1860194206238, -0.021030984818935, 2.088, 0.1260, 0},

    
    models = {
        {4878482, 1, -0.552, -1.595, -0.654, 0, 0, 0},
        {"displayID:112345", 0.6, -0.014, 0.008, -0.37, 0, 0, 0, 13739},
        {4198203, 1.1, 0.05, 0, -1.153, 0, 0, 0},
        {4363616, 0.6, 2.826, -0.053, -1.976, 0, 0, 0},
        {2918346, 0.7, 1.777, -0.25, -0.985, 1.396, 0, 0},
        {2165391, 0.2, 0.331, 0.509, -6.694, 0, 0, 0},
        {2165391, 0.2, 0.331, -4.969, -6.694, 0, 0, 0},
        {2165391, 0.2, 0.331, -10.45, -6.694, 0, 0, 0},
        {2165391, 0.2, 5.849, -10.45, -6.694, 3.142, 0, 0},
        {2165391, 0.2, 5.852, -4.922, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 5.852, 0.457, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 5.852, 5.987, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 0.331, 5.987, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 0.331, 11.503, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 5.818, 11.473, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 5.818, 16.984, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 0.331, 16.99, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 11.305, 16.984, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 11.305, 11.473, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 11.305, 5.962, -6.694, 1.571, 0, 0},
        {2165391, 0.2, 11.305, 0.451, -6.694, -1.571, 0, 0},
        {2165391, 0.2, 11.305, -5.02, -6.694, 3.142, 0, 0},
        {2165391, 0.2, 11.305, -10.485, -6.694, 1.571, 0, 0},
        {2165391, 0.2, -5.174, -10.45, -6.694, 0, 0, 0},
        {2165391, 0.2, -5.174, -4.936, -6.694, 0, 0, 0},
        {2165391, 0.2, -5.174, 0.482, -6.694, 0, 0, 0},
        {2165391, 0.2, -5.174, 5.981, -6.694, 0, 0, 0},
        {2165391, 0.2, -5.174, 11.518, -6.694, 0, 0, 0},
        {2165391, 0.2, -5.174, 16.931, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, -10.45, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, -4.905, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, 0.515, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, 5.965, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, 11.405, -6.694, 0, 0, 0},
        {2165391, 0.2, -10.636, 16.885, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, 16.885, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, 11.434, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, 5.945, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, 0.484, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, -4.924, -6.694, 0, 0, 0},
        {2165391, 0.2, -16.183, -10.442, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, 16.885, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, 11.365, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, 5.848, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, 0.436, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, -4.937, -6.694, 0, 0, 0},
        {2165391, 0.2, -21.706, -10.394, -6.694, 0, 0, 0},
        {1278483, 0.253, -9.135, 6.414, -1.343, -1.047, 0, 0},
        {1282941, 0.4, -4.175, 7.077, 0.217, 0.524, 0, 1.571},
        {1282941, 0.4, -10.642, 3.945, -0.153, 0.524, 0, 1.571},
        {1282941, 0.4, 2.904, 11.765, 0.181, 0.524, 0, 1.571},
        {1278555, 0.4, -0.257, 8.445, 0.363, -1.047, 0, 0},
        {362202, 1, -0.447, 0.921, -0.281, 0, 0, 0},
        {4878482, 1, -1.439, -0.417, -0.654, 0, 0, 0},
        {4878482, 1, 0.296, 2.007, -0.871, 0, 0, 0},
        {4878482, 1, 2.301, -1.403, -1.008, 0, 0, 0},
    },
};
