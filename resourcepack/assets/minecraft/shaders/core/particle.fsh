#version 150

#moj_import <minecraft:fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

// ShaderSelector
#moj_import <shader_selector:marker_settings.glsl>

flat in int isMarker;
flat in ivec4 iColor;

void main() {
    // ShaderSelector
    if (isMarker == 1) {
        fragColor = vec4(iColor.rgb, 255) / 255.0;
        ivec2 iCoord = ivec2(gl_FragCoord.xy);
        if (
            (iCoord.x + iCoord.y) % 2 != 0
            #define ADD_MARKER(i, marker_pos, green, op, rate) || iCoord != marker_pos && iColor.g == green
            LIST_MARKERS
        ) {
            discard;
        }
        return;
    }
    // Vanilla code
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
