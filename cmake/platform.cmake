if(WIN32)
    message(STATUS "Configuring for Windows (BGFX: Direct3D 12/11)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/bgfx/main.cpp
        ${SRC_DIR}/backend/bgfx/imgui_impl_bgfx.cpp
        ${SRC_DIR}/backend/bgfx/disabled_renderers.cpp
        ${SRC_DIR}/ui/styling/system_theme/system_theme_detector.cpp
    )
elseif(APPLE)
    message(STATUS "Configuring for macOS (BGFX: Metal)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/bgfx/main.cpp
        ${SRC_DIR}/backend/bgfx/imgui_impl_bgfx.cpp
        ${SRC_DIR}/backend/bgfx/disabled_renderers.cpp
        ${SRC_DIR}/ui/styling/system_theme/system_theme_detector.mm
    )
    set(OBJC_FLAGS "-ObjC++ -fobjc-arc -fobjc-weak")
else()
    message(STATUS "Configuring for Linux (BGFX: Vulkan)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/bgfx/main.cpp
        ${SRC_DIR}/backend/bgfx/imgui_impl_bgfx.cpp
        ${SRC_DIR}/backend/bgfx/disabled_renderers.cpp
        ${SRC_DIR}/ui/styling/system_theme/system_theme_detector.cpp
    )
endif()

if(WIN32)
    add_executable(${EXECUTABLE_NAME} WIN32 ${SOURCES})
elseif(APPLE)
    if(BUILD_MACOS_BUNDLE)
        add_executable(${EXECUTABLE_NAME} MACOSX_BUNDLE ${SOURCES})
    else()
        add_executable(${EXECUTABLE_NAME} ${SOURCES})
    endif()
else()
    add_executable(${EXECUTABLE_NAME} ${SOURCES})
endif()

resolve_app_bgfx_config(app_bgfx_renderer_definitions)
target_compile_definitions(${EXECUTABLE_NAME} PRIVATE ${app_bgfx_renderer_definitions})

if(WIN32)
    target_compile_options(${EXECUTABLE_NAME} PRIVATE
        $<$<CONFIG:Release>:/O2>
        $<$<CONFIG:Release>:/GL>
    )
    target_link_options(${EXECUTABLE_NAME} PRIVATE
        $<$<CONFIG:Release>:/LTCG>
        $<$<CONFIG:Release>:/SUBSYSTEM:WINDOWS>
        $<$<CONFIG:Release>:/ENTRY:mainCRTStartup>
    )
elseif(APPLE)
    target_compile_options(${EXECUTABLE_NAME} PRIVATE
        "-Wall" "-Wextra" "-Wformat" "-Wpedantic"
        "-Wunused" "-Wuninitialized" "-Wshadow"
        "-Wconversion" "-Wsign-conversion" "-Wfloat-conversion"
        "-Wnull-dereference" "-Wdouble-promotion"
        "-Wmissing-include-dirs" "-Wundef" "-Wredundant-decls"
        "-Woverloaded-virtual" "-Wnon-virtual-dtor"
        "-O3" "-ffast-math" "-march=native"
    )

    set_source_files_properties(${SRC_DIR}/ui/styling/system_theme/system_theme_detector.mm PROPERTIES COMPILE_FLAGS "${OBJC_FLAGS}")

    set_property(SOURCE ${SRC_DIR}/ui.cpp APPEND PROPERTY COMPILE_OPTIONS "-Wno-c99-extensions")
    set_property(SOURCE ${SRC_DIR}/backend/bgfx/imgui_impl_bgfx.cpp APPEND PROPERTY COMPILE_OPTIONS
        "-Wno-sign-conversion" "-Wno-implicit-float-conversion" "-Wno-double-promotion")
else()
    target_compile_options(${EXECUTABLE_NAME} PRIVATE
        "-Wall" "-Wextra" "-Wformat" "-Wpedantic"
        "-O3" "-ffast-math" "-march=native"
    )
endif()

if(APPLE)
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
    find_library(COREVIDEO_FRAMEWORK CoreVideo REQUIRED)

    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        ${METAL_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${IOKIT_FRAMEWORK}
        ${COREVIDEO_FRAMEWORK}
        bgfx
        bimg
        bx
        ${GLFW_TARGET}

        vendor_imgui
        vendor_imgui_backends
        m
    )
elseif(WIN32)
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        bgfx
        bimg
        bx
        ${GLFW_TARGET}

        vendor_imgui
        vendor_imgui_backends
        windowsapp
    )
else()
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        bgfx
        bimg
        bx
        ${GLFW_TARGET}

        vendor_imgui
        vendor_imgui_backends
        dl
        pthread
        m
    )
endif()

if(APPLE AND BUILD_MACOS_BUNDLE)
    set_target_properties(${EXECUTABLE_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/Info.plist"
        MACOSX_BUNDLE_ICON_FILE "app.icns"
        MACOSX_BUNDLE_BUNDLE_NAME "${APP_NAME}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${APP_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${APP_VERSION}"
        MACOSX_BUNDLE_LONG_VERSION_STRING "${APP_NAME} ${APP_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "Copyright © ${CURRENT_YEAR} ${AUTHOR_NAME} | MIT License"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.${AUTHOR_HANDLE}.${APP_NAME}"
        MACOSX_BUNDLE_EXECUTABLE_NAME "${EXECUTABLE_NAME}"
        RESOURCE "${ICON_SRC}"
    )

    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/assets/Info.plist.in ${CMAKE_BINARY_DIR}/Info.plist)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/assets/entitlements.plist ${CMAKE_BINARY_DIR}/entitlements.plist COPYONLY)

    set(ICON_SRC "${CMAKE_CURRENT_SOURCE_DIR}/assets/icon/app.icns")
    set(ICON_DEST "${CMAKE_BINARY_DIR}/${EXECUTABLE_NAME}.app/Contents/Resources/app.icns")

    add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/${EXECUTABLE_NAME}.app/Contents/Resources"
        COMMAND ${CMAKE_COMMAND} -E copy "${ICON_SRC}" "${ICON_DEST}"
        COMMENT "Copying app icon to bundle resources"
    )
endif()

if(WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Release")
    install(TARGETS ${EXECUTABLE_NAME}
        RUNTIME DESTINATION bin
    )
    install(FILES
        $<TARGET_RUNTIME_DLLS:${EXECUTABLE_NAME}>
        DESTINATION bin
    )
elseif(APPLE)
    install(TARGETS ${EXECUTABLE_NAME} BUNDLE DESTINATION ".")
else()
    install(TARGETS ${EXECUTABLE_NAME}
        RUNTIME DESTINATION bin
    )
endif()
