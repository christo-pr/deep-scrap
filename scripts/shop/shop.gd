class_name Shop
extends Area2D

@export var reach := 260.0

@onready var _prompt: Label = $Prompt

func _ready() -> void:
	add_to_group(&"shops")
	_prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func is_in_reach(at: Vector2) -> bool:
	return global_position.distance_to(at) <= reach

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or not player.is_multiplayer_authority():
		return
	_prompt.show()
	player.set_nearby_shop(self)

func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if player == null or not player.is_multiplayer_authority():
		return
	_prompt.hide()
	player.clear_nearby_shop(self)
