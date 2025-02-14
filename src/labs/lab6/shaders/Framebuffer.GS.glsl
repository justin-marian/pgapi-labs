#version 430

layout(triangles) in;
// TODO(student): Update max_vertices
layout(triangle_strip, max_vertices = 18) out;

uniform mat4 View;
uniform mat4 Projection;
uniform mat4 viewMatrices[6];

in vec3 geom_position[3];
in vec2 geom_texture_coord[3];

out vec3 frag_position;
out vec2 frag_texture_coord;

void main()
{
    int face, i;
    // TODO(student): Update the code to compute the position from each camera view 
    // in order to render a cubemap in one pass using gl_Layer. Use the "viewMatrices"
    // attribute according to the corresponding layer.
    // 0	GL_TEXTURE_CUBE_MAP_POSITIVE_X
    // 1	GL_TEXTURE_CUBE_MAP_NEGATIVE_X
    // 2	GL_TEXTURE_CUBE_MAP_POSITIVE_Y
    // 3	GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
    // 4	GL_TEXTURE_CUBE_MAP_POSITIVE_Z
    // 5	GL_TEXTURE_CUBE_MAP_NEGATIVE_Z

    for (int layer = 0; layer < 6; ++layer)
    {
        gl_Layer = layer;
        for (int i = 0; i < gl_in.length(); i++)
        {
            frag_position = geom_position[i];
            frag_texture_coord = geom_texture_coord[i];
            gl_Position = Projection * viewMatrices[layer] * gl_in[i].gl_Position;
            EmitVertex();
        }
        EndPrimitive();
    }
}