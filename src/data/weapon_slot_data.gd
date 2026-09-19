class_name WeaponSlotData
extends Resource
## A hardpoint on a hull. A weapon fits if its size and mount type match.

enum Size { SMALL, MEDIUM, LARGE }
enum Mount { BALLISTIC, ENERGY, MISSILE, HYBRID, UNIVERSAL }

@export var id: String = ""
## Offset from the hull centre, in sprite pixels; ship faces +X.
@export var position: Vector2 = Vector2.ZERO
## Centre of the firing arc, degrees, 0 = forward.
@export var angle: float = 0.0
## Total width of the firing arc in degrees.
@export var arc: float = 90.0
@export var size: Size = Size.SMALL
@export var mount: Mount = Mount.BALLISTIC
