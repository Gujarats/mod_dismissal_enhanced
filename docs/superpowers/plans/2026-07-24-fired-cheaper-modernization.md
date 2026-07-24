# Fired Cheaper Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `mod_fired_cheaper` to MSU and modern Hooks, replace the current compensation formula with configurable settings-driven logic, and keep extra dismissal behaviors grouped behind one master option.

**Architecture:** Split the current monolithic preload script into a small MSU loader, a settings registration module, a compensation helper, and focused hook files for UI data injection and dismissal flow. Keep the current dismiss dialog experience, but drive both the computed amount and mandatory on-dialog breakdown display from explicit MSU settings.

**Tech Stack:** Squirrel mod scripts, Hooks, MSU Mod Settings, Battle Brothers UI JS integration.

## Global Constraints

- Use `mod_fired_cheaper` as the project root.
- Do not modify `data_001`.
- Do not modify unrelated community mods.
- Preserve current behavior by default where requested.
- Prefer MSU settings over hard-coded constants.
- Keep formula settings granular.
- Use one master toggle for grouped extra dismissal behaviors.
- Group settings by context in separate MSU pages.
- The firing menu must show the compensation breakdown directly; tooltip-only presentation is insufficient.

---

## File Structure

### Create

- `scripts/!mods_preload/mod_fired_cheaper_loader.nut`
  - MSU registration, hook queue, JS/CSS registration if needed
- `scripts/!mods_preload/mod_fired_cheaper_settings.nut`
  - all MSU settings registration
- `scripts/mod_fired_cheaper/compensation_calculator.nut`
  - helper functions for each compensation component and final result
- `scripts/mod_fired_cheaper/dismiss_hooks.nut`
  - dismissal flow hook and grouped extra behavior gating
- `scripts/mod_fired_cheaper/ui_hooks.nut`
  - UI data injection and tooltip/popup preview support
- `docs/superpowers/specs/2026-07-24-fired-cheaper-comparison.md`
  - comparison/spec reference
- `docs/superpowers/plans/2026-07-24-fired-cheaper-modernization.md`
  - this plan

### Modify

- `scripts/!mods_preload/mod_fairCompensation.nut`
  - either remove legacy bootstrap logic or convert into a thin compatibility include
- `ui/screens/character/modules/character_screen_left_panel/character_screen_left_panel_header_module.js`
  - limit edits to reading and displaying richer compensation breakdown data, unless a narrower JS patch strategy is proven viable

### Optional Create

- `ui/mods/fired_cheaper.js`
  - only if direct JS registration is cleaner than replacing the existing file

## Settings Contract

The implementation should standardize on these setting keys:

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
- `EnableExtraDismissalBehaviors`

## Data Contract

The UI hook should inject a stable structure for the dismiss dialog:

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

### Task 1: Replace Legacy Bootstrap With MSU Loader

**Files:**
- Create: `mod_fired_cheaper/scripts/!mods_preload/mod_fired_cheaper_loader.nut`
- Create: `mod_fired_cheaper/scripts/!mods_preload/mod_fired_cheaper_settings.nut`
- Modify: `mod_fired_cheaper/scripts/!mods_preload/mod_fairCompensation.nut`

**Interfaces:**
- Consumes: existing mod ID, version, and name from current preload script
- Produces:
  - `::FiredCheaper`
  - `::FiredCheaper.HookMod`
  - `::FiredCheaper.Mod`
  - `::FiredCheaper.registerSettings()`

- [ ] Audit the current preload file and extract the canonical mod identity fields used today.
- [ ] Create `mod_fired_cheaper_loader.nut` with `::Hooks.register(...)`, `require("mod_msu >= 1.9.0")`, and queue-after-MSU bootstrapping.
- [ ] Create `mod_fired_cheaper_settings.nut` with a `::FiredCheaper.registerSettings <- function() { ... }` entrypoint.
- [ ] Move bootstrap-only responsibilities out of `mod_fairCompensation.nut`.
- [ ] Decide whether `mod_fairCompensation.nut` becomes:
  - a compatibility include that forwards to new modules, or
  - a deprecated file left unused but documented
- [ ] Verify the final load path contains exactly one active bootstrap path.

### Task 2: Register Settings Pages and Defaults

**Files:**
- Modify: `mod_fired_cheaper/scripts/!mods_preload/mod_fired_cheaper_settings.nut`

**Interfaces:**
- Consumes: `::FiredCheaper.Mod.ModSettings`
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
  - `EquipmentPriceMode`
  - `EquipmentValuePercent`
  - `CountHeadArmor`
  - `CountBodyArmor`
  - `CountMainhandWeapon`
  - `CountOffhand`
  - `CountAccessory`
  - `CountAmmo`
- [ ] Set `EquipmentPriceMode` default to `SellPrice`.
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
- Create: `mod_fired_cheaper/scripts/mod_fired_cheaper/compensation_calculator.nut`

**Interfaces:**
- Produces:
  - `::FiredCheaper.getHireCostContribution(_bro)`
  - `::FiredCheaper.getDaysContribution(_bro)`
  - `::FiredCheaper.getLevelContribution(_bro)`
  - `::FiredCheaper.getEquipmentDeduction(_bro)`
  - `::FiredCheaper.getPermanentInjuryContribution(_bro)`
  - `::FiredCheaper.getTemporaryInjuryContribution(_bro)`
  - `::FiredCheaper.getCompensationBreakdown(_bro)`
  - `::FiredCheaper.getCompensationCost(_bro)`

- [ ] Implement a helper to resolve the brother’s original hire cost or fallback source.
- [ ] Implement a helper that returns `0` when days contribution is disabled.
- [ ] Implement a helper that returns the configured flat amount for the brother’s level bracket:
  - levels `1-5`
  - levels `6-10`
  - levels `11+`
- [ ] Make the level contribution return `0` when `EnableLevelBracketCompensation` is disabled.
- [ ] Implement equipment-value aggregation by slot, respecting per-slot boolean settings.
- [ ] Use sell price as the default equipment deduction model and apply `EquipmentValuePercent`.
- [ ] If `EquipmentPriceMode` supports multiple modes, keep `BasePrice` as an optional stricter alternative and document the switch clearly.
- [ ] Implement permanent injury counting based on skill queries.
- [ ] Implement temporary injury counting based on skill queries.
- [ ] Clamp final compensation with `MinimumCompensationFloor`.
- [ ] Return a stable breakdown table so UI and dismissal logic consume the same computed source.

### Task 4: Replace UI Data Injection

**Files:**
- Create: `mod_fired_cheaper/scripts/mod_fired_cheaper/ui_hooks.nut`

**Interfaces:**
- Consumes:
  - `::FiredCheaper.getCompensationBreakdown(_bro)`
  - `::FiredCheaper.getCompensationCost(_bro)`
- Produces UI fields:
  - `compensationCost`
  - `compensationBreakdown`

- [ ] Replace the legacy `mods_hookNewObjectOnce("ui/global/data_helper", ...)` flow with modern `mod.hook(...)`.
- [ ] Hook the narrowest available UI data conversion path that already carries selected-brother data.
- [ ] Inject compensation only for player brothers.
- [ ] Ensure the hook does not mutate tactical non-player entities.
- [ ] Keep the injected payload backward-compatible enough that the existing dismiss dialog can still read `compensationCost` during the transition.

### Task 5: Rework Dismissal Flow Around Settings

**Files:**
- Create: `mod_fired_cheaper/scripts/mod_fired_cheaper/dismiss_hooks.nut`

**Interfaces:**
- Consumes:
  - `::FiredCheaper.getCompensationCost(_bro)`
  - `EnableExtraDismissalBehaviors`
- Produces:
  - hooked `onDismissCharacter`

- [ ] Port the current dismiss hook from the legacy preload script into this focused file.
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

### Task 6: Update the Dismiss Dialog Presentation

**Files:**
- Modify: `mod_fired_cheaper/ui/screens/character/modules/character_screen_left_panel/character_screen_left_panel_header_module.js`
- Optional Create: `mod_fired_cheaper/ui/mods/fired_cheaper.js`

**Interfaces:**
- Consumes:
  - `selectedBrother.compensationCost`
  - `selectedBrother.compensationBreakdown`
  - `EnableCompensationPaymentCheckbox`
- Produces:
  - dismiss popup with mandatory visible formula breakdown

- [ ] Minimize the JS surface area that differs from vanilla.
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
- Modify: `mod_fired_cheaper/scripts/mod_fired_cheaper/compensation_calculator.nut`
- Modify: `mod_fired_cheaper/scripts/mod_fired_cheaper/ui_hooks.nut`
- Modify: `mod_fired_cheaper/scripts/mod_fired_cheaper/dismiss_hooks.nut`

**Interfaces:**
- Consumes: shared helper outputs
- Produces: single-source-of-truth compensation behavior

- [ ] Ensure the dialog preview amount and the actual deducted amount both use `::FiredCheaper.getCompensationCost(_bro)`.
- [ ] Ensure the preview breakdown and the charged amount come from the same `getCompensationBreakdown(_bro)` source.
- [ ] Avoid duplicate formula logic in JS.
- [ ] Document in code comments that calculation changes should only happen in the calculator helper.

### Task 8: Validation Pass

**Files:**
- Modify: `mod_fired_cheaper/docs/superpowers/specs/2026-07-24-fired-cheaper-comparison.md`
- Modify: `mod_fired_cheaper/docs/superpowers/plans/2026-07-24-fired-cheaper-modernization.md`

**Interfaces:**
- Consumes: completed implementation
- Produces: verified documentation

- [ ] Verify mod loads with MSU available and settings pages appear.
- [ ] Verify dismiss dialog opens for a normal brother and a slave brother.
- [ ] Verify default settings preserve current/original behavior as intended.
- [ ] Verify toggling `EnableExtraDismissalBehaviors` changes only grouped side effects, not core dismissal completion.
- [ ] Verify equipment deduction slot toggles affect the final value as expected.
- [ ] Verify disabled `DaysWithRoster` contributes `0`.
- [ ] Verify the final UI amount matches the actual money deducted.
- [ ] Update docs if any implementation-driven constraint changed during execution.

## Self-Review

### Spec Coverage

- MSU migration: covered by Tasks 1 and 2
- configurable formula: covered by Tasks 2 and 3
- UI final tooltip/dialog amount: covered by Tasks 4 and 6
- grouped extra behaviors master toggle: covered by Task 5
- keep current behavior by default: covered by Tasks 2, 5, and 8

### Placeholder Scan

No `TODO` or deferred implementation markers should be introduced during execution unless they are explicitly converted into a documented follow-up item.

### Type and Naming Consistency

The plan standardizes on:

- namespace: `::FiredCheaper`
- settings entrypoint: `::FiredCheaper.registerSettings()`
- compensation helpers:
  - `getCompensationBreakdown`
  - `getCompensationCost`

Any implementation should keep these names stable unless the docs are updated in the same task.
