if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.12)
    cmake_policy(SET CMP0074 NEW)
endif()
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.5)
    set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)
endif()

include(cmake/vendor.cmake)

if(EXISTS "${GLFW_DIR}/CMakeLists.txt")
    message(STATUS "Using vendor GLFW from ${GLFW_DIR}")
    add_vendor_subdirectory(${GLFW_DIR} glfw)
    set(GLFW_TARGET glfw)
endif()

if(EXISTS "${JSON_DIR}/CMakeLists.txt")
    message(STATUS "Using vendor nlohmann_json from ${JSON_DIR}")
    add_vendor_subdirectory(${JSON_DIR} json)
endif()