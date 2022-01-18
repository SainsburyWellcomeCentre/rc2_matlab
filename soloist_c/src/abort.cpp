#include "rc_soloist.h"
#include <iostream>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <tchar.h>



int
main () {
    
    SoloistHandle *handles;
	DWORD handle_count = 0;
    
    // Connect to soloist.
    if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
    
    
    for(std::string line; std::getline(std::cin, line);) {
        
        if (line.compare("abort") == 0) {
            
            if(!SoloistMotionAbort(handles[0])) { cleanup(handles, handle_count); }
            usleep(5000);
            if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
            printf("aborted...\n");
            // Reset gear parameters
            reset_gear(handles, handle_count);
            
        } else if (line.compare("close") == 0) {
            
            // Reset gear parameters
            reset_gear(handles, handle_count);
            if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
            if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
            printf("shutdown...\n");
            
        } else if (line.compare("stop") == 0) {
            
            if(!SoloistMotionDisable(handles[0])) { cleanup(handles, handle_count); }
            printf("stopped...\n");
            // Reset gear parameters
            reset_gear(handles, handle_count);
            
        } else if (line.compare("reset_pso") == 0) {
            
            if(!SoloistPSOControl(handles[0], PSOMODE_Reset)) { cleanup(handles, handle_count); }
            printf("pso_reset...\n");
            
        }
    }
    
    return 0;
}
