#include "ui.h"
#include "styling.h"
#include "system_theme_detector.h"

void updateUI(float* clear_color, ImGuiIO& io) {
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

    ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", (double)(1000.0f / io.Framerate), (double)io.Framerate);

    ImGui::End();
}
