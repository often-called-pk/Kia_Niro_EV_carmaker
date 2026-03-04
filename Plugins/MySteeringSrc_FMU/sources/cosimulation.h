/*
 * cosimulation.h
 * - based on https://github.com/modelica/Reference-FMUs/blob/main/include/cosimulation.h
 */

#pragma once

#include "fmu3Template.h"

#define EPSILON (FIXED_SOLVER_STEP * 1e-6)

void doFixedStep(ModelInstance *comp, bool* stateEvent, bool* timeEvent);
