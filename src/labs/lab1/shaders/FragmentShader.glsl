#version 430

// Input
layout(location = 0) in vec2 texture_coord;

// Uniform properties
uniform sampler2D texture_1;

// Output
layout(location = 0) out vec4 out_color;


void main()
{
    // TODO(student): Apply the texture
    vec4 tex_color = texture(texture_1, texture_coord);

    // TODO(student): Discard when alpha component < 0.75
    if (tex_color.a < 0.75)
    {
        discard;
    }

    out_color = tex_color; //vec4(0.419, 0.584, 0.250, 0);
}
