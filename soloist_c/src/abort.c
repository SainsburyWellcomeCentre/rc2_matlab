#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
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
            if (reset_running == false) {
                threads.emplace_back(reset);
                reset_running = true;
            }
        } else if (line.compare("close") == 0) {
            
        } else {
            
        }
    }
    
    return 0;
}
