#ifndef STATE_H
#define STATE_H

#include "updates/update.h"

struct UIState {
    UpdateState updateState;
    UpdateChecker updateChecker;
};

#endif
