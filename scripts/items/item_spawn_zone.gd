@tool
class_name ItemSpawnZone
extends Marker2D

@export var size := Vector2(400.0, 200.0):
	set(value):
		size = value
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-size * 0.5, size), Color(0.2, 1.0, 0.4, 0.25))

func random_point(rng: RandomNumberGenerator) -> Vector2:
	var half := size * 0.5
	return global_position + Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
