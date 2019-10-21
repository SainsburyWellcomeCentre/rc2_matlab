#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
#include "rc_soloist.h"
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>




int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
    
    DOUBLE cnts_per_unit;
    DOUBLE return_value, return_value_pos, return_value_vel;
    double max_speed_scale;
    double gear_scale;
    int gear_set;
    DWORD ready_to_go = 1; // digital input starts high
    LPCSTR filename = "C:\\Users\\Mateo\\Documents\\rc_version2_0\\rc2_matlab\\soloist_c\\ab\\listen_until_main_loop.ab";
    
    if (argc < 2) {
        printf("must have at least 2 numeric arguments.\n");
        return 1;
    }
    
    // Arguments
    DOUBLE backward_limit = atof(argv[1]);
    DOUBLE forward_limit = atof(argv[2]);
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Setup analog output velocity tracking
    if(!SoloistAdvancedAnalogTrack(handles[0], AO_CHANNEL, AO_SERVO_VALUE, AO_SCALE_FACTOR, 0.0)){ cleanup(handles, handle_count); }
    
    // Setup pso output
    if(!SoloistPSOControl(handles[0], PSOMODE_Reset)) { cleanup(handles, handle_count); }
    if(!SoloistPSOPulseCyclesAndDelay(handles[0], 10000, 5000, 1, 0)) { cleanup(handles, handle_count); }
    if(!SoloistPSOOutputPulse(handles[0])) { cleanup(handles, handle_count); }
    
    // Get the number of counts per unit.
    if(!SoloistParameterGetValue(handles[0], PARAMETERID_CountsPerUnit, 1, &cnts_per_unit)) { cleanup(handles, handle_count); }
    printf("Counts per unit: %.2f\n", cnts_per_unit);
    
    // Calculate the scale from the input voltage, speed and counts per unit
    max_speed_scale = (MAX_INPUT_SPEED * cnts_per_unit)/1000;
    gear_scale = -(max_speed_scale * (1/MAX_INPUT_VOLTAGE));
    
    // Set the gearing parameters...
    gear_set = set_gear_params(handles, GEARCAM_SOURCE, gear_scale, DEADBAND, 0);
    if (gear_set != 0) { cleanup(handles, handle_count); }
    
    // Enable
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Subtract offset on analog input
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_Analog0InputOffset, 1, AI_OFFSET)) { cleanup(handles, handle_count); }
    
    // Wait for a trigger to go low.
    //while (ready_to_go == 1) {
    //    if(!SoloistIODigitalInput(handles[0], DI_PORT, &ready_to_go)) { cleanup(handles, handle_count); }
    //}
    
    // Set to gear mode... no turning back now.
    if(!SoloistCommandExecute(handles[0], "GEAR 1", NULL)) { cleanup(handles, handle_count); }
    
    // Stay in gear mode until one of the following conditions is satisfied
    int looping = 1;
    
    printf("Start loop\n");
    while (looping) {
        
        // Exit loop if there is a fault on the axis
        if(!SoloistCommandExecute(handles[0], "RET = AXISFAULT()", &return_value)) { cleanup(handles, handle_count); }
        if (return_value > 0.5) {
            looping = 0;
        }
        
        // Exit loop if there treadmill moves to reward zone
        //DRIVEINFO_PositionCommandRaw = 94
        if(!SoloistCommandExecute(handles[0], "RET = DRIVEINFO (94)", &return_value_pos)) { cleanup(handles, handle_count); }
        if (return_value_pos < forward_limit | return_value_pos > backward_limit) {
            looping = 0;
        }
        
        // Exit loop if velocity is above a limit.
        if(!SoloistCommandExecute(handles[0], "RET = VFBK()", &return_value_vel)) { cleanup(handles, handle_count); }
        if (abs(return_value_vel) > SPEED_LIMIT) {
            looping = 0;
        }
    }
    
    // Disable the axis.
    if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    
    // Pulse the digital output
    if(!SoloistPSOControl(handles[0], PSOMODE_Fire)) { cleanup(handles, handle_count); }
    
    // Reset the gear parameters to their defaults.
    reset_gear(handles, handle_count);
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
