shader_type spatial;

uniform sampler2D overlay;
uniform float base_scale = 2.0;

void fragment() {
	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float scale = base_scale / view_pos.z;
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 centered_uv = SCREEN_UV - 0.5;
	centered_uv.x *= aspect;
	vec2 tex_uv = centered_uv / scale + 0.5;

	vec3 col = vec3(0.0, 1.0, 0.0);
	float brightness = texture(overlay, tex_uv).r * 0.5 + 0.25;
	ALBEDO = col * brightness;
	EMISSION = ALBEDO * 0.1;
}
