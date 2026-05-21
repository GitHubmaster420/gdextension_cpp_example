shader_type canvas_item;

uniform int chunks = 4;
uniform int selected_chunk = -1;

uniform vec3 selected_color : source_color;
uniform vec3 unselected_color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv_local = UV - vec2(0.5);
	COLOR.a = mix(0, 1, float(uv_local.x*uv_local.x + uv_local.y*uv_local.y < 0.25));
	float angle = atan(uv_local.y, -uv_local.x);
	float angle_divisor = PI * 2.0 / float(chunks);
	float angle_pos = angle + PI;
	int this_chunk = int(angle_pos / angle_divisor + 0.5);
	COLOR.rgb = mix(unselected_color, selected_color, float(this_chunk % chunks == selected_chunk));;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
