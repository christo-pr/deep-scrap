extends Control

const ROW_ICON_SIZE := Vector2(40, 40)
const SELECTED_TINT := Color(1.0, 0.9, 0.4)

@onready var _coins_label: Label = %CoinsLabel
@onready var _close_button: Button = %CloseButton
@onready var _tabs: TabContainer = %Tabs
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _empty_label: Label = %EmptyLabel
@onready var _sell_all_button: Button = %SellAllButton

var _player: Player

func _ready() -> void:
	add_to_group(&"shop_modal")
	hide()
	_close_button.pressed.connect(_on_close_pressed)
	_sell_all_button.pressed.connect(_on_sell_all_pressed)

func bind_player(player: Player) -> void:
	if _player != null:
		_player.shop_toggled.disconnect(_on_shop_toggled)
		_player.carry.changed.disconnect(_refresh)
		_player.wallet.changed.disconnect(_on_coins_changed)
	_player = player
	_player.shop_toggled.connect(_on_shop_toggled)
	_player.carry.changed.connect(_refresh)
	_player.wallet.changed.connect(_on_coins_changed)
	_on_coins_changed(_player.wallet.coins)

func _unhandled_input(event: InputEvent) -> void:
	if visible and _player != null and event.is_action_pressed(&"ui_cancel"):
		_player.close_shop()
		get_viewport().set_input_as_handled()

func _on_shop_toggled(open: bool) -> void:
	visible = open
	if open:
		_tabs.current_tab = 0
		_refresh()

func _on_coins_changed(coins: int) -> void:
	_coins_label.text = "%d coins" % coins

func _refresh() -> void:
	if _player == null or not visible:
		return
	for child in _slot_list.get_children():
		child.queue_free()
	var slots := _player.carry.data.slots
	var total := 0
	for i in slots.size():
		var slot := slots[i]
		if slot.item == null or slot.item.sell_value <= 0:
			continue
		var value := slot.item.sell_value * slot.count
		total += value
		_slot_list.add_child(_make_row(i, slot, value))
	_empty_label.visible = total == 0
	_sell_all_button.disabled = total == 0
	_sell_all_button.text = "Sell all (%d coins)" % total

func _make_row(index: int, slot: CarrySlot, value: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	if index == _player.carry.data.selected:
		row.modulate = SELECTED_TINT

	var icon := TextureRect.new()
	icon.texture = slot.item.icon
	icon.custom_minimum_size = ROW_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.text = "[%d] %s x%d = %d coins" % [index + 1, slot.item.display_name, slot.count, value]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var button := Button.new()
	button.text = "Sell"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(96, 48)
	button.pressed.connect(_on_sell_pressed.bind(index))
	row.add_child(button)
	return row

func _on_sell_pressed(index: int) -> void:
	if _player != null:
		_player.carry.sell_at(index)

func _on_sell_all_pressed() -> void:
	if _player != null:
		_player.carry.sell_all()

func _on_close_pressed() -> void:
	if _player != null:
		_player.close_shop()
