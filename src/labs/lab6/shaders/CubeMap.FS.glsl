#version 430

// Input
layout(location = 0) in vec3 world_position;
layout(location = 1) in vec3 world_normal;

// Uniform properties
uniform samplerCube texture_cubemap;
uniform int type;  // 0 = reflect, 1 = refract
uniform vec3 camera_position;

// Output
layout(location = 0) out vec4 out_color;

vec3 myReflect()
{
    // TODO - compute the reflection color value
    vec3 I = normalize(world_position - camera_position);
    vec3 R = reflect(I, normalize(world_normal));
    return texture(texture_cubemap, R).xyz;
}

vec3 myRefract(float refractive_index)
{
    // TODO - compute the refraction color value
    vec3 I = normalize(world_position - camera_position);
    vec3 R = refract(I, normalize(world_normal), 1.00 / refractive_index);
    return texture(texture_cubemap, R).xyz;
}

void main()
{
    if (type == 0)
    {
        out_color = vec4(myReflect(), 1.0);
    }
    else
    {
        out_color = vec4(myRefract(1.33), 1.0);
    }
}
