shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 local_uv = UV - vec2(0.5);
	vec2 uv_sqrd = local_uv * local_uv;
	COLOR.a = mix(0.0, 1.0, step(uv_sqrd.x + uv_sqrd.y, 0.25));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
