class_name ItemSpawner
extends Node2D

signal spawn_requested(item_id: StringName, count: int, at: Vector2)

const WILD_GROUP := &"wild_items"

@onready var refill_timer: Timer = $RefillTimer

@export var entries: Array[ItemSpawnEntry] = []
@export var players: Node2D
@export var target_count := 20
@export var refill_interval := 30.0
@export var refill_batch := 3
@export var surface_y := 360.0
@export var bottom_y := 4400.0
@export var min_spacing := 80.0
@export var min_player_distance := 300.0
@export var max_attempts := 10

var _rng := RandomNumberGenerator.new()
var _zones: Array[ItemSpawnZone] = []

func _ready() -> void:
	_rng.randomize()
	for child in get_children():
		var zone := child as ItemSpawnZone
		if zone != null:
			_zones.append(zone)
	refill_timer.timeout.connect(_on_refill_timer_timeout)

func start() -> void:
	if not multiplayer.is_server():
		return
	_fill(target_count)
	refill_timer.start(refill_interval)

func _fill(max_new: int) -> void:
	var missing := target_count - get_tree().get_nodes_in_group(WILD_GROUP).size()
	for i in mini(missing, max_new):
		_spawn_one()

func _spawn_one() -> void:
	if _zones.is_empty() or entries.is_empty():
		return
	for attempt in max_attempts:
		var at := _random_point()
		if not _is_free(at):
			continue
		var entry := _pick_entry(_depth_of(at))
		if entry == null or entry.item == null:
			continue
		spawn_requested.emit(entry.item.id, _rng.randi_range(entry.min_count, entry.max_count), at)
		return

func _random_point() -> Vector2:
	var areas := PackedFloat32Array()
	for zone in _zones:
		areas.append(zone.size.x * zone.size.y)
	return _zones[_rng.rand_weighted(areas)].random_point(_rng)

func _depth_of(at: Vector2) -> float:
	return clampf(inverse_lerp(surface_y, bottom_y, at.y), 0.0, 1.0)

func _pick_entry(depth: float) -> ItemSpawnEntry:
	var weights := PackedFloat32Array()
	var total := 0.0
	for entry in entries:
		var weight := entry.weight_at(depth)
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return null
	return entries[_rng.rand_weighted(weights)]

func _is_free(at: Vector2) -> bool:
	# can also run a point query with PhysicsDirectSpaceState2D.intersect_point 
	# and retry if it hits something.
	for node in get_tree().get_nodes_in_group(WILD_GROUP):
		if (node as Node2D).global_position.distance_to(at) < min_spacing:
			return false
	if players != null:
		for child in players.get_children():
			var player := child as Player
			if player != null and player.global_position.distance_to(at) < min_player_distance:
				return false
	return true

func _on_refill_timer_timeout() -> void:
	_fill(refill_batch)
