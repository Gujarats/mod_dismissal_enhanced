if (!("FiredCheaper" in getroottable()))
{
	::FiredCheaper <- {};
}

::FiredCheaper.ID <- "mod_fired_cheaper";
::FiredCheaper.Name <- "Fired Cheaper";
::FiredCheaper.Version <- "0.1.0";

::include("scripts/mod_fired_cheaper/compensation_calculator");
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
