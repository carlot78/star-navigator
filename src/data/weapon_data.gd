class_name WeaponData
extends Resource
## Static definition of a weapon. One .tres per weapon under res://data/weapons/.

enum DamageType { KINETIC, HIGH_EXPLOSIVE, ENERGY, FRAGMENTATION }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var size: WeaponSlotData.Size = WeaponSlotData.Size.SMALL
@export var mount: WeaponSlotData.Mount = WeaponSlotData.Mount.BALLISTIC
@export var sprite: Texture2D

@export_group("Damage")
@export var damage: float = 50.0
@export var damage_type: DamageType = DamageType.KINETIC
@export var range: float = 600.0
@export var projectile_speed: float = 800.0
## Seconds between shots.
@export var refire_delay: float = 0.5
## 0 means unlimited ammunition.
@export var ammo: int = 0

@export_group("Cost")
@export var flux_per_shot: float = 40.0
@export var ordnance_cost: int = 4
@export var base_price: int = 1500
