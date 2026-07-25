if (!("DismissalEnhanced" in getroottable()))
{
	::DismissalEnhanced <- {};
}

::DismissalEnhanced.ID <- "mod_dismissal_enhanced";
::DismissalEnhanced.Name <- "Dismissal Enhanced";
::DismissalEnhanced.Version <- "0.1.0";

::DismissalEnhanced.installFallbackCalculator <- function()
{
	::DismissalEnhanced.CalculatorSource <- "fallback";

	if (!("getDefaultSettingValue" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getDefaultSettingValue <- function( _id )
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

	if (!("getSettingValue" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getSettingValue <- function( _id )
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
		}
	}

	if (!("countInjuriesByType" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.countInjuriesByType <- function( _bro, _skillType )
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

	if (!("getEquipmentSlotValue" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getEquipmentSlotValue <- function( _items, _slot )
		{
			local item = _items.getItemAtSlot(_slot);
			if (item == null || item == -1)
			{
				return 0;
			}

			return ::DismissalEnhanced.getSettingValue("UseSellPriceForEquipmentDeduction") ? item.getSellPrice() : item.getValue();
		}
	}

	if (!("getCompensationBreakdown" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getCompensationBreakdown <- function( _bro )
		{
			local hireCostBase = _bro.getHiringCost();
			local hireCostPercent = ::DismissalEnhanced.getSettingValue("HireCostPercent");
			local hireCostContribution = ::Math.ceil(hireCostBase * hireCostPercent / 100.0);

			local daysContributionEnabled = ::DismissalEnhanced.getSettingValue("EnableDaysWithRosterCompensation");
			local daysWithCompany = _bro.getDaysWithCompany();
			local daysContributionRate = ::DismissalEnhanced.getSettingValue("DaysWithRosterFlatGoldPerDay");
			local daysContribution = daysContributionEnabled ? daysWithCompany * daysContributionRate : 0;

			local levelContributionEnabled = ::DismissalEnhanced.getSettingValue("EnableLevelBracketCompensation");
			local level = _bro.getLevel();
			local levelBracket = "disabled";
			local levelContribution = 0;

			if (levelContributionEnabled)
			{
				if (level <= 5)
				{
					levelBracket = "1-5";
					levelContribution = ::DismissalEnhanced.getSettingValue("LevelBracketLowFlatGold");
				}
				else if (level <= 10)
				{
					levelBracket = "6-10";
					levelContribution = ::DismissalEnhanced.getSettingValue("LevelBracketMidFlatGold");
				}
				else
				{
					levelBracket = "11+";
					levelContribution = ::DismissalEnhanced.getSettingValue("LevelBracketHighFlatGold");
				}
			}

			local permanentInjuryCount = ::DismissalEnhanced.countInjuriesByType(_bro, ::Const.SkillType.PermanentInjury);
			local permanentInjuryRate = ::DismissalEnhanced.getSettingValue("PermanentInjuryFlatGold");
			local permanentInjuryContribution = permanentInjuryCount * permanentInjuryRate;

			local temporaryInjuryCount = ::DismissalEnhanced.countInjuriesByType(_bro, ::Const.SkillType.TemporaryInjury);
			local temporaryInjuryRate = ::DismissalEnhanced.getSettingValue("TemporaryInjuryFlatGold");
			local temporaryInjuryContribution = temporaryInjuryCount * temporaryInjuryRate;

			local equipmentDeductionEnabled = ::DismissalEnhanced.getSettingValue("EnableEquipmentDeduction");
			local equipmentUsesSellPrice = ::DismissalEnhanced.getSettingValue("UseSellPriceForEquipmentDeduction");
			local equipmentValuePercent = ::DismissalEnhanced.getSettingValue("EquipmentValuePercent");
			local equipmentBaseTotal = 0;
			local items = _bro.getItems();

			if (equipmentDeductionEnabled)
			{
				if (::DismissalEnhanced.getSettingValue("CountHeadArmor")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Head);
				if (::DismissalEnhanced.getSettingValue("CountBodyArmor")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Body);
				if (::DismissalEnhanced.getSettingValue("CountMainhandWeapon")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Mainhand);
				if (::DismissalEnhanced.getSettingValue("CountOffhand")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Offhand);
				if (::DismissalEnhanced.getSettingValue("CountAccessory")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Accessory);
				if (::DismissalEnhanced.getSettingValue("CountAmmo")) equipmentBaseTotal = equipmentBaseTotal + ::DismissalEnhanced.getEquipmentSlotValue(items, ::Const.ItemSlot.Ammo);
			}

			local equipmentDeduction = equipmentDeductionEnabled ? ::Math.ceil(equipmentBaseTotal * equipmentValuePercent / 100.0) : 0;
			local totalBeforeFloor = hireCostContribution + daysContribution + levelContribution + permanentInjuryContribution + temporaryInjuryContribution - equipmentDeduction;
			local minimumCompensationFloor = ::DismissalEnhanced.getSettingValue("MinimumCompensationFloor");
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

	if (!("getCompensationCost" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getCompensationCost <- function( _bro )
		{
			return ::DismissalEnhanced.getCompensationBreakdown(_bro).finalCompensation;
		}
	}

	if (!("getCompensationBreakdownLines" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.getCompensationBreakdownLines <- function( _bro )
		{
			local b = ::DismissalEnhanced.getCompensationBreakdown(_bro);
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

	if (!("attachCompensationMethods" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.attachCompensationMethods <- function( _bro )
		{
			if (_bro != null && !("getCompensationCost" in _bro))
			{
				_bro.getCompensationCost <- function()
				{
					return ::DismissalEnhanced.getCompensationCost(this);
				}
			}
		}
	}
}

::DismissalEnhanced.ensureCalculatorLoaded <- function()
{
	if (!("CalculatorSource" in ::DismissalEnhanced) || ::DismissalEnhanced.CalculatorSource != "full")
	{
		try
		{
			::include("scripts/mod_dismissal_enhanced/compensation_calculator");
			::DismissalEnhanced.LastCalculatorIncludeError <- null;
		}
		catch (e)
		{
			::DismissalEnhanced.LastCalculatorIncludeError <- e;
		}
	}

	if (!("attachCompensationMethods" in ::DismissalEnhanced))
	{
		::DismissalEnhanced.installFallbackCalculator();
	}

	return ("attachCompensationMethods" in ::DismissalEnhanced)
		&& ("getSettingValue" in ::DismissalEnhanced)
		&& ("getCompensationCost" in ::DismissalEnhanced)
		&& ("getCompensationBreakdown" in ::DismissalEnhanced)
		&& ("getCompensationBreakdownLines" in ::DismissalEnhanced);
}

::DismissalEnhanced.ensureCalculatorLoaded();
::include("scripts/mod_dismissal_enhanced/ui_hooks");
::include("scripts/mod_dismissal_enhanced/dismiss_hooks");

::DismissalEnhanced.HookMod <- ::Hooks.register(::DismissalEnhanced.ID, ::DismissalEnhanced.Version, ::DismissalEnhanced.Name);
::DismissalEnhanced.HookMod.require("mod_msu >= 1.9.0");

::DismissalEnhanced.HookMod.queue(">mod_msu", function()
{
	::DismissalEnhanced.Mod <- ::MSU.Class.Mod(::DismissalEnhanced.ID, ::DismissalEnhanced.Version, ::DismissalEnhanced.Name);
	::DismissalEnhanced.registerSettings();

	::Hooks.registerJS("ui/mods/dismissal_enhanced.js");
	::Hooks.registerCSS("ui/mods/dismissal_enhanced.css");

	::DismissalEnhanced.applyUIHooks(::DismissalEnhanced.HookMod);
	::DismissalEnhanced.applyDismissHooks(::DismissalEnhanced.HookMod);
});
