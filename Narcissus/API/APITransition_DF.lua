local _, addon = ...
local TransitionAPI = addon.TransitionAPI;

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


function TransitionAPI.SetGradient(texture, orientation, minR, minG, minB, maxR, maxG, maxB)
    local minColor = CreateColor(minR, minG, minB, 1);
    local maxColor = CreateColor(maxR, maxG, maxB, 1);
    texture:SetGradient(orientation, minColor, maxColor);
end

function TransitionAPI.SetTrackingPets(state)
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

function TransitionAPI.SetModelLight(model, enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
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

function TransitionAPI.GetModelLight(model)
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

function TransitionAPI.SetModelLightFromModel(toModel, fromModel)
    local enabled, light = fromModel:GetLight();
    toModel:SetLight(enabled, light);
end

function TransitionAPI.TransformCameraSpaceToModelSpace(model, x, y, z)
    SharedVector3D:SetXYZ(x, y, z);
    return model:TransformCameraSpaceToModelSpace(SharedVector3D);
end

function TransitionAPI.SetCameraPosition(model, x, y, z)
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end
    model:SetCameraPosition(x, y, z);
end

function TransitionAPI.SetCameraTarget(model, x, y, z)
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end
    model:SetCameraTarget(x, y, z);
end

function TransitionAPI.SetModelPosition(model, x, y, z)
    if type(x) == "table" then
        x, y, z = x:GetXYZ();
    end
    model:SetPosition(x, y, z);
end

function TransitionAPI.SetModelByUnit(model, unit)
    local _, raceFileName = UnitRace(unit);
    if raceFileName == "Dracthyr" or raceFileName == "Worgen" then
        local arg = WantsAlteredForm(unit);
        model:SetUnit(unit, true, arg);
    else
        model:SetUnit(unit, true);
    end
    model.unit = unit;
end

function TransitionAPI.IsPlayerInAlteredForm()
	return
end

do
    local _, RACE_FILE_NAME = UnitRace("player");

    if RACE_FILE_NAME == "Dracthyr" or RACE_FILE_NAME == "Worgen" then
        function TransitionAPI.IsPlayerInAlteredForm()
            if WantsAlteredForm("player") then
                return
            else
                return true
            end
        end
    end
end