function CreateDressingRoomModelDuplicate()
    local ModelScene = DressUpFrame.ModelScene;

    local playerActor = ModelScene:GetPlayerActor();
    local duplicateActor = ModelScene:CreateActor();
    duplicateActor:SetModelByUnit("player", playerActor:GetSheathed(), true);

    C_Timer.After(0.1, function()
        local scale = playerActor:GetScale();
        duplicateActor:SetScale(scale);

        local centeX, centerY, centerZ = playerActor:IsUsingCenterForOrigin();
        duplicateActor:SetUseCenterForOrigin(centeX, centerY, centerZ);

        for _, actor in pairs({playerActor, duplicateActor}) do
            actor:SetPosition(0, 0, 0);
            actor:SetAnimation(0, 0, 1, 0);
            actor:SetYaw(-math.pi*0.5);
            actor:UndressSlot(16);
            actor:UndressSlot(17);
        end
    end);
end

--/script local m=DressUpFrame.ModelScene;local a1,a2=m:GetPlayerActor(),m:CreateActor();a2:SetModelByUnit("player", true, true);local x,y,z=a1:IsUsingCenterForOrigin();a2:SetUseCenterForOrigin(x,y,z);TEMP_ACTORS={a1,a2};
--/script TEMP_ACTORS[2]:SetScale(TEMP_ACTORS[1]:GetScale());for _, a in pairs(TEMP_ACTORS) do a:SetPosition(0, 0, 0);a:SetAnimation(618, 0, 1, 0);a:SetYaw(-1.57);a:UndressSlot(16);a:UndressSlot(17);end