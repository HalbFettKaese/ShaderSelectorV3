#version 330

#moj_import <shader_selector:utils.glsl>

uniform sampler2D MainSampler;
uniform sampler2D DataSampler;
uniform sampler2D BlurSampler;

uniform vec2 OutSize;
uniform float GameTime;

in vec2 texCoord;

out vec4 fragColor;

void main() {

    float greyscaleChannel = decodeColor(texelFetch(DataSampler, ivec2(4, EXAMPLE_GREYSCALE_CHANNEL), 0));
    float rotationChannel = decodeColor(texelFetch(DataSampler, ivec2(4, EXAMPLE_ROTATION_CHANNEL), 0));

    float angle = radians(rotationChannel * 360.0);

    vec2 uv = (texCoord - 0.5) * OutSize;

    uv *= mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

    uv = uv / OutSize + 0.5;

    fragColor = texture(MainSampler, uv);

    if (uv.x < 0. || uv.x > 1. || uv.y < 0. || uv.y > 1.) {
        fragColor = texture(BlurSampler, (uv - 0.5)*sqrt(0.5) + 0.5);
    }

    vec3 greyscale = vec3(dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722)));
    fragColor.rgb = greyscale + (fragColor.rgb - greyscale) * (1. - greyscaleChannel);

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