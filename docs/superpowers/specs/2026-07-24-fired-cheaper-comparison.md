# Fired Cheaper Comparison and Design Notes

**Project Root:** `mod_fired_cheaper`

**Purpose:** Compare the current `mod_fired_cheaper` implementation against the requested redesign, then lock the design assumptions for the implementation plan.

## Current Mod Behavior

### Files

- [`scripts/!mods_preload/mod_fairCompensation.nut`](/E:/Battle%20Brother%20extract%20code/mod_fired_cheaper/scripts/!mods_preload/mod_fairCompensation.nut)
- [`ui/screens/character/modules/character_screen_left_panel/character_screen_left_panel_header_module.js`](/E:/Battle%20Brother%20extract%20code/mod_fired_cheaper/ui/screens/character/modules/character_screen_left_panel/character_screen_left_panel_header_module.js)

### Current Architecture

The current mod is a legacy Hooks-era implementation:

- registers with `::mods_registerMod(...)`
- uses `::mods_queue(...)`
- injects data through `::mods_hookNewObjectOnce("ui/global/data_helper", ...)`
- overrides dismissal handling through `::mods_hookNewObjectOnce("ui/screens/character/character_screen", ...)`
- ships a copied Battle Brothers UI JS file with local edits

It does not use:

- `::Hooks.register(...)`
- `mod_msu`
- `::MSU.Class.Mod(...)`
- MSU Mod Settings pages
- isolated helper functions for compensation sub-components

### Current Compensation Formula

The current formula is custom and based on:

- effective wage and base wage average
- days with company scaled into a pension
- healing time and medicine cost
- temporary injury compensation
- permanent injury compensation
- semi-injury compensation
- distance from civilization

This formula is not based on the requested "hire cost + configurable deductions/additions" model.

### Current Dismissal/UI Behavior

The current mod:

- adds a compensation amount to selected brother UI data
- changes dismiss dialog text to mention compensation or reparations
- lets the user keep a checkbox to pay or not pay compensation
- applies custom dismissal money removal through `onDismissCharacter`
- preserves existing game-side dismissal news, mood, slave, statistics, stash transfer, and roster removal behavior inside the overridden function

## Requested Redesign

## Core Goals

1. Replace legacy mod bootstrap with MSU + modern Hooks.
2. Expose important compensation variables in the option menu.
3. Replace the current compensation formula with the requested configurable formula.
4. Keep original/current dismissal side behaviors by default, but make the extra behavior group adjustable through settings.
5. Show the final compensation formula result and breakdown directly in the dismiss dialog during firing.

## Requested Formula Model

The requested formula is:

`final compensation = base hire portion + optional roster days + injury bonuses - optional equipment deductions`

### Requested Components

- `HireCostPortion`
  - default behavior: compensation includes first hire cost multiplied by a configurable percentage
- `DaysWithRoster`
  - disabled by default
  - when enabled, each day contributes a configurable flat gold value
- `EquipmentDeduction`
  - deduct equipment value from final compensation
  - default calculation uses sell price
  - base/original item price may remain as an optional stricter mode
  - configurable multiplier
  - base requested scope:
    - head armor
    - body armor
    - mainhand weapon
  - additional slots:
    - offhand
    - accessory/bag slot
    - ammo
  - additional slot counting defaults to `false`
- `PermanentInjuryBonus`
  - configurable flat amount per permanent injury
- `TemporaryInjuryBonus`
  - configurable flat amount per injury
- `LevelBracketBonus`
  - optional flat amount based on brother level bracket
  - approved brackets:
    - level `1-5` => `50` gold
    - level `6-10` => `100` gold
    - level `11+` => `200` gold

## Settings Model

Settings must be grouped by context in the option menu rather than shown as one flat list.

Recommended page structure:

- `General`
- `Hire Compensation`
- `Equipment Deduction`
- `Injury Compensation`
- `Dismissal Behaviors`

### Formula Settings

These should remain individually adjustable inside their context-appropriate groups.

Recommended settings:

- `EnableCompensationPaymentCheckbox`
- `HireCostPercent`
- `EnableDaysWithRosterCompensation`
- `DaysWithRosterFlatGoldPerDay`
- `EnableEquipmentDeduction`
- `EquipmentPriceMode`
- `EquipmentValuePercent`
- `CountHeadArmor`
- `CountBodyArmor`
- `CountMainhandWeapon`
- `CountOffhand`
- `CountAccessory`
- `CountAmmo`
- `PermanentInjuryFlatGold`
- `TemporaryInjuryFlatGold`
- `EnableLevelBracketCompensation`
- `LevelBracketLowFlatGold`
- `LevelBracketMidFlatGold`
- `LevelBracketHighFlatGold`
- `MinimumCompensationFloor`

### Extra Behavior Settings

User requested simplification:

- one master setting for all extra dismissal behaviors

Recommended setting:

- `EnableExtraDismissalBehaviors`

When `true`:

- preserve the current non-formula extras already implemented in the mod, including:
  - slave mood side effects tied to compensated dismissal
  - dismissal news generation
  - roster mood penalties from dismissing brothers

When `false`:

- keep the dismissal function mechanically correct
- still transfer items to stash
- still remove the brother
- still update statistics required for roster/state consistency
- skip the grouped custom flavor/side-effect behaviors

## Vanilla vs Mod Behavior Boundary

The redesign should not try to rewrite the full vanilla dismiss pipeline. The safe scope is:

- modernize the mod bootstrap and hooks
- isolate compensation calculation into helpers
- inject UI-facing preview data
- gate extra modded side behaviors behind one setting
- leave core dismissal completion behavior intact
- require the dismiss dialog itself to show the compensation breakdown, not tooltip-only disclosure

## Recommended Technical Direction

### Bootstrap

Follow the pattern used in `mod_op_archers` and `mod_aura_routing`:

- `::Hooks.register(...)`
- `require("mod_msu >= 1.9.0")`
- `queue(">mod_msu", function() { ... })`
- create `::FiredCheaper.Mod <- ::MSU.Class.Mod(...)`
- register settings in a dedicated file

### File Layout Direction

Recommended split:

- one loader/bootstrap file
- one settings-registration file
- one compensation-calculation helper file
- one dismiss-flow hook file
- one UI hook file or JS asset patch registration file

This reduces the current single-file logic concentration in `mod_fairCompensation.nut`.

## Constraints

- Use `mod_fired_cheaper` as the project root.
- Do not modify `data_001`.
- Do not modify unrelated community mods.
- Preserve current behavior by default where requested.
- Prefer MSU settings over hard-coded constants.
- Avoid copying more vanilla UI code than necessary when a hook can patch behavior more narrowly.

## Open Risk Areas

1. **Dismiss UI patch scope**
   - The current mod ships a copied JS file. If a narrower JS patch/hook is possible, it is preferable. If not, the replacement file must be kept minimal and documented.

2. **Hire cost source**
   - The requested formula depends on "the hired cost as the first time". The implementation must identify a reliable source for the original hiring price on a rostered brother. If vanilla does not persist this cleanly, the mod may need a fallback or tracked value.

3. **Equipment price source**
   - Sell price is now the default deduction model. If optional base-price mode is retained, the implementation must normalize both paths cleanly across item classes.

4. **Extra behavior grouping**
   - Some currently embedded behaviors are structural and should never be disabled, such as stash transfer and roster removal. The toggle must only cover optional side effects.

## Final Design Decision for Planning

The implementation plan should assume:

- MSU migration is required.
- The requested compensation formula replaces the current one.
- Formula variables are individually configurable and grouped by context in settings pages.
- Brother level is an additional compensation variable using flat level brackets.
- Equipment deduction defaults to sell price, not base price.
- Additional equipment slots are individually configurable and default to `false`.
- One master toggle controls grouped extra dismissal behaviors.
- Default settings preserve current/original behavior as closely as practical.
