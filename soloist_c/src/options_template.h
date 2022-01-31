#ifndef OPTIONS_H
#define OPTIONS_H

/* 
 * options_template.h
 *
 * This file should be configured for a setup and re-saved as `options.h`
 * This is to prevent overwriting of any options.h files on a particular setup.
 *
 * Note that the resulting options.h file will not be tracked.
 *
 */

#define AI_CHANNEL                      0
#define AO_CHANNEL                      0
#define AO_SERVO_VALUE                  4
#define AO_SCALE_FACTOR                 0.00001f
#define DI_PORT                         0
#define SPEED_LIMIT 					1200
#define GEARCAM_SOURCE                  2

#define DEFAULT_GEARSOURCE              1
#define DEFAULT_GEARSCALEFACTOR         1
#define DEFAULT_ANALOGDEADBAND          0.05
#define DEFAULT_GAINKPOS                128.7
#define DEFAULT_RAMPRATE                200
#define DEFAULT_RAMPMODE                RAMPMODE_Rate
#define DEFAULT_POSITION                20
#define DEFAULT_SPEED					300


#endif /* OPTIONS_H */