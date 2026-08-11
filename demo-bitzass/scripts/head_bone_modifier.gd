@tool
extends BodyPartInterpolator
class_name HeadInterpolator

@export var head_name : String:
	set(v):
		head_name = v
		if not get_skeleton():
			return
		head_idx = get_skeleton().find_bone(v)
@export var neck_name : String:
	set(v):
		neck_name = v
		if not get_skeleton():
			return
		neck_idx = get_skeleton().find_bone(v)

@export var neck_2_name : String:
	set(v):
		neck_2_name = v
		if not get_skeleton():
			return
		neck_2_idx = get_skeleton().find_bone(v)



@export var head_idx : int
@export var neck_idx : int
@export var neck_2_idx :int

@export var spine_bone_modifier : SpineBoneModifier

func _ready() -> void:
	super()
	head_name = head_name
	neck_name = neck_name

func _validate_property(property: Dictionary) -> void:
	if property.name == "head_name" or property.name == "neck_name" or property.name == "neck_2_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process_modification_with_delta(delta: float) -> void:
	on_time_changed(anim_track_holder.time)
	interpolate_keyframes()

func interpolate_keyframes():
	if Engine.is_editor_hint():
		return
	if anim_track_holder.keyframes.size() == 0:
		return
	var animator_1 := prev_keyframe.animator as HeadAnimator
	var animator_2 := next_keyframe.animator as HeadAnimator
	
	
	animator_1.chest.global_transform = spine_bone_modifier.interpolate_chest_in_time(prev_keyframe.time)
	animator_2.chest.global_transform = spine_bone_modifier.interpolate_chest_in_time(next_keyframe.time)
	animator_1.neck.position = get_skeleton().get_bone_rest(neck_idx).origin
	animator_2.neck.position = get_skeleton().get_bone_rest(neck_idx).origin
	animator_1.neck_2.position = get_skeleton().get_bone_rest(neck_2_idx).origin
	animator_2.neck_2.position = get_skeleton().get_bone_rest(neck_2_idx).origin
	animator_1.head.position = get_skeleton().get_bone_rest(head_idx).origin
	animator_2.head.position = get_skeleton().get_bone_rest(head_idx).origin
	
	
	var t := get_t_from_keyframes(anim_track_holder.time)
	
	var neck_offset := interpolate_neck_at_time(prev_keyframe, next_keyframe, t)
	
	var neck_bees := animator_2.interpolate_neck(neck_offset)
	
	var neck_b := neck_bees[0]
	var neck_2_b := neck_bees[1]
	var head_b := interpolate_head_at_time(prev_keyframe, next_keyframe, t)
	
	get_skeleton().set_bone_pose_rotation(neck_idx, neck_b)
	get_skeleton().set_bone_pose_rotation(neck_2_idx, neck_2_b)
	get_skeleton().set_bone_pose_rotation(head_idx, head_b)

func interpolate_neck_at_time(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Quaternion:
	var animator_1 := key_1.animator as HeadAnimator
	var animator_2 := key_2.animator as HeadAnimator
	
	var neck_offset := QuaternionExtender.my_quat_interpolate(
		animator_1.neck_control.basis.get_rotation_quaternion(), animator_1.neck_tangent_vector, animator_1.neck_vel_magnitude,
		animator_2.neck_control.basis.get_rotation_quaternion(), animator_2.neck_tangent_vector, animator_2.neck_vel_magnitude,
		t, next_keyframe.time - prev_keyframe.time, animator_2.neck_ease_curve.baked_points
	)
	return neck_offset

func interpolate_head_at_time(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Quaternion:
	var animator_1 := key_1.animator as HeadAnimator
	var animator_2 := key_2.animator as HeadAnimator
	var head_b := QuaternionExtender.my_quat_interpolate(
		animator_1.head.basis.get_rotation_quaternion(), animator_1.head_tangent_vector, animator_1.head_vel_magnitude, 
		animator_2.head.basis.get_rotation_quaternion(), animator_2.head_tangent_vector, animator_2.head_vel_magnitude,
		t, next_keyframe.time - prev_keyframe.time, animator_2.head_ease_curve.baked_points
	)
	return head_b

func on_keyframe_added(key : Keyframe):
	await get_skeleton().skeleton_updated
	
	var animator := key.animator as HeadAnimator
	var g := animator.gizmo
	var stored : GizmoControllable
	if g:
		stored = g.controllable
		if stored:
			stored.gizmo = null
		g.controllable = null
		
	animator.chest.global_transform = get_skeleton().get_bone_global_pose(get_skeleton().get_bone_parent(neck_idx))
	var prev_key : Keyframe
	var next_key : Keyframe
	if key in anim_track_holder.keyframes:
		var this_idx := anim_track_holder.keyframes.find(key)
			
		if this_idx > 0:
			prev_key = anim_track_holder.keyframes[this_idx - 1]
		if this_idx < anim_track_holder.keyframes.size() - 1:
			next_key = anim_track_holder.keyframes[this_idx + 1]
		if this_idx <= 0:
			prev_key = next_key
		if this_idx >= anim_track_holder.keyframes.size() - 1:
			next_key = prev_key
		else:
			var time := key.time
			
			var ks := get_next_and_prev_keyframes_indices(time)
			prev_key = anim_track_holder.keyframes[ks[0]]
			next_key = anim_track_holder.keyframes[ks[1]]
	await get_tree().process_frame
	if not prev_key or not next_key:
		animator.neck_control.basis = Basis.IDENTITY
		animator.head.basis = get_skeleton().get_bone_pose_rotation(head_idx)
		if g:
			g.controllable = stored
		return
	var t := get_t_from_keyframes(anim_track_holder.time, prev_key, next_key)
	animator.neck_control.basis = interpolate_neck_at_time(prev_key, next_key, t)
	animator.head.basis = interpolate_head_at_time(prev_key, next_key, t)
	animator.head.position = get_skeleton().get_bone_rest(head_idx).origin
	animator.neck.position = get_skeleton().get_bone_rest(neck_idx).origin
	animator.neck_2.position = get_skeleton().get_bone_rest(neck_2_idx).origin
	if g:
		g.controllable = stored
	
