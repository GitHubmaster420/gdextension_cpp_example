@tool
extends Node
class_name FootController

@export var toe: MeshInstance3D
@export var ik_target: MeshInstance3D
@export var heel: MeshInstance3D

@export var toe_transform : Transform3D
var toe_offset : Basis:
	get:
		return toe_transform.basis
@export var right_foot_transform : Transform3D
var right_foot_offset : Basis:
	get:
		return right_foot_transform.basis
@export var heel_transform : Transform3D
var heel_offset : Basis:
	get:
		return heel_transform.basis

@export var rotation : Vector3

@export var rotation_angles : Vector3:
	set(value):
		rotation_angles = value
		for i in range(3):
			rotation[i] = deg_to_rad(rotation_angles[i])

enum State{
	ON_GROUND,
	IN_AIR
}

@export var state : State

enum GroundState{
	ON_HEEL,
	ON_TOE
}

@export var ground_state : GroundState

@export_tool_button("apply rotation") var a_r = apply_rotation
@export_tool_button("update offsets") var u_o = update_offsets
@export_tool_button("copy foot rotation") var c_r = copy_foot_rotation

func apply_rotation():
	# if on ground, move foot as if it's a child of toe. Otherwise rotate toe
	match state:
		State.IN_AIR:
			var quat := Quaternion.from_euler(rotation)
			var toe_quat := Quaternion(toe_offset)
			toe.global_basis = Quaternion(quat * toe_quat)
		State.ON_GROUND:
			match ground_state:
				GroundState.ON_TOE:
					var toe_tr := toe.global_transform
					var foot_tr := ik_target.global_transform
					#the problem part. assumes that rotation is 0
					var offset = right_foot_transform.origin - toe_transform.origin
					var quat := Quaternion.from_euler(rotation)
					offset = quat * offset
					ik_target.global_position = toe_tr.origin + offset
					var right_foot_quat := Quaternion(right_foot_offset)
					ik_target.global_basis = Quaternion(quat * right_foot_quat)
					var heel_quat := Quaternion(heel_offset)
					heel.global_basis = quat * heel_quat
				GroundState.ON_HEEL:
					var heel_tr := heel.global_transform
					var foot_tr := ik_target.global_transform
					var offset = right_foot_transform.origin - heel_transform.origin
					var quat := Quaternion.from_euler(rotation)
					offset = quat * offset
					ik_target.global_position = heel_tr.origin + offset
					var right_foot_quat := Quaternion(right_foot_offset)
					ik_target.global_basis = Quaternion(quat * right_foot_quat)
					var toe_quat := Quaternion(toe_offset)
					toe.global_basis = quat * toe_quat

func copy_foot_rotation():
	rotation_angles = ik_target.global_rotation_degrees

func update_offsets():
	right_foot_transform = ik_target.global_transform
	toe_transform = toe.global_transform
	heel_transform = heel.global_transform
