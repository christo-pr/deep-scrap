class_name Enemy
extends CharacterBody2D

signal bit

enum State { WANDER, CHASE, FLEE, DEAD }

@export var data: EnemyData

@export var net_state: State = State.WANDER
@export var net_facing_left := false

var health := 0.0
var _home := Vector2.ZERO
var _target: Player
var _threat_position := Vector2.ZERO
var _wander_point := Vector2.ZERO
var _state_time := 0.0
var _aggro_cooldown := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	health = data.health_max
	_home = global_position
	if multiplayer.is_server():
		_rng.randomize()
		_wander_point = _pick_wander_point()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or net_state == State.DEAD:
		return
	_state_time += delta
	_aggro_cooldown = maxf(_aggro_cooldown - delta, 0.0)
	match net_state:
		State.WANDER:
			_tick_wander(delta)
		State.CHASE:
			_tick_chase(delta)
		State.FLEE:
			_tick_flee(delta)
	move_and_slide()
	if absf(velocity.x) > 5.0:
		net_facing_left = velocity.x < 0.0

func take_damage(amount: float, from: Vector2) -> void:
	if not multiplayer.is_server() or net_state == State.DEAD:
		return
	health -= amount
	if health <= 0.0:
		velocity = Vector2.ZERO
		_enter(State.DEAD)
		get_tree().create_timer(1.0).timeout.connect(queue_free)
		return
	_threat_position = from
	_enter(State.FLEE)

# ===== RCP METHODS =====
@rpc("authority", "call_local", "reliable")
func net_play_bite() -> void:
	bit.emit()
# ===== END RCP METHODS =====

# Override in a subclass for custom reactions (e.g. a pufferfish that inflates).
func _react_to(player: Player) -> void:
	_target = player
	_threat_position = player.global_position
	_enter(State.CHASE if data.aggressive else State.FLEE)

func _tick_wander(delta: float) -> void:
	var spotted := _closest_player(data.detect_radius)
	if spotted != null and _aggro_cooldown <= 0.0:
		_react_to(spotted)
		return
	var to_point := _wander_point - global_position
	if to_point.length() < 24.0 or get_slide_collision_count() > 0 or _state_time > data.wander_retarget_time:
		_wander_point = _pick_wander_point()
		_state_time = 0.0
	_steer(to_point.normalized(), data.wander_speed, delta)

func _tick_chase(delta: float) -> void:
	if not _is_valid_target(_target) or _state_time >= data.chase_duration:
		_start_flee()
		return
	var to_target := _target.global_position - global_position
	if to_target.length() > data.lose_radius:
		_start_flee()
		return
	if to_target.length() <= data.bite_range:
		_bite(_target)
		_start_flee()
		return
	_steer(to_target.normalized(), data.chase_speed, delta)

func _tick_flee(delta: float) -> void:
	if _state_time >= data.flee_duration:
		_aggro_cooldown = data.aggro_cooldown
		_wander_point = _pick_wander_point()
		_enter(State.WANDER)
		return
	var away := global_position - _threat_position
	if away.length() < 1.0:
		away = Vector2.LEFT if net_facing_left else Vector2.RIGHT
	_steer(away.normalized(), data.flee_speed, delta)

func _start_flee() -> void:
	if _is_valid_target(_target):
		_threat_position = _target.global_position
	_target = null
	_enter(State.FLEE)

func _bite(player: Player) -> void:
	if data.bite_damage <= 0.0:
		return
	player.net_take_damage.rpc_id(player.get_multiplayer_authority(), data.bite_damage)
	net_play_bite.rpc()

func _steer(direction: Vector2, speed: float, delta: float) -> void:
	velocity = velocity.move_toward(direction * speed, data.acceleration * delta)

func _enter(state: State) -> void:
	net_state = state
	_state_time = 0.0

func _pick_wander_point() -> Vector2:
	var offset := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.3, 1.0) * data.wander_radius
	offset.y *= data.vertical_bias
	return _home + offset

func _closest_player(radius: float) -> Player:
	var best: Player = null
	var best_distance := radius
	for node in get_tree().get_nodes_in_group(&"players"):
		var player := node as Player
		if not _is_valid_target(player):
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance <= best_distance:
			best = player
			best_distance = distance
	return best

func _is_valid_target(player: Player) -> bool:
	return is_instance_valid(player) and not player.net_dead and player.is_underwater
