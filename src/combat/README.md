# combat/

Real-time tactical battles. Owns the battle scene, ship controllers, weapons,
projectiles, shields/flux, damage resolution and ship AI. Receives a battle
context from the campaign through `EventBus.battle_started` and returns a
result through `EventBus.battle_ended`; it never touches campaign scenes
directly. Arrives in milestone M2 (see `docs/ROADMAP.md`).
