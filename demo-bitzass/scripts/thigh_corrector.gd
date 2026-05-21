@tool
extends SkeletonModifier3D
class_name ThighCorrector
## Meant to be used when shin has a joycon and thigh doesn't to trust joycon for natural motion

@export var thigh : String
@export var shin : String

func _validate_property(property: Dictionary) -> void:
	if property.name == "thigh" or property.name == "shin":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

var thigh_idx : int
var shin_idx : int

func _ready() -> void:
	if thigh:
		thigh_idx = get_skeleton().find_bone(thigh)
	if shin:
		shin_idx = get_skeleton().find_bone(shin)



func _process_modification_with_delta(_delta: float) -> void:
	var stored := get_skeleton().get_bone_global_pose(shin_idx).basis
	var thigh_tr := get_skeleton().get_bone_global_pose(thigh_idx)
	var thigh_basis := thigh_tr.basis
	var shin_basis := get_skeleton().get_bone_global_pose(shin_idx).basis
	var new_basis : Basis
	
	var x := shin_basis.x
	var new_z := x.cross(thigh_basis.y).normalized()
	var new_y := new_z.cross(x).normalized()
	var new_x := new_y.cross(new_z).normalized()
	new_basis.x = new_x
	new_basis.y = new_y
	new_basis.z = new_z
	
	get_skeleton().set_bone_global_pose(thigh_idx, Transform3D(new_basis, thigh_tr.origin))
	
	# Because shin inherits from thigh, need this to keep original orientation
	get_skeleton().set_bone_global_pose(shin_idx, Transform3D(stored, get_skeleton().get_bone_global_pose(shin_idx).origin))
	
