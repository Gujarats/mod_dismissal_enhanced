if (!("setCalculatorSlot" in ::DismissalEnhanced))
{
	::DismissalEnhanced.setCalculatorSlot <- function( _key, _value )
	{
		if (_key in ::DismissalEnhanced)
		{
			::DismissalEnhanced[_key] = _value;
		}
		else
		{
			::DismissalEnhanced[_key] <- _value;
		}
	}
}

::DismissalEnhanced.setCalculatorSlot("CalculatorSource", "full");

::DismissalEnhanced.setCalculatorSlot("getDefaultSettingValue", function( _id )
{
	switch (_id)
	{
		case "EnableCompensationPaymentCheckbox": return true;
		case "MinimumCompensationFloor": return 0;
		case "HireCostPercent": return 50;
		case "EnableDaysWithRosterCompensation": return false;
		case "DaysWithRosterFlatGoldPerDay": return 1;
		case "EnableLevelBracketCompensation": return true;
		case "LevelBracketLowFlatGold": return 50;
		case "LevelBracketMidFlatGold": return 100;
		case "LevelBracketHighFlatGold": return 200;
		case "EnableEquipmentDeduction": return true;
		case "UseSellPriceForEquipmentDeduction": return true;
		case "EquipmentValuePercent": return 100;
		case "CountHeadArmor": return true;
		case "CountBodyArmor": return true;
		case "CountMainhandWeapon": return true;
		case "CountOffhand": return false;
		case "CountAccessory": return false;
		case "CountAmmo": return false;
		case "PermanentInjuryFlatGold": return 250;
		case "TemporaryInjuryFlatGold": return 150;
		case "EnableExtraDismissalBehaviors": return true;
	}

	return null;
});

::DismissalEnhanced.setCalculatorSlot("getSettingValue", function( _id )
{
	if (("Mod" in ::DismissalEnhanced) && ::DismissalEnhanced.Mod != null)
	{
		try
		{
			local setting = ::DismissalEnhanced.Mod.ModSettings.getSetting(_id);
			if (setting != null)
			{
				return setting.getValue();
			}
		}
		catch (e)
		{
		}
	}

	return ::DismissalEnhanced.getDefaultSettingValue(_id);
});

::DismissalEnhanced.setCalculatorSlot("countInjuriesByType", function( _bro, _skillType )
{
	local injuries = _bro.getSkills().query(::Const.SkillType.Injury | ::Const.SkillType.SemiInjury);
	local count = 0;

	foreach (injury in injuries)
	{
		if (injury != null && injury.isType(_skillType))
		{
			count = count + 1;
		}
	}

	return count;
});

::DismissalEnhanced.setCalculatorSlot("getHireCostContribution", function( _bro )
{
	local base = _bro.getHiringCost();
	local percent = ::DismissalEnhanced.getSettingValue("HireCostPercent");

	return {
		Base = base,
		Percent = percent,
		Value = ::Math.ceil(base * percent / 100.0)
	};
});

::DismissalEnhanced.setCalculatorSlot("getDaysContribution", function( _bro )
{
	local enabled = ::DismissalEnhanced.getSettingValue("EnableDaysWithRosterCompensation");
	local rate = ::DismissalEnhanced.getSettingValue("DaysWithRosterFlatGoldPerDay");
	local days = _bro.getDaysWithCompany();

	return {
		Enabled = enabled,
		Days = days,
		Rate = rate,
		Value = enabled ? days * rate : 0
	};
});

::DismissalEnhanced.setCalculatorSlot("getLevelContribution", function( _bro )
{
	local enabled = ::DismissalEnhanced.getSettingValue("EnableLevelBracketCompensation");
	local level = _bro.getLevel();
	local value = 0;
	local label = "disabled";

	if (enabled)
	{
		if (level <= 5)
		{
			value = ::DismissalEnhanced.getSettingValue("LevelBracketLowFlatGold");
			label = "1-5";
		}
		else if (level <= 10)
		{
			value = ::DismissalEnhanced.getSettingValue("LevelBracketMidFlatGold");
			label = "6-10";
		}
		else
		{
			value = ::DismissalEnhanced.getSettingValue("LevelBracketHighFlatGold");
			label = "11+";
		}
	}

	return {
		Enabled = enabled,
		Level = level,
		Bracket = label,
		Value = value
	};
});

::DismissalEnhanced.setCalculatorSlot("getEquipmentSlotValue", function( _items, _slot )
{
	local item = _items.getItemAtSlot(_slot);
	if (item == null || item == -1)
	{
		return 0;
	}

	local useSellPrice = ::DismissalEnhanced.getSettingValue("UseSellPriceForEquipmentDeduction");
	return useSellPrice ? item.getSellPrice() : item.getValue();
});

::DismissalEnhanced.setCalculatorSlot("getEquipmentDeduction", function( _bro )
{
	local enabled = ::DismissalEnhanced.getSettingValue("EnableEquipmentDeduction");
	local percent = ::DismissalEnhanced.getSettingValue("EquipmentValuePercent");
	local useSellPrice = ::DismissalEnhanced.getSettingValue("UseSellPriceForEquipmentDeduction");
	local items = _bro.getItems();
	local total = 0;

	if (enabled)
	{
		if (::DismissalEnhanced.getSettingValue("CountHeadArmor")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Head);
		if (::DismissalEnhanced.getSettingValue("CountBodyArmor")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Body);
		if (::DismissalEnhanced.getSettingValue("CountMainhandWeapon")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Mainhand);
		if (::DismissalEnhanced.getSettingValue("CountOffhand")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Offhand);
		if (::DismissalEnhanced.getSettingValue("CountAccessory")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Accessory);
		if (::DismissalEnhanced.getSettingValue("CountAmmo")) total += ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Ammo);
	}

	return {
		Enabled = enabled,
		UsesSellPrice = useSellPrice,
		BaseTotal = total,
		Percent = percent,
		Value = enabled ? ::Math.ceil(total * percent / 100.0) : 0
	};
});

::DismissalEnhanced.setCalculatorSlot("getPermanentInjuryContribution", function( _bro )
{
	local count = ::DismissalEnhanced.countInjuriesByType(_bro, ::Const.SkillType.PermanentInjury);
	local rate = ::DismissalEnhanced.getSettingValue("PermanentInjuryFlatGold");

	return {
		Count = count,
		Rate = rate,
		Value = count * rate
	};
});

::DismissalEnhanced.setCalculatorSlot("getTemporaryInjuryContribution", function( _bro )
{
	local count = ::DismissalEnhanced.countInjuriesByType(_bro, ::Const.SkillType.TemporaryInjury);
	local rate = ::DismissalEnhanced.getSettingValue("TemporaryInjuryFlatGold");

	return {
		Count = count,
		Rate = rate,
		Value = count * rate
	};
});

::DismissalEnhanced.setCalculatorSlot("getCompensationBreakdown", function( _bro )
{
	local hire = ::DismissalEnhanced.getHireCostContribution(_bro);
	local days = ::DismissalEnhanced.getDaysContribution(_bro);
	local level = ::DismissalEnhanced.getLevelContribution(_bro);
	local permanent = ::DismissalEnhanced.getPermanentInjuryContribution(_bro);
	local temporary = ::DismissalEnhanced.getTemporaryInjuryContribution(_bro);
	local equipment = ::DismissalEnhanced.getEquipmentDeduction(_bro);
	local floor = ::DismissalEnhanced.getSettingValue("MinimumCompensationFloor");
	local totalBeforeFloor = hire.Value + days.Value + level.Value + permanent.Value + temporary.Value - equipment.Value;
	local finalValue = ::Math.max(floor, totalBeforeFloor);

	return {
		hireCostBase = hire.Base,
		hireCostPercent = hire.Percent,
		hireCostContribution = hire.Value,
		daysContributionEnabled = days.Enabled,
		daysWithCompany = days.Days,
		daysContributionRate = days.Rate,
		daysContribution = days.Value,
		levelContributionEnabled = level.Enabled,
		level = level.Level,
		levelBracket = level.Bracket,
		levelContribution = level.Value,
		permanentInjuryCount = permanent.Count,
		permanentInjuryRate = permanent.Rate,
		permanentInjuryContribution = permanent.Value,
		temporaryInjuryCount = temporary.Count,
		temporaryInjuryRate = temporary.Rate,
		temporaryInjuryContribution = temporary.Value,
		equipmentDeductionEnabled = equipment.Enabled,
		equipmentUsesSellPrice = equipment.UsesSellPrice,
		equipmentBaseTotal = equipment.BaseTotal,
		equipmentValuePercent = equipment.Percent,
		equipmentDeduction = equipment.Value,
		totalBeforeFloor = totalBeforeFloor,
		minimumCompensationFloor = floor,
		finalCompensation = finalValue
	};
});

::DismissalEnhanced.setCalculatorSlot("getCompensationBreakdownLines", function( _bro )
{
	local b = ::DismissalEnhanced.getCompensationBreakdown(_bro);
	local lines = [];

	lines.push("Hire cost (" + b.hireCostPercent + "% of " + b.hireCostBase + "): +" + b.hireCostContribution);

	if (b.daysContributionEnabled)
	{
		lines.push("Days with company (" + b.daysWithCompany + " x " + b.daysContributionRate + "): +" + b.daysContribution);
	}
	else
	{
		lines.push("Days with company: disabled");
	}

	if (b.levelContributionEnabled)
	{
		lines.push("Level bonus (level " + b.level + ", bracket " + b.levelBracket + "): +" + b.levelContribution);
	}
	else
	{
		lines.push("Level bonus: disabled");
	}

	lines.push("Permanent injuries (" + b.permanentInjuryCount + " x " + b.permanentInjuryRate + "): +" + b.permanentInjuryContribution);
	lines.push("Temporary injuries (" + b.temporaryInjuryCount + " x " + b.temporaryInjuryRate + "): +" + b.temporaryInjuryContribution);

	if (b.equipmentDeductionEnabled)
	{
		lines.push("Equipment deduction (" + (b.equipmentUsesSellPrice ? "sell price" : "base price") + ", " + b.equipmentValuePercent + "% of " + b.equipmentBaseTotal + "): -" + b.equipmentDeduction);
	}
	else
	{
		lines.push("Equipment deduction: disabled");
	}

	if (b.totalBeforeFloor != b.finalCompensation)
	{
		lines.push("Minimum floor applied: " + b.minimumCompensationFloor);
	}

	lines.push("Final compensation: " + b.finalCompensation);
	return lines;
});

::DismissalEnhanced.setCalculatorSlot("getCompensationCost", function( _bro )
{
	return ::DismissalEnhanced.getCompensationBreakdown(_bro).finalCompensation;
});

::DismissalEnhanced.setCalculatorSlot("attachCompensationMethods", function( _bro )
{
	if (_bro != null && !("getCompensationCost" in _bro))
	{
		_bro.getCompensationCost <- function()
		{
			return ::DismissalEnhanced.getCompensationCost(this);
		}
	}
});
