extends Area2D

@export var item: ItemData
@export var count: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or not player.is_multiplayer_authority():
		return
	var left := player.carry.try_add(item, count)
	if left == count:
		return
	count = left
	if count <= 0:
		queue_free()
