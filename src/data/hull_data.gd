class_name HullData
extends Resource
## Static definition of a ship hull: the chassis every ship of that type is
## built on. Per-ship state (current hull points, fitted weapons) lives in a
## ShipInstance, not here. One .tres per hull under res://data/hulls/.

enum Size { FRIGATE, DESTROYER, CRUISER, CAPITAL }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var size: Size = Size.FRIGATE
@export var sprite: Texture2D

@export_group("Durability")
@export var hull_points: float = 1000.0
@export var armor: float = 100.0

@export_group("Flux")
@export var max_flux: float = 2000.0
@export var flux_dissipation: float = 150.0
@export var shield_arc: float = 180.0
## Damage taken by the shield is multiplied by this before becoming flux.
@export var shield_efficiency: float = 1.0

@export_group("Mobility")
@export var max_speed: float = 120.0
@export var acceleration: float = 80.0
@export var turn_rate: float = 60.0

@export_group("Outfitting")
@export var ordnance_points: int = 40
@export var weapon_slots: Array[WeaponSlotData] = []

@export_group("Logistics")
@export var crew: int = 20
@export var fuel_per_jump: float = 1.0
@export var supplies_per_month: float = 2.0
@export var cargo: int = 30
@export var base_price: int = 20000
