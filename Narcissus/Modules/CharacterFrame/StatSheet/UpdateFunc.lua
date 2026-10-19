local _, addon = ...

local Narci = Narci;
local L = Narci.L;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local StatSheetAPI = addon.StatSheetAPI; ---@type StatSheetAPI

local C_PaperDollInfo = C_PaperDollInfo;
local format = string.format;
local FormatPercent = StatSheetAPI.FormatPercent;
local UnitStat = UnitStat;
local GetCombatRating = GetCombatRating;
local GetCombatRatingBonus = GetCombatRatingBonus;
local GetUnitSpeed = GetUnitSpeed;
local canaccessvalue = canaccessvalue;

local N_SLASH_A = NOT_APPLICABLE;

---------------------------------------------------------------
----Stat Display code is derivated from PapaerDollFrame.lua----
---------------------------------------------------------------

---@class StatUpdateFunc
local UpdateFunc = {};
addon.StatUpdateFunc = UpdateFunc;


local function ShouldMakeValueGrey(value)
	return canaccessvalue(value) and ( not(value) or (value <= 0));
end

---Set up a StatButton
---@param self any StatButton
---@param statIndex number The stat you want to display
local function SetupPrimaryStat(self, statIndex)
	local unit = "player";
	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
	local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);
	self:SetLabelAndValue(statName, effectiveStatDisplay);
end

function UpdateFunc:Primary()
	local statIndex = StatSheetAPI.GetPrimaryStatIndex();
	if statIndex then
		SetupPrimaryStat(self, statIndex);
	else
		self:SetLabelAndValue(L["Primary Stat"], N_SLASH_A, true);
	end
end

function UpdateFunc:Strength()
	SetupPrimaryStat(self, StatSheetAPI.PrimaryStatIndex.Strength);
end

function UpdateFunc:Agility()
	SetupPrimaryStat(self, StatSheetAPI.PrimaryStatIndex.Agility);
end

function UpdateFunc:Intellect()
	SetupPrimaryStat(self, StatSheetAPI.PrimaryStatIndex.Intellect);
end

function UpdateFunc:Stamina()
	SetupPrimaryStat(self, StatSheetAPI.PrimaryStatIndex.Stamina);
end

function UpdateFunc:Spirit()
	SetupPrimaryStat(self, StatSheetAPI.PrimaryStatIndex.Spirit);
end

function UpdateFunc:Damage()
	self:SetLabelAndValue(DAMAGE, StatSheetAPI.GetDisplayedDamage());
end

function UpdateFunc:AttackSpeed()
	local attackSpeedText = StatSheetAPI.GetDisplayedAttackSpeed(true);
	self:SetLabelAndValue(ATTACK_SPEED, attackSpeedText);
end

function UpdateFunc:Armor()
	local _, effectiveArmor = UnitArmor("player");
	self:SetLabelAndValue(STAT_ARMOR, effectiveArmor);
end

function UpdateFunc:Reduction()
	local armorReduction, armorReductionAgainstTarget, effectiveArmor = StatSheetAPI.GetArmorReduction();
	if effectiveArmor then
		self:SetLabelAndValue(L["Damage Reduction Percentage"], FormatPercent(armorReduction));
	else
		self:SetLabelAndValue(L["Damage Reduction Percentage"], N_SLASH_A, true);
	end
end

function UpdateFunc:Dodge()
	local chance = GetDodgeChance();
	self:SetLabelAndValue(STAT_DODGE, FormatPercent(chance));
end

function UpdateFunc:Parry()
	local chance = GetParryChance();
	self:SetLabelAndValue(STAT_PARRY, FormatPercent(chance));
end

function UpdateFunc:Block()
	if C_PaperDollInfo.OffhandHasShield() then
		local chance = GetBlockChance();
		self:SetLabelAndValue(STAT_BLOCK, FormatPercent(chance));
	else
		self:SetLabelAndValue(STAT_BLOCK, N_SLASH_A, true);
	end
end

function UpdateFunc:Health()
	local health = UnitHealthMax("player");
	local healthText = BreakUpLargeNumbers(health);
	self:SetLabelAndValue(HEALTH, healthText);
end

function UpdateFunc:Power()
	local powerName, displayedValue = StatSheetAPI.GetDisplayedPower();
	if powerName then
		self:SetLabelAndValue(powerName, displayedValue);
	else
		self:SetLabelAndValue(L["Combat Resources"], N_SLASH_A, true);
	end
end

function UpdateFunc:Regen()
	local regenName, regenRateText = StatSheetAPI.GetDisplayedComatRegen();
	if regenName then
		self:SetLabelAndValue(regenName, regenRateText);
	else
		self:SetLabelAndValue(MANA_REGEN_COMBAT, N_SLASH_A, true);
	end
end

function UpdateFunc:Crit()
	local critChance, ratingIndex = StatSheetAPI.GetEffectiveCrit();
	local extraCritRating = GetCombatRating(ratingIndex);

	self:SetLabelAndValue(L["Stat Crit"], FormatPercent(critChance)); --COMBAT_RATING_NAME10
	self:SetValueRating(extraCritRating);
end

function UpdateFunc:Haste()
	local haste = GetHaste();

	self:SetLabelAndValue(STAT_HASTE, FormatPercent(haste));
	self:SetValueRating(GetCombatRating(CR_HASTE_MELEE));
end

function UpdateFunc:Mastery()
	local mastery = GetMasteryEffect();
	self:SetLabelAndValue(STAT_MASTERY, FormatPercent(mastery));
	self:SetValueRating(GetCombatRating(CR_MASTERY));
end

function UpdateFunc:Versatility()
	local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
	local attackBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
	local versaBonusAttack = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);

	local displayedValue;
	if canaccessallvalues(attackBonus, versaBonusAttack) then
		displayedValue = attackBonus + versaBonusAttack;
	else
		displayedValue = attackBonus;
	end

	self:SetLabelAndValue(STAT_VERSATILITY, FormatPercent(displayedValue));
	self:SetValueRating(versatility);
end

---Certain values grey out if zero
local function IsValueZero(value)
	return canaccessvalue(value) and value == 0;
end

function UpdateFunc:Leech()
	local lifesteal = GetLifesteal();
	self:SetLabelAndValue(STAT_LIFESTEAL, FormatPercent(lifesteal), IsValueZero(lifesteal));
end

function UpdateFunc:Avoidance()
	local avoidance = GetAvoidance();
	self:SetLabelAndValue(STAT_AVOIDANCE, FormatPercent(avoidance), IsValueZero(avoidance));
end

function UpdateFunc:Speed()
	local speed = GetSpeed();
	self:SetLabelAndValue(STAT_SPEED, FormatPercent(speed), IsValueZero(speed));
end

local function MovementSpeed_OnEnter(self)
	local tooltip = NarciGameTooltip;

	if not (canaccessvalue(self.speed) and self.speed) then
		return;
	end

	tooltip:SetOwner(self, "ANCHOR_NONE");
	tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -4, 0)

	tooltip:SetText(format("%s %d%%", STAT_MOVEMENT_SPEED, self.speed + 0.5), 1, 1, 1);
	tooltip:AddNormalLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, self.runSpeed + 0.5));
	tooltip:AddNormalLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, self.flightSpeed + 0.5));
	tooltip:AddNormalLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, self.swimSpeed + 0.5));
	tooltip:AddBlankLine();
	tooltip:AddNormalLine(format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED)));

	tooltip:Show();
end

local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7;

local function MovementSpeed_OnUpdate(self, elapsed)
	self.t = self.t + elapsed;
	if self.t > 0.2 then
		self.t = 0;
	else
		return;
	end

	local unit = "player";
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit);

	if not canaccessvalue(runSpeed) then
		self.Value:SetText(N_SLASH_A);
		self.speed = nil;
		return;
	end

	runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100;
	flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100;
	swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100;

	-- Determine whether to display running, flying, or swimming speed
	local speed = runSpeed;
	local swimming = IsSwimming(unit);
	if swimming then
		speed = swimSpeed;
	elseif IsFlying(unit) then
		speed = flightSpeed;
	end

	-- Hack so that your speed doesn't appear to change when jumping out of the water
	if IsFalling(unit) then
		if self.wasSwimming then
			speed = swimSpeed;
		end
	else
		self.wasSwimming = swimming;
	end

	local valueText = format("%d%%", speed + 0.5);
	self.Value:SetText(valueText);

	self.speed = speed;
	self.runSpeed = runSpeed;
	self.flightSpeed = flightSpeed;
	self.swimSpeed = swimSpeed;

	if self:IsMouseMotionFocus() then
		MovementSpeed_OnEnter(self);
	end
end

function UpdateFunc:MovementSpeed()
	self.wasSwimming = nil;
	self.t = 0;
	self.Label:SetText(L["Movement Speed"]);		--STAT_MOVEMENT_SPEED
	MovementSpeed_OnUpdate(self, 1);
	self:SetScript("OnEnter", MovementSpeed_OnEnter);
	self:SetScript("OnUpdate", MovementSpeed_OnUpdate);
end


---- The following are for Forever ----

function UpdateFunc:Defense()
	local effectiveDefenseSkill, baseDefenseSkill, defenseModifier, maxDefense = StatSheetAPI.GetEffectiveDefenseSkill();
	if effectiveDefenseSkill then
		self:SetLabelAndValue(DEFENSE, string.format("%s / %s", effectiveDefenseSkill, maxDefense));
	else
		self:SetLabelAndValue(DEFENSE, N_SLASH_A, true);
	end
end

function UpdateFunc:MeleeDamage()
	self:SetLabelAndValue(DAMAGE, StatSheetAPI.GetDisplayedDamage(false));
end

function UpdateFunc:RangedDamage()
	self:SetLabelAndValue(DAMAGE, StatSheetAPI.GetDisplayedDamage(true));
end

UpdateFunc.MeleeAttackSpeed = UpdateFunc.AttackSpeed;

function UpdateFunc:RangedAttackSpeed()
	local formattedText = StatSheetAPI.GetDisplayedRangedAttackSpeed();
	if formattedText then
		self:SetLabelAndValue(ATTACK_SPEED, formattedText);
	else
		self:SetLabelAndValue(ATTACK_SPEED, N_SLASH_A, true);
	end
end

local function SetupAttackPower(self, getterFunc)
	local base, posBuff, negBuff = getterFunc("player");
	local valueText;
	if issecretvalue(base) then
		valueText = format("%s +%.0f |cffff2020%s.0f|r", base, posBuff, negBuff);
	else
		valueText = format("%.0f", base + posBuff + negBuff);
	end
	self:SetLabelAndValue(STAT_ATTACK_POWER, valueText);
end

function UpdateFunc:MeleeAttackPower()
	SetupAttackPower(self, UnitAttackPower);
end

function UpdateFunc:RangedAttackPower()
	SetupAttackPower(self, UnitRangedAttackPower);
end

function UpdateFunc:MeleeExpertise()
	local expertise, offhandExpertise, rangedExpertise = GetExpertise();
	local grey = ShouldMakeValueGrey(expertise);
	local valueText;

	if canaccessallvalues(expertise and offhandExpertise) then
		local _, offhandSpeed = UnitAttackSpeed("player");
		if offhandSpeed and offhandExpertise > 0 then
			valueText = format("%s / %s", FormatPercent(expertise),  FormatPercent(offhandExpertise));
		else
			valueText = FormatPercent(expertise);
		end
	else
		valueText = FormatPercent(expertise);
	end

	self:SetLabelAndValue(STAT_EXPERTISE, valueText, grey);
end

function UpdateFunc:RangedExpertise()
	local _, _, rangedExpertise = GetExpertise();
	local grey = ShouldMakeValueGrey(rangedExpertise);
	local valueText = format("%.2f%%", rangedExpertise);
	self:SetLabelAndValue(STAT_EXPERTISE, valueText, grey);
end

function UpdateFunc:ArmorPenetration()
	local armorPenetration = GetArmorPenetration();
	self:SetLabelAndValue(STAT_ARMOR_PENETRATION, format("%d", armorPenetration), ShouldMakeValueGrey(armorPenetration));
end

local function SetupHitChance(self, attackType)
	local hitChance1, hitChance2 = StatSheetAPI.GetDisplayedHitChance(attackType);
	if hitChance1 then
		if hitChance2 then
			self:SetLabelAndValue(STAT_HIT_CHANCE, format("%s / %s",  FormatPercent(hitChance1),  FormatPercent(hitChance2)), ShouldMakeValueGrey(hitChance1));
		else
			self:SetLabelAndValue(STAT_HIT_CHANCE,  FormatPercent(hitChance1), ShouldMakeValueGrey(hitChance1));
		end
	else
		self:SetLabelAndValue(STAT_HIT_CHANCE, N_SLASH_A, true);
	end
end

function UpdateFunc:HitChance()
	SetupHitChance(self, nil);
end

function UpdateFunc:MeleeHitChance()
	SetupHitChance(self, nil);
end

function UpdateFunc:RangedHitChance()
	SetupHitChance(self, nil);
end

function UpdateFunc:SpellHitChance()
	SetupHitChance(self, nil);
end

local function SetupCritChance(self, attackType)
	local critChance = StatSheetAPI.GetCritByAttackType(attackType);
	self:SetLabelAndValue(L["Stat Crit"], FormatPercent(critChance));
end

function UpdateFunc:MeleeCrit()
	SetupCritChance(self, 1);
end

function UpdateFunc:RangedCrit()
	SetupCritChance(self, 2);
end

function UpdateFunc:SpellCrit()
	SetupCritChance(self, 3);
end
