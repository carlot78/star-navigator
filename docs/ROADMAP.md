# Star Navigator — Roadmap

The game is built as a strict sequence of milestones. Each one ends with a build
that runs on a phone and is at least as playable as the previous one; nothing from
a later milestone starts before the current one's *definition of done* is met.
Requirement ids refer to [REQUIREMENTS.md](REQUIREMENTS.md); the structure every
milestone must respect is in [ARCHITECTURE.md](ARCHITECTURE.md).

## Overview

| # | Milestone | Playable result | Requirements | Status |
| --- | --- | --- | --- | --- |
| M0 | Foundation | Title screen → placeholder campaign → back, with autosave; CI lint | FR-SAV-1 (mechanism), FR-SAV-3, NFR-8 | ✅ done (2026-09-19) |
| M1 | Flying | Fly one ship around a star system with touch; settings; Web playtest build | FR-CMP-2 (single ship), FR-UX-1/3/5/6 | ✅ done (2026-09-20) |
| M2 | Combat core | 1-vs-1 battle: flux, shields, armour, weapons, AI, win/lose | FR-CBT-1/2/3/4/6/9, FR-UX-2, NFR-9 | ⬜ |
| M3 | Fleet battles | Several ships per side, orders, retreat; benchmark scene | FR-CBT-5, NFR-1 | ⬜ |
| M4 | Campaign | Generated sector, fleet travel, fuel/supplies, encounters that lead to battles, sector map, save slots | FR-CMP-1/3/4/5, FR-EXP-3, FR-ECO-4, FR-SAV-1/2/4 | ⬜ |
| M5 | Fleet & refit | Ship instances, refit screen, repairs, salvage, ship systems | FR-FLT-1/2/3/4, FR-CBT-8 | ⬜ |
| M6 | Economy | Markets, trade, docking menu, missions, buying ships | FR-CMP-7, FR-ECO-1/2/3, FR-FLT-6 | ⬜ |
| M7 | Factions | Factions, reputation, patrols, sensors, market events | FR-FAC-1/2/3, FR-CMP-8, FR-ECO-5 | ⬜ |
| M8 | Progression | Skills, officers, fighters | FR-PRG-1/2, FR-FLT-5, FR-CBT-7 | ⬜ |
| M9 | Exploration | Hyperspace, derelicts, surveys | FR-CMP-6, FR-EXP-1/2 | ⬜ |
| M10 | Colonies | Found and run a colony | FR-COL-1 | ⬜ |
| M11 | Release | Tutorial, audio, localisation pass, store builds | FR-UX-4, NFR-2/3/10/11/12 | ⬜ |

Rough sizing for a solo developer working part-time: M1–M3 about two to three
weeks each, M4 and M6 the largest (a month each), the rest two to four weeks each.
Sizes are guesses; the order is not.

## Definition of done (every milestone)

1. Every requirement listed for the milestone is implemented and marked *done* in
   REQUIREMENTS.md with the milestone number.
2. The build runs on the reference Android phone; the manual checklist below passes.
3. CI is green (lint; unit tests from M2; exports from M1).
4. `docs/ARCHITECTURE.md` is updated if the structure changed; new model classes
   appear in the domain model diagram.
5. Saves from the previous milestone still load (or `SAVE_VERSION` was bumped with a
   migration and a fixture test).
6. A git tag `m<N>` marks the milestone commit.

Manual checklist: cold start < 3 s · rotate the phone · background the app mid-action
and return · kill the app and reopen (state restored) · every screen has a back
control · nothing needs a hover or a keyboard.

## Milestones in detail

### M0 — Foundation ✅

Repository, documents, Godot project skeleton, six autoloads, Resource classes for
hulls/weapons/factions with one sample each, title screen, placeholder campaign
scene, autosave round-trip, `gdlint` CI.

### M1 — Flying ✅

Goal: the core feel of moving a ship on a phone, and the tooling to put a build on
the phone every day.

Shipped:

- `src/campaign/system/`: placeholder "home" system (star, two orbiting planets,
  boundary), procedural `CelestialBody`; `starfield.gd` (three tiling parallax layers
  generated at start-up); `campaign_camera.gd` (follow, pan, pinch/wheel zoom, recenter).
- `ship_mover.gd` (pure arrive-at-target model, stats from `HullData`) rendered by
  `player_ship.gd`; touch grammar in `campaign.gd`: tap = fly there, drag from the ship =
  course, drag elsewhere = pan, two fingers = zoom.
- `ui/settings_menu` bound to `Settings` (volumes, combat control scheme, UI scale,
  haptics), `ui/pause_menu` (resume / settings / save & quit), `ui/theme/theme.tres`
  (48 px buttons), `ui/safe_area.gd`.
- Android back and Escape routed through `EventBus.back_requested`; losing focus pauses
  and autosaves.
- `export_presets.cfg` (Web, Android); CI runs `gdlint`, the headless `tests/smoke.gd`,
  exports Web to GitHub Pages on every push to `main`, and uploads an Android debug APK
  (experimental, `continue-on-error`).
- Not done: on-device measurement of NFR-1/2 (needs the reference phone); the Android
  export job has not yet been verified on a device.

### M2 — Combat core

Goal: prove that combat is fun with a thumb. Everything after depends on this.

- `src/combat/sim/`: `CombatSim`, `ShipState`, `ProjectileState`,
  `DamageResolver` as pure classes; fixed-timestep `step(delta)`; unit tests for the
  flux/shield/armour maths and damage-type modifiers.
- `src/combat/combat.tscn`: arena, ship sprites mirroring the sim, projectiles,
  hit effects, HUD (flux bar, hull bar, weapon groups, shield toggle, pause).
- `VirtualJoystick` control and `TapTarget` mode, selectable in settings.
- `ShipAI` v1: keep range, shield when threatened, vent when safe, retreat under a
  hull threshold.
- Battle end → `BattleResult` → `EventBus.battle_ended`; a debug entry on the title
  screen launches a battle directly ("Skirmish") so combat can be iterated without
  the campaign.
- 3 hulls, 6 weapons in `data/`.
- gdUnit4 addon, CI runs tests headless. Tag `m2`.

### M3 — Fleet battles

- Deployment: each side fields several ships; the player picks the flagship.
- Command overlay: pause, tap an ally, tap an order (engage target / defend
  point / retreat); orders drive `ShipAI`.
- Retreat edge, victory/defeat conditions for fleets, result summary screen.
- `tests/benchmark_battle.tscn`: 10 v 10, frame-time overlay; NFR-1 measured on the
  reference phone and the number written into REQUIREMENTS.
- Projectile rendering through `MultiMeshInstance2D` if the benchmark demands it.
- Tag `m3`.

### M4 — Campaign

- `SectorGenerator` + `SectorModel`/`SystemModel`/`Body` models; unit test that a
  seed reproduces the same sector and that the hyperspace graph is connected.
- Player `FleetModel` (position, fuel, supplies, cargo) replacing the M1 single ship;
  travel between systems through jump points (instant transition for now, hyperspace
  flight comes in M9).
- `CampaignClock`, `day_passed`, supplies/fuel consumption, out-of-supplies effects.
- NPC fleets with `patrol` / `trade` / `hunt` goals; proximity → encounter dialog
  (talk / fight / leave) → `BattleContext` → Combat → result applied (losses,
  credits).
- Sector map overlay: discovered systems, current position, tap to set course.
- Save slots (3 + autosave), load from title, corrupt-save handling; all autosave
  triggers.
- Tag `m4`.

### M5 — Fleet & refit

- `ShipInstance` model (hull id, fitted weapons per slot, hullmods, hull fraction,
  crew) and `GameState.fleet` migration (`SAVE_VERSION` 2).
- Refit overlay: slot compatibility (size, mount), ordnance points, hullmods
  (5 to start), save/load variants; drag on touch with generous drop targets.
- Persistent damage after battle; repairs over time consuming supplies.
- Post-battle salvage: weapons from wrecks, chance of a recoverable hull.
- Ship systems (one per hull, cooldown, HUD button): 3 to start.
- Tag `m5`.

### M6 — Economy

- Commodities (10) and `Market` model with stock, supply/demand pricing and a
  daily drift toward baseline; unit tests for pricing.
- Docking menu overlay (FR-CMP-7): market (buy/sell with cargo limits), refit
  (from M5), ship dealer, mission board, bar.
- Missions: bounty, delivery, survey — generation, tracking, deadlines, rewards.
- Tag `m6`.

### M7 — Factions

- 5 factions in `data/`, home systems assigned by the generator, inter-faction
  relations.
- Reputation model, effects on docking, prices and mission availability; reputation
  changes from missions, attacks, smuggling.
- Patrols inspect cargo; illegal goods; hostile patrols hunt low-reputation players.
- Sensors and "go dark"; market events reacting to destroyed trade fleets.
- Tag `m7`.

### M8 — Progression

- XP, levels, skill tree (4 branches, 3 tiers); skill effects applied through a
  single `StatModifier` pipeline so hullmods, skills and officers compose.
- Officers: recruit at bars, assign to ships, level up.
- Carriers and fighter wings with their own AI.
- Tag `m8`.

### M9 — Exploration

- Hyperspace as a flyable layer with storms; jump-point transitions in both
  directions.
- Derelicts, debris fields and ruins in unexplored systems; salvage and survey
  actions; planet surveys with resource/hazard results.
- Tag `m9`.

### M10 — Colonies

- Found a colony on a surveyed planet; 4 industries; income; growth; raids and
  expeditions as campaign events.
- Tag `m10`.

### M11 — Release

- Tutorial hints, full audio pass (music per mode, SFX), `tr()` on every string,
  accessibility check (UI scale, colour + icon), store listing assets, signed Android
  release build, iOS build for personal devices, `CREDITS.md` complete.
- Tag `v1.0.0`.

## Adding a feature (any milestone)

1. Find or add its `FR-`/`NFR-` id in REQUIREMENTS.md.
2. Model first: a pure class under the domain folder with a unit test if it holds a
   rule.
3. Content second: new `.tres` under `data/` if the feature needs data.
4. View last: scene under the domain or `ui/`, reading the model, emitting through
   `EventBus`.
5. If the save shape changed: bump `SAVE_VERSION`, add a migration arm and a fixture.
6. Update the ARCHITECTURE diagrams if a new model class or scene appeared.
7. Play it on the phone before merging.
