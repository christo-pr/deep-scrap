extends Node2D

# Player scene at scenes/player
const PLAYER_SCENE := preload("uid://dejvf2we711bk")

@onready var players: Node2D = %Players
@onready var lobby: Lobby = %Lobby
@onready var spawn_point: Marker2D = $Players/SpawnPoint
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	spawner.spawn_function = _make_player
	lobby.on_host_pressed.connect(_on_host_pressed)
	lobby.on_join_pressed.connect(_on_join_pressed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
	var hands := player.get_node("Carry") as Carry
	hands.place_requested.connect(_spawn_prop)
	return player

# ===== RCP METHODS =====
@rpc("any_peer", "reliable")
func scene_ready() -> void:
	if not multiplayer.is_server():
		return
	_spawn_player(multiplayer.get_remote_sender_id())
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

func _on_join_pressed(ip: String) -> void:
	var err := Network.join_game(ip)
	if err != OK:
		status_label.text = "Join failed: %s" % error_string(err)
		return
	status_label.text = "Connecting..."

func _on_connected_to_server() -> void:
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

func _spawn_prop(scene: PackedScene, at: Vector2) -> void:
	var prop := scene.instantiate()
	prop.global_position = at
	%Props.add_child(prop)
