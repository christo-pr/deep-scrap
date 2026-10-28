class_name Player
extends CharacterBody2D

const SPEED := 220.0

@onready var body: Polygon2D = $Body
@onready var camera: Camera2D = $Camera2D
@onready var playerVisuals: PlayerVisuals = $Visuals

@export var net_moving := false
@export var net_facing := 0

var _is_attacking := false
var is_underwater := false

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
		var anim := playerVisuals.attack_anim()
		var flip := playerVisuals.facing == PlayerVisuals.Facing.LEFT
		net_play_attack.rpc(anim, flip)

	var direction := Vector2.ZERO
	if not _is_attacking:
		direction = Input.get_vector(&"swim_left", &"swim_right", &"swim_up", &"swim_down")
		if direction == Vector2.ZERO:
			var stick := get_tree().get_first_node_in_group("touch_stick")
			if stick != null:
				direction = stick.direction
		if direction != Vector2.ZERO:
			playerVisuals.update_facing(direction)

	net_moving = direction != Vector2.ZERO
	net_facing = playerVisuals.facing
	velocity = direction * SPEED
	move_and_slide()

func set_underwater(under: bool) -> void:
	is_underwater = under
	modulate = Color(0.45, 0.7, 1.0) if under else Color.WHITE
	print("underwater" if under else "surface")
	
# ===== RCP METHODS =====
@rpc("authority", "call_local", "reliable")
func net_play_attack(anim: String, flip: bool) -> void:
	if playerVisuals.play_attack_forced(StringName(anim), flip):
		_is_attacking = true
# ===== END RCP METHODS =====

func _on_attack_finished() -> void:
	_is_attacking = false
