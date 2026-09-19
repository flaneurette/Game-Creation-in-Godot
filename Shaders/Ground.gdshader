shader_type spatial;

// #333333. ALBEDO is linear, so this is the sRGB value 0.2 converted to linear.
const vec3 GROUND_COLOR = vec3(0.0001);

void fragment() {
	ALBEDO = GROUND_COLOR;
}
