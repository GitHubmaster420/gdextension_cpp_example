@tool
extends BoneController
class_name AngularVelocityTest

@export var anim_player : AnimPlayerModifier

@export_range(0.01, 1.0, 0.01) var dt := 0.5

@export var angular_velocity_object : MeshInstance3D

@export_range(0, 30, 1, "prefer_slider") var current_frame := 0

func get_angular_velocity() -> Vector3:
	var quats : Array[Quaternion]
	quats.append(Quaternion(global_basis.orthonormalized()))
	quats.append(Quaternion(angular_velocity_object.global_basis.orthonormalized()))
	var v := AnimTrack.angular_velocity(quats, dt)
	return v

@export_tool_button("assign current keyframe") var acav = assign_current_keyframe

func assign_current_keyframe():
	if not anim_player:
		return
	if not anim_player.current_animation:
		return
	if anim_player.current_animation.tracks.size() == 0:
		return
	var track : AnimTrack = anim_player.current_animation.tracks.values()[0]
	if not track:
		return
	var v := get_angular_velocity()
	track.angular_w_velocities[current_frame] = v
	track.transforms[current_frame] = transform
	track.basis_interp_types[current_frame] = AnimTrack.BasisInterpType.HERMITE_CUBIC
	track.origin_interp_types[current_frame] = AnimTrack.OriginInterpType.LERP

func do_stuff():
	pass
