if (!("FiredCheaper" in getroottable()))
{
	::FiredCheaper <- {};
}

::FiredCheaper.ID <- "mod_fired_cheaper";
::FiredCheaper.Name <- "Fired Cheaper";
::FiredCheaper.Version <- "0.1.0";

::FiredCheaper.installFallbackCalculator <- function()
{
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

	if (!("getCompensationCost" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationCost <- function( _bro )
		{
			return 10 * ::Math.max(1, _bro.getDaysWithCompany());
		}
	}

	if (!("getCompensationBreakdown" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationBreakdown <- function( _bro )
		{
			local value = ::FiredCheaper.getCompensationCost(_bro);
			return {
				finalCompensation = value
			};
		}
	}

	if (!("getCompensationBreakdownLines" in ::FiredCheaper))
	{
		::FiredCheaper.getCompensationBreakdownLines <- function( _bro )
		{
			return [
				"Final compensation: " + ::FiredCheaper.getCompensationCost(_bro)
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
	if (!("attachCompensationMethods" in ::FiredCheaper))
	{
		try
		{
			::include("scripts/mod_fired_cheaper/compensation_calculator");
		}
		catch (e)
		{
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

	::FiredCheaper.applyUIHooks(::FiredCheaper.HookMod);
	::FiredCheaper.applyDismissHooks(::FiredCheaper.HookMod);
});
