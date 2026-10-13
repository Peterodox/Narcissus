local _, addon = ...

local Narci = Narci;
local L = Narci.L;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local StatSheetAPI = addon.StatSheetAPI; ---@type StatSheetAPI

local format = string.format;
local floor = math.floor;
local ceil = math.ceil;
local max = math.max;

local DefaultTooltip = NarciGameTooltip;	--Created in NarciAPI.lua

local C_PaperDollInfo = C_PaperDollInfo;
local UnitStat = UnitStat;
local GetCombatRating = GetCombatRating;
local GetCombatRatingBonus = GetCombatRatingBonus;
local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7;
local GetUnitSpeed = GetUnitSpeed;
local canaccessvalue = canaccessvalue;

local N_SLASH_A = NOT_APPLICABLE;

local DIGITS = "%.2f";

local FormatPercent = StatSheetAPI.FormatPercent;


------------------------------------------------------------------
----The following codes are derivated from PapaerDollFrame.lua----
------------------------------------------------------------------

---@class StatUpdateFunc
local UpdateFunc = {};
addon.StatUpdateFunc = UpdateFunc;


---@param self any StatButton
local function ClearTooltipIfSecret(self, statName, value1)
	if not canaccessvalue(value1) then
		self.tooltip = statName;
		self.tooltip2 = nil;
		return true;
	end
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

local function GetAppropriateDamage(unit)
	if IsRangedWeapon() then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	else
		return UnitDamage(unit);
	end
end

local function CharacterDamageFrame_OnEnter(self)
	-- Main hand weapon
	DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
	if self.unit == "pet" then
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND_PET, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	else
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format(DIGITS, self.attackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.damage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	-- Check for offhand weapon
	if self.offhandAttackSpeed then
		DefaultTooltip:AddLine("\n");
		DefaultTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format(DIGITS, self.offhandAttackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), self.offhandDamage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	end

	DefaultTooltip:SetPoint("TOPRIGHT",self,"TOPLEFT", -4, 0);
	DefaultTooltip:Show();
end

function UpdateFunc:Damage()
	local unit = "player";

	local speed, offhandSpeed = UnitAttackSpeed(unit);
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage(unit);

	if ClearTooltipIfSecret(self, DAMAGE, minDamage) then
		self:SetLabelAndValue(DAMAGE, format("%.0f", minDamage));
		self:SetScript("OnEnter", nil);
		return;
	end

	-- remove decimal points for display values
	local displayMin = max(floor(minDamage),1);
	local displayMinLarge = displayMin; --BreakUpLargeNumbers(displayMin)
	local displayMax = max(ceil(maxDamage),1);
	local displayMaxLarge = displayMax; --BreakUpLargeNumbers(displayMax)

	-- calculate base damage
	if percent == 0 then return; end;
	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	-- set tooltip text with base damage
	local damageTooltip = BreakUpLargeNumbers(max(floor(minDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxDamage),1));

	local colorPos = "|cffffffff";
	local colorNeg = "|cffffffff";

	-- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
	end

	local value;
	if totalBonus == 0  then
		if displayMin < 100 and displayMax < 100 then
			value = displayMinLarge.." - "..displayMaxLarge;
		else
			value = displayMinLarge.." - "..displayMaxLarge;
		end
	else
		-- set bonus color and display
		local color;
		if totalBonus > 0  then
			color = colorPos;
		else
			color = colorNeg;
		end
		if displayMin < 100 and displayMax < 100 then
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		else
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		end
		if physicalBonusPos > 0 then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if physicalBonusNeg < 0 then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if percent > 1 then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent * 100 + 0.5).."%|r";
		elseif percent < 1 then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent * 100 + 0.5).."%|r";
		end

	end

	self:SetLabelAndValue(DAMAGE, value);
	self.damage = damageTooltip;
	self.attackSpeed = speed;
	self.unit = unit;

	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and minOffHandDamage and maxOffHandDamage ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		--local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent; -- We don't have space to show offhand damage :(
		local offhandDamageTooltip = BreakUpLargeNumbers(max(floor(minOffHandDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxOffHandDamage),1));
		if physicalBonusPos > 0 then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if physicalBonusNeg < 0 then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if percent > 1 then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent * 100 + 0.5).."%|r";
		elseif percent < 1 then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent * 100 + 0.5).."%|r";
		end
		self.offhandDamage = offhandDamageTooltip;
		self.offhandAttackSpeed = offhandSpeed;
	else
		self.offhandAttackSpeed = nil;
	end

	self:SetScript("OnEnter", CharacterDamageFrame_OnEnter);
end

function UpdateFunc:AttackSpeed()
	local meleeHaste = GetMeleeHaste();
	local speed, offhandSpeed = UnitAttackSpeed("player");

	if ClearTooltipIfSecret(self, ATTACK_SPEED, speed) then
		self:SetLabelAndValue(ATTACK_SPEED, format(DIGITS, speed));
		return;
	end

	local displaySpeed = floor(100 * speed + 0.5) / 100;
	if offhandSpeed then
		offhandSpeed = floor(100 * offhandSpeed + 0.5) / 100;
	end
	if offhandSpeed then
		if displaySpeed ~= offhandSpeed then
			displaySpeed =  displaySpeed.." / ".. offhandSpeed;
		else
			displaySpeed =  displaySpeed;
		end
	else
		displaySpeed =  displaySpeed;
	end

	self:SetLabelAndValue(ATTACK_SPEED, displaySpeed);
	self.tooltip = "|cffffffff".. ATTACK_SPEED .." "..displaySpeed.."|r";
	self.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, format(DIGITS, meleeHaste));
end

local function ArmorOrReduction_OnEnter(self)
	local _, effectiveArmor = UnitArmor("player");
	local armorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(effectiveArmor);
	if canaccessvalue(armorReductionAgainstTarget) and armorReductionAgainstTarget then
		self.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, 100 * armorReductionAgainstTarget);
	else
		self.tooltip3 = nil;
	end
	self:ShowTooltip();
end

function UpdateFunc:Armor()
	local unit = "player";

	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);
	self:SetLabelAndValue(STAT_ARMOR, effectiveArmor);

	if ClearTooltipIfSecret(self, STAT_ARMOR, effectiveArmor) then
		return;
	end

    local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit));

	self.tooltip = "|cffffffff".. ARMOR .." "..BreakUpLargeNumbers(effectiveArmor).."|r";
	self.tooltip2 = format(STAT_ARMOR_TOOLTIP, 100 * armorReduction);

	self:SetScript("OnEnter", ArmorOrReduction_OnEnter);
end

function UpdateFunc:Reduction()
	local unit = "player"
	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);

	if ClearTooltipIfSecret(self, COMBAT_TEXT_SHOW_RESISTANCES_TEXT, effectiveArmor) then
		self:SetLabelAndValue(L["Damage Reduction Percentage"], N_SLASH_A, true);
		return;
	end

	local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit)) or 0;
	armorReduction = 100 * armorReduction;

	local armorReductionText = FormatPercent(armorReduction);
	self:SetLabelAndValue(L["Damage Reduction Percentage"], armorReductionText);

	self.tooltip = "|cffffffff"..COMBAT_TEXT_SHOW_RESISTANCES_TEXT.." "..armorReductionText.."|r";
	self.tooltip2 = format(STAT_ARMOR_TOOLTIP, armorReduction);

	self:SetScript("OnEnter", ArmorOrReduction_OnEnter);
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
	local unit = "player";

	local chance = GetBlockChance();
	local chanceText = FormatPercent(chance);

	if ClearTooltipIfSecret(self, STAT_BLOCK, chance) then
		self:SetLabelAndValue(STAT_BLOCK, chanceText);
		return;
	end

	if chance ~= 0 and C_PaperDollInfo.OffhandHasShield() then
		self:SetLabelAndValue(STAT_BLOCK, chanceText);
	else
		self:SetLabelAndValue(STAT_BLOCK, N_SLASH_A, true);
	end

	self.tooltip = "|cffffffff".. BLOCK_CHANCE .." "..FormatPercent(chance).."|r";

	local shieldBlockArmor = GetShieldBlock();
	local blockArmorReduction = C_PaperDollInfo.GetArmorEffectiveness(shieldBlockArmor, UnitEffectiveLevel(unit));
	local blockArmorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(shieldBlockArmor);

	self.tooltip2 = format(CR_BLOCK_TOOLTIP, blockArmorReduction * 100);
	if (blockArmorReductionAgainstTarget) then
		self.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget * 100);
	else
		self.tooltip3 = nil;
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

	self:SetLabelAndValue(NARCI_CRITICAL_STRIKE, FormatPercent(critChance)); --COMBAT_RATING_NAME10
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

function UpdateFunc:Leech()
	local lifesteal = GetLifesteal();
	self:SetLabelAndValue(STAT_LIFESTEAL, FormatPercent(lifesteal), canaccessvalue(lifesteal) and lifesteal == 0);
end

function UpdateFunc:Avoidance()
	local avoidance = GetAvoidance();
	self:SetLabelAndValue(STAT_AVOIDANCE, FormatPercent(avoidance), canaccessvalue(avoidance) and avoidance == 0);
end

function UpdateFunc:Speed()
	local speed = GetSpeed();
	self:SetLabelAndValue(STAT_SPEED, FormatPercent(speed), canaccessvalue(speed) and speed == 0);
end

local function MovementSpeed_OnEnter(self)
	local tooltip = NarciGameTooltip;

	if not (canaccessvalue(self.speed) and self.speed) then
		tooltip:SetOwner(self, "ANCHOR_NONE");
		tooltip:SetText(format(STAT_MOVEMENT_SPEED));
		tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -4, 0)
		tooltip:Show();
		return;
	end

	tooltip:SetOwner(self, "ANCHOR_NONE");
	tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -4, 0)
	tooltip:SetText("|cffffffff".. STAT_MOVEMENT_SPEED .." "..format("%d%%", self.speed+0.5).."|r");

	tooltip:AddNormalLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, self.runSpeed + 0.5));
	tooltip:AddNormalLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, self.flightSpeed + 0.5));
	tooltip:AddNormalLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, self.swimSpeed + 0.5));
	tooltip:AddBlankLine();
	tooltip:AddNormalLine(format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED)));

	tooltip:Show();
end

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
