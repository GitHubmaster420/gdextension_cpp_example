extends Marker3D
class_name GroundedFoot

var pos_at_start : Vector3

@export var ankle : Marker3D

@export var gizmo : Gizmo:
	set(v):
		if gizmo == v:
			return
		if gizmo:
			gizmo.released.disconnect(on_gizmo_released)
		gizmo = v
		if not gizmo:
			return
		gizmo.released.connect(on_gizmo_released)
		if not is_node_ready():
			return
		on_gizmo_released()

enum PivotMode{
	ON_TOE,
	ON_HEEL
}

var controllable : Marker3D

var pivot_mode := PivotMode.ON_TOE

@export var toe_pivot: Marker3D
@export var heel_pivot: Marker3D

@onready var toe_to_ankle := toe_pivot.position-position
@onready var heel_to_ankle := heel_pivot.position-position

func _ready() -> void:
	pos_at_start = position
	match pivot_mode:
		PivotMode.ON_TOE:
			controllable = toe_pivot
		PivotMode.ON_HEEL:
			controllable = heel_pivot
	if gizmo:
		on_gizmo_released()

func on_gizmo_released():
	match pivot_mode:
		PivotMode.ON_TOE:
			toe_pivot.rotation = controllable.rotation
			controllable = toe_pivot
			gizmo.controllable = controllable.get_child(0)
			(controllable.get_child(0) as GizmoControllable).gizmo = gizmo
			heel_pivot.position = position + basis * heel_to_ankle
		PivotMode.ON_HEEL:
			heel_pivot.rotation = controllable.rotation
			controllable = heel_pivot
			gizmo.controllable = controllable.get_child(0)
			(controllable.get_child(0) as GizmoControllable).gizmo = gizmo
			toe_pivot.position = position + basis * toe_to_ankle
			
func _process(delta: float) -> void:
	if not gizmo:
		return
	if rotation.x < 0:
		pivot_mode = PivotMode.ON_HEEL
	else:
		pivot_mode = PivotMode.ON_TOE
	match pivot_mode:
		PivotMode.ON_TOE:
			var offset := -toe_to_ankle
			rotation = controllable.rotation
			position = toe_pivot.position + basis * offset
			if controllable == toe_pivot:
				heel_pivot.position = position + basis * heel_to_ankle
		PivotMode.ON_HEEL:
			var offset := -heel_to_ankle
			rotation = controllable.rotation
			position = heel_pivot.position + basis * offset
			if controllable == heel_pivot:
				toe_pivot.position = position + basis * toe_to_ankle
