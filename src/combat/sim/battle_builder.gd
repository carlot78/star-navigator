class_name BattleBuilder
extends RefCounted
## Turns a battle context into ships in a CombatSim, deployed in columns on
## each side's half of the arena. Pure: hulls and weapons are resolved through
## the lookups passed in (DataRegistry in the game, builders in tests).
##
## Context shape (GameState.battle):
##   {"player": [spec...], "enemy": [spec...], "arena": [w, h] (optional)}
##   spec = {"hull": id, "fit": {slot_id: weapon_id}, "count": n (optional, default 1)}

const DEFAULT_ARENA := Vector2(2400.0, 1600.0)
## Distance of the first deployment column from the arena edge.
const EDGE_MARGIN := 500.0
const COLUMN_SPACING := 170.0
const ROW_SPACING := 130.0
const SHIPS_PER_COLUMN := 6


## Adds every ship of the context to the sim and returns them in spec order,
## player side first. Unknown hulls are skipped with an error.
static func populate(sim: CombatSim, context: Dictionary, hull_lookup: Callable,
		weapon_lookup: Callable) -> Array[ShipState]:
	var size := DEFAULT_ARENA
	var arena_size: Array = context.get("arena", [])
	if arena_size.size() == 2:
		size = Vector2(float(arena_size[0]), float(arena_size[1]))
	sim.arena = Rect2(-size * 0.5, size)
	var out: Array[ShipState] = []
	for side in 2:
		var specs := expand(context.get("player" if side == 0 else "enemy", []))
		for i in specs.size():
			var hull: HullData = hull_lookup.call(str(specs[i].get("hull", "")))
			if hull == null:
				push_error("BattleBuilder: unknown hull %s" % specs[i].get("hull"))
				continue
			var fit := {}
			var fit_ids: Dictionary = specs[i].get("fit", {})
			for slot_id: String in fit_ids:
				var weapon: WeaponData = weapon_lookup.call(str(fit_ids[slot_id]))
				if weapon != null:
					fit[slot_id] = weapon
			var heading := 0.0 if side == 0 else PI
			out.append(sim.add_ship(hull, fit, side, deploy_position(sim.arena, side, i, specs.size()), heading))
	return out


## Specs with "count" unrolled into one entry per ship.
static func expand(specs: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in specs:
		for _i in maxi(1, int(spec.get("count", 1))):
			out.append(spec)
	return out


## Slot `index` of `count` ships: columns of SHIPS_PER_COLUMN, first column
## nearest the enemy, rows centred on the arena's middle line.
static func deploy_position(arena: Rect2, side: int, index: int, count: int) -> Vector2:
	var column := index / SHIPS_PER_COLUMN
	var row := index % SHIPS_PER_COLUMN
	var rows := mini(SHIPS_PER_COLUMN, count - column * SHIPS_PER_COLUMN)
	var y := arena.get_center().y + (row - (rows - 1) * 0.5) * ROW_SPACING
	var from_edge := EDGE_MARGIN + COLUMN_SPACING * float(maxi(0, _columns(count) - 1 - column))
	var x := arena.position.x + from_edge if side == 0 else arena.end.x - from_edge
	return Vector2(x, y)


static func _columns(count: int) -> int:
	return ceili(float(count) / SHIPS_PER_COLUMN)
