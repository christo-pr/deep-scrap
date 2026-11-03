class_name Player
extends CharacterBody2D

signal air_changed(value: float, max_value: float)
signal health_changed(value: float, max_value: float)
signal died
signal revived
signal shop_toggled(open: bool)

const SPEED := 220.0

@onready var camera: Camera2D = $Camera2D
@onready var playerVisuals: PlayerVisuals = $Visuals
@onready var carry: Carry = $Carry
@onready var wallet: Wallet = $Wallet

@export var net_moving := false
@export var net_facing := 0
@export var net_low_air := false
@export var net_air_critical := false
@export var net_dead := false

@export var air_max := 10.0
@export var air_drain := 1.0
@export var air_refill := 15
@export var low_air_threshold := 5.0
@export var health_max := 100.0
@export var drowning_damage := 20.0

var _is_attacking := false
var _ui_groups := [&"hotbar", &"status_bars", &"death_modal", &"shop_modal", &"controls"]
var is_underwater := false
var _nearby_shop: Shop
var is_shopping := false
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
		if is_equal_approx(health, 0.0):
			_die()

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	add_to_group(&"players")

func _ready() -> void:
	air = air_max
	health = health_max
	camera.enabled = is_multiplayer_authority()
	playerVisuals.attack_finished.connect(_on_attack_finished)
	
	if is_multiplayer_authority():
		for group in _ui_groups:
			var ui := get_tree().get_first_node_in_group(group)
			if ui != null and ui.has_method(&"bind_player"):
				ui.bind_player(self)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if net_dead:
		velocity = Vector2.ZERO
		net_moving = false
		return
	
	if Input.is_action_just_pressed(&"shop"):
		interact()
		
	if is_shopping:
		velocity = Vector2.ZERO
		net_moving = false
		if Input.is_action_just_pressed(&"use_carry"):
			carry.sell_selected()
		_update_air(delta)
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

func apply_grant(stat: StringName, amount: float) -> void:
	if stat == &"air":
		air = minf(air + amount, air_max)
	# TODO: More grants to add

func take_damage(amount: float) -> void:
	if net_dead:
		return
	health -= amount

func revive(at: Vector2) -> void:
	if not is_multiplayer_authority() or not net_dead:
		return
	position = at
	velocity = Vector2.ZERO
	air = air_max
	health = health_max
	_is_attacking = false
	net_dead = false
	revived.emit()

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

func interact() -> void:
	if not is_multiplayer_authority() or net_dead:
		return
	if is_shopping:
		close_shop()
	elif _nearby_shop != null:
		_set_shopping(true)

func close_shop() -> void:
	_set_shopping(false)

func set_nearby_shop(shop: Shop) -> void:
	_nearby_shop = shop

func clear_nearby_shop(shop: Shop) -> void:
	if _nearby_shop != shop:
		return
	_nearby_shop = null
	close_shop()

# ===== RCP METHODS =====
@rpc("authority", "call_local", "reliable")
func net_play_attack(anim: String, flip: bool) -> void:
	if playerVisuals.play_attack_forced(StringName(anim), flip):
		_is_attacking = true

@rpc("authority", "call_local", "reliable")
func net_play_hurt() -> void:
	playerVisuals.hurt()

@rpc("any_peer", "call_local", "reliable")
func net_take_damage(amount: float) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	if not is_multiplayer_authority():
		return
	take_damage(amount)
	net_play_hurt.rpc()
# ===== END RCP METHODS =====

func _die() -> void:
	close_shop()
	net_dead = true
	net_moving = false
	velocity = Vector2.ZERO
	_is_attacking = false
	died.emit()

func _update_air(delta: float) -> void:
	if is_underwater:
		air = maxf(air - air_drain * delta, 0.0)
	else:
		air = minf(air + air_refill * delta, air_max)
	net_low_air = is_underwater and air <= low_air_threshold
	net_air_critical = is_underwater and air <= 0
	if net_air_critical:
		take_damage(drowning_damage * delta)

func _set_shopping(open: bool) -> void:
	if is_shopping == open:
		return
	is_shopping = open
	shop_toggled.emit(open)

func _on_attack_finished() -> void:
	_is_attacking = false
