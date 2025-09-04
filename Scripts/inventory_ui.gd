extends Control

# This variable keeps track of which item is currently selected.
var selected_index = -1 # Changed default to -1 for the "hand" state

# These arrays will store our item slot and blood splatter nodes.
var item_slots = []
var blood_splatters = []

func _ready():
	# Get references to the item slots and their blood splatter children.
	# The paths are now relative to the current node (Inventory_UI).
	var flashlight_slot = get_node("ItemSlots/Flashlight")
	var knife_slot = get_node("ItemSlots/Knife")
	
	# Append the nodes to their respective arrays.
	item_slots.append(flashlight_slot)
	item_slots.append(knife_slot)
	
	# Get references to the blood splatter nodes.
	blood_splatters.append(flashlight_slot.get_node("BloodSplatterFL"))
	blood_splatters.append(knife_slot.get_node("BloodSplatterKN"))
	
	# Hide all blood splatters initially.
	for splatter in blood_splatters:
		splatter.visible = false
	
	# Initially, no item is selected, so no blood splatter is shown.
	# The `selected_index` is -1 by default.

func _input(event):
	# Listen for your custom input actions.
	if event.is_action_pressed("inventory_slot_1"):
		select_item(0)
	elif event.is_action_pressed("inventory_slot_2"):
		select_item(1)
	elif event.is_action_pressed("inventory_slot_0"):
		# We'll use index -1 to represent the "hand" state.
		select_item(-1)

func select_item(index):
	# Check if an item was previously selected.
	if selected_index != -1 and selected_index < blood_splatters.size():
		# Hide the blood splatter of the previously selected item.
		blood_splatters[selected_index].visible = false
	
	# If the new index is valid (not the hand state), show the blood splatter.
	if index != -1 and index < blood_splatters.size():
		blood_splatters[index].visible = true
	
	# Update the selected_index to the new item's index.
	selected_index = index
