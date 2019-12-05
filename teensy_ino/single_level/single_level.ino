/* CALIBRATE_SOLOIST.INO
 * 
 * script for 
 * 1. wait for trigger input
 * 2. play a single velocity profile
 */


#include "ao.h"

#define DAC_OFFSET 		1.5

AnalogOut ao = AnalogOut();

void
setup() {
    // Protocol specific variables
    //    see class definition for details.
    ao.setup(DAC_OFFSET);
}


void
loop() {
}
