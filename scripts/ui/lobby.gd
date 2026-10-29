class_name Lobby
extends Control

signal on_host_pressed
signal on_join_pressed(ip: String)

@onready var host_button: Button = %HostButton
@onready var ip_edit: LineEdit = %IpEdit
@onready var join_button: Button = %JoinButton

func _ready() -> void:
	ip_edit.text = Network.lan_ip()
	host_button.pressed.connect(on_host)
	join_button.pressed.connect(on_join)

func on_host():
	on_host_pressed.emit()

func on_join():
	on_join_pressed.emit(ip_edit.text)
