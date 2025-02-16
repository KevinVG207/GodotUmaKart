shader_type spatial;
render_mode unshaded, cull_front;

uniform bool enable = true; // on and off switsch to disable/enable the outline
// outline costumization
uniform float outline_thickness = 0.05; // how thick is the outline?
uniform vec4 color : source_color = vec4(0.0); // which color does the outline have?


void vertex() {
	if (enable) {
		// Calculate the scale factor from the object's transform
		mat3 normal_matrix = mat3(MODELVIEW_MATRIX);
		float scale_factor = length(normal_matrix[0]) + length(normal_matrix[1]) + length(normal_matrix[2]);
		scale_factor /= 3.0; // Average scale factor

		// Adjust vertex position to create a consistent outline
		VERTEX += NORMAL * (outline_thickness / scale_factor);
	//VERTEX += NORMAL*outline_thickness; // apply the outlines thickness
	}
}

void fragment() {
	if (enable) {
	ALBEDO = color.rgb; // apply the outlines color
	}
}