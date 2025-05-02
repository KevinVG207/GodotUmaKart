shader_type spatial;

uniform sampler2D overlay;
uniform float base_scale = 1.0;
instance uniform vec2 offset_in_viewport = vec2(0.5, 0.5);
instance uniform vec2 leaves_random_offset = vec2(0.0);

void fragment() {
	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float scale = base_scale / view_pos.z;
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 centered_uv = SCREEN_UV - 0.5;
	centered_uv.x *= aspect;
	vec2 tex_uv = centered_uv / scale + 0.5;
	tex_uv += vec2((offset_in_viewport.x - 0.5) * -2.0 * aspect/2.0, 0.5 - offset_in_viewport.y) / scale;
	tex_uv += leaves_random_offset;

	vec3 col = vec3(0.0, 1.0, 0.0);
	float brightness = texture(overlay, tex_uv).r * 0.5 + 0.25;
	ALBEDO = col * brightness;
	EMISSION = ALBEDO * 0.1;
}
