local DIGITS = "%.2f";
local NO_BONUS_ALPHA = 0.5;

local Narci = Narci;
local L = Narci.L;
local FormatLargeNumbers = NarciAPI.FormatLargeNumbers;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local GetPrimaryStats = NarciAPI.GetPrimaryStats;
local SplitTooltipByLineBreak = NarciAPI.SplitTooltipByLineBreak;
local format = string.format;
local floor = math.floor;
local ceil = math.ceil;
local max = math.max;
local min = math.min;

local DefaultTooltip = NarciGameTooltip;	--Created in NarciAPI.lua

local C_PaperDollInfo = C_PaperDollInfo;
local UnitStat = UnitStat;
local GetCombatRating = GetCombatRating;
local GetCombatRatingBonus = GetCombatRatingBonus;
local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED;
local GetSpecialization = GetSpecialization;
local GetUnitSpeed = GetUnitSpeed;


local NARCI_CRIT_TOOLTIP, NARCI_CRIT_TOOLTIP_FORMAT = SplitTooltipByLineBreak(CR_CRIT_TOOLTIP);
local _, NARCI_HASTE_TOOLTIP_FORMAT = SplitTooltipByLineBreak(STAT_HASTE_BASE_TOOLTIP);
local NARCI_VERSATILITY_TOOLTIP_FORMAT_1, NARCI_VERSATILITY_TOOLTIP_FORMAT_2 = SplitTooltipByLineBreak(CR_VERSATILITY_TOOLTIP);


local function GetPrimaryStatsNum()
	local _, strength = UnitStat("player", 1);
	local _, agility = UnitStat("player", 2);
	local _, intellect = UnitStat("player", 4);
	if strength > agility and strength > intellect then
		return strength;
	elseif	agility > strength and agility > intellect then
		return agility;
	elseif	intellect > agility and	intellect >	strength then
		return intellect;
	end
end

local function GetAppropriateDamage(unit)
	if IsRangedWeapon() then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	else
		return UnitDamage(unit);
	end
end

local function CharacterDamageFrame_OnEnter(object)
	-- Main hand weapon
	DefaultTooltip:SetOwner(object, "ANCHOR_NONE");
	if ( object.unit == "pet" ) then
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND_PET, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	else
		DefaultTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2F", object.attackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), object.damage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	-- Check for offhand weapon
	if ( object.offhandAttackSpeed ) then
		DefaultTooltip:AddLine("\n");
		DefaultTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2F", object.offhandAttackSpeed), 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		DefaultTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), object.offhandDamage, 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
	end

	DefaultTooltip:SetPoint("TOPRIGHT",object,"TOPLEFT", -4, 0);
	DefaultTooltip:Show();
end

local function MovementSpeed_OnUpdate(object, elapsed)
	object.t = object.t + elapsed;
	if object.t > 0.1 then
		object.t = 0;
	else
		return
	end

	local unit = object.unit;
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit);
	runSpeed = runSpeed/BASE_MOVEMENT_SPEED*100;
	flightSpeed = flightSpeed/BASE_MOVEMENT_SPEED*100;
	swimSpeed = swimSpeed/BASE_MOVEMENT_SPEED*100;

	-- Determine whether to display running, flying, or swimming speed
	local speed = runSpeed;
	local swimming = IsSwimming(unit);
	if (swimming) then
		speed = swimSpeed;
	elseif (IsFlying(unit)) then
		speed = flightSpeed;
	end

	-- Hack so that your speed doesn't appear to change when jumping out of the water
	if (IsFalling(unit)) then
		if (object.wasSwimming) then
			speed = swimSpeed;
		end
	else
		object.wasSwimming = swimming;
	end

	local valueText = format("%d%%", speed+0.5);

	object.Label:SetText(L["Movement Speed"]);		--STAT_MOVEMENT_SPEED
	object.Value:SetText(valueText);

	object.speed = speed;
	object.runSpeed = runSpeed;
	object.flightSpeed = flightSpeed;
	object.swimSpeed = swimSpeed;
end

local function MovementSpeed_OnEnter(object)
	DefaultTooltip:SetOwner(object, "ANCHOR_NONE");
	DefaultTooltip:SetText("|cffffffff".. STAT_MOVEMENT_SPEED .." "..format("%d%%", object.speed+0.5).."|r");

	DefaultTooltip:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, object.runSpeed+0.5));
	if (object.unit ~= "pet") then
		DefaultTooltip:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, object.flightSpeed+0.5));
	end
	DefaultTooltip:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, object.swimSpeed+0.5));
	DefaultTooltip:AddLine(" ");
	DefaultTooltip:AddLine(format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED)));

	DefaultTooltip:SetPoint("TOPRIGHT",object,"TOPLEFT", -4, 0)
	DefaultTooltip:Show();

	object.UpdateTooltip = MovementSpeed_OnEnter;
end

local function MasteryFrame_OnEnter(object)
    local RadarChart = object:GetParent();
    if RadarChart.SetVerticeSize then
        RadarChart.SetVerticeSize(RadarChart, object, 15);
    end

	DefaultTooltip:SetOwner(object, "ANCHOR_NONE");

	local mastery, bonusCoeff = GetMasteryEffect();
	local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;

	local title = "|cffffffff"..STAT_MASTERY.." "..format("%.2F%%", mastery).."|r";
	if (masteryBonus > 0) then
		title = title.."|cffffffff".." ("..format("%.2F%%", mastery-masteryBonus).."|r"..GREEN_FONT_COLOR_CODE.."+"..format("%.2F%%", masteryBonus).."|r".."|cffffffff"..")".."|r";
	end
	DefaultTooltip:SetText(title);

	local masteryRating = GetCombatRating(CR_MASTERY);
	local primaryTalentTree = GetSpecialization();
	if (primaryTalentTree) then	--dragonflight
		local masterySpell, masterySpell2 = GetSpecializationMasterySpells(primaryTalentTree);
		if DefaultTooltip.AddSpellByID then
			if (masterySpell) then
				DefaultTooltip:AddSpellByID(masterySpell);
			end
			if (masterySpell2) then
				DefaultTooltip:AddLine(" ");
				DefaultTooltip:AddSpellByID(masterySpell2);
			end
		else
			if (masterySpell) then
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell);
				tooltipInfo.append = true;
				DefaultTooltip:ProcessInfo(tooltipInfo);
			end
			if (masterySpell2) then
				DefaultTooltip:AddLine(" ");
				local tooltipInfo = CreateBaseTooltipInfo("GetSpellByID", masterySpell2);
				tooltipInfo.append = true;
				DefaultTooltip:ProcessInfo(tooltipInfo);
			end
		end
		DefaultTooltip:AddLine(" ");
		local tooltip = format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus);
		if masteryBonus ~= 0 then
			DefaultTooltip:AddDoubleLine(tooltip ,floor( (masteryRating / masteryBonus) * 100 + 0.5) / 100 .. " [+1%]", 1.00, 0.82, 0.00, 1.00, 0.82, 0.00);
		else
			DefaultTooltip:AddLine(tooltip, 1.00, 0.82, 0.00, true);
		end
	else
		DefaultTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(masteryRating), masteryBonus), 1.00, 0.82, 0.00, true);
		DefaultTooltip:AddLine(" ");
		DefaultTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true);
	end
	DefaultTooltip:SetPoint("TOPRIGHT",object,"TOPLEFT", -4, 0)
	DefaultTooltip:Show();
end

local function GetEffectiveCrit()
	local rating;
	local spellCrit, rangedCrit, meleeCrit;
	local critChance;
	
	-- Start at 2 to skip physical damage
	local holySchool = 2;
	local minCrit = GetSpellCritChance(holySchool);
	local spellCritTable = {};
	spellCritTable[holySchool] = minCrit;
	local spellCrit;
	for i = (holySchool+1), MAX_SPELL_SCHOOLS do
		spellCrit = GetSpellCritChance(i);
		minCrit = min(minCrit, spellCrit);
		spellCritTable[i] = spellCrit;
	end
	spellCrit = minCrit
	rangedCrit = GetRangedCritChance();
	meleeCrit = GetCritChance();

	if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
		critChance = spellCrit;
		rating = CR_CRIT_SPELL;
	elseif (rangedCrit >= meleeCrit) then
		critChance = rangedCrit;
		rating = CR_CRIT_RANGED;
	else
		critChance = meleeCrit;
		rating = CR_CRIT_MELEE;
	end

	return critChance, rating
end

Narci.GetEffectiveCrit = GetEffectiveCrit;

------------------------------------------------------------------
----The following codes are derivated from PapaerDollFrame.lua----
------------------------------------------------------------------
local UpdateFunc = {};

function UpdateFunc:Primary(object)
	local unit = "player";
	local PrimaryStatsName, PrimaryStatsNum = GetPrimaryStats();
	object.Label:SetText(PrimaryStatsName)
	object.Value:SetText(PrimaryStatsNum)
	local spec = GetSpecialization();
	if not spec then return; end
	local role = GetSpecializationRole(spec);
	local _, _, _, _, _, primaryStat = GetSpecializationInfo(spec);
	if type(tonumber(primaryStat)) ~= "number" then return; end		--sometimes changing zones cause Lua error
	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, primaryStat);
	local effectiveStatDisplay = FormatLargeNumbers(effectiveStat);

	-- Set the tooltip text
	local statName = _G["SPELL_STAT"..primaryStat.."_NAME"];
	local tooltipText = "|cffffffff".. statName .." ";

	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		object.tooltip = tooltipText..effectiveStatDisplay.."|r";
	else
		tooltipText = tooltipText..effectiveStatDisplay;
		if ( posBuff > 0 or negBuff < 0 ) then
			tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff).."|r";
		end
		if ( posBuff > 0 ) then
			tooltipText = tooltipText.."|r"..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff).."|r";
		end
		if ( negBuff < 0 ) then
			tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff).."|r";
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			tooltipText = tooltipText.."|cffffffff"..")".."|r";
		end
		object.tooltip = tooltipText;

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if ( negBuff < 0 and not GetPVPGearStatRules() ) then
			effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay.."|r";
		end
	end

	object.tooltip2 = _G["DEFAULT_STAT"..primaryStat.."_TOOLTIP"];

	if ( primaryStat == LE_UNIT_STAT_AGILITY ) then
		local attackPower = GetAttackPowerForStat(primaryStat, effectiveStat);
		local tooltip = STAT_TOOLTIP_BONUS_AP;
		if (HasAPEffectsSpellPower()) then
			tooltip = STAT_TOOLTIP_BONUS_AP_SP;
		end
		if (not primaryStat or primaryStat == LE_UNIT_STAT_AGILITY) then
			object.tooltip2 = format(tooltip, BreakUpLargeNumbers(attackPower));
			if ( role == "TANK" ) then
				local increasedDodgeChance = GetDodgeChanceFromAttribute();
				if ( increasedDodgeChance > 0 ) then
					object.tooltip2 = object.tooltip2.."|n|n"..format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance);
				end
			end
		else
			object.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end

	elseif ( primaryStat == LE_UNIT_STAT_STRENGTH ) then
		local attackPower = GetAttackPowerForStat(primaryStat,effectiveStat);
		if (HasAPEffectsSpellPower()) then
			object.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP;
		end
		if (not primaryStat or primaryStat == LE_UNIT_STAT_STRENGTH) then
			object.tooltip2 = format(object.tooltip2, BreakUpLargeNumbers(attackPower));
			if ( role == "TANK" ) then
				local increasedParryChance = GetParryChanceFromAttribute();
				if ( increasedParryChance > 0 ) then
					object.tooltip2 = object.tooltip2.."|n|n"..format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance);
				end
			end
		else
			object.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end

	elseif ( primaryStat == LE_UNIT_STAT_INTELLECT ) then
		if ( UnitHasMana("player") ) then
			if (HasAPEffectsSpellPower()) then
				object.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
			else
				local result, druid = HasSPEffectsAttackPower();
				if (result and druid) then
					object.tooltip2 = format(STAT_TOOLTIP_SP_AP_DRUID, max(0, effectiveStat), max(0, effectiveStat));
				elseif (result) then
					object.tooltip2 = format(STAT_TOOLTIP_BONUS_AP_SP, max(0, effectiveStat));
				elseif (not primaryStat or primaryStat == LE_UNIT_STAT_INTELLECT) then
					object.tooltip2 = format(object.tooltip2, max(0, effectiveStat));
				else
					object.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
				end
			end
		else
			object.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
		end
	end
end

function UpdateFunc:Stamina(object)
	local statIndex = LE_UNIT_STAT_STAMINA;
	local stat, effectiveStat, posBuff, negBuff = UnitStat("player", statIndex);

	local effectiveStatDisplay = FormatLargeNumbers(effectiveStat);
	-- Set the tooltip text
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
	local tooltipText = "|cffffffff".. statName .." ";

	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		object.tooltip = tooltipText..effectiveStatDisplay.."|r";
	else
		tooltipText = tooltipText..effectiveStatDisplay;
		if ( posBuff > 0 or negBuff < 0 ) then
			tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff).."|r";
		end
		if ( posBuff > 0 ) then
			tooltipText = tooltipText.."|r"..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff).."|r";
		end
		if ( negBuff < 0 ) then
			tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff).."|r";
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			tooltipText = tooltipText.."|cffffffff"..")".."|r";
		end
		object.tooltip = tooltipText;

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if ( negBuff < 0 and not GetPVPGearStatRules() ) then
			effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay.."|r";
		end
	end

	object.Label:SetText(statName)
	object.Value:SetText(effectiveStat)
	object.tooltip2 = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];
	object.tooltip2 = format(object.tooltip2, BreakUpLargeNumbers(((effectiveStat*UnitHPPerStamina("player")))*GetUnitMaxHealthModifier("player")));

	--object:Show();
end

function UpdateFunc:Damage(object)
	local unit = "player";

	local speed, offhandSpeed = UnitAttackSpeed(unit);
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage(unit);

	-- remove decimal points for display values
	local displayMin = max(floor(minDamage),1);
	local displayMinLarge = displayMin	--BreakUpLargeNumbers(displayMin);
	local displayMax = max(ceil(maxDamage),1);
	local displayMaxLarge = displayMax	--BreakUpLargeNumbers(displayMax);

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
	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			value = displayMinLarge.." - "..displayMaxLarge;
		else
			value = displayMinLarge.." - "..displayMaxLarge;
		end
	else
		-- set bonus color and display
		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		else
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end

	end

	object.Label:SetText(DAMAGE)
	object.Value:SetText(value)
	object.damage = damageTooltip;
	object.attackSpeed = speed;
	object.unit = unit;

	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and minOffHandDamage and maxOffHandDamage ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamageTooltip = BreakUpLargeNumbers(max(floor(minOffHandDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxOffHandDamage),1));
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		object.offhandDamage = offhandDamageTooltip;
		object.offhandAttackSpeed = offhandSpeed;
	else
		object.offhandAttackSpeed = nil;
	end

	object:SetScript("OnEnter", CharacterDamageFrame_OnEnter);
	--object:Show();
end

function UpdateFunc:AttackSpeed(object, unit)
	local unit = "player"

	local meleeHaste = GetMeleeHaste();
	local speed, offhandSpeed = UnitAttackSpeed(unit);

	local displaySpeed = floor(100*speed + 0.5)/100;
	if ( offhandSpeed ) then
		offhandSpeed = floor(100*offhandSpeed + 0.5)/100;
	end
	if ( offhandSpeed ) then
		if displaySpeed ~= offhandSpeed then
			displaySpeed =  displaySpeed.." / ".. offhandSpeed;
		else
			displaySpeed =  displaySpeed;
		end
	else
		displaySpeed =  displaySpeed;
	end

	local speedText = format(DIGITS, meleeHaste).."%"
	object.Label:SetText(ATTACK_SPEED)
	object.Value:SetText(displaySpeed)

	object.tooltip = "|cffffffff".. ATTACK_SPEED .." "..displaySpeed.."|r";
	object.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, format(DIGITS, meleeHaste));

	--object:Show();
end

function UpdateFunc:Armor(object, unit)
	local unit = "player"

	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);
	object.Label:SetText(STAT_ARMOR);
	object.Value:SetText(effectiveArmor);

    local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit));
	local armorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(effectiveArmor);

	object.tooltip = "|cffffffff".. ARMOR .." "..BreakUpLargeNumbers(effectiveArmor).."|r";
	object.tooltip2 = format(STAT_ARMOR_TOOLTIP, 100*armorReduction);
	if (armorReductionAgainstTarget) then
		object.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, 100*armorReductionAgainstTarget);
	else
		object.tooltip3 = nil;
	end
	--object:Show();
end

function UpdateFunc:Reduction(object)
	local unit = "player"
	local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(unit);

	local armorReduction = C_PaperDollInfo.GetArmorEffectiveness(effectiveArmor, UnitEffectiveLevel(unit)) or 0;
	armorReduction = 100 * armorReduction;
	local armorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(effectiveArmor);
	local armorReductionText = format(DIGITS, armorReduction).."%"
	
	object.Label:SetText(L["Damage Reduction Percentage"]);

	object.tooltip = "|cffffffff"..COMBAT_TEXT_SHOW_RESISTANCES_TEXT.." "..armorReductionText.."|r";
	object.tooltip2 = format(STAT_ARMOR_TOOLTIP, armorReduction);
	if (armorReductionAgainstTarget) then
		object.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, 100*armorReductionAgainstTarget);
		armorReduction = 100 * armorReductionAgainstTarget
	else
		object.tooltip3 = nil;
	end

	object.Value:SetText(armorReductionText);
	--object:Show();
end

function UpdateFunc:Dodge(object)
	local chance = GetDodgeChance();
	local chanceText = format("%.2F", chance).."%"
	object.Label:SetText(STAT_DODGE);
	object.Value:SetText(chanceText);

	object.tooltip = "|cffffffff".. DODGE_CHANCE .." "..format("%.2F", chance).."%".."|r";
	object.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
	--object:Show();
end

function UpdateFunc:Parry(object)
	local chance = GetParryChance();
	local chanceText = format("%.2F", chance).."%"
	object.Label:SetText(STAT_PARRY);
	object.Value:SetText(chanceText);		

	object.tooltip = "|cffffffff".. PARRY_CHANCE .." "..format("%.2F", chance).."%".."|r";
	object.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
	--object:Show();
end

function UpdateFunc:Block(object)
	local unit = "player";

	local chance = GetBlockChance();
	local chanceText = format("%.2F", chance).."%";

	local spec = GetSpecialization();
	if not spec then return; end

	--local role = GetSpecializationRole(spec);
	if chance ~= 0 and C_PaperDollInfo.OffhandHasShield() then		--role == "TANK"
		object:SetLabelAndValue(STAT_BLOCK, chanceText);
	else
		object:SetLabelAndValue(STAT_BLOCK, "N/A", true);
	end

	object.tooltip = "|cffffffff".. BLOCK_CHANCE .." "..format("%.2F", chance).."%".."|r";

	local shieldBlockArmor = GetShieldBlock();
	local blockArmorReduction = C_PaperDollInfo.GetArmorEffectiveness(shieldBlockArmor, UnitEffectiveLevel(unit));
	local blockArmorReductionAgainstTarget = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(shieldBlockArmor);

	object.tooltip2 = format(CR_BLOCK_TOOLTIP, blockArmorReduction * 100);
	if (blockArmorReductionAgainstTarget) then
		object.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget * 100);
	else
		object.tooltip3 = nil;
	end
end

function UpdateFunc:Health(object, unit)
	if (not unit) then
		unit = "player";
	end
	local health = UnitHealthMax(unit);
	local healthText = FormatLargeNumbers(health);
	object.Label:SetText(HEALTH)
	object.Value:SetText(healthText)
	object.tooltip = "|cffffffff".. HEALTH .." "..healthText.."|r";
	if (unit == "player") then
		object.tooltip2 = STAT_HEALTH_TOOLTIP;
	elseif (unit == "pet") then
		object.tooltip2 = STAT_HEALTH_PET_TOOLTIP;
	end
	object:Show();
end

function UpdateFunc:Power(object)
	local unit = "player";
	local powerType, powerToken = UnitPowerType(unit);
	local power = UnitPowerMax(unit) or 0;
	local powerText = FormatLargeNumbers(power);
	local powerName = _G[powerToken];
	if (powerToken and powerName) then
		object.Label:SetText(powerName)
		object.Value:SetText(powerText)
		object.tooltip = "|cffffffff".. powerName .." "..powerText.."|r";
		object.tooltip2 = _G["STAT_"..powerToken.."_TOOLTIP"];
		object:Show();
	else
		object:SetLabelAndValue("Resource", "N/A", true);
	end
end

function UpdateFunc:Regen(object)
	local powerType, powerToken = UnitPowerType("player");
	local regenRate = GetPowerRegen();
	local regenRateText = BreakUpLargeNumbers(regenRate);
	local regenRatePerSec = format("%.2f", regenRate).."/s";
	local labelText;
	if powerToken == "ENERGY" then
		labelText = STAT_ENERGY_REGEN;
		object.tooltip2 = STAT_ENERGY_REGEN_TOOLTIP;
	elseif powerToken == "RUNES" then
		labelText = STAT_RUNE_REGEN;
		object.tooltip2 = STAT_RUNE_REGEN_TOOLTIP;
	elseif powerToken == "FOCUS" then
		labelText = STAT_FOCUS_REGEN;
		object.tooltip2 = STAT_FOCUS_REGEN_TOOLTIP;
	elseif UnitHasMana("player") then
		labelText = MANA_REGEN;
		regenRate = GetManaRegen();
		regenRatePerSec = tostring(floor(regenRate)).."/s";
	else
		local _, class = UnitClass("player");
		if (class ~= "DEATHKNIGHT") then
			object:SetLabelAndValue(MANA_REGEN_COMBAT, "N/A", true);		--MANA_REGEN_ABBR
			return;
		end
		local _, regenRate = GetRuneCooldown(1);
		local regenRateText = (format(STAT_RUNE_REGEN_FORMAT, regenRate));
		object:SetLabelAndValue(STAT_RUNE_REGEN, regenRateText);
		return;
	end
	if labelText then
		object.tooltip = "|cffffffff".. labelText .." "..regenRatePerSec.."|r";
	end
	object:SetLabelAndValue(labelText, regenRatePerSec);
end

function UpdateFunc:Crit(object)
	if not Narci.refreshCombatRatings then return end;
	local critChance, rating = GetEffectiveCrit();

	object.tooltip = "|cffffffff".. STAT_CRITICAL_STRIKE .." "..format("%.2F%%", critChance).."|r";
	local extraCritChance = GetCombatRatingBonus(rating);
	local extraCritRating = GetCombatRating(rating);
	object.tooltip4 = nil;
	if (GetCritChanceProvidesParryEffect()) then
		object.tooltip2 = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
	else
		if extraCritChance == 0 then
			object.tooltip2 = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance);
		else
			object.tooltip2 = NARCI_CRIT_TOOLTIP;
			object.tooltip4 = {format(NARCI_CRIT_TOOLTIP_FORMAT, BreakUpLargeNumbers(extraCritRating), extraCritChance), floor( (extraCritRating / extraCritChance) * 100 + 0.5) / 100 .. " [+1%]"}
		end
	end

	local PercentageText = format(DIGITS, critChance).."%"
	object.Label:SetText(NARCI_CRITICAL_STRIKE);		--COMBAT_RATING_NAME10
	object.Value:SetText(PercentageText);
	object.ValueRating:SetText(extraCritRating);
end

function UpdateFunc:Haste(object)
	if not Narci.refreshCombatRatings then return end;
	local unit = "player";
	local haste = GetHaste();
	local rating = CR_HASTE_MELEE;
	local hasteFormatString;

	if (haste < 0 and not GetPVPGearStatRules()) then
		hasteFormatString = RED_FONT_COLOR_CODE.."%s".."|r";
	else
		hasteFormatString = "%s";
	end

	object.tooltip = "|cffffffff" .. STAT_HASTE .. " " .. format(hasteFormatString, format("%.2F%%", haste)) .. "|r";

	local _, class = UnitClass(unit);
	object.tooltip2 = _G["STAT_HASTE_"..class.."_TOOLTIP"];
	if (not object.tooltip2) then
		object.tooltip2 = STAT_HASTE_TOOLTIP;
	end

	local Rating = GetCombatRating(rating);
	local RatingBonus = GetCombatRatingBonus(rating);
	if RatingBonus == 0 then
		object.tooltip2 = object.tooltip2 .. format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(Rating), RatingBonus);
		object.tooltip4 = nil;
	else
		object.tooltip4 = {format(NARCI_HASTE_TOOLTIP_FORMAT, BreakUpLargeNumbers(Rating), RatingBonus), floor( (Rating / RatingBonus) * 100 + 0.5) / 100 .. " [+1%]"};
	end

	local PercentageText = format(DIGITS, haste).."%"
	object.Label:SetText(STAT_HASTE);
	object.Value:SetText(PercentageText);
	object.ValueRating:SetText(GetCombatRating(rating));
end

function UpdateFunc:Mastery(object)
	if not Narci.refreshCombatRatings then return end;
	object:SetScript("OnEnter", MasteryFrame_OnEnter);

	local mastery = GetMasteryEffect();
	local PercentageText = format(DIGITS, mastery).."%"
	object.Label:SetText(STAT_MASTERY);

	--[[
	if (UnitLevel("player") < SHOW_MASTERY_LEVEL) then
		object.numericValue = 0;
		object.Value:SetText("N/A");
		object.ValueRating:SetText("0");
		object.Label:SetAlpha(NO_BONUS_ALPHA)
		object.Value:SetAlpha(NO_BONUS_ALPHA)
		object.ValueRating:SetAlpha(NO_BONUS_ALPHA)
		return;
	end
	--]]

	object.Value:SetText(PercentageText);
	object.ValueRating:SetText(GetCombatRating(CR_MASTERY));

	object.Label:SetAlpha(1)
	object.Value:SetAlpha(1)
	object.ValueRating:SetAlpha(1)
end

function UpdateFunc:Versatility(object)
	if not Narci.refreshCombatRatings then return end;
	local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
	local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
	local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
	object.tooltip = "|cffffffff" .. format(VERSATILITY_TOOLTIP_FORMAT, STAT_VERSATILITY, versatilityDamageBonus, versatilityDamageTakenReduction) .. "|r";

	if versatilityDamageBonus == 0 then
		object.tooltip2 = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction);
		object.tooltip4 = nil;
	else
		object.tooltip2 = format(NARCI_VERSATILITY_TOOLTIP_FORMAT_1, versatilityDamageBonus, versatilityDamageTakenReduction);
		object.tooltip4 = {format(NARCI_VERSATILITY_TOOLTIP_FORMAT_2, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction) , floor( (versatility / versatilityDamageBonus) * 100 + 0.5) / 100 .. " [+1%/0.5%]"};
	end

	local PercentageText = format(DIGITS, versatilityDamageBonus).."%";
	object.Label:SetText(STAT_VERSATILITY);
	object.Value:SetText(PercentageText);
	object.ValueRating:SetText(GetCombatRating(CR_VERSATILITY_DAMAGE_DONE));
end

function UpdateFunc:Leech(object)
	local lifesteal = GetLifesteal();

	object.tooltip = "|cffffffff" .. STAT_LIFESTEAL .. " " .. format("%.2F%%", lifesteal) .. "|r";
	object.tooltip2 = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)), GetCombatRatingBonus(CR_LIFESTEAL));

	local PercentageText = format(DIGITS, lifesteal).."%";
	object:SetLabelAndValue(STAT_LIFESTEAL, PercentageText, lifesteal == 0);
end

function UpdateFunc:Avoidance(object)
	local avoidance = GetAvoidance();

	object.tooltip = "|cffffffff" .. STAT_AVOIDANCE .. " " .. format("%.2F%%", avoidance) .. "|r";
	object.tooltip2 = format(CR_AVOIDANCE_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE)), GetCombatRatingBonus(CR_AVOIDANCE));
	
	local PercentageText = format(DIGITS, avoidance).."%";
	object:SetLabelAndValue(STAT_AVOIDANCE, PercentageText, avoidance == 0);
end

function UpdateFunc:Speed(object)
	local speed = GetSpeed();

	object.tooltip = "|cffffffff" .. STAT_SPEED .. " " .. format("%.2F%%", speed) .. "|r";
	object.tooltip2 = format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED));

	local PercentageText = format(DIGITS, speed).."%";
	object:SetLabelAndValue(STAT_SPEED, PercentageText, speed == 0);
end

function UpdateFunc:MovementSpeed(object)
	local unit = "player";

	object.wasSwimming = nil;
	object.unit = unit;
	object.t = 0;
	MovementSpeed_OnUpdate(object, 1);
	object:SetScript("OnEnter", MovementSpeed_OnEnter);
	object:SetScript("OnUpdate", MovementSpeed_OnUpdate);
end

---------------------------------------------------------------------------
NarciAttributeMixin = {};

function NarciAttributeMixin:Update()
    if UpdateFunc[self.token] then
        UpdateFunc[self.token](nil, self);
    end
end

function NarciAttributeMixin:SetLabelAndValue(label, value, grey)
	self.Label:SetText(label);
	self.Value:SetText(value);
	if grey then
		self.Label:SetTextColor(0.5, 0.5, 0.5);
		self.Value:SetTextColor(0.5, 0.5, 0.5);
	else
		self.Label:SetTextColor(0.92, 0.92, 0.92);
		self.Value:SetTextColor(0.92, 0.92, 0.92);
	end
end