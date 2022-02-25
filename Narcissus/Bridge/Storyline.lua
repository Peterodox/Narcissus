--Storyline by EllypseCelwe [Quest AddOn]
--Modify Lights

if true then return end

local function SetModelLight(model, horizontalAngle, verticalAngle)
    local rad, sin, cos = math.rad, math.sin, math.cos;
    local r1, r2 = rad(horizontalAngle), rad(verticalAngle);
    local x, y, z = sin(r1) * cos(r2), sin(r1) * sin(r2), cos(r1);
    model:SetLight(true, false, x, -y, -z, 1, 0.68, 0.6, 0.72, 1, 0.6, 0.6, 0.6);
end

local Bridge = CreateFrame("Frame");
Bridge:RegisterEvent("PLAYER_ENTERING_WORLD");
Bridge:SetScript("OnEvent", function(self)
    C_Timer.After(1, function()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if Storyline_NPCFrameModelsYou and Storyline_NPCFrameModelsMe then
            SetModelLight(Storyline_NPCFrameModelsYou, -45, 45);
            SetModelLight(Storyline_NPCFrameModelsMe, -60, -60);
        end
    end);
end)