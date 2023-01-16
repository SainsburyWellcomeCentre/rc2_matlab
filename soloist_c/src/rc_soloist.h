#ifndef RC_SOLOIST_H
#define RC_SOLOIST_H

#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"
#include "options.h"

// Common functions in rc_shared.c
void cleanup(SoloistHandle *handles, DWORD handle_count);
int set_gear_params(SoloistHandle *handles, DOUBLE src, 
				DOUBLE gear_scale, DOUBLE deadband, DOUBLE k_pos);
void reset_gear(SoloistHandle *handles, DWORD handle_count);
char *get_ab_path(char *ab_dir, char *suffix);

#endif /* RC_SOLOIST_H */
