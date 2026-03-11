##
## ManeuverStepJump.tcl
## CarMaker 15.0 ScriptControl Example - IPG Automotive GmbH (www.ipg-automotive.com)
##
## This example shows how to jump between maneuver steps.
##
## StepJump <step_no>
##     <step_no> number of a combined maneuver step.
##
## Id

Log "* Load Test Run and start simulation"
LoadTestRun "Examples/VehicleDynamics/Braking/Braking"

StartSim
WaitForStatus running
Sleep 10000

# jump to combined maneuver step 1
Log "* Jump to combined maneuver step 1"
StepJump 1

Sleep 500

# jump to combined maneuver step 0
Log "* Jump back to combined maneuver step 0"
StepJump 0

Sleep 5000

# jump to combined maneuver step 1
Log "* Jump to combined maneuver step 1"
StepJump 1

Sleep 1000

# jump to combined maneuver step 0
Log "* Jump back to combined maneuver step 0"
StepJump 0

# wait for the simulation to stop
WaitForStatus idle
