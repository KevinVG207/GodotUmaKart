shader_type spatial;
render_mode unshaded, cull_front;

uniform bool enable = true; // on and off switsch to diesable/enable the outline
// outline costumization
uniform float outline_thickness = 1.0; // how thick is the outline?
uniform vec4 color : source_color = vec4(0.0); // which color does the outline have?


void vertex() {
	if (enable) {
	// Extract the scale from the WORLD_MATRIX
	vec3 x_axis = MODEL_MATRIX[0].xyz; // X basis vector
	vec3 y_axis = MODEL_MATRIX[1].xyz; // Y basis vector
	vec3 z_axis = MODEL_MATRIX[2].xyz; // Z basis vector
	vec3 object_scale = vec3(length(x_axis), length(y_axis), length(z_axis));
		
	VERTEX += (normalize(NORMAL) * outline_thickness) / object_scale; // apply the outlines thickness	
	}
}

void fragment() {
	if (enable) {
	ALBEDO = color.rgb; // apply the outlines color
	}
}