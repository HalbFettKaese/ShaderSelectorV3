#version 150

out vec2 texCoord;

vec2[] corners = vec2[](
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
    vec2(1.0, 0.0),
    vec2(1.0, 1.0)
);

void main() {
    texCoord = corners[gl_VertexID % 4];
    gl_Position = vec4(texCoord * 2. - 1., 0., 1.);
}
