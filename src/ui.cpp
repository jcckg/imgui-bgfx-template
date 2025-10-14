#include <imgui.h>

#include "ui.h"
#include "styling.h"
#include "system_theme_detector.h"

void initialiseApp(UIState& state) {
    if (!state.updateState.hasCheckedThisSession) {
        state.updateChecker.checkForUpdates("${AUTHOR}", "${EXECUTABLE_NAME}");
        state.updateState.hasCheckedThisSession = true;
    }
}

void updateUI(float* clear_color, ImGuiIO& io, UIState& state) {
    static float f = 0.0f;
    static int counter = 0;

    ImGui::Begin("Hello, world!");

    ImGui::Text("This is some useful text.");

    ImGui::SliderFloat("float", &f, 0.0f, 1.0f);
    ImGui::ColorEdit3("clear color", (float*)&clear_color);

    if (ImGui::Button("Button"))
        counter++;
    ImGui::SameLine();
    ImGui::Text("counter = %d", counter);

    ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
    ImGui::End();
}
