#include <stdio.h>
#include <tchar.h>
#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
#include "rc_soloist.h"



int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    // Reset just in case
    reset_gear(handles, handle_count);
    
    // Enable and leave enabled
    if(!SoloistMotionEnable(handles[0])) { cleanup(handles, handle_count); }
    
    // Disconnect from Soloist
    if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}