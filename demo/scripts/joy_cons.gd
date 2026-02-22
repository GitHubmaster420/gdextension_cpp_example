extends Node3D
class_name JoyCons
@export var joy_cons: Node3D

@export var copy_modifier: CopyModifierPose
@export var copy_right_foot_modifier : CopyModifierPose

@export var kinect: Kinect

@export var skeleton_3d: Skeleton3D

var velocity := Vector3.ZERO

var peer := PacketPeerUDP.new()

var port := 5005

var gravity := Vector3.DOWN * 9.81

var joycon_manager : JoyConManagerGD

var is_right_array : Array[bool]


func _ready() -> void:
	var creat_mesh_indices := [1]
	peer.bind(port)
	joycon_manager = JoyConManagerGD.new()
	joycon_manager.discover_devices()
	is_right_array.assign(joycon_manager.get_is_right())
	for i in range(joycon_manager.get_device_count()):
		var joy_con := JoyCon.new()
		joy_con.is_right_joycon = is_right_array[i]
		joy_con.name = "joy_con_" + str(i)
		joy_cons.add_child(joy_con)
		if i not in creat_mesh_indices:
			continue
		var mesh := BoxMesh.new()
		var m_i := MeshInstance3D.new()
		m_i.mesh = mesh
		joy_con.add_child(m_i)
	

var basis_at_start : Basis

const GYRO_SCALE := 0.070

const ACCEL_SCALE := 1.0 / (403.0 * 1.1) #Between 402 and 404 most of the time, used to convert to m/s**2

var reference_basis : Basis
var joycon_basis := Basis()

func construct_joycon_basis(g : Vector3):
	joycon_basis.y = -g.normalized()
	var temp_z := Vector3.BACK
	joycon_basis.x = temp_z.cross(joycon_basis.y).normalized()
	joycon_basis.z = joycon_basis.y.cross(joycon_basis.x).normalized()
	reference_basis = joycon_basis

enum JoyConOrientation{
	FORWARD,
	RIGHT,
	BACK,
	LEFT
}

var orientation := JoyConOrientation.FORWARD

func rotate_90_deg():
	if orientation == JoyConOrientation.LEFT:
		orientation = JoyConOrientation.FORWARD
		return
	orientation += 1
	
#func swap_accel_axes(a: Vector3) -> Vector3:
	##basis: [X: (1.0, 0.0, 0.0), Y: (0.0, 1.0, 0.0), Z: (0.0, 0.0, 1.0)]
	#return Vector3(a.y, -a.z, -a.x)
	##basis: [X: (-0.0, 0.0, -1.0), Y: (0.0, 1.0, 0.0), Z: (1.0, 0.0, -0.0)]
	#return Vector3(a.x, -a.z, a.y)
	##basis: [X: (1.0, 0.0, 0.0), Y: (0.0, -0.0, 1.0), Z: (0.0, -1.0, -0.0)]
	#return Vector3(a.y, -a.x, a.z)

var first_right_joycon : JoyCon

var zr_pressed := false
var r_pressed := false
var a_pressed := false
var b_pressed := false

var time : float = -INF

func point_at_screen(a : Vector3):
	construct_joycon_basis(a)
	calibrated = false
	reset_j()

func reset_j():
	velocity = Vector3.ZERO

var calibrated := false
var gravity_q : Quaternion

var prev_time := -INF

var started := false

var right_joycons : Array[JoyCon]
var left_joycons : Array[JoyCon]

@export var right_arm_node : Node3D

func _physics_process(delta: float) -> void:
	var frames := joycon_manager.get_imu_frames()
	for i in range(joycon_manager.get_device_count()):
		pass
		#(joy_cons.get_child(i) as JoyCon).update_joycon(frames[i], delta)
	#if peer.get_available_packet_count() == 0:
		#return
	#var arr : Array = JSON.parse_string(peer.get_packet().get_string_from_ascii())
	#for dic : Dictionary in arr:
		#if not started:
			#started = true
			#var right : Array[Dictionary]
			#right.assign(dic["right_joycons"])
			#var i := 0
			#for joycon_d in right:
				#var joycon := JoyCon.new()
				#if not first_right_joycon:
					#first_right_joycon = joycon
					#print("creating first right joycon")
				#joycon.name = "JoyConRight" + str(i)
				#joycon.global_position = Vector3.ZERO
				#joy_cons.add_child(joycon)
				#joycon.global_basis = Basis.IDENTITY
				## Vector3(basis_at_start.x.dot(Vector3.UP) * -a.z, basis_at_start.y.dot(Vector3.BACK) * -a.x, basis_at_start.z.dot(Vector3.RIGHT) * a.y)
				#joycon.basis_at_start = joycon.global_basis
				#right_joycons.append(joycon)
				#joycon.kinect = kinect
				#copy_modifier.target = joycon
				#joycon.copy_modifier = copy_modifier
				#
				##var mesh := BoxMesh.new()
				##var mesh_instance := MeshInstance3D.new()
				##mesh_instance.mesh = mesh
				##joycon.add_child(mesh_instance)
				#joycon.arm_node = right_arm_node
			#var left : Array[Dictionary]
			#left.assign(dic["left_joycons"])
			#i = 0
			#for joycon_d in left:
				#var joycon := JoyCon.new()
				#joycon.is_right_joycon = false
				#joycon.name = "JoyConLeft" + str(i)
				#joy_cons.add_child(joycon)
				#left_joycons.append(joycon)
				#joycon.kinect = kinect
				#copy_right_foot_modifier.target = joycon
				#joycon.copy_modifier = copy_right_foot_modifier
				#joycon.foot_id = skeleton_3d.find_bone("foot.R")
				#joycon.skeleton = skeleton_3d
				#first_right_joycon.idk.connect(func(): joycon.upcoming_calibration = true)
				#print("connecting signal")
				#joycon.current_target = JoyCon.Target.RIGHT_FOOT
				#var mesh := TextMesh.new()
				#mesh.text = char(randi_range(1, 297334))
				#var mesh_instance := MeshInstance3D.new()
				#mesh_instance.mesh = mesh
				#joycon.add_child(mesh_instance)
		#
		#
		#var d_r : Array[Dictionary]
		#d_r.assign(dic["right_joycons"])
		#var d_l : Array[Dictionary]
		#d_l.assign(dic["left_joycons"])
		#var t : float = dic["time"]
		#var dt : float
		#if prev_time == -INF:
			#dt = 0
		#else:
			#dt = t - prev_time
		#prev_time = t
		#for i in range(right_joycons.size()):
			#right_joycons[i].update_joycon(d_r[i], dt)
		#for i in range(left_joycons.size()):
			#left_joycons[i].update_joycon(d_l[i], dt)
