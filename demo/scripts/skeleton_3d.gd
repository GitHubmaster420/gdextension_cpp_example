@tool
extends Skeleton3D

@export var other_skeleton : Skeleton3D

@export_tool_button("create copy modifiers") var c = create_copy_modifiers

func create_copy_modifiers():
	for bone in get_bone_count():
		var bone_name = get_bone_name(bone)
		var new_modifier := CopyOtherArmatureBone.new()
		new_modifier.name = bone_name.to_snake_case() + "_copy_modifier"
		add_child(new_modifier)
		new_modifier.owner = owner
		
		new_modifier.other_skeleton = other_skeleton
		new_modifier.other_bone = bone_name
		new_modifier.this_bone = bone_name
