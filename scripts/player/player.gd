class_name Player
extends CharacterBody2D

const SPEED := 220.0

@onready var body: Polygon2D = $Body
@onready var camera: Camera2D = $Camera2D
@onready var playerVisuals: PlayerVisuals = $Visuals

var _is_attacking := false

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	body.color = Color(0.2, 0.75, 0.95) if str(name) == "1" else Color(0.95, 0.55, 0.2)
	camera.enabled = is_multiplayer_authority()
	playerVisuals.attack_finished.connect(_on_attack_finished)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not _is_attacking and Input.is_action_just_pressed(&"attack"):
		_is_attacking = playerVisuals.play_attack()

	var direction := Vector2.ZERO
	if not _is_attacking:
		direction = Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
		if direction == Vector2.ZERO:
			var stick := get_tree().get_first_node_in_group("touch_stick")
			if stick != null:
				direction = stick.direction
	velocity = direction * SPEED
	move_and_slide()

func _on_attack_finished() -> void:
	_is_attacking = false
