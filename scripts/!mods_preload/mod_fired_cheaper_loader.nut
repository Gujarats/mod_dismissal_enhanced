if (!("FiredCheaper" in getroottable()))
{
	::FiredCheaper <- {};
}

::FiredCheaper.ID <- "mod_fired_cheaper";
::FiredCheaper.Name <- "Fired Cheaper";
::FiredCheaper.Version <- "0.1.0";

::FiredCheaper.installFallbackCalculator <- function()
{
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
