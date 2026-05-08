cmake_minimum_required(VERSION 3.13)

string(TIMESTAMP CURRENT_YEAR "%Y")
string(TIMESTAMP CURRENT_MONTH "%m")
string(TIMESTAMP CURRENT_DAY "%d")

set(APP_VERSION_MAJOR "${CURRENT_YEAR}")
set(APP_VERSION_MINOR "${CURRENT_MONTH}")
set(APP_VERSION_PATCH "${CURRENT_DAY}")
set(APP_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_PATCH}")

set(AUTHOR_NAME "Author Name")
set(AUTHOR_HANDLE "AuthorHandle")

project(App VERSION ${APP_VERSION})

set(APP_NAME "ExampleApplication")
set(EXECUTABLE_NAME "${APP_NAME}")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/imgui")
set(GLFW_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/glfw")
set(BX_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/bx")
set(BIMG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/bimg")
set(BGFX_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/bgfx")
set(BGFX_CMAKE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/bgfx.cmake")
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")

option(BUILD_MACOS_BUNDLE "Build as macOS .app bundle" OFF)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/version.h.in"
    "${CMAKE_BINARY_DIR}/version.h"
    @ONLY
)

include(cmake/dependencies.cmake)
include(cmake/sources.cmake)
include(cmake/platform.cmake)

configure_include_directories()

target_compile_definitions(${EXECUTABLE_NAME} PRIVATE
    APP_VERSION_MAJOR=${APP_VERSION_MAJOR}
    APP_VERSION_MINOR=${APP_VERSION_MINOR}
    APP_VERSION_PATCH=${APP_VERSION_PATCH}
    APP_VERSION_STRING="${APP_VERSION}"
    APP_NAME_STRING="${APP_NAME}"
    APP_TITLE_STRING="${APP_NAME} v${APP_VERSION}"
)

set_target_properties(${EXECUTABLE_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
