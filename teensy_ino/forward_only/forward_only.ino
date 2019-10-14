/* FORWARD_ONLY.INO
 * 
 * script for 
 * 1. monitoring the motion of a rotary encoder
 * 2. filtering the encoder signal
 * 3. outputing voltage signal of encoder velocity
 * 
 */


#include "controller.h"
#include "options.h"


// Controller defined in Arduino/Libraries: controller.cpp/h
Controller ctl;


void
setup() {
    // Protocol specific variables
    //    see class definition for details.
    ctl.protocol = FORWARD_ONLY;
    ctl.dac_offset_volts = 0.5;
    ctl.min_volts = 0;
    ctl.setup();
}


void
loop() {

    ctl.loop();
}
