#version 330

uniform sampler2D MainSampler;
uniform sampler2D DataSampler;
uniform sampler2D BlurSampler;

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 InSize;
};

#moj_import <minecraft:globals.glsl>

#moj_import <shader_selector:marker_settings.glsl>
#moj_import <shader_selector:utils.glsl>
#moj_import <shader_selector:data_reader.glsl>

in vec2 texCoord;

out vec4 fragColor;

void main() {

    // Apply rotation effect
    // Read rotation amount
    float rotationAmount = readChannel(EXAMPLE_ROTATION_CHANNEL);

    // Convert to radians
    float angle = radians(rotationAmount * 360.0);

    // Apply rotation to texture coordinates
    vec2 uv = (texCoord - 0.5) * OutSize;
    uv *= mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = uv / OutSize + 0.5;

    // Show color at texture coordinates
    fragColor = texture(MainSampler, uv);
    // If texture coordinates are out of bounds, show blurred version
    if (uv.x < 0. || uv.x > 1. || uv.y < 0. || uv.y > 1.) {
        fragColor = texture(BlurSampler, (uv - 0.5)*sqrt(0.5) + 0.5);
    }

    // Apply greyscale effect
    // Get full greyscale color
    vec3 greyscale = vec3(dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722)));
    
    // Apply greyscale color
    float greyscaleAmount = readChannel(EXAMPLE_GREYSCALE_CHANNEL);
    fragColor.rgb = mix(fragColor.rgb, greyscale, greyscaleAmount);

//#define DEBUG
#ifdef DEBUG
    // Show data sampler on screen
    if (texCoord.x < .25 && texCoord.y < .25) {
        uv = texCoord * 4.0;
        vec4 col = texture(DataSampler, uv);
        if (uv.x > 1./5.)
            col = vec4(vec3(fract(decodeColor(col))), 1.0);
        fragColor = col;
    }
#endif
}