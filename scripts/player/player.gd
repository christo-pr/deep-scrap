class_name Player
extends CharacterBody2D

signal air_changed(value: float, max_value: float)
signal health_changed(value: float, max_value: float)

const SPEED := 220.0

@onready var camera: Camera2D = $Camera2D
@onready var playerVisuals: PlayerVisuals = $Visuals
@onready var carry: Carry = $Carry

@export var net_moving := false
@export var net_facing := 0
@export var net_low_air := false
@export var net_air_critical := false
@export var air_max := 10.0
@export var air_drain := 1.0
@export var air_refill := 15
@export var low_air_threshold := 5.0
@export var health_max := 100.0
@export var drowning_damage := 5.0

var _is_attacking := false
var _air_log := 0.0
var is_underwater := false
var air := air_max:
	set(value):
		value = clampf(value, 0.0, air_max)
		if is_equal_approx(value, air):
			return
		air = value
		air_changed.emit(air, air_max)
var health := health_max:
	set(value):
		value = clampf(value, 0.0, health_max)
		if is_equal_approx(value, health):
			return
		health = value
		health_changed.emit(health, health_max)

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	air = air_max
	health = health_max
	camera.enabled = is_multiplayer_authority()
	playerVisuals.attack_finished.connect(_on_attack_finished)
	
	if is_multiplayer_authority():
		for group: StringName in [&"hotbar", &"status_bars"]:
			var ui := get_tree().get_first_node_in_group(group)
			if ui != null and ui.has_method(&"bind_player"):
				ui.bind_player(self)

func _physics_process(delta: float) -> void:
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
	
	# Checks here so the net_moving and net_facing are the values took in 
	# consideration when doing this
	if Input.is_action_just_pressed(&"use_carry"):
		carry.use_selected()
	if Input.is_action_just_pressed(&"throw_carry"):
		carry.throw_selected()
		
	move_and_slide()
	_update_air(delta)

func set_underwater(under: bool) -> void:
	is_underwater = under
	modulate = Color(0.45, 0.7, 1.0) if under else Color.WHITE
	print("underwater" if under else "surface")

func apply_grant(stat: StringName, amount: float) -> void:
	if stat == &"air":
		air = minf(air + amount, air_max)
	# TODO: More grants to add

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		print("player died")  # TODO: death/respawn

func heal(amount: float) -> void:
	health += amount

func facing_vector() -> Vector2:
	match playerVisuals.facing:
		PlayerVisuals.Facing.LEFT:
			return Vector2.LEFT
		PlayerVisuals.Facing.UP:
			return Vector2.UP
		PlayerVisuals.Facing.DOWN:
			return Vector2.DOWN
		_:
			return Vector2.RIGHT

# ===== RCP METHODS =====
@rpc("authority", "call_local", "reliable")
func net_play_attack(anim: String, flip: bool) -> void:
	if playerVisuals.play_attack_forced(StringName(anim), flip):
		_is_attacking = true
# ===== END RCP METHODS =====

func _update_air(delta: float) -> void:
	if is_underwater:
		air = maxf(air - air_drain * delta, 0.0)
	else:
		air = minf(air + air_refill * delta, air_max)
	net_low_air = is_underwater and air <= low_air_threshold
	net_air_critical = is_underwater and air <= 0
	if net_air_critical:
		take_damage(drowning_damage * delta)
	_air_log += delta
	
	if _air_log < 0.5:
		return
	_air_log = 0.0
	print("air %.0f  %s" % [air, "under" if is_underwater else "surface"])
	if air <= 0.0:
		print("out of air")
	
func _on_attack_finished() -> void:
	_is_attacking = false
