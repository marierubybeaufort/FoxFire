# MainMenu.gd
extends Control

@onready var new_btn: Button = %NewGameBtn
@onready var cont_btn: Button = %ContinueBtn
@onready var quit_btn: Button = %QuitBtn

func _ready() -> void:
	_update_continue_state()
	new_btn.pressed.connect(_on_new_game)
	cont_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(func(): get_tree().quit())

# Enable or disable Continue depending on if any save exists
func _update_continue_state() -> void:
	var any_save := false
	for entry in SaveManager.list_saves(6):
		if entry["exists"]:
			any_save = true
			break
	cont_btn.disabled = not any_save

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Intro.tscn")

func _on_continue() -> void:
	var latest_slot := _find_latest_save_slot()
	if latest_slot <= 0:
		return
	var data := SaveManager.load_game(latest_slot)
	if not data.is_empty():
		_apply_loaded_state_and_switch(data)

func _find_latest_save_slot() -> int:
	var latest_slot := -1
	var latest_time := ""
	for entry in SaveManager.list_saves(6):
		if not entry["exists"]:
			continue
		var t := String(entry["meta"].get("timestamp_iso", ""))
		if t > latest_time:
			latest_time = t
			latest_slot = int(entry["slot"])
	return latest_slot

func _apply_loaded_state_and_switch(payload:Dictionary) -> void:
	var target_scene := String(payload.get("meta", {}).get("scene", ""))
	if target_scene == "":
		target_scene = "res://scenes/town_square.tscn"
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	var state := payload.get("state", {})
	get_tree().current_scene.call_deferred("apply_saved_state", state)
