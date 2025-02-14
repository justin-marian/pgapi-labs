#version 430

// Input and output topologies
// TODO(student): First, generate a curve (via line strip),
// then a rotation/translation surface (via triangle strip)
layout(lines) in;
layout(triangle_strip, max_vertices = 256) out;

// Uniform properties
uniform mat4 View;
uniform mat4 Projection;
uniform vec3 control_p0, control_p1, control_p2, control_p3;

// TODO(student): Declare any other uniforms here
uniform int no_of_instances;
uniform int no_of_generated_points;

uniform float max_translate;
uniform float max_rotate;

uniform int curve_type;
uniform int operation_surface;

// Input
in int instance[2];


vec3 rotateY(vec3 point, float u)
{
    float x = point.x * cos(u) - point.z *sin(u);
    float z = point.x * sin(u) + point.z *cos(u);
    return vec3(x, point.y, z);
}


vec3 translateX(vec3 point, float t)
{
    return vec3(point.x + t, point.y, point.z);
}


// This function computes B(t) with 4 control points. For a visual example,
// see [1]. For an interactive Javascript example with the exact points in
// this code, see [2].
//
// [1] https://www.desmos.com/calculator/cahqdxeshd
// [2] https://jsfiddle.net/6yuv9htf/
vec3 bezier(float t)
{
    return  control_p0 * pow((1 - t), 3) +
            control_p1 * 3 * t * pow((1 - t), 2) +
            control_p2 * 3 * pow(t, 2) * (1 - t) +
            control_p3 * pow(t, 3);
}


// TODO(student): If you want to take things a step further, try drawing a
// Hermite spline. Hint: you can repurpose two of the control points. For a
// visual example, see [1]. For an interactive Javascript example with the
// exact points in this code, see [2].
// 
// Unlike the Javascript function, you MUST NOT call the Bezier function.
// There is another way to draw a Hermite spline, all you need is to find
// the formula.
//
// [1] https://www.desmos.com/calculator/5knm5tkr8m
// [2] https://jsfiddle.net/6yuv9htf/
// [3] https://www.inf.ed.ac.uk/teaching/courses/cg/d3/hermite.html
vec3 hermite(float t)
{
    float h00 = 2.0 * pow(t, 3.0) - 3.0 * pow(t, 2.0) + 1.0;
    float h10 = pow(t, 3.0) - 2.0 * pow(t, 2.0) + t;
    float h01 = -2.0 * pow(t, 3.0) + 3.0 * pow(t, 2.0);
    float h11 = pow(t, 3.0) - pow(t, 2.0);

    return control_p0 * h00 +
           control_p1 * h10 +
           control_p2 * h01 +
           control_p3 * h11;
}


void main()
{
    const int SURFACE_TYPE_ROTATION     = 0;
    const int SURFACE_TYPE_TRANSLATION  = 1;
    const int CURVE_TYPE_BEZIER         = 0;
    const int CURVE_TYPE_HERMITE        = 1;

    // You can change the value of SURFACE_TYPE to experiment
    // with different transformation types.
    // int SURFACE_TYPE = SURFACE_TYPE_TRANSLATION;

    // if (instance[0] < no_of_instances)
    // {
    //     TODO(student): Rather than emitting vertices for the control
    //     points, you must emit vertices that approximate the curve itself.
    //     gl_Position = Projection * View * vec4(control_p0, 1);   EmitVertex();
    //     gl_Position = Projection * View * vec4(control_p1, 1);   EmitVertex();
    //     gl_Position = Projection * View * vec4(control_p2, 1);   EmitVertex();
    //     gl_Position = Projection * View * vec4(control_p3, 1);   EmitVertex();
    //     EndPrimitive();
    // }

    float t1 = float(instance[0]) / float(no_of_instances);
    float t2 = float(instance[0] + 1) / float(no_of_instances);
    vec3 cp1 = vec3(0.0);
    vec3 cp2 = vec3(0.0);

    if (curve_type == CURVE_TYPE_BEZIER)
    {
        cp1 = bezier(t1);
        cp2 = bezier(t2);
    }
    else if (curve_type == CURVE_TYPE_HERMITE)
    {
        cp1 = hermite(t1);
        cp2 = hermite(t2);
    }

    for (int j = 0; j <= no_of_generated_points; ++j)
    {
        float u = float(j) / float(no_of_generated_points);

        vec3 tp1 = vec3(0.0);
        vec3 tp2 = vec3(0.0);

        if (operation_surface == SURFACE_TYPE_ROTATION)
        {
            tp1 = rotateY(cp1, u * max_rotate);
            tp2 = rotateY(cp2, u * max_rotate);
        }
        else if (operation_surface == SURFACE_TYPE_TRANSLATION)
        {
            tp1 = translateX(cp1, u * max_translate);
            tp2 = translateX(cp2, u * max_translate);
        }

        gl_Position = Projection * View * vec4(tp1, 1.0);
        EmitVertex();
        gl_Position = Projection * View * vec4(tp2, 1.0);
        EmitVertex();
    }

    EndPrimitive();
}