extends Control

var direction := Vector2.ZERO
var _touch_index := -1
var _origin := Vector2.ZERO
const MAX_RADIUS := 80.0

func _ready() -> void:
	add_to_group("touch_stick")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_origin = touch.position
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			direction = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		var offset := drag.position - _origin
		offset = offset.limit_length(MAX_RADIUS)
		direction = offset / MAX_RADIUS
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, MAX_RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(center + direction * MAX_RADIUS, 28.0, Color(1, 1, 1, 0.45))
