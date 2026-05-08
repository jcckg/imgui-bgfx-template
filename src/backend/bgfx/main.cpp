#include "imgui.h"
#include "imgui_impl_bgfx.h"
#include "imgui_impl_glfw.h"

#include "ui.h"

#include <algorithm>
#include <array>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <bgfx/bgfx.h>
#include <bgfx/platform.h>

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

#if defined(_WIN32)
#define GLFW_EXPOSE_NATIVE_WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#elif defined(__APPLE__)
#define GLFW_EXPOSE_NATIVE_COCOA
#else
#define GLFW_EXPOSE_NATIVE_X11
#define GLFW_EXPOSE_NATIVE_WAYLAND
#endif
#include <GLFW/glfw3native.h>

namespace {

constexpr bgfx::ViewId kClearViewId = 0;
constexpr bgfx::ViewId kImGuiViewId = 1;
constexpr int kDefaultWindowWidth = 1280;
constexpr int kDefaultWindowHeight = 800;

class BgfxCallback final : public bgfx::CallbackI {
public:
    void fatal(const char* filePath, uint16_t line, bgfx::Fatal::Enum code, const char* message) override {
        std::fprintf(
            stderr,
            "[bgfx] fatal 0x%08x at %s:%u: %s\n",
            static_cast<unsigned int>(code),
            filePath != nullptr ? filePath : "<unknown>",
            static_cast<unsigned int>(line),
            message != nullptr ? message : "<no message>");
        std::fflush(stderr);

        if (code != bgfx::Fatal::DebugCheck) {
            std::abort();
        }
    }

    void traceVargs(const char*, uint16_t, const char*, va_list) override {
    }

    void profilerBegin(const char*, uint32_t, const char*, uint16_t) override {
    }

    void profilerBeginLiteral(const char*, uint32_t, const char*, uint16_t) override {
    }

    void profilerEnd() override {
    }

    uint32_t cacheReadSize(uint64_t) override {
        return 0;
    }

    bool cacheRead(uint64_t, void*, uint32_t) override {
        return false;
    }

    void cacheWrite(uint64_t, const void*, uint32_t) override {
    }

    void screenShot(const char*, uint32_t, uint32_t, uint32_t, bgfx::TextureFormat::Enum, const void*, uint32_t, bool) override {
    }

    void captureBegin(uint32_t, uint32_t, uint32_t, bgfx::TextureFormat::Enum, bool) override {
    }

    void captureEnd() override {
    }

    void captureFrame(const void*, uint32_t) override {
    }
};

void glfwErrorCallback(int error, const char* description) {
    std::fprintf(stderr, "GLFW Error %d: %s\n", error, description != nullptr ? description : "unknown");
}

bgfx::PlatformData platformData(GLFWwindow* window) {
    bgfx::PlatformData data{};

#if defined(_WIN32)
    data.nwh = glfwGetWin32Window(window);
#elif defined(__APPLE__)
    data.nwh = glfwGetCocoaWindow(window);
#else
    if (glfwGetPlatform() == GLFW_PLATFORM_WAYLAND) {
        data.ndt = glfwGetWaylandDisplay();
        data.nwh = glfwGetWaylandWindow(window);
        data.type = bgfx::NativeWindowHandleType::Wayland;
    } else {
        data.ndt = glfwGetX11Display();
        data.nwh = reinterpret_cast<void*>(static_cast<uintptr_t>(glfwGetX11Window(window)));
        data.type = bgfx::NativeWindowHandleType::Default;
    }
#endif

    return data;
}

bgfx::RendererType::Enum preferredRendererType() {
#if defined(_WIN32)
    return bgfx::RendererType::Direct3D12;
#elif defined(__APPLE__)
    return bgfx::RendererType::Metal;
#else
    return bgfx::RendererType::Vulkan;
#endif
}

bool initialiseBgfx(GLFWwindow* window, uint32_t width, uint32_t height) {
#if defined(__APPLE__)
    bgfx::renderFrame(0);
#endif

    std::array rendererCandidates{
        preferredRendererType(),
#if defined(_WIN32)
        bgfx::RendererType::Direct3D11,
#else
        preferredRendererType(),
#endif
    };

    for (const bgfx::RendererType::Enum renderer : rendererCandidates) {
        bgfx::Init init;
        static BgfxCallback callback;
        init.type = renderer;
        init.fallback = false;
        init.callback = &callback;
        init.platformData = platformData(window);
        init.resolution.width = std::max(width, 1u);
        init.resolution.height = std::max(height, 1u);
        init.resolution.reset = BGFX_RESET_VSYNC
#if defined(__APPLE__)
            | BGFX_RESET_HIDPI
#endif
            ;

        if (bgfx::init(init)) {
            return true;
        }
    }

    return false;
}

void setViewRects(uint32_t width, uint32_t height) {
    const auto viewWidth = static_cast<uint16_t>(std::min(width, static_cast<uint32_t>(UINT16_MAX)));
    const auto viewHeight = static_cast<uint16_t>(std::min(height, static_cast<uint32_t>(UINT16_MAX)));
    bgfx::setViewRect(kClearViewId, 0, 0, viewWidth, viewHeight);
    bgfx::setViewRect(kImGuiViewId, 0, 0, viewWidth, viewHeight);
}

uint32_t packRgba8(float red, float green, float blue, float alpha) {
    const auto toByte = [](float value) -> uint32_t {
        return static_cast<uint32_t>(std::clamp(value, 0.0f, 1.0f) * 255.0f + 0.5f);
    };

    return (toByte(red) << 24) | (toByte(green) << 16) | (toByte(blue) << 8) | toByte(alpha);
}

} // namespace

int main(int, char**) {
    glfwSetErrorCallback(glfwErrorCallback);
    if (glfwInit() != GLFW_TRUE) {
        return 1;
    }

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);

    const float mainScale = ImGui_ImplGlfw_GetContentScaleForMonitor(glfwGetPrimaryMonitor());
    GLFWwindow* window = glfwCreateWindow(
        static_cast<int>(kDefaultWindowWidth * mainScale),
        static_cast<int>(kDefaultWindowHeight * mainScale),
        APP_TITLE_STRING,
        nullptr,
        nullptr);
    if (window == nullptr) {
        glfwTerminate();
        return 1;
    }

    int framebufferWidth = 0;
    int framebufferHeight = 0;
    glfwGetFramebufferSize(window, &framebufferWidth, &framebufferHeight);

    if (!initialiseBgfx(window, static_cast<uint32_t>(framebufferWidth), static_cast<uint32_t>(framebufferHeight))) {
        std::fprintf(stderr, "Failed to initialise bgfx\n");
        glfwDestroyWindow(window);
        glfwTerminate();
        return 1;
    }

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;

    ImGui::StyleColorsDark();
    ImGui::GetStyle().ScaleAllSizes(mainScale);

    ImGui_ImplGlfw_InitForOther(window, true);
    ImGui_Implbgfx_Init(kImGuiViewId);

    ImVec4 clearColor = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    while (glfwWindowShouldClose(window) == 0) {
        glfwPollEvents();

        int currentWidth = 0;
        int currentHeight = 0;
        glfwGetFramebufferSize(window, &currentWidth, &currentHeight);
        if (currentWidth != framebufferWidth || currentHeight != framebufferHeight) {
            framebufferWidth = currentWidth;
            framebufferHeight = currentHeight;
            bgfx::reset(
                static_cast<uint32_t>(std::max(framebufferWidth, 1)),
                static_cast<uint32_t>(std::max(framebufferHeight, 1)),
                BGFX_RESET_VSYNC
#if defined(__APPLE__)
                    | BGFX_RESET_HIDPI
#endif
            );
        }

        ImGui_Implbgfx_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        updateUI(reinterpret_cast<float*>(&clearColor), io);

        ImGui::Render();

        if (framebufferWidth > 0 && framebufferHeight > 0) {
            setViewRects(static_cast<uint32_t>(framebufferWidth), static_cast<uint32_t>(framebufferHeight));
            const uint32_t packedClear = packRgba8(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
            bgfx::setViewClear(kClearViewId, BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH, packedClear, 1.0f, 0);
            bgfx::touch(kClearViewId);
            ImGui_Implbgfx_RenderDrawData(ImGui::GetDrawData());
        }

        bgfx::frame();
    }

    ImGui_Implbgfx_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    bgfx::shutdown();
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
