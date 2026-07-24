if (!("FiredCheaper" in getroottable()))
{
	::FiredCheaper <- {};
}

::FiredCheaper.ID <- "mod_fired_cheaper";
::FiredCheaper.Name <- "Fired Cheaper";
::FiredCheaper.Version <- "0.1.0";

::include("mod_fired_cheaper/compensation_calculator");
::include("mod_fired_cheaper/dismiss_hooks");
::include("mod_fired_cheaper/ui_hooks");

::FiredCheaper.HookMod <- ::Hooks.register(::FiredCheaper.ID, ::FiredCheaper.Version, ::FiredCheaper.Name);
::FiredCheaper.HookMod.require("mod_msu >= 1.9.0");

::FiredCheaper.HookMod.queue(">mod_msu", function()
{
	::FiredCheaper.Mod <- ::MSU.Class.Mod(::FiredCheaper.ID, ::FiredCheaper.Version, ::FiredCheaper.Name);
	::FiredCheaper.registerSettings();
	::FiredCheaper.applyUIHooks(::FiredCheaper.HookMod);
	::FiredCheaper.applyDismissHooks(::FiredCheaper.HookMod);
});
