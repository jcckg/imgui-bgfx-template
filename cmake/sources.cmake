set(SOURCES

    ${SRC_DIR}/ui/styling/styling.cpp
    ${SRC_DIR}/ui.cpp
)

function(configure_include_directories)
    target_include_directories(${EXECUTABLE_NAME} PRIVATE
        ${IMGUI_DIR}
        ${IMGUI_DIR}/backends
        ${SRC_DIR}
        ${SRC_DIR}/backend/bgfx
        ${SRC_DIR}/ui/styling
        ${SRC_DIR}/ui/styling/system_theme
        ${BGFX_DIR}/include
        ${BX_DIR}/include
        ${BIMG_DIR}/include
        ${CMAKE_BINARY_DIR}
    )
endfunction()
