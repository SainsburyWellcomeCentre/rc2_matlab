#include <stdio.h>
#include <tchar.h>
#include "rc_soloist.h"



void cleanup(SoloistHandle *handles, DWORD handle_count);
int set_gear_params(SoloistHandle *handles, DOUBLE src, DOUBLE gear_scale, DOUBLE deadband, DOUBLE k_pos);
void print_error();
void reset_gear(SoloistHandle *handles, DWORD handle_count);

void
print_error()
{
    CHAR data[1024];
    SoloistGetLastErrorString(data, 1024);
    printf("Error : %s\n", data);
}


void
cleanup(SoloistHandle *handles, DWORD handle_count)
{
	print_error();
    if(handle_count > 0) {
		if(!SoloistMotionDisable(handles[0])) { print_error(); }
		if(!SoloistDisconnect(handles)) { print_error(); }
    }
    exit(-1);
}


int
set_gear_params(SoloistHandle *handles, DOUBLE src, DOUBLE gear_scale, DOUBLE deadband, DOUBLE k_pos)
{
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_GearCamSource , 1, src)) { return -1; }
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_GearCamScaleFactor , 1, gear_scale)) { return -1; }
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_GearCamAnalogDeadband , 1, deadband)) { return -1; }
    if(!SoloistParameterSetValue(handles[0], PARAMETERID_GainKpos , 1, k_pos)) { return -1; }
    return 0;
}


void
reset_gear(SoloistHandle *handles, DWORD handle_count) {
    
    // Take the stage out of gear mode if necessary
    if(!SoloistCommandExecute(handles[0], "GEAR 0", NULL)) { cleanup(handles, handle_count); }
    
    // Reset all the gear parameters to their defaults
    int gear_set = set_gear_params(handles, DEFAULT_GEARSOURCE, DEFAULT_GEARSCALEFACTOR, DEFAULT_ANALOGDEADBAND, DEFAULT_GAINKPOS);
    if (gear_set != 0) { cleanup(handles, handle_count); }
}


char *
get_ab_path(char *ab_dir, char *suffix) {
// return paths to the aerobasic scripts
	char *full_path;
	full_path = (char *) malloc(strlen(ab_dir) + 1);
	strcpy(full_path, ab_dir);
	full_path = (char *) realloc(full_path, strlen(full_path) + strlen(suffix) + 1);
	strcat(full_path, suffix);
	return full_path;
}