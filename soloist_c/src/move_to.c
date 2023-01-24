#include "rc_soloist.h"
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>




int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
    BOOL time_out;
    
    if (argc < 4) {
        printf("must have at least 3 numeric arguments.\n");
        return 1;
    }
    
    DOUBLE position = atof(argv[1]);
    DOUBLE speed = atof(argv[2]);
    int leave_enabled = atoi(argv[3]);
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }

    // Setup analog output velocity tracking
    if(!SoloistAdvancedAnalogTrack(handles[0], AO_CHANNEL, AO_SERVO_VALUE, AO_SCALE_FACTOR, 0.0)){ cleanup(handles, handle_count); }
    
    // Reset gear parameters
    reset_gear(handles, handle_count);
    
    // Enable axis
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Move to the default position at the default speed
    if(!SoloistMotionSetupRampRateAccel(handles[0], DEFAULT_RAMPRATE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionSetupRampMode(handles[0], DEFAULT_RAMPMODE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionMoveAbs(handles[0], position, speed)) { cleanup(handles, handle_count); }
    
    // Make sure controller waits for move to finish
    if(!SoloistMotionWaitForMotionDone(handles[0], WAITOPTION_MoveDone, 50000, &time_out)) { cleanup(handles, handle_count); }
    
    
    // If we have requested, stay enabled.
    if (!leave_enabled) {
        if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    }
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
