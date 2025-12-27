if(WIN32)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/assets/icon/app.ico
        ${CMAKE_BINARY_DIR}/app.ico COPYONLY)
    configure_file(${SRC_DIR}/backend/win32/resource.h
        ${CMAKE_BINARY_DIR}/resource.h COPYONLY)
    configure_file(${SRC_DIR}/backend/win32/app.rc.in
        ${CMAKE_BINARY_DIR}/app.rc @ONLY)
endif()

if(WIN32)
    message(STATUS "Configuring for Windows (DirectX 12)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/win32/main.cpp
        ${CMAKE_BINARY_DIR}/app.rc
        ${SRC_DIR}/ui/styling/system_theme/system_theme_detector.cpp
    )
    set(DX12_LIBS d3d12 dxgi d3dcompiler)
elseif(APPLE)
    message(STATUS "Configuring for macOS (Metal)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/darwin/main.mm
        ${SRC_DIR}/ui/styling/system_theme/system_theme_detector.mm
    )
    set(OBJC_FLAGS "-ObjC++ -fobjc-arc -fobjc-weak")
else()
    message(STATUS "Configuring for Linux (Vulkan)")
    list(APPEND SOURCES
        ${SRC_DIR}/backend/linux/main.cpp
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

    set_source_files_properties(${SRC_DIR}/backend/darwin/main.mm PROPERTIES COMPILE_FLAGS "${OBJC_FLAGS}")
    set_source_files_properties(${SRC_DIR}/ui/styling/system_theme/system_theme_detector.mm PROPERTIES COMPILE_FLAGS "${OBJC_FLAGS}")
    set_source_files_properties(${SRC_DIR}/updates/update.cpp PROPERTIES COMPILE_FLAGS "-Wno-nan-infinity-disabled")

    set_property(SOURCE ${SRC_DIR}/ui.cpp APPEND PROPERTY COMPILE_OPTIONS "-Wno-c99-extensions")
else()
    target_compile_options(${EXECUTABLE_NAME} PRIVATE
        "-Wall" "-Wextra" "-Wformat" "-Wpedantic"
        "-O3" "-ffast-math" "-march=native"
    )
endif()

if(APPLE)
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
    find_library(COREVIDEO_FRAMEWORK CoreVideo REQUIRED)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)

    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        ${METAL_FRAMEWORK}
        ${METALKIT_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${IOKIT_FRAMEWORK}
        ${COREVIDEO_FRAMEWORK}
        ${QUARTZCORE_FRAMEWORK}
        ${GLFW_TARGET}
        ${PORTAUDIO_TARGET}

        vendor_imgui
        vendor_imgui_backends
        m
    )
elseif(WIN32)
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        ${GLFW_TARGET}
        ${PORTAUDIO_TARGET}
        ${DX12_LIBS}

        vendor_imgui
        windowsapp
    )
else()
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        ${GLFW_TARGET}
        ${PORTAUDIO_TARGET}
        Vulkan::Vulkan
        ${ALSA_LIBRARIES}

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
