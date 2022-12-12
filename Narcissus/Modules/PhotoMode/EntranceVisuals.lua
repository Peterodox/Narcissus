local pi = math.pi;
local TO_FACING = -pi/8;
local sin = math.sin;
local After = C_Timer.After;
local PlaySound = PlaySound;

local function outSine(t, b, c, d)
	return c * sin(t / d * (pi / 2)) + b
end

local function outQuad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

local function PlaySFX(id)
	PlaySound(id, "SFX", false);
end

local function Entrance_DH(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	local offset = outQuad(self.t, 2, self.defaultZ - 2, t)

	ModelFrame:SetPosition(0, ModelFrame.posY, offset)
	ModelFrame.posZ = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end
	
	if self.t <= 0.2 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:SetAnimation(39, 1)
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
			ModelFrame:ApplySpellVisualKit(79517, true);
			--ModelFrame:ApplySpellVisualKit(40277, true);
		end);
		After(0.9, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Mage(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
			ModelFrame:ApplySpellVisualKit(68828, true);
			ModelFrame:ApplySpellVisualKit(68661, true);	--65750 Blast
		end);
		After(1.1, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Warlock(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	ModelFrame:SetAlpha(0);
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:FreezeAnimation(1056, 0, 1);
		After(0, function()
			ModelFrame:ApplySpellVisualKit(71357, true);
			After(1, function()
				ModelFrame:SetAlpha(0);
			end);
		end);
		After(1.8, function()
			PlaySFX(139198);
			ModelFrame:SetAnimation(55);
			After(0.1, function()
				ModelFrame:SetAlpha(1)
				ModelFrame:ApplySpellVisualKit(86545, true);
			end)

			After(1, function()
				ModelFrame:SetAnimation(804, 1);
			end);
		end);

	end
end

local function Entrance_Rogue(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
            ModelFrame:ApplySpellVisualKit(105866, true);
		end);
		--[[
		After(0.3, function()
            ModelFrame:ApplySpellVisualKit(105969, true);	--FPS drop
		end);
		--]]
		After(0.8, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Priest(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
			ModelFrame:ApplySpellVisualKit(41593, true);
			ModelFrame:ApplySpellVisualKit(44806, true);	--10875
		end);
		After(0.6, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_DK(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
            ModelFrame:ApplySpellVisualKit(57627, true);
            ModelFrame:ApplySpellVisualKit(57287, true);
        end);
		After(0.8, function()
            ModelFrame:SetAnimation(142, 1);
        end);
		After(2, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Monk(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local turnTime = 0.36
	local t = 1;
	local offset = outQuad(self.t, self.startY, self.defaultY - self.startY, t)

	if self.t > turnTime then
		self.faceTime= self.faceTime + elapsed;
		local radian = outSine(self.faceTime, -pi/2, -pi/8 + pi/2, 0.8) --0.11 NE
		ModelFrame:SetFacing(radian)
        ModelFrame.rotation = radian
	end

	ModelFrame:SetPosition(0, offset, ModelFrame.posZ)
	ModelFrame.posY = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end

	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:ApplySpellVisualKit(6095, true);	--Cloud
		After(0.8, function()
			ModelFrame:ApplySpellVisualKit(65638, true);	--65217
			ModelFrame:SetAnimation(116, 1);
			PlaySFX(32858)
		end)
		After(1.6, function()
            ModelFrame:SetAnimation(804, 1);
        end);
	end
end

local function Entrance_Warrior(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	local offset = outQuad(self.t, 6, self.defaultZ - 6, t)

	ModelFrame:SetPosition(0, ModelFrame.posY, offset)
	ModelFrame.posZ = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		
		ModelFrame:SetAnimation(39, 1)
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
			PlaySFX(76938)
		end);
		After(0.2, function()
			ModelFrame:ApplySpellVisualKit(77753, true);	--shockwave
			ModelFrame:ApplySpellVisualKit(113504, true)
        end);
		After(0.8, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Shaman(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.3;
	local offset = outQuad(self.t, 2, self.defaultZ - 2, t)

	ModelFrame:SetPosition(0, ModelFrame.posY, offset)
	ModelFrame.posZ = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end

	if self.t <= 0 then
		return;
	elseif self.trigger then
        self.trigger = false;
		ModelFrame:ApplySpellVisualKit(100019, true);	--74261 Thunder
		ModelFrame:SetAnimation(115, 1)
		After(0.2, function()
            ModelFrame:SetAnimation(116, 1)
        end);
		After(1.4, function()
            ModelFrame:SetAnimation(804, 1);
        end);
	end
end

local function Entrance_Druid(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1;
	self.t = self.t + elapsed;
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		local id = 78803 + math.random(0, 3);
		ModelFrame:ApplySpellVisualKit(id, true);
		ModelFrame:ApplySpellVisualKit(82209, true);	--81597
		ModelFrame:ApplySpellVisualKit(81597, true);
		After(0.2, function()
            ModelFrame:SetAnimation(142, 1);
        end);
		After(2, function()
			ModelFrame:SetAnimation(804, 1);
		end);
	end
end

local function Entrance_Paladin(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 0.25;
	if self.t >= t then
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0, function()
			ModelFrame:ApplySpellVisualKit(109802, true);
			ModelFrame:ApplySpellVisualKit(105334, true);
        end);
		After(0.8, function()
            ModelFrame:SetAnimation(142, 1);
        end);
		After(2, function()
			ModelFrame:SetAnimation(804, 1)
		end);
	end
end

local function Entrance_Hunter(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local turnTime = 0.36
	local t = 1;
	local offset = outQuad(self.t, self.startY, self.defaultY - self.startY, t)

	if self.t > turnTime then
		self.faceTime= self.faceTime + elapsed;
		local radian = outSine(self.faceTime, -pi/2, TO_FACING + pi/2, 0.8) --0.11 NE
		ModelFrame:SetFacing(radian)
		ModelFrame.rotation = radian
	end

	ModelFrame:SetPosition(0, offset, ModelFrame.posZ)
	ModelFrame.posY = offset;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0.8 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:ApplySpellVisualKit(11212, true);
		After(0.2, function()
			ModelFrame:SetAnimation(113);
		end)
		After(1.8, function()
			ModelFrame:SetAnimation(804, 1);
		end)
		ModelFrame:MakeCurrentCameraCustom();
	end
end


local function Entrance_Evoker_VisageForm(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local turnTime = 0.36
	local t = 1;
	local offsetX = outQuad(self.t, -3, 3, t)
	local offsetY = outQuad(self.t, self.startY, self.defaultY - self.startY, t)

	ModelFrame:SetPosition(offsetX, offsetY, ModelFrame.posZ)
	ModelFrame.posY = offsetY;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		local id = math.random(0, 4);
		local visualID;
		if id == 0 then
			visualID = 162625;
		elseif id == 1 then
			visualID = 172117;
		elseif id == 2 then
			visualID = 162707;
		elseif id == 3 then
			visualID = 162709;
		elseif id == 4 then
			visualID = 162713;
		end
		ModelFrame:ApplySpellVisualKit(visualID, true);
		--[[
		After(0.2, function()
            ModelFrame:SetAnimation(142, 1);
        end);
		--]]
		After(1.08, function()
			ModelFrame:SetAnimation(804, 1);
		end);
	end
end


local function Entrance_Evoker_Dragonform(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1
	self.t = self.t + elapsed
	local t = 1;
	local offsetX = outSine(self.t, -20, 20, t)
	local offsetY = outSine(self.t, self.startY, self.defaultY - self.startY, t)

	ModelFrame:SetPosition(offsetX, offsetY, ModelFrame.posZ)
	ModelFrame.posY = offsetY;
	if self.t >= t then
		ModelFrame.posX = 0;
		self.t = 0;
		self:Hide();
	end
	
	if self.t <=0 then
		return;
	elseif self.trigger then
		self.trigger = false;
		ModelFrame:MakeCurrentCameraCustom();
		After(0.15, function()
			ModelFrame:ApplySpellVisualKit(172235, true);
		end);
		After(0.5, function()
			ModelFrame:SetAnimation(1610, 1);	--1694
		end);
		After(1.0, function()
			ModelFrame:SetAnimation(1478, 1);	--1694
		end);
		After(1.6, function()
			ModelFrame:SetAnimation(804, 1);	--1694
		end);
	end
end

local function Entrance_Evoker(self, elapsed)
	local ModelFrame = NarciPlayerModelFrame1;
	local modelFileID = ModelFrame:GetModelFileID();
	if modelFileID == 4207724 then
		self:SetScript("OnUpdate", Entrance_Evoker_Dragonform);
		self.startY = 8;
		ModelFrame:SetAnimation(1580);
	else
		self:SetScript("OnUpdate", Entrance_Evoker_VisageForm);
		self.startY = 2.5;
		ModelFrame:SetAnimation(4);
	end
end

Narci.ClassEntranceVisuals = {
    --[[
            1
                Warrior 	WARRIOR
            2
                Paladin 	PALADIN	
            3
                Hunter 	HUNTER
            4
                Rogue 	ROGUE
            5
                Priest 	PRIEST
            6
                Death Knight 	DEATHKNIGHT
            7
                Shaman 	SHAMAN
            8
                Mage 	MAGE
            9
                Warlock 	WARLOCK
            10
                Monk 	MONK
            11
                Druid 	DRUID
            12
                Demon Hunter 	DEMONHUNTER 
    --]]
	--[classID] = {startY, startZ, startFacing, startAnimationID, UpdateFunc, SoundID},
	[1]  = {false, 6, false, 38, Entrance_Warrior, 76955},
	[2]  = {false, false, false, 141, Entrance_Paladin, 90434},    --942
	[3]  = {2.5, false, -pi/2, 4, Entrance_Hunter, false},    --
	[4]  = {false, false, false, 1002, Entrance_Rogue, 101593},
	[5]  = {false, false, false, 1122, Entrance_Priest, 84001},
	[6]  = {false, false, false, 141, Entrance_DK, 13168},
	[7]  = {false, 2, false, 40, Entrance_Shaman, 59081},
	[8]  = {false, false, false, 1120, Entrance_Mage, 3226},
	[9]  = {false, false, false, 55, Entrance_Warlock, 116927},
	[10]  = {2.5, false, -pi/2, 732, Entrance_Monk, 32860},
	[11]  = {false, false, false, 141, Entrance_Druid, 86938},
    [12] = {false, 2, false, 38, Entrance_DH, 119406},	--62730 Spell_DH_ImmolationAura_Cast
	[13] = {2.5, false, false, 4, Entrance_Evoker, false},
	--[13] = {8, false, false, 1580, Entrance_Evoker_Dragonform, false},
	--Test Override
	--[4]  = {false, false, false, 55, Entrance_Warlock, 116927},
};

--[[

8.2.5 120270
8.3.0 122002

Mail box
120565
120835 Wing
120879 Heart Channeling
121946 Tent
121990 Purification Protocol

76146 Kill command
--]]