class_name SafeArea
extends RefCounted
## Keeps HUD content out of notches and rounded corners (FR-UX-3): sets a
## MarginContainer's margins from the display safe area, converted from
## screen pixels to canvas units, plus a base gutter.

const BASE_MARGIN := 16


static func apply(container: MarginContainer) -> void:
	var window := Vector2(DisplayServer.window_get_size())
	if window.x <= 0.0 or window.y <= 0.0:
		return
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var canvas := container.get_viewport().get_visible_rect().size
	var ratio := canvas / window
	var left := safe.position.x * ratio.x
	var top := safe.position.y * ratio.y
	var right := (window.x - safe.end.x) * ratio.x
	var bottom := (window.y - safe.end.y) * ratio.y
	container.add_theme_constant_override("margin_left", BASE_MARGIN + int(maxf(0.0, left)))
	container.add_theme_constant_override("margin_top", BASE_MARGIN + int(maxf(0.0, top)))
	container.add_theme_constant_override("margin_right", BASE_MARGIN + int(maxf(0.0, right)))
	container.add_theme_constant_override("margin_bottom", BASE_MARGIN + int(maxf(0.0, bottom)))
