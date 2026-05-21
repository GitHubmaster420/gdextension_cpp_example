@tool
extends SkeletonModifier3D
class_name AnimPlayerModifier

@export var hips_anim_target : AnimTarget
@export var pelvis_height_correction_layer : GroundCorrectionLayer

@export_tool_button("set ground correction") var sgc = set_hips_ground_correction

func set_hips_ground_correction():
	current_animation.tracks[hips_anim_target].initiate_first_layer(pelvis_height_correction_layer)

var target_stetchers : Dictionary[AnimTarget, BoneStretcher]

@export var hips_stretcher : BoneStretcher
@export var chest_stretcher : BoneStretcher

@export_tool_button("fill target stretchers") var fts = fill_target_stretchers

@export var noise_threshold := 0.5

@export_tool_button("update auto layers") var ual = update_auto_layers

func update_auto_layers():
	if not current_animation:
		return
	for target in current_animation.tracks:
		current_animation.tracks[target].update_auto_layer(noise_threshold)

@export_tool_button("clear all layers") var cal = clear_all_layers

func clear_all_layers():
	if not current_animation:
		return
	for target in current_animation.tracks:
		current_animation.tracks[target].layer_times.clear()

func fill_target_stretchers():
	var stretchers : Array[BoneStretcher]
	for c in get_skeleton().get_children():
		if c is BoneStretcher:
			stretchers.append(c)
	for target in current_animation.tracks:
		if target.type == AnimTarget.TargetType.BONE:
			for s in stretchers:
				if not s:
					continue
				if s.start_stretch.bone_idx == target._bone_idx:
					target_stetchers[target] = s
					break
		else:
			var names : String = ""
			for i in range(target.node_path.get_name_count()):
				names += (target.node_path.get_name(i).to_lower())
			if "hips" in names:
				target_stetchers[target] = hips_stretcher
				hips_anim_target = target
			elif "chest" in names:
				print("chest in names")
				target_stetchers[target] = chest_stretcher
			else:
				print("chest not in names: ", names)



const FPS = 30.0

@export var bone_filters : Dictionary[String, bool]

@export_tool_button("fill dictionary") var f = fill_bool_dictionary

@export var object_joints: Dictionary[BoneController, KinectJoint]

@export var apply_on_top := false

@export_range(-0.0, 5.0, 1.0/FPS) var current_time : float:
	set(value):
		current_time = value
		if current_animation:
			
			if current_playing_state == PlayingState.PLAYING:
				current_time = minf(current_time, current_animation.duration)
			current_animation.current_time = current_time
			

enum PlayingState{
	PLAYING,
	RECORDING
}

@export var current_playing_state := PlayingState.PLAYING:
	set(value):
		if value == current_playing_state:
			return
		if current_playing_state == PlayingState.RECORDING:
			if current_animation:
				current_animation.duration = current_time
		current_playing_state = value
		if current_playing_state == PlayingState.RECORDING:
			if not current_animation:
				current_animation_name = next_slot
				animations[current_animation_name] = AnimationRes.new()
				current_time = 0.0
			for target in anim_targets:
				current_animation.tracks[target] = AnimTrack.new()

@export var current_frame : int:
	get:
		return floori(current_time * FPS)
	set(frame):
		current_time = float(frame) / FPS

func fill_bool_dictionary():
	for i in get_skeleton().get_bone_count():
		bone_filters[get_skeleton().get_bone_name(i)] = true

@export var animations : Dictionary[String, AnimationRes]

@export var controller_controller : ControllerController

@export var kinect : Kinect

var next_slot : String:
	get:
		var i := 0
		while str(i) in animations.keys():
			i += 1
		return str(i)
			

var current_animation : AnimationRes:
	get:
		if not animations.has(current_animation_name):
			return null
		return animations[current_animation_name]

@export_enum("current_anim_name") var current_animation_name : String:
	set(v):
		current_animation_name = v
		if current_animation:
			fill_target_stretchers()
			current_animation.bind_all(self)

signal animation_updated

@export var current_target : AnimTarget

@export_tool_button("insert keyframe") var i_k = func():
	current_animation.assign_keyframe(current_target, self)

func _validate_property(property: Dictionary) -> void:
	if property.name == "current_animation_name":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for key in animations.keys():
			names.append(key)
		property.hint_string = ",".join(names)

#func fill_bone_tracks(name : String):
	#for key in bone_filters.keys():
		#if bone_filters[key]:
			#var anim_target := AnimTarget.new()
			#anim_target.call_init(AnimTarget.TargetType.BONE,get_path_to(get_skeleton()),self)
			#anim_target.type = AnimTarget.TargetType.BONE
			#anim_target.bone_name = key
			#anim_target.node_path = get_skeleton().get_path()
			#animations[name].tracks[anim_target] = AnimTrack.new()

@export_tool_button("update owner") var u_o = update_owner

func update_owner():
	for anim_name in animations.keys(): #Done to get autocomplete
		animations[anim_name].bind_all(self)

func _process_modification_with_delta(delta: float) -> void:
	
	if current_playing_state == PlayingState.RECORDING:
		await controller_controller.all_updated
		for target in anim_targets:
			current_animation.tracks[target].add_keyframe(KeyFrame.new(target.get_transform(), current_frame))
			if target not in kinect_track_state_target_joints:
				continue
			var kinect_joint := kinect_track_state_target_joints[target]
			var next_joint := kinect_joint.next_node
			if not next_joint:
				next_joint = kinect_joint
			var s1 := kinect_joint.tracked_state
			var s2 := next_joint.tracked_state
			var state : Kinect.TrackingState
			if s1 == Kinect.TrackingState.TRACKED and s2 == Kinect.TrackingState.TRACKED:
				state = Kinect.TrackingState.TRACKED
			elif s1 != Kinect.TrackingState.NOT_TRACKED and s2 != Kinect.TrackingState.NOT_TRACKED:
				state = Kinect.TrackingState.INFERRED
			else:
				state = Kinect.TrackingState.NOT_TRACKED
			#TODO: append if exists
			current_animation.tracks[target].additional_information[current_frame] = [{"tracking_state" : state}]
		current_time += delta
		return
	if apply_on_top:
		if controller_controller:
			await controller_controller.all_updated
	if not current_animation:
		return
	if current_animation.tracks.size() == 0:
		return
	#if (not current_animation.tracks.keys()[0] as AnimTarget).owner:
	if target_stetchers.size() < 1:
		fill_target_stretchers()
	for t in current_animation.tracks:
		var track := current_animation.tracks[t]
		current_animation.tracks[t].current_frame = current_frame
		t.set_transform(current_animation.tracks[t].interpolate_transforms(current_time))
		if track.layer_times.size() > 0:
			t.set_transform(track.interpolate_layers(current_time))
		for a_i in current_animation.tracks[t].get_additional_info(current_frame):
			t.set_additional_info(a_i)
			if t in target_stetchers:
				if not target_stetchers[t]:
					continue
				if "tracking_state" in a_i:
					if not target_stetchers[t].material_override:
						target_stetchers[t].material_override = StandardMaterial3D.new()
					match a_i["tracking_state"]:
						Kinect.TrackingState.TRACKED:
							(target_stetchers[t].material_override as StandardMaterial3D).albedo_color = Color.GREEN
						Kinect.TrackingState.NOT_TRACKED:
							(target_stetchers[t].material_override as StandardMaterial3D).albedo_color = Color.RED
						Kinect.TrackingState.INFERRED:
							(target_stetchers[t].material_override as StandardMaterial3D).albedo_color = Color.YELLOW
						
		
	animation_updated.emit()

var anim_targets : Array[AnimTarget]

var kinect_track_state_target_joints : Dictionary[AnimTarget, KinectJoint]

func _ready() -> void:
	for obj in object_joints:
		var target := AnimTarget.new()
		target.call_init(AnimTarget.TargetType.OBJECT, get_path_to(obj), self)
		anim_targets.append(target)
		kinect_track_state_target_joints[target] = object_joints[obj]
	for bone in bone_filters:
		var target := AnimTarget.new()
		target.call_init(AnimTarget.TargetType.BONE, get_path_to(get_skeleton()), self, bone)
		anim_targets.append(target)
		for joint : KinectJoint in kinect.armature.get_children():
			if joint.bone == target.bone_name:
				kinect_track_state_target_joints[target] = joint
				break
	if current_animation:
		current_animation.bind_all(self)

			
	

	
