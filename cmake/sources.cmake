set(SOURCES
    ${SRC_DIR}/updates/update.cpp
    ${SRC_DIR}/ui/styling/styling.cpp
    ${SRC_DIR}/ui.cpp
)

function(configure_include_directories)
    target_include_directories(${EXECUTABLE_NAME} PRIVATE
        ${IMGUI_DIR}
        ${IMGUI_DIR}/backends
        ${SRC_DIR}
        ${SRC_DIR}/ui/styling
        ${SRC_DIR}/ui/styling/system_theme
        ${CMAKE_BINARY_DIR}
        /opt/homebrew/include
    )
endfunction()
