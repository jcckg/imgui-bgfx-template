#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_metal.h"
#include "ui.h"
#include "system_theme_detector.h"
#include <stdio.h>

#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

static void glfw_error_callback(int error, const char* description)
{
    fprintf(stderr, "Glfw Error %d: %s\n", error, description);
}

void windowStyling(GLFWwindow* window) {
    NSWindow* nsWindow = glfwGetCocoaWindow(window);

    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.titleVisibility = NSWindowTitleHidden;

    nsWindow.opaque = NO;
    nsWindow.backgroundColor = [NSColor clearColor];

    NSVisualEffectView* visualEffectView = [[NSVisualEffectView alloc] init];
    if (@available(macOS 10.14, *)) {
        visualEffectView.material = NSVisualEffectMaterialUnderWindowBackground;
    } else {
        visualEffectView.material = NSVisualEffectMaterialTitlebar;
    }

    visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    visualEffectView.state = NSVisualEffectStateFollowsWindowActiveState;
    
    NSView* originalContentView = nsWindow.contentView;
    nsWindow.contentView = visualEffectView;
    
    [visualEffectView addSubview:originalContentView];
    originalContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [originalContentView.topAnchor constraintEqualToAnchor:visualEffectView.topAnchor],
        [originalContentView.bottomAnchor constraintEqualToAnchor:visualEffectView.bottomAnchor],
        [originalContentView.leadingAnchor constraintEqualToAnchor:visualEffectView.leadingAnchor],
        [originalContentView.trailingAnchor constraintEqualToAnchor:visualEffectView.trailingAnchor]
    ]];
    
    [nsWindow invalidateShadow];

    CABasicAnimation* scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @0.95;
    scaleAnimation.toValue = @1.0;
    scaleAnimation.duration = 0.3;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [visualEffectView.layer addAnimation:scaleAnimation forKey:@"windowAppear"];
}

void getThemeBackgroundColor(float* color) {
    SystemTheme theme = SystemThemeDetector::detectSystemTheme();
    if (theme == SystemTheme::Light) {
        // Light theme background
        color[0] = 1.00f;
        color[1] = 1.00f;
        color[2] = 1.00f;
        color[3] = 1.00f;
    } else {
        // Dark theme background
        color[0] = 0.00f;
        color[1] = 0.00f;
        color[2] = 0.00f;
        color[3] = 1.00f;
    }
}

int main(int, char**)
{
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit())
        return 1;

    // Create window with graphics context
    float main_scale = ImGui_ImplGlfw_GetContentScaleForMonitor(glfwGetPrimaryMonitor());
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow* window = glfwCreateWindow((int)(1280 * main_scale), (int)(800 * main_scale), "Dear ImGui GLFW+Metal example", nullptr, nullptr);
    if (window == nullptr)
        return 1;

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    // Setup scaling
    ImGuiStyle& style = ImGui::GetStyle();
    style.ScaleAllSizes(main_scale);
    style.FontScaleDpi = main_scale;

    id <MTLDevice> device = MTLCreateSystemDefaultDevice();
    id <MTLCommandQueue> commandQueue = [device newCommandQueue];

    // Setup Platform/Renderer backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplMetal_Init(device);

    NSWindow *nswin = glfwGetCocoaWindow(window);
    CAMetalLayer *layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    nswin.contentView.layer = layer;
    nswin.contentView.wantsLayer = YES;

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];

    // Our state
    bool show_demo_window = true;
    bool show_another_window = false;
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
    UIState uiState;

    // Main loop
    while (!glfwWindowShouldClose(window))
    {
        @autoreleasepool
        {
            glfwPollEvents();

            int width, height;
            glfwGetFramebufferSize(window, &width, &height);
            layer.drawableSize = CGSizeMake(width, height);
            id<CAMetalDrawable> drawable = [layer nextDrawable];

            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clear_color[0] * clear_color[3], clear_color[1] * clear_color[3], clear_color[2] * clear_color[3], clear_color[3]);
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
            renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
            renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui demo"];

            // Start the Dear ImGui frame
            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui_ImplGlfw_NewFrame();
            ImGui::NewFrame();

            // Display our UI
            updateUI(clear_color, io, uiState);

            // Rendering
            ImGui::Render();
            ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:drawable];
            [commandBuffer commit];
        }
    }

    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
