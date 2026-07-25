# Dismissal Enhanced New Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `mod_dismissal_enhanced` as a new MSU + Modern Hooks mod with configurable settings-driven compensation logic and grouped optional dismissal behaviors.

**Architecture:** Use `mod_aura_routing` as the Modern Hooks/MSU pattern reference and `mod_fire_cheaper_legacy` only as one reference approach for dismissal/UI behavior. The shared formula lives in `::DismissalEnhanced`; player brother entities should also receive `bro.getCompensationCost()` as a compatibility API that delegates to the shared calculation. Keep the dismiss dialog experience focused on the approved formula and mandatory on-dialog breakdown display.

**Tech Stack:** Squirrel mod scripts, Hooks, MSU Mod Settings, Battle Brothers UI JS integration.

## Global Constraints

- Use `mod_dismissal_enhanced` as the project root.
- Do not modify `data_001`.
- Do not modify unrelated community mods.
- Preserve current behavior by default where requested.
- Prefer MSU settings over hard-coded constants.
- Keep formula settings granular.
- Use one master toggle for grouped extra dismissal behaviors.
- Group settings by context in separate MSU pages.
- The firing menu must show the compensation breakdown directly; tooltip-only presentation is insufficient.
- Expose `bro.getCompensationCost()` on player brothers as a compatibility API for UI and compatibility mods.
- Treat `mod_fire_cheaper_legacy` as reference material, not a migration source of truth.
- Use `UseSellPriceForEquipmentDeduction` as the boolean equipment price setting; default value is `true`.

---

## File Structure

### Create

- `scripts/!mods_preload/mod_dismissal_enhanced_loader.nut`
  - Modern Hooks registration, MSU requirement, queued setup, and module includes
- `scripts/!mods_preload/mod_dismissal_enhanced_settings.nut`
  - all MSU settings registration
- `scripts/mod_dismissal_enhanced/compensation_calculator.nut`
  - helper functions for each compensation component, final result, and entity compatibility method attachment
- `scripts/mod_dismissal_enhanced/dismiss_hooks.nut`
  - dismissal flow hook and grouped extra behavior gating
- `scripts/mod_dismissal_enhanced/ui_hooks.nut`
  - UI data injection and tooltip/popup preview support
- `docs/superpowers/specs/2026-07-24-fired-cheaper-comparison.md`
  - comparison/spec reference
- `docs/superpowers/plans/2026-07-24-fired-cheaper-modernization.md`
  - this plan

### Modify

- `scripts/!mods_preload/mod_fairCompensation.nut`
  - create only if needed as a thin compatibility stub; do not create a second active bootstrap path

### Create for UI

- `ui/mods/dismissal_enhanced.js`
  - selected approach: direct JS registration is narrower than replacing the full vanilla character screen file

## Settings Contract

The implementation should standardize on these setting keys:

- `EnableCompensationPaymentCheckbox`
- `HireCostPercent`
- `EnableDaysWithRosterCompensation`
- `DaysWithRosterFlatGoldPerDay`
- `EnableEquipmentDeduction`
- `UseSellPriceForEquipmentDeduction`
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
- `EnableExtraDismissalBehaviors`

## Data Contract

The UI hook should inject a stable structure for the dismiss dialog:

- player brother entity method:
  - `getCompensationCost()`
- `compensationCost`
- `compensationBreakdown`
  - `hireCostBase`
  - `hireCostContribution`
  - `daysContribution`
  - `levelContribution`
  - `equipmentDeduction`
  - `permanentInjuryContribution`
  - `temporaryInjuryContribution`
  - `finalCompensation`

The plan assumes the UI can render a single final number first and optionally expand the breakdown later without changing the backend contract.
The dismiss dialog itself must render the breakdown lines directly; hover-only disclosure is not acceptable.

`bro.getCompensationCost()` is part of the backend compatibility contract. It must exist on player brother entities before any UI or dismissal path tries to read compensation.

### Task 1: Create MSU Loader

**Files:**
- Create: `mod_dismissal_enhanced/scripts/!mods_preload/mod_dismissal_enhanced_loader.nut`
- Create: `mod_dismissal_enhanced/scripts/!mods_preload/mod_dismissal_enhanced_settings.nut`
- Optional Create: `mod_dismissal_enhanced/scripts/!mods_preload/mod_fairCompensation.nut`

**Interfaces:**
- Consumes: existing mod ID, version, and name from current preload script
- Produces:
  - `::DismissalEnhanced`
  - `::DismissalEnhanced.HookMod`
  - `::DismissalEnhanced.Mod`
  - `::DismissalEnhanced.registerSettings()`

- [ ] Review `mod_fire_cheaper_legacy/scripts/!mods_preload/mod_fairCompensation.nut` as reference only; extract useful dismissal and UI ideas without treating it as mandatory source.
- [ ] Create `mod_dismissal_enhanced_loader.nut` with `::Hooks.register(...)`, `require("mod_msu >= 1.9.0")`, and queue-after-MSU bootstrapping.
- [ ] Create `mod_dismissal_enhanced_settings.nut` with a `::DismissalEnhanced.registerSettings <- function() { ... }` entrypoint.
- [ ] Do not recreate legacy `::mods_registerMod(...)` / `::mods_queue(...)` bootstrap in `mod_fairCompensation.nut`.
- [ ] If `mod_fairCompensation.nut` is created, keep it as a comment-only or include-only compatibility stub.
- [ ] Verify the final load path contains exactly one active bootstrap path.

### Task 2: Register Settings Pages and Defaults

**Files:**
- Modify: `mod_dismissal_enhanced/scripts/!mods_preload/mod_dismissal_enhanced_settings.nut`

**Interfaces:**
- Consumes: `::DismissalEnhanced.Mod.ModSettings`
- Produces:
  - `General` settings page
  - `Hire Compensation` settings page
  - `Equipment Deduction` settings page
  - `Injury Compensation` settings page
  - `Dismissal Behaviors` settings page

- [ ] Add a `General` page with `EnableCompensationPaymentCheckbox`.
- [ ] Decide whether `MinimumCompensationFloor` belongs in `General` or `Hire Compensation`, then keep that placement consistent in code and docs.
- [ ] Add a `Hire Compensation` page with:
  - `HireCostPercent`
  - `EnableDaysWithRosterCompensation`
  - `DaysWithRosterFlatGoldPerDay`
  - `EnableLevelBracketCompensation`
  - `LevelBracketLowFlatGold`
  - `LevelBracketMidFlatGold`
  - `LevelBracketHighFlatGold`
- [ ] Set level-bracket defaults to:
  - levels `1-5` => `50`
  - levels `6-10` => `100`
  - levels `11+` => `200`
- [ ] Add an `Equipment Deduction` page with:
  - `EnableEquipmentDeduction`
  - `UseSellPriceForEquipmentDeduction`
  - `EquipmentValuePercent`
  - `CountHeadArmor`
  - `CountBodyArmor`
  - `CountMainhandWeapon`
  - `CountOffhand`
  - `CountAccessory`
  - `CountAmmo`
- [ ] Set `UseSellPriceForEquipmentDeduction` default to `true`.
- [ ] Add an `Injury Compensation` page with:
  - `PermanentInjuryFlatGold`
  - `TemporaryInjuryFlatGold`
- [ ] Add a `Dismissal Behaviors` page with `EnableExtraDismissalBehaviors`.
- [ ] Set defaults to match the approved design:
  - days contribution disabled by default
  - extra slot counts default false
  - extra behaviors enabled by default
- [ ] Add concise descriptions that explain player-facing impact, not internal implementation.

### Task 3: Isolate Compensation Calculation

**Files:**
- Create: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/compensation_calculator.nut`

**Interfaces:**
- Produces:
  - `::DismissalEnhanced.getHireCostContribution(_bro)`
  - `::DismissalEnhanced.getDaysContribution(_bro)`
  - `::DismissalEnhanced.getLevelContribution(_bro)`
  - `::DismissalEnhanced.getEquipmentDeduction(_bro)`
  - `::DismissalEnhanced.getPermanentInjuryContribution(_bro)`
  - `::DismissalEnhanced.getTemporaryInjuryContribution(_bro)`
  - `::DismissalEnhanced.getCompensationBreakdown(_bro)`
  - `::DismissalEnhanced.getCompensationCost(_bro)`
  - `::DismissalEnhanced.attachCompensationMethods(_bro)`

- [ ] Implement a helper to resolve the brother’s original hire cost or fallback source.
- [ ] Implement a helper that returns `0` when days contribution is disabled.
- [ ] Implement a helper that returns the configured flat amount for the brother’s level bracket:
  - levels `1-5`
  - levels `6-10`
  - levels `11+`
- [ ] Make the level contribution return `0` when `EnableLevelBracketCompensation` is disabled.
- [ ] Implement equipment-value aggregation by slot, respecting per-slot boolean settings.
- [ ] Use sell price as the default equipment deduction model and apply `EquipmentValuePercent`.
- [ ] Use `UseSellPriceForEquipmentDeduction == true` to choose `item.getSellPrice()`.
- [ ] Use `UseSellPriceForEquipmentDeduction == false` to choose `item.getValue()`.
- [ ] Implement permanent injury counting based on skill queries.
- [ ] Implement temporary injury counting based on skill queries.
- [ ] Clamp final compensation with `MinimumCompensationFloor`.
- [ ] Return a stable breakdown table so UI and dismissal logic consume the same computed source.
- [ ] Implement `::DismissalEnhanced.attachCompensationMethods(_bro)` so player brothers get `getCompensationCost()` when missing.
- [ ] Make `bro.getCompensationCost()` call `::DismissalEnhanced.getCompensationCost(this)`.

### Task 4: Add UI Data Injection

**Files:**
- Create: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/ui_hooks.nut`

**Interfaces:**
- Consumes:
  - `::DismissalEnhanced.getCompensationBreakdown(_bro)`
  - `::DismissalEnhanced.getCompensationCost(_bro)`
  - `::DismissalEnhanced.attachCompensationMethods(_bro)`
- Produces UI fields:
  - `compensationCost`
  - `compensationBreakdown`
  - `compensationBreakdownLines`
  - `showCompensationCheckbox`

- [ ] Implement UI data injection with modern `mod.hook(...)`.
- [ ] Hook the narrowest available UI data conversion path that already carries selected-brother data.
- [ ] Inject compensation only for player brothers.
- [ ] Before injecting UI fields, call `::DismissalEnhanced.attachCompensationMethods(_entity)`.
- [ ] Ensure the hook does not mutate tactical non-player entities.
- [ ] Set `target.compensationCost` from `_entity.getCompensationCost()` to use the compatibility entity method path.
- [ ] Set `target.compensationBreakdown` from `::DismissalEnhanced.getCompensationBreakdown(_entity)`.
- [ ] Set `target.compensationBreakdownLines` from `::DismissalEnhanced.getCompensationBreakdownLines(_entity)`.
- [ ] Set `target.showCompensationCheckbox` from `EnableCompensationPaymentCheckbox`.

### Task 5: Implement Dismissal Flow Around Settings

**Files:**
- Create: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/dismiss_hooks.nut`

**Interfaces:**
- Consumes:
  - `::DismissalEnhanced.attachCompensationMethods(_bro)`
  - `bro.getCompensationCost()`
  - `EnableExtraDismissalBehaviors`
- Produces:
  - hooked `onDismissCharacter`

- [ ] Use vanilla dismissal and the legacy reference to design the focused dismiss hook; do not port the legacy hook blindly.
- [ ] After resolving `bro`, call `::DismissalEnhanced.attachCompensationMethods(bro)` before any compensation read.
- [ ] Separate structural dismissal steps from optional extra behaviors.
- [ ] Keep these structural steps always on:
  - `bro.getSkills().onDismiss()`
  - required statistics updates for dismissed brothers
  - money removal when compensation is paid
  - item transfer to stash
  - roster removal
  - screen/topbar refresh
- [ ] Put these behind `EnableExtraDismissalBehaviors`:
  - slave compensated-dismissal mood effects
  - dismissal news generation
  - roster-wide mood penalties for dismissing brothers
- [ ] Verify that disabling extra behaviors does not break scenario-specific bookkeeping such as manhunter indebted tracking.
- [ ] Deduct money with `this.World.Assets.addMoney(-bro.getCompensationCost())` so payment uses the same compatibility API as UI-facing code.

### Task 6: Update the Dismiss Dialog Presentation

**Files:**
- Create: `mod_dismissal_enhanced/ui/mods/dismissal_enhanced.js`

**Interfaces:**
- Consumes:
  - `selectedBrother.compensationCost`
  - `selectedBrother.compensationBreakdown`
  - `selectedBrother.compensationBreakdownLines`
  - `selectedBrother.showCompensationCheckbox`
  - `EnableCompensationPaymentCheckbox`
- Produces:
  - dismiss popup with mandatory visible formula breakdown

- [ ] Minimize the JS surface area that differs from vanilla.
- [ ] Register `ui/mods/dismissal_enhanced.js` from the loader with `::Hooks.registerJS("ui/mods/dismissal_enhanced.js")`.
- [ ] Keep the final dialog centered on the existing dismiss flow.
- [ ] Make the dialog show the final compensation number from backend data.
- [ ] Add a visible breakdown block inside the dismiss dialog that explains:
  - hire-cost contribution
  - days contribution when enabled
  - level contribution when enabled
  - injury contributions
  - equipment deduction when enabled
  - final result
- [ ] Do not rely on tooltip-only disclosure for formula explanation.
- [ ] Respect `EnableCompensationPaymentCheckbox`; if disabled, remove or lock the checkbox path cleanly.
- [ ] Keep existing wording differences for compensation vs reparations if still desired; otherwise standardize and document the chosen copy.

### Task 7: Remove Formula Drift Between UI and Payment

**Files:**
- Modify: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/compensation_calculator.nut`
- Modify: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/ui_hooks.nut`
- Modify: `mod_dismissal_enhanced/scripts/mod_dismissal_enhanced/dismiss_hooks.nut`

**Interfaces:**
- Consumes: shared helper outputs
- Produces: single-source-of-truth compensation behavior

- [ ] Ensure the dialog preview amount uses `target.compensationCost`, which was produced from `_entity.getCompensationCost()`.
- [ ] Ensure the actual deducted amount uses `bro.getCompensationCost()`.
- [ ] Ensure the preview breakdown and the charged amount come from the same `getCompensationBreakdown(_bro)` source.
- [ ] Avoid duplicate formula logic in JS.
- [ ] Document in code comments that calculation changes should only happen in the calculator helper.
- [ ] Verify `::DismissalEnhanced.getCompensationCost(_bro)`, `bro.getCompensationCost()`, and `target.compensationCost` produce the same value for the same brother.

### Task 8: Validation Pass

**Files:**
- Modify: `mod_dismissal_enhanced/docs/superpowers/specs/2026-07-24-fired-cheaper-comparison.md`
- Modify: `mod_dismissal_enhanced/docs/superpowers/plans/2026-07-24-fired-cheaper-modernization.md`

**Interfaces:**
- Consumes: completed implementation
- Produces: verified documentation

- [ ] Verify mod loads with MSU available and settings pages appear.
- [ ] Verify dismiss dialog opens for a normal brother and a slave brother.
- [ ] Verify default settings match the approved gameplay design.
- [ ] Verify toggling `EnableExtraDismissalBehaviors` changes only grouped side effects, not core dismissal completion.
- [ ] Verify equipment deduction slot toggles affect the final value as expected.
- [ ] Verify disabled `DaysWithRoster` contributes `0`.
- [ ] Verify the final UI amount matches the actual money deducted.
- [ ] Verify `bro.getCompensationCost()` exists after opening the character screen and after opening BBRoster-style roster views.
- [ ] Verify no runtime path throws `the index 'getCompensationCost' does not exist`.
- [ ] Update docs if any implementation-driven constraint changed during execution.

## Self-Review

### Spec Coverage

- MSU + Modern Hooks setup: covered by Tasks 1 and 2
- configurable formula: covered by Tasks 2 and 3
- `bro.getCompensationCost()` compatibility API: covered by Tasks 3, 4, 5, and 8
- UI final tooltip/dialog amount: covered by Tasks 4 and 6
- grouped extra behaviors master toggle: covered by Task 5
- keep current behavior by default: covered by Tasks 2, 5, and 8

### Placeholder Scan

No `TODO` or deferred implementation markers should be introduced during execution unless they are explicitly converted into a documented follow-up item.

### Type and Naming Consistency

The plan standardizes on:

- namespace: `::DismissalEnhanced`
- settings entrypoint: `::DismissalEnhanced.registerSettings()`
- compensation helpers:
  - `getCompensationBreakdown`
  - `getCompensationCost`
- entity compatibility method:
  - `bro.getCompensationCost()`
  - `::DismissalEnhanced.attachCompensationMethods(_bro)`

Any implementation should keep these names stable unless the docs are updated in the same task.
