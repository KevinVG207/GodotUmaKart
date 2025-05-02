shader_type spatial;

uniform sampler2D normal;
uniform float base_scale = 2.0;

void fragment() {
	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float scale = base_scale / view_pos.z;
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 centered_uv = SCREEN_UV - 0.5;
	centered_uv.x *= aspect;
	vec2 tex_uv = centered_uv / scale + 0.5;
	
	float diff = dot(VIEW, NORMAL);
	vec3 col = vec3(1.5);
	if (diff > 0.5) {
		col = vec3(0.7, 0.2, 0.0) * 1.2;
	}
	float brightness_offset = texture(normal, tex_uv * 1.2).r * 0.2;
	ALBEDO = col + brightness_offset;
	EMISSION = ALBEDO * 0.1;
	SPECULAR = clamp(brightness_offset, 0.0, 1.0) * 3.0;
}
