if (!("DismissalEnhanced" in getroottable()))
{
	::DismissalEnhanced <- {};
}

::DismissalEnhanced.registerSettings <- function()
{
	local general = ::DismissalEnhanced.Mod.ModSettings.addPage("General");
	local hire = ::DismissalEnhanced.Mod.ModSettings.addPage("Hire Compensation");
	local equipment = ::DismissalEnhanced.Mod.ModSettings.addPage("Equipment Deduction");
	local injury = ::DismissalEnhanced.Mod.ModSettings.addPage("Injury Compensation");
	local behavior = ::DismissalEnhanced.Mod.ModSettings.addPage("Dismissal Behaviors");

	general.addBooleanSetting("EnableCompensationPaymentCheckbox", true, "Show Compensation Checkbox", "When enabled, the dismiss dialog lets you choose whether to pay compensation.");
	general.addRangeSetting("MinimumCompensationFloor", 0, 0, 5000, 10, "Minimum Compensation Floor", "The final compensation can never go below this amount.");

	hire.addRangeSetting("HireCostPercent", 50, 0, 200, 5, "Hire Cost Percent", "Percent of the brother's hiring cost added to compensation.");
	hire.addBooleanSetting("EnableDaysWithRosterCompensation", false, "Enable Days With Company", "When enabled, each day with the company adds a flat amount to compensation.");
	hire.addRangeSetting("DaysWithRosterFlatGoldPerDay", 1, 0, 50, 1, "Gold Per Day", "Flat gold added per day when days with company compensation is enabled.");
	hire.addBooleanSetting("EnableLevelBracketCompensation", true, "Enable Level Bonus", "When enabled, compensation gains a flat bonus based on the brother's level bracket.");
	hire.addRangeSetting("LevelBracketLowFlatGold", 50, 0, 5000, 10, "Level 1-5 Bonus", "Flat gold added for brothers from level 1 to 5.");
	hire.addRangeSetting("LevelBracketMidFlatGold", 100, 0, 5000, 10, "Level 6-10 Bonus", "Flat gold added for brothers from level 6 to 10.");
	hire.addRangeSetting("LevelBracketHighFlatGold", 200, 0, 5000, 10, "Level 11+ Bonus", "Flat gold added for brothers from level 11 upward.");

	equipment.addBooleanSetting("EnableEquipmentDeduction", true, "Enable Equipment Deduction", "When enabled, equipped items reduce final compensation.");
	equipment.addBooleanSetting("UseSellPriceForEquipmentDeduction", true, "Use Sell Price", "When enabled, equipment deduction uses sell price. When disabled, it uses base item value.");
	equipment.addRangeSetting("EquipmentValuePercent", 100, 0, 200, 5, "Equipment Value Percent", "Percent of counted equipment value deducted from compensation.");
	equipment.addBooleanSetting("CountHeadArmor", true, "Count Head Armor", "Include equipped head armor in the equipment deduction.");
	equipment.addBooleanSetting("CountBodyArmor", true, "Count Body Armor", "Include equipped body armor in the equipment deduction.");
	equipment.addBooleanSetting("CountMainhandWeapon", true, "Count Mainhand Weapon", "Include the equipped mainhand item in the equipment deduction.");
	equipment.addBooleanSetting("CountOffhand", false, "Count Offhand", "Include the equipped offhand item in the equipment deduction.");
	equipment.addBooleanSetting("CountAccessory", false, "Count Accessory", "Include the equipped accessory in the equipment deduction.");
	equipment.addBooleanSetting("CountAmmo", false, "Count Ammo", "Include the equipped ammo item in the equipment deduction.");

	injury.addRangeSetting("PermanentInjuryFlatGold", 250, 0, 5000, 10, "Permanent Injury Gold", "Flat gold added for each permanent injury.");
	injury.addRangeSetting("TemporaryInjuryFlatGold", 150, 0, 5000, 10, "Temporary Injury Gold", "Flat gold added for each temporary injury.");

	behavior.addBooleanSetting("EnableExtraDismissalBehaviors", true, "Enable Extra Dismissal Behaviors", "When enabled, dismissal includes the optional news and mood side effects.");
};
