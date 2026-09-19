shader_type sky;

// --- Stars ---
uniform vec3 top_color : source_color = vec3(0.01, 0.02, 0.06);
uniform vec3 horizon_color : source_color = vec3(0.04, 0.05, 0.10);
uniform float star_count : hint_range(10.0, 20000.0) = 3000.0;
uniform float star_size_px : hint_range(0.01, 5.0) = 1;
uniform float star_brightness : hint_range(0.0, 5.0) = 1;
uniform float twinkle_speed : hint_range(0.0, 50.0) = 8;

// --- Clouds ---
uniform float cloud_scale : hint_range(0.5, 10.0) = 3.0;
uniform float cloud_speed : hint_range(0.0, 1.0) = 0.03;
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.01, 1.0) = 0.25;
uniform float density : hint_range(0.1, 5.0) = 1.5;
uniform vec3 cloud_color : source_color = vec3(0.15, 0.16, 0.22); // dim, night-tinted clouds
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.5; // master fade for clouds (e.g. clear-sky control)

vec2 hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// --- Cloud noise (3D, separate hash so it doesn't collide with star hash) ---
float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float cloud_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(mix(hash3(i + vec3(0,0,0)), hash3(i + vec3(1,0,0)), f.x),
			mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x),
			mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y),
		f.z
	);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amp * cloud_noise(p);
		p *= 2.02;
		amp *= 0.5;
	}
	return value;
}

float get_cloud_coverage(vec3 dir) {
	if (dir.y < 0.01) {
		dir.y = 0.01;
	}
	vec2 cloud_uv = dir.xz / dir.y;
	cloud_uv *= cloud_scale * 0.1;
	cloud_uv += TIME * cloud_speed;

	float n = fbm(vec3(cloud_uv, TIME * 0.01));
	float cloud = smoothstep(coverage - softness, coverage + softness, n);
	cloud = pow(cloud, density);

	// fade near/below horizon so it doesn't smear sideways
	float fade = smoothstep(0.0, 0.2, dir.y);
	cloud *= fade;
	cloud *= cloud_opacity;

	return clamp(cloud, 0.0, 1.0);
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	float height_grad = smoothstep(-0.05, 0.4, dir.y);
	vec3 sky_color = mix(horizon_color, top_color, height_grad);

	// --- Stars ---
	float u = atan(dir.z, dir.x) / (2.0 * 3.14159265) + 0.5;
	float v = (dir.y + 1.0) * 0.5;
	vec2 uv = vec2(u, v);

	float freq = sqrt(star_count / 2.0);
	vec2 scaled = uv * freq;
	vec2 base_cell = floor(scaled);
	vec2 local = fract(scaled);

	vec2 px = max(fwidth(scaled), vec2(0.0001));

	float best_dist_px = 1e6;
	float best_hash = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 cell = base_cell + neighbor;
			float exists = step(0.5, hash1(cell));
			if (exists > 0.5) {
				vec2 jitter = hash2(cell + 7.0);
				vec2 point_pos = neighbor + jitter;
				vec2 diff_px = (local - point_pos) / px;
				float d_px = length(diff_px);
				if (d_px < best_dist_px) {
					best_dist_px = d_px;
					best_hash = hash1(cell);
				}
			}
		}
	}

	float aa_px = 0.90;
	float star = 0.088 - smoothstep(star_size_px - aa_px, star_size_px + aa_px, best_dist_px);
	star *= star_brightness;
	star *= smoothstep(-0.02, 0.25, dir.y);

	// --- Clouds ---
	float cloud = get_cloud_coverage(dir);

	// Stars get dimmed/hidden behind cloud coverage
	float star_visibility = 1.0 - cloud;
	vec3 base_color = sky_color + vec3(star) * star_visibility;

	// Composite clouds over the star sky
	vec3 final_color = mix(base_color, cloud_color, cloud);

	COLOR = final_color;
}