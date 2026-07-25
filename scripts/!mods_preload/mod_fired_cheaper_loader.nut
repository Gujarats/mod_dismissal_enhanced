if (!("FiredCheaper" in getroottable()))
{
	::FiredCheaper <- {};
}

::FiredCheaper.ID <- "mod_fired_cheaper";
::FiredCheaper.Name <- "Fired Cheaper";
::FiredCheaper.Version <- "0.1.0";

::FiredCheaper.installFallbackCalculator <- function()
{
	::FiredCheaper.CalculatorSource <- "fallback";

	if (!("getDefaultSettingValue" in ::FiredCheaper))
	{
		::FiredCheaper.getDefaultSettingValue <- function( _id )
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
		}
	}

	if (!("getSettingValue" in ::FiredCheaper))
	{
		::FiredCheaper.getSettingValue <- function( _id )
		{
			if (("Mod" in ::FiredCheaper) && ::FiredCheaper.Mod != null)
			{
				try
				{
					local setting = ::FiredCheaper.Mod.ModSettings.getSetting(_id);
					if (setting != null)
					{
						return setting.getValue();
					}
				}
				catch (e)
				{
				}
			}

			return ::FiredCheaper.getDefaultSettingValue(_id);
		}
	}

	if (!("countInjuriesByType" in ::FiredCheaper))
	{
		::FiredCheaper.countInjuriesByType <- function( _bro, _skillType )
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
		}
	}

	if (!("getEquipmentSlotValue" in ::FiredCheaper))
	{
		::FiredCheaper.getEquipmentSlotValue <- function( _items, _slot )
		{
			local item = _items.getItemAtSlot(_slot);
			if (item == null || item == -1)
			{
				return 0;
			}

			return ::FiredCheaper.getSettingValue("UseSellPriceForEquipmentDeduction") ? item.getSellPrice() : item.getValue();
		}
	}

	if (!("getCompensationBreakdown" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationBreakdown <- function( _bro )
		{
			local hireCostBase = _bro.getHiringCost();
			local hireCostPercent = ::FiredCheaper.getSettingValue("HireCostPercent");
			local hireCostContribution = ::Math.ceil(hireCostBase * hireCostPercent / 100.0);

			local daysContributionEnabled = ::FiredCheaper.getSettingValue("EnableDaysWithRosterCompensation");
			local daysWithCompany = _bro.getDaysWithCompany();
			local daysContributionRate = ::FiredCheaper.getSettingValue("DaysWithRosterFlatGoldPerDay");
			local daysContribution = daysContributionEnabled ? daysWithCompany * daysContributionRate : 0;

			local levelContributionEnabled = ::FiredCheaper.getSettingValue("EnableLevelBracketCompensation");
			local level = _bro.getLevel();
			local levelBracket = "disabled";
			local levelContribution = 0;

			if (levelContributionEnabled)
			{
				if (level <= 5)
				{
					levelBracket = "1-5";
					levelContribution = ::FiredCheaper.getSettingValue("LevelBracketLowFlatGold");
				}
				else if (level <= 10)
				{
					levelBracket = "6-10";
					levelContribution = ::FiredCheaper.getSettingValue("LevelBracketMidFlatGold");
				}
				else
				{
					levelBracket = "11+";
					levelContribution = ::FiredCheaper.getSettingValue("LevelBracketHighFlatGold");
				}
			}

			local permanentInjuryCount = ::FiredCheaper.countInjuriesByType(_bro, ::Const.SkillType.PermanentInjury);
			local permanentInjuryRate = ::FiredCheaper.getSettingValue("PermanentInjuryFlatGold");
			local permanentInjuryContribution = permanentInjuryCount * permanentInjuryRate;

			local temporaryInjuryCount = ::FiredCheaper.countInjuriesByType(_bro, ::Const.SkillType.TemporaryInjury);
			local temporaryInjuryRate = ::FiredCheaper.getSettingValue("TemporaryInjuryFlatGold");
			local temporaryInjuryContribution = temporaryInjuryCount * temporaryInjuryRate;

			local equipmentDeductionEnabled = ::FiredCheaper.getSettingValue("EnableEquipmentDeduction");
			local equipmentUsesSellPrice = ::FiredCheaper.getSettingValue("UseSellPriceForEquipmentDeduction");
			local equipmentValuePercent = ::FiredCheaper.getSettingValue("EquipmentValuePercent");
			local equipmentBaseTotal = 0;
			local items = _bro.getItems();

			if (equipmentDeductionEnabled)
			{
				if (::FiredCheaper.getSettingValue("CountHeadArmor")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Head);
				if (::FiredCheaper.getSettingValue("CountBodyArmor")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Body);
				if (::FiredCheaper.getSettingValue("CountMainhandWeapon")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Mainhand);
				if (::FiredCheaper.getSettingValue("CountOffhand")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Offhand);
				if (::FiredCheaper.getSettingValue("CountAccessory")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Accessory);
				if (::FiredCheaper.getSettingValue("CountAmmo")) equipmentBaseTotal = equipmentBaseTotal + ::FiredCheaper.getEquipmentSlotValue(items, ::Const.ItemSlot.Ammo);
			}

			local equipmentDeduction = equipmentDeductionEnabled ? ::Math.ceil(equipmentBaseTotal * equipmentValuePercent / 100.0) : 0;
			local totalBeforeFloor = hireCostContribution + daysContribution + levelContribution + permanentInjuryContribution + temporaryInjuryContribution - equipmentDeduction;
			local minimumCompensationFloor = ::FiredCheaper.getSettingValue("MinimumCompensationFloor");
			local finalCompensation = ::Math.max(minimumCompensationFloor, totalBeforeFloor);

			return {
				hireCostBase = hireCostBase,
				hireCostPercent = hireCostPercent,
				hireCostContribution = hireCostContribution,
				daysContributionEnabled = daysContributionEnabled,
				daysWithCompany = daysWithCompany,
				daysContributionRate = daysContributionRate,
				daysContribution = daysContribution,
				levelContributionEnabled = levelContributionEnabled,
				level = level,
				levelBracket = levelBracket,
				levelContribution = levelContribution,
				permanentInjuryCount = permanentInjuryCount,
				permanentInjuryRate = permanentInjuryRate,
				permanentInjuryContribution = permanentInjuryContribution,
				temporaryInjuryCount = temporaryInjuryCount,
				temporaryInjuryRate = temporaryInjuryRate,
				temporaryInjuryContribution = temporaryInjuryContribution,
				equipmentDeductionEnabled = equipmentDeductionEnabled,
				equipmentUsesSellPrice = equipmentUsesSellPrice,
				equipmentBaseTotal = equipmentBaseTotal,
				equipmentValuePercent = equipmentValuePercent,
				equipmentDeduction = equipmentDeduction,
				totalBeforeFloor = totalBeforeFloor,
				minimumCompensationFloor = minimumCompensationFloor,
				finalCompensation = finalCompensation
			};
		}
	}

	if (!("getCompensationCost" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationCost <- function( _bro )
		{
			return ::FiredCheaper.getCompensationBreakdown(_bro).finalCompensation;
		}
	}

	if (!("getCompensationBreakdownLines" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationBreakdownLines <- function( _bro )
		{
			local b = ::FiredCheaper.getCompensationBreakdown(_bro);
			return [
				"Hire cost (" + b.hireCostPercent + "% of " + b.hireCostBase + "): +" + b.hireCostContribution,
				b.daysContributionEnabled ? "Days with company (" + b.daysWithCompany + " x " + b.daysContributionRate + "): +" + b.daysContribution : "Days with company: disabled",
				b.levelContributionEnabled ? "Level bonus (level " + b.level + ", bracket " + b.levelBracket + "): +" + b.levelContribution : "Level bonus: disabled",
				"Permanent injuries (" + b.permanentInjuryCount + " x " + b.permanentInjuryRate + "): +" + b.permanentInjuryContribution,
				"Temporary injuries (" + b.temporaryInjuryCount + " x " + b.temporaryInjuryRate + "): +" + b.temporaryInjuryContribution,
				b.equipmentDeductionEnabled ? "Equipment deduction (" + (b.equipmentUsesSellPrice ? "sell price" : "base price") + ", " + b.equipmentValuePercent + "% of " + b.equipmentBaseTotal + "): -" + b.equipmentDeduction : "Equipment deduction: disabled",
				"Final compensation: " + b.finalCompensation
			];
		}
	}

	if (!("attachCompensationMethods" in ::FiredCheaper))
	{
		::FiredCheaper.attachCompensationMethods <- function( _bro )
		{
			if (_bro != null && !("getCompensationCost" in _bro))
			{
				_bro.getCompensationCost <- function()
				{
					return ::FiredCheaper.getCompensationCost(this);
				}
			}
		}
	}
}

::FiredCheaper.ensureCalculatorLoaded <- function()
{
	if (!("CalculatorSource" in ::FiredCheaper) || ::FiredCheaper.CalculatorSource != "full")
	{
		try
		{
			::include("scripts/mod_fired_cheaper/compensation_calculator");
			::FiredCheaper.LastCalculatorIncludeError <- null;
		}
		catch (e)
		{
			::FiredCheaper.LastCalculatorIncludeError <- e;
		}
	}

	if (!("attachCompensationMethods" in ::FiredCheaper))
	{
		::FiredCheaper.installFallbackCalculator();
	}

	return ("attachCompensationMethods" in ::FiredCheaper)
		&& ("getSettingValue" in ::FiredCheaper)
		&& ("getCompensationCost" in ::FiredCheaper)
		&& ("getCompensationBreakdown" in ::FiredCheaper)
		&& ("getCompensationBreakdownLines" in ::FiredCheaper);
}

::FiredCheaper.ensureCalculatorLoaded();
::include("scripts/mod_fired_cheaper/ui_hooks");
::include("scripts/mod_fired_cheaper/dismiss_hooks");

::FiredCheaper.HookMod <- ::Hooks.register(::FiredCheaper.ID, ::FiredCheaper.Version, ::FiredCheaper.Name);
::FiredCheaper.HookMod.require("mod_msu >= 1.9.0");

::FiredCheaper.HookMod.queue(">mod_msu", function()
{
	::FiredCheaper.Mod <- ::MSU.Class.Mod(::FiredCheaper.ID, ::FiredCheaper.Version, ::FiredCheaper.Name);
	::FiredCheaper.registerSettings();

	::Hooks.registerJS("ui/mods/fired_cheaper.js");
	::Hooks.registerCSS("ui/mods/fired_cheaper.css");

	::FiredCheaper.applyUIHooks(::FiredCheaper.HookMod);
	::FiredCheaper.applyDismissHooks(::FiredCheaper.HookMod);
});
