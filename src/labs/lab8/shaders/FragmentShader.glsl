#version 410

// Input
layout(location = 0) in vec2 texture_coord;

// Uniform properties
uniform sampler2D textureImage;
uniform ivec2 screenSize;

uniform int flipVertical;
uniform int outputMode;  // 0: original, 1: grayscale, 2: blur, 3: optimized median, 4: sobel
uniform int radius;

uniform float threshold;

// Output
layout(location = 0) out vec4 out_color;

// Local variables
vec2 textureCoord = clamp(vec2(texture_coord.x, (flipVertical != 0) ? 1.0 - texture_coord.y : texture_coord.y), 0.0, 1.0); // Flip texture


const mat3 Gy = mat3(
                     +1, +2, +1, // -1, -2, -1
                      0,  0,  0, //  0,  0,  0
                     -1, -2, -1  // +1, +2, +1
                    );
const mat3 Gx = mat3(
                     +1,  0,  -1, // -1,  0,  +1
                     +2,  0,  -2, // -2,  0,  +2
                     +1,  0,  -1  // -1,  0,  +1
                    );


float gray_nuance(vec4 pixel)
{
    return 0.21 * pixel.r + 0.71 * pixel.g + 0.07 * pixel.b;
}


vec4 median()
{
    int radius = 4;
    vec4 sorted[64];
    vec2 texelSize = 1.0f / screenSize;

    int index = 0;

    for (int i = -radius; i <= radius; i++)
    {
        for (int j = -radius; j <= radius; j++)
        {
            sorted[index] = texture(textureImage, textureCoord + vec2(i, j) * texelSize);
			index++;
        }
    }

    for (int i = 0; i < (2 * radius + 1) * (2 * radius + 1); ++i)
    {
        for (int j = 0; j <= (2 * radius + 1) * (2 * radius + 1); ++j)
        {
            if (gray_nuance(sorted[i]) > gray_nuance(sorted[j]))
            {
                vec4 aux = sorted[i];
                sorted[i] = sorted[j];
                sorted[j] = aux;
            }
        }
    }

    return sorted[(2 * radius + 1) * (2 * radius + 1) / 2];
}


vec4 grayscale()
{
    vec4 color = texture(textureImage, textureCoord);
    float gray = 0.21 * color.r + 0.71 * color.g + 0.07 * color.b;
    return vec4(gray, gray, gray, color.a);
}


vec4 blur(int blurRadius)
{
    vec2 texelSize = 1.0f / screenSize;
    vec4 sum = vec4(0);

    for (int i = -blurRadius; i <= blurRadius; i++)
    {
        for (int j = -blurRadius; j <= blurRadius; j++)
        {
            sum += texture(textureImage, textureCoord + vec2(i, j) * texelSize);
        }
    }

    float samples = pow((2 * blurRadius + 1), 2);
    return sum / samples;
}


vec4 sobel()
{
    vec2 texelSize = 1.0f / screenSize;
    vec2 sum = vec2(0);

    for (int i = -1; i <= 1; ++i)
    {
        for (int j = -1; j <= 1; ++j) 
        {
            vec4 color = texture(textureImage, textureCoord + vec2(i + 1, j + 1) * texelSize);
            sum.x += gray_nuance(color) * Gx[i + 1][j + 1];
            sum.y += gray_nuance(color) * Gy[i + 1][j + 1];
        }
    }

    float magnitude = length(sum);
    float outputValue = (magnitude >= threshold) ? 0.0 : 1.0;

    return vec4(vec3(outputValue), 1.0);
}


void main()
{
    switch (outputMode)
    {
    case 1: // Grayscale
        out_color = grayscale();
        break;
    case 2: // Blur
        out_color = blur(radius);
        break;
    case 3: // Median
        out_color = median();
        break;
    case 4: // Sobel
        out_color = sobel();
        break;
    default: // Original Texture
        out_color = texture(textureImage, textureCoord);
        break;
    }
}
