extends Node2D

const PLAYER_SCENE := preload("res://player/player.tscn")

@onready var players: Node2D = %Players
@onready var lobby: Control = %Lobby
@onready var status_label: Label = %StatusLabel
@onready var ip_edit: LineEdit = %IpEdit

func _ready() -> void:
	ip_edit.text = Network.lan_ip()
	%HostButton.pressed.connect(_on_host_pressed)
	%JoinButton.pressed.connect(_on_join_pressed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_pressed() -> void:
	var err := Network.host()
	if err != OK:
		status_label.text = "Host failed: %s" % error_string(err)
		return
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status_label.text = "Hosting. Other phone joins %s" % Network.lan_ip()
	lobby.hide()
	_spawn_player(1)

func _on_join_pressed() -> void:
	var err := Network.join_game(ip_edit.text)
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

func _spawn_player(id: int) -> void:
	if players.has_node(str(id)):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.position = Vector2(640, 360) if id == 1 else Vector2(760, 360)
	players.add_child(player, true)

@rpc("any_peer", "reliable")
func scene_ready() -> void:
	if not multiplayer.is_server():
		return
	_spawn_player(multiplayer.get_remote_sender_id())
