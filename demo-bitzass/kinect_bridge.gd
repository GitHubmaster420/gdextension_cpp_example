extends KinectBridge
class_name KinectBridgeConverter

@export var kinect : Kinect

func _ready() -> void:
	joint_positions.resize(Kinect.JOINT_COUNT)
	start()

func _exit_tree() -> void:
	stop()


var joint_positions : PackedFloat32Array
var tracked_at_start := false
func _physics_process(delta: float) -> void:
	#print("joint positions before: ", joint_positions)
	#fill_joint_positions(joint_positions)
	#print("joint positions after: ", joint_positions)
	
	fill_joint_positions()
	
	
	if not tracked_at_start:
		tracked_at_start = true
		
		for i in range(0, Kinect.JOINT_COUNT):
			var tr_state := (int(get_array_value(i * 4 + 3)))
			kinect.set_joint_color(tr_state, i)
			if tr_state != Kinect.TrackingState.TRACKED:
				tracked_at_start = false
				return
	
	for i in range(0, Kinect.JOINT_COUNT):
		var tr_state := (int(get_array_value(i * 4 + 3)))
		kinect.set_joint_color(tr_state, i)
		if tr_state == Kinect.TrackingState.NOT_TRACKED:
			return
		kinect.set_joint_location(i, 0, -get_array_value(i * 4))
		kinect.set_joint_location(i, 1, get_array_value(i * 4 + 1))
		kinect.set_joint_location(i, 2, -get_array_value(i * 4 + 2))
	
