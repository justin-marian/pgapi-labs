#version 430

// Uniform properties
uniform sampler2D texture_position;   // G-buffer position texture
uniform sampler2D texture_normal;     // G-buffer normal texture

uniform ivec2 resolution;             // Screen resolution
uniform vec3 eye_position;            // Camera/eye position
uniform vec3 light_position;          // Light position
uniform vec3 light_color;             // Light color
uniform float light_radius;           // Light radius

// Output
layout(location = 0) out vec4 out_color;

// Local variables and constants
const vec3 LD = vec3(0.8);            // Diffuse factor
const vec3 LS = vec3(0.5);            // Specular factor
const float SHININESS = 32.0;         // Specular exponent

// Computes the Phong lighting contribution for a fragment
// w_pos - world space position of the fragment
// w_N   - world space normal vector of the fragment
vec3 PhongLight(vec3 w_pos, vec3 w_N)
{
    // Compute light direction and distance
    vec3 L = normalize(light_position - w_pos);
    float dist = distance(light_position, w_pos);

    // Ignore fragments outside the light's influence radius
    if (dist > light_radius)
        return vec3(0);

    // Attenuation factor (quadratic falloff)
    float att = max(1.0 - (dist / light_radius), 0.0);
    att = att * att;

    // Diffuse component
    float diff = max(dot(w_N, L), 0.0);
    vec3 diffuse = LD * diff;

    // Specular component (Phong reflection)
    vec3 V = normalize(eye_position - w_pos); // View direction
    vec3 H = normalize(L + V);                // Halfway vector
    float spec = pow(max(dot(w_N, H), 0.0), SHININESS);
    vec3 specular = LS * spec;

    // Combine results
    return att * (diffuse + specular) * light_color;
}

void main()
{
    // Calculate texture coordinates
    vec2 tex_coord = gl_FragCoord.xy / resolution;

    // Sample G-buffer textures
    vec3 wPos = texture(texture_position, tex_coord).xyz;  // World-space position
    vec3 wNorm = normalize(texture(texture_normal, tex_coord).xyz); // World-space normal

    // Compute Phong lighting
    vec3 lighting = PhongLight(wPos, wNorm);

    // Output final color
    out_color = vec4(lighting, 1.0);
}
