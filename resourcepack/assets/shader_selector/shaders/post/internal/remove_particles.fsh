#version 150

#moj_import <shader_selector:marker_settings.glsl>

uniform sampler2D ParticlesSampler;

uniform vec2 OutSize;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    ivec2 iCoord = ivec2(gl_FragCoord.xy);
    fragColor = texture(ParticlesSampler, texCoord);
    ivec4 iColor = ivec4(round(fragColor * 255.));
    if (false
        #define ADD_MARKER(i, marker_pos, green, op, r) || marker_pos == iCoord && iColor.rga == ivec3(MARKER_RED, green, 255)
        LIST_MARKERS
    ) {
        fragColor = texture(ParticlesSampler, texCoord + vec2(1./OutSize.x, 0.0));
    }
}
