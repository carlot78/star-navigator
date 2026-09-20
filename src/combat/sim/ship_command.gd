class_name ShipCommand
extends RefCounted
## What a pilot (player or AI) wants a ship to do during the next tick.
## Pure data; both the touch controls and ShipAI produce one of these.

## World-space direction to travel, length 0..1 = throttle.
var move: Vector2 = Vector2.ZERO
## World-space direction to point the bow at; ZERO means face the move direction.
var face: Vector2 = Vector2.ZERO
## World point the weapons aim at.
var aim: Vector2 = Vector2.ZERO
var fire: bool = false
var shield: bool = false
var vent: bool = false
