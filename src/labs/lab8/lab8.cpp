#include "labs/lab8/lab8.h"

#include <vector>
#include <iostream>

#include "pfd/portable-file-dialogs.h"

using namespace std;



/*
 *  To find out more about `FrameStart`, `Update`, `FrameEnd`
 *  and the order in which they are called, see `world.cpp`.
 */

/// <summary>
/// processedImage - processed on the CPU (used and for savings)
/// originalImage - processed on the GPU
/// </summary>

Lab8::Lab8() : originalImage(nullptr), processedImage(nullptr)
{
    outputMode = 0;
    gpuProcessing = false;
    saveScreenToImage = false;
    window->SetSize(600, 600);
    radiusSize = 10;
    threshold = 0.3;
}


Lab8::~Lab8() {}


void Lab8::Init()
{
    // Load default texture fore imagine processing
    originalImage = TextureManager::LoadTexture(PATH_JOIN(window->props.selfDir, RESOURCE_PATH::TEXTURES, "cube", "pos_x.png"), nullptr, "image", true, true);
    processedImage = TextureManager::LoadTexture(PATH_JOIN(window->props.selfDir, RESOURCE_PATH::TEXTURES, "cube", "pos_x.png"), nullptr, "newImage", true, true);

    {
        Mesh* mesh = new Mesh("quad");
        mesh->LoadMesh(PATH_JOIN(window->props.selfDir, RESOURCE_PATH::MODELS, "primitives"), "quad.obj");
        mesh->UseMaterials(false);
        meshes[mesh->GetMeshID()] = mesh;
    }

    std::string shaderPath = PATH_JOIN(window->props.selfDir, SOURCE_PATH::M2, "Lab8", "shaders");

    // Create a shader program for particle system
    {
        Shader* shader = new Shader("ImageProcessing");
        shader->AddShader(PATH_JOIN(shaderPath, "VertexShader.glsl"), GL_VERTEX_SHADER);
        shader->AddShader(PATH_JOIN(shaderPath, "FragmentShader.glsl"), GL_FRAGMENT_SHADER);

        shader->CreateAndLink();
        shaders[shader->GetName()] = shader;
    }
}


void Lab8::FrameStart()
{
	glClearColor(0.2, 0.2, 0.2, 1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


void Lab8::Update(float deltaTimeSeconds)
{
    ClearScreen();

    if (!gpuProcessing) {
        switch (outputMode) {
        case 1:
            GrayScale();
            break;
        case 2:
            Blur();
            break;
        default:
            break;
        }
        outputMode = 0;
    }

    auto shader = shaders["ImageProcessing"];
    shader->Use();

    if (saveScreenToImage)
    {
        window->SetSize(originalImage->GetWidth(), originalImage->GetHeight());
    }

    int flip_loc = shader->GetUniformLocation("flipVertical");
    glUniform1i(flip_loc, saveScreenToImage ? 0 : 1);

    int screenSize_loc = shader->GetUniformLocation("screenSize");
    glm::ivec2 resolution = window->GetResolution();
    glUniform2i(screenSize_loc, resolution.x, resolution.y);

    int outputMode_loc = shader->GetUniformLocation("outputMode");
    glUniform1i(outputMode_loc, outputMode);

    int locTexture = shader->GetUniformLocation("textureImage");
    glUniform1i(locTexture, 0);

    int locRadius = shader->GetUniformLocation("radius");
    glUniform1i(locRadius, radiusSize);

    int locThreshold = shader->GetUniformLocation("threshold");
    glUniform1f(locThreshold, threshold);

    auto textureImage = (gpuProcessing == true) ? originalImage : processedImage;
    textureImage->BindToTextureUnit(GL_TEXTURE0);

    RenderMesh(meshes["quad"], shader, glm::mat4(1));

    if (saveScreenToImage)
    {
        saveScreenToImage = false;

        GLenum format = GL_RGB;
        if (originalImage->GetNrChannels() == 4)
        {
            format = GL_RGBA;
        }

        glReadPixels(0, 0, originalImage->GetWidth(), originalImage->GetHeight(), format, GL_UNSIGNED_BYTE, processedImage->GetImageData());
        processedImage->UploadNewData(processedImage->GetImageData());
        SaveImage("shader_processing_" + std::to_string(outputMode));

        float aspectRatio = static_cast<float>(originalImage->GetWidth()) / originalImage->GetHeight();
        window->SetSize(static_cast<int>(600 * aspectRatio), 600);
    }
}


void Lab8::FrameEnd()
{
    DrawCoordinateSystem();
}


void Lab8::OnFileSelected(const std::string& fileName)
{
    if (fileName.size())
    {
        std::cout << fileName << endl;
        originalImage = TextureManager::LoadTexture(fileName, nullptr, "image", true, true);
        processedImage = TextureManager::LoadTexture(fileName, nullptr, "newImage", true, true);

        float aspectRatio = static_cast<float>(originalImage->GetWidth()) / originalImage->GetHeight();
        window->SetSize(static_cast<int>(600 * aspectRatio), 600);
    }
}


void Lab8::Blur()
{
    unsigned int channels = originalImage->GetNrChannels();
    unsigned char* data = originalImage->GetImageData();
    unsigned char* newData = processedImage->GetImageData();

    if (channels < 3)
        return;

    glm::ivec2 imageSize = glm::ivec2(originalImage->GetWidth(), originalImage->GetHeight());
    int radius = radiusSize;

    for (int y = 0; y < imageSize.y; y++)
    {
        for (int x = 0; x < imageSize.x; x++)
        {
            int r = 0, g = 0, b = 0;

            for (int i = -radius; i <= radius; i++) 
            {
                for (int j = -radius; j <= radius; j++) 
                {
                    int ny = y + i;
                    int nx = x + j;

                    if (ny >= 0 && ny < imageSize.y && nx >= 0 && nx < imageSize.x) 
                    {
                        int offset = channels * (ny * imageSize.x + nx);
                        r += data[offset];
                        g += data[offset + 1];
                        b += data[offset + 2];
                    }
                }
            }

            float samples = pow((2 * radius + 1), 2);
            int offset = channels * (y * imageSize.x + x);
            newData[offset] = r / samples;
            newData[offset + 1] = g / samples;
            newData[offset + 2] = b / samples;
        }
    }

    processedImage->UploadNewData(newData);
}


void Lab8::GrayScale()
{
    unsigned int channels = originalImage->GetNrChannels();
    unsigned char* data = originalImage->GetImageData();
    unsigned char* newData = processedImage->GetImageData();

    if (channels < 3)
        return;

    glm::ivec2 imageSize = glm::ivec2(originalImage->GetWidth(), originalImage->GetHeight());

    for (int i = 0; i < imageSize.y; i++)
    {
        for (int j = 0; j < imageSize.x; j++)
        {
            int offset = channels * (i * imageSize.x + j);
            char value = static_cast<char>(data[offset + 0] * 0.2f + data[offset + 1] * 0.71f + data[offset + 2] * 0.07);
            memset(&newData[offset], value, 3);
        }
    }

    processedImage->UploadNewData(newData);
}


void Lab8::SaveImage(const std::string& fileName)
{
    cout << "Saving image! ";
    processedImage->SaveToFile((fileName + ".png").c_str());
    cout << "[Done]" << endl;
}


void Lab8::OpenDialog()
{
    std::vector<std::string> filters =
    {
        "Image Files", "*.png *.jpg *.jpeg *.bmp",
        "All Files", "*"
    };

    auto selection = pfd::open_file("Select a file", ".", filters).result();
    if (!selection.empty())
    {
        std::cout << "User selected file " << selection[0] << "\n";
        OnFileSelected(selection[0]);
    }
}


/*
 *  These are callback functions. To find more about callbacks and
 *  how they behave, see `input_controller.h`.
 */


void Lab8::OnInputUpdate(float deltaTime, int mods)
{
    // Treat continuous update based on input
}


void Lab8::OnKeyPress(int key, int mods)
{
    // Add key press event
    if (key == GLFW_KEY_F || key == GLFW_KEY_ENTER || key == GLFW_KEY_SPACE)
    {
        OpenDialog();
    }

    if (key == GLFW_KEY_E)
    {
        gpuProcessing = !gpuProcessing;
        if (!gpuProcessing) 
        {
            cout << "Processing on CPU: " << endl;
        }
        else 
        {
            cout << "Processing on GPU: " << endl;
        }
        outputMode = 0;
    }

    if (key - GLFW_KEY_0 >= 0 && key <= GLFW_KEY_4)
    {
        outputMode = key - GLFW_KEY_0;
        cout << "Switched to output mode: " << outputMode << endl;
    }

    if (key == GLFW_KEY_S && (mods & GLFW_MOD_CONTROL))
    {
        if (!gpuProcessing)
        {
            SaveImage("processCPU_" + std::to_string(outputMode));
        }
        else
        {
            saveScreenToImage = true;
        }
    }
}

void Lab8::OnKeyRelease(int key, int mods)
{
    // Add key release event
}


void Lab8::OnMouseMove(int mouseX, int mouseY, int deltaX, int deltaY)
{
    // Add mouse move event
}


void Lab8::OnMouseBtnPress(int mouseX, int mouseY, int button, int mods)
{
    // Add mouse button press event
}


void Lab8::OnMouseBtnRelease(int mouseX, int mouseY, int button, int mods)
{
    // Add mouse button release event
}


void Lab8::OnMouseScroll(int mouseX, int mouseY, int offsetX, int offsetY)
{
    // Treat mouse scroll event
}


void Lab8::OnWindowResize(int width, int height)
{
    // Treat window resize event
}
