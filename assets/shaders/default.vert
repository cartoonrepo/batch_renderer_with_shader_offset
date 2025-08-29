#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec4 color;
layout (location = 2) in vec2 offset;

out vec4 v_color;

uniform mat4 projection;

void main() {
    v_color = color;

    vec2 pos = position + offset;
    gl_Position = projection * vec4(pos, 0.0f, 1.0f);
}
