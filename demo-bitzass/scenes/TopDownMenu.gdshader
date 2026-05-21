shader_type canvas_item;

uniform int selected_section = -1;
uniform int section_count = 1;

uniform vec4 selected_color : source_color = vec4(1, 1, 1, 1);
uniform vec4 unselected_color : source_color = vec4(0, 0, 0, 1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	int current_section = int(UV.y * float(section_count));
	COLOR = mix(unselected_color, selected_color, float(current_section == selected_section));;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
