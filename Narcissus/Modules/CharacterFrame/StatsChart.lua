local _, addon = ...
local UIColorThemeUtil = addon.UIColorThemeUtil;
local FadeFrame = NarciFadeUI.Fade;
local GetEffectiveCrit = Narci.GetEffectiveCrit;
local GetCombatRating = GetCombatRating;
local outSine = addon.EasingFunctions.outSine;

local max = math.max;

local CR_HASTE_MELEE = CR_HASTE_MELEE;
local CR_MASTERY = CR_MASTERY;
local CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE;


NarciRadarChartMixin = {}

function NarciRadarChartMixin:OnLoad()
	local circleTex = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\RadarChart\\Radar-Vertice";
	local filter = "TRILINEAR";
	local tex;
	local texs = {};
	for i = 1, 4 do
		tex = self:CreateTexture(nil, "OVERLAY", nil, 2);
		table.insert(texs, tex);
		tex:SetSize(12, 12);
		tex:SetTexture(circleTex, nil, nil, filter);
	end

	self.vertices = texs;

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;

	self.deg = math.deg;
	self.rad = math.rad;
	self.atan2 = math.atan2;
	self.sqrt = math.sqrt;

	self.onFisrtShow = function()
		self:UpdateStatsGetter();
	end
end

function NarciRadarChartMixin:OnShow()
	self.MaskedBackground:SetAlpha(0.4);
	self.MaskedBackground2:SetAlpha(0.4);

	if self.onFisrtShow then
		self.onFisrtShow();
		self.onFisrtShow = nil;
	end
end

function NarciRadarChartMixin:OnHide()
	self:StopAnimating();
end

function NarciRadarChartMixin:SetVerticeSize(attributeFrame, size)
	local name = attributeFrame.token;
	local vertice;
	if name == "Crit" then
		vertice = self.vertices[1];
	elseif name == "Haste" then
		vertice = self.vertices[2];
	elseif name == "Mastery" then
		vertice = self.vertices[3];
	elseif name == "Versatility" then
		vertice = self.vertices[4];
	end
	vertice:SetSize(size, size);
end

function NarciRadarChartMixin:UpdateColor()
	UIColorThemeUtil:SetWidgetColor(self.MaskedBackground);
	UIColorThemeUtil:SetWidgetColor(self.MaskedBackground2);
	UIColorThemeUtil:SetWidgetColor(self.MaskedLine1);
	UIColorThemeUtil:SetWidgetColor(self.MaskedLine2);
	UIColorThemeUtil:SetWidgetColor(self.MaskedLine3);
	UIColorThemeUtil:SetWidgetColor(self.MaskedLine4);
end


function NarciRadarChartMixin:SetValue(c, h, m, v)
	--c, h, m, v: Input manually or use combat ratings

	local chartWidth = 96 / 2;	--In half

	local crit, haste, mastery, versatility;
	if c then
		crit = c;
	else
		local _, rating = GetEffectiveCrit();
		crit = GetCombatRating(rating) or 0;
	end
	if h then
		haste = h;
	else
		haste = GetCombatRating(CR_HASTE_MELEE) or 0;
	end
	if m then
		mastery = m;
	else
		mastery = GetCombatRating(CR_MASTERY) or 0;
	end
	if v then
		versatility = v;
	else
		versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0;
	end

	--		|	p1(x1,y1)	  Line4		p3(x3,y3)
	--		|			*				*
	--		|			 	*		*
	--		|	Line1		 	*		   Line3
	--		|			 	*		*
	--		|			*				*
	--		|	p2(x2,y2)	  Line2		p4(x4,y4)

	local v1, v2, v3, v4, v5, v6 = true, true, true, true, true, true;
	if crit == 0 and haste == 0 and mastery == 0 and versatility == 0 then
		v1, v2, v3, v4, v5, v6 = false, false, false, false, false, false;
	else
		if crit == 0 and haste == 0 then v1 = false; end;
		if haste == 0 and versatility == 0 then v2 = false; end;
		if mastery == 0 and versatility == 0 then v3 = false; end;
		if crit == 0 and mastery == 0 then v4 = false; end;
		crit, haste, mastery = crit + 0.03, haste + 0.02, mastery + 0.01;				--Avoid some mathematical issues
	end
	self.MaskedLine1:SetShown(v1);
	self.MaskedLine2:SetShown(v2);
	self.MaskedLine3:SetShown(v3);
	self.MaskedLine4:SetShown(v4);
	self.MaskedBackground:SetShown(v5);
	self.MaskedBackground2:SetShown(v6);

	--[[
		--4500 9.0 Stats sum Level 50
		Enchancements on ilvl 445 (Mythic Eternal Palace) Player Lvl 120
		Neck 159 Weapon 25 Back 51 Wrist 28 Hands 37 Waist 36 Legs 50 Feet 37 Ring 89 Trinket 35	Max:696 + 12*7 ~= 800
		Player Lvl 60 iLvl 233(Mythic Castle Nathria):	Back 82 Leg 141 Chest 141 Neck 214 Waist 105 Hand 105 Feet 105 Wrist 79 Ring 226 Shoulder 109  Head 146 Trinket 200 ~=1900
		Player Lvl 60 iLvl 259(Mythic Sanctum of Domination):	Back 90 Leg 165 Chest 165 Neck 268 Waist 124 Hand 130 Feet 124 Wrist 91 Ring 268 Shoulder 124  Head 146 Trinket 200 weapon 162 ~= 2500 (+ 8 sockets)


		ilvl 240 (Mythic Antorus) Player Lvl 110
		Head 87 Shoulder 64 Chest 88 Weapon 152 Back 49 Wrist 49 Hands 64 Waist 64 Legs 87 Feet 63 Ring 165 Trinket 62	Max ~= 1100
		ilvl 149 (Mythic HFC) Player Lvl 100
		Head 48 Shoulder 36 Chest 48 Weapon 24 Back 28 Wrist 27 Hands 36 Waist 36 Legs 48 Feet 35 Ring 27 Trinket 32	Max ~= 510
		Heirlooms Player Lvl 20
		Weapon 4 Back 4 Wrist 4 Hands 6 Waist 6 Legs 8 Feet 6 Ring 5 Trinket 6	 ~= 60
	--]]

	local sum = self.bestSum or 0;
	local maxNum = max(crit + haste + mastery + versatility, 1);
	if maxNum > 0.95 * sum then
		sum = maxNum;
	end

	local d1, d2, d3, d4 = (crit / sum), (haste / sum) , (mastery / sum) , (versatility / sum);
	local a;
	if (d1 + d4) ~= 0 and (d2 + d3) ~= 0 then
		--a = chartWidth * math.sqrt(0.618/(d1 + d4)/(d2 + d3)/2)* 96;
		a = 1.414 * chartWidth;
	else
		a = 0;
	end

	local x1, x2, x3, x4 = -d1*a, -d2*a, d3*a, d4*a;
	local y1, y2, y3, y4 = d1*a, -d2*a, d3*a, -d4*a;
	local mx1, mx2, mx3, mx4 = (x1 + x2)/2, (x2 + x4)/2, (x3 + x4)/2, (x1 + x3)/2;
	local my1, my2, my3, my4 = (y1 + y2)/2, (y2 + y4)/2, (y3 + y4)/2, (y1 + y3)/2;

	local ma1 = self.atan2((y1 - y2), (x1 - x2));
	local ma2 = self.atan2((y2 - y4), (x2 - x4));
	local ma3 = self.atan2((y4 - y3), (x4 - x3));
	local ma4 = self.atan2((y3 - y1), (x3 - x1));

	if my1 == 0 then
		my1 = 0.01;
	end
	if my3 == 0 then
		my1 = -0.01;
	end
	if self.deg(ma1) == 90 then
		ma1 = self.rad(89);
	end
	if self.deg(ma3) == -90 then
		ma1 = self.rad(-89);
	end

	self.vertices[1]:SetPoint("CENTER", x1, y1);
	self.vertices[2]:SetPoint("CENTER", x2, y2);
	self.vertices[3]:SetPoint("CENTER", x3, y3);
	self.vertices[4]:SetPoint("CENTER", x4, y4);

	self.Mask1:SetRotation(ma1);
	self.Mask2:SetRotation(ma2);
	self.Mask3:SetRotation(ma3);
	self.Mask4:SetRotation(ma4);

	local hypo1 = self.sqrt(2*x1^2 + 2*x2^2);
	local hypo2 = self.sqrt(2*x2^2 + 2*x4^2);
	local hypo3 = self.sqrt(2*x4^2 + 2*x3^2);
	local hypo4 = self.sqrt(2*x3^2 + 2*x1^2);

	if (hypo1 - 4) > 0 then
		self.MaskLine1:SetWidth(hypo1 - 4);	--Line length
	else
		self.MaskLine1:SetWidth(0.1);
	end

	if (hypo2 - 4) > 0 then
		self.MaskLine2:SetWidth(hypo2 - 4);
	else
		self.MaskLine2:SetWidth(0.1);
	end

	if (hypo3 - 4) > 0 then
		self.MaskLine3:SetWidth(hypo3 - 4);
	else
		self.MaskLine3:SetWidth(0.1);
	end

	if (hypo4 - 4) > 0 then
		self.MaskLine4:SetWidth(hypo4 - 4);
	else
		self.MaskLine4:SetWidth(0.1);
	end

	self.MaskLine1:ClearAllPoints();
	self.MaskLine1:SetRotation(0);
	self.MaskLine1:SetRotation(ma1);
	self.MaskLine1:SetPoint("CENTER", self, "CENTER", mx1, my1);
	self.MaskLine2:ClearAllPoints();
	self.MaskLine2:SetRotation(0);
	self.MaskLine2:SetRotation(ma2);
	self.MaskLine2:SetPoint("CENTER", self, "CENTER", mx2, my2);
	self.MaskLine3:ClearAllPoints();
	self.MaskLine3:SetRotation(0);
	self.MaskLine3:SetRotation(ma3);
	self.MaskLine3:SetPoint("CENTER", self, "CENTER", mx3, my3);
	self.MaskLine4:ClearAllPoints();
	self.MaskLine4:SetRotation(0);
	self.MaskLine4:SetRotation(ma4);
	self.MaskLine4:SetPoint("CENTER", self, "CENTER", mx4, my4);
	self.Mask1:SetPoint("CENTER", mx1, my1);
	self.Mask2:SetPoint("CENTER", mx2, my2);
	self.Mask3:SetPoint("CENTER", mx3, my3);
	self.Mask4:SetPoint("CENTER", mx4, my4);

	self.MaskedBackground:SetAlpha(0.4);
	self.MaskedBackground2:SetAlpha(0.4);

	self.n1, self.n2, self.n3, self.n4 = crit, haste, mastery, versatility;
end

function NarciRadarChartMixin:AnimateValue(c, h, m, v)
	--Update the radar chart using animation

	local UpdateFrame = self.UpdateFrame;
	if not UpdateFrame then
		UpdateFrame = CreateFrame("Frame", nil, self, "NarciUpdateFrameTemplate");
		self.UpdateFrame = UpdateFrame;
		self.n1, self.n2, self.n3, self.n4 = 0, 0, 0, 0;
	end

	local s1, s2, s3, s4 = self.n1, self.n2, self.n3, self.n4;	--start/end point
	local e1, e2, e3, e4 = c or 0, h or 0, m or 0, v or 0;

	local duration = 0.2;

	local function UpdateFunc(frame, elapsed)
		local t = frame.t;
		frame.t = t + elapsed;
		local v1 = outSine(t, s1, e1, duration);
		local v2 = outSine(t, s2, e2, duration);
		local v3 = outSine(t, s3, e3, duration);
		local v4 = outSine(t, s4, e4, duration);

		if t >= duration then
			v1, v2, v3, v4 = e1, e2, e3, e4;
			frame:Hide();
		end
		self:SetValue(v1, v2, v3, v4);
	end

	UpdateFrame:Hide();
	UpdateFrame:SetScript("OnUpdate", UpdateFunc);
	UpdateFrame:Show();
end

function NarciRadarChartMixin:TogglePrimaryStats(state)
	state = false;

	if state then
		self.Primary.Color:SetColorTexture(0.24, 0.24, 0.24, 0.75);
		self.Health.Color:SetColorTexture(0.15, 0.15, 0.15, 0.75);
		FadeFrame(self.Primary, 0.15, 1);
		FadeFrame(self.Health, 0.15, 1);
		self.Primary:Update();
		self.Health:Update();
	else
		FadeFrame(self.Primary, 0.25, 0);
		FadeFrame(self.Health, 0.25, 0);
	end
end

function NarciRadarChartMixin:CalculateBestSum(e1, e2, e3, e4)
	self.bestSum = nil;

	local playerLevel = UnitLevel("player");
	local sum = e1 + e2 + e3 + e4;
	local bestSum;

	if playerLevel == 50 then
		bestSum = max(sum, 800);		--Status sum for 8.3 Raid
	elseif playerLevel == 60 then
		bestSum = max(sum, 2500);		--Status sum for 9.1 Raid
	elseif playerLevel == 80 then
		local cap = 27000;
		if sum < 0.4*cap then
			bestSum = 1.5 * sum;
		else
			bestSum = max(sum, cap);
		end
	else
		--sum = 31 * math.exp( 0.04 * UnitLevel("player")) + 40;
		bestSum = 1.5 * sum;
	end

	self.bestSum = bestSum;
end

function NarciRadarChartMixin:UpdateChart(useAnimation)
	local critChance, critRating = GetEffectiveCrit();
	local e1 = GetCombatRating(critRating) or 0;
	local e2 = GetCombatRating(CR_HASTE_MELEE) or 0;
	local e3 = GetCombatRating(CR_MASTERY) or 0;
	local e4 = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0;
	self:CalculateBestSum(e1, e2, e3, e4);
	if useAnimation then
		self:AnimateValue(e1, e2, e3, e4);
	else
		if self.UpdateFrame then
			self.UpdateFrame:Hide();
		end
		self:SetValue(e1, e2, e3, e4);
	end
end

function NarciRadarChartMixin:UpdateAttributeFrames()
	self.Crit:Update();
	self.Haste:Update();
	self.Mastery:Update();
	self.Versatility:Update();
	if self.Primary:IsShown() then
		self.Primary:Update();
		self.Health:Update();
	end
end

do	--Timerunning
	local EquipmentSlots = {
		1, 3, 5, 6, 7, 8, 9, 10, 15,
	};

	function NarciRadarChartMixin:UpdateStatsGetter()
		local seasonID = NarciAPI.GetTimeRunningSeason();
		if seasonID == 2 then
			self.itemStatsGetter = NarciAPI.GetTimerunningItemStats;
			if self.itemStatsGetter then
				self.UpdateChart = self.UpdateChart_LegionRemix;
				self.bestSum = (#EquipmentSlots * 2) * 1.1;

				local function customValueSetter(f, leftText, rightText)
					if self.statRatings then
						rightText:SetText(self.statRatings[f.token]);
					end
				end

				self.Crit.customValueSetter = customValueSetter;
				self.Haste.customValueSetter = customValueSetter;
				self.Mastery.customValueSetter = customValueSetter;
				self.Versatility.customValueSetter = customValueSetter;
			end
		end
	end

	local GetInventoryItemLink = GetInventoryItemLink;

	function NarciRadarChartMixin:UpdateChart_LegionRemix(useAnimation)
		local itemlink;
		local stats = {
			Crit = 0,
			Haste = 0,
			Mastery = 0,
			Versatility = 0,
		};

		for _, slotID in ipairs(EquipmentSlots) do
			itemlink = GetInventoryItemLink("player", slotID);
			if itemlink then
				local tbl = self.itemStatsGetter(itemlink);
				if tbl then
					for k, v in pairs(stats) do
						if tbl[k] then
							stats[k] = stats[k] + tbl[k];
						end
					end
				end
			end
		end

		self.statRatings = stats;
		self:UpdateAttributeFrames();

		local e1, e2, e3, e4 = stats.Crit, stats.Haste, stats.Mastery, stats.Versatility;
		if useAnimation then
			self:AnimateValue(e1, e2, e3, e4);
		else
			if self.UpdateFrame then
				self.UpdateFrame:Hide();
			end
			self:SetValue(e1, e2, e3, e4);
		end
	end
end