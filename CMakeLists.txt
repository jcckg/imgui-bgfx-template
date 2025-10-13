cmake_minimum_required(VERSION 3.13)

string(TIMESTAMP CURRENT_YEAR "%Y")
string(TIMESTAMP CURRENT_MONTH "%m")
string(TIMESTAMP CURRENT_DAY "%d")

set(APP_VERSION_MAJOR "${CURRENT_YEAR}")
set(APP_VERSION_MINOR "${CURRENT_MONTH}")
set(APP_VERSION_PATCH "${CURRENT_DAY}")
set(APP_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_PATCH}")

set(AUTHOR "jcckg")

project(App VERSION ${APP_VERSION})

set(EXECUTABLE_NAME "App")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/imgui")
set(JSON_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/json")
set(GLFW_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/glfw")
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
)

set_target_properties(${EXECUTABLE_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)