/*
calibrate_zero.c
Takes an initial estimate of the voltage offset.
Enters gear mode, records several values of the analog input.
Averages those values and returns them on standard output.
*/



#include "rc_soloist.h"
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>

/* number of iterations to record */
#define N_ITER 100


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
    
    // Check number of arguments.
    if (argc < 3) {
        printf("must have at least 3 numeric arguments.\n");
        return 1;
    }
    
    // Arguments
    DOUBLE backward_limit = atof(argv[1]);
    DOUBLE forward_limit = atof(argv[2]);
    DOUBLE ai_offset = atof(argv[3]);
    
    // Setup iteration to record the analog input.
    int iter = 0;
    DOUBLE ai_value[N_ITER];
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Get the number of counts per unit.
    if(!SoloistParameterGetValue(handles[0], PARAMETERID_CountsPerUnit, 1, &cnts_per_unit)) { cleanup(handles, handle_count); }
    
    // Calculate the scale from the input voltage, speed and counts per unit
    max_speed_scale = (MAX_INPUT_SPEED * cnts_per_unit)/1000;
    gear_scale = -(max_speed_scale * (1/MAX_INPUT_VOLTAGE));
    
    // Set the gearing parameters...
    gear_set = set_gear_params(handles, GEARCAM_SOURCE, gear_scale, DEADBAND, 0);
    if (gear_set != 0) { cleanup(handles, handle_count); }
    
    // Enable
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Subtract offset on analog input
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_Analog0InputOffset, 1, ai_offset)) { cleanup(handles, handle_count); }
    
    // Set to gear mode... no turning back now.
    if(!SoloistCommandExecute(handles[0], "GEAR 1", NULL)) { cleanup(handles, handle_count); }
    
    // Stay in gear mode until one of the following conditions is satisfied
    int looping = 1;
    
    while (looping) {
        
        // Run several checks to make sure that we are safe.
        
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
        
        // Stop looping after N_ITER
        if (iter >= N_ITER) {
            looping = 0;
        }
        
        // Store the analog input level
        SoloistIOAnalogInput(handles[0], AI_CHANNEL, &(ai_value[iter++]));
    }
    
    // Disable the axis.
    if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    
    // Reset the gear parameters to their defaults.
    reset_gear(handles, handle_count);
    
    // Calculate the average analog offset.
    DOUBLE sum = 0;
    for (int i = 0; i < N_ITER; i++) {
        sum += ai_value[i];
    }
    DOUBLE mean = sum/N_ITER;
    
    // print the result to standard output
    printf("%.10f\n", mean);
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
