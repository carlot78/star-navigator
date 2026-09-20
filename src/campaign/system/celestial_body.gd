class_name CelestialBody
extends Node2D
## A star or planet drawn procedurally: a disc, a soft glow and a name label.
## Sprites replace the disc later; the node interface stays.

var body_name: String = ""
var radius: float = 20.0
var color: Color = Color.WHITE
var glow: float = 0.0


func setup(p_name: String, p_radius: float, p_color: Color, p_glow: float = 0.0) -> CelestialBody:
	body_name = p_name
	radius = p_radius
	color = p_color
	glow = p_glow
	queue_redraw()
	return self


func _draw() -> void:
	if glow > 0.0:
		for i in 10:
			var t := float(i + 1) / 10.0
			draw_circle(Vector2.ZERO, radius * (1.0 + glow * t), Color(color, 0.05 * (1.0 - t) * (1.0 - t)))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.55, Color(1, 1, 1, 0.12))
	var font := ThemeDB.fallback_font
	var size := 16
	var width := font.get_string_size(body_name, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
	draw_string(font, Vector2(-width * 0.5, radius + size + 6), body_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		Color(0.8, 0.85, 0.95, 0.9))
