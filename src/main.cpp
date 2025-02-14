#include <ctime>
#include <iostream>

#include "core/engine.h"
#include "components/simple_scene.h"

#include "labs/lab_list.h"


#ifdef _WIN32
    PREFER_DISCRETE_GPU_NVIDIA;
    PREFER_DISCRETE_GPU_AMD;
#endif


std::string GetParentDir(const std::string &filePath)
{
    size_t pos = filePath.find_last_of("\\/");
    return (std::string::npos == pos) ? "." : filePath.substr(0, pos);
}


int main(int argc, char **argv)
{
    srand((unsigned int)time(NULL));

    // Create a window property structure
    WindowProperties wp;
    wp.resolution = glm::ivec2(1280, 720);
    wp.vSync = true;
    wp.selfDir = GetParentDir(std::string(argv[0]));

    // Init the Engine and create a new window with the defined properties
    (void)Engine::Init(wp);

    //World* world = new Lab1();
    //World* world = new Lab2();
    //World* world = new Lab3();
    //World* world = new Lab4();
    //World* world = new Lab5();
    //World* world = new Lab6();
    //World* world = new Lab7();
    World* world = new Lab8();                    // Lab9 is here

    world->Init();
    world->Run();

    // Signals to the Engine to release the OpenGL context
    Engine::Exit();

    return 0;
}
