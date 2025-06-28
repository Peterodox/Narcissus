local unpack = unpack;
local CreateColor = NarciAPI.CreateColor;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetItemGemID = C_Item.GetItemGemID;

local FILE_PATH_DARK = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/JPG/";

local itemBorderMask = {
    [1] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/RegularHeavy",    --Regular Hexagon Heavy
    [2] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/RegularSolid",

    [8001] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Heart",
    [9001] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Runeforge",

    [9101] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Sylvanas",
    [9102] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Garrosh",

    [9200] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Progenitor",
    [9201] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Menethil",
    [9202] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Anduin",

    [100701] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/ThreeSocket",
    [100101] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/Neltharion",

    [100200] = "Interface/AddOns/Narcissus/Art/ItemBorder-Dark/Mask/TreeAndFlame",
}

local itemBorderHeavy = {
    --[Quality or Specific Name] = {fileName, border's mask index}
    [0] = {"Black", 1},
    [1] = {"Black", 1},
    [2] = {"Uncommon", 1},
    [3] = {"Rare", 1},
    [4] = {"Epic", 1},
    [5] = {"Legendary", 1},
    [6] = {"Artifact", 1},
    [7] = {"Heirloom", 1},
    [12] = {"Black", 1},
    Azerite= {"Azerite", 1},
    Heart = {"Heart", 8001},
    NZoth = {"NZoth", 1},
    BlackDragon = {"BlackDragon", 1},    --8.3 Legendary Cloak / What's its name again?
    Runeforge = {"Runeforge", 9001},    --Sylvanas's Legendary Bow
    Sylvanas = {"Sylvanas", 9101},
    Garrosh = {"Garrosh", 9102},
    Progenitor = {"Progenitor", 9200},
    Cosmos = {"Cosmos", 2},
    Arbiter = {"Arbiter", 2},
    Menethil = {"Menethil", 9201},
    Varian = {"Varian", 2},
    Anduin = {"Anduin", 9202},
    Genesis = {"Genesis", 2},
    Shield = {"Shield", 1},
    Strife = {"Strife", 2},
    ThreeSocket_Purple = {"ThreeSocket_Purple", 100701},
    Neltharion = {"Neltharion", 100101},
    EmeraldDream = {"TreeAndFlame", 100200},
    ThreeSocket_Yellow = {"ThreeSocket_Yellow", 100701},
};

local function GetBorderThemeName()
    local themeName = NarcissusDB and NarcissusDB.BorderTheme
    if true then    --not (themeName and type(themeName) ~= "string" and (themeName == "Bright" or themeName == "Dark") )
        return "Dark"
    else
        return themeName
    end
end

NarciAPI.GetBorderThemeName = GetBorderThemeName;

local function SetBorderTexture(object, textureKey, themeIndex)
    if not themeIndex then
        themeIndex = 2;
    end
    if textureKey == object.textureKey and themeIndex == object.textureThemeIndex then
        return
    else
        object.textureKey = textureKey;
        object.textureThemeIndex = themeIndex;
    end
    local texFile, maskFile;
    if themeIndex == 1 then
        texFile = itemBorderHeavy[textureKey][1];
        maskFile = itemBorderMask[ itemBorderHeavy[textureKey][2] ];
    else
        texFile = itemBorderHeavy[textureKey][1];
        maskFile = itemBorderMask[ itemBorderHeavy[textureKey][2] ];
    end
    object:SetTexture(FILE_PATH_DARK..texFile);
    if not object.BorderMask then
        local layer, sublevel = object:GetDrawLayer();
        local mask = object:GetParent():CreateMaskTexture(nil, layer, nil, sublevel);
        mask:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0);
        mask:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 0, 0);
        object:AddMaskTexture(mask);
        object.BorderMask = mask;
    end
    object.BorderMask:SetTexture(maskFile, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
end

NarciAPI.SetBorderTexture = SetBorderTexture;


local itemIDxBorderArt = {
    --[itemID] = {borderName, vfxName, color, hideItemIcon}
    [186429] = {"Garrosh", "Garrosh", CreateColor(235, 91, 80)},    --177057
    [186414] = {"Sylvanas", "Sylvanas",  CreateColor(148, 188, 203)},

    [189852] = {"Cosmos", nil, CreateColor(169, 218, 215)},         --Shadow of the Cosmos
    [189862] = {"Arbiter", nil, CreateColor(180, 216, 222)},        --Gravel of the First Arbiter
    [189841] = {"Menethil", nil, CreateColor(240, 104, 104)},       --Soulwarped Seal of Wrynn
    [189839] = {"Varian", nil, CreateColor(116, 208, 249)},         --Soulwarped Seal of Wrynn
    [188262] = {"Anduin", "LigntFall", CreateColor(255, 204, 58)},  --The Lion's Roar
    [189845] = {"Shield", nil, nil},                                --Ruined Crest of Lordaeron
    [189754] = {"Genesis", nil, CreateColor(216, 212, 155)},        --Genesis Lathe
    [188253] = {"Strife", "OrangeRune", nil},                       --Scars of Fraternal Strife

    [203460] = {"ThreeSocket_Purple", "ThreeSocketRing", nil, nil, nil, true},           --Onyx Annulet --CreateColor(255, 171, 0)
    [228411] = {"ThreeSocket_Yellow", "ThreeSocketRing", nil, nil, nil, true},           --Cyrce's Circlet

    --Progenitor = {"Progenitor", nil, CreateColor(230, 204, 128)},   --Class Sets: Sepulcher of the First Ones


    --[visualID] = {borderName, vfxName, color, hideItemIcon}
    [1] = {"Neltharion", nil, CreateColor(252, 185, 54)},           --Class Sets: Embers of Neltharion
    [2] = {"EmeraldDream", nil, CreateColor(56, 224, 178)},         --Class Sets: Guardians of the Dream
    [3] = {"EmeraldDream", nil, CreateColor(56, 224, 178)},         --Class Sets: DF S4 Awakened Raids
    [4] = {"Neltharion", nil, CreateColor(252, 185, 54)},           --Class Sets: TWW S2 Undermined
};
itemIDxBorderArt[5] = itemIDxBorderArt[4];  --TEMP Class Sets: TWW S3 Manaforge Omega


local itemVisualGroup = {};

do
    for borderVisualID, items in pairs(NarciAPI.GetClassSetGroup()) do
        for _, itemID in pairs(items) do
            itemVisualGroup[itemID] = borderVisualID;
        end
    end
end

local function GetBorderArtByItemID(itemID)
    if itemVisualGroup[itemID] then
        return unpack(itemIDxBorderArt[ itemVisualGroup[itemID] ]);
    else
        if itemIDxBorderArt[itemID] then
            return unpack(itemIDxBorderArt[itemID]);
        end
    end
end

NarciAPI.GetBorderArtByItemID = GetBorderArtByItemID;


---- Gem Border ----
local gemBorderTexture = {
    filePrefix = "Interface/AddOns/Narcissus/Art/GemBorder/Dark/",
	[0]  = "White",			--Empty
	[1]  = "Primary",	--Kraken's Eye
	[2]  = "Green",
	[3]  = "Primary",	--Prismatic
	[4]  = "Primary",	--Meta
	[5]  = "Orange",	--Orange
	[6]  = "Purple",
    [7]  = "Yellow",	--Yellow
	[8]  = "Blue",		--Blue
	[9]  = "Black",	--(Other Type)
	[10] = "Red",		--Red
	[11] = "White",			--Artifact
    [12] = "Crystallic",
};

local specialGemBoder = {
    [153714] = 10,
    [173125] = 10,
    [153715] = 2,
    [169220] = 2,
    [173126] = 2,
    [168636] = 1,
    [168637] = 1,
    [168638] = 1,
    [153707] = 1,
    [153708] = 1,
    [153709] = 1,
    [189723] = 12,
    [189722] = 12,
    [189732] = 12,
    [189560] = 12,
    [189763] = 12,
    [189724] = 12,
    [189725] = 12,
    [189726] = 12,
    [189762] = 12,
    [189727] = 12,
    [189728] = 12,
    [189729] = 12,
    [189730] = 12,
    [189731] = 12,
    [189764] = 12,
    [189733] = 12,
    [189734] = 12,
    [189760] = 12,
    [189761] = 12,
    [189735] = 12,
};

local function GetGemBorderTexture(itemSubClassID, itemID)
    local index = (itemID and specialGemBoder[itemID]) or itemSubClassID or 0;
    return gemBorderTexture.filePrefix..gemBorderTexture[index], index
end

local function SetBorderTheme(theme)
    --1.1.2 Override
    theme = "Dark";

    if theme == "Bright" then
        gemBorderTexture.filePrefix = "Interface/AddOns/Narcissus/Art/GemBorder/Bright/";
    elseif theme == "Dark" then
        gemBorderTexture.filePrefix = "Interface/AddOns/Narcissus/Art/GemBorder/Dark/";
    end
end

NarciAPI.SetBorderTheme = SetBorderTheme;
NarciAPI.GetGemBorderTexture = GetGemBorderTexture;


---- Item Border Visual (ModelScene) ----
local PI = math.pi;
local VFXContainer = CreateFrame("Frame", "NarciItemVFXContainer");

function VFXContainer:AcquireAndSetModelScene(parentFrame, effectName)
    if not self.models then
        self.models = {};
    end
    local model;
    for i = 1, #self.models do
        if not self.models[i].isActive then
            model = self.models[i];
            break
        end
    end
    if model then
        model:GetParent().VFX = nil;
    else
        model = CreateFrame("ModelScene", nil, self, "NarciItemVFXTemplate");
        table.insert(self.models, model);
    end
    model:SetParent(parentFrame);
    model:SetUpByName(effectName);
    return model
end

function VFXContainer:GetNumModels()
    if self.models then
        print(#self.models);
    else
        print(0);
    end
end


NarciModelSceneActorMixin = CreateFromMixins(ModelSceneActorMixin);

function NarciModelSceneActorMixin:OnAnimFinished()
    if self.oneShot then
        if self.finalSequence then
            self:SetAnimation(0, 0, 0, self.finalSequence);
        else
            self:Hide();
        end
    end
    if self.onfinishedCallback then
        self.onfinishedCallback();
    end
end

--[[
    table:modelSceneInfo = {
        camera = {zoomDistance = distance, direction = string },
        actors = {
            {fileID = modelFileID, modelOffset = {x, y}, oneShot = bool, animationID = number, animationSpeed = number},
        }
    } 

    --/run NarciItemVFX:SetUpByName("heart")
--]]


---- Display 3 Sockets ----
local SocketContainer;

local function CreateSocketTexture(container)
    local texture = container:CreateTexture(nil, "OVERLAY");
    texture:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375);

    local mask = container:CreateMaskTexture(nil, "OVERLAY");
    mask:SetPoint("TOPLEFT", texture, "TOPLEFT", 0, 0);
    mask:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 0, 0);
    mask:SetTexture("Interface/AddOns/Narcissus/Art/BasicShapes/Circle64", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    texture:AddMaskTexture(mask);

    local overlay = container:CreateTexture(nil, "OVERLAY", nil, 3);
    overlay:SetPoint("TOPLEFT", texture, "TOPLEFT", 0, 0);
    overlay:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 0, 0);
    overlay:SetTexture("Interface/AddOns/Narcissus/Art/BasicShapes/Circle-InnerShadow-8");

    return texture
end

local function DisplayThreeSockets(vfxFrame)
    vfxFrame.effectName = nil;  --Cleared this so we can update this container

    local slotButton = vfxFrame:GetParent();

    if slotButton and slotButton.itemLink then
        local ids = {};
        local _, socket, icon;

        for i = 1, 3 do
            local gemID = GetItemGemID(slotButton.itemLink, i)
            if gemID then
                table.insert(ids, gemID);
            end
        end

        local total = #ids;

        if total > 0 then
            if not SocketContainer then
                SocketContainer = CreateFrame("Frame", nil, vfxFrame);
                SocketContainer.sockets = {};
            end
            if total > 1 then
                table.sort(ids);
            end
            vfxFrame.additionalFrame = SocketContainer;
            SocketContainer:SetParent(vfxFrame);
            SocketContainer.owner = vfxFrame;
            SocketContainer:Show();
        end

        for i = 1, total do
            socket = SocketContainer.sockets[i];
            if not socket then
                socket = CreateSocketTexture(SocketContainer);
                SocketContainer.sockets[i] = socket;

                local degree;
                if i == 1 then
                    degree = 0;
                elseif i == 2 then
                    degree = 120;
                else
                    degree = 240;
                end

                local r = 18;
                local x = r * math.cos( math.rad(degree) );
                local y = r * math.sin( math.rad(degree) );

                socket:SetSize(22, 22);
                socket.x, socket.y = x, y;
            end

            socket:ClearAllPoints();
            socket:SetPoint("CENTER", vfxFrame, "CENTER", socket.x, socket.y);
            _, _, _, _, icon = GetItemInfoInstant(ids[i]);
            socket:SetTexture(icon);
            socket:Show();
        end

        if SocketContainer then
            for i = total + 1, #SocketContainer.sockets do
                SocketContainer.sockets[i]:Hide();
            end
        end
    end
end

local itemVFXInfo = {
    Heart = {
        camera = { zoomDistance = 2.65, direction = "LEFT" },
        actors = {
            {fileID = 165995, alpha = 0.6, },
        },
        offset = {x = 1, y = -23 },
    },

    DragonFire = {
        camera = { zoomDistance = 1.25 },
        actors = {
            {fileID = 969794},
        },
        offset = {x = 8, y = 8 },
    },

    Runeforge = {
        camera = { zoomDistance = 3.5, direction = "TOP" },
        actors = {
            {fileID = 166011, modelOffset = {0.75, -0.05}, alpha = 0.6, animationSpeed = 0.5, },
            {fileID = 166011, modelOffset = {-0.75, -0.05}, alpha = 0.6, animationSpeed = 0.5, },
        },
        offset = {x = 0, y = 0 },
    },

    Sylvanas = {
        camera = { zoomDistance = 2.65, direction = "RIGHT" },
        actors = {
            {fileID = 165995, alpha = 1, },
        },
        offset = {x = 8, y = 10 },
    },

    Garrosh = {
        camera = { zoomDistance = 5, direction = "BOTTOM" },
        actors = {
            {fileID = 3486623, animationID = 0, animationSpeed = -0.6, modelOffset = {-0.15, 0.24}, alpha = 1, particleScale = 0.1,};
            {fileID = 3486623, animationID = 0, animationSpeed = -0.6, modelOffset = {-0.15, 0.24}, alpha = 0.8, particleScale = 0.1,};
            {fileID = 3486625, animationID = 0, animationSpeed = -0.6, modelOffset = {0.35, 0}, alpha = 1, particleScale = 0.1,};
            {fileID = 3486625, animationID = 0, animationSpeed = -0.6, modelOffset = {0.35, 0}, alpha = 0.8, particleScale = 0.1,};
        },
        offset = {x = 0, y = 16 },
    },

    SoulfireChisel = {
        camera = { zoomDistance = 3.5, direction = "TOP" },
        actors = {
            {fileID = 3483468},
        },
        offset = {x = 0, y = 0},
    },

    LigntFall = {
        camera = { zoomDistance = 10, direction = "FRONT" },
        actors = {
            {fileID = 2429902, animationID = 158, animationSpeed = 8, modelOffset = {-1, -3.2}, alpha = 0.65, particleScale = 2,};
        },
        offset = {x = 0, y = 0 },
    },

    OrangeRune = {
        camera = { zoomDistance = 5, direction = "FRONT" },
        actors = {
            {fileID = 3656114, animationID = 158, modelOffset = {0.2,-0.05}, alpha = 1, particleScale = 1,};
        },
        offset = {x = 0, y = 0 },
    },

    ThreeSocketRing = {
        setupFunc = DisplayThreeSockets,
    },
};


NarciItemVFXMixin = {};

function NarciItemVFXMixin:Activate()
    self:Show();
    self.isActive = true;
end

function NarciItemVFXMixin:Remove()
    self:Hide();
    self.isActive = false;

    if self.additionalFrame and self.additionalFrame.owner == self then
        self.additionalFrame:Hide();
        self.additionalFrame = nil;
    end
end

function NarciItemVFXMixin:ClearEffects(fromIndex)
    if self.effects then
        fromIndex = fromIndex or 1;
        for i = fromIndex, #self.effects do
            self.effects[i]:Hide();
            self.effects[i]:ClearModel();
        end
    end
end

function NarciItemVFXMixin:SetUp(vfxInfo, useCustomPosition)
    self:SetFrameLevel( (self:GetParent():GetFrameLevel() or 0) + 2);
    self:Activate();

    if vfxInfo.setupFunc then
        self:ClearAllPoints();
        self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0);
        self:ClearEffects();
        vfxInfo.setupFunc(self);
        return
    end

    local camera = self.effectCamera;
    if not camera then
        camera = CameraRegistry:CreateCameraByType("OrbitCamera");
        camera:SetOwningScene(self);
        self.effectCamera = camera;
        self.activeCamera = camera;
        local modelSceneCameraInfo = C_ModelInfo.GetModelSceneCameraInfoByID(114);
        camera:ApplyFromModelSceneCameraInfo(modelSceneCameraInfo, 1, 1);    --1 ~ CAMERA_TRANSITION_TYPE_IMMEDIATE / CAMERA_MODIFICATION_TYPE_DISCARD
    end

    local cameraInfo = vfxInfo.camera;
    camera:SetZoomDistance(cameraInfo.zoomDistance or 3);
    camera:SynchronizeCamera();

    local view = cameraInfo.direction;
    local actorPitch, actorYaw = 0, 0;
    if view then
        if type(view) == "string" then
            view = string.upper(view);
            if view == "FRONT" then
                actorPitch = 0;
                actorYaw = PI;
            elseif view == "BACK" then
                actorPitch = 0;
                actorYaw = 0;
            elseif view == "TOP" then
                actorPitch = PI/2;
                actorYaw = PI; 
            elseif view == "BOTTOM" then
                actorPitch = -PI/2;
                actorYaw = PI;
            elseif view == "LEFT" then
                actorPitch = 0;
                actorYaw = -PI/2;
            elseif view == "RIGHT" then
                actorPitch = 0;
                actorYaw = PI/2;
            end
        elseif type(view) == "table" then
            actorPitch = view[1] or actorPitch;
            actorYaw = view[2] or actorYaw;
        end
    end
    
    if not self.effects then
        self.effects = {};
    end

    local actorInfo;
    local actor;
    local numEffects = #vfxInfo.actors;

    for i = 1, numEffects do
        actorInfo = vfxInfo.actors[i];
        actor = self.effects[i];
        if actorInfo then
            if not actor then
                actor = self:CreateActor(nil, "NarciModelSceneActorTemplate");
                self.effects[i] = actor;
                actor:SetPosition(0, 0, 0);
            end
            actor:SetModelByFileID(actorInfo.fileID);
            if actorInfo.modelOffset then
                local a = actorInfo.modelOffset[1];
                local b = actorInfo.modelOffset[2];
                actor:SetPosition(0, a or 0, b or 0);
            else
                actor:SetPosition(0, 0, 0);
            end
            if actorInfo.particleScale then
                actor:SetParticleOverrideScale(actorInfo.particleScale);
            end
            actor:SetAlpha(actorInfo.alpha or 1);
            actor:SetScale(actorInfo.scale or 1);
            actor.oneShot = actorInfo.oneShot;
            actor:SetAnimation(actorInfo.animationID or 0, 0, actorInfo.animationSpeed or 1, 0);
            actor:SetPitch(actorPitch);
            actor:SetYaw(actorYaw);
            actor:Show();
        else
            actor:Hide();
        end
    end

    self:ClearEffects(numEffects + 1);

    local frameOffset = vfxInfo.offset;
    self:ClearAllPoints();
    self.offsetX = frameOffset.x or 0;
    self.offsetY = frameOffset.y or 0;
    if not useCustomPosition then
        self:SetPoint("CENTER", self:GetParent(), "CENTER", self.offsetX, self.offsetY);
    end
end

function NarciItemVFXMixin:SetUpByName(effectName, useCustomPosition)
    if itemVFXInfo[effectName] then
        if effectName ~= self.effectName then
            self.effectName = effectName;
            self:SetUp(itemVFXInfo[effectName], useCustomPosition);
        else
            self:Activate();
            self:ClearAllPoints();
            self:SetPoint("CENTER", self:GetParent(), "CENTER", self.offsetX, self.offsetY);
            self:SetFrameLevel( (self:GetParent():GetFrameLevel() or 0) + 2);
        end
    end
end

function NarciItemVFXMixin:SetOwningFrame()

end