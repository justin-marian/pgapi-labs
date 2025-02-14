#version 430

// Input and output topologies
layout(triangles) in;
layout(triangle_strip, max_vertices = 170) out;

// Input
layout(location = 0) in vec2 v_texture_coord[];

// Uniform properties
uniform mat4 View;
uniform mat4 Projection;
uniform int instances;

// TODO(student): Declare other uniforms here
uniform float shrink;

// BONUS(student): Explosion effect
uniform int is_exploding;
uniform float explosion_radius;

// Output
layout(location = 0) out vec2 texture_coord;


void EmitPoint(vec3 pos, vec3 offset)
{
    gl_Position = Projection * View * vec4(pos + offset, 1.0);
    EmitVertex();
}

/// <summary>
/// Random generetor function from: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
/// Used to randomize the explosion effect, choose a random direction for the explosion
/// based on the center of the triangle and explosion center.
/// </summary>
float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    // Triangle points
    vec3 p1 = gl_in[0].gl_Position.xyz;
    vec3 p2 = gl_in[1].gl_Position.xyz;
    vec3 p3 = gl_in[2].gl_Position.xyz;

    const vec3 INSTANCE_OFFSET = vec3(1.25, 0, 1.25);
    const int NR_COLS = 6;

    // TODO(student): Second, modify the points so that the
    // triangle shrinks relative to its center
    vec3 center = (p1 + p2 + p3) / 3.0;

    // BONUS(student): Explosion effect implementation
    // If the explosion flag is set, move the triangle points
    if (is_exploding != 0) {
        vec3 explosion_center = center + vec3(
            (rand(center.xy) - 0.5) * explosion_radius,
            (rand(center.yz) - 0.5) * explosion_radius,
            (rand(center.xz) - 0.5) * explosion_radius
        );

        vec3 explosion_dir = center - explosion_center;
        vec3 explosion_offset = normalize(explosion_dir) * explosion_radius;

        p1 += explosion_offset;
        p2 += explosion_offset;
        p3 += explosion_offset;
    } else {
        p1 = center + (p1 - center) * shrink;
        p2 = center + (p2 - center) * shrink;
        p3 = center + (p3 - center) * shrink;
    }

    for (int i = 0; i <= instances; i++)
    {
        // TODO(student): First, modify the offset so that instances
        // are displayed on `NR_COLS` columns. Test your code by
        // changing the value of `NR_COLS`. No need to recompile.
        int row = i / NR_COLS;
        int col = i % NR_COLS;

        vec3 offset = vec3(col, 0, -row) * INSTANCE_OFFSET;

        texture_coord = v_texture_coord[0];
        EmitPoint(p1, offset);

        texture_coord = v_texture_coord[1];
        EmitPoint(p2, offset);

        texture_coord = v_texture_coord[2];
        EmitPoint(p3, offset);

        EndPrimitive();
    }
}
