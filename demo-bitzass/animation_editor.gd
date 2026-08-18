extends Node3D
class_name AnimationEditor

@export var save_button: Button
@export var file_name_editor: LineEdit
var folder_name := "res://saved_scenes/"

@export var right_foot_holder : AnimTrackHolder
@export var left_foot_holder : AnimTrackHolder
@export var spine_holder : AnimTrackHolder
@export var head_holder : AnimTrackHolder
@export var root_holder : AnimTrackHolder
@export var right_hand_holder : AnimTrackHolder
@export var left_hand_holder : AnimTrackHolder

func _ready() -> void:
	save_button.pressed.connect(func():
		file_name_editor.visible = true
		file_name_editor.grab_focus()
		)
	file_name_editor.visible = false
	file_name_editor.text_submitted.connect(func(_name : String):
		_name = _name.to_snake_case()
		var all_children := find_children("*", "", true, false)
		for c in all_children:
			c.owner = self
		var scene := PackedScene.new()
		scene.pack(self)
		var path := folder_name + _name + ".tscn"
		ResourceSaver.save(scene, path)
		file_name_editor.visible = false
		)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			file_name_editor.visible = false
