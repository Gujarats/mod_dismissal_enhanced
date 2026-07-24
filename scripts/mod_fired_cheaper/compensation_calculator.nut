::FiredCheaper.getSettingValue <- function( _id )
{
	return ::FiredCheaper.Mod.ModSettings.getSetting(_id).getValue();
}

::FiredCheaper.countInjuriesByType <- function( _bro, _skillType )
{
	local injuries = _bro.getSkills().query(this.Const.SkillType.Injury | this.Const.SkillType.SemiInjury);
	local count = 0;

	foreach (injury in injuries)
	{
		if (injury != null && injury.isType(_skillType))
		{
			count = count + 1;
		}
	}

	return count;
}

::FiredCheaper.getHireCostContribution <- function( _bro )
{
	local base = _bro.getHiringCost();
	local percent = ::FiredCheaper.getSettingValue("HireCostPercent");
	return {
		Base = base,
		Percent = percent,
		Value = this.Math.ceil(base * percent / 100.0)
	};
}

::FiredCheaper.getDaysContribution <- function( _bro )
{
	local enabled = ::FiredCheaper.getSettingValue("EnableDaysWithRosterCompensation");
	local rate = ::FiredCheaper.getSettingValue("DaysWithRosterFlatGoldPerDay");
	local days = _bro.getDaysWithCompany();
	return {
		Enabled = enabled,
		Days = days,
		Rate = rate,
		Value = enabled ? days * rate : 0
	};
}

::FiredCheaper.getLevelContribution <- function( _bro )
{
	local enabled = ::FiredCheaper.getSettingValue("EnableLevelBracketCompensation");
	local level = _bro.getLevel();
	local value = 0;
	local label = "disabled";

	if (enabled)
	{
		if (level <= 5)
		{
			value = ::FiredCheaper.getSettingValue("LevelBracketLowFlatGold");
			label = "1-5";
		}
		else if (level <= 10)
		{
			value = ::FiredCheaper.getSettingValue("LevelBracketMidFlatGold");
			label = "6-10";
		}
		else
		{
			value = ::FiredCheaper.getSettingValue("LevelBracketHighFlatGold");
			label = "11+";
		}
	}

	return {
		Enabled = enabled,
		Level = level,
		Bracket = label,
		Value = value
	};
}

::FiredCheaper.getEquipmentSlotValue <- function( _items, _slot )
{
	local item = _items.getItemAtSlot(_slot);
	if (item == null || item == -1)
	{
		return 0;
	}

	local useSellPrice = ::FiredCheaper.getSettingValue("UseSellPriceForEquipmentDeduction");
	return useSellPrice ? item.getSellPrice() : item.getValue();
}

::FiredCheaper.getEquipmentDeduction <- function( _bro )
{
	local enabled = ::FiredCheaper.getSettingValue("EnableEquipmentDeduction");
	local percent = ::FiredCheaper.getSettingValue("EquipmentValuePercent");
	local useSellPrice = ::FiredCheaper.getSettingValue("UseSellPriceForEquipmentDeduction");
	local items = _bro.getItems();
	local total = 0;

	if (enabled)
	{
		if (::FiredCheaper.getSettingValue("CountHeadArmor")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Head);
		if (::FiredCheaper.getSettingValue("CountBodyArmor")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Body);
		if (::FiredCheaper.getSettingValue("CountMainhandWeapon")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Mainhand);
		if (::FiredCheaper.getSettingValue("CountOffhand")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Offhand);
		if (::FiredCheaper.getSettingValue("CountAccessory")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Accessory);
		if (::FiredCheaper.getSettingValue("CountAmmo")) total += ::FiredCheaper.getEquipmentSlotValue(items, this.Const.ItemSlot.Ammo);
	}

	return {
		Enabled = enabled,
		UsesSellPrice = useSellPrice,
		BaseTotal = total,
		Percent = percent,
		Value = enabled ? this.Math.ceil(total * percent / 100.0) : 0
	};
}

::FiredCheaper.getPermanentInjuryContribution <- function( _bro )
{
	local count = ::FiredCheaper.countInjuriesByType(_bro, this.Const.SkillType.PermanentInjury);
	local rate = ::FiredCheaper.getSettingValue("PermanentInjuryFlatGold");
	return {
		Count = count,
		Rate = rate,
		Value = count * rate
	};
}

::FiredCheaper.getTemporaryInjuryContribution <- function( _bro )
{
	local count = ::FiredCheaper.countInjuriesByType(_bro, this.Const.SkillType.TemporaryInjury);
	local rate = ::FiredCheaper.getSettingValue("TemporaryInjuryFlatGold");
	return {
		Count = count,
		Rate = rate,
		Value = count * rate
	};
}

::FiredCheaper.getCompensationBreakdown <- function( _bro )
{
	local hire = ::FiredCheaper.getHireCostContribution(_bro);
	local days = ::FiredCheaper.getDaysContribution(_bro);
	local level = ::FiredCheaper.getLevelContribution(_bro);
	local permanent = ::FiredCheaper.getPermanentInjuryContribution(_bro);
	local temporary = ::FiredCheaper.getTemporaryInjuryContribution(_bro);
	local equipment = ::FiredCheaper.getEquipmentDeduction(_bro);
	local floor = ::FiredCheaper.getSettingValue("MinimumCompensationFloor");
	local totalBeforeFloor = hire.Value + days.Value + level.Value + permanent.Value + temporary.Value - equipment.Value;
	local finalValue = this.Math.max(floor, totalBeforeFloor);

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
}

::FiredCheaper.getCompensationBreakdownLines <- function( _bro )
{
	local b = ::FiredCheaper.getCompensationBreakdown(_bro);
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
}

::FiredCheaper.getCompensationCost <- function( _bro )
{
	return ::FiredCheaper.getCompensationBreakdown(_bro).finalCompensation;
}
