#ifndef UI_H
#define UI_H

#include "state.h"

void initialiseApp(UIState& state);
void updateUI(float* clear_colour, ImGuiIO &io, UIState& state);

#endif