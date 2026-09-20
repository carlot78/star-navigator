# Star Navigator

A touch-first space RPG/strategy game for phones: captain a small fleet in a
generated sector, fight real-time top-down battles, refit your ships, trade
between markets, work for factions and explore the unknown. An original game
inspired by the open-sector design of [Starsector](https://fractalsoftworks.com/)
(no assets, names or code from it are used — see
[docs/REQUIREMENTS.md §7](docs/REQUIREMENTS.md#7-intellectual-property)).

Built progressively, one playable milestone at a time. Latest milestone: **M2 —
Combat core** (1-vs-1 real-time battle with flux, shields, armour, six weapons, an AI
opponent, joystick or tap controls — try **Skirmish** on the title screen).
Next: **M3 — Fleet battles**.

**Play the latest build in a phone browser:** https://carlot78.github.io/star-navigator/
(published by CI on every push to `main`; landscape, add to home screen for full screen).

## Documents

| Document | What it holds |
| --- | --- |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Vision, scope, functional (`FR-*`) and non-functional (`NFR-*`) requirements with priority and milestone, IP rules, glossary |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technology decisions, repository layout, autoloads, model/view split, domain model, combat and campaign design, persistence, conventions |
| [docs/ROADMAP.md](docs/ROADMAP.md) | The milestone plan M0 → M11, definition of done, how to add a feature |

## Stack

- [Godot 4.7+](https://godotengine.org/), GDScript, GL Compatibility renderer, landscape.
- Content as Godot Resources under `data/`; saves as versioned JSON.
- CI: `gdlint`, headless unit tests (`tests/unit`) and smoke test (`tests/smoke.gd`), Web export to GitHub Pages, Android debug APK artifact.

## Run

1. Install Godot 4.7 or later (standard build, no .NET needed).
2. Open `project.godot` in the editor and press **Play** (F5). Mouse input is
   emulated as touch.
3. Headless checks without the editor: `godot --headless --path . --import`, then
   `godot --headless --path . -s res://tests/run_tests.gd` (unit tests) and
   `godot --headless --path . -s res://tests/smoke.gd` (boots every scene).
4. On a phone: open the GitHub Pages link above, or download the debug APK from the
   latest CI run (Actions → CI → artifacts), or use the editor.s one-click Android
   deploy (Editor → Export → Android, *Deploy with remote debug*).

## Layout

```
src/core      autoload singletons: EventBus, Settings, DataRegistry, GameState, SaveService, SceneRouter
src/data      Resource classes: HullData, WeaponSlotData, WeaponData, FactionData
src/campaign  star system view, ship movement model, camera, starfield
src/combat    battle scene, ship views, effects; sim/ is the pure combat model
src/fleet     ship instances, refit (M5)
src/economy   markets, missions (M6)
src/ui        title, pause, settings and battle-result screens; camera, starfield, joystick, theme
data/         content: one .tres per hull / weapon / faction
assets/       sprites, audio, fonts
tests/        unit tests (run_tests.gd + unit/) and the smoke test
```

## License

Code: [MIT](LICENSE) © 2026 Carlo Tuzi. Assets: see `CREDITS.md`.
