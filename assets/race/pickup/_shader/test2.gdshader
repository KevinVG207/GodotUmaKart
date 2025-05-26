shader_type spatial;

uniform sampler2D tex;
uniform sampler2D normal;
uniform float base_scale = 4.0;
instance uniform vec2 offset_in_viewport = vec2(0.5, 0.5);
instance uniform float rot_offset = 0.0;

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return vec2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x
	) + pivot;
}

void fragment() {
	vec4 view_pos = VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float scale = base_scale / view_pos.z;
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 centered_uv = SCREEN_UV - 0.5;
	centered_uv.x *= aspect;
	vec2 tex_uv = centered_uv / scale + 0.5;
	tex_uv += vec2((offset_in_viewport.x - 0.5) * -2.0 * aspect/2.0, 0.5 - offset_in_viewport.y) / scale;
	vec2 non_rotated_uv = tex_uv;
	tex_uv = rotateUV(tex_uv, vec2(0.5), TIME + rot_offset);
	float brightness_offset = texture(normal, non_rotated_uv * 1.2).r * 0.8;
	ALBEDO = 2.5 * texture(tex, tex_uv).rgb - brightness_offset;
	EMISSION = ALBEDO * 0.1;
	SPECULAR = clamp(brightness_offset, 0.0, 1.0) * 3.0;
}