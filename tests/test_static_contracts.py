from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]


def read(rel_path: str) -> str:
    return (ROOT / rel_path).read_text(encoding="utf-8")


class StaticContractsTest(unittest.TestCase):
    def test_mod_config_identifies_fired_cheaper(self):
        config = json.loads(read("mod_config.json"))

        self.assertEqual(config["mod_id"], "mod_fired_cheaper")
        self.assertEqual(config["mod_name"], "Fired Cheaper")
        self.assertEqual(config["version"], "0.1.0")

    def test_modern_hooks_loader_and_msu_setup_are_defined(self):
        loader = read("scripts/!mods_preload/mod_fired_cheaper_loader.nut")

        self.assertIn("::Hooks.register(::FiredCheaper.ID", loader)
        self.assertIn('require("mod_msu >= 1.9.0")', loader)
        self.assertIn('queue(">mod_msu"', loader)
        self.assertIn("::MSU.Class.Mod", loader)
        self.assertIn("::FiredCheaper.registerSettings()", loader)
        self.assertIn('::Hooks.registerJS("ui/mods/fired_cheaper.js")', loader)

    def test_settings_include_approved_adjustable_variables(self):
        settings = read("scripts/!mods_preload/mod_fired_cheaper_settings.nut")

        for setting_id in [
            "EnableCompensationPaymentCheckbox",
            "MinimumCompensationFloor",
            "HireCostPercent",
            "EnableDaysWithRosterCompensation",
            "DaysWithRosterFlatGoldPerDay",
            "EnableLevelBracketCompensation",
            "LevelBracketLowFlatGold",
            "LevelBracketMidFlatGold",
            "LevelBracketHighFlatGold",
            "EnableEquipmentDeduction",
            "UseSellPriceForEquipmentDeduction",
            "EquipmentValuePercent",
            "CountHeadArmor",
            "CountBodyArmor",
            "CountMainhandWeapon",
            "CountOffhand",
            "CountAccessory",
            "CountAmmo",
            "PermanentInjuryFlatGold",
            "TemporaryInjuryFlatGold",
            "EnableExtraDismissalBehaviors",
        ]:
            self.assertIn(f'"{setting_id}"', settings)

        self.assertIn('"Use Sell Price"', settings)
        self.assertIn('"Level 11+ Bonus"', settings)

    def test_compensation_calculator_exposes_entity_compatibility_method(self):
        calculator = read("scripts/mod_fired_cheaper/compensation_calculator.nut")

        self.assertIn("::FiredCheaper.attachCompensationMethods", calculator)
        self.assertIn('"getCompensationCost" in _bro', calculator)
        self.assertIn("_bro.getCompensationCost <- function()", calculator)
        self.assertIn("::FiredCheaper.getCompensationCost(this)", calculator)
        self.assertIn("UseSellPriceForEquipmentDeduction", calculator)
        self.assertIn("item.getSellPrice()", calculator)
        self.assertIn("item.getValue()", calculator)
        self.assertNotIn("this.Math", calculator)
        self.assertNotIn("this.Const", calculator)

    def test_ui_hook_injects_compensation_preview_payload(self):
        ui_hook = read("scripts/mod_fired_cheaper/ui_hooks.nut")

        self.assertIn('hook("scripts/ui/global/data_helper"', ui_hook)
        self.assertIn("q.addCharacterToUIData = @(__original) function", ui_hook)
        self.assertIn("_target.isPlayerCharacter", ui_hook)
        self.assertNotIn('"getHiringCost" in _entity', ui_hook)
        self.assertIn("::FiredCheaper.attachCompensationMethods(_entity)", ui_hook)
        self.assertIn("_target.compensationCost <- _entity.getCompensationCost()", ui_hook)
        self.assertIn("_target.compensationBreakdown <- ::FiredCheaper.getCompensationBreakdown(_entity)", ui_hook)
        self.assertIn("_target.compensationBreakdownLines <- ::FiredCheaper.getCompensationBreakdownLines(_entity)", ui_hook)
        self.assertIn("_target.showCompensationCheckbox <- ::FiredCheaper.getSettingValue", ui_hook)

    def test_dismiss_hook_uses_same_entity_compensation_method_for_payment(self):
        dismiss_hook = read("scripts/mod_fired_cheaper/dismiss_hooks.nut")

        self.assertIn('hook("scripts/ui/screens/character/character_screen"', dismiss_hook)
        self.assertIn("q.onDismissCharacter = @(__original) function", dismiss_hook)
        self.assertIn("::FiredCheaper.attachCompensationMethods(bro)", dismiss_hook)
        self.assertIn("this.World.Assets.addMoney(-bro.getCompensationCost())", dismiss_hook)
        self.assertIn("EnableExtraDismissalBehaviors", dismiss_hook)

    def test_dismiss_dialog_renders_visible_breakdown_lines(self):
        ui = read("ui/mods/fired_cheaper.js")

        self.assertIn("selectedBrother['compensationBreakdownLines']", ui)
        self.assertIn("selectedBrother['showCompensationCheckbox']", ui)
        self.assertIn("Compensation breakdown", ui)
        self.assertIn("Final compensation: ", ui)
        self.assertIn("bindTooltip", ui)


if __name__ == "__main__":
    unittest.main()
