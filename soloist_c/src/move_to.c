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
    
    if (argc < 2) {
        printf("must have at least 2 numeric arguments.\n");
        return 1;
    }
    
    DOUBLE position = atof(argv[1]);
    int leave_enabled = atoi(argv[2]);
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Reset gear parameters
    reset_gear(handles, handle_count);
    
    // Enable axis
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Move to the default position at the default speed
    if(!SoloistMotionSetupRampRateAccel(handles[0], DEFAULT_RAMPRATE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionSetupRampMode(handles[0], DEFAULT_RAMPMODE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionMoveAbs(handles[0], position, DEFAULT_SPEED)) { cleanup(handles, handle_count); }
    
    // If we have requested, stay enabled.
    if (!leave_enabled) {
        if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    }
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
