--"SetCustomRace" removed in 10.1.5

local function CustomModelPosition(model, raceID, genderID)
	model:MakeCurrentCameraCustom();
	raceID = ReAssignRaceID(raceID, true);

	local data;
	if genderID == 2 then
		data = TranslateValue_Male[raceID][2];
	else
		data = TranslateValue_Female[raceID][2];
	end

	model:SetPosition(0, data[2], data[3]);
	model:SetPortraitZoom(data[1]);
	model:MakeCurrentCameraCustom();
	After(0, function()
		model:ResetCameraPosition();
	end)
end

function Narci_GenderButton_OnLoad(self)
	self.tooltipDescription = Narci.L["Sex Change Tooltip"];
	local _, genderID = GetUnitRaceIDAndSex("player");
	SetGenderIcon(genderID);
end

local function RestoreModelAfterRaceChange(model)
	if model.isPaused then
		model:Freeze(model.animationID or 804);
	else
		model:PlayAnimation(model.animationID or 804);
	end

	After(0, function()
		local visualID;
		local AppliedVisuals = model.AppliedVisuals;
		for i = 1, #AppliedVisuals do
			visualID = AppliedVisuals[i];
			if visualID then
				model:ApplySpellVisualKit(visualID, false);
			end
		end
		if model.isVirtual then
			model:SetModelAlpha(0);
		else
			model:SetModelAlpha(1);
		end

		model.hasRaceChanged = true;
		--Weapons Gone
		--It seems that after race change, the model can no longer get dressed or undressed
		--[[
		local WeaponInfo = ActorPanel;
		if WeaponInfo.MainHandSource then
			model:TryOn(WeaponInfo.MainHandSource, "MAINHANDSLOT", WeaponInfo.MainHandEnchant);
		end
		if WeaponInfo.OffHandSource then
			model:TryOn(WeaponInfo.OffHandSource, "SECONDARYHANDSLOT", WeaponInfo.OffHandEnchant);
		end
		--]]
	end)
end

--[[
function Narci_GenderButton_OnClick(self)
	local index = ACTIVE_MODEL_INDEX;
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local genderID = PlayerInfo[index].gender or 2;
	local raceID = PlayerInfo[index].raceID;
	local _, _, dirX, dirY, dirZ, _, ambR, ambG, ambB, _, dirR, dirG, dirB = GetModelLight(model);
	model:SetBarberShopAlternateForm();
	if genderID == 2 then
		model:SetCustomRace(raceID, 1);
		genderID = 3;
	elseif genderID == 3 then
		model:SetCustomRace(raceID, 0);
		genderID = 2;
	end
	PlayerInfo[index].gender = genderID;
	SetGenderIcon(PlayerInfo[index].gender);
	model:SetModelAlpha(0);
	After(0, function()
		CustomModelPosition(model, raceID, genderID);
		After(0, function()
			RestoreModelAfterRaceChange(model);
			SetModelLight(model, true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
		end);
	end);
end


local AutoCloseTimer2 = C_Timer.NewTimer(0, function()	end);

local function AutoCloseRaceOption(time)
	AutoCloseTimer2:Cancel();
	AutoCloseTimer2 = C_Timer.NewTimer(time, function()
		if NarciModelControl_ActorButton.isOn then
			NarciModelControl_ActorButton:Click();
		end
	end)
end

function Narci_RaceOptionButton_OnEnter(self)
	self.Highlight:Show();
	AutoCloseTimer2:Cancel();
end

function Narci_RaceOptionButton_OnLeave(self)
	self.Highlight:Hide();
	AutoCloseRaceOption(2);
end

function Narci_RaceOptionButton_OnClick(self)
	AutoCloseTimer2:Cancel();
	local model = ModelFrames[ACTIVE_MODEL_INDEX];
	local genderID = PlayerInfo[ACTIVE_MODEL_INDEX].gender;
	local raceID = self:GetID() or 1;
	PlayerInfo[ACTIVE_MODEL_INDEX].raceID = raceID;
	local _, _, dirX, dirY, dirZ, _, ambR, ambG, ambB, _, dirR, dirG, dirB = GetModelLight(model);
	model:SetBarberShopAlternateForm();
	if genderID == 2 then
		model:SetCustomRace(raceID, 0);
	else
		model:SetCustomRace(raceID, 1);
	end
	AutoCloseRaceOption(4);
	
	model:SetModelAlpha(0);
	After(0, function()
		CustomModelPosition(model, raceID, genderID);
		After(0, function()
			RestoreModelAfterRaceChange(model);
			SetModelLight(model, true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
		end);
	end);
end

--]]