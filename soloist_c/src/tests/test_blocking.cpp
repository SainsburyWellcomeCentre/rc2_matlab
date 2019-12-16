#include "rc_soloist.h"
#include <stdio.h>
#include <tchar.h>

/*
Tests blocking behaviour of SoloistProgramStart()
Compile with (or similar)
g++ -o test_blocking.exe test_blocking.cpp rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
*/

int 

int
main(int argc, char **argv)
{
    SoloistHandle *handles;
	DWORD handle_count = 0;
	//int task_state;
	
	// Location of the test aerobasic script
	LPCSTR ab_script = "..\\..\\ab\\tests\\test_blocking.ab";
	
	if(!SoloistConnect(&handles, &handle_count)) { cleanup(handles, handle_count); }
	if(!SoloistProgramLoad(handles[0], 1, ab_script)) { cleanup(handles, handle_count); }
	printf("Starting the aerobasic program\n");
	if(!SoloistProgramStart(handles[0], 1)) { cleanup(handles, handle_count); }
	
	//SoloistProgramGetTaskState(handles[0], 1, &task_state);
	//printf("Task state: %i\n", task_state);
	
	printf("Test result:  it has not/has blocked\n");
	if(!SoloistDisconnect(handles)) { cleanup(handles, handle_count); }
}
