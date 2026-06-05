shader_type canvas_item;
render_mode unshaded;

uniform vec4 silhouette_color : source_color = vec4(0.62, 0.60, 0.55, 0.88);

void fragment() {
	float portrait_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(silhouette_color.rgb, portrait_alpha * silhouette_color.a);
}
