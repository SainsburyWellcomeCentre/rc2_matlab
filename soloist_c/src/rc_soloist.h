#ifndef RC_SOLOIST_H
#define RC_SOLOIST_H

#include "C:\Program Files (x86)\Aerotech\Soloist\CLibrary\Include\Soloist.h"

#define AI_CHANNEL                      0
#define AO_CHANNEL                      0
#define AO_SERVO_VALUE                  4
#define AO_SCALE_FACTOR                 0.001f
#define DI_PORT                         0
#define DI_BIT                          0
#define RAMP_RATE                       200
#define MAX_INPUT_SPEED                 1000
#define SPEED_LIMIT 					1200
#define MAX_INPUT_VOLTAGE               2.5
#define GEARCAM_SOURCE                  2
#define DEADBAND                        0.005

#define AI_OFFSET 						-508.0
#define DEFAULT_GEARSOURCE              1
#define DEFAULT_GEARSCALEFACTOR         1
#define DEFAULT_ANALOGDEADBAND          0.05
#define DEFAULT_GAINKPOS                115
#define DEFAULT_RAMPRATE                200
#define DEFAULT_RAMPMODE                RAMPMODE_Rate
#define DEFAULT_POSITION                20
#define DEFAULT_SPEED					300


// Common functions in rc_shared.c
void cleanup(SoloistHandle *handles, DWORD handle_count);
int set_gear_params(SoloistHandle *handles, DOUBLE src, 
				DOUBLE gear_scale, DOUBLE deadband, DOUBLE k_pos);
void reset_gear(SoloistHandle *handles, DWORD handle_count);


#endif /* RC_SOLOIST_H */
