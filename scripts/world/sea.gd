extends Node2D

# Player scene at scenes/player
const PLAYER_SCENE := preload("uid://dejvf2we711bk")
# Pickup scene at scenes/props/kelp_pickup
const PICKUP_SCENE = preload("uid://itponffx0uyf")

@onready var players: Node2D = %Players
@onready var lobby: Lobby = %Lobby
@onready var spawn_point: Marker2D = $Players/SpawnPoint
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var status_label: Label = %StatusLabel
@onready var world_spawner: MultiplayerSpawner = $WorldSpawner
@onready var enemy_spawner: MultiplayerSpawner = $EnemySpawner

var _world_serial := 0
var _enemy_serial := 0

func _ready() -> void:
	spawner.spawn_function = _make_player
	world_spawner.spawn_function = _make_world_object
	enemy_spawner.spawn_function = _make_enemy
	lobby.on_host_pressed.connect(_on_host_pressed)
	lobby.on_join_pressed.connect(_on_join_pressed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func request_pickup(pickup_name: String) -> void:
	request_pickup_rpc.rpc_id(1, pickup_name)

func request_throw(slot_index: int) -> void:
	var player := _authority_player()
	if player == null:
		return
	request_throw_rpc.rpc_id(1, slot_index, player.facing_vector())

func request_use(slot_index: int) -> void:
	request_use_rpc.rpc_id(1, slot_index)

func request_revive() -> void:
	var player := _authority_player()
	if player == null:
		return
	player.revive(spawn_point.position)

func spawn_enemy(enemy_id: StringName, at: Vector2) -> void:
	if not multiplayer.is_server():
		return
	enemy_spawner.spawn({
		"name": "enemy_%d" % _enemy_serial,
		"enemy_id": enemy_id,
		"position": at,
	})
	_enemy_serial += 1

func _authority_player() -> Player:
	return players.get_node_or_null(str(multiplayer.get_unique_id())) as Player

func _sender_id() -> int:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		return 1
	return sender

func _spawn_player(id: int) -> void:
	if players.has_node(str(id)):
		return
	spawner.spawn({
		"id": id,
		"position": spawn_point.position,
	})

func _make_player(data: Dictionary) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(data["id"])
	player.position = data["position"]
	return player

func _apply_pickup(peer_id: int, pickup_name: String) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	var pickup := %Props.get_node_or_null(pickup_name) as Pickup
	if player == null or pickup == null or pickup.item == null or pickup.count <= 0:
		return
	if player.global_position.distance_to(pickup.global_position) > 200.0:
		return
	var left := player.carry.try_add(pickup.item, pickup.count)
	if left == pickup.count:
		return
	_replicate_hands(peer_id)
	if left <= 0:
		pickup.queue_free()
		return
	pickup.count = left

func _apply_throw(peer_id: int, slot_index: int, direction: Vector2) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	var taken := player.carry.data.take_at(slot_index)
	if taken == null:
		return
	if direction.length() < 0.5:
		direction = player.facing_vector()
	direction = direction.normalized()
	_replicate_hands(peer_id)
	_spawn_networked({
		"kind": "pickup",
		"item_id": taken.item.id,
		"count": taken.count,
		"position": player.global_position + direction * 110.0,
		"direction": direction,
		"thrower_id": peer_id,
	})

func _apply_use(peer_id: int, slot_index: int) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	if slot_index < 0 or slot_index >= player.carry.data.slots.size():
		return
	var slot := player.carry.data.slots[slot_index]
	if slot.item == null or slot.count <= 0:
		return
	match slot.item.use_kind:
		ItemData.UseKind.CONSUME:
			player.carry.data.consume_at(slot_index)
			_replicate_hands(peer_id)
			grant_stat.rpc(peer_id, slot.item.grant_stat, slot.item.grant_amount)
		ItemData.UseKind.PLACE:
			if slot.item.place_scene == null:
				return
			var at := player.global_position
			var item_id := slot.item.id
			player.carry.data.consume_at(slot_index)
			_replicate_hands(peer_id)
			_spawn_networked({
				"kind": "prop",
				"item_id": item_id,
				"position": at,
			})

func _replicate_hands(peer_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	replicate_hands.rpc(
		peer_id,
		player.carry.data.snapshot_ids(),
		player.carry.data.snapshot_counts()
	)

func _spawn_networked(data: Dictionary) -> void:
	data["name"] = "world_%d" % _world_serial
	_world_serial += 1
	world_spawner.spawn(data)

func _make_world_object(data: Dictionary) -> Node:
	if str(data["kind"]) == "prop":
		var placed := ItemCatalog.from_id(data["item_id"])
		var prop := placed.place_scene.instantiate()
		prop.name = str(data["name"])
		prop.position = data["position"]
		return prop
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.name = str(data["name"])
	pickup.networked = true
	pickup.item = ItemCatalog.from_id(data["item_id"])
	pickup.count = int(data["count"])
	pickup.position = data["position"]
	pickup.set_multiplayer_authority(1)
	var direction := data["direction"] as Vector2
	if direction.length() > 0.0:
		var thrower := players.get_node_or_null(str(data["thrower_id"])) as Node2D
		pickup.launch(direction, thrower)
	return pickup

func _publish_editor_pickups() -> void:
	var specs: Array[Dictionary] = []
	for child in %Props.get_children():
		var pickup := child as Pickup
		if pickup == null or pickup.networked or pickup.item == null:
			continue
		specs.append({
			"kind": "pickup",
			"item_id": pickup.item.id,
			"count": pickup.count,
			"position": pickup.position,
			"direction": Vector2.ZERO,
			"thrower_id": 0,
		})
		pickup.queue_free()
	for spec in specs:
		_spawn_networked(spec)

func _make_enemy(data: Dictionary) -> Node:
	var enemy := EnemyCatalog.scene_for(data["enemy_id"]).instantiate()
	enemy.name = str(data["name"])
	enemy.position = data["position"]
	return enemy

func _spawn_editor_enemies() -> void:
	for child in %EnemySpawns.get_children():
		var point := child as EnemySpawnPoint
		if point == null:
			continue
		for i in point.count:
			var offset := Vector2(randf_range(-point.spread, point.spread), randf_range(-point.spread, point.spread))
			spawn_enemy(point.enemy_id, point.global_position + offset)

# ===== RCP METHODS =====
@rpc("any_peer", "reliable")
func scene_ready() -> void:
	if not multiplayer.is_server():
		return
	_spawn_player(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_local", "reliable")
func request_pickup_rpc(pickup_name: String) -> void:
	if not multiplayer.is_server():
		return
	_apply_pickup(_sender_id(), pickup_name)

@rpc("any_peer", "call_local", "reliable")
func request_throw_rpc(slot_index: int, direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	_apply_throw(_sender_id(), slot_index, direction)

@rpc("any_peer", "call_local", "reliable")
func request_use_rpc(slot_index: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_use(_sender_id(), slot_index)

@rpc("authority", "call_local", "reliable")
func replicate_hands(peer_id: int, item_ids: Array, counts: Array) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.carry.data.apply_snapshot(item_ids, counts)

@rpc("authority", "call_local", "reliable")
func grant_stat(peer_id: int, stat: StringName, amount: float) -> void:
	var player := players.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.apply_grant(stat, amount)
# ===== END RCP METHODS =====

func _on_host_pressed() -> void:
	var err := Network.host()
	if err != OK:
		status_label.text = "Host failed: %s" % error_string(err)
		return
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status_label.text = "Hosting. Other phone joins %s" % Network.lan_ip()
	lobby.hide()
	_spawn_player(1)
	_publish_editor_pickups()
	_spawn_editor_enemies()

func _on_join_pressed(ip: String) -> void:
	var err := Network.join_game(ip)
	if err != OK:
		status_label.text = "Join failed: %s" % error_string(err)
		return
	status_label.text = "Connecting..."

func _on_connected_to_server() -> void:
	# Clear any local prop, just leave the networked one
	for child in %Props.get_children():
		var pickup := child as Pickup
		if pickup != null and not pickup.networked:
			pickup.queue_free()
	lobby.hide()
	status_label.text = "Connected."
	scene_ready.rpc_id(1)

func _on_connection_failed() -> void:
	status_label.text = "Could not reach the host. Check Wi-Fi, VPN, and the IP."

func _on_server_disconnected() -> void:
	status_label.text = "Host closed."
	lobby.show()

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var body := players.get_node_or_null(str(id))
	if body != null:
		body.queue_free()
