if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.12)
    cmake_policy(SET CMP0074 NEW)
endif()
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.5)
    set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)
endif()

include(cmake/vendor.cmake)

function(resolve_app_bgfx_config definitions_var)
    set(bgfx_renderer_definitions "")

    if(APPLE)
        list(APPEND bgfx_renderer_definitions
            BGFX_CONFIG_RENDERER_DIRECT3D11=0
            BGFX_CONFIG_RENDERER_DIRECT3D12=0
            BGFX_CONFIG_RENDERER_METAL=1
            BGFX_CONFIG_RENDERER_OPENGL=0
            BGFX_CONFIG_RENDERER_OPENGLES=0
            BGFX_CONFIG_RENDERER_VULKAN=0
            BGFX_CONFIG_RENDERER_WEBGPU=0
        )
    elseif(WIN32)
        list(APPEND bgfx_renderer_definitions
            BGFX_CONFIG_RENDERER_DIRECT3D11=1
            BGFX_CONFIG_RENDERER_DIRECT3D12=1
            BGFX_CONFIG_RENDERER_METAL=0
            BGFX_CONFIG_RENDERER_OPENGL=0
            BGFX_CONFIG_RENDERER_OPENGLES=0
            BGFX_CONFIG_RENDERER_VULKAN=0
            BGFX_CONFIG_RENDERER_WEBGPU=0
        )
    elseif(UNIX)
        list(APPEND bgfx_renderer_definitions
            BGFX_CONFIG_RENDERER_DIRECT3D11=0
            BGFX_CONFIG_RENDERER_DIRECT3D12=0
            BGFX_CONFIG_RENDERER_METAL=0
            BGFX_CONFIG_RENDERER_OPENGL=0
            BGFX_CONFIG_RENDERER_OPENGLES=0
            BGFX_CONFIG_RENDERER_VULKAN=1
            BGFX_CONFIG_RENDERER_WEBGPU=0
        )
    endif()

    set(${definitions_var} "${bgfx_renderer_definitions}" PARENT_SCOPE)
endfunction()

function(configure_app_bgfx_cache_options)
    if(APPLE)
        set(BGFX_CONFIG_RENDERER_DIRECT3D11 0 CACHE STRING "Enable bgfx Direct3D 11 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_DIRECT3D12 0 CACHE STRING "Enable bgfx Direct3D 12 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_METAL 1 CACHE STRING "Enable bgfx Metal renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGL 0 CACHE STRING "Enable bgfx OpenGL renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGLES 0 CACHE STRING "Enable bgfx OpenGL ES renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_VULKAN 0 CACHE STRING "Enable bgfx Vulkan renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_WEBGPU 0 CACHE BOOL "Enable bgfx WebGPU renderer." FORCE)
    elseif(WIN32)
        set(BGFX_CONFIG_RENDERER_DIRECT3D11 1 CACHE STRING "Enable bgfx Direct3D 11 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_DIRECT3D12 1 CACHE STRING "Enable bgfx Direct3D 12 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_METAL 0 CACHE STRING "Enable bgfx Metal renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGL 0 CACHE STRING "Enable bgfx OpenGL renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGLES 0 CACHE STRING "Enable bgfx OpenGL ES renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_VULKAN 0 CACHE STRING "Enable bgfx Vulkan renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_WEBGPU 0 CACHE BOOL "Enable bgfx WebGPU renderer." FORCE)
    elseif(UNIX)
        set(BGFX_CONFIG_RENDERER_DIRECT3D11 0 CACHE STRING "Enable bgfx Direct3D 11 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_DIRECT3D12 0 CACHE STRING "Enable bgfx Direct3D 12 renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_METAL 0 CACHE STRING "Enable bgfx Metal renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGL 0 CACHE STRING "Enable bgfx OpenGL renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_OPENGLES 0 CACHE STRING "Enable bgfx OpenGL ES renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_VULKAN 1 CACHE STRING "Enable bgfx Vulkan renderer." FORCE)
        set(BGFX_CONFIG_RENDERER_WEBGPU 0 CACHE BOOL "Enable bgfx WebGPU renderer." FORCE)
    endif()
endfunction()

function(configure_app_bgfx_target)
    if(NOT TARGET bgfx)
        return()
    endif()

    resolve_app_bgfx_config(bgfx_renderer_definitions)

    if(APPLE)
        message(STATUS "Configuring bgfx backend for macOS: Metal")
    elseif(WIN32)
        message(STATUS "Configuring bgfx backends for Windows: Direct3D 12 and Direct3D 11")
    elseif(UNIX)
        message(STATUS "Configuring bgfx backend for Linux: Vulkan")
    endif()

    target_compile_definitions(bgfx PRIVATE ${bgfx_renderer_definitions})

    get_target_property(bgfx_sources bgfx SOURCES)
    if(NOT bgfx_sources)
        return()
    endif()

    set(bgfx_filtered_sources "")
    foreach(bgfx_source IN LISTS bgfx_sources)
        get_filename_component(bgfx_source_name "${bgfx_source}" NAME)
        set(keep_source TRUE)

        if(bgfx_source_name MATCHES "^renderer_.*\\.(cpp|mm)$" OR bgfx_source_name MATCHES "^glcontext_.*\\.cpp$" OR bgfx_source_name STREQUAL "dxgi.cpp" OR bgfx_source_name STREQUAL "nvapi.cpp")
            set(keep_source FALSE)

            if(APPLE AND bgfx_source_name MATCHES "^renderer_mtl\\.(cpp|mm)$")
                set(keep_source TRUE)
            elseif(WIN32 AND (bgfx_source_name STREQUAL "renderer_d3d11.cpp" OR bgfx_source_name STREQUAL "renderer_d3d12.cpp" OR bgfx_source_name STREQUAL "dxgi.cpp" OR bgfx_source_name STREQUAL "nvapi.cpp"))
                set(keep_source TRUE)
            elseif(UNIX AND NOT APPLE AND bgfx_source_name STREQUAL "renderer_vk.cpp")
                set(keep_source TRUE)
            endif()
        endif()

        if(keep_source)
            list(APPEND bgfx_filtered_sources "${bgfx_source}")
        endif()
    endforeach()

    set_property(TARGET bgfx PROPERTY SOURCES ${bgfx_filtered_sources})
endfunction()

if(EXISTS "${GLFW_DIR}/CMakeLists.txt")
    message(STATUS "Using vendor GLFW from ${GLFW_DIR}")
    add_vendor_subdirectory(${GLFW_DIR} glfw)
    set(GLFW_TARGET glfw)
endif()

if(EXISTS "${BGFX_CMAKE_DIR}/CMakeLists.txt")
    message(STATUS "Using vendor bgfx via ${BGFX_CMAKE_DIR}")
    set(BX_DIR "${BX_DIR}" CACHE STRING "Location of bx." FORCE)
    set(BIMG_DIR "${BIMG_DIR}" CACHE STRING "Location of bimg." FORCE)
    set(BGFX_DIR "${BGFX_DIR}" CACHE STRING "Location of bgfx." FORCE)
    configure_app_bgfx_cache_options()
    set(BGFX_BUILD_TOOLS OFF CACHE BOOL "Build bgfx tools." FORCE)
    set(BGFX_BUILD_EXAMPLES OFF CACHE BOOL "Build bgfx examples." FORCE)
    set(BGFX_BUILD_EXAMPLE_COMMON OFF CACHE BOOL "Build bgfx example common." FORCE)
    set(BGFX_BUILD_TESTS OFF CACHE BOOL "Build bgfx tests." FORCE)
    set(BGFX_INSTALL OFF CACHE BOOL "Install bgfx targets." FORCE)
    set(BGFX_CUSTOM_TARGETS OFF CACHE BOOL "Include bgfx convenience targets." FORCE)
    add_vendor_subdirectory(${BGFX_CMAKE_DIR} bgfx)
    configure_app_bgfx_target()
else()
    message(FATAL_ERROR "bgfx.cmake not found at ${BGFX_CMAKE_DIR}. Initialise submodules before configuring.")
endif()
