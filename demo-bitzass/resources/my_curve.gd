@abstract class_name MyCurve extends Resource

signal t_set(t : float)

@export_range(0.0, 1.0, 0.01) var current_t := 0.0:
	set(t):
		current_t = t
		t_set.emit(t)
		bake_if_possible(get_required_args())

@export var point_count := 100:
	set(v):
		if v == point_count:
			return
		point_count = v
		bake_if_possible(get_required_args())
		

@abstract func get_required_args() -> Array

@export var points : Array[float]

func bake_if_possible(args : Array):
	for arg in args:
		if typeof(arg) == TYPE_NIL:
			print("did not bake")
			return
	changed.emit()
	bake()

func bake(resolution := point_count):
	var _points : Array[float]
	var original : Array[Vector2]
	for i in range(resolution):
		original.append(interpolate_normalized(float(i) / float(resolution)))
	var current_x := 0
	var prev_point := Vector2.ZERO
	for point in original:
		var point_x := int(point.x * float(resolution))
		if point_x > current_x:
			var amount := point_x - current_x
			for i in range(amount):
				_points.append(lerpf(prev_point.y, point.y, float(i) / amount))
			prev_point = point
			current_x = point_x
	_points.append(1.0)
	points = _points
@abstract func interpolate_normalized(t : float) -> Vector2

func interpolate_baked(t : float) -> float:
	t = clampf(t, 0.0, 1.0)
	return points[int(t * float(points.size() - 1))]
