#version 430

// Input
layout(location = 0) in vec3 v_position;
layout(location = 1) in vec3 v_normal;
layout(location = 2) in vec2 v_texture_coord;

// TODO (student): Add the new attributes neccessary for skinning
layout(location = 3) in ivec4 v_bone_ids;
layout(location = 4) in vec4 v_bone_weights;

const int MAX_BONES = 200;

// Uniform properties
uniform mat4 Model;
uniform mat4 View;
uniform mat4 Projection;

// TODO (student): Declare a new uniform variable array, which will
// receive the bone transformations
uniform mat4 bones[MAX_BONES];

// Output
layout(location = 0) out vec2 texture_coord;
// TODO (student): Send the normal to the fragment shader
layout(location = 1) out vec3 frag_normal;

void main()
{
    // TODO (student): Compute the final bone transformation
    mat4 bone_transform = mat4(0.0);

    bone_transform += v_bone_weights[0] * bones[v_bone_ids[0]];
    bone_transform += v_bone_weights[1] * bones[v_bone_ids[1]];
    bone_transform += v_bone_weights[2] * bones[v_bone_ids[2]];
    bone_transform += v_bone_weights[3] * bones[v_bone_ids[3]];

    vec4 skinned_position = bone_transform * vec4(v_position, 1.0);
    vec3 skinned_normal = mat3(bone_transform) * v_normal;

    texture_coord = v_texture_coord;
    
    // TODO (student): Compute the normal
    frag_normal = normalize(mat3(Model) * skinned_normal);

    // TODO (student): Apply the bone transformation on the vertex position
    gl_Position = Projection * View * Model * skinned_position;
}
