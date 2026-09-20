# Star Navigator — working notes for Claude

Godot 4.7 / GDScript mobile game. Read `docs/ARCHITECTURE.md` before touching
structure and `docs/ROADMAP.md` before starting a feature; the current milestone is
the first one without ✅ in the roadmap overview table.

## Rules that are easy to break

- Content (hull/weapon/faction numbers) goes in `data/*.tres`, never in scripts.
- Domains (`campaign`, `combat`, `fleet`, `economy`) never import each other's
  scenes; they use `EventBus` signals or `GameState`.
- Game rules are pure classes (no `Node`), testable headless; scenes only render and
  forward input.
- Changing `GameState.to_dict()` shape ⇒ bump `SAVE_VERSION` and add a migration arm
  in `SaveService._migrate()`.
- Autoload scripts must not declare `class_name` (Godot forbids the clash). A
  `class_name` must not shadow an engine class either (Godot 4.7 has a native
  `VirtualJoystick`; ours is `TouchJoystick`).
- Connect signals in `_ready()` in code, not inside `.tscn` files.
- Every new requirement gets an `FR-`/`NFR-` id in `docs/REQUIREMENTS.md`; mark it
  done with the milestone when shipped.
- Original names only (see REQUIREMENTS §7) — nothing from Starsector.

## Style

GDScript style guide: tabs, static typing everywhere, `## ` doc comments on classes
and public methods, enums before consts before vars (gdlint `class-definitions-order`),
max line length 120. `gdlint src tests` runs in CI.

## Godot on this machine

Godot 4.7.2 is at `F:\APPS\GODOT\Godot_v4.7.2-stable_win64_console.exe` (not on PATH).
Useful headless commands from the project root:

- `--headless --import` — validate scenes, resources and script classes
- `--headless --quit-after 180` — boot the main scene for a few frames
- `--headless -s res://tests/run_tests.gd` — unit tests (`tests/unit/test_*.gd` extend
  `TestCase`); add a test file per new model class.
- `--headless -s res://tests/smoke.gd` — boots every scene; extend it when adding a scene. In `-s` scripts autoloads are reached with
  `root.get_node("GameState")`, not by name.
- `-s` with a script that saves `get_viewport().get_texture().get_image()` (no
  `--headless`) is the way to look at a scene: a window opens for a second.

Commit the `.uid` and `.import` files the editor generates.
