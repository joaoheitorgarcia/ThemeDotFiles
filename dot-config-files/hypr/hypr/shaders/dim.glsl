#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// 0.0 = black, 1.0 = original brightness
const float dimFactor = 0.6;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb * dimFactor;
    fragColor = vec4(color, pixColor.a);
}
