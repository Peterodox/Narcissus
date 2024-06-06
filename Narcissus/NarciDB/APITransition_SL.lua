local _, addon = ...

if addon.IsDragonflight() then
    return
end

local TransitionAPI = addon.TransitionAPI;


function TransitionAPI.IsDragonflight()
    return false
end

function TransitionAPI.SetGradient(texture, orientation, minR, minG, minB, maxR, maxG, maxB)    --#1
    texture:SetGradient(orientation, minR, minG, minB, maxR, maxG, maxB);
end

function TransitionAPI.IsRTXSupported()     --#2
    local supported;

	if Advanced_RTShadowQualityDropDown then
		supported = true;
	end

    if GetToolTipInfo then
        local info = { GetToolTipInfo(1, 4, "shadowrt", 0, 1, 2, 3) };
        for i = 1, #info do
            if info[i] ~= 0 then
                supported = supported and false;
                break
            end
        end
    end

    return supported
end

function TransitionAPI.HookSocketContainerItem(callback)     --#3
    hooksecurefunc("SocketContainerItem", callback);
end

function TransitionAPI.HookSocketInventoryItem(callback)     --#4
    hooksecurefunc("SocketInventoryItem", callback);
end

function TransitionAPI.IsTrackingPets()      --#5
    local id = 1;
    local state = GetTrackingInfo(id);
    return state
end

function TransitionAPI.SetTrackingPets(enabled)      --#6
    local id = 1;
    local state = GetTrackingInfo(id);
    if state ~= enabled then
        SetTracking(id, enabled);
    end
end

function TransitionAPI.SetModelLight(model, enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)        --#7
    model:SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB);
end

function TransitionAPI.GetModelLight(model)        --#8
    return model:GetLight();
end

function TransitionAPI.TransformCameraSpaceToModelSpace(model, x, y, z)     --#9
    return model:TransformCameraSpaceToModelSpace(x, y, z);
end

function TransitionAPI.SetCameraPosition(model, x, y, z)        --#10
    model:SetCameraPosition(x, y, z);
end

function TransitionAPI.SetCameraTarget(model, x, y, z)     --#11
    model:SetCameraTarget(x, y, z);
end

function TransitionAPI.SetModelPosition(model, x, y, z)     --#12
    model:SetPosition(x, y, z);
end

function TransitionAPI.SetModelByUnit(model, unit)      --#13
	model:SetUnit(unit);
    model.unit = unit;
end

function TransitionAPI.IsPlayerInAlteredForm()      --#14
	return
end

do
    local _, raceFilename = UnitRace("player");
    if raceFilename == "Worgen" then
        local GetAlternateFormInfo = C_PlayerInfo.GetAlternateFormInfo or HasAlternateForm;

        function TransitionAPI.IsPlayerInAlteredForm()      --#15
            local _, inAlternateForm = GetAlternateFormInfo();
            if inAlternateForm then
                --Human
                return true
            else
                return
            end
        end
    end
end

function TransitionAPI.SetModelLightFromModel(toModel, fromModel)      --#15
    toModel:SetLight(fromModel:GetLight());
end

