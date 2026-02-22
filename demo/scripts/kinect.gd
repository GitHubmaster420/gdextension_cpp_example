@tool
extends Node3D
class_name Kinect


enum TrackingState{
	NOT_TRACKED = 0,
	INFERRED = 1,
	TRACKED = 2
}

const JOINT_COUNT := 25

enum JOINT_DICTIONARY {
	JointType_SpineBase	= 0,
	JointType_SpineMid	= 1,
	JointType_Neck	= 2,
	JointType_Head	= 3,
	JointType_ShoulderLeft	= 4,
	JointType_ElbowLeft	= 5,
	JointType_WristLeft	= 6,
	JointType_HandLeft	= 7,
	JointType_ShoulderRight	= 8,
	JointType_ElbowRight	= 9,
	JointType_WristRight	= 10,
	JointType_HandRight	= 11,
	JointType_HipLeft	= 12,
	JointType_KneeLeft	= 13,
	JointType_AnkleLeft	= 14,
	JointType_FootLeft	= 15,
	JointType_HipRight	= 16,
	JointType_KneeRight	= 17,
	JointType_AnkleRight	= 18,
	JointType_FootRight	= 19,
	JointType_SpineShoulder	= 20,
	JointType_HandTipLeft	= 21,
	JointType_ThumbLeft	= 22,
	JointType_HandTipRight	= 23,
	JointType_ThumbRight	= 24,
}
@export var armature: Node3D
@export var right_foot_c: MeshInstance3D
@export var left_foot_c: MeshInstance3D

@export var pevis: Pelvis
@export var chest: MeshInstance3D

@export var pelvis_offset_basis : Basis
@export var chest_offset_basis : Basis

@export var pelvis_basis_at_start : Basis
@export var chest_offset_at_start : Basis

@export_tool_button("update offsets") var u_o = update_offsets

func update_offsets():
	pelvis_offset_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineBase) as Node3D).global_basis
	chest_offset_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineShoulder) as Node3D).global_basis
	pelvis_basis_at_start = pevis.global_basis
	chest_offset_at_start = chest.global_basis

func update_offsets_tpose():
	pelvis_offset_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineBase) as Node3D).global_basis
	chest_offset_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineShoulder) as Node3D).global_basis

func construct_joints():
	for key : String in JOINT_DICTIONARY.keys():
		var str := key.split("_")[1].to_snake_case()
		var mesh := SphereMesh.new()
		mesh.radius = 0.05
		mesh.height = 0.1
		var mesh_instance := KinectJoint.new()
		mesh_instance.mesh = mesh
		mesh_instance.name = str
		armature.add_child(mesh_instance)
		mesh_instance.owner = self

@export_tool_button("create armature") var create = construct_joints

func copy_locations():
	for c : KinectJoint in armature.get_children():
		c.copy_position()

@export_tool_button("copy locations") var copy = copy_locations

func tpose():
	update_offsets_tpose()
	pevis.calculate_scale()
	pevis.set_target_start_pos()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for c in armature.get_children():
		var m := StandardMaterial3D.new()
		(c as MeshInstance3D).material_override = m
		((c as MeshInstance3D).mesh as SphereMesh).radius = 0.05
		((c as MeshInstance3D).mesh as SphereMesh).height = 0.1


func on_received_message(str : String):
	var bone_array : Array[String]
	bone_array.assign(str.split(";"))
	bone_array.pop_back()
	
	var i := 0
	
	var stuff : Array[Array]
	
	for sub_str in bone_array:
		var sub_arr : Array[String]
		sub_arr.assign(sub_str.split(","))
		var last_element : Array[String]
		last_element.assign(sub_arr[-1].split("-"))
		sub_arr[-1] = last_element[0]
		sub_arr.push_back(last_element[1])
		var kinect_x := -float(sub_arr[0])
		var kinect_y := float(sub_arr[1])
		var kinect_z := -float(sub_arr[2])
		var tracking_state : TrackingState = TrackingState.values()[int(sub_arr[-1])]
		stuff.append([kinect_x, kinect_y, kinect_z, tracking_state])
		var f := func():
			(armature.get_child(i) as Node3D).global_position = Vector3(kinect_x, kinect_y, kinect_z)
			match tracking_state:
				TrackingState.NOT_TRACKED:
					((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.RED
				TrackingState.INFERRED:
					((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.YELLOW
				TrackingState.TRACKED:
					((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.GREEN
		f.call_deferred()
		i += 1
		

func set_joint_color(tracking_state : TrackingState, i):
	match tracking_state:
		TrackingState.NOT_TRACKED:
			((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.RED
		TrackingState.INFERRED:
			((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.YELLOW
		TrackingState.TRACKED:
			((armature.get_child(i) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color.GREEN

func set_joint_location(child_i : int ,arr_i : int, f : float):
	(armature.get_child(child_i) as Node3D).global_position[arr_i] = f
	

func set_leg_forward_dir(right : bool):
	var thigh_id : int 
	var knee_id : int
	var foot_id : int
	var foot_controller : Node3D
	if right:
		thigh_id = JOINT_DICTIONARY.JointType_HipRight
		knee_id = JOINT_DICTIONARY.JointType_KneeRight
		foot_id = JOINT_DICTIONARY.JointType_AnkleRight
		foot_controller = right_foot_c
	else:
		thigh_id = JOINT_DICTIONARY.JointType_HipLeft
		knee_id = JOINT_DICTIONARY.JointType_KneeLeft
		foot_id = JOINT_DICTIONARY.JointType_AnkleLeft
		foot_controller = left_foot_c
	var hip_node := armature.get_child(thigh_id) as KinectJoint
	var knee_node := armature.get_child(knee_id) as KinectJoint
	var foot_node := armature.get_child(foot_id) as KinectJoint
	var hip_to_knee = hip_node.global_position.direction_to(knee_node.global_position)
	var knee_to_foot = knee_node.global_position.direction_to(foot_node.global_position)
	var threshold := 0.95
	var knee_bent := hip_to_knee.dot(knee_to_foot) < threshold
	var forward_dir : Vector3 #just a direction, normalized elsewhere
	if knee_bent:
		forward_dir = (hip_node.global_position + foot_node.global_position) / 2.0 - knee_node.global_position
	else:
		# if knee is straight, use foot controller. Using foot bone would require awaiting for foot to be processed, which would mess up shit
		forward_dir = -foot_controller.global_basis.z -foot_controller.global_basis.y * 0.5
		
	hip_node.forward_dir = forward_dir
	knee_node.forward_dir = forward_dir

func set_arm_forward_dir(right : bool):
	var upper_arm_id : int 
	var elbow_id : int
	var hand_id : int
	var hand_controller : Node3D
	if right:
		upper_arm_id = JOINT_DICTIONARY.JointType_ShoulderRight
		elbow_id = JOINT_DICTIONARY.JointType_ElbowRight
		hand_id = JOINT_DICTIONARY.JointType_WristRight
	else:
		upper_arm_id = JOINT_DICTIONARY.JointType_ShoulderLeft
		elbow_id = JOINT_DICTIONARY.JointType_ElbowLeft
		hand_id = JOINT_DICTIONARY.JointType_WristLeft

	var shoulder_node := armature.get_child(upper_arm_id) as KinectJoint
	var elbow_node := armature.get_child(elbow_id) as KinectJoint
	var hand_node := armature.get_child(hand_id) as KinectJoint
	var shoulder_to_elbow = shoulder_node.global_position.direction_to(elbow_node.global_position)
	var elbow_to_hand = elbow_node.global_position.direction_to(hand_node.global_position)
	var threshold := 0.95
	var elbow_bent := shoulder_to_elbow.dot(elbow_to_hand) < threshold
	var forward_dir : Vector3 #just a direction, normalized elsewhere
	if true:#elbow_bent:
		forward_dir = (shoulder_node.global_position + hand_node.global_position) / 2.0 - elbow_node.global_position
		
	shoulder_node.forward_dir = forward_dir
	elbow_node.forward_dir = forward_dir

func set_spine_forward_dir():
	var pelvis_id := JOINT_DICTIONARY.JointType_SpineBase
	var left_hip_id := JOINT_DICTIONARY.JointType_HipLeft
	var right_hip_id := JOINT_DICTIONARY.JointType_HipRight
	var left_hip_node : KinectJoint = armature.get_child(left_hip_id)
	var right_hip_node : KinectJoint = armature.get_child(right_hip_id)
	var diff := right_hip_node.global_position - left_hip_node.global_position
	var up := Vector3.UP
	var forward := diff.cross(up).normalized()
	var pelvis_node : KinectJoint = armature.get_child(pelvis_id)
	pelvis_node.forward_dir = forward
	
	var chest_id := JOINT_DICTIONARY.JointType_SpineShoulder
	var left_shoulder_id := JOINT_DICTIONARY.JointType_ShoulderLeft
	var right_shoulder_id := JOINT_DICTIONARY.JointType_ShoulderRight
	var left_shoulder_node : KinectJoint = armature.get_child(left_shoulder_id)
	var right_shoulder_node : KinectJoint = armature.get_child(right_shoulder_id)
	diff = right_shoulder_node.global_position - left_shoulder_node.global_position
	forward = diff.cross(up).normalized()
	var chest_node : KinectJoint = armature.get_child(chest_id)
	chest_node.forward_dir = forward
	
func _process(_delta: float) -> void:
	for is_right_foot : bool in [true, false]: # lol
		set_leg_forward_dir(is_right_foot)
		set_arm_forward_dir(is_right_foot)
	if not chest: return
	#set_spine_forward_dir()
	chest.global_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineShoulder) as Node3D).global_basis * chest_offset_basis.inverse() * chest_offset_at_start
	if not pevis: return
	pevis.global_basis = (armature.get_child(JOINT_DICTIONARY.JointType_SpineBase) as Node3D).global_basis * pelvis_offset_basis.inverse() * pelvis_basis_at_start
