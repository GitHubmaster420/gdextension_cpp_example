@tool
extends Resource
class_name NestedCubicCurve

@export var a : float = -1:
	set(v):
		a = v
		changed.emit()
@export var b : float = 2:
	set(v):
		b = v
		changed.emit()
@export var c : float = -1:
	set(v):
		c = v
		changed.emit()
@export var d : float = 2:
	set(v):
		d = v
		changed.emit()

enum CurvePresets{
	SUPER_S,
	LINEAR,
	SINGLE_S
}

const CURVE_DIC : Dictionary[CurvePresets, Array]= {
	CurvePresets.SUPER_S : [1, 0, 1, 0],
	CurvePresets.LINEAR : [-1, 2, -1, 2],
	CurvePresets.SINGLE_S : [1, 0, -1, 2]
	
}

func interpolate(t : float) -> float:
	return cubic_interpolate(0, 1, a, b, cubic_interpolate(0, 1, c, d, t))

static func create_preset(preset : CurvePresets) -> NestedCubicCurve:
	return create_curve.callv(CURVE_DIC[preset])

static func create_curve(_a : float, _b : float, _c : float, _d : float) -> NestedCubicCurve:
	var n := new()
	n.a = _a
	n.b = _b
	n.c = _c
	n.d = _d
	return n
