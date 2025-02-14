#include "labs/lab1/lab1.h"

#include <vector>
#include <iostream>

using namespace std;



/*
 *  To find out more about `FrameStart`, `Update`, `FrameEnd`
 *  and the order in which they are called, see `world.cpp`.
 */


Lab1::Lab1()
{
    shrink = 0.;
    nrInstances = 0;
    maxInstances = 0;
    // Explosion effect
    explosion = 0;
    isExploding = 0;
}


Lab1::~Lab1()
{
}


void Lab1::Init()
{
    nrInstances = 0;
    maxInstances = 50;
    shrink = 1.0f;
    // Explosion effect
    explosion = 0.0f;
    isExploding = 0;

    auto camera = GetSceneCamera();
    camera->SetPositionAndRotation(glm::vec3(0, 5, 4), glm::quat(glm::vec3(-30 * TO_RADIANS, 0, 0)));
    camera->Update();

    // Load a mesh from file into GPU memory
    {
        Mesh* mesh = new Mesh("bamboo");
        mesh->LoadMesh(PATH_JOIN(window->props.selfDir, RESOURCE_PATH::MODELS, "vegetation", "bamboo"), "bamboo.obj");
        meshes[mesh->GetMeshID()] = mesh;
    }

    // Create a shader program for rendering to texture
    {
        Shader *shader = new Shader("Instances");
        shader->AddShader(PATH_JOIN(window->props.selfDir, SOURCE_PATH::M2, "lab1", "shaders", "VertexShader.glsl"), GL_VERTEX_SHADER);
        shader->AddShader(PATH_JOIN(window->props.selfDir, SOURCE_PATH::M2, "lab1", "shaders", "GeometryShader.glsl"), GL_GEOMETRY_SHADER);
        shader->AddShader(PATH_JOIN(window->props.selfDir, SOURCE_PATH::M2, "lab1", "shaders", "FragmentShader.glsl"), GL_FRAGMENT_SHADER);
        shader->CreateAndLink();
        shaders[shader->GetName()] = shader;
    }
}


void Lab1::FrameStart()
{
}


void Lab1::Update(float deltaTimeSeconds)
{
    ClearScreen();

    {
        auto shader = shaders["Instances"];

        shader->Use();

        int loc_instances = shader->GetUniformLocation("instances");
        if (loc_instances != -1) {
            glUniform1i(loc_instances, nrInstances);
        }

        // TODO(student): Add a shrinking parameter for scaling each
        // triangle in the geometry shader
        int loc_shrink = shader->GetUniformLocation("shrink");
        if (loc_shrink != -1) {
            glUniform1f(loc_shrink, shrink);
        }

        // BONUS(student): Add an explosion effect
        int loc_explosion_radius = shader->GetUniformLocation("explosion_radius");
        if (loc_explosion_radius != -1) {
            glUniform1f(loc_explosion_radius, explosion);
        }
        // BONUS(student): Add a flag to enable/disable the explosion effect
        int loc_is_exploding = shader->GetUniformLocation("is_exploding");
        if (loc_is_exploding != -1) {
            glUniform1i(loc_is_exploding, isExploding);
        }

        // Note that we only render a single mesh!
        RenderMesh(meshes["bamboo"], shaders["Instances"], glm::vec3(-3.3f, 0.5f, 0), glm::vec3(0.1f));
    }
}


void Lab1::FrameEnd()
{
    DrawCoordinateSystem();
}


/*
 *  These are callback functions. To find more about callbacks and
 *  how they behave, see `input_controller.h`.
 */


void Lab1::OnInputUpdate(float deltaTime, int mods)
{
    // Treat continuous update based on input with window->KeyHold()

    // TODO(student): Add events for modifying the shrinking parameter
    if (window->KeyHold(GLFW_KEY_UP))
    {
        shrink += deltaTime;
        // Max shrink value allowed is 1f
        if (shrink > 1.0f) shrink = 1.0f;
    }
    if (window->KeyHold(GLFW_KEY_DOWN))
    {
        shrink -= deltaTime;
        // Min shrink value allowed is 0f
        if (shrink < 0.0f) shrink = 0.0f;
    }
    // BONUS(student):
    // Explode the triangles in upwards direction
    if (window->KeyHold(GLFW_KEY_E))
	{
        isExploding = 1;
		explosion += deltaTime * 5;
        if (explosion > 20.0f) {
            explosion = 20.0f;
            isExploding = 0;
        }
    }
    // Explode the triangles in downwards direction
	if (window->KeyHold(GLFW_KEY_T))
	{
		isExploding = 1;
		explosion -= deltaTime * 5;
        if (explosion < 0.0f) {
            explosion = 0.0f;
            isExploding = 0;
        }
	}
    // Reset the explosion effect
    if (window->KeyHold(GLFW_KEY_R))
	{
        isExploding = 0;
        explosion = 0.0f;
    }
}


void Lab1::OnKeyPress(int key, int mods)
{
    // Add key press event

    if (key == GLFW_KEY_EQUAL)
    {
        nrInstances++;
        nrInstances %= maxInstances;
    }

    if (key == GLFW_KEY_MINUS)
    {
        nrInstances--;
        nrInstances %= maxInstances;
    }
}


void Lab1::OnKeyRelease(int key, int mods)
{
    // Add key release event
}


void Lab1::OnMouseMove(int mouseX, int mouseY, int deltaX, int deltaY)
{
    // Add mouse move event
}


void Lab1::OnMouseBtnPress(int mouseX, int mouseY, int button, int mods)
{
    // Add mouse button press event
}


void Lab1::OnMouseBtnRelease(int mouseX, int mouseY, int button, int mods)
{
    // Add mouse button release event
}


void Lab1::OnMouseScroll(int mouseX, int mouseY, int offsetX, int offsetY)
{
    // Treat mouse scroll event
}


void Lab1::OnWindowResize(int width, int height)
{
    // Treat window resize event
}
