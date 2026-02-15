extends Node3D
class_name JoyCon

signal idk
var foot_id : int
var basis_at_start : Basis

var reference_basis : Basis
var joycon_basis := Basis()

var calibrated := false

var zr_pressed := false
var r_pressed := false
var a_pressed := false
var b_pressed := false
var y_pressed := false

var is_right_joycon := true

var arm_node : KinectJoint

var copy_modifier : CopyModifierPose

var kinect : Kinect

var skeleton : Skeleton3D

enum Target{
	RIGHT_FOOT,
	LEFT_FOOT,
	RIGHT_HAND,
	LEFT_HAND,
	RIGHT_SHIN,
	LEFT_SHIN,
	RIGHT_THIGH,
	LEFT_THIGH
}

var current_target := Target.RIGHT_HAND

func construct_joycon_basis(g : Vector3):
	joycon_basis.y = -g.normalized()
	var temp_z := Vector3.FORWARD
	joycon_basis.x = joycon_basis.y.cross(temp_z).normalized()
	joycon_basis.z = joycon_basis.x.cross(joycon_basis.y).normalized()
	reference_basis = joycon_basis

var arm_offset : Basis

func update_arm_offset():
	var up := Vector3.UP
	var forward := arm_node.global_position.direction_to(arm_node.next_node.global_position)
	var y := up.cross(forward).normalized()
	var x := -forward.cross(y).normalized()
	arm_offset = Basis(x, y, forward).orthonormalized()

func update_leg_offset():
	var up := Vector3.UP
	var forward := -skeleton.get_bone_global_pose(0).basis.y
	var x := up.cross(forward).normalized()
	var y := forward.cross(x).normalized()
	arm_offset = Basis(x, y, forward).orthonormalized()

func point_at_screen(a : Vector3):
	construct_joycon_basis(a)
	calibrated = false

func swap_accel_axes(a: Vector3) -> Vector3:

	return Vector3(a.y, -a.z, -a.x) if is_right_joycon else Vector3(-a.y, a.z, -a.x)
	

signal basis_updated


var upcoming_calibration := false
	

func calibrate(a_local : Vector3):
	
	if current_target == Target.RIGHT_HAND or current_target == Target.LEFT_HAND:
		update_arm_offset()
	if current_target == Target.RIGHT_FOOT or current_target == Target.LEFT_FOOT:
		update_leg_offset()
	point_at_screen(a_local)
	
	if current_target == Target.RIGHT_HAND or current_target == Target.LEFT_HAND:
		
		var _basis : Basis
		_basis.y = arm_node.global_basis.y.normalized()
		
		var x := Vector3.UP
		
		var z := x.cross(_basis.y)
		x = _basis.y.cross(z)
		_basis.x = x
		_basis.z = z
		copy_modifier.reference_basis = _basis
	if current_target == Target.RIGHT_FOOT or current_target == Target.LEFT_FOOT:
		print("calibrating foot")

		var _basis : Basis = skeleton.get_bone_global_rest(foot_id).basis * skeleton.get_bone_global_rest(0).basis.inverse() * skeleton.get_bone_global_pose(0).basis
		copy_modifier.reference_basis = _basis


func update_joycon(d : Dictionary, dt : float):
	var samples : Array = d["samples"]
	var v := Vector3.ZERO
	for sample in samples:
		var g : Array = sample["gyro"]
		v.x += g[0]
		v.y += g[1]
		v.z += g[2]
	v /= 3.0
	var gx := deg_to_rad(v.x)
	var gy := deg_to_rad(v.y)
	var gz := deg_to_rad(v.z)
	var omega_original := Vector3(gx, gy, gz)
	var omega_local := swap_accel_axes(omega_original)
	var omega_delta := omega_local * dt
	var omega_translated := arm_offset * omega_delta
	var omega_quat := Quaternion.from_euler(omega_translated)
	joycon_basis = Quaternion(joycon_basis) * omega_quat
	var relative_rotation := reference_basis.inverse() * joycon_basis
	global_basis = relative_rotation * basis_at_start
	#var g : Dictionary = d["gyro"]
	#var a : Dictionary = d["accel"]
	## --- 2. Apply gyro rotation ---
	#var gx := deg_to_rad(g.x * JoyCons.GYRO_SCALE)
	#var gy := deg_to_rad(g.y * JoyCons.GYRO_SCALE)
	#var gz := deg_to_rad(g.z * JoyCons.GYRO_SCALE)
	#
	#var omega_original := Vector3(gx, gy, gz)
	#
	#var omega_local := swap_accel_axes(omega_original)
	#
	#var omega_delta := omega_local * dt
	#
	#var omega_translated := arm_offset * omega_delta# * arm_offset
	#
	#var omega_quat := Quaternion.from_euler(-omega_translated)
	#
	#joycon_basis = Quaternion(joycon_basis) * omega_quat
#
	#var angle := omega_local.length() * dt
### Only rotate if there's meaningful rotation
	##if angle > 0.0001:
		### Normalize the axis (in local space)
		##var axis_local := (omega_local).normalized()
		##
		### Transform the local axis to world space using the current basis
		##var axis_world := (joycon_basis * arm_offset * axis_local).normalized() # TODO: make work in world space even when joycon is rolled 
		##
		### Rotate the basis around the world axis
		##joycon_basis = joycon_basis.rotated(-axis_world, angle)
		##
	#var relative_rotation := reference_basis.inverse() * joycon_basis
		#
		## Apply to your mesh
	#global_basis = relative_rotation * basis_at_start
	#basis_updated.emit()
	#
	#var a_raw := Vector3(a.x, a.y, a.z)
	#var a_local := swap_accel_axes(a_raw) * JoyCons.ACCEL_SCALE
	#
	#if upcoming_calibration:
		#upcoming_calibration = false
		#calibrate(a_local)
	#
	#var b : Dictionary = d["buttons"]
	#var pressed := bool(b.zr if is_right_joycon else b.zl)
	#if not zr_pressed:
		#if pressed:
			#if a_pressed:
				#upcoming_calibration = true
	#zr_pressed = pressed
	#pressed = bool(b.r if is_right_joycon else b.l)
	#if not r_pressed:
		#if pressed:
			#point_at_screen(a_local)
	#r_pressed = pressed
	#pressed = bool(b.a if is_right_joycon else b.right)
	#if not a_pressed:
		#if pressed:
			#pass
	#a_pressed = pressed
	#pressed = bool(b.b if is_right_joycon else b.down)
	#if not b_pressed and pressed:
		#kinect.tpose()
	#pressed = bool(b.y if is_right_joycon else b.left)
	#if not y_pressed:
		#if pressed:
			#idk.emit()
			#print("y pressed")
	#y_pressed = pressed
