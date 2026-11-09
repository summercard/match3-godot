shader_type canvas_item;
render_mode unshaded;

// 受击闪白：0 = 原图，1 = 纯白。仅由 battle_hit_reaction.gd 驱动。
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
