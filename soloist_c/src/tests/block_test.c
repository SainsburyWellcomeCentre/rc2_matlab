#include <stdio.h>
#include <unistd.h>
#include <windows.h>

BOOL WINAPI consoleHandler(DWORD signal) {
    
    printf("not handling this");
    if (signal == CTRL_C_EVENT) {
        printf("handling this");
        exit(2);
    }
    
    return 2;
}


int
main(int argc, char **argv) {
    
    if (!SetConsoleCtrlHandler(consoleHandler, TRUE)) {
        printf("cannot setup handler");
        return 1;
    }
    
    printf("sleeping for 5 seconds...\n");
    sleep(5);
    printf("done\n");
    return(0);
}