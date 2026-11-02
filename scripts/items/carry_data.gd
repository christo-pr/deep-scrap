class_name CarryData
extends Resource

var slots: Array[CarrySlot] = []
var selected: int = 0

func setup(size: int) -> void:
	slots.clear()
	for _i in size:
		slots.append(CarrySlot.new())

func select(index: int) -> void:
	if index < 0 or index >= slots.size() or index == selected:
		return
	selected = index
	changed.emit()

func current() -> CarrySlot:
	if slots.is_empty():
		return null
	return slots[selected]

func try_add(item: ItemData, count: int) -> int:
	if item == null or count <= 0:
		return count
	var left := count
	if item.max_stack > 1:
		for slot in slots:
			if left <= 0:
				break
			if slot.item == null or slot.item.id != item.id:
				continue
			var room := item.max_stack - slot.count
			if room <= 0:
				continue
			var moved := mini(room, left)
			slot.count += moved
			left -= moved
	for slot in slots:
		if left <= 0:
			break
		if slot.item != null:
			continue
		var moved := mini(item.max_stack, left)
		slot.item = item
		slot.count = moved
		left -= moved
	if left != count:
		changed.emit()
	return left

func consume_one() -> void:
	var slot := current()
	if slot == null or slot.item == null:
		return
	slot.count -= 1
	if slot.count <= 0:
		slot.item = null
		slot.count = 0
	changed.emit()

func take_selected() -> CarrySlot:
	var slot := current()
	if slot == null or slot.item == null or slot.count <= 0:
		return null
	var taken := CarrySlot.new()
	taken.item = slot.item
	taken.count = slot.count
	slot.item = null
	slot.count = 0
	changed.emit()
	return taken

func take_at(index: int) -> CarrySlot:
	if index < 0 or index >= slots.size():
		return null
	selected = index
	return take_selected()

func consume_at(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	selected = index
	consume_one()

func snapshot_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot in slots:
		ids.append(slot.item.id if slot.item != null else &"")
	return ids


func snapshot_counts() -> Array[int]:
	var amounts: Array[int] = []
	for slot in slots:
		amounts.append(slot.count if slot.item != null else 0)
	return amounts


func apply_snapshot(item_ids: Array, counts: Array) -> void:
	for i in slots.size():
		var id := StringName(item_ids[i]) if i < item_ids.size() else &""
		var amount := int(counts[i]) if i < counts.size() else 0
		var resolved := ItemCatalog.from_id(id)
		if resolved == null or amount <= 0:
			slots[i].item = null
			slots[i].count = 0
		else:
			slots[i].item = resolved
			slots[i].count = amount
	changed.emit()
