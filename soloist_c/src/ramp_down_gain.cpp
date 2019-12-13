#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
#include "rc_soloist.h"
#include <ctime>
#include <chrono>
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>
#include <unistd.h>


int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
    
    if (argc < 5) {
        printf("must have at least 5 numeric arguments.\n");
        return 1;
    }
    
    // Arguments
    DOUBLE backward_limit = atof(argv[1]);
    DOUBLE forward_limit = atof(argv[2]);
    DOUBLE ai_offset = atof(argv[3]);
    DOUBLE gear_scale = atof(argv[4]);
    DOUBLE deadband = atof(argv[5]);
    
    DOUBLE gear_scale_now;
    
    DOUBLE return_value, return_value_pos, return_value_vel;
    int gear_set;
    DWORD ready_to_go = 1; // digital input starts high
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Setup analog output velocity tracking
    if(!SoloistAdvancedAnalogTrack(handles[0], AO_CHANNEL, AO_SERVO_VALUE, AO_SCALE_FACTOR, 0.0)){ cleanup(handles, handle_count); }
    
    // Setup pso output
    if(!SoloistPSOControl(handles[0], PSOMODE_Reset)) { cleanup(handles, handle_count); }
    if(!SoloistPSOPulseCyclesAndDelay(handles[0], 1000000, 500000, 1, 0)) { cleanup(handles, handle_count); }
    if(!SoloistPSOOutputPulse(handles[0])) { cleanup(handles, handle_count); }
    
    
    // Set the gearing parameters...
    gear_set = set_gear_params(handles, GEARCAM_SOURCE, gear_scale, deadband, 0);
    if (gear_set != 0) { cleanup(handles, handle_count); }
    
    
    // Enable
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    
    // Subtract offset on analog input
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_Analog0InputOffset, 1, ai_offset)) { cleanup(handles, handle_count); }
    
    
    // Wait for a trigger to go low.
    while (ready_to_go == 1) {
        if(!SoloistIODigitalInput(handles[0], DI_PORT, &ready_to_go)) { cleanup(handles, handle_count); }
    }
    
    
    // Set to gear mode... no turning back now.
    if(!SoloistCommandExecute(handles[0], "GEAR 1", NULL)) { cleanup(handles, handle_count); }
    
    // Stay in gear mode until one of the following conditions is satisfied
    int looping = 1;
    int success = 0;
    
    printf("Start loop\n");
    while (looping) {
        
        // Exit loop if there is a fault on the axis
        if(!SoloistCommandExecute(handles[0], "RET = AXISFAULT()", &return_value)) { cleanup(handles, handle_count); }
        if (return_value > 0.5) {
            looping = 0;
            success = 0;
        }
        
        // Exit loop if there treadmill moves to reward zone
        //DRIVEINFO_PositionCommandRaw = 94
        if(!SoloistCommandExecute(handles[0], "RET = DRIVEINFO (94)", &return_value_pos)) { cleanup(handles, handle_count); }
        if (return_value_pos < forward_limit | return_value_pos > backward_limit) {
            looping = 0;
            success = 1;
            
        }
        
        // Exit loop if velocity is above a limit.
        if(!SoloistCommandExecute(handles[0], "RET = VFBK()", &return_value_vel)) { cleanup(handles, handle_count); }
        if (abs(return_value_vel) > SPEED_LIMIT) {
            looping = 0;
            success = 0;
        }
    }
    
    // If ends have been reached ramp the gain down to zero over 200ms.
    auto initial_time = std::chrono::steady_clock::now();
    int out_of_time = 1;
    int n_loops = 0;
    double factor;
    
    if (success) {
        while (out_of_time) {
            
            auto time_now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(time_now - initial_time);
            
            out_of_time = (elapsed.count() < 200000);
            
            factor = (1 - ((double) elapsed.count())/200000);
            if (factor < 0) factor = 0;
            gear_scale_now = gear_scale * factor;
            n_loops += 1;
            //printf("%i\n", elapsed.count());
            
            usleep(50000);
            
            if(!SoloistParameterSetValue(handles[0], PARAMETERID_GearCamScaleFactor , 1, gear_scale_now)) { return -1; }
        }
    }
    
    printf("%i\n", n_loops);
    
    // Disable the axis.
    if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    
    // Pulse the digital output
    if(!SoloistPSOControl(handles[0], PSOMODE_Fire)) { cleanup(handles, handle_count); }
    
    // Reset the gear parameters to their defaults.
    reset_gear(handles, handle_count);
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
