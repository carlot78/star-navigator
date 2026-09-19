# Star Navigator — Requirements

Status: **living document**. Requirements get an ID once, are never renumbered, and
are marked *done* with the milestone that shipped them. Change history is the git log.

## 1. Vision

Star Navigator is a single-player, touch-first space RPG/strategy game for phones,
inspired by the open-sector gameplay of *Starsector* (Fractal Softworks): you captain
a small fleet in a procedurally generated sector, fight real-time top-down battles,
refit your ships, trade between markets, take on missions for factions, explore
derelicts, and eventually found colonies of your own.

The mobile constraint shapes everything: a session must be satisfying in 5–15
minutes, every action must work with one thumb on a 6-inch screen, and the game
must survive being interrupted at any moment.

**Owner requirements (verbatim):**

- **R1** — "I want to create a version for mobile of the game Star Sector"
- **R2** — "I want to create it progressively"

R1 is delivered as an *original game inspired by* Starsector — see §7 (Intellectual
property). R2 is delivered by the milestone plan in [ROADMAP.md](ROADMAP.md): every
milestone leaves a playable, installable build.

## 2. Scope

| | In scope | Out of scope (for now) |
| --- | --- | --- |
| Platforms | Android (first), iOS (second); Web export for playtesting only | Desktop as a product (it stays a dev convenience) |
| Players | Single player, offline | Multiplayer, leaderboards, cloud saves |
| Content | Procedurally generated sector with hand-authored factions, hulls, weapons | Scripted main storyline (later, see §6) |
| Business | Free, open-source (MIT), no ads, no IAP | Monetisation of any kind |
| Modding | Content is data files (see NFR-8) | A public modding API |

## 3. Player and session model

- **Player** — someone who enjoys strategy/RPG depth (fleet building, trade routes,
  reputation) and wants it on a phone without a keyboard and mouse. Comfortable with
  systems, impatient with clunky touch controls.
- **Session** — 5–15 minutes, often interrupted (phone call, train stop). The game is
  paused whenever the app loses focus and autosaves at every safe point, so nothing
  meaningful is ever lost.
- **Play posture** — landscape, two thumbs in combat (left: movement, right: aim/fire
  or tap-to-target), one thumb on the campaign map.

## 4. Functional requirements

Priority uses MoSCoW: **M** must, **S** should, **C** could. Milestone is where the
requirement is first delivered (see [ROADMAP.md](ROADMAP.md)).

### 4.1 Campaign (sector and travel)

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-CMP-1 | A new game generates a sector from a seed: 8–20 star systems with planets, stations, jump points and a hyperspace layer connecting them. The same seed produces the same sector. | M | M4 |
| FR-CMP-2 | The player fleet moves through a star system in real time by touching a destination (tap-to-move) or dragging a course; the camera follows the fleet and can be pinched to zoom. | M | M1 (single ship), M4 (fleet) |
| FR-CMP-3 | Campaign time advances while the fleet moves and pauses when it is idle or a menu is open; a day counter is visible. | M | M4 |
| FR-CMP-4 | Travelling between systems consumes fuel; sustaining the fleet consumes supplies per day; running out has consequences (slow, then damage). | M | M4 |
| FR-CMP-5 | Other fleets (patrols, traders, pirates) move in the system with their own goals; approaching one opens an encounter dialog (talk / fight / leave). | M | M4 |
| FR-CMP-6 | Hyperspace travel between systems via jump points, with hazards (storms) that push or damage the fleet. | S | M9 |
| FR-CMP-7 | Docking at a planet or station opens the location menu (market, refit, missions, bar). | M | M6 |
| FR-CMP-8 | Sensors: fleets are seen only within sensor range; larger fleets are seen from farther away; a "go dark" toggle trades speed for stealth. | S | M7 |

### 4.2 Combat

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-CBT-1 | Battles are real-time, top-down, in a bounded arena; the player pilots one flagship with a virtual joystick (movement) and a fire button/tap-to-target (weapons). | M | M2 |
| FR-CBT-2 | Ships have hull points, armour (per-cell or per-side damage reduction), shields (an arc that absorbs damage as flux) and a flux pool with dissipation; reaching max flux overloads the ship for a few seconds. | M | M2 |
| FR-CBT-3 | Weapons have size, mount type, damage, damage type (kinetic ×2 vs shields, high-explosive ×2 vs armour, energy neutral, fragmentation weak vs both), range, refire delay and flux cost. | M | M2 |
| FR-CBT-4 | Enemy ships are driven by an AI that manages range, shields and flux and that can be told to aggressively engage, hold or retreat. | M | M2 (1 ship), M3 (fleet) |
| FR-CBT-5 | Fleet battles: both sides deploy several ships; the player issues simple orders to allies (engage target, defend point, retreat) through a pause-able command view. | M | M3 |
| FR-CBT-6 | A battle ends in victory, defeat or retreat; the result (losses, damage, salvage) flows back to the campaign. | M | M2 |
| FR-CBT-7 | Fighter wings launched from carriers, with their own AI. | C | M8 |
| FR-CBT-8 | Ship systems (one active ability per hull: burn drive, phase skimmer, flare launcher…) on a cooldown, triggered by a button. | S | M5 |
| FR-CBT-9 | Combat can be paused at any time; losing app focus pauses automatically. | M | M2 |

### 4.3 Fleet and refit

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-FLT-1 | The fleet is a list of ship instances, each a hull with fitted weapons, hull modifications, crew and current damage. | M | M5 |
| FR-FLT-2 | Refit screen: drag weapons into compatible slots (size and mount type), within the hull's ordnance points; add/remove hull modifications; save variants. | M | M5 |
| FR-FLT-3 | Damage persists after battle; repairs cost supplies and time. | M | M5 |
| FR-FLT-4 | Salvage after a won battle: recover weapons and sometimes a disabled hull. | S | M5 |
| FR-FLT-5 | Crew and officers: officers have skills that buff the ship they command; crew is a logistics resource. | S | M8 |
| FR-FLT-6 | Buy and sell ships at markets. | M | M6 |

### 4.4 Economy and missions

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-ECO-1 | Markets sell and buy commodities (food, ore, metals, fuel, supplies, drugs…) with prices driven by local supply and demand and a global baseline. | M | M6 |
| FR-ECO-2 | Cargo capacity limits what a fleet can carry; illegal goods risk inspection by patrols. | S | M6 / M7 |
| FR-ECO-3 | Missions: bounties (destroy a fleet), deliveries (cargo A → B by a deadline), surveys (visit a location); rewards in credits and reputation. | M | M6 |
| FR-ECO-4 | Credits are the single currency; the player starts with a small fleet and a small amount. | M | M4 |
| FR-ECO-5 | Markets react to events: a destroyed trade fleet raises prices; a player selling a lot lowers them. | C | M7 |

### 4.5 Factions and reputation

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-FAC-1 | 4–6 factions with distinct colours, hull pools, home systems and relations to each other. | M | M7 |
| FR-FAC-2 | Player reputation with each faction (−100…100) changes with actions (missions, attacks, smuggling) and gates docking, prices and missions. | M | M7 |
| FR-FAC-3 | Hostile factions send patrols after a player with low reputation. | S | M7 |

### 4.6 Progression

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-PRG-1 | Experience from battles and missions; levels unlock skill points spent in a small skill tree (combat, leadership, technology, industry). | M | M8 |
| FR-PRG-2 | Officers are recruited at bars and levelled with the fleet. | S | M8 |

### 4.7 Exploration

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-EXP-1 | Unexplored systems hold derelict ships, debris fields and ruins that can be surveyed or salvaged for loot. | S | M9 |
| FR-EXP-2 | Planet surveys reveal resources and hazards and determine colony suitability. | S | M9 |
| FR-EXP-3 | A sector map shows discovered systems, known markets and mission targets. | M | M4 |

### 4.8 Colonies

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-COL-1 | The player can found a colony on a surveyed planet, build industries, and receive income; colonies attract raids and expeditions. | C | M10 |

### 4.9 Mobile UX

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-UX-1 | All interaction works with touch alone: minimum touch target 48 dp, no hover-only information, no keyboard needed. | M | M1 |
| FR-UX-2 | Two selectable combat control schemes: virtual joystick + fire button, and tap-to-move + tap-to-target. | M | M2 |
| FR-UX-3 | Landscape orientation; UI respects the display safe area (notches, rounded corners). | M | M1 |
| FR-UX-4 | Tutorial: the first battle and the first docking are guided by short, dismissible hints. | S | M11 |
| FR-UX-5 | Settings: master/music/sfx volume, control scheme, UI scale, haptics. | M | M1 |
| FR-UX-6 | Every screen has an obvious way back; the Android back gesture behaves like the screen's back control. | M | M1 |

### 4.10 Persistence

| ID | Requirement | Pri | Milestone |
| --- | --- | --- | --- |
| FR-SAV-1 | Autosave on every safe transition (dock, undock, battle end, scene change, app going to background). | M | M0 (mechanism), M4 (all triggers) |
| FR-SAV-2 | Three manual save slots plus the autosave; load from the title screen. | S | M4 |
| FR-SAV-3 | Saves are versioned and migrated forward; a save from any released build loads in every later build. | M | M0 |
| FR-SAV-4 | A corrupt or unreadable save is reported, never crashes the game, and does not block starting a new game. | M | M4 |

## 5. Non-functional requirements

| ID | Requirement | How it is checked |
| --- | --- | --- |
| NFR-1 | **Performance.** 60 fps in campaign and ≥ 45 fps in a 10-vs-10 frigate/destroyer battle on a 2021 mid-range Android phone (reference: Snapdragon 7-series class, 4 GB RAM). | Frame-time overlay in debug builds; a fixed benchmark battle scene in `tests/`. |
| NFR-2 | **Startup.** Cold start to title screen under 3 s; title to campaign under 2 s. | Stopwatch on the reference device at every milestone. |
| NFR-3 | **Install size.** APK/AAB under 100 MB. | CI prints the export size. |
| NFR-4 | **Battery and heat.** Frame rate capped at 60; campaign renders on demand where possible; no background processing. | Godot `max_fps`; manual thermal check on long sessions. |
| NFR-5 | **Interruptibility.** Losing focus pauses and autosaves within 200 ms; killing the app loses at most the actions since the last safe transition. | Manual test: swipe-kill mid-battle and reopen. |
| NFR-6 | **Deterministic simulation.** Sector generation and combat resolution depend only on the seed and inputs (fixed timestep, seeded RNG); no wall-clock dependence in game logic. | Unit tests replay a seed and compare. |
| NFR-7 | **Offline and private.** No network access, no accounts, no analytics, no permissions beyond storage of its own files. | Android manifest review at each release. |
| NFR-8 | **Data-driven content.** Hulls, weapons, factions, commodities and missions are Godot Resources / JSON under `data/`; adding content never requires code changes. | Code review rule; `DataRegistry` loads by folder. |
| NFR-9 | **Testability.** Game rules (flux, damage, pricing, generation, migrations) are pure GDScript classes with no scene dependency and have unit tests. | gdUnit4 in CI from M2. |
| NFR-10 | **Accessibility.** UI text at least 14 dp, colour is never the only carrier of information (faction colours are paired with icons/labels), UI scale setting 0.8–1.4. | Design checklist per screen. |
| NFR-11 | **Localisation-ready.** All player-facing strings go through Godot's `tr()`; English is the source language. | Lint: no literal UI strings in `.tscn` after M11. |
| NFR-12 | **Licensing.** Code MIT; every asset original or under a redistributable licence, credited in `CREDITS.md`. | PR checklist. |

## 6. Out of scope and known limitations

- **No storyline campaign** in the current plan; missions are procedural. A scripted arc can be layered on the mission system later.
- **No multiplayer, cloud saves or accounts.** Saves are local files; a device change means starting over (an export/import of the save file is a possible later convenience).
- **iOS distribution needs a Mac and an Apple developer account**; until then iOS is built only for personal devices.
- **Web export** exists for quick playtests on a phone browser; it is not a supported platform (no persistent saves guarantee, lower performance).
- **Scale is deliberately smaller than the inspiration**: fewer systems, smaller fleets, fewer hull sizes on screen. The design goal is depth per minute, not breadth.

## 7. Intellectual property

Starsector is the property of Fractal Softworks. Star Navigator is an independent,
original work *inspired by its design*; it must not:

- use the Starsector name, logo, ship/faction/character names, lore text, art, audio, data files or code;
- present itself as a port, remake or official companion.

Game mechanics as ideas (flux, armour cells, ordnance points, sector generation) are
not protected and may be reimplemented from scratch. All names in this repository
(hulls such as *Kestrel*, factions such as *Independents*) are original placeholders
and are replaced by original names as content is authored.

## 8. Glossary

| Term | Meaning |
| --- | --- |
| Sector | The whole generated game world: star systems plus hyperspace. |
| System | One star with its bodies, stations and jump points; the campaign flight arena. |
| Hyperspace | The layer connecting systems; entered and left at jump points. |
| Hull | A ship type (static data). |
| Ship instance | One concrete ship in a fleet (hull + fit + state). |
| Fit / variant | The set of weapons and hull modifications on a ship instance. |
| Flux | Heat-like resource produced by firing and by shields; dissipates over time; overflow overloads the ship. |
| Ordnance points (OP) | Budget a hull has for weapons and hull modifications. |
| Market | The trading post of a planet or station. |
| Reputation | The player's standing with a faction, −100…100. |
| Milestone | A planned increment in [ROADMAP.md](ROADMAP.md) that ends in a playable build. |
