shader_type canvas_item;

uniform sampler2D light_texture;

void fragment() {
    vec4 light = texture(TEXTURE, UV);
    
    // Где чёрный (0,0,0) — полностью затемнено, где белый — видно.
    float brightness = dot(light.rgb, vec3(0.299, 0.587, 0.114)); // или просто light.r
    
    // Удаляем тёмные участки из CanvasModulate
    COLOR = vec4(0.0, 0.0, 0.0, 1.0 - brightness);
}