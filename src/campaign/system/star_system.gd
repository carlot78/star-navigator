extends Node2D
## The star system the player flies in: a star at the origin, planets on
## circular orbits and a boundary the ship cannot leave.
##
## M1 placeholder: one hand-defined "home" system. In M4 the SectorGenerator
## produces a SystemModel and this scene renders whichever system the fleet is
## in; the tables below move to that model.

const BOUNDS_RADIUS := 1500.0
const STAR := {"name": "Halcyon", "radius": 80.0, "color": Color(1.0, 0.85, 0.55)}
const PLANETS := [
	{"name": "Ardent", "radius": 20.0, "orbit": 480.0, "period": 180.0, "phase": 0.6, "color": Color(0.85, 0.5, 0.35)},
	{"name": "Verdance", "radius": 30.0, "orbit": 980.0, "period": 420.0, "phase": 3.4, "color": Color(0.4, 0.7, 0.55)},
]
const ORBIT_COLOR := Color(1, 1, 1, 0.08)
const BOUNDS_COLOR := Color(0.5, 0.6, 1.0, 0.18)

## Orbital time in seconds. Local for now; becomes the campaign clock in M4.
var _time: float = 0.0
var _planets: Array[CelestialBody] = []


func _ready() -> void:
	add_child(CelestialBody.new().setup(STAR.name, STAR.radius, STAR.color, 2.5))
	for planet: Dictionary in PLANETS:
		var body := CelestialBody.new().setup(planet.name, planet.radius, planet.color)
		add_child(body)
		_planets.append(body)
	_place_planets()


func _process(delta: float) -> void:
	_time += delta
	_place_planets()


## Keeps a point inside the system boundary.
func clamp_point(point: Vector2) -> Vector2:
	if point.length() <= BOUNDS_RADIUS:
		return point
	return point.normalized() * BOUNDS_RADIUS


func _place_planets() -> void:
	for i in _planets.size():
		var planet: Dictionary = PLANETS[i]
		var angle: float = planet.phase + TAU * _time / planet.period
		_planets[i].position = Vector2.from_angle(angle) * planet.orbit


func _draw() -> void:
	for planet: Dictionary in PLANETS:
		draw_arc(Vector2.ZERO, planet.orbit, 0.0, TAU, 128, ORBIT_COLOR, 1.0, true)
	draw_arc(Vector2.ZERO, BOUNDS_RADIUS, 0.0, TAU, 192, BOUNDS_COLOR, 2.0, true)
