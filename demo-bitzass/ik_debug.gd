@tool
extends Node3D
@onready var thigh: Marker3D = $Thigh
@onready var shin: Marker3D = $Thigh/Shin
@onready var foot: Marker3D = $Thigh/Shin/Foot

@onready var start_foot: Node3D = $"../StartFoot"
@onready var start_hip: Node3D = $"../StartHip"
@onready var end_foot: Node3D = $"../EndFoot"
@onready var end_hip: Node3D = $"../EndHip"
@onready var gizmo: Gizmo = %Gizmo
@onready var h_scroll_bar: HScrollBar = $"../CanvasLayer/HScrollBar"

@onready var hermite_start_pivot_thigh: Marker3D = $HermiteStartPivotThigh
@onready var hermite_start_pivot_shin: Marker3D = $HermiteStartPivotThigh/HermiteStartPivotShin
@onready var hermite_start_pivot_foot: Marker3D = $HermiteStartPivotThigh/HermiteStartPivotShin/HermiteStartPivotFoot

@onready var hermite_end_pivot_thigh: Marker3D = $HermiteEndPivotThigh
@onready var hermite_end_pivot_shin: Marker3D = $HermiteEndPivotThigh/HermiteEndPivotShin
@onready var hermite_end_pivot_foot: Marker3D = $HermiteEndPivotThigh/HermiteEndPivotShin/HermiteEndPivotFoot


var thigh_length : float
var shin_length : float

@export var active := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thigh_length = thigh.global_position.distance_to(shin.global_position)
	shin_length = shin.global_position.distance_to(foot.global_position)

var current := -1

var current_pivot := -1

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_S:
				current += 1
				if current > 3:
					current = 0
				match current:
					0:
						gizmo.controllable = start_hip.get_child(0)
					1:
						gizmo.controllable = start_foot.get_child(0)
					2:
						gizmo.controllable = end_hip.get_child(0)
					3:
						gizmo.controllable = end_foot.get_child(0)
			elif event.keycode == KEY_T:
				current_pivot += 1
				if current_pivot > 3:
					current_pivot = 0
				match current_pivot:
					0:
						gizmo.controllable = hermite_start_pivot_thigh.get_child(0)
					1:
						gizmo.controllable = hermite_start_pivot_shin.get_child(0)
					2:
						gizmo.controllable = hermite_end_pivot_thigh.get_child(0)
					3:
						gizmo.controllable = hermite_end_pivot_shin.get_child(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not active and Engine.is_editor_hint():
		return
	
	var ik_interp := IkInterpstatic.get_fk_hermite_interpolation(start_hip.global_position, start_foot.global_position, start_hip.global_rotation.y,
	Quaternion.from_euler(hermite_start_pivot_thigh.global_rotation), Quaternion.from_euler(hermite_start_pivot_shin.rotation),
	end_hip.global_position, end_foot.global_position, end_hip.global_rotation.y, Quaternion.from_euler(hermite_end_pivot_thigh.global_rotation), Quaternion.from_euler(hermite_end_pivot_shin.rotation), thigh_length, shin_length, h_scroll_bar.value)
	thigh.global_position = start_hip.global_position.lerp(end_hip.global_position,  ease(h_scroll_bar.value, 3.2))
	thigh.global_rotation = ik_interp[0].get_euler()
	shin.rotation = ik_interp[1].get_euler()
	foot.global_rotation = QuaternionExtender.bezier_quat(
		Quaternion.from_euler(start_foot.global_rotation),
		Quaternion.from_euler(hermite_end_pivot_foot.global_rotation),
		Quaternion.from_euler(hermite_end_pivot_foot.global_rotation),
		Quaternion.from_euler(end_foot.global_rotation), h_scroll_bar.value).get_euler()
