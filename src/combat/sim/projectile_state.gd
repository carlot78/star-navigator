class_name ProjectileState
extends RefCounted
## A shot in flight. Kinematic only; CombatSim moves it and tests it against
## enemy hulls each tick.

var position: Vector2
var velocity: Vector2
var damage: float
var damage_type: WeaponData.DamageType
var side: int
var owner_id: int
## Seconds of flight left before the shot fades (range / speed).
var life: float
var radius: float = 3.0
var alive: bool = true
