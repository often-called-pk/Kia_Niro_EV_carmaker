
#define CM_HAS_SINCOS 0   // Suppress warning for 32-bit targets.
#include "MathUtils.h"

// define class name and unique id
#define fmi3True            true
#define MODEL_IDENTIFIER    MySteeringSrc_FMU
#define INSTANTIATION_TOKEN "{fdd63009-20c9-4231-8ae8-5192806f060a}"
#define FMI_VERSION         3
#define CO_SIMULATION
#define M(v) (comp->modelData.v)
#define NX   0
#define NZ   0
#define GET_FLOAT64
#define SET_FLOAT64
#define FIXED_SOLVER_STEP 0.001

// define model size
#define NUMBER_OF_REALS            33
#define NUMBER_OF_INTEGERS         0
#define NUMBER_OF_BOOLEANS         0
#define NUMBER_OF_STRINGS          0
#define NUMBER_OF_STATES           0
#define NUMBER_OF_EVENT_INDICATORS 0

// required by fmu3Template
#define EVENT_UPDATE

// define all model variables and their value references
// conventions used here:
// - if x is a variable, then macro x_ is its variable reference
// - the vr of a variable is its index in array  r, i, b or s
// - if k is the vr of a real state, then k+1 is the vr of its derivative

// Parameters
typedef enum {
    iRack2StWhl = 1,
    Irot,
    d,
    RackRange_0,
    RackRange_1,
    TrqAmplify,
    // Inputs
    L_Inert,
    R_Inert,
    L_Frc,
    R_Frc,
    Trq_In,
    PosSign,
    // Outputs
    TrqStatic,
    L_iSteer2q,
    R_iSteer2q,
    L_q,
    L_qp,
    L_qpp,
    R_q,
    R_qp,
    R_qpp,
    Ang,
    AngVel,
    AngAcc,
    Trq
} ValueReference;

typedef struct {
    double iRack2StWhl;
    double Irot;
    double d;
    double RackRange_0;
    double RackRange_1;
    double TrqAmplify;
    double iSteer2Rack;
    // Inputs
    double L_Inert;
    double R_Inert;
    double L_Frc;
    double R_Frc;
    double Trq_In;
    double PosSign;
    // Outputs
    double TrqStatic;
    double L_iSteer2q;
    double R_iSteer2q;
    double L_q;
    double L_qp;
    double L_qpp;
    double R_q;
    double R_qp;
    double R_qpp;
    double Ang;
    double AngVel;
    double AngAcc;
    double Trq;
} ModelData;

#define STATES \
    {          \
    }

// include fmu header files, typedefs and macros
#include "fmu3Template.h"
#include "fmi3FunctionTypes.h"

// called by fmi3InstantiateXXX
// Set values for all variables that define a start value
// Settings used unless changed by fmiSetX before fmiInitialize
void
setStartValues(ModelInstance *comp)
{
    // set start Values if any
}

Status
calculateValues(ModelInstance *comp)
{
    comp->nextEventTimeDefined = fmi3True;
    comp->nextEventTime        = -1;
    return OK;
}

// called by fmi3GetFloat64
Status
getFloat64(ModelInstance *comp, ValueReference vr, double *value, size_t *index)
{
    switch (vr) {
        case iRack2StWhl:
            value[(*index)++] = M(iRack2StWhl);
            return OK;
        case Irot:
            value[(*index)++] = M(Irot);
            return OK;
        case d:
            value[(*index)++] = M(d);
            return OK;
        case RackRange_0:
            value[(*index)++] = M(RackRange_0);
            return OK;
        case RackRange_1:
            value[(*index)++] = M(RackRange_1);
            return OK;
        case TrqAmplify:
            value[(*index)++] = M(TrqAmplify);
            return OK;
            // Inputs
        case L_Inert:
            value[(*index)++] = M(L_Inert);
            return OK;
        case R_Inert:
            value[(*index)++] = M(R_Inert);
            return OK;
        case L_Frc:
            value[(*index)++] = M(L_Frc);
            return OK;
        case R_Frc:
            value[(*index)++] = M(R_Frc);
            return OK;
        case Trq_In:
            value[(*index)++] = M(Trq_In);
            return OK;
        case PosSign:
            value[(*index)++] = M(PosSign);
            return OK;
            // Outputs
        case TrqStatic:
            value[(*index)++] = M(TrqStatic);
            return OK;
        case L_iSteer2q:
            value[(*index)++] = M(L_iSteer2q);
            return OK;
        case R_iSteer2q:
            value[(*index)++] = M(R_iSteer2q);
            return OK;
        case L_q:
            value[(*index)++] = M(L_q);
            return OK;
        case L_qp:
            value[(*index)++] = M(L_qp);
            return OK;
        case L_qpp:
            value[(*index)++] = M(L_qpp);
            return OK;
        case R_q:
            value[(*index)++] = M(R_q);
            return OK;
        case R_qp:
            value[(*index)++] = M(R_qp);
            return OK;
        case R_qpp:
            value[(*index)++] = M(R_qpp);
            return OK;
        case Ang:
            value[(*index)++] = M(Ang);
            return OK;
        case AngVel:
            value[(*index)++] = M(AngVel);
            return OK;
        case AngAcc:
            value[(*index)++] = M(AngAcc);
            return OK;
        case Trq:
            value[(*index)++] = M(Trq);
            return OK;
        default:
            return Error;
    }
}

// called by fmi3SetFloat64
Status
setFloat64(ModelInstance *comp, ValueReference vr, double const *value, size_t *index)
{
    switch (vr) {
        case iRack2StWhl:
            M(iRack2StWhl) = value[(*index)++];
            return OK;
        case Irot:
            M(Irot) = value[(*index)++];
            return OK;
        case d:
            M(d) = value[(*index)++];
            return OK;
        case RackRange_0:
            M(RackRange_0) = value[(*index)++];
            return OK;
        case RackRange_1:
            M(RackRange_1) = value[(*index)++];
            return OK;
        case TrqAmplify:
            M(TrqAmplify) = value[(*index)++];
            return OK;
            // Inputs
        case L_Inert:
            M(L_Inert) = value[(*index)++];
            return OK;
        case R_Inert:
            M(R_Inert) = value[(*index)++];
            return OK;
        case L_Frc:
            M(L_Frc) = value[(*index)++];
            return OK;
        case R_Frc:
            M(R_Frc) = value[(*index)++];
            return OK;
        case Trq_In:
            M(Trq_In) = value[(*index)++];
            return OK;
        case PosSign:
            M(PosSign) = value[(*index)++];
            return OK;

            // Outputs
        case TrqStatic:
            M(TrqStatic) = value[(*index)++];
            return OK;
        case L_iSteer2q:
            M(L_iSteer2q) = value[(*index)++];
            return OK;
        case R_iSteer2q:
            M(R_iSteer2q) = value[(*index)++];
            return OK;
        case L_q:
            M(L_q) = value[(*index)++];
            return OK;
        case L_qp:
            M(L_qp) = value[(*index)++];
            return OK;
        case L_qpp:
            M(L_qpp) = value[(*index)++];
            return OK;
        case R_q:
            M(R_q) = value[(*index)++];
            return OK;
        case R_qp:
            M(R_qp) = value[(*index)++];
            return OK;
        case R_qpp:
            M(R_qpp) = value[(*index)++];
            return OK;
        case Ang:
            M(Ang) = value[(*index)++];
            return OK;
        case AngVel:
            M(AngVel) = value[(*index)++];
            return OK;
        case AngAcc:
            M(AngAcc) = value[(*index)++];
            return OK;
        case Trq:
            M(Trq) = value[(*index)++];
            return OK;
        default:
            return Error;
    }
}

// called by fmi3UpdateDiscreteStates() and fmi3DoStep()
// Used to set the next time event, if any.
void
eventUpdate(ModelInstance *comp)
{
    double        val, Frc, mass;
    static double q = 0, qp = 0, qpp = 0, lastT;
    double const  kRackBuf = 1e6;
    double const  dRackBuf = 1e4;
    double        dt       = (comp->time - lastT);

    M(iSteer2Rack) = 1.0 / M(iRack2StWhl) * M(PosSign);

    /*** Kinematics */
    mass = M(Irot) / (M(iSteer2Rack) * M(iSteer2Rack)) + M(L_Inert) + M(R_Inert);

    /*** Kinetics */
    Frc = M(TrqAmplify) * M(Trq_In) / M(iSteer2Rack) + (M(L_Frc) + M(R_Frc)) - M(d) / M(iSteer2Rack) * qp;

    /*** Limitation of rack buffers */
    if (q < M(RackRange_0)) {
        double val  = q - M(RackRange_0);
        Frc        += -kRackBuf * val - dRackBuf * qp;

    } else if (q > M(RackRange_1)) {
        double val  = q - M(RackRange_1);
        Frc        += -kRackBuf * val - dRackBuf * qp;
    }

    /*** DOF equation */
    qpp = Frc / mass;

    /*** Integration */
    qp += qpp * dt;
    q  += qp * dt;

    /*** Assignment */
    M(L_q) = M(R_q) = q;
    M(L_qp) = M(R_qp) = qp;
    M(L_qpp) = M(R_qpp) = qpp;

    val       = 1.0 / M(iSteer2Rack);
    M(Ang)    = val * q;
    M(AngVel) = val * qp;
    M(AngAcc) = val * qpp;

    M(L_iSteer2q) = M(R_iSteer2q) = M(iSteer2Rack);

    /*
     * The signal TrqStatic is only an output signal or
     * an additional information!
     *
     * steering wheel torque, to keep the wheel in its position
     * under static conditions
     */
    M(TrqStatic) = M(L_iSteer2q) * M(L_Frc) + M(R_iSteer2q) * M(R_Frc);
    lastT        = comp->time;

    comp->valuesOfContinuousStatesChanged   = false;
    comp->nominalsOfContinuousStatesChanged = false;
    comp->terminateSimulation               = false;
    comp->nextEventTimeDefined              = true;
}

// include code that implements the FMI based on the above definitions
#include "fmu3Template.c"
