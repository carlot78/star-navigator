# Star Navigator

A touch-first space RPG/strategy game for phones: captain a small fleet in a
generated sector, fight real-time top-down battles, refit your ships, trade
between markets, work for factions and explore the unknown. An original game
inspired by the open-sector design of [Starsector](https://fractalsoftworks.com/)
(no assets, names or code from it are used — see
[docs/REQUIREMENTS.md §7](docs/REQUIREMENTS.md#7-intellectual-property)).

Built progressively, one playable milestone at a time. Current milestone: **M0 —
Foundation** (project skeleton, documents, autosave round-trip).

## Documents

| Document | What it holds |
| --- | --- |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Vision, scope, functional (`FR-*`) and non-functional (`NFR-*`) requirements with priority and milestone, IP rules, glossary |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technology decisions, repository layout, autoloads, model/view split, domain model, combat and campaign design, persistence, conventions |
| [docs/ROADMAP.md](docs/ROADMAP.md) | The milestone plan M0 → M11, definition of done, how to add a feature |

## Stack

- [Godot 4.4+](https://godotengine.org/), GDScript, GL Compatibility renderer, landscape.
- Content as Godot Resources under `data/`; saves as versioned JSON.
- CI: `gdlint`; Web playtest export and Android builds arrive in M1.

## Run

1. Install Godot 4.4 or later (standard build, no .NET needed).
2. Open `project.godot` in the editor and press **Play** (F5). Mouse input is
   emulated as touch.
3. To try it on a phone: from M1 a Web build is published on every push to `main`;
   until then use the editor's one-click Android deploy (Editor → Export → Android,
   *Deploy with remote debug*).

## Layout

```
src/core      autoload singletons: EventBus, Settings, DataRegistry, GameState, SaveService, SceneRouter
src/data      Resource classes: HullData, WeaponSlotData, WeaponData, FactionData
src/campaign  star system view, travel, encounters
src/combat    battles (M2)
src/fleet     ship instances, refit (M5)
src/economy   markets, missions (M6)
src/ui        screens and theme
data/         content: one .tres per hull / weapon / faction
assets/       sprites, audio, fonts
tests/        gdUnit4 tests (M2)
```

## License

Code: [MIT](LICENSE) © 2026 Carlo Tuzi. Assets: see `CREDITS.md`.
