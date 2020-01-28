#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
#include "rc_soloist.h"
#include <stdio.h>
#include <tchar.h>



int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Reset gear parameters
    reset_gear(handles, handle_count);
    
    // Enable
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Move to the default position at the default speed
    if(!SoloistMotionSetupRampRateAccel(handles[0], DEFAULT_RAMPRATE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionSetupRampMode(handles[0], DEFAULT_RAMPMODE)) { cleanup(handles, handle_count); }
    if(!SoloistMotionMoveAbs(handles[0], DEFAULT_POSITION, DEFAULT_SPEED)) { cleanup(handles, handle_count); }
    
    // Make sure controller waits for move to finish
    if(!SoloistMotionWaitForMotionDone(handles[0], WAITOPTION_MoveDone, 50000, NULL)) { cleanup(handles, handle_count); }
    
    // Disable
    if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
