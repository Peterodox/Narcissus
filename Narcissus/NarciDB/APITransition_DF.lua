local _, addon = ...

if not addon.IsDragonflight() then
    return
end

local TransitionAPI = addon.TransitionAPI;


function TransitionAPI.IsDragonflight()
    return true
end


local CreateColor = CreateColor;
local WantsAlteredForm = C_UnitAuras.WantsAlteredForm;
local UnitRace = UnitRace;
local C_Minimap = C_Minimap;
local type = type;

local SharedVector3D = CreateVector3D(0, 0, 0);

local SharedLightValues = {
    omnidirectional = true,
    point = CreateVector3D(0, 0, 0),
    ambientIntensity = 0.8,
    ambientColor = CreateColor(1, 1, 1),
    diffuseIntensity = 0,
    diffuseColor = CreateColor(1, 1, 1),
};


function TransitionAPI.SetGradient(texture, orientation, minR, minG, minB, maxR, maxG, maxB)    --#1
    local minColor = CreateColor(minR, minG, minB, 1);
    local maxColor = CreateColor(maxR, maxG, maxB, 1);
    texture:SetGradient(orientation, minColor, maxColor);
end

function TransitionAPI.IsRTXSupported()
    return true
end

function TransitionAPI.HookSocketContainerItem(callback)     --#3
    if C_Container and C_Container.SocketContainerItem then
        hooksecurefunc(C_Container, "SocketContainerItem", callback);
    elseif SocketContainerItem then
        hooksecurefunc("SocketContainerItem", callback);
    end
end

function TransitionAPI.HookSocketInventoryItem(callback)     --#4
    if SocketInventoryItem then
        hooksecurefunc("SocketInventoryItem", callback);
    elseif C_Container.SocketInventoryItem then
        hooksecurefunc(C_Container, "SocketInventoryItem", callback);
    end
end

function TransitionAPI.IsTrackingPets()      --#5
    return C_Minimap.IsTrackingBattlePets();
end

function TransitionAPI.SetTrackingPets(state)      --#6
    local GetTrackingInfo = C_Minimap.GetTrackingInfo;
    local numTypes = C_Minimap.GetNumTrackingTypes();
    local _, active, spellID;
    for i = 1, numTypes do
        _, _, active, _, _, spellID = GetTrackingInfo(i);
        if spellID == 122026 then
            if active ~= state then
                C_Minimap.SetTracking(i, state);
            end
            return active
        end
    end
end

function TransitionAPI.SetModelLight(model, enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)        --#7
    if type(omni) == "table" then
        model:SetLight(enabled, omni);
    else
        SharedLightValues.omnidirectional = omni or false;
        SharedLightValues.point:SetXYZ(dirX or 0, dirY or 0, dirZ or 0);
        SharedLightValues.ambientIntensity = ambIntensity or 0;
        SharedLightValues.ambientColor:SetRGB(ambR or 0, ambG or 0, ambB or 0);
        SharedLightValues.diffuseIntensity = dirIntensity or 0;
        SharedLightValues.diffuseColor:SetRGB(dirR or 0, dirG or 0, dirB or 0);

        model:SetLight(enabled, SharedLightValues);
    end
end

function TransitionAPI.GetModelLight(model)        --#8
    local enabled, light = model:GetLight();
    local _, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB;
    if type(light) == "table" then
        omni = light.omnidirectional;
        dirX, dirY, dirZ = light.point:GetXYZ();

        ambIntensity = light.ambientIntensity;
        if light.ambientColor then
            ambR, ambG, ambB = light.ambientColor:GetRGB();
        else    --intensity = 0
            ambR, ambG, ambB = 0, 0, 0;
        end

        dirIntensity = light.diffuseIntensity;
        if light.diffuseColor then
            dirR, dirG, dirB = light.diffuseColor:GetRGB();
        else
            dirR, dirG, dirB = 0, 0, 0;
        end

        return enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB
    end
end

function TransitionAPI.TransformCameraSpaceToModelSpace(model, x, y, z)     --#9
    SharedVector3D:SetXYZ(x, y, z);
    return model:TransformCameraSpaceToModelSpace(SharedVector3D);
end

local USING_TABLE_ARG = false;    --Model APIs weren't fully unified by 10.1.5, this is a temp workaround

--[[
do
    local _, _, _, tocVersion = GetBuildInfo();
    tocVersion = tonumber(tocVersion);

    if addon.IsTOCVersionEqualOrNewerThan(100105) then
        USING_TABLE_ARG = true;
    end
end
--]]

function TransitionAPI.SetCameraPosition(model, x, y, z)     --#10
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end

    if USING_TABLE_ARG and model:IsObjectType("CinematicModel") then
        local position = {
            x = x,
            y = y,
            z = z,
        }
        model:SetCameraPosition(position);
    else
        model:SetCameraPosition(x, y, z);
    end
end

function TransitionAPI.SetCameraTarget(model, x, y, z)     --#11
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end

    if USING_TABLE_ARG and model:IsObjectType("CinematicModel") then
        local position = {
            x = x,
            y = y,
            z = z,
        }
        model:SetCameraTarget(position);
    else
        model:SetCameraTarget(x, y, z);
    end
end

function TransitionAPI.SetModelPosition(model, x, y, z)     --#12
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end
    model:SetPosition(x, y, z);
end

function TransitionAPI.SetModelByUnit(model, unit)    --#13
    local _, raceFileName = UnitRace(unit);
    if raceFileName == "Dracthyr" or raceFileName == "Worgen" then
        local arg = WantsAlteredForm(unit);
        model:SetUnit(unit, true, arg);
    else
        model:SetUnit(unit, true);
    end
    model.unit = unit;
end

function TransitionAPI.IsPlayerInAlteredForm()      --#14
	return
end

do
    local _, RACE_FILE_NAME = UnitRace("player");

    if RACE_FILE_NAME == "Dracthyr" or RACE_FILE_NAME == "Worgen" then
        function TransitionAPI.IsPlayerInAlteredForm()      --#15
            if WantsAlteredForm("player") then
                return
            else
                return true
            end
        end
    end
end

function TransitionAPI.SetModelLightFromModel(toModel, fromModel)      --#15
    local enabled, light = fromModel:GetLight();
    toModel:SetLight(enabled, light);
end



--[[

Misc Experiments:

#100 UI Edit Mode: Toggle Frame Selection and Grid
    EditModeManagerFrame:HideSystemSelections()
    EditModeManagerFrame:SetGridShown(false);

--]]

--[[
local SHOW_EXPERIEMENT_FEATURE = false;

if not SHOW_EXPERIEMENT_FEATURE then
    return
end

local NUM_ACTIVE_SELECTIONS = 0;

local EditFrame = _G["EditModeManagerFrame"];
local EMST = CreateFrame("Button", "NarciBlizzardEditModeSelectionToggle", EditFrame, "SecureHandlerMouseUpDownTemplate");
EMST:SetIgnoreParentAlpha(true);
EMST:SetSize(48, 48);
EMST:SetPoint("TOP", UIParent, "TOP", 0, -8);
EMST.Texture = EMST:CreateTexture(nil, "OVERLAY");
EMST.Texture:SetAllPoints(true);
EMST.Texture:SetColorTexture(1, 0, 0);

EMST:SetFrameRef("EditModeManagerFrame", EditFrame);
EMST:SetAttribute("_onmousedown", [=[
    local f = self:GetFrameRef("EditModeManagerFrame");
    if not f:IsShown() then return end;

    f:SetAlpha(0);

    local total = self:GetAttribute("numSelections") or 0;
    local selection;

    for i = 1, total do
        selection = self:GetFrameRef("SystemFrame"..i);
        if selection then
            selection:Hide();
        end
    end

    local grid = self:GetFrameRef("Grid");
    if grid then
        grid:Hide();
    end
]=]);

EMST:SetAttribute("_onmouseup", [=[
    local f = self:GetFrameRef("EditModeManagerFrame");
    if not f:IsShown() then return end;

    f:SetAlpha(1);

    local total = self:GetAttribute("numSelections") or 0;
    local selection;

    for i = 1, total do
        selection = self:GetFrameRef("SystemFrame"..i);
        if selection then
            selection:Show();
        end
    end

    local grid = self:GetFrameRef("Grid");
    if grid then
        grid:Show();
    end
]=]);

EMST:SetFrameRef("Grid", EditFrame.Grid);

local function EditModeManagerFrame_OnShow(self)
    NUM_ACTIVE_SELECTIONS = #EditFrame.registeredSystemFrames;
    EMST:SetAttribute("numSelections", NUM_ACTIVE_SELECTIONS);

    for i, systemFrame in ipairs(EditFrame.registeredSystemFrames) do
        SecureHandlerSetFrameRef(EMST, "SystemFrame"..i, systemFrame.Selection);
    end
end

EditFrame:HookScript("OnShow", EditModeManagerFrame_OnShow);
--]]