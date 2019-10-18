#ifndef OPTIONS_H
#define OPTIONS_H


#define FORWARD_DISTANCE         1200   // MM,  distance treadmill travels forwards before distance is reset 
#define BACKWARD_DISTANCE        100	// MM, distance treadmill travels backwards before distance is reset 

// VELOCITY
#define FILTER_ON               1       // BOOL, whether to filter the velocity output with sliding average
#define VARIABLE_WINDOW         1       // BOOL, whether to decrease the filtering window with faster speeds.
#define N_MILLIS_LOW            5       // MILLISECONDS, time to average over at low speeds
                                            // this is used as the window, if VARIABLE_WINDOW = 0
											// at MAX_VELOCITY integration is over 1 bin = UPDATE_US
#define UPDATE_US               250     // MICROSECONDS, update rate for filtered trace
#define SIGMA_MS                2       // MILLISECONDS, sigma of the exponential for the sigmoid filter
#define MAX_VELOCITY            1000    // MM/S,  maximum velocity to output as voltage
#define MAX_VOLTS               2.5     // VOLTS,  voltage offset which MAX_VELOCITY attains

// ENCODER
#define DUAL_TRIGGER            1       // BOOLEAN,  whether or not to use encoder ticks A and B to calculate velocity
#define TIMEOUT                 50000   // MICROSECONDS, if encoder doesn't move, time to wait before setting velocity to zero 
#define NM_PER_COUNT            164381  // NM,  distance treadmill travels each tick
#define PHASE_FACTOR            0.2615 // 0-1,  phase of distance from A to B relative to distance from A to A encoder tick - empirically determined
#define PHASE_FACTOR_BACK       0.252 

// PROTOCOLS
#define FORWARD_ONLY            0
#define FORWARD_AND_BACKWARD    1

// PINS
#define ENC_A_PIN               0
#define ENC_B_PIN               1
#define ZERO_POSITION_PIN		6
#define REWARD_PIN				14
#define DAC_PIN                 A14

// ANALOG OUTPUT
#define MAX_DAC_VOLTS           3.3     // VOLTS, for converting to BITS
#define MAX_DAC_BITS            4095    // 2^12-1,  we are writing 12-bit integers to analog output


#endif /* OPTIONS_H */
