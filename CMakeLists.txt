cmake_minimum_required(VERSION 3.16) 
# This sets the minimum required version of CMake. If the user has an older version, an error will occur.
# The version 3.16 is chosen because it provides features needed for this project.

# ----------------------------------------------------------------------
# Set up the root directory for the project
# ----------------------------------------------------------------------
# This block checks if the GFXF_ROOT_DIR variable is set. If it is not, it assigns the current CMake
# directory (`CMAKE_CURRENT_LIST_DIR`) as the root directory for the project.
if (NOT GFXF_ROOT_DIR)
    set(GFXF_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})
endif()

# ----------------------------------------------------------------------
# Project configuration
# ----------------------------------------------------------------------
# This block sets the project name as GFXFramework and specifies that both C and C++ languages will
# be used in the project.
set(target_name GFXFramework)
project(${target_name} C CXX)

# ----------------------------------------------------------------------
# C and C++ Standard configuration
# ----------------------------------------------------------------------
# This part enforces the use of specific C and C++ standards:
# - C99 for C code: This ensures that C code uses features from C99 standard (e.g., variable declarations inside blocks).
# - C++11 for C++ code: This sets the project to use the C++11 standard, which provides modern features like auto, nullptr, etc.
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ----------------------------------------------------------------------
# Include helper scripts
# ----------------------------------------------------------------------
# This includes additional CMake scripts that may define helper functions. 
# Specifically, 'utils.cmake' might contain utility functions used by the project.
include(${GFXF_ROOT_DIR}/infra/utils.cmake)
# Custom helper function that sets the build type (e.g., Debug or Release) based on the user's input or defaults.
custom_set_build_type()

# ----------------------------------------------------------------------
# CMake policy to avoid warnings in specific cases
# ----------------------------------------------------------------------
# This fixes a CMake bug related to the CMP0012 policy, which controls the behavior of CMake when
# certain commands (e.g., `find_package`) are invoked with certain parameters.
set(CMAKE_POLICY_DEFAULT_CMP0012 NEW)

# ----------------------------------------------------------------------
# Find required packages
# ----------------------------------------------------------------------
# This section finds necessary libraries or packages for the project.
# OpenGL is a must-have, so we make it required.
find_package(OpenGL REQUIRED)

# For non-Windows systems, the following dependencies are required:
if (NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    find_package(GLEW REQUIRED)      # GLEW is used for managing OpenGL extensions
    find_package(PkgConfig REQUIRED) # Package manager to help find libraries
    pkg_search_module(GLFW REQUIRED glfw3) # GLFW for creating windows and handling input
    find_package(assimp REQUIRED)     # Assimp for importing various 3D model formats
    find_package(spdlog REQUIRED)     # SPDLOG for logging
    find_package(Freetype REQUIRED)   # Freetype for handling fonts
endif()

# ----------------------------------------------------------------------
# Set RPATH for proper library path resolution
# ----------------------------------------------------------------------
# This section ensures that libraries are found at runtime by setting RPATH 
# (runtime library search path). It differs depending on the platform.
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_INSTALL_RPATH "@executable_path") # macOS: search for libraries in the same folder as the executable
else()
    set(CMAKE_INSTALL_RPATH "$ORIGIN") # Linux/Windows: search for libraries relative to the executable
endif()

# ----------------------------------------------------------------------
# Gather the source files
# ----------------------------------------------------------------------
# Here, all source code files (with extensions .c, .cpp) are gathered from various subdirectories.
# This ensures that the project compiles all the necessary source files.
file(GLOB_RECURSE GFXF_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/src/components/*.c*
    ${CMAKE_CURRENT_LIST_DIR}/src/core/*.c*
    ${CMAKE_CURRENT_LIST_DIR}/src/utils/*.c*
    ${CMAKE_CURRENT_LIST_DIR}/src/main.cpp
    ${CMAKE_CURRENT_LIST_DIR}/src/labs/lab*/*.c*
)

# ----------------------------------------------------------------------
# Gather the header files
# ----------------------------------------------------------------------
# This block collects all header files (.h) and shader files (.glsl) needed for the project.
file(GLOB_RECURSE GFXF_HEADERS_PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/src/components/*.h*
    ${CMAKE_CURRENT_LIST_DIR}/src/core/*.h*
    ${CMAKE_CURRENT_LIST_DIR}/src/utils/*.h*
    ${CMAKE_CURRENT_LIST_DIR}/src/labs/*.h*
    ${CMAKE_CURRENT_LIST_DIR}/src/labs/lab*/*.h*
    ${CMAKE_CURRENT_LIST_DIR}/src/labs/lab*/shaders/*.glsl
    ${CMAKE_CURRENT_LIST_DIR}/res/*.glsl
    ${CMAKE_CURRENT_LIST_DIR}/assets/shaders/*.glsl
)

# ----------------------------------------------------------------------
# Gather the include directories
# ----------------------------------------------------------------------
# This part adds directories to the compiler's search path for header files.
# The directories specified here will be searched for header files during compilation.
set(GFXF_INCLUDE_DIRS_PRIVATE
    ${GFXF_ROOT_DIR}/deps/api    # API headers from the dependencies
    ${CMAKE_CURRENT_LIST_DIR}/src # Source code headers
)

# ----------------------------------------------------------------------
# Add the executable target
# ----------------------------------------------------------------------
# This defines the target (the executable) and includes all source and header files
custom_add_executable(${target_name}
    ${GFXF_SOURCES}
    ${GFXF_SOURCES_HIDDEN} # If there are any hidden source files
    ${GFXF_HEADERS_PRIVATE}
)

# ----------------------------------------------------------------------
# Detect system architecture
# ----------------------------------------------------------------------
# The system architecture (32-bit or 64-bit) is detected. It also distinguishes between ARM and x86 processors.
# The architecture is used to determine the correct version of pre-built libraries to link.
if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm|aarch")
        set(__cmake_arch arm64) # For 64-bit ARM processors
    else()
        set(__cmake_arch x86_64) # For 64-bit x86 processors
    endif()
elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm|aarch")
        set(__cmake_arch armv7) # For 32-bit ARM processors
    else()
        set(__cmake_arch i686) # For 32-bit x86 processors
    endif()
endif()

# ----------------------------------------------------------------------
# Set library suffixes based on the platform
# ----------------------------------------------------------------------
# This section sets the correct suffix for shared libraries (e.g., .dll for Windows, .so for Linux, .dylib for macOS)
if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(__cmake_shared_suffix dll)
    set(__cmake_import_suffix lib)
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(__cmake_shared_suffix so)
    set(__cmake_import_suffix so)
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(__cmake_shared_suffix dylib)
    set(__cmake_import_suffix dylib)
endif()

# ----------------------------------------------------------------------
# Link third-party libraries
# ----------------------------------------------------------------------
# This section links the appropriate third-party libraries for OpenGL, GLEW, GLFW, Assimp, etc.
# The libraries are linked differently depending on the platform (Windows, Linux, or macOS).
target_link_libraries(${target_name} PRIVATE
    ${OPENGL_LIBRARIES}
)

if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(${target_name} PRIVATE
        ${GFXF_ROOT_DIR}/deps/prebuilt/GL/${__cmake_arch}/glew32.lib
        ${GFXF_ROOT_DIR}/deps/prebuilt/GLFW/${__cmake_arch}/glfw3dll.lib
        ${GFXF_ROOT_DIR}/deps/prebuilt/assimp/${__cmake_arch}/assimp.lib
        ${GFXF_ROOT_DIR}/deps/prebuilt/spdlog/${__cmake_arch}/spdlog.lib
        ${GFXF_ROOT_DIR}/deps/prebuilt/freetype/${__cmake_arch}/freetype.lib
    )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(${target_name} PRIVATE
        GLEW
        glfw
        assimp
        spdlog
        freetype
    )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    # macOS-specific linking adjustments for libraries
    target_link_directories(${target_name} PRIVATE
        /usr/local/lib
    )

    if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm|aarch")
        target_link_directories(${target_name} PRIVATE
        /opt/homebrew/lib
    )
    endif ()

    target_link_libraries(${target_name} PRIVATE
        GLEW
        glfw
        assimp
        spdlog
        freetype
    )
endif()

# ----------------------------------------------------------------------
# Link custom components
# ----------------------------------------------------------------------
# This links a custom component (GFXComponents) for the project from the pre-built libraries directory.
target_link_libraries(${target_name} PRIVATE
    ${GFXF_ROOT_DIR}/deps/prebuilt/GFXComponents/${__cmake_arch}/GFXComponents.${__cmake_import_suffix}
)

# ----------------------------------------------------------------------
# Set target properties
# ----------------------------------------------------------------------
# This sets additional properties for the target, such as include directories.
# It ensures that the specified directories are included during compilation.
target_include_directories(${target_name} PRIVATE ${GFXF_INCLUDE_DIRS_PRIVATE})

# ----------------------------------------------------------------------
# Visual Studio-specific configuration
# ----------------------------------------------------------------------
# For Visual Studio, this sets the working directory and startup project.
# This makes debugging easier by ensuring the project is correctly set up.
if (MSVC)
    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY VS_STARTUP_PROJECT ${target_name})
    set_property(TARGET ${target_name} PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
endif()

# ----------------------------------------------------------------------
# Set properties for header files
# ----------------------------------------------------------------------
# This ensures that the header files are recognized as "header-only" files in the IDE.
set_source_files_properties(${GFXF_HEADERS_PRIVATE}  PROPERTIES HEADER_FILE_ONLY TRUE)

# ----------------------------------------------------------------------
# Organize source files in IDEs for better visibility
# ----------------------------------------------------------------------
# This creates logical groups in the IDE for organizing source files by their location in the directory.
source_group(TREE ${CMAKE_CURRENT_LIST_DIR} FILES
    ${GFXF_SOURCES}
    ${GFXF_SOURCES_HIDDEN}
    ${GFXF_HEADERS_PRIVATE}
)

# ----------------------------------------------------------------------
# Add compiler options
# ----------------------------------------------------------------------
# This section configures compiler warnings and options.
# It sets different warning levels and disables specific warnings.
if (MSVC)
    set(GFXF_CXX_FLAGS  /W4 /WX-)
    set(GFXF_CXX_FLAGS  ${GFXF_CXX_FLAGS} /wd4100 /wd4458 /wd4189)
else()
    set(GFXF_CXX_FLAGS  -Wall -Wextra -pedantic -Wno-error)
    if (CMAKE_C_COMPILER_ID MATCHES "GNU")
        set(GFXF_CXX_FLAGS  ${GFXF_CXX_FLAGS}   -Wno-unused-parameter -Wno-unused-variable
                                                -Wno-unused-but-set-variable
                                                -Wno-missing-field-initializers -Wno-sign-compare)
    elseif (CMAKE_C_COMPILER_ID MATCHES "Clang")
        set(GFXF_CXX_FLAGS  ${GFXF_CXX_FLAGS}   -Wno-unused-parameter -Wno-unused-variable
                                                -Wno-missing-field-initializers -Wno-sign-compare
                                                -Wno-unknown-warning-option
                                                -Wno-microsoft-enum-value -Wno-language-extension-token)
    endif()
endif()
target_compile_options(${target_name} PRIVATE ${GFXF_CXX_FLAGS})

# ----------------------------------------------------------------------
# Post-build actions
# ----------------------------------------------------------------------
# After building the target, this section copies required DLLs (on Windows) or creates symlinks
# to shared directories to ensure proper runtime behavior.
get_target_property(__target_dir ${target_name} RUNTIME_OUTPUT_DIRECTORY)

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${GFXF_ROOT_DIR}/deps/prebuilt/GL/${__cmake_arch}/glew32.dll"
            "${GFXF_ROOT_DIR}/deps/prebuilt/GLFW/${__cmake_arch}/glfw3.dll"
            "${GFXF_ROOT_DIR}/deps/prebuilt/assimp/${__cmake_arch}/assimp.dll"
            "${GFXF_ROOT_DIR}/deps/prebuilt/spdlog/${__cmake_arch}/spdlog.dll"
            "${GFXF_ROOT_DIR}/deps/prebuilt/freetype/${__cmake_arch}/freetype.dll"
            "${__target_dir}"
    )
endif()

# ----------------------------------------------------------------------
# Create symbolic links for directories (src and assets)
# ----------------------------------------------------------------------
# This section creates symlinks for directories (e.g., `src` and `assets`) to avoid including them
# directly in the binary directory. This helps manage files properly during the build process.
foreach (dir IN ITEMS "src" "assets")
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        string(REPLACE "/" "\\" __target_dir "${__target_dir}")
        string(REPLACE "/" "\\" GFXF_ROOT_DIR "${GFXF_ROOT_DIR}")
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND rmdir /S /Q "${__target_dir}\\${dir}" ${__error_sink}
            COMMAND mklink /J "${__target_dir}\\${dir}" "${GFXF_ROOT_DIR}\\${dir}" ${__error_sink}
        )
    else()
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND rm -rf "${__target_dir}/${dir}"
            COMMAND ln -s "${GFXF_ROOT_DIR}/${dir}" "${__target_dir}/${dir}"
        )
    endif()
endforeach()
