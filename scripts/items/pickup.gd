extends Area2D
class_name Pickup

const THROW_SPEED := 280.0
const THROW_DRAG := 360.0

@export var item: ItemData
@export var count: int = 1

var _velocity := Vector2.ZERO
var _ignored: Node2D

func _ready() -> void:
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if item != null and item.icon != null:
		$Sprite2D.texture = item.icon

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_velocity = _velocity.move_toward(Vector2.ZERO, THROW_DRAG * delta)
	if _velocity.length() < 20.0:
		_velocity = Vector2.ZERO
		set_physics_process(false)

func launch(direction: Vector2, thrower: Node2D) -> void:
	_ignored = thrower
	_velocity = direction.normalized() * THROW_SPEED
	set_physics_process(true)

func _on_body_entered(body: Node2D) -> void:
	if body == _ignored:
		return
	var player := body as Player
	if player == null or not player.is_multiplayer_authority():
		return
	var left := player.carry.try_add(item, count)
	if left == count:
		return
	count = left
	if count <= 0:
		queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body == _ignored:
		_ignored = null
