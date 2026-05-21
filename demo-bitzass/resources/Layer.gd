@tool
@abstract class_name Layer extends Resource

@export var transforms : Dictionary[int, Transform3D]

@abstract func interpolate(t : float) -> Transform3D

var previous_layer : Layer

@export var index : int = 0

func initiate_transforms_from_previous_layer(times : Array[int]):
	if not previous_layer:
		return
	transforms.clear()
	
	for frame in times:
		var t := frame / AnimPlayerModifier.FPS
		var transform := previous_layer.interpolate(t)
		transforms[frame] = transform


func get_interpolation_info(t : float) -> Vector3: ## x start, y end, z t
	var interpolate_times := transforms.keys()
	interpolate_times.sort()
	var start_frame : float = interpolate_times[-2]
	var end_frame : float = interpolate_times[-1]
	
	var frame : float = t * AnimPlayerModifier.FPS
	
	for i in range(interpolate_times.size()):
		if interpolate_times[i] > frame:
			start_frame = interpolate_times[i - 1]
			end_frame = interpolate_times[i]
			break

	var relative_t := (frame - start_frame) / (end_frame - start_frame)
	
	return Vector3(start_frame, end_frame, relative_t)

func get_velocity(t : float) -> Vector3:
	var start_time : float
	var end_time : float
	
	var dt := 1.0 / AnimPlayerModifier.FPS
	
	if get_interpolation_info(t).z > 0.5:
		start_time = t - dt
		end_time = t
	else:
		start_time = t
		end_time = t + dt
	
	var start_v := interpolate(start_time).origin
	var end_v := interpolate(end_time).origin
	
	var v := (start_v - end_v) / dt
	
	return v

func get_w_velocity(t : float) -> Vector3:
	var start_time : float
	var end_time : float
	
	var dt := 1.0 / AnimPlayerModifier.FPS
	
	if get_interpolation_info(t).z > 0.5:
		start_time = t - dt
		end_time = t
	else:
		start_time = t
		end_time = t + dt
	
	var start_quat := interpolate(start_time).basis.orthonormalized() as Quaternion
	var end_quat := interpolate(end_time).basis.orthonormalized() as Quaternion
	
	var w_v := AnimTrack.angular_velocity([start_quat, end_quat], dt)
	
	return w_v
	
