local After = C_Timer.After;

local entranceDelay = NarciAPI_CreateAnimationFrame(0.25);
entranceDelay:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide()
        if self.callBack then
            self.callBack();
        end
    end
end);

function entranceDelay:SetCallBack(func)
    self:Hide();
    self.callBack = func;
    self:Show();
end

local requestDelay = NarciAPI_CreateAnimationFrame(0.25);
requestDelay:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide()
        if self.callBack then
            self.callBack();
        end
    end
end);

function requestDelay:SetCallBack(func)
    self:Hide();
    self.callBack = func;
    self:Show();
end

----------------------------------------------------------------------------
NarciAchievementRewardModelMixin = CreateFromMixins(ModelSceneMixin);

function NarciAchievementRewardModelMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
end

function NarciAchievementRewardModelMixin:Initialize()
    self.reversedLighting = true;
    self:OnLoad();
    self.description = self.ClipFrame.description;
    self.flyIn = self.ClipFrame.description.flyIn;
    self.arrow.spring:Play();

    --Fade In/Out
    local animation = NarciAPI_CreateAnimationFrame(0.15);

    animation:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local alpha = frame.fromAlpha + frame.delta;
        frame.fromAlpha = alpha;
        if alpha <= 0 then
            alpha = 0;
            frame:Hide();
            self:Hide();
        elseif alpha >= 1 then
            alpha = 1;
            frame:Hide();
        end
        self:SetAlpha(alpha);
    end);
    
    function self:FadeIn()
        animation:Hide();
        local state = self:IsShown();
        local alpha = self:GetAlpha();
        animation.fromAlpha = alpha;
        if state then
            if alpha ~= 1 then
                animation.delta = 1 / animation.duration / 60;
                animation:Show();
            end
        else
            entranceDelay:SetCallBack(
                function()
                    self:Show();
                    animation.delta = 1 / animation.duration / 60;
                    animation:Show();
                end
            );
        end
    end
    
    function self:FadeOut()
        if not self:IsShown() then return end
        animation:Hide();
        animation.fromAlpha = self:GetAlpha();
        animation.delta = - 1 / animation.duration / 60;
        animation:Show();
    end

    function self:ClearCallback()
        entranceDelay.callBack = nil;
    end
end

function NarciAchievementRewardModelMixin:SetItem(itemID, breakLoop)
    requestDelay:SetCallBack(nil);

    local mountID = C_MountJournal.GetMountFromItem(itemID);
    local ModelScene = self;
    local _, mode, actorTag, modelSceneID, creatureDisplayID, creatureName, description, icon, isSelfMount, isCollected;

    if mountID and mountID ~= 0 then
        
        if mountID == ModelScene.mountID and ModelScene.mode == "mount" then
            self:FadeIn();
            if self.isCollected then
                self.SummonButton:Show();
            end
            return
        else
            mode = "mount";
            ModelScene.mode = "mount";
            actorTag = "unwrapped";
            ModelScene.mountID = mountID;
        end
        
        creatureName, _, icon, _, _, _, _, _, _, _, isCollected  = C_MountJournal.GetMountInfoByID(mountID);
        creatureDisplayID, description, _, isSelfMount, _, modelSceneID, animID= C_MountJournal.GetMountInfoExtraByID(mountID);
        
        self.isCollected = isCollected;
        self.SummonButton:SetShown(isCollected);
        self.SummonButton.label:SetText(MOUNT);
    else
        local petID, speciesID;
        creatureName, icon, _, petID, _, description, _, _, _, _, _, creatureDisplayID, speciesID = C_PetJournal.GetPetInfoByItemID(itemID);

        if (petID and creatureDisplayID) then
            
            --print("This is a pet:"..creatureName);
            if petID == ModelScene.petID and ModelScene.mode == "battlepet" then
                self:FadeIn();
                if self.isCollected then
                    self.SummonButton:Show();
                end
                return
            else
                mode = "battlepet";
                ModelScene.mode = "battlepet";
                modelSceneID = C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID);  --cardModelSceneID, loadoutModelSceneID
                actorTag = "unwrapped";
                ModelScene.petID = petID;
            end
            local _, petGUID = C_PetJournal.FindPetIDByName(creatureName);
            if petGUID then
                isCollected = C_PetJournal.PetIsSummonable(petGUID);
            end
            self.petGUID = petGUID;
            self.isCollected = isCollected;
            self.SummonButton:SetShown(isCollected);
            self.SummonButton.label:SetText(BATTLE_PET_SUMMON);

        else
            --neither mount or pet
            if breakLoop then
                self:FadeOut();
                --print("No Data");
            else
                --Request model info again
                requestDelay:SetCallBack(function()
                    self:SetItem(itemID, true);
                end);
            end
            self.SummonButton:Hide();

            return false
        end
    end

    ModelScene.itemIcon:SetTexture(icon);
    --Cropped Description Text
    ModelScene.flyIn:Stop();
    ModelScene.header:SetText(creatureName);
    ModelScene.description:SetText(description);

    local textHeight = ModelScene.description:GetHeight();
    local clipHeight = ModelScene.ClipFrame:GetHeight();
    if textHeight > clipHeight then
        local offset = textHeight - clipHeight;
        ModelScene.flyIn.offset:SetOffset(0, offset);
        ModelScene.flyIn.offset:SetDuration( offset / 8 );
        ModelScene.flyIn:Play();
        ModelScene.arrow:Show();
    else
        ModelScene.arrow:Hide();
    end

	local forceEvenIfSame = false;
	ModelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceEvenIfSame);
	
    local actor = ModelScene:GetActorByTag(actorTag);

	if actor then
		actor:SetModelByCreatureDisplayID(creatureDisplayID);
        local fromZoom, toZoom;
        -- mount self idle animation
        if mode == "mount" then
            fromZoom = 15;
            toZoom = 12;
            if (isSelfMount) then
                actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_NONE);
                actor:SetAnimation(618); -- MountSelfIdle
            else
                actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_ANIM);
                actor:SetAnimation(0);
            end
            --ModelScene:AttachPlayerToMount(actor, animID, isSelfMount, disablePlayerMountPreview);
            ModelScene:SetViewInsets(0, 0, 0, 0);
        else
            fromZoom = 24;
            toZoom = 15;
            actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_NONE);
            actor:SetAnimation(0, -1);
            ModelScene:SetViewInsets(0, 0, 80, 0);
        end


        --Zoom-In Transition
        local camera = ModelScene:GetActiveCamera();
        --local d = camera:GetZoomDistance();
        
        camera:SetZoomDistance(fromZoom);
        camera:SnapAllInterpolatedValues();
        actor:SetAlpha(0);
        After(0, function()
            UIFrameFadeIn(actor, 0.15, 0, 1);
            camera:SetZoomDistance(toZoom);
            ModelScene:SetLightDirection(-0.0655, 1, 0);
        end)
        
    end
    
    self:FadeIn();
	return true;
end