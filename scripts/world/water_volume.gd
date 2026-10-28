extends Area2D

var _inside: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Overlap signals do not fire for a body that is already inside at spawn.
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if body in _inside:
		return
	var player := body as Player
	if player == null:
		return
	_inside[body] = true
	player.set_underwater(true)

func _on_body_exited(body: Node2D) -> void:
	if body not in _inside:
		return
	_inside.erase(body)
	var player := body as Player
	if player == null:
		return
	player.set_underwater(false)
